#!/usr/bin/env python3
"""Human X11 input and real-window captures of Allure 0.11.0.0 SDL.

Only read native user files. No game configuration, saves, sources or API are
injected. Pixel comparisons observe the actual SDL-rendered map and HUD;
native bitmap glyphs read the diary and menus. Bundled square fonts are selected using the documented --fontset option.
"""
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import signal
import socket
import struct
import subprocess
import sys
import time
import traceback


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


def isolate(root, evidence):
    descriptors = [os.open(path, os.O_RDONLY | os.O_DIRECTORY)
                   for path in (root, evidence)]
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int

    def mount(source, target, filesystem=None, flags=0):
        if libc.mount(os.fsencode(source), os.fsencode(target),
                      None if filesystem is None else os.fsencode(filesystem), flags, None):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), str(target))

    try:
        mount('/gnu/store', '/gnu/store', flags=4096)
        mount('/gnu/store', '/gnu/store', flags=4096 | 32 | 1 | 2 | 4)
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, evidence = Path('/tmp/allure-root'), Path('/tmp/allure-evidence')
        root.mkdir()
        evidence.mkdir()
        for descriptor, destination in zip(descriptors, (root, evidence)):
            mount('/proc/self/fd/' + str(descriptor), destination, flags=4096)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
    finally:
        for descriptor in descriptors:
            os.close(descriptor)
    require([name for _, name in socket.if_nameindex()] == ['lo'],
            'network namespace contains non-loopback interfaces')
    # Verify the mount flag instead of attempting a store write.
    store = [line for line in Path('/proc/self/mountinfo').read_text().splitlines()
             if line.split()[4] == '/gnu/store']
    require(store and 'ro' in store[-1].split()[5].split(','), 'store is not read-only')
    return root, evidence


def native_glyphs(output):
    # Native regular font: 16x16 full-cell bitmaps, no OCR substitutions.
    fonts = [Path(output) / 'share/doc/allure/fonts/16x16xw.bdf']
    require(fonts[0].is_file(), 'installed native Allure BDF font reference missing')
    require(len(fonts) == 1, 'expected exactly one native text font')
    glyphs, encodings = {}, set()
    blocks = re.split(r'^STARTCHAR[^\n]*\n',
                      fonts[0].read_text(encoding='ascii'), flags=re.MULTILINE)
    for block in blocks[1:]:
        encoding = re.search(r'^ENCODING (-?\d+)$', block, re.MULTILINE)
        require(encoding is not None, 'native text font glyph lacks encoding')
        encoding = int(encoding.group(1))
        if not 32 <= encoding <= 126:
            continue
        require(re.search(r'^DWIDTH 16 0$', block, re.MULTILINE) is not None,
                'native text font glyph has unexpected advance')
        require(re.search(r'^BBX 16 16 0 -3$', block, re.MULTILINE) is not None,
                'native text font glyph has unexpected geometry')
        bitmap = re.search(r'^BITMAP\n(.*?)^ENDCHAR$', block,
                           re.MULTILINE | re.DOTALL)
        require(bitmap is not None, 'native text font glyph lacks bitmap')
        rows = bitmap.group(1).splitlines()
        require(len(rows) == 16 and all(re.fullmatch(r'[0-9A-Fa-f]{4}', row)
                                       for row in rows),
                'native text font glyph has malformed bitmap')
        # Exact Sdl.hs:504-519 chooseAndDrawHighlight overwrites the complete
        # cell border black even for HighlightNone, after rendering the BDF.
        # Match that deterministic native raster operation, not fuzzy OCR.
        mask = bytes(((int(row, 16) >> (15 - x)) & 1)
                     if 0 < x < 15 and 0 < y < 15 else 0
                     for y, row in enumerate(rows) for x in range(16))
        glyphs.setdefault(mask, []).append(chr(encoding))
        encodings.add(encoding)
    require(encodings == set(range(32, 127)),
            'native text font lacks complete printable ASCII')
    return glyphs


class Session:
    def __init__(self, name, executable, evidence, env, tools):
        self.directory = evidence / name
        self.directory.mkdir()
        self.env, self.tools = env, tools
        self.glyphs = native_glyphs(Path(executable).parent.parent)
        self.window = None
        self.events, self.images = [], []
        self.log = (self.directory / 'native.log').open('wb')
        self.process = subprocess.Popen([str(executable), '--fontset', '16x16xw'], env=env,
                                        cwd=env['ALLURE_WORK'], stdout=self.log,
                                        stderr=self.log, start_new_session=True)
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'native game exited before SDL window')
            result = self.tool(tools['xdotool'], 'search', '--onlyvisible',
                               '--pid', str(self.process.pid), check=False)
            if result.returncode == 0 and result.stdout.split():
                self.window = result.stdout.split()[-1].decode()
                break
            time.sleep(0.1)
        require(self.window is not None, 'native SDL window did not appear')
        self.tool(tools['xdotool'], 'windowfocus', '--sync', self.window)

    def tool(self, *arguments, check=True):
        return subprocess.run(arguments, env=self.env, check=check, timeout=20,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def key(self, *keys):
        require(self.process.poll() is None, 'game exited before human input')
        self.tool(self.tools['xdotool'], 'windowfocus', '--sync', self.window)
        self.tool(self.tools['xdotool'], 'key', '--clearmodifiers', '--delay', '150', *keys)
        self.events.append({'keys': list(keys), 'time_ns': time.monotonic_ns()})
        time.sleep(0.3)

    def capture(self, name, record=True):
        path = self.directory / (name + '.png')
        self.tool(self.tools['import'], '-window', self.window, str(path))
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'X11 capture is not PNG')
        width, height = struct.unpack('>II', data[16:24])
        require(width == 1280 and height == 720,
                'native SDL window does not match upstream 80x45 square-cell layout (42 map + message + 2 HUD)')
        self.cell = width // 80
        if record:
            self.images.append({'path': str(path.relative_to(self.directory.parent)),
                                'width': width, 'height': height, 'sha256': sha(data)})
        return path

    def pixels(self, image):
        return self.tool(self.tools['convert'], str(image), '-depth', '8', 'rgb:-').stdout

    def text(self, name='current'):
        image = self.capture(name, record=False)
        text = self.glyph_text(image)
        (self.directory / (name + '.txt')).write_text(text)
        return text

    def expect(self, predicate, label, timeout=40):
        deadline = time.monotonic() + timeout
        text = ''
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'native game exited awaiting ' + label)
            text = self.text()
            self.check_native_errors(text)
            if predicate(text):
                return text
            time.sleep(0.2)
        self.capture('failure')
        raise RuntimeError('timed out awaiting ' + label + ': ' + text)

    def frame(self, name):
        # Space executes AllHistory when messages are clear. Inspect the real
        # message row first; never blindly open that overlay.
        for _ in range(8):
            current = self.capture('current', record=False)
            current_text = self.glyph_text(current)
            (self.directory / 'current.txt').write_text(current_text)
            self.check_native_errors(current_text)
            pixels = self.pixels(current)
            if not any(pixels[:80 * self.cell * self.cell * 3]):
                break
            self.key('space')
        else:
            raise RuntimeError('native message row did not clear')
        time.sleep(0.4)
        image = self.capture(name)
        pixels = self.pixels(image)
        self.check_native_errors(self.glyph_text(image))
        stride = 80 * self.cell * 3
        # Skip only message row; retain all map and both HUD rows.
        view = pixels[self.cell * stride:]
        leaders = []
        for y in range(1, 43):
            for x in range(80):
                offset = (y * self.cell * 80 * self.cell + x * self.cell) * 3
                if pixels[offset:offset + 3] == bytes((0xEB, 0xD6, 0x42)):
                    leaders.append([x, y - 1])
        require(len(leaders) == 1, 'ambiguous native yellow leader border: ' + repr(leaders))
        return {'leader': leaders[0], 'map_hud_sha256': sha(view)}, pixels

    def glyph_text(self, image, rows=45, strict=False):
        # SDL draws packaged 16x16xw.bdf directly into square cells. Unknown
        # map symbols/non-ASCII glyphs remain visible as replacement characters
        # in text evidence; they cannot manufacture letters or join phrases.
        require(self.cell == 16, 'native text font requires 16-pixel cells')
        pixels = self.tool(self.tools['convert'], str(image),
                           '-crop', '1280x' + str(rows * 16) + '+0+0', '+repage',
                           '-depth', '8', 'rgb:-').stdout
        require(len(pixels) == 1280 * rows * 16 * 3, 'incomplete native text pixels')
        lines = []
        for row in range(rows):
            text = []
            for column in range(80):
                mask = bytes(any(pixels[((row * 16 + y) * 1280 + column * 16 + x) * 3:
                                        ((row * 16 + y) * 1280 + column * 16 + x) * 3 + 3])
                             for y in range(16) for x in range(16))
                matches = self.glyphs.get(mask, [])
                if strict:
                    require(len(matches) == 1,
                            'unrecognized or ambiguous native text glyph at '
                            + str(column) + ',' + str(row) + ': ' + repr(matches))
                text.append(matches[0] if len(matches) == 1 else '\ufffd')
            lines.append(''.join(text).rstrip())
        return '\n'.join(lines).rstrip()

    def clock_text(self, image):
        # HandleHumanLocalM.allHistoryHuman places the numeric clock in row zero.
        # Every glyph in that row must match exactly, including punctuation.
        return self.glyph_text(image, rows=1, strict=True)

    def history(self, name):
        self.frame(name + '-map')
        self.key('F12')  # Allure AllHistory; direct native binding.
        image = self.capture(name)
        text = self.clock_text(image)
        (self.directory / (name + '.txt')).write_text(text + '\n')
        # Four native key hints can extend beyond the 80-cell first row. Read
        # the complete numeric sentence exactly; hints are not clock state.
        match = re.match(r'You survived for ([0-9]+) half-second (turn|turns) '
                         r'\(this level: ([0-9]+)\)\.(?: |$)', text)
        require(match is not None, 'cannot read native global/local clock: ' + text)
        global_turns, local_turns = int(match[1]), int(match[3])
        require(match[2] == ('turn' if global_turns == 1 else 'turns'),
                'native clock has inconsistent turn count: ' + text)
        self.key('Escape')
        return {'global': global_turns, 'local': local_turns}

    def snapshot(self, name):
        clock = self.history(name + '-history')
        panels = {}
        for key, panel in [('O', 'equipment'), ('I', 'inventory')]:
            self.key(key)
            expected = 'outfit' if panel == 'equipment' else 'stash'
            self.expect(lambda text: expected in text.lower(), 'native ' + panel + ' menu')
            image = self.capture(name + '-' + panel)
            panels[panel] = sha(self.pixels(image))
            self.key('Escape')
        frame, _ = self.frame(name)
        return dict(frame, clock=clock, **panels)

    def move(self, name, old):
        # Choose a visibly dotted adjacent floor cell, not a guessed wall.
        _, pixels = self.frame(name + '-before')
        x, y = old['leader']
        cell, stride = self.cell, 80 * self.cell * 3
        choices = [('l', 1, 0), ('h', -1, 0), ('j', 0, 1), ('k', 0, -1),
                   ('u', 1, -1), ('n', 1, 1), ('b', -1, 1), ('y', -1, -1)]
        for key, dx, dy in choices:
            nx, ny = x + dx, y + dy
            if not (0 <= nx < 80 and 0 <= ny < 42):
                continue
            lit = [(cx, cy) for cy in range(cell) for cx in range(cell)
                   if any(pixels[(ny + 1) * cell * stride + cy * stride
                                 + nx * cell * 3 + cx * 3:
                                 (ny + 1) * cell * stride + cy * stride
                                 + nx * cell * 3 + cx * 3 + 3])]
            # The upstream bold floor-dot glyph is small and centered. Walls,
            # actors and highlights extend far beyond this central square.
            if not lit or not all(cell // 4 <= cx < cell * 3 // 4
                                  and cell // 4 <= cy < cell * 3 // 4 for cx, cy in lit):
                continue
            self.key(key)
            frame, _ = self.frame(name + '-after')
            require(frame['leader'] == [nx, ny], 'human floor move did not reach adjacent cell')
            clock = self.history(name + '-clock')
            require(clock['global'] > old['clock']['global']
                    and clock['local'] > old['clock']['local'],
                    'human movement did not advance both native clocks')
            return
        raise RuntimeError('no visibly dotted adjacent floor for human movement')

    def save_exit(self):
        # Permit only the exact pre-command map during asynchronous transition.
        before = self.capture('save-exit-before')
        before_pixels = self.pixels(before)
        self.key('ctrl+x')
        deadline = time.monotonic() + 40
        index = 0
        while self.process.poll() is None and time.monotonic() < deadline:
            time.sleep(0.3)
            if self.process.poll() is not None:
                break
            try:
                image = self.capture('save-exit-' + str(index))
            except subprocess.CalledProcessError:
                self.process.wait(timeout=max(1, deadline - time.monotonic()))
                break
            text = self.glyph_text(image)
            self.check_native_errors(text)
            (self.directory / ('save-exit-' + str(index) + '.txt')).write_text(text)
            # WatchQuitM offers Escape on its ordinary camping status screen.
            # Unlike Space it skips optional lore/end-message slides; never
            # dismiss an unrecognized overlay or a save-error dialog.
            if text.splitlines()[0] == 'Autonomous Spacefarers set camp. [SPACE] [ESC]':
                self.key('Escape')
                index += 1
            elif 'saving...' in text.lower():
                # UpdKillExit appends Done. then displayMore waits for a key.
                if re.search(r'\bDone\.', text):
                    self.key('Escape')
                index += 1
            elif ('your valiant exploits' in text.lower()
                  and 'award you' in text.lower() and 'place' in text.lower()):
                self.key('Escape')
                index += 1
            elif index == 0 and self.pixels(image) == before_pixels:
                continue
            else:
                raise RuntimeError('unknown native save-exit overlay: ' + text)
        require(self.process.poll() is not None, 'native save-exit did not finish')
        status = self.process.wait()
        require(status == 0, 'native save-exit failed: ' + str(status))
        self.check_native_errors()
        (self.directory / 'exit-status.txt').write_text(str(status) + '\n')

    def check_native_errors(self, screen=''):
        texts = [screen]
        self.log.flush()
        for path in (self.directory / 'native.log',
                     Path(self.env['HOME']) / '.Allure/stdout.txt',
                     Path(self.env['HOME']) / '.Allure/stderr.txt'):
            if path.is_file():
                texts.append(path.read_text(errors='replace'))
        # Save.restoreGame deliberately catches restore exceptions, logs them,
        # and starts a new game. Native exit status alone is not authoritative.
        for text in texts:
            require(re.search(r'(?i)fatal error|restore failed|exception|'
                              r'assertion failed|error:|showfailure|'
                              r'corrupt|zlib|compression error|decompression error|'
                              r'unable to save|failed to (?:save|write)|'
                              r'permission denied|does not exist|resource exhausted|'
                              r'font file (?:does not exist|not supplied)', text) is None,
                    'native error diagnostic: ' + text)

    def close(self):
        stop(self.process)
        # GameDefinition/Main.hs redirects non-terminal stdout/stderr here.
        for name in ('stdout.txt', 'stderr.txt'):
            path = Path(self.env['HOME']) / '.Allure' / name
            if path.is_file():
                shutil.copy2(path, self.directory / name)
        self.log.close()


def saves(root, evidence, name):
    directory = root / 'home/.Allure/saves'
    files = sorted(directory.glob('*.sav'))
    require((directory / 'Allure.server.sav') in files, 'native server save missing')
    # Save.saveNameCli labels UI factions as team_N in this exact engine.
    require(any(re.fullmatch(r'Allure\.team_-?\d+\.sav', path.name) for path in files),
            'native team client save missing')
    require(not list(directory.glob('bkp.*')), 'native restore rejected a save')
    require(not list(directory.glob('*.tmp')), 'native save transaction incomplete')
    target = evidence / name
    target.mkdir()
    result = []
    for path in files:
        data = path.read_bytes()
        require(len(data) > 100, 'native save unexpectedly small: ' + path.name)
        # HSFile.hs: Binary (Version,(zlib state,"OK")). Do not misrepresent
        # these hashes as a Haskell decoder or proof of hidden RNG identity.
        shutil.copy2(path, target / path.name)
        result.append({'path': name + '/' + path.name,
                       'bytes': len(data), 'sha256': sha(data)})
    return result


def native_main_menu(text):
    # Require three independent MainMenu bindings from Content/Input.hs, not
    # a fuzzy spelling or a generic 'game' substring. Ignore layout whitespace.
    compact = ''.join(text.lower().split())
    return all(anchor in compact for anchor in (
        'setupandstartnewgame', 'saveandexittodesktop',
        'backtoplaying'))


def play(output, root, evidence, env, tools, record):
    session = None

    def launch(name, executable):
        nonlocal session
        session = Session(name, executable, evidence, env, tools)
        record['sessions'].append({'name': name, 'executable': str(executable),
                                   'arguments': ['--fontset', '16x16xw'], 'events': session.events,
                                   'screenshots': session.images})

    try:
        launch('new-game', output / 'bin/Allure')
        # Default launch is upstream insert-coin autoplay. First input takes
        # human control and opens the native main menu.
        session.expect(lambda text: 'HP' in text, 'native autoplay map')
        session.key('l')
        session.expect(native_main_menu, 'native main menu')
        session.capture('native-main-menu')
        # Slot letters are not legal native menu input in 0.11. Home selects
        # the first entry, Return activates it; Right cycles its forward value.
        session.key('Home', 'Return')
        session.expect(lambda text: 'adventure:' in text.lower(), 'native challenge menu')
        for index in range(12):
            text = session.text('adventure-' + str(index))
            if re.search(r'adventure:\s*\*?long crawl \(main\)', text, re.IGNORECASE):
                break
            session.key('Home', 'Right')
        else:
            raise RuntimeError('native adventure menu did not offer long crawl')
        session.capture('selected-adventure')
        session.key('ctrl+g')
        # Attract mode suppresses restart confirmation. A human confirmation
        # must be explicitly read and answered if the UI presents one.
        text = session.text('new-game-request')
        if 'are you sure?' in text.lower():
            session.key('y')
        session.expect(lambda text: 'new game started' in text.lower()
                       and 'crawl' in text.lower(), 'native long-crawl start message')
        initial = session.snapshot('initial')
        # Human wait is distinct from menu manipulation and advances game time.
        session.key('KP_Begin')
        waited = session.snapshot('after-human-wait')
        require(waited['clock']['global'] > initial['clock']['global']
                and waited['clock']['local'] > initial['clock']['local'],
                'human wait did not advance native clocks')
        session.move('human-movement', waited)
        saved = session.snapshot('before-save')
        require(saved['leader'] != initial['leader'], 'human movement did not change position')
        record['initial'], record['saved'] = initial, saved
        session.save_exit()
        record['first_saves'] = saves(root, evidence, 'first-saves')
        session.close()
        session = None
        # New process, same genuine installed command; no seed or state injection.
        launch('restored-game', output / 'bin/Allure')
        session.expect(lambda text: 'HP' in text, 'native restored map')
        restored = session.snapshot('restored')
        require(restored == saved, 'native restore changed visible state: '
                + repr({'saved': saved, 'restored': restored}))
        record['restored'] = restored
        record['assertions'].append('restore exact map/HUD pixels, leader position, native global/local clocks, equipment and inventory')
        # A move (not wait) resets transient swaitTimes, which is intentionally
        # not serialized; both pre-save snapshots follow successful movement.
        session.move('continued-human-movement', restored)
        continued = session.snapshot('continued-before-save')
        require(continued['leader'] != restored['leader'], 'restored game did not continue moving')
        session.save_exit()
        record['continued_saves'] = saves(root, evidence, 'continued-saves')
        session.close()
        session = None
        launch('second-restored-game', output / 'bin/Allure')
        session.expect(lambda text: 'HP' in text, 'second native restored map')
        second = session.snapshot('second-restored')
        require(second == continued, 'second native restore changed visible state')
        record['continued'], record['second_restored'] = continued, second
        session.move('second-continued-human-movement', second)
        final = session.snapshot('second-continued-before-save')
        require(final['leader'] != second['leader'], 'second restored game did not continue moving')
        record['final'] = final
        session.save_exit()
        record['final_saves'] = saves(root, evidence, 'final-saves')
        record['assertions'].append('both fresh-process restores continue human movement, advance clocks, and cleanly save-exit')
        record['limitations'] = 'No decoding of hidden server fields/RNG; identity proved through native visible map/HUD, position, clocks and item screens, not byte-identical full state.'
        require({path.name for path in (root / 'home').iterdir()} == {'.Allure'},
                'native command wrote unexpected HOME state')
        for name in ('config', 'data', 'state'):
            require(not list((root / name).iterdir()), 'unexpected XDG ' + name + ' writes')
        return None
    finally:
        if session is not None:
            session.close()


def main():
    output, root, xvfb, xdotool, capture, convert, evidence, nar = sys.argv[1:]
    output, root, evidence = map(Path, (output, root, evidence))
    record = {'status': 'running', 'consumer': 'native SDL via X11 human input, bundled square fontset',
              'fontset': '16x16xw', 'output': str(output), 'output_nar_before': nar,
              'upstream': 'Allure 0.11.0.0 0ec5296bec777c399e21d6fed44b5366dda95f84',
              'engine': 'LambdaHack 0.11.0.1 1399d5bd0f6a4c104249375a2968b314ca1a60d4',
              'sessions': [], 'assertions': []}
    session, server, server_log = None, None, None

    def report():
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')

    report()
    try:
        root, evidence = isolate(root, evidence)
        expected_uid = int(os.environ['ALLURE_EXPECTED_UID'])
        expected_gid = int(os.environ['ALLURE_EXPECTED_GID'])
        require(os.getuid() == os.geteuid() == expected_uid,
                'user namespace did not preserve current UID')
        require(os.getgid() == os.getegid() == expected_gid,
                'user namespace did not preserve current GID')
        record['identity'] = {'expected_uid': expected_uid, 'uid': os.getuid(),
                              'euid': os.geteuid(), 'expected_gid': expected_gid,
                              'gid': os.getgid(), 'egid': os.getegid()}
        record['native_font_reference'] = {
            'path': 'share/doc/allure/fonts/16x16xw.bdf',
            'sha256': sha((output / 'share/doc/allure/fonts/16x16xw.bdf').read_bytes())}
        record['compared_fields'] = ['leader', 'map_hud_sha256',
                                     'clock.global', 'clock.local',
                                     'equipment', 'inventory']
        env = dict(os.environ)
        for variable, directory in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                    ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                    ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                    ('TMPDIR', 'tmp')]:
            (root / directory).mkdir(mode=0o700)
            env[variable] = str(root / directory)
        (root / 'work').mkdir()
        env.update(ALLURE_WORK=str(root / 'work'), SDL_VIDEODRIVER='x11',
                   LIBGL_ALWAYS_SOFTWARE='1',
                   DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/no-session-bus')
        tools = {'xdotool': xdotool, 'import': capture, 'convert': convert}
        server_log = (evidence / 'xvfb.log').open('wb')
        read_fd, write_fd = os.pipe()
        try:
            server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                       '2560x1440x24', '-nolisten', 'tcp', '-ac'],
                                      env=env, pass_fds=(write_fd,), stdout=server_log,
                                      stderr=server_log, start_new_session=True)
            os.close(write_fd)
            write_fd = None
            require(select.select([read_fd], [], [], 10)[0], 'Xvfb allocation timed out')
            display = os.read(read_fd, 128).decode().strip()
            require(display.isdecimal(), 'Xvfb failed to allocate display')
            env['DISPLAY'] = ':' + display
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
        session = play(output, root, evidence, env, tools, record)
        record['user_files'] = sorted(str(path.relative_to(root)) for path in root.rglob('*')
                                      if path.is_file())
        record['isolation'] = 'private HOME/XDG/tmp; user/mount/net/PID namespaces; read-only store'
        record['status'] = 'passed'
        print('ALLURE: native-consumer-ok')
    except BaseException as error:
        record.update(status='failed', error=str(error), traceback=traceback.format_exc())
        raise
    finally:
        if session is not None:
            session.close()
        stop(server)
        if server_log is not None:
            server_log.close()
        native_state = root / 'home/.Allure'
        if native_state.is_dir():
            shutil.copytree(native_state, evidence / 'native-user-state')
        record['limitations'] = (
            'Native square fontset selected through documented --fontset option; '
            'default proportional fonts not exercised. Save hashes are artifact '
            'integrity only, not a decoder or hidden RNG/full-state identity proof. '
            'Equality covers exact rendered map/HUD, leader, native global/local '
            'clocks, equipment and stash screens. No combat or win claim.')
        report()


if __name__ == '__main__':
    main()
