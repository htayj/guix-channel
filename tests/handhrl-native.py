#!/usr/bin/env python3
"""External HandhRL 0.3 consumer; never import or instrument the game.

Invoke ONLY inside the smoke wrapper's private namespaces:
  python3 -B -s tests/handhrl-native.py OUTPUT EVIDENCE XVFB XDOTOOL XWD CONVERT LIBX11 LIBXTST

Oracles read at pinned 03d0d256f150af256ac34a62fdafbf1a7514d76b:
handhrl.py main_menu/new_game/play_game/save_game/load_game, handle_keys,
get_text_entry, menu, inventory_menu, render_all; hhmessage.py intro_sequence
and show_text_log; hhtable.py rolldice. Menus consume BOTH press and release,
whereas gameplay/name entry consume presses. Escape saves from gameplay;
main-menu (d) exits. There is no save confirmation or tutorial 'y' answer.
Terrain is BACKGROUND COLOR, not '.'; player is glyph 1, not '@'.
No seed/config/save injection, imports, process memory, hooks or rerolls.
"""
from collections import Counter
import base64
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

COLS, ROWS, CELL = 80, 50, 16
WIDTH, HEIGHT = COLS * CELL, ROWS * CELL
FONT_HASH = '0475c1cc68cf710cde725d532acf949f3143d130b90709903571f0f123d68896'
SOURCE = 'https://codeload.github.com/jarcane/handhRL/tar.gz/03d0d256f150af256ac34a62fdafbf1a7514d76b'
SOURCE_HASH = '284fcabffd46fd4634e4d40e0b1b8b324916b697476a280e1123fbd616e558a3'
PLAYER_NAME = 'nativeensign'
ERRORS = re.compile(r'traceback|\b\w*(?:Error|Exception)\s*:|segmentation fault|permission denied|'
                    r'no such file|couldn.t (?:open|load)|cannot (?:open|load)|failed to|'
                    r'assertion .* failed|terminate called|^\s*(?:>\s*)?\((?:EE|F)\)|'
                    r'^\s*(?:fatal|error)\b|X (?:Error|IO Error)\b', re.I)
DIRECTIONS = [('Left', -1, 0), ('Right', 1, 0), ('Up', 0, -1), ('Down', 0, 1),
              ('Home', -1, -1), ('Prior', 1, -1), ('End', -1, 1), ('Next', 1, 1)]
# This separate interpreter only reads the game's native DBM bytes. It never
# imports handhrl/libtcodpy or unpickles anything (not even a restricted load).
READ_DB = """import anydbm, base64, json, pickletools, StringIO, sys
def text(value):
    return value.decode('latin1') if isinstance(value, str) else value
f = anydbm.open(sys.argv[1], 'r')
try:
    result = {}
    for key in f.keys():
        value = f[key]
        operations = list(pickletools.genops(StringIO.StringIO(value)))
        primitives = [text(arg) for op, arg, position in operations if op.name in
                      ('STRING', 'UNICODE', 'BINUNICODE', 'SHORT_BINSTRING', 'BINSTRING',
                       'INT', 'BININT', 'BININT1', 'BININT2', 'LONG')]
        identities = sorted(set(text(arg) for op, arg, position in operations
                                if op.name in ('GLOBAL', 'INST')))
        result[base64.b64encode(key)] = dict(payload=base64.b64encode(value),
                                            primitives=primitives, identities=identities)
    print(json.dumps(result, sort_keys=True))
finally:
    f.close()
"""


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
        retained = Path('/tmp/handhrl-evidence')
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
        """Match single-row foreground text without interpreting its backdrop.

        menu() blits its background at alpha0.7 over the starfield/world;
        expected spaces contain no foreground ink and can retain decoration.
        Every non-space glyph must still match at its exact relative column.
        This predicate never modifies codes, rows, backgrounds or pixels and
        is not used for world-state or saved-game continuity comparisons.
        """
        require(label and '\n' not in label and label.strip(), 'single-row label required')
        foreground = [(offset, ord(char)) for offset, char in enumerate(label) if char != ' ']
        return any(all(row[start + offset] == code for offset, code in foreground)
                   for row in self.codes for start in range(COLS - len(label) + 1))

    def actor(self):
        points = [(x, y) for y in range(43) for x in range(80) if self.codes[y][x] == 1]
        require(len(points) == 1, 'native smiley player not unique: ' + repr(points))
        return points[0]

    def region(self, x, y, width, height):
        return b''.join(self.pixels[((y * CELL + row) * WIDTH + x * CELL) * 3:
                                   ((y * CELL + row) * WIDTH + (x + width) * CELL) * 3]
                        for row in range(height * CELL))

    def state(self):
        require('HP:' in self.text() and 'Cave level 1' in self.text(), 'native HUD missing')
        return {'player': self.actor(), 'map_sha256': sha(self.region(0, 0, 80, 43)),
                'hud_sha256': sha(self.region(0, 43, 80, 7)), 'rgb_sha256': sha(self.pixels)}


class PhysicalKeyboard:
    """Direct physical XTEST edges; no xdotool keysym modifier synthesis."""
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
        self.server = self.keyboard = self.process = self.window = self.interpreter = None
        self.inputs, self.commands, self.processes, self.frames = [], [], [], []
        self.env = {'PATH': '', 'LC_ALL': 'C', 'HOME': str(root / 'home'), 'TMPDIR': str(root / 'tmp'),
                    'SDL_VIDEODRIVER': 'x11', 'SDL_AUDIODRIVER': 'dummy', 'LIBGL_ALWAYS_SOFTWARE': '1',
                    'GALLIUM_DRIVER': 'llvmpipe', 'MESA_LOADER_DRIVER_OVERRIDE': 'swrast',
                    'MESA_SHADER_CACHE_DISABLE': 'true', 'PYTHONNOUSERSITE': '1', 'PYTHONDONTWRITEBYTECODE': '1',
                    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-session'),
                    'DBUS_SYSTEM_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-system')}
        for variable, name in [('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'), ('XDG_STATE_HOME', 'state'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_RUNTIME_DIR', 'runtime')]:
            self.env[variable] = str(root / name)
        self.state_dir = root / 'data/handhrl'
        font = output / 'share/handhrl/terminal16x16_gs_ro.png'
        require(sha(font.read_bytes()) == FONT_HASH, 'not original font')
        require(self.tool(self.convert, str(font), '-format', '%w %h', 'info:').strip() == b'256 256',
                'original 16x16 atlas geometry changed')
        pixels = self.tool(self.convert, str(font), '-depth', '8', 'rgba:-')
        require(len(pixels) == 256 * 256 * 4, 'truncated font pixels')
        transparent = any(pixels[i] < 255 for i in range(3, len(pixels), 4))
        invert = pixels[((CELL // 2) * 256 + CELL // 2) * 4] > 128
        self.glyphs = {}
        # FONT_LAYOUT_ASCII_INROW: glyph 1 is the native player smiley.
        for code in range(128):
            values = []
            for y in range((code // 16) * CELL, (code // 16 + 1) * CELL):
                for x in range((code % 16) * CELL, (code % 16 + 1) * CELL):
                    index = (y * 256 + x) * 4
                    values.append(pixels[index + 3] if transparent else 255 - pixels[index] if invert else pixels[index])
            peak = max(values)
            self.glyphs[code] = sum(1 << i for i, value in enumerate(values) if peak and value > peak / 3)

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
        for path in [*self.evidence.glob('game-*.stdout'), *self.evidence.glob('game-*.stderr'), self.evidence / 'xvfb.log']:
            if path.exists():
                result[path.name] = [{'line': number, 'text': line,
                                      'severity': 'error' if ERRORS.search(line) else 'information'}
                                     for number, line in enumerate(path.read_text(errors='replace').splitlines(), 1)]
        record(self.evidence / 'native-diagnostics.json', result)
        require(not any(item['severity'] == 'error' for items in result.values() for item in items),
                'native diagnostics contain errors; exit0 is not success')
        return result

    def launch(self, label):
        if self.server is None:
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
        require(self.process is None or self.process.poll() == 0, 'previous game did not exit naturally')
        with (self.evidence / ('game-' + label + '.stdout')).open('wb') as stdout, \
             (self.evidence / ('game-' + label + '.stderr')).open('wb') as stderr:
            self.process = subprocess.Popen([str(self.output / 'bin/handhrl')], env=self.env,
                                            cwd=self.root / 'work', stdout=stdout, stderr=stderr)
        self.processes.append(self.process)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            self.diagnostics()
            require(self.process.poll() is None, 'game exited before SDL window')
            windows = self.tool(self.xdotool, 'search', '--onlyvisible', '--name', '^Hulks and Horrors$',
                                absent_ok=True).decode('ascii').splitlines()
            if windows:
                require(len(windows) == 1, 'native window not unique')
                self.window = windows[0]
                self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
                # Keep the real pointer outside the window; get_names_under_mouse
                # is not saved state and must not confound continuity comparisons.
                self.tool(self.xdotool, 'mousemove', '1279', '799')
                time.sleep(0.5)
                proc = Path('/proc') / str(self.process.pid)
                proof = namespaces(proc, hardened=True)
                proof.update(pid=self.process.pid, exe=os.readlink(proc / 'exe'), cwd=os.readlink(proc / 'cwd'))
                self.interpreter = proof['exe']
                interpreter = Path(self.interpreter)
                require(interpreter.parent.parent.parent == Path('/gnu/store') and
                        interpreter.name.startswith('python2') and interpreter.read_bytes()[:4] == b'\x7fELF',
                        'not native store Python2')
                cmdline = (proc / 'cmdline').read_bytes().split(b'\0')
                require(os.fsencode(self.output / 'share/handhrl/handhrl.py') in cmdline,
                        'not immutable original main script')
                require(all(flag in cmdline for flag in (b'-B', b'-s', b'-E')), 'Python isolation flags missing')
                require(Path(proof['cwd']) == self.state_dir, 'not fixed XDG_DATA_HOME/handhrl cwd')
                mappings = (proc / 'maps').read_text()
                require(re.search(r'/gnu/store/[^/]+/[^\s]*libtcod\.so', mappings), 'native libtcod not mapped')
                require(re.search(r'/gnu/store/[^/]+/lib/libSDL[^/\s]*\.so', mappings), 'native SDL not mapped')
                for name in ('status', 'maps', 'mountinfo', 'cmdline'):
                    (self.evidence / ('process-' + label + '-' + name + '.raw')).write_bytes((proc / name).read_bytes())
                return proof
            time.sleep(0.1)
        raise RuntimeError('native SDL window timeout')

    def capture(self, label, retain=False):
        self.diagnostics()
        require(self.process.poll() is None, 'game exited during ' + label)
        # Each observation owns its temporary directory. Neither XWD, RGB nor
        # polling PNGs survive it, including on conversion/decode exceptions.
        with tempfile.TemporaryDirectory(prefix='frame-', dir=self.root / 'tmp') as temporary:
            dump, png = Path(temporary) / 'frame.xwd', Path(temporary) / 'frame.png'
            self.tool(self.xwd, '-silent', '-id', self.window, '-out', str(dump))
            self.tool(self.convert, str(dump), str(png))
            geometry = self.tool(self.convert, str(png), '-format', '%w %h', 'info:')
            require(tuple(map(int, geometry.split())) == (WIDTH, HEIGHT), 'original 80x50 SDL geometry changed')
            pixels = self.tool(self.convert, str(png), '-depth', '8', 'rgb:-')
            frame = Frame(pixels, self.glyphs)
            receipt = {'label': label, 'png_sha256': sha(png.read_bytes()), 'rgb_sha256': sha(pixels), 'retained': retain}
            if retain:
                shutil.copyfile(png, self.evidence / (label + '.png'))  # original, not annotated/re-encoded
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
        # Upstream menu waits for a release AFTER its press. Hold across at
        # least two 20Hz frames, below SDL repeat's 500ms threshold. No image
        # conversion/evidence writes occur while a key is held.
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

    def save_files(self):
        files = {path.name: {'size': path.stat().st_size, 'sha256': sha(path.read_bytes())}
                 for path in sorted(self.state_dir.glob('savegame*')) if path.is_file() and not path.is_symlink()}
        require(files and all(item['size'] for item in files.values()), 'no native save files')
        return files

    def inspect_save(self, label):
        before = self.save_files()
        encoded = json.loads(self.tool(self.interpreter, '-B', '-s', '-E', '-c', READ_DB,
                                       str(self.state_dir / 'savegame')))
        decoded = {base64.b64decode(key).decode('ascii'): value for key, value in encoded.items()}
        values = {key: base64.b64decode(value['payload']) for key, value in decoded.items()}
        expected = {'map', 'objects', 'player_index', 'inventory', 'game_msgs', 'game_state', 'stairs_index', 'dungeon_level'}
        require(set(values) == expected, 'upstream shelve keys differ: ' + repr(sorted(values)))
        # Python2's own standard-library pickletools handles protocol0 binary
        # strings without Python3 ASCII-decoding assumptions. Disassembly does
        # not resolve GLOBAL/INST or execute reducers/constructors.
        primitives = {key: value['primitives'] for key, value in decoded.items()}
        globals_seen = {key: value['identities'] for key, value in decoded.items()}
        require(PLAYER_NAME in primitives['objects'], 'entered player name absent from native objects')
        require('combat knife' in primitives['inventory'], 'native inventory missing starting knife')
        require('playing' in primitives['game_state'] and 1 in primitives['dungeon_level'], 'native save is not living level1')
        require('__main__ Tile' in globals_seen['map'] and '__main__ Object' in globals_seen['objects'],
                'not original Python2 __main__ identities')
        require(self.save_files() == before, 'external read-only DBM inspection modified save')
        receipt = {'files': before, 'shelve_values': {key: {'size': len(value), 'sha256': sha(value),
                   'globals_disassembled_not_imported': globals_seen[key]} for key, value in values.items()},
                   'player_name': PLAYER_NAME, 'inventory': 'combat knife', 'game_state': 'playing',
                   'dungeon_level': 1, 'inspection': 'external Python2 anydbm r + pickletools disassembly only; no unpickling'}
        record(self.evidence / (label + '-native-save.json'), receipt)
        target = self.evidence / (label + '-native-save')
        target.mkdir(mode=0o700)
        for name in before:
            shutil.copyfile(self.state_dir / name, target / name)
        return receipt

    def save_and_quit(self, label):
        saved = self.capture(label + '-world', retain=True)
        saved.state()
        self.key(label + '-escape-save', 'Escape')
        menu = self.await_frame(label + '-menu', lambda frame: frame.has_label('(b)Continue last save') and frame.has_label('(d)Quit'))
        require(not menu.has_label('No saved game'), 'native save returned load error')
        self.key(label + '-menu-d', 'd')
        status = self.process.wait(timeout=15)
        require(status == 0, 'natural menu d exit failed')
        self.window = None
        self.diagnostics()
        return saved, self.inspect_save(label), status

    def cleanup(self):
        errors = []
        if self.keyboard is not None:
            if self.keyboard.held():
                errors.append('physical keys left held')
            self.keyboard.close()
        if any(process.poll() is None for process in self.processes):
            errors.append('game still running; namespace teardown is NOT natural exit proof')
        if self.server is not None and self.server.poll() is None:
            self.server.terminate()  # only this consumer's X server
            try:
                self.server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                errors.append('consumer Xvfb did not stop')
        return {'game_exit_statuses': [process.poll() for process in self.processes],
                'xvfb_exit_status': None if self.server is None else self.server.poll(), 'errors': errors}


def movement(session, before, label):
    x, y = before.actor()
    for key, dx, dy in DIRECTIONS:
        nx, ny = x + dx, y + dy
        if not (0 <= nx < 80 and 0 <= ny < 43):
            continue
        # A visible bare light-ground cell: no monster, object or unknown RNG
        # outcome assumption. No movement trial, regeneration or reroll.
        if before.codes[ny][nx] != 32 or before.backgrounds[ny][nx] != (200, 180, 50):
            continue
        after = session.action(label, key)
        require(after.actor() == (nx, ny), 'arrow did not move onto observed bare ground')
        require(after.region(0, 0, 80, 43) != before.region(0, 0, 80, 43), 'movement did not change native map')
        after.state()
        return after, {'key': key, 'observed_target_background': [200, 180, 50],
                       'before': before.state(), 'after': after.state()}
    raise RuntimeError('no observed adjacent bare ground; this run is not rerolled')


def inventory_modal(session, label, equipped):
    frame = session.action(label, 'i')
    require(frame.has_label('(a)combat knife') and frame.has_label('Press the key next to an item'),
            'original inventory not visible')
    require(frame.has_label('(on right hand)') == equipped, 'native knife equipment state differs')
    return frame


def play(session):
    first = session.launch('new')
    session.await_frame('title', lambda frame: frame.has_label('(a)Play a new game') and frame.has_label('(d)Quit'))
    require(not session.state_dir.exists() or not any(session.state_dir.iterdir()), 'preseeded native state')
    session.key('new-game-a', 'a')
    session.await_frame('intro-start', lambda frame: frame.has_label('INITIATE COMM SEQUENCE'))
    # Let the original 14-line cinematic finish (18.2s); no skip or queued
    # key can leak into the subsequent name-entry press-only loop.
    session.await_frame('intro', lambda frame: frame.has_label('Press any key to continue'), timeout=35, retain=True)
    session.key('intro-acknowledge', 'Return')
    session.await_frame('name-prompt', lambda frame: frame.has_label('What is your name, Ensign?'))
    for index, letter in enumerate(PLAYER_NAME):
        session.key('name-letter-' + str(index), letter)
    named = session.capture('name-entry', retain=True)
    require(named.has_label(PLAYER_NAME), 'physical name entry differs')
    session.key('name-submit', 'Return')
    initial = session.await_frame('new-world', lambda frame: 'Cave level 1' in frame.text(), retain=True)
    initial.state()
    moved, movement_proof = movement(session, initial, 'new-game-movement')
    inventory_modal(session, 'inventory-first', True)
    restored = session.action('inventory-cancel', 'Escape')
    require(restored.pixels == moved.pixels, 'inventory cancel changed world/HUD/messages or saved unexpectedly')
    saved, first_save, first_status = session.save_and_quit('first')
    require(saved.pixels == restored.pixels, 'pre-save state changed without input')
    second = session.launch('continue')
    require(second['pid'] != first['pid'], 'Continue not a fresh interpreter')
    session.await_frame('continue-title', lambda frame: frame.has_label('(b)Continue last save') and frame.has_label('(d)Quit'))
    session.key('continue-b', 'b')
    resumed = session.await_frame('continued', lambda frame: 'Cave level 1' in frame.text(), retain=True)
    require(resumed.pixels == saved.pixels, 'fresh Continue did not restore exact map/player/HUD/messages')
    require(session.save_files() == first_save['files'], 'Continue changed native save bytes')
    # Establish disk/visible continuity BEFORE spending a real gameplay turn.
    # Choose from current observed bare ground, never a blind move or reroll.
    continued, continued_movement = movement(session, resumed, 'continued-movement')
    inventory_modal(session, 'continued-inventory', True)
    # Also exercise original inventory use after the continued gameplay turn:
    # dequip the starting knife, inspect its menu, and persist the change.
    changed = session.action('continued-dequip-a', 'a')
    require('Dequipped combat knife from right hand.' in changed.text(), 'knife use did not dequip')
    require(changed.actor() == continued.actor(), 'no-turn inventory use moved player')
    inventory_modal(session, 'inventory-dequipped', False)
    # Retain just this distinct inventory state, not all polling frames.
    dequipped = session.capture('inventory-dequipped', retain=True)
    require(not dequipped.has_label('(on right hand)'), 'dequip not reflected in inventory')
    session.key('inventory-dequipped-cancel', 'Escape')
    final, final_save, final_status = session.save_and_quit('final')
    require(final_save['files'] != first_save['files'], 'resave did not persist meaningful action')
    require(final_save['shelve_values']['inventory']['sha256'] != first_save['shelve_values']['inventory']['sha256'],
            'native persisted inventory unchanged after dequip')
    require(final.pixels == changed.pixels, 'inventory inspection/save changed post-turn world without input')
    require(final.actor() == continued.actor() and final.actor() != resumed.actor(),
            'final native state did not preserve continued movement')
    require(final_save['shelve_values']['objects']['sha256'] != first_save['shelve_values']['objects']['sha256'],
            'resaved native world objects did not persist post-Continue progress')
    # A real turn can change explored flags and monster positions. Full-map
    # pickle equality is intentionally required nowhere AFTER this turn.
    return {'new_process': first, 'continued_process': second, 'movement': movement_proof,
            'continued_movement': continued_movement,
            'new': initial.state(), 'first': saved.state(), 'continued': resumed.state(), 'final': final.state(),
            'exact_visible_continuity': True, 'continue_save_bytes_unchanged': True,
            'further_action': 'observed-ground movement spends a real turn; inventory a dequips knife; resave persists changed objects and inventory',
            'first_save': first_save, 'final_save': final_save, 'natural_exit_statuses': [first_status, final_status]}


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
              'verification': 'external real X11/XTEST/framebuffer/native DBM disassembly; no injected state or instrumentation'}
    root = session = None
    cleanup_errors = []
    try:
        require(os.getpid() == 1, 'not PID1 in private proc mount')
        report['isolation_before_drop'] = namespaces(Path('/proc/self'))
        evidence, entries = isolate(evidence)
        drop_privileges()
        report['isolation'] = namespaces(Path('/proc/self'), hardened=True)
        report['isolation']['store'] = entries
        native = output / 'bin/handhrl'
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
        report['output'] = {'launcher_sha256': sha(native.read_bytes()), 'closure': closure}
        root = Path('/tmp/handhrl-private')
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'state', 'cache', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        record(evidence / 'private-before.json', inventory(root))
        session = Session(output, evidence, root, sys.argv[3:])
        report['gameplay'] = play(session)
        writes = inventory(root)
        for name, item in writes.items():
            require(item['type'] in ('file', 'directory'), 'unexpected private symlink/device: ' + name)
            if item['type'] == 'file':
                require(Path(name).parent == Path('data/handhrl') and
                        re.fullmatch(r'(?:savegame|scorefile)(?:\.(?:db|dat|dir|bak))?', Path(name).name) and item['size'] > 0,
                        'unexpected native write: ' + name)
                require(item['uid'] == 1000 and item['gid'] == 998 and not (item['mode'] & 0o077),
                        'native state owner/umask differs')
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
                # Successful saves already have two exact snapshots. On failure
                # retain only game-generated state, never transient frame dumps.
                if not report['success'] and session is not None and session.state_dir.exists():
                    target = evidence / 'failure-native-state'
                    target.mkdir(mode=0o700)
                    for path in session.state_dir.iterdir():
                        if path.is_file() and not path.is_symlink():
                            shutil.copyfile(path, target / path.name)
                shutil.rmtree(root)
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
    print('HANDHRL_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
