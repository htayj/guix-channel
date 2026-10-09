#!/usr/bin/env python3
"""External ordinary Grippy Socks console consumer, never an injected smoke mode.

Pinned Daedalus 3.5 source: 32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8.
Macro5/Macro6/Macro7 are documented F5/F6/F7 user commands. Rest consumes
native turns; the next-day Message reports an actual wellness consequence.
Only the documented console-loop lifecycle setting is changed at exit.
MessageInside/ScreenDot are console no-ops: no graphical, HUD, save, player
position, full-day duration, or complete playability claim is made here.
"""
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

COMMIT = '32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8'
SOURCE = 'https://github.com/CruiserOne/Daedalus/blob/' + COMMIT + '/'
PROMPT = b'Enter Command Line: '
SCRIPT_HASH = '37b06691d67261c16e8de1504fe70506a57d9e8a2fc6eef2dbc13c31fc6928b7'
UPSTREAM = {
    'README.md': '113dfcdec127e5efe74a7d51c2bbee2845fb1457e97bff72b039893686089fb5',
    'license.htm': '9c2023d14fb98b456f6b659b3f855021e59654242cfa10fd0a8a523ad74c114f',
    'changes.htm': 'faacd8fc6679f6ec3726a7537ec7da877d2e0ecac9649997c441d457519e7f36',
    'changes.doc': 'cdf4211121f0cb773bdf5eda302a672aea56b8743e8828183e50c32a47fb76df',
    'daedalus.htm': 'c6b8370d1cafde0df4a83ad71ee67681dad6b8664082c6d3932bdc9eed6f46e1',
    'daedalus.doc': '53c3879b159b5d21534331a9189376ead5b26a0164d44fa6166488b0f568a1dc',
    'script.htm': 'dcd58e2c723b87ea11f5044d0949e9355427fb0e8bdd222ae3a6df6e9ed7e2e8',
    'script.doc': '8814d45eeea176f66d68a786d054d8d3127df35ea4519044b8af90a95563b412',
}
DAY_MESSAGE = (
    "You made it through another day on the psych ward! Here's a summary of your actions the previous day:\n\n"
    "Negative: Didn't eat anything all day. [-1]\n"
    "Negative: Never showered. [-1]\n"
    "Negative: Skipped all daily therapy groups.\n"
    "Negative: Didn't check in with your psychiatrist.\n"
    "\nAs a result of your actions yesterday, your wellness level has decreased from 3 to 1. :-("
    "\n\nYour wellness has fallen enough that you are in crisis! For your safety you have been placed on a one-on-one continual observation. :-("
)


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
    identity = {}
    for line in raw['status'].splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(part) for part in value.split()]
    proof = {'namespaces': namespaces, 'identity': identity,
             'executable': os.readlink(proc / 'exe'), 'files': raw}
    record(evidence / (label + '-namespace.json'), proof)
    for name, host in (('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                       ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')):
        require(namespaces[name] != os.environ[host], 'not in private ' + name + ' namespace')
        require(namespaces[name] == os.readlink('/proc/self/ns/' + name),
                'game escaped private ' + name + ' namespace')
    for kind, field, variable in (('uid', 'Uid', 'HOST_UID'), ('gid', 'Gid', 'HOST_GID')):
        expected = int(os.environ[variable])
        require(identity[field] == [expected] * 4, 'caller identity changed: ' + kind)
        require([int(part) for part in raw[kind + '_map'].split()] ==
                [expected, expected, 1], 'not same-identity mapping: ' + kind)
    interfaces = sorted(line.split(':')[0].strip() for line in
                        raw['net/dev'].splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'private network has external interfaces')
    routes = [line.split() for line in raw['net/route'].splitlines() if line.strip()]
    header = ['Iface', 'Destination', 'Gateway', 'Flags', 'RefCnt', 'Use', 'Metric',
              'Mask', 'MTU', 'Window', 'IRTT']
    require(not routes or routes == [header], 'private network has IPv4 routes')
    require(all(line.split()[-1] == 'lo' for line in raw['net/ipv6_route'].splitlines()
                if line.strip()), 'private network has external IPv6 routes')
    return proof


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
    for target in sorted({item[0] for item in entries()[1]}, key=len, reverse=True):
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    (evidence / 'mountinfo-after.txt').write_text(text)
    require(found and any(target == '/gnu/store' for target, _, _ in found),
            'recursive store bind absent')
    require(all('ro' in options and 'rw' not in options and not
                any(item.startswith(('shared:', 'master:')) for item in optional)
                for _, options, optional in found), 'store is not private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store filesystem writable')
    return found


class Session:
    def __init__(self, output, evidence, work, env):
        self.evidence = evidence
        self.raw = bytearray()
        self.inputs = []
        self.status = None
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(work)
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 120, 0, 0))
                # Disable PTY input echo: input cannot satisfy output assertions.
                attrs = termios.tcgetattr(0)
                attrs[3] &= ~termios.ECHO
                termios.tcsetattr(0, termios.TCSANOW, attrs)
                launcher = str(output / 'bin/grippy-socks')
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
        require(len(self.raw) < 4000000, 'excessive native terminal output')
        return True

    def prompt(self, label, offset):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            self.pump()
            if self.raw[offset:].endswith(PROMPT):
                text = bytes(self.raw[offset:-len(PROMPT)]).decode('utf-8').replace('\r\n', '\n')
                (self.evidence / (label + '.console.txt')).write_text(text)
                (self.evidence / 'terminal.raw').write_bytes(self.raw)
                require(not re.search(r'(Daedalus Error:|Initialization failed!|not defined\.|Unknown action:)', text),
                        'native engine reported an error: ' + label)
                return text
            require(not self.exited(), 'game exited before ' + label)
        raise RuntimeError('native prompt timeout: ' + label)

    def send(self, label, command):
        require(not self.exited(), 'cannot send input to exited game')
        data = (command + '\n').encode('ascii')
        offset = len(self.raw)
        self.inputs.append({'label': label, 'command': command, 'hex': data.hex(),
                            'raw_offset': offset})
        require(os.write(self.fd, data) == len(data), 'short PTY write')
        return offset

    def command(self, label, command):
        return self.prompt(label, self.send(label, command))

    def finish(self):
        offset = self.send('documented-console-exit', 'fNoExit 0 Exit')
        deadline = time.monotonic() + 10
        while not self.exited() and time.monotonic() < deadline:
            self.pump()
        require(self.exited(), 'documented Exit did not terminate ordinary launcher')
        while self.pump(0.05):
            pass
        require(self.status == 0, 'native exit status: ' + str(self.status))
        response = bytes(self.raw[offset:]).decode('utf-8').replace('\r\n', '\n')
        (self.evidence / 'exit.console.txt').write_text(response)
        require('Program exit has been disabled.' not in response and PROMPT not in self.raw[offset:],
                'ordinary Exit was refused or returned to prompt')

    def close(self):
        (self.evidence / 'terminal.raw').write_bytes(self.raw)
        record(self.evidence / 'pty-inputs.json', self.inputs)
        # Any failed child remains owned by the enclosing unshare --kill-child;
        # a signal or EOF is never accepted as successful ordinary termination.
        os.close(self.fd)


def footprint(root):
    result = {}
    for path in sorted(root.rglob('*')):
        relative = str(path.relative_to(root))
        if path.is_symlink():
            result[relative] = {'kind': 'symlink', 'target': os.readlink(path)}
        elif path.is_dir():
            result[relative] = {'kind': 'directory', 'mode': oct(path.stat().st_mode & 0o777)}
        else:
            blob = path.read_bytes()
            result[relative] = {'kind': 'file', 'bytes': len(blob),
                                'sha256': hashlib.sha256(blob).hexdigest()}
    return result


def main(output, evidence):
    require(os.getpid() == 1, 'consumer not PID 1 in private PID/proc namespace')
    consumer = namespace_proof(Path('/proc/self'), evidence, 'consumer')
    mounts = readonly_store(evidence)
    require((output / 'libexec/grippy-socks-real').read_bytes()[:4] == b'\x7fELF',
            'source-built Unix engine is not ELF')
    for path in [output, *output.rglob('*')]:
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, 'output has writable entry: ' + str(path))
        require(path.suffix.lower() not in ('.wav', '.exe'), 'excluded opaque asset installed')
    data = output / 'share/grippy-socks'
    require(sorted(path.name for path in data.iterdir()) == ['gripsox.ds'],
            'unexpected game data assets')
    doc = output / 'share/doc/grippy-socks'
    originals = {}
    for name, expected_hash in dict(UPSTREAM, **{'gripsox.ds': SCRIPT_HASH}).items():
        blob = ((data if name == 'gripsox.ds' else doc) / name).read_bytes()
        actual_hash = hashlib.sha256(blob).hexdigest()
        originals[name] = {'bytes': len(blob), 'sha256': actual_hash}
        require(actual_hash == expected_hash, 'complete pinned original differs: ' + name)
    record(evidence / 'upstream-files.json', {'commit': COMMIT, 'files': originals})
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
    before = footprint(root)
    record(evidence / 'state-before.json', before)
    session = Session(output, evidence, work, env)
    try:
        startup = session.prompt('startup', 0)
        require('Grippy Socks: A mental health simulation\n' in startup and
                'F7: Rest for an hour' in startup and
                'Select OK for more help, or Cancel to start playing.' in startup,
                'ordinary native game startup/help missing')
        game = namespace_proof(Path('/proc') / str(session.pid), evidence, 'game')
        require(game['executable'] == str(output / 'libexec/grippy-socks-real'),
                'ordinary launcher did not exec installed source-built engine')
        proc = Path('/proc') / str(session.pid)
        argv = (proc / 'cmdline').read_bytes().split(b'\0')[:-1]
        require(argv == [str(output / 'libexec/grippy-socks-real').encode(),
                         b"OpenScript 'gripsox.ds' fNoExit 1 fSkipMessageDisplay 0"],
                'unexpected launcher engine arguments')
        descriptors = {str(fd): os.readlink(proc / 'fd' / str(fd)) for fd in (0, 1, 2)}
        require(len(set(descriptors.values())) == 1 and descriptors['0'].startswith('/dev/pts/'),
                'engine not attached to one genuine PTY')
        require(os.readlink(proc / 'cwd') == str(root / 'state/grippy-socks'),
                'launcher did not use private XDG state')
        record(evidence / 'game-entry.json', {'argv': [arg.decode() for arg in argv],
                                             'stdio': descriptors, 'environment': env})
        actions = []
        # Console redraw callbacks are absent: h starts at zero and advances
        # by 60 per F7. The sixth action reaches Wait's h==360 day evaluation;
        # no graphical-clock rollover is claimed (VInside never runs here).
        for number in range(1, 7):
            response = session.command('rest-' + str(number), 'Macro7')
            actions.append({'command': 'Macro7', 'response': response,
                            'number': number})
            if 'You made it through another day on the psych ward!' in response:
                require(number == 6, 'daily evaluation did not occur at native console rest boundary')
                require(response == 'Daedalus: ' + DAY_MESSAGE + '\n',
                        'native daily consequence differs from rest-only source oracle')
                break
            require(response == '', 'rest-only command emitted unexpected console text')
        else:
            raise RuntimeError('prerequisite missing: documented native rest produced no observable '
                               'day/wellness Message within the source-derived bound; help/map alone is insufficient')
        record(evidence / 'daily-consequence.json', {
            'source_expected_message': DAY_MESSAGE,
            'observed_response': actions[-1]['response'],
            'ordinary_actions': actions,
            'observed_wellness_before': 3, 'observed_wellness_after': 1,
            'observed_consequence': 'one-on-one continual observation',
            'scope': 'native daily evaluation Message, not hidden state queries or visible HUD'})
        session.finish()
        after = footprint(root)
        record(evidence / 'state-after.json', after)
        expected = dict(before)
        expected['state/grippy-socks'] = {'kind': 'directory', 'mode': '0o700'}
        expected['state/grippy-socks/gripsox.ds'] = {
            'kind': 'symlink', 'target': str(data / 'gripsox.ds')}
        require(after == expected, 'unexpected native state footprint (see state-after.json)')
        record(evidence / 'result.json', {
            'status': 'passed', 'scope': 'ordinary Unix console, not graphical frontend',
            'source_commit': COMMIT, 'source_anchors': {
                'user_help': SOURCE + 'gripsox.ds#L52-L56',
                'initial_state': SOURCE + 'gripsox.ds#L58-L81',
                'rest_bounds': SOURCE + 'gripsox.ds#L103-L129',
                'wait_and_day_event': SOURCE + 'gripsox.ds#L184-L246',
                'wellness_consequence': SOURCE + 'gripsox.ds#L249-L264',
                'user_macro_commands': SOURCE + 'command.cpp#L286-L292',
                'user_macro_dispatch': SOURCE + 'command.cpp#L5982-L5996',
                'console_clock_limitation': SOURCE + 'gripsox.ds#L142-L164',
                'prompt_and_exit': SOURCE + 'daedalus.cpp#L3072-L3106',
                'console_prompt': SOURCE + 'daedalus.cpp#L3297-L3316',
                'no_graphics': SOURCE + 'daedalus.cpp#L3224-L3229',
                'no_status_display': SOURCE + 'daedalus.cpp#L3341-L3343'},
            'rest_actions': len(actions), 'native_day_message': actions[-1]['response'],
            'exit': {'command': 'fNoExit 0 Exit', 'status': session.status,
                     'lifecycle_only': True, 'signals_or_eof_used': False},
            'consumer': consumer, 'game': game, 'store_mounts': mounts,
            'state_footprint': after, 'save_or_graphical_proof': False})
    finally:
        record(evidence / 'state-final.json', footprint(root))
        session.close()


if __name__ == '__main__':
    require(len(sys.argv) == 3, 'usage: grippy-socks-native.py OUTPUT EVIDENCE')
    evidence = Path(sys.argv[2])
    try:
        main(Path(sys.argv[1]), evidence)
    except BaseException as error:
        record(evidence / 'failure.json', {'error': str(error), 'traceback': traceback.format_exc()})
        raise
