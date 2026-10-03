#!/usr/bin/env python3
"""Human X11 input and real-window captures of LambdaHack 0.9.5.0 SDL.

Only read native user files. No game configuration, saves, sources or API are
injected. Pixel comparisons observe the actual SDL-rendered map and HUD;
native bitmap glyphs read the diary and menus. Benchmark is a separate CLI path.
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
        root, evidence = Path('/tmp/lambdahack-root'), Path('/tmp/lambdahack-evidence')
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
    fonts = list(Path(output).glob(
        'share/*/LambdaHack-*/GameDefinition/fonts/16x16xw.bdf'))
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
        mask = bytes((int(row, 16) >> (15 - x)) & 1
                     for row in rows for x in range(16))
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
        self.process = subprocess.Popen([str(executable)], env=env,
                                        cwd=env['LH_WORK'], stdout=self.log,
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
        require(width % 80 == 0 and height % 24 == 0 and width // 80 == height // 24,
                'native SDL window does not match upstream 80x24 square-cell layout')
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
            if predicate(text):
                return text
            time.sleep(0.2)
        self.capture('failure')
        raise RuntimeError('timed out awaiting ' + label + ': ' + text)

    def frame(self, name):
        # Space executes LastHistory when messages are clear. Inspect the real
        # message row first; never blindly open that overlay.
        for _ in range(8):
            current = self.capture('current', record=False)
            pixels = self.pixels(current)
            if not any(pixels[:80 * self.cell * self.cell * 3]):
                break
            self.key('space')
        else:
            raise RuntimeError('native message row did not clear')
        time.sleep(0.4)
        image = self.capture(name)
        pixels = self.pixels(image)
        stride = 80 * self.cell * 3
        # Skip only message row; retain all map and both HUD rows.
        view = pixels[self.cell * stride:]
        leaders = []
        for y in range(1, 22):
            for x in range(80):
                offset = (y * self.cell * 80 * self.cell + x * self.cell) * 3
                if pixels[offset:offset + 3] == bytes((0xEB, 0xD6, 0x42)):
                    leaders.append([x, y - 1])
        require(len(leaders) == 1, 'ambiguous native yellow leader border: ' + repr(leaders))
        return {'leader': leaders[0], 'map_hud_sha256': sha(view)}, pixels

    def glyph_text(self, image, rows=24, strict=False):
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
        # HandleHumanLocalM.eitherHistory places the numeric clock in row zero.
        # Every glyph in that row must match exactly, including punctuation.
        return self.glyph_text(image, rows=1, strict=True)

    def history(self, name):
        self.frame(name + '-map')
        self.key('space', 'space')  # LastHistory, then full history with native clock
        image = self.capture(name)
        text = self.clock_text(image)
        (self.directory / (name + '.txt')).write_text(text + '\n')
        match = re.fullmatch(r'You survived for ([0-9]+) half-second (turn|turns) '
                             r'\(this level: ([0-9]+)\)\. \[ESC\]', text)
        require(match is not None, 'cannot read native global/local clock: ' + text)
        global_turns, local_turns = int(match[1]), int(match[3])
        require(match[2] == ('turn' if global_turns == 1 else 'turns'),
                'native clock has inconsistent turn count: ' + text)
        self.key('Escape')
        return {'global': global_turns, 'local': local_turns}

    def snapshot(self, name):
        clock = self.history(name + '-history')
        panels = {}
        for key, panel in [('E', 'equipment'), ('P', 'inventory')]:
            self.key(key)
            expected = 'equipment' if panel == 'equipment' else 'pack'
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
            if not (0 <= nx < 80 and 0 <= ny < 21):
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
        self.key('ctrl+x')
        # Camping always displays the ordinary final status slideshow. It may
        # also show the score/end-message slides. Space is the native dismissal.
        deadline = time.monotonic() + 40
        index = 0
        while self.process.poll() is None and time.monotonic() < deadline:
            time.sleep(0.3)
            if self.process.poll() is not None:
                break
            try:
                self.capture('save-exit-' + str(index))
                self.key('space')
                index += 1
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired, RuntimeError):
                # SDL can close its window before the main thread exits. A
                # zero native exit, not a capture failure, is authoritative.
                self.process.wait(timeout=max(1, deadline - time.monotonic()))
                break
        require(self.process.poll() is not None, 'native save-exit did not finish')
        status = self.process.wait()
        require(status == 0, 'native save-exit failed: ' + str(status))
        (self.directory / 'exit-status.txt').write_text(str(status) + '\n')

    def close(self):
        stop(self.process)
        # GameDefinition/Main.hs redirects non-terminal stdout/stderr here.
        for name in ('stdout.txt', 'stderr.txt'):
            path = Path(self.env['HOME']) / '.LambdaHack' / name
            if path.is_file():
                shutil.copy2(path, self.directory / name)
        self.log.close()


def saves(root, evidence, name):
    directory = root / 'home/.LambdaHack/saves'
    files = sorted(directory.glob('*.sav'))
    require((directory / 'LambdaHack.server.sav') in files, 'native server save missing')
    # Save.saveNameCli labels the sole SOLO-raid UI faction (id 1) explicitly.
    require((directory / 'LambdaHack.human_1.sav') in files,
            'native human client save missing')
    require(not list(directory.glob('bkp.*')), 'native restore rejected a save')
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
        'enterchallengesmenu', 'saveandexittodesktop',
        'backtoplaying'))


def play(output, root, evidence, env, tools, record):
    session = None

    def launch(name, executable):
        nonlocal session
        session = Session(name, executable, evidence, env, tools)
        record['sessions'].append({'name': name, 'executable': str(executable),
                                   'arguments': [], 'events': session.events,
                                   'screenshots': session.images})

    try:
        launch('new-game', output / 'bin/LambdaHack')
        # Default launch is upstream insert-coin autoplay. First input takes
        # human control and opens the native main menu.
        session.expect(lambda text: 'HP' in text, 'native autoplay map')
        session.key('l')
        session.expect(native_main_menu, 'native main menu')
        session.capture('native-main-menu')
        session.key('s')
        session.expect(lambda text: 'new game started' in text.lower()
                       and 'solo' in text.lower() and 'raid' in text.lower(),
                       'native solo-raid start message')
        initial = session.snapshot('initial')
        # Human wait is distinct from menu manipulation and advances game time.
        session.key('KP_5')
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
        # Exercise the basename-preserving lowercase wrapper on restart. No
        # --newGame, gameMode, seed or alternate frontend is supplied.
        launch('restored-game', output / 'bin/lambdahack')
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
        launch('second-restored-game', output / 'bin/LambdaHack')
        session.expect(lambda text: 'HP' in text, 'second native restored map')
        second = session.snapshot('second-restored')
        require(second == continued, 'second native restore changed visible state')
        record['continued'], record['second_restored'] = continued, second
        session.save_exit()
        record['assertions'].append('continued human movement advances both clocks; second native save-exit and exact visible restore')
        record['limitations'] = 'No decoding of hidden server fields/RNG; identity proved through native visible map/HUD, position, clocks and item screens, not byte-identical full state.'
        require({path.name for path in (root / 'home').iterdir()} == {'.LambdaHack'},
                'basename-preserving wrapper wrote unexpected HOME state')
        for name in ('config', 'data', 'state'):
            require(not list((root / name).iterdir()), 'unexpected XDG ' + name + ' writes')
        return None
    finally:
        if session is not None:
            session.close()


def benchmark(output, root, evidence, env, record):
    # Exact original test/test.hs:13 argv, not a new game-side smoke mode.
    arguments = ('--dbgMsgSer --logPriority 4 --newGame 1 --noAnim --maxFps 100000 '
                 '--frontendNull --benchmark --stopAfterFrames 50 --automateAll '
                 '--keepAutomated --gameMode crawl --setDungeonRng 0 --setMainRng 0').split()
    started = time.monotonic_ns()
    with (evidence / 'benchmark.log').open('wb') as log:
        result = subprocess.run([str(output / 'bin/LambdaHack'), *arguments],
                                env=env, cwd=root / 'work', stdout=log,
                                stderr=subprocess.STDOUT, timeout=300)
    require(result.returncode == 0, 'upstream 50-frame benchmark failed')
    # Main.hs redirects logs when stdout is not a terminal. Read the native
    # files directly; do not introduce a PTY or change upstream benchmark args.
    native_stdout = root / 'home/.LambdaHack/stdout.txt'
    require(native_stdout.is_file(), 'native benchmark stdout file missing')
    for name in ('stdout.txt', 'stderr.txt'):
        path = root / 'home/.LambdaHack' / name
        if path.is_file():
            shutil.copy2(path, evidence / name)
    text = native_stdout.read_text(errors='replace')
    reports = re.findall(r'Session time:.*?frames:\s*(\d+)\.', text)
    require(reports and max(map(int, reports)) >= 50,
            'native benchmark did not report at least 50 rendered frames')
    require(not list((root / 'home').rglob('*.sav')), 'benchmark unexpectedly wrote native saves')
    record.update(consumer='original upstream headless 50-frame crawl benchmark',
                  arguments=arguments, elapsed_ns=time.monotonic_ns() - started,
                  exit_status=result.returncode, reported_frames=max(map(int, reports)),
                  limitations='Headless benchmark only; no GUI or save/reload claim.')
    record['assertions'].append('original native frontendNull benchmark exits successfully at configured 50-frame limit without saves')


def main():
    mode, output, root, xvfb, xdotool, capture, convert, evidence, nar = sys.argv[1:]
    output, root, evidence = map(Path, (output, root, evidence))
    record = {'status': 'running', 'consumer': 'native default SDL via X11 human input',
              'mode': mode, 'output': str(output), 'output_nar_before': nar,
              'upstream': '0.9.5.0 aa894089399abe1a564a1ae6160a4751b6c61004',
              'sessions': [], 'assertions': []}
    session, server, server_log = None, None, None

    def report():
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')

    report()
    try:
        root, evidence = isolate(root, evidence)
        env = dict(os.environ)
        for variable, directory in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                    ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                    ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                    ('TMPDIR', 'tmp')]:
            (root / directory).mkdir(mode=0o700)
            env[variable] = str(root / directory)
        (root / 'work').mkdir()
        env.update(LH_WORK=str(root / 'work'), SDL_VIDEODRIVER='x11',
                   LIBGL_ALWAYS_SOFTWARE='1',
                   DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/no-session-bus')
        tools = {'xdotool': xdotool, 'import': capture, 'convert': convert}
        if mode == 'benchmark':
            benchmark(output, root, evidence, env, record)
        else:
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
        print('LAMBDAHACK-' + mode.upper() + ': native-consumer-ok')
    except BaseException as error:
        record.update(status='failed', error=str(error), traceback=traceback.format_exc())
        raise
    finally:
        if session is not None:
            session.close()
        stop(server)
        if server_log is not None:
            server_log.close()
        report()


if __name__ == '__main__':
    main()
