#!/usr/bin/env python3
"""Keyboard-only native EverSector 0.7.3 proof, using immutable source glyphs.

No seed, save, option, game-state or instrumentation injection. The native save
persists ship/resources/location and seed, NOT galaxy turn/NPC state/reputation.
Reload checks exactly the state upstream actually restores, then performs a
continued orbit maneuver. Genuine station fuel trading is mandatory; mining is
not claimed. Every frame is XGetImage of the ordinary Java AWT window.
"""
import ctypes as C
from collections import Counter
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

WIDTH = HEIGHT = 0
COMMIT = '224ead104afc6bc9df9d7dcf86f87766ff1b5152'
SOURCE_HASHES = {'Main.java': '55075bb8d73ca3872e9d7756af0c3175a4b6409f703f0ba8bc0cea2137df3ac4', 'Option.java': '93f65c76eef098864f191083ebcdcfe477f5ad2ecf445bd1fca0465006c741e5', 'Paths.java': '868d5fe555cd0e75f478bcab38d676d6949caed59e44057efc8adec7b58ce9d1', 'Symbol.java': '0992c1a5be3e3a2a8995fde41df1073996ba9d52ee20be812a1fb6cf2e8632bb', 'actions/Orbit.java': '0c16e077f4a2ebe3a461dac3b8acfc6324edd13c7c3f04aff083f48db4fbf82f', 'actions/TransactResource.java': 'e262ed0c2876c7a3daddac17ee9457af7e6559a89bee0d878cd3d8a38372c34d', 'map/Galaxy.java': '636d4c2583350fa87279419507bdf264600e30240e8b03d0a77536f143e57d3a', 'map/Sector.java': '1ff32410dd578a35c3545bfffe1e7036af256fa22f0591339761e06e10fe6762', 'map/Station.java': '0c45e4433aaa5bc1e3b48cae6ff195576eb80e1de75322fcdd3b00beb37efaab', 'screens/EndScreen.java': 'a84a454ce52bef914a06ff7ac2f5ebdc0726dc9d72b4d749846c0f646e665da4', 'screens/GameScreen.java': '5741faf194cdb143d6819999389dd0cb3d84d0bf5e6787753a56b135b9f0a484', 'screens/NamePromptScreen.java': 'bf0ed9fbcac44b9b7d098e28559337da0f3339a64f1157c3da0440cf066a9806', 'screens/QuitScreen.java': 'aa4addd1f927c7c8b4a28460be121c68b7d1a5fada22e415bcdf90cb90b4f268', 'screens/SectorScreen.java': 'c301e3bb6d90fc11a915659112896638e5b48c8a05aad9699335ab2aafc0ae16', 'screens/StartScreen.java': '5b7cb8d6bcf218486611fb5e4f7519b2505a13954c6a355fedf406b12c51c7e2', 'screens/StationScreen.java': 'f52826c0abcce36c27017cd11b58aad55517feaeca540195f6802ededfe72da9', 'ships/Ship.java': '4a471eebb8322aeafcfcafff228e7a76c538e7e4f4aaf53d1d06cb1ab2768c05'}
SOURCE_HASHES.update({
    'screens/ElectionResultsScreen.java':
        '86406b435770bb7bfc6094e54ac5a0529b9646ec922f5629ae3206f179d7ef85',
    'screens/VotingScreen.java':
        '5b417439aab672a6d412617ad13752e3c2e5e996ea7079f73b0cf246773e1e6d',
})
FONT_HASHES = {
    'alloy/font.properties': '6751b9a590d3c3044848bedff8e6ba03564805b8787874c1f5674f3725c9ad29',
    'alloy/tiles.png': '7a967cd326414f2cb16dd3951c2eb4cfc12c5ddcf805d77512f1e8951ea2fef4',
    'cooz/font.properties': 'be669f9d40a9bc4ced62dacba51bb90b25ffa047f800167f9cd798d012b76f9c',
    'cooz/tiles.png': '5de72a872a7819eb33d7d6fdc31a6aa2a1b168e872c065c72ae7d478c07a1642',
    'qbicfeet/font.properties': '9fce8dbd0b28896f97af30d981a5a6e866251361b5bad60270de6ec0f074c81e',
    'qbicfeet/tiles.png': 'b598c0bc27734191ec815fc08a4ae262e201189de4820bfc25f75ccf0dd10e0f',
}
DEPENDENCY_HASHES = {
    'apwt/src/main/java/maugrift/apwt/display/AsciiPanelDisplay.java':
        'f9fae2173d65c878f3ac410c270a82c03670a58f89d11d99a0012cd443400b86',
    'apwt/src/main/java/maugrift/apwt/screens/ConfirmationScreen.java':
        'ace18a6bed6c934ca39583e27b3a2d5ab4b137b14f4a5b88dcb93fdeb6390fa5',
    'asciipanel/src/main/java/asciiPanel/AsciiPanel.java':
        'b1f1e599fe90d42ecc5899edc13cb8a2f78ae7e98d1cd8c2bb5d486605c3bbd1',
}


def require(value, message):
    if not value:
        raise AssertionError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def sha(data):
    return hashlib.sha256(data).hexdigest()


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
        result = subprocess.run([os.environ['MOUNT'], *args], capture_output=True,
                                text=True, timeout=15)
        commands.append(dict(command=[os.environ['MOUNT'], *args], status=result.returncode,
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
    for target in sorted({row[0] for row in entries()[1]}, key=len, reverse=True):
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    require(found and all('ro' in opts and 'rw' not in opts and not
                         any(x.startswith(('shared:', 'master:')) for x in optional)
                         for _, opts, optional in found), 'store not private read-only')
    (evidence / 'mountinfo-after.txt').write_text(text)
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        source = '/proc/' + str(os.getpid()) + '/fd/' + str(descriptor)
        evidence = Path(source)
        mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/tmp')
        retained = Path('/tmp/eversector-evidence')
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
            h = C.cast(image, C.POINTER(XImage)).contents
            require((h.width, h.height, h.depth, h.bits_per_pixel, h.byte_order,
                     h.red_mask, h.green_mask, h.blue_mask) ==
                    (WIDTH, HEIGHT, 24, 32, 0, 0xff0000, 0xff00, 0xff),
                    'native framebuffer format changed')
            raw = C.string_at(h.data, h.bytes_per_line * HEIGHT)
            rgb = bytearray(WIDTH * HEIGHT * 3)
            for y in range(HEIGHT):
                row = raw[y * h.bytes_per_line:y * h.bytes_per_line + WIDTH * 4]
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


def decode_png(data):
    """Decode the immutable bitmap font only; no GUI/game code is invoked."""
    require(data[:8] == b'\x89PNG\r\n\x1a\n', 'font is not PNG')
    position, compressed, palette, alpha = 8, bytearray(), None, b''
    while position < len(data):
        size = struct.unpack_from('>I', data, position)[0]
        kind = data[position + 4:position + 8]
        body = data[position + 8:position + 8 + size]
        require(zlib.crc32(kind + body) == struct.unpack_from('>I', data, position + 8 + size)[0],
                'font PNG CRC mismatch')
        if kind == b'IHDR':
            width, height, depth, colour, compression, filtering, interlace = struct.unpack('>IIBBBBB', body)
            require(depth == 8 and colour in (0, 2, 3, 4, 6) and
                    (compression, filtering, interlace) == (0, 0, 0), 'unsupported font PNG')
        elif kind == b'IDAT':
            compressed.extend(body)
        elif kind == b'PLTE':
            palette = body
        elif kind == b'tRNS':
            alpha = body
        position += size + 12
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[colour]
    stride = width * channels
    raw = zlib.decompress(compressed)
    require(len(raw) == height * (stride + 1), 'font PNG byte length changed')
    decoded, previous = [], bytearray(stride)
    for y in range(height):
        base = y * (stride + 1)
        filter_type = raw[base]
        row = bytearray(raw[base + 1:base + 1 + stride])
        for i in range(stride):
            a = row[i - channels] if i >= channels else 0
            b = previous[i]
            c = previous[i - channels] if i >= channels else 0
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = a
            elif filter_type == 2:
                predictor = b
            elif filter_type == 3:
                predictor = (a + b) // 2
            elif filter_type == 4:
                p = a + b - c
                candidates = [(abs(p - a), a), (abs(p - b), b), (abs(p - c), c)]
                predictor = min(enumerate(candidates), key=lambda v: (v[1][0], v[0]))[1][1]
            else:
                raise AssertionError('unknown PNG filter')
            row[i] = (row[i] + predictor) & 255
        for x in range(width):
            pixel = row[x * channels:(x + 1) * channels]
            if colour == 6:
                value = tuple(pixel)
            elif colour == 2:
                value = (*pixel, 255)
            elif colour == 0:
                value = (pixel[0],) * 3 + (255,)
            elif colour == 4:
                value = (pixel[0],) * 3 + (pixel[1],)
            else:
                index = pixel[0]
                require(palette is not None, 'font palette absent')
                value = (*palette[index * 3:index * 3 + 3], alpha[index] if index < len(alpha) else 255)
            decoded.append(value)
        previous = row
    return width, height, decoded


class GlyphGrid:
    """Read complete binary source glyphs; color alone never proves a character."""
    def __init__(self, bitmap, width, height):
        bw, bh, pixels = decode_png(bitmap)
        require((bw, bh) == (width * 16, height * 16), 'source font grid changed')
        self.width, self.height = width, height
        self.origin = (0, 0)
        self.codes = {}
        for code in range(256):
            x, y = (code % 16) * width, (code // 16) * height
            mask = bytes(pixels[(y + dy) * bw + x + dx][0] > 127
                         for dy in range(height) for dx in range(width))
            if code == 1 or 32 <= code < 127:
                self.codes.setdefault(mask, []).append(code)

    def read(self, rgb):
        rows, players = [], []
        ox, oy = self.origin
        for row in range(50):
            chars = []
            for col in range(90):
                cell = crop(rgb, ox + col * self.width, oy + row * self.height,
                            self.width, self.height)
                colors = Counter(cell[i:i + 3] for i in range(0, len(cell), 3))
                bg, _ = colors.most_common(1)[0]
                mask = bytes(cell[i:i + 3] != bg for i in range(0, len(cell), 3))
                codes = self.codes.get(mask, [])
                if len(codes) == 1:
                    code = codes[0]
                    chars.append(chr(code))
                    if code == 1 and colors.get(b'\xff\xff\xff', 0) == sum(mask):
                        players.append([col, row])
                elif not any(mask):
                    chars.append(' ')
                else:
                    chars.append('\ufffd')
            rows.append(''.join(chars))
        return dict(rows=rows, text='\n'.join(rows), players=players)


def hud(view):
    # Both labels and every digit must match their original bitmap silhouettes.
    text = view['text']
    credits = re.search(r'Credits: (\d+)', text)
    turn = re.search(r'\bTurn (\d+)', text)
    resources = {}
    for name in ('Fuel', 'Energy', 'Ore', 'Hull'):
        match = re.search(r'(\d+)/(\d+) ' + name + r'\b', text)
        if not match:
            return None
        resources[name] = list(map(int, match.groups()))
    if not credits or not turn:
        return None
    return dict(credits=int(credits[1]), turn=int(turn[1]), resources=resources)


def orbital(view):
    state = hud(view)
    ruler_row = next((i for i, row in enumerate(view['rows']) if 'Ruler: ' in row), None)
    star_row = next((i for i, row in enumerate(view['rows']) if 'Star: ' in row), None)
    if not state or len(view['players']) != 1 or ruler_row is None or star_row is None:
        return None
    # Ignore the variable-width window border, but never unidentified title glyphs.
    ruler = re.search(r'Ruler: ([A-Za-z0-9 .\'-]+)', view['rows'][ruler_row])
    star = re.search(r'Star: ([A-Za-z0-9 .\'-]+)', view['rows'][star_row])
    title = re.match(r'[A-Za-z][A-Za-z0-9 .\'-]*', view['rows'][star_row - 1][1:])
    sector = title[0].strip() if title else None
    if not ruler or not star or not sector:
        return None
    cell = view['players'][0]
    orbit = cell[1] - ruler_row - 1
    if orbit < 1:
        return None
    state.update(player_cell=cell, orbit=orbit, sector=sector,
                 star=star[1].strip(), ruler=ruler[1].strip())
    return state


def main():
    global WIDTH, HEIGHT
    require(len(sys.argv) == 3, 'usage: eversector-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    proof = dict(output=str(output), source_commit=COMMIT, inputs=[], captures=[],
                 success=False, limitations=[
                     'Native save restores ship/location/resources/modules/faction and galaxy seed.',
                     'Upstream regenerates the galaxy and resets turn/NPC state/reputation on load.',
                     'Mining is not claimed; guaranteed starting-station fuel trading is exercised.',
                     'Position is exact displayed orbital glyph cell, not hidden world coordinates.'])
    game = server = capture = None
    game_logs = []

    def save():
        write_json(evidence / 'native-gameplay.json', proof)

    try:
        require(output.parent == Path('/gnu/store') and output.resolve(strict=True) == output,
                'noncanonical direct package output')
        require(sys.flags.isolated and sys.flags.no_site, 'Python is not isolated/no-site')
        for path in [output, *output.rglob('*')]:
            mode = path.lstat().st_mode
            if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
                require(not mode & 0o222, 'writable output member: ' + str(path))
        proof['isolation'] = namespace_proof(Path('/proc/self'), evidence)
        evidence, proof['store_mounts'] = isolate_mounts(evidence)
        root = Path('/tmp/eversector-state')
        root.mkdir(mode=0o700)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        env = dict(PATH='', LC_ALL='C', DISPLAY='')
        for key, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                          ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                          ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                          ('TMPDIR', 'tmp')]:
            directory = root / name
            directory.mkdir(mode=0o700)
            env[key] = str(directory)
        env.update(DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-session'),
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-system'))
        work = root / 'work'
        work.mkdir()
        proof['environment'] = env.copy()
        proof['clean_state_before'] = {key: os.listdir(env[key]) for key in env if
                                      key.startswith('XDG_') or key == 'HOME'}
        require(not any(proof['clean_state_before'].values()), 'initial state is not fresh')
        source = output / 'share/eversector/source/game/src/main/java/maugrift/eversector'
        proof['source_oracles'] = {}
        for name, expected in SOURCE_HASHES.items():
            path = source / name
            data = path.read_bytes()
            require(sha(data) == expected, 'pinned original source changed: ' + name)
            proof['source_oracles'][name] = dict(path=str(path), sha256=expected)
        proof['source_archive'] = dict(
            url='https://codeload.github.com/friedev/eversector/tar.gz/' + COMMIT,
            sha256='be8b8b0510fea5ea153de9418312783d35ecfe69e180f74db372045a291c4617',
            identification='release 0.7.3; immutable commit; original retained sources hashed above')
        for name, expected in DEPENDENCY_HASHES.items():
            path = output / 'share/eversector/source' / name
            require(sha(path.read_bytes()) == expected, 'pinned GUI dependency source changed: ' + name)
            proof['source_oracles'][name] = dict(path=str(path), sha256=expected)
        for name, expected in FONT_HASHES.items():
            path = output / 'share/eversector/assets/fonts' / name
            require(sha(path.read_bytes()) == expected, 'original source bitmap changed: ' + name)
        fonts = []
        for directory in sorted((output / 'share/eversector/assets/fonts').iterdir()):
            props = dict(line.split('=', 1) for line in
                         (directory / 'font.properties').read_text().splitlines() if '=' in line)
            bitmap = (directory / 'tiles.png').read_bytes()
            fonts.append((directory, GlyphGrid(bitmap, int(props['width']), int(props['height']))))
        require(len(fonts) == 3, 'complete authentic font set absent')
        save()

        def tool(*args, executable=None):
            command = [executable or os.environ['XDOTOOL'], *map(str, args)]
            result = subprocess.run(command, env=env, cwd=work, capture_output=True,
                                    text=True, timeout=15)
            with (evidence / 'tools.jsonl').open('a') as log:
                log.write(json.dumps(dict(command=command,
                                          status=result.returncode, stdout=result.stdout,
                                          stderr=result.stderr)) + '\n')
            return result

        def start(label, args, **kwargs):
            with (evidence / (label + '.log')).open('wb') as log:
                return subprocess.Popen(args, env=env, cwd=work, stdin=subprocess.DEVNULL,
                                        stdout=log, stderr=log, **kwargs)

        def errors():
            for path in game_logs:
                text = path.read_text(errors='replace')
                require(not re.search(r'Exception|Error|UnsatisfiedLink|SIGSEGV|'
                                      r'Could not (?:load|initialize)|Failed to '
                                      r'(?:load|create|initialize)|fatal', text, re.IGNORECASE),
                        'native runtime error in ' + path.name)
            require(not list(root.rglob('crash.txt')), 'upstream native crash receipt present')
            require(server.poll() is None, 'private X server exited')

        readfd, writefd = os.pipe()
        try:
            server = start('xvfb', [os.environ['XVFB'], '-displayfd', str(writefd),
                                   '-screen', '0', '1600x1000x24', '-nolisten', 'tcp',
                                   '-noreset'], pass_fds=(writefd,))
            os.close(writefd)
            writefd = None
            require(select.select([readfd], [], [], 20)[0] and server.poll() is None,
                    'private X server readiness absent')
            number = os.read(readfd, 64).decode().strip()
            require(number.isdigit(), 'invalid Xvfb displayfd')
            env['DISPLAY'] = ':' + number
        finally:
            os.close(readfd)
            if writefd is not None:
                os.close(writefd)
        proof['xserver'] = namespace_proof(Path('/proc') / str(server.pid), evidence)
        capture = XCapture(env['DISPLAY'])
        grid = None
        window = None

        def launch(label):
            nonlocal game, window, grid
            global WIDTH, HEIGHT
            game_logs.append(evidence / (label + '.log'))
            game = start(label, [str(output / 'bin/eversector')])
            deadline = time.monotonic() + 60
            while time.monotonic() < deadline:
                errors()
                require(game.poll() is None, 'ordinary Java game exited before window')
                result = tool('search', '--onlyvisible', '--pid', game.pid)
                windows = result.stdout.split() if result.returncode == 0 else []
                if len(windows) == 1:
                    window = int(windows[0])
                    break
                time.sleep(.2)
            else:
                raise AssertionError('ordinary Java AWT window absent/ambiguous')
            proc = Path('/proc') / str(game.pid)
            proof[label] = dict(namespace=namespace_proof(proc, evidence),
                                cmdline=(proc / 'cmdline').read_bytes().decode().split('\0')[:-1],
                                cwd=os.readlink(proc / 'cwd'))
            require(proof[label]['cwd'].startswith(str(root) + '/'),
                    'launcher mutable cwd escaped private state')
            require(not any(arg.startswith(('-javaagent', '-agentlib', '-agentpath')) or
                            'java.awt.headless=true' in arg
                            for arg in proof[label]['cmdline']),
                    'ordinary AWT JVM was instrumented or forced headless')
            maps = (proc / 'maps').read_text()
            (evidence / (label + '-native-maps.txt')).write_text(maps)
            require('libawt_xawt.so' in maps, 'ordinary native Java X11 AWT backend is not mapped')
            geometry = tool('getwindowgeometry', '--shell', window)
            require(geometry.returncode == 0, 'window geometry unavailable')
            fields = dict(line.split('=', 1) for line in geometry.stdout.splitlines() if '=' in line)
            WIDTH, HEIGHT = int(fields['WIDTH']), int(fields['HEIGHT'])
            proof[label]['geometry'] = fields
            require(tool('windowfocus', '--sync', window).returncode == 0, 'AWT focus failed')
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                rgb = capture.capture(window)
                for directory, candidate in fonts:
                    mx, my = WIDTH - 90 * candidate.width, HEIGHT - 50 * candidate.height
                    if not (0 <= mx <= 32 and 0 <= my <= 32):
                        continue
                    for oy in range(my + 1):
                        for ox in range(mx + 1):
                            candidate.origin = (ox, oy)
                            if 'Welcome to EverSector!' in candidate.read(rgb)['text']:
                                grid = candidate
                                proof['font_oracle'] = dict(path=str(directory / 'tiles.png'),
                                                           sha256=sha((directory / 'tiles.png').read_bytes()),
                                                           properties_sha256=sha((directory / 'font.properties').read_bytes()),
                                                           origin=[ox, oy], cell=[grid.width, grid.height],
                                                           method='complete original 16x16 bitmap glyph masks')
                                save()
                                return
                time.sleep(.2)
            raise AssertionError('source bitmap glyphs do not identify ordinary start UI')

        def frame(label, rgb, view, value):
            path = evidence / (label + '.png')
            save_png(path, rgb)
            (evidence / (label + '.txt')).write_text(view['text'] + '\n')
            proof['captures'].append(dict(file=path.name, sha256=sha(path.read_bytes()), observed=value))
            save()

        def observe(label, predicate, timeout=20):
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                errors()
                require(game.poll() is None, 'native game exited during ' + label)
                rgb = capture.capture(window)
                view = grid.read(rgb)
                if settle_election(label, rgb, view):
                    continue
                value = predicate(view)
                if value:
                    frame(label, rgb, view, value)
                    return value
                time.sleep(.15)
            frame(label + '-failed', rgb, view, None)
            raise AssertionError('positive source-backed screen observation absent: ' + label)

        def phrase(text):
            return lambda view: text if text in view['text'] else None

        def raw_key(name, control):
            # AWT receives real X keyboard input through its descendant
            # FocusProxy, not the visible JFrame shell used for screenshots.
            # Reuse the proven alone-rl native Swing consumer convention.
            tree = tool('-id', window, '-tree', executable=os.environ['XWININFO'])
            require(tree.returncode == 0, 'native AWT window tree unavailable')
            candidates = re.findall(r'^\s*(0x[0-9a-fA-F]+) "FocusProxy"',
                                    tree.stdout, re.MULTILINE)
            require(len(candidates) == 1, 'expected one descendant native AWT FocusProxy')
            input_window = str(int(candidates[0], 16))
            require(tool('windowfocus', '--sync', input_window).returncode == 0,
                    'native AWT FocusProxy focus failed')
            focused = tool('getwindowfocus', '-f')
            require(focused.returncode == 0 and focused.stdout.strip() == input_window,
                    'native AWT FocusProxy does not own X input focus')
            proof['inputs'].append(dict(key=name, control=control, input_window=input_window,
                                        method='XTest real keydown/keyup to native AWT FocusProxy'))
            save()
            require(tool('keydown', '--clearmodifiers', name).returncode == 0,
                    'native keydown failed')
            time.sleep(.08)
            require(tool('keyup', name).returncode == 0, 'native keyup failed')
            time.sleep(.3)
            errors()

        def election_popup(view):
            text = view['text']
            winner = re.search(
                r'\b(?:You have|[A-Za-z][A-Za-z0-9 .\'-]+ has) '
                r'(?:won the election|been reelected)\.', text)
            votes = re.findall(r'\([A-Za-z ]+\) - \d+ Votes?\b', text)
            if winner and votes:
                return dict(kind='results', winner=winner[0], votes=votes)
            if ('The candidates are listed below.' in text and
                    'Press enter on a candidate to vote or escape to abstain.' in text):
                return dict(kind='voting', action='source-native Escape abstains')
            return None

        def settle_election(context, rgb, view):
            popup = election_popup(view)
            if not popup:
                return False
            before_hud, before_orbit = hud(view), orbital(view)
            require(before_hud is not None, 'election overlay hides required gameplay HUD')
            event = dict(context=context, before=before_hud, transitions=[])
            events = proof.setdefault('election_interruptions', [])
            events.append(event)
            number = len(events)
            # VotingScreen.onCancel -> ElectionResultsScreen -> inherited
            # ConfirmationScreen.onCancel(null). Neither Escape advances a turn.
            # No unknown dialog, error, nomination or combat screen is dismissed.
            for step in range(2):
                popup = election_popup(view)
                if not popup:
                    break
                frame('election-%02d-%d-%s' % (number, step, popup['kind']),
                      rgb, view, popup)
                event['transitions'].append(popup)
                raw_key('Escape', 'source-native election ' + popup['kind'] + ' dismissal')
                rgb = capture.capture(window)
                view = grid.read(rgb)
                require(hud(view) == before_hud,
                        'election dismissal changed credits/resources/turn')
            require(election_popup(view) is None, 'bounded native election dismissal did not complete')
            after_orbit = orbital(view)
            require(after_orbit is not None, 'election dismissal did not restore exact orbital view')
            if before_orbit is not None:
                require(after_orbit == before_orbit, 'election dismissal changed exact displayed position')
            event['restored'] = after_orbit
            frame('election-%02d-restored-orbit' % number, rgb, view, after_orbit)
            return True

        def key(name, control):
            rgb = capture.capture(window)
            settle_election('before ' + control, rgb, grid.read(rgb))
            raw_key(name, control)

        def quit_game(label, saving):
            key('shift+q', 'GameScreen native quit confirmation')
            observe(label + '-confirmation', phrase('Save before quitting?'))
            key('y' if saving else 'n', 'QuitScreen save' if saving else 'QuitScreen discard')
            observe(label + '-end', phrase('to play again or Q to quit.'))
            key('shift+q', 'EndScreen System.exit(0)')
            status = game.wait(timeout=20)
            errors()
            require(status == 0, 'ordinary native exit was not zero')
            require(tool('search', '--onlyvisible', '--pid', game.pid).returncode != 0,
                    'native window survived ordinary quit')
            proof[label] = dict(exit_status=status, saved=saving)
            save()

        launch('game-new')
        observe('01-native-start', phrase('to begin.'))
        key('Return', 'StartScreen begin new random galaxy')
        observe('02-ship-name', phrase('Enter the name of your ship.'))
        for char in 'NativeShip':
            key(char, 'NamePromptScreen ship name')
        key('Return', 'confirm ship name and advance captain prompt')
        observe('03-captain-name', phrase("Enter the name of your ship's captain."))
        for char in 'NativeCaptain':
            key(char, 'NamePromptScreen captain name')
        key('Return', 'confirm captain and enter gameplay')
        initial = observe('04-native-orbit-initial', orbital)
        # Discover which adjacent orbit is valid from displayed position and HUD;
        # a failed key is never claimed as movement. No random seed is selected.
        moved = None
        for direction, dy in [('Up', -1), ('Down', 1)]:
            key(direction, 'SectorScreen orbital maneuver')
            current = observe('05-orbit-' + direction.lower(), orbital)
            if current['player_cell'] == [initial['player_cell'][0], initial['player_cell'][1] + dy]:
                require(current['turn'] == initial['turn'] + 1 and
                        current['resources']['Fuel'][0] == initial['resources']['Fuel'][0] - 1,
                        'orbital glyph moved without exact native turn/fuel cost')
                moved = current
                reverse = 'Down' if direction == 'Up' else 'Up'
                break
            require(current == initial, 'unexpected non-orbital state after direction')
        require(moved is not None, 'no exact displayed player orbital movement')
        key(reverse, 'return to source-guaranteed starting station orbit')
        returned = observe('06-orbit-returned', orbital)
        require(returned['player_cell'] == initial['player_cell'] and
                returned['turn'] == initial['turn'] + 2 and
                returned['resources']['Fuel'][0] == initial['resources']['Fuel'][0] - 2,
                'orbital roundtrip did not restore exact displayed map position')
        proof['navigation'] = dict(initial=initial, moved=moved, returned=returned)
        key('Left', 'SectorScreen Dock at genuine starting station')
        docked = observe('07-native-station', lambda view: hud(view) if 'Orbit: ' in view['text'] else None)
        key('Return', 'StationScreen buy selected first resource Fuel')
        traded = observe('08-native-fuel-purchase', lambda view: hud(view) if 'Orbit: ' in view['text'] else None)
        require(traded['resources']['Fuel'][0] == docked['resources']['Fuel'][0] + 1 and
                traded['credits'] < docked['credits'] and traded['turn'] == docked['turn'],
                'native station trade lacks positive fuel and credit HUD evidence')
        proof['trade'] = dict(before=docked, after=traded, resource='Fuel', amount=1)
        key('Escape', 'StationScreen Undock')
        saved_state = observe('09-before-native-save', orbital)
        quit_game('10-save-and-quit', True)
        saves = list(root.rglob('save.properties'))
        require(len(saves) == 1 and not saves[0].is_symlink() and saves[0].stat().st_size > 50,
                'ordinary upstream save writer produced no unique substantial save')
        native_save = saves[0]
        save_bytes = native_save.read_bytes()
        (evidence / 'native-save.properties').write_bytes(save_bytes)
        proof['native_save'] = dict(path=str(native_save.relative_to(root)),
                                    bytes=len(save_bytes), sha256=sha(save_bytes),
                                    source='EndScreen -> Ship.toProperties -> FileManager.save')
        launch('game-load')
        observe('11-continue-saved-start', phrase('to continue your saved game.'))
        key('Return', 'StartScreen continue ordinary native save')
        restored = observe('12-restored-native-state', orbital)
        for field in ('credits', 'resources', 'player_cell', 'orbit', 'sector', 'star', 'ruler'):
            require(restored[field] == saved_state[field], 'native reload lost displayed ' + field)
        require(native_save.read_bytes() == save_bytes, 'load modified save before continued action')
        proof['save_load'] = dict(before=saved_state, restored=restored,
                                  compared_fields=['credits', 'resources', 'player_cell', 'orbit',
                                                   'sector', 'star', 'ruler'],
                                  turn_not_persisted_by_upstream=True)
        key(direction, 'continued orbital action after native save load')
        continued = observe('13-continued-native-action', orbital)
        require(continued['player_cell'] == moved['player_cell'] and
                continued['turn'] == restored['turn'] + 1 and
                continued['resources']['Fuel'][0] == restored['resources']['Fuel'][0] - 1,
                'loaded game did not perform real continued orbital maneuver')
        proof['continued_action'] = continued
        quit_game('14-normal-final-quit', False)
        require(not native_save.exists(), 'QuitScreen discard did not remove upstream save')
        proof['state_files'] = [dict(path=str(path.relative_to(root)), bytes=path.stat().st_size,
                                     sha256=sha(path.read_bytes()))
                                for path in root.rglob('*') if path.is_file()]
        proof['success'] = True
        save()
        print('EVERSECTOR_NATIVE_GAMEPLAY_OK')
        return 0
    except Exception:
        proof['failure'] = traceback.format_exc()
        save()
        traceback.print_exc()
        return 1
    finally:
        if capture and capture.display:
            capture.lib.XCloseDisplay(capture.display)
        # Only our processes are cleaned up; cleanup is never a successful quit.
        for process in (game, server):
            if process and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=10)


if __name__ == '__main__':
    sys.exit(main())
