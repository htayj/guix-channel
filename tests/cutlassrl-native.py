#!/usr/bin/env python3
"""Observe ordinary CutlassRL gameplay externally, through a real terminal.

The pinned Python 2 game owns all map generation, input, saves and restoration.
This Python 3 consumer never imports game code, edits saves, or controls its RNG.
Screens are decoded observations, not reconstructed state or graphical proof.
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

COMMIT = '304bb87fc185726f3f7afb08c69564687003d093'
SOURCE_URL = 'https://github.com/stenno/CutlassRL'
SOURCE_NAR_SHA256 = '1d2dz0c2xlp5xlkn136apbyc1cgfdypfr2k9kds30yy2gv13jk8h'
ROWS, COLS = 40, 120
NAME = 'NativeCutlass'


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
    for kind, variable, field in (('uid', 'HOST_UID', 'Uid'), ('gid', 'HOST_GID', 'Gid')):
        expected = int(os.environ[variable])
        require(identity[field] == [expected] * 4, 'caller ' + kind + ' changed')
        require([int(part) for part in raw[kind + '_map'].split()] == [expected, expected, 1],
                'not a same-identity ' + kind + ' mapping')
    interfaces = sorted(line.split(':')[0].strip() for line in
                        raw['net/dev'].splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'network namespace contains external interfaces')
    ipv4_rows = [line.split() for line in raw['net/route'].splitlines() if line.strip()]
    if ipv4_rows:
        require(ipv4_rows[0] ==
                ['Iface', 'Destination', 'Gateway', 'Flags', 'RefCnt', 'Use', 'Metric',
                 'Mask', 'MTU', 'Window', 'IRTT'], 'unexpected /proc/net/route header')
        require(not ipv4_rows[1:], 'offline namespace has IPv4 routes')
    ipv6_rows = [line.split() for line in raw['net/ipv6_route'].splitlines() if line.strip()]
    require(all(row[-1] == 'lo' for row in ipv6_rows), 'offline namespace has external IPv6 routes')
    return {'namespaces': namespaces, 'identity': identity, 'maps': {kind: raw[kind + '_map']
            for kind in ('uid', 'gid')}, 'interfaces': interfaces,
            'routes': {kind: raw['net/' + kind] for kind in ('route', 'ipv6_route')},
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
    require(found and any(target == '/gnu/store' for target, _, _ in found), 'store mount missing')
    require(all('ro' in options and 'rw' not in options and not
                any(item.startswith(('shared:', 'master:')) for item in optional)
                for _, options, optional in found), 'store is not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store filesystem is writable')
    return found


class Session:
    def __init__(self, output, evidence, work, env):
        self.evidence = evidence
        evidence.mkdir(mode=0o700)
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.raw = bytearray()
        self.keys = []
        self.status = None
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(work)
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                launcher = str(output / 'bin/cutlassrl')
                os.execve(launcher, [launcher, NAME], env)
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
        deadline = time.monotonic() + 12
        candidate = None
        stable_since = None
        observations = 0
        raw_start = len(self.raw)
        diagnostics = []
        previous_rows = None
        while time.monotonic() < deadline:
            self.pump()
            now = time.monotonic()
            rows = tuple(self.screen.display)
            cursor = {'x': self.screen.cursor.x, 'y': self.screen.cursor.y}
            # Game.mainLoop ends every map redraw with printex(x,y,'@'),
            # refresh=True. Only the cursor immediately after the sole @ is
            # a completed player refresh; intermediate floor/HUD writes are
            # not state observations and must not reset a completed frame.
            complete = (0 < cursor['x'] <= COLS and 0 <= cursor['y'] < ROWS and
                        rows[cursor['y']][cursor['x'] - 1] == '@' and
                        sum(row[:62].count('@') for row in rows[:22]) == 1)
            matches = bool(predicate())
            diagnostics.append({'raw_bytes': len(self.raw), 'predicate': matches,
                                'complete_player_refresh': complete, 'cursor': cursor,
                                'changed_rows': [index for index, row in enumerate(rows)
                                                 if previous_rows is None or row != previous_rows[index]],
                                'hud': {str(index): rows[index][63:].rstrip()
                                        for index in (2, 4, 6, 8, 10, 12)},
                                'players': [[index, row.index('@')] for index, row in enumerate(rows[:22])
                                            if '@' in row[:62]]})
            previous_rows = rows
            frame = rows
            # The quit prompt is drawn at row0 after the player refresh and
            # blocks in readkey; it is its own complete source event boundary.
            boundary = complete or rows[0].startswith("PRESS '!' TO QUIT:")
            if boundary and matches:
                if frame != candidate:
                    candidate = frame
                    stable_since = now
                    observations = 1
                    raw_start = len(self.raw)
                else:
                    observations += 1
                # IO.rkey halfdelay(2) can redraw terrain/@ indefinitely.
                # Compare exact decoded completed frames across two polling
                # cycles; cursor is an event boundary, not persistent state.
                # Neither raw silence nor intermediate redraw stability counts.
                if observations >= 3 and now - stable_since >= 0.45:
                    self.snapshot(label)
                    record(self.evidence / (label + '-readiness.json'),
                           {'oracle': 'unchanged decoded rows at completed source refresh with predicate true',
                            'observations': observations, 'stable_seconds': now - stable_since,
                            'raw_bytes_during_stability': len(self.raw) - raw_start})
                    record(self.evidence / (label + '-observations.json'), diagnostics)
                    return
            elif boundary:
                candidate = None
                stable_since = None
                observations = 0
            require(not self.exited(), 'game exited before ' + label)
        self.snapshot('timeout-' + label)
        record(self.evidence / (label + '-observations.json'), diagnostics)
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
        deadline = time.monotonic() + 12
        while not self.exited() and time.monotonic() < deadline:
            self.pump()
        require(self.exited(), 'native quit did not terminate game')
        while self.pump(0.05):
            pass
        self.snapshot('exit')
        require(self.status == 0, 'native game exited ' + str(self.status))
        text = bytes(self.raw).decode('utf-8')
        require(not re.search(r'Traceback \(most recent call last\)|(?:\w*Error|\w*Exception):|'
                              r'Curses library is missing\.', text),
                'Python 2 error was printed despite native exit status zero')

    def close(self):
        (self.evidence / 'terminal.raw').write_bytes(self.raw)
        record(self.evidence / 'pty-inputs.json', self.keys)
        record(self.evidence / 'process.json', {'pid': self.pid, 'exit_status': self.status})
        # The enclosing private PID namespace and bounded executor own failure
        # teardown; this consumer never signals a game to claim a normal quit.
        os.close(self.fd)


# The encoding cookie is not a rights notice. A dated downstream modification
# notice may legitimately sit between it and the unchanged upstream grant.
GPL_HEADER = '''#     This file is part of CutlassRL.
#
#    CutlassRL is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    CutlassRL is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with CutlassRL.  If not, see <http://www.gnu.org/licenses/>.
'''
UNICURSES_HEADER = '''# UniCurses -- A unified multiplatform Curses provider library for Python 2.x/3.x
# Copyright (C) 2010 by Michael Kamensky.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#    Copyright (c) init
'''
FOV_NOTICE = '''"""
    Author:         Aaron MacDonald
    Date:           June 14, 2007

    Description:    An implementation of the precise permissive field
                    of view algorithm for use in tile-based games.
                    Based on the algorithm presented at
                    http://roguebasin.roguelikedevelopment.org/
                      index.php?title=
                      Precise_Permissive_Field_of_View.

    You are free to use or modify this code as long as this notice is
    included.
    This code is released without warranty.
"""'''


def notices(output, evidence):
    runtime = output / 'libexec/cutlassrl'
    records = {}
    for relative in ('main.py', 'Game.py', 'Modules/AStar.py', 'Modules/Cell.py',
                     'Modules/Constants.py', 'Modules/Fov.py', 'Modules/IO.py',
                     'Modules/Level.py', 'Modules/You.py'):
        text = (runtime / relative).read_text()
        require('# -*- coding: utf-8 -*-\n' in text,
                'upstream source encoding declaration changed: ' + relative)
        require(GPL_HEADER in text, 'exact upstream GPL3+ header changed: ' + relative)
        if relative != 'main.py':
            require(GPL_HEADER + '#    Copyright (c) init\n' in text,
                    'upstream copyright notice changed: ' + relative)
        records[relative] = {'sha256': hashlib.sha256((runtime / relative).read_bytes()).hexdigest(),
                             'exact_upstream_header': True}
    require((runtime / 'Modules/Unicurses.py').read_text().startswith(UNICURSES_HEADER),
            'independent UniCurses GPL3+ grant/copyright changed')
    require(FOV_NOTICE in (runtime / 'Modules/Fov.py').read_text(),
            'independent Aaron MacDonald FOV permission notice changed')
    for path, expected in ((runtime / 'COPYING', '94a9ed024d3859793618152ea559a168bbcbb5e2'),
                           (output / 'share/doc/cutlassrl/README', 'a9ae93dfd66c2b56b3f647c2508135900bfc84af')):
        data = path.read_bytes()
        git_hash = hashlib.sha1(b'blob ' + str(len(data)).encode('ascii') + b'\0' + data).hexdigest()
        require(git_hash == expected, 'complete pinned upstream notice differs: ' + str(path))
        records[str(path.relative_to(output))] = {'git_blob_sha1': git_hash, 'bytes': len(data)}
    for name in ('pdcurses.dll', 'cpf.sh', 'rldev.pl'):
        require(not (runtime / name).exists(), 'non-runtime upstream file installed: ' + name)
    require((runtime / 'Levels/last.lvl').is_file(), 'native level resource missing')
    for path in output.rglob('*'):
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, 'installed output has writable entries')
    record(evidence / 'upstream-notices.json', {
        'source_url': SOURCE_URL, 'source_revision': COMMIT,
        'source_method': 'git-fetch', 'source_nar_sha256_base32': SOURCE_NAR_SHA256,
        'files': records, 'unicurses_grant': UNICURSES_HEADER, 'fov_permission': FOV_NOTICE})


def ready(session):
    rows = session.screen.display
    return rows[2][63:].rstrip() == NAME and rows[4][63:].rstrip() == 'Player' and \
        re.fullmatch(r'HP:\d+/\d+ *', rows[6][63:]) is not None and \
        re.fullmatch(r'T:\d+ *', rows[8][63:]) is not None and \
        sum(row[:62].count('@') for row in rows[:22]) == 1


def state(session):
    require(ready(session), 'native player map/HUD missing')
    rows = session.screen.display
    values = {'name': rows[2][63:].rstrip(), 'mode': rows[4][63:].rstrip()}
    for key, row, pattern in (('hp', 6, r'HP:(\d+)/(\d+)'), ('turns', 8, r'T:(\d+)'),
                              ('score', 10, r'Score:(\d+)'), ('level', 12, r'Level:(\d+)')):
        match = re.fullmatch(pattern + r' *', rows[row][63:])
        require(match is not None, 'native HUD field differs: ' + key)
        numbers = [int(value) for value in match.groups()]
        values[key] = numbers if len(numbers) > 1 else numbers[0]
    # addMsg owns row 22; exclude it from terrain continuity so the native
    # Saved... and Loaded... messages cannot masquerade as changed terrain.
    values['map'] = [row[:62] for row in rows[:22]]
    values['position'] = next([y, row.index('@')] for y, row in enumerate(values['map']) if '@' in row)
    require(values['hp'][0] > 0 and any('.' in row for row in values['map']),
            'living player and generated native floor missing')
    return values


def move(session, label):
    before = state(session)
    y, x = before['position']
    # Pick a visible ordinary floor adjacent to the actual random spawn. Do
    # not prescribe a seed, alter the level, or mistake a wall bump for a move.
    choices = [(key, dy, dx) for key, dy, dx in
               ((b'l', 0, 1), (b'h', 0, -1), (b'j', 1, 0), (b'k', -1, 0))
               if 0 <= y + dy < 22 and 0 <= x + dx < 62 and
               before['map'][y + dy][x + dx] == '.']
    require(choices, 'native player has no adjacent visible ordinary floor')
    key, dy, dx = choices[0]
    session.send(label, key)
    session.await_screen(lambda: ready(session) and
                         state(session)['position'] == [y + dy, x + dx], label)
    after = state(session)
    # playerTurn's timeout (-1) can reset turn before the outer loop counts
    # it. Position/redraw is the source-backed movement oracle, not T:+1.
    require(after['turns'] >= before['turns'], 'native turn counter moved backwards')
    require(after['map'] != before['map'], 'native map did not redraw after movement')
    require(after['map'][y][x] != '@', 'vacated native player position was not redrawn')
    return {'key': key.decode('ascii'), 'before': before, 'after': after}


def game_proof(session, output, evidence, label, data):
    proof = namespace_proof(Path('/proc') / str(session.pid), evidence, label)
    executable = Path(proof['executable']).resolve()
    require(str(executable).startswith('/gnu/store/') and executable.name.startswith('python2'),
            'ordinary launcher did not exec a store Python 2 interpreter')
    cmdline = (Path('/proc') / str(session.pid) / 'cmdline').read_bytes().split(b'\0')
    require(os.fsencode(str(output / 'libexec/cutlassrl/main.py')) in cmdline and
            os.fsencode(NAME) in cmdline, 'game argv does not identify installed entrypoint/name')
    proof['argv'] = [os.fsdecode(arg) for arg in cmdline if arg]
    proof['cwd'] = os.readlink('/proc/%d/cwd' % session.pid)
    require(proof['cwd'] == str(data), 'native persistence escaped private XDG data directory')
    terminal_fds = {str(fd): os.readlink('/proc/%d/fd/%d' % (session.pid, fd)) for fd in (0, 1, 2)}
    require(os.isatty(session.fd) and len(set(terminal_fds.values())) == 1 and
            terminal_fds['0'].startswith('/dev/pts/'), 'game does not use the same real PTY for stdio')
    proof['terminal_fds'] = terminal_fds
    # forkpty makes the native game the controlling terminal's foreground
    # process group; merely having tty-looking descriptors is insufficient.
    proof['process_group'] = os.getpgid(session.pid)
    proof['terminal_foreground_group'] = os.tcgetpgrp(session.fd)
    require(proof['process_group'] == session.pid and
            proof['terminal_foreground_group'] == session.pid,
            'native game is not the controlling PTY foreground process group')
    record(evidence / (label + '-process-proof.json'), proof)
    return proof


def main(output, evidence):
    notices(output, evidence)
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
    data = root / 'data/cutlassrl'
    save = data / (NAME + '.sav')
    first = Session(output, evidence / 'new-game', work, env)
    try:
        first.await_screen(lambda: ready(first), 'initial')
        require(not save.exists(), 'fresh ordinary player unexpectedly has a save')
        initial = state(first)
        require(initial['turns'] == 0 and initial['score'] == 0 and initial['level'] == 1 and
                initial['hp'][0] == initial['hp'][1], 'fresh native HUD differs from source initial state')
        native1 = game_proof(first, output, evidence, 'new-game', data)
        action1 = move(first, 'movement-before-save')
        saved_state = state(first)
        first.send('save-and-exit', b's')
        first.finish()
        require(b'Saved...' in first.raw, 'normal save message missing')
        require(save.is_file() and save.stat().st_size > 0, 'native save-and-exit did not write a save')
        blob = save.read_bytes()
        require(blob.startswith(b'\x1f\x8b'), 'native save is not a gzip file')
        save_proof = {'path': str(save), 'bytes': len(blob), 'sha256': hashlib.sha256(blob).hexdigest(),
                      'inspection': 'opaque native bytes only; never unpickled or modified'}
        record(evidence / 'save-file.json', save_proof)
        require(not (data / 'mainlog.log').exists(), 'normal save incorrectly logged a quit/death')
    finally:
        first.close()
    # A second exec with a new PTY/PID and the same ordinary name exercises
    # upstream mainLoop's automatic restore, not the Wizard-only r command.
    second = Session(output, evidence / 'restore-game', work, env)
    try:
        second.await_screen(lambda: ready(second) and b'Loaded...' in second.raw, 'restored')
        native2 = game_proof(second, output, evidence, 'restore-game', data)
        require(first.pid != second.pid, 'restore reused the old native process')
        restored = state(second)
        require(restored == saved_state, 'native visible map/HUD/position did not survive restore')
        require(not save.exists(), 'normal restore did not consume the native save')
        action2 = move(second, 'movement-after-restore')
        final = state(second)
        second.send('ordinary-quit', b'q')
        second.await_screen(lambda: second.screen.display[0].startswith("PRESS '!' TO QUIT:"), 'quit-confirmation')
        require(not second.exited(), 'quit skipped the native paranoid confirmation')
        second.send('confirm-quit', b'!')
        second.finish()
        log = (data / 'mainlog.log').read_text()
        expected = ('version=0.05:name=%s:score=%d:hp=%d:maxhp=%d:killer=Quit:'
                    'gold=0:kills=0:maxdlvl=1:dlvl=1\n') % (NAME, final['score'], *final['hp'])
        require(log == expected, 'native log does not attest a clean ordinary quit: ' + repr(log))
        require(not save.exists(), 'ordinary quit created/reinstated a consumed save')
        files = sorted(str(path.relative_to(root)) for path in root.rglob('*') if path.is_file())
        require(files == ['data/cutlassrl/mainlog.log'], 'unexpected private native state: ' + repr(files))
        record(evidence / 'runtime.json', {
            'status': 'passed', 'launcher': str(output / 'bin/cutlassrl'), 'arguments': [NAME],
            'source_url': SOURCE_URL, 'source_revision': COMMIT, 'source_method': 'git-fetch',
            'source_nar_sha256_base32': SOURCE_NAR_SHA256, 'rows': ROWS, 'columns': COLS,
            'environment': env, 'consumer': consumer, 'store_mounts': mounts,
            'game_processes': [native1, native2], 'initial': initial,
            'actions': [action1, action2], 'saved_state': saved_state, 'restored_state': restored,
            'save_file': save_proof, 'save_consumed': True, 'log': log,
            'exit_statuses': [first.status, second.status], 'private_files': files,
            'rng_control': None, 'state_injection': None, 'store_read_only': True,
            'limitations': ['Two ordinary movement turns, not a victory/death run',
                            'Terminal observations are decoded text/JSON, not graphical screenshots',
                            'NAR equality is recorded by cutlassrl-smoke.sh'],
        })
    finally:
        second.close()


if __name__ == '__main__':
    require(len(sys.argv) == 3, 'usage: cutlassrl-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    try:
        main(output, evidence)
    except BaseException as error:
        record(evidence / 'failure.json', {'error': str(error), 'traceback': traceback.format_exc()})
        raise
