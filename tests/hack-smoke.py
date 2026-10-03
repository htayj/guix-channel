#!/usr/bin/env python3
"""Real Hack 1.0.3 PTYs, native S saves and independent restores.

The native save is an ABI-specific dump (hack.save.c/dosave0); rather than
inventing a portable decoder, compare the exact restored HUD, full displayed
map, player coordinates, inventory and native time option. A third independent
process verifies the further-turn resave too. No patched executable, artificial
save, test argument, farewell-text assertion or synthesized ANSI.

HACK_RAW_CAPTURE is the unmodified second-process live PTY prefix at 24x80;
HACK_TEXT_CAPTURE is that screen; HACK_TRANSCRIPT is all three sessions.
"""
import codecs
import errno
import fcntl
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
import termios
import time

import pyte

ROWS, COLS = 24, 80  # pinned config.h: ROWNO=22, COLNO=80, plus two UI lines
NAME = 'OmpProof'
CAPTURES = ('HACK_RAW_CAPTURE', 'HACK_TEXT_CAPTURE', 'HACK_TRANSCRIPT')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class Session:
    def __init__(self, executable, root, transcript):
        self.raw = bytearray()
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.transcript = transcript
        self.alive = True
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color',
               'LC_ALL': 'C', 'PATH': '', 'TMPDIR': str(root / 'tmp'),
               'HACKOPTIONS': 'time', 'USER': NAME, 'LOGNAME': NAME}
        for variable, directory in (('XDG_CONFIG_HOME', 'config'),
                                    ('XDG_DATA_HOME', 'data'),
                                    ('XDG_CACHE_HOME', 'cache'),
                                    ('XDG_STATE_HOME', 'state'),
                                    ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / directory)
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack('HHHH', ROWS, COLS, 0, 0))
                # Ordinary public game flags: suppress news, name, Fighter.
                os.execve(executable, [executable, '-n', '-u', NAME, '-F'], env)
            except BaseException:
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def read(self, timeout=0.1):
        if not select.select([self.fd], [], [], timeout)[0]:
            return False
        try:
            data = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        if not data:
            return False
        self.raw.extend(data)
        self.stream.feed(self.decoder.decode(data))
        require(len(self.raw) < 4000000, 'excessive PTY output')
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
            if self.exited():
                self.settle()
                raise RuntimeError(description + ': game exited '
                                   + str(self.status) + '\n' + self.text())
            require(time.monotonic() < deadline,
                    description + ': timed out\n' + self.text())

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(0.3):
            require(time.monotonic() < deadline, 'PTY never became idle')

    def send(self, keys):
        require(not self.exited(), 'cannot send keys after exit')
        os.write(self.fd, keys)

    def clear_messages(self):
        self.settle()
        for _ in range(12):
            if '--More--' not in self.text():
                return
            self.send(b' ')
            self.settle()
        raise RuntimeError('message pagination did not finish')

    def live(self):
        hud = self.screen.display[-1].rstrip()
        # hack.pri.c/bot: optional Gold, native Hp/Ac/Str/Exp, hunger, time.
        match = re.search(r'^Level\s+(\d+)\s+(?:Gold\s+(\d+)\s+)?'
                          r'Hp\s+(\d+)\((\d+)\)\s+Ac\s+(-?\d+)\s+'
                          r'Str\s+(\S+)\s+Exp\s+(\d+)(?:/(\d+))?'
                          r'\s*(.*?)\s+(\d+)\s*$', hud)
        positions = [(x, y) for y in range(1, 23) for x in range(COLS)
                     if self.screen.buffer[y][x].data == '@']
        if match is None or len(positions) != 1 or '--More--' in self.text():
            return None
        return {'hud': hud, 'level': int(match[1]),
                'gold': int(match[2]) if match[2] else None,
                'hp': [int(match[3]), int(match[4])], 'ac': int(match[5]),
                'strength': match[6], 'experience_level': int(match[7]),
                'experience': int(match[8]) if match[8] else None,
                'hunger': match[9].strip(), 'turn': int(match[10]),
                'position': list(positions[0]),
                'map': self.screen.display[1:23]}

    def gameplay(self):
        self.clear_messages()
        self.wait(lambda: self.live() is not None, 'missing native HUD/map/time')
        # Ctrl-R is the game's doredraw, consumes no turn, clears overlay damage.
        self.send(b'\x12')
        self.clear_messages()
        self.wait(lambda: self.live() is not None, 'missing redrawn gameplay')
        state = self.live()
        require(state['hp'][0] > 0, 'player is not alive')
        return state

    def enter(self, resume):
        self.wait(lambda: 'Hello ' + NAME in self.text() or '--More--' in self.text(),
                  'missing native welcome')
        self.clear_messages()
        state = self.gameplay()
        restored = b'Restoring old save file...' in self.raw
        require(restored == resume, 'unexpected new-game/restore path')
        return state

    def inventory(self):
        before = self.gameplay()
        self.send(b'i')
        self.wait(lambda: '--More--' in self.text(), 'missing native inventory menu')
        self.settle()
        items = []
        for row in self.screen.display:
            match = re.search(r'\b([a-zA-Z]) - (.+)', row)
            if match:
                items.append(match[1] + ' - ' + match[2].rstrip())
        require(any('sword' in item for item in items)
                and any('mail' in item for item in items),
                'Fighter inventory has no actual sword and armour')
        self.send(b' ')
        after = self.gameplay()
        require(after == before, 'inventory command changed game state')
        return items

    def move(self):
        before = self.gameplay()
        x, y = before['position']
        # Choose an actually visible empty floor/stair neighbor, not a monster,
        # door, unknown square or item. No seeded world or fabricated movement.
        for key, dx, dy in ((b'h', -1, 0), (b'l', 1, 0),
                            (b'k', 0, -1), (b'j', 0, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < COLS and 1 <= ny < 23 \
                    and self.screen.buffer[ny][nx].data in '.<>':
                self.send(key)
                self.clear_messages()
                after = self.gameplay()
                require(after['position'] == [nx, ny], 'native movement missed target')
                require(after['turn'] > before['turn'], 'movement consumed no native turn')
                return after
        raise RuntimeError('no visible empty cardinal neighbor for native movement')

    def save_exit(self, savefile):
        require(not savefile.exists(), 'previous save was not consumed by restore')
        self.send(b'S')
        deadline = time.monotonic() + 20
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'native S save/exit timed out')
        self.settle()
        require(self.status == 0 and savefile.is_file() and savefile.stat().st_size > 0,
                'native S did not exit successfully with a durable save')

    def close(self):
        if self.alive:
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        self.settle()
        self.transcript.extend(self.raw)
        os.close(self.fd)


def isolated(executable, root):
    for namespace in ('net', 'mnt', 'pid'):
        require(os.readlink('/proc/self/ns/' + namespace) !=
                os.environ['HACK_HOST_' + namespace.upper()],
                namespace + ' namespace unchanged')
    require(socket.if_nameindex() == [(1, 'lo')], 'non-loopback network interface exposed')
    mount = shutil.which('mount')
    require(mount is not None, 'realized mount tool missing')
    subprocess.run([mount, '--bind', '/gnu/store', '/gnu/store'], check=True)
    subprocess.run([mount, '-o', 'remount,bind,ro', '/gnu/store'], check=True)
    entries = [line.split() for line in Path('/proc/self/mountinfo').read_text().splitlines()]
    require(any(row[4] == '/gnu/store' and 'ro' in row[5].split(',') for row in entries),
            'store mount is not read-only')
    proof = root / 'proof'
    state_dir = root / 'data/hack'
    savefile = state_dir / ('save/0' + NAME)  # mapped namespace UID, hack.main.c/SAVEF
    receipt = {'schema': 'hack-native-proof-v1', 'terminal': [ROWS, COLS],
               'store_readonly': True, 'namespaces': {
                   ns: os.readlink('/proc/self/ns/' + ns) for ns in ('net', 'mnt', 'pid')},
               'sessions': []}
    transcript = bytearray()
    try:
        first = Session(executable, root, transcript)
        try:
            initial = first.enter(False)
            first.move()
            saved = first.gameplay()
            inventory = first.inventory()
            (proof / 'first-pre-save.txt').write_text(first.text())
            first.save_exit(savefile)
        finally:
            first.close()
        shutil.copyfile(savefile, proof / 'first.sav')
        receipt['sessions'].append({'initial': initial, 'saved': saved, 'inventory': inventory})
        second = Session(executable, root, transcript)
        try:
            restored = second.enter(True)
            require(not savefile.exists(), 'dorecover did not consume native save')
            require(restored == saved, 'restored HUD/position/map/turn differs from saved game')
            require(second.inventory() == inventory, 'restored inventory differs')
            (proof / 'restored.txt').write_text(second.text())
            continued = second.move()
            continued_inventory = second.inventory()
            require(continued['turn'] > restored['turn'], 'restored game made no further turn')
            # Exact live prefix, before S or terminal teardown, original geometry.
            for variable, data in (('HACK_RAW_CAPTURE', bytes(second.raw)),
                                   ('HACK_TEXT_CAPTURE', second.text().encode())):
                if os.environ.get(variable):
                    Path(os.environ[variable]).write_bytes(data)
            (proof / 'continued.txt').write_text(second.text())
            second.save_exit(savefile)
        finally:
            second.close()
        shutil.copyfile(savefile, proof / 'continued.sav')
        require((proof / 'continued.sav').read_bytes() != (proof / 'first.sav').read_bytes(),
                'further turn produced identical native save')
        receipt['sessions'].append({'restored': restored, 'continued': continued,
                                    'inventory': continued_inventory})
        third = Session(executable, root, transcript)
        try:
            resaved = third.enter(True)
            require(resaved == continued, 'further-turn resave did not durably restore exactly')
            require(third.inventory() == continued_inventory, 'resaved inventory changed')
            third.save_exit(savefile)
        finally:
            third.close()
        receipt['sessions'].append({'restored_resave': resaved})
        receipt['save_sha256'] = {name: hashlib.sha256((proof / name).read_bytes()).hexdigest()
                                  for name in ('first.sav', 'continued.sav')}
        for file in ('perm', 'record'):
            require((state_dir / file).is_file() and not (state_dir / file).is_symlink(),
                    'mutable state missing or linked: ' + file)
        for asset in ('data', 'help', 'hh', 'rumors'):
            require((state_dir / asset).is_symlink()
                    and (state_dir / asset).resolve() ==
                    Path(executable).parent.parent / ('share/hack/' + asset),
                    'runtime asset does not link to immutable store: ' + asset)
        # Proof files are deliberately external; game files must stay in XDG data.
        for directory in ('home', 'config', 'cache', 'state', 'runtime', 'tmp', 'work'):
            require(not any((root / directory).iterdir()), 'game escaped XDG data: ' + directory)
        (proof / 'receipt.json').write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n')
        print('Hack native gameplay and two exact independent save restores passed')
    finally:
        (proof / 'transcript.raw').write_bytes(transcript)
        if os.environ.get('HACK_TRANSCRIPT'):
            Path(os.environ['HACK_TRANSCRIPT']).write_bytes(transcript)


def main():
    inside = len(sys.argv) == 4 and sys.argv[1] == '--inside'
    args = sys.argv[2:] if inside else sys.argv[1:]
    require(len(args) == 2, 'usage: hack-smoke.py HACK FRESH_ROOT')
    executable, root_arg = args
    root = Path(root_arg).resolve()
    if inside:
        isolated(executable, root)
        return
    require(not any((root / 'home').iterdir()), 'HOME must be fresh')
    require(all((root / directory).is_dir() for directory in
                ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work', 'proof')),
            'missing isolated scratch directories')
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized unshare missing')
    env = {key: os.environ[key] for key in CAPTURES if os.environ.get(key)}
    for key in ('GUIX_PYTHONPATH', 'PYTHONPATH'):
        if os.environ.get(key):
            env[key] = os.environ[key]
    env.update({'PATH': os.environ['PATH'], 'LC_ALL': 'C',
                'HOME': str(root / 'home'), 'TMPDIR': str(root / 'tmp')})
    for ns in ('net', 'mnt', 'pid'):
        env['HACK_HOST_' + ns.upper()] = os.readlink('/proc/self/ns/' + ns)
    command = [unshare, '--user', '--map-root-user', '--mount', '--propagation',
               'private', '--net', '--pid', '--mount-proc', '--kill-child', '--fork',
               sys.executable, '-B', str(Path(__file__).resolve()), '--inside', executable, str(root)]
    process = subprocess.Popen(command, env=env, start_new_session=True)
    try:
        status = process.wait(timeout=150)
    except BaseException:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
        raise
    require(status == 0, 'isolated proof failed (namespace denial is not a pass): ' + str(status))


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print('hack-smoke: ' + str(error), file=sys.stderr)
        sys.exit(1)
