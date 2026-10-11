#!/usr/bin/env python3
"""External Encircled PTY proof: ordinary Standard gameplay and postmortem report.

No installed test hooks, injected seed/state, boss shortcut, or resume claim.
The 80x30 decoded frames are actual terminal output, not a source-text oracle.
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
import site
import stat
import signal
import struct
import subprocess
import sys
import termios
import time

import pyte

ROWS, COLS = 30, 80
SOURCE_URL = 'https://dl.dropbox.com/s/ldw5k988ryubtli/encircled.zip'
SOURCE_SHA256 = '5fc3157c0b986b3af62c5d196201870168fcea048683626f5d028e1e385b99e2'
ERRORS = re.compile(r'Please resize your terminal|does not support colour|Error opening terminal|'
                    r'exec failed|segmentation fault|assertion .*failed|terminate called|'
                    r'symbol lookup error|cannot open shared object|error while loading', re.I)


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

def tool_receipt():
    require(sys.flags.no_user_site and not site.ENABLE_USER_SITE,
            'Python must run with -s and user-site disabled')
    tools = {'python': sys.executable, 'unshare': shutil.which('unshare'), 'pyte': pyte.__file__}
    resolved = {}
    for name, value in tools.items():
        require(value is not None, 'realized tool missing: ' + name)
        path = Path(value).resolve(strict=True)
        require(path.is_relative_to('/gnu/store'), 'ambient non-store tool forbidden: ' + str(path))
        resolved[name] = str(path)
    driver = Path(__file__).resolve()
    imports = {}
    for name, module in tuple(sys.modules.items()):
        value = getattr(module, '__file__', None)
        if value:
            path = Path(value).resolve(strict=True)
            require(path == driver or path.is_relative_to('/gnu/store'),
                    'ambient Python module forbidden: ' + name + ': ' + str(path))
            imports[name] = str(path)
    import_paths = []
    for value in sys.path:
        path = Path(value).resolve()
        require(path == driver.parent or path.is_relative_to('/gnu/store'),
                'ambient Python search path forbidden: ' + str(path))
        import_paths.append(str(path))
    return {'executables_and_pyte': resolved, 'module_files': imports,
            'import_paths': import_paths, 'no_user_site': True}



def output_contract(package, evidence):
    require(package.parent == Path('/gnu/store') and re.fullmatch(
        r'[0-9abcdfghijklmnpqrsvwxyz]{32}-encircled-.+', package.name),
        'OUTPUT must be the canonical realized Encircled store output')
    binary = package / 'bin/encircled'
    require(binary.is_file() and not binary.is_symlink() and os.access(binary, os.X_OK),
            'ordinary bin/encircled executable missing')
    require(binary.read_bytes()[:4] == b'\x7fELF', 'ordinary installed executable is not ELF')
    notice_path = package / 'share/doc/encircled/SOURCE-NOTICE'
    require(stat.S_ISREG(notice_path.lstat().st_mode), 'installed regular source notice missing')
    notice = notice_path.read_text()
    for marker in ('Encircled -- SRD (Quendus)', SOURCE_SHA256,
                   '// This code is public domain. Do anything you want with it.'):
        require(marker in notice, 'installed scoped provenance marker missing: ' + marker)
    for path in [package, *package.rglob('*')]:
        require(not path.is_symlink(), 'unexpected installed symlink: ' + str(path))
        require(path.stat().st_mode & 0o222 == 0, 'output has write bits: ' + str(path))
        require(path.suffix.lower() not in ('.exe', '.dll'), 'prebuilt binary shipped: ' + str(path))
        require('smoke' not in path.name and 'native.py' not in path.name,
                'installed proof helper forbidden: ' + str(path))
    closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
    require(str(package) in closure, 'runtime closure receipt missing')
    require(not any(Path(p).name[33:].startswith(('python-', 'python-pyte-')) for p in closure),
            'external terminal tools leaked into runtime closure')
    return {'source_url': SOURCE_URL, 'source_sha256': SOURCE_SHA256,
            'native_executable_sha256': sha(binary), 'runtime_closure': closure,
            'source_notice_sha256': sha(notice_path)}


def namespace_receipt(proc):
    namespaces = {name: os.readlink(proc / 'ns' / name) for name in ('user', 'mnt', 'net', 'pid')}
    for name, actual in namespaces.items():
        require(actual != os.environ['ENC_HOST_' + name.upper()], 'host namespace leaked: ' + name)
        require(actual == os.readlink('/proc/self/ns/' + name), 'game escaped private namespace: ' + name)
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, text = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(x) for x in text.split()]
    maps = {}
    for kind, key in (('uid', 'Uid'), ('gid', 'Gid')):
        expected = int(os.environ['ENC_HOST_' + kind.upper()])
        require(identity[key] == [expected] * 4, 'process changed caller ' + key)
        maps[kind] = (proc / (kind + '_map')).read_text()
        require([int(x) for x in maps[kind].split()] == [expected, expected, 1],
                'not an exact same-UID/GID mapping')
    interfaces = sorted(line.split(':')[0].strip() for line in
                        (proc / 'net/dev').read_text().splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'offline namespace exposes non-loopback interfaces')
    return {'namespaces': namespaces, 'identity': identity, 'maps': maps, 'interfaces': interfaces}


def mount(source, target, flags):
    # mount(8) rejects nonzero real UID; use the syscall with namespace caps.
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
                            for e in entries), 'store mounts not recursively private/read-only')
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
    # xterm terminfo's ECMA-48 REP is absent from stock pyte 0.8.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, package, env, work, evidence, number):
        self.package, self.evidence = package, evidence
        self.label = 'session-' + str(number)
        self.raw_file = (evidence / (self.label + '.pty')).open('xb')
        self.raw = bytearray()
        self.inputs = []
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.status, self.eof = None, False
        self.deadline = time.monotonic() + 120
        self.argv = [str(package / 'bin/encircled')]
        self.fd, slave = os.openpty()
        self.original_tty = termios.tcgetattr(slave)
        self.slave = slave  # retained consumer FD permits explicit external restoration
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
        self.pid = os.fork()
        if self.pid == 0:
            try:
                os.close(self.fd)
                os.setsid()
                fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
                for fd in (0, 1, 2):
                    os.dup2(slave, fd)
                if slave > 2:
                    os.close(slave)
                os.chdir(work)
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
        require(time.monotonic() < self.deadline, self.label + ': deadline exceeded')
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
        require(not ERRORS.search(self.raw.decode('utf-8', errors='replace')),
                'native error diagnostic (even exit zero is failure)\n' + self.text())
        return True

    def send(self, keys):
        require(not self.exited(), 'input after native exit')
        require('*' not in keys, 'boss shortcut is forbidden')
        self.inputs.append({'raw_output_offset': len(self.raw), 'keys': keys})
        write_json(self.evidence / (self.label + '-inputs.json'), self.inputs)
        data = keys.encode('ascii')
        require(os.write(self.fd, data) == len(data), 'partial PTY input write')

    def settle(self):
        # Animation frames can have pauses: wait for a full half-second of quiet.
        while self.read(0.5):
            pass

    def wait(self, predicate, description, bosses=False):
        end = time.monotonic() + 25
        while True:
            self.read()
            if bosses and 'Boss killed!' in self.text():
                self.snapshot('natural-boss-prompt-' + str(len(self.inputs)))
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
        # Preserve attributes too: these are decoded terminal frames, including colors.
        cells = [[self.screen.buffer[y][x]._asdict() for x in range(COLS)] for y in range(ROWS)]
        write_json(self.evidence / (stem + '.frame.json'),
                   {'columns': COLS, 'rows': ROWS, 'cells': cells,
                    'cursor': {'column': self.screen.cursor.x, 'row': self.screen.cursor.y},
                    'pty_output_bytes': len(self.raw)})
        return stem

    def live(self):
        require('Press ? for help and options' in self.text(), 'native gameplay HUD missing')
        hp = re.search(r'HP (\d+)/(\d+)', self.screen.display[1][51:])
        bosses = re.search(r'Bosses left:\s*(\d+)/(\d+)', self.screen.display[1][62:])
        require(hp and bosses and int(hp[1]) > 0, 'live HP/boss HUD missing')
        board = [line[:50] for line in self.screen.display]
        players = [(x, y) for y, line in enumerate(board) for x, ch in enumerate(line) if ch == '@']
        require(len(players) == 1, 'expected one board player (HUD @ is not the player)')
        return {'board': board, 'position': players[0], 'hp': list(map(int, hp.groups())),
                'bosses': list(map(int, bosses.groups())), 'hud': self.screen.display[1][51:]}

    def is_live(self):
        try:
            self.live()
            return 'Welcome to level' not in self.text() and 'REST IN PEACE' not in self.text()
        except RuntimeError:
            return False

    def enter(self):
        self.wait(lambda: 'Welcome to Encircled!' in self.text(), 'start menu')
        self.snapshot('start-menu')
        proc = Path('/proc') / str(self.pid)
        require(os.readlink(proc / 'exe') == self.argv[0], 'not the ordinary installed ELF')
        require((proc / 'cmdline').read_bytes() == self.argv[0].encode() + b'\0',
                'unexpected native test argv')
        receipt = namespace_receipt(proc)
        receipt['exe'] = os.readlink(proc / 'exe')
        self.send('S')
        self.wait(lambda: 'Press S to play a Standard game.' in self.text(), 'Standard selection')
        self.snapshot('standard-menu')
        self.send('S')
        self.wait(lambda: re.search(r'Welcome to level\s+1!', self.text()), 'level one welcome')
        self.snapshot('level-one-welcome')
        self.send(' ')
        self.wait(self.is_live, 'ordinary live dungeon', bosses=True)
        self.snapshot('initial-live')
        require(self.live()['hp'][1] == 25, 'not native Standard level-one health')
        return receipt

    def natural_exit(self):
        self.wait(self.exited, 'natural native exit')
        self.settle()
        require(self.status == 0, 'signal/nonzero native exit is not acceptance: ' + str(self.status))
        self.snapshot('natural-exit')

    def close(self):
        forced = not self.exited()
        if forced:
            os.kill(self.pid, signal.SIGKILL)
            _, status = os.waitpid(self.pid, 0)
            self.status = os.waitstatus_to_exitcode(status)
        altered = termios.tcgetattr(self.slave)
        # Upstream exits without endwin; restore the private consumer TTY externally.
        termios.tcsetattr(self.slave, termios.TCSANOW, self.original_tty)
        restored = termios.tcgetattr(self.slave)
        require(restored == self.original_tty, 'external consumer TTY restoration failed')
        write_json(self.evidence / (self.label + '-exit.json'),
                   {'native_exit_status': self.status, 'forced_cleanup': forced,
                    'tty_changed_by_native': altered != self.original_tty,
                    'tty_restored_by_external_consumer': restored == self.original_tty})
        os.close(self.slave)
        os.close(self.fd)
        self.raw_file.close()


def gameplay(session):
    first = session.live()
    x, y = first['position']
    # Select an actually visible unoccupied floor from this run, not a fixture.
    directions = [('d', 1, 0), ('w', 0, -1), ('a', -1, 0), ('x', 0, 1),
                  ('e', 1, -1), ('c', 1, 1), ('q', -1, -1), ('z', -1, 1)]
    candidates = [(key, x + dx, y + dy) for key, dx, dy in directions
                  if 0 <= x + dx < 50 and 0 <= y + dy < 30 and first['board'][y + dy][x + dx] == '.']
    require(candidates, 'no visible adjacent unoccupied floor; no seed injection or restart workaround')
    key, tx, ty = candidates[0]
    session.snapshot('before-movement')
    session.send(key)
    session.wait(lambda: session.is_live() and session.live()['position'] == (tx, ty),
                 'visible ordinary movement', bosses=True)
    moved = session.live()
    session.snapshot('after-movement')
    require(moved['position'] != first['position'], 'movement did not change board player')
    # There is no turn counter. Prove period rest by unchanged player position and
    # an observed enemy/terrain/HP/boss change, not merely echoed input or repaint.
    rest_frames = []
    for turn in range(1, 17):
        before = session.live()
        session.send('.')
        session.settle()
        if 'Boss killed!' in session.text():
            session.snapshot('natural-boss-prompt-' + str(len(session.inputs)))
            session.send(' ')
            session.settle()
        session.wait(session.is_live, 'live period rest', bosses=True)
        after = session.live()
        rest_frames.append(session.snapshot('rest-' + str(turn)))
        require(after['position'] == moved['position'], 'period rest moved player')
        if after != before:
            break
    else:
        raise RuntimeError('period rest produced no visible turn effect; not claiming invisible progress')
    session.send('?')
    session.wait(lambda: 'Press S to suicide' in session.text() and 'Press space to return.' in session.text(),
                 'ordinary pause menu')
    session.snapshot('pause-menu')
    session.send(' ')
    session.wait(session.is_live, 'pause cancel/resume')
    resumed = session.live()
    session.snapshot('pause-cancel')
    require(resumed == after, 'pause/cancel changed map/HUD/player without a turn')
    session.send('?')
    session.wait(lambda: 'Press Q to quit.' in session.text(), 'pause before quit')
    session.snapshot('pause-before-quit')
    session.send('Q')  # gameplay Q is northwest; only the observed menu Q quits.
    session.natural_exit()
    return {'initial': first, 'movement_key': key, 'movement_target': [tx, ty], 'moved': moved,
            'rest_frames': rest_frames, 'rested': after, 'pause_cancel_exact': resumed == after,
            'natural_menu_quit_status': session.status}


def postmortem(session, work):
    report_path = work / 'report.txt'  # safely shorter than upstream's 30-byte getstr buffer
    require(not report_path.exists(), 'report must be absent before native interaction')
    before = session.live()
    session.send('?')
    session.wait(lambda: 'Press S to suicide' in session.text(), 'native suicide menu')
    session.snapshot('report-pause')
    session.send('S')
    session.wait(lambda: 'REST IN PEACE' in session.text() and 'ADVENTURE REPORT.' in session.text(),
                 'native death/report screen', bosses=True)
    session.snapshot('native-death')
    require(re.search(r'HP 0/25', session.screen.display[1][51:]), 'native suicide did not show HP zero')
    require(not report_path.exists(), 'native report appeared before requesting it')
    session.send('F')
    session.wait(lambda: 'Enter filename:' in session.text(), 'native report filename prompt')
    session.snapshot('report-filename-prompt')
    require(not report_path.exists(), 'report appeared before native filename input')
    session.send('report.txt\n')
    session.natural_exit()
    require(report_path.is_file() and not report_path.is_symlink(), 'native postmortem report missing')
    text = report_path.read_text()
    pattern = (r"You entered the dungeon on turn zero\.\n"
               r"Soon afterwards, on level 1, you died\.\n"
               r"On the way, you killed (\d+) 'a's, (\d+) 'b's, (\d+) 'c's, (\d+) 'd's, and (\d+) 'E's\.\n"
               r"In return, the 'a's did (\d+) damage to you, the 'b's did (\d+), the 'c's (\d+), "
               r"the 'd's (\d+) and the 'E's (\d+)\.\n")
    match = re.fullmatch(pattern, text)
    require(match, 'report disagrees with observed native level-one death/prose')
    shutil.copyfile(report_path, session.evidence / 'native-postmortem-report.txt')
    return {'before_suicide': before, 'relative_filename': 'report.txt', 'sha256': sha(report_path),
            'size': report_path.stat().st_size, 'statistics': list(map(int, match.groups())),
            'causal_oracle': 'absent until F/filename; observed level-one HP-zero death; ordinary native exit',
            'statistics_not_independently_instrumented': True, 'is_resume_save': False,
            'evidence_copy_never_reinjected': True, 'natural_report_exit_status': session.status}


def launch_isolated(package, evidence):
    tools = tool_receipt()
    unshare = tools['executables_and_pyte']['unshare']
    env = {key: os.environ[key] for key in ('PATH', 'HOME', 'TMPDIR', 'GUIX_PYTHONPATH', 'PYTHONPATH',
                                           'TERMINFO', 'TERMINFO_DIRS') if os.environ.get(key)}
    env['PYTHONNOUSERSITE'] = '1'
    env.update({'LC_ALL': 'C', 'ENC_HOST_UID': str(os.getuid()), 'ENC_HOST_GID': str(os.getgid())})
    for name in ('user', 'mnt', 'net', 'pid'):
        env['ENC_HOST_' + name.upper()] = os.readlink('/proc/self/ns/' + name)
    command = [unshare, '--user', '--map-current-user', '--keep-caps', '--mount', '--propagation', 'private',
               '--net', '--pid', '--mount-proc', '--kill-child', '--fork',
               tools['executables_and_pyte']['python'], '-s', '-B',
               str(Path(__file__).resolve()), str(package), str(evidence), '--inside']
    receipt = {'command': command, 'tools': tools,
               'host_identity_and_namespaces': {k: v for k, v in env.items() if k.startswith('ENC_HOST_')}}
    write_json(evidence / 'namespace-launch.json', receipt)
    with (evidence / 'namespace.stdout').open('xb') as stdout, (evidence / 'namespace.stderr').open('xb') as stderr:
        process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        try:
            status = process.wait(timeout=270)
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
    parser.add_argument('package', type=Path)
    parser.add_argument('evidence', type=Path)
    parser.add_argument('--inside', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    package, evidence = args.package.resolve(strict=True), args.evidence.resolve(strict=True)
    require(str(package) == str(args.package) and str(evidence) == str(args.evidence),
            'canonical absolute paths required')
    require(evidence.is_dir() and not (evidence / 'native-proof.json').exists(), 'fresh shell evidence required')
    require(not evidence.is_relative_to('/gnu/store'), 'EVIDENCE must be outside the store')
    require(evidence.stat().st_uid == os.getuid() and evidence.stat().st_mode & 0o077 == 0,
            'EVIDENCE must be caller-owned and private')
    if not args.inside:
        try:
            launch_isolated(package, evidence)
        except BaseException as error:
            if not (evidence / 'native-proof.json').exists():
                write_json(evidence / 'native-proof.json', {'success': False, 'error': repr(error)})
            raise
        print('ENCIRCLED NATIVE SMOKE OK')
        return
    report = {'success': False, 'source_url': SOURCE_URL, 'source_sha256': SOURCE_SHA256,
              'geometry': {'columns': COLS, 'rows': ROWS}, 'sessions': [],
              'state_contract': 'explicit postmortem report in cwd only; no resume/load or automatic HOME/XDG state'}
    write_json(evidence / 'native-proof.json', report)
    session = None
    try:
        report['output_contract'] = output_contract(package, evidence)
        report['tools'] = tool_receipt()
        report['isolation'] = namespace_receipt(Path('/proc/self'))
        require(os.getpid() == 1, 'proof is not PID-one in its private namespace')
        report['isolation']['store'] = readonly_store(evidence)
        root = evidence / 'private'
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work-1', 'work-2'):
            (root / name).mkdir(mode=0o700)
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color', 'LC_ALL': 'C',
               'PATH': '', 'TMPDIR': str(root / 'tmp')}
        for variable in ('TERMINFO', 'TERMINFO_DIRS'):
            if os.environ.get(variable):
                env[variable] = os.environ[variable]
        for variable, subdir in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                 ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                 ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / subdir)
        for number in (1, 2):
            work = root / ('work-' + str(number))
            session = Session(package, env, work, evidence, number)
            process = session.enter()
            result = gameplay(session) if number == 1 else postmortem(session, work)
            session.close()
            report['sessions'].append({'process': process, 'argv': session.argv, 'result': result})
            write_json(evidence / 'native-proof.json', report)
            session = None
        for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work-1'):
            require(not any((root / name).iterdir()), 'unexpected automatic state in ' + name)
        require(sorted(p.name for p in (root / 'work-2').iterdir()) == ['report.txt'],
                'unexpected native cwd files')
        for path in root.rglob('*'):
            require(not path.is_symlink(), 'private state symlink escape')
            st = path.stat()
            require(st.st_uid == os.getuid() and st.st_gid == os.getgid(), 'private state ownership changed')
            require(st.st_mode & 0o077 == 0, 'private state permissions too broad')
        report['private_environment'] = env
        report['private_footprint'] = {str(p.relative_to(root)): {'size': p.stat().st_size, 'sha256': sha(p)}
                                       for p in root.rglob('*') if p.is_file()}
        report['success'] = True
        write_json(evidence / 'native-proof.json', report)
    except BaseException as error:
        report['error'] = repr(error)
        if session is not None:
            session.snapshot('failure')
            session.close()
            report['failed_session_exit_status'] = session.status
        write_json(evidence / 'native-proof.json', report)
        raise


if __name__ == '__main__':
    main()
