#!/usr/bin/env python3
"""Ordinary GearHead2 UI only: two pilots, selected restore, native text saves.

No state/config injection, command-line smoke mode, input through save files, or
signal-based successful quit. Decoder claims only fields actually serialized.
"""
import codecs
import errno
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time
import tty
# Capture import/startup failures before xterm destroys its child window.
if '--terminal' in sys.argv:
    sys.stderr = open(sys.argv[2] + '/proof/terminal.log', 'w', buffering=1)

import pyte

ROWS, COLS = 25, 80
NAMES = ('OmpGearHead2Alpha', 'OmpGearHead2Beta')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True,
                                    separators=(',', ':')).encode()).hexdigest()


def save_json(path, value):
    path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


class XtermScreen(pyte.Screen):
    def set_margins(self, *parameters, private=False):
        if private:
            # CSI ? Pm r is xterm XTRESTORE (DEC private modes), NOT
            # DECSTBM. FPC emits it during native terminal teardown. xterm
            # receives the original bytes; it has no map/HUD margin effect.
            return
        return super().set_margins(*parameters)


class Session:
    def __init__(self, executable, root, number):
        self.root, self.number = root, number
        self.raw = bytearray()
        self.screen = XtermScreen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.alive = True
        env = {'HOME': str(root / 'home'), 'USER': 'OmpProof',
               'TERM': 'xterm', 'LC_ALL': 'C.UTF-8', 'PATH': '',
               'TMPDIR': str(root / 'tmp')}
        for var, directory in (('XDG_CONFIG_HOME', 'config'),
                               ('XDG_DATA_HOME', 'data'),
                               ('XDG_CACHE_HOME', 'cache'),
                               ('XDG_STATE_HOME', 'state'),
                               ('XDG_RUNTIME_DIR', 'runtime')):
            env[var] = str(root / directory)
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(executable, [executable], env)
            except BaseException:
                os._exit(127)
        os.write(1, b'\x1b[2J\x1b[H')

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def read(self, timeout=0.1):
        ready = select.select([self.fd, 0], [], [], timeout)[0]
        if 0 in ready:
            reply = os.read(0, 4096)
            if reply:
                os.write(self.fd, reply)  # Actual xterm capability replies.
        if self.fd not in ready:
            return bool(ready)
        try:
            data = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        if not data:
            return False
        self.raw.extend(data)
        require(len(self.raw) < 16000000, 'unbounded game output')
        self.stream.feed(self.decoder.decode(data))
        os.write(1, data)
        return True

    def exited(self):
        if not self.alive:
            return True
        pid, status = os.waitpid(self.pid, os.WNOHANG)
        if pid:
            self.alive = False
            self.status = os.waitstatus_to_exitcode(status)
            return True
        return False

    def wait(self, predicate, description, timeout=30):
        deadline = time.monotonic() + timeout
        while not predicate():
            self.read()
            require(not self.exited(), description + ': exited\n' + self.text())
            require(time.monotonic() < deadline,
                    description + ': timed out\n' + self.text())

    def settle(self):
        deadline = time.monotonic() + 10
        while self.read(0.3):
            require(time.monotonic() < deadline, 'terminal did not become idle')

    def send(self, keys):
        require(not self.exited(), 'game exited before input')
        os.write(self.fd, keys)
        self.read(0.2)
        self.settle()

    def expect(self, text):
        # Native framed widgets wrap independently of the neighboring panel.
        # Match their displayed text, ignoring only whitespace and box borders.
        wanted = re.sub(r'[\s|+\-]', '', text).casefold()
        def shown():
            rows = self.screen.display
            panels = ('\n'.join(rows), '\n'.join(row[55:] for row in rows),
                      '\n'.join(row[:55] for row in rows))
            return any(wanted in re.sub(r'[\s|+\-]', '', panel).casefold()
                       for panel in panels)
        self.wait(shown, text)
        self.settle()

    def snapshot(self, label):
        proof = self.root / 'proof'
        (proof / (label + '.txt')).write_text(self.text())
        cells = [[list(self.screen.buffer[y][x]) for x in range(COLS)]
                 for y in range(ROWS)]
        save_json(proof / (label + '-cells.json'), cells)
        return cells

    def capture(self):
        self.settle()
        self.snapshot('selected-restore')
        subprocess.run([os.environ['GEARHEAD2_IMPORT'], '-display',
                        os.environ['DISPLAY'], '-window', 'root',
                        str(self.root / 'proof/screenshot.png')],
                       check=True, timeout=20)
        require((self.root / 'proof/screenshot.png').read_bytes().startswith(
                b'\x89PNG\r\n\x1a\n'), 'screenshot is not PNG')

    def finish(self):
        deadline = time.monotonic() + 20
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'native Quit Game did not exit')
        self.settle()
        require(self.status == 0, 'native quit exit status ' + str(self.status))

    def close(self):
        (self.root / 'proof' / ('session-%d.raw' % self.number)).write_bytes(self.raw)
        self.snapshot('session-%d-final' % self.number)
        if self.alive and not self.exited():
            # Failure cleanup only. A signal is never accepted as successful quit.
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)


def user_files(root):
    return {str(path.relative_to(root)) for directory in
            ('home', 'work', 'config', 'data', 'cache', 'state', 'runtime', 'tmp')
            for path in (root / directory).rglob('*') if path.is_file()}


def verify_game_files(root, before):
    allowed = {'config/gearhead2/gearhead2.cfg'}
    allowed.update('state/gearhead2/savegame/' + prefix + name + '.txt'
                   for prefix in ('EGG', 'RPG', 'CHA') for name in NAMES)
    unexpected = user_files(root) - before - allowed
    require(not unexpected, 'game wrote outside native XDG contracts: ' + repr(sorted(unexpected)))


def select_item(session, label):
    """Navigate native menus by their real highlighted cell rendition."""
    session.expect(label)
    for _ in range(18):
        for y, line in enumerate(session.screen.display):
            x = line.find(label)
            if x >= 0:
                chars = [session.screen.buffer[y][column]
                         for column in range(x, x + len(label))
                         if line[column] != ' ']
                if chars and all(cell.bold or cell.fg in ('brightcyan', '00ffff')
                                 for cell in chars):
                    session.snapshot('menu-%s-%d' %
                                     (re.sub('[^a-zA-Z0-9]', '-', label), session.number))
                    session.send(b' ')
                    return
        session.send(b'2')
    raise RuntimeError('cannot locate native highlighted item: ' + label + '\n' + session.text())


def title(session):
    session.expect('Create Character')
    session.expect('Quit Game')
    require('ERROR:' not in session.text(), 'upstream reports missing game data')


def live(session, name):
    # vidmap Map_Zone: 55x19; PCStatus is in the right column. Exclude the
    # filename/title menu, which also contains the pilot name during selection.
    return ('Create Character' not in session.text()
            and name in '\n'.join(row[46:] for row in session.screen.display[:19])
            and any(row[:55].strip() for row in session.screen.display[:19]))


def enter_game(session, name):
    deadline = time.monotonic() + 40
    while not live(session, name):
        session.read()
        if '[MORE]' in session.text().upper():
            session.send(b' ')
        require(not session.exited(), 'campaign startup exited')
        require(time.monotonic() < deadline,
                'no deployed pilot/map HUD: ' + name + '\n' + session.text())
    session.settle()


def quit_game(session):
    session.send(b'Q')  # Native campaign autosave and return to title.
    title(session)
    select_item(session, 'Quit Game')  # Esc cancels title but does not exit upstream.
    session.finish()


def native_save(session, root, decoder, name, label):
    path = root / 'state/gearhead2/savegame' / ('RPG' + name + '.txt')
    before = path.stat().st_mtime_ns if path.exists() else None
    session.send(b'X')
    session.wait(lambda: path.exists() and path.stat().st_mtime_ns != before,
                 'explicit X native save')
    session.expect('The game has been saved.')
    target = root / 'proof' / (label + '.native')
    target.write_bytes(path.read_bytes())
    state = decoder.read_campaign(target)
    decoder.pilot(state, name)  # Exactly one matching deployed actor.
    require(state['width'] > 0 and state['height'] > 0 and state['actors'],
            'save is not an active native RPG campaign')
    save_json(root / 'proof' / (label + '.json'), state)
    return state


def coordinates(decoder, state, name):
    actor = decoder.pilot(state, name)
    require('-1,0' in actor['na'] and '-1,1' in actor['na'],
            'pilot lacks native map coordinates')
    return [actor['na']['-1,0'], actor['na']['-1,1']]


def floor_directions(decoder, state, name):
    """Observe native state to choose ordinary inputs, never rewrite it."""
    x, y = coordinates(decoder, state, name)
    # locale.pp TileIndex: X + (Y-1)*width - 1. Floor/Threshold/Carpet/
    # WoodenFloor/TileFloor are flat walkable indoor TerrMan entries.
    floors = {14, 15, 16, 19, 21}
    occupied = {(gear['na'].get('-1,0'), gear['na'].get('-1,1'))
                for gear in state['actors']}
    directions = ((b'6', 1, 0), (b'4', -1, 0), (b'8', 0, -1), (b'2', 0, 1),
                  (b'9', 1, -1), (b'7', -1, -1), (b'3', 1, 1), (b'1', -1, 1))
    safe = []
    for key, dx, dy in directions:
        tx, ty = x + dx, y + dy
        if not (1 <= tx <= state['width'] and 1 <= ty <= state['height']):
            continue
        index = tx + (ty - 1) * state['width'] - 1
        if ((tx, ty) not in occupied and state['map']['visible'][index]
                and state['map']['terrain'][index] in floors):
            safe.append(key)
    # All eight are legal native commands; if the observer has no known plain
    # floor, retain bounded attempts with explicit native modal cancellation.
    return safe + [key for key, _, _ in directions if key not in safe]


def stable_cells(session):
    # All native map and right-column HUD cells incl rendition, except console
    # rows 20-24 (save/load prose differs). Same fresh-session viewport each time.
    raw = [[session.screen.buffer[y][x] for x in range(COLS)]
           for y in range(19)]
    save_json(session.root / 'proof' /
              ('session-%d-map-hud-raw.json' % session.number),
              [[list(cell) for cell in row] for row in raw])
    # Resolve only terminal defaults against the explicitly configured xterm
    # palette. Preserve every glyph, foreground/background and rendition flag.
    return [[list(cell._replace(fg='white' if cell.fg == 'default' else cell.fg,
                               bg='black' if cell.bg == 'default' else cell.bg))
             for cell in row] for row in raw]


def play(executable, root, decoder):
    saves = root / 'state/gearhead2/savegame'
    expected = None
    expected_cells = None
    receipt = {'upstream': 'v0.701',
               'commit': '415dee8d8730ef1ed8adfd741b1a2b2fa201c2e7',
               'offline': 'user/net/pid/mount namespace; /gnu/store bind-remounted read-only',
               'cell_comparison': 'Exact glyphs, effective configured white/black '
                                  'palette colors and all rendition attributes; '
                                  'raw cells retained separately, not CSI encoding equality.',
               'limits': ['Only native serialized campaign state, not RNG or UI caches.',
                          'Screenshot is the real live Xvfb xterm, not a transcript renderer.',
                          'Title Esc cancels upstream; native Quit Game exits status zero.'],
               'pilots': [], 'restores': [], 'movement': None}
    # Xvfb/xterm startup is complete; exclude only existing helper files.
    files_before = user_files(root)
    for number, name in enumerate(NAMES, 1):
        session = Session(executable, root, number)
        try:
            title(session)
            select_item(session, 'Create Character')
            session.expect('Select Mode')
            select_item(session, 'Basic Mode')
            session.expect('Male')
            select_item(session, 'Male')
            session.expect('Select Romantic Interest')
            select_item(session, 'Not looking at all')
            session.expect('Enter a name for this character')
            session.send(name.encode() + b'\r')
            title(session)
            egg = saves / ('EGG' + name + '.txt')
            require(egg.is_file(), 'native character creation did not write EGG')
            (root / 'proof' / egg.name).write_bytes(egg.read_bytes())
            select_item(session, 'Start RPG Campaign')
            select_item(session, egg.name)
            # PLOT_CORE intro Alert -> YesNoMenu('', '') is a real modal even
            # though it draws a deployed pilot and map beneath it. Space is
            # SelectMenu's native accept key (arenascript.pp:641-665).
            session.expect("It's another normal day")
            session.snapshot('native-introduction-' + name)
            session.send(b' ')
            enter_game(session, name)
            state = native_save(session, root, decoder, name, 'initial-' + name)
            if name == NAMES[0]:
                expected = state
                expected_cells = stable_cells(session)
                save_json(root / 'proof/initial-map-hud.json', expected_cells)
            quit_game(session)
            receipt['pilots'].append({'name': name, 'state_sha256': digest(state),
                                      'native_exit_status': session.status})
        finally:
            session.close()
    require(len(list(saves.glob('RPG*.txt'))) == 2,
            'selected restore proof requires exactly two independently named campaigns')
    # The beta campaign was saved last. Every load below must explicitly select
    # alpha from the real two-file menu, never accidental newest-save autoload.
    name = NAMES[0]
    for number in range(3, 5):
        session = Session(executable, root, number)
        try:
            title(session)
            select_item(session, 'Load RPG Campaign')
            session.expect('Select campaign file to load.')
            require(('RPG' + NAMES[1] + '.txt') in session.text(),
                    'restore chooser is missing the independently saved beta campaign')
            select_item(session, 'RPG' + name + '.txt')
            enter_game(session, name)
            state = native_save(session, root, decoder, name, 'selected-%d' % number)
            cells = stable_cells(session)
            save_json(root / 'proof' / ('selected-%d-map-hud.json' % number), cells)
            if number == 3:
                session.capture()
            require(state == expected,
                    'selected no-action restore differs from original explicit X save '
                    'in full canonical native state; compare retained initial/selected-%d '
                    'JSON (no fields excluded)' % number)
            require(cells == expected_cells,
                    'selected no-action restore changed native map/HUD cells')
            receipt['restores'].append({'selected_name': name,
                                        'state_sha256': digest(state),
                                        'map_hud_sha256': digest(cells),
                                        'full_serialized_equality': True})
            if number == 4:
                origin = coordinates(decoder, state, name)
                attempts = []
                for key in floor_directions(decoder, state, name) * 2:
                    session.send(key)
                    if 'Press [/] to switch between the' in session.text():
                        session.snapshot('movement-inventory-%02d' % len(attempts))
                        # Backpack DoInvMenu returns N=-1 on native Esc and
                        # RealBackpack exits; map redraw is caller-owned.
                        session.send(b'\x1b')
                        session.wait(lambda: live(session, name) and
                                     'Press [/] to switch between the' not in session.text(),
                                     'native inventory cancellation back to map')
                    moved = native_save(session, root, decoder, name,
                                        'move-%02d' % len(attempts))
                    position = coordinates(decoder, moved, name)
                    attempts.append({'key': key.decode(), 'position': position,
                                     'time': moved['time']})
                    if position != origin and moved['time'] > state['time']:
                        break
                receipt['movement'] = {'origin': origin, 'initial_time': state['time'],
                                       'attempts': attempts}
                require(position != origin and moved['time'] > state['time'],
                        'bounded ordinary movement did not change coordinates and advance time')
            quit_game(session)
        finally:
            session.close()
    verify_game_files(root, files_before)
    require((root / 'config/gearhead2/gearhead2.cfg').is_file(),
            'ordinary launcher did not persist native XDG config')
    save_json(root / 'proof/receipt.json', receipt)


def main(executable, root, decoder_path):
    root = Path(root).resolve()
    for directory in ('home', 'tmp', 'work', 'proof', 'config', 'data',
                      'cache', 'state', 'runtime'):
        (root / directory).mkdir(mode=0o700, exist_ok=True)
    if '--terminal' in sys.argv:
        sys.stderr = (root / 'proof/terminal.log').open('w', buffering=1)
        original = termios.tcgetattr(0)
        tty.setraw(0)
        try:
            spec = importlib.util.spec_from_file_location('native_save', decoder_path)
            decoder = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(decoder)
            play(executable, root, decoder)
        except BaseException as error:
            (root / 'proof/failure.txt').write_text(str(error) + '\n')
            raise
        finally:
            termios.tcsetattr(0, termios.TCSANOW, original)
        return
    read_fd, write_fd = os.pipe()
    server = terminal = None
    try:
        with (root / 'proof/xvfb.log').open('wb') as log:
            server = subprocess.Popen([os.environ['GEARHEAD2_XVFB'], '-displayfd',
                                       str(write_fd), '-screen', '0', '1024x768x24',
                                       '-nolisten', 'tcp', '-ac'],
                                      pass_fds=(write_fd,), stdout=log, stderr=log)
        os.close(write_fd)
        write_fd = -1
        require(select.select([read_fd], [], [], 20)[0], 'Xvfb no display')
        display = ':' + os.read(read_fd, 100).decode().strip()
        require(re.fullmatch(r':\d+', display), 'invalid Xvfb display')
        env = dict(os.environ, DISPLAY=display, HOME=str(root / 'home'),
                   TMPDIR=str(root / 'tmp'), XDG_RUNTIME_DIR=str(root / 'runtime'))
        with (root / 'proof/xterm.log').open('wb') as log:
            terminal = subprocess.Popen([os.environ['GEARHEAD2_XTERM'], '-display',
                                         display, '-geometry', '%dx%d+0+0' % (COLS, ROWS),
                                         '-fg', 'white', '-bg', 'black',
                                         '-xrm', 'XTerm*color7: white',
                                         '-xrm', 'XTerm*color0: black',
                                         '-fn', 'fixed', '-xrm',
                                         'XTerm*allowTitleOps: false', '-e',
                                         sys.executable, '-B', str(Path(__file__).resolve()),
                                         executable, str(root), decoder_path, '--terminal'],
                                        env=env, stdout=log, stderr=log)
        status = terminal.wait(timeout=270)
        failure = root / 'proof/failure.txt'
        require(status == 0 and (root / 'proof/receipt.json').is_file(),
                'xterm proof failed (status %s): %s' %
                (status, failure.read_text() if failure.exists() else
                 (root / 'proof/xterm.log').read_text()))
    finally:
        os.close(read_fd)
        if write_fd != -1:
            os.close(write_fd)
        for process in (terminal, server):
            if process and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3])
