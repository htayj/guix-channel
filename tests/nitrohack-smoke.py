#!/usr/bin/env python3
"""Native NitroHack curses gameplay, exact save continuity and offline PTY proof.

Only the ordinary installed launcher runs; Python/pyte are test dependencies.
Every .pty is verbatim terminal bytes, including full-screen pre-save prefixes.
Map/HUD/inventory comparisons preserve all cells and item descriptions; no
normalization hides game changes. No fixture, injected screen or engine state.
"""
import argparse
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
import tempfile
import termios
import time

import pyte

ROWS, COLS = 30, 100
NAME = 'OmpProof'
MAP_Y, MAP_ROWS, MAP_COLS = 4, 21, 80
UI_CONFIG = ('frame=false\nsidebar=false\nstatus3=false\nmsgheight=4\n'
             'graphics=plain\nblink=false\ntime=true\n')
GAME_CONFIG = ('autopickup=false\nlegacy=false\nrole=Valkyrie\nrace=human\n'
               'gender=female\nalign=lawful\n')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


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
    def __init__(self, executable, env, root, output, number):
        self.output = output
        self.label = 'session-' + str(number)
        self.raw_file = (output / (self.label + '.pty')).open('xb')
        self.raw = bytearray()
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.status = None
        self.eof = False
        self.deadline = time.monotonic() + 80
        # -@ fills only unspecified character choices; -p/-r stay fixed.
        self.argv = [executable, '-@', '-u', NAME, '-p', 'Valkyrie', '-r', 'human']
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(executable, self.argv, env)
            except BaseException:
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display)

    def read(self, delay=0.1):
        require(time.monotonic() < self.deadline, 'session deadline: ' + self.text())
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
        require(len(self.raw) < 8000000, 'excessive native terminal output')
        return True

    def exited(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
        return self.status is not None

    def send(self, keys):
        require(not self.exited(), 'native process already exited')
        os.write(self.fd, keys.encode('ascii'))

    def settle(self):
        while self.read(0.25):
            pass

    def wait(self, predicate, description, more=True):
        end = time.monotonic() + 15
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
        (self.output / (stem + '.pty')).write_bytes(self.raw)
        (self.output / (stem + '.screen.txt')).write_text(self.text() + '\n')
        return stem

    def menu(self):
        self.wait(lambda: 'new game' in self.text() and 'load game' in self.text(),
                  'native main menu', more=False)

    def startup(self, number):
        self.menu()
        self.snapshot('main-menu')
        self.send('n' if number == 1 else 'l')
        if number != 1:
            self.wait(lambda: 'saved games' in self.text() and NAME in self.text(),
                      'native save selection', more=False)
            self.snapshot('save-selection')
            require('crashed' not in self.text() and 'in progress' not in self.text(),
                    'load menu does not describe a cleanly saved game')
            self.send('a')
        self.wait(lambda: NAME in self.screen.display[25]
                  and 'HP:' in self.screen.display[26], 'native live game')
        raw = self.raw.decode('latin1')
        require(('welcome to NitroHack' in raw) if number == 1
                else ('welcome back to NitroHack' in raw or 'Welcome back' in raw),
                'native new/restore welcome missing')

    def live(self, label):
        self.send('\x12')  # Ordinary curses redraw; no world turn.
        self.settle()
        lines = self.screen.display
        hud = lines[25:27]
        require(NAME in hud[0] and 'St:' in hud[0] and 'HP:' in hud[1],
                'classic native HUD absent\n' + self.text())
        turn = re.search(r'\bT:\s*(\d+)', hud[1])
        hp = re.search(r'\bHP:\s*(\d+)\((\d+)\)', hud[1])
        require(turn is not None and hp is not None and int(hp.group(1)) > 0,
                'turn/health absent or player dead')
        stats = {}
        for stat in ('St', 'Dx', 'Co', 'In', 'Wi', 'Ch'):
            match = re.search(r'\b' + stat + r':\s*(\S+)', hud[0])
            require(match is not None, 'missing native stat ' + stat)
            stats[stat] = match.group(1)
        dungeon = [line[:MAP_COLS] for line in lines[MAP_Y:MAP_Y + MAP_ROWS]]
        x, y = self.screen.cursor.x, self.screen.cursor.y - MAP_Y
        require(0 <= x < MAP_COLS and 0 <= y < MAP_ROWS and dungeon[y][x] == '@',
                'native curses cursor does not identify player\n' + self.text())
        require(any(c in ''.join(dungeon) for c in '.-|'), 'empty dungeon')
        state = {'hud': hud, 'stats': stats, 'turn': int(turn.group(1)),
                 'hp': [int(hp.group(1)), int(hp.group(2))],
                 'map': dungeon, 'player': [x, y],
                 'coordinate_kind': 'zero-based native 80x21 map viewport'}
        write_json(self.output / (self.snapshot(label) + '.json'), state)
        return state

    def inventory(self, before, label):
        self.send('i')
        self.wait(lambda: 'Inventory' in self.text(), 'native inventory menu', more=False)
        items = {}
        for page in range(20):
            self.settle()
            lines = self.screen.display
            title_y = next(y for y, line in enumerate(lines) if 'Inventory' in line)
            title_x = lines[title_y].index('Inventory')
            left = title_x - 2
            border = lines[title_y][left]
            require(border in '|│x', 'native inventory frame absent')
            right = lines[title_y].find(border, title_x + len('Inventory'))
            require(right > title_x, 'native inventory right edge absent')
            rows = []
            for line in lines[title_y + 2:]:
                if line[left] != border or line[right] != border:
                    break
                rows.append(line[left + 2:right - 1])
            self.snapshot(label + '-page-' + str(page + 1))
            require(rows, 'native inventory has no content rows')
            for line in rows:
                match = re.match(r'([a-zA-Z$])\s+[-+]\s+(.+?)\s*$', line)
                if match:
                    letter, description = match.groups()
                    require(letter not in items or items[letter] == description,
                            'inventory row changed while paginating')
                    items[letter] = description
            before_page = self.text()
            self.send('>')  # Native page-down stays open even at the bottom.
            self.settle()
            if self.text() == before_page:
                break
        else:
            raise RuntimeError('native inventory pagination did not reach bottom')
        require(items, 'native inventory item rows absent')
        self.send('\x1b')
        self.settle()
        require(self.live(label + '-closed') == before,
                'inventory inspection changed native HUD/turn/map')
        return [{'letter': letter, 'description': description}
                for letter, description in sorted(items.items())]

    def capture(self, label):
        state = self.live(label)
        state['inventory'] = self.inventory(state, label + '-inventory')
        write_json(self.output / (self.label + '-' + label + '-complete.json'), state)
        # Complete full-screen real byte prefix, ending after menu closure.
        self.snapshot(label + '-fullscreen')
        return state

    def advance(self, before, label):
        x, y = before['player']
        moved = None
        for dx, dy, key in ((-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j')):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < MAP_COLS and 0 <= ny < MAP_ROWS):
                continue
            if before['map'][ny][nx] != '.':
                continue
            self.send(key)
            self.wait(lambda: '--More--' not in self.text(), 'native movement')
            moved = self.live(label + '-movement')
            require(moved['turn'] > before['turn'] and moved['player'] != [x, y],
                    'movement did not move player and advance turn')
            break
        require(moved is not None, 'native dungeon has no adjacent visible floor')
        current = moved
        for number in range(3):
            self.send('s')
            self.wait(lambda: '--More--' not in self.text(), 'native search')
            following = self.live(label + '-search-' + str(number + 1))
            require(following['turn'] > current['turn'], 'search did not advance turn')
            current = following
        return self.capture(label)

    def save_exit(self):
        self.send('S')
        self.wait(lambda: 'save' in self.text().lower() and '[yn' in self.text(),
                  'native save confirmation', more=False)
        self.snapshot('save-confirmation')
        self.send('y')
        self.menu()
        self.snapshot('saved-main-menu')
        self.send('q')
        end = time.monotonic() + 15
        while not self.exited() or not self.eof:
            self.read()
            require(time.monotonic() < end, 'native menu quit did not exit')
        require(self.status == 0, 'native save/exit status: ' + str(self.status))
        self.snapshot('saved-exit')

    def close(self):
        if not self.exited():
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.status = -signal.SIGKILL
        os.close(self.fd)
        self.raw_file.close()


def fingerprint(path):
    if not path.exists() and not path.is_symlink():
        return None
    if path.is_symlink():
        return {'link': os.readlink(path)}
    if path.is_file():
        return {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'size': path.stat().st_size}
    return {str(child.relative_to(path)): fingerprint(child)
            for child in sorted(path.iterdir())}


def native_save(state, output, number):
    files = list((state / 'save').glob('*.nhgame'))
    require(len(files) == 1 and files[0].is_file() and files[0].stat().st_size > 0,
            'expected one nonempty native .nhgame in private XDG config')
    copy = output / ('session-' + str(number) + '.nhgame')
    shutil.copyfile(files[0], copy)
    return {'path': str(files[0].relative_to(state)),
            'size': copy.stat().st_size,
            'sha256': hashlib.sha256(copy.read_bytes()).hexdigest()}


def isolation_receipt():
    network = os.readlink('/proc/self/ns/net')
    mount_namespace = os.readlink('/proc/self/ns/mnt')
    require(network != os.environ['NITROHACK_HOST_NET'], 'network namespace unchanged')
    require(mount_namespace != os.environ['NITROHACK_HOST_MOUNT'], 'mount namespace unchanged')
    interfaces = socket.if_nameindex()
    require(interfaces == [(1, 'lo')], 'network namespace has external interfaces')
    mount = shutil.which('mount')
    require(mount is not None, 'realized mount missing')
    subprocess.run([mount, '--bind', '/gnu/store', '/gnu/store'], check=True)
    subprocess.run([mount, '-o', 'remount,bind,ro', '/gnu/store'], check=True)
    entries = [line for line in Path('/proc/self/mountinfo').read_text().splitlines()
               if line.split()[4] == '/gnu/store']
    require(entries and 'ro' in entries[-1].split()[5].split(','),
            'store bind mount not read-only')
    return {'host_network_namespace': os.environ['NITROHACK_HOST_NET'],
            'network_namespace': network, 'network_interfaces': interfaces,
            'host_mount_namespace': os.environ['NITROHACK_HOST_MOUNT'],
            'mount_namespace': mount_namespace, 'store_readonly': True,
            'store_mountinfo': entries[-1]}


def launch_isolated(executable, output):
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized unshare missing')
    variables = ('PATH', 'HOME', 'TMPDIR', 'GUIX_PYTHONPATH', 'PYTHONPATH',
                 'TERMINFO', 'TERMINFO_DIRS', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME',
                 'XDG_STATE_HOME')
    env = {key: os.environ[key] for key in variables if os.environ.get(key)}
    env.update({'LC_ALL': 'C', 'NITROHACK_HOST_NET': os.readlink('/proc/self/ns/net'),
                'NITROHACK_HOST_MOUNT': os.readlink('/proc/self/ns/mnt')})
    command = [unshare, '--user', '--map-root-user', '--mount', '--propagation',
               'private', '--net', '--pid', '--mount-proc', '--kill-child', '--fork',
               sys.executable, '-B', str(Path(__file__).resolve()), '--inside',
               executable, '--output', str(output)]
    process = subprocess.Popen(command, env=env, start_new_session=True)
    try:
        status = process.wait(timeout=300)
    except BaseException:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
        raise
    require(status == 0, 'isolated proof failed (namespace denial is not a pass): ' + str(status))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', help='installed bin/nitrohack launcher')
    parser.add_argument('--output', required=True, type=Path, help='fresh evidence directory')
    parser.add_argument('--inside', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    executable = str(Path(args.executable).resolve())
    require(os.access(executable, os.X_OK), 'installed NitroHack not executable')
    output = args.output.absolute()
    require(not output.exists(), 'evidence already exists; choose fresh --output')
    if not args.inside:
        launch_isolated(executable, output)
        return
    output.mkdir(parents=True, mode=0o700)
    watched = {Path.home() / '.config/NitroHack', Path.cwd() / 'NitroHack',
               Path.cwd() / 'save', Path.cwd() / 'log', Path(executable).parent.parent}
    if os.environ.get('XDG_CONFIG_HOME'):
        watched.add(Path(os.environ['XDG_CONFIG_HOME']) / 'NitroHack')
    initial = {str(path): fingerprint(path) for path in watched}
    report = {'success': False, 'issue': 456, 'executable': executable,
              'source_commit': '21b9774b24efbdafdd20e152f9b1e5ed2a7b4150',
              'terminal': {'rows': ROWS, 'columns': COLS},
              'ui_config': UI_CONFIG, 'game_config': GAME_CONFIG,
              'sessions': [], 'continuity': []}
    session = None
    try:
        report['isolation'] = isolation_receipt()
        with tempfile.TemporaryDirectory(prefix='nitrohack-proof-', dir='/tmp') as directory:
            root = Path(directory)
            for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
                (root / name).mkdir(mode=0o700)
            state = root / 'config' / 'NitroHack'
            state.mkdir()
            (state / 'curses.conf').write_text(UI_CONFIG)
            (state / 'NitroHack.conf').write_text(GAME_CONFIG)
            env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color',
                   'LC_ALL': 'C', 'PATH': '', 'TMPDIR': str(root / 'tmp')}
            for variable, subdir in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                     ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                     ('XDG_RUNTIME_DIR', 'runtime')):
                env[variable] = str(root / subdir)
            previous = None
            previous_save = None
            for number in range(1, 4):
                session = Session(executable, env, root, output, number)
                session.startup(number)
                start = session.capture('first-live' if number == 1 else 'restored')
                if previous is not None:
                    require(start == previous, 'restored HUD/map/player/turn/inventory differs')
                    report['continuity'].append({'from': number - 1, 'to': number,
                                                 'exact_fields_map_inventory': True})
                advanced = session.advance(start, 'advanced')
                session.save_exit()
                saved = native_save(state, output, number)
                if previous_save is not None:
                    require(saved['path'] == previous_save['path'], 'resume created a new game file')
                    require(saved['sha256'] != previous_save['sha256'], 'further turns not resaved')
                report['sessions'].append({'argv': session.argv, 'initial': start,
                                           'advanced': advanced, 'native_save': saved,
                                           'exit_status': session.status,
                                           'fullscreen_prefix': session.label + '-advanced-fullscreen.pty'})
                previous, previous_save = advanced, saved
                session.close()
                session = None
            for subdir in ('home', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
                require(not list((root / subdir).iterdir()), 'state escaped private config: ' + subdir)
            require(list((root / 'config').iterdir()) == [state], 'unexpected XDG config sibling')
            for path in root.rglob('*'):
                require(not path.is_symlink(), 'runtime symlink could escape private root')
            require(all(fingerprint(Path(path)) == value for path, value in initial.items()),
                    'game changed original home/caller state/store')
            report['private_footprint'] = {str(p.relative_to(root)): p.stat().st_size
                                           for p in root.rglob('*') if p.is_file()}
            report['isolation'].update({'private_environment': env,
                                        'working_directory_empty': True,
                                        'host_game_state_unchanged': True,
                                        'runtime_symlinks_absent': True})
            report['success'] = True
        write_json(output / 'continuity.json', report)
        print('NITROHACK SMOKE OK')
    except BaseException as error:
        report['error'] = str(error)
        if session is not None:
            session.snapshot('failure')
            session.close()
        write_json(output / 'continuity.json', report)
        raise


if __name__ == '__main__':
    main()
