#!/usr/bin/env python3
"""Observe ordinary City of the Condemned menus, movement and world turns.

Source contract: tapio/cotc e9a8989d34c9d3e0c68e7e42b526e1bee923ac7c,
main.cc handleInput/mainLoop, screens.hh title/frame, world.hh viewport,
world.cc draw, actor.hh move/idle and ability.cc. There is no native save/load.
No seed, debug interface, injected state or installed test hook is used.
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
import shutil
import stat
import struct
import sys
import termios
import time
import traceback

import pyte

ROWS, COLS = 30, 100
MAP_X, MAP_Y = COLS - 47, ROWS // 2 - 11
PLAYER_X, PLAYER_Y = MAP_X + 22, MAP_Y + 9
GAME = 'city-of-the-condemned'
SOURCE = 'https://github.com/tapio/cotc/tree/e9a8989d34c9d3e0c68e7e42b526e1bee923ac7c'
DIRECTIONS = [('g', -1, 0), ('j', 1, 0), ('y', 0, -1), ('h', 0, 1),
              ('t', -1, -1), ('u', 1, -1), ('b', -1, 1), ('n', 1, 1)]
FLOOR = '.,:/h'
ACTORS = '@aiAdD'
ERRORS = re.compile(r'error initializing|error with console|segmentation fault|'
                    r'permission denied|no such file|traceback|backtrace|'
                    r'couldn.t open|terminate called|assertion .* failed', re.I)
COMBAT = re.compile(r'You punish the |You vanquished the |You were hurt by the |'
                    r'You burn the |You burnt the ')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def inventory(root):
    result = {}
    for path in sorted(root.rglob('*')):
        info = path.lstat()
        entry = {'uid': info.st_uid, 'gid': info.st_gid,
                 'mode': stat.S_IMODE(info.st_mode)}
        if stat.S_ISDIR(info.st_mode):
            entry['type'] = 'directory'
        elif stat.S_ISREG(info.st_mode):
            data = path.read_bytes()
            entry.update(type='file', size=len(data), sha256=digest(data))
        else:
            raise RuntimeError('unexpected runtime filesystem object: ' + str(path))
        result[str(path.relative_to(root))] = entry
    return result


def namespace_proof(proc):
    namespaces = {key: os.readlink(proc / 'ns' / key)
                  for key in ('user', 'mnt', 'net', 'pid')}
    host = {'user': os.environ['HOST_USER_NS'], 'mnt': os.environ['HOST_MOUNT_NS'],
            'net': os.environ['HOST_NET_NS'], 'pid': os.environ['HOST_PID_NS']}
    files = {key: (proc / key).read_text() for key in
             ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route')}
    for key, actual in namespaces.items():
        require(actual != host[key], 'not a private ' + key + ' namespace')
        require(actual == os.readlink('/proc/self/ns/' + key), 'game escaped ' + key)
    for kind, field in (('uid', 'Uid'), ('gid', 'Gid')):
        number = int(os.environ['HOST_' + kind.upper()])
        values = re.search(r'^' + field + r':\s*(.+)$', files['status'], re.M)
        require(number != 0 and values and [int(x) for x in values[1].split()] == [number] * 4,
                'not ordinary same-identity ' + field)
        require([int(x) for x in files[kind + '_map'].split()] == [number, number, 1],
                'not exact same-identity ' + kind + ' mapping')
    interfaces = [line.split(':')[0].strip() for line in files['net/dev'].splitlines()[2:]
                  if ':' in line]
    require(interfaces == ['lo'], 'external network interface present')
    require(len(files['net/route'].splitlines()) <= 1, 'IPv4 routes present')
    require(all(row.split()[-1] == 'lo' for row in files['net/ipv6_route'].splitlines()
                if row.strip()), 'external IPv6 routes present')
    return {'namespaces': namespaces, 'host_namespaces': host, 'files': files}


def mount(source, target, flags):
    # Nonzero caller UID is retained. Use namespace capabilities directly:
    # mount(8)'s real-UID policy is not the kernel's user-namespace policy.
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int
    if libc.mount(os.fsencode(source), os.fsencode(target), None, flags, None):
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number), target)


def store_mounts():
    text = Path('/proc/self/mountinfo').read_text()
    entries = []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in (('\\040', ' '), ('\\011', '\t'),
                                 ('\\012', '\n'), ('\\134', '\\')):
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            entries.append({'target': target, 'options': fields[5].split(','),
                            'optional': fields[6:fields.index('-')]})
    return text, entries


def readonly_store(evidence):
    (evidence / 'mountinfo-before.txt').write_text(store_mounts()[0])
    mount('/gnu/store', '/gnu/store', 4096 | 16384)  # bind recursively
    mount('/gnu/store', '/gnu/store', 262144 | 16384)  # private recursively
    for target in sorted({item['target'] for item in store_mounts()[1]}, key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)  # bind remount read-only
    text, entries = store_mounts()
    (evidence / 'mountinfo-after.txt').write_text(text)
    require(entries and any(item['target'] == '/gnu/store' for item in entries),
            'store mount missing')
    require(all('ro' in item['options'] and 'rw' not in item['options'] and not
                any(option.startswith(('shared:', 'master:')) for option in item['optional'])
                for item in entries), 'store is not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store filesystem writable')
    return entries


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
    # ncurses xterm terminfo uses REP, absent from stock pyte 0.8.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, output, evidence, root):
        self.output, self.evidence, self.root = output, evidence, root
        evidence.mkdir(mode=0o700)
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.raw, self.inputs = bytearray(), []
        self.status = None
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                launcher = str(output / 'bin' / GAME)
                environment = {'PATH': '', 'TERM': 'xterm-256color', 'LC_ALL': 'C',
                               'HOME': str(root / 'home'), 'TMPDIR': str(root / 'tmp')}
                for variable, name in (('XDG_STATE_HOME', 'state'), ('XDG_CONFIG_HOME', 'config'),
                                       ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                       ('XDG_RUNTIME_DIR', 'runtime')):
                    environment[variable] = str(root / name)
                os.execve(launcher, [launcher], environment)
            except BaseException:
                os.write(2, traceback.format_exc().encode())
                os._exit(127)

    def exited(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
        return self.status is not None

    def pump(self, delay=0.05):
        if self.fd not in select.select([self.fd], [], [], delay)[0]:
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
        # Decoded screen and the full stream are retained, including ANSI bytes.
        require(not ERRORS.search(self.raw.decode('utf-8', errors='replace')),
                'native error in PTY output')
        return True

    def text(self):
        return '\n'.join(self.screen.display)

    def snapshot(self, label):
        record(self.evidence / (label + '.screen.json'),
               {'rows': self.screen.display, 'raw_bytes': len(self.raw),
                'cursor': {'x': self.screen.cursor.x, 'y': self.screen.cursor.y}})
        (self.evidence / (label + '.screen.txt')).write_text(self.text() + '\n')
        (self.evidence / 'terminal.raw').write_bytes(self.raw)
        record(self.evidence / 'pty-inputs.json', self.inputs)

    def settle(self, seconds=0.25):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            self.pump(0.05)

    def wait(self, predicate, label):
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            self.pump()
            if predicate():
                self.settle()
                if predicate():
                    self.snapshot(label)
                    return
            require(not self.exited(), 'game exited before ' + label)
        self.snapshot('timeout-' + label)
        raise RuntimeError('native screen timeout: ' + label)

    def send(self, label, key):
        require(not self.exited(), 'sending to exited game')
        data = key.encode('ascii')
        self.inputs.append({'label': label, 'hex': data.hex(), 'raw_offset': len(self.raw)})
        record(self.evidence / 'pty-inputs.json', self.inputs)
        require(os.write(self.fd, data) == len(data), 'short PTY write')

    def title(self):
        return all(marker in self.text() for marker in
                   ('Join the Heavenly Host', 'Join the forces of Hell', '[q] Quit', 'Version:'))

    def game(self):
        return ('Player - ' in self.text() and 'Condition:' in self.text()
                and 'Abilities:' in self.text() and 'Humans:' in self.text()
                and self.screen.display[PLAYER_Y][PLAYER_X] in ACTORS)

    def finished(self):
        return 'Battle summary:' in self.text() and ('VICTORY' in self.text() or 'DEFEAT' in self.text())

    def state(self):
        require(self.game(), 'missing real gameplay HUD/map/player')
        rows = self.screen.display
        health = rows[4][2:26].rstrip()
        require(health and set(health) <= {'I', '-'}, 'native health bar absent')
        counts = {}
        for label in ('Humans', 'Blessed', 'Angels', 'Demons'):
            match = re.search(label + r':\s*(\d+)', self.text())
            require(match, 'world count missing: ' + label)
            counts[label] = int(match[1])
        return {'map': [row[MAP_X + 1:MAP_X + 44] for row in rows[MAP_Y + 1:MAP_Y + 18]],
                'health': health, 'health_points': health.count('I'), 'world': counts,
                'role': rows[1].strip(), 'player_glyph': rows[PLAYER_Y][PLAYER_X],
                'hud': [row[:MAP_X] for row in rows[1:20]],
                'messages': rows[-4:-1]}

    def action(self, label, key):
        self.send(label, key)
        # handleInput flushes pending input. Never batch keys, and allow each
        # ordinary action to finish its world update before the next key.
        self.settle(0.30)
        require(not self.exited(), 'game unexpectedly exited during ' + label)
        require(self.game() or self.finished(), 'action left native gameplay')
        self.snapshot(label)
        return self.state() if self.game() else None

    def process_receipt(self):
        proc = Path('/proc') / str(self.pid)
        receipt = namespace_proof(proc)
        native = str(self.output / 'libexec/cotc')
        require(os.readlink(proc / 'exe') == native, 'wrapper did not exec installed native ELF')
        argv = (proc / 'cmdline').read_bytes().rstrip(b'\0').split(b'\0')
        require(argv == [native.encode()], 'game received injected flags')
        tty = os.readlink(proc / 'fd/0')
        require(tty.startswith('/dev/pts/') and all(os.readlink(proc / ('fd/' + str(fd))) == tty
                                                 for fd in (1, 2)), 'game lacks real PTY')
        state = self.root / 'state' / GAME
        require(os.readlink(proc / 'cwd') == str(state), 'wrapper did not route CWD log state')
        environment = dict(item.split(b'=', 1) for item in (proc / 'environ').read_bytes().split(b'\0')
                           if b'=' in item)
        require(environment[b'HOME'] == str(self.root / 'home').encode(), 'wrapper changed HOME')
        receipt.update(pid=self.pid, executable=native, argv=[a.decode() for a in argv],
                       tty=tty, cwd=str(state), environment={k.decode(): v.decode() for k, v in environment.items()})
        record(self.evidence / 'native-process.json', receipt)
        return receipt

    def quit(self):
        self.send('quit-game-to-title', 'q')
        self.wait(self.title, 'returned-title')
        self.send('quit-title', 'q')
        deadline = time.monotonic() + 15
        while not self.exited() and time.monotonic() < deadline:
            self.pump()
        require(self.exited(), 'ordinary title quit did not terminate')
        while self.pump(0.05):
            pass
        self.snapshot('normal-exit')
        require(self.status == 0, 'native nonzero/signal exit: ' + str(self.status))

    def close(self):
        (self.evidence / 'terminal.raw').write_bytes(self.raw)
        record(self.evidence / 'pty-inputs.json', self.inputs)
        record(self.evidence / 'process-exit.json', {'pid': self.pid, 'exit_status': self.status,
                                                   'normal_quit': self.status == 0})
        os.close(self.fd)


def translation(before, after, dx, dy):
    # The native camera follows the player at a fixed viewport center. Static
    # terrain shifting by the requested direction proves movement, unlike raw
    # ANSI changes or NPC motion alone. Ignore actor cells and unrevealed blanks.
    matches, mismatches, features, shifted_features = 0, 0, 0, 0
    for y, row in enumerate(after['map']):
        for x, cell in enumerate(row):
            xx, yy = x + dx, y + dy
            if not (0 <= yy < 17 and 0 <= xx < 43):
                continue
            old = before['map'][yy][xx]
            if old in ACTORS + ' ' or cell in ACTORS + ' ':
                continue
            if old == cell:
                matches += 1
                features += int(old not in '.,:')
                stationary = before['map'][y][x]
                if stationary not in ACTORS + ' ' and stationary != cell:
                    shifted_features += 1
            else:
                mismatches += 1
    return {'matches': matches, 'mismatches': mismatches, 'features': features,
            'shifted_features': shifted_features, 'dx': dx, 'dy': dy,
            'confirmed': matches >= 20 and mismatches <= 2 and features >= 2
                         and shifted_features >= 2}


def move(session, number):
    before = session.state()
    # Choose only native visible walkable neighbors. Do not overwrite a map or
    # trust a movement key without observing the terrain-camera translation.
    for key, dx, dy in DIRECTIONS:
        if before['map'][8 + dy][21 + dx] not in FLOOR:
            continue
        after = session.action('movement-%02d-%s' % (number, key), key)
        require(after is not None, 'game ended before movement acceptance')
        proof = translation(before, after, dx, dy)
        if proof['confirmed']:
            proof.update(key=key, before=before, after=after)
            return proof
        before = after
    raise RuntimeError('no ordinary movement produced confirmed terrain translation')


def enemy_direction(state):
    # Small BFS over the actual visible frame, not generated state. Target only
    # visibly evil glyphs for Angel; humans may be concealed, so are not targets.
    grid = state['map']
    queue = [(21, 8, None, 0)]
    visited = {(21, 8)}
    for x, y, first, depth in queue:
        if depth >= 12:
            continue
        for key, dx, dy in DIRECTIONS:
            xx, yy = x + dx, y + dy
            if not (0 <= xx < 43 and 0 <= yy < 17) or (xx, yy) in visited:
                continue
            cell = grid[yy][xx]
            choice = first or key
            if cell in 'idD':
                return choice
            if cell in FLOOR:
                visited.add((xx, yy))
                queue.append((xx, yy, choice, depth + 1))
    return None


def play(session, selection, role):
    session.wait(session.title, 'title')
    session.send('select-' + role, selection)
    session.wait(lambda: session.game() and ('Player - ' + role) in session.text(), 'selected-role')
    process = session.process_receipt()
    initial = session.state()
    require(initial['world']['Humans'] > 0 and initial['world']['Angels'] > 0
            and initial['world']['Demons'] > 0, 'populated native world missing')
    movements = [move(session, number) for number in range(1, 4)]
    turns = []
    for number in range(8):
        before = session.state()
        after = session.action('ordinary-wait-%02d' % number, '5')
        require(after is not None, 'game ended before ordinary-turn acceptance')
        changed = any(before[field] != after[field] for field in ('map', 'health', 'world'))
        turns.append({'before': before, 'after': after, 'key': '5',
                      'visible_state_changed': changed})
        if number >= 2 and any(turn['visible_state_changed'] for turn in turns):
            break
    require(any(turn['visible_state_changed'] for turn in turns),
            'ordinary waits produced no observable native actor/HP/world state change')
    # Combat is opportunistic in the unseeded world. Pursue visible enemies
    # through ordinary controls, never force spawn, health, RNG or outcome.
    combat = {'attempted_keys': [], 'observed_messages': [], 'available': False}
    if role == 'Angel':
        for number in range(35):
            if not session.game():
                break
            key = enemy_direction(session.state())
            if key is None:
                break
            combat['available'] = True
            combat['attempted_keys'].append(key)
            session.action('visible-enemy-pursuit-%02d' % number, key)
            messages = [row.strip() for row in session.screen.display[-4:-1] if COMBAT.search(row)]
            combat['observed_messages'].extend(messages)
            if messages:
                break
    combat['observed_messages'] = sorted(set(combat['observed_messages']))
    combat['observed'] = bool(combat['observed_messages'])
    final = session.state() if session.game() else {'ending': session.text()}
    require(initial != final, 'native gameplay did not change meaningful state')
    require(any(turn['visible_state_changed'] for turn in turns) or
            initial['world'] != final.get('world') or initial['health'] != final.get('health') or
            any(proof['before']['map'] != proof['after']['map'] for proof in movements),
            'no native map/actor/health/world change observed')
    session.quit()
    return {'role': role, 'process': process, 'initial': initial, 'movements': movements,
            'ordinary_turns': turns, 'combat': combat, 'final': final,
            'normal_quit_exit_status': session.status}


def main():
    require(len(sys.argv) == 3, 'usage: native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    require(output.parent == Path('/gnu/store') and output.is_dir(), 'direct prebuilt store output required')
    require(evidence.is_dir() and not (evidence / 'native-result.json').exists(), 'fresh shell evidence required')
    root = evidence / 'private'
    report = {'success': False, 'source': SOURCE, 'sessions': [],
              'persistence': 'Upstream has no save/load; only CWD log.log may be written.'}
    session = None
    try:
        require(os.getpid() == 1, 'consumer is not PID 1 in private proc mount')
        report['isolation'] = namespace_proof(Path('/proc/self'))
        report['isolation']['store'] = readonly_store(evidence)
        native = output / 'libexec/cotc'
        require(native.read_bytes()[:4] == b'\x7fELF', 'native game is not ELF')
        closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
        require(str(output) in closure, 'runtime closure missing game output')
        require(not any(Path(path).name[33:].startswith(('python-', 'python-pyte-', 'python-wcwidth-'))
                        for path in closure), 'consumer-only Python tools leaked into runtime closure')
        require(not any('smoke' in path.name or 'native.py' in path.name for path in output.rglob('*')),
                'external test helper installed into game output')
        report['output'] = {'native_sha256': digest(native.read_bytes()), 'runtime_closure': closure}
        root.mkdir(mode=0o700)
        for name in ('home', 'work', 'state', 'config', 'data', 'cache', 'tmp', 'runtime'):
            (root / name).mkdir(mode=0o700)
        record(evidence / 'private-before.json', inventory(root))
        for selection, role in (('a', 'Angel'), ('b', 'Imp')):
            session = Session(output, evidence / role.lower(), root)
            report['sessions'].append(play(session, selection, role))
            session.close()
            session = None
            record(evidence / 'native-result.json', report)
        state = root / 'state' / GAME
        require(state.is_dir(), 'launcher did not create private log directory')
        require(all(path.name == 'log.log' and path.is_file() for path in state.iterdir()),
                'unexpected game persistence beyond native log.log')
        for name in ('home', 'work', 'config', 'data', 'cache', 'tmp', 'runtime'):
            require(not any((root / name).iterdir()), 'game state escaped XDG state: ' + name)
        require(list((root / 'state').iterdir()) == [state], 'unexpected state directory')
        for path in root.rglob('*'):
            require(path.stat().st_uid == os.getuid() and path.stat().st_gid == os.getgid(),
                    'native state changed ownership')
            require(path.stat().st_mode & 0o077 == 0, 'private state accessible to other users')
        if (state / 'log.log').exists():
            data = (state / 'log.log').read_bytes()
            (evidence / 'native-log.log').write_bytes(data)
            require(not ERRORS.search(data.decode('utf-8', errors='replace')), 'native log reports error')
            report['log'] = {'present': True, 'size': len(data), 'sha256': digest(data)}
        else:
            report['log'] = {'present': False, 'reason': 'Logging is dormant in ordinary upstream gameplay.'}
        report['success'] = True
    except BaseException as error:
        report['error'] = repr(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        raise
    finally:
        if session is not None:
            session.snapshot('failure-last-frame')
            session.close()
        if root.exists():
            record(evidence / 'private-after.json', inventory(root))
            # Retain every native file before deleting only this task's house.
            for path in root.rglob('*'):
                if path.is_file():
                    target = evidence / 'retained-state' / path.relative_to(root)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(path, target)
            shutil.rmtree(root)
        record(evidence / 'cleanup.json', {'private_path': str(root), 'removed': not root.exists(),
                                         'evidence_retained': True,
                                         'failed_children': 'private PID namespace teardown; never accepted as quit'})
        record(evidence / 'native-result.json', report)
    print('CITY_OF_THE_CONDEMNED_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
