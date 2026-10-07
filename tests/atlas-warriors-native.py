#!/usr/bin/env python3
"""External consumer of ordinary Atlas Warriors alpha-009 SDL gameplay.

Oracle: pinned d5354adbe29884016aec2867c9ded52d15f9fcd1 src/rl.py,
mainmenu.py, pygcurse.py, character.py, player_character.py, map.py,
tutorial.py and messageBox.py. Only installed font files are opened for
reference rasterization, with the launcher's exact Pygame dependency. No game
module is imported, patched or evaluated; no state is seeded; no pygame event
is posted. XTest keys and a WM_DELETE_WINDOW request enter the real SDL loop.
Font rasters are compared byte-for-byte with XGetImage pixels, never OCR.
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

COMMIT = 'd5354adbe29884016aec2867c9ded52d15f9fcd1'
WIDTH, HEIGHT = 520, 648


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
        require(value == os.readlink('/proc/self/ns/' + kind), 'game escaped ' + kind)
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
        result = subprocess.run(command, capture_output=True, text=True, timeout=10)
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
    for target in sorted({item[0] for item in entries()[1]}, key=len, reverse=True):
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    require(found and all('ro' in options and 'rw' not in options and not
                         any(x.startswith(('shared:', 'master:')) for x in optional)
                         for _, options, optional in found), 'store is not private/read-only')
    (evidence / 'mountinfo-after.txt').write_text(text)
    # Preserve the only writable host bind outside /tmp before overlaying it.
    # Log the relocation through the open directory FD: /run may itself hide
    # the original evidence path, just as /tmp does for typical callers.
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        evidence = Path('/proc/' + str(os.getpid()) + '/fd/' + str(descriptor))
        mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/run')
        retained = Path('/run/atlas-evidence')
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


class Glyphs:
    def __init__(self, pygame, data):
        self.pg = pygame
        self.mono = pygame.font.Font(str(data / 'DejaVuSansMono.ttf'), 20)
        self.serif = pygame.font.Font(str(data / 'DejaVuSerif.ttf'), 20)
        self.body = pygame.font.Font(str(data / 'DejaVuSerif.ttf'), 14)
        sizes = [self.mono.render(chr(code), True, (0, 0, 0)).get_size()
                 for code in range(32, 127)]
        self.cw = max(size[0] for size in sizes)
        self.ch = max(size[1] for size in sizes)
        require(self.cw * 40 <= WIDTH and self.ch * 27 <= HEIGHT,
                'source grid does not fit native window')

    def raster(self, font, text, color, background=(0, 0, 0)):
        glyph = font.render(text, True, color)
        reference = self.pg.Surface(glyph.get_size(), depth=32)
        reference.fill(background)
        reference.blit(glyph, (0, 0))
        return glyph.get_size(), self.pg.image.tostring(reference, 'RGB')

    def line(self, rgb, font, text, x, y, color=(255, 255, 255), background=(0, 0, 0)):
        (width, height), reference = self.raster(font, text, color, background)
        return crop(rgb, x, y, width, height) == reference

    def cell(self, char, color):
        # rl.py's game PygcurseSurface(shadow=True): render shadow+glyph
        # into RGBA intermediate, then blit that layer to black game surface.
        layer = self.pg.Surface((self.cw, self.ch), self.pg.SRCALPHA, 32)
        layer.fill((0, 0, 0, 0))
        glyph = self.mono.render(char, True, color)
        rect = glyph.get_rect()
        rect.centerx, rect.bottom = self.cw // 2, self.ch
        layer.blit(self.mono.render(char, True, (0, 0, 0)), rect.move(1, 2))
        layer.blit(glyph, rect)
        reference = self.pg.Surface((self.cw, self.ch), depth=32)
        reference.fill((0, 0, 0))
        reference.blit(layer, (0, 0))
        return self.pg.image.tostring(reference, 'RGB')

    def cells(self, rgb, text, col, row, color):
        return all(crop(rgb, (col + i) * self.cw, row * self.ch, self.cw, self.ch) ==
                   self.cell(char, color) for i, char in enumerate(text))

    def selected_menu(self, rgb):
        # mainmenu redraws putchars(bgcolor=None) onto a transparent Pygcurse
        # surface, repeatedly blitting to the uncleared opaque game surface.
        # Edge intensity accumulates, but exact glyph alpha support, zero
        # background/channels and solid red255 pixels are frame-invariant.
        text = 'Start Easiest Game'
        mask = self.pg.Surface((len(text) * self.cw, self.ch), self.pg.SRCALPHA, 32)
        mask.fill((0, 0, 0, 0))
        for i, char in enumerate(text):
            glyph = self.mono.render(char, True, (255, 0, 0))
            rect = glyph.get_rect()
            rect.centerx, rect.bottom = i * self.cw + self.cw // 2, self.ch
            mask.blit(glyph, rect)
        alpha = self.pg.image.tostring(mask, 'RGBA')[3::4]
        actual = crop(rgb, 2 * self.cw, 10 * self.ch, len(text) * self.cw, self.ch)
        red = actual[0::3]
        return (not any(actual[1::3]) and not any(actual[2::3]) and
                all((coverage != 0) == (value != 0) and
                    (coverage != 255 or value == 255)
                    for coverage, value in zip(alpha, red)))

    def skills_button(self, rgb):
        # rl.py draws black/blue outlined 9-cell-wide rectangle before the
        # directly blitted white font. Include the entire source rectangle,
        # including its border, rather than masking discrepant pixels.
        reference = self.pg.Surface((9 * self.cw, self.ch), depth=32)
        reference.fill((0, 0, 0))
        self.pg.draw.rect(reference, (0, 0, 255), (0, 0, 9 * self.cw, 26 * self.ch), 1)
        reference.blit(self.mono.render('  Skills  ', True, (255, 255, 255)), (0, 0))
        return (crop(rgb, 18 * self.cw, 26 * self.ch, 9 * self.cw, self.ch) ==
                self.pg.image.tostring(reference, 'RGB'))

    def avatar(self, rgb):
        reference = self.cell('@', (192, 192, 192))
        found = [(x, y) for y in range(20) for x in range(40)
                 if crop(rgb, x * self.cw, y * self.ch, self.cw, self.ch) == reference]
        require(len(found) == 1, 'expected exactly one source silver @ player: ' + repr(found))
        return found[0]

    def floor(self, rgb, x, y):
        # map.HackAwayGenerator uses exact randint(52-level*2,64)
        # grayscale for walkable '.', not Cell's generic silver default.
        # This new game's map level is zero: enumerate its finite palette.
        actual = crop(rgb, x * self.cw, y * self.ch, self.cw, self.ch)
        matches = [brightness for brightness in range(52, 65)
                   if actual == self.cell('.', (brightness,) * 3)]
        return matches[0] if len(matches) == 1 else None

    def tutorial_line(self, rgb, text):
        # messageBox.py: left=(520-400)/2; body blit at left+10;
        # gray32 opaque background and DejaVuSerif14 white antialiased text.
        # Source truncline algorithm gives the first displayed line at width380.
        original, candidate, cut, splits = text, text, 0, 0
        while self.body.size(candidate)[0] > 380:
            splits += 1
            prefix = original.rsplit(None, splits)[0]
            if candidate == prefix:
                cut += 1
                candidate = prefix[:-cut]
            else:
                candidate = prefix
        candidate = candidate.strip()
        positions = [y for y in range(HEIGHT - self.body.get_height())
                     if self.line(rgb, self.body, candidate, 70, y,
                                  background=(32, 32, 32))]
        return {'text': candidate, 'x': 70, 'y': positions[0]} if len(positions) == 1 else None


def main():
    output, evidence = map(Path, sys.argv[1:])
    proof = {'status': 'failed', 'source_commit': COMMIT, 'inputs': [], 'captures': [],
             'source': ['https://github.com/lkingsford/AtlasWarriors/blob/' + COMMIT + '/src/' + name
                        for name in ('rl.py', 'mainmenu.py', 'pygcurse.py', 'character.py',
                                     'player_character.py', 'map.py', 'tutorial.py', 'messageBox.py')],
             'limits': ['Normal Easiest gameplay, menu, six real first-run dialogs, one movement '
                        'and SDL clean quit only; no save/load API, audio, combat or winning claim.']}

    def save():
        write_json(evidence / 'runtime.json', proof)
        write_json(evidence / 'evidence.json', proof)

    try:
        require(output.parent == Path('/gnu/store') and output.resolve() == output,
                'OUTPUT must be canonical direct store item')
        launcher = output / 'bin/atlas-warriors'
        data = output / 'share/atlas-warriors'
        launch_text = launcher.read_text()
        require(os.access(launcher, os.X_OK), 'ordinary launcher absent')
        for name in ['rl.py', 'items.xml', 'DejaVuSans.ttf', 'DejaVuSansMono.ttf', 'DejaVuSerif.ttf',
                     *['assets/back_level_' + str(i) + '.png' for i in range(4)]]:
            require((data / name).is_file(), 'missing runtime data: ' + name)
        for path in [output, *output.rglob('*')]:
            mode = path.lstat().st_mode
            if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
                require(not mode & 0o222, 'writable store member: ' + str(path))
        # Only the launcher's pinned external Pygame dependency is imported to
        # rasterize reference glyphs; never import any installed game code.
        match = re.search(r'^export PYTHONPATH=(/gnu/store/[^\n]+/site-packages)$', launch_text, re.M)
        require(match, 'cannot resolve launchers exact Pygame font rasterizer')
        sys.path.insert(0, match[1])
        import pygame
        pygame.font.init()
        glyphs = Glyphs(pygame, data)
        proof['font_oracle'] = {'pygame_path': match[1], 'cell_size': [glyphs.cw, glyphs.ch],
                                'fonts': {name: hashlib.sha256((data / name).read_bytes()).hexdigest()
                                          for name in ('DejaVuSansMono.ttf', 'DejaVuSerif.ttf')}}
        proof['isolation'] = namespace_proof(Path('/proc/self'), evidence)
        evidence, store = mount_readonly(evidence)
        proof['isolation'].update(store)
        # evidence now resolves outside /tmp; all later diagnostics survive
        # the private tmpfs overlay, including failures during that mount.
        command = [os.environ['MOUNT'], '-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/tmp']
        mounted = subprocess.run(command, capture_output=True, text=True, timeout=10)
        write_json(evidence / 'tmp-mount.json', {'command': command,
                   'returncode': mounted.returncode, 'stdout': mounted.stdout, 'stderr': mounted.stderr})
        require(mounted.returncode == 0, 'private /tmp mount failed: ' + mounted.stderr)
        os.chmod('/tmp', 0o1777)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
        root = Path('/tmp/atlas-state')
        root.mkdir(mode=0o700)
        env = {'PATH': '', 'LC_ALL': 'C.UTF-8', 'SDL_VIDEODRIVER': 'x11',
               'SDL_AUDIODRIVER': 'dummy', 'SDL_RENDER_DRIVER': 'software',
               'LIBGL_ALWAYS_SOFTWARE': '1', 'MESA_SHADER_CACHE_DISABLE': 'true'}
        for key, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                          ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                          ('XDG_RUNTIME_DIR', 'runtime'), ('TMPDIR', 'tmp')]:
            directory = root / name
            directory.mkdir(mode=0o700)
            env[key] = str(directory)
        env['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=' + str(root / 'runtime/no-session')
        env['DBUS_SYSTEM_BUS_ADDRESS'] = 'unix:path=' + str(root / 'runtime/no-system')
        work = root / 'work'
        work.mkdir()
        proof['environment'] = env.copy()
        proof['clean_state_before'] = {key: sorted(os.listdir(env[key])) for key in
                                       ('HOME', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME',
                                        'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'TMPDIR')}
        require(not any(proof['clean_state_before'].values()), 'state not fresh')
        readfd, writefd = os.pipe()
        with (evidence / 'xvfb.log').open('wb') as log:
            xserver = subprocess.Popen([os.environ['XVFB'], '-displayfd', str(writefd), '-screen', '0',
                                        '1024x768x24', '-nolisten', 'tcp', '-noreset'],
                                       pass_fds=(writefd,), env=env, cwd=work, stdout=log, stderr=log)
        os.close(writefd)
        require(select.select([readfd], [], [], 10)[0] and xserver.poll() is None,
                'private Xvfb readiness absent')
        number = os.read(readfd, 64).decode().strip()
        os.close(readfd)
        require(number.isdigit(), 'invalid Xvfb displayfd')
        env['DISPLAY'] = ':' + number
        capture = XCapture(env['DISPLAY'])
        with (evidence / 'game.log').open('wb') as log:
            game = subprocess.Popen([str(launcher)], env=env, cwd=work, stdin=subprocess.DEVNULL,
                                    stdout=log, stderr=log)

        def tool(*args):
            return subprocess.run([os.environ['XDOTOOL'], *args], env=env, cwd=work,
                                  capture_output=True, text=True, timeout=10)

        deadline = time.monotonic() + 15
        window = None
        while time.monotonic() < deadline:
            require(game.poll() is None, 'ordinary game exited before native window')
            result = tool('search', '--onlyvisible', '--pid', str(game.pid), '--name', '^Atlas Warriors$')
            if result.returncode == 0:
                windows = result.stdout.split()
                require(len(windows) == 1, 'ambiguous SDL window')
                window = int(windows[0])
                break
            time.sleep(.1)
        require(window is not None, 'ordinary SDL window absent')
        proof['game_process'] = namespace_proof(Path('/proc') / str(game.pid), evidence)
        proof['command_line'] = (Path('/proc') / str(game.pid) / 'cmdline').read_bytes().decode().split('\0')[:-1]
        geometry = tool('getwindowgeometry', '--shell', str(window))
        require(geometry.returncode == 0 and 'WIDTH=520\n' in geometry.stdout and
                'HEIGHT=648\n' in geometry.stdout, 'native SDL geometry changed')
        (evidence / 'window-geometry.txt').write_text(geometry.stdout)
        require(tool('windowfocus', '--sync', str(window)).returncode == 0, 'window focus failed')
        require(tool('mousemove', '--window', str(window), '519', '647').returncode == 0,
                'cannot move pointer away from map tooltips')

        def frame(label, rgb):
            path = evidence / (label + '.png')
            save_png(path, rgb)
            proof['captures'].append({'file': path.name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
            save()

        def observe(label, predicate, timeout=10):
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                require(game.poll() is None, 'ordinary game exited during ' + label)
                rgb = capture.capture(window)
                value = predicate(rgb)
                if value:
                    frame(label, rgb)
                    return rgb, value
                time.sleep(.12)
            frame(label + '-failed', rgb)
            raise AssertionError('exact source glyph/pixel observation absent: ' + label)

        def key(name, control):
            proof['inputs'].append({'key': name, 'control': control, 'method': 'XTest'})
            require(tool('key', '--clearmodifiers', name).returncode == 0, 'native input failed')
            time.sleep(.25)  # tutorial queue removes one closed dialog on the next frame

        _, menu = observe('01-main-menu', glyphs.selected_menu)
        proof['menu'] = {'text': 'Start Easiest Game', 'cell': [2, 10], 'selected_color': [255, 0, 0],
                         'exact_alpha_support': bool(menu), 'exact_solid_foreground': True,
                         'exact_zero_background_green_blue': True}
        key('Return', 'start selected Easiest new game')
        tutorial_starts = [
            'Welcome to Atlas Warriors',
            'This game is still in Alpha and unfinished, but I really appreciate you playing it.',
            'You can move by using the arrows, or by using the numeric keypad.',
            'You currently have no weapons equipped. If you click on the Inventory button (or push',
            'By default, you pick up all items you walk over. You can change this by pushing',
            "That's all you should need for now. Good luck, and good hunting!"]
        proof['tutorial_dialogs'] = []
        for index, text in enumerate(tutorial_starts):
            _, line = observe('02-tutorial-' + str(index + 1), lambda rgb, text=text:
                              glyphs.tutorial_line(rgb, text), timeout=25 if index == 0 else 10)
            proof['tutorial_dialogs'].append(line)
            key('space', 'dismiss first-run tutorial ' + str(index + 1))
        hud = 'HP 10 (10)  Level 1 XP  0 (10)  Hit 3  Def 3'

        def initial_game(rgb):
            if not glyphs.line(rgb, glyphs.serif, hud, 3, 5 + glyphs.ch * 20):
                return None
            if not glyphs.skills_button(rgb):
                return None
            try:
                return glyphs.avatar(rgb)
            except AssertionError:
                return None

        before, start = observe('03-initialized-game', initial_game)
        proof['initial_hud'] = {'text': hud, 'pixel': [3, 5 + glyphs.ch * 20], 'exact_pixels': True}
        proof['initial_player_cell'] = list(start)
        # Pick a visible, exact source floor adjacent to the observed player.
        # This adapts only to the game's random map; no PRNG or map manipulation.
        choices = [('Right', 1, 0), ('Down', 0, 1), ('Left', -1, 0), ('Up', 0, -1)]
        floors = []
        for keyname, dx, dy in choices:
            x, y = start[0] + dx, start[1] + dy
            if 0 <= x < 40 and 0 <= y < 20:
                brightness = glyphs.floor(before, x, y)
                if brightness is not None:
                    floors.append((keyname, (x, y), brightness))
        require(floors, 'random start has no observed adjacent source floor')
        direction, destination, floor_brightness = floors[0]
        key(direction, 'move into observed adjacent floor')
        after, moved = observe('04-native-movement', lambda rgb:
                              glyphs.cells(rgb, '@', *destination, (192, 192, 192)) and
                              not glyphs.cells(rgb, '@', *start, (192, 192, 192)))
        require(glyphs.avatar(after) == destination, 'player delta differs from native arrow')
        # HP/level/XP remain observable even if an ordinary pickup adds messages.
        require(glyphs.line(after, glyphs.serif, 'HP 10 (10)  Level 1 XP  0 (10)',
                            3, 5 + glyphs.ch * 20), 'movement HUD changed unexpectedly')
        proof['movement'] = {'key': direction, 'before': list(start), 'after': list(destination),
                             'adjacent_floor_exact_pixels': True, 'silver_avatar_exact_pixels': True,
                             'floor_source_grayscale': floor_brightness,
                             'old_avatar_absent': True, 'hud_exact_pixels': True}
        capture.close_window(window)
        proof['inputs'].append({'control': 'close native SDL window',
                                'method': 'WM_DELETE_WINDOW -> SDL_QUIT'})
        require(game.wait(timeout=10) == 0, 'native SDL quit did not exit zero')
        capture.lib.XCloseDisplay(capture.display)
        log_text = (evidence / 'game.log').read_text()
        require(not any(word in log_text for word in ('Traceback', 'Error:', 'Exception', 'CRITICAL')),
                'game logged an exception despite its custom excepthook')
        state = Path(env['XDG_STATE_HOME']) / 'atlas-warriors'
        tutorial = json.loads((state / 'tutorial.json').read_text())
        require(tutorial['0'] is True and len(tutorial) == 17,
                'native close did not persist first-run tutorial state')
        error_log = (state / 'error.log').read_text()
        require(not any(word in error_log for word in ('CRITICAL', 'ERROR', 'Traceback', 'Exception')),
                'native game error log is not clean')
        retained_files = {}
        for name in ('tutorial.json', 'error.log'):
            content = (state / name).read_bytes()
            (evidence / name).write_bytes(content)
            retained_files[name] = hashlib.sha256(content).hexdigest()
        require(sorted(p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file()) ==
                ['state/atlas-warriors/error.log', 'state/atlas-warriors/tutorial.json'],
                'unexpected mutable application file outside XDG state')
        proof['quit'] = {'exit_status': 0, 'tutorial_first_run_seen': True,
                         'state_files': retained_files, 'exception_free': True}
        proof['status'] = 'passed'
        save()
        # Namespace init exit disposes only its own Xvfb and private tmpfs;
        # never signal host services or manipulate caller cleanup state.
        print('ATLAS_WARRIORS_NATIVE_GAMEPLAY_OK menu/newgame/tutorial/movement/HUD/SDL-quit')
    except Exception:
        proof['error'] = traceback.format_exc()
        save()
        raise


if __name__ == '__main__':
    main()
