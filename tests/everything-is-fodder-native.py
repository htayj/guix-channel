#!/usr/bin/env python3
"""Observe ordinary Fodder X11 gameplay and read, never inject, native saves.

Four fresh processes share one randomly created world: baseline Q; restore and
move Q; restore with no turns Q (exact player/clock/inventory comparison);
restore and continue moving Q. Every accepted movement is an exact source-backed
POS delta in native saves, not a pixel/time-only assertion. No private game API,
seed, config/state injection, process-memory access, or test hooks are used.
"""
import ctypes as C
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import re
import select
import struct
import subprocess
import sys
import time
import traceback
import zlib

WIDTH, HEIGHT = 1024, 680
COLS, ROWS, CW, CH = 128, 40, 8, 17
ASSETS = {
    'terminal.png': '7ed1cc4cc91e35b4b10330dcaac8ab2d4635174e69b8a9adc553f8067fc09c1f',
    'fodder.cfg': '8f5a3c6df9eb8761eace8f37f40dd7862ed587dddbf8ce174ee448dedd0df91d',
    'text.txt': '821821d01d9bdabc12f1462d2ddf661f7b0193d9bcd57d2f375f9c0a0ec0ab43',
    'rooms/village.map': '2945569c915aaeb2c8eab17533a0332677476d0e59e2043107513788d200f831',
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
        retained = Path('/tmp/fodder-evidence')
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


def font_masks(data):
    """Read the actual uncompressed 24-bit BMP despite its .png suffix.

    libtcod ASCII_INCOL selects column=code//16,row=code%16. The font
    is greyscale with a white background (sampled from the space glyph).
    """
    require(data[:2] == b'BM', 'original Oxygen font is not BMP')
    offset = struct.unpack_from('<I', data, 10)[0]
    header, width, height, planes, depth, compression = struct.unpack_from('<IiiHHI', data, 14)
    require((header, width, height, planes, depth, compression) ==
            (40, 128, 272, 1, 24, 0), 'Oxygen BMP format changed')
    stride = (width * 3 + 3) & ~3
    require(len(data) >= offset + stride * height, 'truncated font BMP')
    def pixel(x, y):
        return data[offset + (height - y - 1) * stride + x * 3 + 2]
    white = pixel((32 // 16) * CW + CW // 2, (32 % 16) * CH + CH // 2) > 128
    result = {}
    for code in range(32, 127):
        values = [pixel((code // 16) * CW + x, (code % 16) * CH + y)
                  for y in range(CH) for x in range(CW)]
        if white:
            values = [255 - x for x in values]
        peak = max(values)
        result[chr(code)] = sum(1 << i for i, x in enumerate(values) if peak and x > peak / 3)
    require(result[' '] == 0 and result['@'] != 0, 'invalid Oxygen glyph masks')
    return result


def surface(rgb, glyphs):
    rows = []
    for row in range(ROWS):
        line = ''
        for column in range(COLS):
            cell = [tuple(rgb[((row * CH + y) * WIDTH + column * CW + x) * 3:
                              ((row * CH + y) * WIDTH + column * CW + x) * 3 + 3])
                    for y in range(CH) for x in range(CW)]
            background = Counter(cell).most_common(1)[0][0]
            distances = [sum((a - b) ** 2 for a, b in zip(p, background)) for p in cell]
            peak = max(distances)
            mask = sum(1 << i for i, d in enumerate(distances) if peak and d > peak / 9)
            error, character = min(((mask ^ glyph).bit_count(), character)
                                   for character, glyph in glyphs.items())
            line += character if error <= CW * CH * .08 else '~'
        rows.append(line)
    return '\n'.join(rows)


class NativeSave:
    """Strict read-only reader for upstream MAP/ROOM/MOB/ITEM::save.

    Native x86_64 Guix representation: s32 little endian and bool/u8 one byte.
    glbdef.h defines 10 YELL entries and MOB_AVATAR=1, ITEM_COIN=11.
    No byte-pattern search for a plausible avatar is permitted: all rooms and
    entities are traversed and the parser must consume the entire file.
    """
    def __init__(self, data):
        self.data, self.offset = data, 0
        self.clock, self.depth = self.ints(2)
        self.item_globals = [self.ints(2) for _ in range(self.count())]
        self.taint = self.integer()
        self.portals = [(self.pos(), self.integer()) for _ in range(2)]
        self.rooms, avatars = {}, []
        for _ in range(self.count()):
            room_id, seed = self.ints(2)
            symbol = self.take(1)[0]
            depth, room_type, width, height = self.ints(4)
            require(0 < width <= 1024 and 0 < height <= 1024, 'invalid saved room dimensions')
            items = [self.item() for _ in range(self.count())]
            mobs = [self.mob() for _ in range(self.count())]
            portals = [(self.pos(), self.pos()) for _ in range(self.count())]
            tiles, flags = self.take(width * height), self.take(width * height)
            jacob = self.ints(4)
            atlas = self.ints(2)
            connectivity = self.ints(4)
            require(room_id not in self.rooms, 'duplicate native room ID')
            self.rooms[room_id] = dict(id=room_id, seed=seed, symbol=symbol, depth=depth,
                type=room_type, width=width, height=height, items=items, mobs=mobs,
                portals=portals, tiles=tiles, flags=flags, jacob=jacob,
                atlas=atlas, connectivity=connectivity)
            avatars.extend(m for m in mobs if m['definition'] == 1)
        require(self.offset == len(data), 'unparsed trailing or truncated native save')
        require(len(avatars) == 1, 'native save does not contain exactly one avatar')
        self.avatar = avatars[0]
        x, y, angle, room = self.avatar['position']
        require(room in self.rooms and 0 <= angle < 4 and self.avatar['hp'] > 0,
                'avatar is dead or has invalid saved position')
        r = self.rooms[room]
        require(0 <= x < r['width'] and 0 <= y < r['height'] and self.clock >= 1,
                'invalid saved avatar coordinates/clock')

    def take(self, n):
        require(0 <= n <= len(self.data) - self.offset, 'truncated native save')
        value = self.data[self.offset:self.offset + n]
        self.offset += n
        return value

    def ints(self, n):
        return list(struct.unpack('<' + 'i' * n, self.take(4 * n)))

    def integer(self):
        return self.ints(1)[0]

    def count(self):
        n = self.integer()
        require(0 <= n <= 100000, 'invalid native save count')
        return n

    def pos(self):
        return self.ints(4)

    def item(self):
        definition, position = self.integer(), self.pos()
        count, timer, uid, interested_uid = self.ints(4)
        flags = list(self.take(2))
        require(all(x in (0, 1) for x in flags), 'invalid item bools')
        mob, element, material, gilt, seed = self.ints(5)
        return dict(definition=definition, position=position, count=count, timer=timer,
                    uid=uid, interested_uid=interested_uid, broken=flags[0], equipped=flags[1],
                    mob=mob, element=element, material=material, gilt=gilt, seed=seed)

    def mob(self):
        definition = self.integer()
        name = self.take(self.count()).hex()
        positions = [self.pos() for _ in range(4)]
        waiting = self.take(1)[0]
        values = self.ints(18)
        flags = list(self.take(4))
        yells = list(self.take(20))
        require(waiting in (0, 1) and all(x in (0, 1) for x in flags + yells),
                'invalid mob bools')
        inventory = [self.item() for _ in range(self.count())]
        return dict(definition=definition, name_hex=name, position=positions[0],
                    other_positions=positions[1:], waiting=waiting, hp=values[0],
                    stats=values, flags=flags, yells=yells, inventory=inventory)

    def record(self):
        return dict(clock=self.clock, depth=self.depth, taint=self.taint,
                    avatar=self.avatar, room_count=len(self.rooms), bytes=len(self.data),
                    sha256=sha(self.data))


def rotate(angle, dx, dy):
    return [(dx, dy), (-dy, dx), (-dx, -dy), (dy, -dx)][angle]


def movement_choice(saved, text):
    """Choose one visible adjacent floor, excluding portals and occupied cells.

    Read-only save observation determines local coordinates; actual framebuffer
    must independently show @ beside a floor glyph. No worlds are retried.
    """
    x, y, angle, room_id = saved.avatar['position']
    room = saved.rooms[room_id]
    rows = text.splitlines()
    # main.cpp constructs DISPLAY(0,0,128,30,...); redrawWorldNoFlush uses
    # avatar->meditatePos(). mob.h returns pos() unless meditating, and
    # DISPLAY::display maps cache(0,0) to (width/2,height/2). NPCs can also
    # use '@', so glyph uniqueness is neither expected nor player identity.
    require(saved.avatar['other_positions'][0][3] == -1,
            'camera is detached from avatar by meditation')
    px, py = COLS // 2, (ROWS - 10) // 2
    require(rows[py][px] == '@', 'source-centered native player glyph absent')
    occupied = {tuple(m['position'][:2]) for m in room['mobs']}
    portals = {tuple(p[0][:2]) for p in room['portals']}
    # Plain floor family only: no doors, terrain hazards, stairs or portals.
    for key, dx, dy in [('l', 1, 0), ('j', 0, 1), ('h', -1, 0), ('k', 0, -1)]:
        lx, ly = rotate(angle, dx, dy)
        nx, ny = x + lx, y + ly
        if not (0 <= nx < room['width'] and 0 <= ny < room['height']):
            continue
        if (nx, ny) in occupied or (nx, ny) in portals:
            continue
        tile = room['tiles'][ny * room['width'] + nx]
        if tile not in (5, 6, 7, 8, 13, 14, 15, 16, 17, 18):
            continue
        if 0 <= py + dy < ROWS and 0 <= px + dx < COLS and rows[py + dy][px + dx] in '.,':
            return dict(key=key, screen_delta=[dx, dy], local_delta=[lx, ly],
                        before=[x, y, angle, room_id], expected=[nx, ny, angle, room_id],
                        source_tile=tile, observed_floor=rows[py + dy][px + dx])
    raise AssertionError('no safely observed adjacent floor in this ordinary world')


def same_player(before, after):
    # MOB::load clears cached AI targets; only fields actually promised here are
    # compared. Position/health/inventory plus native clock are mandatory.
    return (before.clock == after.clock and before.depth == after.depth and
            before.taint == after.taint and
            all(before.avatar[k] == after.avatar[k] for k in
                ('definition', 'name_hex', 'position', 'hp', 'inventory')))


def main():
    require(len(sys.argv) == 3, 'usage: everything-is-fodder-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    proof = dict(success=False, output=str(output), injected_state=False,
                 movement_observation='exact native saved POS delta plus observed adjacent floor',
                 claim_limits=['No full game/victory/combat or spell coverage.',
                               'Transmutation only claimed if native item/coin and taint transition proved.'])
    game = output / 'bin/everything-is-fodder'
    assets = output / 'share/everything-is-fodder'
    processes, game_logs = [], []
    capture = None
    try:
        proof['driver_namespace'] = namespace_proof(Path('/proc/self'), evidence)
        for name, expected in ASSETS.items():
            require(sha((assets / name).read_bytes()) == expected, 'modified original asset: ' + name)
        proof['assets'] = ASSETS
        sources = assets / 'source/game'
        source_names = ('map.cpp', 'map.h', 'mob.cpp', 'mob.h', 'item.cpp', 'buf.cpp',
                        'main.cpp', 'display.cpp', 'gfxengine.h', 'glbdef.h')
        proof['sources'] = {name: sha((sources / name).read_bytes()) for name in source_names}
        require('#define SCR_WIDTH 128' in (sources / 'gfxengine.h').read_text() and
                '#define SCR_HEIGHT 40' in (sources / 'gfxengine.h').read_text(), 'source geometry differs')
        require('new DISPLAY(0, 0, SCR_WIDTH, SCR_HEIGHT-10, 80)' in
                (sources / 'main.cpp').read_text() and
                'lookup(x-myW/2, y-myH/2)' in (sources / 'display.cpp').read_text() and
                'return pos();' in (sources / 'mob.h').read_text(),
                'source-backed player camera mapping differs')
        docs = output / 'share/doc/everything-is-fodder'
        require(docs.is_dir() and any(docs.iterdir()), 'source/license notices missing')
        for path in output.rglob('*'):
            require(path.suffix.lower() not in ('.exe', '.dll'), 'foreign opaque binary installed')
        glyphs = font_masks((assets / 'terminal.png').read_bytes())
        evidence, store_mounts = isolate_mounts(evidence)
        proof['store_read_only_mounts'] = store_mounts
        root = Path('/tmp/fodder-private')
        root.mkdir(mode=0o700)
        dirs = {}
        for variable, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'), ('TMPDIR', 'tmp')]:
            dirs[variable] = root / name
            dirs[variable].mkdir(mode=0o700)
        work = root / 'work'
        work.mkdir(mode=0o700)
        env = dict(os.environ, **{k: str(v) for k, v in dirs.items()})
        env.update(SDL_VIDEODRIVER='x11', SDL_AUDIODRIVER='dummy', SDL_RENDER_DRIVER='software',
                   LIBGL_ALWAYS_SOFTWARE='1', MESA_SHADER_CACHE_DISABLE='true',
                   DBUS_SESSION_BUS_ADDRESS='unix:path=/run/no-session-bus',
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path=/run/no-system-bus')
        state = dirs['XDG_DATA_HOME'] / 'everything-is-fodder'
        save = state / 'save/Default.sav'
        require(not state.exists(), 'fresh XDG data not empty')
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)

        def start(label, command, **kwargs):
            with (evidence / (label + '.log')).open('wb') as log:
                child = subprocess.Popen(command, cwd=work, env=env, stdin=subprocess.DEVNULL,
                                         stdout=log, stderr=log, **kwargs)
            processes.append(child)
            return child

        def tool(*args):
            return subprocess.check_output([os.environ['XDOTOOL'], *args], env=env,
                                           stderr=subprocess.PIPE, timeout=10)

        def key(name):
            require(process.poll() is None, 'game exited before input ' + name)
            if name in ('h', 'j', 'k', 'l'):
                # gfx_cookDir explicitly maps these ordinary vi letters to the
                # same cardinal ACTION_BUMP as arrows. Use an explicit XTest
                # press/release pair and observe server key-up; the exact saved
                # coordinate assertion still rejects any repeated movement.
                tool('keydown', '--clearmodifiers', name)
                try:
                    time.sleep(.06)
                finally:
                    tool('keyup', name)
                lib = capture.lib
                lib.XStringToKeysym.argtypes = [C.c_char_p]
                lib.XStringToKeysym.restype = C.c_ulong
                lib.XKeysymToKeycode.argtypes = [C.c_void_p, C.c_ulong]
                lib.XKeysymToKeycode.restype = C.c_ubyte
                lib.XQueryKeymap.argtypes = [C.c_void_p, C.c_void_p]
                lib.XQueryKeymap.restype = C.c_int
                code = lib.XKeysymToKeycode(capture.display, lib.XStringToKeysym(name.encode()))
                require(code != 0, 'native directional keysym unavailable')
                bits = C.create_string_buffer(32)
                lib.XQueryKeymap(capture.display, bits)
                require(not bits.raw[code // 8] & (1 << (code % 8)),
                        'native directional key still pressed after release')
            else:
                tool('key', '--clearmodifiers', name)
            time.sleep(.35)

        readfd, writefd = os.pipe()
        try:
            server = start('xvfb', [os.environ['XVFB'], '-displayfd', str(writefd),
                '-screen', '0', '1280x800x24', '-nolisten', 'tcp', '-noreset'], pass_fds=(writefd,))
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
        capture = XCapture(env['DISPLAY'])
        process = None
        window = None
        saved_config = None
        proof['launches'] = []

        def frame(label):
            require(process.poll() is None, 'native game exited during ' + label)
            rgb = capture.capture(int(window))
            save_png(evidence / (label + '.png'), rgb)
            text = surface(rgb, glyphs)
            (evidence / (label + '-surface.txt')).write_text(text + '\n')
            require(not re.search(r'(?i)assertion failed|segmentation fault|fatal error|traceback', text),
                    'native error visible in framebuffer')
            return text

        def launch(label, restoring=False):
            nonlocal process, window
            if restoring:
                require(save.is_file(), 'missing normal native save before restoration')
            process = start('game-' + label, [str(game)])
            game_logs.append(evidence / ('game-' + label + '.log'))
            deadline = time.monotonic() + 25
            while time.monotonic() < deadline:
                require(process.poll() is None, 'native game exited before options')
                found = subprocess.run([os.environ['XDOTOOL'], 'search', '--onlyvisible',
                    '--name', '^Everything Is Fodder$'], env=env, capture_output=True, timeout=5)
                if found.returncode == 0 and (not restoring or not save.exists()):
                    window = found.stdout.decode().splitlines()[-1]
                    tool('windowfocus', '--sync', window)
                    time.sleep(.6)
                    proc = Path('/proc') / str(process.pid)
                    namespaces = namespace_proof(proc, evidence)
                    require(Path(os.readlink(proc / 'exe')).resolve() ==
                            (output / 'libexec/everything-is-fodder').resolve(), 'launcher did not exec game')
                    require(Path(os.readlink(proc / 'cwd')) == state / 'linux', 'wrong writable working directory')
                    proof['launches'].append(dict(label=label, pid=process.pid, namespaces=namespaces,
                        save_consumed_before_play=restoring and not save.exists()))
                    require('Play' in frame(label + '-options'), 'ordinary Play options absent')
                    if not restoring:
                        require((state / 'fodder.cfg').read_bytes() == (assets / 'fodder.cfg').read_bytes(),
                                'launcher modified initial default config')
                    key('Return')
                    welcome = frame(label + '-welcome')
                    require(('return to your attempt' if restoring else 'evil demon lord') in welcome,
                            'ordinary new-game/restore welcome missing')
                    key('space')
                    text = frame(label + '-game')
                    require('Depth:' in text and 'Inventory:' in text, 'native gameplay HUD absent')
                    return text
                time.sleep(.15)
            raise AssertionError('native options/save consumption timed out')

        def confinement():
            expected_links = {'linux/terminal.png': assets / 'terminal.png',
                              'text.txt': assets / 'text.txt',
                              'rooms/village.map': assets / 'rooms/village.map'}
            for name, target in expected_links.items():
                require((state / name).is_symlink() and (state / name).resolve() == target,
                        'asset not linked to immutable output: ' + name)
            for name in ('HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME',
                         'XDG_RUNTIME_DIR', 'TMPDIR'):
                require(not list(dirs[name].iterdir()), 'game wrote outside private data: ' + name)
            require(not list(work.iterdir()) and list(dirs['XDG_DATA_HOME'].iterdir()) == [state],
                    'unexpected writes outside game data')
            paths = {str(p.relative_to(state)) for p in state.rglob('*')}
            expected = {'linux', 'rooms', 'save', 'fodder.cfg', 'save/Default.sav', 'save/Default.txt',
                        *expected_links}
            require(paths == expected, 'unexpected mutable paths: ' + repr(paths ^ expected))
            config = state / 'fodder.cfg'
            require(not config.is_symlink() and config.stat().st_mode & 0o200 and
                    (saved_config is None or config.read_bytes() == saved_config), 'caller config altered on restart')
            require(all(not p.is_symlink() and p.stat().st_mode & 0o200
                        for p in (save, state / 'save/Default.txt')), 'save not private writable regular files')

        def quit_save(label):
            frame(label + '-before-quit')
            key('shift+q')
            require(process.wait(timeout=20) == 0, 'normal uppercase Q quit failed')
            log = game_logs[-1].read_text(errors='replace')
            # Reject native diagnostics even when upstream returns status zero.
            require(not re.search(r'(?i)error|failed|fatal|assert|segmentation|exception|could not|cannot|warning', log),
                    'native diagnostics in ' + str(game_logs[-1]))
            confinement()
            data = save.read_bytes()  # observation only; never written back to the game
            parsed = NativeSave(data)
            (evidence / (label + '.sav')).write_bytes(data)
            write_json(evidence / (label + '-save.json'), parsed.record())
            return parsed

        launch('baseline')
        key('question')
        help_text = frame('help')
        require('Command Keys:' in help_text and 'Quit and Save' in help_text and
                'Transmute Items' in help_text, 'native help missing')
        key('Escape')
        baseline = quit_save('baseline')
        saved_config = (state / 'fodder.cfg').read_bytes()

        text = launch('movement', restoring=True)
        choice = movement_choice(baseline, text)
        key(choice['key'])
        frame('directional-action')
        key('i')
        inventory_text = frame('inventory')
        require('nothing' in inventory_text.lower() or '(equipped)' in inventory_text or
                inventory_text != text, 'inventory chooser not observed')
        key('Escape')
        # A bounded ordinary transmutation is available if a carried item or the
        # floor reached by the one safe move has a real base material. Never
        # claim that an empty-air command exercises the conversion mechanic.
        eligible = [(i, item) for i, item in enumerate(baseline.avatar['inventory'])
                    if item['material'] != 0 and item['definition'] != 11 and not item['equipped']]
        ground = [item for item in baseline.rooms[choice['before'][3]]['items']
                  if item['position'][:2] == choice['expected'][:2] and
                  item['material'] != 0 and item['definition'] != 11]
        transmute_item = None
        if eligible:
            index, transmute_item = eligible[0]
            key('i')
            key('Home')
            for _ in range(index):
                key('Down')
            frame('transmute-inventory-selection')
            key('t')
        elif len(ground) == 1:
            transmute_item = ground[0]
            key('t')
        if transmute_item is not None:
            transmuted_text = frame('transmuted')
            require('dissolve' in transmuted_text and 'transmute' in transmuted_text,
                    'ordinary transmutation message absent')
        moved = quit_save('moved')
        if transmute_item is not None:
            require(moved.taint == baseline.taint + 1 and
                    not any(i['uid'] == transmute_item['uid'] for i in moved.avatar['inventory']) and
                    not any(i['uid'] == transmute_item['uid']
                            for r in moved.rooms.values() for i in r['items']) and
                    sum(i['count'] for i in moved.avatar['inventory'] if i['definition'] == 11) >
                    sum(i['count'] for i in baseline.avatar['inventory'] if i['definition'] == 11),
                    'native transmutation did not consume item and create coins/taint')
        proof['transmutation'] = dict(exercised=transmute_item is not None,
            item=transmute_item, reason=None if transmute_item is not None else
            'No convertible carried or safely adjacent ground item; no empty-air success claim.')
        require(moved.avatar['position'] == choice['expected'] and moved.clock > baseline.clock,
                'directional input did not produce exact native coordinate delta')
        proof['movement'] = dict(choice=choice, before=baseline.record(), after=moved.record())

        launch('restore-comparison', restoring=True)
        restored = quit_save('restored')
        require(same_player(moved, restored), 'fresh process lost native player/clock/inventory state')
        proof['restore'] = dict(exact_player_clock_inventory=True, saved=restored.record())

        text = launch('continued', restoring=True)
        continued_choice = movement_choice(restored, text)
        key(continued_choice['key'])
        frame('continued-directional-action')
        continued = quit_save('continued')
        require(continued.avatar['position'] == continued_choice['expected'] and
                continued.clock > restored.clock, 'restored directional action did not move native player')
        proof['continued_movement'] = dict(choice=continued_choice, after=continued.record())
        proof['inventory_exercised'] = True
        proof['state_confinement'] = True
        proof['framebuffer'] = dict(width=WIDTH, height=HEIGHT, columns=COLS, rows=ROWS,
                                    glyph_width=CW, glyph_height=CH, font='exact Oxygen BMP ASCII_INCOL')
        proof['success'] = True
    except BaseException as error:
        proof['failure'] = str(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        raise
    finally:
        # Persist even a failed proof before touching X resources. Xlib's
        # default I/O handler can terminate Python if the server is already gone.
        write_json(evidence / 'native-gameplay.json', proof)
        if capture is not None:
            capture.lib.XCloseDisplay(capture.display)
        for child in reversed(processes):
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait(timeout=5)
    print('Everything Is Fodder: exact native movement, save/load and continued movement proved')


if __name__ == '__main__':
    try:
        main()
    except BaseException:
        traceback.print_exc()
        sys.exit(1)
