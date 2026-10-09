#!/usr/bin/env python3
"""Observe the ordinary CryptRover 1.1 no-sound game through a real PTY.

Only native keys are sent. No seed, memory access, RNG suppression, or injected
state is used. Decoded screens and the game's scores.dat are observations;
there is no upstream save/resume operation and no screenshot claim.
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
SOURCE_URL = ('https://storage.googleapis.com/google-code-archive-downloads/v2/'
              'code.google.com/cryptrover/cryptrover_1.1_nosound.tar.gz')
SOURCE_SHA256 = '4c8fdb89c21e3302b81afcb7fb974e02533685c461a1e395e869c58e1ea51494'


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
                launcher = str(output / 'bin/cryptrover')
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


# main.c save_score, io.c show_help/print_info/draw_screen, map.h, entities.h,
# and items.h in the official separately released 1.1 no-sound archive.
UPSTREAM = {
    'README': ('a366fe6df0f0ccb000be783fae7fe3642a1d568f3c45a1fcd13252ed7ad6fe23', 1326),
    'COPYING': ('d0495053051967ebe76fb1facd287d79d1ed800da1be75cf501a556bc39a0472', 32471),
    'BSD-3-Clause.txt': ('5ce4047027d9961cc31d9dc1920c68459ea86c3721d0da8807bd58f789ffd3a8', 1618),
}
MAP_ROWS, MAP_COLS, HUD_COL = 24, 48, 49
HELP = ('To move or attack use wasd,', 'vi keys or the numpad:',
        "To flip the flashlight on and off", "press 'f'.",
        'To quit the game press ESC or', 'Ctrl+c.')


def help_visible(session):
    text = '\n'.join(session.screen.display)
    return all(line in text for line in HELP)


def hud(session):
    values = {}
    for row, key, pattern in (
            (0, 'hp', r'Hit points: (\d+)% *'),
            (2, 'air', r'Air: (\d+)% *'),
            (4, 'battery', r'Battery: (\d+)% *'),
            (6, 'gold', r'Gold: (\d+) coins? *'),
            (7, 'level', r'Dungeon level: (\d+)/12 *')):
        match = re.fullmatch(pattern, session.screen.display[row][HUD_COL:])
        if match is None:
            return None
        values[key] = int(match.group(1))
    return values


def state(session):
    values = hud(session)
    require(values is not None, 'native HUD differs from io.c print_info')
    rows = [row[:MAP_COLS] for row in session.screen.display[:MAP_ROWS]]
    players = [(x, y) for y, row in enumerate(rows) for x, char in enumerate(row) if char == '@']
    require(len(players) == 1, 'map does not contain exactly one native player glyph')
    require(all(char in ' #.<@a%+*!$' for row in rows for char in row),
            'native map has glyphs not defined by source')
    require(any('#' in row for row in rows) and any('.' in row for row in rows),
            'native dungeon floor/walls were not observed')
    values['position'] = list(players[0])
    values['map'] = rows
    return values


def main(output, evidence):
    notices = {}
    for name, (expected, size) in UPSTREAM.items():
        blob = (output / 'share/doc/cryptrover' / name).read_bytes()
        actual = hashlib.sha256(blob).hexdigest()
        notices[name] = {'bytes': len(blob), 'sha256': actual}
        require(actual == expected and len(blob) == size,
                'complete upstream notice differs: ' + name)
    record(evidence / 'upstream-notices.json',
           {'source': SOURCE_URL, 'source_sha256': SOURCE_SHA256,
            'version': '1.1 no-sound', 'files': notices})
    require((output / 'libexec/cryptrover').read_bytes()[:4] == b'\x7fELF',
            'source-built installed game is not ELF')
    require(not (output / 'bin/cr').exists() and not (output / 'libexec/cr').exists(),
            'obsolete cr executable installed')
    for path in [output, *output.rglob('*')]:
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, 'output has writable entry: ' + str(path))
        require(path.suffix.lower() not in ('.exe', '.wav', '.ogg'),
                'opaque executable/sound asset installed')
    require(not list(output.rglob('scores.dat')), 'output includes mutable scores.dat')
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
    record(evidence / 'private-state-before.json', footprint(root))
    score = root / 'state/cryptrover/scores.dat'
    require(not score.exists(), 'score state was not initially fresh')
    session = Session(output, evidence, work, env)
    try:
        session.await_screen(lambda: help_visible(session), 'startup-help')
        native = namespace_proof(Path('/proc') / str(session.pid), evidence, 'game')
        require(Path(native['executable']).resolve() == (output / 'libexec/cryptrover').resolve(),
                'ordinary launcher did not exec installed native game')
        require(os.readlink('/proc/%d/cwd' % session.pid) == str(score.parent),
                'ordinary launcher did not select private XDG state directory')
        terminal_fds = {str(fd): os.readlink('/proc/%d/fd/%d' % (session.pid, fd))
                        for fd in (0, 1, 2)}
        require(os.isatty(session.fd) and len(set(terminal_fds.values())) == 1 and
                terminal_fds['0'].startswith('/dev/pts/'),
                'game stdin/stdout/stderr are not the same real PTY')
        native['terminal_fds'] = terminal_fds
        record(evidence / 'namespace-proof.json',
               {'consumer': consumer, 'game': native, 'store_mounts': mounts})
        session.send('dismiss-startup-help', b' ')
        session.await_screen(lambda: not help_visible(session) and hud(session) is not None, 'new-game')
        initial = state(session)
        require({key: initial[key] for key in ('hp', 'air', 'battery', 'gold', 'level')} ==
                {'hp': 100, 'air': 100, 'battery': 100, 'gold': 0, 'level': 1},
                'ordinary launcher did not start a fresh native game')
        session.send('native-help', b'?')
        session.await_screen(lambda: help_visible(session), 'reopened-help')
        session.send('dismiss-native-help', b' ')
        session.await_screen(lambda: not help_visible(session) and hud(session) is not None, 'after-help')
        require(state(session) == initial, 'native help unexpectedly changed game state')

        # Source maps w/a/d to movement but s to WAIT; downward movement is x.
        # Prefer an observed empty cardinal tile. Diagonal keys are a native
        # fallback for a one-cell diagonal corridor, not an invented move.
        x, y = initial['position']
        choices = []
        for key, dx, dy in (('w', 0, -1), ('a', -1, 0), ('d', 1, 0), ('x', 0, 1),
                            ('q', -1, -1), ('e', 1, -1), ('z', -1, 1), ('c', 1, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < MAP_COLS and 0 <= ny < MAP_ROWS:
                glyph = initial['map'][ny][nx]
                if glyph in '.<+*!$':
                    choices.append((glyph not in '.<', key, nx, ny, glyph))
        require(choices, 'no source-observed walkable adjacent tile')
        _, key, nx, ny, glyph = min(choices, key=lambda choice: choice[0])
        session.send('observed-map-move-' + key, key.encode('ascii'))
        session.await_screen(lambda: hud(session) is not None and hud(session)['air'] == 99,
                             'movement-turn')
        moved = state(session)
        require(moved['position'] == [nx, ny] and moved['battery'] == 99 and moved['level'] == 1,
                'native movement did not change player coordinate and consume air/battery')
        require(moved['map'][y][x] != '@', 'native player left a duplicate old-position glyph')

        # f is a documented mechanic. Source use_item runs before resource
        # decay: an adjacent air/battery pickup that was full on arrival may
        # replenish on this following turn. Derive expectations from the
        # observed target glyph, not a seed or silently rejected random map.
        off_air = 99 if glyph == '*' else 98
        off_battery = 100 if glyph == '!' else 99
        on_air = off_air - 1
        on_battery = 99 if glyph == '!' else 98
        session.send('flashlight-off', b'f')
        session.await_screen(lambda: hud(session) is not None and hud(session)['air'] == off_air
                             and hud(session)['battery'] == off_battery,
                             'flashlight-off-turn')
        off = state(session)
        require(off['position'] == moved['position'] and off['battery'] == off_battery,
                'flashlight-off did not match native battery conservation/pickup')
        session.send('flashlight-on', b'f')
        session.await_screen(lambda: hud(session) is not None and hud(session)['air'] == on_air
                             and hud(session)['battery'] == on_battery,
                             'flashlight-on-turn')
        on = state(session)
        require(on['position'] == moved['position'] and on['battery'] == on_battery,
                'flashlight-on did not restore native battery consumption')
        require(not score.exists(), 'scores.dat written before native game end')
        session.send('native-escape-quit', b'\x1b')
        session.await_screen(lambda: ' YOU HAVE LOST! :( ' in '\n'.join(session.screen.display),
                             'native-loss')
        require(not score.exists(), 'score written before loss acknowledgement')
        session.send('acknowledge-native-loss', b' ')
        session.await_screen(lambda: score.exists() and
                             any(re.search(r'Gold: +\d+ +Level: +\d+ +HP: *\d+%', row)
                                 for row in session.screen.display), 'native-highscore')
        blob = score.read_bytes()
        match = re.fullmatch(rb'Gold: +(\d+) +Level: +(\d+) +HP: *(\d+)%  Air: *(\d+)%  Battery: *(\d+)%\n', blob)
        require(match is not None, 'native scores.dat differs from save_score format')
        scores = dict(zip(('gold', 'level', 'hp', 'air', 'battery'), map(int, match.groups())))
        require(scores == {key: on[key] for key in scores}, 'score does not match last observed native HUD')
        require(any(blob.decode('ascii').strip() in row for row in session.screen.display),
                'native highscore panel does not display generated score record')
        (evidence / 'scores.dat').write_bytes(blob)
        session.send('acknowledge-native-highscore', b' ')
        session.finish()
        after = footprint(root)
        record(evidence / 'private-state-after.json', after)
        files = {name for name, entry in after.items() if entry['kind'] != 'directory'}
        require(files == {'state/cryptrover/scores.dat'}, 'unexpected native user-state files: ' + repr(files))
        require(not list(output.rglob('scores.dat')), 'native state leaked into output')
        record(evidence / 'native-proof.json', {
            'ordinary_launcher': str(output / 'bin/cryptrover'), 'argv': [],
            'source': SOURCE_URL, 'map_dimensions': [MAP_COLS, MAP_ROWS],
            'new_game': initial, 'movement': {'key': key, 'observed_target_glyph': glyph,
                                            'before': initial['position'], 'after': moved},
            'flashlight_off': off, 'flashlight_on': on,
            'score_file': str(score), 'score': scores,
            'score_sha256': hashlib.sha256(blob).hexdigest(),
            'exit_status': session.status,
            'save_resume': 'not offered by upstream; scores.dat is highscore user state only',
            'screens': 'terminal-decoded native observations, not PNG screenshots',
        })
    finally:
        session.close()


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('usage: cryptrover-native.py OUTPUT EVIDENCE')
    output, evidence = (Path(argument) for argument in sys.argv[1:])
    try:
        main(output, evidence)
    except BaseException:
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        raise
