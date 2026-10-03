#!/usr/bin/env python3
"""External observer of PtIG 32c8b0d: upstream test and real curses/xterm UI.

Only native human keys enter the game. Worldstate and saves are read-only input
for choosing legal hex moves and asserting persistence; no game module is
imported, no entry point is patched, and no save/oracle is manufactured.
"""
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
import shlex
import shutil
import signal
import struct
import subprocess
import sys
import termios
import time
import tty

import pyte

COLS, ROWS = 120, 40
PIN = '32c8b0d55c091b10ba683621d7881ef57ce8a88a'
HUD = re.compile(r'T: (\d+) H: (-?\d+) S: (-?\d+) G: (-?\d+)')
NAMES = {'d': 'east', 'e': 'north-east', 'w': 'north-west',
         's': 'west', 'x': 'south-west', 'c': 'south-east'}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def write_all(fd, data):
    while data:
        count = os.write(fd, data)
        require(count > 0, 'short terminal write')
        data = data[count:]


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


def worldstate(path):
    # client/config/io.py plus plugins/client/PleaseTheIslandGod.py.
    lines = path.read_text().splitlines()
    turn, health, satiation = map(int, lines[:3])
    inventory_end = lines.index('%', 3)
    offset = inventory_end + 1
    y, x, size = map(int, lines[offset:offset + 3])
    offset += 3
    fov, memory = lines[offset:offset + size], lines[offset + size:offset + 2 * size]
    favor = int(lines[offset + 2 * size])
    require(len(lines) == offset + 4 * size + 1, 'unexpected PtIG worldstate size')
    require(all(len(row) == size for row in fov + memory), 'incomplete native map')
    require(0 <= y < size and 0 <= x < size, 'native avatar outside map')
    return {'turn': turn, 'health': health, 'satiation': satiation, 'favor': favor,
            'position': [y, x], 'size': size, 'fov': fov, 'memory': memory}


def saved_state(data):
    # server/io.py save_world: command serialization; select T_ID 0 (avatar).
    top, avatar, current = {}, {}, None
    for line in data.decode().splitlines():
        tokens = shlex.split(line)
        if not tokens:
            continue
        key = tokens[0]
        if key in ('T_ID', 'TT_ID', 'TA_ID'):
            current = (key, int(tokens[1]))
        elif current == ('T_ID', 0) and key in (
                'T_POSY', 'T_POSX', 'T_LIFEPOINTS', 'T_SATIATION'):
            avatar[key] = int(tokens[1])
        elif key in ('TURN', 'GOD_FAVOR', 'SEED_RANDOMNESS', 'WORLD_ACTIVE'):
            top[key] = int(tokens[1])
    require(set(avatar) == {'T_POSY', 'T_POSX', 'T_LIFEPOINTS', 'T_SATIATION'},
            'save lacks avatar fields')
    require(set(top) == {'TURN', 'GOD_FAVOR', 'SEED_RANDOMNESS', 'WORLD_ACTIVE'},
            'save lacks world/RNG state')
    require(top['WORLD_ACTIVE'] == 1 and avatar['T_LIFEPOINTS'] > 0,
            'native game no longer active')
    return {'turn': top['TURN'], 'health': avatar['T_LIFEPOINTS'],
            'satiation': avatar['T_SATIATION'], 'favor': top['GOD_FAVOR'],
            'position': [avatar['T_POSY'], avatar['T_POSX']],
            'random_seed': top['SEED_RANDOMNESS']}


class Session:
    def __init__(self, executable, root, evidence, number):
        self.root, self.evidence, self.number = root, evidence, number
        self.raw = bytearray()
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.alive, self.status = True, None
        self.events = []
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack('HHHH', ROWS, COLS, 0, 0))
                environment = dict(os.environ, PATH='')
                os.execve(executable, [executable], environment)
            except BaseException:
                os._exit(127)
        write_all(1, b'\x1b[2J\x1b[H')

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def read(self, timeout=0.1):
        ready = select.select([self.fd, 0], [], [], timeout)[0]
        if 0 in ready:
            # Only actual xterm query replies; never fabricate handshake bytes.
            reply = os.read(0, 4096)
            if reply:
                write_all(self.fd, reply)
        if self.fd not in ready:
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
        require(len(self.raw) < 8000000, 'unbounded native terminal output')
        self.stream.feed(self.decoder.decode(data))
        write_all(1, data)
        return True

    def exited(self):
        if self.alive:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.alive = False
                self.status = os.waitstatus_to_exitcode(status)
        return not self.alive

    def wait(self, predicate, description, timeout=25):
        deadline = time.monotonic() + timeout
        while True:
            self.read()
            if predicate():
                return
            require(not self.exited(), description + ': native process exited\n' + self.text())
            require(time.monotonic() < deadline, description + ': timeout\n' + self.text())

    def settle(self):
        # The client backs off to 1s reads. Allow a full polling interval before
        # requiring a quiet terminal, rather than accepting the startup screen.
        until = time.monotonic() + 1.2
        deadline = until + 5
        while time.monotonic() < until:
            if self.read(0.1):
                until = time.monotonic() + 1.2
            require(time.monotonic() < deadline, 'native screen never settled')

    def live(self):
        self.wait(lambda: HUD.search(self.text()) is not None and
                  'PLEASE THE ISLAND GOD' in self.text(), 'waiting for native PtIG UI')
        self.settle()
        state = worldstate(self.root / 'state/plomrogue/server_run/worldstate')
        visible = tuple(map(int, HUD.search(self.text()).groups()))
        require(visible == tuple(state[k] for k in ('turn', 'health', 'satiation', 'favor')),
                'native HUD does not match worldstate')
        require(state['health'] > 0, 'avatar died')
        return state

    def send(self, key):
        require(not self.exited(), 'native game exited before keypress')
        self.events.append({'key': key})
        write_all(self.fd, key.encode('ascii'))

    def stable_screen(self):
        # PtIG fixed layout: Stats at row 1/columns 0..32; map starts column
        # 34 and spans all rows. Log and Things here are intentionally excluded.
        return {'hud': [list(self.screen.buffer[1][x]) for x in range(33)],
                'map': [[list(self.screen.buffer[y][x]) for x in range(34, COLS)]
                        for y in range(ROWS)]}

    def capture(self, label):
        self.settle()
        require(not self.exited(), 'cannot capture exited native UI')
        prefix = self.evidence / label
        prefix.with_suffix('.txt').write_text(self.text())
        prefix.with_suffix('.raw').write_bytes(self.raw)
        stable = self.stable_screen()
        write_json(prefix.with_suffix('.json'), stable)
        native_world = self.root / 'state/plomrogue/server_run/worldstate'
        prefix.with_suffix('.worldstate').write_bytes(native_world.read_bytes())
        subprocess.run([os.environ['PLOMROGUE_IMPORT'], '-display', os.environ['DISPLAY'],
                        '-window', 'root', str(prefix.with_suffix('.png'))],
                       env=dict(os.environ, HOME=str(self.root / 'x-home'),
                                TMPDIR=str(self.root / 'x-tmp')),
                       check=True, timeout=20)
        require(prefix.with_suffix('.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n'),
                'real Xvfb screenshot is not PNG')
        return stable

    def move(self):
        before = self.live()
        y, x = before['position']
        # libplomrogue.c mv_yx_in_dir: odd rows offset to the right.
        neighbors = {'d': (y, x + 1), 'e': (y - 1, x + y % 2),
                     'w': (y - 1, x - (1 - y % 2)), 's': (y, x - 1),
                     'x': (y + 1, x - (1 - y % 2)), 'c': (y + 1, x + y % 2)}
        choices = [(key, pos) for key, pos in neighbors.items()
                   if 0 <= pos[0] < before['size'] and 0 <= pos[1] < before['size']
                   and before['fov'][pos[0]][pos[1]] in '.:_']
        require(choices, 'no visible passable adjacent tile in naturally generated world')
        for key, target in choices:
            self.send(key)
            self.settle()
            after = self.live()
            if after['position'] != before['position']:
                require(after['position'] == list(target), 'native move reached wrong hex')
                require(after['turn'] > before['turn'], 'native movement did not advance turn')
                event = {'key': key, 'direction': NAMES[key], 'before': before['position'],
                         'after': after['position'], 'turn_before': before['turn'],
                         'turn_after': after['turn'], 'selection': 'read-only native FOV map'}
                self.events[-1].update(event)
                return event
            require(after['turn'] == before['turn'],
                    'candidate action consumed a turn without moving')
        raise RuntimeError('native input did not move to any visible passable neighbor')

    def quit_save(self, label):
        visible = self.live()
        self.send('Q')  # client command_quit and wrapper force server QUIT save.
        deadline = time.monotonic() + 20
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'native Q quit timed out')
        self.settle()
        require(self.status == 0, 'native Q quit status ' + str(self.status))
        game = self.root / 'state/plomrogue'
        require(not (game / 'server_run').exists(), 'native wrapper left server_run behind')
        data = (game / 'save').read_bytes()
        decoded = saved_state(data)
        require(all(decoded[k] == visible[k] for k in
                    ('turn', 'health', 'satiation', 'favor', 'position')),
                'native saved state differs from live HUD/position')
        (self.evidence / (label + '.save')).write_bytes(data)
        (self.evidence / (label + '.record')).write_bytes((game / 'record_save').read_bytes())
        (self.evidence / (label + '.log')).write_bytes((game / 'log').read_bytes())
        (self.evidence / (label + '-session.raw')).write_bytes(self.raw)
        return data, decoded

    def close(self):
        (self.evidence / ('session-%d.raw' % self.number)).write_bytes(self.raw)
        if not self.exited():
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)


def play(executable, root, evidence):
    sessions, restores = [], []
    baseline_bytes = baseline_state = baseline_screen = None
    for number in range(1, 5):
        session = Session(executable, root, evidence, number)
        try:
            loaded = session.live()
            if number == 1:
                initial = loaded
                session.capture('initial')
                movement = session.move()
                baseline_screen = session.capture('saved-screen')
                baseline_bytes, baseline_state = session.quit_save('baseline')
            else:
                require(all(loaded[k] == baseline_state[k] for k in
                            ('turn', 'health', 'satiation', 'favor', 'position')),
                        'restored native state differs from previous save')
                screen = session.capture('restore-%d' % (number - 1))
                require(screen == baseline_screen,
                        'restored map/HUD characters or rendition attributes differ')
                if number < 4:
                    data, state = session.quit_save('no-action-%d' % (number - 1))
                    require(data == baseline_bytes, 'no-action restore changed full native save')
                    restores.append({'session': number, 'full_save_sha256': digest(data),
                                     'state': state, 'map_hud_attributes_exact': True})
                else:
                    session.send('W')
                    session.wait(lambda: (HUD.search(session.text()) is not None and
                                 int(HUD.search(session.text()).group(1)) > loaded['turn']),
                                 'waiting for further native wait action')
                    further = session.live()
                    require(further['turn'] > baseline_state['turn'], 'further action had no effect')
                    session.capture('continued')
                    final, final_state = session.quit_save('continued')
                    require(final != baseline_bytes, 'further native action left save unchanged')
            sessions.append({'session': number, 'events': session.events, 'quit_status': session.status})
        finally:
            session.close()
        # Game writes must not leak into caller CWD/HOME or other XDG areas.
        for directory in ('home', 'config', 'data', 'cache', 'work', 'runtime', 'tmp'):
            require(not list((root / directory).iterdir()),
                    'native game wrote outside XDG_STATE_HOME/plomrogue: ' + directory)
        state_root = root / 'state'
        require([path.name for path in state_root.iterdir()] == ['plomrogue'],
                'game wrote outside state/plomrogue')
        immutable = Path(executable).parent.parent / 'share/plomrogue'
        for name in ('server', 'client', 'plugins', 'confserver', 'roguelike',
                     'start_server_client_union.sh', 'roguelike-server',
                     'roguelike-client', 'libplomrogue.so'):
            link = state_root / 'plomrogue' / name
            require(link.is_symlink() and link.resolve() == immutable / name,
                    'runtime source is not the installed immutable symlink: ' + name)
    record = {'initial': {key: initial[key] for key in ('turn', 'position', 'health')},
              'movement': movement, 'baseline': baseline_state,
              'baseline_save_sha256': digest(baseline_bytes), 'restores': restores,
              'continued': final_state, 'continued_save_sha256': digest(final),
              'sessions': sessions, 'writes_confined_to': str(root / 'state/plomrogue'),
              'state_limits': 'Exact no-action UI restoration and original-fixture '
              '90-versus-45/save/reload/45 full-save continuation are exercised separately; '
              'arbitrary future-action sequences are not exhaustively tested.'}
    write_json(evidence / 'gameplay.json', record)


def isolate(root, evidence):
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int

    def mount(source, target, filesystem=None, flags=0):
        if libc.mount(os.fsencode(source), os.fsencode(target),
                      None if filesystem is None else os.fsencode(filesystem), flags, None):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), str(target))

    try:
        mount('/gnu/store', '/gnu/store', flags=4096)
        mount('/gnu/store', '/gnu/store', flags=4096 | 32 | 1 | 2 | 4)
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, evidence = Path('/tmp/plomrogue-root'), Path('/tmp/plomrogue-evidence')
        root.mkdir()
        evidence.mkdir()
        mount('/proc/self/fd/' + str(root_fd), root, flags=4096)
        mount('/proc/self/fd/' + str(evidence_fd), evidence, flags=4096)
        mount('proc', '/proc', 'proc', 2 | 4 | 8)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
    finally:
        os.close(root_fd)
        os.close(evidence_fd)
    return root, evidence


def namespaces():
    return {name: os.readlink('/proc/self/ns/' + name) for name in ('user', 'mnt', 'net', 'pid')}


def regression(source, root, evidence):
    destination = root / 'upstream-regression'
    shutil.copytree(source, destination, symlinks=False)
    # Store permissions are intentionally immutable. Only the independent copy
    # is writable, including the pre-existing upstream test output if present.
    for path in [destination, *destination.rglob('*')]:
        path.chmod(path.stat().st_mode | (0o700 if path.is_dir() else 0o600))
    names = ('testing/start', 'testing/run', 'testing/ref_end', 'test_server.sh', 'build.sh')
    before = {name: digest((destination / name).read_bytes()) for name in names}
    with (evidence / 'upstream-test.log').open('wb') as log:
        completed = subprocess.run([str(destination / 'test_server.sh')], cwd=destination,
                                   stdout=log, stderr=subprocess.STDOUT, timeout=120)
    require(completed.returncode == 0, 'installed original upstream test_server.sh failed')
    after = {name: digest((destination / name).read_bytes()) for name in names}
    require(before == after, 'original regression inputs/oracle were modified')
    actual, reference = destination / 'testing/last_end', destination / 'testing/ref_end'
    with (evidence / 'upstream-cmp.log').open('wb') as log:
        comparison = subprocess.run(['cmp', str(actual), str(reference)],
                                    stdout=log, stderr=subprocess.STDOUT, timeout=10)
    require(comparison.returncode in (0, 1), 'could not compare upstream reference save')
    matches = comparison.returncode == 0
    require(matches == (actual.read_bytes() == reference.read_bytes()), 'inconsistent cmp result')
    with (evidence / 'upstream-reference.diff').open('wb') as log:
        difference = subprocess.run(['diff', '-u', str(reference), str(actual)],
                                    stdout=log, stderr=subprocess.STDOUT, timeout=10)
    require(difference.returncode in (0, 1), 'could not preserve upstream reference diff')
    for name in ('start', 'run', 'ref_end', 'last_end'):
        shutil.copyfile(destination / 'testing' / name, evidence / ('upstream-' + name))
    write_json(evidence / 'upstream-regression.json', {
        'command': str(destination / 'test_server.sh'), 'exit_status': completed.returncode,
        'inputs_sha256': before, 'inputs_unchanged': True,
        'cmp_exit_status': comparison.returncode, 'upstream_reference_matches': matches,
        'original_reference_gate': 'passed' if matches else 'failed: original reference differs',
        'final_save_sha256': digest(actual.read_bytes()),
        'reference_save_sha256': digest(reference.read_bytes()), 'oracle_regenerated': False})
    require(matches, 'original upstream reference mismatch; see upstream-cmp.log and '
            'upstream-reference.diff (original oracle retained)')


def continuation(source, root, evidence):
    # Original testing/run contains 90 AI actions and QUIT. Split only at a
    # native command boundary; QUIT uses the server's own save serialization.
    fixture = (source / 'testing/run').read_text().splitlines(keepends=True)
    require(fixture and fixture[-1].strip() == 'QUIT' and
            all(line.strip() == 'ai' for line in fixture[:-1]),
            'unexpected original upstream continuation fixture')
    commands = fixture[:-1]
    require(len(commands) == 90, 'pinned upstream fixture no longer has 90 AI actions')
    midpoint = len(commands) // 2
    hashes = {name: digest((source / 'testing' / name).read_bytes())
              for name in ('start', 'run', 'ref_end')}

    def prepare(label):
        work = root / ('continuation-' + label)
        shutil.copytree(source, work, symlinks=False)
        for path in [work, *work.rglob('*')]:
            path.chmod(path.stat().st_mode | (0o700 if path.is_dir() else 0o600))
        shutil.copyfile(source / 'testing/start', work / '_test')
        return work

    def run(work, actions, label):
        with (evidence / ('continuation-' + label + '.log')).open('wb') as log:
            process = subprocess.Popen([str(work / 'roguelike-server'), '-l', '_test'],
                                       cwd=work, env=dict(os.environ), stdout=log,
                                       stderr=subprocess.STDOUT, start_new_session=True)
            try:
                deadline = time.monotonic() + 60
                inbox = work / 'server_run/in'
                world = work / 'server_run/worldstate'
                while not world.is_file():
                    require(process.poll() is None, label + ': server exited before ready')
                    require(time.monotonic() < deadline, label + ': server startup timed out')
                    time.sleep(0.05)
                require(inbox.is_file(), label + ': server input absent')
                with inbox.open('a') as stream:
                    stream.write(''.join(actions) + 'QUIT\n')
                    stream.flush()
                require(process.wait(timeout=120) == 0, label + ': native server failed')
                require(not inbox.exists() and not world.exists(),
                        label + ': native server did not clean up')
            finally:
                stop(process)
        require((work / '_test').is_file(), label + ': native save absent')
        result = (work / '_test').read_bytes()
        require(re.search(rb'^SEED_RANDOMNESS \d+$', result, re.MULTILINE) is not None,
                label + ': native save lacks RNG seed')
        (evidence / ('continuation-' + label + '.save')).write_bytes(result)
        shutil.copyfile(work / 'record__test', evidence / ('continuation-' + label + '.record'))
        return result

    uninterrupted = run(prepare('uninterrupted'), commands, 'uninterrupted')
    restored_work = prepare('restored')
    run(restored_work, commands[:midpoint], 'midpoint')
    restored = run(restored_work, commands[midpoint:], 'restored')
    oracle = (source / 'testing/ref_end').read_bytes()
    record = {'upstream_ai_actions': len(commands), 'split_after': midpoint,
              'exact_continuation': uninterrupted == restored,
              'scope': 'all native serialized bytes including RNG seed; original upstream fixture',
              'uninterrupted_sha256': digest(uninterrupted),
              'restored_sha256': digest(restored), 'oracle_sha256': digest(oracle),
              'uninterrupted_matches_original_oracle': uninterrupted == oracle,
              'restored_matches_original_oracle': restored == oracle,
              'original_inputs_sha256': hashes, 'oracle_regenerated': False}
    require(hashes == {name: digest((source / 'testing' / name).read_bytes())
                       for name in hashes}, 'continuation changed original fixtures')
    with (evidence / 'continuation.diff').open('wb') as log:
        comparison = subprocess.run(['diff', '-u',
                                    str(evidence / 'continuation-uninterrupted.save'),
                                    str(evidence / 'continuation-restored.save')],
                                   stdout=log, stderr=subprocess.STDOUT, timeout=10)
    require(comparison.returncode in (0, 1), 'continuation diff failed')
    record['diff_exit_status'] = comparison.returncode
    write_json(evidence / 'continuation.json', record)
    require(uninterrupted == restored, 'native 90 AI versus 45/save/reload/45 continuation differs')



def inner(arguments):
    game_out, root, evidence, xvfb, xterm, image_import, fonts = arguments
    root, evidence = isolate(Path(root), Path(evidence))
    scope = json.loads((evidence / 'scope.json').read_text())
    scope['isolated_namespaces'] = namespaces()
    require(all(scope['host_namespaces'][key] != scope['isolated_namespaces'][key]
                for key in scope['host_namespaces']), 'namespace isolation did not change identity')
    interfaces = [line.split(':')[0].strip() for line in
                  Path('/proc/net/dev').read_text().splitlines()[2:]]
    require(interfaces == ['lo'], 'offline network namespace contains non-loopback interface')
    mounts = Path('/proc/self/mountinfo').read_text()
    store = [line for line in mounts.splitlines() if line.split()[4] == '/gnu/store']
    require(store and 'ro' in store[-1].split()[5].split(','), 'store bind mount is not read-only')
    scope.update(interfaces=interfaces, store_read_only=True, private_tmp=True,
                 isolated_pid=os.getpid())
    write_json(evidence / 'scope.json', scope)
    (evidence / 'mountinfo.txt').write_text(mounts)
    (evidence / 'net-dev.txt').write_text(Path('/proc/net/dev').read_text())
    for variable, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                ('TMPDIR', 'tmp')):
        (root / directory).mkdir(mode=0o700)
        os.environ[variable] = str(root / directory)
    (root / 'work').mkdir()
    os.environ.update(TERM='xterm-256color', PLOMROGUE_IMPORT=image_import,
                      PYTHONDONTWRITEBYTECODE='1',
                      DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/no-session-bus')
    source = Path(game_out) / 'share/plomrogue'
    for name in ('NOTICE', 'GPLv3', 'README', 'README_PtIG', 'roguelike', 'roguelike-client',
                 'roguelike-server', 'libplomrogue.c', 'libplomrogue.so', 'test_server.sh',
                 'build.sh', 'testing/start', 'testing/run', 'testing/ref_end'):
        require((source / name).is_file(), 'installed source/runtime missing ' + name)
    regression(source, root, evidence)
    continuation(source, root, evidence)
    # Distinguish regression infrastructure from the native consumer below.
    require(not list((root / 'tmp').iterdir()), 'upstream regression left temporary files')
    fontconfig = root / 'fonts.conf'
    fontconfig.write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">'
                          '<fontconfig><dir>' + fonts + '</dir><cachedir>'
                          + str(root / 'font-cache') + '</cachedir></fontconfig>')
    os.environ['FONTCONFIG_FILE'] = str(fontconfig)
    # xterm/font infrastructure uses independent HOME/tmp/cache, not game areas.
    (root / 'x-home').mkdir()
    (root / 'x-tmp').mkdir()
    infrastructure_env = dict(os.environ, HOME=str(root / 'x-home'), TMPDIR=str(root / 'x-tmp'))
    server = terminal = None
    read_fd, write_fd = os.pipe()
    try:
        with (evidence / 'xvfb.log').open('wb') as log:
            server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                       '1600x1000x24', '-nolisten', 'tcp', '-ac'],
                                      pass_fds=(write_fd,), stdout=log, stderr=log,
                                      env=infrastructure_env, start_new_session=True)
        os.close(write_fd)
        write_fd = None
        require(select.select([read_fd], [], [], 20)[0], 'Xvfb display allocation timed out')
        display = os.read(read_fd, 100).decode().strip()
        require(display.isdecimal(), 'invalid Xvfb display number')
        os.environ['DISPLAY'] = ':' + display
        infrastructure_env['DISPLAY'] = ':' + display
        with (evidence / 'xterm.log').open('wb') as log:
            terminal = subprocess.Popen([xterm, '-display', ':' + display, '-geometry',
                                         '%dx%d+0+0' % (COLS, ROWS), '-fa', 'DejaVu Sans Mono',
                                         '-fs', '12', '-xrm', 'XTerm*allowTitleOps: false',
                                         '-e', sys.executable, '-B', str(root / 'runner.py'),
                                         '--terminal', game_out, str(root), str(evidence)],
                                        env=dict(infrastructure_env,
                                                 PLOMROGUE_GAME_ENV=json.dumps(dict(os.environ))),
                                        stdout=log, stderr=log, start_new_session=True)
        status = terminal.wait(timeout=150)
        require(status == 0 and (evidence / 'gameplay.json').is_file(),
                'native terminal failed; see terminal.log/failure.txt (status %d)' % status)
    finally:
        os.close(read_fd)
        if write_fd is not None:
            os.close(write_fd)
        stop(terminal)
        stop(server)
    return 0


def main():
    if sys.argv[1] == '--isolated':
        return inner(sys.argv[2:])
    game_out, root, evidence, nar, unshare, timeout, xvfb, xterm, image_import, fonts = sys.argv[1:]
    root, evidence = Path(root).resolve(), Path(evidence).resolve()
    if list(evidence.iterdir()):
        print('PLOMROGUE_EVIDENCE_DIR must be new or empty', file=sys.stderr)
        return 64
    record = {'status': 'running', 'consumer': 'native curses in real xterm/Xvfb',
              'output': game_out, 'upstream_pin': PIN, 'output_nar_before': nar}
    write_json(evidence / 'evidence.json', record)
    write_json(evidence / 'scope.json', {'host_namespaces': namespaces(),
                                        'host_cwd_unchanged': True, 'host_home_untouched': True})
    shutil.copyfile(__file__, root / 'runner.py')
    try:
        with (evidence / 'namespace.log').open('wb') as log:
            completed = subprocess.run([timeout, '--kill-after=10', '650', unshare,
                                        '--user', '--map-current-user', '--keep-caps', '--mount',
                                        '--propagation', 'private', '--net', '--pid', '--fork',
                                        '--kill-child', sys.executable, '-B', str(root / 'runner.py'),
                                        '--isolated', game_out, str(root), str(evidence),
                                        xvfb, xterm, image_import, fonts],
                                       stdout=log, stderr=subprocess.STDOUT, timeout=670)
        require(completed.returncode == 0, 'isolated native consumer failed (status %d)' % completed.returncode)
        upstream = json.loads((evidence / 'upstream-regression.json').read_text())
        require(upstream['upstream_reference_matches'], 'original upstream reference gate failed')
        record.update(status='passed', native_status='passed',
                      gameplay=json.loads((evidence / 'gameplay.json').read_text()),
                      upstream_regression=upstream,
                      continuation=json.loads((evidence / 'continuation.json').read_text()),
                      scope=json.loads((evidence / 'scope.json').read_text()))
        return 0
    except BaseException as error:
        record.update(status='failed', error=str(error))
        for name, key in (('upstream-regression.json', 'upstream_regression'),
                          ('continuation.json', 'continuation'),
                          ('scope.json', 'scope'), ('gameplay.json', 'gameplay')):
            path = evidence / name
            if path.is_file():
                record[key] = json.loads(path.read_text())
        return 1
    finally:
        write_json(evidence / 'evidence.json', record)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--terminal':
        # Load game environment before isolating the terminal infrastructure.
        environment = json.loads(os.environ['PLOMROGUE_GAME_ENV'])
        game_out, root, evidence = sys.argv[2:]
        root, evidence = Path(root), Path(evidence)
        sys.stderr = (evidence / 'terminal.log').open('w', buffering=1)
        os.environ.clear()
        os.environ.update(environment)
        original = termios.tcgetattr(0)
        tty.setraw(0)
        try:
            play(str(Path(game_out) / 'bin/plomrogue'), root, evidence)
        except BaseException as error:
            (evidence / 'failure.txt').write_text(str(error) + '\n')
            raise
        finally:
            termios.tcsetattr(0, termios.TCSANOW, original)
    else:
        sys.exit(main())
