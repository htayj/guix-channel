#!/usr/bin/env python3
"""External installed-game PTY consumer, called by bell-labs-rogue7-smoke.sh.

Only normal character creation and gameplay keys reach the ordinary launcher.
The original native save is consumed by a separate -r process; evidence copies
are never restored.  No seed, wizard options, injected code or generated state.
Source: early-roguelike-rel2021.03-src/arogue7, release 7.7.1.
"""
import argparse
import codecs
from collections import deque
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

ROWS, COLS = 24, 80
GAME = 'bell-labs-rogue7'
SOURCE_URL = 'https://rlgallery.org/files/early-roguelike-rel2021.03-src.tgz'
LICENSE_SHA256 = 'de8c8864e21c63dde8be961367c9ed9a47b8078e2f7f01142ee9c543fc8ce637'
SOURCE_ANCHORS = {
    'character': 'arogue7/init.c:init_player (class 1, Escape allocates maxima, y accepts)',
    'movement': 'arogue7/command.c:command (h/j/k/l), rogue.h:FLOOR=., VPLAYER=@, STAIRS=%',
    'entrance': 'arogue7/trader.c:do_post; command.c:d_level (start post %, > enters level 1)',
    'redraw': 'arogue7/command.c:command (space is no-op; Ctrl-L touches cw without a turn)',
    'hud': 'arogue7/io.c:status (last two lines, attributes and Lvl/Hp/Ac/Carry/Exp/rank)',
    'save': 'arogue7/save.c:save_game; command.c:S (default filename y, exit 0)',
    'restore': 'arogue7/save.c:restore (-r, unlinks native save, playit)',
    'quit': 'arogue7/command.c:quit (Q, exact yes line); rip.c:score (pack continue, score exit)',
}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(65536), b''):
            digest.update(chunk)
    return digest.hexdigest()


def fingerprint(path):
    if path.is_symlink():
        return {'symlink': os.readlink(path)}
    if not path.exists():
        return None
    if path.is_file():
        return {'size': path.stat().st_size, 'sha256': sha(path)}
    return {p.name: fingerprint(p) for p in sorted(path.iterdir())}


def output_contract(package, evidence):
    require(package.parent == Path('/gnu/store'), 'OUTPUT must be a direct store output')
    native = package / 'libexec' / GAME
    require(native.read_bytes()[:4] == b'\x7fELF', 'installed native executable is not ELF')
    for path in [package, *package.rglob('*')]:
        target = path.resolve(strict=True) if path.is_symlink() else path
        require(target.is_relative_to(package), 'output symlink escapes package: ' + str(path))
        require(target.stat().st_mode & 0o222 == 0, 'output has write bits: ' + str(path))
    doc = package / 'share/doc' / GAME
    notices = {}
    for name in ('LICENSE.TXT', 'aguide.mm', 'arogue77.html'):
        path = doc / name
        require(path.is_file() and path.stat().st_size > 0, 'missing upstream document: ' + name)
        notices[name] = {'size': path.stat().st_size, 'sha256': sha(path)}
    require(notices['LICENSE.TXT']['sha256'] == LICENSE_SHA256,
            'complete upstream license/notices differ from reviewed bytes')
    text = (doc / 'LICENSE.TXT').read_text()
    for marker in ('Products derived from this software may not be called',
                   'Copyright (C) 1984, 1985, 1986 Michael Morgan, Ken Dalka and AT&T',
                   'Copyright (C) 1984 Robert D. Kindelberger',
                   'Copyright (C) 1980, 1981 Michael Toy, Ken Arnold and Glenn Wichman',
                   'Copyright (C) 2005 Nicholas J. Kisseberth',
                   'Copyright (C) 1994 David Burren',
                   'THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) AND CONTRIBUTORS'):
        require(marker in text, 'upstream notice missing: ' + marker)
    for name in ('aguide.mm', 'arogue77.html'):
        require('See the file LICENSE.TXT' in (doc / name).read_text(),
                'document license reference missing: ' + name)
    require(not any('smoke' in p.name or 'native.py' in p.name for p in package.rglob('*')),
            'external test helper was installed into game output')
    closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
    require(str(package) in closure, 'runtime closure lacks output')
    require(not any(Path(p).name[33:].startswith(('python-', 'python-pyte-')) for p in closure),
            'external tools leaked into game closure')
    return {'native_sha256': sha(native), 'notices': notices, 'runtime_closure': closure,
            'source_url': SOURCE_URL, 'source_anchors': SOURCE_ANCHORS}


def namespace_receipt(proc):
    namespaces = {name: os.readlink(proc / 'ns' / name) for name in ('user', 'mnt', 'net', 'pid')}
    for name, actual in namespaces.items():
        require(actual != os.environ['ROGUE_HOST_' + name.upper()], 'host namespace leaked: ' + name)
        require(actual == os.readlink('/proc/self/ns/' + name), 'game escaped private ' + name)
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, text = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(x) for x in text.split()]
    maps = {}
    for kind, key in (('uid', 'Uid'), ('gid', 'Gid')):
        expected = int(os.environ['ROGUE_HOST_' + kind.upper()])
        require(expected != 0 and identity[key] == [expected] * 4, 'not ordinary caller ' + key)
        maps[kind] = (proc / (kind + '_map')).read_text()
        require([int(x) for x in maps[kind].split()] == [expected, expected, 1],
                'not exact same-UID/GID namespace mapping')
    interfaces = sorted(line.split(':')[0].strip() for line in
                        (proc / 'net/dev').read_text().splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'offline namespace exposes non-loopback interfaces')
    flags = (proc / 'net/route').read_text().splitlines()[1:]
    require(not flags, 'private network namespace has a route')
    return {'namespaces': namespaces, 'identity': identity, 'maps': maps, 'interfaces': interfaces}


def mount(source, target, flags):
    # mount(8) rejects real nonzero UID; namespace capabilities permit syscall.
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
    # ECMA-48 REP is emitted by xterm terminfo but absent in stock pyte 0.8.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, package, env, root, evidence, number, restored=False):
        self.package, self.evidence = package, evidence
        self.label = 'session-' + str(number)
        self.argv = [str(package / 'bin' / GAME)] + (['-r'] if restored else [])
        self.raw_file = (evidence / (self.label + '.pty')).open('xb')
        self.raw = bytearray()
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.inputs = []
        self.status, self.eof = None, False
        self.deadline = time.monotonic() + 150
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

    def wait(self, predicate, description):
        end = time.monotonic() + 20
        while True:
            self.read()
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
        proc = Path('/proc') / str(self.pid)
        self.wait(lambda: os.readlink(proc / 'exe') == str(self.package / 'libexec' / GAME),
                  'ordinary launcher exec of installed ELF')
        receipt = namespace_receipt(proc)
        argv = (proc / 'cmdline').read_bytes().split(b'\0')[:-1]
        expected = [str(self.package / 'libexec' / GAME).encode(),
                    *[a.encode() for a in self.argv[1:]]]
        require(argv == expected, 'unexpected native argv/test mode')
        tty = os.readlink(proc / 'fd/0')
        require(tty.startswith('/dev/pts/'), 'native input is not an external PTY')
        environment = dict(item.split(b'=', 1) for item in
                           (proc / 'environ').read_bytes().split(b'\0') if b'=' in item)
        for key in (b'SEED', b'SUPER', b'ROGUEOPTS', b'LD_PRELOAD', b'LD_LIBRARY_PATH'):
            require(key not in environment, 'forbidden game-state/code override: ' + key.decode())
        require(environment[b'ROGUEHOME'] == (str(self.evidence / 'private/data' / GAME) + '/').encode(),
                'ordinary wrapper did not supply private state home')
        receipt.update({'pid': self.pid, 'tty': tty, 'executable': os.readlink(proc / 'exe'),
                        'argv': [a.decode() for a in argv], 'launcher_argv': self.argv})
        write_json(self.evidence / (self.label + '-process.json'), receipt)
        return receipt

    def enter(self, restored=False):
        if not restored:
            self.wait(lambda: 'What character class do you desire?' in self.text(), 'class selection')
            self.snapshot('class-selection')
            self.send('1')
            self.wait(lambda: 'Minimum:' in self.text() and 'Maximum:' in self.text(), 'attribute allocation')
            self.snapshot('attributes')
            self.send('\x1b')
            self.wait(lambda: 'Is this character okay?' in self.text(), 'character confirmation')
            self.snapshot('character-confirmation')
            self.send('y')
        self.wait(lambda: 'Lvl:' in self.screen.display[23] and 'Int:' in self.screen.display[22],
                  'normal playable map and status')
        if restored:
            require(b'arogue77.sav:' in self.raw and b'What character class' not in self.raw,
                    'not independent native restore')
        else:
            require(b'just a moment while I dig the dungeon' in self.raw,
                    'ordinary new-game greeting absent')

    def live(self, label):
        offset = len(self.raw)
        # Space clears transient startup/restore messages without consuming a
        # turn. Ctrl-L is source-defined redraw, not Ctrl-R (repeat message).
        self.send(' \x0c')
        self.settle()
        frame = bytes(self.raw[offset:])
        require(frame, 'redraw produced no native bytes')
        (self.evidence / (self.label + '-' + label + '-redraw.raw')).write_bytes(frame)
        hud = list(self.screen.display[22:24])
        for key in ('Int', 'Str', 'Wis', 'Dxt', 'Con', 'Cha'):
            require(re.search(key + r':\d+\(\d+\)', hud[0]), 'invalid source HUD attribute: ' + key)
        stats = re.search(r'Lvl:(-?\d+)  Hp:\s*(\d+)\(\s*(\d+)\)  Ac:(-?\d+)  '
                          r'Carry:(\d+)\((\d+)\)  Exp:(\d+)/(\d+)  (\S.*)', hud[1])
        require(stats is not None, 'source-exact status decode failed\n' + self.text())
        require(int(stats.group(2)) > 0, 'character is not alive')
        dungeon = list(self.screen.display[1:22])
        x, row = self.screen.cursor.x, self.screen.cursor.y
        require(0 <= x < COLS and 1 <= row < 22 and dungeon[row - 1][x] == '@',
                'native cursor does not identify displayed player\n' + self.text())
        require('.' in ''.join(dungeon), 'no source-defined visible floor')
        state = {'map': dungeon, 'hud': hud, 'player': [x, row],
                 'coordinate_kind': 'zero-based native screen columns/rows; map rows 1..21',
                 'depth': int(stats.group(1)), 'hp': [int(stats.group(2)), int(stats.group(3))],
                 'ac': int(stats.group(4)), 'carry': [int(stats.group(5)), int(stats.group(6))],
                 'experience': [int(stats.group(7)), int(stats.group(8))], 'rank': stats.group(9).rstrip()}
        stem = self.snapshot(label)
        write_json(self.evidence / (stem + '.json'), state)
        return state

    def advance(self, before, label):
        x, row = before['player']
        for dx, dy, key in ((-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j')):
            nx, nr = x + dx, row + dy
            if 0 <= nx < COLS and 1 <= nr < 22 and before['map'][nr - 1][nx] == '.':
                self.send(key)
                self.settle()
                after = self.live(label)
                require(after['player'] == [nx, nr] and after['player'] != before['player'],
                        'normal floor movement did not reach observed target')
                return after
        raise RuntimeError('no adjacent displayed floor; no RNG retry or injected level permitted')

    def enter_dungeon(self, before):
        # STARTLEV is a real equipment post, not the dungeon. Its randomized
        # items are traversable; command.c disables auto-pickup in POSTLEV.
        # Find a shortest path to source-defined STAIRS (%) from native pixels.
        require(before['depth'] == 0, 'ordinary birth did not start in equipment post')
        queue = deque([(tuple(before['player']), [])])
        seen = {tuple(before['player'])}
        route = None
        while queue:
            (x, row), path = queue.popleft()
            if before['map'][row - 1][x] == '%':
                route = path
                break
            for dx, dy, key in ((-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j')):
                nx, nr = x + dx, row + dy
                if not (0 <= nx < COLS and 1 <= nr < 22) or (nx, nr) in seen:
                    continue
                if before['map'][nr - 1][nx] not in '.%!:?)]=/$;,*<>':
                    continue
                seen.add((nx, nr))
                queue.append(((nx, nr), path + [(key, nx, nr)]))
        require(route is not None and len(route) <= 80, 'no bounded visible route to equipment-post stairs')
        current = before
        for step, (key, nx, nr) in enumerate(route):
            self.send(key)
            self.settle()
            current = self.live('post-step-' + str(step + 1))
            require(current['player'] == [nx, nr] and current['depth'] == 0,
                    'native post movement differs from observed route')
        self.send('>')
        self.wait(lambda: 'Lvl:1 ' in self.screen.display[23], 'normal descent into dungeon')
        entered = self.live('dungeon-entry')
        require(entered['depth'] == 1, 'stairs did not enter dungeon level 1')
        return entered

    def finish(self, label):
        end = time.monotonic() + 20
        while not self.exited() or not self.eof:
            self.read()
            require(time.monotonic() < end, label + ': native process failed to exit')
        require(self.status == 0, label + ': native exit status ' + str(self.status))
        self.snapshot(label)

    def save(self):
        self.send('S')
        self.wait(lambda: 'Save file (' in self.text() and 'arogue77.sav' in self.text(), 'native save prompt')
        self.snapshot('save-prompt')
        self.send('y')
        self.finish('saved-exit')

    def quit(self):
        self.send('Q')
        self.wait(lambda: 'Really quit? <yes or no>' in self.text(), 'normal quit confirmation')
        self.snapshot('quit-confirmation')
        self.send('yes\n')
        # rip.c:score first shows the native pack and calls getstr(prbuf)
        # at retstr before printing scores; this is distinct from final fgets.
        self.wait(lambda: 'Contents of your pack when you quit:' in self.text() and
                  '[Press return to continue]' in self.text(), 'native quit pack acknowledgement')
        self.snapshot('quit-pack')
        self.send('\n')
        self.wait(lambda: '[Press return to exit]' in self.text(), 'native score exit prompt')
        self.snapshot('quit-score')
        require(b'Top 10 Adventurers:' in self.raw, 'native score heading missing after quit')
        self.send('\n')
        self.finish('clean-quit')

    def close(self):
        # Failure-only teardown never counts as normal save/quit acceptance.
        if not self.exited():
            os.kill(self.pid, signal.SIGKILL)
            _, status = os.waitpid(self.pid, 0)
            self.status = os.waitstatus_to_exitcode(status)
        os.close(self.fd)
        self.raw_file.close()


def launch_isolated(package, evidence):
    require(os.getuid() != 0 and os.getgid() != 0, 'consumer requires ordinary nonroot caller')
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized unshare unavailable')
    variables = ('PATH', 'HOME', 'TMPDIR', 'GUIX_PYTHONPATH', 'PYTHONPATH',
                 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME')
    env = {key: os.environ[key] for key in variables if os.environ.get(key)}
    env.update({'LC_ALL': 'C', 'ROGUE_HOST_UID': str(os.getuid()), 'ROGUE_HOST_GID': str(os.getgid())})
    for name in ('user', 'mnt', 'net', 'pid'):
        env['ROGUE_HOST_' + name.upper()] = os.readlink('/proc/self/ns/' + name)
    command = [unshare, '--user', '--map-current-user', '--keep-caps', '--mount',
               '--propagation', 'private', '--net', '--pid', '--mount-proc', '--kill-child',
               '--fork', sys.executable, '-B', str(Path(__file__).resolve()),
               str(package), str(evidence), '--inside']
    receipt = {'command': command, 'host_identity_and_namespaces':
               {key: value for key, value in env.items() if key.startswith('ROGUE_HOST_')}}
    write_json(evidence / 'namespace-launch.json', receipt)
    with (evidence / 'namespace.stdout').open('xb') as stdout, (evidence / 'namespace.stderr').open('xb') as stderr:
        process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        try:
            status = process.wait(timeout=300)
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise
    receipt['exit_status'] = status
    write_json(evidence / 'namespace-launch.json', receipt)
    if status != 0:
        sys.stderr.write((evidence / 'namespace.stderr').read_text(errors='replace'))
        require(False, 'isolated consumer failed (namespace denial is not acceptance): ' + str(status))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path)
    parser.add_argument('evidence', type=Path)
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
        print('BELL_LABS_ROGUE7_NATIVE_OK')
        return
    report = {'success': False, 'sessions': [], 'source_url': SOURCE_URL}
    write_json(evidence / 'continuity.json', report)
    session = None
    try:
        report['output_contract'] = output_contract(package, evidence)
        report['isolation'] = namespace_receipt(Path('/proc/self'))
        report['isolation']['store'] = readonly_store(evidence)
        watched = {Path.home() / '.local/share' / GAME, Path.home() / 'arogue77.sav',
                   Path.home() / 'arogue77.scr', Path.cwd() / 'arogue77.sav', Path.cwd() / 'arogue77.scr'}
        for variable in ('XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME'):
            if os.environ.get(variable):
                watched.add(Path(os.environ[variable]) / GAME)
        initial = {str(path): fingerprint(path) for path in watched}
        root = evidence / 'private'
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color', 'LC_ALL': 'C',
               'PATH': '', 'TMPDIR': str(root / 'tmp')}
        for variable, subdir in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                 ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                 ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / subdir)
        state_dir = root / 'data' / GAME
        save_path = state_dir / 'arogue77.sav'
        session = Session(package, env, root, evidence, 1)
        session.enter()
        process = session.process_receipt()
        post = session.live('first-live')
        start = session.enter_dungeon(post)
        advanced = session.advance(start, 'movement')
        require(session.live('pre-save') == advanced, 'no-turn redraw changed pre-save state')
        session.save()
        require(save_path.is_file() and save_path.stat().st_size > 0, 'normal save did not create native state')
        native_save = {'path': str(save_path), 'size': save_path.stat().st_size, 'sha256': sha(save_path)}
        copy = evidence / 'session-1-native-save.bin'
        shutil.copyfile(save_path, copy)
        native_save.update({'evidence_copy': str(copy), 'evidence_copy_never_reinjected': True})
        report['sessions'].append({'process': process, 'initial': start, 'advanced': advanced,
                                   'native_save': native_save, 'normal_save_exit_status': session.status})
        write_json(evidence / 'continuity.json', report)
        session.close()
        session = Session(package, env, root, evidence, 2, restored=True)
        session.enter(restored=True)
        process = session.process_receipt()
        restored = session.live('restored')
        require(restored == advanced, 'restored exact decoded map/HUD/player differ from pre-save state')
        require(not save_path.exists(), 'ordinary restore failed to consume original native save')
        report['continuity'] = {'full_map_and_hud_exact': True, 'player_exact': True,
                                'native_save_consumed': True, 'independent_process': True}
        continued = session.advance(restored, 'continued-movement')
        require(session.live('pre-quit') == continued, 'no-turn redraw changed continued state')
        session.quit()
        require(not save_path.exists(), 'clean quit unexpectedly created a save')
        report['sessions'].append({'process': process, 'initial': restored, 'advanced': continued,
                                   'normal_quit_exit_status': session.status})
        session.close()
        session = None
        require((state_dir / 'arogue77.scr').is_file() and (state_dir / 'arogue77.scr').stat().st_size > 0,
                'clean quit did not persist native score')
        for name in ('home', 'config', 'cache', 'state', 'runtime', 'tmp', 'work'):
            require(not any((root / name).iterdir()), 'state escaped native XDG data: ' + name)
        require(list((root / 'data').iterdir()) == [state_dir], 'unexpected data subtree')
        for path in root.rglob('*'):
            require(not path.is_symlink(), 'private runtime symlink escapes root')
            require(path.stat().st_uid == os.getuid(), 'native state changed ownership')
            require(path.stat().st_mode & 0o077 == 0, 'native private state is accessible to other users')
        require(all(fingerprint(Path(path)) == value for path, value in initial.items()),
                'host game state or working directory changed')
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
