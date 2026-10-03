#!/usr/bin/env python3
"""External DynaHack acceptance: real xterm/Xvfb, ordinary UI and native saves.

Invoke through dynahack-smoke.sh OUTPUT EVIDENCE. --relay is an external raw
PTY recorder, not a game hook. Screenshots are captured from the X window;
pyte only reads raw terminal evidence; glyph matching reads real X pixels.
"""
import base64
import codecs
import errno
import fcntl
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

COLS, ROWS = 110, 40
NAME = 'Dynaproof'
XTERM_FONT = '-misc-fixed-medium-r-normal--13-120-75-75-c-60-iso8859-1'
REFERENCE_COLUMNS = 32


def reference_terminal():
    # Independent external reference terminal, never the game or its evidence.
    data = '\x1b[2J'
    for style in range(2):
        for code in range(32, 127):
            index = code - 32
            row, col = style * 3 + index // REFERENCE_COLUMNS, index % REFERENCE_COLUMNS
            data += f'\x1b[{row + 1};{col * 3 + 2}H\x1b[{style}m' + chr(code)
    # Native map @ carries bold+underline SGR in the recorded game stream.
    # Keep this separate real reference glyph outside the cursor overlay.
    data += '\x1b[10;2H\x1b[0;1;4m@\x1b[0m\x1b[12;1H'
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
        command('xdotool', 'windowfocus', '--sync', window)
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
            player_mask = pixel_mask(pixels, width, 2 + cell_w, 2 + 9 * cell_h, cell_w, cell_h)
            glyphs.setdefault(player_mask, set()).add('@')
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
        os.execv(program, [program, '-u', NAME, '-p', 'Valkyrie', '-r', 'human'])
    (Path(raw_path).parent / 'game-process.json').write_text(json.dumps(
        {'pid': pid, 'relay_pid': os.getpid(),
         'program': os.path.realpath(program),
         'argv': [program, '-u', NAME, '-p', 'Valkyrie', '-r', 'human']}, indent=2) + '\n')
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


class WindowSession:
    def __init__(self, executable, directory, env, glyphs, reference):
        import pyte
        self.directory, self.env = directory, env
        self.glyphs, self.reference = glyphs, reference
        self.window = None
        self.raw_path = directory / 'terminal.raw'
        self.raw_path.touch()
        self.events, self.offset = [], 0
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.stderr = open(directory / 'launch.stderr', 'wb')
        command = ['xterm', '-geometry', f'{COLS}x{ROWS}', '-fn', XTERM_FONT, '-fb', XTERM_FONT,
                   '-xrm', 'XTerm*renderFont:false', '-b', '2', '+sb', '-bg', 'black', '-fg', 'white',
                   '-title', 'DynaHack native proof', '-e', sys.executable,
                   str(Path(__file__).resolve()), '--relay', str(executable),
                   str(self.raw_path), str(directory / 'input.raw')]
        self.proc = subprocess.Popen(command, env=env, stdout=self.stderr,
                                     stderr=self.stderr, start_new_session=True)

    def command(self, *args, check=True):
        return subprocess.run(args, env=self.env, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, timeout=10, check=check)

    def pump(self):
        with open(self.raw_path, 'rb') as stream:
            stream.seek(self.offset)
            chunk = stream.read()
            self.offset += len(chunk)
        self.stream.feed(self.decoder.decode(chunk))

    def locate(self):
        result = self.command('xdotool', 'search', '--onlyvisible', '--pid',
                              str(self.proc.pid), check=False)
        windows = result.stdout.decode().split() if result.returncode == 0 else []
        if windows:
            self.window = windows[-1]
        return self.window is not None

    def image(self, path):
        self.command('import', '-window', self.window, str(path))
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'X capture is not PNG')
        width, height = struct.unpack('>II', data[16:24])
        require(width >= 640 and height >= 400, 'native X window too small')
        return {'path': path.name, 'sha256': digest(data),
                'width': width, 'height': height, 'window': self.window}

    def text(self):
        self.pump()
        return '\n'.join(self.screen.display)

    def await_screen(self, predicate, label, seconds=25):
        end = time.monotonic() + seconds
        last = ''
        while time.monotonic() < end:
            self.pump()
            require(self.proc.poll() is None, f'exited waiting for {label}')
            if self.window is None and not self.locate():
                time.sleep(0.05)
                continue
            last = self.text()
            if re.search(r'--\s*More\s*--', last, re.I):
                self.key('space')
            elif predicate(last):
                return last
            time.sleep(0.05)
        (self.directory / 'failure-screen.txt').write_text(last)
        raise RuntimeError(f'timed out waiting for {label}; see {self.directory}')

    def key(self, key):
        require(self.window is not None, 'no target X window')
        self.command('xdotool', 'windowfocus', '--sync', self.window)
        self.command('xdotool', 'key', '--clearmodifiers', key)
        self.events.append({'key': key, 'time_ns': time.monotonic_ns()})

    def capture(self, label, state):
        text = self.text()
        require(visible_state(text, self.screen.cursor) == state, 'live state changed before capture')
        (self.directory / f'{label}.txt').write_text(text)
        snapshot = self.image(self.directory / f'{label}.png')
        # The game PNG is never altered. Independent real xterm glyphs decode
        # native status pixels exactly; no OCR substitution or fuzzy matching.
        require((snapshot['width'] - 4) % COLS == 0 and
                (snapshot['height'] - 4) % ROWS == 0,
                'xterm capture has unexpected border or character geometry')
        cell_w = (snapshot['width'] - 4) // COLS
        cell_h = (snapshot['height'] - 4) // ROWS
        require((cell_w, cell_h) == (self.reference['cell_width'], self.reference['cell_height']),
                'native and reference terminal font geometry differ')
        pixels = self.command('convert', str(self.directory / f'{label}.png'),
                              '-depth', '8', 'rgb:-').stdout
        require(len(pixels) == snapshot['width'] * snapshot['height'] * 3,
                'incomplete native screenshot pixels')
        decoded, masks = [], []
        for row in (24, 25):
            line, hashes = decode_pixel_row(pixels, snapshot['width'], row, COLS,
                                           cell_w, cell_h, self.glyphs)
            require(line == self.screen.display[row],
                    f'actual native pixel row {row} differs from exact raw-terminal row')
            decoded.append(line)
            masks.append(hashes)
        native_status = '\n'.join(decoded)
        require(visible_status(native_status) ==
                {k: state[k] for k in ('player', 'turn', 'depth', 'hp', 'hp_max')},
                'native exact glyphs do not corroborate player/turn/depth/HP')
        (self.directory / f'{label}.glyphs.txt').write_text(native_status + '\n')
        (self.directory / f'{label}.glyph-masks.json').write_text(
            json.dumps({'rows': [24, 25], 'masks': masks}, indent=2) + '\n')
        snapshot['exact_glyph_status'] = native_status
        x, y = state['terminal_coordinate']
        player_mask = pixel_mask(pixels, snapshot['width'], 2 + x * cell_w,
                                 2 + y * cell_h, cell_w, cell_h)
        require(self.glyphs.get(player_mask) == {'@'},
                'genuine screenshot does not show player at raw-terminal coordinate')
        snapshot['player_glyph_mask_sha256'] = digest(player_mask)
        raw = self.raw_path.read_bytes()
        (self.directory / f'{label}.raw').write_bytes(raw)
        snapshot['terminal_raw_sha256'] = digest(raw)
        snapshot['state'] = state
        return snapshot

    def finish(self):
        self.key('q')
        end = time.monotonic() + 10
        while self.proc.poll() is None and time.monotonic() < end:
            self.pump()
            time.sleep(0.05)
        self.pump()
        require(self.proc.poll() == 0, 'xterm did not exit cleanly after native quit')
        require((self.directory / 'game-exit-status.txt').read_text().strip() == '0',
                'game did not exit cleanly (xterm status is not game status)')

    def close(self):
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



def native_state(path):
    # log.c:217-222, save.c:70-104 and u_init.c:1280-1461 in v0.6.0.
    # store_mf writes the raw, little-endian memfile after the text log.
    data = path.read_bytes()
    header = re.match(rb'NHGAME save ([0-9a-f]{8}) ([0-9a-f]{8}) 0\.6\.0\n', data)
    require(header is not None, 'not an ordinary resumable DynaHack 0.6.0 save')
    offset = int(header[1], 16)
    binary = data[offset:]
    require(len(binary) > 1737 and struct.unpack_from('<I', binary)[0] == 0x00060000,
            'missing/version-mismatched native binary save')
    identity = data.split(b'\n', 2)[1]
    fields = identity.split()
    require(len(fields) == 8 and fields[2] == b'0', 'not an ordinary scoring game')
    player = base64.b64decode(fields[3], validate=True).rstrip(b'\0').decode('ascii')
    require(player == NAME and fields[4:] == [b'Valkyrie', b'human', b'female', b'neutral'],
            'unexpected native character identity')
    number = lambda pos: struct.unpack_from('<i', binary, pos)[0]
    # Fixed flags = 14*4 + 44 + 18 + 52 bytes after 12-byte version.
    # Full struct-you ends at offset 1733; no C structure padding is written.
    return {'player': player, 'identity_line': identity.decode('ascii'),
            'identity': [item.decode('ascii') for item in fields[4:]],
            'hp': number(194), 'hp_max': number(198), 'turn': number(1733),
            'map_coordinate': list(binary[507:509]),
            'dungeon_coordinate': list(binary[515:517]),
            'initial_identity_indices': [number(i) for i in (398, 402, 406, 410)],
            'save_offset': offset, 'actions': int(header[2], 16),
            'sha256': digest(data), 'bytes': len(data),
            'binary_sha256': digest(binary), 'binary_bytes': len(binary)}


def compare_restore_bytes(path, snapshot):
    # Successful dorecover_fd (restore.c:710-735) removes the binary tail.
    # log_truncate removes its final delimiter, not committed command/diff data.
    old = native_state(snapshot)
    before, after = snapshot.read_bytes(), path.read_bytes()
    identity = after.split(b'\n', 2)
    require(len(identity) == 3 and identity[1].decode('ascii') == old['identity_line'],
            'restore changed immutable native identity')
    body = before.split(b'\n', 2)[2][:old['save_offset'] -
                                           len(before.split(b'\n', 2)[0]) -
                                           len(before.split(b'\n', 2)[1]) - 2]
    require(identity[2].rstrip(b'\n') == body.rstrip(b'\n'),
            'restore changed committed command/diff bytes or advanced gameplay')
    return {'identity_equal': True, 'committed_log_bytes_equal': True,
            'saved_sha256': digest(before), 'live_log_sha256': digest(after),
            'binary_tail_removed_by_native_restore': True}


def compare_resave(path, snapshot):
    old, new = native_state(snapshot), native_state(path)
    fields = ('player', 'identity_line', 'hp', 'hp_max', 'turn', 'map_coordinate',
              'dungeon_coordinate', 'initial_identity_indices')
    require(all(new[k] == old[k] for k in fields), 'no-turn resave changed decoded state')
    before = snapshot.read_bytes()[old['save_offset']:]
    after = path.read_bytes()[new['save_offset']:]
    # dorecover resets serialized flags.move (offset 82) to zero; exclude only
    # this source-defined transient byte, not arbitrary differing bytes.
    require(before[:82] + before[83:] == after[:82] + after[83:],
            'no-turn resave changed binary state beyond native flags.move reset')
    return {'decoded_fields_equal': True, 'binary_equal': before == after,
            'binary_equal_except_flags_move': True, 'excluded_offset': 82,
            'flags_move_before': before[82], 'flags_move_after': after[82],
            'before_binary_sha256': digest(before), 'after_binary_sha256': digest(after)}


def visible_status(text):
    rows = text.splitlines()
    status = '\n'.join(rows[24:26]) if len(rows) > 25 else text
    if not re.search(r'\b' + NAME + r'\s+the\b', status):
        return None
    turn = re.search(r'\bT\s*:\s*(\d+)\b', status)
    depth = re.search(r'\bDlvl\s*:\s*(\d+)\b', status)
    hp = re.search(r'\bHP\s*:\s*(\d+)\s*\(\s*(\d+)\s*\)', status)
    if not (turn and depth and hp):
        return None
    return {'player': NAME, 'turn': int(turn[1]), 'depth': int(depth[1]),
            'hp': int(hp[1]), 'hp_max': int(hp[2])}


def visible_state(text, cursor):
    state = visible_status(text)
    if state is None or cursor.hidden:
        return None
    # windows.c:326-329: frame=false, sidebar=false, msgheight=3.
    # map.c:21,44 uses ux-1 for the terminal column.
    x, y = cursor.x + 1, cursor.y - 3
    if not (1 <= x < 80 and 0 <= y < 21):
        return None
    if text.splitlines()[cursor.y][cursor.x] != '@':
        return None
    return dict(state, map_coordinate=[x, y], terminal_coordinate=[cursor.x, cursor.y])


def main_menu(text):
    return 'new game' in text.lower() and 'load game' in text.lower()


def save_and_exit(session, state_root, destination, state):
    session.key('S')
    session.await_screen(lambda t: 'Really save?' in t, 'native save confirmation')
    session.key('y')
    session.await_screen(main_menu, 'main menu after native save')
    session.finish()
    saves = list((state_root / 'save').glob('*.nhgame'))
    require(len(saves) == 1, 'expected exactly one native saved game')
    native = native_state(saves[0])
    require(all(native[k] == state[k] for k in ('player', 'turn', 'hp', 'hp_max', 'map_coordinate')),
            'decoded native save differs from exact rendered live state')
    require(native['dungeon_coordinate'] == [0, state['depth']],
            'native saved dungeon coordinate differs from live depth')
    destination.write_bytes(saves[0].read_bytes())
    native.update(filename=saves[0].name, snapshot=str(destination.relative_to(destination.parents[1])))
    return native, saves[0]


def move_player(session, state):
    directions = [(1, 0, 'l'), (-1, 0, 'h'), (0, 1, 'j'), (0, -1, 'k'),
                  (1, 1, 'n'), (-1, 1, 'b'), (1, -1, 'u'), (-1, -1, 'y')]
    x, y = state['terminal_coordinate']
    rows = session.text().splitlines()
    choice = next(((dx, dy, key) for dx, dy, key in directions
                   if 3 <= y + dy < 24 and 1 <= x + dx < 80 and
                   rows[y + dy][x + dx] in '.#<>'), None)
    require(choice is not None, 'no visible empty adjacent native map cell')
    dx, dy, key = choice
    session.key(key)
    text = session.await_screen(
        lambda t: (visible_state(t, session.screen.cursor) is not None and
                   visible_state(t, session.screen.cursor)['turn'] > state['turn'] and
                   visible_state(t, session.screen.cursor)['terminal_coordinate'] == [x + dx, y + dy]),
        'real adjacent movement')
    moved = visible_state(text, session.screen.cursor)
    require(moved['depth'] == state['depth'], 'ordinary adjacent move changed depth')
    return moved


def prove_game(output, evidence, env, glyphs, reference):
    state_root = Path(env['XDG_CONFIG_HOME']) / 'DynaHack'
    state_root.mkdir(mode=0o700)
    (state_root / 'DynaHack.conf').write_text('legacy=false\ngender="female"\nalign="neutral"\n')
    (state_root / 'curses.conf').write_text(
        'classic_status=true\nstatus3=true\ntime=true\nframe=false\nsidebar=false\n'
        'graphics="plain"\nmsgheight=3\n')
    proof = {'program': str(output / 'bin' / 'dynahack'), 'sessions': [],
             'hidden_state_limit': 'Only fixed player fields are decoded. Binary equality is opaque byte equality, not semantic decoding of inventory, monsters, maps, timers or RNG.'}
    saved_state, saved_path, saved_snapshot, identity = None, None, None, None
    for stage in ('new', 'restore-one', 'restore-two'):
        directory = evidence / stage
        directory.mkdir(mode=0o700)
        session = WindowSession(output / 'bin' / 'dynahack', directory, env, glyphs, reference)
        try:
            session.await_screen(main_menu, 'initial native menu')
            session.key('n' if stage == 'new' else 'l')
            if stage != 'new':
                session.await_screen(lambda t: 'saved games' in t.lower() and NAME in t,
                                     'native saved-game chooser')
                session.key('a')
            text = session.await_screen(lambda t: visible_state(t, session.screen.cursor) is not None,
                                        'native live status and position')
            state = visible_state(text, session.screen.cursor)
            record = {'stage': stage, 'initial_state': state,
                      'screenshots': [session.capture('started' if stage == 'new' else 'restored', state)],
                      'process': json.loads((directory / 'game-process.json').read_text()),
                      'xterm_pid': session.proc.pid}
            if stage == 'new':
                require(state['turn'] == 1, 'ordinary game did not start on turn one')
            else:
                require(state == saved_state, 'restore changed exact rendered state before any gameplay input')
                record['restore_bytes'] = compare_restore_bytes(saved_path, saved_snapshot)
            if stage != 'restore-two':
                record['movement'] = []
                for step in range(3 if stage == 'new' else 2):
                    previous = state
                    state = move_player(session, state)
                    record['movement'].append({'from': previous, 'to': state})
                    record['screenshots'].append(session.capture(f'moved-{step + 1}', state))
            snapshot = directory / 'native-save.nhgame'
            native, path = save_and_exit(session, state_root, snapshot, state)
            if identity is None:
                identity = native['identity_line']
            require(native['identity_line'] == identity, 'native identity changed across processes')
            if stage == 'restore-two':
                record['no_turn_resave'] = compare_resave(path, saved_snapshot)
            record['final_state'], record['native'] = state, native
            proof['sessions'].append(record)
            saved_state, saved_path, saved_snapshot = state, path, snapshot
        finally:
            session.close()
    require(len({item['process']['pid'] for item in proof['sessions']}) == 3,
            'restores did not use fresh native processes')
    return proof


def main(argv):
    require(len(argv) == 2, 'usage: dynahack-smoke.py OUTPUT EVIDENCE (via .sh wrapper)')
    output, evidence = map(lambda p: Path(p).resolve(), argv)
    namespaces = {}
    for kind in ('net', 'mnt', 'pid'):
        current = os.readlink(f'/proc/self/ns/{kind}')
        host = os.environ.get(f'DYNAHACK_HOST_{kind.upper()}NS')
        require(host and host != current, f'driver requires a new {kind} namespace')
        namespaces[kind] = current
    require(str(os.getuid()) == os.environ.get('DYNAHACK_HOST_UID'),
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
        evidence = Path('/tmp/dynahack-evidence')
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
    env.update(TERM='xterm-256color', LC_ALL='C.UTF-8')
    read_fd, write_fd = os.pipe()
    xlog = open(evidence / 'xvfb.log', 'wb')
    xvfb = subprocess.Popen(['Xvfb', '-displayfd', str(write_fd), '-screen', '0',
                             '1920x1200x24', '-nolisten', 'tcp', '-ac'],
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
    print('dynahack external proof: native movement/save/two exact restores/quit complete')
    return 0


if __name__ == '__main__':
    try:
        if len(sys.argv) > 1 and sys.argv[1] == '--font-reference':
            reference_terminal()
        if len(sys.argv) > 1 and sys.argv[1] == '--relay':
            sys.exit(relay(sys.argv[2:]))
        sys.exit(main(sys.argv[1:]))
    except Exception as exc:
        print(f'dynahack proof failed: {exc}', file=sys.stderr)
        sys.exit(1)
