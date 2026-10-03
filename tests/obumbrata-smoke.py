#!/usr/bin/env python3
"""External native Obumbrata proof: live xterm, ordinary keys and unedited saves.

The save reader below decodes release 1.0.0 log.cc network-byte-order prefix;
it never writes game state. Namespace denial or an uncertain input gate fails.
"""
import argparse
import codecs
import ctypes
import errno
import fcntl
import hashlib
import json
import os
import pty
import tty
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

ROWS, COLS = 24, 80
NAME = 'OmpProof'
SAVE_SUFFIX = Path('com.blackswordsonics/obumbrata/obumbrata.sav')


def require(condition, description):
    if not condition:
        raise RuntimeError(description)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def write_all(fd, data):
    pending = memoryview(data)
    while pending:
        size = os.write(fd, pending)
        require(size > 0, 'PTY write made no progress')
        pending = pending[size:]


def relay(argv):
    """Forward only native PTY bytes to xterm; socket carries player input."""
    program, raw_path, status_path, socket_path, env_path, work = argv
    env = json.loads(Path(env_path).read_text())
    listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    listener.bind(socket_path)
    listener.listen(1)
    listener.settimeout(15)
    pid, master = pty.fork()
    if pid == 0:
        try:
            os.chdir(work)
            fcntl.ioctl(0, termios.TIOCSWINSZ,
                        struct.pack('HHHH', ROWS, COLS, 0, 0))
            os.execve(program, [program], env)
        except BaseException:
            os._exit(127)
    previous = termios.tcgetattr(0)
    transport = None
    reaped = False
    def interrupted(signum, frame):
        raise RuntimeError('native relay interrupted: ' + str(signum))
    signal.signal(signal.SIGHUP, interrupted)
    signal.signal(signal.SIGTERM, interrupted)
    try:
        tty.setraw(0)
        transport, _ = listener.accept()
        with open(raw_path, 'ab', buffering=0) as raw, \
                open(raw_path + '.input', 'xb', buffering=0) as inputs:
            while True:
                ready, _, _ = select.select([0, master, transport], [], [], 1)
                if master in ready:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        break
                    if not chunk:
                        break
                    raw.write(chunk)
                    write_all(1, chunk)
                for source in (0, transport):
                    if source in ready:
                        chunk = (os.read(0, 4096) if source == 0
                                 else transport.recv(4096))
                        require(chunk, 'native relay input transport closed')
                        inputs.write(chunk)
                        write_all(master, chunk)
        _, status = os.waitpid(pid, 0)
        reaped = True
        code = os.waitstatus_to_exitcode(status)
        pending = Path(status_path + '.pending')
        pending.write_text(str(code) + '\n')
        pending.replace(status_path)
        return code
    finally:
        if not reaped:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
        termios.tcsetattr(0, termios.TCSANOW, previous)
        os.close(master)
        if transport is not None:
            transport.close()
        listener.close()
        Path(socket_path).unlink(missing_ok=True)

def mount(source, target, filesystem=None, flags=0):
    # Use the native syscall, not mount(8)'s real-UID-zero policy.  Namespace
    # capabilities are retained by unshare while xterm keeps the caller UID.
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int
    if libc.mount(os.fsencode(source), os.fsencode(target),
                  None if filesystem is None else os.fsencode(filesystem),
                  flags, None) != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), str(target))



def private_tmp(output):
    # Hide host X sockets/locks without changing the caller's evidence inode.
    require(not Path(__file__).resolve().is_relative_to('/tmp') and
            not Path(sys.executable).resolve().is_relative_to('/tmp'),
            'checkout and Python must be outside host /tmp')
    evidence_fd = os.open(output, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)  # MS_NOSUID | MS_NODEV
        os.chmod('/tmp', 0o1777)
        private = Path('/tmp/obumbrata-evidence')
        private.mkdir(mode=0o700)
        mount(f'/proc/self/fd/{evidence_fd}', private, flags=4096)  # MS_BIND
    finally:
        os.close(evidence_fd)
    return private


class Display:
    def __init__(self, output):
        self.env = {key: os.environ[key] for key in
                    ('PATH', 'GUIX_PYTHONPATH', 'PYTHONPATH', 'TERMINFO', 'TERMINFO_DIRS')
                    if os.environ.get(key)}
        self.env['LC_ALL'] = 'C'
        self.root = Path('/tmp/native-display')
        self.root.mkdir(mode=0o700)
        for variable in ('HOME', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_STATE_HOME',
                         'XDG_CACHE_HOME', 'XDG_RUNTIME_DIR', 'TMPDIR'):
            directory = self.root / variable.lower()
            directory.mkdir(mode=0o700)
            self.env[variable] = str(directory)
        self.log = (output / 'xvfb.log').open('xb')
        read_fd, write_fd = os.pipe()
        try:
            self.process = subprocess.Popen(
                ['Xvfb', '-displayfd', str(write_fd), '-screen', '0',
                 '1920x1200x24', '-nolisten', 'tcp', '-ac'],
                pass_fds=(write_fd,), stdout=self.log, stderr=self.log, env=self.env)
        finally:
            os.close(write_fd)
        try:
            require(select.select([read_fd], [], [], 10)[0],
                    'Xvfb did not announce a display')
            display = os.read(read_fd, 64).decode('ascii').strip()
            require(display.isdigit(), 'invalid Xvfb display announcement')
            self.env['DISPLAY'] = ':' + display
        except BaseException:
            self.close()
            raise
        finally:
            os.close(read_fd)

    def close(self):
        self.process.terminate()
        try:
            self.process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        self.log.close()


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
    def __init__(self, executable, env, root, output, number, gui_env):
        self.output = output
        self.label = 'session-' + str(number)
        self.raw_path = output / (self.label + '.pty')
        self.raw_path.touch(exist_ok=False)
        self.raw = bytearray()
        self.offset = 0
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.status = None
        self.eof = False
        self.deadline = time.monotonic() + 120
        self.argv = [executable]
        self.status_path = output / (self.label + '-exit-status.txt')
        self.socket_path = root / (self.label + '.sock')
        env_path = root / (self.label + '-game-env.json')
        write_json(env_path, env)
        self.gui_env = gui_env
        self.window = None
        self.transport = None
        self.stderr = (output / (self.label + '-xterm.log')).open('xb')
        command = ['xterm', '-geometry', f'{COLS}x{ROWS}', '-fa', 'Monospace',
                   '-fs', '14', '-bg', 'black', '-fg', 'white',
                   '-title', "Obumbrata native proof " + str(number),
                   '-e', sys.executable, '-B', str(Path(__file__).resolve()),
                   '--relay', executable, str(self.raw_path), str(self.status_path),
                   str(self.socket_path), str(env_path), str(root / 'work')]
        self.process = subprocess.Popen(command, env=gui_env, stdout=self.stderr,
                                        stderr=self.stderr, start_new_session=True)
        try:
            end = time.monotonic() + 15
            while not self.socket_path.exists() or self.window is None:
                require(self.process.poll() is None, 'xterm exited before native relay was ready')
                require(time.monotonic() < end, 'xterm/relay startup timed out')
                found = self.command('xdotool', 'search', '--onlyvisible', '--pid',
                                     str(self.process.pid), check=False)
                if found.returncode == 0 and found.stdout.split():
                    self.window = found.stdout.split()[-1].decode('ascii')
                time.sleep(0.05)
            self.transport = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            self.transport.connect(str(self.socket_path))
        except BaseException:
            self.close()
            raise

    def command(self, *args, check=True):
        return subprocess.run(args, env=self.gui_env, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, check=check, timeout=10)

    def image(self, label, filename=None):
        # Capture the live X window after the native redraw has drained. No
        # terminal replay, rasterizer, OCR copy, or injected display bytes.
        self.settle()
        time.sleep(0.15)
        require(not self.exited() and self.window is not None, 'no live native X window')
        path = self.output / (filename or (self.label + '-' + label + '.png'))
        self.command('import', '-window', self.window, str(path))
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'live X capture is not PNG')
        width, height = struct.unpack('>II', data[16:24])
        require(width >= 640 and height >= 400, 'native X window too small')
        return {'path': path.name, 'sha256': hashlib.sha256(data).hexdigest(),
                'width': width, 'height': height, 'window': self.window,
                'source': 'ImageMagick import of live xterm window',
                'terminal_raw_sha256': hashlib.sha256(self.raw).hexdigest()}

    def text(self):
        return '\n'.join(self.screen.display)

    def read(self, delay=0.1):
        require(time.monotonic() < self.deadline,
                self.label + ': global deadline exceeded\n' + self.text())
        time.sleep(delay)
        with self.raw_path.open('rb') as stream:
            stream.seek(self.offset)
            data = stream.read()
        self.offset += len(data)
        if data:
            self.raw.extend(data)
            self.stream.feed(self.decoder.decode(data))
            require(len(self.raw) < 8000000, 'excessive native terminal output')
        if self.status_path.exists():
            self.status = int(self.status_path.read_text().strip())
            self.eof = True
        return bool(data)

    def exited(self):
        if self.status is None and self.status_path.exists():
            self.status = int(self.status_path.read_text().strip())
        return self.status is not None

    def send(self, keys):
        require(not self.exited(), self.label + ': process already exited')
        self.transport.sendall(keys.encode('ascii'))

    def settle(self):
        # Drain output, not a surrogate for the action-specific assertions.
        while self.read(0.25):
            pass

    def wait(self, predicate, what):
        end = time.monotonic() + 15
        while True:
            self.read()
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

    def menu(self):
        self.wait(lambda: all(text in self.text() for text in
                             ('S)tart new game', 'R)esume existing game', 'Q)uit')),
                  'native main menu')

    def start(self):
        self.menu()
        self.snapshot('menu')
        self.image('menu')
        self.send('S')
        self.wait(lambda: 'Welcome. Remind me of thy name?' in self.text(),
                  'native name prompt')
        self.snapshot('name-prompt')
        self.image('name-prompt')
        self.send(NAME + '\n')
        self.wait(lambda: all(text in self.text() for text in
                             ('(P)rincess', '(D)emon Hunter', '(T)hanatophile')),
                  'native role menu')
        self.snapshot('role-menu')
        self.image('role-menu')
        self.send('D')
        self.wait(self.game_visible, 'native fresh dungeon')
        return self.capture('fresh')

    def game_visible(self):
        return (NAME in self.screen.display[22] and
                'HP:' in self.screen.display[22] and
                'Depth:' in self.screen.display[23] and
                self.screen.display[10][10] == '@')

    def capture(self, label):
        self.settle()
        require(self.game_visible(), 'native map/HUD not visible\n' + self.text())
        state = {'map': [line[:21] for line in self.screen.display[:21]],
                 'hud': [line[:80] for line in self.screen.display[22:24]]}
        require(any('.' in line for line in state['map']), 'no native visible floor')
        hp = re.search(r'HP:\s*(\d+)/(\d+)', state['hud'][0])
        require(hp is not None and int(hp.group(1)) > 0, 'native player is not alive')
        self.snapshot(label)
        filename = 'obumbrata-native.png' if self.label == 'session-1' and label == 'second-move-after' else None
        state['image'] = self.image(label, filename=filename)
        write_json(self.output / (self.label + '-' + label + '-state.json'), state)
        return state

    def restore(self, save):
        self.menu()
        require(save.is_file(), 'native save missing before R')
        self.send('R')
        self.wait(lambda: self.game_visible() and
                  'Game successfully restored.' in self.text() and not save.exists(),
                  'native restored notification and save unlink')
        return self.capture('restored-' + str(self.offset))

    def move(self, label):
        before = self.capture(label + '-before')
        # The native 21x21 camera is always centered at (10,10), not absolute
        # coordinates. Choose an observed, empty floor once; never retry a
        # blocked command and present it as success. Saves verify displacement.
        threats = [(x, y) for y, line in enumerate(before['map'])
                   for x, glyph in enumerate(line) if glyph.isalpha()]
        choices = []
        for dy, dx, key in ((0, -1, 'h'), (0, 1, 'l'), (-1, 0, 'k'), (1, 0, 'j'),
                            (-1, -1, 'y'), (-1, 1, 'u'), (1, -1, 'b'), (1, 1, 'n')):
            y, x = 10 + dy, 10 + dx
            if before['map'][y][x] != '.':
                continue
            clearance = min((max(abs(x - tx), abs(y - ty)) for tx, ty in threats),
                            default=21)
            choices.append((clearance, dy, dx, key))
        require(choices, 'no observed adjacent empty floor for genuine native movement')
        choice = max(choices, key=lambda item: item[0])
        _, dy, dx, key = choice
        write_json(self.output / (self.label + '-' + label + '-movement.json'),
                   {'key': key, 'delta_yx': [dy, dx], 'choices': choices,
                    'visible_letter_threats': threats})
        self.send(key)
        self.settle()
        return [dy, dx], self.capture(label + '-after')

    def save(self, save, label):
        require(self.game_visible(), 'S must be sent in native gameplay')
        before = self.capture(label + '-before-save')
        self.send('S')
        self.menu()
        self.wait(lambda: save.is_file() and save.stat().st_size > 0,
                  'native save file')
        require(not self.exited(), 'native save must return to menu without exiting')
        self.snapshot(label + '-saved-menu')
        self.image(label + '-saved-menu')
        data = save.read_bytes()
        (self.output / (label + '.native-save')).write_bytes(data)
        decoded = decode_save(data)
        decoded['file'] = label + '.native-save'
        decoded['sha256'] = hashlib.sha256(data).hexdigest()
        decoded['size'] = len(data)
        write_json(self.output / (label + '-save.json'), decoded)
        return data, decoded, before

    def quit(self):
        self.menu()
        self.send('Q')
        end = time.monotonic() + 15
        while not self.exited():
            self.read()
            require(time.monotonic() < end, 'native menu Q did not exit')
        self.read(0)
        require(self.status == 0, 'native Q exit status ' + str(self.status))
        self.snapshot('quit')

    def close(self):
        if self.transport is not None:
            self.transport.close()
            self.transport = None
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        self.stderr.close()



def decode_save(data):
    # log.cc: save_game, serialize_player, serialize_cstring, serialize_coord.
    require(len(data) >= 32, 'truncated native save prefix')
    magic, major, minor, depth, tick, next_obj, next_mon = struct.unpack_from('>IIIiiII', data)
    require((magic, major, minor) == (0x0b756d62, 1, 0), 'wrong native save magic/version')
    length, = struct.unpack_from('>I', data, 28)
    require(0 < length < 16 and len(data) > 32 + length + 76,
            'invalid native name length/player prefix')
    name = data[32:32 + length].decode('ascii')
    mh, y, x, *values = struct.unpack_from('>Iii16i', data, 32 + length)
    fields = ('role', 'body', 'bdam', 'agility', 'adam', 'hpmax', 'hpcur', 'food',
              'experience', 'level', 'defence', 'protection', 'leadfoot',
              'withering', 'armourmelt', 'speed')
    state = dict(zip(fields, values))
    require(name == NAME and state['role'] == 1, 'wrong native player name/role')
    require(depth == 1 and tick > 0 and state['hpcur'] > 0,
            'save is not live first-level gameplay after genuine turns')
    require(next_obj > 0 and next_mon > 0 and mh < next_mon, 'invalid native handles')
    return dict(state, name=name, player_monster_handle=mh, position_yx=[y, x],
                depth=depth, tick=tick, magic=hex(magic), major=major, minor=minor,
                next_object_handle=next_obj, next_monster_handle=next_mon)


def equivalent(before, after):
    require(before['map'] == after['map'], 'native map differs after exact restore')
    require(before['hud'] == after['hud'], 'native HUD differs after exact restore')


def moved(before, after, delta):
    require(after['tick'] > before['tick'], 'genuine movement did not advance saved tick')
    require(after['position_yx'] == [a + b for a, b in zip(before['position_yx'], delta)],
            'genuine movement did not reach selected floor in decoded save coordinates')


def isolation_receipt():
    host_net = os.environ['OBUMBRATA_HOST_NET']
    host_mount = os.environ['OBUMBRATA_HOST_MOUNT']
    host_user = os.environ['OBUMBRATA_HOST_USER']
    host_pid = os.environ['OBUMBRATA_HOST_PID']
    network = os.readlink('/proc/self/ns/net')
    mount_namespace = os.readlink('/proc/self/ns/mnt')
    pid_namespace = os.readlink('/proc/self/ns/pid')
    user_namespace = os.readlink('/proc/self/ns/user')
    require(user_namespace != host_user, 'user namespace unchanged')
    require(network != host_net, 'network namespace unchanged')
    require(mount_namespace != host_mount, 'mount namespace unchanged')
    require(pid_namespace != host_pid, 'PID namespace unchanged')
    interfaces = socket.if_nameindex()
    require(interfaces == [(1, 'lo')],
            'network namespace exposes non-loopback interfaces')
    mount('/gnu/store', '/gnu/store', flags=4096)  # MS_BIND
    mount('/gnu/store', '/gnu/store', flags=4096 | 32 | 1)  # BIND|REMOUNT|RDONLY
    entries = [line for line in Path('/proc/self/mountinfo').read_text().splitlines()
               if line.split()[4] == '/gnu/store']
    require(entries and 'ro' in entries[-1].split()[5].split(','),
            'store bind mount is not read-only')
    return {'host_network_namespace': host_net, 'network_namespace': network,
            'host_mount_namespace': host_mount, 'mount_namespace': mount_namespace,
            'host_user_namespace': host_user, 'user_namespace': user_namespace,
            'network_interfaces': interfaces, 'store_readonly': True,
            'host_pid_namespace': host_pid, 'pid_namespace': pid_namespace,
            'store_mountinfo': entries[-1]}


def launch_isolated(executable, output):
    unshare = shutil.which('unshare')
    require(unshare is not None, 'realized unshare missing')
    variables = ('PATH', 'HOME', 'TMPDIR', 'GUIX_PYTHONPATH', 'PYTHONPATH',
                 'TERMINFO', 'TERMINFO_DIRS', 'XDG_DATA_HOME', 'XDG_STATE_HOME',
                 'XDG_CONFIG_HOME')
    env = {key: os.environ[key] for key in variables if os.environ.get(key)}
    env.update({'LC_ALL': 'C',
                'OBUMBRATA_HOST_NET': os.readlink('/proc/self/ns/net'),
                'OBUMBRATA_HOST_MOUNT': os.readlink('/proc/self/ns/mnt'),
                'OBUMBRATA_HOST_PID': os.readlink('/proc/self/ns/pid')})
    env['OBUMBRATA_HOST_USER'] = os.readlink('/proc/self/ns/user')
    command = [unshare, '--user', '--map-current-user', '--keep-caps', '--mount', '--propagation',
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
    parser.add_argument('executable', help='installed ordinary bin/obumbrata launcher')
    parser.add_argument('--output', required=True, type=Path, help='new evidence directory')
    parser.add_argument('--inside', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    executable = str(Path(args.executable).resolve())
    package = Path(executable).parent.parent
    require(package.parent == Path('/gnu/store') and
            executable == str(package / 'bin/obumbrata'), 'launcher is not a store output bin/obumbrata')
    require(os.access(executable, os.X_OK) and
            os.access(package / 'libexec/obumbrata', os.X_OK), 'native launcher/binary missing')
    license_path = package / 'share/doc/obumbrata/COPYING'
    license_text = license_path.read_text()
    for notice in ('Copyright 2005-2014 Martin Read',
                   'Redistribution and use in source and binary forms',
                   '1. Redistributions of source code must retain',
                   '2. Redistributions in binary form must reproduce',
                   'THIS SOFTWARE IS PROVIDED BY THE AUTHOR',
                   'THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'):
        require(notice in license_text, 'installed BSD notice missing: ' + notice)
    output = args.output.absolute()
    require(not output.exists() and not output.is_symlink(), 'choose a fresh --output directory')
    require(not output.is_relative_to('/gnu/store'), 'evidence must be outside store')
    if not args.inside:
        launch_isolated(executable, output)
        return
    output.mkdir(parents=True, mode=0o700)
    report = {'success': False, 'executable': executable, 'native_binary': str(package / 'libexec/obumbrata'),
              'license': {'path': str(license_path), 'sha256': hashlib.sha256(license_path.read_bytes()).hexdigest()},
              'save_suffix': str(SAVE_SUFFIX), 'sessions': [], 'continuity': [],
              'source_release': '1.0.0', 'source_sha256': '253d6250d2378fe91f15ea92ef9c9ad5c7f967bada7778ee8955bb2c8eacac47'}
    report['persistence_scope'] = 'Exact persisted save bytes and visible map/HUD; upstream does not serialize RNG state.'
    report['input_gates'] = {'menu': 'S)tart new game',
        'name_prompt': 'Welcome. Remind me of thy name?',
        'name': NAME, 'role_menu': ['(P)rincess', '(D)emon Hunter', '(T)hanatophile'],
        'role_key': 'D', 'matcher': 'reconstructed pyte screen, not raw curses byte occurrences',
        'historical_timeout': 'No historical root cause claimed; gates follow release 1.0.0 display-nc.cc run_main_menu.'}
    session = display = None
    try:
        report['isolation'] = isolation_receipt()
        output = private_tmp(output)
        display = Display(output)
        report['isolation']['display'] = display.env['DISPLAY']
        with tempfile.TemporaryDirectory(prefix='obumbrata-proof-', dir='/tmp') as directory:
            root = Path(directory)
            for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
                (root / name).mkdir(mode=0o700)
            env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color', 'LC_ALL': 'C',
                   'PATH': '', 'TMPDIR': str(root / 'tmp')}
            for variable in ('TERMINFO', 'TERMINFO_DIRS'):
                if os.environ.get(variable):
                    env[variable] = os.environ[variable]
            for variable, subdir in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                     ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                     ('XDG_RUNTIME_DIR', 'runtime')):
                env[variable] = str(root / subdir)
            report['game_environment'] = env
            gui_env = dict(display.env)
            gui_env['TMPDIR'] = str(root / 'tmp')
            save = root / 'data' / SAVE_SUFFIX
            require(not save.exists(), 'fresh data directory already has a save')
            session = Session(executable, env, root, output, 1, gui_env)
            session.start()
            delta1, _ = session.move('first-move')
            data1, state1, view1 = session.save(save, 'first-moved')
            # This same-process restore provides a decoded coordinate baseline
            # while the very first save is already genuine moved gameplay.
            restored1 = session.restore(save)
            equivalent(view1, restored1)
            delta2, _ = session.move('second-move')
            data2, state2, view2 = session.save(save, 'second-moved')
            moved(state1, state2, delta2)
            report['initial_movement'] = {'first_delta_yx': delta1, 'first_save': state1,
                                          'second_delta_yx': delta2, 'second_save': state2}
            session.quit()
            report['sessions'].append({'number': 1, 'exit_status': session.status})
            session.close()
            session = None
            # Two independent native processes must round-trip the entire save
            # byte-for-byte without any turn after the exact restore.
            for number in (2, 3):
                session = Session(executable, env, root, output, number, gui_env)
                restored = session.restore(save)
                equivalent(view2, restored)
                label = 'exact-restore-' + str(number - 1)
                exact_data, exact_state, exact_view = session.save(save, label)
                require(exact_data == data2, 'entire save differs after no-turn ' + label)
                equivalent(view2, exact_view)
                report['continuity'].append({'session': number, 'entire_save_bytes_equal': True,
                                             'map_equal': True, 'hud_equal': True, 'save': exact_state})
                if number == 3:
                    again = session.restore(save)
                    equivalent(view2, again)
                    delta3, _ = session.move('post-second-restore-move')
                    final_data, final_state, _ = session.save(save, 'post-second-restore-moved')
                    moved(state2, final_state, delta3)
                    require(final_data != data2, 'save unchanged despite genuine post-restore movement')
                    report['post_restore_movement'] = {'delta_yx': delta3, 'before': state2, 'after': final_state}
                session.quit()
                report['sessions'].append({'number': number, 'exit_status': session.status})
                session.close()
                session = None
            report['private_files'] = {str(p.relative_to(root)): {'size': p.stat().st_size,
                'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                for p in sorted(root.rglob('*')) if p.is_file()}
            native_file = 'data/' + str(SAVE_SUFFIX)
            harness_files = {'session-' + str(number) + '-game-env.json' for number in (1, 2, 3)}
            require(set(report['private_files']) == harness_files | {native_file},
                    'unexpected native writes outside isolated XDG save: ' + str(set(report['private_files']) - harness_files - {native_file}))
            require(not any(p.is_symlink() for p in root.rglob('*')),
                    'unexpected symlink in isolated native state')
            report['write_scope'] = {'native_files': [native_file],
                'harness_files': sorted(harness_files), 'unexpected_files': [],
                'home_config_cache_state_runtime_work_files': []}
            report['primary_screenshot'] = 'obumbrata-native.png'
            report['success'] = True
        write_json(output / 'receipt.json', report)
        print('OBUMBRATA_NATIVE_OK')
    except BaseException as error:
        report['error'] = str(error)
        if session is not None:
            session.read(0)
            session.snapshot('failure')
        write_json(output / 'receipt.json', report)
        raise
    finally:
        if session is not None:
            session.close()
        if display is not None:
            display.close()


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--relay':
        sys.exit(relay(sys.argv[2:]))
    main()
