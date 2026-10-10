#!/usr/bin/env python3
"""Read DungeonMinder's real 80x60 SDL framebuffer and use ordinary X keys.

Source: official DungeonMinder.cpp v0.8, SHA256
70674a831a67a4a7abe61174f5e0daefa9b3a0e85a67b5e427497dd395f42260.
main:191-538, drawScreen:540-729, displayStatLine:1427-1484,
displaySpellMenu:1831-2205, castSpell:2213-2305. There is no save/load.
No RNG seed, memory/state injection, game hook or replacement font is used.
"""
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

COLS, ROWS, CELL = 80, 60, 8
WIDTH, HEIGHT = COLS * CELL, ROWS * CELL
FONT_HASH = '5e9e64246b857dc414bd0acde98820885274483580f751b9b3329b8ee86b82f4'
SOURCE = 'https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/dungeonminder/DungeonMinder.cpp'
ERRORS = re.compile(r'segmentation fault|permission denied|no such file|traceback|'
                    r'couldn.t (?:open|load)|cannot (?:open|load)|failed to|'
                    r'error loading|assertion .* failed|terminate called', re.I)
DIRECTIONS = [('Left', -1, 0), ('Right', 1, 0), ('Up', 0, -1), ('Down', 0, 1),
              ('y', -1, -1), ('u', 1, -1), ('b', -1, 1), ('n', 1, 1)]


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def namespace_proof(proc):
    namespaces = {kind: os.readlink(proc / 'ns' / kind)
                  for kind in ('user', 'mnt', 'net', 'pid')}
    host = {kind: os.environ['HOST_' + key + '_NS'] for kind, key in
            [('user', 'USER'), ('mnt', 'MOUNT'), ('net', 'NET'), ('pid', 'PID')]}
    files = {name: (proc / name).read_text() for name in
             ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route')}
    for kind, actual in namespaces.items():
        require(actual != host[kind], 'host namespace leaked: ' + kind)
        require(actual == os.readlink('/proc/self/ns/' + kind), 'child escaped: ' + kind)
    for kind, field in [('uid', 'Uid'), ('gid', 'Gid')]:
        number = int(os.environ['HOST_' + kind.upper()])
        match = re.search(r'^' + field + r':\s*(.+)$', files['status'], re.M)
        require(number != 0 and match and [int(x) for x in match[1].split()] == [number] * 4,
                'child is not ordinary same-identity ' + field)
        require([int(x) for x in files[kind + '_map'].split()] == [number, number, 1],
                'not map-current-user: ' + kind)
    interfaces = [row.split(':')[0].strip() for row in files['net/dev'].splitlines()[2:]
                  if ':' in row]
    require(interfaces == ['lo'], 'external network interface present')
    require(len(files['net/route'].splitlines()) <= 1, 'IPv4 routes present')
    require(all(row.split()[-1] == 'lo' for row in files['net/ipv6_route'].splitlines()
                if row.strip()), 'external IPv6 routes present')
    return {'namespaces': namespaces, 'host_namespaces': host, 'files': files}


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
    text = Path('/proc/self/mountinfo').read_text()
    entries = []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in [('\\040', ' '), ('\\011', '\t'),
                                 ('\\012', '\n'), ('\\134', '\\')]:
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            entries.append({'target': target, 'options': fields[5].split(','),
                            'optional': fields[6:fields.index('-')]})
    return text, entries


def isolate_filesystem(evidence):
    (evidence / 'mountinfo-before.txt').write_text(store_entries()[0])
    mount('/gnu/store', '/gnu/store', 4096 | 16384)
    mount('/gnu/store', '/gnu/store', 262144 | 16384)
    for target in sorted({item['target'] for item in store_entries()[1]}, key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)
    text, entries = store_entries()
    (evidence / 'mountinfo-store-readonly.txt').write_text(text)
    require(entries and any(item['target'] == '/gnu/store' for item in entries), 'missing store bind')
    require(all('ro' in item['options'] and 'rw' not in item['options'] and not
                any(value.startswith(('shared:', 'master:')) for value in item['optional'])
                for item in entries), 'store is not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store filesystem writable')
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
        mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=0755')
        retained = Path('/tmp/dungeonminder-evidence')
        retained.mkdir(mode=0o700)
        mount('/proc/self/fd/' + str(descriptor), retained, 4096)
    finally:
        os.close(descriptor)
    Path('/tmp/.X11-unix').mkdir(mode=0o1777)
    os.chmod('/tmp/.X11-unix', 0o1777)
    (retained / 'mountinfo-isolated.txt').write_text(Path('/proc/self/mountinfo').read_text())
    return retained, entries


def inventory(root):
    result = {}
    for path in sorted(root.rglob('*')):
        info = path.lstat()
        item = {'uid': info.st_uid, 'gid': info.st_gid, 'mode': stat.S_IMODE(info.st_mode)}
        if path.is_symlink():
            item.update(type='symlink', target=os.readlink(path))
        elif stat.S_ISDIR(info.st_mode):
            item['type'] = 'directory'
        elif stat.S_ISREG(info.st_mode):
            data = path.read_bytes()
            item.update(type='file', size=len(data), sha256=digest(data))
        else:
            item['type'] = 'other'
        result[str(path.relative_to(root))] = item
    return result


class Frame:
    def __init__(self, pixels, glyphs):
        require(len(pixels) == WIDTH * HEIGHT * 3, 'incomplete native framebuffer')
        self.pixels, self.cells, self.codes = pixels, [], []
        full_mask = (1 << (CELL * CELL)) - 1
        for row in range(ROWS):
            cells, codes = [], []
            for col in range(COLS):
                values = [tuple(pixels[((row * CELL + y) * WIDTH + col * CELL + x) * 3:
                                      ((row * CELL + y) * WIDTH + col * CELL + x) * 3 + 3])
                          for y in range(CELL) for x in range(CELL)]
                background = max(set(values), key=values.count)
                distances = [sum((a - b) ** 2 for a, b in zip(value, background))
                             for value in values]
                peak = max(distances)
                mask = sum(1 << i for i, distance in enumerate(distances)
                           if peak and distance > peak / 9)
                if not peak:
                    # Solid wall glyph219 is distinguishable from floor by
                    # source wall RGB (blue >= 115); floor blue is at most60.
                    code = 219 if background[2] >= 90 else 32
                else:
                    error, code = min((min((mask ^ glyph).bit_count(),
                                          ((mask ^ full_mask) ^ glyph).bit_count()), code)
                                      for code, glyph in glyphs.items())
                    if error > 4:
                        code = -1
                cells.append({'background': background, 'mask': mask,
                              'sha256': digest(bytes(component for value in values for component in value))})
                codes.append(code)
            self.cells.append(cells)
            self.codes.append(codes)
        self.rows = [''.join(chr(code) if 32 <= code < 127 else '~' if code == -1 else ' '
                             for code in row) for row in self.codes]

    def has_color(self, col, row, color):
        return any(tuple(self.pixels[((row * CELL + y) * WIDTH + col * CELL + x) * 3:
                                     ((row * CELL + y) * WIDTH + col * CELL + x) * 3 + 3]) == color
                   for y in range(CELL) for x in range(CELL))

    def text(self):
        return '\n'.join(self.rows)

    def actor(self, code):
        points = [(col, row) for row in range(2, 47) for col in range(4, 76)
                  if self.codes[row][col] == code]
        require(len(points) == 1, 'native map actor glyph %d is not unique: %r' % (code, points))
        return points[0]

    def mana(self, start):
        # Source HUD: unfilled cells are entirely black, filled cells contain
        # colored glyph224 backgrounds. Count actual visible 10-power blips,
        # not an invented precise mana value (regeneration is one per turn).
        return sum(any(self.pixels[((48 * CELL + y) * WIDTH + col * CELL + x) * 3 + c]
                       for y in range(CELL) for x in range(CELL) for c in range(3))
                   for col in range(start, start + 5))

    def state(self):
        return {'player': self.actor(15), 'hero': self.actor(64),
                'power_blips': {'hero': self.mana(48), 'monster': self.mana(56), 'world': self.mana(64)},
                'map_sha256': digest(b''.join(self.pixels[(row * CELL * WIDTH) * 3:
                                                        ((row + 1) * CELL * WIDTH) * 3]
                                             for row in range(2, 47))),
                'messages': self.rows[50:58]}


class Session:
    def __init__(self, output, evidence, root, tools):
        self.output, self.evidence, self.root = output, evidence, root
        self.xvfb, self.xdotool, self.xwd, self.convert = tools
        self.process = self.server = None
        self.window = None
        self.inputs, self.commands = [], []
        self.env = {'PATH': '', 'LC_ALL': 'C', 'HOME': str(root / 'home'),
                    'TMPDIR': str(root / 'tmp'), 'SDL_VIDEODRIVER': 'x11',
                    'SDL_AUDIODRIVER': 'dummy', 'LIBGL_ALWAYS_SOFTWARE': '1',
                    'MESA_SHADER_CACHE_DISABLE': 'true',
                    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-session'),
                    'DBUS_SYSTEM_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-system')}
        for variable, name in [('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                               ('XDG_STATE_HOME', 'state'), ('XDG_CACHE_HOME', 'cache'),
                               ('XDG_RUNTIME_DIR', 'runtime')]:
            self.env[variable] = str(root / name)
        font = output / 'share/dungeonminder/terminal.png'
        require(digest(font.read_bytes()) == FONT_HASH, 'font differs from exact historical primary asset')
        geometry = self.tool(self.convert, str(font), '-format', '%w %h', 'info:')
        require(geometry.strip() == b'128 128', 'original font grid changed')
        pixels = self.tool(self.convert, str(font), '-depth', '8', 'rgba:-')
        require(len(pixels) == 128 * 128 * 4, 'font pixels truncated')
        transparent = any(pixels[i] < 255 for i in range(3, len(pixels), 4))
        space = ((32 % 16) * CELL + CELL // 2) * 128 + (32 // 16) * CELL + CELL // 2
        invert = pixels[space * 4] > 128
        self.glyphs = {}
        for code in [*range(32, 127), 15, 127, 177, 195, 180, 207, 224]:
            values = []
            for y in range((code % 16) * CELL, (code % 16 + 1) * CELL):
                for x in range((code // 16) * CELL, (code // 16 + 1) * CELL):
                    i = (y * 128 + x) * 4
                    values.append(pixels[i + 3] if transparent else
                                  255 - pixels[i] if invert else pixels[i])
            peak = max(values)
            self.glyphs[code] = sum(1 << i for i, value in enumerate(values) if peak and value > peak / 3)

    def tool(self, *command):
        result = subprocess.run(command, env=self.env, capture_output=True, timeout=15)
        self.commands.append({'argv': command, 'status': result.returncode,
                              'stdout_sha256': digest(result.stdout),
                              'stderr': result.stderr.decode('utf-8', errors='replace')})
        record(self.evidence / 'tool-commands.json', self.commands)
        require(result.returncode == 0, 'native consumer command failed: ' + repr(command))
        require(not ERRORS.search(result.stderr.decode('utf-8', errors='replace')),
                'native consumer reported an error: ' + repr(command))
        return result.stdout

    def launch(self):
        read_fd, write_fd = os.pipe()
        try:
            with (self.evidence / 'xvfb.log').open('wb') as log:
                self.server = subprocess.Popen([self.xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                                '1024x768x24', '-nolisten', 'tcp', '-ac'],
                                               env=self.env, pass_fds=(write_fd,), stdout=log, stderr=log)
            os.close(write_fd)
            write_fd = None
            require(select.select([read_fd], [], [], 15)[0], 'Xvfb display allocation timed out')
            display = os.read(read_fd, 128).decode('ascii').strip()
            require(display.isdecimal(), 'Xvfb did not allocate a private display')
            self.env['DISPLAY'] = ':' + display
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
        with (self.evidence / 'game.log').open('wb') as log:
            self.process = subprocess.Popen([str(self.output / 'bin/dungeonminder')],
                                            env=self.env, cwd=self.root / 'work', stdout=log, stderr=log)
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'ordinary game exited before SDL window')
            found = subprocess.run([self.xdotool, 'search', '--onlyvisible', '--name', '^DungeonMinder$'],
                                   capture_output=True, env=self.env, timeout=5)
            if found.returncode == 0:
                windows = found.stdout.decode('ascii').splitlines()
                require(len(windows) == 1, 'native game window is not unique')
                self.window = windows[0]
                self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
                time.sleep(0.5)
                proc = Path('/proc') / str(self.process.pid)
                proof = namespace_proof(proc)
                proof.update(exe=os.readlink(proc / 'exe'), cwd=os.readlink(proc / 'cwd'), pid=self.process.pid)
                require(Path(proof['exe']).resolve() == self.output / 'bin/dungeonminder', 'not installed native executable')
                require(Path(proof['cwd']) == self.root / 'work', 'native game changed private CWD')
                for name in ('status', 'maps', 'mountinfo', 'cmdline'):
                    (self.evidence / ('process-' + name + '.raw')).write_bytes((proc / name).read_bytes())
                return proof
            time.sleep(0.1)
        raise RuntimeError('native SDL window timeout')

    def capture(self, label):
        require(self.process.poll() is None, 'game exited during ' + label)
        dump, png = self.evidence / (label + '.xwd'), self.evidence / (label + '.png')
        self.tool(self.xwd, '-silent', '-id', self.window, '-out', str(dump))
        self.tool(self.convert, str(dump), str(png))
        geometry = self.tool(self.convert, str(png), '-format', '%w %h', 'info:')
        require(tuple(map(int, geometry.split())) == (WIDTH, HEIGHT), 'original 80x60 SDL geometry changed')
        pixels = self.tool(self.convert, str(png), '-depth', '8', 'rgb:-')
        (self.evidence / (label + '.rgb')).write_bytes(pixels)
        frame = Frame(pixels, self.glyphs)
        (self.evidence / (label + '.screen.txt')).write_text(frame.text() + '\n')
        record(self.evidence / (label + '.screen.json'), {'codes': frame.codes, 'cells': frame.cells,
                                                         'png_sha256': digest(png.read_bytes())})
        return frame

    def key(self, label, key):
        require(self.process.poll() is None, 'input to exited game')
        self.inputs.append({'label': label, 'key': key, 'monotonic': time.monotonic(),
                            'transport': 'xdotool native focused XTEST keyboard'})
        record(self.evidence / 'native-inputs.json', self.inputs)
        self.tool(self.xdotool, 'key', '--clearmodifiers', key)
        time.sleep(0.22)

    def action(self, label, key):
        self.key(label, key)
        return self.capture(label)

    def quit(self):
        self.key('ordinary-quit-source-main-403', 'Escape')
        status = self.process.wait(timeout=15)
        require(status == 0, 'ordinary Escape exit failed: %r' % status)
        return status

    def cleanup(self):
        result, errors = {}, []
        if self.process is not None:
            if self.process.poll() is None:
                try:
                    # Failure cleanup is still ordinary input. A first Escape
                    # may dismiss a menu/direction prompt; the next exits main.
                    for number in range(3):
                        if self.process.poll() is not None:
                            break
                        self.key('failure-cleanup-escape-%d' % number, 'Escape')
                        time.sleep(0.2)
                    self.process.wait(timeout=5)
                except BaseException as error:
                    errors.append('game cleanup: ' + repr(error))
            result['game_exit_status'] = self.process.poll()
            require_finished = self.process.poll() is not None
            if not require_finished:
                errors.append('game still running; namespace teardown is not a successful ordinary quit')
        if self.server is not None:
            if self.server.poll() is None:
                self.server.terminate()  # consumer-owned X server, never game quit evidence
                try:
                    self.server.wait(timeout=5)
                except BaseException as error:
                    errors.append('Xvfb cleanup: ' + repr(error))
            result['xvfb_exit_status'] = self.server.poll()
        result['errors'] = errors
        return result


def play(session):
    process = session.launch()
    initial = session.capture('initial')
    require(all(marker in initial.text() for marker in
                ('DungeonMinder', 'Level 1', 'Hero health:', 'Power:', 'Welcome to the game!',
                 'Message History', 'Spell Menu')), 'original map/HUD/welcome missing')
    before = initial.state()
    require(before['power_blips'] == {'hero': 5, 'monster': 5, 'world': 5}, 'new game power is not full')
    menu = session.action('spell-menu', 'Tab')
    require(all(marker in menu.text() for marker in
                ('Pacifism', 'Speed', 'Heal', 'Blind', 'Rage', 'Sleep', 'Clear', 'Cloud', 'Trap')),
            'original spell menu missing initial nine spells')
    dismissed = session.action('spell-menu-dismissed', 'Escape')
    require(dismissed.state() == before and dismissed.pixels == initial.pixels,
            'menu dismissal took a turn or changed original framebuffer')
    history = session.action('message-history', 'm')
    require('Message History' in history.text() and 'press any key to close' in history.text(),
            'ordinary message history did not open')
    resumed = session.action('history-dismissed', 'Escape')
    require(resumed.pixels == initial.pixels, 'message history dismissal took a turn')
    session.action('spell-menu-for-pacifism', 'Tab')
    pacified = session.action('cast-pacifism-from-menu', 'q')
    require('The hero appears calmer!' in pacified.text(), 'ordinary menu q did not cast PACIFISM')
    after_pacifism = pacified.state()
    require(after_pacifism['power_blips']['hero'] == 4 and
            after_pacifism['power_blips']['monster'] == 5 and after_pacifism['power_blips']['world'] == 5,
            'PACIFISM did not consume the visible hero-school power blip')
    player = pacified.actor(15)
    move = next(((key, (player[0] + dx, player[1] + dy)) for key, dx, dy in DIRECTIONS
                 if 4 <= player[0] + dx <= 75 and 2 <= player[1] + dy <= 46 and
                 pacified.codes[player[1] + dy][player[0] + dx] == 32), None)
    require(move is not None, 'no visible ordinary adjacent empty floor')
    moved = session.action('move-player-to-visible-floor', move[0])
    require(moved.actor(15) == move[1], 'ordinary movement did not move player to observed floor')
    cloud_menu = session.action('spell-menu-for-cloud', 'Tab')
    require('Cloud' in cloud_menu.text() and 'Creates a cloud of' in cloud_menu.text(),
            'ordinary CLOUD menu and source description missing')
    cloud = session.action('cast-cloud-from-menu', 'd')
    require('A thick cloud of smoke appears around you!' in cloud.text(), 'ordinary menu d did not cast CLOUD')
    after_cloud = cloud.state()
    require(after_cloud['power_blips']['world'] == 2, 'CLOUD did not consume three visible world power blips')
    px, py = cloud.actor(15)
    green = [(col, row) for row in range(max(2, py - 2), min(47, py + 3))
             for col in range(max(4, px - 2), min(76, px + 3))
             if cloud.has_color(col, row, (100, 150, 100))]
    require(len(green) >= 5 and cloud.pixels != moved.pixels,
            'CLOUD message/power changed without actual source green smoke map effect')
    turns = []
    for number in range(8):
        waited = session.action('ordinary-wait-%02d' % number, 'space')
        require('The hero has died!' not in waited.text(), 'hero died before native AI progress proof')
        state = waited.state()
        require(state['player'] == after_cloud['player'], 'SPACE wait moved the player')
        turns.append(state)
    require(len({tuple(state['hero']) for state in [before, after_pacifism, after_cloud, *turns]}) >= 2,
            'ordinary turn-taking inputs did not advance autonomous hero position')
    require(any(state['hero'] != after_cloud['hero'] for state in turns),
            'ordinary SPACE waits did not advance autonomous hero')
    status = session.quit()
    return {'process': process, 'initial': before, 'pacifism': after_pacifism,
            'movement': {'key': move[0], 'destination': move[1], 'state': moved.state()},
            'cloud': {'state': after_cloud, 'green_smoke_cells': green},
            'ordinary_space_turns': turns, 'normal_escape_exit_status': status,
            'menu_dismissal_did_not_take_turn': True, 'history_dismissal_did_not_take_turn': True}


def main():
    require(len(sys.argv) == 7, 'usage: native.py OUTPUT EVIDENCE XVFB XDOTOOL XWD CONVERT')
    output, evidence = map(Path, sys.argv[1:3])
    require(output.parent == Path('/gnu/store') and output.is_dir(), 'canonical prebuilt store item required')
    require(evidence.is_dir() and not (evidence / 'native-result.json').exists(), 'fresh shell evidence required')
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    # Keep the host-retained directory reachable even if isolation fails
    # between overlaying /tmp and binding the evidence into the private tree.
    evidence = Path('/proc/self/fd/' + str(evidence_fd))
    report = {'success': False, 'source': SOURCE, 'source_sha256':
              '70674a831a67a4a7abe61174f5e0daefa9b3a0e85a67b5e427497dd395f42260',
              'persistence': 'Upstream has no save/load; no save feature is invented or tested.',
              'font_sha256': FONT_HASH}
    root = session = None
    cleanup_errors = []
    try:
        require(os.getpid() == 1, 'consumer is not PID1 in private proc mount')
        report['isolation'] = namespace_proof(Path('/proc/self'))
        evidence, entries = isolate_filesystem(evidence)
        report['isolation']['store'] = entries
        native = output / 'bin/dungeonminder'
        require(native.read_bytes()[:4] == b'\x7fELF', 'installed game is not native ELF')
        require(not any('native.py' in path.name or 'smoke' in path.name for path in output.rglob('*')),
                'external smoke helper leaked into output')
        closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
        require(str(output) in closure, 'runtime closure missing game')
        # Compare exact consumer outputs, not package-name prefixes: SDL's
        # Wayland/libxml2 runtime legitimately references python-minimal.
        tools = json.loads((evidence / 'consumer-tools.json').read_text())
        consumers = {name: tools[name] for name in
                     ('python', 'xorg-server', 'xdotool', 'xwd', 'imagemagick')}
        leaks = {name: path for name, path in consumers.items() if path in closure}
        record(evidence / 'consumer-closure-audit.json',
               {'consumer_outputs': consumers, 'exact_consumer_leaks': leaks,
                'python_named_runtime_items': [path for path in closure
                                              if Path(path).name[33:].startswith('python-')]})
        require(not leaks, 'exact consumer-only outputs leaked into runtime closure: ' + repr(leaks))
        report['output'] = {'native_sha256': digest(native.read_bytes()), 'closure': closure,
                            'consumer_outputs': consumers, 'exact_consumer_leaks': leaks}
        root = Path('/tmp/dungeonminder-private')
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        initial_inventory = inventory(root)
        record(evidence / 'private-before.json', initial_inventory)
        session = Session(output, evidence, root, sys.argv[3:])
        report['gameplay'] = play(session)
        require(inventory(root) == initial_inventory, 'game unexpectedly wrote files despite upstream having no persistence')
        for path in (evidence / 'game.log', evidence / 'xvfb.log'):
            require(not ERRORS.search(path.read_text(errors='replace')), 'native error in ' + path.name)
        report['success'] = True
    except BaseException as error:
        report['error'] = repr(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        raise
    finally:
        cleanup = {'private_removed': root is None, 'evidence_retained': True}
        if session is not None:
            if session.window and session.process and session.process.poll() is None:
                try:
                    session.capture('failure-last-frame')
                except BaseException as error:
                    cleanup_errors.append('last frame: ' + repr(error))
            cleanup.update(session.cleanup())
            cleanup_errors.extend(cleanup.get('errors', []))
        if root is not None and root.exists():
            try:
                record(evidence / 'private-after.json', inventory(root))
                for path in root.rglob('*'):
                    if path.is_file() and not path.is_symlink():
                        target = evidence / 'retained-native-files' / path.relative_to(root)
                        target.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copyfile(path, target)
                shutil.rmtree(root)
                cleanup['private_removed'] = not root.exists()
            except BaseException as error:
                cleanup_errors.append('private cleanup: ' + repr(error))
        for name in ('game.log', 'xvfb.log'):
            path = evidence / name
            if path.exists() and ERRORS.search(path.read_text(errors='replace')):
                cleanup_errors.append('native error retained in ' + name)
        cleanup['errors'] = cleanup_errors
        if cleanup_errors:
            report['success'] = False
            report['cleanup_errors'] = cleanup_errors
        record(evidence / 'cleanup.json', cleanup)
        record(evidence / 'native-result.json', report)
        os.close(evidence_fd)
        require(not cleanup_errors, 'native cleanup failed: ' + repr(cleanup_errors))
    print('DUNGEONMINDER_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
