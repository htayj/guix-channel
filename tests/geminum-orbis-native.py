#!/usr/bin/env python3
"""External, unseeded Geminum Orbis consumer: PTY bytes and rendered cells only.

No game imports, source-copy checks, memory reads, injected saves/configuration,
or instrumentation. PNGs rasterize the captured terminal, not a model of the map.
"""
from collections import deque
import codecs
import ctypes
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import socket
import stat
import struct
import subprocess
import sys
import termios
import time
import traceback

import pyte
from PIL import Image, ImageDraw, ImageFont

COLS, ROWS = 80, 25
NAME = 'OrbisQA'
DIRECTIONS = [('8', 0, -1), ('6', 1, 0), ('2', 0, 1), ('4', -1, 0)]
ERRORS = re.compile(r'segmentation fault|permission denied|no such file|traceback|'
                    r'couldn.t (?:open|load)|cannot (?:open|load)|failed to|'
                    r'assertion .* failed|terminate called|fatal error|'
                    r'symbol lookup error|error opening terminal|Geminum Orbis:', re.I)
PALETTE = {'black': '#000000', 'red': '#cd0000', 'green': '#00cd00',
           'brown': '#cdcd00', 'yellow': '#ffff00', 'blue': '#0000ee',
           'magenta': '#cd00cd', 'cyan': '#00cdcd', 'white': '#e5e5e5',
           'brightblack': '#7f7f7f', 'brightred': '#ff0000',
           'brightgreen': '#00ff00', 'brightblue': '#5c5cff',
           'brightmagenta': '#ff00ff', 'brightcyan': '#00ffff',
           'brightwhite': '#ffffff'}


def require(value, message):
    if not value:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def namespaces(proc):
    result = {'namespaces': {}, 'files': {}}
    for kind, host in [('user', 'USER'), ('mnt', 'MOUNT'), ('net', 'NET'), ('pid', 'PID')]:
        actual = os.readlink(proc / 'ns' / kind)
        require(actual != os.environ['HOST_' + host + '_NS'], 'host namespace leaked: ' + kind)
        require(actual == os.readlink('/proc/self/ns/' + kind), 'child namespace escape: ' + kind)
        result['namespaces'][kind] = actual
    for name in ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route'):
        result['files'][name] = (proc / name).read_text()
    for label, field in [('UID', 'Uid'), ('GID', 'Gid')]:
        number = int(os.environ['HOST_' + label])
        match = re.search(r'^' + field + r':\s*(.+)$', result['files']['status'], re.M)
        require(number != 0 and match and list(map(int, match[1].split())) == [number] * 4,
                'not same ordinary caller ' + field)
        require(list(map(int, result['files'][label.lower() + '_map'].split())) ==
                [number, number, 1], 'identity is not map-current-user')
    interfaces = [line.split(':')[0].strip() for line in result['files']['net/dev'].splitlines()[2:]
                  if ':' in line]
    require(interfaces == ['lo'], 'non-loopback network interface present')
    require(len(result['files']['net/route'].splitlines()) <= 1, 'IPv4 route present')
    require(all(line.split()[-1] == 'lo' for line in result['files']['net/ipv6_route'].splitlines()
                if line.strip()), 'external IPv6 route present')
    result['interfaces'] = interfaces
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as connection:
        request = fcntl.ioctl(connection.fileno(), 0x8913, struct.pack('256s', b'lo'))
    flags = struct.unpack_from('H', request, 16)[0]
    result['loopback_flags'] = flags
    require(not flags & 1, 'private loopback unexpectedly enabled')
    return result


def mount(source, target, flags=0, filesystem=None, data=None):
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_char_p]
    libc.mount.restype = ctypes.c_int
    encode = lambda value: None if value is None else os.fsencode(value)
    if libc.mount(encode(source), encode(target), encode(filesystem), flags, encode(data)):
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number), str(target))


def store_entries():
    text, entries = Path('/proc/self/mountinfo').read_text(), []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in [('\\040', ' '), ('\\011', '\t'), ('\\012', '\n'), ('\\134', '\\')]:
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            entries.append({'target': target, 'options': fields[5].split(','),
                            'optional': fields[6:fields.index('-')]})
    return text, entries


def isolate(evidence):
    (evidence / 'mountinfo-before.txt').write_text(store_entries()[0])
    mount('/gnu/store', '/gnu/store', 4096 | 16384)
    mount('/gnu/store', '/gnu/store', 262144 | 16384)
    for target in sorted({entry['target'] for entry in store_entries()[1]}, key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)
    text, entries = store_entries()
    require(entries and any(entry['target'] == '/gnu/store' for entry in entries), 'store bind absent')
    require(all('ro' in entry['options'] and 'rw' not in entry['options'] and not
                any(value.startswith(('shared:', 'master:')) for value in entry['optional'])
                for entry in entries), 'store is not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store statvfs not read-only')
    (evidence / 'mountinfo-store-readonly.txt').write_text(text)
    probe = '/gnu/store/.geminum-consumer-write-probe-' + str(os.getpid())
    try:
        fd = os.open(probe, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except OSError as error:
        record(evidence / 'store-write-probe.json', {'path': probe, 'errno': error.errno,
                                                    'error': str(error), 'failed': True})
        require(error.errno == errno.EROFS, 'write probe did not fail with EROFS')
    else:
        os.close(fd)
        os.unlink(probe)
        raise RuntimeError('store write probe unexpectedly succeeded')
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
        mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=0755')
        retained = Path('/tmp/geminum-evidence')
        retained.mkdir(mode=0o700)
        mount('/proc/self/fd/' + str(descriptor), retained, 4096)
    finally:
        os.close(descriptor)
    (retained / 'mountinfo-private.txt').write_text(Path('/proc/self/mountinfo').read_text())
    return retained, entries


def inventory(root):
    result = {}
    for path in sorted(root.rglob('*')):
        info = path.lstat()
        item = {'uid': info.st_uid, 'gid': info.st_gid, 'mode': stat.S_IMODE(info.st_mode)}
        if path.is_symlink():
            item.update(type='symlink', target=os.readlink(path))
        elif path.is_dir():
            item['type'] = 'directory'
        elif path.is_file():
            data = path.read_bytes()
            item.update(type='file', bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
        else:
            item['type'] = 'other'
        result[str(path.relative_to(root))] = item
    return result


def drop_capabilities():
    """Keep namespace setup privileged, then irreversibly deprivilege the child."""
    libc = ctypes.CDLL(None, use_errno=True)
    libc.prctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong,
                           ctypes.c_ulong, ctypes.c_ulong]
    libc.prctl.restype = ctypes.c_int

    def prctl(option, argument=0, argument2=0):
        value = libc.prctl(option, argument, argument2, 0, 0)
        if value < 0:
            number = ctypes.get_errno()
            raise OSError(number, os.strerror(number))
        return value

    # PR_CAPBSET_READ/DROP: enumerate the kernel's actual capability range.
    capability = 0
    while libc.prctl(23, capability, 0, 0, 0) >= 0:
        prctl(24, capability)
        capability += 1
    require(ctypes.get_errno() == errno.EINVAL and capability > 0,
            'cannot enumerate capability bounding set')
    prctl(47, 4)  # PR_CAP_AMBIENT, PR_CAP_AMBIENT_CLEAR_ALL
    prctl(38, 1)  # PR_SET_NO_NEW_PRIVS

    class Header(ctypes.Structure):
        _fields_ = [('version', ctypes.c_uint32), ('pid', ctypes.c_int)]

    class Data(ctypes.Structure):
        _fields_ = [('effective', ctypes.c_uint32), ('permitted', ctypes.c_uint32),
                    ('inheritable', ctypes.c_uint32)]

    # _LINUX_CAPABILITY_VERSION_3 uses two 32-bit data words.
    header, data = Header(0x20080522, 0), (Data * 2)()
    libc.capset.argtypes = [ctypes.POINTER(Header), ctypes.POINTER(Data)]
    libc.capset.restype = ctypes.c_int
    if libc.capset(ctypes.byref(header), data):
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number))


def child_terminal():
    os.setsid()
    fcntl.ioctl(0, termios.TIOCSCTTY, 0)
    drop_capabilities()


class Session:
    def __init__(self, output, evidence, root, font):
        self.evidence, self.root = evidence, root
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        # Bytes are UTF-8-decoded separately below. Unlike the Linux console,
        # xterm honors DEC G0/G1 designations inside UTF-8 sessions. pyte's
        # default use_utf8=True skips ESC ( 0, leaving ACS_BULLET '~' and
        # ACS_CKBOARD 'a' unrendered. Enable its actual charset machinery.
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.font = ImageFont.truetype(str(font), 16)
        self.raw = (evidence / 'terminal.raw').open('wb', buffering=0)
        self.events = (evidence / 'terminal-events.jsonl').open('w', buffering=1)
        self.offset = self.number = self.moves = 0
        self.eof = False
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
        self.env = {'PATH': '', 'HOME': str(root / 'home'), 'TERM': 'xterm-256color',
                    'LC_ALL': 'C.UTF-8', 'LANG': 'C.UTF-8', 'TMPDIR': str(root / 'tmp'),
                    'XDG_CONFIG_HOME': str(root / 'config'), 'XDG_DATA_HOME': str(root / 'data'),
                    'XDG_STATE_HOME': str(root / 'state'), 'XDG_CACHE_HOME': str(root / 'cache'),
                    'XDG_RUNTIME_DIR': str(root / 'runtime')}
        argv = [str(output / 'bin/geminum-orbis')]
        record(evidence / 'game-launch.json', {'argv': argv,
               'environment': self.env, 'cwd': str(root / 'work'), 'rows': ROWS, 'columns': COLS})
        try:
            self.process = subprocess.Popen(argv,
                stdin=slave, stdout=slave, stderr=slave, env=self.env, cwd=root / 'work',
                close_fds=True, preexec_fn=child_terminal)
        finally:
            os.close(slave)

    def pump(self, duration=0.12):
        deadline = time.monotonic() + duration
        while not self.eof and time.monotonic() < deadline:
            ready, _, _ = select.select([self.master], [], [], max(0, deadline - time.monotonic()))
            if not ready:
                break
            try:
                data = os.read(self.master, 65536)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise
                data = b''
            if not data:
                self.eof = True
                break
            self.raw.write(data)
            self.offset += len(data)
            self.stream.feed(self.decoder.decode(data))

    def text(self):
        return '\n'.join(self.screen.display)

    def wait(self, predicate, label, timeout=10):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            self.pump()
            try:
                ready = predicate()
            except RuntimeError:
                # Curses may be observed between erase() and its status redraw.
                ready = False
            if ready:
                self.pump(0.08)
                self.capture(label, image=(label != 'move'))
                return
            require(self.process.poll() is None, 'game exited while waiting for ' + label)
        self.capture('timeout-' + label)
        raise RuntimeError('timeout waiting for ' + label)

    def send(self, text):
        require(self.process.poll() is None, 'input after game exit')
        self.events.write(json.dumps({'input': text, 'raw_offset_before': self.offset,
                                     'time_monotonic': time.monotonic()}) + '\n')
        pending = memoryview(text.encode('utf-8'))
        while pending:
            pending = pending[os.write(self.master, pending):]
        self.pump()

    def capture(self, label, image=True):
        self.number += 1
        stem = f'{self.number:04d}-{label}'
        (self.evidence / (stem + '.txt')).write_text(self.text() + '\n')
        cells = [[self.screen.buffer[y][x]._asdict() for x in range(COLS)] for y in range(ROWS)]
        record(self.evidence / (stem + '.cells.json'), cells)
        self.events.write(json.dumps({'screen': stem, 'raw_offset': self.offset}) + '\n')
        if image:
            picture = Image.new('RGB', (COLS * 10, ROWS * 20), 'black')
            draw = ImageDraw.Draw(picture)
            for y, row in enumerate(cells):
                for x, cell in enumerate(row):
                    fg = self.color(cell['fg'], '#e5e5e5', cell['bold'])
                    bg = self.color(cell['bg'], '#000000', False)
                    if cell['reverse']:
                        fg, bg = bg, fg
                    draw.rectangle((x * 10, y * 20, x * 10 + 9, y * 20 + 19), fill=bg)
                    if not cell.get('hidden', False):
                        draw.text((x * 10, y * 20), cell['data'], font=self.font, fill=fg)
                    if cell['underscore']:
                        draw.line((x * 10, y * 20 + 18, x * 10 + 9, y * 20 + 18), fill=fg)
            picture.save(self.evidence / (stem + '.png'))
        return stem

    @staticmethod
    def color(value, default, bold):
        if value == 'default':
            return '#ffffff' if bold and default != '#000000' else default
        if bold and 'bright' + value in PALETTE:
            value = 'bright' + value
        return PALETTE.get(value, '#' + value if re.fullmatch('[0-9a-fA-F]{6}', value) else default)

    def observation(self):
        rows = self.screen.display
        players = [(x, y) for y in range(1, 22) for x in range(COLS) if rows[y][x] == '@']
        require(len(players) == 1, 'expected exactly one observed player @')
        status = '\n'.join(rows[23:25])
        require(NAME in status and re.search(r'Dlvl:\d+.*HP:\d+\(\d+\)', status),
                'native name/HP/dungeon status missing')
        level = int(re.search(r'Dlvl:(\d+)', status)[1])
        turn = re.search(r'\bT:(\d+)', status)
        return {'position': players[0], 'level': level, 'turn': int(turn[1]) if turn else None,
                'status': status, 'message': rows[0]}

    def terrain(self, point):
        x, y = point
        if not (0 < x < COLS - 1 and 1 < y < 21):
            return 'boundary'
        cell = self.screen.buffer[y][x]
        glyph = cell.data
        if glyph == '+':
            return 'closed'
        # ACS_BLOCK is used for both walls and open doors; color is observable.
        if glyph in ('#', '█', '▮', '■') and cell.fg in ('brown', 'yellow', 'cdcd00', 'ffff00'):
            return 'open'
        if glyph in ('.', '·', '∙', '•', 'o', ':', '▒', '░', '±', '{', '⌠', '<', '>', '@'):
            return 'floor'
        return 'blocked'

    def route(self, target, doors=True):
        start = self.observation()['position']
        queue, previous = deque([start]), {start: None}
        while queue:
            point = queue.popleft()
            if target(point):
                path = []
                while previous[point] is not None:
                    parent, key = previous[point]
                    path.append((key, point))
                    point = parent
                return list(reversed(path))
            for key, dx, dy in DIRECTIONS:
                neighbor = (point[0] + dx, point[1] + dy)
                if neighbor not in previous and self.terrain(neighbor) in (
                        ('floor', 'open', 'closed') if doors else ('floor', 'open')):
                    previous[neighbor] = (point, key)
                    queue.append(neighbor)
        return None

    def step(self, key, expected):
        require(self.moves < 2200, 'observed navigation input bound exceeded')
        if self.terrain(expected) == 'closed':
            self.open_door(key, expected)
        before = self.observation()
        self.send(key)
        self.wait(lambda: self.observation()['position'] == expected, 'move', timeout=3)
        after = self.observation()
        require(before['position'] != after['position'], 'movement did not change actual @ position')
        require(before['level'] == after['level'], 'ordinary movement changed dungeon level')
        self.moves += 1
        self.events.write(json.dumps({'movement': self.moves, 'before': before, 'after': after}) + '\n')
        return after

    def walk(self, route):
        require(route is not None and len(route) <= 250, 'no bounded observed route')
        for key, point in route:
            self.step(key, point)

    def open_door(self, key, point):
        for attempt in range(20):
            self.send('o')
            self.wait(lambda: 'In what direction?' in self.text(), 'open-direction')
            self.send(key)
            self.wait(lambda: 'door opens' in self.text() or 'door resists' in self.text(),
                      'door-open-attempt')
            if 'door opens' in self.text():
                require(self.terrain(point) == 'open', 'open message without observed open door')
                return
        raise RuntimeError('door resisted all 20 bounded native attempts')

    def stop(self):
        errors = []
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(timeout=3)
            errors.append('game required forced cleanup')
        self.pump(0.1)
        record(self.evidence / 'game-exit.json', {'returncode': self.process.returncode,
                                                'forced_cleanup': bool(errors)})
        self.raw.close()
        self.events.close()
        os.close(self.master)
        return errors


def static_template_observation(session, output, label):
    """Compare actual terminal terrain with immutable native map data, never inject it."""
    observation = session.observation()
    player = observation['position']
    candidates = []
    for name in ('sdlvl_starta.txt', 'sdlvl_startb.txt'):
        path = output / 'share/geminum-orbis/levels' / name
        data = path.read_bytes()
        rows = data.decode('ascii').splitlines()[:21]
        require(len(rows) == 21 and all(len(row) == COLS for row in rows),
                'immutable native map has invalid 80x21 geometry')
        mismatches = []
        features = {'upstairs': [], 'downstairs': [], 'fountains': [], 'doors': []}
        for y, row in enumerate(rows, 1):
            for x, expected in enumerate(row):
                cell = session.screen.buffer[y][x]
                if expected in '<>{+':
                    feature = {'<': 'upstairs', '>': 'downstairs', '{': 'fountains', '+': 'doors'}[expected]
                    features[feature].append([x, y])
                if (x, y) == player:
                    matched = cell.data == '@' and expected in '.<>'
                elif expected in '-_':
                    matched = cell.data in ('#', '█', '▮') and session.terrain((x, y)) != 'open'
                elif expected == '.':
                    matched = cell.data in ('.', '·', '∙', '•', 'o')
                elif expected == '+':
                    matched = cell.data == '+' or session.terrain((x, y)) == 'open'
                elif expected == '{':
                    matched = cell.data == '{' and cell.fg in ('blue', '0000ee', '0000ff')
                else:
                    matched = cell.data == expected
                if not matched:
                    mismatches.append({'x': x, 'y': y, 'expected': expected,
                                       'actual': cell.data, 'foreground': cell.fg})
        candidates.append({'template': name, 'sha256': hashlib.sha256(data).hexdigest(),
                           'features': features, 'mismatch_count': len(mismatches),
                           'first_mismatches': mismatches[:40]})
    result = {'observation': observation, 'compared_cells_per_template': COLS * 21,
              'candidates': candidates, 'matching_templates': [item['template'] for item in candidates
                                                             if not item['mismatch_count']]}
    record(session.evidence / (label + '.json'), result)
    session.capture(label)
    require(result['matching_templates'], 'displayed static map differs from both original templates')
    return result


def descend_observed(session):
    route = session.route(lambda p: session.screen.buffer[p[1]][p[0]].data == '>')
    require(route is not None, 'no bounded reachable observed downstairs')
    session.walk(route)
    before = session.observation()
    session.send('>')
    session.wait(lambda: session.observation()['level'] == before['level'] + 1,
                 'descended-to-level-' + str(before['level'] + 1), timeout=20)
    return {'before': before, 'after': session.observation()}


def ascend_observed(session):
    route = session.route(lambda p: session.screen.buffer[p[1]][p[0]].data == '<')
    if route is not None:
        session.walk(route)
    # Immediately after descent the actual upstairs is covered by @; otherwise
    # the route above must lead to a visible upstairs. Success is the real HUD.
    before = session.observation()
    session.send('<')
    session.wait(lambda: session.observation()['level'] == before['level'] - 1,
                 'ascended-to-level-' + str(before['level'] - 1))
    return {'before': before, 'after': session.observation()}


def play(session, output):
    session.wait(lambda: 'What is your name?' in session.text(), 'name-prompt')
    proc = Path('/proc') / str(session.process.pid)
    process_proof = namespaces(proc)
    process_proof['exe'] = os.readlink(proc / 'exe')
    process_proof['cmdline'] = (proc / 'cmdline').read_bytes().decode().split('\0')
    process_proof['environment'] = (proc / 'environ').read_bytes().decode().split('\0')
    process_proof['stdio'] = [os.readlink(proc / 'fd' / str(fd)) for fd in (0, 1, 2)]
    process_proof['cwd'] = os.readlink(proc / 'cwd')
    process_proof['mountinfo'] = (proc / 'mountinfo').read_text()
    record(session.evidence / 'game-process.json', process_proof)
    native_env = dict(entry.split('=', 1) for entry in process_proof['environment'] if '=' in entry)
    require(all(native_env.get(key) == value for key, value in session.env.items()),
            'game did not retain clean HOME/XDG/empty PATH environment')
    require(not any(key.startswith(('HOST_', 'PYTHON')) for key in native_env),
            'harness environment leaked into native game')
    require(all(value.startswith('/dev/pts/') for value in process_proof['stdio']), 'game lacks real PTY')
    for field in ('CapInh', 'CapPrm', 'CapEff', 'CapBnd', 'CapAmb'):
        require(re.search(r'^' + field + r':\s*0+$', process_proof['files']['status'], re.M),
                'native game retained namespace capabilities: ' + field)
    require(re.search(r'^NoNewPrivs:\s*1$', process_proof['files']['status'], re.M),
            'native game lacks no_new_privs')
    session.send(NAME + '\n')
    session.wait(lambda: 'what gender will you be?' in session.text(), 'gender-prompt')
    session.send('m')
    session.wait(lambda: 'Press any key to continue' in session.text() and
                 'grandparents' in session.text(), 'generated-family')
    require(NAME in session.text(), 'generated family lacks chosen character name')
    session.send(' ')
    session.wait(lambda: NAME in session.text() and 'Dlvl:' in session.text() and
                 '@' in '\n'.join(session.screen.display[1:22]), 'initial-map')
    initial = session.observation()
    # The spawn overlays an upstairs. We learn terrain only by leaving it.
    visits = {}
    positions = [initial['position']]
    for _ in range(7):
        point = session.observation()['position']
        options = [(visits.get((point[0] + dx, point[1] + dy), 0), key,
                    (point[0] + dx, point[1] + dy)) for key, dx, dy in DIRECTIONS
                   if session.terrain((point[0] + dx, point[1] + dy)) in ('floor', 'open')]
        require(options, 'no legal observed movement from initial room')
        _, key, neighbor = min(options)
        visits[point] = visits.get(point, 0) + 1
        positions.append(session.step(key, neighbor)['position'])
    require(len(set(positions)) >= 3, 'several turns did not visit distinct observed cells')
    after_movement = session.observation()
    require(after_movement['position'] != initial['position'], 'final movement returned to initial position')
    # Exercise a genuinely reachable door: no wall probing or model-state edits.
    def adjacent_closed(point):
        return any(session.terrain((point[0] + dx, point[1] + dy)) == 'closed'
                   for _, dx, dy in DIRECTIONS)
    door_route = session.route(adjacent_closed)
    require(door_route is not None, 'no reachable observed closed door')
    session.walk(door_route)
    position = session.observation()['position']
    key, dx, dy = next(direction for direction in DIRECTIONS if
                      session.terrain((position[0] + direction[1], position[1] + direction[2])) == 'closed')
    door = (position[0] + dx, position[1] + dy)
    session.open_door(key, door)
    session.send('c')
    session.wait(lambda: 'In what direction?' in session.text(), 'close-direction')
    session.send(key)
    session.wait(lambda: 'door closes' in session.text(), 'door-closed')
    require(session.terrain(door) == 'closed', 'close message without observed closed door')
    session.open_door(key, door)
    # Cancel an ordinary direction request, then observe that play can continue.
    session.send('o')
    session.wait(lambda: 'In what direction?' in session.text(), 'cancel-direction')
    session.send(' ')
    session.wait(lambda: 'Never mind.' in session.text(), 'direction-cancelled')
    journey = []
    static_map = None
    # static_start is unseeded 3..7 (internal), i.e. displayed levels 4..8.
    # Procedural levels have no fountains; identify the actual static screen,
    # then check every cell rather than trusting a depth or a marker alone.
    for _ in range(7):
        journey.append(descend_observed(session))
        if any(session.screen.buffer[y][x].data == '{'
               for y in range(1, 22) for x in range(COLS)):
            static_map = static_template_observation(session, output, 'static-template-arrival')
            break
    require(static_map is not None, 'no actual static template reached by displayed level 8')
    require(4 <= session.observation()['level'] <= 8, 'static template outside native random depth range')
    beyond_static = descend_observed(session)
    return_static = ascend_observed(session)
    revisited_static = static_template_observation(session, output, 'static-template-revisited')
    require(static_map['matching_templates'] == revisited_static['matching_templates'],
            'returning stairs changed the actual static template')
    return_prior = ascend_observed(session)
    before_stairs = journey[0]['before']
    descended = journey[0]['after']
    ascended = session.observation()
    session.send('Q')
    session.wait(lambda: 'Are you sure you want to leave?' in session.text(), 'quit-cancel-prompt')
    session.send('n')
    session.wait(lambda: 'Nevermind.' in session.text(), 'quit-cancelled')
    require(session.process.poll() is None, 'Q n exited instead of cancelling')
    require(session.observation()['position'] == ascended['position'], 'quit cancel moved character')
    session.send('Q')
    session.wait(lambda: 'Are you sure you want to leave?' in session.text(), 'quit-confirm-prompt')
    session.send('y')
    session.wait(lambda: 'Save game?' in session.text() or 'Goodbye ' in session.text(), 'quit-confirmed')
    if 'Save game?' in session.text():
        # r59 save is explicitly unimplemented. Decline this native nested prompt.
        session.send('n')
        session.wait(lambda: 'Goodbye ' in session.text(), 'goodbye')
    require(NAME in session.text() and 'Press any key to end' in session.text(), 'native goodbye missing')
    session.send(' ')
    session.process.wait(timeout=5)
    session.pump()
    session.capture('exited')
    require(session.process.returncode == 0, 'ordinary native exit was nonzero')
    return {'initial': initial, 'after_movement': after_movement, 'positions': positions,
            'verified_movements': session.moves, 'door': door, 'before_stairs': before_stairs,
            'descended': descended, 'ascended': ascended, 'quit_cancelled': True,
            'level_journey': journey, 'static_template': static_map,
            'beyond_static': beyond_static, 'return_static': return_static,
            'revisited_static': revisited_static, 'return_prior': return_prior,
            'ordinary_exit': session.process.returncode,
            'turn_counter': {'initial': initial['turn'], 'after_movement': after_movement['turn'],
                             'changed': initial['turn'] != after_movement['turn'],
                             'claim': 'Displayed T is observed; r59 does not increment it.'}}


def main():
    require(len(sys.argv) == 4, 'usage: native.py OUTPUT EVIDENCE FONT')
    output, evidence, font = map(Path, sys.argv[1:])
    require(output.parent == Path('/gnu/store') and output.is_dir(), 'canonical store item required')
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc/self/fd/' + str(descriptor))
    proof = {'success': False, 'output': str(output), 'injected_seed_config_save': False,
             'screenshot_method': 'Pillow rendering of actual pyte terminal cells from retained PTY bytes',
             'font_sha256': hashlib.sha256(font.read_bytes()).hexdigest(),
             'claim_limits': ['Unseeded character/family creation, movement, doors, stairs and ordinary quit.',
                              'No implemented save/load, combat or full-game completion is claimed.']}
    session = root = None
    failure = None
    cleanup_errors = []
    try:
        require(os.getpid() == 1, 'driver not PID1 in private mounted proc')
        proof['driver_namespace'] = namespaces(Path('/proc/self'))
        evidence, mounts = isolate(evidence)
        proof['read_only_store_mounts'] = mounts
        closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
        tools = json.loads((evidence / 'consumer-tools.json').read_text())
        leaks = {name: tools[name] for name in ('python', 'pyte', 'wcwidth', 'pillow', 'font')
                 if tools[name] in closure}
        require(str(output) in closure and not leaks, 'consumer-only tools leaked into game closure')
        proof['runtime_closure'] = closure
        proof['consumer_outputs'] = tools
        root = evidence / 'scratch'
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'state', 'cache', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        record(evidence / 'private-before.json', inventory(root))
        session = Session(output, evidence, root, font)
        proof['gameplay'] = play(session, output)
        require(not list((root / 'work').iterdir()), 'game wrote into caller working directory')
        require(not list((root / 'config').iterdir()), 'game unexpectedly generated configuration')
        proof['success'] = True
    except BaseException as error:
        failure = error
        proof['error'] = repr(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        if session is not None:
            session.capture('failure')
    finally:
        if session is not None:
            cleanup_errors.extend(session.stop())
        if root is not None and root.exists():
            record(evidence / 'private-after.json', inventory(root))
            for path in root.rglob('*'):
                if path.is_file() and not path.is_symlink():
                    target = evidence / 'native-generated-files' / path.relative_to(root)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(path, target)
        raw_path = evidence / 'terminal.raw'
        if raw_path.exists():
            text = raw_path.read_bytes().decode('utf-8', errors='replace')
            matches = sorted(set(match.group() for match in ERRORS.finditer(text)))
            proof['native_error_matches'] = matches
            if matches:
                cleanup_errors.append('native error retained in terminal.raw')
        if cleanup_errors:
            proof['success'] = False
            proof['cleanup_errors'] = cleanup_errors
        record(evidence / 'native-result.json', proof)
        os.close(descriptor)
    require(proof['success'] and failure is None, 'native consumer failed: ' + repr(failure or cleanup_errors))
    print('GEMINUM_ORBIS_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
