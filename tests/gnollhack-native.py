#!/usr/bin/env python3
"""External consumer of upstream GnollHack's ordinary tty and curses ports.

Fresh HOME/XDG roots contain no rc, injected save, RNG seed, or wizard flags.
All game state is observed through the native UI; this driver is not installed.
Source anchors below refer to commit 10c2529b38ee457e8d015f8e1561039ab4d4bf2e.
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
import signal
import struct
import sys
import termios
import time
import traceback

import pyte

ROWS, COLS = 40, 120
NAME = 'NativeGnoll'
REVISION = '10c2529b38ee457e8d015f8e1561039ab4d4bf2e'
SOURCE_ANCHORS = {
    'cli': 'sys/unix/unixmain.c:418-464 (-u NAME; -wtty/-wcurses)',
    'selection': 'win/tty/wintty.c:517-1067; win/curses/cursinit.c:456-817',
    'difficulty': 'src/allmain.c:1370-1447 (ordinary Standard difficulty menu)',
    'time_option': 'src/options.c:300,6041-6084,6143-6207 (in-game O toggle)',
    'status': 'src/botl.c:943-975 (HP, MP, DL/Dlvl, T native status fields)',
    'save': 'src/cmd.c:6584 (M-s/#save); src/save.c:89-155 (confirmation and exit)',
    'restore': 'sys/unix/unixmain.c:287-315 (automatic native same-name restore)',
    'menu': 'include/wintype.h:181-191; win/curses/cursdial.c:1203-1241,1409-1423',
}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def mount(source, target, flags, filesystem=None, data=None):
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_char_p]
    libc.mount.restype = ctypes.c_int
    encode = lambda value: None if value is None else os.fsencode(value)
    if libc.mount(encode(source), encode(target), encode(filesystem), flags, encode(data)):
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number), str(target))


def namespace_proof(pid):
    proc = Path('/proc') / str(pid)
    host = {kind: os.environ['HOST_' + name + '_NS'] for kind, name in
            [('user', 'USER'), ('mnt', 'MOUNT'), ('net', 'NET'), ('pid', 'PID')]}
    actual = {kind: os.readlink(proc / 'ns' / kind) for kind in host}
    for kind in host:
        require(actual[kind] != host[kind], 'host namespace leaked: ' + kind)
        require(actual[kind] == os.readlink('/proc/self/ns/' + kind), 'namespace escaped: ' + kind)
    files = {name: (proc / name).read_text() for name in
             ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route')}
    for kind, label in [('uid', 'Uid'), ('gid', 'Gid')]:
        identity = int(os.environ['HOST_' + kind.upper()])
        values = re.search(r'^' + label + r':\s*(.+)$', files['status'], re.M)
        require(identity != 0 and values and list(map(int, values[1].split())) == [identity] * 4,
                'not same ordinary identity: ' + kind)
        require(list(map(int, files[kind + '_map'].split())) == [identity, identity, 1],
                'not map-current-user: ' + kind)
    interfaces = [line.split(':')[0].strip() for line in files['net/dev'].splitlines() if ':' in line]
    require(interfaces == ['lo'], 'external network interface exists')
    require(len(files['net/route'].splitlines()) <= 1, 'IPv4 route exists')
    require(all(row.split()[-1] == 'lo' for row in files['net/ipv6_route'].splitlines() if row.strip()),
            'external IPv6 route exists')
    return {'namespaces': actual, 'host_namespaces': host, 'files': files}


def isolate(evidence):
    require(os.getpid() == 1, 'driver must be private PID1')
    proof = namespace_proof('self')
    mount('/gnu/store', '/gnu/store', 4096 | 16384)
    mount(None, '/gnu/store', 262144 | 16384)

    def store_mounts():
        entries = []
        for line in Path('/proc/self/mountinfo').read_text().splitlines():
            fields = line.split()
            if fields[4] == '/gnu/store' or fields[4].startswith('/gnu/store/'):
                entries.append((fields[4], fields[5].split(','), fields[6:fields.index('-')]))
        return entries

    for target, _, _ in sorted(store_mounts(), key=lambda entry: len(entry[0]), reverse=True):
        mount(target, target, 4096 | 32 | 1)
    entries = store_mounts()
    require(entries and all('ro' in options and 'rw' not in options and not
                           any(value.startswith(('shared:', 'master:')) for value in optional)
                           for _, options, optional in entries), 'store not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store writable')
    fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
        mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=0755')
        retained = Path('/tmp/gnollhack-evidence')
        retained.mkdir(mode=0o700)
        mount('/proc/self/fd/' + str(fd), retained, 4096)
    finally:
        os.close(fd)
    for path in ('/home', '/root'):
        if Path(path).is_dir():
            mount('tmpfs', path, 2 | 4, 'tmpfs', 'mode=0755')
    (retained / 'mountinfo-isolated.txt').write_text(Path('/proc/self/mountinfo').read_text())
    proof['store_mounts'] = entries
    return retained, proof


def drop_capabilities():
    libc = ctypes.CDLL(None, use_errno=True)
    libc.prctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong,
                           ctypes.c_ulong, ctypes.c_ulong]
    libc.prctl.restype = ctypes.c_int

    def prctl(option, argument=0):
        if libc.prctl(option, argument, 0, 0, 0) < 0:
            number = ctypes.get_errno()
            raise OSError(number, os.strerror(number))

    capability = 0
    while libc.prctl(23, capability, 0, 0, 0) >= 0:
        prctl(24, capability)
        capability += 1
    require(ctypes.get_errno() == errno.EINVAL and capability > 0, 'capability enumeration failed')
    prctl(47, 4)  # PR_CAP_AMBIENT_CLEAR_ALL
    prctl(38, 1)  # PR_SET_NO_NEW_PRIVS

    class Header(ctypes.Structure):
        _fields_ = [('version', ctypes.c_uint32), ('pid', ctypes.c_int)]

    class Data(ctypes.Structure):
        _fields_ = [('effective', ctypes.c_uint32), ('permitted', ctypes.c_uint32),
                    ('inheritable', ctypes.c_uint32)]

    header, data = Header(0x20080522, 0), (Data * 2)()
    libc.capset.argtypes = [ctypes.POINTER(Header), ctypes.POINTER(Data)]
    libc.capset.restype = ctypes.c_int
    if libc.capset(ctypes.byref(header), data):
        raise OSError(ctypes.get_errno(), 'capset failed')


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
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, output, environment, root, evidence, mode, number):
        self.output, self.root, self.evidence, self.mode = output, root, evidence, mode
        self.label = mode + '-' + str(number)
        self.raw_file = (evidence / (self.label + '.raw')).open('xb')
        self.raw, self.inputs = bytearray(), []
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        # xterm honors DEC G0/G1 designations even in UTF-8 sessions;
        # decode bytes separately so pyte does not skip ESC ( 0 graphics.
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.status, self.eof = None, False
        self.deadline = time.monotonic() + 150
        self.argv = [str(output / 'bin/gnollhack'), '-w' + mode, '-u' + NAME]
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                drop_capabilities()
                os.execve(self.argv[0], self.argv, environment)
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
        require(len(self.raw) < 16000000, 'excessive PTY output')
        return True

    def send(self, keys, reason):
        require(not self.exited(), self.label + ': process already exited')
        self.inputs.append({'raw_output_offset': len(self.raw), 'keys': keys, 'reason': reason})
        record(self.evidence / (self.label + '-inputs.json'), self.inputs)
        data = keys.encode('ascii')
        require(os.write(self.fd, data) == len(data), 'partial PTY input write')

    def settle(self):
        while self.read(0.2):
            pass

    def snapshot(self, label):
        stem = self.label + '-' + label
        (self.evidence / (stem + '.screen.txt')).write_text(self.text() + '\n')
        record(self.evidence / (stem + '-cursor.json'),
               {'column': self.screen.cursor.x, 'row': self.screen.cursor.y,
                'raw_output_offset': len(self.raw)})

    def more(self):
        # cursmesg.c:235-298 renders bare >> immediately before its input
        # cursor (not the source comment's descriptive "More>>" spelling).
        x, y = self.screen.cursor.x, self.screen.cursor.y
        curses_more = (self.mode == 'curses' and x >= 2 and
                       self.screen.display[y][x - 2:x] == '>>')
        if curses_more or re.search(r'--More--|More>>|\(more\)', self.text(), re.I):
            self.send(' ', 'acknowledge native message pagination')
            self.settle()
            return True
        return False

    def wait(self, predicate, description, more=True):
        end = time.monotonic() + 25
        while True:
            self.read()
            if more and self.more():
                continue
            if predicate():
                self.settle()
                if predicate():
                    return
            require(not self.exited(), description + ': exited\n' + self.text())
            require(time.monotonic() < end, description + ': timed out\n' + self.text())

    def search_menu(self, text):
        self.send(':', 'native menu substring search')
        self.wait(lambda: 'Search for:' in self.text(), 'native menu search prompt', more=False)
        self.send(text + '\n', 'select native ' + text + ' entry')
        self.settle()

    def enter(self, restored):
        choices = set()
        end = time.monotonic() + 60
        while True:
            self.settle()
            text = self.text()
            if self.more():
                continue
            # allmain.c:1580-1623 draws the dungeon/HUD before the blocking
            # legacy prologue, then emits the welcome greeting afterwards.
            # curses presents this as PICK_NONE without a More footer.
            if (not restored and self.mode == 'curses' and
                    'It is written in the Book of' in text and 'Go bravely with' in text):
                self.snapshot('native-prologue')
                self.send(' ', 'acknowledge displayed native introductory story')
                continue
            if NAME in text and re.search(r'HP:\s*\d+', text) and '@' in text:
                greeting = b'welcome back to GnollHack!' if restored else b'welcome to GnollHack!'
                if greeting in self.raw:
                    break
                require(not self.exited() and time.monotonic() < end,
                        'native HUD drawn but startup greeting not reached\n' + text)
                self.read(0.2)
                continue
            if 'Shall I pick' in text:
                self.snapshot('character-prompt')
                self.send('n', 'ordinary manual character selection')
            elif re.search(r'Pick a level for game difficulty', text):
                self.snapshot('difficulty-menu')
                self.search_menu('Standard')
                choices.add('Standard difficulty')
            elif 'Is this ok?' in text:
                self.snapshot('character-confirmation')
                self.send('y', 'confirm ordinary character')
            else:
                for pattern, choice in [
                    (r'Pick an alignment or creed|Choose one of the following alignments:', 'lawful'),
                    (r'Pick a gender or sex|Choose one of the following genders:', 'female'),
                    (r'Pick a race or species|Choose one of the following races:', 'human'),
                    (r'Pick a role or profession|Choose one of the following roles:', 'Valkyrie'),
                ]:
                    if re.search(pattern, text):
                        self.snapshot('selection-' + choice)
                        self.search_menu(choice)
                        choices.add(choice)
                        break
                else:
                    self.read(0.2)
            require(not self.exited() and time.monotonic() < end,
                    'ordinary character/difficulty startup stalled\n' + self.text())
        self.snapshot('restored-start' if restored else 'ordinary-birth')
        raw = bytes(self.raw)
        require(b'discovery mode' not in raw and b'Do you want to keep the save file?' not in raw,
                'explore/wizard mode is not ordinary acceptance')
        if restored:
            require(b'Restoring save file...' in raw and b'welcome back to GnollHack!' in raw,
                    'ordinary automatic native restore missing')
            require(not choices, 'restore entered new-character selection')
        else:
            require(b'welcome to GnollHack!' in raw and b'welcome back' not in raw,
                    'ordinary native birth greeting missing')
            require({'Valkyrie', 'human', 'Standard difficulty'} <= choices,
                    'normal role/race/difficulty selection not exercised')
        return sorted(choices)

    def process_receipt(self):
        proc = Path('/proc') / str(self.pid)
        proof = namespace_proof(self.pid)
        executable = os.readlink(proc / 'exe')
        require(executable.startswith(str(self.output / 'libexec') + '/'),
                'launcher did not exec installed native game: ' + executable)
        argv = (proc / 'cmdline').read_bytes().split(b'\0')[:-1]
        require(argv[1:] == [arg.encode() for arg in self.argv[1:]], 'native argv changed/test flags injected')
        status = proof['files']['status']
        for field in ('CapInh', 'CapPrm', 'CapEff', 'CapBnd', 'CapAmb'):
            match = re.search('^' + field + r':\s*([0-9a-f]+)$', status, re.M)
            require(match and int(match[1], 16) == 0, 'native process retains ' + field)
        require(re.search(r'^NoNewPrivs:\s*1$', status, re.M), 'native process lacks no_new_privs')
        require(os.readlink(proc / 'cwd') == str(self.root / 'data/gnollhack'), 'wrong native XDG cwd')
        tty = os.readlink(proc / 'fd/0')
        require(tty.startswith('/dev/pts/'), 'not an actual external PTY')
        proof.update(pid=self.pid, executable=executable, argv=[arg.decode() for arg in argv],
                     tty=tty, cwd=os.readlink(proc / 'cwd'))
        record(self.evidence / (self.label + '-process.json'), proof)
        return proof

    def enable_time(self):
        if re.search(r'\bT:\s*\d+', self.text()):
            return
        self.send('O', 'ordinary in-game options, not a seeded rc')
        self.wait(lambda: 'Set what options?' in self.text(), 'native options menu', more=False)
        for page in range(80):
            self.snapshot('options-' + str(page + 1))
            match = re.search(r'([a-zA-Z])\s*(?:[-+]\s+|\)\s+)time\s+\[false\]', self.text())
            if match:
                self.send(match[1], 'toggle only displayed native time boolean')
                self.settle()
                self.send('\n', 'apply ordinary native option selection')
                self.wait(lambda: re.search(r'\bT:\s*\d+', self.text()), 'native turn HUD enabled')
                self.snapshot('native-time-option-enabled')
                return
            marker = self.page_marker()
            require(marker and marker[0] < marker[1], 'native time option not found in options menu')
            self.send('>', 'next native options page')
            self.wait(lambda: self.page_marker() != marker, 'next options page', more=False)
        raise RuntimeError('excessive native options pages')

    def select_symbols(self):
        # cursinit.c:830-835 explicitly warns DECgraphics breaks curses;
        # cursmain.c:752-756 passes named-set characters straight through.
        # dat/symbols:673-684 supplies plain ASCII for that native port.
        name = 'DECgraphics' if self.mode == 'tty' else 'plain'
        # Read the original symbols file through its real HACKPREFIX consumer.
        self.send('O', 'open native options to select installed symbol set')
        self.wait(lambda: 'Set what options?' in self.text(), 'native symset options', more=False)
        for page in range(80):
            self.snapshot('symset-options-' + str(page + 1))
            match = re.search(r'([a-zA-Z])\s*(?:[-+]\s+|\)\s+)symset\s+\[([^\]]+)\]', self.text())
            if match:
                self.send(match[1], 'select only the native primary symset compound option')
                self.settle()
                self.send('\n', 'apply native symset option selection')
                break
            marker = self.page_marker()
            require(marker and marker[0] < marker[1], 'native primary symset option absent')
            self.send('>', 'next native options page for primary symset')
            self.wait(lambda: self.page_marker() != marker, 'next symset options page', more=False)
        else:
            raise RuntimeError('excessive native symset option pages')
        self.wait(lambda: 'Select symbol set:' in self.text() or
                  'Unable to access' in self.text() or 'There were no symbol sets' in self.text(),
                  'native installed symbols file menu', more=False)
        self.snapshot('installed-symbols-menu')
        require('Select symbol set:' in self.text(),
                'native installed symbols file unavailable through primary symset option\n' + self.text())
        self.search_menu(name)
        # doset can immediately redraw over its transient acceptance message;
        # retain that surface, then prove the persistent option and map below.
        self.snapshot('symbols-selected')
        while self.more():
            pass
        self.send('O', 'inspect native accepted primary symset setting')
        self.wait(lambda: 'Set what options?' in self.text(), 'inspect native symset option', more=False)
        for page in range(80):
            self.snapshot('accepted-symset-options-' + str(page + 1))
            match = re.search(r'([a-zA-Z])\s*(?:[-+]\s+|\)\s+)symset\s+\[([^\]]+)\]', self.text())
            if match:
                require(match[2] == name + ', active', 'native primary symbols not active: ' + match[2])
                self.send('\x1b', 'close native option inspection without changing settings')
                self.settle()
                rendered = self.live('selected-symbols-rendered')
                terrain = ''.join(rendered['map'])
                if self.mode == 'tty':
                    require('·' in terrain and any(char in terrain for char in '─│┌┐└┘'),
                            'active native DECgraphics lacks decoded floor and walls')
                else:
                    require('.' in terrain and '+' in terrain and any(char in terrain for char in '-|'),
                            'active native plain symbols lack original ASCII floor/walls/corners')
                return {'primary_symset': match[2], 'selected_through_native_options': True,
                        'native_floor_walls_and_corners_rendered': True}
            marker = self.page_marker()
            require(marker and marker[0] < marker[1], 'accepted native primary symset option absent')
            self.send('>', 'next native options page for accepted primary symset')
            self.wait(lambda: self.page_marker() != marker, 'next accepted symset page', more=False)
        raise RuntimeError('excessive native accepted symset option pages')

    def page_marker(self):
        match = re.search(r'\((?:Page )?(\d+) of (\d+)\)', self.text())
        if match:
            return tuple(map(int, match.groups()))
        if '(end)' in self.text():
            return (1, 1)
        return None

    def live(self, label):
        offset = len(self.raw)
        self.send('\x12', 'ordinary Ctrl-R redraw')
        self.settle()
        require(len(self.raw) > offset, 'redraw produced no native output')
        self.snapshot(label)
        (self.evidence / (self.label + '-' + label + '-redraw.raw')).write_bytes(self.raw[offset:])
        text = self.text()
        values = {}
        for key, pattern in {'turn': r'\bT:\s*(\d+)', 'depth': r'\b(?:Dlvl|DL):\s*(\d+)',
                             'hp': r'\bHP:\s*(\d+)\s*\(\s*(\d+)\s*\)',
                             'mp': r'\bMP:\s*(\d+)\s*\(\s*(\d+)\s*\)'}.items():
            match = re.search(pattern, text)
            require(match, 'missing native HUD field ' + key + '\n' + text)
            values[key] = [int(value) for value in match.groups()] if len(match.groups()) > 1 else int(match[1])
        require(NAME in text and values['hp'][0] > 0 and values['depth'] == 1, 'not alive on native dungeon level 1')
        x, y = self.screen.cursor.x, self.screen.cursor.y
        if not (0 <= y < ROWS and 0 <= x < COLS and self.screen.display[y][x] == '@'):
            actors = [(column, row) for row, line in enumerate(self.screen.display)
                      for column, char in enumerate(line) if char == '@']
            require(len(actors) == 1, 'native viewport player not uniquely visible')
            x, y = actors[0]
        if self.mode == 'tty':
            left, top = 0, 1
        else:
            # Borders are native auto layout at 120x40, not a configured test viewport.
            borders = [(row, match.start(), match.end())
                       for row, line in enumerate(self.screen.display)
                       for match in re.finditer(r'[─━q-]{79,}', line)
                       if row < y and match.start() <= x < match.end()]
            require(borders, 'native curses map upper border not observed\n' + text)
            row, left, _ = max(borders)
            top = row + 1
        grid = [line[left:left + 80] for line in self.screen.display[top:top + 21]]
        position = [x - left, y - top]
        require(len(grid) == 21 and all(len(line) == 80 for line in grid) and
                0 <= position[0] < 80 and 0 <= position[1] < 21 and
                grid[position[1]][position[0]] == '@', 'invalid observed native 80x21 dungeon')
        require(any(char in ''.join(grid) for char in '.-|─│'), 'empty native map')
        stats = {}
        for key in ('St', 'Dx', 'Co', 'In', 'Wi', 'Ch'):
            match = re.search(r'\b' + key + r':\s*(\S+)', text)
            require(match, 'missing native attribute ' + key)
            stats[key] = match[1]
        result = dict(values, player=position, map=grid, attributes=stats,
                      coordinate_kind='zero-based observed native 80x21 viewport')
        record(self.evidence / (self.label + '-' + label + '.json'), result)
        return result

    def inventory(self, label):
        self.send('i', 'ordinary native inventory')
        self.wait(lambda: 'Inventory' in self.text() or self.page_marker(), 'native inventory', more=False)
        items = []
        for page in range(20):
            self.snapshot(label + '-page-' + str(page + 1))
            rows = re.findall(r'(?:^|[ │])([a-zA-Z$])\s*(?:[-+]\s+|\)\s+)([^\n│]+)', self.text(), re.M)
            items.extend({'letter': letter, 'description': text.strip()} for letter, text in rows)
            marker = self.page_marker()
            if marker and marker[0] < marker[1]:
                self.send('>', 'next native inventory page')
                self.wait(lambda: self.page_marker() != marker, 'next inventory page', more=False)
            else:
                self.send('\x1b', 'close native inventory without choosing an action')
                self.settle()
                break
        else:
            raise RuntimeError('excessive native inventory pages')
        require(len(items) >= 3 and len({item['letter'] for item in items}) == len(items),
                'native inventory rows missing, duplicated, or ambiguous')
        record(self.evidence / (self.label + '-' + label + '.json'), items)
        return items

    def capture(self, label):
        state = self.live(label)
        state['inventory'] = self.inventory(label + '-inventory')
        closed = self.live(label + '-inventory-closed')
        require(all(state[key] == closed[key] for key in closed), 'inventory inspection changed game state')
        record(self.evidence / (self.label + '-' + label + '-complete.json'), state)
        return state

    def advance(self, before, movement):
        current = before
        if movement:
            directions = [(-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j'),
                          (-1, -1, 'y'), (1, -1, 'u'), (-1, 1, 'b'), (1, 1, 'n')]
            # Native birth can put monsters between the hero and bare floor.
            # Do not restart it: ordinary directional play may fight first.
            for attempt in range(40):
                x, y = current['player']
                candidates = []
                for dx, dy, key in directions:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 80 and 0 <= ny < 21:
                        glyph = current['map'][ny][nx]
                        # Visible floor, traversable furniture/stairs, objects;
                        # x is DEF_XAN (e.g. native grid bug), not furniture.
                        if glyph in '.·_<>{\\)![?/=($%*89':
                            candidates.append((0, nx, ny, key, glyph))
                        elif glyph == 'x':
                            candidates.append((1, nx, ny, key, glyph))
                require(candidates, 'no adjacent observed floor/object or native grid-bug path; no injected map')
                _, nx, ny, key, glyph = min(candidates, key=lambda item: item[0])
                self.send(key, 'ordinary directional play toward observed ' + repr(glyph))
                self.settle()
                while self.more():
                    pass
                following = self.live('movement-attempt-' + str(attempt + 1))
                require(following['turn'] > current['turn'], 'ordinary directional play did not advance native time')
                current = following
                if current['player'] == [nx, ny]:
                    break
                require(current['player'] == [x, y] and glyph == 'x',
                        'native movement failed without the observed intervening monster')
            else:
                raise RuntimeError('ordinary combat did not clear an observed movement path')
        for number in range(2 if movement else 1):
            self.send('s', 'ordinary search consumes a native game turn')
            self.settle()
            while self.more():
                pass
            following = self.live('search-' + str(number + 1))
            require(following['turn'] > current['turn'], 'ordinary search did not advance native time')
            current = following
        return self.capture('pre-save')

    def save(self):
        offset = len(self.raw)
        # GnollHack binds save to M-s, not NetHack's uppercase S.
        self.send('#save\n', 'ordinary native extended save command')
        self.wait(lambda: 'Really save?' in self.text(), 'native save confirmation', more=False)
        self.snapshot('save-confirmation')
        self.send('y', 'confirm ordinary native save and exit')
        end = time.monotonic() + 25
        while not self.exited() or not self.eof:
            self.read()
            if not self.exited():
                self.more()
            require(time.monotonic() < end, 'native save did not exit')
        require(self.status == 0, 'native save exit status ' + str(self.status))
        tail = bytes(self.raw[offset:])
        require(b'Saving...' in tail and b'Be seeing you...' in tail, 'native natural save/exit messages missing')
        self.snapshot('saved-exit')

    def close(self):
        forced = not self.exited()
        if forced:
            os.kill(self.pid, signal.SIGKILL)
            _, status = os.waitpid(self.pid, 0)
            self.status = os.waitstatus_to_exitcode(status)
        self.deadline = time.monotonic() + 5
        self.settle()
        os.close(self.fd)
        self.raw_file.close()
        record(self.evidence / (self.label + '-cleanup.json'),
               {'forced_failure_cleanup': forced, 'natural_exit_status': self.status,
                'process_reaped': not (Path('/proc') / str(self.pid)).exists(),
                'pty_closed': True, 'raw_bytes': len(self.raw)})


def native_saves(state, evidence, label):
    files = sorted(path for path in (state / 'save').rglob('*') if path.is_file())
    require(files, 'ordinary save did not produce a native save file')
    receipt = {}
    for path in files:
        require(path.stat().st_size > 32, 'empty/truncated native save')
        receipt[str(path.relative_to(state))] = {'bytes': path.stat().st_size, 'sha256': sha(path)}
    record(evidence / (label + '-native-saves.json'), receipt)
    return receipt


def play(output, evidence, mode):
    root = evidence / (mode + '-private')
    root.mkdir(mode=0o700)
    for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
        (root / name).mkdir(mode=0o700)
    environment = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color', 'LC_ALL': 'C',
                   'PATH': '', 'TMPDIR': str(root / 'tmp')}
    for variable, subdir in [('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                             ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                             ('XDG_RUNTIME_DIR', 'runtime')]:
        environment[variable] = str(root / subdir)
    state = root / 'data/gnollhack'
    report = {'environment': environment, 'sessions': []}
    record(evidence / (mode + '-report.json'), report)
    previous = first_save = None
    for number in (1, 2):
        session = Session(output, environment, root, evidence, mode, number)
        try:
            choices = session.enter(restored=number == 2)
            process = session.process_receipt()
            session.enable_time()
            symbols = session.select_symbols()
            start = session.capture('restored' if number == 2 else 'first-live')
            if previous is not None:
                require(start == previous, 'restored native map/position/turn/attributes/HP/MP/inventory differ')
            advanced = session.advance(start, movement=number == 1)
            session.save()
            saved = native_saves(state, evidence, session.label)
            if number == 1:
                first_save = saved
            else:
                require(saved != first_save, 'resave after another native turn did not change save')
            report['sessions'].append({'process': process, 'choices': choices, 'initial': start,
                                       'pre_save': advanced, 'native_save': saved, 'symbols': symbols,
                                       'natural_exit_status': session.status})
            record(evidence / (mode + '-report.json'), report)
            previous = advanced
        except BaseException:
            session.snapshot('failure')
            raise
        finally:
            session.close()
    for name in ('home', 'cache', 'state', 'runtime', 'tmp', 'work', 'config'):
        require(not any((root / name).iterdir()), 'unexpected state outside XDG_DATA_HOME: ' + name)
    require(list((root / 'data').iterdir()) == [state], 'unexpected XDG data footprint')
    footprint = {}
    for path in root.rglob('*'):
        require(path.lstat().st_uid == os.getuid(), 'native state changed caller ownership')
        if path.is_symlink():
            require(str(path.resolve(strict=True)).startswith(str(output) + '/'), 'runtime symlink outside package')
        if path.is_file():
            footprint[str(path.relative_to(root))] = {'bytes': path.stat().st_size, 'sha256': sha(path)}
    report.update(native_continuity_exact=True, subsequent_turn_and_resave=True, footprint=footprint)
    record(evidence / (mode + '-report.json'), report)
    return report


def main():
    output, evidence = map(Path, sys.argv[1:])
    output = output.resolve()
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    retained = Path('/proc/self/fd/' + str(evidence_fd))
    report = {'success': False, 'output': str(output), 'source_commit': REVISION,
              'upstream_source_anchors': SOURCE_ANCHORS}
    try:
        retained, report['isolation'] = isolate(retained)
        os.chdir('/tmp')
        for mode in ('tty', 'curses'):
            report[mode] = play(output, retained, mode)
        report['success'] = True
    except BaseException as error:
        report['error'] = repr(error)
        (retained / 'failure.txt').write_text(traceback.format_exc())
        raise
    finally:
        record(retained / 'report.json', report)
        os.close(evidence_fd)


if __name__ == '__main__':
    main()
