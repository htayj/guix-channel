#!/usr/bin/env python3
"""Consume Richard D. Clark's 0.2 through the ordinary FreeBASIC X11 UI.

The installed original source and built-in 8x8 font are read-only pixel oracles,
never imported, executed or used to fabricate screenshots. XGetImage captures
native frames; xdotool without --window sends XTest keyboard events to focus.
Navigation learns only displayed terrain. There is no seed, game-state access,
save injection, debugger, hook, executor, headless game or proof renderer.
"""
from collections import deque
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

WIDTH, HEIGHT, TILE = 640, 480, 8
WHITE, GREEN, YELLOW = (255, 255, 255), (0, 255, 0), (255, 255, 0)
RED, TAN, GREY = (255, 0, 0), (210, 180, 140), (192, 192, 192)
ORANGE, BLUE, CYAN, GOLD = (255, 128, 0), (0, 0, 255), (0, 255, 255), (255, 215, 0)
DARK, ZOMBIE = (47, 79, 79), (255, 69, 0)
DIRECTIONS = [('Right', 1, 0), ('Down', 0, 1), ('Left', -1, 0), ('Up', 0, -1),
              ('3', 1, 1), ('1', -1, 1), ('7', -1, -1), ('9', 1, -1)]
SOURCE_HASHES = {
    'lab42.bas': 'e6367b5f5f349e982eeedd3cef0950208c90464199cb54c005a1a0f1fa153d60',
    'labdata.bi': '38a5b471474913e7f590cd9eec847c62578583dca83ef47a858fd22855a6c93b',
    'labutils.bi': '866403360ef1e30db67cf2457e4eb81aff90ce247b7b0adc1d6975e987802172',
    'labmap.bi': 'b7c7331acb66846e2c369536a5de6859a660fe6b3c138757db6c0d6b73cbb0d9',
    'labchar.bi': 'bf58a1837146148da45e82f09e8257314ffaf329fffd166df21e26fac9e702bb',
    '42title.bi': '54509b1e3614642e49261e5bbb3434741f7c487c5044816bd83bf6e9c8336d6f',
    'corridor.bi': '5abbd5f7d9e41a568412ea96fa3986b9c311a1658db7cbf2b96420a20f9bf7e3',
    'fnt08x08.fnt': 'fc1a3e0b12e7c68c18b63bb1df7e59163362b1023099bc32c4bdc6315c663610',
}


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
    dev, routes = (proc / 'net/dev').read_text(), (proc / 'net/route').read_text()
    interfaces = sorted(line.split(':')[0].strip() for line in dev.splitlines()[2:]
                        if ':' in line)
    require(interfaces == ['lo'] and len(routes.splitlines()) <= 1, 'network not isolated')
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
        source = '/proc/' + str(os.getpid()) + '/fd/' + str(descriptor)
        evidence = Path(source)
        mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/tmp')
        retained = Path('/tmp/lab42-evidence')
        retained.mkdir()
        mount('--bind', source, str(retained))
    finally:
        os.close(descriptor)
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
                ('XQueryTree', [C.c_void_p, C.c_ulong, C.POINTER(C.c_ulong),
                                C.POINTER(C.c_ulong), C.POINTER(C.POINTER(C.c_ulong)),
                                C.POINTER(C.c_uint)], C.c_int),
                ('XFree', [C.c_void_p], C.c_int),
                ('XCloseDisplay', [C.c_void_p], C.c_int)]:
            function = getattr(self.lib, name)
            function.argtypes, function.restype = args, result
        self.display = self.lib.XOpenDisplay(display.encode())
        require(self.display, 'cannot open private X display')

    def children(self, window):
        root, parent, count = C.c_ulong(), C.c_ulong(), C.c_uint()
        children = C.POINTER(C.c_ulong)()
        require(self.lib.XQueryTree(self.display, window, C.byref(root), C.byref(parent),
                                   C.byref(children), C.byref(count)), 'XQueryTree failed')
        try:
            return [children[index] for index in range(count.value)]
        finally:
            if children:
                self.lib.XFree(children)

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


class Oracle:
    def __init__(self, source):
        self.hashes = {}
        for name, expected in SOURCE_HASHES.items():
            actual = hashlib.sha256((source / name).read_bytes()).hexdigest()
            require(actual == expected, 'original oracle bytes changed: ' + name)
            self.hashes[name] = actual
        font = (source / 'fnt08x08.fnt').read_bytes()
        require(len(font) == 2048, 'wrong built-in font length')
        # gfx_drawstring.c tests 1 << px, so the font uses least-significant-bit first.
        self.masks = [int.from_bytes(font[i * 8:(i + 1) * 8], 'little') for i in range(256)]
        self.codes = {mask: char for char, mask in enumerate(self.masks) if mask}
        # Prefer the actual source's CP437 terrain and ASCII codes over any
        # visually identical unused extended glyphs.
        for char in [*range(33, 127), 10, 219, 249]:
            self.codes[self.masks[char]] = char
        self.title = self.array(source / '42title.bi')
        self.corridor = self.array(source / 'corridor.bi')
        self.title_samples = [i for i, color in enumerate(self.title)
                              if color != (0, 0, 0)][::13]
        require(len(self.title_samples) >= 50, 'source title oracle too small')

    @staticmethod
    def array(path):
        values = [int(value, 16) for value in re.findall(r'&h([0-9A-Fa-f]{8})', path.read_text())]
        require(len(values) == 4800, 'wrong source image array size: ' + str(path))
        return [((value >> 16) & 255, (value >> 8) & 255, value & 255) for value in values]

    def title_frame(self, rgb):
        # Check source array sample colors against one native fade step. Step 0 is still
        # distinguishable: AlphaBlend gives corridor-1 on title cells, exact corridor elsewhere.
        for alpha in range(256):
            matches = 0
            for index in self.title_samples:
                x, y = (index % 80) * 8 + 4, (index // 80) * 8 + 4
                offset = (y * WIDTH + x) * 3
                expected = bytes((fg * alpha + bg * (255 - alpha)) >> 8
                                 for fg, bg in zip(self.title[index], self.corridor[index]))
                if rgb[offset:offset + 3] == expected:
                    matches += 1
            if matches >= len(self.title_samples) * .98:
                return dict(alpha=alpha, matching_source_samples=matches)
        return None

    def mask(self, rgb, x, y, color):
        cell = crop(rgb, x * 8, y * 8, 8, 8)
        target = bytes(color)
        return sum(1 << i for i in range(64) if cell[i * 3:i * 3 + 3] == target)

    def text(self, rgb, x, y, text, color=WHITE):
        return all(self.mask(rgb, x + offset, y, color) == self.masks[ord(char)]
                   for offset, char in enumerate(text) if char != ' ')

    def line(self, rgb, x, y, length, color=WHITE):
        return ''.join(chr(self.codes.get(self.mask(rgb, x + offset, y, color), 32))
                       for offset in range(length)).rstrip()

    def tiles(self, rgb):
        cells = {}
        colors = {WHITE, GREEN, YELLOW, RED, TAN, GREY, ORANGE, BLUE, CYAN, GOLD, DARK, ZOMBIE}
        for y in range(55):
            for x in range(50):
                cell = crop(rgb, x * 8, y * 8, 8, 8)
                masks = {}
                for i in range(64):
                    color = tuple(cell[i * 3:i * 3 + 3])
                    if color in colors:
                        masks[color] = masks.get(color, 0) | (1 << i)
                for color, mask in masks.items():
                    code = self.codes.get(mask)
                    if code is not None:
                        cells[x, y] = code, color
                        break
        return cells

    def board(self, rgb, level):
        if not (self.text(rgb, 52, 0, 'Level: ' + str(level)) and
                self.text(rgb, 52, 32, 'Esc: Quit')):
            return None
        cells = self.tiles(rgb)
        players = [position for position, tile in cells.items()
                   if tile[0] == ord('@') and tile[1] in (GREEN, YELLOW, RED)]
        return (players[0], cells) if len(players) == 1 else None


def terrain(tile):
    if not tile:
        return None
    char, color = tile
    if char == 219 and color in (GREY, DARK):
        return 'wall'
    if char == 249 and color in (WHITE, DARK):
        return 'floor'
    if char in (ord("'"), ord('\\')) and color in (TAN, DARK):
        return 'door'
    if char == 10 and color in (YELLOW, DARK):
        return 'elevator'
    if color == GOLD and char == ord('c'):
        return 'code'
    if color in (RED, GREEN, ORANGE, BLUE, CYAN) and char in map(ord, 'psihclkm'):
        return 'item'
    if color == ZOMBIE and char in (ord('z'), ord('Z')):
        return 'monster'
    if color == YELLOW and chr(char) in 'abcdefghijklmnopqrsuvwxyz':
        return 'monster'
    return None


def main():
    output, evidence = map(Path, sys.argv[1:])
    proof = dict(version='0.2', source_archive_sha256=
                 '0b5f03ac310a8ef5b180b9b4f5dff4a564277c49f11717035284f6b4e4cf978d',
                 captures=[], inputs=[], movement=[], success=False, launch_arguments=[])
    game = capture = server = None

    def save():
        write_json(evidence / 'proof.json', proof)

    try:
        require(output.is_absolute() and output.resolve(strict=True) == output and
                output.parent == Path('/gnu/store'), 'noncanonical package output')
        require(sys.flags.isolated and sys.flags.no_site and
                str(Path(sys.executable).resolve(strict=True)).startswith('/gnu/store/'),
                'tool Python not isolated/no-site/store-provided')
        for path in [output, *output.rglob('*')]:
            mode = path.lstat().st_mode
            if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
                require(not mode & 0o222, 'writable output member: ' + str(path))
        proof['tool_python'] = dict(executable=sys.executable, initial_sys_path=sys.path[:])
        proof['isolation'] = namespace_proof(Path('/proc/self'), evidence)
        evidence, mounts = isolate_mounts(evidence)
        proof['store_mounts'] = mounts
        oracle = Oracle(output / 'share/doc/escape-from-lab-42/source')
        proof['source_oracle_sha256'] = oracle.hashes
        root = Path('/tmp/lab42-state')
        root.mkdir(mode=0o700)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        env = {'PATH': '', 'LC_ALL': 'C', 'LIBGL_ALWAYS_SOFTWARE': '1',
               'MESA_SHADER_CACHE_DISABLE': 'true', 'PYTHONNOUSERSITE': '1',
               'PYTHONDONTWRITEBYTECODE': '1'}
        for key, name in [('HOME', 'home'), ('XDG_DATA_HOME', 'data'),
                          ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache'),
                          ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                          ('TMPDIR', 'tmp')]:
            directory = root / name
            directory.mkdir(mode=0o700)
            env[key] = str(directory)
        env.update(DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-session'),
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-system'),
                   PULSE_SERVER='unix:' + str(root / 'runtime/no-pulse'))
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
        proof['display_process'] = namespace_proof(Path('/proc') / str(server.pid), evidence)
        capture = XCapture(env['DISPLAY'])
        game = start('game', [str(output / 'bin/escape-from-lab-42')])
        deadline = time.monotonic() + 20
        window = None
        while time.monotonic() < deadline:
            require(game.poll() is None, 'ordinary game exited before native window')
            result = tool('XDOTOOL', 'search', '--onlyvisible', '--name',
                          '^Escape from Lab 42 \\(ver\\. 0\\.2\\)$')
            if result.returncode == 0:
                windows = result.stdout.split()
                require(len(windows) == 1, 'ambiguous titled native window')
                parent = int(windows[0])
                children = capture.children(parent)
                # gfx_x11.c names wmwindow, then reparents the unnamed framebuffer child.
                require(len(children) == 1, 'FreeBASIC framebuffer child absent/ambiguous')
                window = children[0]
                proof['window'] = dict(title_parent=parent, framebuffer_child=window)
                break
            time.sleep(.05)
        require(window is not None, 'ordinary FreeBASIC window absent')
        proof['game_process'] = namespace_proof(Path('/proc') / str(game.pid), evidence)
        proc = Path('/proc') / str(game.pid)
        proof['command_line'] = (proc / 'cmdline').read_bytes().decode().split('\0')[:-1]
        proof['native_executable'] = os.readlink(proc / 'exe')
        require(proof['native_executable'].startswith(str(output) + '/'),
                'launcher did not execute output native binary')
        geometry = tool('XDOTOOL', 'getwindowgeometry', '--shell', str(window))
        require(geometry.returncode == 0 and 'WIDTH=640\n' in geometry.stdout and
                'HEIGHT=480\n' in geometry.stdout, 'ordinary window geometry changed')
        (evidence / 'window-geometry.txt').write_text(geometry.stdout)
        require(tool('XDOTOOL', 'windowfocus', '--sync', str(window)).returncode == 0,
                'native child focus failed')
        require(tool('XDOTOOL', 'mousemove', '1000', '740').returncode == 0,
                'cannot park native pointer outside framebuffer')

        def errors():
            log = (evidence / 'game.log').read_text(errors='replace')
            require(not re.search(r'(?i)\berror\b|\bexception\b|aborting|segmentation fault|'
                                  r'failed to|fatal|XIO:|unable to|out of memory|division by zero|'
                                  r'cannot (?:open|load|initialize)|illegal function call', log),
                    'native runtime error even if exit status is zero (game.log)')
            require(server.poll() is None, 'native display service exited')

        def frame(label, rgb):
            path = evidence / (label + '.png')
            save_png(path, rgb)
            proof['captures'].append(dict(file=path.name,
                                           sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
            save()

        def observe(label, predicate, timeout=10, retain=True):
            deadline = time.monotonic() + timeout
            rgb = None
            while time.monotonic() < deadline:
                errors()
                require(game.poll() is None, 'native game exited during ' + label)
                rgb = capture.capture(window)
                require(not oracle.text(rgb, 0, 0, 'You have died...'),
                        'natural death before required level transition')
                value = predicate(rgb)
                if value:
                    if retain:
                        frame(label, rgb)
                    return rgb, value
                time.sleep(.04)
            if rgb is not None:
                frame(label + '-failed', rgb)
            raise AssertionError('source pixel observation absent: ' + label)

        def key(name, control):
            proof['inputs'].append(dict(key=name, control=control, method='XTest'))
            require(tool('XDOTOOL', 'key', '--clearmodifiers', '--delay', '35', name).returncode == 0,
                    'native input failed: ' + name)
            errors()

        _, title = observe('01-native-title', oracle.title_frame)
        proof['title_source_observation'] = title
        # DoTitle never prompts: after its fade and Delay(2), DrawIntroText draws and waits.
        # A key sent during the fade ends the fade, or stays buffered and ends the intro.
        observe('02-native-intro', lambda rgb: oracle.text(rgb, 30, 1, 'Escape from Lab 42') and
                oracle.text(rgb, 1, 3, 'You wake up in the Medlab,'))
        key('space', 'dismiss ordinary introduction; generate unseeded level')
        rgb, board = observe('03-generated-level10', lambda image: oracle.board(image, 10))
        require(oracle.text(rgb, 52, 8, 'R Hand: .45 Pistol (12)') and
                oracle.text(rgb, 52, 21, 'F1-F5: None'), 'fresh native equipment differs')
        proof['initial_player_screen_tile'] = board[0]
        world = (0, 0)
        known, visited = {}, {world}
        access = False
        transition = False
        shots = 0

        def learn(current):
            position, cells = current
            for (x, y), tile in cells.items():
                if (x, y) == position:
                    continue
                kind = terrain(tile)
                if kind:
                    # PutText is one-based for both map and player: i+x and
                    # player-i yield the same displayed native tile coordinate.
                    coordinate = (world[0] + x - position[0],
                                  world[1] + y - position[1])
                    if tile[1] != DARK or coordinate not in known:
                        known[coordinate] = 'floor' if kind == 'monster' else kind

        def plan():
            elevator = {pos for pos, kind in known.items() if kind == 'elevator'}
            codes = {pos for pos, kind in known.items() if kind == 'code'}
            goal = elevator if access and elevator else codes if not access and codes else set()
            queue = deque([world])
            paths = {world: []}
            candidates = []
            while queue:
                pos = queue.popleft()
                path = paths[pos]
                if pos in goal and path:
                    return path
                if path:
                    frontier = any((pos[0] + dx, pos[1] + dy) not in known
                                   for _, dx, dy in DIRECTIONS)
                    if pos not in visited and (known.get(pos) == 'door' or frontier):
                        candidates.append((0 if known.get(pos) == 'door' else 1, len(path), path))
                for direction in DIRECTIONS:
                    _, dx, dy = direction
                    neighbor = pos[0] + dx, pos[1] + dy
                    kind = known.get(neighbor)
                    if neighbor not in paths and kind in ('floor', 'door', 'item', 'code', 'elevator'):
                        if kind == 'elevator' and not access:
                            continue
                        paths[neighbor] = path + [direction]
                        queue.append(neighbor)
            if candidates:
                return min(candidates, key=lambda value: value[:2])[2]
            # A fully seen room may have no unknown neighbors except beyond its door;
            # visit any remaining ordinary walkable cell rather than assume a map seed.
            remaining = [path for pos, path in paths.items() if pos not in visited and path]
            require(remaining, 'no observed reachable exploration frontier')
            return min(remaining, key=len)

        def move(current_rgb, current, direction, label, level=10):
            before, cells = current
            name, dx, dy = direction
            key(name, 'move along screenshot-learned terrain')
            target = world[0] + dx, world[1] + dy

            def changed(image):
                new = oracle.board(image, level)
                if not new:
                    return None
                after, after_cells = new
                sx, sy = before[0] + dx - after[0], before[1] + dy - after[1]
                # DrawMap: i = player.x - vw/2 = player.x - 25 exactly, but
                # j = player.y - vh/2 = player.y - 27.5 is converted to Integer with
                # round-half-even and clamped to 1..45. So vertical camera steps are 0 or 2
                # rows (1 at a clamp edge); horizontal steps are 0 or dx.
                if sx not in (0, dx) or sy not in (0, dy, 2 * dy):
                    return None
                if sx == sy == 0 and after == before:
                    return None
                matches = 0
                kinds = set()
                for (x, y), tile in cells.items():
                    kind = terrain(tile)
                    shifted = x - sx, y - sy
                    if kind not in ('wall', 'floor', 'door') or (x, y) == before or shifted == after:
                        continue
                    if after_cells.get(shifted) == tile:
                        matches += 1
                        kinds.add(kind)
                if matches >= 8 and 'floor' in kinds and 'wall' in kinds:
                    stationary = sum(1 for pos, tile in cells.items()
                                     if terrain(tile) in ('wall', 'floor', 'door') and
                                     pos != before and pos != after and after_cells.get(pos) == tile)
                    if (sx or sy) and matches <= stationary + 2:
                        return None
                    return new, (sx, sy), matches
                return None
            def action(image):
                moved = changed(image)
                if moved:
                    return 'movement', moved
                new = oracle.board(image, level)
                if not new or new[0] != before:
                    return None
                messages_changed = crop(image, 8, 448, 384, 32) != \
                    crop(current_rgb, 8, 448, 384, 32)
                melee_message = any(oracle.text(image, 1, 56, message, (254, 254, 254))
                                    for message in ('You killed the zombie.', 'You hit the zombie',
                                                    'You missed the zonbie.'))
                stationary = sum(1 for pos, tile in cells.items()
                                 if terrain(tile) in ('wall', 'floor', 'door') and
                                 new[1].get(pos) == tile)
                if messages_changed and melee_message and stationary >= 8:
                    return 'combat', new
                return None

            # A genuine elevator changes the level before the next frame. It must have
            # been observed, unlocked and entered with the ordinary movement key.
            if level == 10 and access and known.get(target) == 'elevator':
                image, new = observe('level10-to-level9', lambda image: oracle.board(image, 9) if
                                     oracle.text(image, 1, 56, 'Entering level 9.',
                                                 (254, 254, 254)) else None)
                return image, new, True
            image, (kind, value) = observe(label, action, timeout=2, retain=True)
            if kind == 'combat':
                proof.setdefault('native_melee_actions', []).append(
                    dict(key=name, screenshot=label + '.png'))
                return image, value, 'combat'
            new, scroll, matches = value
            proof['movement'].append(dict(key=name, world_delta=[dx, dy],
                                          before_screen_tile=before, after_screen_tile=new[0],
                                          camera_delta=scroll, matching_static_tiles=matches,
                                          screenshot=label + '.png'))
            with (evidence / 'movement.jsonl').open('a') as log:
                log.write(json.dumps(proof['movement'][-1]) + '\n')
            return image, new, False

        # DoDropItem places the item under the player only when that tile holds no item;
        # otherwise it uses a neighbor and native g would collect something else. The @
        # hides loot under the player, so first step onto a displayed plain floor glyph.
        empty = [direction for direction in DIRECTIONS
                 if board[1].get((board[0][0] + direction[1], board[0][1] + direction[2])) ==
                 (249, WHITE)]
        require(empty, 'no displayed item-free floor neighbor for native drop/pickup')
        rgb, board, outcome = move(rgb, board, empty[0], '04-empty-floor')
        require(outcome is False, 'move onto observed empty floor was not observed')
        world = world[0] + empty[0][1], world[1] + empty[0][2]
        visited.add(world)

        def neighbor_items(current):
            (x, y), cells = current
            return {(dx, dy): cells.get((x + dx, y + dy)) for _, dx, dy in DIRECTIONS
                    if terrain(cells.get((x + dx, y + dy))) == 'item'}

        items_before_drop = neighbor_items(board)
        key('F1', 'empty inventory slot unequips the starting pistol')
        observe('05-unequipped', lambda image: oracle.text(image, 52, 8, 'R Hand: None') and
                oracle.text(image, 52, 21, 'F1-F5: .45 Pistol (12)'))
        key('F5', 'drop the ordinary unequipped item onto the observed empty floor tile')
        rgb, board = observe('06-dropped', lambda image: oracle.board(image, 10) if
                             oracle.text(image, 52, 21, 'F1-F5: None') and
                             not oracle.text(image, 1, 56, 'No empty tiles to drop item.',
                                             (254, 254, 254)) else None)
        require(neighbor_items(board) == items_before_drop,
                'native drop landed beside the player instead of under it')
        key('g', 'pick up native dropped pistol; no fixture or inventory injection')
        observe('07-picked-up', lambda image:
                oracle.text(image, 52, 21, 'F1-F5: .45 Pistol (12)') and
                oracle.text(image, 1, 56, 'Item added to your inventory.', (254, 254, 254)))
        key('F1', 'equip observed inventory pistol into a free hand')
        rgb, board = observe('08-equipped', lambda image: oracle.board(image, 10) if
                             oracle.text(image, 52, 7, 'L Hand: .45 Pistol (12)') and
                             oracle.text(image, 52, 21, 'F1-F5: None') else None)
        proof['equipment_pickup'] = dict(
            precondition='moved onto a displayed plain floor glyph, so no item lay under player',
            unequip=True, native_drop=True, drop_under_player=True, native_get=True,
            reequipped_left_hand=True)

        for step in range(1400):
            learn(board)
            access = oracle.text(rgb, 52, 4, 'Access Code: Yes', GREEN)
            if access and not proof.get('access_code'):
                frame('08-native-access-code', rgb)
                proof['access_code'] = dict(observed=True, world_tile=world)
            # Target only real displayed monsters, and fire only an assigned native label.
            monsters = [pos for pos, tile in board[1].items() if terrain(tile) == 'monster']
            hand = oracle.line(rgb, 52, 7, 26)
            ammo = re.search(r'\.45 Pistol \((\d+)\)', hand)
            if monsters and ammo and int(ammo.group(1)) > 0:
                if not oracle.text(rgb, 52, 34, 'Targeting On', GREEN):
                    key('t', 'target real visible zombies with equipped pistol')
                    def targeted_or_departed(image):
                        current = oracle.board(image, 10)
                        if current and (oracle.text(image, 52, 34, 'Targeting On', GREEN) or
                                        (oracle.text(image, 52, 34, 'Targeting Off') and
                                         not any(terrain(tile) == 'monster'
                                                 for tile in current[1].values()))):
                            return current
                        return None
                    rgb, board = observe('target-state-' + str(step), targeted_or_departed,
                                         timeout=2)
                labels = sorted({chr(tile[0]) for tile in board[1].values()
                                 if tile[1] == YELLOW and chr(tile[0]) in
                                 'abcdefghijklmnopqrsuvwxyz'})
                if labels:
                    before_ammo = int(ammo.group(1))
                    key(labels[0], 'fire at observed yellow native zombie target label')
                    rgb, board = observe('shot-' + str(shots), lambda image:
                                         oracle.board(image, 10) if oracle.text(
                                             image, 52, 7, 'L Hand: .45 Pistol (' +
                                             str(before_ammo - 1) + ')') else None, timeout=2)
                    shots += 1
                    proof['native_projectile_shots'] = shots
                    continue
            if oracle.text(rgb, 52, 34, 'Targeting On', GREEN):
                key('t', 'return from native targeting to movement/pickup controls')
                rgb, board = observe('target-off-' + str(step), lambda image:
                                     oracle.board(image, 10) if
                                     oracle.text(image, 52, 34, 'Targeting Off') else None)
            direction = plan()[0]
            rgb, board, transition = move(rgb, board, direction, 'move-' + str(step))
            if transition == 'combat':
                transition = False
                continue
            if transition:
                proof['transition'] = dict(from_level=10, to_level=9,
                                           access_code_observed=True, native_elevator=True)
                break
            world = world[0] + direction[1], world[1] + direction[2]
            visited.add(world)
        require(transition and len(proof['movement']) >= 2,
                'real unseeded movement/level10-to-level9 transition not reached')
        # Continue playing the newly generated level, using only its displayed terrain.
        world, known, visited, access = (0, 0), {}, {(0, 0)}, False
        learn(board)
        candidates = [direction for direction in DIRECTIONS
                      if terrain(board[1].get((board[0][0] + direction[1],
                                               board[0][1] + direction[2]))) in
                      ('floor', 'door', 'item', 'code')]
        require(candidates, 'no displayed walkable neighbor on newly generated level9')
        rgb, board, outcome = move(rgb, board, candidates[0],
                                   '09-continued-level9-action', level=9)
        require(outcome is False, 'continued level9 movement was not observed')
        proof['continued_action_level'] = 9
        frame('10-before-clean-quit', rgb)
        key('Escape', 'ordinary clean native quit; there is no save/load interface')
        status = game.wait(timeout=15)
        proof['native_exit_status'] = status
        errors()
        require(status == 0, 'native exit nonzero/signalled: ' + str(status))
        require(not list(work.iterdir()), 'clean quit unexpectedly wrote working directory')
        proof['mutable_files'] = [str(p.relative_to(root)) for p in root.rglob('*') if p.is_file()]
        proof['save_load'] = 'not implemented upstream; neither attempted nor claimed'
        proof['morgue'] = 'optional death/win path not exercised; clean Esc quit exercised'
        proof['success'] = True
        save()
        print('ESCAPE_FROM_LAB_42_NATIVE_GAMEPLAY_OK title/intro/level10/equipment/drop/pickup/'
              'movement/access-code/elevator/level9/continued-action/clean-Esc-quit')
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
        # Namespace init exit disposes only this consumer's private processes.
        # Never signal a native game and call that a successful quit; no host cleanup.


if __name__ == '__main__':
    main()
