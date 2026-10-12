#!/usr/bin/env python3
"""Observe ordinary Enemy Trench through XTest and real X11 screenshots.

Oracle: upstream 698bee218f76d16b98abc7eb2991a7690fffd9b4 main.py,
setup_game.py, input_handlers.py, game_map.py, tile_types.py and entity_factories.py.
Only the immutable tilesheet is rasterized through the launcher's exact tcod
closure.  No game module, pickle, injected state, PRNG seed, event hook or
headless game interface is used.  Save bytes are only hashed/copied as evidence.
All gameplay, including save selection and quit, enters the real SDL key loop.
"""
import ast
import ctypes as C
import hashlib
import json
import os
from pathlib import Path
import re
import select
import stat
import struct
import subprocess
import sys
import time
import traceback
import zlib

COMMIT = '698bee218f76d16b98abc7eb2991a7690fffd9b4'
WIDTH, HEIGHT, TILE = 800, 500, 10


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def namespace_proof(proc, evidence):
    result = {}
    for kind, key in [('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                      ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')]:
        value = os.readlink(proc / 'ns' / kind)
        require(value != os.environ[key], 'host namespace leaked: ' + kind)
        require(value == os.readlink('/proc/self/ns/' + kind), 'namespace escape: ' + kind)
        result[kind] = value
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            identity[key] = [int(x) for x in value.split()]
    for label, key in [('Uid', 'HOST_UID'), ('Gid', 'HOST_GID')]:
        require(identity[label] == [int(os.environ[key])] * 4, 'caller identity changed')
    for filename, key in [('uid_map', 'HOST_UID'), ('gid_map', 'HOST_GID')]:
        mapping = (proc / filename).read_text()
        require([int(x) for x in mapping.split()] ==
                [int(os.environ[key]), int(os.environ[key]), 1], 'not map-current-user')
        result[filename] = mapping
    dev = (proc / 'net/dev').read_text()
    routes = (proc / 'net/route').read_text()
    interfaces = sorted(line.split(':')[0].strip() for line in dev.splitlines()[2:]
                        if ':' in line)
    require(interfaces == ['lo'], 'nonisolated network interfaces')
    require(len(routes.splitlines()) <= 1, 'network route data present')
    result.update(identity=identity, interfaces=interfaces, net_dev=dev, net_route=routes)
    write_json(evidence / ('namespace-' + proc.name + '.json'), result)
    return result


def isolate_mounts(evidence):
    commands = []

    def mount(*args):
        command = [os.environ['MOUNT'], *args]
        result = subprocess.run(command, capture_output=True, text=True, timeout=15)
        commands.append(dict(command=command, status=result.returncode,
                             stdout=result.stdout, stderr=result.stderr))
        write_json(evidence / 'mount-commands.json', commands)
        require(result.returncode == 0, 'mount failed: ' + result.stderr)

    def entries():
        text = Path('/proc/self/mountinfo').read_text()
        found = []
        for line in text.splitlines():
            fields = line.split()
            target = fields[4]
            for escaped, literal in [('\\040', ' '), ('\\011', '\t'),
                                     ('\\012', '\n'), ('\\134', '\\')]:
                target = target.replace(escaped, literal)
            if target == '/gnu/store' or target.startswith('/gnu/store/'):
                found.append((target, fields[5].split(','), fields[6:fields.index('-')]))
        return text, found

    (evidence / 'mountinfo-before.txt').write_text(entries()[0])
    mount('--rbind', '/gnu/store', '/gnu/store')
    mount('--make-rprivate', '/gnu/store')
    targets = sorted({row[0] for row in entries()[1]}, key=len, reverse=True)
    require('/gnu/store' in targets, 'recursive store bind absent')
    for target in targets:
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    require(found and all('ro' in options and 'rw' not in options and not
                         any(x.startswith(('shared:', 'master:')) for x in optional)
                         for _, options, optional in found), 'store not private read-only')
    (evidence / 'mountinfo-after.txt').write_text(text)
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        # Use the retained directory descriptor for command logs while /tmp
        # hides the original path (EVIDENCE itself may have been under /tmp).
        source = '/proc/' + str(os.getpid()) + '/fd/' + str(descriptor)
        evidence = Path(source)
        mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/tmp')
        retained = Path('/tmp/enemy-trench-evidence')
        retained.mkdir()
        mount('--bind', source, str(retained))
    finally:
        os.close(descriptor)
    # Hide all host runtime sockets, including D-Bus and audio.
    evidence = retained
    mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/run')
    return retained, found


class XImage(C.Structure):
    _fields_ = [('width', C.c_int), ('height', C.c_int), ('xoffset', C.c_int),
                ('format', C.c_int), ('data', C.c_void_p), ('byte_order', C.c_int),
                ('bitmap_unit', C.c_int), ('bitmap_bit_order', C.c_int),
                ('bitmap_pad', C.c_int), ('depth', C.c_int),
                ('bytes_per_line', C.c_int), ('bits_per_pixel', C.c_int),
                ('red_mask', C.c_ulong), ('green_mask', C.c_ulong), ('blue_mask', C.c_ulong)]


class XCapture:
    def __init__(self, display):
        self.lib = C.CDLL(os.environ['LIBX11'])
        for name, args, result in [
                ('XOpenDisplay', [C.c_char_p], C.c_void_p),
                ('XGetImage', [C.c_void_p, C.c_ulong, C.c_int, C.c_int,
                               C.c_uint, C.c_uint, C.c_ulong, C.c_int], C.c_void_p),
                ('XDestroyImage', [C.c_void_p], C.c_int),
                ('XCloseDisplay', [C.c_void_p], C.c_int)]:
            function = getattr(self.lib, name)
            function.argtypes, function.restype = args, result
        self.display = self.lib.XOpenDisplay(display.encode())
        require(self.display, 'cannot open private X display')

    def capture(self, window):
        image = self.lib.XGetImage(self.display, window, 0, 0, WIDTH, HEIGHT,
                                   C.c_ulong(-1).value, 2)
        require(image, 'XGetImage failed')
        try:
            header = C.cast(image, C.POINTER(XImage)).contents
            require((header.width, header.height, header.depth, header.bits_per_pixel,
                     header.byte_order, header.red_mask, header.green_mask, header.blue_mask) ==
                    (WIDTH, HEIGHT, 24, 32, 0, 0xff0000, 0xff00, 0xff),
                    'native framebuffer format changed')
            raw = C.string_at(header.data, header.bytes_per_line * HEIGHT)
            rgb = bytearray(WIDTH * HEIGHT * 3)
            for y in range(HEIGHT):
                row = raw[y * header.bytes_per_line:y * header.bytes_per_line + WIDTH * 4]
                offset = y * WIDTH * 3
                rgb[offset:offset + WIDTH * 3:3] = row[2::4]
                rgb[offset + 1:offset + WIDTH * 3:3] = row[1::4]
                rgb[offset + 2:offset + WIDTH * 3:3] = row[0::4]
            return bytes(rgb)
        finally:
            self.lib.XDestroyImage(image)


def crop(rgb, x, y, width, height):
    return b''.join(rgb[((y + dy) * WIDTH + x) * 3:
                       ((y + dy) * WIDTH + x + width) * 3] for dy in range(height))


def save_png(path, rgb):
    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body))
    rows = b''.join(b'\0' + rgb[y * WIDTH * 3:(y + 1) * WIDTH * 3] for y in range(HEIGHT))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' +
                     chunk(b'IHDR', struct.pack('>IIBBBBB', WIDTH, HEIGHT, 8, 2, 0, 0, 0)) +
                     chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


class Raster:
    """Reference tileset only; never import/evaluate installed game modules."""
    def __init__(self, source):
        tree = ast.parse((source / 'launch.py').read_text())
        lists = [ast.literal_eval(node.value) for node in ast.walk(tree)
                 if isinstance(node, ast.Assign) and any(
                     isinstance(target, ast.Subscript) and isinstance(target.value, ast.Attribute)
                     and isinstance(target.value.value, ast.Name) and target.value.value.id == 'sys'
                     and target.value.attr == 'path' for target in node.targets)]
        require(len(lists) == 1 and isinstance(lists[0], list), 'launcher closure list absent')
        require(lists[0][0] == str(source), 'launcher source directory changed')
        paths = lists[0][1:]
        require(paths and all(isinstance(value, str) and value.startswith('/gnu/store/')
                              and value.endswith('/site-packages') and
                              str(Path(value).resolve(strict=True)) == value
                              for value in paths), 'noncanonical runtime dependency path')
        sys.path[:0] = paths
        import tcod
        self.tcod = tcod
        self.tiles = tcod.tileset.load_tilesheet(str(source / 'media/Images/tiles.png'),
                                               16, 16, tcod.tileset.CHARMAP_CP437)
        require((self.tiles.tile_width, self.tiles.tile_height) == (TILE, TILE),
                'tilesheet geometry changed')
        self.cache = {}
        self.paths = paths

    def glyph(self, char, fg=(255, 255, 255)):
        key = (char, fg)
        if key not in self.cache:
            console = self.tcod.console.Console(1, 1)
            console.print(0, 0, char, fg=fg, bg=(0, 0, 0))
            rgb = self.tiles.render(console)[:, :, :3].tobytes()
            tile = self.tiles.get_tile(ord(char))
            # Match opaque glyph interiors exactly.  The native SDL atlas can
            # sample a neighboring texel at a glyph boundary: native evidence
            # shows descender row 9 white pixels as 249, while CPU render has
            # 255.  No color tolerance is applied to the remaining pixels.
            # Fixed source text, grid anchors and every non-space glyph still
            # have to match; screenshots retain the unmodified boundary pixels.
            mask = [i for i, alpha in enumerate(tile[:, :, 3].flat)
                    if alpha == 255 and any(rgb[i * 3:i * 3 + 3]) and
                    0 < i % TILE < TILE - 1 and 0 < i // TILE < TILE - 1]
            self.cache[key] = (rgb, mask)
        return self.cache[key]

    def text(self, rgb, x, y, text, fg=(255, 255, 255)):
        for offset, char in enumerate(text):
            if char == ' ':
                continue
            reference, mask = self.glyph(char, fg)
            require(mask, 'reference glyph lacks opaque pixels: ' + repr(char))
            cell = crop(rgb, (x + offset) * TILE, y * TILE, TILE, TILE)
            if any(cell[i * 3:i * 3 + 3] != reference[i * 3:i * 3 + 3] for i in mask):
                return False
        return True

    def player(self, rgb):
        reference, mask = self.glyph('è')
        require(mask, 'Infantry sprite has no opaque pixels')
        positions = []
        for y in range(43):
            for x in range(80):
                cell = crop(rgb, x * TILE, y * TILE, TILE, TILE)
                if all(cell[i * 3:i * 3 + 3] == reference[i * 3:i * 3 + 3] for i in mask):
                    positions.append((x, y))
        return positions[0] if len(positions) == 1 else None

    def terrain(self, rgb, x, y):
        cell = crop(rgb, x * TILE, y * TILE, TILE, TILE)
        # Only visible, non-toxic source tiles; no save/map introspection.
        for char, fg in [('Ç', (196, 157, 0)), ('Ç', (76, 153, 0)),
                         ('ü', (255, 251, 175)), ('ç', (255, 255, 255)),
                         ('ä', (200, 200, 200)), ('é', (202, 108, 0))]:
            if cell == self.glyph(char, fg)[0]:
                return char, fg
        return None


def main():
    output, evidence = map(Path, sys.argv[1:])
    proof = {'commit': COMMIT, 'version': '1.0.5-698bee2', 'captures': [], 'inputs': [],
             'success': False, 'launch_arguments': []}
    game = None
    capture = None

    def save():
        write_json(evidence / 'proof.json', proof)

    try:
        require(output.is_absolute() and output.resolve(strict=True) == output and
                output.parent == Path('/gnu/store'), 'noncanonical package output')
        require(sys.flags.isolated and sys.flags.no_site, 'tool Python not isolated/no-site')
        require(str(Path(sys.executable).resolve(strict=True)).startswith('/gnu/store/'),
                'host tool Python')
        proof['tool_python'] = dict(executable=str(Path(sys.executable).resolve(strict=True)),
                                    isolated=True, no_site=True, initial_sys_path=sys.path[:])
        source = output / 'share/enemy-trench'
        launcher = output / 'bin/enemy-trench'
        for path in [output, *output.rglob('*')]:
            mode = path.lstat().st_mode
            if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
                require(not mode & 0o222, 'writable output member: ' + str(path))
        proof['isolation'] = namespace_proof(Path('/proc/self'), evidence)
        evidence, store = isolate_mounts(evidence)
        proof['store_mounts'] = store
        root = Path('/tmp/enemy-trench-state')
        root.mkdir(mode=0o700)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        env = {'PATH': '', 'LC_ALL': 'C.UTF-8', 'SDL_VIDEODRIVER': 'x11',
               'SDL_AUDIODRIVER': 'pulseaudio', 'SDL_RENDER_DRIVER': 'software',
               'LIBGL_ALWAYS_SOFTWARE': '1', 'MESA_SHADER_CACHE_DISABLE': 'true',
               'PYTHONNOUSERSITE': '1', 'PYTHONDONTWRITEBYTECODE': '1'}
        for key, name in [('HOME', 'home'), ('XDG_DATA_HOME', 'data'),
                          ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache'),
                          ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                          ('TMPDIR', 'tmp')]:
            directory = root / name
            directory.mkdir(mode=0o700)
            env[key] = str(directory)
        env.update(DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-session'),
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-system'),
                   PULSE_SERVER='unix:' + str(root / 'runtime/pulse-native'))
        work = root / 'work'
        work.mkdir()
        proof['environment'] = env.copy()
        proof['clean_state_before'] = {key: os.listdir(env[key]) for key in
                                      ('HOME', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME',
                                       'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR')}
        require(not any(proof['clean_state_before'].values()), 'state not fresh')
        save()

        def tool(binary, *args):
            result = subprocess.run([os.environ[binary], *args], env=env, cwd=work,
                                    capture_output=True, text=True, timeout=10)
            with (evidence / 'tools.jsonl').open('a') as log:
                log.write(json.dumps(dict(command=[os.environ[binary], *args],
                                          status=result.returncode, stdout=result.stdout,
                                          stderr=result.stderr)) + '\n')
            return result

        def start(label, args, **kwargs):
            with (evidence / (label + '.log')).open('wb') as log:
                return subprocess.Popen(args, env=env, cwd=work, stdin=subprocess.DEVNULL,
                                        stdout=log, stderr=log, **kwargs)

        config = root / 'pulse.pa'
        config.write_text('load-module module-native-protocol-unix socket=' +
                          str(root / 'runtime/pulse-native') + ' auth-anonymous=1\n'
                          'load-module module-null-sink sink_name=enemy_trench_smoke\n'
                          'set-default-sink enemy_trench_smoke\n')
        audio = start('pulseaudio', [os.environ['PULSEAUDIO'], '--daemonize=no',
                                   '--exit-idle-time=-1', '--use-pid-file=no',
                                   '--disable-shm=yes', '--log-target=stderr',
                                   '-n', '--file=' + str(config)])
        deadline = time.monotonic() + 15
        while not (root / 'runtime/pulse-native').exists() and time.monotonic() < deadline:
            require(audio.poll() is None, 'isolated audio daemon failed')
            time.sleep(.1)
        require(audio.poll() is None and (root / 'runtime/pulse-native').exists(),
                'audio readiness timeout')
        info = tool('PACTL', 'info')
        require(info.returncode == 0 and 'Default Sink: enemy_trench_smoke' in info.stdout,
                'isolated real SDL audio sink not ready')
        (evidence / 'pulse-info.txt').write_text(info.stdout)
        proof['audio_process'] = namespace_proof(Path('/proc') / str(audio.pid), evidence)
        raster = Raster(source)
        proof['raster_dependency_paths'] = raster.paths
        proof['tilesheet_sha256'] = hashlib.sha256(
            (source / 'media/Images/tiles.png').read_bytes()).hexdigest()
        readfd, writefd = os.pipe()
        try:
            server = start('xvfb', [os.environ['XVFB'], '-displayfd', str(writefd),
                                   '-screen', '0', '1024x768x24', '-nolisten', 'tcp', '-noreset'],
                           pass_fds=(writefd,))
            os.close(writefd)
            writefd = None
            require(select.select([readfd], [], [], 15)[0] and server.poll() is None,
                    'private Xvfb readiness absent')
            number = os.read(readfd, 64).decode().strip()
            require(number.isdigit(), 'invalid Xvfb displayfd')
            env['DISPLAY'] = ':' + number
        finally:
            os.close(readfd)
            if writefd is not None:
                os.close(writefd)
        capture = XCapture(env['DISPLAY'])
        game = start('game', [str(launcher)])
        deadline = time.monotonic() + 30
        window = None
        while time.monotonic() < deadline:
            require(game.poll() is None, 'ordinary game exited before native window')
            result = tool('XDOTOOL', 'search', '--onlyvisible', '--pid', str(game.pid),
                          '--name', '^Enemy Trench$')
            if result.returncode == 0:
                windows = result.stdout.split()
                require(len(windows) == 1, 'ambiguous native window')
                window = int(windows[0])
                break
            time.sleep(.15)
        require(window is not None, 'ordinary SDL window absent')
        proof['game_process'] = namespace_proof(Path('/proc') / str(game.pid), evidence)
        proof['command_line'] = (Path('/proc') / str(game.pid) / 'cmdline').read_bytes() \
            .decode().split('\0')[:-1]
        geometry = tool('XDOTOOL', 'getwindowgeometry', '--shell', str(window))
        require(geometry.returncode == 0 and 'WIDTH=800\n' in geometry.stdout and
                'HEIGHT=500\n' in geometry.stdout, 'ordinary window geometry changed')
        (evidence / 'window-geometry.txt').write_text(geometry.stdout)
        require(tool('XDOTOOL', 'windowfocus', '--sync', str(window)).returncode == 0,
                'native focus failed')
        require(tool('XDOTOOL', 'mousemove', '--window', str(window), '799', '499').returncode == 0,
                'cannot park native pointer')

        def errors():
            log = (evidence / 'game.log').read_text(errors='replace')
            require(not re.search(r'Traceback \(most recent call last\)|(?:Error|Exception):|'
                                  r'ALSA lib|Failed to (?:open|load|initialize)|'
                                  r'Audio device.*(?:failed|error)', log),
                    'native runtime error (see unfiltered game.log)')
            require(audio.poll() is None and server.poll() is None, 'native service exited')

        def frame(label, rgb):
            path = evidence / (label + '.png')
            save_png(path, rgb)
            proof['captures'].append(dict(file=path.name,
                                           sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
            save()

        def observe(label, predicate, timeout=12):
            deadline = time.monotonic() + timeout
            rgb = None
            while time.monotonic() < deadline:
                errors()
                require(game.poll() is None, 'native game exited during ' + label)
                rgb = capture.capture(window)
                value = predicate(rgb)
                if value:
                    frame(label, rgb)
                    return rgb, value
                time.sleep(.15)
            if rgb is not None:
                frame(label + '-failed', rgb)
            raise AssertionError('source pixel observation absent: ' + label)

        def key(name, control):
            proof['inputs'].append(dict(key=name, control=control, method='XTest'))
            save()
            require(tool('XDOTOOL', 'key', '--clearmodifiers', name).returncode == 0,
                    'native input failed: ' + name)
            time.sleep(.3)
            errors()

        def main_menu(rgb):
            return (raster.text(rgb, 0, 21, 'ENEMY TRENCH', (255, 255, 63)) and
                    raster.text(rgb, 0, 24, '[N] Play a new game') and
                    raster.text(rgb, 0, 23, '[C] Continue with last game'))

        def board(rgb):
            return raster.text(rgb, 0, 46, 'Area level: 1') and raster.player(rgb)

        observe('01-main-menu', main_menu)
        streams = tool('PACTL', 'list', 'short', 'sink-inputs')
        require(streams.returncode == 0 and streams.stdout.strip(), 'game has no real audio stream')
        proof['audio_sink_inputs'] = streams.stdout.splitlines()
        key('n', 'ordinary normal mode, not hardcore')
        observe('02-class', lambda rgb: raster.text(rgb, 0, 21, 'Select your Class:',
                                                   (255, 255, 63)))
        key('1', 'Infantry')
        observe('03-default-name', lambda rgb: raster.text(rgb, 26, 7, 'Name: Player Infantry'))
        # Native name-entry evidence shows that counting short synthetic presses can
        # leave a character behind.  Use the real name editor's rendered
        # Length field as the boundary, not an assumed count of delivered keys.
        for _ in range(32):
            errors()
            require(game.poll() is None, 'native game exited while clearing name')
            current = capture.capture(window)
            if raster.text(current, 26, 8, 'Length: 0/32'):
                break
            key('BackSpace', 'clear native name until observed Length is zero')
        else:
            raise AssertionError('native name editor did not clear within 32 presses')
        observe('03-cleared-name', lambda rgb:
                raster.text(rgb, 26, 7, 'Name: ◄') and
                raster.text(rgb, 26, 8, 'Length: 0/32'))
        name = 'GuixNative'
        proof['inputs'].append(dict(text=name, control='native SDL text input', method='XTest'))
        require(tool('XDOTOOL', 'type', '--clearmodifiers', '--delay', '100', name).returncode == 0,
                'native name input failed')
        observe('04-entered-name', lambda rgb:
                raster.text(rgb, 26, 7, 'Name: ' + name + '◄') and
                raster.text(rgb, 26, 8, 'Length: ' + str(len(name)) + '/32'))
        key('Return', 'create normal native game')
        observe('05-story', lambda rgb: raster.text(rgb, 1, 1,
                                                  'The 1st of September 1916 - The Somme'))
        key('space', 'dismiss story without a turn')
        initial, initial_pos = observe('06-initial-map', board)
        proof['normal_mode_evidence'] = 'N menu control; fresh state; ordinary Infantry creation'
        proof['initial_player_screen_tile'] = initial_pos
        movement = []

        def move(rgb, label):
            before = raster.player(rgb)
            require(before, 'unique Infantry sprite absent')
            choice = None
            for name_, dx, dy in [('Right', 1, 0), ('Down', 0, 1),
                                  ('Left', -1, 0), ('Up', 0, -1)]:
                x, y = before[0] + dx, before[1] + dy
                if 0 <= x < 80 and 0 <= y < 43:
                    terrain = raster.terrain(rgb, x, y)
                    if terrain and terrain[0] != 'é':
                        choice = name_, dx, dy
                        break
            require(choice, 'no visibly safe ordinary movement neighbor')
            name_, dx, dy = choice
            key(name_, 'move into observed non-toxic walkable terrain')
            after, position = observe(label, lambda image: board(image) if
                                      crop(image, 0, 0, 800, 430) !=
                                      crop(rgb, 0, 0, 800, 430) else None)
            scroll = (before[0] + dx - position[0], before[1] + dy - position[1])
            require(scroll[0] in (0, dx) and scroll[1] in (0, dy), 'unexpected camera displacement')
            matching = 0
            # Source get_camera follows the player.  Confirm visible static
            # terrain aligns under precisely this key's world displacement.
            for y in range(43):
                for x in range(80):
                    xx, yy = x - scroll[0], y - scroll[1]
                    if (x, y) == before or (xx, yy) == position or not (
                            0 <= xx < 80 and 0 <= yy < 43):
                        continue
                    terrain = raster.terrain(rgb, x, y)
                    if terrain and raster.terrain(after, xx, yy) == terrain:
                        matching += 1
            require(matching >= 10, 'movement lacked static terrain alignment')
            old_x, old_y = before[0] - scroll[0], before[1] - scroll[1]
            require(raster.terrain(after, old_x, old_y), 'old player tile did not become terrain')
            movement.append(dict(key=name_, world_delta=[dx, dy], before_screen_tile=before,
                                 after_screen_tile=position, camera_delta=scroll,
                                 matching_static_terrain_cells=matching))
            proof['movement'] = movement
            save()
            return after

        moved = move(initial, '07-moved-map')
        key('period', 'ordinary wait action')
        waited, _ = observe('08-wait-map', board)
        key('i', 'inspect ordinary inventory')
        inventory, _ = observe('09-inventory', lambda rgb:
                               raster.text(rgb, 1, 2, '(a) LE-Rifle w/ Bayo') and
                               raster.text(rgb, 1, 4, '(e) Gas Mask') and
                               raster.text(rgb, 1, 6, '(b) Rifle Ammo Pack') and
                               raster.text(rgb, 1, 8, '(d) Health Pack'))
        key('Escape', 'close inventory')
        saved_map, saved_pos = observe('10-before-save', board)
        key('Escape', 'native game menu')
        observe('11-game-menu', lambda rgb: raster.text(rgb, 1, 6, '[M]enu') and
                                            raster.text(rgb, 1, 7, '[Q]uit'))
        key('m', 'save through ordinary menu and return to main menu')
        observe('12-saved-main-menu', main_menu)
        state = Path(env['XDG_DATA_HOME']) / 'enemy-trench'
        savefile = state / 'saves' / (name + '.sav')
        require(savefile.is_file() and savefile.stat().st_size > 0, 'native XDG save missing')
        require(sorted(p.name for p in (state / 'saves').iterdir()) == [name + '.sav'],
                'unexpected saves in fresh state')
        require((state / 'settings.ini').is_file(), 'native XDG settings missing')
        save_bytes = savefile.read_bytes()
        (evidence / 'menu-save.sav').write_bytes(save_bytes)
        proof['menu_save'] = dict(path=str(savefile), bytes=len(save_bytes),
                                  sha256=hashlib.sha256(save_bytes).hexdigest())
        key('c', 'ordinary Continue save chooser')
        observe('13-save-chooser', lambda rgb: raster.text(rgb, 16, 7, name + '.sav'))
        key('Down', 'select observed native save')
        observe('14-save-selected', lambda rgb: raster.text(rgb, 16, 7, name + '.sav') and
                                                raster.text(rgb, 60, 7, '<-'))
        key('Return', 'load observed native save')
        loaded, loaded_pos = observe('15-loaded-map', board)
        require(loaded_pos == saved_pos and
                crop(loaded, 0, 0, 800, 430) == crop(saved_map, 0, 0, 800, 430),
                'loaded position/map differs from saved native observation')
        require(savefile.read_bytes() == save_bytes, 'loading rewrote native save')
        key('i', 'inspect inventory after load')
        loaded_inventory, _ = observe('16-loaded-inventory', lambda rgb:
                                      crop(rgb, 0, 0, 800, 350) ==
                                      crop(inventory, 0, 0, 800, 350))
        proof['continuity'] = dict(same_player_screen_tile=True,
                                   identical_map_pixels=True, identical_inventory_pixels=True,
                                   unchanged_save_on_load=True)
        key('Escape', 'close loaded inventory')
        resumed, _ = observe('17-resumed-map', board)
        continued = move(resumed, '18-continued-action')
        key('Escape', 'native quit menu')
        observe('19-quit-menu', lambda rgb: raster.text(rgb, 1, 7, '[Q]uit'))
        key('q', 'natural save-and-quit; no windowkill or process signal')
        status = game.wait(timeout=15)
        proof['native_exit_status'] = status
        require(status == 0, 'native exit was nonzero/signalled: ' + str(status))
        errors()
        final_bytes = savefile.read_bytes()
        require(final_bytes != save_bytes, 'continued action/quit did not update native save')
        (evidence / 'quit-save.sav').write_bytes(final_bytes)
        (evidence / 'settings.ini').write_bytes((state / 'settings.ini').read_bytes())
        proof['quit_save_sha256'] = hashlib.sha256(final_bytes).hexdigest()
        proof['mutable_files'] = [str(p.relative_to(root)) for p in root.rglob('*') if p.is_file()]
        require(not list(work.iterdir()), 'launcher wrote consumer working directory')
        require(not list(Path(env['HOME']).rglob('*.sav')), 'save escaped XDG data home')
        proof['success'] = True
        save()
        print('ENEMY_TRENCH_NATIVE_GAMEPLAY_OK normal/new/name/story/movement/wait/inventory/save/load/continued-action/natural-quit')
    except BaseException as error:
        proof['error'] = str(error)
        if game is not None:
            proof['native_exit_status_at_failure'] = game.poll()
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        save()
        raise
    finally:
        if capture is not None and capture.display:
            capture.lib.XCloseDisplay(capture.display)
        # PID namespace init exit disposes only this consumer's private services.
        # No host service/vault cleanup or native-game kill is used as success.


if __name__ == '__main__':
    main()
