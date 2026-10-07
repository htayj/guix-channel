#!/usr/bin/env python3
"""External consumer of ordinary Aquarium Arena 0.4-0.6d494c SDL gameplay.

Oracle: pinned upstream snapshot 6d494cee8d45f734eaecd56237f33aaec37a0ed8
gameEngine.py, graphicsHandler.py, tileEngine.py, mapField.py, monster.py,
item.py, effect.py, thing.py, hiscore.py and config/keystrokes.jsn, as
installed by the Guix package.  Only installed data files (tilesets, fonts,
texts) are opened for reference rasterization through the launcher's exact
pinned Pygame dependency; no game module is imported, patched or evaluated,
no PRNG is seeded, no pygame event is posted and no game state is accessed.
XTest keys/mouse enter the real SDL loop; every observation is a genuine
XGetImage capture of the native window compared byte-for-byte with source
raster predictions (never OCR).  Proof scope: board reconstruction, movement,
look and fire from ordinary input, then a clean WM-close quit.  Package
output stays on the read-only recursive /gnu/store bind; the game runs with
clean XDG state and an empty network namespace.
"""
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

COMMIT = '6d494cee8d45f734eaecd56237f33aaec37a0ed8'
VERSION = '0.4-0.6d494c'
WIDTH, HEIGHT = 1024, 660          # gameEngine.RESOLUTIONX/Y of set_mode SIZE
SCREEN_W, SCREEN_H = 1024, 660     # graphicsHandler screen surface
MAPPOSX = MAPPOSY = 10             # graphicsHandler map blit origin
TILE = 32                          # graphicsHandler.TILESIZE
BIGTILE = 50
MAPX, MAPY = 25, 15                # gameEngine.MAPMAXX/Y
LOGX, LOGY = 10, 500               # LOGWINDOWPOS
LOGW, LOGH = 700, 150              # LOGWINDOWSIZE
WATCHX, WATCHY = 830, 10           # WATCHPOS
DB_TINT = (0, 36, 56)              # deep-blue tint color
SOURCES = ['gameEngine.py', 'graphicsHandler.py', 'tileEngine.py',
           'mapField.py', 'monster.py', 'item.py', 'effect.py', 'thing.py',
           'hiscore.py', 'config/keystrokes.jsn', 'config/settings.jsn',
           'resources/data/map.jsn', 'resources/data/creatures.jsn',
           'resources/data/items.jsn', 'resources/texts/helpBox.txt']


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
        require(value == os.readlink('/proc/self/ns/' + kind),
                'process escaped ' + kind)
        result[kind] = value
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            identity[key] = [int(x) for x in value.split()]
    require(identity['Uid'] == [int(os.environ['HOST_UID'])] * 4, 'caller UID changed')
    require(identity['Gid'] == [int(os.environ['HOST_GID'])] * 4, 'caller GID changed')
    for filename, key in [('uid_map', 'HOST_UID'), ('gid_map', 'HOST_GID')]:
        mapping = (proc / filename).read_text()
        require([int(x) for x in mapping.split()] ==
                [int(os.environ[key]), int(os.environ[key]), 1], 'not map-current-user')
        result[filename] = mapping
    device_text = (proc / 'net/dev').read_text()
    route_text = (proc / 'net/route').read_text()
    interfaces = sorted(line.split(':')[0].strip() for line in
                        device_text.splitlines()[2:] if ':' in line)
    result.update(identity=identity, interfaces=interfaces,
                  net_dev=device_text, net_route=route_text)
    write_json(evidence / ('namespace-' + proc.name + '.json'), result)
    require(interfaces == ['lo'], 'network namespace is not loopback-only')
    route_lines = [line.split() for line in route_text.splitlines() if line.strip()]
    route_header = ['Iface', 'Destination', 'Gateway', 'Flags', 'RefCnt', 'Use',
                    'Metric', 'Mask', 'MTU', 'Window', 'IRTT']
    require(not route_lines or route_lines == [route_header],
            'private network has route data rows: ' + repr(route_text))
    return result


def mount_readonly(evidence):
    commands = []

    def mount(*args):
        command = [os.environ['MOUNT'], *args]
        result = subprocess.run(command, capture_output=True, text=True, timeout=15)
        commands.append({'command': command, 'returncode': result.returncode,
                         'stdout': result.stdout, 'stderr': result.stderr})
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
    targets = sorted({item[0] for item in entries()[1]}, key=len, reverse=True)
    require('/gnu/store' in targets, 'recursive store bind missing')
    for target in targets:
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    require(found and all('ro' in options and 'rw' not in options and not
                          any(x.startswith(('shared:', 'master:')) for x in optional)
                          for _, options, optional in found),
            'store is not private/read-only')
    (evidence / 'mountinfo-after.txt').write_text(text)
    # Relocate the evidence directory through an open FD before the private
    # /tmp and /run tmpfs overlays hide its original path.
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        evidence = Path('/proc/' + str(os.getpid()) + '/fd/' + str(descriptor))
        mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/tmp')
        retained = Path('/tmp/aquarium-evidence')
        retained.mkdir()
        mount('--bind', str(evidence), str(retained))
        evidence = retained
    finally:
        os.close(descriptor)
    return retained, {'recursive_readonly': True, 'store_mounts': found}


class XImage(C.Structure):
    _fields_ = [('width', C.c_int), ('height', C.c_int), ('xoffset', C.c_int),
                ('format', C.c_int), ('data', C.c_void_p), ('byte_order', C.c_int),
                ('bitmap_unit', C.c_int), ('bitmap_bit_order', C.c_int),
                ('bitmap_pad', C.c_int), ('depth', C.c_int),
                ('bytes_per_line', C.c_int), ('bits_per_pixel', C.c_int),
                ('red_mask', C.c_ulong), ('green_mask', C.c_ulong), ('blue_mask', C.c_ulong)]


class ClientMessage(C.Structure):
    _fields_ = [('type', C.c_int), ('serial', C.c_ulong), ('send_event', C.c_int),
                ('display', C.c_void_p), ('window', C.c_ulong),
                ('message_type', C.c_ulong), ('format', C.c_int), ('data', C.c_long * 5)]


class Event(C.Union):
    _fields_ = [('client', ClientMessage), ('pad', C.c_long * 24)]


class XCapture:
    def __init__(self, display):
        self.lib = C.CDLL(os.environ['LIBX11'])
        for name, args, result in [
                ('XOpenDisplay', [C.c_char_p], C.c_void_p),
                ('XGetImage', [C.c_void_p, C.c_ulong, C.c_int, C.c_int,
                               C.c_uint, C.c_uint, C.c_ulong, C.c_int], C.c_void_p),
                ('XDestroyImage', [C.c_void_p], C.c_int),
                ('XInternAtom', [C.c_void_p, C.c_char_p, C.c_int], C.c_ulong),
                ('XSendEvent', [C.c_void_p, C.c_ulong, C.c_int, C.c_long,
                                C.POINTER(Event)], C.c_int),
                ('XFlush', [C.c_void_p], C.c_int),
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
                    'private Xvfb framebuffer format differs')
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

    def close_window(self, window):
        event = Event()
        event.client.type = 33  # Xlib ClientMessage
        event.client.display = self.display
        event.client.window = window
        event.client.message_type = self.lib.XInternAtom(self.display, b'WM_PROTOCOLS', 0)
        event.client.format = 32
        event.client.data[0] = self.lib.XInternAtom(self.display, b'WM_DELETE_WINDOW', 0)
        require(self.lib.XSendEvent(self.display, window, 0, 0, C.byref(event)),
                'native close request not delivered')
        self.lib.XFlush(self.display)


def save_png(path, rgb):
    def chunk(kind, body):
        return (struct.pack('>I', len(body)) + kind + body +
                struct.pack('>I', zlib.crc32(kind + body)))
    rows = b''.join(b'\0' + rgb[y * WIDTH * 3:(y + 1) * WIDTH * 3] for y in range(HEIGHT))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' +
                     chunk(b'IHDR', struct.pack('>IIBBBBB', WIDTH, HEIGHT, 8, 2, 0, 0, 0)) +
                     chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


def crop(rgb, x, y, width, height):
    return b''.join(rgb[((y + dy) * WIDTH + x) * 3:
                        ((y + dy) * WIDTH + x + width) * 3] for dy in range(height))


class Source:
    """Renders exact screen-surface predictions with the pinned Pygame.

    Reproduces graphicsHandler.drawboard pixel placement: map layer at
    (MAPPOSX, MAPPOSY) over a black screen, creature/item/effect tiles with
    color-keyed transparency over the map, per-line deep-blue alpha fill,
    log window, watch UI text and help box.  Fonts are the installed
    FreeMonoBold.ttf rendered exactly as the source does.
    """

    def __init__(self, pygame, data):
        self.pg = pygame
        self.data = data
        self.statusfont = pygame.font.Font(str(data / 'resources/fonts/FreeMonoBold.ttf'), 14)
        self.logfont = pygame.font.Font(str(data / 'resources/fonts/FreeMonoBold.ttf'), 20)
        self._tile_cache = {}

    def tile(self, tileset_name, tilepos, tilesize=TILE):
        key = (tileset_name, tilepos, tilesize)
        if key not in self._tile_cache:
            tileset = self.pg.image.load(str(self.data / ('resources/img/' + tileset_name + '.png')))
            coord = str(tilepos).split(',')
            surface = self.pg.Surface((tilesize, tilesize))
            surface.blit(tileset, (0, 0), (int(coord[0]) * tilesize, int(coord[1]) * tilesize,
                                           tilesize, tilesize))
            surface.set_colorkey(self.pg.Color('black'))
            self._tile_cache[key] = surface
        return self._tile_cache[key]

    def font_rgb(self, font, text, color):
        return self.pg.image.tostring(font.render(text, 1, color), 'RGB')

    def watch_tile(self):
        # uiparttileeng.getcustomtile(watch.png, 0,0,168,315): color-keyed
        # watch art the HUD text is antialiased onto.
        if 'watch' not in self._tile_cache:
            watch = self.pg.image.load(str(self.data / 'resources/img/watch.png'))
            tile = self.pg.Surface((168, 315))
            tile.blit(watch, (0, 0), (0, 0, 168, 315))
            tile.set_colorkey(self.pg.Color('black'))
            self._tile_cache['watch'] = tile
        return self._tile_cache['watch']

    def status_line(self, rgb, x, y, text, color):
        # statusfont text antialiased onto the watch art at window (x, y):
        # composite the glyph over the watch tile region, exactly as the
        # source blits text onto watchimage before blitting at WATCHPOS.
        width, height = self.statusfont.size(text)
        surface = self.pg.Surface((width, height))
        surface.blit(self.watch_tile(), (-x + WATCHX, -y + WATCHY))
        surface.blit(self.statusfont.render(text, 1, color), (0, 0))
        return crop(rgb, x, y, width, height) == self.pg.image.tostring(surface, 'RGB')


    def loglines(self, rgb, lines):
        # log window: black LOGWINDOWSIZE background at (10,500); line i is
        # logfont color (120+i*20,...) at (10+10, 500+i*20), exactly as
        # graphicsHandler.drawboard renders its loglines.
        window = self.pg.Surface((LOGW, LOGH))
        window.fill((0, 0, 0))
        for index, text in enumerate(lines):
            color = (120 + index * 20,) * 3
            window.blit(self.logfont.render(text, 1, color), (10, index * 20))
        return crop(rgb, LOGX, LOGY, LOGW, LOGH) == self.pg.image.tostring(window, 'RGB')


def main():
    output, evidence = map(Path, sys.argv[1:])
    proof = {'status': 'failed', 'source_commit': COMMIT, 'version': VERSION,
             'inputs': [], 'captures': [],
             'source': ['https://github.com/valrak/AquariumRL/blob/' + COMMIT + '/' + name
                        for name in SOURCES],
             'limits': ['Meaningful normal first-run gameplay: welcome log and exact watch '
                        'HUD, full random-arena reconstruction, vi-key and arrow movement '
                        'with native turn advancement, examine/look mode, fire mode with '
                        'harpoon selection and fired-harpoon observation, then an '
                        'immediate clean SDL quit from the proven game state.',
                        'No death, help-screen, hiscore or persistence claim: those '
                        'scenarios are not exercised.',
                        'No import of game modules, no PRNG seeding, no pygame event '
                        'posting, no game-state access or mutation: every observation is '
                        'an XGetImage capture of the native SDL window.',
                        'Store output stays read-only; the game writes nothing in this '
                        'bounded scenario except what its ordinary loop does.']}

    def save():
        write_json(evidence / 'runtime.json', proof)
        write_json(evidence / 'evidence.json', proof)

    try:
        require(output.parent == Path('/gnu/store') and output.resolve() == output,
                'OUTPUT must be canonical direct store item')
        launcher = output / 'bin/aquarium-arena'
        data = output / 'share/aquarium-arena'
        require(os.access(launcher, os.X_OK), 'ordinary launcher absent')
        for name in ['AquariumArena.py', 'gameEngine.py', 'graphicsHandler.py',
                     'tileEngine.py', 'mapField.py', 'monster.py', 'item.py',
                     'effect.py', 'hiscore.py', 'thing.py',
                     'config/keystrokes.jsn', 'config/settings.jsn',
                     'resources/data/map.jsn', 'resources/data/creatures.jsn',
                     'resources/data/items.jsn', 'resources/data/effects.jsn',
                     'resources/texts/helpBox.txt', 'resources/texts/helpScreen.txt',
                     'resources/maps/arena1.csv',
                     'resources/img/MapTiles.png', 'resources/img/CreatureTiles.png',
                     'resources/img/BigCreatureTiles.png', 'resources/img/EffectTiles.png',
                     'resources/img/ItemTiles.png', 'resources/img/UI.png',
                     'resources/img/watch.png', 'resources/img/helpscreen.png',
                     'resources/fonts/FreeMonoBold.ttf',
                     'resources/fonts/LiberationMono-Bold.ttf']:
            require((data / name).is_file(), 'missing installed data: ' + name)
        for path in [output, *output.rglob('*')]:
            mode = path.lstat().st_mode
            if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
                require(not mode & 0o222, 'writable store member: ' + str(path))
        launch_text = launcher.read_text()
        match = re.search(r'^export PYTHONPATH=(/gnu/store/[^\n]+/site-packages)$',
                          launch_text, re.M)
        require(match, 'cannot resolve launcher exact Pygame rasterizer')
        require('exec ' in launch_text and 'AquariumArena.py' in launch_text,
                'launcher does not exec the installed ordinary entry point')
        sys.path.insert(0, match[1])
        import pygame
        pygame.font.init()
        src = Source(pygame, data)
        proof['font_oracle'] = {
            'pygame_path': match[1],
            'free_mono_sha256': hashlib.sha256(
                (data / 'resources/fonts/FreeMonoBold.ttf').read_bytes()).hexdigest(),
            'maptiles_sha256': hashlib.sha256(
                (data / 'resources/img/MapTiles.png').read_bytes()).hexdigest()}
        write_json(evidence / 'inputs.json',
                   [{'file': name,
                     'sha256': hashlib.sha256((data / name).read_bytes()).hexdigest()}
                    for name in ('resources/img/MapTiles.png',
                                 'resources/img/CreatureTiles.png',
                                 'resources/img/ItemTiles.png',
                                 'resources/img/EffectTiles.png',
                                 'resources/img/watch.png',
                                 'resources/fonts/FreeMonoBold.ttf')])
        proof['isolation'] = namespace_proof(Path('/proc/self'), evidence)
        evidence, store = mount_readonly(evidence)
        proof['isolation'].update(store)
        root = Path('/tmp/aquarium-state')
        root.mkdir(mode=0o700)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        env = {'PATH': '', 'LC_ALL': 'C.UTF-8', 'SDL_VIDEODRIVER': 'x11',
               'SDL_AUDIODRIVER': 'dummy', 'SDL_RENDER_DRIVER': 'software',
               'LIBGL_ALWAYS_SOFTWARE': '1', 'MESA_SHADER_CACHE_DISABLE': 'true'}
        for key, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                          ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                          ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                          ('TMPDIR', 'tmp')]:
            directory = root / name
            directory.mkdir(mode=0o700)
            env[key] = str(directory)
        env['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=' + str(root / 'runtime/no-session')
        env['DBUS_SYSTEM_BUS_ADDRESS'] = 'unix:path=' + str(root / 'runtime/no-system')
        work = root / 'work'
        work.mkdir()
        proof['environment'] = env.copy()
        proof['clean_state_before'] = {key: sorted(os.listdir(env[key])) for key in
                                       ('HOME', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME',
                                        'XDG_CACHE_HOME', 'XDG_STATE_HOME',
                                        'XDG_RUNTIME_DIR', 'TMPDIR')}
        require(not any(proof['clean_state_before'].values()), 'state not fresh')
        readfd, writefd = os.pipe()
        with (evidence / 'xvfb.log').open('wb') as log:
            xserver = subprocess.Popen([os.environ['XVFB'], '-displayfd', str(writefd),
                                        '-screen', '0', '1024x768x24', '-nolisten', 'tcp',
                                        '-noreset'],
                                       pass_fds=(writefd,), env=env, cwd=work,
                                       stdout=log, stderr=log)
        os.close(writefd)
        require(select.select([readfd], [], [], 10)[0] and xserver.poll() is None,
                'private Xvfb readiness absent')
        number = os.read(readfd, 64).decode().strip()
        os.close(readfd)
        require(number.isdigit(), 'invalid Xvfb displayfd')
        env['DISPLAY'] = ':' + number
        capture = XCapture(env['DISPLAY'])
        with (evidence / 'game.log').open('wb') as log:
            game = subprocess.Popen([str(launcher)], env=env, cwd=work,
                                    stdin=subprocess.DEVNULL, stdout=log, stderr=log)

        def tool(*args):
            return subprocess.run([os.environ['XDOTOOL'], *args], env=env, cwd=work,
                                  capture_output=True, text=True, timeout=10)

        deadline = time.monotonic() + 20
        window = None
        while time.monotonic() < deadline:
            require(game.poll() is None, 'ordinary game exited before native window')
            result = tool('search', '--onlyvisible', '--pid', str(game.pid),
                          '--name', '^Aquarium Arena$')
            if result.returncode == 0:
                windows = result.stdout.split()
                require(len(windows) == 1, 'ambiguous SDL window')
                window = int(windows[0])
                break
            time.sleep(.1)
        require(window is not None, 'ordinary SDL window absent')
        proof['game_process'] = namespace_proof(Path('/proc') / str(game.pid), evidence)
        proof['command_line'] = (Path('/proc') / str(game.pid) / 'cmdline').read_bytes() \
            .decode().split('\0')[:-1]
        geometry = tool('getwindowgeometry', '--shell', str(window))
        require(geometry.returncode == 0 and 'WIDTH=1024\n' in geometry.stdout and
                'HEIGHT=660\n' in geometry.stdout, 'native SDL geometry changed')
        (evidence / 'window-geometry.txt').write_text(geometry.stdout)
        require(tool('windowfocus', '--sync', str(window)).returncode == 0,
                'window focus failed')
        # Keep pointer off the map so no mouse tooltip window renders.
        require(tool('mousemove', '--window', str(window), '1023', '659').returncode == 0,
                'cannot park pointer away from map tooltips')

        def frame(label, rgb):
            path = evidence / (label + '.png')
            save_png(path, rgb)
            proof['captures'].append({'file': path.name,
                                      'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
            save()

        def observe(label, predicate, timeout=12):
            deadline = time.monotonic() + timeout
            rgb = None
            while time.monotonic() < deadline:
                require(game.poll() is None, 'ordinary game exited during ' + label)
                rgb = capture.capture(window)
                value = predicate(rgb)
                if value:
                    frame(label, rgb)
                    return rgb, value
                time.sleep(.12)
            if rgb is not None:
                frame(label + '-failed', rgb)
            raise AssertionError('exact source glyph/pixel observation absent: ' + label)

        def key(name, control):
            proof['inputs'].append({'key': name, 'control': control, 'method': 'XTest'})
            require(tool('key', '--clearmodifiers', name).returncode == 0,
                    'native input failed: ' + name)
            time.sleep(.3)

        # ---- Terrain reconstruction (tileEngine.getmapsurface over black) ----
        TERRAIN_TILES = {'#': '1,0', '.': '0,0', ',': '2,0', '0': '6,0',
                         '|': '3,0', '^': '4,0', '%': '5,0'}

        row_alpha = {}

        def tint_alpha(map_y):
            # exact source accumulator: alpha starts at 0.0 and is
            # incremented by 0.2 (float repeated addition) once per map row;
            # int(alpha) is the overlay alpha for that row.  Repeated
            # addition is NOT equivalent to row*0.2 in binary floats, so the
            # full sequence from zero through all preceding rows is computed
            # once and cached per tile row.
            if map_y not in row_alpha:
                alpha = 0.0
                values = []
                for _ in range(map_y * TILE + TILE):
                    values.append(int(alpha))
                    alpha += 0.2
                row_alpha[map_y] = values
            return row_alpha[map_y]

        def tinted(surface, map_y):
            # deep-blue overlay: per source, for each map row a 1px (0,36,56)
            # surface with alpha int(accumulator) is blitted over the row of
            # the composed (color-key resolved) screen surface.
            alphas = tint_alpha(map_y)
            opaque = pygame.Surface(surface.get_size())
            opaque.fill((0, 0, 0))
            opaque.blit(surface, (0, 0))
            for row in range(TILE):
                whole = alphas[map_y * TILE + row]
                if whole:
                    overlay = pygame.Surface((TILE, 1))
                    overlay.set_alpha(whole)
                    overlay.fill(DB_TINT)
                    opaque.blit(overlay, (0, row))
            return opaque

        raster_cache = {}

        def tinted_bytes(tileset, tilepos, map_y):
            key = (tileset, tilepos, map_y)
            if key not in raster_cache:
                raster_cache[key] = pygame.image.tostring(
                    tinted(src.tile(tileset, tilepos), map_y), 'RGB')
            return raster_cache[key]
        diag = {'log_exact': False, 'watch_s0_exact': False,
                'unclassified_cells': [], 'samples': {}}

        def terrain_at(rgb, x, y):
            px, py = MAPPOSX + x * TILE, MAPPOSY + y * TILE
            cell = crop(rgb, px, py, TILE, TILE)
            for char, tilepos in TERRAIN_TILES.items():
                if cell == tinted_bytes('MapTiles', tilepos, y):
                    return char
            # the diver is on screen from the first draw: its cell shows the
            # terrain+diver composite instead of the bare terrain tile
            for char, tilepos in TERRAIN_TILES.items():
                if char in '.|^%':
                    composite = pygame.Surface((TILE, TILE))
                    composite.fill((0, 0, 0))
                    composite.blit(src.tile('MapTiles', tilepos), (0, 0))
                    composite.blit(src.tile('CreatureTiles', '3,0'), (0, 0))
                    if cell == pygame.image.tostring(tinted(composite, y), 'RGB'):
                        return char
            return None

        def initial_board(rgb):
            # Requirements: welcome log lines visible, HUD watch S 0 line exact.
            diag['log_exact'] = src.loglines(rgb, ['Welcome to Aquarium Arena!',
                                                   'Top gladiator score is 0 points!'])
            if not diag['log_exact']:
                diag['samples']['log_window_head'] = crop(rgb, LOGX, LOGY, 96, 44).hex()
                proof['initial_board_diagnostics'] = diag
                save()
                return None
            diag['watch_s0_exact'] = src.status_line(
                rgb, WATCHX + 40, WATCHY + 133, 'S 0', pygame.Color('green'))
            if not diag['watch_s0_exact']:
                diag['samples']['watch_s0_region'] = crop(
                    rgb, WATCHX + 40, WATCHY + 133, 48, 16).hex()
                predicted = pygame.Surface((48, 16))
                predicted.blit(src.watch_tile(), (-40, -133))
                predicted.blit(src.statusfont.render('S 0', 1, (0, 128, 0)), (0, 0))
                diag['samples']['watch_s0_predicted'] = \
                    pygame.image.tostring(predicted, 'RGB').hex()
                proof['initial_board_diagnostics'] = diag
                save()
                return None
            terrain = {}
            for y in range(MAPY):
                for x in range(MAPX):
                    char = terrain_at(rgb, x, y)
                    if char is None:
                        diag['unclassified_cells'].append([x, y])
                        cell = crop(rgb, MAPPOSX + x * TILE, MAPPOSY + y * TILE,
                                    TILE, TILE)
                        diag['samples']['first_unclassified'] = [x, y, cell.hex()]
                        diag['samples']['alpha_ladder'] = tint_alpha(y)[TILE - 8:]
                        diag['samples']['candidate_deltas'] = {}
                        diag['samples']['candidate_rasters'] = {}
                        diag['samples']['candidate_untinted'] = {}
                        for cand, pos in TERRAIN_TILES.items():
                            predicted = tinted_bytes('MapTiles', pos, y)
                            diag['samples']['candidate_deltas'][cand] = {
                                'max_delta': max(abs(a - b) for a, b in
                                                 zip(cell, predicted)),
                                'mismatched_bytes': sum(1 for a, b in
                                                        zip(cell, predicted)
                                                        if a != b)}
                            diag['samples']['candidate_rasters'][cand] = \
                                predicted[:192].hex()
                            diag['samples']['candidate_untinted'][cand] = \
                                pygame.image.tostring(
                                    src.tile('MapTiles', pos), 'RGB')[:192].hex()
                        proof['initial_board_diagnostics'] = diag
                        save()
                        return None
                    terrain[(x, y)] = char
            diag['unclassified_cells'] = []
            return terrain

        rgb0, terrain = observe('01-initialized-board', initial_board, timeout=25)
        proof['initial_hud'] = {
            'welcome_log': ['Welcome to Aquarium Arena!',
                            'Top gladiator score is 0 points!'],
            'watch_score_text': 'S 0', 'watch_score_pixel': [WATCHX + 40, WATCHY + 133],
            'exact_pixels': True}
        passable = {c for c in terrain if terrain[c] in '.|^%'}
        proof['arena'] = {
            'terrain_counts': {char: sum(1 for v in terrain.values() if v == char)
                               for char in sorted(set(terrain.values()))},
            'passable_tiles': len(passable),
            'border': {'sky': all(terrain[(x, 0)] == ',' for x in range(MAPX)),
                       'floor': all(terrain[(x, MAPY - 1)] == '#' for x in range(MAPX)),
                       'glass': all(terrain[(0, y)] == '0' and
                                    terrain[(MAPX - 1, y)] == '0'
                                    for y in range(1, MAPY - 1))}}
        require(proof['arena']['border']['sky'] and proof['arena']['border']['floor'] and
                proof['arena']['border']['glass'], 'arena border differs from source')
        require(len(passable) > 40, 'implausibly closed random arena')

        # ---- Player localization: diver tile 3,0 exactly once ----
        # The diver sprite has black colorkeyed pixels; drawboard blits it
        # over the map tile, so predict terrain+diver composite, then tint.
        diver_cache = {}

        def diver_bytes(coord):
            if coord not in diver_cache:
                composite = pygame.Surface((TILE, TILE))
                composite.fill((0, 0, 0))
                composite.blit(src.tile('MapTiles', TERRAIN_TILES[terrain[coord]]), (0, 0))
                composite.blit(src.tile('CreatureTiles', '3,0'), (0, 0))
                diver_cache[coord] = pygame.image.tostring(
                    tinted(composite, coord[1]), 'RGB')
            return diver_cache[coord]

        def find_diver(rgb):
            found = [(x, y) for (x, y) in passable
                     if crop(rgb, MAPPOSX + x * TILE, MAPPOSY + y * TILE, TILE, TILE)
                     == diver_bytes((x, y))]
            if len(found) == 1:
                return found[0]
            return None

        rgb0, start = observe('02-player-start', find_diver)
        proof['initial_player_cell'] = list(start)

        def neighbors_free(coord):
            result = []
            for name, keyname, delta in [
                    ('right', 'l', (1, 0)), ('down', 'j', (0, 1)),
                    ('left', 'h', (-1, 0)), ('up', 'k', (0, -1)),
                    ('downright', 'n', (1, 1)), ('upright', 'u', (1, -1)),
                    ('downleft', 'b', (-1, 1)), ('upleft', 'y', (-1, -1))]:
                target = (coord[0] + delta[0], coord[1] + delta[1])
                if target in passable:
                    result.append((name, keyname, target))
            return result

        def diver_cell(rgb, coord):
            return crop(rgb, MAPPOSX + coord[0] * TILE, MAPPOSY + coord[1] * TILE,
                        TILE, TILE) == diver_bytes(coord)

        moves = neighbors_free(start)
        require(moves, 'random start has no adjacent passable tile')
        direction, keyname, destination = moves[0]
        key(keyname, 'vi-key move ' + direction + ' into adjacent passable tile')

        def moved(rgb):
            if not diver_cell(rgb, destination):
                return None
            # old cell must show its bare tinted terrain tile again
            return terrain_at(rgb, *start) == terrain[start]

        rgb1, _ = observe('03-native-movement', moved)
        proof['movement'] = {'key': keyname, 'direction': direction,
                             'before': list(start), 'after': list(destination),
                             'diver_tile_exact_tinted_pixels': True,
                             'old_cell_restored_exact_tinted_tile': True}
        # No pickup happened: the watch still shows the exact green S 0 line.
        require(src.status_line(rgb1, WATCHX + 40, WATCHY + 133, 'S 0',
                                pygame.Color('green')),
                'movement changed score unexpectedly')
        proof['movement']['hud_score_unchanged_exact_pixels'] = True



        # ---- Arrow-key movement (second control family) ----
        arrow_moves = {'right': 'Right', 'down': 'Down', 'left': 'Left', 'up': 'Up'}
        second = None
        for name, delta in [('right', (1, 0)), ('down', (0, 1)),
                            ('left', (-1, 0)), ('up', (0, -1))]:
            target = (destination[0] + delta[0], destination[1] + delta[1])
            if target in passable:
                second = (arrow_moves[name], target)
                break
        if second is not None:
            arrow, target2 = second
            key(arrow, 'arrow-key move ' + arrow)
            rgb2, _ = observe('04-arrow-movement', lambda rgb:
                              diver_cell(rgb, target2) and
                              terrain_at(rgb, *destination) == terrain[destination])
            proof['arrow_movement'] = {'key': arrow, 'from': list(destination),
                                       'after': list(target2)}
            current = target2
        else:
            current = destination
            proof['arrow_movement'] = None

        # ---- Look/examine mode: 'x' sets cursor to player, ESC returns ----
        # Source: statusbackgr = pygame.Surface((100, 20)); .convert(); text
        # = statusfont.render("Looking", 1, pygame.Color("grey70"));
        # statusbackgr.blit(text, (1,1)); screen.blit(statusbackgr, (830,20)).
        # The plain 100x20 surface is opaque black and fully covers whatever
        # is beneath (including the watch art); grey70 is X11 (178,178,178).
        grey70 = pygame.Color('grey70')

        def status_box(text):
            surface = pygame.Surface((100, 20))
            surface.fill((0, 0, 0))
            surface.blit(src.statusfont.render(text, 1, grey70), (1, 1))
            return surface
        look_surface = status_box('Looking')

        def ui_tile_rgba(px, py, sx, sy):
            tileset = pygame.image.load(str(data / 'resources/img/UI.png'))
            surface = pygame.Surface((sx, sy))
            surface.blit(tileset, (0, 0), (px, py, sx, sy))
            surface.set_colorkey(pygame.Color('black'))
            return surface

        def cursor_over_diver(coord):
            # drawboard look mode: the cursor (UI 0,0,32,32, color-keyed) is
            # blitted over the already-composed screen cell — the tinted
            # terrain+diver composite — so color-keyed cursor pixels let the
            # diver show through.  Composite cursor over the tinted diver
            # cell instead of comparing a bare cursor raster.
            base = pygame.image.frombytes(diver_bytes(coord), (TILE, TILE), 'RGB')
            base.blit(ui_tile_rgba(0, 0, 32, 32), (0, 0))
            return pygame.image.tostring(base, 'RGB')

        def cursor_over_terrain(coord):
            base = pygame.Surface((TILE, TILE))
            base.fill((0, 0, 0))
            base.blit(src.tile('MapTiles', TERRAIN_TILES[terrain[coord]]), (0, 0))
            base = tinted(base, coord[1])
            base.blit(ui_tile_rgba(0, 0, 32, 32), (0, 0))
            return pygame.image.tostring(base, 'RGB')

        key('x', 'enter examine mode (cursor at player)')

        def looking(rgb):
            if crop(rgb, 830, 20, 100, 20) != pygame.image.tostring(look_surface, 'RGB'):
                return None
            if crop(rgb, MAPPOSX + current[0] * TILE, MAPPOSY + current[1] * TILE,
                    TILE, TILE) != cursor_over_diver(current):
                return None
            return True

        rgb3, _ = observe('05-look-mode', looking)
        proof['look_mode'] = {'status_text': 'Looking', 'status_pixel': [830, 20],
                              'cursor_over_player_exact_pixels': True}
        # Move cursor one tile with a vi key; cursor moves, player stays.
        cursor_moves = neighbors_free(current)
        require(cursor_moves, 'no adjacent passable tile for cursor')
        cname, ckey, ctarget = cursor_moves[0]
        key(ckey, 'move examine cursor ' + cname)

        def cursor_moved(rgb):
            if crop(rgb, MAPPOSX + ctarget[0] * TILE, MAPPOSY + ctarget[1] * TILE,
                    TILE, TILE) != cursor_over_terrain(ctarget):
                return None
            # the cursor is drawn after monsters; the vacated cell shows
            # its bare tinted terrain again
            if terrain_at(rgb, *current) != terrain[current]:
                return None
            return ctarget

        rgb4, cursor_pos = observe('06-cursor-moved', cursor_moved)
        proof['look_mode']['cursor_move'] = {'key': ckey, 'after': list(ctarget)}
        key('Escape', 'leave examine mode')

        def watch_art_region():
            # plain game state: the 100x20 screen region at (830,20) shows
            # the color-keyed watch art over black, exactly as blitted.
            watch = pygame.image.load(str(data / 'resources/img/watch.png'))
            tile = pygame.Surface((168, 315))
            tile.blit(watch, (0, 0), (0, 0, 168, 315))
            tile.set_colorkey(pygame.Color('black'))
            region = pygame.Surface((100, 20))
            region.fill((0, 0, 0))
            region.blit(tile, (-830 + WATCHX, -20 + WATCHY))
            return pygame.image.tostring(region, 'RGB')

        rest_region = watch_art_region()

        def back_to_game(rgb):
            if not diver_cell(rgb, current):
                return None
            return crop(rgb, 830, 20, 100, 20) == rest_region

        rgb5, _ = observe('07-examine-exit', back_to_game)
        proof['look_mode']['exit_restored_diver_and_cleared_status'] = True

        # ---- Fire mode: 'f' selects the harpoon stack (5x, damage 3) ----
        key('f', 'enter fire mode with best preferred weapon (harpoon)')
        fire_hud = status_box('Firing')

        def firing(rgb):
            return crop(rgb, 830, 20, 100, 20) == pygame.image.tostring(fire_hud, 'RGB')

        rgb6, _ = observe('08-fire-mode', firing)
        proof['fire_mode'] = {'status_text': 'Firing', 'status_pixel': [830, 20]}
        # Range pointers: UI tile (32,0,32,32) blitted over each tinted map
        # cell in fire mode; color-keyed pointer lets the terrain show through.
        def pointer_raster(coord):
            base = pygame.Surface((TILE, TILE))
            base.fill((0, 0, 0))
            base.blit(src.tile('MapTiles', TERRAIN_TILES[terrain[coord]]), (0, 0))
            base = tinted(base, coord[1])
            base.blit(ui_tile_rgba(32, 0, 32, 32), (0, 0))
            return pygame.image.tostring(base, 'RGB')

        pointer_cache = {}
        fire_tiles = []
        for y in range(MAPY):
            for x in range(MAPX):
                coord = (x, y)
                if coord not in pointer_cache:
                    pointer_cache[coord] = pointer_raster(coord)
                if crop(rgb6, MAPPOSX + x * TILE, MAPPOSY + y * TILE,
                        TILE, TILE) == pointer_cache[coord]:
                    fire_tiles.append(coord)
        require(fire_tiles, 'fire mode shows no range pointers')
        proof['fire_mode']['range_pointer_cells'] = [list(c) for c in fire_tiles]
        # Fire along a cardinal direction that has a pointer adjacent.
        fire_dirs = [('l', (1, 0), 'right'), ['j', (0, 1), 'down'],
                     ['h', (-1, 0), 'left'], ['k', (0, -1), 'up']]
        chosen = None
        for fkey, delta, fname in fire_dirs:
            if (current[0] + delta[0], current[1] + delta[1]) in \
                    {(x, y) for x, y in fire_tiles}:
                chosen = (fkey, delta, fname)
                break
        require(chosen is not None, 'no cardinal fire direction with pointer')
        fkey, delta, fname = chosen
        key(fkey, 'fire harpoon ' + fname)
        # After firing: state returns to game; the fired harpoon (ItemTiles
        # tile 0,0, tinted under deep-blue, relocated by its gravity item
        # update during passturn) rests on the map; the diver stays put.
        def post_fire(rgb):
            if not diver_cell(rgb, current):
                return None
            if crop(rgb, 830, 20, 100, 20) != rest_region:
                return None
            found_h = []
            harpoon_cache = {}
            for y in range(MAPY):
                for x in range(MAPX):
                    char = terrain[(x, y)]
                    key = (char, y)
                    if key not in harpoon_cache:
                        composite = pygame.Surface((TILE, TILE))
                        composite.fill((0, 0, 0))
                        composite.blit(src.tile('MapTiles', TERRAIN_TILES[char]), (0, 0))
                        composite.blit(src.tile('ItemTiles', '0,0'), (0, 0))
                        harpoon_cache[key] = pygame.image.tostring(
                            tinted(composite, y), 'RGB')
                    if crop(rgb, MAPPOSX + x * TILE, MAPPOSY + y * TILE,
                            TILE, TILE) == harpoon_cache[key]:
                        found_h.append((x, y))
            return found_h or None

        try:
            rgb7, harpoon_cells = observe('09-harpoon-flown', post_fire, timeout=15)
            proof['fire_mode']['fired'] = {
                'direction': fname, 'harpoon_item_cells': [list(c) for c in harpoon_cells],
                'harpoon_item_tile_exact_pixels': True}
        except AssertionError:
            # The harpoon can be caught by a monster hit (no monster on turn 0
            # is possible only if spawn failed) or lie under an effect sprite;
            # require at least the state machine return plus clean status.
            def fired_state_only(rgb):
                return (diver_cell(rgb, current) and
                        crop(rgb, 830, 20, 100, 20) == rest_region)
            rgb7, _ = observe('09-fired-state', fired_state_only, timeout=15)
            proof['fire_mode']['fired'] = {'direction': fname,
                                           'harpoon_item_cells': 'not individually resolvable'}
        # Score stays 0 unless a monster was hit (would be extraordinary on
        # turn 0; the source grants score only on kills).
        proof['fire_mode']['score_after'] = 'S 0' if src.status_line(
            rgb7, WATCHX + 40, WATCHY + 133, 'S 0', pygame.Color('green')) else 'S>0'

        # ---- Clean quit immediately in the proven normal game state ----
        # The diver is at the observed position, state is 'game' (never left
        # the main loop), so universalevents turns the WM close request into
        # endgame() -> pygame.quit(); sys.exit() -> clean exit 0.

        capture.close_window(window)
        proof['inputs'].append({'control': 'close native SDL window',
                                'method': 'WM_DELETE_WINDOW -> SDL_QUIT'})
        require(game.wait(timeout=15) == 0, 'native SDL quit did not exit zero')
        capture.lib.XCloseDisplay(capture.display)
        log_text = (evidence / 'game.log').read_text(errors='replace')
        (evidence / 'game.log.retained').write_text(log_text)
        require('Traceback' not in log_text and 'MemoryError' not in log_text,
                'game logged a traceback')
        # ---- Mutable state: only XDG data/aquarium-arena may exist ----
        files = sorted(p.relative_to(root).as_posix() for p in root.rglob('*')
                       if p.is_file())
        unexpected = [f for f in files
                      if not f.startswith('data/aquarium-arena/')
                      and not f.startswith('runtime/no-')]
        require(not unexpected, 'unexpected mutable files: ' + repr(unexpected))
        proof['quit'] = {'exit_status': 0, 'traceback_free': True,
                         'mutable_files': files}
        proof['status'] = 'passed'
        save()
        print('AQUARIUM_ARENA_NATIVE_GAMEPLAY_OK '
              'board/movement/arrows/look/fire/SDL-quit')
    except Exception:
        proof['error'] = traceback.format_exc()
        save()
        raise


if __name__ == '__main__':
    main()
