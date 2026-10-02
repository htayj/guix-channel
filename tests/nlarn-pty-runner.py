#!/usr/bin/env python3
"""Ordinary two-process NLarn gameplay, screen and native gzip-JSON continuity.

The shell realizes Python/pyte/util-linux/coreutils. This helper owns its offline
user/mount/network/PID namespace and fails closed. NLARN_RAW_CAPTURE is the
unmodified second PTY prefix before save/exit; NLARN_TEXT_CAPTURE is that screen,
NLARN_TRANSCRIPT holds both complete sessions. Native saves and receipt.json
remain in ROOT/proof. No executable patch, simulated game state or renderer.
"""
import codecs
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
import socket
import struct
import subprocess
import sys
import termios
import time
import zlib

import pyte

ROWS, COLS = 30, 100
NAME = 'OmpProof'
CAPTURES = ('NLARN_RAW_CAPTURE', 'NLARN_TEXT_CAPTURE', 'NLARN_TRANSCRIPT')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def native_save(path):
    # NLarn rewinds the locked descriptor without truncating it on resave.
    # zlib reads the first actual gzip stream, not any stale file tail.
    return json.loads(zlib.decompress(path.read_bytes(), 31))


def native_player(save):
    player = save['player']
    ids = player['inventory']
    require(isinstance(ids, list) and len(ids) == 2,
            'fixed starting inventory must contain the actual two items')
    items = {item['oid']: item for item in save['items']}
    carried = [items[oid] for oid in ids]
    require(sorted(item['id'] for item in carried) == ['AT_LEATHER', 'WT_DAGGER'],
            'native inventory is not the displayed starting armour and dagger')
    fields = ('name', 'sex', 'position', 'strength', 'intelligence', 'wisdom',
              'constitution', 'dexterity', 'hp', 'hp_max', 'mp', 'mp_max',
              'level', 'experience', 'inventory')
    fields += tuple(key for key in player if key.startswith('eq_'))
    return {'player': {key: player[key] for key in fields}, 'gtime': save['gtime'],
            'inventory_items': carried}


class XtermScreen(pyte.Screen):
    # ncurses uses xterm's ECMA-48 REP (CSI Ps b). pyte otherwise ignores it,
    # shifting all subsequent HUD/map cells while raw capture stays correct.
    last_graphic = ''

    def draw(self, data):
        super().draw(data)
        if data:
            self.last_graphic = data[-1]

    def repeat_character(self, count=1):
        if self.last_graphic:
            super().draw(self.last_graphic * (count or 1))


class XtermStream(pyte.Stream):
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Session:
    def __init__(self, executable, root, transcript):
        self.raw = bytearray()
        self.screen = XtermScreen(COLS, ROWS)
        self.stream = XtermStream(self.screen)
        self.stream.use_utf8 = False  # LC_ALL=C ncurses uses DEC ACS glyphs.
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.transcript = transcript
        self.alive = True
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color',
               'LC_ALL': 'C', 'PATH': '', 'TMPDIR': str(root / 'tmp')}
        for variable, directory in (('XDG_CONFIG_HOME', 'config'),
                                    ('XDG_DATA_HOME', 'data'),
                                    ('XDG_CACHE_HOME', 'cache'),
                                    ('XDG_STATE_HOME', 'state'),
                                    ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / directory)
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(executable, [executable], env)
            except BaseException:
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def read(self, timeout=0.1):
        if not select.select([self.fd], [], [], timeout)[0]:
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
        require(len(self.raw) < 4000000, 'excessive PTY output')
        return True

    def exited(self):
        if not self.alive:
            return True
        pid, status = os.waitpid(self.pid, os.WNOHANG)
        if pid:
            self.alive = False
            self.status = os.waitstatus_to_exitcode(status)
            return True
        return False

    def wait(self, predicate, description, timeout=20):
        deadline = time.monotonic() + timeout
        while not predicate():
            self.read()
            if self.exited():
                self.settle()
                raise RuntimeError(description + ': game exited '
                                   + str(self.status) + '\n' + self.text())
            require(time.monotonic() < deadline,
                    description + ': timed out\n' + self.text())

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(0.2):
            require(time.monotonic() < deadline, 'PTY never became idle')

    def send(self, data):
        require(not self.exited(), 'cannot send keys after exit')
        os.write(self.fd, data)

    def prompt(self, text, key):
        self.wait(lambda: text in self.text(), 'missing ' + text)
        self.settle()
        self.send(key)
        self.settle()

    def live(self):
        text = self.text()
        if NAME not in text or 'Lvl:' not in text or 'Inventory' in text:
            return None
        # The town has wandering humans whose glyph is also '@' (LAVENDER).
        # A healthy player's map glyph is WHEAT, xterm index 229 (ffffaf).
        # Require that actual style, then tie coordinates to the native save.
        positions = [(x, y) for y in range(17) for x in range(67)
                     if self.screen.buffer[y][x].data == '@'
                     and self.screen.buffer[y][x].fg == 'ffffaf']
        hp = re.search(r'\bHP\s+(\d+)\s*/\s*(\d+)', text)
        mp = re.search(r'\bMP\s+(\d+)\s*/\s*(\d+)', text)
        xp = re.search(r'\bXP\s+(\d+)\s*/\s*(\d+)', text)
        turn = re.search(r'\bT\s+(\d+)\b', text)
        place = re.search(r'Lvl:\s*([^\n]+)', text)
        if len(positions) != 1 or not all((hp, mp, xp, turn, place)):
            return None
        stats = {}
        for stat in ('STR', 'DEX', 'CON', 'INT', 'WIS'):
            match = re.search(r'\b' + stat + r'\s+(\d+)', text)
            if not match:
                return None
            stats[stat] = int(match[1])
        return {'name': NAME, 'position': list(positions[0]),
                'hp': list(map(int, hp.groups())),
                'mp': list(map(int, mp.groups())),
                'xp': list(map(int, xp.groups())), 'stats': stats,
                'turn': int(turn[1]), 'place': place[1].strip()}

    def gameplay(self):
        self.wait(lambda: self.live() is not None, 'missing gameplay HUD/map')
        self.settle()
        state = self.live()
        require(state is not None and state['hp'][0] > 0,
                'missing settled living character')
        return state

    def enter(self, resume):
        self.prompt('Welcome to the game of NLarn!', b' ')
        self.prompt('Continue saved Game' if resume else 'New Game', b'a')
        if not resume:
            self.prompt('By what name shall ', (NAME + '\r').encode())
            self.prompt('Are you male or female?', b'm')
            self.prompt('Choose a character build', b'a')
        return self.gameplay()

    def inventory(self):
        before = self.gameplay()
        self.send(b'i')
        self.wait(lambda: 'Inventory' in self.text(), 'missing native inventory')
        self.settle()
        rows = [row.strip() for row in self.screen.display
                if ('dagger' in row.lower() or 'leather' in row.lower()) and '*' in row]
        require(len(rows) == 2 and all('*' in row for row in rows),
                'native inventory did not show equipped dagger and leather armour')
        self.send(b'\x1b')
        after = self.gameplay()
        require(before == after, 'inventory inspection changed character/turn')
        return rows

    def move(self):
        before = self.gameplay()
        x, y = before['position']
        # Select a visibly empty neighbouring town tile and verify that the
        # resulting action really moves one square and advances native time.
        for key, dx, dy in ((b'l', 1, 0), (b'h', -1, 0), (b'j', 0, 1),
                            (b'k', 0, -1), (b'n', 1, 1), (b'b', -1, 1),
                            (b'u', 1, -1), (b'y', -1, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < 67 and 0 <= ny < 17 \
                    and self.screen.display[ny][nx] in '."':
                self.send(key)
                self.wait(lambda: self.live() is not None and
                          self.live()['turn'] > before['turn'],
                          'legal movement failed to advance native turn')
                after = self.gameplay()
                require(after['position'] == [nx, ny], 'movement missed chosen tile')
                require(after['place'] == before['place'], 'town movement changed level')
                return after
        raise RuntimeError('no visibly safe adjacent town floor\n' + self.text())

    def save_quit(self):
        self.send(b'\x13')
        deadline = time.monotonic() + 20
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'native save/quit timed out')
        self.settle()
        require(self.status == 0, 'native save/quit failed: ' + str(self.status))

    def close(self):
        if self.alive:
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        self.transcript.extend(self.raw)
        os.close(self.fd)


def screen_matches_save(screen, save):
    player = save['player']
    packed = int(player['position'])
    require(screen['position'] == [packed & 4095, (packed >> 12) & 4095]
            and packed >> 24 == 0, 'screen position differs from native town save')
    require(screen['name'] == player['name'] and screen['turn'] == save['gtime'],
            'screen identity/time differs from native save')
    require(screen['hp'] == [player['hp'], player['hp_max']]
            and screen['mp'] == [player['mp'], player['mp_max']]
            and screen['xp'] == [player['level'], player['experience']],
            'screen vitals/experience differ from native save')
    for label, field in (('STR', 'strength'), ('DEX', 'dexterity'),
                         ('CON', 'constitution'), ('INT', 'intelligence'),
                         ('WIS', 'wisdom')):
        require(screen['stats'][label] == player[field],
                'screen ' + label + ' differs from native save')


def isolated(executable, root):
    host_net, host_mount = os.environ['NLARN_HOST_NET'], os.environ['NLARN_HOST_MOUNT']
    require(os.readlink('/proc/self/ns/net') != host_net, 'network namespace unchanged')
    require(os.readlink('/proc/self/ns/mnt') != host_mount, 'mount namespace unchanged')
    require(socket.if_nameindex() == [(1, 'lo')],
            'network namespace exposes non-loopback interfaces')
    mount = shutil.which('mount')
    require(mount is not None, 'realized mount tool missing')
    subprocess.run([mount, '--bind', '/gnu/store', '/gnu/store'], check=True)
    subprocess.run([mount, '-o', 'remount,bind,ro', '/gnu/store'], check=True)
    entries = [line.split() for line in Path('/proc/self/mountinfo').read_text().splitlines()]
    require(any(row[4] == '/gnu/store' and 'ro' in row[5].split(',') for row in entries),
            'store bind mount is not read-only')
    proof = root / 'proof'
    savefile = root / 'home/.nlarn/nlarn.sav'
    transcript = bytearray()
    receipt = {'schema': 'nlarn-gameplay-proof-v1', 'terminal': [ROWS, COLS],
               'network_namespace': os.readlink('/proc/self/ns/net'),
               'store_readonly': True, 'sessions': []}
    highscores = subprocess.run([executable, '--highscores'], check=True,
                               env={'HOME': str(root / 'home'), 'LC_ALL': 'C',
                                    'PATH': '', 'TMPDIR': str(root / 'tmp')},
                               capture_output=True, timeout=10)
    require(b'NLarn Hall of Fame' in highscores.stdout,
            'native highscore interface failed')
    require(not any((root / 'home').iterdir()),
            'highscores unexpectedly created user state')
    (proof / 'highscores.txt').write_bytes(highscores.stdout)
    receipt['highscores_no_user_state'] = True
    try:
        first = Session(executable, root, transcript)
        try:
            initial = first.enter(False)
            require(initial['turn'] == 1 and initial['stats'] ==
                    {'STR': 20, 'DEX': 15, 'CON': 16, 'INT': 12, 'WIS': 12},
                    'fixed strong character preset was not applied')
            first_inventory = first.inventory()
            advanced = first.move()
            (proof / 'first-pre-save.txt').write_text(first.text())
            first.save_quit()
        finally:
            first.close()
        require(savefile.is_file(), 'first native save absent')
        shutil.copyfile(savefile, proof / 'first.sav')
        saved = native_save(savefile)
        screen_matches_save(advanced, saved)
        persisted = native_player(saved)
        write_json(proof / 'first-native.json', saved)
        receipt['sessions'].append({'initial': initial, 'saved': advanced,
                                    'inventory': first_inventory})
        second = Session(executable, root, transcript)
        try:
            restored = second.enter(True)
            require(restored == advanced, 'restored HUD/position/time not exact')
            screen_matches_save(restored, saved)
            restored_inventory = second.inventory()
            require(restored_inventory == first_inventory,
                    'restored actual inventory screen changed')
            (proof / 'restored.txt').write_text(second.text())
            continued = second.move()
            require(continued['turn'] > restored['turn'], 'restored game did not advance')
            # Raw is precisely what the real game emitted up to this live frame.
            # Do not append resets, reconstruct ANSI or include endwin teardown.
            raw = bytes(second.raw)
            text = second.text().encode()
            for variable, data in (('NLARN_RAW_CAPTURE', raw),
                                   ('NLARN_TEXT_CAPTURE', text)):
                if os.environ.get(variable):
                    Path(os.environ[variable]).write_bytes(data)
            second.save_quit()
        finally:
            second.close()
        shutil.copyfile(savefile, proof / 'continued.sav')
        final_save = native_save(savefile)
        screen_matches_save(continued, final_save)
        final_player = native_player(final_save)
        require(final_player['inventory_items'] == persisted['inventory_items'],
                'native item identities or contents changed across restore')
        fields = ('name', 'sex', 'strength', 'intelligence', 'wisdom',
                  'constitution', 'dexterity', 'hp', 'hp_max', 'mp', 'mp_max',
                  'level', 'experience', 'inventory')
        fields += tuple(key for key in saved['player'] if key.startswith('eq_'))
        for field in fields:
            require(final_save['player'][field] == saved['player'][field],
                    'native restored player field changed: ' + field)
        require(final_save['gtime'] > saved['gtime'] and
                final_save['player']['position'] != saved['player']['position'],
                'native resave has no further movement/turn')
        write_json(proof / 'continued-native.json', final_save)
        receipt['sessions'].append({'restored': restored, 'continued': continued,
                                    'inventory': restored_inventory})
        receipt['native_state'] = {'first': persisted, 'continued': final_player}
        receipt['save_sha256'] = {name: hashlib.sha256((proof / name).read_bytes()).hexdigest()
                                  for name in ('first.sav', 'continued.sav')}
        write_json(proof / 'receipt.json', receipt)
        print('NLarn native gameplay, exact restore, further turn and resave passed')
    finally:
        (proof / 'transcript.raw').write_bytes(transcript)
        if os.environ.get('NLARN_TRANSCRIPT'):
            Path(os.environ['NLARN_TRANSCRIPT']).write_bytes(transcript)


def main():
    inside = len(sys.argv) == 4 and sys.argv[1] == '--inside'
    args = sys.argv[2:] if inside else sys.argv[1:]
    require(len(args) == 2, 'usage: nlarn-pty-runner.py NLARN FRESH_ROOT')
    executable, root_arg = args
    root = Path(root_arg).resolve()
    if inside:
        isolated(executable, root)
        return
    require(not any((root / 'home').iterdir()), 'HOME must be fresh')
    require(all((root / directory).is_dir() for directory in
                ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work', 'proof')),
            'missing isolated scratch directories')
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized unshare missing')
    env = {key: os.environ[key] for key in CAPTURES if os.environ.get(key)}
    for key in ('GUIX_PYTHONPATH', 'PYTHONPATH'):
        if os.environ.get(key):
            env[key] = os.environ[key]
    env.update({'PATH': os.environ['PATH'], 'LC_ALL': 'C',
                'HOME': str(root / 'home'), 'TMPDIR': str(root / 'tmp'),
                'NLARN_HOST_NET': os.readlink('/proc/self/ns/net'),
                'NLARN_HOST_MOUNT': os.readlink('/proc/self/ns/mnt')})
    command = [unshare, '--user', '--map-root-user', '--mount', '--propagation',
               'private', '--net', '--pid', '--mount-proc', '--kill-child', '--fork',
               sys.executable, '-B', str(Path(__file__).resolve()), '--inside', executable, str(root)]
    process = subprocess.Popen(command, env=env, start_new_session=True)
    try:
        status = process.wait(timeout=120)
    except BaseException:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
        raise
    require(status == 0, 'isolated proof failed (namespace denial is not a pass): ' + str(status))


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print('nlarn-pty-runner: ' + str(error), file=sys.stderr)
        sys.exit(1)
