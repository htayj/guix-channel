#!/usr/bin/env python3
"""External ordinary-launch PTY consumer for Cave Chop 1.0.

No installed test mode, seed override, wizard command, generated save or
reinjected evidence is used. Save/restore continuity covers the full native
visible map, complete HUD and decoded cell attributes. Test tools stay outside
the game runtime closure; namespace denial and native diagnostics are failures.
"""
import argparse
import codecs
import ctypes
import errno
import fcntl
import hashlib
import gzip
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
GAME = 'cavechop'
SOURCE_URL = ('http://git.blackswordsonics.com/?p=cavechop-7drl;'
              'a=snapshot;h=ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692;sf=tgz')
SOURCE_SHA256 = '6c16c18125ebd6b3fd56402c0dd2094abfd716b7515700da2050be4a908aef97'


NOTES_SHA256 = '25e1e232b0a01c0ea193e8eb37a7b672511472f71045f882215b10cc6a77ce3f'
NOTES_SIZE = 3346
SOURCE_HEADER_SHA256 = 'c954101c8e373d0d85d60cb4a6011f6d0fbaa69cbcd49717b2bc820c159a44eb'
SOURCE_HEADER_SIZE = 13557
SOURCE_ANCHORS = {
    'birth': 'u.c:u_init 439-502 (normal name max16, default Matilda; fresh ordinary character)',
    'mode': 'main.c:main 625-646 (no args, automatic cavechop.sav.gz detection)',
    'geometry': 'display.c:display_init/draw_world (21x21 at 0,0; centre 10,10; HUD 22..23)',
    'hud': 'display.c:draw_status_line (name HP XL Body / Defence Food Depth Agility XP; NO Gold)',
    'movement': 'display.c:get_command 484-580; u.c:move_player/reloc_player (h/j/k/l plus diagonals)',
    'turn': 'main.c:main_loop 570-615; u.c:update_player (nutrition decreases per tick)',
    'inventory': 'main.c:do_command SHOW_INVENTORY (i no turn; NOT load)',
    'save': 'main.c:save_game 89-120 (S native cavechop.sav, gzip; no turn)',
    'restore': 'main.c:load_game 122-146 (automatic gzip load, reconstruct map, consume save)',
    'exit': 'display.c:getYN 599-611 capital Y; display_shutdown 583-591; press_enter 215-228',
    'inspect': 'display.c:I / main.c:INSPECT_ITEM / objects.c:describe_object 647-655; normal dagger description',
    'rights': 'notes.txt complete 3346-byte BSD-2 notice; C/H copyright 2005-2012 Martin Read; no assets',
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


class PermanentObject(ctypes.Structure):
    # cavechop.h:struct permobj. Use the native compiler ABI layout; the
    # description pointer is inert bytes only and is never dereferenced.
    _fields_ = [('name', ctypes.c_char * 48), ('plural', ctypes.c_char * 48),
                ('description', ctypes.c_void_p), ('poclass', ctypes.c_int),
                ('rarity', ctypes.c_int), ('sym', ctypes.c_int),
                ('power', ctypes.c_int), ('used', ctypes.c_int), ('depth', ctypes.c_int)]


def native_save_receipt(path, evidence, number, package):
    require(path.is_file() and path.stat().st_size > 0 and
            not path.with_suffix('').exists(), 'normal save did not create only compressed native state')
    compressed = path.read_bytes()
    require(compressed[:2] == b'\x1f\x8b', 'save is not native gzip state')
    data = gzip.decompress(compressed)
    # This regression is for the actual x86-64 Linux native output, not an
    # emulated or cross-ABI save. Fail explicitly instead of guessing offsets.
    elf = (package / 'libexec/cavechop').read_bytes()[:20]
    require(elf[:6] == b'\x7fELF\x02\x01' and int.from_bytes(elf[18:20], 'little') == 62 and
            sys.byteorder == 'little' and ctypes.sizeof(ctypes.c_int) == 4 and
            ctypes.sizeof(ctypes.c_uint32) == 4 and ctypes.sizeof(ctypes.c_void_p) == 8 and
            ctypes.sizeof(PermanentObject) == 128 and PermanentObject.poclass.offset == 104,
            'unsupported native save ABI; cannot safely decode permanent-object records')
    offset = 5 * ctypes.sizeof(ctypes.c_uint32) + 42 * 42 * ctypes.sizeof(ctypes.c_int)
    width, count = ctypes.sizeof(PermanentObject), 39
    require(len(data) > offset + width * count, 'native save truncates permanent-object table')
    fields = ('poclass', 'rarity', 'sym', 'power', 'used', 'depth')
    records = []
    for index in range(count):
        record = PermanentObject.from_buffer_copy(data[offset + index * width:offset + (index + 1) * width])
        records.append({'index': index, 'name': bytes(record.name).decode('ascii'),
                        'plural': bytes(record.plural).decode('ascii'),
                        'scalars': {field: getattr(record, field) for field in fields}})
    # objects.c:flavours_init chooses four potion, three scroll and five ring
    # powers uniquely within each class. No RNG is changed or save injected.
    flavour_groups = {'potions': list(range(8, 12)), 'scrolls': list(range(15, 18)),
                      'rings': list(range(30, 35))}
    flavour_powers = {}
    for group, indices in flavour_groups.items():
        powers = [records[index]['scalars']['power'] for index in indices]
        require(all(0 <= power < 20 for power in powers) and len(set(powers)) == len(powers),
                'native randomized flavour powers lost or invalid: ' + group)
        flavour_powers[group] = powers
    copy = evidence / ('session-' + str(number) + '-native-save.gz')
    shutil.copyfile(path, copy)
    receipt = {'path': str(path), 'size': len(compressed), 'sha256': sha(path),
               'uncompressed_bytes': len(data), 'uncompressed_sha256': hashlib.sha256(data).hexdigest(),
               'evidence_copy': str(copy), 'evidence_copy_never_reinjected': True,
               'permobj_abi': {'offset': offset, 'record_bytes': width, 'count': count,
                               'scalar_offsets': {field: getattr(PermanentObject, field).offset for field in fields},
                               'description_pointer_excluded': True},
               'permanent_objects': records, 'flavour_powers': flavour_powers}
    write_json(evidence / ('session-' + str(number) + '-native-save.json'), receipt)
    return receipt


def output_contract(package, evidence):
    require(package.parent == Path('/gnu/store'), 'OUTPUT must be a direct store output')
    native = package / 'libexec/cavechop'
    require(native.read_bytes()[:4] == b'\x7fELF', 'installed native executable is not ELF')
    for path in [package, *package.rglob('*')]:
        target = path.resolve(strict=True) if path.is_symlink() else path
        require(target.is_relative_to(package), 'output symlink escapes package: ' + str(path))
        require(target.stat().st_mode & 0o222 == 0, 'output has write bits: ' + str(path))
    notes = package / 'share/doc' / GAME / 'notes.txt'
    require(notes.is_file() and notes.stat().st_size == NOTES_SIZE and sha(notes) == NOTES_SHA256,
            'complete canonical upstream notes/license bytes differ')
    for marker in ('Copyright 2012 Martin Read.', 'copyright 2012 Martin Read.',
                   '1. Redistributions of source code must retain the above copyright',
                   '2. Redistributions in binary form must reproduce the above copyright',
                   'THIS SOFTWARE IS PROVIDED BY THE AUTHOR',
                   'THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'):
        require(marker in notes.read_text(), 'upstream license clause missing: ' + marker)
    source_header = package / 'share/doc' / GAME / 'cavechop.h'
    require(source_header.is_file() and source_header.stat().st_size == SOURCE_HEADER_SIZE and
            sha(source_header) == SOURCE_HEADER_SHA256,
            'complete canonical source copyright/header bytes differ')
    require('Copyright 2005-2012 Martin Read' in source_header.read_text(),
            'source copyright year range missing from binary distribution')
    launcher = (package / 'bin/cavechop').read_text()
    require('--smoke' not in launcher,
            'installed synthetic gameplay branch is forbidden')
    require(not any('smoke' in p.name or 'native.py' in p.name or
                    p.suffix.lower() == '.html' or p.name == 'spoilers'
                    for p in package.rglob('*')), 'test helper or unlicensed spoiler document installed')
    closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
    require(str(package) in closure, 'runtime closure lacks output')
    require(not any(Path(p).name[33:].startswith(('python-', 'python-pyte-', 'util-linux-'))
                    for p in closure), 'external PTY/test tools leaked into game closure')
    return {'native_sha256': sha(native), 'notes_sha256': sha(notes),
            'source_copyright_header_sha256': sha(source_header),
            'runtime_closure': closure, 'source_url': SOURCE_URL,
            'source_sha256': SOURCE_SHA256, 'source_anchors': SOURCE_ANCHORS}


def namespace_receipt(proc):
    namespaces = {name: os.readlink(proc / 'ns' / name) for name in ('user', 'mnt', 'net', 'pid')}
    for name, actual in namespaces.items():
        require(actual != os.environ['CC_HOST_' + name.upper()], 'host namespace leaked: ' + name)
        require(actual == os.readlink('/proc/self/ns/' + name), 'game escaped private ' + name)
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, text = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(x) for x in text.split()]
    maps = {}
    for kind, key in (('uid', 'Uid'), ('gid', 'Gid')):
        expected = int(os.environ['CC_HOST_' + kind.upper()])
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
        self.package, self.evidence, self.env = package, evidence, env
        self.label = 'session-' + str(number)
        self.argv = [str(package / 'bin/cavechop')]
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
        self.check_native_errors()
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
        self.wait(lambda: (proc / 'exe').exists() and os.readlink(proc / 'exe') == str(self.package / 'libexec/cavechop'),
                  'ordinary launcher exec of installed ELF')
        receipt = namespace_receipt(proc)
        argv = (proc / 'cmdline').read_bytes().split(b'\0')[:-1]
        require(argv == [str(self.package / 'libexec/cavechop').encode()],
                'unexpected native argv/test mode')
        tty = os.readlink(proc / 'fd/0')
        require(tty.startswith('/dev/pts/'), 'native input is not an external PTY')
        expected_cwd = self.evidence / 'private/state' / GAME
        require(os.readlink(proc / 'cwd') == str(expected_cwd), 'normal launcher did not enter private XDG state')
        environment = dict(item.split(b'=', 1) for item in
                           (proc / 'environ').read_bytes().split(b'\0') if b'=' in item)
        for key in (b'SEED', b'LD_PRELOAD', b'LD_LIBRARY_PATH', b'RANDOM_SEED', b'CAVECHOP_SEED'):
            require(key not in environment, 'forbidden gameplay/code override: ' + key.decode())
        require(environment[b'PATH'] == b'', 'game can consult host PATH')
        for key in ('HOME', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME',
                    'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'TMPDIR', 'TERM', 'LC_ALL'):
            require(environment.get(key.encode()) == self.env[key].encode(),
                    'native private environment differs: ' + key)
        receipt.update({'pid': self.pid, 'tty': tty, 'executable': os.readlink(proc / 'exe'),
                        'argv': [a.decode() for a in argv], 'launcher_argv': self.argv,
                        'cwd': os.readlink(proc / 'cwd'),
                        'private_environment': self.env})
        write_json(self.evidence / (self.label + '-process.json'), receipt)
        return receipt

    def check_native_errors(self):
        # main.c returns zero after display_shutdown regardless of many upstream
        # diagnostics; neither shell status nor a save's existence is sufficient.
        text = self.raw.decode('utf-8', errors='replace') + '\n' + self.text()
        require(not re.search(r"Couldn't|Could not|\b(?:fatal|error|failed|failure)\b|"
                              r"Segmentation fault|Aborted|core dumped|THOU ART SLAIN!|"
                              r"Absurd (?:body|agility) gain|No such file|Permission denied|"
                              r"not found|Attempted move out of bounds", text, re.IGNORECASE),
                self.label + ': native error/death output (even if exit status is zero)\n' + self.text())

    def enter(self, name, restored=False):
        if not restored:
            self.wait(lambda: 'What is your name, stranger?' in self.text(), 'ordinary birth name entry')
            self.snapshot('name-prompt')
            self.send(name + '\n')
        self.wait(lambda: self.screen.display[10][10] == '@' and
                  'HP:' in self.screen.display[22] and 'Food:' in self.screen.display[23],
                  'normal playable viewport and HUD')
        require(b'Welcome to Cave Chop, Princess ' in self.raw, 'normal welcome missing')
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
        top = re.fullmatch(r'(.{16}) HP: (\d{3})/(\d{3})\s+XL: (\d+)\s+Body: (\d{2})/(\d{2})\s*', hud[0])
        bottom = re.fullmatch(r'Defence: (\d{2})\s+Food: (-?\d+)\s+Depth: (\d+)\s+Agility: (\d{2})/(\d{2})\s+XP: (\d+)\s*', hud[1])
        require(top is not None and bottom is not None, 'source-exact HUD decode failed\n' + self.text())
        require(int(top.group(2)) > 0 and b'THOU ART SLAIN!' not in self.raw, 'character is not alive')
        dungeon = [row[:21] for row in self.screen.display[:21]]
        require(dungeon[10][10] == '@' and '.' in ''.join(dungeon), 'source-exact viewport/player absent')
        state = {'map': dungeon, 'hud': hud, 'player_viewport': [10, 10],
                 'coordinate_kind': 'zero-based 21x21 player-centred scrolling viewport, NOT world position',
                 'name': top.group(1).rstrip(), 'hp': [int(top.group(2)), int(top.group(3))],
                 'level': int(top.group(4)), 'body': [int(top.group(5)), int(top.group(6))],
                 'defence': int(bottom.group(1)),
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
        for dx, dy, key in ((-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j'),
                            (-1, -1, 'y'), (1, -1, 'u'), (-1, 1, 'b'), (1, 1, 'n')):
            if before['map'][10 + dy][10 + dx] != '.':
                continue
            # Walls cannot move or be covered by monsters. Require displaced
            # wall-edge witnesses so a wait/failed bump cannot pass as movement.
            witnesses = [(x, y, x - dx, y - dy) for y in range(21) for x in range(21)
                         if 0 <= x - dx < 21 and 0 <= y - dy < 21 and
                         before['map'][y][x] == '#' and before['map'][y - dy][x - dx] != '#']
            candidates.append((len(witnesses), dx, dy, key, witnesses))
        require(candidates, 'no adjacent observed floor; no seed/fixture/retry permitted')
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

    def inspect_dagger(self, label):
        # The restored permanent-object table contains native description
        # pointers. Exercise them through the real I/a interface, not a save
        # fixture or private API; a stale pointer must fail this consumer.
        self.send('I')
        self.wait(lambda: 'What do you want to inspect?' in self.text(),
                  'ordinary item inspection selection')
        self.snapshot(label + '-selection')
        offset = len(self.raw)
        self.send('a')
        description = 'A long knife, designed for stabbing.'
        self.wait(lambda: description in self.text() and len(self.raw) > offset,
                  'native starter dagger description')
        self.snapshot(label + '-description')
        return description

    def finish(self, label):
        self.wait(lambda: 'Press RETURN or SPACE to continue' in self.text(), 'normal shutdown acknowledgement')
        self.snapshot(label + '-acknowledgement')
        self.send('\n')
        end = time.monotonic() + 20
        while not self.exited() or not self.eof:
            self.read()
            require(time.monotonic() < end, label + ': native process failed to exit')
        self.check_native_errors()
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
    env.update({'LC_ALL': 'C', 'CC_HOST_UID': str(os.getuid()), 'CC_HOST_GID': str(os.getgid())})
    for name in ('user', 'mnt', 'net', 'pid'):
        env['CC_HOST_' + name.upper()] = os.readlink('/proc/self/ns/' + name)
    command = [unshare, '--user', '--map-current-user', '--keep-caps', '--mount',
               '--propagation', 'private', '--net', '--pid', '--mount-proc', '--kill-child',
               '--fork', sys.executable, '-B', str(Path(__file__).resolve()),
               str(package), str(evidence), '--inside']
    receipt = {'command': command, 'host_identity_and_namespaces':
               {key: value for key, value in env.items() if key.startswith('CC_HOST_')}}
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
        receipt = json.loads((evidence / 'continuity.json').read_text())
        require(receipt.get('success') is True, 'namespace exited zero without complete continuity proof')
        print('CAVECHOP_NATIVE_OK')
        return
    report = {'success': False, 'sessions': [], 'source_url': SOURCE_URL,
              'source_sha256': SOURCE_SHA256, 'ordinary_gameplay_only': True}
    write_json(evidence / 'continuity.json', report)
    session = None
    try:
        report['output_contract'] = output_contract(package, evidence)
        report['isolation'] = namespace_receipt(Path('/proc/self'))
        report['isolation']['store'] = readonly_store(evidence)
        watched = {Path.home() / '.local/state' / GAME, Path.home() / 'cavechop.sav.gz',
                   Path.cwd() / 'cavechop.sav.gz', Path.cwd() / 'cavechop.sav', Path.cwd() / 'cavechop.log'}
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
        save_path = state_dir / 'cavechop.sav.gz'
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
        dagger_description = session.inspect_dagger('pre-save-inspection')
        require(session.live('pre-save') == advanced, 'no-turn inventory changed pre-save map/HUD')
        session.save()
        native_save = native_save_receipt(save_path, evidence, 1, package)
        report['sessions'].append({'process': process, 'initial': start, 'advanced': advanced,
                                   'native_save': native_save, 'normal_save_exit_status': session.status})
        write_json(evidence / 'continuity.json', report)
        session.close()
        session = Session(package, env, root, evidence, 2)
        session.enter(name, restored=True)
        process = session.process_receipt()
        restored = session.live('restored')
        require(restored == advanced, 'restored exact decoded map/HUD/cell styles differ from pre-save')
        require(not save_path.exists() and not (state_dir / 'cavechop.sav').exists(),
                'ordinary restore failed to consume original native save')
        require(process['pid'] != report['sessions'][0]['process']['pid'], 'restore was not an independent process')
        report['continuity'] = {'full_map_and_hud_exact': True, 'decoded_nonblank_and_hud_styles_exact': True,
                                'blank_map_colors_only_normalized': True,
                                'native_save_consumed': True, 'independent_process': True}
        require(session.inspect_dagger('restored-inspection') == dagger_description,
                'ordinary restored item description differs')
        require(session.live('post-restore-inspection') == restored,
                'no-turn restored item inspection changed map/HUD')
        # Save a second time through the ordinary interface before another
        # turn. A no-turn UI restore alone cannot detect the old fseek bug:
        # all six serialized permanent-object scalars, including the twelve
        # randomized flavour powers, must survive the real load/save cycle.
        session.save()
        second_save = native_save_receipt(save_path, evidence, 2, package)
        require(second_save['permanent_objects'] == native_save['permanent_objects'] and
                second_save['flavour_powers'] == native_save['flavour_powers'],
                'native restore/save lost permanent-object scalars or randomized flavour powers')
        report['continuity']['all_39_permobj_six_scalars_exact'] = True
        report['continuity']['all_12_randomized_flavour_powers_exact'] = True
        report['sessions'].append({'process': process, 'initial': restored,
                                   'native_save': second_save, 'normal_save_exit_status': session.status})
        write_json(evidence / 'continuity.json', report)
        session.close()
        session = Session(package, env, root, evidence, 3)
        session.enter(name, restored=True)
        process = session.process_receipt()
        restored_again = session.live('restored-again')
        require(restored_again == restored, 'second independent restore changed exact map/HUD/cells')
        require(not save_path.exists() and not (state_dir / 'cavechop.sav').exists(),
                'second ordinary restore did not consume native save')
        require(process['pid'] not in [saved['process']['pid'] for saved in report['sessions']],
                'third ordinary launch did not create an independent process')
        require(session.inspect_dagger('third-launch-inspection') == dagger_description and
                session.live('third-launch-post-inspection') == restored_again,
                'second restore lost ordinary description pointer or changed no-turn state')
        continued = session.advance(restored_again, 'continued-movement')
        session.inventory('continued-inventory')
        require(session.live('pre-quit') == continued, 'no-turn inventory changed continued state')
        session.quit()
        require(not save_path.exists() and not (state_dir / 'cavechop.sav').exists(), 'clean quit unexpectedly saved')
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
