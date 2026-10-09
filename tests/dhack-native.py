#!/usr/bin/env python3
"""Consume ordinary DreamHack trunk r45 from the pinned Google Code r47 archive.

CGame::Title/Input/Run/ShowInventory and CRoom::Draw provide the native oracle.
Only ordinary keys are sent; no seed, wizard mode, memory access or forced
stats. There is no upstream class menu, save/resume or quit-confirmation menu.
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

ROWS, COLS = 25, 80
SOURCE_URL = ('https://storage.googleapis.com/google-code-archive-source/'
              'v2/code.google.com/dreamhack/source-archive.zip')
SOURCE_SHA256 = '42c44d93343bb4b204ae08b3938c6718cfc3d5de48d7698d1705d8d9934ba9cc'
NAME = 'NativeDream'



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
    identity = {}
    for line in raw['status'].splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(part) for part in value.split()]
    proof = {'namespaces': namespaces, 'identity': identity,
             'executable': executable, 'files': raw}
    record(evidence / (label + '-namespace.json'), proof)
    for name, host in (('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                       ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')):
        require(namespaces[name] != os.environ[host], 'not in private ' + name + ' namespace')
        require(namespaces[name] == os.readlink('/proc/self/ns/' + name),
                'process escaped private ' + name + ' namespace')
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
    for target in sorted({entry[0] for entry in entries()[1]}, key=len, reverse=True):
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
                launcher = str(output / 'bin/dhack')
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

    def close(self):
        (self.evidence / 'terminal.raw').write_bytes(self.raw)
        record(self.evidence / 'pty-inputs.json', self.inputs)
        if not self.exited():
            # Failed-run cleanup only; never evidence of a normal game exit.
            os.kill(self.pid, 9)
            os.waitpid(self.pid, 0)
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
            data = path.read_bytes()
            result[relative] = {'kind': 'file', 'bytes': len(data),
                                'sha256': hashlib.sha256(data).hexdigest()}
    return result


# Complete trunk COPYING shipped by the pinned r47 archive; trunk last changed
# at r45. main.cpp's GPL-2.0-or-later header permits use of this GPLv3 notice.
COPYING_SHA256 = '8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903'
COPYING_BYTES = 35147
MAP_COLS, MAP_ROWS = 40, 14
CENTER = (20, 7)


def hud(session):
    match = re.fullmatch(r'HP: (\d+)/(\d+) XP: (\d+)/(\d+) *',
                         session.screen.display[1][40:])
    return dict(zip(('hp', 'max_hp', 'xp', 'next_level'), map(int, match.groups()))) if match else None

def gameplay_visible(session):
    rows = [row[:MAP_COLS] for row in session.screen.display[:MAP_ROWS]]
    players = [(x, y) for y, row in enumerate(rows) for x, char in enumerate(row) if char == '@']
    return hud(session) is not None and players == [CENTER]


def state(session):
    values = hud(session)
    require(values is not None, 'native HP/XP HUD differs from CPlayer::Run')
    rows = [row[:MAP_COLS] for row in session.screen.display[:MAP_ROWS]]
    players = [(x, y) for y, row in enumerate(rows) for x, char in enumerate(row) if char == '@']
    require(players == [CENTER], 'native player is not centered by CRoom::Draw')
    require(any('|' in row or '-' in row for row in rows) and any('.' in row for row in rows),
            'native room floor and walls not observed')
    values['map'] = rows
    values['player_screen_position'] = list(CENTER)
    return values


def translated_tiles(before, after, dx, dy):
    # CRoom::Draw uses (Player.x - 20, Player.y - 7). A real move leaves
    # @ centered and translates unchanged source-defined floor/wall glyphs.
    matches = []
    for y, row in enumerate(before['map']):
        for x, glyph in enumerate(row):
            nx, ny = x - dx, y - dy
            if glyph in '.|-' and 0 <= nx < MAP_COLS and 0 <= ny < MAP_ROWS:
                if after['map'][ny][nx] == glyph:
                    matches.append([x, y, nx, ny, glyph])
                elif glyph in '|-':
                    raise RuntimeError('native movement did not translate room wall at ' + repr((x, y)))
    return matches

def static_tiles_retained(before, after):
    # Enemies advance on every acknowledged inventory/normal turn; explored
    # fog may also reveal additional cells. Compare actual immovable walls,
    # not the whole random viewport or mutable object glyphs.
    walls = [(x, y, glyph) for y, row in enumerate(before['map'])
             for x, glyph in enumerate(row) if glyph in '|-']
    return bool(walls) and all(after['map'][y][x] == glyph for x, y, glyph in walls)


def main(output, evidence):
    copying = (output / 'share/doc/dhack/COPYING').read_bytes()
    digest = hashlib.sha256(copying).hexdigest()
    require(len(copying) == COPYING_BYTES and digest == COPYING_SHA256,
            'complete pinned trunk COPYING differs')
    require(b'GNU GENERAL PUBLIC LICENSE' in copying and b'Version 3, 29 June 2007' in copying
            and b'END OF TERMS AND CONDITIONS' in copying,
            'installed GPLv3 notice is incomplete')
    record(evidence / 'upstream-notices.json', {
        'source': SOURCE_URL, 'source_sha256': SOURCE_SHA256,
        'archive_revision': 47, 'trunk_revision': 45,
        'files': {'COPYING': {'bytes': len(copying), 'sha256': digest}},
        'source_header': 'main.cpp: GPL-2.0-or-later, compatible with trunk GPLv3 COPYING',
        'oracle': {'CGame.cpp': 'Title 768-819; CPlayer 820-846; Run 968-1055; Input 1065-1117; ShowInventory 1304-1313',
                   'CEngine.cpp': 'CRoom::Draw player-centered viewport; Init/Input/Run/Exit 340-394'},
    })
    require((output / 'libexec/dhack-real').read_bytes()[:4] == b'\x7fELF',
            'source-built installed game is not ELF')
    require(not (output / 'bin/dreamhack').exists() and not (output / 'libexec/main').exists(),
            'obsolete native executable installed')
    for path in [output, *output.rglob('*')]:
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, 'output has writable entry: ' + str(path))
        require(path.suffix.lower() != '.exe', 'opaque Windows executable installed')
    require(os.getpid() == 1, 'consumer not PID 1 in private PID/proc namespace')
    consumer = namespace_proof(Path('/proc/self'), evidence, 'consumer')
    mounts = readonly_store(evidence)
    root = evidence / 'private-state'
    root.mkdir(mode=0o700)
    env = {'PATH': '', 'TERM': 'xterm-256color', 'LC_ALL': 'C'}
    for variable, name in (('HOME', 'home'), ('TMPDIR', 'tmp'),
                           ('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                           ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                           ('XDG_RUNTIME_DIR', 'runtime')):
        directory = root / name
        directory.mkdir(mode=0o700)
        env[variable] = str(directory)
    work = root / 'work'
    work.mkdir(mode=0o700)
    before_files = footprint(root)
    record(evidence / 'private-state-before.json', before_files)
    session = Session(output, evidence, work, env)
    try:
        session.await_screen(lambda: session.screen.display[0][54:80] == '[Press space to continue.]',
                             'native-title')
        native = namespace_proof(Path('/proc') / str(session.pid), evidence, 'game')
        require(Path(native['executable']).resolve() == (output / 'libexec/dhack-real').resolve(),
                'ordinary launcher did not exec installed native game')
        require(os.readlink('/proc/%d/cwd' % session.pid) == str(work),
                'ordinary launcher unexpectedly changed working directory')
        terminal_fds = {str(fd): os.readlink('/proc/%d/fd/%d' % (session.pid, fd)) for fd in (0, 1, 2)}
        require(os.isatty(session.fd) and len(set(terminal_fds.values())) == 1 and
                terminal_fds['0'].startswith('/dev/pts/'), 'native fds are not the same real PTY')
        native['terminal_fds'] = terminal_fds
        record(evidence / 'namespace-proof.json', {'consumer': consumer, 'game': native, 'store_mounts': mounts})
        session.send('dismiss-native-title', b' ')
        session.await_screen(lambda: session.screen.display[0].rstrip() == 'DreamHack' and
                             session.screen.display[1].rstrip() == 'Created by Bryan Strait.' and
                             session.screen.display[6].startswith('What is your name? '), 'name-prompt')
        session.send('enter-native-name', NAME.encode('ascii') + b'\r')
        session.await_screen(lambda: session.screen.display[23].rstrip() ==
                             'You are feeling very sleepy, ' + NAME + '... [press space]', 'sleep-prompt')
        session.send('acknowledge-native-sleep', b' ')
        session.await_screen(lambda: session.screen.display[0].rstrip() ==
                             'You have fallen asleep. You dream that your house is very different. [more]',
                             'dream-introduction')
        # Title calls getch TWICE under echo(), then Run waits for a separate
        # Input after flushinp(). Observe each echo before advancing; never
        # queue gameplay input that flushinp() could silently discard.
        session.send('acknowledge-introduction-first-getch', b' ')
        session.await_screen(lambda: True, 'introduction-first-echo')
        session.send('acknowledge-introduction-second-getch', b' ')
        session.await_screen(lambda: True, 'introduction-second-echo')
        session.send('start-native-first-turn', b' ')
        session.await_screen(lambda: gameplay_visible(session), 'new-game')
        initial = state(session)
        require({key: initial[key] for key in ('hp', 'max_hp', 'xp', 'next_level')} ==
                {'hp': 100, 'max_hp': 100, 'xp': 0, 'next_level': 20},
                'fresh ordinary native HP/XP differs from CPlayer constructor')
        session.send('open-native-inventory', b'i')
        session.await_screen(lambda: session.screen.display[0][40:49] == 'Inventory', 'inventory')
        require([row[:40] for row in session.screen.display[:14]] == initial['map'],
                'inventory changed map before acknowledgement')
        session.send('acknowledge-native-inventory', b' ')
        session.await_screen(lambda: gameplay_visible(session) and
                             session.screen.display[0][40:49] != 'Inventory', 'after-inventory')
        inventory_closed = state(session)
        require(static_tiles_retained(initial, inventory_closed),
                'native inventory acknowledgement shifted room walls')
        require({key: inventory_closed[key] for key in ('hp', 'max_hp', 'xp', 'next_level')} ==
                {key: initial[key] for key in ('hp', 'max_hp', 'xp', 'next_level')},
                'native inventory acknowledgement altered fresh HP/XP')
        choices = []
        for key, dx, dy in (('4', -1, 0), ('6', 1, 0), ('8', 0, -1), ('2', 0, 1),
                            ('7', -1, -1), ('9', 1, -1), ('1', -1, 1), ('3', 1, 1)):
            if inventory_closed['map'][CENTER[1] + dy][CENTER[0] + dx] == '.':
                choices.append((key, dx, dy))
        require(choices, 'no observed unoccupied source floor adjacent to native player')
        key, dx, dy = choices[0]
        session.send('observed-native-floor-move-' + key, key.encode('ascii'))
        session.await_screen(lambda: gameplay_visible(session) and
                             [row[:40] for row in session.screen.display[:14]] != inventory_closed['map'],
                             'movement-turn')
        moved = state(session)
        translated = translated_tiles(inventory_closed, moved, dx, dy)
        require(len(translated) >= 12 and any(tile[4] in '|-' for tile in translated),
                'movement did not translate observed floor/walls by native camera delta')
        require(moved['max_hp'] == 100 and moved['next_level'] == 20 and 0 < moved['hp'] <= 100,
                'movement lost meaningful native HUD')
        # Reverse the same observed empty step. Match immovable landmarks at
        # their original screen coordinates, allowing native enemy motion and
        # newly explored fog rather than demanding a frozen random viewport.
        reverse_key = {'4': '6', '6': '4', '8': '2', '2': '8',
                       '7': '3', '9': '1', '1': '9', '3': '7'}[key]
        session.send('return-native-floor-move-' + reverse_key, reverse_key.encode('ascii'))
        session.await_screen(lambda: gameplay_visible(session) and
                             static_tiles_retained(inventory_closed,
                                                   {'map': [row[:40] for row in session.screen.display[:14]]}),
                             'returned-movement-turn')
        returned = state(session)
        session.send('native-quit-without-confirmation', b'q')
        session.finish()
        after_files = footprint(root)
        record(evidence / 'private-state-after.json', after_files)
        require(after_files == before_files, 'upstream no-save game unexpectedly wrote private user state')
        record(evidence / 'native-proof.json', {
            'ordinary_launcher': str(output / 'bin/dhack'), 'argv': [],
            'source': SOURCE_URL, 'name_entered': NAME,
            'class_selection': 'not offered by pinned upstream; name used only in sleep prompt',
            'initial': initial, 'inventory_acknowledged': inventory_closed,
            'movement': {'key': key, 'delta': [dx, dy], 'observed_target': '.',
                         'translated_static_tiles': translated, 'after': moved},
            'return_movement': {'key': reverse_key, 'after': returned},
            'quit': 'q sets m_On false; final native Run/Draw then Exit/endwin; no quit acknowledgement prompt',
            'exit_status': session.status,
            'save_resume': 'not offered by upstream; fresh HOME/XDG/work remained unchanged; no persistence claim',
            'screens': 'terminal-decoded native observations, not PNG screenshots',
        })
    finally:
        session.close()


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('usage: dhack-native.py OUTPUT EVIDENCE')
    output, evidence = (Path(argument) for argument in sys.argv[1:])
    try:
        main(output, evidence)
    except BaseException:
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        raise
