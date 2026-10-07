#!/usr/bin/env python3
"""External normal-launch PTY acceptance for Martin's Dungeon Bash 1.7.

Only ordinary name entry, movement, inventory, S/RETURN save, restart and
X/Y/RETURN quit reach the game. No installed smoke branch, RNG override,
wizard key, generated save or reinjected evidence copy is used. The native
21x21 scrolling viewport and entire 2x80 HUD must survive an independent
normal-launch restore exactly. Python/pyte/unshare are external test tools.
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

ROWS, COLS = 24, 80
GAME = 'martins-dungeon-bash'
SOURCE_URL = ('https://www.chiark.greenend.org.uk/~mpread/dungeonbash/'
              'archive-1.7/dungeonbash-1.7.tar.gz')
SOURCE_SHA256 = '790bde04ff869ba2817ad1f07d062d75f7f15af4a2c99669dd60a4b98fdf1380'
NOTES_SHA256 = 'b20fe51930fbc81e44900ec5806e9286ba58edad9c975891b18f9c344e6e4d93'
SOURCE_ANCHORS = {
    'birth': 'u.c:u_init/read_input (ordinary name prompt, max16); main.c:new_game',
    'mode': 'dunbash.h:WIZARD_MODE=0; main.c:main (no arguments, automatic saved-game detection)',
    'geometry': 'display.c:display_init/draw_world (21x21 at 0,0; player always 10,10; HUD 22..23)',
    'hud': 'display.c:draw_status_line (name HP XL Body Gold / Defence Food Depth Agility XP)',
    'movement': 'display.c:get_command h/j/k/l; u.c:move_player/reloc_player (viewport scrolls)',
    'turn': 'main.c:main_loop; u.c:update_player (food decreases per simulation tick)',
    'inventory': 'display.c:get_command i; main.c:do_command SHOW_INVENTORY (no turn)',
    'save': 'display.c:get_command S; main.c:save_game (dunbash.sav + gzip, no turn)',
    'restore': 'main.c:main/load_game (auto-load gzip, reconstruct map, consume original save)',
    'exit': 'display.c:display_shutdown/press_enter (RETURN/SPACE); getYN (capital Y); main.c:QUIT X',
    'rights': 'notes.txt complete 19827-byte BSD-2 notice; all 19 C/header members repeat BSD-2 terms; no runtime assets',
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
        return {'symlink': os.readlink(path)}
    if not path.exists():
        return None
    if path.is_file():
        return {'size': path.stat().st_size, 'sha256': sha(path)}
    return {p.name: fingerprint(p) for p in sorted(path.iterdir())}


def output_contract(package, evidence):
    require(package.parent == Path('/gnu/store'), 'OUTPUT must be a direct store output')
    native = package / 'libexec/dungeonbash'
    require(native.read_bytes()[:4] == b'\x7fELF', 'installed native executable is not ELF')
    for path in [package, *package.rglob('*')]:
        target = path.resolve(strict=True) if path.is_symlink() else path
        require(target.is_relative_to(package), 'output symlink escapes package: ' + str(path))
        require(target.stat().st_mode & 0o222 == 0, 'output has write bits: ' + str(path))
    notes = package / 'share/doc' / GAME / 'notes.txt'
    require(notes.is_file() and notes.stat().st_size == 19827 and sha(notes) == NOTES_SHA256,
            'complete canonical upstream notes/license bytes differ')
    for marker in ('Copyright 2009 Martin Read.', 'copyright 2005-2009 Martin Read.',
                   '1. Redistributions of source code must retain the above copyright',
                   '2. Redistributions in binary form must reproduce the above copyright',
                   'THIS SOFTWARE IS PROVIDED BY THE AUTHOR',
                   'THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'):
        require(marker in notes.read_text(), 'upstream license clause missing: ' + marker)
    launcher = (package / 'bin/dungeonbash').read_text()
    require('--smoke' not in launcher and 'Goocastle' not in launcher,
            'installed synthetic gameplay branch is forbidden')
    require(not any('smoke' in p.name or 'native.py' in p.name or
                    p.suffix.lower() == '.html' or p.name == 'spoilers'
                    for p in package.rglob('*')), 'test helper or unlicensed spoiler document installed')
    closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
    require(str(package) in closure, 'runtime closure lacks output')
    require(not any(Path(p).name[33:].startswith(('python-', 'python-pyte-', 'util-linux-'))
                    for p in closure), 'external PTY/test tools leaked into game closure')
    return {'native_sha256': sha(native), 'notes_sha256': sha(notes),
            'runtime_closure': closure, 'source_url': SOURCE_URL,
            'source_sha256': SOURCE_SHA256, 'source_anchors': SOURCE_ANCHORS}


def namespace_receipt(proc):
    namespaces = {name: os.readlink(proc / 'ns' / name) for name in ('user', 'mnt', 'net', 'pid')}
    for name, actual in namespaces.items():
        require(actual != os.environ['DB_HOST_' + name.upper()], 'host namespace leaked: ' + name)
        require(actual == os.readlink('/proc/self/ns/' + name), 'game escaped private ' + name)
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, text = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(x) for x in text.split()]
    maps = {}
    for kind, key in (('uid', 'Uid'), ('gid', 'Gid')):
        expected = int(os.environ['DB_HOST_' + kind.upper()])
        require(expected != 0 and identity[key] == [expected] * 4, 'not ordinary caller ' + key)
        maps[kind] = (proc / (kind + '_map')).read_text()
        require([int(x) for x in maps[kind].split()] == [expected, expected, 1],
                'not exact same-UID/GID namespace mapping')
    interfaces = sorted(line.split(':')[0].strip() for line in
                        (proc / 'net/dev').read_text().splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'offline namespace exposes non-loopback interfaces')
    require(not (proc / 'net/route').read_text().splitlines()[1:], 'private network has a route')
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
    # xterm terminfo ECMA-48 REP is absent in stock pyte 0.8.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, package, env, root, evidence, number):
        self.package, self.evidence = package, evidence
        self.label = 'session-' + str(number)
        self.argv = [str(package / 'bin/dungeonbash')]
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
        self.wait(lambda: os.readlink(proc / 'exe') == str(self.package / 'libexec/dungeonbash'),
                  'ordinary launcher exec of installed ELF')
        receipt = namespace_receipt(proc)
        argv = (proc / 'cmdline').read_bytes().split(b'\0')[:-1]
        require(argv == [str(self.package / 'libexec/dungeonbash').encode()],
                'unexpected native argv/test mode')
        tty = os.readlink(proc / 'fd/0')
        require(tty.startswith('/dev/pts/'), 'native input is not an external PTY')
        expected_cwd = self.evidence / 'private/state' / GAME
        require(os.readlink(proc / 'cwd') == str(expected_cwd), 'normal launcher did not enter private XDG state')
        environment = dict(item.split(b'=', 1) for item in
                           (proc / 'environ').read_bytes().split(b'\0') if b'=' in item)
        for key in (b'SEED', b'LD_PRELOAD', b'LD_LIBRARY_PATH', b'GOOCASTLE_RUNTIME_RAW_CAPTURE'):
            require(key not in environment, 'forbidden gameplay/code override: ' + key.decode())
        require(environment[b'PATH'] == b'', 'game can consult host PATH')
        receipt.update({'pid': self.pid, 'tty': tty, 'executable': os.readlink(proc / 'exe'),
                        'argv': [a.decode() for a in argv], 'launcher_argv': self.argv,
                        'cwd': os.readlink(proc / 'cwd')})
        write_json(self.evidence / (self.label + '-process.json'), receipt)
        return receipt

    def enter(self, name, restored=False):
        if not restored:
            self.wait(lambda: 'What is your name, stranger?' in self.text(), 'ordinary birth name entry')
            self.snapshot('name-prompt')
            self.send(name + '\n')
        self.wait(lambda: self.screen.display[10][10] == '@' and
                  'HP:' in self.screen.display[22] and 'Food:' in self.screen.display[23],
                  'normal playable viewport and HUD')
        require(b"Welcome to Martin's Infinite Dungeon." in self.raw, 'normal welcome missing')
        if restored:
            require(b'Game loaded.' in self.raw and b'Loading...' in self.raw and
                    b'What is your name, stranger?' not in self.raw,
                    'not independent automatic native restore')
        else:
            require(b'Initialisation complete.' in self.raw and b'Game loaded.' not in self.raw,
                    'ordinary new game missing')

    def live(self, label):
        self.settle()
        hud = list(self.screen.display[22:24])
        top = re.fullmatch(r'(.{16}) HP: (\d{3})/(\d{3})\s+XL: (\d+)\s+Body: (\d{2})/(\d{2})\s+Gold: (\d+)\s*', hud[0])
        bottom = re.fullmatch(r'Defence: (\d{2})\s+Food: (-?\d+)\s+Depth: (\d+)\s+Agility: (\d{2})/(\d{2})\s+XP: (\d+)\s*', hud[1])
        require(top is not None and bottom is not None, 'source-exact HUD decode failed\n' + self.text())
        require(int(top.group(2)) > 0 and b'THOU ART SLAIN!' not in self.raw, 'character is not alive')
        dungeon = [row[:21] for row in self.screen.display[:21]]
        require(dungeon[10][10] == '@' and '.' in ''.join(dungeon), 'source-exact viewport/player absent')
        state = {'map': dungeon, 'hud': hud, 'player_viewport': [10, 10],
                 'coordinate_kind': 'zero-based 21x21 player-centred scrolling viewport, NOT world position',
                 'name': top.group(1).rstrip(), 'hp': [int(top.group(2)), int(top.group(3))],
                 'level': int(top.group(4)), 'body': [int(top.group(5)), int(top.group(6))],
                 'gold': int(top.group(7)), 'defence': int(bottom.group(1)),
                 'food': int(bottom.group(2)), 'depth': int(bottom.group(3)),
                 'agility': [int(bottom.group(4)), int(bottom.group(5))], 'xp': int(bottom.group(6))}
        # Preserve the raw decoded cells separately. display.c:newsym emits
        # literal spaces for unexplored tiles; draw_world does likewise outside
        # the dungeon. ncurses may paint those plain blanks white-on-black or
        # erase them with terminal defaults. Neither encodes game state. Only
        # these two blank colors are normalized; every glyph, nonblank style,
        # other blank attribute and complete HUD style remains exact.
        cells = [[self.screen.buffer[y][x]._asdict() for x in range(21)] for y in range(21)]
        write_json(self.evidence / (self.label + '-' + label + '-raw-map-cells.json'), cells)
        for row in cells:
            for cell in row:
                if cell['data'] == ' ':
                    require(cell['fg'] in ('white', 'default') and cell['bg'] in ('black', 'default') and
                            not any(cell[attr] for attr in ('blink', 'bold', 'italics', 'reverse',
                                                           'strikethrough', 'underscore')),
                            'unexpected styled blank in source map viewport')
                    cell['fg'], cell['bg'] = 'default', 'default'
        state['map_cells'] = cells
        state['hud_cells'] = [[self.screen.buffer[y][x]._asdict() for x in range(80)] for y in (22, 23)]
        write_json(self.evidence / (self.snapshot(label) + '.json'), state)
        return state

    def advance(self, before, label):
        candidates = []
        for dx, dy, key in ((-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j')):
            if before['map'][10 + dy][10 + dx] != '.':
                continue
            # Walls cannot move or be covered by monsters. Require displaced
            # wall-edge witnesses so a wait/failed bump cannot pass as movement.
            witnesses = [(x, y, x - dx, y - dy) for y in range(21) for x in range(21)
                         if 0 <= x - dx < 21 and 0 <= y - dy < 21 and
                         before['map'][y][x] == '#' and before['map'][y - dy][x - dx] != '#']
            candidates.append((len(witnesses), dx, dy, key, witnesses))
        require(candidates, 'no adjacent observed floor; no RNG retry or generated level permitted')
        count, dx, dy, key, witnesses = max(candidates, key=lambda value: value[0])
        require(count >= 2, 'insufficient visible wall edges to prove scrolling movement')
        self.send(key)
        self.wait(lambda: self.screen.display[23] != before['hud'][1], 'native movement turn updates HUD')
        after = self.live(label)
        require(after['food'] < before['food'] and after['depth'] == before['depth'],
                'normal floor movement did not advance simulation at same depth')
        require(all(after['map'][ny][nx] == '#' for _, _, nx, ny in witnesses),
                'viewport did not scroll by the source-defined movement delta')
        require(after['map'] != before['map'], 'movement did not change viewport')
        write_json(self.evidence / (self.label + '-' + label + '-movement.json'),
                   {'key': key, 'world_delta': [dx, dy], 'wall_scroll_witnesses': witnesses,
                    'food_before': before['food'], 'food_after': after['food']})
        return after

    def inventory(self, label):
        offset = len(self.raw)
        self.send('i')
        self.wait(lambda: b'You are carrying:' in self.raw[offset:], 'normal no-turn inventory command')
        self.snapshot(label)

    def finish(self, label):
        self.wait(lambda: 'Press RETURN or SPACE to continue' in self.text(), 'normal shutdown acknowledgement')
        self.snapshot(label + '-acknowledgement')
        self.send('\n')
        end = time.monotonic() + 20
        while not self.exited() or not self.eof:
            self.read()
            require(time.monotonic() < end, label + ': native process failed to exit')
        require(self.status == 0, label + ': native exit status ' + str(self.status))
        self.snapshot(label)

    def save(self):
        self.send('S')
        self.finish('saved-exit')

    def quit(self):
        self.send('X')
        self.wait(lambda: 'Really quit?' in self.text() and 'Press capital Y to confirm' in self.text(),
                  'normal quit confirmation')
        self.snapshot('quit-confirmation')
        self.send('Y')
        self.finish('clean-quit')

    def close(self):
        # Failure-only teardown is never normal save/quit acceptance.
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
    env.update({'LC_ALL': 'C', 'DB_HOST_UID': str(os.getuid()), 'DB_HOST_GID': str(os.getgid())})
    for name in ('user', 'mnt', 'net', 'pid'):
        env['DB_HOST_' + name.upper()] = os.readlink('/proc/self/ns/' + name)
    command = [unshare, '--user', '--map-current-user', '--keep-caps', '--mount',
               '--propagation', 'private', '--net', '--pid', '--mount-proc', '--kill-child',
               '--fork', sys.executable, '-B', str(Path(__file__).resolve()),
               str(package), str(evidence), '--inside']
    receipt = {'command': command, 'host_identity_and_namespaces':
               {key: value for key, value in env.items() if key.startswith('DB_HOST_')}}
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
        print('MARTINS_DUNGEON_BASH_NATIVE_OK')
        return
    report = {'success': False, 'sessions': [], 'source_url': SOURCE_URL}
    write_json(evidence / 'continuity.json', report)
    session = None
    try:
        report['output_contract'] = output_contract(package, evidence)
        report['isolation'] = namespace_receipt(Path('/proc/self'))
        report['isolation']['store'] = readonly_store(evidence)
        watched = {Path.home() / '.local/state' / GAME, Path.home() / 'dunbash.sav.gz',
                   Path.cwd() / 'dunbash.sav.gz', Path.cwd() / 'dunbash.sav', Path.cwd() / 'dunbash.log'}
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
        write_json(evidence / 'private-before.json', fingerprint(root))
        require(all(not any((root / name).iterdir()) for name in
                    ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work')),
                'private HOME/XDG/cwd are not initially empty')
        state_dir = root / 'state' / GAME
        save_path = state_dir / 'dunbash.sav.gz'
        # This is ordinary prompt input, not a fixed-name/stat/RNG fixture.
        name = 'Native' + format(os.getpid(), 'x')
        require(len(name) <= 16, 'ordinary generated name exceeds source input limit')
        session = Session(package, env, root, evidence, 1)
        session.enter(name)
        process = session.process_receipt()
        start = session.live('first-live')
        require(start['name'] == name, 'normal name entry did not reach HUD')
        advanced = session.advance(start, 'movement')
        session.inventory('pre-save-inventory')
        require(session.live('pre-save') == advanced, 'no-turn inventory changed pre-save map/HUD')
        session.save()
        require(save_path.is_file() and save_path.stat().st_size > 0 and
                not (state_dir / 'dunbash.sav').exists(), 'normal save did not create only compressed native state')
        native_save = {'path': str(save_path), 'size': save_path.stat().st_size, 'sha256': sha(save_path)}
        copy = evidence / 'session-1-native-save.gz'
        shutil.copyfile(save_path, copy)
        native_save.update({'evidence_copy': str(copy), 'evidence_copy_never_reinjected': True})
        report['sessions'].append({'process': process, 'initial': start, 'advanced': advanced,
                                   'native_save': native_save, 'normal_save_exit_status': session.status})
        write_json(evidence / 'continuity.json', report)
        session.close()
        session = Session(package, env, root, evidence, 2)
        session.enter(name, restored=True)
        process = session.process_receipt()
        restored = session.live('restored')
        require(restored == advanced, 'restored exact decoded map/HUD/cell styles differ from pre-save')
        require(not save_path.exists() and not (state_dir / 'dunbash.sav').exists(),
                'ordinary restore failed to consume original native save')
        require(process['pid'] != report['sessions'][0]['process']['pid'], 'restore was not an independent process')
        report['continuity'] = {'full_map_and_hud_exact': True, 'decoded_nonblank_and_hud_styles_exact': True,
                                'blank_map_colors_only_normalized': True,
                                'native_save_consumed': True, 'independent_process': True}
        continued = session.advance(restored, 'continued-movement')
        session.inventory('continued-inventory')
        require(session.live('pre-quit') == continued, 'no-turn inventory changed continued state')
        session.quit()
        require(not save_path.exists() and not (state_dir / 'dunbash.sav').exists(), 'clean quit unexpectedly saved')
        report['sessions'].append({'process': process, 'initial': restored, 'advanced': continued,
                                   'normal_quit_exit_status': session.status})
        session.close()
        session = None
        for subdir in ('home', 'config', 'data', 'cache', 'runtime', 'tmp', 'work'):
            require(not any((root / subdir).iterdir()), 'state escaped native XDG state: ' + subdir)
        require(list((root / 'state').iterdir()) == [state_dir] and not any(state_dir.iterdir()),
                'unexpected private state footprint after save consumption/clean quit')
        for path in root.rglob('*'):
            require(not path.is_symlink(), 'private runtime symlink escapes root')
            require(path.stat().st_uid == os.getuid(), 'native state changed ownership')
            require(path.stat().st_mode & 0o077 == 0, 'native private state accessible to other users')
        require(all(fingerprint(Path(path)) == value for path, value in initial.items()),
                'host game state or working directory changed')
        report['private_footprint'] = fingerprint(root)
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
