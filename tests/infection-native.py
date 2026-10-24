#!/usr/bin/env python3
"""External Infection 2013 consumer: original SDL window and physical XTEST.

Run only through infection-smoke.sh, never import the game or its bindings.
Source oracles: main.d menuInput/gameInput/charInput/helpInput and draw routines;
world.d updateWorld/draw; map.d draw/isWalkable; system.d move; data/gameData.js.
The camera keeps @ at (30,17), so movement is proved by exact translated native
wall pixels, NOT by claiming the screen-centred player changes screen position.
No save/load exists upstream. No RNG seeds, rerolls, injected state or hooks.
"""
from collections import Counter
import ctypes
import errno
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
import tempfile
import time
import traceback

COLS, ROWS, CELL = 60, 34, 16
WIDTH, HEIGHT = COLS * CELL, ROWS * CELL
FONT_HASH = 'cb17ade2c0a346af0de6f5d66877d68cf2736d1689ae7bc4dc4e34382e1720ce'
SOURCE = 'https://www.tndwolf.org/infection/infection_src.rar'
SOURCE_HASH = '1a9606c9e2e429b02af438b173ad91ea0ebe4af45defd6851844d6a6eb5a120a'
RENDERER = 'https://raw.githubusercontent.com/libtcod/libtcod/a7cabfda0b0c770d4092f0dec02efbd2a3b6d990/src/sys_sdl_c.c'
# Verbatim init_ascii_to_tcod[256] from the actual pinned SDL renderer.
# TCOD layout is 32 columns x 8 rows, NOT ASCII_INROW or ASCII_INCOL.
ASCII_TO_TCOD = (
      0,  0,  0,  0,  0,  0,  0,  0,  0, 76, 77,  0,  0,  0,  0,  0,
     71, 70, 72,  0,  0,  0,  0,  0, 64, 65, 67, 66,  0, 73, 68, 69,
      0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
     16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
     32, 96, 97, 98, 99,100,101,102,103,104,105,106,107,108,109,110,
    111,112,113,114,115,116,117,118,119,120,121, 33, 34, 35, 36, 37,
     38,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,
    143,144,145,146,147,148,149,150,151,152,153, 39, 40, 41, 42,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     43, 44, 45, 46, 49,  0,  0,  0,  0, 81, 78, 87, 88,  0,  0, 55,
     53, 50, 52, 51, 47, 48,  0,  0, 85, 86, 82, 84, 83, 79, 80,  0,
      0,  0,  0,  0,  0,  0,  0,  0, 56, 54,  0,  0,  0,  0,  0,
     74, 75, 57, 58, 59, 60, 61, 62, 63,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
)
GROUND = (64, 112, 128)  # original data/lungs.js background
DIRECTIONS = [('Left', -1, 0), ('Right', 1, 0), ('Up', 0, -1), ('Down', 0, 1)]
ERRORS = re.compile(
    r'traceback|\b\w*(?:Error|Exception)(?:\s*:|@)|segmentation fault|permission denied|'
    r'no such file|couldn.t (?:open|load)|cannot (?:open|load)|failed to|'
    r'assertion .* failed|terminate called|^\s*(?:>\s*)?\((?:EE|F)\)|'
    r'^\s*(?:fatal|error)\b|X (?:Error|IO Error)\b|'
    r'\b(?:initWorld|initMap) exception\b|SharedLibLoadException|FailedBinding|'
    r'core dumped|Aborted|symbol lookup error', re.I)


def require(value, message):
    if not value:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def namespaces(proc, hardened=False):
    kinds = [('user', 'USER'), ('mnt', 'MOUNT'), ('net', 'NET'), ('pid', 'PID')]
    result = {'namespaces': {}, 'files': {}}
    for kind, env in kinds:
        value = os.readlink(proc / 'ns' / kind)
        require(value != os.environ['HOST_' + env + '_NS'], 'host namespace leaked: ' + kind)
        require(value == os.readlink('/proc/self/ns/' + kind), 'child escaped: ' + kind)
        result['namespaces'][kind] = value
    for name in ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route'):
        result['files'][name] = (proc / name).read_text()
    status = result['files']['status']
    for kind, field, expected in [('uid', 'Uid', 1000), ('gid', 'Gid', 998)]:
        require(int(os.environ['HOST_' + kind.upper()]) == expected, 'unexpected caller identity')
        values = re.search(r'^' + field + r':\s*(.+)$', status, re.M)
        require(values and list(map(int, values[1].split())) == [expected] * 4,
                'not original unprivileged ' + field)
        require(list(map(int, result['files'][kind + '_map'].split())) == [expected, expected, 1],
                'not map-current-user: ' + kind)
    interfaces = [row.split(':')[0].strip() for row in result['files']['net/dev'].splitlines()[2:] if ':' in row]
    require(interfaces == ['lo'], 'external network interface present')
    require(len(result['files']['net/route'].splitlines()) <= 1, 'IPv4 routes present')
    require(all(row.split()[-1] == 'lo' for row in result['files']['net/ipv6_route'].splitlines() if row.strip()),
            'external IPv6 routes present')
    if hardened:
        for field in ('CapInh', 'CapPrm', 'CapEff', 'CapBnd', 'CapAmb'):
            match = re.search(r'^' + field + r':\s*([0-9a-fA-F]+)$', status, re.M)
            require(match and int(match[1], 16) == 0, 'capabilities not zero: ' + field)
        require(re.search(r'^NoNewPrivs:\s*1$', status, re.M), 'NoNewPrivs is not 1')
    return result


def mount(source, target, flags=0, filesystem=None, data=None):
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p, ctypes.c_ulong, ctypes.c_char_p]
    libc.mount.restype = ctypes.c_int
    enc = lambda value: None if value is None else os.fsencode(value)
    if libc.mount(enc(source), enc(target), enc(filesystem), flags, enc(data)):
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
    for target in sorted({item['target'] for item in store_entries()[1]}, key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)
    text, entries = store_entries()
    require(entries and any(item['target'] == '/gnu/store' for item in entries), 'store bind missing')
    require(all('ro' in item['options'] and 'rw' not in item['options'] and not
                any(value.startswith(('shared:', 'master:')) for value in item['optional']) for item in entries),
            'store not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'writable store')
    (evidence / 'mountinfo-store-readonly.txt').write_text(text)
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
        mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=0755')
        retained = Path('/tmp/infection-evidence')
        retained.mkdir(mode=0o700)
        mount('/proc/self/fd/' + str(descriptor), retained, 4096)
    finally:
        os.close(descriptor)
    Path('/tmp/.X11-unix').mkdir(mode=0o1777)
    os.chmod('/tmp/.X11-unix', 0o1777)
    (retained / 'mountinfo-isolated.txt').write_text(Path('/proc/self/mountinfo').read_text())
    return retained, entries


def drop_privileges():
    libc = ctypes.CDLL(None, use_errno=True)
    libc.prctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_ulong]
    libc.prctl.restype = ctypes.c_int
    require(libc.prctl(38, 1, 0, 0, 0) == 0, 'PR_SET_NO_NEW_PRIVS failed')
    require(libc.prctl(47, 4, 0, 0, 0) == 0, 'clear ambient capabilities failed')
    for capability in range(64):
        if libc.prctl(24, capability, 0, 0, 0):
            number = ctypes.get_errno()
            require(number == errno.EINVAL, 'drop capability bounding set: ' + os.strerror(number))
    class Header(ctypes.Structure):
        _fields_ = [('version', ctypes.c_uint32), ('pid', ctypes.c_int)]
    class Data(ctypes.Structure):
        _fields_ = [('effective', ctypes.c_uint32), ('permitted', ctypes.c_uint32), ('inheritable', ctypes.c_uint32)]
    libc.capset.argtypes = [ctypes.POINTER(Header), ctypes.POINTER(Data)]
    libc.capset.restype = ctypes.c_int
    require(libc.capset(ctypes.byref(Header(0x20080522, 0)), (Data * 2)()) == 0, 'capset zero failed')


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
            item.update(type='file', size=len(data), sha256=sha(data))
        else:
            item['type'] = 'other'
        result[str(path.relative_to(root))] = item
    return result


class Frame:
    def __init__(self, pixels, glyphs):
        require(len(pixels) == WIDTH * HEIGHT * 3, 'truncated framebuffer')
        self.pixels, self.codes, self.backgrounds = pixels, [], []
        for row in range(ROWS):
            codes, backgrounds = [], []
            for col in range(COLS):
                values = [tuple(pixels[((row * CELL + y) * WIDTH + col * CELL + x) * 3:
                                      ((row * CELL + y) * WIDTH + col * CELL + x) * 3 + 3])
                          for y in range(CELL) for x in range(CELL)]
                background = Counter(values).most_common(1)[0][0]
                distances = [sum((a - b) ** 2 for a, b in zip(value, background)) for value in values]
                peak = max(distances)
                if not peak:
                    code = 32
                else:
                    mask = sum(1 << i for i, distance in enumerate(distances) if distance > peak / 9)
                    error, code = min(((mask ^ glyph).bit_count(), code) for code, glyph in glyphs.items())
                    if error > 8:
                        code = -1
                codes.append(code)
                backgrounds.append(background)
            self.codes.append(codes)
            self.backgrounds.append(backgrounds)
        self.rows = [''.join(chr(code) if 32 <= code < 127 else '~' for code in row) for row in self.codes]

    def text(self):
        return '\n'.join(self.rows)

    def has_label(self, label):
        require(label and '\n' not in label and label.strip(), 'single-row label required')
        foreground = [(offset, ord(char)) for offset, char in enumerate(label) if char != ' ']
        return any(all(row[start + offset] == code for offset, code in foreground)
                   for row in self.codes for start in range(COLS - len(label) + 1))

    def region(self, x, y, width, height):
        return b''.join(self.pixels[((y * CELL + row) * WIDTH + x * CELL) * 3:
                                   ((y * CELL + row) * WIDTH + (x + width) * CELL) * 3]
                        for row in range(height * CELL))

    def state(self):
        header = re.fullmatch(r'H:(\d+)/(\d+) - C:(\d+)\s+Lungs\s*', self.rows[0])
        require(header, 'original Lungs HUD missing: ' + self.rows[0])
        health, maximum, cells = map(int, header.groups())
        require(0 < health <= maximum and maximum == 10 and 0 < cells <= 3, 'not living Normal game')
        require(self.codes[17][30] == ord('@'), 'original player not at camera centre (30,17)')
        require(sum(row.count(ord('@')) for row in self.codes[2:29]) == 1, 'player glyph not unique in world')
        return {'health': health, 'max_health': maximum, 'cells_left': cells, 'level': 'Lungs',
                'player_screen': [30, 17], 'world_sha256': sha(self.region(0, 2, 60, 27)),
                'rgb_sha256': sha(self.pixels)}

    def ground(self, x, y):
        # An entire native solid background tile is unambiguously bare visible
        # ground; a blank unknown/unexplored cell has a different colour.
        return self.region(x, y, 1, 1) == bytes(GROUND) * (CELL * CELL)

    def wall(self, x, y):
        # map.d generates each Lungs wall's own foreground RGB in these ranges.
        # Do not use dense-glyph OCR to decide which cells are static terrain.
        tile = self.region(x, y, 1, 1)
        return any(130 <= tile[i] <= 150 and 190 <= tile[i + 1] <= 220 and 230 <= tile[i + 2] <= 255
                   for i in range(0, len(tile), 3))


class PhysicalKeyboard:
    """Direct physical XTEST edges, never keysym modifier synthesis."""
    def __init__(self, display, x11, xtst):
        self.x11 = ctypes.CDLL(x11, mode=ctypes.RTLD_GLOBAL)
        self.xtst = ctypes.CDLL(xtst)
        for name, args, result in [
                ('XOpenDisplay', [ctypes.c_char_p], ctypes.c_void_p),
                ('XStringToKeysym', [ctypes.c_char_p], ctypes.c_ulong),
                ('XKeysymToKeycode', [ctypes.c_void_p, ctypes.c_ulong], ctypes.c_ubyte),
                ('XSync', [ctypes.c_void_p, ctypes.c_int], ctypes.c_int),
                ('XQueryKeymap', [ctypes.c_void_p, ctypes.c_void_p], ctypes.c_int),
                ('XCloseDisplay', [ctypes.c_void_p], ctypes.c_int)]:
            function = getattr(self.x11, name)
            function.argtypes, function.restype = args, result
        self.xtst.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
        self.xtst.XTestFakeKeyEvent.restype = ctypes.c_int
        self.xtst.XTestQueryExtension.argtypes = [ctypes.c_void_p, *([ctypes.POINTER(ctypes.c_int)] * 4)]
        self.xtst.XTestQueryExtension.restype = ctypes.c_int
        self.display = self.x11.XOpenDisplay(display.encode('ascii'))
        require(self.display, 'private XTEST display unavailable')
        values = [ctypes.c_int() for _ in range(4)]
        require(self.xtst.XTestQueryExtension(self.display, *(ctypes.byref(value) for value in values)),
                'real XTEST extension missing')
        self.expected = set()
        require(not self.held(), 'fresh X server has held keys')

    def held(self):
        bitmap = (ctypes.c_ubyte * 32)()
        require(self.x11.XQueryKeymap(self.display, bitmap), 'XQueryKeymap failed')
        return {code for code in range(256) if bitmap[code // 8] & (1 << (code % 8))}

    def edge(self, key, pressed):
        symbol = self.x11.XStringToKeysym(key.encode('ascii'))
        require(symbol, 'unknown keysym ' + key)
        code = int(self.x11.XKeysymToKeycode(self.display, symbol))
        require(code, 'missing physical keycode ' + key)
        before = self.held()
        require(before == self.expected, 'unexpected held keys')
        require((code not in before) if pressed else (code in before), 'duplicate physical edge')
        require(self.xtst.XTestFakeKeyEvent(self.display, code, int(pressed), 0), 'XTEST failed')
        self.x11.XSync(self.display, 0)
        if pressed:
            self.expected.add(code)
        else:
            self.expected.remove(code)
        after = self.held()
        require(after == self.expected, 'XTEST changed unexpected held keys')
        return {'keysym': key, 'keycode': code, 'pressed': pressed,
                'held_before': sorted(before), 'held_after': sorted(after)}

    def close(self):
        self.x11.XCloseDisplay(self.display)


class Session:
    def __init__(self, output, evidence, root, tools):
        self.output, self.evidence, self.root = output, evidence, root
        self.xvfb, self.xdotool, self.xwd, self.convert, self.x11, self.xtst = tools
        self.server = self.keyboard = self.process = self.window = None
        self.inputs, self.commands, self.frames = [], [], []
        self.env = {'PATH': '', 'LC_ALL': 'C', 'HOME': str(root / 'home'), 'TMPDIR': str(root / 'tmp'),
                    'SDL_VIDEODRIVER': 'x11', 'SDL_AUDIODRIVER': 'dummy', 'LIBGL_ALWAYS_SOFTWARE': '1',
                    'GALLIUM_DRIVER': 'llvmpipe', 'MESA_LOADER_DRIVER_OVERRIDE': 'swrast',
                    'MESA_SHADER_CACHE_DISABLE': 'true', 'PYTHONNOUSERSITE': '1', 'PYTHONDONTWRITEBYTECODE': '1',
                    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-session'),
                    'DBUS_SYSTEM_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-system')}
        for variable, name in [('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'), ('XDG_STATE_HOME', 'state'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_RUNTIME_DIR', 'runtime')]:
            self.env[variable] = str(root / name)
        font = output / 'share/infection/data/dejavu16x16_gs_tc.png'
        require(sha(font.read_bytes()) == FONT_HASH, 'not original author-modified font')
        require(self.tool(self.convert, str(font), '-format', '%w %h', 'info:').strip() == b'512 128',
                'original TCOD 32x8 atlas geometry changed')
        pixels = self.tool(self.convert, str(font), '-depth', '8', 'rgba:-')
        require(len(pixels) == 512 * 128 * 4, 'truncated font pixels')
        transparent = any(pixels[i] < 255 for i in range(3, len(pixels), 4))
        # TCOD_sys_load_font samples space, which in TCOD layout is atlas0.
        invert = pixels[((CELL // 2) * 512 + CELL // 2) * 4] > 128
        self.glyphs = {}
        codes = [*range(32, 127), 178]  # ASCII UI/player plus TCOD_CHAR_BLOCK3
        for code in codes:
            atlas = ASCII_TO_TCOD[code]
            values = []
            for y in range((atlas // 32) * CELL, (atlas // 32 + 1) * CELL):
                for x in range((atlas % 32) * CELL, (atlas % 32 + 1) * CELL):
                    index = (y * 512 + x) * 4
                    values.append(pixels[index + 3] if transparent else 255 - pixels[index] if invert else pixels[index])
            peak = max(values)
            self.glyphs[code] = sum(1 << i for i, value in enumerate(values) if peak and value > peak / 3)
        record(evidence / 'glyph-map.json', {'renderer': RENDERER, 'table': 'init_ascii_to_tcod[256]',
               'ascii_to_tcod': ASCII_TO_TCOD, 'atlas_pixels': [512, 128], 'atlas_cells': [32, 8],
               'font_sha256': FONT_HASH, 'alpha_present': transparent, 'invert': invert,
               'decoded_cells': {str(code): [ASCII_TO_TCOD[code] % 32, ASCII_TO_TCOD[code] // 32] for code in codes},
               'author_custom_cells': [[0, 1], [13, 1]], 'player_cell': [0, 1], 'wall_cell': [13, 1]})

    def tool(self, *command, absent_ok=False):
        result = subprocess.run(command, env=self.env, cwd=self.root / 'work', capture_output=True, timeout=20)
        stderr = result.stderr.decode('utf-8', errors='replace')
        self.commands.append({'argv': command, 'status': result.returncode,
                              'stdout_sha256': sha(result.stdout), 'stderr': stderr})
        record(self.evidence / 'tool-commands.json', self.commands)
        require(result.returncode == 0 or (absent_ok and result.returncode == 1), 'consumer command failed: ' + repr(command))
        require(not any(ERRORS.search(line) for line in stderr.splitlines()), 'consumer tool diagnostic: ' + stderr)
        return result.stdout

    def diagnostics(self):
        result = {}
        for path in [self.evidence / 'game.stdout', self.evidence / 'game.stderr', self.evidence / 'xvfb.log']:
            if path.exists():
                result[path.name] = [{'line': number, 'text': line,
                                      'severity': 'error' if ERRORS.search(line) else 'information'}
                                     for number, line in enumerate(path.read_text(errors='replace').splitlines(), 1)]
        record(self.evidence / 'native-diagnostics.json', result)
        require(not any(item['severity'] == 'error' for items in result.values() for item in items),
                'native diagnostics contain errors; exit0 is not success')
        return result

    def identity(self):
        proc = Path('/proc') / str(self.process.pid)
        proof = namespaces(proc, hardened=True)
        proof.update(pid=self.process.pid, exe=os.readlink(proc / 'exe'), cwd=os.readlink(proc / 'cwd'))
        native = self.output / 'libexec/infection'
        require(Path(proof['exe']) == native and native.read_bytes()[:4] == b'\x7fELF',
                'not the exact installed original compiled ELF')
        cmdline = (proc / 'cmdline').read_bytes().split(b'\0')
        require(cmdline == [os.fsencode(native), b''], 'not original ELF with no synthetic CLI flags')
        require(Path(proof['cwd']) == self.output / 'share/infection', 'not immutable original data cwd')
        require(os.statvfs(proof['cwd']).f_flag & os.ST_RDONLY, 'game cwd writable')
        mappings = (proc / 'maps').read_text()
        require(re.search(r'/gnu/store/[^/]+/lib/libtcod\.so(?:\s|\.)', mappings), 'native libtcod not mapped')
        require(re.search(r'/gnu/store/[^/]+/lib/libSDL[^/\s]*\.so', mappings), 'native SDL not mapped')
        require(self.tool(self.xdotool, 'getwindowpid', self.window).strip() == str(self.process.pid).encode(),
                'SDL window not owned by launched original game')
        proof['cmdline'] = [os.fsdecode(arg) for arg in cmdline[:-1]]
        for name in ('status', 'maps', 'mountinfo', 'cmdline'):
            (self.evidence / ('process-' + name + '.raw')).write_bytes((proc / name).read_bytes())
        record(self.evidence / 'process-identity.json', proof)
        return proof

    def launch(self):
        read_fd, write_fd = os.pipe()
        try:
            with (self.evidence / 'xvfb.log').open('wb') as log:
                self.server = subprocess.Popen([self.xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                                '1280x800x24', '-nolisten', 'tcp', '-ac', '-r'],
                                               env=self.env, pass_fds=(write_fd,), stdout=log, stderr=log)
            os.close(write_fd)
            write_fd = None
            require(select.select([read_fd], [], [], 15)[0], 'Xvfb allocation timed out')
            display = os.read(read_fd, 128).decode('ascii').strip()
            require(display.isdecimal(), 'Xvfb did not allocate private display')
            self.env['DISPLAY'] = ':' + display
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
        self.keyboard = PhysicalKeyboard(self.env['DISPLAY'], self.x11, self.xtst)
        with (self.evidence / 'game.stdout').open('wb') as stdout, (self.evidence / 'game.stderr').open('wb') as stderr:
            self.process = subprocess.Popen([str(self.output / 'bin/infection')], env=self.env,
                                            cwd=self.root / 'work', stdout=stdout, stderr=stderr)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            self.diagnostics()
            require(self.process.poll() is None, 'game exited before SDL window')
            windows = self.tool(self.xdotool, 'search', '--onlyvisible', '--name', '^Infection$',
                                absent_ok=True).decode('ascii').splitlines()
            if windows:
                require(len(windows) == 1, 'native window not unique')
                self.window = windows[0]
                self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
                self.tool(self.xdotool, 'mousemove', '1279', '799')
                time.sleep(0.5)
                return self.identity()
            time.sleep(0.1)
        raise RuntimeError('native SDL window timeout')

    def capture(self, label, retain=False):
        self.diagnostics()
        require(self.process.poll() is None, 'game exited during ' + label)
        # No polling PNG, XWD or RGB survives a capture, even on exceptions.
        with tempfile.TemporaryDirectory(prefix='frame-', dir=self.root / 'tmp') as temporary:
            dump, png = Path(temporary) / 'frame.xwd', Path(temporary) / 'frame.png'
            self.tool(self.xwd, '-silent', '-id', self.window, '-out', str(dump))
            self.tool(self.convert, str(dump), str(png))
            geometry = self.tool(self.convert, str(png), '-format', '%w %h', 'info:')
            require(tuple(map(int, geometry.split())) == (WIDTH, HEIGHT), 'original 60x34 SDL geometry changed')
            pixels = self.tool(self.convert, str(png), '-depth', '8', 'rgb:-')
            frame = Frame(pixels, self.glyphs)
            receipt = {'label': label, 'png_sha256': sha(png.read_bytes()), 'rgb_sha256': sha(pixels), 'retained': retain}
            if retain:
                shutil.copyfile(png, self.evidence / (label + '.png'))  # original, not annotated or re-encoded
                (self.evidence / (label + '.screen.txt')).write_text(frame.text() + '\n')
            self.frames.append(receipt)
            record(self.evidence / 'frame-receipts.json', self.frames)
            return frame

    def await_frame(self, label, predicate, timeout=12, retain=False):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            frame = self.capture(label)
            if predicate(frame):
                if retain:
                    frame = self.capture(label, retain=True)
                    require(predicate(frame), 'checkpoint changed before retention: ' + label)
                return frame
            time.sleep(0.15)
        raise RuntimeError('native state timed out: ' + label)

    def key(self, label, key):
        # main.d waits KEY_PRESS, checking physical held state for arrows/Tab.
        # Hold below SDL repeat's 500ms threshold; no capture while held.
        require(self.process.poll() is None, 'input to exited game')
        pressed = self.keyboard.edge(key, True)
        start = time.monotonic()
        try:
            time.sleep(0.12)
        finally:
            released = self.keyboard.edge(key, False)
        duration = time.monotonic() - start
        self.inputs.append({'label': label, 'transport': 'physical XTestFakeKeyEvent',
                            'press': pressed, 'release': released, 'held_seconds': duration})
        record(self.evidence / 'native-inputs.json', self.inputs)
        require(duration < 0.45 and not self.keyboard.held(), 'hold/repeat or stuck-key violation')
        time.sleep(0.25)

    def action(self, label, key, retain=False):
        self.key(label, key)
        return self.capture(label, retain=retain)

    def cleanup(self):
        errors = []
        if self.keyboard is not None:
            if self.keyboard.held():
                errors.append('physical keys left held')
            self.keyboard.close()
        if self.process is not None and self.process.poll() is None:
            errors.append('game still running; namespace teardown is NOT natural exit proof')
        if self.server is not None and self.server.poll() is None:
            self.server.terminate()  # only this consumer's X server
            try:
                self.server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                errors.append('consumer Xvfb did not stop')
        return {'game_exit_status': None if self.process is None else self.process.poll(),
                'xvfb_exit_status': None if self.server is None else self.server.poll(), 'errors': errors}


def movement(session, before, label, direction=None, retain=False):
    before.state()
    choices = DIRECTIONS if direction is None else [direction]
    for key, dx, dy in choices:
        if not before.ground(30 + dx, 17 + dy):
            continue
        # The original camera moves, not the screen-centred @. Track actual
        # randomly coloured static walls near the player through that scroll.
        anchors = [(x, y) for y in range(11, 24) for x in range(24, 37) if before.wall(x, y)]
        require(len(anchors) >= 3, 'too few visible wall anchors; no reroll')
        after = session.action(label, key, retain=retain)
        after.state()
        require(after.ground(30 - dx, 17 - dy), 'old player tile not bare ground after camera scroll')
        matched = []
        for x, y in anchors:
            original = before.region(x, y, 1, 1)
            if original == after.region(x - dx, y - dy, 1, 1) and original != after.region(x, y, 1, 1):
                matched.append({'before': [x, y], 'after': [x - dx, y - dy], 'tile_sha256': sha(original)})
        require(len(matched) >= 3 and len({item['tile_sha256'] for item in matched}) >= 2,
                'movement not proven by distinct exact translated terrain pixels')
        require(before.region(0, 2, 60, 27) != after.region(0, 2, 60, 27), 'world unchanged after movement')
        return after, {'key': key, 'world_delta': [dx, dy], 'camera_scroll': [-dx, -dy],
                       'observed_target': 'solid bare Lungs background [64,112,128]',
                       'translated_static_walls': matched, 'before': before.state(), 'after': after.state(),
                       'turn_oracle': 'world.d updateWorld arrow -> system.move -> spawnCharacters -> heartBeat/AI -> computeFov'}
    raise RuntimeError('no observed adjacent bare ground; this single unseeded run is not rerolled')


def play(session):
    process = session.launch()
    menu = session.await_frame('menu', lambda frame: all(frame.has_label(label) for label in
                               ('Play - Normal', 'Play - Easy', 'Help', 'Exit')), retain=True)
    require(menu.rows[20].strip() == 'Play - Normal', 'original Normal menu entry differs')
    session.key('menu-play-normal', 'Return')  # selectedMenu starts0, never choose Easy
    initial = session.await_frame('normal-world', lambda frame: frame.rows[0].startswith('H:10/10 - C:3') and
                                  frame.rows[0].endswith('Lungs'), retain=True)
    initial.state()
    moved, first_move = movement(session, initial, 'movement')
    dx, dy = first_move['world_delta']
    reverse = next(item for item in DIRECTIONS if item[1:] == (-dx, -dy))
    turned, second_move = movement(session, moved, 'another-turn', direction=reverse, retain=True)
    # Inspect only: a Normal pathogen has no resources/traits initially. Do not
    # purchase unavailable traits, manufacture inventory or rely on AA order.
    traits = session.action('traits', 'Tab', retain=True)
    require(all(traits.has_label(label) for label in ('Inventory', 'Your Traits', 'Buy Traits', 'Required:')),
            'original pathogen traits screen missing')
    require(traits.has_label('Use the <arrow keys>'), 'original traits navigation help missing')
    require(all(traits.codes[y][x] == 32 for y in range(5, 29) for x in range(21, 40)),
            'Normal run unexpectedly has traits (Easy or modified state)')
    navigated = session.action('traits-next', 'Down')
    require(navigated.has_label('Required:') and navigated.pixels != traits.pixels,
            'real traits navigation did not change selection/description')
    returned = session.action('traits-return-game', 'q')
    require(returned.pixels == turned.pixels, 'traits inspection changed world/HUD/log without a turn')
    help_frame = session.action('help', 'h', retain=True)
    require(all(help_frame.has_label(label) for label in
                ('You are the pathogen @', 'Move around using the <arrow keys>',
                 'Press <TAB>', '<ESC> to close.')), 'original gameplay help missing')
    final = session.action('help-return-game', 'Escape')
    final.state()
    require(final.pixels == turned.pixels, 'help return changed world/HUD/log without a turn')
    final_identity = session.identity()
    require(final_identity['pid'] == process['pid'], 'game replaced itself during play')
    session.key('natural-game-quit', 'q')
    status = session.process.wait(timeout=15)
    require(status == 0, 'original gameInput q did not exit naturally with status0')
    session.window = None
    session.diagnostics()
    return {'process': process, 'final_process': final_identity, 'mode': 'Play - Normal',
            'initial': initial.state(), 'first_movement': first_move, 'another_turn': second_move,
            'traits': 'Tab -> original Inventory/Your Traits/Buy Traits -> Down -> q returns unchanged game',
            'help': 'h -> original pathogen instructions -> Escape returns unchanged game',
            'modal_exact_visible_continuity': True, 'natural_exit_status': status,
            'save_load': 'not implemented upstream; no save/load input or fabricated persistence assertion'}


def main():
    require(len(sys.argv) == 9, 'usage: native.py OUTPUT EVIDENCE XVFB XDOTOOL XWD CONVERT LIBX11 LIBXTST')
    output, evidence = map(Path, sys.argv[1:3])
    require(output.is_absolute() and output.resolve() == output and output.parent == Path('/gnu/store') and output.is_dir(),
            'canonical prebuilt store output required')
    require(evidence.is_absolute() and evidence.resolve() == evidence and evidence.is_dir() and
            not evidence.is_relative_to('/gnu/store') and not (evidence / 'native-result.json').exists(),
            'fresh shell-created evidence required')
    for tool in sys.argv[3:]:
        require(Path(tool).is_absolute() and Path(tool).is_file() and os.access(tool, os.R_OK), 'unresolved consumer tool/library')
    for tool in sys.argv[3:7]:
        require(os.access(tool, os.X_OK), 'consumer executable not executable')
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc/self/fd/' + str(evidence_fd))
    report = {'success': False, 'source': SOURCE, 'source_sha256': SOURCE_HASH, 'font_sha256': FONT_HASH,
              'renderer_source': RENDERER,
              'verification': 'external real X11/XTEST/framebuffer only; no injected state, imports, hooks or RNG control'}
    root = session = None
    cleanup_errors = []
    try:
        require(os.getpid() == 1, 'not PID1 in private proc mount')
        report['isolation_before_drop'] = namespaces(Path('/proc/self'))
        evidence, entries = isolate(evidence)
        drop_privileges()
        report['isolation'] = namespaces(Path('/proc/self'), hardened=True)
        report['isolation']['store'] = entries
        native = output / 'bin/infection'
        require(native.is_file() and os.access(native, os.X_OK), 'installed launcher missing')
        require(not any('native.py' in path.name or 'smoke' in path.name for path in output.rglob('*')),
                'consumer helper leaked into package')
        closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
        require(str(output) in closure, 'runtime closure missing package')
        tools = json.loads((evidence / 'consumer-tools.json').read_text())
        consumers = {name: tools[name] for name in ('python', 'xorg-server', 'xdotool', 'xwd', 'imagemagick')}
        leaks = {name: path for name, path in consumers.items() if path in closure}
        record(evidence / 'consumer-closure-audit.json', {'consumer_outputs': consumers, 'exact_consumer_leaks': leaks})
        require(not leaks, 'consumer-only outputs in runtime closure: ' + repr(leaks))
        report['output'] = {'launcher_sha256': sha(native.read_bytes()),
                            'elf_sha256': sha((output / 'libexec/infection').read_bytes()), 'closure': closure}
        root = Path('/tmp/infection-private')
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'state', 'cache', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        before = inventory(root)
        record(evidence / 'private-before.json', before)
        session = Session(output, evidence, root, sys.argv[3:])
        report['gameplay'] = play(session)
        after = inventory(root)
        record(evidence / 'private-after.json', after)
        require(after == before, 'unexpected private write; original Infection has no save or persistent state')
        session.diagnostics()
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
                    session.capture('failure-last-frame', retain=True)
                except BaseException as error:
                    cleanup_errors.append('failure capture: ' + repr(error))
            try:
                cleanup.update(session.cleanup())
                cleanup_errors.extend(cleanup.get('errors', []))
                report['diagnostics'] = session.diagnostics()
            except BaseException as error:
                cleanup_errors.append('session cleanup/diagnostics: ' + repr(error))
        if root is not None and root.exists():
            try:
                record(evidence / 'private-after.json', inventory(root))
                shutil.rmtree(root)  # only this consumer's fresh private tmpfs tree
                cleanup['private_removed'] = not root.exists()
            except BaseException as error:
                cleanup_errors.append('private cleanup: ' + repr(error))
        cleanup['errors'] = cleanup_errors
        if cleanup_errors:
            report['success'] = False
            report['cleanup_errors'] = cleanup_errors
        record(evidence / 'cleanup.json', cleanup)
        record(evidence / 'native-result.json', report)
        os.close(evidence_fd)
        require(not cleanup_errors, 'native cleanup failed: ' + repr(cleanup_errors))
    print('INFECTION_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
