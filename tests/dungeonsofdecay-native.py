#!/usr/bin/env python3
"""External consumer of the exact 0.4.9 Python2/SDL game, never a game hook.

Oracles: Dungeons_of_Decay.py render_all:1585-1786 (50x50 map, right
30-column HUD and Steps), handle_keys:2592-2661 (S, arrows, ., inventory),
new_game:2989 (race menu), save/load:3064-3202, main_menu:3227-3243.
IMPORTANT: supporters.py YesNo:315-321 is a letter-indexed menu: (a) Yes,
(b) No. Uppercase S then a saves; y does NOT mean Yes in this upstream.
libtcod 1.5.0 sys_sdl_c.c:122-139,271-291 defines TCOD atlas mapping;
wait_for_keypress:852-865 accepts modifier presses and flushes queued events.
No forced seed, injected save, imported game module or process-memory access.
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

COLS, ROWS, CELL = 80, 50, 12
WIDTH, HEIGHT = COLS * CELL, ROWS * CELL
FONT_HASH = '9ecc8d2b6d702b46ba92a89c7e9963a90409b3cdd9c454464216a2310f63a1fb'
SOURCE = 'https://downloads.sourceforge.net/project/dungeonsofdecay/Dungeons_of_Decay_0_4_9_sources.zip'
SOURCE_HASH = '800d5d9be83077767c80f19c93d8d07a1f2552aba5d6f7d29d7734843c8d5c43'
FAILURES = re.compile(r'traceback|\b\w*(?:Error|Exception)\s*:|segmentation fault|permission denied|'
                      r'no such file|couldn.t (?:open|load)|cannot (?:open|load)|'
                      r'failed to|assertion .* failed|terminate called', re.I)
ERROR_SEVERITY = re.compile(r'^\s*(?:>\s*)?(?:\((?:EE|F)\)\s*|'
                            r'(?:fatal|error)\b|X (?:Error|IO Error)\b)', re.I)
WARNING_SEVERITY = re.compile(r'^\s*(?:>\s*)?\(WW\)\s*|\bwarning\s*:', re.I)
NEGATED_FATAL = re.compile(r'\b(?:errors?|warnings?)\s+.+?\s+(?:are|is)\s+not\s+fatal\b', re.I)
DIRECTIONS = [('Left', -1, 0), ('Right', 1, 0), ('Up', 0, -1), ('Down', 0, 1)]


def diagnostics(text):
    """Keep every line; distinguish severity markers from negated prose.

    Concrete failures and explicit error severity always win, even on a line
    also containing 'not fatal'. No entire log or server is exempted.
    """
    result = []
    for number, line in enumerate(text.splitlines(), 1):
        if FAILURES.search(line) or ERROR_SEVERITY.search(line):
            severity = 'error'
        elif WARNING_SEVERITY.search(line):
            severity = 'warning'
        elif NEGATED_FATAL.search(line):
            severity = 'informational-nonfatal'
        elif 'should be' in line.lower():
            severity = 'advisory'
        else:
            severity = 'information'
        result.append({'line': number, 'severity': severity, 'text': line})
    return result


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
        retained = Path('/tmp/dungeonsofdecay-evidence')
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
        self.pixels, self.codes = pixels, []
        for row in range(ROWS):
            codes = []
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
                    code = 32
                else:
                    error, code = min(((mask ^ glyph).bit_count(), code)
                                      for code, glyph in glyphs.items())
                    if error > 8:
                        code = -1
                codes.append(code)
            self.codes.append(codes)
        self.rows = [''.join(chr(code) if 32 <= code < 127 else '~'
                             for code in row) for row in self.codes]

    def text(self):
        return '\n'.join(self.rows)

    def actor(self):
        points = [(col, row) for row in range(50) for col in range(50)
                  if self.codes[row][col] == ord('@')]
        require(len(points) == 1, 'visible map player @ is not unique: ' + repr(points))
        return points[0]

    def turn(self):
        # Semantic HUD field, not incidental prose: render_all:1761-1764.
        match = re.search(r'Steps:\s*([\d.]+)', self.rows[6][50:])
        require(match is not None, 'visible native Steps counter missing (possibly a load-error modal)')
        return int(match[1].replace('.', ''))

    def region(self, x, y, width, height):
        return b''.join(self.pixels[((y * CELL + row) * WIDTH + x * CELL) * 3:
                                   ((y * CELL + row) * WIDTH + (x + width) * CELL) * 3]
                        for row in range(height * CELL))

    def state(self):
        return {'player': self.actor(), 'turn': self.turn(),
                'map_sha256': digest(self.region(0, 0, 50, 50)),
                'hud_sha256': digest(self.region(50, 0, 30, 13)),
                'messages_sha256': digest(self.region(50, 13, 30, 37)),
                'rgb_sha256': digest(self.pixels)}


class PhysicalKeyboard:
    """Send exactly one physical edge, without keysym modifier synthesis.

    xdotool xdo.c _xdo_send_key derives modmask and may synthesize modifier
    edges itself (including for Shift_L). Numeric XTEST keycodes avoid that
    ambiguity; XQueryKeymap receipts prove the real server-held key state.
    """
    def __init__(self, display, x11_path, xtst_path):
        self.x11 = ctypes.CDLL(x11_path, mode=ctypes.RTLD_GLOBAL)
        self.xtst = ctypes.CDLL(xtst_path)
        self.x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
        self.x11.XOpenDisplay.restype = ctypes.c_void_p
        self.x11.XStringToKeysym.argtypes = [ctypes.c_char_p]
        self.x11.XStringToKeysym.restype = ctypes.c_ulong
        self.x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
        self.x11.XKeysymToKeycode.restype = ctypes.c_ubyte
        self.x11.XSync.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.x11.XSync.restype = ctypes.c_int
        self.x11.XQueryKeymap.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
        self.x11.XQueryKeymap.restype = ctypes.c_int
        self.x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
        self.x11.XCloseDisplay.restype = ctypes.c_int
        self.xtst.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint,
                                               ctypes.c_int, ctypes.c_ulong]
        self.xtst.XTestFakeKeyEvent.restype = ctypes.c_int
        self.xtst.XTestQueryExtension.argtypes = [ctypes.c_void_p, *([ctypes.POINTER(ctypes.c_int)] * 4)]
        self.xtst.XTestQueryExtension.restype = ctypes.c_int
        self.display = self.x11.XOpenDisplay(display.encode('ascii'))
        require(self.display, 'cannot open private physical XTEST display')
        values = [ctypes.c_int() for _ in range(4)]
        require(self.xtst.XTestQueryExtension(self.display, *(ctypes.byref(value) for value in values)),
                'real XTEST extension unavailable')
        self.expected = set()
        require(not self.held(), 'private X server starts with held keys')

    def held(self):
        bitmap = (ctypes.c_ubyte * 32)()
        require(self.x11.XQueryKeymap(self.display, bitmap), 'XQueryKeymap failed')
        return {code for code in range(256) if bitmap[code // 8] & (1 << (code % 8))}

    def edge(self, key, pressed):
        symbol = self.x11.XStringToKeysym(key.encode('ascii'))
        require(symbol, 'unknown physical keysym: ' + key)
        code = int(self.x11.XKeysymToKeycode(self.display, symbol))
        require(code, 'no physical keycode for: ' + key)
        before = self.held()
        require(before == self.expected, 'unexpected physical held keys before edge')
        require((code not in before) if pressed else (code in before), 'duplicate physical edge: ' + key)
        require(self.xtst.XTestFakeKeyEvent(self.display, code, int(pressed), 0), 'XTEST edge failed')
        self.x11.XSync(self.display, 0)
        if pressed:
            self.expected.add(code)
        else:
            self.expected.remove(code)
        after = self.held()
        require(after == self.expected, 'physical edge changed unexpected X server keys')
        return {'keysym': key, 'keycode': code, 'pressed': pressed,
                'held_before': sorted(before), 'held_after': sorted(after)}

    def close(self):
        self.x11.XCloseDisplay(self.display)


class Session:
    def __init__(self, output, evidence, root, tools):
        self.output, self.evidence, self.root = output, evidence, root
        self.xvfb, self.xdotool, self.xwd, self.convert, self.x11_path, self.xtst_path = tools
        self.process = self.server = self.window = self.keyboard = None
        self.inputs, self.commands, self.processes = [], [], []
        self.env = {'PATH': '', 'LC_ALL': 'C', 'HOME': str(root / 'home'),
                    'TMPDIR': str(root / 'tmp'), 'SDL_VIDEODRIVER': 'x11',
                    'SDL_AUDIODRIVER': 'dummy', 'LIBGL_ALWAYS_SOFTWARE': 'true',
                    'GALLIUM_DRIVER': 'llvmpipe', 'MESA_LOADER_DRIVER_OVERRIDE': 'swrast',
                    'MESA_SHADER_CACHE_DISABLE': 'true', 'PYTHONNOUSERSITE': '1',
                    'PYTHONDONTWRITEBYTECODE': '1',
                    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-session'),
                    'DBUS_SYSTEM_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-system')}
        for variable, name in [('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                               ('XDG_STATE_HOME', 'state'), ('XDG_CACHE_HOME', 'cache'),
                               ('XDG_RUNTIME_DIR', 'runtime')]:
            self.env[variable] = str(root / name)
        self.state_dir = root / 'data/dungeonsofdecay'
        font = output / 'share/dungeonsofdecay/arial12x12.png'
        require(digest(font.read_bytes()) == FONT_HASH, 'font differs from exact original asset')
        geometry = self.tool(self.convert, str(font), '-format', '%w %h', 'info:')
        require(geometry.strip() == b'384 96', 'original 32x8 TCOD atlas changed')
        pixels = self.tool(self.convert, str(font), '-depth', '8', 'rgba:-')
        require(len(pixels) == 384 * 96 * 4, 'font pixels truncated')
        transparent = any(pixels[i] < 255 for i in range(3, len(pixels), 4))
        invert = pixels[((CELL // 2) * 384 + CELL // 2) * 4] > 128
        self.glyphs = {}
        # Exact init_ascii_to_tcod table for printable ASCII, not ASCII_INROW.
        mapping = [*range(32), 32, *range(96, 122), *range(33, 38),
                   38, *range(128, 154), *range(39, 43)]
        require(len(mapping) == 95, 'printable TCOD table length')
        for code, index in zip(range(32, 127), mapping):
            values = []
            for y in range((index // 32) * CELL, (index // 32 + 1) * CELL):
                for x in range((index % 32) * CELL, (index % 32 + 1) * CELL):
                    i = (y * 384 + x) * 4
                    values.append(pixels[i + 3] if transparent else
                                  255 - pixels[i] if invert else pixels[i])
            peak = max(values)
            self.glyphs[code] = sum(1 << i for i, value in enumerate(values)
                                    if peak and value > peak / 3)

    def tool(self, *command, absent_ok=False):
        result = subprocess.run(command, env=self.env, capture_output=True, timeout=15)
        self.commands.append({'argv': command, 'status': result.returncode,
                              'stdout_sha256': digest(result.stdout),
                              'stderr': result.stderr.decode('utf-8', errors='replace')})
        record(self.evidence / 'tool-commands.json', self.commands)
        require(result.returncode == 0 or (absent_ok and result.returncode == 1),
                'native consumer command failed: ' + repr(command))
        classified = diagnostics(result.stderr.decode('utf-8', errors='replace'))
        self.commands[-1]['diagnostics'] = classified
        record(self.evidence / 'tool-commands.json', self.commands)
        require(not any(item['severity'] == 'error' for item in classified),
                'native consumer reported an error: ' + repr(command))
        return result.stdout

    def assert_no_errors(self):
        retained = {}
        for path in [*self.evidence.glob('game-*.stdout'), *self.evidence.glob('game-*.stderr'),
                     self.evidence / 'xvfb.log']:
            if path.exists():
                retained[path.name] = diagnostics(path.read_text(errors='replace'))
        record(self.evidence / 'native-diagnostics.json', retained)
        errors = {name: [item for item in items if item['severity'] == 'error']
                  for name, items in retained.items()}
        errors = {name: items for name, items in errors.items() if items}
        require(not errors, 'native error (exit0 is not success): ' + repr(errors))

    def launch(self, label):
        if self.server is None:
            read_fd, write_fd = os.pipe()
            try:
                with (self.evidence / 'xvfb.log').open('wb') as log:
                    self.server = subprocess.Popen([self.xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                                    '1024x768x24', '-nolisten', 'tcp', '-ac', '-r'],
                                                   env=self.env, pass_fds=(write_fd,), stdout=log, stderr=log)
                os.close(write_fd)
                write_fd = None
                require(select.select([read_fd], [], [], 15)[0], 'Xvfb allocation timed out')
                display = os.read(read_fd, 128).decode('ascii').strip()
                require(display.isdecimal(), 'Xvfb did not allocate a private display')
                self.env['DISPLAY'] = ':' + display
            finally:
                os.close(read_fd)
                if write_fd is not None:
                    os.close(write_fd)
            self.keyboard = PhysicalKeyboard(self.env['DISPLAY'], self.x11_path, self.xtst_path)
        require(self.process is None or self.process.poll() == 0, 'previous game did not quit naturally')
        with (self.evidence / ('game-' + label + '.stdout')).open('wb') as stdout, \
             (self.evidence / ('game-' + label + '.stderr')).open('wb') as stderr:
            self.process = subprocess.Popen([str(self.output / 'bin/dungeonsofdecay')],
                                            env=self.env, cwd=self.root / 'work', stdout=stdout, stderr=stderr)
        self.processes.append(self.process)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            self.assert_no_errors()
            require(self.process.poll() is None, 'game exited before SDL window')
            windows = self.tool(self.xdotool, 'search', '--onlyvisible', '--name', '^Dungeons of Decay$',
                                absent_ok=True).decode('ascii').splitlines()
            if windows:
                require(len(windows) == 1, 'native window not unique')
                self.window = windows[0]
                self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
                time.sleep(0.5)
                proc = Path('/proc') / str(self.process.pid)
                proof = namespace_proof(proc)
                proof.update(exe=os.readlink(proc / 'exe'), cwd=os.readlink(proc / 'cwd'), pid=self.process.pid)
                cmdline = (proc / 'cmdline').read_bytes().split(b'\0')
                scripts = [Path(os.fsdecode(arg)) for arg in cmdline
                           if arg.endswith(b'/Dungeons_of_Decay.py')]
                require(len(scripts) == 1 and scripts[0].is_relative_to(self.output) and scripts[0].is_file(),
                        'not immutable installed original main script')
                interpreter = Path(proof['exe'])
                require(interpreter.parent.parent.parent == Path('/gnu/store') and
                        interpreter.name.startswith('python2') and interpreter.read_bytes()[:4] == b'\x7fELF',
                        'launcher did not exec native store Python2')
                require(Path(proof['cwd']) == self.state_dir, 'not writable XDG native save cwd')
                mappings = (proc / 'maps').read_text()
                require(re.search(r'/gnu/store/[^/]+/[^\s]*libtcod\.so', mappings),
                        'native libtcod shared renderer not mapped')
                require(re.search(r'/gnu/store/[^/]+/lib/libSDL[^/\s]*\.so', mappings),
                        'native SDL runtime not mapped')
                for name in ('status', 'maps', 'mountinfo', 'cmdline'):
                    (self.evidence / ('process-' + label + '-' + name + '.raw')).write_bytes((proc / name).read_bytes())
                return proof
            time.sleep(0.1)
        raise RuntimeError('native SDL window timeout')

    def capture(self, label):
        self.assert_no_errors()
        require(self.process.poll() is None, 'game exited during ' + label)
        dump, png = self.evidence / (label + '.xwd'), self.evidence / (label + '.png')
        self.tool(self.xwd, '-silent', '-id', self.window, '-out', str(dump))
        self.tool(self.convert, str(dump), str(png))
        geometry = self.tool(self.convert, str(png), '-format', '%w %h', 'info:')
        require(tuple(map(int, geometry.split())) == (WIDTH, HEIGHT), 'original 80x50 SDL geometry changed')
        pixels = self.tool(self.convert, str(png), '-depth', '8', 'rgb:-')
        (self.evidence / (label + '.rgb')).write_bytes(pixels)
        frame = Frame(pixels, self.glyphs)
        (self.evidence / (label + '.screen.txt')).write_text(frame.text() + '\n')
        record(self.evidence / (label + '.screen.json'), {'codes': frame.codes,
                                                         'png_sha256': digest(png.read_bytes())})
        return frame

    def edges(self, label, sequence):
        require(self.process.poll() is None, 'input to exited game')
        receipts, pressed_at = [], {}
        try:
            for key, pressed, pause in sequence:
                receipt = self.keyboard.edge(key, pressed)
                now = time.monotonic()
                receipts.append(dict(receipt, label=label,
                                     operation='keydown' if pressed else 'keyup',
                                     monotonic=now, transport='direct physical XTestFakeKeyEvent'))
                if pressed:
                    pressed_at[receipt['keycode']] = now
                else:
                    started = pressed_at.pop(receipt['keycode'], None)
                    require(started is not None and now - started < 0.45,
                            'physical hold reached upstream SDL repeat delay')
                    receipts[-1]['held_seconds'] = now - started
                if pause:
                    time.sleep(pause)
            require(not pressed_at and not self.keyboard.held(), 'physical group left held keys')
        finally:
            # No framebuffer conversion or evidence-file IO while a key is
            # held: upstream sys_sdl_c.c:549 enables SDL's 500ms repeat.
            self.inputs.extend(receipts)
            record(self.evidence / 'native-inputs.json', self.inputs)
        time.sleep(0.2)

    def key(self, label, key):
        self.edges(label, [(key, True, 0.03), (key, False, 0)])

    def action(self, label, key):
        self.key(label, key)
        return self.capture(label)

    def save(self, label, title):
        saved = self.capture(label + '-saved-state')
        inventory_frame = self.action(label + '-modifier-staging-inventory', 'i')
        require(inventory_frame.pixels != saved.pixels and '(a)' in inventory_frame.text(),
                'native inventory did not open for modifier staging')
        # Shift cancels inventory without a turn (handle_keys:2655-2661).
        # Let that wait/redraw complete, then tap uppercase S and release
        # both keys before capturing. SDL repeats held keys after 500ms;
        # native-4 held Shift for1.71s and s for>0.85s across conversion,
        # allowing repeated S to cancel the YesNo menu. Never disable repeat.
        self.edges(label + '-uppercase-S-short-group',
                   [('Shift_L', True, 0.15), ('s', True, 0.03),
                    ('s', False, 0), ('Shift_L', False, 0)])
        confirmation = self.capture(label + '-confirmation')
        require(confirmation.pixels != saved.pixels and '(a)' in confirmation.text() and
                '(b)' in confirmation.text(), 'native indexed Yes/No confirmation is not visible')
        require(confirmation.region(50, 0, 30, 13) == saved.region(50, 0, 30, 13) and
                confirmation.turn() == saved.turn(),
                'short uppercase save group spent an unintended gameplay turn')
        menu = self.action(label + '-confirmed-a', 'a')
        require(menu.pixels == title.pixels, 'save did not return to original native menu')
        files = {str(path.relative_to(self.state_dir)): {'size': path.stat().st_size,
                                                       'sha256': digest(path.read_bytes())}
                 for path in sorted(self.state_dir.glob('savegame.rls*')) if path.is_file()}
        require(files and all(item['size'] > 0 for item in files.values()), 'ordinary native save not generated')
        record(self.evidence / (label + '-native-save.json'), files)
        for name in files:
            shutil.copyfile(self.state_dir / name, self.evidence / (label + '-' + name))
        return saved, {'before_modifier': saved.state(), 'saved': saved.state(), 'files': files,
                       'confirmation': 'S then (a) Yes; upstream y is not a confirmation'}

    def quit(self, label):
        self.key(label + '-menu-c', 'c')
        status = self.process.wait(timeout=15)
        require(status == 0, 'natural main-menu c quit failed: %r' % status)
        self.assert_no_errors()
        self.window = None
        return status

    def cleanup(self):
        errors = []
        if self.keyboard is not None and self.keyboard.expected:
            errors.append('physical keys remain held after failed input group')
        # A still-live game is never killed or misreported as an ordinary quit.
        # The enclosing PID namespace teardown bounds failure lifetime.
        if any(process.poll() is None for process in self.processes):
            errors.append('game still running; namespace teardown is not natural quit evidence')
        if self.keyboard is not None:
            try:
                self.keyboard.close()
            except BaseException as error:
                errors.append('physical XTEST display cleanup: ' + repr(error))
        if self.server is not None and self.server.poll() is None:
            self.server.terminate()  # only the consumer-owned X server
            try:
                self.server.wait(timeout=5)
            except BaseException as error:
                errors.append('Xvfb cleanup: ' + repr(error))
        return {'game_exit_statuses': [process.poll() for process in self.processes],
                'xvfb_exit_status': None if self.server is None else self.server.poll(), 'errors': errors}


def movement(session, before, label):
    x, y = before.actor()
    for key, dx, dy in DIRECTIONS:
        nx, ny = x + dx, y + dy
        if not (0 <= nx < 50 and 0 <= ny < 50):
            continue
        # Select visible ordinary ground, not an attack or an unseen obstacle.
        if before.codes[ny][nx] not in (ord('.'), ord("'"), ord('<'), ord('>')):
            continue
        after = session.action(label, key)
        require(after.actor() == (nx, ny), 'real arrow did not move onto observed passable ground')
        require(after.turn() == before.turn() + 1, 'movement did not take one native turn')
        require(after.region(0, 0, 50, 50) != before.region(0, 0, 50, 50), 'movement map did not visibly change')
        return after, {'key': key, 'before': before.state(), 'after': after.state()}
    raise RuntimeError('no adjacent visible passable ground for real movement')


def look(session, before):
    # look_out:2473 assigns fov_recompute locally, so opening look may leave
    # the last framebuffer unchanged. target_move:2507 sets the real global;
    # an arrow is required to exercise the native '+' cursor renderer.
    x, y = before.actor()
    key, dx, dy = next((key, dx, dy) for key, dx, dy in DIRECTIONS
                       if 0 <= x + 2 * dx < 50 and 0 <= y + 2 * dy < 50)
    entered = session.action('look-enter', 'l')
    require(entered.turn() == before.turn(), 'opening look spent a native world turn')
    first = session.action('look-cursor-first', key)
    require(first.codes[y + dy][x + dx] == ord('+'), 'first native look cursor not visible')
    require(first.actor() == (x, y) and first.turn() == before.turn(),
            'look arrow moved player or advanced native world turn')
    second = session.action('look-cursor-second', key)
    require(second.codes[y + 2 * dy][x + 2 * dx] == ord('+'), 'native look cursor did not move')
    require(second.actor() == (x, y) and second.turn() == before.turn(),
            'second look arrow moved player or advanced native world turn')
    # Only the cursor cells and HUD row3 (tile/object description) change.
    for row in range(50):
        for col in range(50):
            if (col, row) not in ((x + dx, y + dy), (x + 2 * dx, y + 2 * dy)):
                require(second.region(col, row, 1, 1) == first.region(col, row, 1, 1),
                        'look cursor unexpectedly changed native world terrain/objects')
    for region in ((50, 0, 30, 3), (50, 4, 30, 46)):
        require(second.region(*region) == before.region(*region),
                'look changed native HUD/world messages outside target description')
    cancelled = session.action('look-cancel', 'Escape')
    require(cancelled.actor() == (x, y) and cancelled.turn() == before.turn(),
            'look Escape moved player or spent a native world turn')
    # Escape sets playing, but handle_keys:2769 returns before the global
    # redraw assignment; look_out:2479 assigns only its local shadow. Thus
    # the historical screen retains exactly the last cursor/description.
    require(cancelled.pixels in (second.pixels, before.pixels),
            'look cancellation changed anything beyond its known stale overlay')
    # Ordinary inventory open/cancel sets the real global fov_recompute and
    # takes no world turn. Its positive appearance also proves Escape left
    # look mode: i cannot open inventory while still looking.
    inventory_frame = session.action('look-after-cancel-inventory', 'i')
    require(inventory_frame.pixels != cancelled.pixels and '(a)' in inventory_frame.text(),
            'Escape did not leave look mode for ordinary inventory input')
    restored = session.action('look-after-cancel-inventory-dismiss', 'Escape')
    require(restored.state() == before.state(),
            'neutral native redraw failed exact world/HUD/messages restoration or advanced a turn')
    return {'key': key, 'player': [x, y], 'world_turn': before.turn(),
            'cursor_first': [x + dx, y + dy], 'cursor_second': [x + 2 * dx, y + 2 * dy],
            'cursor_only_movement': True, 'escape_left_stale_overlay': cancelled.pixels == second.pixels,
            'inventory_proved_playing_without_turn': True, 'cancel_restored': restored.state()}


def play(session):
    first_process = session.launch('new')
    title = session.capture('title')
    require(len(set(title.pixels)) > 16, 'native entrance framebuffer is blank')
    race = session.action('race-menu', 'a')
    require(race.pixels != title.pixels, 'new-game race menu did not appear')
    initial = session.action('initial', 'c')  # ordinary dwarf selection, not forced state
    require(initial.turn() == 0, 'new game did not start with native zero Steps')
    initial.actor()
    moved, move_proof = movement(session, initial, 'movement')
    rested = session.action('rest', 'period')
    require(rested.actor() == moved.actor() and rested.turn() == moved.turn() + 1,
            'ordinary rest did not hold position and advance one native turn')
    inventory_frame = session.action('inventory', 'i')
    require(inventory_frame.pixels != rested.pixels and '(a)' in inventory_frame.text(),
            'ordinary inventory modal/items not visible')
    dismissed = session.action('inventory-cancel', 'Escape')
    require(dismissed.state() == rested.state(), 'inventory cancellation changed map/HUD/messages or took a turn')
    look_proof = look(session, dismissed)
    saved, save_proof = session.save('save-first', title)
    first_quit = session.quit('first-natural-quit')
    # Fresh real interpreter removes the possibility of proving only in-memory
    # continuity. Only the game opens its own shelve and unpickles native data.
    second_process = session.launch('continue')
    second_title = session.capture('continue-title')
    require(second_title.pixels == title.pixels, 'relaunch native menu changed')
    resumed = session.action('continued', 'b')
    require(resumed.state() == saved.state(),
            'disk reload did not restore observed map, HUD, player, turn and messages; load-error modal fails')
    unchanged = {str(path.relative_to(session.state_dir)): {'size': path.stat().st_size,
                                                          'sha256': digest(path.read_bytes())}
                 for path in sorted(session.state_dir.glob('savegame.rls*')) if path.is_file()}
    require(unchanged == save_proof['files'], 'read-only native continue unexpectedly changed save bytes')
    continued, continued_proof = movement(session, resumed, 'continued-movement')
    final, final_save = session.save('save-final', title)
    require(final.turn() > saved.turn(), 'continued game did not make meaningful progress')
    require(final_save['files'] != save_proof['files'], 'second ordinary save did not persist progress')
    final_quit = session.quit('final-natural-quit')
    return {'new_process': first_process, 'continued_process': second_process,
            'initial': initial.state(), 'movement': move_proof,
            'rest': {'before': moved.state(), 'after': rested.state()},
            'inventory_cancel_without_turn': True, 'look': look_proof, 'first_save': save_proof,
            'first_natural_menu_c_status': first_quit, 'restored': resumed.state(),
            'reload_exact_visible_map_hud_messages': True, 'reload_save_bytes_unchanged': True,
            'continued_movement': continued_proof, 'final_save': final_save,
            'final_natural_menu_c_status': final_quit}


def main():
    require(len(sys.argv) == 9, 'usage: native.py OUTPUT EVIDENCE XVFB XDOTOOL XWD CONVERT LIBX11 LIBXTST')
    output, evidence = map(Path, sys.argv[1:3])
    require(output.is_absolute() and output.resolve() == output and
            output.parent == Path('/gnu/store') and output.is_dir(), 'canonical prebuilt store item required')
    require(evidence.is_absolute() and evidence.resolve() == evidence and evidence.is_dir() and
            not (evidence / 'native-result.json').exists(), 'fresh shell evidence required')
    for tool in sys.argv[3:]:
        require(Path(tool).is_absolute() and Path(tool).is_file() and os.access(tool, os.R_OK),
                'consumer tool/library must be resolved before isolation: ' + tool)
    for tool in sys.argv[3:7]:
        require(os.access(tool, os.X_OK), 'consumer executable is not executable: ' + tool)
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc/self/fd/' + str(evidence_fd))
    report = {'success': False, 'source': SOURCE, 'source_sha256': SOURCE_HASH,
              'font_sha256': FONT_HASH, 'save_confirmation_correction':
              'supporters.py:315-321 YesNo uses menu indexes: S then a, not y.',
              'verification': 'real external X11 input and framebuffer; no injected state or game instrumentation'}
    root = session = None
    cleanup_errors = []
    try:
        require(os.getpid() == 1, 'consumer is not PID1 in private proc mount')
        report['isolation'] = namespace_proof(Path('/proc/self'))
        evidence, entries = isolate_filesystem(evidence)
        report['isolation']['store'] = entries
        native = output / 'bin/dungeonsofdecay'
        require(native.is_file() and os.access(native, os.X_OK), 'installed launcher not executable')
        require(not any('native.py' in path.name or 'smoke' in path.name for path in output.rglob('*')),
                'external helper leaked into output')
        closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
        require(str(output) in closure, 'runtime closure missing game')
        tools = json.loads((evidence / 'consumer-tools.json').read_text())
        consumers = {name: tools[name] for name in ('python', 'xorg-server', 'xdotool', 'xwd', 'imagemagick')}
        leaks = {name: path for name, path in consumers.items() if path in closure}
        record(evidence / 'consumer-closure-audit.json', {'consumer_outputs': consumers, 'exact_consumer_leaks': leaks})
        require(not leaks, 'consumer-only outputs leaked into runtime closure: ' + repr(leaks))
        report['output'] = {'launcher_sha256': digest(native.read_bytes()), 'closure': closure}
        root = Path('/tmp/dungeonsofdecay-private')
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        record(evidence / 'private-before.json', inventory(root))
        session = Session(output, evidence, root, sys.argv[3:])
        report['gameplay'] = play(session)
        writes = inventory(root)
        for name, item in writes.items():
            if item['type'] == 'file':
                require(Path(name).parent == Path('data/dungeonsofdecay') and
                        Path(name).name.startswith('savegame.rls') and item['size'] > 0,
                        'unexpected private native write: ' + name)
                require(item['uid'] == int(os.environ['HOST_UID']) and
                        item['gid'] == int(os.environ['HOST_GID']), 'native save owner differs from caller')
            require(item['type'] in ('file', 'directory'), 'unexpected private symlink/device: ' + name)
        session.assert_no_errors()
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
            try:
                session.assert_no_errors()
            except BaseException as error:
                cleanup_errors.append(str(error))
            diagnostics_path = evidence / 'native-diagnostics.json'
            if diagnostics_path.exists():
                retained = json.loads(diagnostics_path.read_text())
                report['diagnostics'] = retained
                report['nonfatal_warnings'] = [dict(item, log=name) for name, items in retained.items()
                                              for item in items if item['severity'] in
                                              ('warning', 'advisory', 'informational-nonfatal')]
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
        cleanup['errors'] = cleanup_errors
        if cleanup_errors:
            report['success'] = False
            report['cleanup_errors'] = cleanup_errors
        record(evidence / 'cleanup.json', cleanup)
        record(evidence / 'native-result.json', report)
        os.close(evidence_fd)
        require(not cleanup_errors, 'native cleanup failed: ' + repr(cleanup_errors))
    print('DUNGEONSOFDECAY_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
