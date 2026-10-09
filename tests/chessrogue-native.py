#!/usr/bin/env python3
"""Drive ChessRogue 0.3.1's ordinary curses launcher through a real PTY.

Native intro/menu/map/HUD/save bytes are observations. Only ordinary keys are
sent: no seeded RNG, fabricated save, imported game code, or screenshot claim.
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

ROWS, COLS = 30, 100
SOURCE_URL = ('https://sourceforge.net/projects/chessrogue/files/chessrogue/'
              '0.3.1/chessrogue0.3.1-src.tgz/download')
SOURCE_SHA256_BASE32 = '15qbvlyamnqjq5lkmbwba68l0n4yl2fxhawxb27xf5djvzfkfyf9'


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
    # Current ncurses xterm terminfo emits ECMA-48 REP; stock pyte 0.8
    # ignores it, leaving displaced text and incomplete native HUD bars.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, output, evidence, work, env):
        self.evidence = evidence
        evidence.mkdir(mode=0o700)
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.raw = bytearray()
        self.inputs = []
        self.input_offset = -1
        self.status = None
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(work)
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                launcher = str(output / 'bin/chessrogue')
                os.execve(launcher, [launcher], env)
            except BaseException:
                os.write(2, traceback.format_exc().encode('utf-8'))
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
            if len(self.raw) > self.input_offset and predicate():
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
        if '-turn-' not in label:
            record(self.evidence / (label + '.cells.json'),
                   [[session_cell._asdict() for session_cell in
                     (self.screen.buffer[y][x] for x in range(COLS))] for y in range(ROWS)])
        (self.evidence / (label + '.screen.txt')).write_text('\n'.join(self.screen.display) + '\n')

    def send(self, label, data):
        require(not self.exited(), 'cannot send input to exited game')
        self.input_offset = len(self.raw)
        self.inputs.append({'label': label, 'hex': data.hex(), 'raw_offset': len(self.raw)})
        require(os.write(self.fd, data) == len(data), 'short PTY write')

    def finish(self):
        deadline = time.monotonic() + 10
        while not self.exited() and time.monotonic() < deadline:
            self.pump()
        require(self.exited(), 'native acknowledgement did not terminate game')
        while self.pump(0.05):
            pass
        self.snapshot('exited')
        require(self.status == 0, 'native game exited ' + str(self.status))
        require(not re.search(r'exception|backtrace|couldn.t find the key map|segmentation fault',
                              bytes(self.raw).decode('utf-8').lower()),
                'native exception/error output despite zero exit status')

    def close(self):
        (self.evidence / 'terminal.raw').write_bytes(self.raw)
        record(self.evidence / 'pty-inputs.json', self.inputs)
        record(self.evidence / 'process.json', {'pid': self.pid, 'exit_status': self.status})
        # Private PID namespace teardown owns failed runs. No signal exit is accepted.
        os.close(self.fd)

DOC_SHA256 = {'COPYING.txt': '6b099eadcf3e4e2a8b14fe949e60bb49a7a15722ad2214b07a818970c8a0c3f7', 'COPYING.pcre.txt': 'e2fdf9bb984ba33f8dc71cadb3ae007c10642e40554e9699b2792f433184fb82', 'COPYING.sdl.txt': '0b6a26ae0c4ade72a7d4aa71be3c93fb2eed4ac8e2daf364959cccc26a14d106', 'README.txt': '678bbd7f479c709d9bfbc179e8247e938ba4cf903ae7a62a52bf944e9f9d8c98', 'INSTALL.txt': '53c64ae0115a70c6d82975dd76ce364ba3250ba372438e907875c30732cd120a', 'CHANGELOG.txt': 'ea127dbfe291994b601e986b76ca6e4c0113f9e0c5b7904e8fe8b0ecd9fd68fc', 'HINTS.txt': '4343ffd152f44dd56bbfc953ce2689cb41cfd051c106db8d1fde34593a42b755', 'crkeymap.txt': '930a1f8af0d8ecb88ba08119382695dd97db62b5c08a06b379ae3bc3044e763f', 'kaya/COPYING': 'a4bd1f7aa9dfff576e6e3f7ad7cb7b7bd612fa8a3c1bac4f293b84eec3dc4d74', 'kaya/GPL2': 'b8a2f73f743dc1a51aff23f1aacbca4b868564db52496fa3c0caba755bfd1eaf', 'kaya/GPL3': '8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903', 'kaya/LGPL2.1': 'd80c9d084ebfb50ea1ed91bfbc2410d6ce542097a32c43b00781b83adcb8c77f', 'kaya/LGPL3': 'a853c2ffec17057872340eee242ae4d96cbf2b520ae27d903e1b2fef1a5f9d1c', 'kaya/compiler/COPYING': 'b8a2f73f743dc1a51aff23f1aacbca4b868564db52496fa3c0caba755bfd1eaf'}


def notices(output, evidence):
    records = {}
    for relative, expected in DOC_SHA256.items():
        path = output / 'share/doc/chessrogue' / relative
        blob = path.read_bytes()
        observed = hashlib.sha256(blob).hexdigest()
        require(observed == expected, 'canonical rights/document changed: ' + relative)
        records[relative] = {'bytes': len(blob), 'sha256': observed}
    keymap = (output / 'share/chessrogue/crkeymap.txt').read_bytes()
    require(hashlib.sha256(keymap).hexdigest() == DOC_SHA256['crkeymap.txt'],
            'installed keymap differs from canonical source')
    require(not (output / 'share/chessrogue/crtiles.bmp').exists(),
            'curses package unexpectedly installed SDL artwork')
    record(evidence / 'license-closure.json', {
        'canonical_documents': records,
        'source_url': SOURCE_URL, 'source_sha256_base32': SOURCE_SHA256_BASE32,
        'kaya_source_sha256_base32': '0j4l6yk3b7znjhgbd27l99k2ry329vim3jc7qhj9283xbb4x4bl9',
        'rights': {'game': 'GPL2+ COPYING grant and GPL2 source headers; complete GPL text retained',
                   'pcre': 'BSD-3 full copyright/conditions/disclaimer retained',
                   'sdl': 'complete upstream LGPL notice retained despite curses-only runtime',
                   'kaya_runtime_libraries': 'LGPL2.1+ umbrella and both license versions retained',
                   'kaya_compiler': 'GPL2+ umbrella and GPL2/GPL3/compiler notice retained'},
        'method': 'exact canonical archive member SHA256, not keyword-only acceptance'})


def game_proof(session, output, evidence, label, data):
    proc = Path('/proc') / str(session.pid)
    proof = namespace_proof(proc, evidence, label)
    require(Path(proof['executable']).resolve() == (output / 'libexec/chessrogue').resolve(),
            'ordinary launcher did not exec the installed native executable')
    argv = [os.fsdecode(part) for part in (proc / 'cmdline').read_bytes().split(b'\0') if part]
    require(argv == [str(output / 'libexec/chessrogue')], 'unexpected native argv')
    proof['argv'] = argv
    proof['cwd'] = os.readlink(proc / 'cwd')
    require(proof['cwd'] == str(data), 'native cwd escaped private XDG data')
    child_env = dict(part.split(b'=', 1) for part in (proc / 'environ').read_bytes().split(b'\0') if b'=' in part)
    require(child_env[b'HOME'] == os.fsencode(data), 'native HOME escaped private XDG data')
    terminal = {str(fd): os.readlink(proc / 'fd' / str(fd)) for fd in (0, 1, 2)}
    require(os.isatty(session.fd) and len(set(terminal.values())) == 1 and
            terminal['0'].startswith('/dev/pts/'), 'native stdio does not share a real PTY')
    require(os.getpgid(session.pid) == session.pid and os.tcgetpgrp(session.fd) == session.pid,
            'native process is not controlling PTY foreground group')
    proof.update({'terminal_fds': terminal, 'process_group': session.pid,
                  'terminal_foreground_group': os.tcgetpgrp(session.fd), 'home': str(data)})
    record(evidence / (label + '-process-proof.json'), proof)
    return proof


HUD_LABELS = ('     Pawns: ', ' Sergeants: ', '   Bishops: ', '  Generals: ',
              '  Mantraps: ', '    Lances: ', '   kNights: ', '    Eagles: ',
              '     Rooks: ', '    Tigers: ', '    Queens: ', 'Crocodiles: ', '  the King: ')
SAVE_TO_HUD = (0, 2, 6, 8, 10, 9, 7, 4, 11, 1, 3, 5)
ENEMIES = set('PSGLBNRQKTEXCAF#')
GLYPHS = set('.=!+*@') | ENEMIES
CHECK_PROMPTS = ('Doing that will move into check! Really go there? (y/N)',
                 'You are in check! Really stand still? (y/N)')
RETRY_PROMPT = "Press any key for the score (or 's' to try this level again)"


def intro(session):
    rows = session.screen.display
    return rows[0][2:].startswith('------------------------------ Chess Rogue ------------------------------') and \
        rows[21][3:].startswith('Press any key to start playing...')


def board(session):
    rows = session.screen.display
    return re.match(r' Level [1-9][0-9]* ', rows[17][26:]) is not None and \
        rows[0][62:80] in ('   F5: Movement   ', '   F6: Captures   ', '  F7: Equipment   ') and \
        sum(row[1:61].count('@') for row in rows[1:17]) == 1


def map_state(session):
    require(board(session), 'native board/HUD anchors missing')
    rows = session.screen.display
    terrain = [row[1:61] for row in rows[1:17]]
    require(all(set(row) <= GLYPHS for row in terrain), 'unknown decoded native terrain glyph')
    require(any('.' in row for row in terrain) and any('=' in row for row in terrain),
            'native generated floor/water missing')
    position = next([y, row.index('@')] for y, row in enumerate(terrain) if '@' in row)
    y, x = position
    cell = session.screen.buffer[y + 1][x + 1]
    require(cell.data == '@' and cell.bold, 'native white/heavy player glyph missing')
    # Kaya Yellow maps to ANSI SGR 33; pyte names that base color brown.
    # Heavy is the separate bold attribute, not a bright-color substitution.
    for glyph, foreground in (('@', 'white'), ('.', 'green'), ('=', 'blue'), ('*', 'brown')):
        found = [session.screen.buffer[row + 1][col + 1]
                 for row, line in enumerate(terrain) for col, value in enumerate(line) if value == glyph]
        require(found and all(item.fg == foreground for item in found),
                'native glyph color differs from showMap: ' + glyph)
    exit_cell = session.screen.buffer[16][60]
    require(exit_cell.bold and not exit_cell.reverse and exit_cell.bg == 'black',
            'native exit does not match Yellow/Heavy rendition')
    require(terrain[15][59] == '*', 'native level exit is not at source bottom-right coordinate')
    level = int(re.match(r' Level ([0-9]+) ', rows[17][26:]).group(1))
    require(rows[18][63:65] == 'F5' and rows[18][66:68] == 'F6' and rows[18][69:71] == 'F7',
            'native HUD tab anchors missing')
    return {'level': level, 'position': position, 'map': terrain,
            'panel': rows[0][62:80], 'check': rows[17][40:48] == ' CHECK! '}


def captures(session, label):
    session.send(label + '-f6', b'\x1b[17~')
    session.await_screen(lambda: board(session) and session.screen.display[0][62:80] ==
                         '   F6: Captures   ', label)
    counts = []
    for y, prefix in enumerate(HUD_LABELS, 1):
        match = re.fullmatch(re.escape(prefix) + r'([0-9]+) *', session.screen.display[y][63:79])
        require(match is not None, 'exact native capture HUD missing: ' + prefix)
        counts.append(int(match.group(1)))
    return counts


def settle_action(session, deadline):
    # Await a complete native input round trip, then require a quiet terminal
    # across a minimum observation window. Silence alone never proves movement.
    minimum = time.monotonic() + 0.4
    while True:
        observed = session.pump(0.15)
        require(time.monotonic() < deadline, 'native action did not settle')
        if not observed and time.monotonic() >= minimum:
            return


def native_action(session, label, key):
    session.send(label, key)
    # Input may redraw no cells for a wait; silence is not movement proof.
    # Only menus/prompts and explicitly changed player coordinates prove events.
    deadline = time.monotonic() + 10
    settle_action(session, deadline)
    rows = session.screen.display
    if any(rows[18].startswith(prompt) for prompt in CHECK_PROMPTS):
        session.snapshot(label + '-check-confirmation')
        session.send(label + '-confirm-check', b'y')
        settle_action(session, deadline)
    session.snapshot(label)
    require(not session.exited(), 'unexpected native exit after ordinary action')


def meaningful_move(session, label):
    before = map_state(session)
    y, x = before['position']
    options = [(key, dy, dx) for key, dy, dx in
               ((b'l', 0, 1), (b'j', 1, 0), (b'h', 0, -1), (b'k', -1, 0))
               if 0 <= y + dy < 16 and 0 <= x + dx < 60 and
               before['map'][y + dy][x + dx] == '.']
    require(options, 'fresh native spawn has no orthogonal floor')
    key, dy, dx = options[0]
    native_action(session, label, key)
    after = map_state(session)
    require(after['position'] == [y + dy, x + dx] and after['map'][y][x] != '@' and
            after['map'] != before['map'], 'ordinary input did not move/redraw native player')
    return {'key': key.decode(), 'before': before, 'after': after}


def reach_native_capture(session, label):
    # Practice has a genuine between-level retry-save. Seek a visible enemy's
    # guarded neighboring floor using only the currently decoded random map;
    # never synthesize map state, bypass water, or edit capture/save data.
    from collections import deque
    actions = []
    deadline = time.monotonic() + 90
    goal = None
    waited = 0
    exhausted = set()
    for turn in range(400):
        require(time.monotonic() < deadline, 'ordinary capture exceeded its 90-second bound')
        if session.screen.display[20].startswith(RETRY_PROMPT):
            session.snapshot(label + '-native-capture')
            require('captures you. Checkmate!' in session.screen.display[19],
                    'retry-save prompt lacks native checkmate message')
            record(session.evidence / (label + '-actions.json'), actions)
            return
        before = map_state(session)
        grid = before['map']
        start = tuple(before['position'])
        # Do not re-target each enemy redraw: moving pawn diagonals caused a
        # two-square chase cycle. Walk to one observed reachable attack floor,
        # hold it for ordinary enemy turns, then consider another floor only
        # if the native enemy never approaches. No game/RNG state is changed.
        if goal == start and not before['check']:
            waited += 1
            if waited > 8:
                exhausted.add(goal)
                goal = None
                waited = 0
        if goal is not None and grid[goal[0]][goal[1]] not in '.@':
            goal = None
        if before['check']:
            key = b'.'
        else:
            enemies = [(y, x) for y, row in enumerate(grid) for x, glyph in enumerate(row)
                       if glyph in ENEMIES and glyph != '#']
            require(enemies, 'native level has no enemy to complete capture flow')
            targets = {(y + dy, x + dx) for y, x in enemies
                       for dy, dx in ((-1, -1), (-1, 1), (1, -1), (1, 1),
                                      (-1, 0), (1, 0), (0, -1), (0, 1))
                       if 0 <= y + dy < 16 and 0 <= x + dx < 60 and
                       grid[y + dy][x + dx] in '.@'}
            # Prefer guarded diagonals for level-one pawns. A stand-still
            # check prompt is explicitly confirmed as ordinary native input.
            diagonal = {(y + dy, x + dx) for y, x in enemies
                        for dy, dx in ((-1, -1), (-1, 1), (1, -1), (1, 1))
                        if 0 <= y + dy < 16 and 0 <= x + dx < 60 and
                        grid[y + dy][x + dx] in '.@'}
            targets = (diagonal or targets) - exhausted
            require(targets or goal is not None, 'all observed native attack floors exhausted')
            if goal is not None:
                targets = {goal}
            queue = deque([start])
            first = {start: None}
            found = None
            while queue:
                y, x = queue.popleft()
                if (y, x) in targets:
                    found = (y, x)
                    break
                for candidate, dy, dx in ((b'l', 0, 1), (b'j', 1, 0), (b'h', 0, -1), (b'k', -1, 0)):
                    nxt = (y + dy, x + dx)
                    if 0 <= nxt[0] < 16 and 0 <= nxt[1] < 60 and nxt not in first and \
                            grid[nxt[0]][nxt[1]] == '.':
                        first[nxt] = candidate if (y, x) == start else first[(y, x)]
                        queue.append(nxt)
            require(found is not None, 'native enemy guarded floor unreachable')
            key = first[found] or b'.'
            if goal is None:
                goal = found
        native_action(session, label + '-turn-%03d' % turn, key)
        actions.append({'turn': turn, 'key': key.decode(), 'before': before,
                        'after_rows': session.screen.display})
    record(session.evidence / (label + '-actions.json'), actions)
    raise RuntimeError('ordinary capture did not occur within 400 observed turns')


def native_save(path):
    blob = path.read_bytes()
    lines = blob.decode('ascii').splitlines()
    require(len(lines) == 4 and all(re.fullmatch(r'-?[0-9]+(?:\|-?[0-9]+)*', line)
                                  for line in lines), 'native save format differs from source')
    fields = [[int(value) for value in line.split('|')] for line in lines]
    require([len(row) for row in fields] == [12, 4, 1, 3], 'native save field shape differs')
    require(all(value >= 0 for value in fields[0]) and fields[1][1:3] == [0, 0] and
            fields[2] == [0] and all(value >= -1 for value in fields[3]),
            'native Practice retry-save values differ from source')
    return {'path': str(path), 'bytes': len(blob), 'sha256': hashlib.sha256(blob).hexdigest(),
            'captures': fields[0], 'bonus_difficulty_level_longrun': fields[1],
            'challenges': fields[2], 'equipment': fields[3],
            'inspection': 'read-only native plain-text bytes, never written by consumer'}


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
    data = root / 'data/chessrogue'
    save = data / '.crsave'
    require(not data.exists() and not save.exists(), 'fresh game is not genuinely empty')
    first = Session(output, evidence / 'new-game', work, env)
    try:
        first.await_screen(lambda: intro(first), 'intro')
        proof1 = game_proof(first, output, evidence, 'new-game', data)
        require(sorted(path.name for path in data.iterdir()) == ['crkeymap.txt'],
                'launcher created state beyond ordinary initial keymap')
        first.send('dismiss-native-intro', b' ')
        first.await_screen(lambda: first.screen.display[2][2:20] == 'Choose difficulty:' and
                           [first.screen.display[y][4:].rstrip() for y in range(3, 7)] ==
                           ['1) Practice', '2) Normal', '3) Expert', '4) Master'], 'difficulty-menu')
        first.send('choose-practice', b'1')
        first.await_screen(lambda: first.screen.display[9][2:20] == 'Choose challenges:' and
                           first.screen.display[11][4:].rstrip() == '0) No special challenges' and
                           first.screen.display[12][4:].rstrip() == '1) Classic pieces', 'challenge-menu')
        first.send('choose-ordinary-pieces', b'0')
        first.await_screen(lambda: board(first), 'new-map')
        initial = map_state(first)
        require(initial['level'] == 1 and initial['position'] == [0, 0],
                'fresh native level/spawn differs from Map.makeMap')
        require(not save.exists(), 'new game unexpectedly preseeded a save')
        initial_counts = captures(first, 'fresh-capture-hud')
        require(initial_counts == [0] * 13, 'fresh capture HUD differs from newPlayer')
        first.send('movement-panel', b'\x1b[15~')
        first.await_screen(lambda: board(first) and first.screen.display[0][62:80] ==
                           '   F5: Movement   ', 'fresh-movement-hud')
        action1 = meaningful_move(first, 'movement-before-save')
        reach_native_capture(first, 'before-save')
        require(not save.exists(), 'in-level play wrote an unsupported mid-level save')
        first.send('native-practice-retry-save', b's')
        first.await_screen(lambda: board(first) and first.screen.display[20].strip() == '', 'native-retry-map')
        require(not first.exited(), 'Practice retry incorrectly exited the native game')
        saved = native_save(save)
        require(saved['equipment'] == [-1, -1, -1], 'fresh native retry-save invented equipment')
        record(evidence / 'native-save.json', saved)
        retried = map_state(first)
        require(retried['level'] == 1 and retried['position'] == [0, 0],
                'native Practice retry did not regenerate the same level at the starting position')
        retry_counts = captures(first, 'retry-capture-hud')
        require([retry_counts[index] for index in SAVE_TO_HUD] == saved['captures'],
                'native retry HUD differs from its own persisted capture counts')
        first.send('retry-movement-panel', b'\x1b[15~')
        first.await_screen(lambda: board(first) and first.screen.display[0][62:80] ==
                           '   F5: Movement   ', 'retry-movement-hud')
        action2 = meaningful_move(first, 'movement-after-native-retry')
        reach_native_capture(first, 'after-retry')
        first.send('native-score-after-capture', b' ')
        first.await_screen(lambda: first.screen.display[0][2:].startswith('You reached level 1 where you ') and
                           'Your final score was ' in first.screen.display[16], 'native-game-report')
        first.send('acknowledge-native-game-report', b' ')
        first.await_screen(lambda: first.screen.display[22][10:].rstrip() ==
                           "Save score report to 'score.TIME.txt'? [y/N]", 'native-score-report-prompt')
        first.send('save-native-score-report', b'y')
        first.await_screen(lambda: first.screen.display[23][20:].rstrip() ==
                           'Again? [Y/c/n] (c=change difficulty)' and
                           'Score report saved to ./score.' in first.screen.display[22], 'native-quit-menu')
        first.send('native-normal-quit', b'n')
        first.finish()
        require(not save.exists(), 'completed native run did not clear its retry-save')
        reports = list(data.glob('score.*.txt'))
        require(len(reports) == 1, 'normal score report persistence missing/duplicated')
        report = reports[0].read_text()
        require(report.splitlines()[1] == '                         ChessRogue 0.3.0 game score' and
                report.splitlines()[3] == 'You played at practice difficulty.' and
                re.fullmatch(r'You reached level 1 and at [0-9]{4}-[0-9]{2}-[0-9]{2} '
                             r'[0-9]{2}:[0-9]{2}:[0-9]{2} you were captured\.', report.splitlines()[4]),
                'native report contradicts exact source version/difficulty/level/result')
        score = (data / '.crscore').read_text()
        require(len(score.splitlines()) == 20, 'native top-20 score file missing')
        files = sorted(str(path.relative_to(root)) for path in root.rglob('*') if path.is_file())
        expected = sorted(['data/chessrogue/crkeymap.txt', 'data/chessrogue/.crscore',
                           'data/chessrogue/' + reports[0].name])
        require(files == expected, 'native files escaped private data root: ' + repr(files))
        require(hashlib.sha256((data / 'crkeymap.txt').read_bytes()).hexdigest() == DOC_SHA256['crkeymap.txt'],
                'ordinary runtime changed canonical keymap')
        record(evidence / 'runtime.json', {
            'status': 'passed', 'launcher': str(output / 'bin/chessrogue'), 'arguments': [],
            'source_url': SOURCE_URL, 'source_sha256_base32': SOURCE_SHA256_BASE32,
            'rows': ROWS, 'columns': COLS, 'environment': env, 'consumer': consumer,
            'store_mounts': mounts, 'game_processes': [proof1], 'initial': initial,
            'meaningful_movements': [action1, action2], 'native_retry_save': saved,
            'retried': retried, 'retry_counts': retry_counts, 'independent_restore_exercised': False,
            'score_report': {'path': str(reports[0]), 'text': report},
            'score_file': score, 'exit_statuses': [first.status],
            'private_files': files, 'rng_control': None, 'state_injection': None,
            'store_read_only': True,
            'source_anchors': ['main.k:main/playGame/nextLevel', 'State.k:newGame/saveState/loadState',
                               'Map.k:makeMap', 'Player.k:movePlayer',
                               'DisplayCurses.k:showInstructions/chooseDifficulty/chooseChallenges',
                               'DisplayCurses.k:showMap/showCaptures/getSaveDecision/nextGameDecision'],
            'limitations': ['Practice retry writes native save but continues in the same process',
                            'No independent restore tested: ordinary completed-run quit clears the save',
                            'Mid-level save-and-exit is unsupported; no full-level/victory solver is attempted',
                            'Practice games are not eligible for high scores',
                            'Decoded terminal text/JSON are not graphical screenshots',
                            'NAR equality is recorded by chessrogue-smoke.sh']})
    finally:
        first.close()


if __name__ == '__main__':
    require(len(sys.argv) == 3, 'usage: chessrogue-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    try:
        main(output, evidence)
    except BaseException as error:
        record(evidence / 'failure.json', {'error': str(error), 'traceback': traceback.format_exc()})
        raise
