#!/usr/bin/env python3
"""External GearHead Arena proof: native bytes, native saves, live X captures.

No fixture state, patched config, seed, replay, or installed test hook is used.
The shell enters same-user offline namespaces and compares the output NAR.
"""
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
import signal
import socket
import struct
import subprocess
import sys
import termios
import time
import tty

import pyte

ROWS, COLS = 25, 80
NAME = 'OmpProof'


def require(value, message):
    if not value:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def write_all(fd, data):
    pending = memoryview(data)
    while pending:
        size = os.write(fd, pending)
        require(size > 0, 'short terminal write')
        pending = pending[size:]


def relay(argv):
    program, raw_path, status_path, socket_path, env_path, work, *arguments = argv
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
            os.execve(program, [program, *arguments], env)
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
                        chunk = os.read(0, 4096) if source == 0 else transport.recv(4096)
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
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int
    if libc.mount(os.fsencode(source), os.fsencode(target),
                  None if filesystem is None else os.fsencode(filesystem),
                  flags, None) != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), str(target))


def isolate(output):
    receipt = {}
    require(os.getuid() == int(os.environ['GEARHEAD_HOST_UID']), 'caller UID changed')
    require(Path('/proc/self/uid_map').read_text().split() ==
            [os.environ['GEARHEAD_HOST_UID'], os.environ['GEARHEAD_HOST_UID'], '1'],
            'unexpected user namespace mapping')
    for kind, variable in (('net', 'NET'), ('mnt', 'MNT'), ('pid', 'PID')):
        host = os.environ['GEARHEAD_HOST_' + variable + 'NS']
        current = os.readlink('/proc/self/ns/' + kind)
        require(host != current, kind + ' namespace unchanged')
        receipt[kind] = {'host': host, 'current': current}
    interfaces = socket.if_nameindex()
    route_text = Path('/proc/net/route').read_text()
    netdev_text = Path('/proc/net/dev').read_text()
    receipt['interfaces'] = interfaces
    receipt['route_text'] = route_text
    receipt['netdev_text'] = netdev_text
    write_json(output / 'network-isolation.json', receipt)
    require(interfaces == [(1, 'lo')], 'network namespace exposes external interfaces')
    route_lines = [line.split() for line in route_text.splitlines() if line.strip()]
    # An empty fresh kernel namespace may expose no route table header at all.
    # If present, require the native header and no routes; any data fails closed.
    if route_lines:
        require(route_lines[0][:3] == ['Iface', 'Destination', 'Gateway'],
                'unrecognized kernel IPv4 route table header')
        require(not route_lines[1:], 'offline namespace has IPv4 routes')
    probe = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    probe.settimeout(1)
    try:
        require(probe.connect_ex(('192.0.2.1', 9)) != 0, 'offline TCP unexpectedly connected')
    finally:
        probe.close()
    receipt['interfaces'] = interfaces
    receipt['offline_tcp_denied'] = True
    mount('/', '/', flags=16384 | 262144)  # MS_REC | MS_PRIVATE
    mount('/gnu/store', '/gnu/store', flags=4096)
    mount('/gnu/store', '/gnu/store', flags=4096 | 32 | 1)
    entries = [line for line in Path('/proc/self/mountinfo').read_text().splitlines()
               if line.split()[4] == '/gnu/store']
    require(entries and 'ro' in entries[-1].split()[5].split(','), 'store is not read-only')
    receipt['store_mountinfo'] = entries[-1]
    require(not Path(__file__).resolve().is_relative_to('/tmp') and
            not Path(sys.executable).resolve().is_relative_to('/tmp'),
            'checkout and Python must be outside host /tmp')
    evidence_fd = os.open(output, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        private = Path('/tmp/gearhead-evidence')
        private.mkdir(mode=0o700)
        mount(f'/proc/self/fd/{evidence_fd}', private, flags=4096)
    finally:
        os.close(evidence_fd)
    return private, receipt


class Display:
    def __init__(self, output):
        self.env = {key: os.environ[key] for key in
                    ('PATH', 'GUIX_PYTHONPATH', 'PYTHONPATH', 'TERMINFO', 'TERMINFO_DIRS',
                     'XDG_DATA_DIRS', 'GUIX_FONTCONFIG_LIBDIR', 'FONTCONFIG_PATH',
                     'FONTCONFIG_FILE', 'GUIX_PROFILE')
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
                 '1280x1024x24', '-nolisten', 'tcp', '-ac'],
                pass_fds=(write_fd,), stdout=self.log, stderr=self.log, env=self.env)
        finally:
            os.close(write_fd)
        try:
            require(select.select([read_fd], [], [], 10)[0], 'Xvfb startup timeout')
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


class Session:
    def __init__(self, package, env, root, output, number, gui_env, arguments):
        self.output, self.gui_env = output, gui_env
        self.label = 'session-' + str(number)
        self.raw_path = output / (self.label + '.pty')
        self.raw_path.touch(exist_ok=False)
        self.raw = bytearray()
        self.offset = 0
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.status = None
        self.deadline = time.monotonic() + 110
        self.status_path = output / (self.label + '-exit-status.txt')
        self.socket_path = root / (self.label + '.sock')
        env_path = root / (self.label + '-env.json')
        write_json(env_path, env)
        self.window = None
        self.transport = None
        self.stderr = (output / (self.label + '-xterm.log')).open('xb')
        self.argv = [str(package / 'bin/gearhead'), *arguments]
        command = ['xterm', '-geometry', f'{COLS}x{ROWS}', '-fa', 'Monospace',
                   '-fs', '14', '-bg', 'black', '-fg', 'white',
                   '-title', 'GearHead native proof ' + str(number),
                   '-e', sys.executable, '-B', str(Path(__file__).resolve()),
                   '--relay', self.argv[0], str(self.raw_path), str(self.status_path),
                   str(self.socket_path), str(env_path), str(root / 'work'), *arguments]
        self.process = subprocess.Popen(command, env=gui_env, stdout=self.stderr,
                                        stderr=self.stderr, start_new_session=True)
        try:
            end = time.monotonic() + 15
            while not self.socket_path.exists() or self.window is None:
                require(self.process.poll() is None, 'xterm exited before relay readiness')
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

    def read(self, delay=0.1):
        require(time.monotonic() < self.deadline, self.label + ': global deadline exceeded')
        time.sleep(delay)
        with self.raw_path.open('rb') as stream:
            stream.seek(self.offset)
            data = stream.read()
        self.offset += len(data)
        if data:
            self.raw.extend(data)
            self.stream.feed(self.decoder.decode(data))
            require(len(self.raw) < 8000000, 'excessive terminal output')
        if self.status_path.exists():
            self.status = int(self.status_path.read_text().strip())
        return bool(data)

    def settle(self):
        while self.read(0.25):
            pass

    def text(self):
        return '\n'.join(self.screen.display)

    def send(self, keys):
        require(self.status is None, 'native process already exited')
        self.transport.sendall(keys.encode('ascii'))

    def wait(self, predicate, what, seconds=20):
        end = time.monotonic() + seconds
        while True:
            self.read()
            if predicate():
                self.settle()
                if predicate():
                    return
            require(self.status is None, what + ': exited\n' + self.text())
            require(time.monotonic() < end, what + ': timeout\n' + self.text())

    def screenshot(self, label):
        self.settle()
        time.sleep(0.15)
        require(self.status is None and self.window is not None, 'no live native X window')
        stem = self.label + '-' + label
        (self.output / (stem + '.screen.txt')).write_text(self.text() + '\n')
        path = self.output / (stem + '.png')
        self.command('import', '-window', self.window, str(path))
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'capture is not PNG')
        width, height = struct.unpack('>II', data[16:24])
        require(width >= 640 and height >= 400, 'native window too small')
        return {'path': path.name, 'sha256': hashlib.sha256(data).hexdigest(),
                'width': width, 'height': height, 'window': self.window,
                'source': 'ImageMagick import of live xterm',
                'terminal_raw_sha256': hashlib.sha256(self.raw).hexdigest()}

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


class SaveReader:
    """Read WriteCampaign/WriteMap/WriteCGears, without changing any game file.

    Pinned upstream: conmap.pp:947-1016, locale.pp:2753-2860,
    gearutil.pp:1634-1699, menugear.pp:342-367.
    """
    def __init__(self, path):
        self.lines = path.read_text().splitlines()
        self.index = 0

    def line(self):
        require(self.index < len(self.lines), 'truncated native save')
        value = self.lines[self.index].strip()
        self.index += 1
        return value

    def integer(self):
        return int(self.line())

    def map(self):
        require(self.line() == '*** GearHead Location Record ***', 'native map header absent')
        width, height = self.integer(), self.integer()
        require(0 < width <= 1000 and 0 < height <= 1000, 'invalid native map dimensions')
        total = width * height
        terrain = []
        while len(terrain) < total:
            count, value = self.integer(), self.integer()
            require(0 < count <= total - len(terrain), 'invalid native terrain RLE')
            terrain.extend([value] * count)
        require(self.line() == '***', 'native terrain terminator absent')
        count = 0
        while count < total:
            run = self.integer()
            require(0 <= run <= total - count, 'invalid native visibility RLE')
            count += run
        return {'dimensions': [width, height], 'terrain': terrain}

    def gears(self, depth=0):
        require(depth < 100, 'native gear nesting excessive')
        result = []
        while True:
            header = self.line()
            if header == '-1':
                return result
            values = [int(value) for value in header.split()]
            require(len(values) == 5 and values[0] == 0, 'invalid native gear header')
            gear = {'type': values[1:5], 'numeric': {}, 'strings': {}}
            stats = self.line().split()
            require(stats and stats[0] == 'Stats' and len(stats) % 2 == 1,
                    'invalid native gear statistics')
            gear['stats'] = [int(value) for value in stats[1:]]
            while True:
                attribute = self.line()
                if attribute == '-1':
                    break
                values = [int(value) for value in attribute.split()]
                require(len(values) == 4 and values[0] == 0, 'invalid numeric attribute')
                gear['numeric'][(values[1], values[2])] = values[3]
            while True:
                attribute = self.line()
                if attribute == 'Z':
                    break
                match = re.fullmatch(r'([^<]+)<(.*)>\s*', attribute)
                require(match is not None, 'invalid string attribute: ' + attribute)
                gear['strings'][match[1].strip().upper()] = match[2]
            gear['inventory'] = self.gears(depth + 1)
            gear['components'] = self.gears(depth + 1)
            result.append(gear)


def flatten(gears):
    for gear in gears:
        yield gear
        yield from flatten(gear['inventory'])
        yield from flatten(gear['components'])


def character_identity(gear):
    # Stats and permanent numeric character attributes distinguish this character
    # from a new same-name character. Location/action/damage/narrative may change
    # legitimately on ScenePlayer entry and are not character identity.
    return {'type': gear['type'], 'stats': gear['stats'],
            'name': gear['strings'].get('NAME'),
            'description': [[axis, gear['numeric'].get((3, axis), 0)] for axis in (0, 1, 2)],
            'skills': [[axis, value] for (group, axis), value in sorted(gear['numeric'].items())
                       if group == 1],
            'biography': gear['strings'].get('BIO1')}


def campaign_state(path):
    reader = SaveReader(path)
    clock, scale = reader.integer(), reader.integer()
    map_data = reader.map()
    scene_index = reader.integer()
    units = reader.gears()
    while reader.line() == '1':
        reader.line()  # Frozen-map name.
        reader.map()
    require(reader.lines[reader.index - 1].strip() == '-1', 'invalid frozen map sentinel')
    source = reader.gears()
    require(reader.index == len(reader.lines), 'trailing native save data')
    source_gears = list(flatten(source))
    require(len(source) == 1 and 0 <= scene_index < len(source_gears), 'invalid scene index')
    scene = source_gears[scene_index]
    require(scene['type'][0] == -3, 'saved current gear is not a scene')
    players = []
    for master in units:
        if master['numeric'].get((-1, 4), 0) != 1:
            continue
        characters = [gear for gear in flatten([master])
                      if gear['type'][0] == 2 and gear['strings'].get('NAME') == NAME]
        if len(characters) == 1:
            players.append((master, characters[0]))
    require(len(players) == 1, 'save does not identify exactly one native named PC')
    master, character = players[0]
    position = [master['numeric'].get((-1, axis), 0) for axis in (0, 1)]
    width, height = map_data['dimensions']
    require(1 <= position[0] <= width and 1 <= position[1] <= height, 'PC outside saved map')
    return {'clock': clock, 'scale': scale, 'position': position,
            'scene_index': scene_index, 'scene_type': scene['type'],
            'scene_name': scene['strings'].get('NAME'),
            'character': character_identity(character),
            'map_dimensions': map_data['dimensions'],
            'terrain_sha256': hashlib.sha256(json.dumps(map_data['terrain']).encode()).hexdigest()}


def save_snapshot(session, config, output, label):
    path = config / 'SaveGame' / ('RPG' + NAME + '.txt')
    previous = path.stat().st_mtime_ns if path.exists() else None
    session.send('X')
    session.wait(lambda: path.exists() and path.stat().st_mtime_ns != previous,
                 'native X save')
    data = path.read_bytes()
    require('The game has been saved.' in session.text(), 'native save success message absent')
    copy = output / (label + '.save.txt')
    copy.write_bytes(data)
    state = campaign_state(copy)
    write_json(output / (label + '.state.json'), state)
    return state


def player_cell(session):
    # congfx.pp ZONE_Map: (2,2,80-32,25-6), Pascal one-based.
    # IndicateTile redraws the active PC using the native cursor highlight,
    # which replaces TeamColor's blue.  Use the glyph plus live PC HUD instead.
    text = session.text()
    require(NAME in text and re.search(r'\d+/\d+ HP', text) and
            re.search(r'\d+:\d{2}:\d{2}, day \d+', text), 'native PC HUD absent')
    cells = []
    for y in range(1, 19):
        for x in range(1, 48):
            cell = session.screen.buffer[y][x]
            if cell.data == '@':
                cells.append([x, y])
    require(len(cells) == 1, 'native map lacks exactly one player @\n' + session.text())
    return cells[0]


def native_process(package):
    expected = (package / 'libexec/gharena').resolve()
    matches = []
    for directory in Path('/proc').iterdir():
        if not directory.name.isdigit():
            continue
        try:
            executable = (directory / 'exe').resolve(strict=True)
            if executable == expected:
                cwd = (directory / 'cwd').resolve(strict=True)
                arguments = (directory / 'cmdline').read_bytes().split(b'\0')
                require(cwd == package / 'share/gearhead', 'native CWD is not installed assets')
                matches.append({'pid': int(directory.name), 'executable': str(executable),
                                'cwd': str(cwd),
                                'argv': [value.decode() for value in arguments if value]})
        except (FileNotFoundError, PermissionError):
            continue
    require(len(matches) == 1, 'expected exactly one native gharena process')
    return matches[0]


def move_player(session, config, output, before):
    x, y = player_cell(session)
    candidates = []
    for dx, dy, key in ((1, 0, '6'), (-1, 0, '4'), (0, 1, '2'), (0, -1, '8'),
                        (1, 1, '3'), (-1, 1, '1'), (1, -1, '9'), (-1, -1, '7')):
        nx, ny = x + dx, y + dy
        if 1 <= nx < 48 and 1 <= ny < 19:
            glyph = session.screen.buffer[ny][nx].data
            if glyph == '.':
                candidates.append((dx, dy, key, glyph))
    require(candidates, 'no adjacent visible native floor for movement')
    attempts = []
    for dx, dy, key, glyph in candidates:
        session.send(key)
        session.settle()
        after = save_snapshot(session, config, output, 'move-' + key)
        attempts.append({'key': key, 'delta': [dx, dy], 'glyph': glyph,
                         'position': after['position']})
        if after['position'] != before['position']:
            require(after['position'] == [before['position'][0] + dx, before['position'][1] + dy],
                    'native movement did not reach adjacent selected square')
            require(after['scene_index'] == before['scene_index'] and
                    after['scene_type'] == before['scene_type'], 'movement changed scene')
            require(after['character'] == before['character'], 'movement changed character identity')
            require(after['clock'] > before['clock'], 'native move did not advance game clock')
            shown = player_cell(session)
            write_json(output / 'movement.json', {'before_screen': [x, y],
                       'after_screen': shown, 'attempts': attempts,
                       'before': before['position'], 'after': after['position']})
            return after
    raise RuntimeError('native keypad attempts did not move the PC')


MAIN_ITEMS = ('Start RPG Campaign', 'Load RPG Campaign', 'New Arena Unit',
              'Load Arena Unit', 'Create Character', 'Edit Map',
              'View Design Files', 'Quit Game')


def main_menu(session):
    session.wait(lambda: 'GearHead Arena v1.310' in session.text() and
                 'Start RPG Campaign' in session.text() and 'Quit Game' in session.text(),
                 'native main menu')
    require('ERROR:' not in session.text(), 'native startup asset error')


def choose_main(session, target):
    # Main menu retains its selected item between invocations. Read its native
    # LightCyan selection, not an assumed default after returning from a game.
    main_menu(session)
    for _ in range(len(MAIN_ITEMS)):
        selected = []
        for y, line in enumerate(session.screen.display):
            for item in MAIN_ITEMS:
                start = line.find(item)
                if start >= 0:
                    cell = session.screen.buffer[y][start]
                    if cell.fg == 'brightcyan' or (cell.fg == 'cyan' and cell.bold):
                        selected.append(item)
        require(len(selected) == 1, 'cannot identify native highlighted main menu entry')
        if selected[0] == target:
            session.send(' ')
            return
        session.send('2')
        session.settle()
    raise RuntimeError('main menu target not reached: ' + target)


def wait_map(session):
    def displayed():
        text = session.text()
        return (NAME in text and re.search(r'\d+/\d+ HP', text) and
                re.search(r'\d+:\d{2}:\d{2}, day \d+', text) and
                any(session.screen.buffer[y][x].data == '@'
                    for y in range(1, 19) for x in range(1, 48)))
    story_prompt = '[Q] or [ESC] to exit'
    for page in range(10):
        session.wait(lambda: displayed() or story_prompt in session.text() or
                     '[Goodbye]' in session.text(),
                     'native campaign map or introduction', seconds=35)
        if displayed():
            break
        session.screenshot(('conversation-' if '[Goodbye]' in session.text()
                            else 'introduction-') + str(page))
        session.send('\x1b')
        session.settle()
    else:
        raise RuntimeError('native introduction did not reach gameplay')
    player_cell(session)


def quit_game(session):
    session.send('Q')  # KMC_QuitGame saves and sets QuitTheGame (pcaction.pp:3318).
    main_menu(session)
    choose_main(session, 'Quit Game')
    end = time.monotonic() + 15
    while session.status is None:
        session.read()
        require(time.monotonic() < end, 'native Quit Game failed to exit')
    require(session.status == 0, 'native quit exit status: ' + str(session.status))
    session.process.wait(timeout=5)


def main():
    require(len(sys.argv) == 3, 'usage: gearhead-pty-runner.py OUTPUT EVIDENCE')
    package, original_output = map(lambda value: Path(value).resolve(), sys.argv[1:])
    report = {'success': False, 'package': str(package), 'sessions': [],
              'defaults_modified': False, 'native_name': NAME}
    session = display = None
    output = original_output
    try:
        output, report['isolation'] = isolate(output)
        root = Path('/tmp/gearhead-proof')
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'state', 'cache', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm', 'LC_ALL': 'C',
               'PATH': os.environ.get('PATH', ''), 'TMPDIR': str(root / 'tmp')}
        for variable, directory in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                    ('XDG_STATE_HOME', 'state'), ('XDG_CACHE_HOME', 'cache'),
                                    ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / directory)
        for variable in ('TERMINFO', 'TERMINFO_DIRS'):
            if os.environ.get(variable):
                env[variable] = os.environ[variable]
        config = root / 'state' / 'gearhead'
        require(not config.exists(), 'first-launch state is not empty')
        display = Display(output)
        report['display'] = display.env['DISPLAY']
        report['environment'] = env
        report['config_directory'] = str(config)
        session = Session(package, env, root, output, 1, display.env, [])
        main_menu(session)
        report['native_first'] = native_process(package)
        report['startup'] = session.screenshot('startup')
        choose_main(session, 'Create Character')
        session.wait(lambda: 'Select Mode' in session.text() and 'Basic Mode' in session.text(),
                     'Basic Mode selection')
        session.send(' ')
        session.wait(lambda: 'Select your Gender' in session.text() and 'Male' in session.text(),
                     'native gender selection')
        session.send(' ')
        session.wait(lambda: 'Enter a name for this character' in session.text(),
                     'native name prompt')
        report['character_creation'] = session.screenshot('character-name')
        session.send(NAME + '\r')
        main_menu(session)
        character_path = config / 'SaveGame' / ('CHA' + NAME + '.txt')
        require(character_path.exists(), 'native character creation did not write CHA file')
        reader = SaveReader(character_path)
        created = [gear for gear in flatten(reader.gears())
                   if gear['type'][0] == 2 and gear['strings'].get('NAME') == NAME]
        require(len(created) == 1, 'created native character identity missing')
        identity = character_identity(created[0])
        (output / 'created-character.txt').write_bytes(character_path.read_bytes())
        choose_main(session, 'Start RPG Campaign')
        session.wait(lambda: 'Select character file.' in session.text() and
                     ('CHA' + NAME) in session.text(), 'native character file menu')
        report['character_selection'] = session.screenshot('character-file')
        session.send(' ')
        wait_map(session)
        require(not character_path.exists(), 'native campaign did not consume CHA file')
        report['map_initial'] = session.screenshot('map-initial')
        before = save_snapshot(session, config, output, 'baseline')
        require(before['character'] == identity, 'campaign character differs from created PC')
        moved = move_player(session, config, output, before)
        report['map_moved'] = session.screenshot('map-moved')
        quit_game(session)
        report['sessions'].append({'argv': session.argv, 'exit': session.status})
        saved_path = config / 'SaveGame' / ('RPG' + NAME + '.txt')
        saved = campaign_state(saved_path)
        require(all(saved[key] == moved[key] for key in
                    ('character', 'position', 'scene_index', 'scene_type', 'scene_name')),
                'native Q save changed identity/position/scene')
        (output / 'quit-save.txt').write_bytes(saved_path.read_bytes())
        require((config / 'gharena.cfg').is_file(), 'native finalization config missing')
        session.close()
        session = Session(package, env, root, output, 2, display.env, [str(config)])
        choose_main(session, 'Load RPG Campaign')
        report['native_reload'] = native_process(package)
        session.wait(lambda: 'Select campaign file to load.' in session.text() and
                     ('RPG' + NAME) in session.text(), 'native campaign load menu')
        report['load_menu'] = session.screenshot('load-file')
        session.send(' ')
        wait_map(session)
        report['map_restored'] = session.screenshot('map-restored')
        restored = save_snapshot(session, config, output, 'restored')
        exact_keys = ('character', 'position', 'scene_index', 'scene_type', 'scene_name',
                      'map_dimensions', 'terrain_sha256', 'scale', 'clock')
        require(all(restored[key] == saved[key] for key in exact_keys),
                'native reload did not restore exact character/position/scene/terrain')
        report['continuity'] = {'saved': saved, 'restored': restored,
                                'exact_fields': list(exact_keys)}
        quit_game(session)
        report['sessions'].append({'argv': session.argv, 'exit': session.status})
        # Preserve only native-produced state, and prove HOME/config/data/cache
        # were not substituted for the launcher's documented state location.
        for name in ('home', 'config', 'data', 'cache'):
            require(not list((root / name).iterdir()), 'unexpected native write in ' + name)
        shutil.copytree(config, output / 'native-config')
        report['success'] = True
        write_json(output / 'proof.json', report)
        print('GEARHEAD_NATIVE_OK')
    except BaseException as error:
        report['error'] = str(error)
        if session is not None:
            report['last_screen'] = session.text()
        write_json(output / 'failure.json', report)
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
