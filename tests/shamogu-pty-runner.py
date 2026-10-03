#!/usr/bin/env python3
"""Drive unmodified Shamogu; retain native saves and a real xterm screenshot.

The shell owns realization and the offline namespace. This consumer only sends
ordinary gameplay keys. No patched game entry point or synthetic save state.
"""
import codecs
import errno
import fcntl
import hashlib
# xterm normally destroys its window on child failure. Preserve even import
# and terminal setup failures before the gameplay exception handler exists.
import sys
if '--terminal' in sys.argv:
    sys.stderr = open(sys.argv[2] + '/proof/terminal.log', 'w', buffering=1)
import json
import os
from pathlib import Path
import re
import select
import signal
import struct
import subprocess
import termios
import tty
import time

import pyte

ROWS, COLS = 24, 80


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class Session:
    def __init__(self, executable, root, number):
        self.raw = bytearray()
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.alive = True
        self.root, self.number = root, number
        env = {'HOME': str(root / 'home'), 'USER': 'OmpProof',
               'TERM': 'xterm-256color', 'LC_ALL': 'C.UTF-8', 'PATH': '',
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
                os.execve(executable, [executable, '-n'], env)
            except BaseException:
                os._exit(127)
        # Clear the actual xterm too; all subsequent screen bytes are game output.
        os.write(1, b'\x1b[2J\x1b[H')

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def read(self, timeout=0.1):
        ready = select.select([self.fd, 0], [], [], timeout)[0]
        if 0 in ready:
            # Forward xterm's actual terminal capability/query replies to the
            # game PTY. No manufactured terminal handshake or game input.
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
        require(len(self.raw) < 4000000, 'unbounded game output')
        self.stream.feed(self.decoder.decode(data))
        os.write(1, data)  # xterm renders the real running game's terminal stream.
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
            require(not self.exited(), description + ': game exited\n' + self.text())
            require(time.monotonic() < deadline, description + ': timed out\n' + self.text())

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(0.2):
            require(time.monotonic() < deadline, 'terminal did not become idle')

    def send(self, keys):
        require(not self.exited(), 'game exited before input')
        os.write(self.fd, keys)
        self.read(0.2)
        self.settle()

    def live(self):
        return bool(re.search(r'L:1\s+T:\d+', self.text())) and 'HP:' in self.text()

    def turns(self):
        found = re.search(r'L:1\s+T:(\d+)', self.text())
        require(found is not None, 'missing native turn status')
        return int(found[1])

    def state_screen(self):
        # Rows 0-1 are transient logs. Compare each native map/HUD character
        # and terminal rendition attribute, not just a text-only snapshot.
        return [[tuple(self.screen.buffer[y][x]) for x in range(COLS)]
                for y in range(2, ROWS)]

    def capture(self):
        self.settle()
        proof = self.root / 'proof'
        (proof / 'screen.txt').write_text(self.text())
        (proof / 'screen.raw').write_bytes(self.raw)
        # A screenshot of the actual X server containing xterm, not a transcript
        # renderer. This occurs while the loaded game remains live at its prompt.
        subprocess.run([os.environ['SHAMOGU_IMPORT'], '-display',
                        os.environ['DISPLAY'], '-window', 'root',
                        str(proof / 'screenshot.png')], check=True, timeout=20)
        require((proof / 'screenshot.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n'),
                'native terminal screenshot is not PNG')

    def finish(self):
        deadline = time.monotonic() + 15
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'native quit did not exit')
        self.settle()
        require(self.status == 0, 'native quit exit status ' + str(self.status))
        (self.root / 'proof' / ('session-%d.raw' % self.number)).write_bytes(self.raw)

    def save(self):
        turn = self.turns()
        self.send(b'S')
        self.finish()
        path = self.root / 'data/shamogu/save'
        require(path.is_file(), 'missing upstream save')
        copy = self.root / 'proof' / ('save-%d.native' % self.number)
        copy.write_bytes(path.read_bytes())
        decoded = subprocess.run([str(self.root / 'shamogu-save-reader'), str(copy)],
                                 check=True, stdout=subprocess.PIPE, timeout=15)
        (self.root / 'proof' / ('save-%d.json' % self.number)).write_bytes(decoded.stdout)
        state = json.loads(decoded.stdout)
        require(state['Turn'] == turn, 'saved turn differs from live native HUD')
        return state

    def close(self):
        if self.alive and not self.exited():
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)


def play(executable, root):
    saves, screens = [], []
    for number in range(1, 6):
        session = Session(executable, root, number)
        try:
            if number == 1:
                session.wait(lambda: 'Shamogu v1.5.0' in session.text(), 'native spirit selection')
                session.send(b'\r')  # Invoke the highlighted first primary spirit.
            else:
                session.wait(lambda: 'load saved game' in session.text(), 'native restore screen')
                session.send(b'\r')  # Dismiss load screen; this does not consume a turn.
            session.wait(session.live, 'native playable map and HUD')
            session.settle()
            if number in (2, 4):
                before = session.turns()
                session.send(b'.')  # Documented wait action, exactly one turn.
                session.wait(lambda: session.live() and session.turns() == before + 1,
                             'one native turn after wait')
            if number == 5:
                session.capture()  # Real running loaded game, before quitting.
            screens.append(session.state_screen())
            (root / 'proof' / ('screen-%d.cells.json' % number)).write_text(
                json.dumps(screens[-1]) + '\n')
            saves.append(session.save())
        finally:
            session.close()
    require(saves[1] == saves[2], 'first no-action restart changed decoded native state')
    require(saves[3] == saves[4], 'second no-action restart changed decoded native state')
    require(screens[1] == screens[2], 'first restart changed exact map/HUD cells')
    require(screens[3] == screens[4], 'second restart changed exact map/HUD cells')
    require([s['Turn'] for s in saves] == [0, 1, 1, 2, 2], 'native wait turn sequence differs')
    require([s['Stats']['Waits'] for s in saves] == [0, 1, 1, 2, 2], 'native wait counter differs')
    require(all(s['Version'] == 'v1.5.0' and s['Map']['Level'] == 1 for s in saves),
            'wrong native save version/level')
    positions = [s['Entities'][8]['P'] for s in saves]
    require(all(p == positions[0] for p in positions), 'waiting changed player position')
    session = Session(executable, root, 6)
    try:
        session.wait(lambda: 'load saved game' in session.text(), 'final native restore screen')
        session.send(b'\r')
        session.wait(session.live, 'final native loaded game')
        session.send(b'Q')
        session.wait(lambda: 'quit without saving?' in session.text() and '[Confirm]' in session.text(),
                     'native quit confirmation')
        session.send(b'Y')
        session.finish()
        require(not (root / 'data/shamogu/save').exists(), 'native quit did not remove save')
    finally:
        session.close()
    # All game writes must remain in the isolated XDG data directory. The
    # decoder/cache/proof files belong to the external helper, not the game.
    for name in ('home', 'work', 'config', 'cache', 'state', 'runtime', 'tmp'):
        require(not any(p.is_file() for p in (root / name).rglob('*')),
                'unexpected game state outside XDG data: ' + name)
    files = sorted(str(p.relative_to(root / 'data')) for p in (root / 'data').rglob('*') if p.is_file())
    require(all(f in ('shamogu/logs.txt', 'shamogu/config', 'shamogu/replay',
                      'shamogu/dump.txt') for f in files), 'unexpected native data files: ' + str(files))
    receipt = {'version': 'v1.5.0', 'turns': [s['Turn'] for s in saves],
               'waits': [s['Stats']['Waits'] for s in saves], 'player_positions': positions,
               'state_scope': 'all native gob Game fields: entities/roles/effects, terrain/knowledge, clouds/noise/waypoints, FOV/path caches, procedure info/logs/mods, Stats, turn/version/wizard/direction/previous position; exact map/HUD characters and rendition attributes',
               'state_limits': 'upstream gob excludes unexported runtime/UI/RNG state; configuration is separate',
               'first_exact_restore': True, 'second_exact_restore': True,
               'native_quit_deleted_save': True, 'native_data_files': files,
               'screenshot': 'screenshot.png', 'screen': 'screen.txt',
               'save_sha256': [hashlib.sha256((root / 'proof' / ('save-%d.native' % n)).read_bytes()).hexdigest()
                               for n in range(1, 6)]}
    (root / 'proof/receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')


def main(executable, root):
    root = Path(root).resolve()
    for directory in ('home', 'tmp', 'work', 'proof', 'config', 'data', 'cache', 'state', 'runtime'):
        (root / directory).mkdir(mode=0o700, exist_ok=True)
    if '--terminal' in sys.argv:
        original = termios.tcgetattr(0)
        tty.setraw(0)
        try:
            play(executable, root)
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
            server = subprocess.Popen([os.environ['SHAMOGU_XVFB'], '-displayfd', str(write_fd),
                                       '-screen', '0', '1024x768x24', '-nolisten', 'tcp', '-ac'],
                                      pass_fds=(write_fd,), stdout=log, stderr=log)
        os.close(write_fd)
        write_fd = -1
        require(select.select([read_fd], [], [], 20)[0], 'Xvfb did not publish display')
        display = ':' + os.read(read_fd, 100).decode().strip()
        require(re.fullmatch(r':\d+', display), 'invalid Xvfb display')
        env = dict(os.environ, DISPLAY=display, HOME=str(root / 'home'),
                   TMPDIR=str(root / 'tmp'), XDG_RUNTIME_DIR=str(root / 'runtime'))
        with (root / 'proof/xterm.log').open('wb') as log:
            terminal = subprocess.Popen([os.environ['SHAMOGU_XTERM'], '-display', display,
                                         '-geometry', '%dx%d+0+0' % (COLS, ROWS), '-fn', 'fixed',
                                         '-xrm', 'XTerm*allowTitleOps: false',
                                         '-e', sys.executable, '-B', str(Path(__file__).resolve()),
                                         executable, str(root), '--terminal'],
                                        env=env, stdout=log, stderr=log)
        status = terminal.wait(timeout=150)
        failure = root / 'proof/failure.txt'
        require(status == 0 and (root / 'proof/receipt.json').is_file(),
                'xterm gameplay failed (status %s): %s' %
                (status, failure.read_text() if failure.exists()
                 else ((root / 'proof/terminal.log').read_text()
                       if (root / 'proof/terminal.log').exists()
                       else (root / 'proof/xterm.log').read_text())))
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
    main(sys.argv[1], sys.argv[2])
