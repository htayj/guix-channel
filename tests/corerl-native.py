#!/usr/bin/env python3
"""Consume the ordinary zero-argument CoreRL launcher through a real PTY.

The complete 1kcore.c is the oracle for map glyphs, native arrows, bumping,
and quitting. No seed, restart, memory access, synthetic argument, or injected
state is used. Evidence is raw terminal bytes and decoded text/JSON, not PNG.
Run only through corerl-smoke.sh's private same-identity offline namespaces.
"""
import codecs
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import select
import struct
import subprocess
import sys
import termios
import time
import traceback

import pyte

ROWS, COLS, MAP_SIZE = 25, 80, 16
SOURCE_URL = 'https://www.roguelikeeducation.org/vault/core/1kcore.c'
GRANT_URL = 'https://www.roguelikeeducation.org/2.html'
SOURCE_SHA256 = '05d55844b30fbfae72bd87ab9e26539cfb8232e540bc0d0ce50b04d6d1369e24'
NOTICE = (
    'CoreRL 1 KiB (1kib-20131024)\n'
    'Canonical source: https://www.roguelikeeducation.org/vault/core/1kcore.c\n'
    "Grant: Studio Tectorum, 'coreRL in 1kib', 2013-10-24\n"
    'https://www.roguelikeeducation.org/2.html\n'
    '"This version of the source is also released into the public domain"\n'
    'The article links that grant directly to 1kcore.c.\n'
    'The complete, unmodified 1023-byte source is installed alongside this notice.\n'
    'Source SHA-256: ' + SOURCE_SHA256 + '\n'
    'The executable is compiled from that source; no upstream binaries or other assets are included.\n'
).encode('utf-8')
ARROWS = (
    ('up', 0, -1, b'\x1bOA'), ('down', 0, 1, b'\x1bOB'),
    ('left', -1, 0, b'\x1bOD'), ('right', 1, 0, b'\x1bOC'),
)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


def namespace_proof(proc, evidence, label):
    namespaces = {name: os.readlink(proc / 'ns' / name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    raw = {name: (proc / name).read_text() for name in
           ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route')}
    executable = os.readlink(proc / 'exe')
    identity = {}
    for line in raw['status'].splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(part) for part in value.split()]
    proof = {'namespaces': namespaces, 'identity': identity,
             'executable': executable, 'files': raw}
    record(evidence / (label + '-namespace-raw.json'), proof)
    for name, host in (('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                       ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')):
        require(namespaces[name] != os.environ[host], 'not in private ' + name + ' namespace')
        require(namespaces[name] == os.readlink('/proc/self/ns/' + name),
                'process escaped private ' + name + ' namespace')
    for kind, variable, field in (('uid', 'HOST_UID', 'Uid'), ('gid', 'HOST_GID', 'Gid')):
        expected = int(os.environ[variable])
        require(identity[field] == [expected] * 4, 'caller ' + kind + ' changed')
        require([int(part) for part in raw[kind + '_map'].split()] ==
                [expected, expected, 1], 'not a same-identity ' + kind + ' mapping')
    interfaces = sorted(line.split(':')[0].strip() for line in
                        raw['net/dev'].splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'network namespace contains external interfaces')
    routes = [line.split() for line in raw['net/route'].splitlines() if line.strip()]
    header = ['Iface', 'Destination', 'Gateway', 'Flags', 'RefCnt', 'Use', 'Metric',
              'Mask', 'MTU', 'Window', 'IRTT']
    require(not routes or routes == [header], 'offline namespace has IPv4 routes')
    require(all(line.split()[-1] == 'lo' for line in
                raw['net/ipv6_route'].splitlines() if line.strip()),
            'offline namespace has non-loopback IPv6 routes')
    proof['interfaces'] = interfaces
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


class Screen(pyte.Screen):
    last_graphic = ''

    def draw(self, data):
        super().draw(data)
        if data:
            self.last_graphic = data[-1]

    def repeat_character(self, count=1):
        if self.last_graphic:
            super().draw(self.last_graphic * (count or 1))


class Stream(pyte.Stream):
    # ncurses xterm terminfo emits ECMA-48 REP, absent from stock pyte 0.8.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, output, evidence, work, env):
        self.evidence = evidence
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.raw = bytearray()
        self.decoded = ''
        self.inputs = []
        self.input_offset = -1
        self.status = None
        self.eof = False
        self.quit_requested = False
        (evidence / 'terminal.raw').write_bytes(b'')
        (evidence / 'terminal.decoded.txt').write_text('')
        record(evidence / 'pty-inputs.json', self.inputs)
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(work)
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                launcher = str(output / 'bin/corerl')
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
        if self.eof:
            time.sleep(seconds)
            return False
        if self.fd not in select.select([self.fd], [], [], seconds)[0]:
            return False
        try:
            data = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        if not data:
            self.eof = True
            text = self.decoder.decode(b'', final=True)
        else:
            self.raw.extend(data)
            with (self.evidence / 'terminal.raw').open('ab') as stream:
                stream.write(data)
            text = self.decoder.decode(data)
        self.decoded += text
        with (self.evidence / 'terminal.decoded.txt').open('a', encoding='utf-8') as stream:
            stream.write(text)
        self.stream.feed(text)
        return bool(data)

    def await_screen(self, predicate, label):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            self.pump()
            if len(self.raw) > self.input_offset and predicate():
                while self.pump(0.15):
                    require(time.monotonic() < deadline, 'terminal never settled: ' + label)
                if predicate():
                    return self.snapshot(label)
            require(not self.exited(), 'game exited before ' + label)
        self.snapshot('timeout-' + label)
        raise RuntimeError('native screen timeout: ' + label)

    def snapshot(self, label):
        screen = {'rows': list(self.screen.display),
                  'cursor': {'x': self.screen.cursor.x, 'y': self.screen.cursor.y},
                  'raw_bytes': len(self.raw)}
        record(self.evidence / (label + '.screen.json'), screen)
        (self.evidence / (label + '.screen.txt')).write_text(
            '\n'.join(screen['rows']) + '\n', encoding='utf-8')
        (self.evidence / (label + '.raw')).write_bytes(self.raw)
        (self.evidence / (label + '.decoded.txt')).write_text(self.decoded, encoding='utf-8')
        return screen

    def send(self, label, data):
        require(not self.exited(), 'cannot send input to exited game')
        self.input_offset = len(self.raw)
        item = {'label': label, 'hex': data.hex(), 'raw_offset': len(self.raw), 'written': 0}
        self.inputs.append(item)
        record(self.evidence / 'pty-inputs.json', self.inputs)
        item['written'] = os.write(self.fd, data)
        record(self.evidence / 'pty-inputs.json', self.inputs)
        require(item['written'] == len(data), 'short PTY write')
        if data == b'q':
            self.quit_requested = True

    def finish(self):
        deadline = time.monotonic() + 10
        while not self.exited() and time.monotonic() < deadline:
            self.pump()
        require(self.exited(), 'native q did not terminate game')
        while self.pump(0.05):
            require(time.monotonic() < deadline, 'exit terminal never settled')
        return self.snapshot('exit')

    def close(self):
        cleanup = {'graceful_input': None, 'exit_status': self.status}
        try:
            if not self.exited() and not self.quit_requested:
                self.send('failure-graceful-quit', b'q')
                cleanup['graceful_input'] = 'q'
            deadline = time.monotonic() + 3
            while not self.exited() and time.monotonic() < deadline:
                self.pump()
            cleanup['exit_status'] = self.status
            cleanup['awaiting_outer_timeout'] = not self.exited()
            record(self.evidence / 'session-close.json', cleanup)
            # Never signal or close a live PTY (which could send SIGHUP). If q
            # cannot finish, keep PID 1 alive for the shell's external timeout.
            while not self.exited():
                self.pump()
            while self.pump(0.05):
                pass
        except BaseException as error:
            cleanup['error'] = str(error)
            record(self.evidence / 'session-close.json', cleanup)
            while not self.exited():
                time.sleep(0.1)
        finally:
            self.snapshot('session-final')
            record(self.evidence / 'pty-inputs.json', self.inputs)
            if self.status is not None:
                os.close(self.fd)


def map_state(session):
    rows = [row[:MAP_SIZE] for row in session.screen.display[:MAP_SIZE]]
    if any(set(row) - set('#.@<e') for row in rows):
        return None
    if rows[0] != '#' * MAP_SIZE or rows[-1] != '#' * MAP_SIZE or any(
            row[0] != '#' or row[-1] != '#' for row in rows):
        return None
    if any(row[MAP_SIZE:].strip() for row in session.screen.display[:MAP_SIZE]) or any(
            row.strip() for row in session.screen.display[MAP_SIZE:]):
        return None
    positions = {glyph: [[x, y] for y, row in enumerate(rows)
                         for x, value in enumerate(row) if value == glyph]
                 for glyph in '#.@<e'}
    if len(positions['@']) != 1 or len(positions['<']) != 1 or len(positions['e']) > 1:
        return None
    return {'rows': rows, 'position': positions['@'][0], 'enemies': positions['e'],
            'stairs': positions['<'][0],
            'glyph_counts': {glyph: len(points) for glyph, points in positions.items()}}


def distance(first, second):
    return sum(abs(a - b) for a, b in zip(first, second))


def decision_for(before):
    x, y = before['position']
    enemy = before['enemies'][0]
    for name, dx, dy, key in ARROWS:
        target = [x + dx, y + dy]
        if before['rows'][target[1]][target[0]] == '.' and distance(target, enemy) > 1:
            return {'kind': 'safe-floor', 'direction': name, 'target': target,
                    'enemy_distance_to_target': distance(target, enemy)}, key
    for name, dx, dy, key in ARROWS:
        target = [x + dx, y + dy]
        if target == enemy:
            return {'kind': 'adjacent-enemy-bump', 'direction': name, 'target': target,
                    'enemy_distance_to_target': 0}, key
    raise RuntimeError('observed level 1 has no safe adjacent floor or adjacent enemy; no retry')


def movement_proof(before, after, target):
    require(after['position'] == target and distance(before['position'], target) == 1,
            'native arrow did not displace the player exactly one tile to the observed target')
    x, y = before['position']
    # The player vacates to floor before the AI acts; the enemy may then
    # occupy that same tile before the next getch redraw is observable.
    require(after['rows'][y][x] == ('e' if before['position'] in after['enemies'] else '.'),
            'vacated player tile differs from the completed native turn')
    require(after['stairs'] == before['stairs'], 'movement changed native stairs')
    require(len(after['enemies']) == len(before['enemies']), 'safe movement changed enemy count')
    allowed = {tuple(before['position']), tuple(target)}
    if before['enemies']:
        old, new = before['enemies'][0], after['enemies'][0]
        require(distance(old, new) <= 1, 'enemy moved more than one axis/tile on one turn')
        allowed.update((tuple(old), tuple(new)))
        if old != new:
            require((before['rows'][new[1]][new[0]] == '.' or new == before['position']) and
                    after['rows'][old[1]][old[0]] == '.',
                    'enemy transition did not preserve native floor')
    for row in range(MAP_SIZE):
        for column in range(MAP_SIZE):
            if (column, row) not in allowed:
                require(before['rows'][row][column] == after['rows'][row][column],
                        'movement altered unrelated native map tile')


def game_proof(session, output, evidence, env):
    proc = Path('/proc') / str(session.pid)
    native = namespace_proof(proc, evidence, 'game')
    executable = output / 'libexec/corerl'
    require(Path(native['executable']).resolve() == executable.resolve(),
            'ordinary launcher did not exec the installed native game')
    cmdline = (proc / 'cmdline').read_bytes()
    terminal_fds = {str(fd): os.readlink(proc / 'fd' / str(fd)) for fd in (0, 1, 2)}
    geometry = list(struct.unpack('HHHH', fcntl.ioctl(
        session.fd, termios.TIOCGWINSZ, struct.pack('HHHH', 0, 0, 0, 0))))
    stat = (proc / 'stat').read_text()
    fields = stat[stat.rfind(')') + 2:].split()
    terminal = {'session': int(fields[3]), 'tty_nr': int(fields[4]),
                'foreground_pgrp': int(fields[5]), 'pgrp': int(fields[2])}
    observed_env = dict(item.decode('utf-8').split('=', 1) for item in
                        (proc / 'environ').read_bytes().split(b'\0') if item)
    native.update({'cmdline_hex': cmdline.hex(), 'terminal_fds': terminal_fds,
                   'controlling_terminal': terminal, 'environment': observed_env,
                   'terminal_geometry': geometry})
    record(evidence / 'game-process.json', native)
    require(cmdline == os.fsencode(executable) + b'\0', 'native cmdline is not zero arguments')
    require(os.isatty(session.fd) and len(set(terminal_fds.values())) == 1 and
            terminal_fds['0'].startswith('/dev/pts/'),
            'game stdin/stdout/stderr are not the same real PTY')
    require(geometry[:2] == [ROWS, COLS], 'observed PTY geometry is not 80x25')
    require(terminal['tty_nr'] != 0 and terminal['session'] == session.pid and
            terminal['foreground_pgrp'] == terminal['pgrp'] == session.pid,
            'forkpty did not give the game its own controlling foreground terminal')
    # The ordinary launcher supplies TERMINFO_DIRS (and its shell may export
    # shell bookkeeping). The private whitelist is the execve input, not a
    # fabricated claim that the launcher leaves the effective environment bare.
    require(all(observed_env.get(name) == value for name, value in env.items()),
            'ordinary launcher changed a supplied private environment value')
    native['launcher_environment_additions'] = {
        name: value for name, value in observed_env.items() if name not in env}
    record(evidence / 'game-process.json', native)
    return native


def private_entries(root):
    return {directory.name: sorted(str(path.relative_to(directory))
                                  for path in directory.rglob('*'))
            for directory in sorted(root.iterdir())}


def main(output, evidence):
    require(output.is_absolute() and output.parent == Path('/gnu/store') and output.is_dir(),
            'OUTPUT must be an absolute store item')
    require(evidence.is_absolute() and evidence.is_dir() and not evidence.is_symlink() and
            not evidence.resolve().is_relative_to(Path('/gnu/store')),
            'EVIDENCE must be an existing fresh absolute directory outside the store')
    require(os.getpid() == 1, 'consumer is not PID 1 in private PID/proc namespace')
    consumer = namespace_proof(Path('/proc/self'), evidence, 'consumer')
    mounts = readonly_store(evidence)
    doc = output / 'share/doc/corerl'
    source = (doc / '1kcore.c').read_bytes()
    notice = (doc / 'NOTICE').read_bytes()
    provenance = {'source_url': SOURCE_URL, 'grant_url': GRANT_URL,
                  'grant_author': 'Studio Tectorum', 'grant_date': '2013-10-24',
                  'files': {'1kcore.c': {'bytes': len(source),
                                       'sha256': hashlib.sha256(source).hexdigest()},
                            'NOTICE': {'bytes': len(notice),
                                       'sha256': hashlib.sha256(notice).hexdigest()}}}
    record(evidence / 'upstream-files.json', provenance)
    require(len(source) == 1023 and hashlib.sha256(source).hexdigest() == SOURCE_SHA256,
            'complete canonical 1023-byte source differs')
    require(notice == NOTICE, 'complete exact upstream grant NOTICE differs')
    with (output / 'libexec/corerl').open('rb') as stream:
        require(stream.read(4) == b'\x7fELF', 'installed source-built runtime is not ELF')
    for path in [output, *output.rglob('*')]:
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, 'installed output has writable entry: ' + str(path))
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
    require(all(path.stat().st_mode & 0o777 == 0o700 for path in [root, *root.iterdir()]),
            'private state directory mode is not 0700')
    initial_entries = private_entries(root)
    require(all(not entries for entries in initial_entries.values()), 'private state was not fresh')
    runtime = {'status': 'running', 'launcher': str(output / 'bin/corerl'), 'arguments': [],
               'environment': env, 'rows': ROWS, 'columns': COLS,
               'coordinate_origin': 'zero-based x,y', 'provenance': provenance,
               'private_state_before': initial_entries, 'rng_control': None,
               'observed_displacements': 0, 'observed_bumps': 0,
               'limitations': ['One level-1 displacement only; no victory or death claim',
                               'Optional adjacent-enemy bump only, not general combat coverage',
                               'No upstream save/restore operation; only absence of writes is observed',
                               'No RNG seed, retry, restart, synthetic argument, or state injection',
                               'Decoded terminal text/JSON and raw bytes, not PNG screenshots',
                               'Source-built attribution comes from packaging; ELF alone is not build proof',
                               'Output NAR equality is checked by corerl-smoke.sh']}
    record(evidence / 'runtime.json', runtime)
    session = Session(output, evidence, work, env)
    try:
        runtime['initial_screen'] = session.await_screen(
            lambda: (state := map_state(session)) is not None and len(state['enemies']) == 1,
            'initial')
        before = map_state(session)
        runtime['before'] = before
        native = game_proof(session, output, evidence, env)
        runtime['effective_game_environment'] = native['environment']
        runtime['launcher_environment_additions'] = native['launcher_environment_additions']
        record(evidence / 'namespace-proof.json',
               {'consumer': consumer, 'game': native, 'store_mounts': mounts})
        decision, key = decision_for(before)
        runtime['safety_input_decision'] = decision
        record(evidence / 'runtime.json', runtime)
        moving_from = before
        if decision['kind'] == 'adjacent-enemy-bump':
            session.send('native-enemy-bump-' + decision['direction'], key)
            runtime['bump_screen'] = session.await_screen(
                lambda: (state := map_state(session)) is not None and
                state['position'] == before['position'] and not state['enemies'], 'bump')
            bumped = map_state(session)
            expected = list(before['rows'])
            x, y = decision['target']
            expected[y] = expected[y][:x] + '.' + expected[y][x + 1:]
            require(bumped['rows'] == expected,
                    'native bump did not remove only the enemy without displacement or response')
            runtime['bump'] = bumped
            runtime['observed_bumps'] = 1
            moving_from = bumped
            record(evidence / 'runtime.json', runtime)
        session.send('native-move-' + decision['direction'], key)
        runtime['moved_screen'] = session.await_screen(
            lambda: (state := map_state(session)) is not None and
            state['position'] == decision['target'], 'moved')
        after = map_state(session)
        movement_proof(moving_from, after, decision['target'])
        runtime.update({'after': after, 'observed_displacements': 1,
                        'position_delta': [a - b for a, b in zip(after['position'], before['position'])],
                        'arrow_inputs_observed': sum(item['written'] == len(key)
                                                     for item in session.inputs)})
        record(evidence / 'runtime.json', runtime)
        session.send('normal-quit', b'q')
        runtime['exit_screen'] = session.finish()
        runtime['exit_status'] = session.status
        record(evidence / 'runtime.json', runtime)
        require(session.status == 0, 'native game exited ' + str(session.status))
        require(b'Quit on level 1.\r\n' in session.raw and b'Died on level ' not in session.raw,
                'native quit text is not exact level-1 quit, or a death was observed')
        require([row.rstrip() for row in session.screen.display].count('Quit on level 1.') == 1,
                'native quit was not rendered as exactly one standalone line')
        entries = private_entries(root)
        runtime['private_state_after'] = entries
        require(entries == initial_entries, 'native game wrote private HOME/XDG/tmp/work state')
        require(all(path.is_dir() and not path.is_symlink() and
                    path.stat().st_mode & 0o777 == 0o700 for path in [root, *root.iterdir()]),
                'native game changed private state directory types or modes')
        runtime.update({'status': 'passed', 'quit': 'q', 'quit_message': 'Quit on level 1.',
                        'store_read_only': True})
        record(evidence / 'runtime.json', runtime)
    except BaseException as error:
        runtime.update({'status': 'failed', 'exit_status': session.status,
                        'private_state_after': private_entries(root)})
        record(evidence / 'runtime.json', runtime)
        session.snapshot('failure')
        record(evidence / 'failure.json', {'error': str(error), 'traceback': traceback.format_exc()})
        raise
    finally:
        session.close()


if __name__ == '__main__':
    require(len(sys.argv) == 3, 'usage: corerl-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    try:
        main(output, evidence)
    except BaseException as error:
        if evidence.is_dir() and not (evidence / 'failure.json').exists():
            record(evidence / 'failure.json', {'error': str(error), 'traceback': traceback.format_exc()})
        raise
