#!/usr/bin/env python3
"""External PTY consumer of the official Gruesome 0.0.3 Pascal game.

The oracle comes from source.pas: SplashScreen, StatusBar, PlayerMove, the 'l'
case in the main loop, and the final quit ReadKey. No RNG seed, game memory,
synthetic launcher option, or expected-state injection is used. Screens are
terminal-decoded observations, not reconstructed game state or PNG evidence.
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
import struct
import subprocess
import sys
import termios
import time
import traceback

import pyte

SOURCE_URL = 'http://www.gamesofgrey.com/games/gruesome/gruesome0.0.3.zip'
# Hashes of complete, unmodified files in the official archive's Gruesome/.
UPSTREAM = {
    'source.pas': 'dddfb828ee24ffbfd7ab7ea7f6d0c43e9686a489aac6faa8556e205df605dd88',
    'license.txt': 'feebd8b2a4505178414f690838019c615762914a5dd82206d31abd6754c90a2c',
    'readme.txt': 'a760d6719ec2175a4c2a4a49bec3b6bd9196ea0754d7bd5e26efca5d8a3d131a',
    'history.txt': '39a60979720da10b0c44bdd9203e9cf847d84f408538480d6e3aa5a46b01abe6',
}
ROWS, COLS = 25, 80
NAME = 'NativeGrue'  # namestring is string[10].


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def namespace_proof(proc, evidence, label):
    namespaces = {name: os.readlink(proc / 'ns' / name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    raw = {name: (proc / name).read_text() for name in
           ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route')}
    executable = os.readlink(proc / 'exe')
    record(evidence / (label + '-namespace-raw.json'),
           {'proc': str(proc), 'namespaces': namespaces, 'executable': executable, 'files': raw})
    for name, host in (('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                       ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')):
        require(namespaces[name] != os.environ[host], 'not in private ' + name + ' namespace')
        require(namespaces[name] == os.readlink('/proc/self/ns/' + name),
                'process escaped private ' + name + ' namespace')
    identity = {}
    for line in raw['status'].splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(part) for part in value.split()]
    maps = {}
    for kind, variable, field in (('uid', 'HOST_UID', 'Uid'), ('gid', 'HOST_GID', 'Gid')):
        expected = int(os.environ[variable])
        require(identity[field] == [expected] * 4, 'caller ' + kind + ' changed')
        maps[kind] = raw[kind + '_map']
        require([int(part) for part in maps[kind].split()] == [expected, expected, 1],
                'not a same-identity ' + kind + ' mapping')
    interfaces = sorted(line.split(':')[0].strip() for line in
                        raw['net/dev'].splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'network namespace contains external interfaces')
    routes = {name: raw['net/' + name] for name in ('route', 'ipv6_route')}
    ipv4_rows = [line.split() for line in routes['route'].splitlines() if line.strip()]
    # The observed private namespace on Linux 7.1.8 exposes an empty file
    # for an empty IPv4 table; kernels that emit a header must have no rows.
    if ipv4_rows:
        require(ipv4_rows[0] ==
                ['Iface', 'Destination', 'Gateway', 'Flags', 'RefCnt', 'Use', 'Metric',
                 'Mask', 'MTU', 'Window', 'IRTT'], 'unexpected /proc/net/route header')
        require(not ipv4_rows[1:], 'offline namespace has IPv4 routes')
    ipv6_rows = [line.split() for line in routes['ipv6_route'].splitlines() if line.strip()]
    require(all(row[-1] == 'lo' for row in ipv6_rows),
            'offline namespace has non-loopback IPv6 routes')
    return {'namespaces': namespaces, 'identity': identity, 'maps': maps,
            'interfaces': interfaces, 'routes': routes,
            'executable': executable}


def readonly_store(evidence):
    commands = []

    def mount(*args):
        result = subprocess.run([os.environ['MOUNT'], *args], capture_output=True,
                                text=True, timeout=10)
        commands.append({'args': args, 'status': result.returncode,
                         'stdout': result.stdout, 'stderr': result.stderr})
        record(evidence / 'mount-commands.json', commands)
        require(result.returncode == 0, 'store mount failed: ' + result.stderr)

    def entries():
        text = Path('/proc/self/mountinfo').read_text()
        found = []
        for line in text.splitlines():
            fields = line.split()
            target = fields[4]
            for escaped, literal in (('\\040', ' '), ('\\011', '\t'),
                                     ('\\012', '\n'), ('\\134', '\\')):
                target = target.replace(escaped, literal)
            if target == '/gnu/store' or target.startswith('/gnu/store/'):
                found.append((target, fields[5].split(','), fields[6:fields.index('-')]))
        return text, found

    (evidence / 'mountinfo-before.txt').write_text(entries()[0])
    mount('--rbind', '/gnu/store', '/gnu/store')
    mount('--make-rprivate', '/gnu/store')
    for target in sorted({entry[0] for entry in entries()[1]}, key=len, reverse=True):
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    (evidence / 'mountinfo-after.txt').write_text(text)
    require(found and any(target == '/gnu/store' for target, _, _ in found),
            'store bind mount missing')
    require(all('ro' in options and 'rw' not in options and not
                any(item.startswith(('shared:', 'master:')) for item in optional)
                for _, options, optional in found), 'store is not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store filesystem is writable')
    return found


class Session:
    def __init__(self, output, evidence, work, env):
        self.evidence = evidence
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('ascii')('strict')
        self.raw = bytearray()
        self.keys = []
        self.status = None
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(work)
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                launcher = str(output / 'bin/gruesome')
                os.execve(launcher, [launcher], env)
            except BaseException:
                os._exit(127)

    def exited(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
        return self.status is not None

    def pump(self, seconds=0.05):
        if self.fd not in select.select([self.fd], [], [], seconds)[0]:
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
        return True

    def await_screen(self, predicate, label):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            self.pump()
            if predicate():
                # Do not use a transient partial redraw as the next input point.
                while self.pump(0.15):
                    require(time.monotonic() < deadline, 'terminal never settled: ' + label)
                if predicate():
                    self.snapshot(label)
                    return
            require(not self.exited(), 'game exited before ' + label)
        self.snapshot('timeout-' + label)
        raise RuntimeError('native screen timeout: ' + label)

    def snapshot(self, label):
        record(self.evidence / (label + '.screen.json'),
               {'rows': self.screen.display, 'cursor': {'x': self.screen.cursor.x,
                                                       'y': self.screen.cursor.y},
                'raw_bytes': len(self.raw)})
        (self.evidence / (label + '.screen.txt')).write_text('\n'.join(self.screen.display) + '\n')

    def send(self, label, data):
        require(not self.exited(), 'cannot send input to exited game')
        self.keys.append({'label': label, 'hex': data.hex(), 'raw_offset': len(self.raw)})
        require(os.write(self.fd, data) == len(data), 'short PTY write')

    def finish(self):
        deadline = time.monotonic() + 10
        while not self.exited() and time.monotonic() < deadline:
            self.pump()
        require(self.exited(), 'quit acknowledgement did not terminate game')
        while self.pump(0.05):
            pass
        require(self.status == 0, 'native game exited ' + str(self.status))

    def close(self):
        (self.evidence / 'terminal.raw').write_bytes(self.raw)
        record(self.evidence / 'pty-inputs.json', self.keys)
        if not self.exited():
            # Failure cleanup only, never used as evidence of normal quit.
            os.kill(self.pid, 9)
            os.waitpid(self.pid, 0)
        os.close(self.fd)


def state(session):
    line = session.screen.display[24]
    require(line[:10] == NAME, 'status bar lost the entered native name')
    values = {}
    for key, left, right, pattern in (
            ('lp', 17, 30, r'LP: (\d+)/(\d+)'),
            ('sp', 30, 43, r'SP: (\d+)/(\d+)'),
            ('meals', 43, 57, r'Meals: (\d+)'),
            ('turns', 57, 73, r'Turns: (\d+)'),
            ('depth', 73, 80, r'D: (\d+)')):
        match = re.fullmatch(pattern + r' *', line[left:right])
        require(match is not None, 'native status field differs: ' + key + ': ' + repr(line[left:right]))
        numbers = [int(value) for value in match.groups()]
        values[key] = numbers if len(numbers) > 1 else numbers[0]
    values['position'] = [session.screen.cursor.x + 1, session.screen.cursor.y + 1]
    require(1 <= values['position'][0] <= 80 and 3 <= values['position'][1] <= 23,
            'native cursor is not on the cave map')
    return values


def main(output, evidence):
    doc = output / 'share/doc/gruesome'
    notices = {}
    for name, expected in UPSTREAM.items():
        blob = (doc / name).read_bytes()
        actual = hashlib.sha256(blob).hexdigest()
        notices[name] = {'bytes': len(blob), 'sha256': actual}
        require(actual == expected, 'complete official notice/source differs: ' + name)
    require((output / 'libexec/gruesome-real').read_bytes()[:4] == b'\x7fELF',
            'installed source-built runtime is not ELF')
    for path in output.rglob('*'):
        require(path.suffix.lower() != '.exe', 'opaque Windows executable was installed')
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, 'installed output has writable entries')
    record(evidence / 'upstream-files.json', {'url': SOURCE_URL, 'version': '0.0.3', 'files': notices})
    require(os.getpid() == 1, 'consumer is not PID 1 in private PID/proc namespace')
    consumer = namespace_proof(Path('/proc/self'), evidence, 'consumer')
    mounts = readonly_store(evidence)
    root = evidence / 'private-state'
    root.mkdir(mode=0o700)
    env = {'PATH': '', 'TERM': 'xterm', 'LC_ALL': 'C'}
    for variable, name in (('HOME', 'home'), ('TMPDIR', 'tmp'),
                           ('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                           ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                           ('XDG_RUNTIME_DIR', 'runtime')):
        directory = root / name
        directory.mkdir(mode=0o700)
        env[variable] = str(directory)
    work = root / 'work'
    work.mkdir(mode=0o700)
    session = Session(output, evidence, work, env)
    try:
        session.await_screen(lambda: session.screen.display[3][1:22] == '> What is your name? ', 'name')
        native = namespace_proof(Path('/proc') / str(session.pid), evidence, 'game')
        require(Path(native['executable']).resolve() == (output / 'libexec/gruesome-real').resolve(),
                'ordinary launcher did not exec the installed native game')
        terminal_fds = {str(fd): os.readlink('/proc/%d/fd/%d' % (session.pid, fd))
                        for fd in (0, 1, 2)}
        require(os.isatty(session.fd) and len(set(terminal_fds.values())) == 1 and
                terminal_fds['0'].startswith('/dev/pts/'),
                'game stdin/stdout/stderr are not the same real PTY')
        native['terminal_fds'] = terminal_fds
        record(evidence / 'namespace-proof.json', {'consumer': consumer, 'game': native, 'store_mounts': mounts})
        require(session.screen.display[1].rstrip() == ' > Welcome to Gruesome, where you play the grue.',
                'native welcome screen differs from SplashScreen')
        session.send('name', NAME.encode('ascii') + b'\r')
        session.await_screen(lambda: session.screen.display[18].rstrip() == '   Press any key to begin.', 'begin')
        session.send('begin', b' ')
        session.await_screen(lambda: session.screen.display[0].rstrip() ==
                             'It is pitch black.  You are likely to eat someone.' and
                             session.screen.display[24][:10] == NAME, 'initial')
        before = state(session)
        require({key: before[key] for key in ('lp', 'sp', 'meals', 'turns', 'depth')} ==
                {'lp': [2, 2], 'sp': [2, 2], 'meals': 0, 'turns': 0, 'depth': 20},
                'fresh native initial stats differ')
        require(any('.' in row or '#' in row for row in session.screen.display[2:23]),
                'native cave was not drawn')
        initial_map = session.screen.display[2:23].copy()
        # CaveGenerator digs the 3x3 neighborhood of the spawn. The 'l' key
        # invokes PlayerMove(x+1,y); an accepted move advances the turn counter
        # and leaves the real CRT cursor on the new, black-on-black player tile.
        # Random creature behavior is not suppressed or treated as success.
        session.send('move-east', b'l')
        session.await_screen(lambda: not session.screen.display[0].strip() and
                             not session.screen.display[1].strip() and
                             re.fullmatch(r'Turns: 1 *', session.screen.display[24][57:73]) is not None and
                             [session.screen.cursor.x + 1, session.screen.cursor.y + 1] ==
                             [before['position'][0] + 1, before['position'][1]], 'turn-one')
        after = state(session)
        require(after == {**before, 'turns': 1,
                          'position': [before['position'][0] + 1, before['position'][1]]},
                'normal east movement did not produce the native turn/position transition')
        x, y = before['position']
        require(session.screen.display[y - 1][x - 1] == '.' and
                session.screen.display[y - 1][x] == ' ',
                'native cave did not redraw the vacated floor and new grue tile')
        require(session.screen.display[2:23] != initial_map, 'movement did not change the native cave rendering')
        session.send('normal-quit', b'Q')
        session.await_screen(lambda: session.screen.display[0].rstrip() == 'Till next lurking....', 'quit')
        require(not session.exited(), 'quit skipped the native ReadKey acknowledgement')
        session.send('quit-acknowledgement', b' ')
        session.finish()
        session.snapshot('exit')
        require(all(not row.strip() for row in session.screen.display), 'final native ClrScr was not observed')
        entries = sorted(str(path.relative_to(root)) for path in root.rglob('*')
                         if path.parent != root or not path.is_dir())
        require(not entries, 'game wrote private state despite no persistence in upstream: ' + repr(entries))
        record(evidence / 'runtime.json', {
            'status': 'passed', 'launcher': str(output / 'bin/gruesome'), 'arguments': [],
            'source_url': SOURCE_URL, 'name': NAME, 'rows': ROWS, 'columns': COLS,
            'environment': env, 'before': before, 'after': after,
            'native_outcome': {'action': 'l', 'message_rows': ['', ''],
                               'turn_delta': 1, 'position_delta': [1, 0]}, 'quit': 'Q',
            'quit_message': 'Till next lurking....', 'quit_acknowledgement_hex': '20',
            'exit_status': session.status, 'private_state_entries': entries,
            'rng_control': None, 'store_read_only': True,
            'limitations': ['One ordinary east-movement turn, not a victory or death run',
                            'Terminal screenshots are decoded text/JSON, not graphical captures',
                            'NAR equality is checked and recorded by gruesome-smoke.sh'],
        })
    finally:
        session.close()


if __name__ == '__main__':
    require(len(sys.argv) == 3, 'usage: gruesome-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    try:
        main(output, evidence)
    except BaseException as error:
        record(evidence / 'failure.json', {'error': str(error), 'traceback': traceback.format_exc()})
        raise
