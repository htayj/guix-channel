#!/usr/bin/env python3
"""External consumer of the ordinary Daedalus Unix-console Hunger Games.

Pinned source: CruiserOne/Daedalus 32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8.
Oracle: hunger.ds FHelp/Name/Table/FMap, VMoved -> Next -> Moves/Hunger;
command.cpp MoveForward -> DotMove and named-macro grammar; daedalus.cpp
main/DoCommandW/PrintSzCore. Only native user commands cross a genuine PTY.
No game imports, memory reads, gameplay settings changes, seed, or forced statistics.
The sole setting sent on exit disables the documented *console prompt loop*,
not game state. Unix ScreenDot/MessageInside are no-ops: the map observation is
the game's own map-command legend, NOT a graphical arena or TUI screenshot.
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
MAP_LEGEND = ('Arena tribute map...\n\nGold: Cornucopia\n'
              'Gray, maroon: Mountains, walls\nDark cyan: Water\nOther: Tributes')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


# Complete original bytes, including all copyright and redistribution notices.
UPSTREAM = {
    'README.md': '113dfcdec127e5efe74a7d51c2bbee2845fb1457e97bff72b039893686089fb5',
    'license.htm': '9c2023d14fb98b456f6b659b3f855021e59654242cfa10fd0a8a523ad74c114f',
    'changes.htm': 'faacd8fc6679f6ec3726a7537ec7da877d2e0ecac9649997c441d457519e7f36',
    'changes.doc': 'cdf4211121f0cb773bdf5eda302a672aea56b8743e8828183e50c32a47fb76df',
    'daedalus.htm': 'c6b8370d1cafde0df4a83ad71ee67681dad6b8664082c6d3932bdc9eed6f46e1',
    'daedalus.doc': '53c3879b159b5d21534331a9189376ead5b26a0164d44fa6166488b0f568a1dc',
    'script.htm': 'dcd58e2c723b87ea11f5044d0949e9355427fb0e8bdd222ae3a6df6e9ed7e2e8',
    'script.doc': '8814d45eeea176f66d68a786d054d8d3127df35ea4519044b8af90a95563b412',
    'hunger.ds': 'd3f6de1c6ab1b66772b9208d42e61a03fd3963b1732635f26b5e0fce9b35d9df',
    'hunger.bmp': '4d7e871d74628724e20b2195203582b7abeef701303101f8adaa266cfbf56fb0',
}


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
    executable = os.readlink(proc / 'exe')
    proof = {'namespaces': namespaces, 'identity': identity,
             'executable': executable, 'files': raw}
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
    require(all(line.split()[-1] == 'lo' for line in
                raw['net/ipv6_route'].splitlines() if line.strip()),
            'private network has external IPv6 routes')
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
                launcher = str(output / 'bin/hunger-games')
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
        return True

    def prompt(self, label, offset):
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            self.pump()
            if self.raw[offset:].endswith(PROMPT):
                text = bytes(self.raw[offset:-len(PROMPT)]).decode('utf-8').replace('\r\n', '\n')
                (self.evidence / (label + '.console.txt')).write_text(text)
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
        if not self.exited():
            # Failed-run cleanup only; never counted as normal exit evidence.
            os.kill(self.pid, 9)
            os.waitpid(self.pid, 0)
        os.close(self.fd)


def table(text):
    require('Name\t\tHealth\tFood\tKills\n' in text, 'native status header absent')
    rows = {}
    for line in text.splitlines():
        match = re.fullmatch(r'(.+?) *\t(\d+|\(DEAD\))\t(-?\d+)\t(\d+)', line)
        if match:
            name, hp, food, kills = match.groups()
            name = name.strip()
            require(name not in rows, 'duplicate native tribute row: ' + name)
            rows[name] = {'health': None if hp == '(DEAD)' else int(hp),
                          'food': int(food), 'kills': int(kills)}
    require(len(rows) >= 24, 'native status omitted initial 24 tributes')
    return rows


def player_row(help_text, rows):
    match = re.search(r'In this game you are (.+?) \([^\n]+\)\.', help_text)
    require(match is not None, 'native help omitted player identity')
    name = match.group(1)
    require(name != 'Audience', 'ordinary startup selected audience, not a player')
    if name in rows:
        return name
    district = re.fullmatch(r'(?:the )?District (\d+) (Female|Male)', name)
    require(district is not None, 'cannot correlate native help player: ' + name)
    short = 'D' + district.group(1) + ' ' + district.group(2)
    require(short in rows, 'player absent from native table: ' + short)
    return short


def bitmap(path, evidence, label):
    # color.cpp CCol::WriteColmap writes 14+40 header, uncompressed 24-bit
    # bottom-up BGR rows, padded to four bytes. Observe only exported pixels.
    blob = path.read_bytes()
    require(len(blob) >= 54 and blob[:2] == b'BM', 'native bitmap export absent/malformed')
    length, reserved, offset = struct.unpack_from('<III', blob, 2)
    dib, width, height, planes, bits, compression = struct.unpack_from('<IiiHHI', blob, 14)
    require(length == len(blob) and reserved == 0 and offset == 54 and dib == 40
            and planes == 1 and bits == 24 and compression == 0,
            'native export differs from source BMP layout')
    require(width > 0 and height > 0, 'native arena bitmap has no dimensions')
    stride = (width * 3 + 3) & ~3
    require(len(blob) == 54 + height * stride, 'native BMP rows truncated')
    colors = set()
    for y in range(height):
        row = blob[54 + y * stride:54 + y * stride + width * 3]
        colors.update(row[x:x + 3] for x in range(0, len(row), 3))
    require(len(colors) > 1, 'native arena export is blank/uniform')
    (evidence / (label + '.bmp')).write_bytes(blob)
    return {'width': width, 'height': height, 'bits_per_pixel': bits,
            'distinct_colors': len(colors), 'bytes': len(blob),
            'sha256': hashlib.sha256(blob).hexdigest(),
            'scope': 'restored active arena; not tinted map or player-coordinate proof'}


def footprint(root):
    result = {}
    for path in sorted(root.rglob('*')):
        relative = str(path.relative_to(root))
        if path.is_symlink():
            result[relative] = {'kind': 'symlink', 'target': os.readlink(path)}
        elif path.is_dir():
            result[relative] = {'kind': 'directory', 'mode': oct(path.stat().st_mode & 0o777)}
        else:
            data = path.read_bytes()
            result[relative] = {'kind': 'file', 'bytes': len(data),
                                'sha256': hashlib.sha256(data).hexdigest()}
    return result


def main(output, evidence):
    require(os.getpid() == 1, 'consumer not PID 1 in private PID/proc namespace')
    consumer = namespace_proof(Path('/proc/self'), evidence, 'consumer')
    mounts = readonly_store(evidence)
    require((output / 'libexec/hunger-games-real').read_bytes()[:4] == b'\x7fELF',
            'source-built Unix engine is not ELF')
    for path in [output, *output.rglob('*')]:
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, 'output has writable entry: ' + str(path))
        require(path.suffix.lower() not in ('.wav', '.exe'), 'excluded opaque asset installed')
    data = output / 'share/hunger-games'
    require(sorted(path.name for path in data.iterdir()) == ['hunger.bmp', 'hunger.ds'],
            'unexpected game data assets')
    require('By Walter D. Pullen' in (data / 'hunger.ds').read_text(), 'script author notice absent')
    doc = output / 'share/doc/hunger-games'
    for name in ('README.md', 'license.htm', 'changes.htm', 'changes.doc',
                 'daedalus.htm', 'daedalus.doc', 'script.htm', 'script.doc'):
        require((doc / name).stat().st_size > 0, 'full rights/manual file absent: ' + name)
    license_text = (doc / 'license.htm').read_text(encoding='cp1252')
    require('GNU GENERAL PUBLIC LICENSE' in license_text and 'Version 2, June 1991' in license_text,
            'GPLv2 text absent')
    changes = (doc / 'changes.htm').read_text(encoding='cp1252')
    require('Walter D.' in changes and 'Pullen' in changes, 'copyright author absent')
    originals = {}
    for name, expected_hash in UPSTREAM.items():
        path = (data if name in ('hunger.ds', 'hunger.bmp') else doc) / name
        blob = path.read_bytes()
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
        session.prompt('startup', 0)
        startup = session.command('player-help', '*FHelp')
        require('Happy Hunger Games!' in startup, 'native player help not observed')
        game = namespace_proof(Path('/proc') / str(session.pid), evidence, 'game')
        require(game['executable'] == str(output / 'libexec/hunger-games-real'),
                'ordinary launcher did not exec installed source-built engine')
        proc = Path('/proc') / str(session.pid)
        argv = (proc / 'cmdline').read_bytes().split(b'\0')[:-1]
        require(argv == [str(output / 'libexec/hunger-games-real').encode(),
                         b"OpenScript 'hunger.ds' fNoExit 1 fSkipMessageDisplay 0"],
                'unexpected launcher engine arguments')
        descriptors = {str(fd): os.readlink(proc / 'fd' / str(fd)) for fd in (0, 1, 2)}
        require(len(set(descriptors.values())) == 1 and descriptors['0'].startswith('/dev/pts/'),
                'engine not attached to one genuine PTY')
        record(evidence / 'game-entry.json', {'argv': [arg.decode() for arg in argv],
                                             'stdio': descriptors, 'environment': env})
        baseline = table(session.command('status-before', '*FTable'))
        player = player_row(startup, baseline)
        require(baseline[player]['health'] is not None, 'native player starts dead')
        map_before = session.command('map-before', '*FMap')
        require(MAP_LEGEND in map_before, 'native map legend absent before movement')
        session.command('export-before', 'SaveBitmap "arena-before.bmp"')
        state_dir = root / 'state/hunger-games'
        arena_before = bitmap(state_dir / 'arena-before.bmp', evidence, 'arena-before')
        unchanged = table(session.command('status-after-map', '*FTable'))
        require(unchanged == baseline, 'non-turn map/status commands changed tribute statistics')
        moves = []
        current = baseline
        # Ordinary compass actions allow a blocked direction to be observed,
        # without changing settings, teleporting, restarting, or forcing RNG.
        for index, command in enumerate(('MoveForward', 'MoveNorth', 'MoveEast',
                                         'MoveSouth', 'MoveWest', 'MoveForward')):
            response = session.command('movement-' + str(index), command)
            following = table(session.command('status-movement-' + str(index), '*FTable'))
            moves.append({'command': command, 'before': current[player],
                          'after': following[player], 'response': response})
            current = following
            if current[player]['food'] < baseline[player]['food']:
                break
            require(current[player]['health'] is not None, 'player died before observed movement turn')
        require(current[player]['food'] < baseline[player]['food'],
                'ordinary movement produced no observed player turn/food consumption')
        map_after = session.command('map-after', '*FMap')
        require(MAP_LEGEND in map_after, 'native map legend absent after movement')
        session.command('export-after', 'SaveBitmap "arena-after.bmp"')
        arena_after = bitmap(state_dir / 'arena-after.bmp', evidence, 'arena-after')
        require((arena_before['width'], arena_before['height']) ==
                (arena_after['width'], arena_after['height']), 'movement resized arena')
        final = table(session.command('status-after-movement-map', '*FTable'))
        require(final == current, 'map/status observations altered tribute statistics')
        session.finish()
        after = footprint(root)
        record(evidence / 'state-after.json', after)
        expected = dict(before)
        expected['state/hunger-games'] = {'kind': 'directory', 'mode': '0o700'}
        for name in ('hunger.ds', 'hunger.bmp'):
            expected['state/hunger-games/' + name] = {'kind': 'symlink', 'target': str(data / name)}
        for name, exported in (('arena-before.bmp', arena_before), ('arena-after.bmp', arena_after)):
            expected['state/hunger-games/' + name] = {
                'kind': 'file', 'bytes': exported['bytes'], 'sha256': exported['sha256']}
        require(after == expected, 'unexpected native state footprint (see state-after.json)')
        record(evidence / 'result.json', {
            'status': 'passed', 'scope': 'ordinary Unix console, not graphical frontend',
            'source_commit': COMMIT, 'source_anchors': {
                'startup': SOURCE + 'hunger.ds#L336-L364',
                'default_message_display': SOURCE + 'daedalus.htm#L1887-L1888',
                'status': SOURCE + 'hunger.ds#L2577-L2593',
                'map_legend_only': SOURCE + 'hunger.ds#L676-L700',
                'movement_event': SOURCE + 'hunger.ds#L1358-L1387',
                'food_consumption': SOURCE + 'hunger.ds#L1880-L1885',
                'engine_movement': SOURCE + 'command.cpp#L4433-L4444',
                'native_export': SOURCE + 'script.htm#L1826-L1828',
                'export_layout': SOURCE + 'color.cpp#L2503-L2532',
                'prompt_and_exit': SOURCE + 'daedalus.cpp#L3078-L3113'},
            'player': player, 'baseline_status': baseline, 'movement': moves,
            'post_movement_status': current, 'native_map_legend': MAP_LEGEND,
            'arena_exports': {'before': arena_before, 'after': arena_after},
            'exit': {'command': 'fNoExit 0 Exit', 'status': session.status,
                     'lifecycle_only': True, 'signals_or_eof_used': False},
            'consumer': consumer, 'game': game, 'store_mounts': mounts,
            'state_footprint': after})
    finally:
        session.close()


if __name__ == '__main__':
    evidence = Path(sys.argv[2])
    try:
        main(Path(sys.argv[1]), evidence)
    except BaseException as error:
        record(evidence / 'failure.json', {'error': str(error), 'traceback': traceback.format_exc()})
        raise
