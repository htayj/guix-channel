#!/usr/bin/env python3
"""Observe the unmodified Space Privateers 0.1.0.0 / LambdaHack 0.2.14 TUI.

X11 events enter a real xterm running the native Vty frontend. The relay only
forwards/records terminal bytes; pyte reads them and never draws evidence.
Screenshots are ImageMagick captures of that actual X window. No game source,
user configuration, saves or content is modified to make the proof pass.
"""
import codecs
import ctypes
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import termios
import time
import traceback
import tty
import zlib


COLS, ROWS = 80, 24


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def write_all(fd, data):
    while data:
        written = os.write(fd, data)
        require(written > 0, 'terminal write made no progress')
        data = data[written:]


def relay(arguments):
    executable, directory, *flags = arguments
    (Path(directory) / 'relay-started.json').write_text(json.dumps({
        'executable': executable, 'arguments': flags,
        'stdin_is_tty': os.isatty(0), 'stdout_is_tty': os.isatty(1),
        'term': os.environ.get('TERM'), 'python': sys.executable}, indent=2) + '\n')
    directory = Path(directory)
    pid, master = pty.fork()
    if pid == 0:
        try:
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
            os.execv(executable, [executable, *flags])
        except BaseException:
            (directory / 'game-exec-error.txt').write_text(traceback.format_exc())
            traceback.print_exc()
            os._exit(1)
    previous = termios.tcgetattr(0)
    tty.setraw(0)
    try:
        with (directory / 'terminal.raw').open('wb', buffering=0) as raw, \
                (directory / 'input.raw').open('wb', buffering=0) as inputs:
            while True:
                ready, _, _ = select.select([0, master], [], [], 1)
                if master in ready:
                    try:
                        data = os.read(master, 65536)
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        break
                    if not data:
                        break
                    raw.write(data)
                    write_all(1, data)
                if 0 in ready:
                    data = os.read(0, 4096)
                    if not data:
                        os.kill(pid, signal.SIGHUP)
                        break
                    inputs.write(data)
                    write_all(master, data)
    finally:
        termios.tcsetattr(0, termios.TCSANOW, previous)
        os.close(master)
    _, status = os.waitpid(pid, 0)
    code = os.waitstatus_to_exitcode(status)
    (directory / 'exit-status.txt').write_text(str(code) + '\n')
    return code


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=3)


class Session:
    def __init__(self, name, executable, evidence, env, tools, flags):
        import pyte
        self.directory = evidence / name
        self.directory.mkdir()
        self.raw_path = self.directory / 'terminal.raw'
        self.raw_path.touch()
        self.offset = 0
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.env, self.tools = env, tools
        self.events, self.images = [], []
        self.window = None
        self.log = (self.directory / 'xterm.log').open('wb')
        self.process = subprocess.Popen(
            [tools['xterm'], '-hold', '-geometry', '80x24', '-fa', 'DejaVu Sans Mono',
             '-fs', '14', '-bg', 'black', '-fg', 'white', '-b', '0',
             '-xrm', 'XTerm*allowSendEvents: true', '-xrm', 'XTerm*cursorBlink: false',
             '-title', 'Space Privateers native ' + name, '-e', sys.executable,
             '-B', str(Path(__file__).resolve()), '--relay', str(executable),
             str(self.directory), *flags], env=env, cwd=env['SP_WORK'],
            stdout=self.log, stderr=self.log, start_new_session=True)

    def tool(self, *args, check=True):
        return subprocess.run(args, env=self.env, check=check, timeout=10,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def pump(self):
        with self.raw_path.open('rb') as stream:
            stream.seek(self.offset)
            data = stream.read()
        self.offset += len(data)
        require(self.offset < 16000000, 'excessive terminal output')
        self.stream.feed(self.decoder.decode(data))
        return len(data)

    def text(self):
        self.pump()
        return '\n'.join(self.screen.display)

    def key(self, key):
        require(self.window is not None, 'no native X11 window')
        self.tool(self.tools['xdotool'], 'windowfocus', '--sync', self.window)
        self.tool(self.tools['xdotool'], 'key', '--clearmodifiers', key)
        self.events.append({'key': key, 'time_ns': time.monotonic_ns()})

    def wait(self, predicate, label, timeout=25, paging=False):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            text = self.text()
            relay_error = self.directory / 'relay-error.txt'
            require(not relay_error.exists(), 'terminal relay failed: '
                    + (relay_error.read_text() if relay_error.exists() else ''))
            exit_path = self.directory / 'exit-status.txt'
            require(not exit_path.exists(), 'native game exited while awaiting ' + label
                    + ': ' + (exit_path.read_text().strip() if exit_path.exists() else ''))
            require(self.process.poll() is None, 'xterm exited while awaiting ' + label
                    + ': status ' + str(self.process.poll())
                    + '; see xterm.log and relay-started.json')
            if self.window is None:
                result = self.tool(self.tools['xdotool'], 'search', '--onlyvisible',
                                   '--pid', str(self.process.pid), check=False)
                if result.returncode == 0 and result.stdout.split():
                    self.window = result.stdout.split()[-1].decode()
            if self.window is not None:
                if paging and '--more--' in text:
                    self.key('space')
                    time.sleep(0.2)
                elif predicate(text):
                    self.settle()
                    return self.text()
            time.sleep(0.05)
        (self.directory / 'failure-screen.txt').write_text(self.text())
        raise RuntimeError('timed out awaiting ' + label)

    def settle(self):
        end, quiet = time.monotonic() + 5, time.monotonic()
        while time.monotonic() < end:
            if self.pump():
                quiet = time.monotonic()
            elif time.monotonic() - quiet > 0.4:
                return
            time.sleep(0.05)
        raise RuntimeError('native screen did not settle')

    def image(self, name):
        path = self.directory / (name + '.png')
        self.tool(self.tools['import'], '-window', self.window, str(path))
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'native X capture is not PNG')
        width, height = struct.unpack('>II', data[16:24])
        require(width >= 640 and height >= 384, 'native terminal window is too small')
        self.images.append({'path': str(path.relative_to(self.directory.parent)),
                            'sha256': digest(data), 'width': width, 'height': height})

    def gameplay(self):
        # overlayOverlay puts map rows 0..20 at terminal rows 1..21;
        # DrawClient appends arena/leader status at rows 22 and 23.
        self.wait(lambda text: 'Cursor:' in self.screen.display[22]
                  and 'Target:' in self.screen.display[23]
                  and re.search(r'\b(?:HP|H)[:}]', self.screen.display[23]),
                  'native map and leader status', paging=True)
        self.key('space')  # native Clear, does not advance time
        self.settle()
        require(self.screen.display[0].strip() == '', 'map still obscured by messages')
        positions = [(x, y - 1, cell.data)
                     for y in range(1, 22) for x in range(COLS)
                     if (cell := self.screen.buffer[y][x]).bg == 'white'
                     and cell.fg == 'black' and cell.data not in (' ', '%')]
        # DrawClient highlights ONLY the current leader with inverseVideo.
        require(len(positions) == 1, 'ambiguous native leader highlight: ' + repr(positions))
        lines = list(self.screen.display)
        require(any('.' in line or '#' in line for line in lines[1:22]),
                'missing native walkable terrain')
        return {'leader': list(positions[0]), 'map': lines[1:22],
                'arena': lines[22][:41], 'identity_status': lines[23][:41],
                'cursor_target': [lines[22][41:], lines[23][41:]]}

    def diary(self, name):
        self.key('D')
        text = self.wait(lambda text: 'You survived for' in text and 'Past messages:' in text,
                         'native diary with game time')
        (self.directory / (name + '.txt')).write_text(text + '\n')
        self.image(name)
        # historyHuman uses Miniutter.CarWs: one is 'a half-second turn',
        # whereas plural counts are decimal numbers. Local time uses tshow.
        match = re.search(r'You survived for\s+(?:a half-second turn|(\d+) half-second turns)\s*'
                          r'\(this level:\s*(\d+)\)', text)
        require(match is not None, 'cannot read native global/local turns')
        self.key('Escape')
        self.gameplay()
        return {'global_turn': 1 if match[1] is None else int(match[1]),
                'level_turn': int(match[2])}

    def possessions(self, key, name):
        self.key(key)
        container = 'in equipment' if key == 'E' else 'in inventory'
        self.wait(lambda text: container in text and ', ESC]' in text,
                  'native possession selection for ' + container)
        pages = []
        while True:
            text = self.text()
            # InventoryClient starts ISuitable, rendering the real bag and its
            # item slots. WidgetClient/Msg split long bags into --more-- pages.
            require(container in text and ', ESC]' in text,
                    'unexpected native possession selection prompt')
            pages.append(text)
            page = name + '-page-' + str(len(pages))
            (self.directory / (page + '.txt')).write_text(text + '\n')
            self.image(page)
            if '--more--' not in text:
                break
            require(len(pages) < 20, 'native possessions exceed page limit')
            self.key('space')
            self.settle()
            require(self.text() != text, 'native possession paging did not advance')
        self.key('Escape')
        self.gameplay()
        # Every exact cell/page, including item descriptions; not a hash check.
        return pages

    def snapshot(self, name):
        state = self.gameplay()
        (self.directory / (name + '-map.txt')).write_text(self.text() + '\n')
        self.image(name + '-map')
        state['time'] = self.diary(name + '-diary')
        state['equipment'] = self.possessions('E', name + '-equipment')
        state['inventory'] = self.possessions('P', name + '-inventory')
        # Observations must not consume native game time or move the leader.
        require(self.gameplay() == {k: v for k, v in state.items()
                                   if k not in ('time', 'equipment', 'inventory')},
                'read-only observations changed visible gameplay state')
        (self.directory / (name + '-state.json')).write_text(json.dumps(state, indent=2) + '\n')
        return state

    def move(self, before):
        x, y, symbol = before['leader']
        choices = [('Right', 1, 0), ('Left', -1, 0), ('Down', 0, 1), ('Up', 0, -1),
                   ('Home', -1, -1), ('Prior', 1, -1), ('End', -1, 1), ('Next', 1, 1)]
        for key, dx, dy in choices:
            nx, ny = x + dx, y + dy
            if 0 <= nx < COLS and 0 <= ny < 21 and before['map'][ny][nx] in '.#':
                self.key(key)
                self.settle()
                after = self.gameplay()
                require(after['leader'] == [nx, ny, symbol],
                        'native movement did not reach chosen adjacent floor')
                return after
        raise RuntimeError('no visibly safe adjacent floor for human movement')

    def advance_human_moves(self, baseline_time, baseline_leader, name):
        # LoopServer handles actors within 100000-tick clips; historyHuman
        # rounds to 500000-tick turns. A legal tile move can share the previous
        # displayed half-second. Send more genuine adjacent-floor moves until
        # BOTH observed clocks cross a boundary, never relax the time proof.
        for number in range(1, 13):
            moved = self.move(self.gameplay())
            observed = self.diary(name + '-move-' + str(number))
            if (observed['global_turn'] > baseline_time['global_turn']
                    and observed['level_turn'] > baseline_time['level_turn']
                    and moved['leader'] != baseline_leader):
                return
        raise RuntimeError('human movement did not advance both native clocks '
                           'and finish at a distinct position within 12 actual moves')

    def save_exit(self):
        self.key('ctrl+x')
        self.wait(lambda text: 'Really save and exit?' in text and '[yn]' in text,
                  'native save confirmation')
        self.image('save-confirmation')
        self.key('y')
        deadline = time.monotonic() + 30
        last_paged = None
        while time.monotonic() < deadline:
            text = self.text()
            if (self.directory / 'exit-status.txt').exists():
                break
            # quitFactionUI displays loot, scores, parting slides; only accept
            # actual native --more-- prompts, never arbitrary guessed inputs.
            if '--more--' in text and text != last_paged:
                self.image('exit-page-' + str(len(self.images)))
                self.key('space')
                last_paged = text
            time.sleep(0.1)
        require((self.directory / 'exit-status.txt').exists(),
                'native save/exit did not finish; see held native window and relay diagnostics')
        self.pump()
        require((self.directory / 'exit-status.txt').read_text().strip() == '0',
                'native game process reported nonzero exit')
        require(b'Restore failed' not in self.raw_path.read_bytes(), 'native restore failed')
        stop(self.process)  # -hold retains genuine failure windows, not game processes

    def close(self):
        try:
            if self.window is None and self.process.poll() is None:
                result = self.tool(self.tools['xdotool'], 'search', '--onlyvisible',
                                   '--pid', str(self.process.pid), check=False)
                if result.returncode == 0 and result.stdout.split():
                    self.window = result.stdout.split()[-1].decode()
            if self.window and self.process.poll() is None:
                self.image('final-observed-window')
        finally:
            stop(self.process)
            self.log.close()


def save_evidence(root, evidence, name):
    # Common/File.hs encodeEOF is Zlib.compress (Data.Binary.encode (a,"OK")).
    # Do not pretend a generic zlib reader is a full Haskell state decoder:
    # restore identity below comes from native visible fields and diary time.
    directory = root / 'home/.SpacePrivateers/saves'
    files = sorted(directory.glob('*.sav'))
    require(any(path.name == 'save.server.sav' for path in files), 'native server save missing')
    require(any(path.name.endswith('.ui.sav') for path in files), 'native UI client save missing')
    target = evidence / name
    target.mkdir()
    result = []
    for path in files:
        data = path.read_bytes()
        inflater = zlib.decompressobj()
        plain = inflater.decompress(data) + inflater.flush()
        require(inflater.eof and not inflater.unused_data and len(plain) > 100,
                'incomplete native compressed save: ' + path.name)
        shutil.copy2(path, target / path.name)
        result.append({'path': name + '/' + path.name, 'bytes': len(data),
                       'sha256': digest(data), 'decompressed_bytes': len(plain)})
    return result


def isolate(root, evidence):
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
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
        root, evidence = Path('/tmp/space-privateers-root'), Path('/tmp/space-privateers-evidence')
        root.mkdir()
        evidence.mkdir()
        mount('/proc/self/fd/' + str(root_fd), root, flags=4096)
        mount('/proc/self/fd/' + str(evidence_fd), evidence, flags=4096)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
    finally:
        os.close(root_fd)
        os.close(evidence_fd)
    return root, evidence


def main():
    game_out, root, xvfb, xterm, xdotool, image_import, fonts, evidence, nar = sys.argv[1:]
    game_out, root, evidence = map(Path, (game_out, root, evidence))
    record = {'status': 'running', 'consumer': 'native Vty 4.7.5 in real xterm/Xvfb',
              'output': str(game_out), 'output_nar_before': nar,
              'upstream': {'game': 'SpacePrivateers-0.1.0.0', 'engine': 'LambdaHack-0.2.14'},
              'sessions': [], 'assertions': [], 'saves': {}}
    server, session, server_log = None, None, None

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
            env[variable] = str(root / directory)
        env['SP_WORK'] = str(root / 'work')
        # Font setup is test infrastructure only, not a game-side configuration.
        fontconfig = root / 'fonts.conf'
        fontconfig.write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">'
                              '<fontconfig><dir>' + fonts + '</dir><cachedir>'
                              + str(root / 'cache/fontconfig') + '</cachedir></fontconfig>')
        env.update(FONTCONFIG_FILE=str(fontconfig), TERM='xterm',
                   DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/no-session-bus')
        tools = {'xterm': xterm, 'xdotool': xdotool, 'import': image_import}
        server_log = (evidence / 'xvfb.log').open('wb')
        read_fd, write_fd = os.pipe()
        try:
            server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                       '1280x800x24', '-nolisten', 'tcp', '-ac'],
                                      pass_fds=(write_fd,), stdout=server_log, stderr=server_log,
                                      env=env, start_new_session=True)
            os.close(write_fd)
            write_fd = None
            require(select.select([read_fd], [], [], 10)[0], 'Xvfb display allocation timed out')
            display = os.read(read_fd, 128).decode().strip()
            require(display.isdecimal(), 'Xvfb failed to allocate display')
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
        env['DISPLAY'] = ':' + display
        executable = game_out / 'bin/space-privateers'
        flags = ['--newGame', '--gameMode', 'campaign', '--setDungeonRng', '42', '--setMainRng', '42']
        session = Session('new-game', executable, evidence, env, tools, flags)
        record['sessions'].append({'name': 'new-game', 'flags': flags,
                                   'events': session.events, 'screenshots': session.images})
        initial = session.snapshot('initial')
        session.key('period')  # native macro KP_Begin => Wait; real human turn
        session.settle()
        session.gameplay()
        waited = session.diary('after-human-wait')
        require(waited['global_turn'] > initial['time']['global_turn']
                and waited['level_turn'] > initial['time']['level_turn'],
                'human wait did not advance native global and level time')
        session.advance_human_moves(waited, initial['leader'], 'first-human-movement')
        saved = session.snapshot('before-save')
        require(saved['leader'] != initial['leader'], 'human movement did not change native position')
        require(saved['time']['global_turn'] > waited['global_turn']
                and saved['time']['level_turn'] > waited['level_turn'],
                'human movement did not advance native global and level time')
        record['assertions'].append('real human wait and adjacent-floor movement advanced native turns')
        session.save_exit()
        record['saves']['first'] = save_evidence(root, evidence, 'first-saves')
        session.close()
        session = None
        # No --newGame or RNG flags on restart: native server/client restore.
        session = Session('restored-game', executable, evidence, env, tools, [])
        record['sessions'].append({'name': 'restored-game', 'flags': [],
                                   'events': session.events, 'screenshots': session.images})
        restored = session.snapshot('restored')
        for field in saved:
            require(restored[field] == saved[field], 'native restore changed visible ' + field)
        record['assertions'].append('restore exact leader, map, arena, identity/status, target, turns, equipment and inventory')
        session.key('period')
        session.settle()
        session.gameplay()
        continued = session.diary('continued-human-wait')
        require(continued['global_turn'] > restored['time']['global_turn']
                and continued['level_turn'] > restored['time']['level_turn'],
                'restored native game did not continue after human wait')
        session.advance_human_moves(continued, restored['leader'], 'continued-human-movement')
        continued_state = session.snapshot('continued-before-save')
        require(continued_state['leader'] != restored['leader']
                and continued_state['time']['global_turn'] > continued['global_turn']
                and continued_state['time']['level_turn'] > continued['level_turn'],
                'continued human movement did not change position and both native clocks')
        session.save_exit()
        record['saves']['continued'] = save_evidence(root, evidence, 'continued-saves')
        session.close()
        session = None
        session = Session('continued-restored-game', executable, evidence, env, tools, [])
        record['sessions'].append({'name': 'continued-restored-game', 'flags': [],
                                   'events': session.events, 'screenshots': session.images})
        second_restore = session.snapshot('continued-restored')
        for field in continued_state:
            require(second_restore[field] == continued_state[field],
                    'continued native restore changed visible ' + field)
        session.save_exit()
        record['assertions'].append('continued human wait/movement, second save and exact second restore')
        # Only native user state and test font cache may appear under HOME/XDG.
        require({p.name for p in (root / 'home').iterdir()} == {'.SpacePrivateers'},
                'game wrote unexpected HOME state')
        for directory in ('config', 'data', 'state'):
            require(not list((root / directory).iterdir()), 'game wrote unexpected XDG ' + directory)
        record['user_state'] = sorted(str(p.relative_to(root / 'home'))
                                      for p in (root / 'home').rglob('*') if p.is_file())
        record['isolation'] = 'private HOME/XDG/tmp; user/mount/network/PID namespaces; store read-only'
        record['status'] = 'passed'
        print('SPACE-PRIVATEERS-SMOKE: native-human-turns-save-two-restores-ok')
    except Exception as error:
        record.update(status='failed', error=str(error), traceback=traceback.format_exc())
        raise
    finally:
        try:
            if session is not None:
                session.close()
        finally:
            stop(server)
            if server_log is not None:
                server_log.close()
            report()


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--relay':
        try:
            code = relay(sys.argv[2:])
        except BaseException:
            (Path(sys.argv[3]) / 'relay-error.txt').write_text(traceback.format_exc())
            traceback.print_exc()
            code = 1
        sys.exit(code)
    main()
