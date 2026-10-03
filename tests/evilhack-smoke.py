#!/usr/bin/env python3
"""External EvilHack 0.9.3 native tty gameplay proof (invoke through .sh).

The unmodified game owns random dungeon generation and native save files.
Three fresh xterm/PTY processes compare exact supported public HUD, map,
player cursor, inventory and turn, not hidden C structures or RNG state.
Screenshots come from the live X window; pyte only interprets recorded bytes.
Native controls/formats: src/cmd.c, src/save.c, src/botl.c, src/invent.c,
sys/unix/unixmain.c and win/tty/{wintty,topl}.c at v0.9.3.
"""
import codecs
import errno
import fcntl
import gzip
import hashlib
import json
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time
import tty

COLS, ROWS = 110, 24
NAME = 'Evilproof'
PLAYER = NAME + '-Val-Hum-Fem-Law'
OPTIONS = ('windowtype:tty,statuslines:2,time,symset:plain,pettype:none,'
           '!color,!legacy,!news,!splash_screen,!autopickup,!menu_overlay,'
           'menustyle:full,number_pad:0,disclose:none')
XTERM_FONT = '-misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-iso8859-1'
REFERENCE_COLUMNS = 32

def reference_terminal():
    # Independent external reference terminal, never the game or its evidence.
    data = '\x1b[2J'
    for style in range(2):
        for code in range(32, 127):
            index = code - 32
            row, col = style * 3 + index // REFERENCE_COLUMNS, index % REFERENCE_COLUMNS
            data += f'\x1b[{row + 1};{col * 3 + 2}H\x1b[{style}m' + chr(code)
    data += '\x1b[0m\x1b[10;1H'
    write_all(1, data.encode('ascii'))
    while True:
        time.sleep(60)


def pixel_mask(pixels, width, x, y, cell_w, cell_h):
    # Each fixed-width cell's top-left pixel is background; compare RGB bytes
    # exactly. This normalizes foreground/background polarity and palette,
    # not glyph shape: no thresholds, fuzzy distance, or substitutions.
    offset = (y * width + x) * 3
    background = pixels[offset:offset + 3]
    return bytes(pixels[((y + dy) * width + x + dx) * 3:
                        ((y + dy) * width + x + dx) * 3 + 3] != background
                 for dy in range(cell_h) for dx in range(cell_w))


def capture_reference(evidence, env):
    directory = evidence / 'font-reference'
    directory.mkdir(mode=0o700)
    log = open(directory / 'xterm.stderr', 'wb')
    proc = subprocess.Popen(
        ['xterm', '-geometry', f'{COLS}x{ROWS}', '-fn', XTERM_FONT, '-fb', XTERM_FONT,
         '-xrm', 'XTerm*renderFont:false', '-b', '2', '+sb', '-bg', 'black', '-fg', 'white',
         '-title', 'External glyph reference (not game evidence)', '-e',
         sys.executable, str(Path(__file__).resolve()), '--font-reference'],
        env=env, stdout=log, stderr=log, start_new_session=True)
    def command(*args, check=True):
        return subprocess.run(args, env=env, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, timeout=10, check=check)
    try:
        window = None
        end = time.monotonic() + 10
        while time.monotonic() < end:
            require(proc.poll() is None, 'glyph reference terminal exited')
            result = command('xdotool', 'search', '--onlyvisible', '--pid', str(proc.pid), check=False)
            if result.returncode == 0 and result.stdout.split():
                window = result.stdout.split()[-1].decode()
                break
            time.sleep(0.05)
        require(window, 'glyph reference window did not appear')
        path = directory / 'native-reference.png'
        end = time.monotonic() + 10
        while time.monotonic() < end:
            command('import', '-window', window, str(path))
            data = path.read_bytes()
            require(data[:8] == b'\x89PNG\r\n\x1a\n', 'glyph reference is not PNG')
            width, height = struct.unpack('>II', data[16:24])
            require((width - 4) % COLS == 0 and (height - 4) % ROWS == 0,
                    'reference terminal character geometry is not exact')
            cell_w, cell_h = (width - 4) // COLS, (height - 4) // ROWS
            pixels = command('convert', str(path), '-depth', '8', 'rgb:-').stdout
            require(len(pixels) == width * height * 3, 'incomplete reference pixels')
            require((cell_w, cell_h) == (6, 13),
                    'explicit core fixed font is unavailable or was substituted')
            glyphs = {}
            for style in range(2):
                for code in range(32, 127):
                    index = code - 32
                    row, col = style * 3 + index // REFERENCE_COLUMNS, index % REFERENCE_COLUMNS
                    mask = pixel_mask(pixels, width, 2 + (col * 3 + 1) * cell_w,
                                      2 + row * cell_h, cell_w, cell_h)
                    glyphs.setdefault(mask, set()).add(chr(code))
            if (all(len(chars) == 1 for chars in glyphs.values()) and
                    set().union(*glyphs.values()) == set(chr(code) for code in range(32, 127))):
                break
            time.sleep(0.05)
        else:
            raise RuntimeError('reference font has missing or colliding printable glyphs')
        metadata = {'font': XTERM_FONT, 'width': width, 'height': height,
                    'cell_width': cell_w, 'cell_height': cell_h,
                    'png_sha256': digest(data), 'window': window,
                    'normalization': 'exact RGB inequality to each cell top-left background; no fuzzy matching',
                    'masks': {digest(mask): sorted(chars) for mask, chars in glyphs.items()}}
        (directory / 'reference.json').write_text(json.dumps(metadata, indent=2) + '\n')
        return glyphs, metadata
    finally:
        if proc.poll() is None:
            os.killpg(proc.pid, signal.SIGTERM)
            try:
                proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
        log.close()


def decode_pixel_row(pixels, width, row, count, cell_w, cell_h, glyphs):
    decoded, masks = [], []
    for col in range(count):
        mask = pixel_mask(pixels, width, 2 + col * cell_w,
                          2 + row * cell_h, cell_w, cell_h)
        matches = glyphs.get(mask, set())
        require(len(matches) == 1,
                f'unknown/colliding genuine glyph at {col},{row}: {sorted(matches)}')
        decoded.append(next(iter(matches)))
        masks.append(digest(mask))
    return ''.join(decoded), masks



def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def write_all(fd, data):
    pending = memoryview(data)
    while pending:
        size = os.write(fd, pending)
        require(size > 0, 'PTY write made no progress')
        pending = pending[size:]


def relay(argv):
    program, raw_path, input_path = argv
    pid, master = pty.fork()
    if pid == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
        os.execv(program, [program, '-X', '-wtty', '-u', PLAYER, '-p', 'Valkyrie', '-r', 'human'])
    (Path(raw_path).parent / 'game-process.json').write_text(json.dumps(
        {'pid': pid, 'relay_pid': os.getpid(),
         'program': os.path.realpath(program),
         'argv': [program, '-X', '-wtty', '-u', PLAYER, '-p', 'Valkyrie', '-r', 'human']}, indent=2) + '\n')
    previous = termios.tcgetattr(0)
    tty.setraw(0)
    try:
        with open(raw_path, 'wb', buffering=0) as raw, open(input_path, 'wb', buffering=0) as inputs:
            while True:
                ready, _, _ = select.select([0, master], [], [], 1)
                if master in ready:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError as exc:
                        if exc.errno != errno.EIO:
                            raise
                        break
                    if not chunk:
                        break
                    raw.write(chunk)
                    write_all(1, chunk)
                if 0 in ready:
                    chunk = os.read(0, 4096)
                    if not chunk:
                        os.kill(pid, signal.SIGHUP)
                        break
                    inputs.write(chunk)
                    write_all(master, chunk)
    finally:
        termios.tcsetattr(0, termios.TCSANOW, previous)
        os.close(master)
    _, status = os.waitpid(pid, 0)
    code = os.waitstatus_to_exitcode(status)
    (Path(raw_path).parent / 'game-exit-status.txt').write_text(str(code) + '\n')
    return code


class Screen:
    @staticmethod
    def create():
        import pyte

        class NativeScreen(pyte.Screen):
            last_graphic = ''

            def draw(self, data):
                super().draw(data)
                if data:
                    self.last_graphic = data[-1]

            def repeat_character(self, count=1):
                if self.last_graphic:
                    super().draw(self.last_graphic * (count or 1))

        class NativeStream(pyte.Stream):
            csi = dict(pyte.Stream.csi, b='repeat_character')
            events = pyte.Stream.events | {'repeat_character'}

        screen = NativeScreen(COLS, ROWS)
        stream = NativeStream(screen)
        stream.use_utf8 = False
        return screen, stream


class WindowSession:
    def __init__(self, executable, directory, env, glyphs, reference):
        self.directory, self.env = directory, env
        self.glyphs, self.reference = glyphs, reference
        self.window = None
        self.raw_path = directory / 'terminal.raw'
        self.raw_path.touch()
        self.events, self.offset = [], 0
        self.screen, self.stream = Screen.create()
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.stderr = open(directory / 'launch.stderr', 'wb')
        self.proc = subprocess.Popen(
            ['xterm', '-geometry', f'{COLS}x{ROWS}', '-fn', XTERM_FONT, '-fb', XTERM_FONT,
             '-xrm', 'XTerm*renderFont:false', '-b', '2', '+sb', '-bg', 'black', '-fg', 'white',
             '-title', 'EvilHack native proof', '-e', sys.executable,
             str(Path(__file__).resolve()), '--relay', str(executable),
             str(self.raw_path), str(directory / 'input.raw')],
            env=env, stdout=self.stderr, stderr=self.stderr, start_new_session=True)

    def command(self, *args, check=True):
        return subprocess.run(args, env=self.env, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, timeout=10, check=check)

    def pump(self):
        with self.raw_path.open('rb') as stream:
            stream.seek(self.offset)
            chunk = stream.read()
        self.offset += len(chunk)
        require(self.offset < 8_000_000, 'excessive native terminal output')
        self.stream.feed(self.decoder.decode(chunk))
        return bool(chunk)

    def require_native_success(self):
        # files.c docompress_file can report a failed child compressor yet
        # continue gameplay and exit zero. Such output is never pagination.
        raw = self.raw_path.read_bytes().decode('latin-1')
        pattern = (r'(?:Exec|Fork) to (?:un)?compress[^\r\n]*failed'
                   r'|freopen[^\r\n]*(?:un)?compress failed'
                   r'|Unable to uncompress[^\r\n]*'
                   r'|Error in (?:zlib )?docompress[^\r\n]*')
        error = re.search(pattern, raw, re.I)
        if error:
            (self.directory / 'native-error.txt').write_text(error[0] + '\n')
            (self.directory / 'failure-screen.txt').write_text(
                '\n'.join(self.screen.display) + '\n')
            if self.window and self.proc.poll() is None:
                try:
                    self.image('native-error')
                except Exception as exc:
                    (self.directory / 'failure-capture-error.txt').write_text(str(exc) + '\n')
            raise RuntimeError('native compression/decompression failed: ' + error[0])

    def text(self):
        self.pump()
        return '\n'.join(self.screen.display)

    def settle(self):
        end, quiet = time.monotonic() + 5, time.monotonic()
        while time.monotonic() - quiet < 0.25:
            if self.pump():
                quiet = time.monotonic()
            require(time.monotonic() < end, 'native terminal never became idle')
            time.sleep(0.025)

    def locate(self):
        result = self.command('xdotool', 'search', '--onlyvisible', '--pid',
                              str(self.proc.pid), check=False)
        windows = result.stdout.decode().split() if result.returncode == 0 else []
        if windows:
            self.window = windows[-1]
        return self.window is not None

    def key(self, key):
        require(self.window is not None and self.proc.poll() is None,
                'no live target X window')
        self.command('xdotool', 'windowfocus', '--sync', self.window)
        self.command('xdotool', 'key', '--clearmodifiers', key)
        self.events.append({'key': key, 'time_ns': time.monotonic_ns(),
                            'output_offset': self.offset})

    def image(self, label):
        path = self.directory / (label + '.png')
        self.command('import', '-window', self.window, str(path))
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'native X capture is not PNG')
        width, height = struct.unpack('>II', data[16:24])
        require((width, height) == (COLS * 6 + 4, ROWS * 13 + 4),
                'explicit native xterm geometry/font was substituted')
        return {'path': path.name, 'sha256': digest(data), 'width': width,
                'height': height, 'window': self.window}

    def record(self, label):
        self.settle()
        text = self.text()
        (self.directory / (label + '.txt')).write_text(text + '\n')
        (self.directory / (label + '.raw')).write_bytes(self.raw_path.read_bytes())
        return self.image(label)

    def more(self):
        # Source topl.c uses exactly --More--. Never acknowledge an arbitrary
        # prompt, a stale marker, or an inventory page as message pagination.
        text = self.text()
        self.require_native_success()
        if '--More--' not in text:
            return False
        before = self.offset
        self.record('message-' + str(len(self.events)))
        self.key('space')
        self.settle()
        require(self.offset > before or self.proc.poll() is not None,
                'native message pagination made no observable progress')
        return True

    def await_screen(self, predicate, label, messages=True, seconds=25):
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            self.pump()
            require(self.proc.poll() is None, 'native process exited waiting for ' + label)
            if self.window is None and not self.locate():
                time.sleep(0.05)
                continue
            self.settle()
            self.require_native_success()
            if messages and self.more():
                continue
            text = self.text()
            if predicate(text):
                return text
            time.sleep(0.05)
        raise RuntimeError('timed out waiting for ' + label)

    def live(self):
        self.key('ctrl+r')  # cmd.c doredraw: display only; no gameplay turn.
        self.await_screen(lambda t: public_state(self.screen) is not None,
                          'native tty HUD/player/turn')
        return public_state(self.screen)

    def capture(self, label):
        before = self.live()
        screenshot = self.record(label)
        # Decode actual native HUD pixels against independent live-xterm glyphs.
        # No ANSI rerender, OCR correction, fuzzy matching or image synthesis.
        pixels = self.command('convert', str(self.directory / screenshot['path']),
                              '-depth', '8', 'rgb:-').stdout
        require(len(pixels) == screenshot['width'] * screenshot['height'] * 3,
                'incomplete native screenshot pixels')
        decoded = []
        for row in (22, 23):
            line, _ = decode_pixel_row(pixels, screenshot['width'], row, COLS,
                                      self.reference['cell_width'],
                                      self.reference['cell_height'], self.glyphs)
            require(line == self.screen.display[row],
                    'native screenshot HUD differs from recorded native terminal')
            decoded.append(line)
        screenshot['exact_pixel_hud'] = decoded
        inventory, images = self.inventory(before, label + '-inventory')
        before['inventory'] = inventory
        screenshot['inventory_screenshots'] = images
        (self.directory / (label + '.json')).write_text(json.dumps(before, indent=2) + '\n')
        return before, screenshot

    def inventory(self, before, label):
        self.key('i')
        marker = r'\(end\)|\((\d+) of (\d+)\)'
        self.await_screen(lambda t: re.search(marker, t), 'native inventory menu', messages=False)
        items, images, seen, expected, total = [], [], set(), 1, None
        while True:
            matches = list(re.finditer(marker, self.text()))
            require(len(matches) == 1, 'inventory needs exactly one native page marker')
            match = matches[0]
            current = int(match[1]) if match[1] else 1
            count = int(match[2]) if match[2] else 1
            require(current == expected and current not in seen and 1 <= current <= count <= 52,
                    'native inventory pagination is inconsistent or stalled')
            require(total is None or count == total, 'inventory page total changed')
            total = count
            seen.add(current)
            images.append(self.record(label + '-page-' + str(current)))
            for line in self.screen.display:
                item = re.match(r'^\s*([a-zA-Z$])\s+[-+]\s+(.+?)\s*$', line)
                if item:
                    items.append({'letter': item[1], 'description': item[2]})
            if current == total:
                self.key('space')  # PICK_NONE last-page native menu completion.
                break
            expected += 1
            self.key('greater')  # wintty.c MENU_NEXT_PAGE, not guessed spaces.
            self.await_screen(lambda t: f'({expected} of {total})' in t,
                              'next exact native inventory page', messages=False)
        after = self.live()
        require(after == before, 'native inventory inspection changed public gameplay state')
        require(items and len({i['letter'] for i in items}) == len(items),
                'native inventory has missing or duplicate item letters')
        require(any('spear' in i['description'] for i in items) and
                any('shield' in i['description'] for i in items),
                'ordinary native Valkyrie inventory lacks spear/shield')
        return items, images

    def move(self, before, label):
        x, y = before['position']
        candidates = []
        threats = [(mx, my) for my, row in enumerate(before['map'])
                   for mx, glyph in enumerate(row) if glyph.isascii() and glyph.isalpha()]
        for dx, dy, key in ((1, 0, 'l'), (-1, 0, 'h'), (0, 1, 'j'), (0, -1, 'k'),
                            (1, -1, 'u'), (-1, -1, 'y'), (1, 1, 'n'), (-1, 1, 'b')):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 80 and 0 <= ny < 21 and before['map'][ny][nx] in '.#<>':
                if dx and dy and (before['map'][y][nx] not in '.#<>' or
                                  before['map'][ny][x] not in '.#<>'):
                    continue  # source hack.c diagonal doorway/tight-corner gates.
                # Empty visible ground only. Doors/objects/creatures/unknown
                # cells excluded; prefer cardinal moves with greatest clearance.
                clearance = min((max(abs(nx - mx), abs(ny - my)) for mx, my in threats), default=80)
                candidates.append((clearance, not (dx and dy), nx, ny, key))
        require(candidates, 'no safe visible adjacent native floor/corridor/stair')
        _, _, nx, ny, key = max(candidates, key=lambda c: c[:2])
        self.key(key)
        self.settle()
        moved, screenshot = self.capture(label)
        require(moved['position'] == [nx, ny] and moved['turn'] > before['turn'],
                'native directional action did not move to target and advance turn')
        require(moved['hp'][0] > 0, 'player did not survive native movement')
        return moved, screenshot, {'key': key, 'from': before['position'],
                                   'to': moved['position'], 'turns': [before['turn'], moved['turn']]}

    def exit_clean(self, label):
        end = time.monotonic() + 25
        while self.proc.poll() is None:
            self.pump()
            self.settle()
            if self.window:
                self.more()
            require(time.monotonic() < end, 'native process did not exit after ' + label)
            time.sleep(0.05)
        self.pump()
        self.require_native_success()
        require(self.proc.returncode == 0, 'xterm exited abnormally after ' + label)
        require((self.directory / 'game-exit-status.txt').read_text().strip() == '0',
                'native game exited abnormally after ' + label)
        (self.directory / (label + '-exit.txt')).write_text(self.text() + '\n')

    def save(self, state_root):
        self.key('S')
        self.await_screen(lambda t: 'Really save?' in t, 'native S confirmation', messages=False)
        self.record('save-confirmation')
        self.key('y')
        self.exit_clean('save')
        require(b'Saving...' in self.raw_path.read_bytes(), 'native saving message absent')
        saves = [p for p in (state_root / 'save').rglob('*') if p.is_file()]
        require(len(saves) == 1 and saves[0].stat().st_size > 0,
                'native save must produce exactly one nonempty durable save')
        save = saves[0]
        data = save.read_bytes()
        require(save.suffix == '.gz' and data.startswith(b'\x1f\x8b'),
                'native save must be the declared real gzip-compressed file')
        require(gzip.decompress(data), 'native gzip save has no payload')
        copy = self.directory / ('native-save' + ''.join(save.suffixes))
        copy.write_bytes(data)
        return {'path': str(save), 'evidence': copy.name, 'bytes': len(data), 'sha256': digest(data)}

    def quit(self):
        self.key('numbersign')
        for key in ('q', 'u', 'i', 't', 'Return'):
            self.key(key)
        self.await_screen(lambda t: 'Really quit?' in t, 'native quit confirmation', messages=False)
        self.record('quit-confirmation')
        for key in ('y', 'e', 's', 'Return'):
            self.key(key)
        self.exit_clean('quit')

    def close(self):
        # Preserve diagnostics before terminating a failed session. A forced
        # cleanup never counts as a successful native save or quit.
        try:
            self.pump()
            (self.directory / 'final-screen.txt').write_text(self.text() + '\n')
            if self.proc.poll() is None and self.window:
                try:
                    self.image('failure')
                except Exception as exc:
                    (self.directory / 'failure-capture-error.txt').write_text(str(exc) + '\n')
        finally:
            if self.proc.poll() is None:
                os.killpg(self.proc.pid, signal.SIGTERM)
                try:
                    self.proc.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    os.killpg(self.proc.pid, signal.SIGKILL)
                    self.proc.wait()
            self.pump()
            (self.directory / 'keys.json').write_text(json.dumps(self.events, indent=2) + '\n')
            self.stderr.close()


def public_state(screen):
    hud = screen.display[22:24]
    turn = re.search(r'\bT:\s*(\d+)', hud[1])
    hp = re.search(r'\bHP:\s*(\d+)\((\d+)\)', hud[1])
    if NAME not in hud[0] or 'St:' not in hud[0] or not turn or not hp:
        return None
    if '--More--' in '\n'.join(screen.display):
        return None
    dungeon = [row[:80] for row in screen.display[1:22]]
    x, y = screen.cursor.x, screen.cursor.y - 1
    if not (0 <= x < 80 and 0 <= y < 21 and dungeon[y][x] == '@'):
        return None
    require('Lawful' in hud[0], 'native HUD has wrong alignment')
    require(re.search(r'\bDlvl:\s*1\b', hud[1]), 'native proof left first dungeon level')
    require(int(hp[1]) > 0, 'native player is not alive')
    return {'hud': hud, 'turn': int(turn[1]), 'hp': [int(hp[1]), int(hp[2])],
            'position': [x, y], 'map': dungeon,
            'coordinate_kind': 'zero-based native COLNO=80 ROWNO=21 map, tty offy=1'}


def prove_game(output, evidence, env, glyphs, reference):
    state_root = Path(env['XDG_DATA_HOME']) / 'evilhack'
    proof = {'program': str(output / 'bin' / 'evilhack'), 'options': OPTIONS,
             'argv': ['-X', '-wtty', '-u', PLAYER, '-p', 'Valkyrie', '-r', 'human'],
             'native_sources': {'save': 'src/cmd.c:4497; src/save.c:80-105 (S, Really save?, exit success)',
                                'quit': 'src/end.c:359-407 (#quit, Really quit?, done QUIT)',
                                'restore': 'sys/unix/unixmain.c:304-314 (restore, keep-save prompt)',
                                'inventory': 'src/invent.c:3014-3018; win/tty/wintty.c:2139-2141,2231-2248,3209-3221; include/wintype.h:113',
                                'geometry': 'win/tty/wintty.c:1531-1561 (status offy22, map offy1, 80x21)',
                                'options': 'src/options.c:915-946,2258-2313,3414-3424 (EVILHACKOPTIONS, pettype, disclosure)'},
             'sessions': [], 'continuity': [],
             'scope': {'exact_fields': ['full two native HUD rows', 'turn', 'HP/current/max',
                                        'player cursor/map coordinate', 'all 80x21 displayed map cells',
                                        'all native inventory letters/descriptions across every page'],
                       'limits': ['Public visible state only; binary saves are not decoded.',
                                  'Hidden terrain, monsters, objects, RNG, timers and unshown internal attributes are not compared.',
                                  'Explore mode is ordinary upstream -X; no world/state injection.',
                                  'Screenshots are live xterm captures; exact pixel glyph corroboration covers HUD, not hidden state.'],
                       'source_commit': 'c444f6a3ab1e9f16d0676961dba86f628e91c6ba'}}
    previous = None
    try:
        for stage in ('new', 'restore-one', 'restore-two'):
            directory = evidence / stage
            directory.mkdir(mode=0o700)
            session = WindowSession(output / 'bin' / 'evilhack', directory, env, glyphs, reference)
            try:
                if previous is not None:
                    session.await_screen(lambda t: 'Do you want to keep the save file?' in t,
                                         'native restored explore-save retention prompt')
                    session.record('restore-save-consumption')
                    session.key('n')  # native unixmain.c removes save after successful recovery.
                session.await_screen(lambda t: public_state(session.screen) is not None,
                                     'native startup HUD/player/turn')
                initial, screenshot = session.capture('initial') if previous is None else session.capture('restored')
                raw = session.raw_path.read_bytes()
                require((b'Restoring save file...' in raw) == (previous is not None),
                        'wrong native new-game/restore path')
                process = json.loads((directory / 'game-process.json').read_text())
                record = {'stage': stage, 'process': process, 'xterm_pid': session.proc.pid,
                          'initial': initial, 'screenshots': [screenshot]}
                if previous is None:
                    require(initial['turn'] == 1, 'native new game did not start at turn one')
                else:
                    require(initial == previous, 'native restore differs from exact saved public state')
                    require(not any(p.is_file() for p in (state_root / 'save').rglob('*')),
                            'native restore did not consume its save after answering no')
                    proof['continuity'].append({'stage': stage, 'exact_public_state': True})
                moved, screenshot, movement = session.move(initial, 'moved')
                record.update(final=moved, movement=movement)
                record['screenshots'].append(screenshot)
                if stage == 'restore-two':
                    session.quit()
                    require(not any(p.is_file() for p in (state_root / 'save').rglob('*')),
                            'clean quit unexpectedly left a native save')
                    record['action'] = 'native #quit after continued movement'
                else:
                    record['native_save'] = session.save(state_root)
                    record['action'] = 'native S save and exit'
                record['exit_status'] = 0
                proof['sessions'].append(record)
                previous = moved
            finally:
                session.close()
        require(len({s['process']['pid'] for s in proof['sessions']}) == 3,
                'proof did not use three distinct fresh native game processes')
        require(len(proof['continuity']) == 2, 'both exact native restores were not proven')
        return proof
    except BaseException as exc:
        proof['error'] = str(exc)
        (evidence / 'partial-proof.json').write_text(json.dumps(proof, indent=2) + '\n')
        raise

def main(argv):
    require(len(argv) == 2, 'usage: evilhack-smoke.py OUTPUT EVIDENCE (via .sh wrapper)')
    output, evidence = map(lambda p: Path(p).resolve(), argv)
    namespaces = {}
    for kind in ('net', 'mnt', 'pid'):
        current = os.readlink(f'/proc/self/ns/{kind}')
        host = os.environ.get(f'EVILHACK_HOST_{kind.upper()}NS')
        require(host and host != current, f'driver requires a new {kind} namespace')
        namespaces[kind] = current
    require(str(os.getuid()) == os.environ.get('EVILHACK_HOST_UID'),
            'namespace must preserve the caller UID, not map to root')
    interfaces = sorted(line.split(':', 1)[0].strip()
                        for line in Path('/proc/net/dev').read_text().splitlines()[2:])
    require(interfaces == ['lo'], 'isolated namespace has a non-loopback interface')
    require(not Path(__file__).resolve().is_relative_to('/tmp') and
            not Path(sys.executable).resolve().is_relative_to('/tmp'),
            'checkout and Python must be outside host /tmp')
    subprocess.run(['mount', '--make-rprivate', '/'], check=True, timeout=10)
    subprocess.run(['mount', '--bind', '/gnu/store', '/gnu/store'], check=True, timeout=10)
    subprocess.run(['mount', '-o', 'remount,bind,ro', '/gnu/store'], check=True, timeout=10)
    mounts = [line.split() for line in Path('/proc/self/mountinfo').read_text().splitlines()]
    store_mounts = [fields for fields in mounts if fields[4] == '/gnu/store']
    require(store_mounts and 'ro' in store_mounts[-1][5].split(','),
            '/gnu/store bind mount is not read-only')
    (evidence / 'namespace-mountinfo.txt').write_text(Path('/proc/self/mountinfo').read_text())
    (evidence / 'namespace-network.txt').write_text(Path('/proc/net/dev').read_text())
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        subprocess.run(['mount', '-t', 'tmpfs', '-o', 'mode=1777,nosuid,nodev',
                        'tmpfs', '/tmp'], check=True, timeout=10)
        evidence = Path('/tmp/evilhack-evidence')
        evidence.mkdir(mode=0o700)
        subprocess.run(['mount', '--no-canonicalize', '--bind',
                        f'/proc/self/fd/{evidence_fd}', str(evidence)],
                       pass_fds=(evidence_fd,), check=True, timeout=10)
    finally:
        os.close(evidence_fd)
    os.chdir('/tmp')
    env = dict(os.environ)
    for key, leaf in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                      ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                      ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                      ('TMPDIR', 'tmp')):
        directory = evidence / leaf
        directory.mkdir(mode=0o700)
        env[key] = str(directory)
    env.update(TERM='xterm-256color', LC_ALL='C', EVILHACKOPTIONS=OPTIONS)
    font_path = env.get('EVILHACK_X_FONT_PATH', '')
    require(font_path.startswith('/gnu/store/') and (Path(font_path) / 'fonts.dir').is_file(),
            'wrapper must supply realized read-only core X11 font directory')
    read_fd, write_fd = os.pipe()
    xlog = open(evidence / 'xvfb.log', 'wb')
    xvfb = subprocess.Popen(['Xvfb', '-displayfd', str(write_fd), '-screen', '0',
                             '1920x1200x24', '-fp', font_path, '-nolisten', 'tcp', '-ac'],
                            pass_fds=(write_fd,), stdout=xlog, stderr=xlog, env=env)
    os.close(write_fd)
    try:
        ready, _, _ = select.select([read_fd], [], [], 10)
        require(ready, 'Xvfb did not announce a display')
        display = os.read(read_fd, 64).decode().strip()
        require(display.isdigit(), 'invalid Xvfb display announcement')
        env['DISPLAY'] = ':' + display
        glyphs, reference = capture_reference(evidence, env)
        proof = {'namespaces': namespaces, 'uid': os.getuid(),
                 'interfaces': interfaces, 'store_read_only': True,
                 'display': env['DISPLAY'], 'font_reference': reference,
                 'game': prove_game(output, evidence, env, glyphs, reference)}
        final_interfaces = sorted(line.split(':', 1)[0].strip()
                                  for line in Path('/proc/net/dev').read_text().splitlines()[2:])
        require(final_interfaces == ['lo'], 'gameplay introduced a non-loopback interface')
        proof['final_interfaces'] = final_interfaces
        (evidence / 'proof.json').write_text(json.dumps(proof, indent=2) + '\n')
    finally:
        os.close(read_fd)
        xvfb.terminate()
        try:
            xvfb.wait(timeout=3)
        except subprocess.TimeoutExpired:
            xvfb.kill()
            xvfb.wait()
        xlog.close()
    print('evilhack external proof: native movement/save/two exact restores/quit complete')
    return 0


if __name__ == '__main__':
    try:
        if len(sys.argv) > 1 and sys.argv[1] == '--font-reference':
            reference_terminal()
        if len(sys.argv) > 1 and sys.argv[1] == '--relay':
            sys.exit(relay(sys.argv[2:]))
        sys.exit(main(sys.argv[1:]))
    except Exception as exc:
        print(f'evilhack proof failed: {exc}', file=sys.stderr)
        sys.exit(1)
