#!/usr/bin/env python3
"""Observe the original FOR alpha through X11, never process memory or hooks.

The unseeded game creates its own 70x70 Junktown and four debug dumps. Those
outputs are read-only observation oracles, not injected fixtures. Native arrows
move through observed terrain; camera-aware screenshot matching distinguishes
movement, fog-of-war updates and HUD redraw from merely changing pixels.
"""
from collections import deque
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import stat
import subprocess
import sys
import time
import traceback

COLS, ROWS, CELL = 100, 60, 16
WIDTH, HEIGHT = COLS * CELL, ROWS * CELL
FONT_SHA256 = '1e7af4dbdc86fd28e5c42d28dd892ff2f765da2d8f7272919820863fba1b8cce'
ERRORS = re.compile(r'generated\s*exception|segmentation fault|permission denied|'
                    r'no such file|traceback|couldn.t (?:open|load)|cannot (?:open|load)|'
                    r'failed to|error loading|assertion .* failed|terminate called|'
                    r'error in [^\r\n]+ line \d+ :|fatal error|symbol lookup error', re.I)
DIRECTIONS = [('Right', 1, 0), ('Down', 0, 1), ('Left', -1, 0), ('Up', 0, -1)]


def require(value, message):
    if not value:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def namespaces(proc):
    result = {'namespaces': {}, 'files': {}}
    for kind, host in [('user', 'USER'), ('mnt', 'MOUNT'), ('net', 'NET'), ('pid', 'PID')]:
        actual = os.readlink(proc / 'ns' / kind)
        require(actual != os.environ['HOST_' + host + '_NS'], 'host namespace leaked: ' + kind)
        require(actual == os.readlink('/proc/self/ns/' + kind), 'child namespace escape: ' + kind)
        result['namespaces'][kind] = actual
    for name in ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route'):
        result['files'][name] = (proc / name).read_text()
    for label, field in [('UID', 'Uid'), ('GID', 'Gid')]:
        number = int(os.environ['HOST_' + label])
        match = re.search(r'^' + field + r':\s*(.+)$', result['files']['status'], re.M)
        require(number != 0 and match and list(map(int, match[1].split())) == [number] * 4,
                'game is not same ordinary caller ' + field)
        require(list(map(int, result['files'][label.lower() + '_map'].split())) ==
                [number, number, 1], 'identity is not map-current-user')
    interfaces = [line.split(':')[0].strip() for line in result['files']['net/dev'].splitlines()[2:]
                  if ':' in line]
    require(interfaces == ['lo'], 'non-loopback interface present')
    require(len(result['files']['net/route'].splitlines()) <= 1, 'IPv4 route present')
    require(all(line.split()[-1] == 'lo' for line in result['files']['net/ipv6_route'].splitlines()
                if line.strip()), 'external IPv6 route present')
    result['interfaces'] = interfaces
    return result


def mount(source, target, flags=0, filesystem=None, data=None):
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_char_p]
    libc.mount.restype = ctypes.c_int
    encode = lambda value: None if value is None else os.fsencode(value)
    if libc.mount(encode(source), encode(target), encode(filesystem), flags, encode(data)):
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number), str(target))


def store_entries():
    text, entries = Path('/proc/self/mountinfo').read_text(), []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in [('\\040', ' '), ('\\011', '\t'), ('\\012', '\n'), ('\\134', '\\')]:
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            entries.append({'target': target, 'options': fields[5].split(','),
                            'optional': fields[6:fields.index('-')]})
    return text, entries


def isolate(evidence):
    (evidence / 'mountinfo-before.txt').write_text(store_entries()[0])
    mount('/gnu/store', '/gnu/store', 4096 | 16384)
    mount('/gnu/store', '/gnu/store', 262144 | 16384)
    for target in sorted({entry['target'] for entry in store_entries()[1]}, key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)
    text, entries = store_entries()
    require(entries and any(entry['target'] == '/gnu/store' for entry in entries), 'store bind absent')
    require(all('ro' in entry['options'] and 'rw' not in entry['options'] and not
                any(value.startswith(('shared:', 'master:')) for value in entry['optional'])
                for entry in entries), 'store is not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store statvfs not read-only')
    (evidence / 'mountinfo-store-readonly.txt').write_text(text)
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
        mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=0755')
        retained = Path('/tmp/for-evidence')
        retained.mkdir(mode=0o700)
        mount('/proc/self/fd/' + str(descriptor), retained, 4096)
    finally:
        os.close(descriptor)
    Path('/tmp/.X11-unix').mkdir(mode=0o1777)
    os.chmod('/tmp/.X11-unix', 0o1777)
    (retained / 'mountinfo-private.txt').write_text(Path('/proc/self/mountinfo').read_text())
    return retained, entries


def inventory(root):
    result = {}
    for path in sorted(root.rglob('*')):
        info = path.lstat()
        item = {'uid': info.st_uid, 'gid': info.st_gid, 'mode': stat.S_IMODE(info.st_mode)}
        if path.is_symlink():
            item.update(type='symlink', target=os.readlink(path))
        elif path.is_dir():
            item['type'] = 'directory'
        elif path.is_file():
            data = path.read_bytes()
            item.update(type='file', bytes=len(data), sha256=sha(data))
        else:
            item['type'] = 'other'
        result[str(path.relative_to(root))] = item
    return result


class Observer:
    def __init__(self, font, tool, convert):
        require(sha(font.read_bytes()) == FONT_SHA256, 'original active font bytes changed')
        geometry = tool(convert, str(font), '-format', '%w %h', 'info:')
        require(geometry.strip() == b'512 128', 'original 32x8 TCOD font atlas dimensions changed')
        rgba = tool(convert, str(font), '-depth', '8', 'rgba:-')
        require(len(rgba) == 512 * 128 * 4, 'font decode incomplete')
        transparent = any(rgba[i] < 255 for i in range(3, len(rgba), 4))
        invert = rgba[((CELL // 2) * 512 + CELL // 2) * 4] > 128
        # libtcod 1.5.1 sys_sdl_c.c:125-133 TCOD_FONT_LAYOUT_TCOD ASCII slots.
        slots = dict(zip(range(32, 65), range(33)))
        slots.update(zip(range(65, 91), range(96, 122)))
        slots.update(zip(range(91, 97), range(33, 39)))
        slots.update(zip(range(97, 123), range(128, 154)))
        slots.update(zip(range(123, 127), range(39, 43)))
        self.glyphs, self.cache = {}, {}
        for code, slot in slots.items():
            values = []
            for y in range((slot // 32) * CELL, (slot // 32 + 1) * CELL):
                for x in range((slot % 32) * CELL, (slot % 32 + 1) * CELL):
                    i = (y * 512 + x) * 4
                    values.append(rgba[i + 3] if transparent else 255 - rgba[i] if invert else rgba[i])
            peak = max(values)
            self.glyphs[chr(code)] = sum(1 << i for i, value in enumerate(values)
                                       if peak and value > peak / 3)

    def surface(self, rgb):
        require(len(rgb) == WIDTH * HEIGHT * 3, 'incomplete native framebuffer')
        rows = []
        for row in range(ROWS):
            chars = []
            for col in range(COLS):
                tile = b''.join(rgb[((row * CELL + y) * WIDTH + col * CELL) * 3:
                                   ((row * CELL + y) * WIDTH + (col + 1) * CELL) * 3]
                                for y in range(CELL))
                if tile not in self.cache:
                    values = [tuple(tile[i:i + 3]) for i in range(0, len(tile), 3)]
                    background = max(set(values), key=values.count)
                    distances = [sum(abs(a - b) for a, b in zip(value, background)) for value in values]
                    peak = max(distances)
                    if not peak:
                        char = ' '
                    else:
                        mask = sum(1 << i for i, value in enumerate(distances) if value > peak / 3)
                        error, char = min(((mask ^ glyph).bit_count(), char)
                                          for char, glyph in self.glyphs.items())
                        if error > 8:
                            char = '\ufffd'
                    self.cache[tile] = char
                chars.append(self.cache[tile])
            rows.append(''.join(chars))
        return rows


class Session:
    def __init__(self, output, evidence, root, tools):
        self.output, self.evidence, self.root = output, evidence, root
        self.xvfb, self.xdotool, self.xwd, self.convert = tools
        self.process = self.server = self.window = None
        self.inputs, self.commands = [], []
        self.env = {'PATH': '', 'LC_ALL': 'C', 'SDL_VIDEODRIVER': 'x11',
                    'SDL_AUDIODRIVER': 'dummy', 'LIBGL_ALWAYS_SOFTWARE': '1',
                    'MESA_SHADER_CACHE_DISABLE': 'true',
                    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=/run/no-session',
                    'DBUS_SYSTEM_BUS_ADDRESS': 'unix:path=/run/no-system'}
        for variable, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                               ('XDG_DATA_HOME', 'data'), ('XDG_STATE_HOME', 'state'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_RUNTIME_DIR', 'runtime'),
                               ('TMPDIR', 'tmp')]:
            self.env[variable] = str(root / name)
        self.state = root / 'state/for-roguelike'
        require(not self.state.exists(), 'initial game state is not fresh')
        self.observer = Observer(output / 'share/for-roguelike/font.png', self.tool, self.convert)

    def tool(self, *command, statuses=(0,)):
        result = subprocess.run(command, env=self.env, capture_output=True, timeout=20)
        self.commands.append({'argv': command, 'status': result.returncode,
                              'stdout_sha256': sha(result.stdout),
                              'stderr': result.stderr.decode(errors='replace')})
        record(self.evidence / 'tool-commands.json', self.commands)
        require(result.returncode in statuses, 'consumer command failed: ' + repr(command))
        require(not ERRORS.search(result.stderr.decode(errors='replace')), 'consumer command reported native error')
        return result.stdout

    def launch(self):
        readfd, writefd = os.pipe()
        try:
            with (self.evidence / 'xvfb.log').open('wb') as log:
                self.server = subprocess.Popen([self.xvfb, '-displayfd', str(writefd), '-screen', '0',
                    '1600x1000x24', '-nolisten', 'tcp', '-noreset', '-ac'],
                    env=self.env, pass_fds=(writefd,), stdout=log, stderr=log)
            os.close(writefd)
            writefd = None
            require(select.select([readfd], [], [], 20)[0] and self.server.poll() is None,
                    'private Xvfb display readiness absent')
            display = os.read(readfd, 128).decode().strip()
            require(display.isdecimal(), 'invalid Xvfb displayfd')
            self.env['DISPLAY'] = ':' + display
        finally:
            os.close(readfd)
            if writefd is not None:
                os.close(writefd)
        with (self.evidence / 'game.log').open('wb') as log:
            self.process = subprocess.Popen([str(self.output / 'bin/for-roguelike')],
                env=self.env, cwd=self.root / 'work', stdin=subprocess.DEVNULL, stdout=log, stderr=log)
        deadline = time.monotonic() + 45
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'game exited before native FOR window')
            found = self.tool(self.xdotool, 'search', '--onlyvisible', '--name', '^FOR$', statuses=(0, 1))
            windows = found.decode().splitlines()
            if windows:
                require(len(windows) == 1, 'FOR window not unique')
                self.window = windows[0]
                break
            time.sleep(.15)
        else:
            raise RuntimeError('FOR native window readiness timeout')
        self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
        time.sleep(.5)
        proc = Path('/proc') / str(self.process.pid)
        proof = namespaces(proc)
        proof.update(pid=self.process.pid, executable=os.readlink(proc / 'exe'), cwd=os.readlink(proc / 'cwd'))
        require(Path(proof['executable']).resolve() == (self.output / 'libexec/for-roguelike').resolve(),
                'launcher did not exec installed native core')
        require(Path(proof['cwd']) == self.state, 'game did not use fresh private XDG state CWD')
        require((self.output / 'libexec/for-roguelike').read_bytes()[:4] == b'\x7fELF', 'core is not ELF')
        for name in ('status', 'maps', 'mountinfo', 'cmdline'):
            (self.evidence / ('process-' + name + '.raw')).write_bytes((proc / name).read_bytes())
        return proof

    def key(self, label, key):
        require(self.process.poll() is None, 'game exited before ordinary input')
        self.inputs.append({'label': label, 'key': key, 'monotonic': time.monotonic(),
                            'transport': 'focused native XTEST keyboard'})
        record(self.evidence / 'native-inputs.json', self.inputs)
        self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
        self.tool(self.xdotool, 'key', '--clearmodifiers', '--delay', '70', key)
        time.sleep(.25)

    def capture(self, label):
        require(self.process.poll() is None, 'game exited during ' + label)
        dump, png = self.evidence / (label + '.xwd'), self.evidence / (label + '.png')
        self.tool(self.xwd, '-silent', '-id', self.window, '-out', str(dump))
        self.tool(self.convert, str(dump), str(png))
        geometry = self.tool(self.convert, str(png), '-format', '%w %h', 'info:')
        require(tuple(map(int, geometry.split())) == (WIDTH, HEIGHT), 'original 100x60 16px SDL window changed')
        rgb = self.tool(self.convert, str(png), '-depth', '8', 'rgb:-')
        rows = self.observer.surface(rgb)
        (self.evidence / (label + '.screen.txt')).write_text('\n'.join(rows) + '\n')
        record(self.evidence / (label + '.screen.json'), {'rows': rows, 'png_sha256': sha(png.read_bytes()),
                                                         'rgb_sha256': sha(rgb)})
        text = '\n'.join(rows)
        require(not ERRORS.search(text), 'native error visible in SDL window')
        require('Welcome to FOR.' in text, 'original welcome absent from real framebuffer')
        require(all(marker in '\n'.join(rows[:3]) for marker in
                    ('VaultDweller the Wanderer', 'Lvl 1', 'XP 0', 'HP ', 'AP ')),
                'original player and HP/AP/level HUD absent')
        return rows

    def stop(self):
        errors = []
        if self.process is not None and self.process.poll() is None:
            try:
                if self.window:
                    self.capture('failure-last-frame')
                    self.key('failure-cleanup-ordinary-escape', 'Escape')
                self.process.wait(timeout=5)
            except BaseException as error:
                errors.append('game cleanup: ' + repr(error))
        if self.server is not None and self.server.poll() is None:
            self.server.terminate()  # consumer-owned server, never game quit evidence
            try:
                self.server.wait(timeout=5)
            except BaseException as error:
                errors.append('Xvfb cleanup: ' + repr(error))
        return errors


def map_observation(rows, world, terrain):
    # WorldWindow.cpp:70 uses C++ truncation toward zero, NOT floor, for x.
    ul = (int(world[0] - 75 / 2), int(world[1] - 50 / 2))
    expected_player = (world[0] - ul[0] + 1, world[1] - ul[1] + 4)
    actors = [(x, y) for y in range(4, 52) for x in range(1, 74) if rows[y][x] == '@']
    require(actors == [expected_player], 'camera-aware actual @ does not match native world position')
    visible, fog, hidden, walls = {}, [], [], []
    for sy in range(4, 52):
        for sx in range(1, 74):
            wx, wy = ul[0] + sx - 1, ul[1] + sy - 4
            if not (0 <= wx < 70 and 0 <= wy < 70) or (wx, wy) == tuple(world):
                continue
            glyph = rows[sy][sx]
            if glyph in '#~.,=':
                require(glyph == terrain[wy][wx], 'visible tile disagrees with native generated dump')
                visible[(wx, wy)] = glyph
                if glyph == '#':
                    walls.append((wx, wy))
            elif glyph == '"':
                fog.append((wx, wy))
            elif glyph == ' ':
                hidden.append((wx, wy))
            else:
                raise RuntimeError('unrecognized native terrain glyph: ' + repr(glyph))
    require(len(visible) >= 20, 'native map is blank or lacks observable terrain')
    return {'world': list(world), 'screen': list(expected_player), 'camera_upper_left': list(ul),
            'visible': visible, 'fog': fog, 'hidden': hidden, 'walls': walls}


def summarize(observation):
    return {**{key: value for key, value in observation.items() if key != 'visible'},
            'visible': [{'world': list(point), 'glyph': glyph}
                        for point, glyph in sorted(observation['visible'].items())]}


def play(session):
    process = session.launch()
    initial = session.capture('initial-original-view')
    dump = session.state / 'leveldump.txt'
    terrain = dump.read_text().splitlines()
    require(len(terrain) == 70 and all(len(row) == 70 for row in terrain), 'generated Junktown is not 70x70')
    require(set(''.join(terrain)) <= set('#~.,= ') and any('#' in row for row in terrain),
            'native generation dump lacks original terrain and buildings')
    for name in ('leveldump.txt', 'visdump.txt', 'edgedump.txt', 'pathdump.txt'):
        require((session.state / name).is_file() and (session.state / name).stat().st_size > 0,
                'original startup dump absent: ' + name)
    # Junktown.cpp:46-75,134-140: buffer10, entrance(15,8), size(8,6),
    # original spawn(19,7). Initial camera is zero until first ordinary input.
    # F12 is unbound and simply runs the original FocusOnChar/Redraw loop.
    session.key('ordinary-unbound-key-focus-original-camera', 'F12')
    focused = session.capture('focused-generated-map')
    world = (19, 7)
    observation = map_observation(focused, world, terrain)
    require(observation['walls'] and observation['hidden'], 'initial map lacks walls or visibility boundary')
    hud = focused[:3]
    visited, moves = {world}, []
    newly_lit, became_fog = set(), set()
    initial_visible = set(observation['visible'])
    # Navigate toward the nearest still-hidden passable native dump cell. The
    # dump is produced by this actual run, not a seeded or injected fixture.
    # Only the first step is taken, and it must be visible in the framebuffer.
    for number in range(64):
        queue = deque([(world, [])])
        seen = {world}
        route = None
        while queue:
            point, path = queue.popleft()
            if path and point not in observation['visible'] and point not in observation['fog']:
                route = path
                break
            for key, dx, dy in DIRECTIONS:
                destination = (point[0] + dx, point[1] + dy)
                if (destination not in seen and 0 <= destination[0] < 70 and
                        0 <= destination[1] < 70 and terrain[destination[1]][destination[0]] in '~.,='):
                    seen.add(destination)
                    queue.append((destination, path + [(key, destination)]))
        if route is None:
            choices = [(destination in visited, index, key, destination)
                       for index, (key, dx, dy) in enumerate(DIRECTIONS)
                       for destination in [(world[0] + dx, world[1] + dy)]
                       if observation['visible'].get(destination) in ('~', '.', ',', '=')]
            require(choices, 'no actually visible adjacent walkable terrain')
            _, _, key, destination = min(choices)
        else:
            key, destination = route[0]
        require(observation['visible'].get(destination) in ('~', '.', ',', '='),
                'planned arrow destination is not actually visible walkable terrain')
        before = observation
        session.key('native-arrow-%02d' % number, key)
        rows = session.capture('native-move-%02d' % number)
        require(rows[:3] == hud, 'movement changed original stationary HP/AP/level HUD')
        observation = map_observation(rows, destination, terrain)
        newly_lit.update(set(observation['visible']) - initial_visible)
        became_fog.update(set(observation['fog']) & set(before['visible']))
        moves.append({'key': key, 'from': list(world), 'to': list(destination),
                      'observation': summarize(observation)})
        require(dump.read_text().splitlines() == terrain, 'generated terrain mutated during walking')
        world = destination
        visited.add(world)
        if len(moves) >= 4 and newly_lit and became_fog:
            break
    require(len(visited) >= 4, 'ordinary arrows did not traverse actual map cells')
    require(newly_lit and became_fog, 'walking did not reveal new tiles and leave native fog-of-war')
    session.key('ordinary-escape-quit', 'Escape')
    status = session.process.wait(timeout=15)
    require(status == 0, 'ordinary Escape did not exit cleanly')
    # main.cpp catches initialization exceptions and can still return zero.
    require(not ERRORS.search((session.evidence / 'game.log').read_text(errors='replace')),
            'native stdout/stderr contains exception or resource failure')
    return {'process': process, 'generated_map': {'size': [70, 70], 'sha256': sha(dump.read_bytes())},
            'initial_hud': initial[:3], 'focused_initial': summarize(map_observation(focused, (19, 7), terrain)),
            'moves': moves, 'newly_lit_world_cells': sorted(newly_lit),
            'became_fog_world_cells': sorted(became_fog), 'ordinary_escape_status': status}


def main():
    require(len(sys.argv) == 7, 'usage: native.py OUTPUT EVIDENCE XVFB XDOTOOL XWD CONVERT')
    output, evidence = map(Path, sys.argv[1:3])
    require(output.parent == Path('/gnu/store') and output.is_dir(), 'canonical store item required')
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc/self/fd/' + str(descriptor))
    proof = {'success': False, 'output': str(output), 'injected_seed_config_save': False,
             'font_sha256': FONT_SHA256, 'claim_limits': [
                 'Original alpha initialization, movement, visibility, HUD and clean quit only.',
                 'No combat, full-game completion or functional save/load is claimed.']}
    session = root = None
    failure = None
    try:
        require(os.getpid() == 1, 'driver not PID1 in private mounted proc')
        proof['driver_namespace'] = namespaces(Path('/proc/self'))
        evidence, mounts = isolate(evidence)
        proof['read_only_store_mounts'] = mounts
        closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
        tools = json.loads((evidence / 'consumer-tools.json').read_text())
        leaks = {name: tools[name] for name in ('python', 'xorg-server', 'xdotool', 'xwd', 'imagemagick')
                 if tools[name] in closure}
        require(str(output) in closure and not leaks, 'consumer-only tools leaked into game closure')
        proof['runtime_closure'] = closure
        proof['consumer_outputs'] = tools
        root = evidence / 'scratch'
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'state', 'cache', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        record(evidence / 'private-before.json', inventory(root))
        session = Session(output, evidence, root, sys.argv[3:])
        proof['gameplay'] = play(session)
        require(not list((root / 'work').iterdir()), 'launcher wrote into caller working directory')
        require(not list((root / 'config').iterdir()), 'game unexpectedly generated configuration')
        proof['success'] = True
    except BaseException as error:
        failure = error
        proof['error'] = repr(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
    finally:
        cleanup_errors = session.stop() if session is not None else []
        if root is not None and root.exists():
            record(evidence / 'private-after.json', inventory(root))
            # Preserve ordinary native outputs independently before successful
            # shell cleanup. On failure the exact scratch is retained as well.
            for path in root.rglob('*'):
                if path.is_file() and not path.is_symlink():
                    target = evidence / 'native-generated-files' / path.relative_to(root)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(path, target)
        for name in ('game.log', 'xvfb.log'):
            path = evidence / name
            if path.exists() and ERRORS.search(path.read_text(errors='replace')):
                cleanup_errors.append('native error retained in ' + name)
        if cleanup_errors:
            proof['success'] = False
            proof['cleanup_errors'] = cleanup_errors
        record(evidence / 'native-result.json', proof)
        os.close(descriptor)
    require(proof['success'] and failure is None, 'native consumer failed: ' + repr(failure or cleanup_errors))
    print('FOR_ROGUELIKE_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
