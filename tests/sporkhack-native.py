#!/usr/bin/env python3
"""External silent SporkHack acceptance, using the installed ordinary launcher.

Only native keystrokes and redraws produce gameplay evidence.  There is no
seed fixture, wizard/discovery option, generated level, save mutation, or OCR.
Every displayed 80x21 map cell and both complete HUD rows are compared exactly
within the same game across two ordinary processes.  Test tools are not shipped.

Source anchors below refer to k21971/SporkHack at SOURCE_REVISION (and the
accompanying selected patched source installed under share/doc/sporkhack/source).
"""
import argparse
import codecs
import ctypes
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
import tempfile
import termios
import time

import pyte

SOURCE_REVISION = '4ed114fc29b9d03f9b2857c730afd9563513ddad'
ROWS, COLS = 24, 100
NAME = 'OmpProof'
# src/role.c:1318 plnamesuffix strips role/race/gender/alignment suffixes.
# sys/unix/unixmain.c:process_options consumes -u/-p/-r, not -D or -X.
PLAYER = NAME + '-Val-Hum-Fem-Law'
# src/options.c: boolean/compound tables and initoptions:649 accept this @file.
# show_dgn_name defaults TRUE at this pin: disable it to select native Dlvl:.
# "sound" governs game messages, not playback.  Do not confuse !sound with
# disabling an audio backend: this package has no USER_SOUNDS backend at all.
OPTIONS = ('windowtype:tty,time,!show_dgn_name,!IBMgraphics,!DECgraphics,!color,'
           '!statuscolors,!hitpointbar,!legacy,!news,!autopickup,!menu_glyphs,'
           'menustyle:full,number_pad:0,pettype:none')
SOURCE_ANCHORS = {
    'geometry': 'include/global.h:321-322 COLNO=80 ROWNO=21; '
                'win/tty/wintty.c:530-552 map offy=1 status offy=22',
    'hud': 'src/botl.c:bot1str/bot2str describe_level, raw stats/HP/AC/Exp/T:moves',
    'greetings': 'src/allmain.c:667-668 welcome(TRUE/FALSE)',
    'character_confirmation': 'src/charinit.c:16-46 selector accelerators; '
                              '122-124 + selected marker; 148-166 ordinary . play confirmation',
    'controls': "src/cmd.c:1990 Ctrl-R redraw, 2019 i inventory, 2045 s search, 2046 S save",
    'save': "src/save.c:70-85 Really save? y; Saving...; Be seeing you...; EXIT_SUCCESS",
    'restore': 'sys/unix/unixmain.c:255 Restoring save file; src/restore.c:726 '
               'normal dorecover deletes the save; src/restore.c:776 welcome(FALSE)',
    'save_path': 'src/files.c:940 save/<getuid()>player under SAVEPREFIX',
    'whereis': 'src/files.c:657-719 native depth/dnum/hp/maxhp/turns/role/race/'
               'gender/align/playing; updated at startup, level change and save, '
               'NOT every turn',
}


def require(condition, description):
    if not condition:
        raise RuntimeError(description)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1048576), b''):
            digest.update(block)
    return digest.hexdigest()


def fingerprint(path):
    if path.is_symlink():
        return {'link': os.readlink(path)}
    if not path.exists():
        return None
    if path.is_file():
        return {'size': path.stat().st_size, 'sha256': sha(path)}
    return {p.name: fingerprint(p) for p in sorted(path.iterdir())}


def output_contract(package, output):
    require(package.parent == Path('/gnu/store'), 'not a direct Guix store output')
    require((package / 'libexec/sporkhack-real').read_bytes()[:4] == b'\x7fELF',
            'native real executable is not ELF')
    for path in [package, *package.rglob('*')]:
        require(not path.is_symlink(), 'unexpected installed symlink: ' + str(path))
        require(path.stat().st_mode & 0o222 == 0, 'installed output has write bits: ' + str(path))
        require(path.suffix.lower() not in ('.uu', '.hqx', '.aiff', '.aif', '.wav', '.mp3', '.ogg'),
                'excluded encoded/audio asset retained: ' + str(path))
    data, doc = package / 'share/sporkhack', package / 'share/doc/sporkhack'
    for name in ('nhdat', 'license'):
        require((data / name).is_file() and (data / name).stat().st_size > 0,
                'missing native data: ' + name)
    for name in ('README', 'README.new_lev_comp', 'README.statuscolors',
                 'Guidebook.txt', 'README.linux', 'license', 'SOURCE', 'sounds-README'):
        require((doc / name).is_file() and (doc / name).stat().st_size > 0,
                'missing installed notice: ' + name)
    require('NETHACK GENERAL PUBLIC LICENSE' in (data / 'license').read_text(),
            'NGPL runtime license missing')
    require(SOURCE_REVISION in (doc / 'SOURCE').read_text(), 'wrong source pin notice')
    source = doc / 'source'
    for name in ('README', 'dat/license', 'src/allmain.c', 'src/save.c',
                 'src/restore.c', 'src/options.c', 'src/botl.c', 'include/global.h',
                 'win/tty/wintty.c', 'sys/unix/unixmain.c'):
        require((source / name).is_file(), 'accompanying selected source missing: ' + name)
    for name in ('sys/mac', 'win/Qt', 'doc/tmac.n', 'include/bitmfile.h'):
        require(not (source / name).exists(), 'excluded source retained: ' + name)
    require(sorted(p.name for p in (source / 'sys/share/sounds').iterdir()) == ['README'],
            'excluded Roland samples retained in accompanying source')
    require(not (data / 'sounds').exists(), 'runtime sounds directory must not be shipped')
    require(not any('smoke' in p.name for p in (package / 'libexec').iterdir()),
            'installed test helper is forbidden')
    closure = (output / 'runtime-closure.txt').read_text().splitlines()
    require(str(package) in closure and closure, 'shell closure evidence missing')
    names = [Path(line).name[33:] for line in closure]
    forbidden = ('python-', 'python-pyte-', 'alsa-', 'alsa-lib-', 'pulseaudio-',
                 'sdl-', 'sdl2-', 'openal-', 'portaudio-', 'libao-', 'sox-', 'jack-')
    require(not any(name.startswith(forbidden) for name in names),
            'audio/test-only dependency leaked into runtime closure')
    return {'source_revision': SOURCE_REVISION, 'native_elf_sha256': sha(package / 'libexec/sporkhack-real'),
            'no_audio_assets': True, 'no_audio_backend_claimed': True,
            'runtime_closure': closure, 'accompanying_selected_source': str(source),
            'source_anchors': SOURCE_ANCHORS}


def identity(proc):
    values = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, text = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            values[key] = [int(x) for x in text.split()]
    for key, host in (('Uid', 'SPORK_HOST_UID'), ('Gid', 'SPORK_HOST_GID')):
        require(values.get(key) == [int(os.environ[host])] * 4,
                'native process changed caller ' + key)
    return values


def namespace_receipt(proc):
    namespaces = {name: os.readlink(proc / 'ns' / name) for name in ('user', 'mnt', 'net', 'pid')}
    for name, actual in namespaces.items():
        require(actual != os.environ['SPORK_HOST_' + name.upper()], 'host namespace leaked: ' + name)
        require(actual == os.readlink('/proc/self/ns/' + name), 'game escaped private ' + name + ' namespace')
    maps = {}
    for kind, host in (('uid', 'SPORK_HOST_UID'), ('gid', 'SPORK_HOST_GID')):
        maps[kind] = (proc / (kind + '_map')).read_text()
        require([int(x) for x in maps[kind].split()] == [int(os.environ[host])] * 2 + [1],
                'not an exact same-UID/GID mapping')
    interfaces = sorted(line.split(':')[0].strip() for line in
                        (proc / 'net/dev').read_text().splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'offline namespace exposes non-loopback interface')
    return {'namespaces': namespaces, 'interfaces': interfaces,
            'identity': identity(proc), 'uid_map': maps['uid'], 'gid_map': maps['gid']}


def mount(source, target, flags):
    # mount(8) rejects nonzero real UID even with namespace capabilities.
    # Use the syscall, retaining the caller UID, never map-root-user.
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int
    if libc.mount(os.fsencode(source), os.fsencode(target), None, flags, None):
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), str(target))


def store_mounts():
    text = Path('/proc/self/mountinfo').read_text()
    entries = []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in (('\\040', ' '), ('\\011', '\t'), ('\\012', '\n'), ('\\134', '\\')):
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            entries.append({'target': target, 'options': fields[5].split(','),
                            'optional': fields[6:fields.index('-')], 'line': line})
    return text, entries


def readonly_store(output):
    (output / 'mountinfo-before.txt').write_text(store_mounts()[0])
    mount('/gnu/store', '/gnu/store', 4096 | 16384)  # MS_BIND | MS_REC
    mount('/gnu/store', '/gnu/store', 262144 | 16384)  # MS_PRIVATE | MS_REC
    for target in sorted({e['target'] for e in store_mounts()[1]}, key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)  # MS_BIND | MS_REMOUNT | MS_RDONLY
    text, entries = store_mounts()
    (output / 'mountinfo-after.txt').write_text(text)
    require(entries and all('ro' in e['options'] and 'rw' not in e['options'] and
                           not any(v.startswith(('shared:', 'master:')) for v in e['optional'])
                           for e in entries), 'store mounts are not recursively private/read-only')
    return {'recursive_readonly': True, 'mounts': entries}


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
    # xterm terminfo can use ECMA-48 REP; pyte 0.8 otherwise ignores it.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, executable, env, root, output, number):
        self.output, self.root = output, root
        self.label = 'session-' + str(number)
        self.raw_file = (output / (self.label + '.pty')).open('xb')
        self.raw = bytearray()
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.status, self.eof = None, False
        self.deadline = time.monotonic() + 90
        self.argv = [executable, '-u', PLAYER, '-p', 'Valkyrie', '-r', 'human']
        self.inputs = []
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(executable, self.argv, env)
            except BaseException as error:
                os.write(2, ('exec failed: ' + repr(error) + '\n').encode())
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display)

    def read(self, delay=0.1):
        require(time.monotonic() < self.deadline, self.label + ': deadline exceeded\n' + self.text())
        if self.eof or not select.select([self.fd], [], [], delay)[0]:
            return False
        try:
            data = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        if not data:
            self.eof = True
            return False
        self.raw.extend(data)
        self.raw_file.write(data)
        self.raw_file.flush()
        self.stream.feed(self.decoder.decode(data))
        require(len(self.raw) < 8000000, 'excessive terminal output')
        require(b'Bad syntax' not in self.raw and b'Unrecognized pet type' not in self.raw,
                'native option parsing failed\n' + self.text())
        return True

    def exited(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
        return self.status is not None

    def send(self, keys):
        require(not self.exited(), self.label + ': process already exited')
        self.inputs.append({'raw_output_offset': len(self.raw), 'keys': keys})
        write_json(self.output / (self.label + '-inputs.json'), self.inputs)
        data = keys.encode('ascii')
        require(os.write(self.fd, data) == len(data), 'partial PTY input write')

    def settle(self):
        while self.read(0.25):
            pass

    def wait(self, predicate, description, more=True):
        end = time.monotonic() + 20
        while True:
            self.read()
            if more and '--More--' in self.text():
                self.send(' ')
                self.settle()
                continue
            if predicate():
                self.settle()
                if predicate():
                    return
            require(not self.exited(), description + ': exited\n' + self.text())
            require(time.monotonic() < end, description + ': timed out\n' + self.text())

    def snapshot(self, label):
        stem = self.label + '-' + label
        (self.output / (stem + '.screen.txt')).write_text(self.text() + '\n')
        write_json(self.output / (stem + '-cursor.json'),
                   {'column': self.screen.cursor.x, 'row': self.screen.cursor.y,
                    'pty_output_bytes': len(self.raw)})
        return stem

    def process_receipt(self, package):
        proc = Path('/proc') / str(self.pid)
        receipt = namespace_receipt(proc)
        exe = os.readlink(proc / 'exe')
        require(exe == str(package / 'libexec/sporkhack-real'),
                'PTY child is not the installed native executable: ' + exe)
        require(os.readlink(proc / 'fd/0').startswith('/dev/pts/'), 'game input is not a real PTY')
        require((proc / 'cmdline').read_bytes().split(b'\0')[1:-1] ==
                [arg.encode() for arg in self.argv[1:]], 'unexpected native argv (test mode?)')
        receipt.update({'pid': self.pid, 'executable': exe,
                        'tty': os.readlink(proc / 'fd/0'), 'argv': self.argv})
        write_json(self.output / (self.label + '-process.json'), receipt)
        return receipt

    def live(self, label):
        offset = len(self.raw)
        self.send('\x12')  # ordinary Ctrl-R; does not advance game moves
        self.settle()
        frame = bytes(self.raw[offset:])
        require(frame, 'native redraw produced no bytes')
        (self.output / (self.label + '-' + label + '-redraw.raw')).write_bytes(frame)
        if label == 'pre-exit':
            (self.output / 'pre-exit.raw').write_bytes(frame)
            (self.output / 'pre-exit.txt').write_text(self.text() + '\n')
        lines = self.screen.display
        hud = lines[22:24]
        require(NAME in hud[0] and 'Lawful' in hud[0], 'wrong player/alignment HUD\n' + self.text())
        stats = {}
        for stat in ('St', 'Dx', 'Co', 'In', 'Wi', 'Ch'):
            match = re.search(r'\b' + stat + r':\s*(\S+)', hud[0])
            require(match is not None, 'missing native HUD stat ' + stat)
            stats[stat] = match.group(1)
        turn = re.search(r'\bT:\s*(\d+)', hud[1])
        hp = re.search(r'\bHP:\s*(\d+)\((\d+)\)', hud[1])
        require(turn is not None, 'native time option missing\n' + self.text())
        require(hp is not None and int(hp.group(1)) > 0, 'player not alive\n' + self.text())
        require(re.search(r'\bDlvl:\s*1\b', hud[1]), 'not first dungeon level')
        dungeon = [line[:80] for line in lines[1:22]]
        require(len(dungeon) == 21 and all(len(line) == 80 for line in dungeon), 'wrong map dimensions')
        x, y = self.screen.cursor.x, self.screen.cursor.y - 1
        require(0 <= x < 80 and 0 <= y < 21 and dungeon[y][x] == '@',
                'native cursor does not identify displayed player\n' + self.text())
        require(any(c in ''.join(dungeon) for c in '.-|'), 'empty native map')
        state = {'hud': hud, 'stats': stats, 'turn': int(turn.group(1)),
                 'hp': [int(hp.group(1)), int(hp.group(2))], 'map': dungeon,
                 'player': [x, y], 'coordinate_kind': 'zero-based native 80x21 map viewport'}
        stem = self.snapshot(label)
        write_json(self.output / (stem + '.json'), state)
        return state

    def inventory(self, before, label):
        self.send('i')
        self.wait(lambda: re.search(r'\(end\)|\(\d+ of \d+\)', self.text()),
                  'native inventory menu', more=False)
        items, pages = [], set()
        for page in range(20):
            marker = re.search(r'\(end\)|\((\d+) of (\d+)\)', self.text())
            require(marker is not None, 'inventory marker missing')
            require(marker.group(0) not in pages, 'inventory pagination stalled')
            pages.add(marker.group(0))
            self.snapshot(label + '-page-' + str(page + 1))
            for line in self.screen.display:
                item = re.match(r'^\s*([a-zA-Z$])\s+[-+]\s+(.+?)\s*$', line)
                if item:
                    items.append({'letter': item.group(1), 'description': item.group(2)})
            if marker.group(0) == '(end)' or marker.group(1) == marker.group(2):
                self.send(' ')
                break
            expected = int(marker.group(1)) + 1
            self.send('>')
            self.wait(lambda: '(' + str(expected) + ' of ' in self.text(),
                      'next native inventory page', more=False)
        else:
            raise RuntimeError('too many inventory pages')
        self.settle()
        require(items and len({i['letter'] for i in items}) == len(items), 'invalid exact inventory rows')
        require(self.live(label + '-closed') == before, 'inventory inspection changed native state')
        return items

    def capture(self, label):
        state = self.live(label)
        state['inventory'] = self.inventory(state, label + '-inventory')
        write_json(self.output / (self.label + '-' + label + '-complete.json'), state)
        return state

    def advance(self, before):
        # Pick an actually displayed adjacent floor, not a fixture coordinate.
        # Fail on no eligible floor rather than inject a level or retry the RNG.
        x, y = before['player']
        for dx, dy, key in ((-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j')):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 80 and 0 <= ny < 21 and before['map'][ny][nx] == '.':
                self.send(key)
                self.settle()
                moved = self.live('movement')
                require(moved['turn'] > before['turn'] and moved['player'] == [nx, ny],
                        'ordinary floor movement did not move player and advance turn')
                break
        else:
            raise RuntimeError('no adjacent displayed floor; native game retained as failure evidence')
        current = moved
        for number in range(2):
            self.send('s')
            self.settle()
            self.wait(lambda: '--More--' not in self.text(), 'ordinary search turn')
            current = self.live('search-' + str(number + 1))
            require(current['turn'] > moved['turn'] + number, 'search did not advance moves')
        require(current['turn'] >= before['turn'] + 3, 'not enough ordinary world turns')
        return self.capture('advanced')

    def save(self):
        offset = len(self.raw)
        self.send('S')
        self.wait(lambda: 'Really save?' in self.text(), 'native save confirmation', more=False)
        self.snapshot('save-confirmation')
        self.send('y')
        end = time.monotonic() + 20
        while not self.exited() or not self.eof:
            self.read()
            if '--More--' in self.text() and not self.exited():
                self.send(' ')
            require(time.monotonic() < end, 'native S/y save did not exit')
        require(self.status == 0, 'native save exit status: ' + str(self.status))
        tail = bytes(self.raw[offset:])
        require(b'Saving...' in tail and b'Be seeing you...' in tail,
                'normal native save/exit messages absent')
        self.snapshot('saved-exit')

    def close(self):
        if not self.exited():
            # Kill only this consumer's failed child.  This never counts as save.
            os.kill(self.pid, signal.SIGKILL)
            _, status = os.waitpid(self.pid, 0)
            self.status = os.waitstatus_to_exitcode(status)
        os.close(self.fd)
        self.raw_file.close()


def native_save(state, output, number, live):
    files = [p for p in (state / 'save').rglob('*') if p.is_file()]
    expected = state / 'save' / (str(os.getuid()) + NAME)
    require(files == [expected] and expected.stat().st_size > 0,
            'expected one nonempty native same-UID/player save, without external compression')
    copy = output / ('session-' + str(number) + '.native-save')
    shutil.copyfile(expected, copy)  # Evidence copy only; never fed back to game.
    whereis = (state / (NAME + '.whereis')).read_text()
    (output / ('session-' + str(number) + '-saved.whereis')).write_text(whereis)
    values = dict(field.split('=', 1) for field in whereis.strip().split(':'))
    require(values['playing'] == '0' and int(values['turns']) == live['turn'] and
            [int(values['hp']), int(values['maxhp'])] == live['hp'],
            'native saved whereis differs from pre-exit HUD')
    # u_init.c:533 zeroes u; u.mfemale is the saved pre-polymorph sex,
    # assigned on first polymorph (polyself.c:357), NOT flags.female.
    # This ordinary never-polymorphed female therefore writes gender=Mal.
    # The selector independently proves Female; do not interpret whereis's
    # uninitialized polymorph field as actual character gender at this pin.
    require(values['depth'] == '1' and values['dnum'] == '0' and values['gender'] == 'Mal' and
            values['role'] == 'Valkyrie' and values['race'] == 'human' and
            values['align'] == 'Law' and values['amulet'] == '0',
            'wrong native saved character/level fields')
    # delete_whereis uses native display names, not initial filecodes.
    return {'path': str(expected.relative_to(state)), 'size': copy.stat().st_size,
            'sha256': sha(copy), 'whereis': values, 'save_evidence_only_not_reinjected': True}


def launch_isolated(package, output):
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized util-linux unshare unavailable')
    variables = ('PATH', 'HOME', 'TMPDIR', 'GUIX_PYTHONPATH', 'PYTHONPATH', 'TERMINFO',
                 'TERMINFO_DIRS', 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME')
    env = {key: os.environ[key] for key in variables if os.environ.get(key)}
    env.update({'LC_ALL': 'C', 'SPORK_HOST_UID': str(os.getuid()), 'SPORK_HOST_GID': str(os.getgid())})
    for name in ('user', 'mnt', 'net', 'pid'):
        env['SPORK_HOST_' + name.upper()] = os.readlink('/proc/self/ns/' + name)
    env['SPORK_INSIDE'] = '1'
    command = [unshare, '--user', '--map-current-user', '--keep-caps', '--mount',
               '--propagation', 'private', '--net', '--pid', '--mount-proc', '--kill-child',
               '--fork', sys.executable, '-B', str(Path(__file__).resolve()),
               str(package), str(output)]
    receipt = {'command': command, 'host_namespaces': {k: v for k, v in env.items() if k.startswith('SPORK_HOST_')}}
    write_json(output / 'namespace-launch.json', receipt)
    with (output / 'namespace.stdout').open('xb') as stdout, (output / 'namespace.stderr').open('xb') as stderr:
        process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        try:
            status = process.wait(timeout=240)
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise
    receipt['exit_status'] = status
    write_json(output / 'namespace-launch.json', receipt)
    if status != 0:
        sys.stderr.write((output / 'namespace.stderr').read_text(errors='replace'))
        require(False, 'isolated proof failed (namespace denial is not a pass): ' + str(status))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path, help='already-realized SporkHack store output')
    parser.add_argument('evidence', type=Path, help='shell-created fresh evidence directory')
    args = parser.parse_args()
    package = args.package.resolve()
    executable = str(package / 'bin/sporkhack')
    output = args.evidence.absolute()
    require(output.is_dir() and not (output / 'continuity.json').exists(), 'fresh shell evidence directory required')
    require(os.access(executable, os.X_OK), 'installed launcher not executable')
    if os.environ.get('SPORK_INSIDE') != '1':
        try:
            launch_isolated(package, output)
        except BaseException as error:
            if not (output / 'continuity.json').exists():
                write_json(output / 'continuity.json', {'success': False, 'error': str(error)})
            raise
        print('SPORKHACK NATIVE SMOKE OK')
        return
    report = {'success': False, 'executable': executable, 'options': OPTIONS,
              'source_revision': SOURCE_REVISION, 'sessions': [], 'continuity': []}
    write_json(output / 'continuity.json', report)
    session = None
    try:
        report['output_contract'] = output_contract(package, output)
        report['isolation'] = namespace_receipt(Path('/proc/self'))
        report['isolation']['store'] = readonly_store(output)
        original_home = Path.home()
        watched = {original_home / '.nethackrc', original_home / '.sporkrc',
                   original_home / '.local/state/sporkhack', original_home / '.local/share/sporkhack',
                   Path.cwd() / 'save', Path.cwd() / 'bones', Path.cwd() / 'level', Path.cwd() / 'dumps'}
        for variable in ('XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME'):
            if os.environ.get(variable):
                watched.add(Path(os.environ[variable]) / 'sporkhack')
        initial = {str(path): fingerprint(path) for path in watched}
        with tempfile.TemporaryDirectory(prefix='spork-proof-', dir='/tmp') as directory:
            root = Path(directory)
            for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
                (root / name).mkdir(mode=0o700)
            options_path = root / 'config/native-options'
            options_path.write_text('OPTIONS=' + OPTIONS + '\n')
            env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color', 'LC_ALL': 'C',
                   'PATH': '', 'TMPDIR': str(root / 'tmp'), 'NETHACKOPTIONS': '@' + str(options_path)}
            for variable in ('TERMINFO', 'TERMINFO_DIRS'):
                if os.environ.get(variable):
                    env[variable] = os.environ[variable]
            for variable, subdir in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                     ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                     ('XDG_RUNTIME_DIR', 'runtime')):
                env[variable] = str(root / subdir)
            state = root / 'state/sporkhack'
            previous = None
            for number in (1, 2):
                session = Session(executable, env, root, output, number)
                if number == 1:
                    session.wait(lambda: 'Create your character:' in session.text() and
                                 '. - play!' in session.text(), 'ordinary character selector', more=False)
                    for selection in ('v + Valkyrie', 'H + Human', 'F + Female', 'L + Lawful'):
                        require(selection in session.text(), 'wrong native character selection: ' + selection)
                    session.snapshot('character-selection')
                    session.send('.')  # src/charinit.c:166, the normal play! menu action
                session.wait(lambda: NAME in session.screen.display[22] and
                             'HP:' in session.screen.display[23], 'ordinary native startup')
                process = session.process_receipt(package)
                raw = bytes(session.raw)
                if number == 1:
                    require(b'welcome to SporkHack!' in raw and b'welcome back' not in raw,
                            'first process did not start an ordinary new game')
                else:
                    require(b'Restoring save file...' in raw and b'welcome back to SporkHack!' in raw,
                            'second process did not normally auto-restore same player')
                start = session.capture('first-live' if number == 1 else 'restored')
                if previous is not None:
                    require(start == previous, 'restored full map/HUD/turn/player/inventory differ from saved state')
                    require(not any(p.is_file() for p in (state / 'save').rglob('*')),
                            'ordinary non-wizard restore did not consume native save')
                    report['continuity'].append({'from': 1, 'to': 2,
                                                 'full_map_hud_inventory_exact': True,
                                                 'native_save_consumed': True})
                advanced = session.advance(start)
                pre_exit = session.live('pre-exit')
                require(all(pre_exit[key] == advanced[key] for key in pre_exit),
                        'pre-exit renderer changed without a turn')
                session.save()
                saved = native_save(state, output, number, advanced)
                report['sessions'].append({'argv': session.argv, 'process': process, 'initial': start,
                                           'advanced': advanced, 'native_save': saved,
                                           'normal_save_exit_status': session.status})
                write_json(output / 'continuity.json', report)
                previous = advanced
                session.close()
                session = None
            for subdir in ('home', 'data', 'cache', 'runtime', 'tmp', 'work'):
                require(not list((root / subdir).iterdir()), 'unexpected state escaped to private ' + subdir)
            require(list((root / 'config').iterdir()) == [options_path], 'unexpected config write')
            require(list((root / 'state').iterdir()) == [state], 'state escaped game XDG directory')
            require(not list((state / 'dumplog').iterdir()), 'saving unexpectedly produced a game-end dump')
            for path in root.rglob('*'):
                require(not path.is_symlink(), 'private runtime symlink could escape root')
                require(path.stat().st_uid == os.getuid(), 'runtime file not owned by caller')
                require(path.stat().st_mode & 0o077 == 0, 'runtime state not private: ' + str(path))
            report['private_footprint'] = {str(p.relative_to(root)): {'size': p.stat().st_size, 'sha256': sha(p)}
                                          for p in root.rglob('*') if p.is_file()}
            require(all(fingerprint(Path(path)) == value for path, value in initial.items()),
                    'host game config/state or working directory changed')
            report['private_environment'] = env
            report['host_game_state_unchanged'] = True
            report['success'] = True
        write_json(output / 'continuity.json', report)
    except BaseException as error:
        report['error'] = repr(error)
        if session is not None:
            session.snapshot('failure')
            session.close()
            report['failed_session_exit_status'] = session.status
        write_json(output / 'continuity.json', report)
        raise


if __name__ == '__main__':
    main()
