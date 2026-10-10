#!/usr/bin/env python3
"""External dNetHack PTY acceptance; no installed helper or injected game state.

The ordinary launcher owns state.  Normal CLI/options character creation,
h/j/k/l movement, search, S/y save, automatic restore, continued turns and
#quit/y provide evidence.  Full map, HUD and inventory are compared across
restore; no RNG fixture, debug/explore mode or save mutation is used.
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

SOURCE_REVISION = 'a6f0a1c43e66f4fb1bcac34d7d9709706682ec19'
SOURCE_URL = 'https://github.com/Chris-plus-alphanumericgibberish/dNAO/tree/' + SOURCE_REVISION
ROWS, COLS = 24, 100
NAME = 'NativeDNet'
# src/options.c:767-774 accepts an explicit @file, avoiding host configuration.
# Birth preferences are normal gameplay options, not injected state.
OPTIONS = ('windowtype:tty,role:Valkyrie,race:human,gender:female,align:lawful,'
           '!descendant,time,statuslines:2,!mod_turncount,!IBMgraphics,!DECgraphics,'
           '!UTF8graphics,!color,!statuscolors,!hitpointbar,!legacy,!news,'
           '!dnethack_start_text,!autopickup,pettype:none,menustyle:full,number_pad:0,'
           'disclose:none')
SOURCE_ANCHORS = {
    'geometry': 'include/global.h:320-321 COLNO=80 ROWNO=21; '
                'win/tty/wintty.c:943-952 status offy=22 map offy=1',
    'hud': 'src/botl.c:457-546 name/rank, attributes/alignment; '
           '665-720 Dlvl, gold, HP/Pw, Br, AC/DR, Exp, moves',
    'birth': 'sys/unix/unixmain.c:294-301 player_selection/newgame; '
             'win/tty/wintty.c:373-749 ordinary specified role/race/gender/alignment; '
             'src/options.c:2687-2689 !descendant; src/allmain.c:4475-4478 greeting',
    'controls': 'src/cmd.c extcmdlist redraw/search/save/inventory/quit; '
                'ordinary vi movement and Ctrl-R',
    'save': 'src/save.c:61-85 Really save?/Saving.../Be seeing you.../EXIT_SUCCESS',
    'save_path': 'src/files.c:909 save/<getuid()>player; include/config.h:181-194 '
                 'disables COMPRESS and INTERNAL_COMP at this pin',
    'save_header': 'src/version.c:store_version writes four unsigned long long fields '
                   'from include/global.h:303-307; util/makedefs.c:452-455 incarnation '
                   '(major<<24)|(minor<<16)|(patch<<8)|edit = 0x031a0000',
    'whereis': 'include/config.h:476 whereis/%n.whereis; '
               'src/files.c:621-650 full character, HP, moves and score',
    'restore': 'sys/unix/unixmain.c:258-292 auto-restore; '
               'src/restore.c:790-791 ordinary restore consumes save',
    'quit': 'src/end.c:300-344 #quit Really quit?/done(QUIT); '
            '1425 clearlocks; 1538 goodbye; 1653 You quit summary',
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
    require((package / 'libexec/dnethack-real').read_bytes()[:4] == b'\x7fELF',
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
    data = package / 'share/dnethack/nhdat'
    require(data.is_file() and data.stat().st_size > 0, 'native nhdat missing')
    doc = package / 'share/doc/dnethack'
    for name in ('README', 'README.gray', 'README.menucolor', 'Guidebook.txt', 'README.linux'):
        require((doc / name).is_file() and (doc / name).stat().st_size > 0,
                'installed upstream notice missing: ' + name)
    fixes = list(doc.glob('fixes*'))
    require(fixes and all(p.is_file() and p.stat().st_size > 0 for p in fixes),
            'installed upstream fixes notices absent')
    require('NETHACK GENERAL PUBLIC LICENSE' in (package / 'share/dnethack/license').read_text(),
            'NGPL missing')
    require('dNetHack is free software' in (doc / 'README').read_text(), 'README grant missing')
    require(not (doc / 'MacroMagicMarker.py').exists(), 'non-runtime source script installed')
    require((doc / 'dnethack-source.tar.gz').is_file() and
            (doc / 'dnethack-source.tar.gz').stat().st_size > 0, 'NGPL complete source archive absent')
    require(not any('smoke' in p.name for p in (package / 'libexec').iterdir()),
            'installed test helper is forbidden')
    closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
    require(str(package) in closure, 'runtime closure receipt missing')
    names = [Path(path).name[33:] for path in closure]
    require(not any(name.startswith(('python-', 'python-pyte-', 'util-linux-')) for name in names),
            'external test tools leaked into runtime closure')
    return {'source_revision': SOURCE_REVISION, 'source_url': SOURCE_URL,
            'source_anchors': SOURCE_ANCHORS, 'runtime_closure': closure,
            'native_executable_sha256': sha(package / 'libexec/dnethack-real'),
            'nhdat_sha256': sha(data)}


def namespace_receipt(proc):
    namespaces = {name: os.readlink(proc / 'ns' / name) for name in ('user', 'mnt', 'net', 'pid')}
    for name, actual in namespaces.items():
        require(actual != os.environ['DNH_HOST_' + name.upper()], 'host namespace leaked: ' + name)
        require(actual == os.readlink('/proc/self/ns/' + name), 'game escaped private ' + name)
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, text = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(x) for x in text.split()]
    maps = {}
    for kind, key in (('uid', 'Uid'), ('gid', 'Gid')):
        expected = int(os.environ['DNH_HOST_' + kind.upper()])
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
        self.package_state = root / 'data/dnethack'
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
        # Birth preferences use ordinary CLI/options, never -X or -D.
        self.argv = [str(package / 'bin/dnethack'), '-u', NAME, '-p', 'Valkyrie', '-r', 'human']
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
        proc = Path('/proc') / str(self.pid)
        receipt = namespace_receipt(proc)
        executable = os.readlink(proc / 'exe')
        require(executable == str(self.package / 'libexec/dnethack-real'),
                'ordinary launcher did not exec installed native game: ' + executable)
        argv = (proc / 'cmdline').read_bytes().split(b'\0')[:-1]
        require(argv == [executable.encode(), *[arg.encode() for arg in self.argv[1:]]],
                'unexpected native argv/test mode')
        tty = os.readlink(proc / 'fd/0')
        require(tty.startswith('/dev/pts/'), 'native input is not an external PTY')
        require(os.readlink(proc / 'cwd') == str(self.package_state),
                'native process not in persistent XDG data playground')
        receipt.update({'pid': self.pid, 'tty': tty, 'executable': executable,
                        'argv': [a.decode() for a in argv], 'cwd': os.readlink(proc / 'cwd')})
        write_json(self.evidence / (self.label + '-process.json'), receipt)
        return receipt

    def enter(self, restored):
        self.wait(lambda: NAME in self.screen.display[22] and 'HP:' in self.screen.display[23]
                  and 'T:' in self.screen.display[23], 'ordinary dungeon startup')
        self.snapshot('ordinary-restored' if restored else 'ordinary-character-birth')
        raw = bytes(self.raw)
        require(b'discovery mode' not in raw and b'Do you want to keep the save file?' not in raw,
                'debug/explore mode is not ordinary acceptance')
        if restored:
            require(b'Restoring save file...' in raw and b'welcome back to dNetHack!' in raw,
                    'ordinary automatic restore/greeting missing')
        else:
            require(b'welcome to dNetHack!' in raw and b'welcome back' not in raw,
                    'not an ordinary new game')
            require(b'lawful' in raw and b'human' in raw and b'Valkyrie' in raw,
                    'ordinary role/race/alignment greeting absent')

    def live(self, label):
        offset = len(self.raw)
        self.send('\x12')  # ordinary Ctrl-R redraw, no game turn
        self.settle()
        frame = bytes(self.raw[offset:])
        require(frame, 'redraw produced no native bytes')
        (self.evidence / (self.label + '-' + label + '-redraw.raw')).write_bytes(frame)
        hud = self.screen.display[22:24]
        require(NAME in hud[0] and 'Lawful' in hud[0], 'wrong name/alignment HUD')
        stats = {}
        for stat in ('St', 'Dx', 'Co', 'In', 'Wi', 'Ch'):
            match = re.search(r'\b' + stat + r':\s*(\S+)', hud[0])
            require(match is not None, 'missing native attribute ' + stat)
            stats[stat] = match.group(1)
        hp = re.search(r'\bHP:\s*(\d+)\((\d+)\)', hud[1])
        pw = re.search(r'\bPw:\s*(\d+)\((\d+)\)', hud[1])
        values = {}
        for key, pattern in {'ac': r'\bAC:\s*(-?\d+)', 'dr': r'\bDR:\s*(-?\d+)',
                             'experience_level': r'\bExp:\s*(\d+)',
                             'depth': r'\bDlvl:\s*(\d+)', 'gold': r'\$:\s*(\d+)',
                             'turn': r'\bT:\s*(\d+)', 'breath': r'\bBr:\s*(\d+)'}.items():
            match = re.search(pattern, hud[1])
            require(match is not None, 'source-exact HUD decode failed: ' + key + '\n' + self.text())
            values[key] = int(match.group(1))
        require(hp and pw and int(hp.group(1)) > 0 and values['depth'] == 1,
                'not alive on first dungeon level')
        dungeon = [row[:80] for row in self.screen.display[1:22]]
        x, y = self.screen.cursor.x, self.screen.cursor.y - 1
        require(0 <= x < 80 and 0 <= y < 21 and dungeon[y][x] == '@',
                'native cursor does not identify displayed player\n' + self.text())
        require(any(c in ''.join(dungeon) for c in '.-|'), 'empty dungeon viewport')
        state = {'hud': hud, 'map': dungeon, 'player': [x, y], 'stats': stats,
                 'coordinate_kind': 'zero-based native 80x21 map viewport',
                 'hp': [int(value) for value in hp.groups()],
                 'pw': [int(value) for value in pw.groups()], **values}
        stem = self.snapshot(label)
        write_json(self.evidence / (stem + '.json'), state)
        if label == 'pre-exit':
            (self.evidence / 'pre-exit.raw').write_bytes(frame)
            (self.evidence / 'pre-exit.txt').write_text(self.text() + '\n')
        return state

    def inventory(self, before, label):
        self.send('i')
        self.wait(lambda: re.search(r'\(end\)|\(\d+ of \d+\)', self.text()),
                  'native inventory menu', more=False)
        items, pages = [], set()
        for page in range(20):
            located = [(row, match) for row, line in enumerate(self.screen.display)
                       for match in [re.search(r'\(end\)|\((\d+) of (\d+)\)', line)] if match]
            require(len(located) == 1, 'one native inventory marker required')
            marker_row, marker = located[0]
            column = marker.start()
            require(marker.group(0) not in pages, 'inventory pagination stalled')
            pages.add(marker.group(0))
            self.snapshot(label + '-page-' + str(page + 1))
            for line in self.screen.display[:marker_row]:
                item = re.match(r'([a-zA-Z$]) [-+] (.+?)\s*$', line[column:])
                if item:
                    items.append({'letter': item.group(1), 'description': item.group(2)})
            if marker.group(0) == '(end)' or marker.group(1) == marker.group(2):
                self.send(' ')
                break
            expected = int(marker.group(1)) + 1
            self.send('>')
            self.wait(lambda: '(' + str(expected) + ' of ' in self.text(),
                      'next inventory page', more=False)
        else:
            raise RuntimeError('too many native inventory pages')
        self.settle()
        require(items and len({i['letter'] for i in items}) == len(items), 'invalid inventory rows')
        require(self.live(label + '-closed') == before, 'inventory inspection changed native state')
        return items

    def capture(self, label):
        state = self.live(label)
        state['inventory'] = self.inventory(state, label + '-inventory')
        write_json(self.evidence / (self.label + '-' + label + '-complete.json'), state)
        return state

    def character_receipt(self, live):
        # restgamestate writes this; fresh birth does not. Save removes it.
        path = self.package_state / 'whereis' / (NAME + '.whereis')
        text = path.read_text()
        (self.evidence / (self.label + '.whereis')).write_text(text)
        fields = dict(part.split('=', 1) for part in text.strip().split(':'))
        require(fields['role'] == 'Val' and fields['race'] == 'Hum' and
                fields['gender'] == 'Fem' and fields['align'] == 'Law',
                'native birth fields differ from ordinary character selections')
        require(fields['depth'] == '1' and fields['dnum'] == '0' and fields['amulet'] == '0',
                'native character not ordinary first-level adventurer')
        require(int(fields['turns']) == live['turn'] and
                [int(fields['hp']), int(fields['maxhp'])] == live['hp'],
                'restored native whereis HP/moves differ from restored HUD')
        return fields

    def quit(self):
        offset = len(self.raw)
        self.send('#quit\n')
        self.wait(lambda: 'Really quit?' in self.text(), 'ordinary #quit confirmation', more=False)
        self.snapshot('quit-confirmation')
        self.send('y')
        end = time.monotonic() + 20
        while not self.exited() or not self.eof:
            self.read()
            if not self.exited() and ('--More--' in self.text() or '(end)' in self.text()):
                self.send(' ')
                self.settle()
            require(time.monotonic() < end, 'ordinary #quit did not exit')
        require(self.status == 0, 'ordinary quit exit status: ' + str(self.status))
        tail = bytes(self.raw[offset:])
        require(b'You quit in ' in tail and b'when you quit' in tail,
                'native natural-quit summary missing')
        self.snapshot('quit-exit')

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
        return self.capture('advanced')

    def save(self):
        offset = len(self.raw)
        self.send('S')
        self.wait(lambda: 'Really save?' in self.text(), 'native S save confirmation', more=False)
        self.snapshot('save-confirmation')
        self.send('y')
        end = time.monotonic() + 20
        while not self.exited() or not self.eof:
            self.read()
            if '--More--' in self.text() and not self.exited():
                self.send(' ')
                self.settle()
            require(time.monotonic() < end, 'ordinary save did not exit')
        require(self.status == 0, 'native save/launcher exit status: ' + str(self.status))
        tail = bytes(self.raw[offset:])
        require(b'Saving...' in tail and b'Be seeing you...' in tail, 'native save/exit messages missing')
        self.snapshot('saved-exit')

    def close(self):
        forced = False
        if not self.exited():
            # Failure cleanup only, explicitly disqualified as acceptance.
            forced = True
            os.kill(self.pid, signal.SIGKILL)
            _, status = os.waitpid(self.pid, 0)
            self.status = os.waitstatus_to_exitcode(status)
        # Drain remaining failed-child bytes without the expired gameplay deadline.
        self.deadline = time.monotonic() + 5
        self.settle()
        os.close(self.fd)
        self.raw_file.close()
        write_json(self.evidence / (self.label + '-cleanup.json'),
                   {'pid': self.pid, 'exit_status': self.status, 'forced_failure_cleanup': forced,
                    'process_reaped': not (Path('/proc') / str(self.pid)).exists(),
                    'pty_closed': True, 'raw_bytes': len(self.raw)})


def native_save(state, evidence, number):
    files = sorted(p for p in (state / 'save').rglob('*') if p.is_file())
    expected = state / 'save' / (str(os.getuid()) + NAME)
    require(files == [expected] and not expected.is_symlink() and expected.stat().st_size > 0,
            'expected one nonempty native same-UID/player save')
    copy = evidence / ('session-' + str(number) + '.native-save')
    shutil.copyfile(expected, copy)  # Receipt only; NEVER supplied back to game.
    with copy.open('rb') as stream:
        header = stream.read(32)
    require(len(header) == 32, 'native version header truncated')
    incarnation, features, entities, sizes = struct.unpack('=4Q', header)
    require(incarnation == 0x031a0000 and entities > 0 and sizes > 0,
            'native save version/layout is not source-derived dNetHack 3.26.0')
    return {'path': str(expected.relative_to(state)), 'size': copy.stat().st_size,
            'sha256': sha(copy), 'evidence_copy_never_reinjected': True,
            'version_header': {'incarnation': hex(incarnation), 'features': hex(features),
                               'entities': hex(entities), 'struct_sizes': hex(sizes),
                               'layout': 'native endian four uint64 fields, 32 bytes'}}


def launch_isolated(package, evidence):
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized util-linux unshare unavailable')
    variables = ('PATH', 'HOME', 'TMPDIR', 'GUIX_PYTHONPATH', 'PYTHONPATH', 'TERMINFO',
                 'TERMINFO_DIRS', 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME')
    env = {key: os.environ[key] for key in variables if os.environ.get(key)}
    env.update({'LC_ALL': 'C', 'DNH_HOST_UID': str(os.getuid()), 'DNH_HOST_GID': str(os.getgid())})
    for name in ('user', 'mnt', 'net', 'pid'):
        env['DNH_HOST_' + name.upper()] = os.readlink('/proc/self/ns/' + name)
    command = [unshare, '--user', '--map-current-user', '--keep-caps', '--mount',
               '--propagation', 'private', '--net', '--pid', '--mount-proc', '--kill-child',
               '--fork', sys.executable, '-B', str(Path(__file__).resolve()),
               str(package), str(evidence), '--inside']
    receipt = {'command': command, 'host_identity_and_namespaces':
               {key: value for key, value in env.items() if key.startswith('DNH_HOST_')}}
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
    parser.add_argument('package', type=Path, help='prebuilt dNetHack output')
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
        print('DNETHACK NATIVE SMOKE OK')
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
        watched = {original_home / '.dnethackrc', original_home / '.nethackrc',
                   original_home / '.local/share/dnethack', original_home / '.local/state/dnethack',
                   Path.cwd() / 'save', Path.cwd() / 'level', Path.cwd() / 'lock', Path.cwd() / 'dumps'}
        for variable in ('XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME'):
            if os.environ.get(variable):
                watched.add(Path(os.environ[variable]) / 'dnethack')
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
               'PATH': '', 'TMPDIR': str(root / 'tmp'), 'NETHACKOPTIONS': '@' + str(options_path)}
        for variable in ('TERMINFO', 'TERMINFO_DIRS'):
            if os.environ.get(variable):
                env[variable] = os.environ[variable]
        for variable, subdir in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                 ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                 ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / subdir)
        state = root / 'data/dnethack'
        previous = None
        for number in (1, 2):
            session = Session(package, env, root, evidence, number)
            session.enter(restored=number == 2)
            process = session.process_receipt()
            start = session.capture('restored' if number == 2 else 'first-live')
            character = session.character_receipt(start) if number == 2 else None
            if previous is not None:
                require(start == previous, 'restored full map/HUD/turn/position/inventory differ')
                require(not any(p.is_file() for p in (state / 'save').rglob('*')),
                        'ordinary restore did not consume native save')
                report['continuity'].append({'from': 1, 'to': 2, 'full_map_hud_inventory_exact': True,
                                             'native_save_consumed': True})
            advanced = session.advance(start)
            pre_exit = session.live('pre-exit')
            require(all(pre_exit[key] == advanced[key] for key in pre_exit),
                    'redraw changed native state without a turn')
            if number == 1:
                session.save()
                saved = native_save(state, evidence, number)
                exit_kind = 'ordinary-save'
            else:
                session.quit()
                saved = None
                exit_kind = 'ordinary-quit'
            require(not list((state / 'whereis').iterdir()), 'native exit left stale whereis')
            locks = list(state.glob(str(os.getuid()) + NAME + '.*'))
            require(not locks, 'native exit left character level/lock files')
            report['sessions'].append({'process': process, 'launcher_argv': session.argv,
                                       'initial': start, 'advanced': advanced, 'native_save': saved,
                                       'character': character, 'exit_kind': exit_kind,
                                       'natural_exit_status': session.status, 'locks_cleaned': True})
            write_json(evidence / 'continuity.json', report)
            previous = advanced
            session.close()
            session = None
        for name in ('home', 'cache', 'state', 'runtime', 'tmp', 'work'):
            require(not any((root / name).iterdir()), 'state escaped native XDG data: ' + name)
        require(list((root / 'config').iterdir()) == [options_path], 'unexpected config write')
        require(list((root / 'data').iterdir()) == [state], 'state escaped dnethack data directory')
        for path in root.rglob('*'):
            if path.is_symlink():
                require(path in (state / 'nhdat', state / 'license'),
                        'unexpected runtime symlink: ' + str(path))
                require(path.resolve(strict=True) == package / 'share/dnethack' / path.name,
                        'runtime asset link is not the installed immutable asset')
                continue
            require(path.stat().st_uid == os.getuid(), 'native state changed ownership')
            # Native FCMASK 0660, whereis 0664 and dumps 0644 are upstream;
            # caller-only directories provide privacy without mutating game files.
            forbidden = 0o077 if path.is_dir() else 0o003
            require(path.stat().st_mode & forbidden == 0, 'native state is not private: ' + str(path))
        require(all(fingerprint(Path(path)) == value for path, value in initial.items()),
                'host game state/config or working directory changed')
        report['private_footprint'] = {
            str(p.relative_to(root)): ({'target': os.readlink(p), 'immutable_asset': True}
                                      if p.is_symlink() else
                                      {'size': p.stat().st_size, 'sha256': sha(p),
                                       'mode': oct(p.stat().st_mode & 0o777)})
            for p in root.rglob('*') if p.is_file() or p.is_symlink()}
        report['private_environment'] = env
        report['host_game_state_unchanged'] = True
        report['cleanup'] = {'both_games_naturally_exited': True,
                             'native_character_locks_removed': True,
                             'native_save_consumed_by_restore': True,
                             'private_state_retained_as_evidence': str(root),
                             'host_paths_unchanged': sorted(initial)}
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
