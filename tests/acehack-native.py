#!/usr/bin/env python3
"""External AceHack PTY acceptance; no installed helper or injected game state.

The ordinary launcher owns state.  Native n/. birth, h/j/k/l movement, s search,
S/y save/exit, c restore and continued turns provide all gameplay evidence.
Every displayed map cell and both entire HUD rows are compared within this run;
no RNG fixture, wizard/discovery/tutorial mode, OCR or save mutation is used.
Generic Python/pyte/unshare tools are external to the package runtime closure.
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
import struct
import subprocess
import sys
import termios
import time

import pyte

SOURCE_REVISION = '9a4c7671a8d8de6c0a7ab4718382b49cf5ec61f5'
SOURCE_URL = 'https://github.com/deepy/acehack/tree/' + SOURCE_REVISION
ROWS, COLS = 24, 100
NAME = 'OmpProof'
# src/options.c:629-646 accepts ACEHACKOPTIONS=@file without reading host RC.
# Character options are ordinary birth preferences, not injected game state.
# number_pad remains a stale compopt entry at options.c:299 but has no
# parser at this pin.  cmd.c's native bindings always include h/j/k/l.
OPTIONS = ('windowtype:tty,role:Valkyrie,race:human,gender:female,align:lawful,'
           'time,!IBMgraphics,!DECgraphics,!color,!floorcolor,!room_colors,'
           '!legacy,!news,!autopickup,!startscum,pettype:none,'
           'menustyle:full')
SOURCE_ANCHORS = {
    'geometry': 'include/global.h:322-323 COLNO=80 ROWNO=21; '
                'win/tty/wintty.c:1045-1064 map offy=1 status offy=22',
    'hud': 'src/botl.c:166-247 hp_pw_bar/bot1: HP:[current / max], '
           'AC, Xp, Dungeons, name/rank; 297-312 bot2: Pw, gold, S:score, T:moves',
    'mode': 'win/tty/wintty.c:336-428 n=new game c=continue; dat/logo.vt100:15-24',
    'birth': 'win/tty/wintty.c:530-557 v/H/F/L accelerators; '
             '660 Create your character; 692-694 selected +; 857 ordinary . play!',
    'controls': 'src/cmd.c:1853,1893,1922,1929-1932,1988 l/k/Ctrl-R/S/s/j/h',
    'save': 'src/save.c:55-97 S opens stop-playing menu; y quicksave; '
            'Saving...; blocking display; Be seeing you...; EXIT_SUCCESS',
    'save_path': 'src/files.c:1097 save/<getuid()>player; native INTERNAL_COMP '
                 'at package --with-compression=no (no external compressor)',
    'restore': 'sys/unix/unixmain.c:258-303 Restoring save file; '
               'src/restore.c:649-650 ordinary restore consumes save; '
               'src/allmain.c:981-984 welcome [back] to AceHack',
}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


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


def output_contract(package, evidence):
    require(package.parent == Path('/gnu/store'), 'OUTPUT must be a direct store output')
    require((package / 'libexec/acehack').read_bytes()[:4] == b'\x7fELF',
            'installed native executable is not ELF')
    for path in [package, *package.rglob('*')]:
        if path.is_symlink():
            # POSIX symlink modes are normally 0777; immutability applies to
            # the resolved file, not these inert link permission bits.
            target = path.resolve(strict=True)
            require(target.is_relative_to(package), 'installed symlink escapes output: ' + str(path))
            require(target.stat().st_mode & 0o222 == 0, 'symlink target has write bits: ' + str(path))
        else:
            require(path.stat().st_mode & 0o222 == 0, 'output has write bits: ' + str(path))
    data = package / 'share/acehack/nhdat'
    require(data.is_file() and data.stat().st_size > 0, 'native nhdat missing')
    doc = package / 'share/doc/acehack'
    for name in ('license', 'README', 'Guidebook.txt', 'fixes36.0'):
        require((doc / name).is_file() and (doc / name).stat().st_size > 0,
                'installed upstream notice missing: ' + name)
    require('NETHACK GENERAL PUBLIC LICENSE' in (doc / 'license').read_text(), 'NGPL missing')
    text = (doc / 'README').read_text()
    for marker in ('AceHack 3.6.0', 'contributors to AceHack', 'also expect that you will follow it'):
        require(marker in text, 'README attribution/license marker missing: ' + marker)
    require(not any('smoke' in p.name for p in (package / 'libexec').iterdir()),
            'installed test helper is forbidden')
    closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
    require(str(package) in closure, 'runtime closure receipt missing')
    names = [Path(path).name[33:] for path in closure]
    require(not any(name.startswith(('python-', 'python-pyte-')) for name in names),
            'external test tools leaked into runtime closure')
    return {'source_revision': SOURCE_REVISION, 'source_url': SOURCE_URL,
            'source_anchors': SOURCE_ANCHORS, 'runtime_closure': closure,
            'native_executable_sha256': sha(package / 'libexec/acehack'),
            'nhdat_sha256': sha(data)}


def namespace_receipt(proc):
    namespaces = {name: os.readlink(proc / 'ns' / name) for name in ('user', 'mnt', 'net', 'pid')}
    for name, actual in namespaces.items():
        require(actual != os.environ['ACE_HOST_' + name.upper()], 'host namespace leaked: ' + name)
        require(actual == os.readlink('/proc/self/ns/' + name), 'game escaped private ' + name)
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, text = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(x) for x in text.split()]
    maps = {}
    for kind, key in (('uid', 'Uid'), ('gid', 'Gid')):
        expected = int(os.environ['ACE_HOST_' + kind.upper()])
        require(identity[key] == [expected] * 4, 'process changed caller ' + key)
        maps[kind] = (proc / (kind + '_map')).read_text()
        require([int(x) for x in maps[kind].split()] == [expected, expected, 1],
                'not an exact same-UID/GID mapping')
    interfaces = sorted(line.split(':')[0].strip() for line in
                        (proc / 'net/dev').read_text().splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'offline namespace exposes non-loopback interfaces')
    return {'namespaces': namespaces, 'identity': identity, 'maps': maps, 'interfaces': interfaces}


def mount(source, target, flags):
    # mount(8) rejects nonzero real UID: use the syscall with namespace caps.
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


def readonly_store(evidence):
    (evidence / 'mountinfo-before.txt').write_text(store_mounts()[0])
    mount('/gnu/store', '/gnu/store', 4096 | 16384)  # MS_BIND | MS_REC
    mount('/gnu/store', '/gnu/store', 262144 | 16384)  # MS_PRIVATE | MS_REC
    for target in sorted({e['target'] for e in store_mounts()[1]}, key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)  # MS_BIND | MS_REMOUNT | MS_RDONLY
    text, entries = store_mounts()
    (evidence / 'mountinfo-after.txt').write_text(text)
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
    # xterm terminfo may emit ECMA-48 REP, not implemented by stock pyte 0.8.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, package, env, root, evidence, number):
        self.package, self.evidence = package, evidence
        self.label = 'session-' + str(number)
        self.raw_file = (evidence / (self.label + '.pty')).open('xb')
        self.raw = bytearray()
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.status, self.eof = None, False
        self.deadline = time.monotonic() + 90
        self.inputs = []
        # Use a suffix-free name: game_mode_selection checks saves BEFORE
        # plnamesuffix strips suffixes (unixmain.c:172-214).
        self.argv = [str(package / 'bin/acehack'), '-u', NAME, '-p', 'Valkyrie', '-r', 'human']
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(self.argv[0], self.argv, env)
            except BaseException as error:
                os.write(2, ('exec failed: ' + repr(error) + '\n').encode())
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display)

    def exited(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
        return self.status is not None

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
        require(len(self.raw) < 8000000, 'excessive PTY output')
        require(b'Bad syntax' not in self.raw and b'Unrecognized pet type' not in self.raw,
                'native options rejected\n' + self.text())
        return True

    def send(self, keys):
        require(not self.exited(), self.label + ': process already exited')
        self.inputs.append({'raw_output_offset': len(self.raw), 'keys': keys})
        write_json(self.evidence / (self.label + '-inputs.json'), self.inputs)
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
        (self.evidence / (stem + '.screen.txt')).write_text(self.text() + '\n')
        write_json(self.evidence / (stem + '-cursor.json'),
                   {'column': self.screen.cursor.x, 'row': self.screen.cursor.y,
                    'pty_output_bytes': len(self.raw)})
        return stem

    def process_receipt(self):
        # The ordinary packaged shell launcher waits for the native game, then
        # copies only newly-created state.  Verify its real descendant, not
        # incorrectly /proc/<forkpty pid>/exe (which is the launcher shell).
        pending, found = [self.pid], []
        while pending:
            pid = pending.pop()
            proc = Path('/proc') / str(pid)
            try:
                executable = os.readlink(proc / 'exe')
                children = (proc / 'task' / str(pid) / 'children').read_text().split()
            except FileNotFoundError:
                continue
            pending.extend(int(child) for child in children)
            if executable == str(self.package / 'libexec/acehack'):
                found.append(proc)
        require(len(found) == 1, 'expected one installed native game below ordinary launcher')
        proc = found[0]
        receipt = namespace_receipt(proc)
        argv = (proc / 'cmdline').read_bytes().split(b'\0')[:-1]
        require(argv == [str(self.package / 'libexec/acehack').encode(),
                         *[arg.encode() for arg in self.argv[1:]]], 'unexpected native argv/test mode')
        tty = os.readlink(proc / 'fd/0')
        require(tty.startswith('/dev/pts/'), 'native input is not an external PTY')
        receipt.update({'pid': int(proc.name), 'launcher_pid': self.pid, 'tty': tty,
                        'executable': os.readlink(proc / 'exe'), 'argv': [a.decode() for a in argv]})
        write_json(self.evidence / (self.label + '-process.json'), receipt)
        return receipt

    def enter(self, restored):
        self.wait(lambda: 'c - Continue game' in self.text() and 'n - New game' in self.text(),
                  'native game-mode splash', more=False)
        self.snapshot('mode-selection')
        self.send('c' if restored else 'n')
        if not restored:
            self.wait(lambda: 'Create your character:' in self.text() and '. - play!' in self.text(),
                      'native ordinary birth selector', more=False)
            for selection in ('v + Valkyrie', 'H + Human', 'F + Female', 'L + Lawful'):
                require(selection in self.text(), 'wrong birth selection: ' + selection)
            self.snapshot('character-selection')
            self.send('.')
        self.wait(lambda: NAME in self.screen.display[22] and 'HP:[' in self.screen.display[22]
                  and 'T:' in self.screen.display[23], 'native dungeon startup')
        raw = bytes(self.raw)
        if restored:
            require(b'Restoring save file...' in raw and b'welcome back to AceHack!' in raw,
                    'native c restore/greeting missing')
        else:
            require(b'welcome to AceHack!' in raw and b'welcome back' not in raw,
                    'not an ordinary new game')

    def live(self, label):
        offset = len(self.raw)
        self.send('\x12')  # cmd.c:1922 ordinary Ctrl-R redraw, no game turn
        self.settle()
        frame = bytes(self.raw[offset:])
        require(frame, 'redraw produced no native bytes')
        (self.evidence / (self.label + '-' + label + '-redraw.raw')).write_bytes(frame)
        hud = [row[:80] for row in self.screen.display[22:24]]
        require(NAME in hud[0], 'player absent from native name/rank HUD')
        hp = re.search(r'HP:\[\s*(\d+)\s*/\s*(\d+)\s*\]', hud[0])
        pw = re.search(r'Pw:\[\s*(\d+)\s*/\s*(\d+)\s*\]', hud[1])
        stats = re.search(r'AC:(-?\d+) Xp:(\d+) Dungeons:(\d+)', hud[0])
        counters = re.search(r'\$(\d+) S:(-?\d+) T:(\d+)', hud[1])
        require(hp and pw and stats and counters, 'source-exact AceHack HUD decode failed\n' + self.text())
        require(int(hp.group(1)) > 0 and stats.group(3) == '1', 'not alive on dungeon level 1')
        dungeon = [row[:80] for row in self.screen.display[1:22]]
        x, y = self.screen.cursor.x, self.screen.cursor.y - 1
        require(0 <= x < 80 and 0 <= y < 21 and dungeon[y][x] == '@',
                'native cursor does not identify displayed player\n' + self.text())
        require(any(c in ''.join(dungeon) for c in '.-|'), 'empty dungeon viewport')
        state = {'hud': hud, 'map': dungeon, 'player': [x, y],
                 'coordinate_kind': 'zero-based native 80x21 map viewport',
                 'hp': [int(value) for value in hp.groups()],
                 'pw': [int(value) for value in pw.groups()],
                 'ac': int(stats.group(1)), 'experience_level': int(stats.group(2)),
                 'depth': int(stats.group(3)), 'gold': int(counters.group(1)),
                 'score': int(counters.group(2)), 'turn': int(counters.group(3))}
        stem = self.snapshot(label)
        write_json(self.evidence / (stem + '.json'), state)
        if label == 'pre-exit':
            (self.evidence / 'pre-exit.raw').write_bytes(frame)
            (self.evidence / 'pre-exit.txt').write_text(self.text() + '\n')
        return state

    def advance(self, before):
        x, y = before['player']
        for dx, dy, key in ((-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j')):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 80 and 0 <= ny < 21 and before['map'][ny][nx] == '.':
                self.send(key)
                self.wait(lambda: '--More--' not in self.text(), 'native floor movement')
                moved = self.live('movement')
                require(moved['turn'] > before['turn'] and moved['player'] == [nx, ny],
                        'native movement did not change coordinate and turn')
                break
        else:
            raise RuntimeError('no adjacent displayed floor; no RNG retry or injected level permitted')
        current = moved
        for number in range(2):
            self.send('s')
            self.wait(lambda: '--More--' not in self.text(), 'native search turn')
            following = self.live('search-' + str(number + 1))
            require(following['turn'] > current['turn'], 'native search did not advance time')
            current = following
        require(current['turn'] >= before['turn'] + 3, 'not enough native dungeon turns')
        return current

    def save(self):
        offset = len(self.raw)
        self.send('S')
        self.wait(lambda: 'Do you want to stop playing?' in self.text() and
                  'y - Quicksave and exit the game' in self.text(), 'native S save menu', more=False)
        self.snapshot('save-menu')
        self.send('y')
        end = time.monotonic() + 20
        while not self.exited() or not self.eof:
            self.read()
            if '--More--' in self.text() and not self.exited():
                self.send(' ')
                self.settle()
            require(time.monotonic() < end, 'normal quicksave did not exit')
        require(self.status == 0, 'native quicksave/launcher exit status: ' + str(self.status))
        tail = bytes(self.raw[offset:])
        require(b'Saving...' in tail and b'Be seeing you...' in tail, 'native save/exit messages missing')
        self.snapshot('saved-exit')

    def close(self):
        if not self.exited():
            # Failed consumer child only.  Forced termination never counts as
            # acceptance, and saves made by hangup are not used for continuity.
            os.kill(self.pid, signal.SIGKILL)
            _, status = os.waitpid(self.pid, 0)
            self.status = os.waitstatus_to_exitcode(status)
        os.close(self.fd)
        self.raw_file.close()


def native_save(state, evidence, number):
    files = sorted(p for p in (state / 'save').rglob('*') if p.is_file())
    expected = state / 'save' / (str(os.getuid()) + NAME)
    require(files == [expected] and not expected.is_symlink() and expected.stat().st_size > 0,
            'expected one nonempty native same-UID/player save')
    copy = evidence / ('session-' + str(number) + '.native-save')
    shutil.copyfile(expected, copy)  # Receipt only; NEVER supplied back to game.
    return {'path': str(expected.relative_to(state)), 'size': copy.stat().st_size,
            'sha256': sha(copy), 'evidence_copy_never_reinjected': True}


def launch_isolated(package, evidence):
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized util-linux unshare unavailable')
    variables = ('PATH', 'HOME', 'TMPDIR', 'GUIX_PYTHONPATH', 'PYTHONPATH', 'TERMINFO',
                 'TERMINFO_DIRS', 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME')
    env = {key: os.environ[key] for key in variables if os.environ.get(key)}
    env.update({'LC_ALL': 'C', 'ACE_HOST_UID': str(os.getuid()), 'ACE_HOST_GID': str(os.getgid())})
    for name in ('user', 'mnt', 'net', 'pid'):
        env['ACE_HOST_' + name.upper()] = os.readlink('/proc/self/ns/' + name)
    command = [unshare, '--user', '--map-current-user', '--keep-caps', '--mount',
               '--propagation', 'private', '--net', '--pid', '--mount-proc', '--kill-child',
               '--fork', sys.executable, '-B', str(Path(__file__).resolve()),
               str(package), str(evidence), '--inside']
    receipt = {'command': command, 'host_identity_and_namespaces':
               {key: value for key, value in env.items() if key.startswith('ACE_HOST_')}}
    write_json(evidence / 'namespace-launch.json', receipt)
    with (evidence / 'namespace.stdout').open('xb') as stdout, (evidence / 'namespace.stderr').open('xb') as stderr:
        process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        try:
            status = process.wait(timeout=240)
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise
    receipt['exit_status'] = status
    write_json(evidence / 'namespace-launch.json', receipt)
    if status != 0:
        sys.stderr.write((evidence / 'namespace.stderr').read_text(errors='replace'))
        require(False, 'isolated proof failed (namespace denial is not acceptance): ' + str(status))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path, help='prebuilt AceHack output')
    parser.add_argument('evidence', type=Path, help='shell-created fresh evidence directory')
    parser.add_argument('--inside', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    package, evidence = args.package.resolve(), args.evidence.resolve()
    require(evidence.is_dir() and not (evidence / 'continuity.json').exists(), 'fresh shell evidence required')
    if not args.inside:
        try:
            launch_isolated(package, evidence)
        except BaseException as error:
            if not (evidence / 'continuity.json').exists():
                write_json(evidence / 'continuity.json', {'success': False, 'error': repr(error)})
            raise
        print('ACEHACK NATIVE SMOKE OK')
        return
    report = {'success': False, 'source_revision': SOURCE_REVISION, 'options': OPTIONS,
              'sessions': [], 'continuity': []}
    write_json(evidence / 'continuity.json', report)
    session = None
    try:
        report['output_contract'] = output_contract(package, evidence)
        report['isolation'] = namespace_receipt(Path('/proc/self'))
        report['isolation']['store'] = readonly_store(evidence)
        original_home = Path.home()
        watched = {original_home / '.acehackrc', original_home / '.nethackrc',
                   original_home / '.local/share/acehack', original_home / '.local/state/acehack',
                   Path.cwd() / 'save', Path.cwd() / 'level', Path.cwd() / 'lock', Path.cwd() / 'dumps'}
        for variable in ('XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME'):
            if os.environ.get(variable):
                watched.add(Path(os.environ[variable]) / 'acehack')
        initial = {str(path): fingerprint(path) for path in watched}
        # Retain actual private native saves and failed sessions as evidence;
        # never remove or alter host game state or feed an evidence copy back.
        root = evidence / 'private'
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        options_path = root / 'config/native-options'
        options_path.write_text('OPTIONS=' + OPTIONS + '\n')
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color', 'LC_ALL': 'C',
               'PATH': '', 'TMPDIR': str(root / 'tmp'), 'ACEHACKOPTIONS': '@' + str(options_path)}
        for variable in ('TERMINFO', 'TERMINFO_DIRS'):
            if os.environ.get(variable):
                env[variable] = os.environ[variable]
        for variable, subdir in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                 ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                 ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / subdir)
        state = root / 'data/acehack'
        previous, first_save = None, None
        for number in (1, 2):
            session = Session(package, env, root, evidence, number)
            session.enter(restored=number == 2)
            process = session.process_receipt()
            start = session.live('restored' if number == 2 else 'first-live')
            if previous is not None:
                require(start == previous, 'restored exact full map/HUD/turn/position differ from pre-save state')
                require(not any(p.is_file() for p in (state / 'save').rglob('*')),
                        'ordinary restore did not consume native save')
                report['continuity'].append({'from': 1, 'to': 2, 'full_map_and_hud_exact': True,
                                             'native_save_consumed': True})
            advanced = session.advance(start)
            require(session.live('pre-exit') == advanced, 'redraw changed native game state without a turn')
            session.save()
            saved = native_save(state, evidence, number)
            if first_save is not None:
                require(saved['sha256'] != first_save['sha256'], 'continued turns produced identical save')
            else:
                first_save = saved
            report['sessions'].append({'process': process, 'launcher_argv': session.argv,
                                       'initial': start, 'advanced': advanced, 'native_save': saved,
                                       'normal_save_exit_status': session.status})
            write_json(evidence / 'continuity.json', report)
            previous = advanced
            session.close()
            session = None
        for name in ('home', 'cache', 'state', 'runtime', 'tmp', 'work'):
            require(not any((root / name).iterdir()), 'state escaped native XDG data: ' + name)
        require(list((root / 'config').iterdir()) == [options_path], 'unexpected config write')
        require(list((root / 'data').iterdir()) == [state], 'state escaped acehack data directory')
        for path in root.rglob('*'):
            require(not path.is_symlink(), 'private runtime symlink could escape root: ' + str(path))
            require(path.stat().st_uid == os.getuid(), 'native state changed ownership')
            # unixmain.c:99 resets umask to 0007 (FCMASK=0660).  Native
            # group-readable saves remain inside the caller-only 0700 tree;
            # do not chmod native state to manufacture a different contract.
            forbidden = 0o077 if path.is_dir() else 0o007
            require(path.stat().st_mode & forbidden == 0, 'native state is not private: ' + str(path))
        require(all(fingerprint(Path(path)) == value for path, value in initial.items()),
                'host game state/config or working directory changed')
        report['private_footprint'] = {str(p.relative_to(root)): {'size': p.stat().st_size, 'sha256': sha(p)}
                                       for p in root.rglob('*') if p.is_file()}
        report['private_environment'] = env
        report['host_game_state_unchanged'] = True
        report['success'] = True
        write_json(evidence / 'continuity.json', report)
    except BaseException as error:
        report['error'] = repr(error)
        if session is not None:
            session.snapshot('failure')
            session.close()
            report['failed_session_exit_status'] = session.status
        write_json(evidence / 'continuity.json', report)
        raise


if __name__ == '__main__':
    main()
