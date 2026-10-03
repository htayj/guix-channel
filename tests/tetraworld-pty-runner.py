#!/usr/bin/env python3
"""Drive unmodified Tetraworld; retain native saves and a real xterm screenshot.

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

ROWS, COLS = 40, 100


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save_tree(path):
    # Native loadsave.d grammar is newline-delimited keys and nested braces.
    # Associative arrays reorder on reload: compare the complete unordered tree,
    # preserving repeated keys (notably world/store/things/thing).
    stack = [[]]
    keys = []
    for line in path.read_text().splitlines():
        line = line.strip()
        require(bool(line), 'unexpected empty native save line')
        if line == '}':
            require(len(stack) > 1, 'unbalanced native save')
            children = tuple(sorted(stack.pop()))
            stack[-1].append((keys.pop(), children))
        elif line.endswith(' {'):
            keys.append(line[:-2])
            stack.append([])
        else:
            key, value = line.split(' ', 1)
            stack[-1].append((key, value))
    require(len(stack) == 1, 'unterminated native save')
    return tuple(sorted(stack[0]))


def field(tree, key):
    values = [value for name, value in tree if name == key]
    require(len(values) == 1, 'missing/ambiguous native field ' + key)
    return values[0]


def native_player(tree):
    player = field(tree, 'player')
    store = field(field(tree, 'world'), 'store')
    position = field(field(field(store, 'pos'), player), 'coors')
    require(re.fullmatch(r'\[\s*-?\d+\s+-?\d+\s+-?\d+\s+-?\d+\s*\]', position),
            'native player position is not four-dimensional')
    return {'id': player, 'position': position, 'turns': int(field(tree, 'turns')),
            'story': field(tree, 'story')}


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
                os.execve(executable, [executable, '--smoothscroll=0'], env)
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
        return bool(re.search(r'\w+:\d+/\d+', self.text())) and '&' in self.text()

    def capture(self):
        self.settle()
        proof = self.root / 'proof'
        (proof / 'screen.txt').write_text(self.text())
        (proof / 'screen.raw').write_bytes(self.raw)
        # A screenshot of the actual X server containing xterm, not a transcript
        # renderer. This occurs while the loaded game remains live at its prompt.
        subprocess.run([os.environ['TETRAWORLD_IMPORT'], '-display',
                        os.environ['DISPLAY'], '-window', 'root',
                        str(proof / 'screenshot.png')], check=True, timeout=20)
        require((proof / 'screenshot.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n'),
                'native terminal screenshot is not PNG')

    def save(self):
        self.send(b'q')
        deadline = time.monotonic() + 15
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'save-and-quit did not exit')
        self.settle()
        require(self.status == 0, 'save-and-quit exit status ' + str(self.status))
        path = self.root / 'home/.tetraworld/OmpProof.save'
        require(path.is_file(), 'missing upstream save')
        data = path.read_bytes()
        (self.root / 'proof' / ('save-%d.native' % self.number)).write_bytes(data)
        (self.root / 'proof' / ('session-%d.raw' % self.number)).write_bytes(self.raw)
        tree = save_tree(path)
        require(field(tree, 'version') == '1000', 'unexpected native save version')
        return tree

    def close(self):
        if self.alive and not self.exited():
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)


def play(executable, root):
    saves = []
    for number in range(1, 5):
        session = Session(executable, root, number)
        try:
            if number == 1:
                for _ in range(8):
                    session.wait(lambda: '[Proceed]' in session.text() or '[More]' in session.text(),
                                 'introductory story page')
                    last_page = '[Proceed]' in session.text()
                    session.send(b'\r')
                    if last_page:
                        break
                else:
                    raise RuntimeError('introductory story exceeded eight pages')
            else:
                session.wait(lambda: b'Welcome back!' in session.raw, 'native restore greeting')
                require(not (root / 'home/.tetraworld/OmpProof.save').exists(),
                        'upstream did not consume the restored save')
            session.wait(session.live, 'rendered playable map and native status')
            if number in (1, 3):
                session.send(b'p')  # documented pass-turn action
                session.wait(session.live, 'rendered map after pass turn')
            if number == 4:
                session.settle()
                store = field(field(saves[2], 'world'), 'store')
                stats = field(field(field(store, 'mortal'), field(saves[2], 'player')), 'curStats')
                for label, current, maximum in (('hp', 'hp', 'maxhp'), ('air', 'air', 'maxair')):
                    expected = '%s:%s/%s' % (label, field(stats, current), field(stats, maximum))
                    require(expected in session.text(), 'loaded HUD disagrees with native save: ' + expected)
                session.capture()
            saves.append(session.save())
        finally:
            session.close()
    require(saves[0] == saves[1], 'first restart did not preserve the entire native state')
    require(saves[2] == saves[3], 'second restart did not preserve the entire native state')
    players = [native_player(tree) for tree in saves]
    require(players[0]['turns'] == 1 and players[2]['turns'] == 2,
            'documented pass action did not advance exact native turn counter')
    require(players[0]['position'] == players[2]['position'] and
            players[0]['id'] == players[2]['id'], 'pass turn changed player identity/position')
    options = root / 'home/.tetraworld/options'
    require(options.is_file() and 'options' in options.read_text(), 'missing native options')
    # The native writer's stdio buffer is flushed only when the game exits.
    (root / 'proof/options.native').write_bytes(options.read_bytes())
    require(not list((root / 'home/.tetraworld').glob('*.old*')), 'game rejected native save')
    receipt = {'players': players, 'first_exact_restore': True,
               'second_exact_restore': True, 'native_save_version': 1000,
               'screenshot': 'screenshot.png', 'screen': 'screen.txt',
               'save_sha256': [hashlib.sha256((root / 'proof' / ('save-%d.native' % n)).read_bytes()).hexdigest()
                               for n in range(1, 5)]}
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
            server = subprocess.Popen([os.environ['TETRAWORLD_XVFB'], '-displayfd', str(write_fd),
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
            terminal = subprocess.Popen([os.environ['TETRAWORLD_XTERM'], '-display', display,
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
