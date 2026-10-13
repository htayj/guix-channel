#!/usr/bin/env python3
"""Observe EtRD's ordinary LWJGL application, never execute a game oracle.

Source contract: MainMenuScreen, InGameScreen, AI_Player_Controlled,
LevelLoadingScreen, LevelGraphics, InventoryScreen and RecipeScreen in the
installed original source.  BitmapFont's original default.fnt/default.png are
read-only glyph references, not a game renderer.  Every evidence picture is
XGetImage of the real window.  All input is XTest on an isolated X server.

Native autosave is GameData.finishLoading's ordinary writer.  Continue loads
that initial level snapshot after genuine movement; its displayed spawn map
must agree with the original map before continued movement.  Do not fabricate
or deserialize a save.  Success additionally requires mouse-look, the native
inventory slots and real recipe ingredient selection, then ordinary menu Exit.
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
import xml.etree.ElementTree as ET
import zipfile
import zlib

WIDTH, HEIGHT = 800, 600
COMMIT = 'ebd9259561f6f3a27ccb3ec6e08bb43b11cee780'


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
        retained = Path('/tmp/etrd-evidence')
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


class Font:
    """Match complete source text by original glyph interiors and dark holes.

    Opaque white strokes must be >=220 in each channel.  Interior transparent
    holes must not be white.  Antialiased boundary pixels are intentionally not
    compared, but all non-space letters and their source advances are required.
    """
    def __init__(self, descriptor, bitmap, origin=(0, 0)):
        width, height, pixels = decode_png(bitmap)
        self.glyphs, self.kerns = {}, {}
        for line in descriptor.decode().splitlines():
            fields = dict((k, int(v)) for k, v in re.findall(r'(\w+)=(-?\d+)', line))
            if line.startswith('char '):
                self.glyphs[chr(fields['id'])] = fields
            elif line.startswith('kerning '):
                self.kerns[(chr(fields['first']), chr(fields['second']))] = fields['amount']
        self.pixels, self.width = pixels, width
        self.origin = origin
        require(all(0 <= g['x'] + origin[0] and 0 <= g['y'] + origin[1] and
                    g['x'] + origin[0] + g['width'] <= width and
                    g['y'] + origin[1] + g['height'] <= height
                    for g in self.glyphs.values()), 'font glyph outside immutable texture')
        self.cache = {}

    def pattern(self, text):
        if text in self.cache:
            return self.cache[text]
        advance, previous = 0, None
        composed, interiors = {}, set()
        for char in text:
            g = self.glyphs[char]
            advance += self.kerns.get((previous, char), 0)
            for y in range(g['height']):
                for x in range(g['width']):
                    p = self.pixels[(self.origin[1] + g['y'] + y) * self.width +
                                    self.origin[0] + g['x'] + x]
                    at = (advance + g['xoffset'] + x, g['yoffset'] + y)
                    # BitmapFontCache draws glyph quads in character order with
                    # SpriteBatch SRC_ALPHA / ONE_MINUS_SRC_ALPHA.  Padding and
                    # translucent shadows of a later glyph can cover an earlier
                    # white stroke; a union of glyph masks is not the rendered word.
                    q = composed.get(at, (0, 0, 0, 0))
                    alpha = p[3] / 255
                    composed[at] = tuple(p[i] * alpha + q[i] * (1 - alpha)
                                         for i in range(3)) + (
                                             p[3] + q[3] * (1 - alpha),)
                    if 2 <= x < g['width'] - 2 and 2 <= y < g['height'] - 2:
                        interiors.add(at)
            advance += g['xadvance']
            previous = char
        bright = [at for at, p in composed.items() if min(p[:3]) > 230 and p[3] > 230]
        dark = [at for at in interiors
                if composed[at][3] < 15 or max(composed[at][:3]) < 15]
        require(len(bright) >= 8, 'text oracle has insufficient glyph interiors')
        # Spread cheap rejection probes across the entire word before full match.
        probes = bright[::max(1, len(bright) // 12)]
        self.cache[text] = bright, dark, probes, advance
        return self.cache[text]

    def find(self, rgb, text, region=(0, 0, WIDTH, HEIGHT)):
        bright, dark, probes, advance = self.pattern(text)
        x0, y0, x1, y1 = region
        low_x = min(x for x, _ in bright + dark)
        high_x = max(x for x, _ in bright + dark)
        low_y = min(y for _, y in bright + dark)
        high_y = max(y for _, y in bright + dark)
        white = bytes(1 if min(rgb[i:i + 3]) >= 220 else 0 for i in range(0, len(rgb), 3))
        for y in range(max(y0, -low_y), min(y1, HEIGHT - high_y)):
            row = y * WIDTH
            for x in range(max(x0, -low_x), min(x1, WIDTH - high_x)):
                start = row + x
                if (all(white[start + dy * WIDTH + dx] for dx, dy in probes) and
                        all(white[start + dy * WIDTH + dx] for dx, dy in bright) and
                        all(not white[start + dy * WIDTH + dx] for dx, dy in dark)):
                    return dict(text=text, x=x, y=y, width=advance, height=20)
        return None


def changed_pixels(before, after, threshold=12):
    require(len(before) == len(after), 'region geometry changed')
    return sum(max(abs(a - b) for a, b in zip(before[i:i + 3], after[i:i + 3])) > threshold
               for i in range(0, len(before), 3))


def source_map_palette(output):
    """Original biome RGB, packed font alpha, RGBA4444 FBO, then screen blend."""
    source = output / 'share/etrd/assets/data/xml/biomes.data'
    biome = ET.fromstring(source.read_bytes()).find('start_town')
    require(biome is not None, 'source first-level biome absent')
    colours = {}
    for symbol, tag in (('#', 'wall'), ('.', 'floor')):
        node = biome.find(tag)
        require(node is not None, 'source map colour absent: ' + tag)
        rgb = tuple(float(node.findtext(channel)) for channel in ('red', 'green', 'blue'))
        require(all(0 <= value <= 1 for value in rgb), 'source map colour outside RGB range')
        # Color.toFloatBits packs alpha254; opaque Arial texels first blend into
        # RGBA4444, then the map texture blends through SpriteBatch alpha254.
        colours[symbol] = tuple(round(round(int(value * 255) * 254 / 255 / 17) *
                                     17 * 254 / 255) for value in rgb)
    return colours


def map_translation(before, after, *, palette, continuity=False):
    """Rigid agreement of source-coloured glyph cores AND their negative holes.

    Only immutable source biome/FBO palette colours identify map foreground.
    Brown world edges and arbitrary screenshot-trained colours are not anchors.
    """
    side = 200
    colours = set(palette.values())
    require(colours, 'source map palette absent')

    def pixel(image, x, y):
        index = (y * side + x) * 3
        return tuple(image[index:index + 3])

    def usable(x, y):
        return 2 <= x < 198 and 2 <= y < 198 and not (
            88 <= x <= 122 and 88 <= y <= 122)

    foreground = {(x, y): pixel(before, x, y) for y in range(3, 197) for x in range(3, 197)
                  if usable(x, y) and pixel(before, x, y) in colours}
    after_foreground = {(x, y): pixel(after, x, y)
                        for y in range(3, 197) for x in range(3, 197)
                        if usable(x, y) and pixel(after, x, y) in colours}
    cells = {}
    # LevelGraphics.STEP=10 is the original glyph-placement spacing.
    for (x, y), value in foreground.items():
        cells.setdefault((x // 10, y // 10), []).append((x, y, value))
    anchors = []
    for (cx, cy), group in cells.items():
        holes = [(x, y) for y in range(cy * 10, cy * 10 + 10)
                 for x in range(cx * 10, cx * 10 + 10)
                 if usable(x, y) and (x, y) not in foreground]
        # Flat clamped texture/background areas are not letter silhouettes.
        if len(holes) >= 3:
            anchors.append((group, holes))
    if len(anchors) < 6:
        return None

    def matched(point, dx, dy):
        x, y, value = point
        return usable(x + dx, y + dy) and after_foreground.get((x + dx, y + dy)) == value

    def score(dx, dy):
        eligible = [(g, h) for g, h in anchors if
                    all(usable(x + dx, y + dy) for x, y, _ in g) and
                    all(usable(x + dx, y + dy) for x, y in h)]
        hits = [(g, h) for g, h in eligible if
                sum(matched(p, dx, dy) for p in g) >= len(g) * .70 and
                sum((x + dx, y + dy) not in after_foreground for x, y in h) >= len(h) * .90]
        if len(hits) < 6 or len(hits) < len(eligible) * .70:
            return None
        centres = [(sum(p[0] for p in g) / len(g), sum(p[1] for p in g) / len(g))
                   for g, _ in hits]
        blocks = {(int(x) // 40, int(y) // 40) for x, y in centres}
        if len(blocks) < 4:
            return None
        x0, y0 = centres[0]
        if not any(abs((x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)) > 25
                   for x1, y1 in centres[1:] for x2, y2 in centres[1:]):
            return None
        return dict(matched_anchors=len(hits), candidate_anchors=len(eligible),
                    matched_pixels=sum(matched(p, dx, dy) for g, _ in hits for p in g),
                    candidate_pixels=sum(len(g) for g, _ in eligible),
                    spatial_blocks=len(blocks), noncollinear=True,
                    source_foreground_colours=sorted(colours), negative_holes_verified=True)

    if continuity:
        result = score(0, 0)
        if result:
            return dict(result, dx_pixels=0, dy_pixels=0, channel_tolerance=0,
                        method='same-position source-palette native glyph silhouettes')
        return None
    points = [p for g, _ in anchors for p in g]
    probes = points[::max(1, len(points) // 18)]
    best = None
    for dy in range(-40, 41):
        for dx in range(-40, 41):
            if max(abs(dx), abs(dy)) < 2:
                continue
            eligible_probes = [p for p in probes if usable(p[0] + dx, p[1] + dy)]
            if not eligible_probes or sum(matched(p, dx, dy) for p in eligible_probes) < (
                    len(eligible_probes) * .65):
                continue
            result = score(dx, dy)
            if result and (best is None or result['matched_pixels'] > best[0]['matched_pixels']):
                best = result, dx, dy
    if best is None:
        return None
    result, dx, dy = best
    zero_hits = sum(matched(p, 0, 0) for g, _ in anchors for p in g)
    if result['matched_pixels'] <= zero_hits + result['candidate_pixels'] * .10:
        return None
    return dict(result, dx_pixels=dx, dy_pixels=dy, unchanged_matches=zero_hits,
                channel_tolerance=0, method='rigid source-palette native glyph silhouette translation')


def main():
    require(len(sys.argv) == 3, 'usage: etrd-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    proof = dict(output=str(output), source_commit=COMMIT, inputs=[], captures=[],
                 success=False, save_load_claimed=False, stair_traversal_claimed=False,
                 limitations=['Autosave occurs on level loading, not on every movement.',
                              'Continue resets the player to the level PlayerPlacer in upstream source.',
                              'Inventory menu inserts baseEquipment, while slots display carryEquipment.',
                              'Map observations establish displayed position, not exact world coordinates.'])
    game = server = capture = audio = None

    def save():
        write_json(evidence / 'native-gameplay.json', proof)

    try:
        require(output.is_absolute() and output.parent == Path('/gnu/store') and
                output.resolve(strict=True) == output, 'noncanonical package output')
        require(sys.flags.isolated and sys.flags.no_site, 'consumer Python is not isolated')
        proof['python'] = dict(executable=sys.executable, isolated=True, no_site=True)
        for path in [output, *output.rglob('*')]:
            mode = path.lstat().st_mode
            if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
                require(not mode & 0o222, 'writable output member: ' + str(path))
        proof['isolation'] = namespace_proof(Path('/proc/self'), evidence)
        evidence, store = isolate_mounts(evidence)
        proof['store_mounts'] = store
        root = Path('/tmp/etrd-state')
        root.mkdir(mode=0o700)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        env = dict(PATH='', LC_ALL='C', LIBGL_ALWAYS_SOFTWARE='1',
                   LIBGL_DRIVERS_PATH=os.environ['MESA_DRIVERS'],
                   MESA_SHADER_CACHE_DISABLE='true', ALSOFT_DRIVERS='pulse')
        for key, name in [('HOME', 'home'), ('XDG_DATA_HOME', 'data'),
                          ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache'),
                          ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                          ('TMPDIR', 'tmp')]:
            directory = root / name
            directory.mkdir(mode=0o700)
            env[key] = str(directory)
        work = root / 'work'
        work.mkdir()
        proof['clean_state_before'] = {key: os.listdir(env[key]) for key in
                                      ('HOME', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME',
                                       'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR')}
        require(not any(proof['clean_state_before'].values()), 'state not fresh')
        env.update(DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-session'),
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-system'),
                   PULSE_SERVER='unix:' + str(root / 'runtime/pulse-native'))
        proof['environment'] = env.copy()
        screens = (output / 'share/etrd/source/core/src/com/lyeeedar/Roguelike3D' /
                   'Graphics/Screens')
        require((screens / 'MainMenuScreen.java').is_file(),
                'installed original core/src MainMenuScreen source absent')
        requirements = {
            'MainMenuScreen.java': ['Enter the Roguelike Dimension', 'New Game',
                                    'GameData.init(game)', 'Inventory', 'Recipe', 'game.ANNIHALATE()'],
            'InGameScreen.java': ['Keys.TAB', 'Keys.ESCAPE', 'Render Type: ',
                                  'GameData.player.getPosition().x', 'GameData.player.getPosition().z'],
            'InventoryScreen.java': ['Equipment_Slot.HEAD', 'createRight(type)'],
            'RecipeScreen.java': ['Craft Recipe', 'recipeListMode = false'],
        }
        proof['source_oracles'] = {}
        for name, tokens in requirements.items():
            data = (screens / name).read_bytes()
            require(all(token in data.decode() for token in tokens), 'source contract changed: ' + name)
            proof['source_oracles'][name] = dict(path=str(screens / name), sha256=sha(data))
        game_source = screens.parent.parent / 'Game' / 'GameData.java'
        data = game_source.read_bytes()
        require(all(token in data.decode() for token in
                    ['SaveGame save = new SaveGame()', 'SaveGame.save(save)',
                     'player.positionAbsolutely', 'SaveGame.load()']),
                'original native autosave/load entrypoints absent')
        proof['source_oracles']['GameData.java'] = dict(path=str(game_source), sha256=sha(data))
        require('currentLevel = "start_town"' in data.decode(),
                'source initial biome changed')
        map_source = screens.parent.parent / 'Game/Level/LevelGraphics.java'
        map_bytes = map_source.read_bytes()
        require(all(token in map_bytes.decode() for token in
                    ('public static final int STEP = 10', 'Format.RGBA4444',
                     'font.setColor(colours.get(c).getColor())')),
                'source map glyph format/spacing/colour changed')
        map_palette = source_map_palette(output)
        biome_source = output / 'share/etrd/assets/data/xml/biomes.data'
        proof['map_palette_oracle'] = dict(path=str(biome_source),
                                          sha256=sha(biome_source.read_bytes()),
                                          biome='start_town', opaque_colours=map_palette,
                                          map_source_sha256=sha(map_bytes))
        # Resource bytes may remain loose or be packaged on the ordinary classpath.
        fonts = []
        for descriptor in output.rglob('default.fnt'):
            bitmap = descriptor.with_name('default.png')
            if bitmap.is_file():
                fonts.append((str(descriptor), descriptor.read_bytes(), bitmap.read_bytes()))
        if not fonts:
            for jar in output.rglob('*.jar'):
                with zipfile.ZipFile(jar) as archive:
                    if 'data/skins/default.fnt' in archive.namelist():
                        fonts.append((str(jar) + ':data/skins/default.fnt',
                                      archive.read('data/skins/default.fnt'),
                                      archive.read('data/skins/default.png')))
        require(fonts and all((f[1], f[2]) == (fonts[0][1], fonts[0][2]) for f in fonts),
                'original font absent/ambiguous')
        hud_font = Font(fonts[0][1], fonts[0][2])
        skin_root = output / 'share/etrd/assets/data/skins'
        atlas = (skin_root / 'uiskin.atlas').read_bytes()
        skin_json = (skin_root / 'uiskin.json').read_bytes()
        bitmap = (skin_root / 'uiskin.png').read_bytes()
        require('file: default.fnt' in skin_json.decode(),
                'original skin font declaration changed')
        region = re.search(r'(?:^|\n)default\n((?:[ \t].*\n)+)', atlas.decode())
        require(region, 'original default font atlas region absent')
        fields = dict(re.findall(r'^[ \t]+(\w+):[ \t]*(.*)$',
                                 region.group(1), re.MULTILINE))
        require(fields.get('rotate') == 'false' and fields.get('offset') == '0, 0' and
                fields.get('size') == fields.get('orig'),
                'unsupported transformed original font atlas region')
        origin = tuple(map(int, fields['xy'].split(',')))
        font = Font(fonts[0][1], bitmap, origin=origin)
        proof['font_oracle'] = dict(path=fonts[0][0], descriptor_sha256=sha(fonts[0][1]),
                                    bitmap_sha256=sha(fonts[0][2]),
                                    skin_texture_sha256=sha(bitmap), atlas_sha256=sha(atlas),
                                    skin_json_sha256=sha(skin_json), skin_region_origin=origin,
                                    method='separate source Skin atlas / AbstractScreen loose font matching')
        save()

        def tool(*args):
            result = subprocess.run([os.environ['XDOTOOL'], *map(str, args)], env=env, cwd=work,
                                    capture_output=True, text=True, timeout=15)
            with (evidence / 'tools.jsonl').open('a') as log:
                log.write(json.dumps(dict(command=[os.environ['XDOTOOL'], *map(str, args)],
                                          status=result.returncode, stdout=result.stdout,
                                          stderr=result.stderr)) + '\n')
            return result

        def start(label, args, **kwargs):
            with (evidence / (label + '.log')).open('wb') as log:
                return subprocess.Popen(args, env=env, cwd=work, stdin=subprocess.DEVNULL,
                                        stdout=log, stderr=log, **kwargs)
        pulse_config = root / 'pulse.pa'
        pulse_config.write_text('load-module module-native-protocol-unix socket=' +
                                str(root / 'runtime/pulse-native') + ' auth-anonymous=1\n'
                                'load-module module-null-sink sink_name=etrd_smoke\n'
                                'set-default-sink etrd_smoke\n')
        audio = start('pulseaudio', [os.environ['PULSEAUDIO'], '--daemonize=no',
                                   '--exit-idle-time=-1', '--use-pid-file=no',
                                   '--disable-shm=yes', '--log-target=stderr',
                                   '-n', '--file=' + str(pulse_config)])
        deadline = time.monotonic() + 20
        while not (root / 'runtime/pulse-native').exists() and time.monotonic() < deadline:
            require(audio.poll() is None, 'private audio daemon failed')
            time.sleep(.1)
        require(audio.poll() is None and (root / 'runtime/pulse-native').exists(),
                'private audio readiness timeout')
        info = subprocess.run([os.environ['PACTL'], 'info'], env=env, cwd=work,
                              capture_output=True, text=True, timeout=15)
        (evidence / 'pulse-info.txt').write_text(info.stdout + info.stderr)
        require(info.returncode == 0 and 'Default Sink: etrd_smoke' in info.stdout,
                'private real audio null sink absent')
        proof['audio_process'] = namespace_proof(Path('/proc') / str(audio.pid), evidence)


        readfd, writefd = os.pipe()
        try:
            server = start('xvfb', [os.environ['XVFB'], '-displayfd', str(writefd),
                                   '-screen', '0', '1024x768x24', '-nolisten', 'tcp',
                                   '-noreset', '+extension', 'GLX'], pass_fds=(writefd,))
            os.close(writefd)
            writefd = None
            require(select.select([readfd], [], [], 20)[0] and server.poll() is None,
                    'private Xvfb readiness absent')
            number = os.read(readfd, 64).decode().strip()
            require(number.isdigit(), 'invalid Xvfb displayfd')
            env['DISPLAY'] = ':' + number
        finally:
            os.close(readfd)
            if writefd is not None:
                os.close(writefd)
        proof['xserver'] = namespace_proof(Path('/proc') / str(server.pid), evidence)
        capture = XCapture(env['DISPLAY'])
        game = start('game', [str(output / 'bin/etrd')])
        deadline, window = time.monotonic() + 60, None
        while time.monotonic() < deadline:
            require(game.poll() is None, 'ordinary game exited before native window')
            result = tool('search', '--onlyvisible', '--pid', game.pid, '--name', '^Roguelike3D$')
            if result.returncode == 0:
                windows = result.stdout.split()
                require(len(windows) == 1, 'ambiguous native window')
                window = int(windows[0])
                break
            time.sleep(.2)
        require(window is not None, 'ordinary LWJGL window absent')
        proof['game_process'] = namespace_proof(Path('/proc') / str(game.pid), evidence)
        proc = Path('/proc') / str(game.pid)
        proof['command_line'] = (proc / 'cmdline').read_bytes().decode().split('\0')[:-1]
        proof['game_cwd'] = os.readlink(proc / 'cwd')
        require(proof['game_cwd'].startswith(str(root) + '/'), 'game escaped private state cwd')
        geometry = tool('getwindowgeometry', '--shell', window)
        require(geometry.returncode == 0 and 'WIDTH=800\n' in geometry.stdout and
                'HEIGHT=600\n' in geometry.stdout, 'ordinary window geometry changed')
        (evidence / 'window-geometry.txt').write_text(geometry.stdout)
        require(tool('windowfocus', '--sync', window).returncode == 0, 'native focus failed')

        def errors():
            log = (evidence / 'game.log').read_text(errors='replace')
            require(not re.search(r'Exception|(?:^|\n).*Error|UnsatisfiedLink|SIGSEGV|'
                                  r'Could not (?:load|initialize)|Failed to (?:load|create|initialize)|'
                                  r'ALSA lib|AL lib:.*(?:error|failed)|Shader.*(?:failed|error)', log,
                                  re.IGNORECASE), 'native runtime error (see unfiltered game.log)')
            require(server.poll() is None, 'private X server exited')
            require(audio.poll() is None, 'private audio daemon exited')

        def frame(label, rgb, observed=None):
            path = evidence / (label + '.png')
            save_png(path, rgb)
            proof['captures'].append(dict(file=path.name, sha256=sha(path.read_bytes()),
                                           observed=observed))
            save()

        def observe(label, predicate, timeout=30):
            deadline, rgb = time.monotonic() + timeout, None
            while time.monotonic() < deadline:
                errors()
                require(game.poll() is None, 'native game exited during ' + label)
                rgb = capture.capture(window)
                value = predicate(rgb)
                if value:
                    frame(label, rgb, value)
                    return rgb, value
                time.sleep(.15)
            if rgb is not None:
                frame(label + '-failed', rgb)
            raise AssertionError('source-backed native observation absent: ' + label)

        def text(rgb, phrase, region=(0, 0, WIDTH, HEIGHT)):
            oracle = hud_font if phrase.startswith(('Render Type:', '[E] ')) else font
            return oracle.find(rgb, phrase, region)
        renderer_labels = re.findall(r'return\s+"(Forward|Deferred - Final)"\s*;',
                                     (screens / 'InGameScreen.java').read_text())
        require(set(renderer_labels) == {'Forward', 'Deferred - Final'},
                'original final gameplay renderer labels absent')
        renderer_label = None

        def gameplay_hud(rgb):
            nonlocal renderer_label
            for label in ([renderer_label] if renderer_label else renderer_labels):
                match = text(rgb, 'Render Type: ' + label, (10, 15, 280, 75))
                if match:
                    renderer_label = label
                    proof['observed_render_type'] = label
                    return match
            return None


        def input_event(control, *args):
            proof['inputs'].append(dict(control=control, command=list(map(str, args)), method='XTest'))
            save()
            require(tool(*args).returncode == 0, 'native input failed: ' + control)
            errors()

        def key(name, control):
            input_event(control, 'keydown', name)
            time.sleep(.15)
            input_event(control, 'keyup', name)
            time.sleep(.2)

        def click(label, match):
            # --window affects only coordinate translation, not event injection.
            input_event(label, 'mousemove', '--window', window,
                        match['x'] + match['width'] // 2, match['y'] + 10)
            input_event(label, 'click', '1')
            time.sleep(.2)

        def menu(label):
            return observe(label, lambda rgb: text(rgb, 'Enter the Roguelike Dimension'))

        rgb, _ = menu('01-main-menu')
        _, button = observe('02-new-game-button', lambda rgb: text(rgb, 'New Game'))
        click('MainMenuScreen New Game', button)
        rgb, hud = observe('03-first-person', gameplay_hud, timeout=180)
        require('Level loading done in ' in (evidence / 'game.log').read_text(errors='replace'),
                'native level loading completion absent')
        native_save = Path(proof['game_cwd']) / 'game.sav'
        require(native_save.is_file() and not native_save.is_symlink(),
                'ordinary initial native autosave absent')
        save_bytes = native_save.read_bytes()
        require(len(save_bytes) > 1024 and save_bytes[:4] == b'\xac\xed\x00\x05',
                'native autosave is not a substantial Java serialization stream')
        (evidence / 'initial-native-autosave.sav').write_bytes(save_bytes)
        proof['initial_native_autosave'] = dict(path=str(native_save.relative_to(root)),
                                               bytes=len(save_bytes), sha256=sha(save_bytes),
                                               source='GameData.finishLoading394-397')
        maps = (proc / 'maps').read_text()
        (evidence / 'game-native-maps.txt').write_text(maps)
        for native in ('liblwjgl64.so', 'libgdx64.so'):
            require(native in maps, 'native library not mapped: ' + native)
        mesa_lib = Path(os.environ['MESA_DRIVERS']).resolve(strict=True).parent
        mesa_output = mesa_lib.parent
        require(mesa_output.parent == Path('/gnu/store'), 'Mesa tool is not a direct store output')
        front = (mesa_lib / 'dri/swrast_dri.so').resolve(strict=True)
        backends = list(mesa_lib.glob('libgallium-*.so'))
        require(len(backends) == 1, 'source-built Mesa Gallium backend absent/ambiguous')
        software_driver = str(backends[0].resolve(strict=True))
        libgl = str((mesa_lib / 'libGL.so.1').resolve(strict=True))
        require(Path(software_driver).is_relative_to(mesa_output) and
                Path(libgl).is_relative_to(mesa_output),
                'Mesa backend/GL escaped the resolved source-built input')
        mapped_paths = {fields[5] for line in maps.splitlines()
                        if len(fields := line.split(maxsplit=5)) == 6}
        require(software_driver in mapped_paths and libgl in mapped_paths,
                'exact source-built Mesa Gallium backend/GL not mapped in game')
        require(not any(('libgallium' in Path(path).name or
                         Path(path).name.startswith('libGL.so')) and
                        path not in {software_driver, libgl} for path in mapped_paths),
                'foreign Mesa Gallium/GL version mapped in game')
        require(env['LIBGL_ALWAYS_SOFTWARE'] == '1', 'software renderer selection missing')
        proof['software_mesa_driver'] = software_driver
        proof['mesa_mapping'] = dict(output=str(mesa_output), backend=software_driver,
                                     gl=libgl, dri_frontend=str(front),
                                     frontend_still_mapped=str(front) in mapped_paths,
                                     selection='LIBGL_ALWAYS_SOFTWARE=1; private Xvfb')
        proof['native_libraries'] = [line for line in maps.splitlines() if
                                     any(n in line for n in
                                         ('liblwjgl', 'libgdx', 'libopenal', software_driver, libgl))]
        world_before = crop(rgb, 230, 100, 550, 450)
        require(len(set(world_before)) > 16, 'first-person viewport lacks rendered scene')
        key('Tab', 'InGameScreen pause and reveal positional map')
        paused, _ = observe('04-paused-position-before', gameplay_hud)
        map_before = crop(paused, 10, HEIGHT - 210, 200, 200)
        require(changed_pixels(crop(rgb, 10, HEIGHT - 210, 200, 200), map_before) > 200,
                'Tab did not expose the source-defined map/tint')
        movement = None
        # Learn success from displayed map changes; never assume a timed key means movement.
        for direction in ('w', 'a', 'd', 's'):
            key('Tab', 'unpause before movement')
            input_event('AI_Player_Controlled movement ' + direction, 'keydown', direction)
            time.sleep(.8)
            input_event('release movement ' + direction, 'keyup', direction)
            time.sleep(.2)
            key('Tab', 'pause after movement')
            moved, _ = observe('05-movement-' + direction, gameplay_hud)
            map_after = crop(moved, 10, HEIGHT - 210, 200, 200)
            delta = changed_pixels(map_before, map_after)
            translation = map_translation(map_before, map_after, palette=map_palette)
            if delta > 100 and translation:
                movement = dict(key=direction, changed_map_pixels=delta,
                                map_before_sha256=sha(map_before), map_after_sha256=sha(map_after),
                                rectangle=[10, HEIGHT - 210, 200, 200],
                                translation=translation,
                                source='InGameScreen146-151: map sample origin follows player x/z')
                break
        require(movement, 'no displayed positional map change after real WASD movement')
        proof['position_observation'] = movement
        key('Tab', 'resume real first-person world')
        resumed, _ = observe('06-resumed-world', gameplay_hud)
        require(changed_pixels(world_before, crop(resumed, 230, 100, 550, 450)) > 500,
                'movement did not change the actual first-person scene')
        input_event('mouse look through native grabbed cursor', 'mousemove_relative', '--', '65', '0')
        time.sleep(.3)
        looked, _ = observe('07-mouse-look', gameplay_hud)
        require(changed_pixels(crop(resumed, 230, 100, 550, 450),
                               crop(looked, 230, 100, 550, 450)) > 500,
                'native mouse-look did not change world projection')
        # LevelLoadingScreen166-167 equips a right-hand torch/STAB and a left
        # FIREBALL. Untargeted attacks do not establish damage to an enemy.
        input_event('left-hand FIREBALL held', 'mousedown', '1')
        time.sleep(.6)
        input_event('left-hand FIREBALL released', 'mouseup', '1')
        input_event('right-hand torch stab held', 'mousedown', '3')
        time.sleep(.6)
        input_event('right-hand torch released', 'mouseup', '3')
        observe('08-native-attacks', gameplay_hud)
        proof['enemy_damage_claimed'] = False
        key('Escape', 'InGameScreen return to main menu')
        menu('09-returned-menu')
        require(sha(native_save.read_bytes()) == proof['initial_native_autosave']['sha256'],
                'initial autosave changed before ordinary Continue')
        _, button = observe('09a-continue-button', lambda rgb: text(rgb, 'Continue'))
        click('MainMenuScreen Continue reads genuine native autosave', button)
        loaded_world, _ = observe('09b-loaded-first-person', gameplay_hud, timeout=180)
        key('Tab', 'pause loaded snapshot to observe positional continuity')
        loaded_map_frame, continuity = observe('09c-loaded-position-continuity', lambda rgb:
                map_translation(map_before, crop(rgb, 10, HEIGHT - 210, 200, 200),
                                palette=map_palette, continuity=True))
        loaded_map = crop(loaded_map_frame, 10, HEIGHT - 210, 200, 200)
        proof['native_load_observation'] = dict(
            original_spawn_map_sha256=sha(map_before), loaded_map_sha256=sha(loaded_map),
            map_agreement=continuity, moved_position_retained=False,
            restored_state='original level-entry PlayerPlacer, as implemented upstream',
            autosave_after_load_sha256=sha(native_save.read_bytes()))
        after_load_movement = None
        for direction in ('w', 'a', 'd', 's'):
            key('Tab', 'resume loaded snapshot')
            input_event('continue native movement after load ' + direction, 'keydown', direction)
            time.sleep(.8)
            input_event('release post-load movement ' + direction, 'keyup', direction)
            time.sleep(.2)
            key('Tab', 'observe post-load positional map')
            current, delta = observe('09d-post-load-action-' + direction, gameplay_hud)
            translation = map_translation(loaded_map, crop(current, 10, HEIGHT - 210, 200, 200),
                                          palette=map_palette)
            if translation:
                after_load_movement = dict(key=direction, translation=translation)
                break
        require(after_load_movement, 'loaded game did not support continued native movement')
        proof['continued_action_after_load'] = after_load_movement
        proof['save_load_claimed'] = True
        key('Tab', 'unpause after continued native action')
        # Interact only with a genuinely displayed source prompt.  Survey the
        # nearby native view; do not pretend a blind E press traversed a stair.
        interaction = None
        for turn in range(8):
            rgb = capture.capture(window)
            errors()
            door = text(rgb, '[E] Open Door')
            stair = text(rgb, '[E] Change Level')
            if door or stair:
                frame('09d-activation-prompt', rgb, door or stair)
                before_log = (evidence / 'game.log').read_text(errors='replace')
                key('e', 'InGameScreen activate displayed native prompt')
                if door:
                    observe('09d-door-opened', lambda rgb: text(rgb, '[E] Close Door'))
                    interaction = dict(kind='door', before='[E] Open Door',
                                       after='[E] Close Door')
                else:
                    observe('09d-native-next-level', lambda rgb:
                            gameplay_hud(rgb)
                            if (evidence / 'game.log').read_text(errors='replace').count(
                                'Level loading done in ') > before_log.count(
                                    'Level loading done in ') else None, timeout=180)
                    interaction = dict(kind='stair', prompt='[E] Change Level',
                                       next_level_loaded=True)
                    proof['stair_traversal_claimed'] = True
                break
            input_event('survey nearby native activation prompts',
                        'mousemove_relative', '--', '65', '0')
            time.sleep(.2)
        proof['native_interaction_observation'] = interaction
        if interaction is None:
            proof['limitations'].append('No nearby door/stair prompt observed in bounded native view survey.')
        key('Escape', 'loaded game returns to ordinary main menu')
        menu('09e-loaded-game-return')
        _, button = observe('10-inventory-button', lambda rgb: text(rgb, 'Inventory'))
        click('ordinary upstream inventory menu', button)
        def inventory_slots(rgb):
            matches = [text(rgb, slot) for slot in ('HEAD', 'BODY', 'LEGS', 'BOOTS',
                                                   'L_HAND', 'R_HAND')]
            return matches if all(matches) else None

        _, slots = observe('11-native-inventory-payload', inventory_slots)
        click('InventoryScreen choose HEAD slot', slots[0])
        observe('12-head-slot-view', inventory_slots)
        click('InventoryScreen choose BODY slot', slots[1])
        observe('13-body-slot-view', inventory_slots)
        proof['inventory_observation'] = dict(slots=[m['text'] for m in slots],
                                              selected_slots=['HEAD', 'BODY'],
                                              carried_equipment_expected_empty=True,
                                              equipped_item_claimed=False)
        key('Escape', 'InventoryScreen return menu')
        menu('14-inventory-return')
        _, button = observe('15-recipe-button', lambda rgb: text(rgb, 'Recipe'))
        click('ordinary upstream recipe menu', button)
        _, craft = observe('16-native-recipe-list', lambda rgb: text(rgb, 'Craft Recipe'))
        observe('17-recipe-payload', lambda rgb: text(rgb, 'Rarity:'))
        click('RecipeScreen enter component crafting view', craft)
        recipe_source = (output / 'share/etrd/assets/data/xml/recipes.data')
        visual = ET.fromstring(recipe_source.read_bytes()).find('sword/visual')
        require(visual is not None and visual.findtext('width') == '1' and
                visual.findtext('height') == '3' and
                [row.text for row in visual.findall('grid/row')] == ['a', 'b', 'c'],
                'original blade_edge-first recipe grid changed')
        recipe_code = (screens / 'RecipeScreen.java').read_text()
        require(all(token in recipe_code for token in
                    ('class CraftButton extends Button', 'view.add(cb).width(20).height(20)',
                     'table.add(left).width(200)', 'table.setFillParent(true)')),
                'source recipe slot layout changed')
        patch = re.search(r'(?:^|\n)default-round\n((?:[ \t].*\n)+)', atlas.decode())
        require(patch, 'source default-round button patch absent')
        patch_fields = dict(re.findall(r'^[ \t]+(\w+):[ \t]*(.*)$',
                                       patch.group(1), re.MULTILINE))
        require(patch_fields.get('rotate') == 'false' and
                patch_fields.get('size') == '12, 20' and
                patch_fields.get('split') == '5, 5, 5, 4' and
                patch_fields.get('offset') == '0, 0',
                'source crafting button nine-patch geometry changed')
        px, py = map(int, patch_fields['xy'].split(','))
        probes = []
        # A20px Button stretches only the two central texture columns; its
        # five-pixel left/right patches retain their actual atlas silhouettes.
        for y in range(20):
            for x in range(20):
                sx = x if x < 5 else x - 8 if x >= 15 else 5 + (x - 5) // 5
                p = font.pixels[(py + y) * font.width + px + sx]
                if p[3] == 255:
                    probes.append((x, y, tuple(round(c * 254 / 255) for c in p[:3])))
        require(len(probes) >= 40, 'source button patch lacks opaque image probes')
        left_x = (WIDTH - 3 * 200) // 2 + (200 - 20) // 2
        top_y = (HEIGHT - 3 * 20) // 2

        def native_recipe_grid(rgb):
            for row in range(3):
                for x, y, expected in probes:
                    i = ((top_y + row * 20 + y) * WIDTH + left_x + x) * 3
                    if max(abs(a - b) for a, b in zip(rgb[i:i + 3], expected)) > 3:
                        return None
            return dict(x=left_x, y=top_y, width=20, height=20, text='source blade_edge button',
                        rows=3, source_patch='default-round', opaque_probes=len(probes))

        _, slot = observe('17a-source-image-verified-native-crafting-grid', native_recipe_grid)
        proof['crafting_grid_oracle'] = dict(source=str(recipe_source),
                                            sha256=sha(recipe_source.read_bytes()),
                                            observed=slot)
        click('select image-verified source blade_edge slot', slot)
        observe('18-component-crafting-view', lambda rgb: text(rgb, 'Recipe Ingredient'))
        observe('18a-component-name', lambda rgb: text(rgb, 'blade_edge'))
        _, tooth = observe('18b-native-component-choice', lambda rgb: text(rgb, 'Tooth thingy'))
        click('choose real recipe ingredient through native UI', tooth)
        observe('18c-selected-component-payload', lambda rgb: text(rgb, 'Crafting Component'))
        proof['recipe_observation'] = dict(ingredient='blade_edge',
                                           selected_component='Tooth thingy',
                                           crafted_item_claimed=False)
        key('Escape', 'RecipeScreen return menu')
        menu('19-recipe-return')
        _, button = observe('20-exit-button', lambda rgb: text(rgb, 'Exit'))
        click('MainMenuScreen Exit / Gdx.app.exit', button)
        status = game.wait(timeout=30)
        errors()
        proof['exit_status'] = status
        require(status == 0, 'ordinary menu Exit failed')
        require(tool('search', '--onlyvisible', '--pid', game.pid).returncode != 0,
                'native window survived ordinary exit')
        save_files = list(root.rglob('game.sav'))
        proof['save_files'] = [dict(path=str(path.relative_to(root)), bytes=path.stat().st_size,
                                    sha256=sha(path.read_bytes())) for path in save_files]
        proof['state_files'] = [dict(path=str(path.relative_to(root)), bytes=path.stat().st_size,
                                     sha256=sha(path.read_bytes())) for path in root.rglob('*')
                                if path.is_file()]
        proof['success'] = True
        save()
        print('ETRD_NATIVE_GAMEPLAY_OK')
        return 0
    except Exception:
        proof['failure'] = traceback.format_exc()
        save()
        traceback.print_exc()
        return 1
    finally:
        if capture and capture.display:
            capture.lib.XCloseDisplay(capture.display)
        # Only processes launched by this consumer are cleaned up.  A killed
        # game is never counted as the required ordinary menu exit.
        for process in (game, server, audio):
            if process and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=10)


if __name__ == '__main__':
    sys.exit(main())
