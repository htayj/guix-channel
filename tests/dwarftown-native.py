#!/usr/bin/env python3
"""Drive the installed original Dwarftown with genuine XTEST keyboard events.

Exact source: src/ui.lua, src/game.lua, src/text.lua and src/main.lua in
commit 9488ae4ec385459ed6c8d15a642e43c8a11607f7. Read the actual 80x25
SDL raster using the original 10x18 font. No RNG seeds, game hooks, memory
injection, save/resume, replacement fonts or installed smoke helpers.
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

COLS, ROWS, CW, CH = 80, 25, 10, 18
WIDTH, HEIGHT = COLS * CW, ROWS * CH
FONT_HASH = '12bcd54b30b2eab6fd85e87d78781ab8064ef792df0d23bba254cc407ad51fe7'
COMMIT = '9488ae4ec385459ed6c8d15a642e43c8a11607f7'
SOURCE = 'https://github.com/pwmarcz/dwarftown/tree/' + COMMIT
ERRORS = re.compile(r'\berror\b|traceback|exception|segmentation fault|permission denied|'
                    r'no such file|couldn.t (?:open|load)|cannot (?:open|load)|'
                    r'failed to|assertion .* failed|terminate called', re.I)
DIRECTIONS = [('Up', 0, -1), ('Left', -1, 0), ('Right', 1, 0)]


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
        retained = Path('/tmp/dwarftown-evidence')
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
        self.pixels, self.codes, self.cells = pixels, [], []
        full_mask = (1 << (CW * CH)) - 1
        for row in range(ROWS):
            codes, cells = [], []
            for col in range(COLS):
                values = [tuple(pixels[((row * CH + y) * WIDTH + col * CW + x) * 3:
                                      ((row * CH + y) * WIDTH + col * CW + x) * 3 + 3])
                          for y in range(CH) for x in range(CW)]
                background = max(set(values), key=values.count)
                distances = [sum((a - b) ** 2 for a, b in zip(value, background))
                             for value in values]
                peak = max(distances)
                mask = sum(1 << i for i, distance in enumerate(distances)
                           if peak and distance > peak / 9)
                if not peak:
                    code = 32
                else:
                    error, code = min((min((mask ^ glyph).bit_count(),
                                          ((mask ^ full_mask) ^ glyph).bit_count()), code)
                                      for code, glyph in glyphs.items())
                    if error > 6:
                        code = -1
                codes.append(code)
                cells.append({'background': background, 'mask': mask,
                              'sha256': digest(bytes(c for value in values for c in value))})
            self.codes.append(codes)
            self.cells.append(cells)
        self.rows = [''.join(chr(code) if 32 <= code < 127 else '~' if code == -1 else ' '
                             for code in row) for row in self.codes]

    def text(self):
        return '\n'.join(self.rows)

    def actor(self):
        points = [(col, row) for row in range(ROWS) for col in range(50)
                  if self.codes[row][col] == 64]
        require(len(points) == 1, 'native player @ glyph is not unique: ' + repr(points))
        return points[0]

    def turn(self):
        match = re.search(r'Turn\s+(\d+)', self.text())
        require(match is not None, 'visible turn counter is missing')
        return int(match[1])

    def state(self):
        return {'player': self.actor(), 'turn': self.turn(), 'rows': self.rows,
                'rgb_sha256': digest(self.pixels)}


class Session:
    def __init__(self, output, evidence, root, tools):
        self.output, self.evidence, self.root = output, evidence, root
        self.xvfb, self.xdotool, self.xwd, self.convert = tools
        self.process = self.server = None
        self.window = None
        self.inputs, self.commands = [], []
        self.shift_held = False
        self.env = {'PATH': '', 'LC_ALL': 'C', 'HOME': str(root / 'home'),
                    'TMPDIR': str(root / 'tmp'), 'SDL_VIDEODRIVER': 'x11',
                    'SDL_AUDIODRIVER': 'dummy', 'LIBGL_ALWAYS_SOFTWARE': 'true',
                    'GALLIUM_DRIVER': 'llvmpipe', 'MESA_LOADER_DRIVER_OVERRIDE': 'swrast',
                    'MESA_SHADER_CACHE_DISABLE': 'true',
                    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-session'),
                    'DBUS_SYSTEM_BUS_ADDRESS': 'unix:path=' + str(root / 'runtime/no-system')}
        for variable, name in [('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                               ('XDG_STATE_HOME', 'state'), ('XDG_CACHE_HOME', 'cache'),
                               ('XDG_RUNTIME_DIR', 'runtime')]:
            self.env[variable] = str(root / name)
        font = output / 'share/dwarftown/fonts/terminal10x18.png'
        require(digest(font.read_bytes()) == FONT_HASH, 'font differs from exact original asset')
        geometry = self.tool(self.convert, str(font), '-format', '%w %h', 'info:')
        require(geometry.strip() == b'160 288', 'original font grid changed')
        pixels = self.tool(self.convert, str(font), '-depth', '8', 'rgba:-')
        require(len(pixels) == 160 * 288 * 4, 'font pixels truncated')
        transparent = any(pixels[i] < 255 for i in range(3, len(pixels), 4))
        # ui.lua:36-37 specifies ASCII_INROW: code % 16 is x, code // 16 is y.
        space = ((32 // 16) * CH + CH // 2) * 160 + (32 % 16) * CW + CW // 2
        invert = pixels[space * 4] > 128
        self.glyphs = {}
        for code in range(32, 127):
            values = []
            for y in range((code // 16) * CH, (code // 16 + 1) * CH):
                for x in range((code % 16) * CW, (code % 16 + 1) * CW):
                    i = (y * 160 + x) * 4
                    values.append(pixels[i + 3] if transparent else
                                  255 - pixels[i] if invert else pixels[i])
            peak = max(values)
            self.glyphs[code] = sum(1 << i for i, value in enumerate(values)
                                    if peak and value > peak / 3)

    def tool(self, *command):
        result = subprocess.run(command, env=self.env, capture_output=True, timeout=15)
        self.commands.append({'argv': command, 'status': result.returncode,
                              'stdout_sha256': digest(result.stdout),
                              'stderr': result.stderr.decode('utf-8', errors='replace')})
        record(self.evidence / 'tool-commands.json', self.commands)
        require(result.returncode == 0, 'native consumer command failed: ' + repr(command))
        require(not ERRORS.search(result.stderr.decode('utf-8', errors='replace')),
                'native consumer reported an error: ' + repr(command))
        return result.stdout

    def launch(self):
        read_fd, write_fd = os.pipe()
        try:
            with (self.evidence / 'xvfb.log').open('wb') as log:
                # Single physical edges must not auto-repeat while evidence
                # capture holds the key: repeats cancel legacy quit prompts.
                self.server = subprocess.Popen([self.xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                                '1024x768x24', '-nolisten', 'tcp', '-ac', '-r'],
                                               env=self.env, pass_fds=(write_fd,), stdout=log, stderr=log)
            os.close(write_fd)
            write_fd = None
            require(select.select([read_fd], [], [], 15)[0], 'Xvfb display allocation timed out')
            display = os.read(read_fd, 128).decode('ascii').strip()
            require(display.isdecimal(), 'Xvfb did not allocate a private display')
            self.env['DISPLAY'] = ':' + display
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
        with (self.evidence / 'game.log').open('wb') as log:
            self.process = subprocess.Popen([str(self.output / 'bin/dwarftown')],
                                            env=self.env, cwd=self.root / 'work', stdout=log, stderr=log)
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'ordinary game exited before SDL window')
            found = subprocess.run([self.xdotool, 'search', '--onlyvisible', '--name', '^Dwarftown$'],
                                   capture_output=True, env=self.env, timeout=5)
            self.commands.append({'argv': [self.xdotool, 'search', '--onlyvisible', '--name', '^Dwarftown$'],
                                  'status': found.returncode, 'stdout_sha256': digest(found.stdout),
                                  'stderr': found.stderr.decode('utf-8', errors='replace')})
            record(self.evidence / 'tool-commands.json', self.commands)
            require(found.returncode in (0, 1) and not ERRORS.search(
                    found.stderr.decode('utf-8', errors='replace')), 'X11 window search failed')
            self.assert_no_errors()
            if found.returncode == 0:
                windows = found.stdout.decode('ascii').splitlines()
                require(len(windows) == 1, 'native game window is not unique')
                self.window = windows[0]
                self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
                time.sleep(0.5)
                proc = Path('/proc') / str(self.process.pid)
                proof = namespace_proof(proc)
                proof.update(exe=os.readlink(proc / 'exe'), cwd=os.readlink(proc / 'cwd'), pid=self.process.pid)
                for name in ('status', 'maps', 'mountinfo', 'cmdline'):
                    (self.evidence / ('process-' + name + '.raw')).write_bytes((proc / name).read_bytes())
                require(Path(proof['exe']).read_bytes()[:4] == b'\x7fELF' and
                        Path(proof['exe']).name.startswith('lua') and
                        Path(proof['exe']).parent.parent.parent == Path('/gnu/store'),
                        'launcher did not exec installed native Lua interpreter')
                require(str(self.output / 'share/dwarftown/src/main.lua').encode() in
                        (proc / 'cmdline').read_bytes(), 'not installed original Lua game')
                mappings = (proc / 'maps').read_text()
                require(str(self.output / 'lib/dwarftown/libtcodlua.so') in mappings,
                        'generated Lua SWIG module not mapped')
                for library in ('libtcod.so', 'libtcodxx.so'):
                    require(re.search(r'/gnu/store/[^/]+-dwarftown-libtcod-1\.5\.1/lib/' +
                                      re.escape(library), mappings),
                            'private source-built renderer not mapped: ' + library)
                require(re.search(r'/gnu/store/[^/]+/lib/libSDL[^/\s]*\.so', mappings),
                        'native SDL library not mapped')
                require(Path(proof['cwd']) == self.root / 'work', 'native game changed private CWD')
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
        require(tuple(map(int, geometry.split())) == (WIDTH, HEIGHT), 'original 80x25 SDL geometry changed')
        pixels = self.tool(self.convert, str(png), '-depth', '8', 'rgb:-')
        (self.evidence / (label + '.rgb')).write_bytes(pixels)
        frame = Frame(pixels, self.glyphs)
        (self.evidence / (label + '.screen.txt')).write_text(frame.text() + '\n')
        record(self.evidence / (label + '.screen.json'), {'codes': frame.codes, 'cells': frame.cells,
                                                         'png_sha256': digest(png.read_bytes())})
        return frame

    def edge(self, label, key, pressed):
        operation = 'keydown' if pressed else 'keyup'
        self.inputs.append({'label': label, 'key': key, 'operation': operation,
                            'monotonic': time.monotonic(),
                            'transport': 'xdotool native focused XTEST keyboard'})
        record(self.evidence / 'native-inputs.json', self.inputs)
        self.tool(self.xdotool, operation, key)
        time.sleep(0.25)

    def held_action(self, label, key):
        self.edge(label, key, True)
        return self.capture(label)

    def key(self, label, key):
        require(self.process.poll() is None, 'input to exited game')
        self.inputs.append({'label': label, 'key': key, 'monotonic': time.monotonic(),
                            'transport': 'xdotool native focused XTEST keyboard'})
        record(self.evidence / 'native-inputs.json', self.inputs)
        self.tool(self.xdotool, 'key', '--clearmodifiers', key)
        time.sleep(0.22)

    def action(self, label, key):
        self.key(label, key)
        return self.capture(label)

    def shift(self, pressed):
        operation = 'keydown' if pressed else 'keyup'
        self.inputs.append({'label': 'help-shift-' + operation, 'key': 'Shift_L',
                            'operation': operation, 'monotonic': time.monotonic(),
                            'transport': 'xdotool native focused XTEST keyboard'})
        record(self.evidence / 'native-inputs.json', self.inputs)
        self.tool(self.xdotool, operation, 'Shift_L')
        self.shift_held = pressed
        time.sleep(0.25)

    def help_key(self):
        self.shift(True)
        # A modifier event completes legacy waitForKeypress. Capture its
        # redraw before sending slash, rather than queueing both for flush.
        self.capture('help-shift-redraw')
        self.inputs.append({'label': 'help-slash-shift-held', 'key': 'slash', 'operation': 'keydown',
                            'monotonic': time.monotonic(),
                            'transport': 'xdotool native focused XTEST keyboard'})
        record(self.evidence / 'native-inputs.json', self.inputs)
        self.tool(self.xdotool, 'keydown', 'slash')
        time.sleep(0.25)
        return self.capture('help')

    def assert_no_errors(self):
        require(not (self.root / 'work/log.txt').exists(),
                'original Lua error-handler wrote log.txt (its exit0 is not success)')
        for name in ('game.log', 'xvfb.log'):
            path = self.evidence / name
            if path.exists():
                require(not ERRORS.search(path.read_text(errors='replace')),
                        'native error in ' + name)

    def quit(self, key):
        confirmation = self.held_action('quit-confirmation', key)
        try:
            require('Quit? [yn]' in confirmation.text(), 'natural quit confirmation not visible')
            self.edge('ordinary-quit-confirm-y', 'y', True)
        finally:
            self.edge('ordinary-quit-release-y', 'y', False)
            self.edge('ordinary-quit-release-' + key, key, False)
        status = self.process.wait(timeout=15)
        require(status == 0, 'ordinary confirmed quit failed: %r' % status)
        self.assert_no_errors()
        return confirmation, status

    def cleanup(self):
        result, errors = {}, []
        if self.shift_held:
            try:
                self.shift(False)
            except BaseException as error:
                errors.append('modifier release: ' + repr(error))
        if self.process is not None:
            if self.process.poll() is None:
                try:
                    # Failure cleanup is still ordinary input. A first Escape
                    # may dismiss a menu; a subsequent Escape/y confirms quit.
                    for number in range(4):
                        if self.process.poll() is not None:
                            break
                        self.key('failure-cleanup-escape-%d' % number, 'Escape')
                        if self.process.poll() is None:
                            self.key('failure-cleanup-confirm-%d' % number, 'y')
                        time.sleep(0.2)
                    self.process.wait(timeout=5)
                except BaseException as error:
                    errors.append('game cleanup: ' + repr(error))
            result['game_exit_status'] = self.process.poll()
            require_finished = self.process.poll() is not None
            if not require_finished:
                errors.append('game still running; namespace teardown is not a successful ordinary quit')
        if self.server is not None:
            if self.server.poll() is None:
                self.server.terminate()  # consumer-owned X server, never game quit evidence
                try:
                    self.server.wait(timeout=5)
                except BaseException as error:
                    errors.append('Xvfb cleanup: ' + repr(error))
            result['xvfb_exit_status'] = self.server.poll()
        result['errors'] = errors
        return result


def validate_dump(session, final_frame, inventory_frame):
    dump = session.root / 'work/character.txt'
    require(dump.is_file(), 'natural quit did not produce original character.txt')
    text = dump.read_text(encoding='latin-1')
    require(text.startswith('  Dwarftown v1.0 character dump\n\n'), 'wrong character dump title')
    require(re.search(r'\n\n[^\n]+\n\nQuit the game\n\n  SCREENSHOT\n\n', text),
            'dump lacks timestamp or natural quit reason')
    separator = '-' * COLS
    screenshot, tail = text.split('  SCREENSHOT\n\n', 1)[1].split('\n\n  LAST MESAGES\n\n', 1)
    lines = screenshot.splitlines()
    require(len(lines) == ROWS + 2 and lines[0] == lines[-1] == separator and
            all(len(row) == COLS for row in lines[1:-1]), 'malformed original character raster dump')
    grid = lines[1:-1]
    # Held quit keys can repeat in SDL itself (sys_sdl_c.c:786-787), even
    # with X server repeat disabled. Only the message pane may legitimately
    # gain further command.quit prompts between XWD capture and confirmation.
    require(all(grid[row][col] == final_frame.rows[row][col]
                for row in range(ROWS) for col in range(COLS)
                if not (14 <= row < 24 and 50 <= col < 80)),
            'character dump map/HUD glyphs differ from actual final X11 framebuffer')
    require(grid[12][25] == '@', 'dump does not show actual centered player')
    require(Frame.turn(final_frame) > 0, 'dump does not reflect exercised turns')
    messages, items = tail.split('\n  INVENTORY\n\n', 1)
    history = messages.splitlines()
    observed = [row[50:80].rstrip() for row in final_frame.rows[14:24]
                if row[50:80].strip()]
    require(observed[:2] == ['Find Dwarftown!', 'Press ? for help.'] and
            len(observed) > 2 and all(line == 'Quit? [yn]' for line in observed[2:]),
            'captured quit history differs from exercised startup and quit actions')
    require(history[:len(observed)] == observed and
            all(line == 'Quit? [yn]' for line in history[len(observed):]) and
            len(history) <= 15,
            'dump history is not observed history followed only by original quit prompts')
    # Reproduce ui.lua:252-288 line wrapping and bottom-up message layout,
    # not a blanket exemption for text. Every dumped pane cell must match.
    wrapped = []
    for message in history:
        lines = []
        for word in message.split(' '):
            if lines and len(word) + len(lines[-1]) + 1 < 30:
                lines[-1] += ' ' + word
            else:
                lines.append(word)
        wrapped.extend(lines)
    expected_pane = [' ' * 30] * max(0, 10 - len(wrapped))
    expected_pane += [line.ljust(30) for line in wrapped[-10:]]
    require([row[50:80] for row in grid[14:24]] == expected_pane,
            'dump message raster does not match its original causal message history')
    expected_items = ['a   / torch', 'b   ! potion of health']
    require(items.splitlines() == expected_items, 'dump starting inventory changed unexpectedly')
    for index, expected in enumerate(expected_items):
        # ui.promptItems blits the 48-column itemConsole at root (1,1),
        # retaining the live HUD at col50. Compare only that actual pane.
        visible = inventory_frame.rows[index + 3][1:49].rstrip()
        require(visible == expected,
                'dump item does not match actual visible inventory: ' + expected)
    (session.evidence / 'character.txt').write_bytes(dump.read_bytes())
    return {'sha256': digest(dump.read_bytes()), 'map_hud_matches_final_x11': True,
            'message_raster_matches_history': True, 'observed_message_history': observed,
            'additional_original_quit_prompts': len(history) - len(observed),
            'reason': 'Quit the game', 'inventory_matches_visible': expected_items,
            'last_messages': history, 'turn': final_frame.turn()}


def movement(session, before):
    # @ stays centered: movement must scroll real terrain, not move the glyph.
    # Forest exits are invisible south of the starting band: never choose Down.
    # map.lua Tree subclasses walkable Floor: both grass '.' and tree '&'
    # are ordinary visible passable ground, unlike TallTree '#'.
    x, y = before.actor()
    for index, (key, dx, dy) in enumerate(DIRECTIONS):
        if before.codes[y + dy][x + dx] not in (ord('.'), ord('&')):
            continue
        after = session.action('movement-%d-%s' % (index, key), key)
        require('Leave the area?' not in after.text(), 'chosen ground unexpectedly reached area exit')
        require(after.actor() == (25, 12), 'player no longer centered after ordinary movement')
        require(after.turn() > before.turn(), 'ordinary ground movement did not spend a turn')
        pairs = []
        for row in range(2, 23):
            for col in range(2, 47):
                nr, nc = row - dy, col - dx
                code = before.codes[row][col]
                if code in (35, 38, 43, 60, 62, 61) and after.codes[nr][nc] == code:
                    pairs.append({'before': [col, row], 'after': [nc, nr], 'glyph': chr(code)})
        overlap = [(before.codes[row][col], after.codes[row - dy][col - dx])
                   for row in range(2, 23) for col in range(2, 47)
                   if (col, row) != (25, 12) and (col - dx, row - dy) != (25, 12)
                   and before.codes[row][col] in (35, 38, 46, 43, 60, 62, 61)
                   and after.codes[row - dy][col - dx] in (35, 38, 46, 43, 60, 62, 61)]
        matching = sum(a == b for a, b in overlap)
        require(len(overlap) >= 12 and matching >= 0.9 * len(overlap),
                'ordinary movement does not scroll overlapping native terrain')
        require(pairs, 'ordinary movement lacks a scrolled non-floor landmark')
        require(before.rows != after.rows, 'movement did not change actual framebuffer glyphs')
        return after, {'key': key, 'delta': [dx, dy], 'before_turn': before.turn(),
                       'after_turn': after.turn(), 'centered_player': [25, 12],
                       'scrolled_terrain_landmarks': pairs,
                       'terrain_overlap': len(overlap), 'terrain_matches': matching}
    raise RuntimeError('no visible adjacent ordinary walkable ground available for genuine movement')


def play(session):
    process = session.launch()
    deadline = time.monotonic() + 60
    while True:
        title = session.capture('title')
        if '[Press any key to continue]' in title.text():
            break
        require(time.monotonic() < deadline, 'original world generation/title timed out')
        time.sleep(0.25)
    require('Dwarftown v1.0' in title.text(), 'original title is absent')
    initial = session.action('initial', 'space')
    require(initial.actor() == (25, 12) and initial.turn() == 0, 'wrong original player start')
    # Forest:getStartingPoint uses the appended road at y=h+3..h+6.
    # map.getSector excludes y>=sector.y+h, so drawStatus prints no name here.
    require(initial.rows[1][50:].strip() == '', 'starting road unexpectedly has a sector header')
    require(sum(code == ord('&') for row in initial.codes for code in row[:49]) >= 1,
            'original road start lacks visible forest tree terrain')
    for text in ('HP       25/25', 'Level    1 (0/50)', 'Attack   1d2+1',
                 'Find Dwarftown!', 'Press ? for help.'):
        require(text in initial.text(), 'original starting screen lacks ' + text)
    moved, move_evidence = movement(session, initial)
    waited = session.action('wait', 'period')
    require(waited.turn() > moved.turn(), 'ordinary wait did not advance visible turn')
    require(waited.actor() == (25, 12), 'wait changed centered player position')
    try:
        inventory_frame = session.held_action('inventory', 'i')
        require('Select an item to use' in inventory_frame.text(), 'original inventory prompt absent')
        for text in ('torch', 'potion of health'):
            require(text in inventory_frame.text(), 'original starting inventory lacks ' + text)
    finally:
        session.edge('inventory-cancel-release-i', 'i', False)
    resumed = session.capture('inventory-cancel')
    require(resumed.turn() == waited.turn() and resumed.actor() == waited.actor(),
            'inventory cancellation spent a turn or moved player')
    # sys_sdl_c.c:1485-1488 flushes queued events after ANY key event,
    # including modifiers. Stage the physical chord across separate waits.
    try:
        help_frame = session.help_key()
        for text in ('--- Dwarftown ---', '--- Keybindings ---', 'Wait:  5, .',
                     'The game saves a character dump to character.txt file.'):
            require(text in help_frame.text(), 'original help screen lacks ' + text)
    finally:
        if session.shift_held:
            try:
                session.tool(session.xdotool, 'keyup', 'slash')
            finally:
                session.shift(False)
    # Modifier release may naturally dismiss help (legacy wait returns keyup).
    resumed = session.capture('help-dismiss')
    require(resumed.turn() == waited.turn() and resumed.actor() == waited.actor(),
            'help dismissal spent a turn or moved player')
    try:
        canceled = session.held_action('quit-q-prompt', 'q')
        require('Quit? [yn]' in canceled.text(), 'q did not open natural quit prompt')
    finally:
        session.edge('quit-q-cancel-release', 'q', False)
    resumed = session.capture('quit-q-cancel')
    require(session.process.poll() is None and resumed.turn() == waited.turn(),
            'natural quit cancellation exited or spent a turn')
    final_frame, status = session.quit('Escape')
    dump = validate_dump(session, final_frame, inventory_frame)
    return {'process': process, 'initial': initial.state(), 'movement': move_evidence,
            'wait': {'before_turn': moved.turn(), 'after_turn': waited.turn()},
            'inventory_canceled_without_turn': True, 'help_dismissed_without_turn': True,
            'q_prompt_canceled': True, 'escape_y_natural_exit': status,
            'character_dump': dump}


def main():
    require(len(sys.argv) == 7, 'usage: native.py OUTPUT EVIDENCE XVFB XDOTOOL XWD CONVERT')
    output, evidence = map(Path, sys.argv[1:3])
    require(output.parent == Path('/gnu/store') and output.is_dir(), 'canonical prebuilt store item required')
    require(evidence.is_dir() and not (evidence / 'native-result.json').exists(), 'fresh shell evidence required')
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    # Keep the host-retained directory reachable even if isolation fails
    # between overlaying /tmp and binding the evidence into the private tree.
    evidence = Path('/proc/self/fd/' + str(evidence_fd))
    report = {'success': False, 'source': SOURCE, 'commit': COMMIT,
              'persistence': 'Character dump only; no save/load or resume is invented or tested.',
              'font_sha256': FONT_HASH}
    root = session = None
    cleanup_errors = []
    try:
        require(os.getpid() == 1, 'consumer is not PID1 in private proc mount')
        report['isolation'] = namespace_proof(Path('/proc/self'))
        evidence, entries = isolate_filesystem(evidence)
        report['isolation']['store'] = entries
        native = output / 'bin/dwarftown'
        require(native.is_file() and os.access(native, os.X_OK), 'installed launcher is not executable')
        require(not any('native.py' in path.name or 'smoke' in path.name for path in output.rglob('*')),
                'external smoke helper leaked into output')
        closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
        require(str(output) in closure, 'runtime closure missing game')
        # Compare exact consumer outputs, not package-name prefixes: SDL's
        # Wayland/libxml2 runtime legitimately references python-minimal.
        tools = json.loads((evidence / 'consumer-tools.json').read_text())
        consumers = {name: tools[name] for name in
                     ('python', 'xorg-server', 'xdotool', 'xwd', 'imagemagick')}
        leaks = {name: path for name, path in consumers.items() if path in closure}
        record(evidence / 'consumer-closure-audit.json',
               {'consumer_outputs': consumers, 'exact_consumer_leaks': leaks,
                'python_named_runtime_items': [path for path in closure
                                              if Path(path).name[33:].startswith('python-')]})
        require(not leaks, 'exact consumer-only outputs leaked into runtime closure: ' + repr(leaks))
        report['output'] = {'launcher_sha256': digest(native.read_bytes()), 'closure': closure,
                            'consumer_outputs': consumers, 'exact_consumer_leaks': leaks}
        root = Path('/tmp/dwarftown-private')
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        initial_inventory = inventory(root)
        record(evidence / 'private-before.json', initial_inventory)
        session = Session(output, evidence, root, sys.argv[3:])
        report['gameplay'] = play(session)
        final_inventory = inventory(root)
        require(set(final_inventory) - set(initial_inventory) == {'work/character.txt'},
                'unexpected native writes (only original character dump is expected)')
        require(all(final_inventory[name] == item for name, item in initial_inventory.items()),
                'pre-existing private directories changed unexpectedly')
        session.assert_no_errors()
        for path in (evidence / 'game.log', evidence / 'xvfb.log'):
            require(not ERRORS.search(path.read_text(errors='replace')), 'native error in ' + path.name)
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
        if root is not None and (evidence / 'retained-native-files/work/log.txt').exists():
            cleanup_errors.append('upstream Lua error-handler log.txt exists, even if exit status is zero')
        for name in ('game.log', 'xvfb.log'):
            path = evidence / name
            if path.exists() and ERRORS.search(path.read_text(errors='replace')):
                cleanup_errors.append('native error retained in ' + name)
        cleanup['errors'] = cleanup_errors
        if cleanup_errors:
            report['success'] = False
            report['cleanup_errors'] = cleanup_errors
        record(evidence / 'cleanup.json', cleanup)
        record(evidence / 'native-result.json', report)
        os.close(evidence_fd)
        require(not cleanup_errors, 'native cleanup failed: ' + repr(cleanup_errors))
    print('DWARFTOWN_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
