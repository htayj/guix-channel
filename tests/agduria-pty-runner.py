#!/usr/bin/env python3
"""Ordinary Agduria gameplay observed through a PTY and real live xterm.

Only human keys are sent. No installed smoke entry point, changed RNG, injected
world, save surrogate, synthetic terminal rendering or network is used. Upstream
has no persistence; the proof intentionally makes no save/load claim.
"""
import codecs
import ctypes
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import select
import signal
import socket
import struct
import subprocess
import sys
import termios
import time
import traceback
import tty

if '--terminal' in sys.argv:
    sys.stderr = (Path(sys.argv[3]) / 'terminal.log').open('w', buffering=1)

import pyte

ROWS, COLS = 24, 80


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


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
        root, evidence = Path('/tmp/agduria-root'), Path('/tmp/agduria-evidence')
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
            'network namespace has non-loopback interfaces')
    mounts = [line for line in Path('/proc/self/mountinfo').read_text().splitlines()
              if line.split()[4] == '/gnu/store']
    require(mounts and 'ro' in mounts[-1].split()[5].split(','),
            'store mount is not read-only')
    require(os.getuid() == int(os.environ['AGDURIA_EXPECTED_UID'])
            and os.getgid() == int(os.environ['AGDURIA_EXPECTED_GID']),
            'namespace changed the caller UID/GID')
    return root, evidence


class Session:
    def __init__(self, executable, root, evidence):
        self.raw = bytearray()
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.alive = True
        self.evidence = evidence
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color',
               'LC_ALL': 'C.UTF-8', 'PATH': '', 'TMPDIR': str(root / 'tmp')}
        for variable, directory in (('XDG_CONFIG_HOME', 'config'),
                                    ('XDG_DATA_HOME', 'data'),
                                    ('XDG_CACHE_HOME', 'cache'),
                                    ('XDG_STATE_HOME', 'state'),
                                    ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / directory)
        version = subprocess.run([executable, '--version'], env=env,
                                 capture_output=True, check=True, timeout=10)
        require(version.stdout == b'Agduria 0.0.1\n' and not version.stderr,
                'installed launcher version differs')
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
                os.write(self.fd, reply)
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
        require(len(self.raw) < 4000000, 'unbounded native terminal output')
        self.stream.feed(self.decoder.decode(data))
        os.write(1, data)  # The actual xterm renders unchanged live game bytes.
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

    def wait(self, predicate, description, timeout=20):
        deadline = time.monotonic() + timeout
        while not predicate():
            self.read()
            require(not self.exited(), description + ': native game exited\n' + self.text())
            require(time.monotonic() < deadline, description + ': timed out\n' + self.text())

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(0.25):
            require(time.monotonic() < deadline, 'native terminal never became idle')

    def send(self, keys):
        require(not self.exited(), 'game exited before input')
        os.write(self.fd, keys)
        self.read(0.2)
        self.settle()

    def live(self):
        players = [(x, y) for y in range(1, ROWS - 1) for x in range(COLS)
                   if self.screen.buffer[y][x].data == '@']
        if len(players) != 1:
            return None
        return {'player_cell': list(players[0]), 'map': self.screen.display[1:-1]}

    def capture(self, name):
        self.settle()
        (self.evidence / (name + '.txt')).write_text(self.text())
        (self.evidence / (name + '.raw')).write_bytes(self.raw)
        return self.live()

    def inspect(self, name):
        # Upstream has no HUD. Its ordinary D/v observer starts its cursor at
        # the real player; never move that cursor or use its terrain-edit keys.
        self.send(b'D')
        self.wait(lambda: 'Debug commands' in self.text() and 'v) view level' in self.text(),
                  'native debug observer menu')
        self.send(b'v')
        self.wait(lambda: re.search(r'Pos: (-?\d+),(-?\d+) Camera: (-?\d+), (-?\d+)',
                                   self.text()) is not None and self.live() is not None,
                  'native coordinate observer')
        observed = re.search(r'Pos: (-?\d+),(-?\d+) Camera: (-?\d+), (-?\d+)', self.text())
        state = self.capture(name + '-observer')
        state.update(position=[int(observed[1]), int(observed[2])],
                     camera=[int(observed[3]), int(observed[4])])
        require(state['player_cell'] == [state['position'][0] - state['camera'][0],
                                         state['position'][1] - state['camera'][1] + 1],
                'rendered @ does not match native player coordinate/camera')
        self.send(b'\x08')
        self.wait(lambda: 'Debug commands' in self.text(), 'backspace exits native observer')
        self.send(b'\x08')
        self.wait(lambda: self.live() is not None and 'Debug commands' not in self.text(),
                  'backspace returns to native gameplay')
        require(self.live() == {'player_cell': state['player_cell'], 'map': state['map']},
                'coordinate observer changed native map/player')
        self.capture(name)
        return state

    def finish(self):
        deadline = time.monotonic() + 15
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'native Q command did not exit')
        self.settle()
        require(self.status == 0, 'native Q exit status ' + str(self.status))

    def close(self):
        (self.evidence / 'session.raw').write_bytes(self.raw)
        if self.alive and not self.exited():
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)


def play(output, root, evidence):
    session = Session(str(output / 'bin/agduria'), root, evidence)
    try:
        session.wait(lambda: 'Version 0.0.1' in session.text()
                     and 'p) Play' in session.text(), 'native title menu')
        session.capture('title')
        session.send(b'p')
        session.wait(lambda: session.live() is not None, 'native playable map/player')
        before = session.inspect('initial')
        moves = []
        # Try ordinary cardinal commands until an actual movement succeeds.
        # Reject blocked/unknown commands rather than claiming any input is proof.
        for key, dx, dy in ((b'\x1bOC', 1, 0), (b'\x1bOD', -1, 0),
                            (b'\x1bOA', 0, -1), (b'\x1bOB', 0, 1)):
            origin = before
            session.send(key)
            session.wait(lambda: session.live() is not None, 'map after cardinal input')
            current = session.inspect('movement')
            if current['position'] != origin['position']:
                require(current['position'] == [origin['position'][0] + dx,
                                                origin['position'][1] + dy],
                        'cardinal movement disagrees with native position')
                require(current['map'] != origin['map'], 'movement did not change rendered map')
                moves.append({'keys_hex': key.hex(), 'from': origin['position'],
                              'native_player_cell': current['player_cell'],
                              'native_camera': current['camera'],
                              'to': current['position']})
                reverse = {b'\x1bOC': b'\x1bOD', b'\x1bOD': b'\x1bOC',
                           b'\x1bOA': b'\x1bOB', b'\x1bOB': b'\x1bOA'}[key]
                session.capture('moved')
                session.send(reverse)
                returned = session.inspect('returned')
                require(returned['position'] == before['position'],
                        'reciprocal native movement did not restore player coordinates')
                moves.append({'keys_hex': reverse.hex(), 'from': current['position'],
                              'to': returned['position'],
                              'native_player_cell': returned['player_cell'],
                              'native_camera': returned['camera']})
                break
        require(moves, 'no cardinal key changed the actual native player position')
        moved = session.capture('before-redraw')
        session.send(b'R')
        session.wait(lambda: session.live() is not None, 'native R redraw')
        redrawn = session.capture('redrawn')
        require(redrawn == moved, 'native R stub redraw changed the dungeon/player')
        session.send(b'T')
        session.wait(lambda: 'Insect: ant' in session.text(), 'native T creature-system test')
        session.capture('creature-test')
        session.send(b'q')
        session.wait(lambda: session.live() is not None, 'map after dismissing native T test')
        final = session.capture('gameplay')
        require(final == redrawn, 'non-gameplay T demonstration changed the dungeon/player')
        # Capture the live real xterm, not an ANSI-to-image renderer.
        subprocess.run([os.environ['AGDURIA_IMPORT'], '-display', os.environ['DISPLAY'],
                        '-window', 'root', str(evidence / 'screenshot.png')],
                       check=True, timeout=20)
        image = (evidence / 'screenshot.png').read_bytes()
        require(image.startswith(b'\x89PNG\r\n\x1a\n'), 'native xterm capture is not PNG')
        session.send(b'Q')
        session.finish()
        for name in ('home', 'work', 'config', 'data', 'cache', 'state', 'runtime', 'tmp'):
            require(not any((root / name).iterdir()), 'unexpected native user state in ' + name)
        record = {'status': 'passed', 'version': '0.0.1', 'native_exit_status': session.status,
                  'initial': before, 'moves': moves, 'redraw_preserved_gameplay': True,
                  'remake': 'R command is an upstream empty stub; redraw only, no regeneration claim',
                  'creature_test': 'Insect: ant', 'creature_test_preserved_gameplay': True,
                  'screenshot': 'screenshot.png', 'screenshot_sha256': hashlib.sha256(image).hexdigest(),
                  'persistence': 'unsupported by pinned upstream; no save/load claim',
                  'user_state_empty': True, 'same_uid': os.getuid(), 'same_gid': os.getgid(),
                  'network_interfaces': [name for _, name in socket.if_nameindex()],
                  'store_read_only': True}
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')
    finally:
        session.close()


def main(output, root, evidence):
    output, root, evidence = map(lambda path: Path(path).resolve(), (output, root, evidence))
    if '--terminal' in sys.argv:
        original = termios.tcgetattr(0)
        tty.setraw(0)
        try:
            play(output, root, evidence)
        except BaseException:
            (evidence / 'failure.txt').write_text(traceback.format_exc())
            raise
        finally:
            termios.tcsetattr(0, termios.TCSANOW, original)
        return
    root, evidence = isolate(root, evidence)
    for directory in ('home', 'tmp', 'work', 'config', 'data', 'cache', 'state', 'runtime'):
        (root / directory).mkdir(mode=0o700)
    for notice in ('LICENSE.md', 'README.md'):
        require((output / 'share/doc/agduria' / notice).is_file(), 'missing upstream notice: ' + notice)
    for file in output.rglob('*'):
        if file.is_file():
            require(file.stat().st_mode & 0o222 == 0, 'writable installed output file: ' + str(file))
    read_fd, write_fd = os.pipe()
    server = terminal = None
    try:
        with (evidence / 'xvfb.log').open('wb') as log:
            server = subprocess.Popen([os.environ['AGDURIA_XVFB'], '-displayfd', str(write_fd),
                                       '-screen', '0', '1024x768x24', '-nolisten', 'tcp', '-ac',
                                       '-fp', os.environ['AGDURIA_FONT']],
                                      pass_fds=(write_fd,), stdout=log, stderr=log)
        os.close(write_fd)
        write_fd = -1
        require(select.select([read_fd], [], [], 20)[0], 'Xvfb did not publish display')
        display = ':' + os.read(read_fd, 100).decode().strip()
        require(re.fullmatch(r':\d+', display), 'Xvfb returned invalid display')
        env = dict(os.environ, DISPLAY=display, HOME=str(root / 'home'),
                   TMPDIR=str(root / 'tmp'), XDG_RUNTIME_DIR=str(root / 'runtime'))
        with (evidence / 'xterm.log').open('wb') as log:
            terminal = subprocess.Popen([os.environ['AGDURIA_XTERM'], '-display', display,
                                         '-geometry', '80x24+0+0', '-fn', 'fixed',
                                         '-xrm', 'XTerm*allowTitleOps: false',
                                         '-e', sys.executable, '-B', str(Path(__file__).resolve()),
                                         str(output), str(root), str(evidence), '--terminal'],
                                        env=env, stdout=log, stderr=log)
        status = terminal.wait(timeout=150)
        require(status == 0 and (evidence / 'evidence.json').is_file(),
                'xterm native gameplay failed (status %s): %s' %
                (status, (evidence / 'failure.txt').read_text()
                 if (evidence / 'failure.txt').exists() else (evidence / 'terminal.log').read_text()
                 if (evidence / 'terminal.log').exists() else (evidence / 'xterm.log').read_text()))
    except BaseException:
        (evidence / 'evidence.json').write_text(json.dumps(
            {'status': 'failed', 'error': traceback.format_exc()}, indent=2) + '\n')
        raise
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
                    process.wait(timeout=5)


if __name__ == '__main__':
    main(*sys.argv[1:4])
