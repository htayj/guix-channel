#!/usr/bin/env python3
"""Drive three ordinary UnNetHack tty processes; Python/pyte are test-only.

Evidence is real PTY output and its interpreted screen, never generated game
state. Map continuity compares all 80x21 displayed cells without normalization.
The native seed controls dungeon layout, not every character RNG draw; continuity
is within this run, not a comparison with a fixture from another run.

The shell realizes Python/pyte/util-linux/coreutils and compares NARs. This
driver owns its offline user/mount/network/PID namespaces and fails closed.
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

ROWS, COLS = 24, 100
NAME = 'OmpProof'
SEED = 424242
# This engine has no separate -g/-a flags. Its documented -u suffix supplies
# gender and alignment on the command line, with explicit -p/-r as well.
PLAYER = NAME + '-Val-Hum-Fem-Law'
OPTIONS = ('seed:424242,windowtype:tty,statuslines:2,time,ascii_map,'
           '!IBMgraphics,!DECgraphics,!color,!statuscolors,!hitpointbar,'
           '!legacy,!news,!splash_screen,!autopickup,!show_dgn_name,'
           'vanilla_ui_behavior,menustyle:full,number_pad:0')


def require(condition, description):
    if not condition:
        raise RuntimeError(description)


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
        self.raw_path = output / (self.label + '.pty')
        self.raw_file = self.raw_path.open('xb')
        self.raw = bytearray()
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.stream.use_utf8 = False  # C locale, native tty/DEC character sets.
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.status = None
        self.eof = False
        self.deadline = time.monotonic() + 60
        self.argv = [executable, '-u', PLAYER, '-p', 'Valkyrie', '-r', 'human']
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
        require(time.monotonic() < self.deadline,
                self.label + ': global deadline exceeded\n' + self.text())
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
        require(not self.exited(), self.label + ': process already exited')
        os.write(self.fd, keys.encode('ascii'))

    def settle(self):
        # Drain output, not a surrogate for the action-specific assertions.
        while self.read(0.25):
            pass

    def wait(self, predicate, what, more=True):
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
            require(not self.exited(), what + ': exited\n' + self.text())
            require(time.monotonic() < end, what + ': timed out\n' + self.text())

    def snapshot(self, label):
        stem = self.label + '-' + label
        (self.output / (stem + '.pty')).write_bytes(self.raw)
        (self.output / (stem + '.screen.txt')).write_text(self.text() + '\n')
        return stem

    def live(self, label):
        self.send('\x12')  # Native redraw, no turns, no synthetic screen bytes.
        self.settle()
        lines = self.screen.display
        hud = lines[22:24]
        require('St:' in hud[0] and 'HP:' in hud[1],
                'not a native tty HUD\n' + self.text())
        require(NAME in hud[0] and 'Lawful' in hud[0], 'wrong player/alignment')
        stats = {}
        for stat in ('St', 'Dx', 'Co', 'In', 'Wi', 'Ch'):
            match = re.search(r'\b' + stat + r':\s*(\S+)', hud[0])
            require(match is not None, 'missing HUD stat ' + stat)
            stats[stat] = match.group(1)
        match = re.search(r'\bT:\s*(\d+)', hud[1])
        require(match is not None, 'time option not visible in native HUD')
        hp = re.search(r'\bHP:\s*(\d+)\((\d+)\)', hud[1])
        require(hp is not None and int(hp.group(1)) > 0, 'player is not alive')
        require(re.search(r'\bDlvl:\s*1\b', hud[1]) is not None,
                'expected first dungeon level')
        # Native tty map is COLNO=80, ROWNO=21, offy=1. Preserve spaces,
        # walls, monsters, objects and player; do not mask dynamic cells.
        dungeon = [line[:80] for line in lines[1:22]]
        x, y = self.screen.cursor.x, self.screen.cursor.y - 1
        require(0 <= x < 80 and 0 <= y < 21 and dungeon[y][x] == '@',
                'native tty cursor does not identify the displayed player')
        require(any(c in ''.join(dungeon) for c in '.-|'), 'empty dungeon map')
        stem = self.snapshot(label)
        state = {'hud': hud, 'stats': stats, 'turn': int(match.group(1)),
                 'hp': [int(hp.group(1)), int(hp.group(2))],
                 'map': dungeon, 'player': [x, y],
                 'coordinate_kind': 'zero-based native 80x21 map viewport'}
        write_json(self.output / (stem + '.json'), state)
        return state

    def inventory(self, before, label):
        self.send('i')
        self.wait(lambda: re.search(r'\(end\)|\(\d+ of \d+\)', self.text()),
                  'complete inventory menu', more=False)
        items, seen_pages = [], set()
        for page in range(20):
            text = self.text()
            marker = re.search(r'\(end\)|\((\d+) of (\d+)\)', text)
            require(marker is not None, 'inventory page marker missing')
            page_key = marker.group(0)
            require(page_key not in seen_pages, 'inventory pagination stalled')
            seen_pages.add(page_key)
            self.snapshot(label + '-page-' + str(page + 1))
            for line in self.screen.display:
                item = re.match(r'^\s*([a-zA-Z$])\s+[-+]\s+(.+?)\s*$', line)
                if item:
                    items.append({'letter': item.group(1), 'description': item.group(2)})
            if marker.group(0) == '(end)' or marker.group(1) == marker.group(2):
                self.send(' ')
                break
            self.send('>')
            expected = int(marker.group(1)) + 1
            self.wait(lambda: '(' + str(expected) + ' of ' in self.text(),
                      'next inventory page', more=False)
        else:
            raise RuntimeError('too many inventory pages')
        self.settle()
        require(items and len({item['letter'] for item in items}) == len(items),
                'inventory must contain distinct exact item rows')
        after = self.live(label + '-closed')
        require(after == before, 'inventory inspection changed HUD, turn or map')
        return items

    def capture(self, label):
        state = self.live(label)
        state['inventory'] = self.inventory(state, label + '-inventory')
        write_json(self.output / (self.label + '-' + label + '-complete.json'), state)
        return state

    def advance(self, before, label):
        # Move onto a visible adjacent floor square, then search repeatedly:
        # actual movement and world turns, not only non-turn menu commands.
        x, y = before['player']
        moved = None
        for dx, dy, key in ((-1, 0, 'h'), (1, 0, 'l'), (0, -1, 'k'), (0, 1, 'j')):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < 80 and 0 <= ny < 21):
                continue
            if before['map'][ny][nx] != '.':
                continue
            self.send(key)
            self.wait(lambda: '--More--' not in self.text(), 'native movement')
            moved = self.live(label + '-movement')
            require(moved['turn'] > before['turn'] and moved['player'] != [x, y],
                    'floor movement did not move player and advance turn')
            break
        require(moved is not None, 'fixed dungeon has no adjacent visible floor for movement')
        current = moved
        for number in range(5):
            self.send('s')
            self.wait(lambda: '--More--' not in self.text(), 'native search turn')
            following = self.live(label + '-search-' + str(number + 1))
            require(following['turn'] > current['turn'], 'search did not advance turn')
            current = following
        require(current['turn'] >= before['turn'] + 6, 'insufficient meaningful world turns')
        return self.capture(label)

    def save(self):
        self.send('S')
        self.wait(lambda: 'Really save?' in self.text(), 'native save confirmation', more=False)
        self.send('y')
        end = time.monotonic() + 15
        while not self.exited() or not self.eof:
            self.read()
            if '--More--' in self.text() and not self.exited():
                self.send(' ')
            require(time.monotonic() < end, 'native save process did not exit')
        require(self.status == 0, 'native save exited with status ' + str(self.status))
        require(b'Saving' in self.raw, 'native save message absent')
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


def save_file(state, output, label):
    files = [p for p in (state / 'saves').rglob('*') if p.is_file()]
    require(len(files) == 1 and files[0].stat().st_size > 0,
            'expected exactly one nonempty native save under private data/unnethack/saves')
    copy = output / (label + '.native-save')
    shutil.copyfile(files[0], copy)
    return {'path': str(files[0].relative_to(state)),
            'size': copy.stat().st_size,
            'sha256': hashlib.sha256(copy.read_bytes()).hexdigest()}


def isolation_receipt():
    host_net = os.environ['UNNETHACK_HOST_NET']
    host_mount = os.environ['UNNETHACK_HOST_MOUNT']
    network = os.readlink('/proc/self/ns/net')
    mount_namespace = os.readlink('/proc/self/ns/mnt')
    require(network != host_net, 'network namespace unchanged')
    require(mount_namespace != host_mount, 'mount namespace unchanged')
    interfaces = socket.if_nameindex()
    require(interfaces == [(1, 'lo')],
            'network namespace exposes non-loopback interfaces')
    mount = shutil.which('mount')
    require(mount is not None, 'realized mount tool missing')
    subprocess.run([mount, '--bind', '/gnu/store', '/gnu/store'], check=True)
    subprocess.run([mount, '-o', 'remount,bind,ro', '/gnu/store'], check=True)
    entries = [line for line in Path('/proc/self/mountinfo').read_text().splitlines()
               if line.split()[4] == '/gnu/store']
    require(entries and 'ro' in entries[-1].split()[5].split(','),
            'store bind mount is not read-only')
    return {'host_network_namespace': host_net, 'network_namespace': network,
            'host_mount_namespace': host_mount, 'mount_namespace': mount_namespace,
            'network_interfaces': interfaces, 'store_readonly': True,
            'store_mountinfo': entries[-1]}


def launch_isolated(executable, output):
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized unshare missing')
    variables = ('PATH', 'HOME', 'TMPDIR', 'GUIX_PYTHONPATH', 'PYTHONPATH',
                 'TERMINFO', 'TERMINFO_DIRS', 'XDG_DATA_HOME', 'XDG_STATE_HOME',
                 'XDG_CONFIG_HOME')
    env = {key: os.environ[key] for key in variables if os.environ.get(key)}
    env.update({'LC_ALL': 'C',
                'UNNETHACK_HOST_NET': os.readlink('/proc/self/ns/net'),
                'UNNETHACK_HOST_MOUNT': os.readlink('/proc/self/ns/mnt')})
    command = [unshare, '--user', '--map-root-user', '--mount', '--propagation',
               'private', '--net', '--pid', '--mount-proc', '--kill-child', '--fork',
               sys.executable, '-B', str(Path(__file__).resolve()), '--inside',
               executable, '--output', str(output)]
    process = subprocess.Popen(command, env=env, start_new_session=True)
    try:
        status = process.wait(timeout=240)
    except BaseException:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
        raise
    require(status == 0,
            'isolated proof failed (namespace denial is not a pass): ' + str(status))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', help='installed bin/unnethack launcher')
    parser.add_argument('--output', required=True, type=Path, help='new evidence directory')
    parser.add_argument('--inside', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    executable = str(Path(args.executable).resolve())
    require(os.access(executable, os.X_OK), 'installed UnNetHack is not executable')
    output = args.output.absolute()
    require(not output.exists(), 'evidence directory already exists; choose a fresh --output')
    if not args.inside:
        launch_isolated(executable, output)
        return
    output.mkdir(parents=True, mode=0o700)
    original_home = Path.home()
    watched = {original_home / '.nethackrc', original_home / '.unnethackrc',
               original_home / '.local/share/unnethack',
               original_home / '.local/state/unnethack', Path.cwd() / 'saves',
               Path.cwd() / 'bones', Path.cwd() / 'level', Path.cwd() / 'dumps',
               Path(executable).parent.parent}
    for variable in ('XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CONFIG_HOME'):
        if os.environ.get(variable):
            watched.add(Path(os.environ[variable]) / 'unnethack')
    initial = {str(path): fingerprint(path) for path in watched}
    report = {'success': False, 'executable': executable, 'seed': SEED,
              'options': OPTIONS, 'sessions': [], 'continuity': []}
    session = None
    try:
        report['isolation'] = isolation_receipt()
        with tempfile.TemporaryDirectory(prefix='unnethack-proof-', dir='/tmp') as directory:
            root = Path(directory)
            for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
                (root / name).mkdir(mode=0o700)
            options_path = root / 'config' / 'native-options'
            options_path.write_text('OPTIONS=' + OPTIONS + '\n')
            env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color',
                   'LC_ALL': 'C', 'PATH': '', 'TMPDIR': str(root / 'tmp'),
                   'MAIL': str(root / 'tmp' / 'no-mailbox'),
                   'NETHACKOPTIONS': '@' + str(options_path)}
            # Guix ncurses may require its explicit read-only terminfo location.
            for variable in ('TERMINFO', 'TERMINFO_DIRS'):
                if os.environ.get(variable):
                    env[variable] = os.environ[variable]
            for variable, subdir in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                     ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                     ('XDG_RUNTIME_DIR', 'runtime')):
                env[variable] = str(root / subdir)
            state = root / 'data' / 'unnethack'
            previous = None
            for number in range(1, 4):
                session = Session(executable, env, root, output, number)
                session.wait(lambda: NAME in session.screen.display[22]
                             and 'HP:' in session.screen.display[23], 'native startup')
                raw = session.raw.decode('latin1')
                if number == 1:
                    require('welcome to UnNetHack' in raw and 'welcome back' not in raw,
                            'first process must start a fresh native game')
                else:
                    require('Restoring save file' in raw and 'welcome back' in raw,
                            'fresh process did not restore native save')
                start = session.capture('first-live' if number == 1 else 'restored')
                if previous is not None:
                    # Includes exact raw HUD rows, every map cell, coordinate,
                    # stats, HP, turn and every inventory letter/description.
                    require(start == previous, 'restored state differs from saved state')
                    require(not any(p.is_file() for p in (state / 'saves').rglob('*')),
                            'normal native restore did not consume its save')
                    report['continuity'].append({'from': number - 1, 'to': number,
                                                 'exact_fields_map_inventory': True})
                advanced = session.advance(start, 'advanced')
                session.save()
                saved = save_file(state, output, 'session-' + str(number))
                report['sessions'].append({'argv': session.argv, 'initial': start,
                                           'advanced': advanced, 'native_save': saved,
                                           'exit_status': session.status})
                previous = advanced
                session.close()
                session = None
            require(not list((root / 'work').iterdir()), 'state escaped into caller working directory')
            for subdir in ('home', 'cache', 'state', 'runtime'):
                require(not list((root / subdir).iterdir()), 'unexpected state outside XDG data: ' + subdir)
            require(list((root / 'config').iterdir()) == [options_path], 'unexpected config write')
            require(list((root / 'data').iterdir()) == [state],
                    'game data escaped its private UnNetHack directory')
            for path in root.rglob('*'):
                require(not path.is_symlink(), 'runtime state symlink could escape private root')
            report['private_footprint'] = {str(p.relative_to(root)): p.stat().st_size
                                           for p in root.rglob('*') if p.is_file()}
            require(all(fingerprint(Path(path)) == value for path, value in initial.items()),
                    'UnNetHack state/config escaped into original home or caller directory')
            report['isolation'].update({'private_environment': env,
                                        'working_directory_empty': True,
                                        'host_game_state_unchanged': True,
                                        'runtime_symlinks_absent': True})
            report['success'] = True
        write_json(output / 'continuity.json', report)
        print('UNNETHACK SMOKE OK')
    except BaseException as error:
        report['error'] = str(error)
        if session is not None:
            session.snapshot('failure')
            session.close()
        write_json(output / 'continuity.json', report)
        raise


if __name__ == '__main__':
    main()
