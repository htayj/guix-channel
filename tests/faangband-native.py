#!/usr/bin/env python3
"""External ordinary FAangband consumer. No injected game configuration/state.

The GCU frontend supplies visible birth, movement and exact character-sheet
turn/identity continuity through two native save/exits. SDL2 then loads that
same game, enables sound through its ordinary options UI, and eats native
starting food while a private PulseAudio monitor records actual output.
All game input is PTY bytes or XTest, never game APIs or process memory.
Main runs this through faangband-smoke.sh; the worker does not run checks.
"""
import codecs
import ctypes as C
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pwd
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time
import traceback
import wave

for directory in os.environ['PYTHON_SITE_PACKAGES'].split(':'):
    if directory:
        sys.path.append(directory)
import pyte
from PIL import Image

REVISION = '7ad7178b5da5819fe1a2d13182001b5bf6e9eaac'
NAME = 'OmpProof'
ROWS, COLS = 32, 100
SOURCE = {
    'url': 'https://github.com/NickMcConnell/FAangband/tree/' + REVISION,
    'birth': 'src/ui-birth.c:162-175,268-310,735-824,1000-1041,1296-1298,1508-1525,1735-1758,1768-1790',
    'input': 'src/ui-game.c:102 E=eat; 159 C=character; 175 Ctrl-X=save/quit; 193 ;=walk; src/ui-input.c:1403-1428 direction prompt',
    'identity_and_turns': 'src/ui-player.c:766-775 Name/Race/Class/HP; 893-903 Game=turn, Standard=total_energy/100; 1291-1319 C/ESC',
    'save': 'src/ui-game.c:630-640 loads living save; 702-727 -u save name; 733-779 save/prefs/lore; 834-843 Escape skips score prediction',
    'sound': 'src/list-options.h:16-17 use_sound defaults false; src/ui-options.c:117-118 visible yes/no,137-144 y/n/t; src/cmd-obj.c:762-773 E emits MSG_EAT; lib/customize/sound.prf:243-244 sound:EAT:plm_eat_bite; src/sound-core.c:56-60 -ssdl; src/snd-sdl.c:74-82 SDL audio/mixer',
    'splash': 'src/main.c:560-564; src/ui-input.c:1366-1370 [Press any key to continue]',
    'map': 'src/ui-term.c:303-305 standard sidebar map origin (13,1); src/ui-map.c:471-488 screen coordinates are native map coordinates minus panel origin',
}


def require(value, message):
    if not value:
        raise AssertionError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def mount(source, target, flags, filesystem=None, data=None):
    libc = C.CDLL(None, use_errno=True)
    libc.mount.argtypes = [C.c_char_p, C.c_char_p, C.c_char_p, C.c_ulong, C.c_char_p]
    libc.mount.restype = C.c_int
    encode = lambda value: None if value is None else os.fsencode(value)
    if libc.mount(encode(source), encode(target), encode(filesystem), flags, encode(data)):
        error = C.get_errno()
        raise OSError(error, os.strerror(error), str(target))


def store_entries():
    text = Path('/proc/self/mountinfo').read_text()
    entries = []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in [('\\040', ' '), ('\\011', '\t'), ('\\012', '\n'), ('\\134', '\\')]:
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            entries.append(dict(target=target, options=fields[5].split(','),
                                optional=fields[6:fields.index('-')]))
    return text, entries


def isolate(evidence):
    (evidence / 'mountinfo-before.txt').write_text(store_entries()[0])
    mount('/gnu/store', '/gnu/store', 4096 | 16384)
    mount('/gnu/store', '/gnu/store', 262144 | 16384)
    for target in sorted({e['target'] for e in store_entries()[1]}, key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)
    text, entries = store_entries()
    require(entries and all('ro' in e['options'] and 'rw' not in e['options'] and
            not any(x.startswith(('shared:', 'master:')) for x in e['optional'])
            for e in entries), 'store is not recursively private and read-only')
    (evidence / 'mountinfo-after.txt').write_text(text)
    # Retain the caller-owned evidence FD while hiding host sockets and temp.
    mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
    retained = Path('/tmp/faangband-evidence')
    retained.mkdir(mode=0o700)
    mount(evidence, retained, 4096)
    mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=755')
    return entries, retained


def namespace_receipt(proc):
    record = {}
    for kind in ('user', 'mnt', 'net', 'pid'):
        actual = os.readlink(proc / 'ns' / kind)
        require(actual != os.environ['FA_HOST_' + kind.upper()], 'host namespace leaked: ' + kind)
        require(actual == os.readlink('/proc/self/ns/' + kind), 'namespace escaped: ' + kind)
        record[kind] = actual
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(x) for x in value.split()]
    for kind, key in [('uid', 'Uid'), ('gid', 'Gid')]:
        expected = int(os.environ['FA_HOST_' + kind.upper()])
        require(identity[key] == [expected] * 4, 'caller identity changed: ' + key)
        text = (proc / (kind + '_map')).read_text()
        require([int(x) for x in text.split()] == [expected, expected, 1], 'not exact same-identity mapping')
        record[kind + '_map'] = text
    interfaces = sorted(line.split(':')[0].strip() for line in
                        (proc / 'net/dev').read_text().splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'], 'non-loopback network interface')
    require(len((proc / 'net/route').read_text().splitlines()) <= 1, 'network route leaked')
    return dict(namespaces=record, identity=identity, interfaces=interfaces)


def check_errors(text):
    # Game events such as a missed attack are not runtime errors. These are
    # native resource/parser/save/frontend failures, including exit-zero ones.
    pattern = (r'(?i)(broken savefile|saving game\.\.\. failed|failed to (?:load|save|open|create)|'
               r'lore save failed|parse error|error at line|cannot (?:open|create|load|find)|'
               r"couldn.t (?:open|initialize)|segmentation fault|assertion .*failed|"
               r'addresssanitizer|undefined symbol|traceback|SDL[^\n]*(?:error|failed))')
    match = re.search(pattern, text)
    require(match is None, 'native error: ' + (match.group(0) if match else ''))


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


class Terminal:
    def __init__(self, output, root, env, evidence, number):
        self.evidence, self.label = evidence, 'gcu-' + str(number)
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.raw = (evidence / (self.label + '.pty')).open('xb')
        self.error_path = evidence / (self.label + '.stderr')
        self.inputs, self.status, self.eof = [], None, False
        self.deadline = time.monotonic() + 150
        self.argv = [str(output / 'bin/faangband'), '-mgcu', '-u' + NAME, '--', '-n1']
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                with self.error_path.open('xb') as error:
                    os.dup2(error.fileno(), 2)
                os.execve(self.argv[0], self.argv, env)
            except BaseException as error:
                os.write(2, (repr(error) + '\n').encode())
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display)

    def exited(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
        return self.status is not None

    def read(self, delay=.1):
        require(time.monotonic() < self.deadline, self.label + ' deadline exceeded\n' + self.text())
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
        self.raw.write(data)
        self.raw.flush()
        self.stream.feed(self.decoder.decode(data))
        check_errors(self.text())
        require(not self.error_path.read_bytes(), 'native GCU stderr is nonempty')
        return True

    def settle(self):
        while self.read(.2):
            pass

    def snapshot(self, label):
        name = self.label + '-' + label
        (self.evidence / (name + '.txt')).write_text(self.text() + '\n')
        cells = [[dict(char=c.data, fg=c.fg, bg=c.bg, bold=c.bold)
                  for c in [self.screen.buffer[y][x] for x in range(COLS)]] for y in range(ROWS)]
        write_json(self.evidence / (name + '.json'), dict(rows=ROWS, columns=COLS, cells=cells))
        return name + '.txt'

    def wait(self, predicate, label):
        while True:
            self.read()
            if predicate(self.text()):
                self.settle()
                if predicate(self.text()):
                    self.snapshot(label)
                    return
            require(not self.exited(), self.label + ' exited early\n' + self.text())

    def expect(self, phrase, label):
        self.wait(lambda text: phrase in text, label)

    def send(self, data, why):
        require(not self.exited(), 'cannot input to exited game')
        self.inputs.append(dict(bytes_hex=data.hex(), purpose=why))
        write_json(self.evidence / (self.label + '-inputs.json'), self.inputs)
        os.write(self.fd, data)

    def enter(self, restored):
        self.expect('[Press any key to continue]', 'splash')
        self.send(b' ', 'ordinary splash acknowledgement')
        if not restored:
            self.expect('Standard Wilderness', 'world-menu')
            self.send(b'a', 'select standard wilderness map')
            self.expect('Race affects stats', 'race-menu')
            self.send(b'a', 'select first ordinary race')
            self.settle()
            if 'Race affects stats' in self.text():
                self.send(b'\r', 'confirm highlighted ordinary race')
            self.expect('Class affects stats', 'class-menu')
            self.send(b'a', 'select Warrior')
            self.settle()
            if 'Class affects stats' in self.text():
                self.send(b'\r', 'confirm Warrior')
            self.expect('Choose how to generate', 'roller-menu')
            self.send(b'\r', 'use recommended point-based stats, no fixture')
            self.expect('left/right to modify', 'point-buy')
            self.send(b'\r', 'accept native allocated starting stats')
            self.expect('Enter a name for your character', 'name')
            self.send(NAME.encode() + b'\r', 'ordinary character name input')
            self.expect('Accept character history?', 'history')
            self.send(b'y', 'accept game-generated history')
            self.expect('any other key to continue', 'birth-confirmation')
            self.send(b'\r', 'complete ordinary birth')
        self.wait(lambda text: self.position_or_none() is not None and
                  ('HP' in text or 'LEV' in text), 'live')

    def position_or_none(self):
        positions = [(x, y) for y, row in enumerate(self.screen.display)
                     for x, char in enumerate(row) if char == '@' and x >= 13 and 1 <= y < ROWS-1]
        return positions[0] if len(positions) == 1 else None

    def live(self, label):
        self.settle()
        position = self.position_or_none()
        require(position is not None, 'unique native @ missing')
        frame = self.snapshot(label)
        return dict(position=list(position), frame=frame,
                    map=[row[13:] for row in self.screen.display[1:-1]],
                    sidebar=[row[:13] for row in self.screen.display[1:-1]],
                    status=self.screen.display[-1])

    def character(self, label):
        self.send(b'C', 'display ordinary character identity and turn counters')
        self.expect("'c' to change name", label)
        rows = self.screen.display
        fields = {}
        # The native panel is at x=1, with identity at x<21 and Game/Standard
        # counters at x=21..38. See ui-player.c:659-695,912-923.
        for key in ('Name', 'Race', 'Class', 'HP', 'SP', 'Gold'):
            matches = [row[1:21].strip()[len(key):].strip() for row in rows
                       if row[1:21].strip().startswith(key + ' ')]
            require(len(matches) == 1, 'missing visible character field ' + key)
            fields[key] = matches[0]
        for key in ('Game', 'Standard', 'Resting'):
            matches = [re.fullmatch(r'\s*' + key + r'\s+(\d+)\s*', row[21:40]) for row in rows]
            values = [int(m.group(1)) for m in matches if m]
            require(len(values) == 1, 'missing visible turn counter ' + key)
            fields[key] = values[0]
        require(fields['Name'] == NAME and fields['Class'] == 'Warrior', 'wrong native identity')
        require(int(fields['HP'].split('/')[0]) > 0, 'character died')
        fields['frame'] = self.label + '-' + label + '.txt'
        self.send(b'\x1b', 'return from character sheet without a game turn')
        self.settle()
        return fields

    def move(self, label):
        before = self.live(label + '-before')
        x, y = before['position']
        choices = [('6', 1, 0), ('2', 0, 1), ('4', -1, 0), ('8', 0, -1),
                   ('3', 1, 1), ('1', -1, 1), ('7', -1, -1), ('9', 1, -1)]
        candidates = [(key, dx, dy) for key, dx, dy in choices
                      if 15 <= x+dx < COLS-3 and 3 <= y+dy < ROWS-3
                      and self.screen.display[y+dy][x+dx] == '.']
        require(candidates, 'no visibly clear adjacent floor; refusing blind/random movement')
        key, dx, dy = candidates[0]
        self.send(b';', 'ordinary walk command')
        self.expect('Direction', label + '-direction')
        self.send(key.encode(), 'walk onto observed adjacent floor')
        self.settle()
        after = self.live(label + '-after')
        require(after['position'] == [x+dx, y+dy], 'visible @ did not move exactly one selected tile')
        return dict(before=before, after=after, direction=key, delta=[dx, dy])

    def save_exit(self):
        self.send(b'\x18', 'ordinary save and quit')
        self.expect('Press Return (or Escape).', 'save-complete')
        require('Saving game... done.' in self.text(), 'native save success not displayed')
        self.send(b'\x1b', 'skip optional score prediction and exit normally')
        while not self.exited():
            self.read()
        self.settle()
        require(self.status == 0, 'native save/quit exit nonzero')
        require(not self.error_path.read_bytes(), 'native GCU stderr nonempty even with exit zero')
        self.raw.close()
        os.close(self.fd)

    def abort(self):
        if not self.exited():
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
        self.raw.close()
        os.close(self.fd)


class XImage(C.Structure):
    _fields_ = [('width', C.c_int), ('height', C.c_int), ('xoffset', C.c_int),
                ('format', C.c_int), ('data', C.c_void_p), ('byte_order', C.c_int),
                ('bitmap_unit', C.c_int), ('bitmap_bit_order', C.c_int),
                ('bitmap_pad', C.c_int), ('depth', C.c_int),
                ('bytes_per_line', C.c_int), ('bits_per_pixel', C.c_int),
                ('red_mask', C.c_ulong), ('green_mask', C.c_ulong), ('blue_mask', C.c_ulong)]


class Desktop:
    def __init__(self, env, evidence):
        self.env, self.evidence, self.sequence = env, evidence, 0
        self.lib = C.CDLL(os.environ['LIBX11'])
        for name, args, result in [
            ('XOpenDisplay', [C.c_char_p], C.c_void_p),
            ('XDefaultRootWindow', [C.c_void_p], C.c_ulong),
            ('XGetImage', [C.c_void_p, C.c_ulong, C.c_int, C.c_int, C.c_uint, C.c_uint,
                          C.c_ulong, C.c_int], C.c_void_p),
            ('XDestroyImage', [C.c_void_p], C.c_int),
            ('XCloseDisplay', [C.c_void_p], C.c_int)]:
            getattr(self.lib, name).argtypes = args
            getattr(self.lib, name).restype = result
        self.display = self.lib.XOpenDisplay(env['DISPLAY'].encode())
        require(self.display, 'cannot open private X display')
        self.root = self.lib.XDefaultRootWindow(self.display)
        self.inputs = []

    def key(self, key, purpose):
        # No --window: xdotool's default is XTest, not XSendEvent.
        subprocess.run([os.environ['XDOTOOL'], 'key', '--clearmodifiers', key],
                       env=self.env, check=True, capture_output=True, timeout=10)
        self.inputs.append(dict(key=key, purpose=purpose, mechanism='XTest'))
        write_json(self.evidence / 'sdl2-inputs.json', self.inputs)
        time.sleep(.3)

    def frame(self, label):
        time.sleep(.3)
        pointer = self.lib.XGetImage(self.display, self.root, 0, 0, 1280, 900,
                                    C.c_ulong(-1).value, 2)
        require(pointer, 'XGetImage failed')
        try:
            header = C.cast(pointer, C.POINTER(XImage)).contents
            require((header.depth, header.bits_per_pixel, header.byte_order,
                     header.red_mask, header.green_mask, header.blue_mask) ==
                    (24, 32, 0, 0xff0000, 0xff00, 0xff), 'unexpected native framebuffer format')
            data = C.string_at(header.data, header.bytes_per_line * 900)
            image = Image.frombytes('RGB', (1280, 900), data, 'raw', 'BGRX', header.bytes_per_line)
            path = self.evidence / (label + '.png')
            image.save(path)
            # main-sdl2.c:90-110,5275-5277 creates an 80x24 10x20
            # raster-font subwindow with 8px borders; 4370-4390 centers it.
            # The native2 screenshot establishes its actual outer bounds as
            # (232,192)-(1048,688). Exclude the ornamental wallpaper, which
            # otherwise fragments Tesseract's lines despite legible UI pixels.
            # This is observation only: original full screenshots stay intact.
            crop_box = (240, 200, 1040, 680)
            panel = image.crop(crop_box)
            panel.save(self.evidence / (label + '-panel.png'))
            # The default terminal surface is opaque black, including menus.
            # Reject a geometry mismatch rather than OCR arbitrary wallpaper.
            dark = sum(max(pixel) < 40 for pixel in panel.getdata())
            require(dark > panel.width * panel.height * .65,
                    'native SDL2 text panel not at its observed default geometry')
            # Isolate bright raster glyph ink (white/cyan/yellow); inverted
            # black-on-white text avoids dark-background OCR segmentation.
            ink = Image.new('L', panel.size)
            ink.putdata([0 if max(pixel) >= 110 else 255 for pixel in panel.getdata()])
            ocr_path = self.evidence / (label + '-ocr.png')
            ink.resize((1600, 960), Image.Resampling.NEAREST).save(ocr_path)
            texts = []
            for mode in ('6', '11'):
                result = subprocess.run([os.environ['TESSERACT'], str(ocr_path), 'stdout', '--psm', mode],
                    env=self.env, check=True, capture_output=True, text=True, timeout=20)
                (self.evidence / (label + '-psm' + mode + '.txt')).write_text(result.stdout)
                texts.append(result.stdout)
            text = '\n'.join(texts)
            (self.evidence / (label + '.txt')).write_text(text)
            write_json(self.evidence / (label + '-observation.json'),
                       dict(crop_box=crop_box, dark_pixels=dark,
                            input_frame=label + '.png', ocr_input=label + '-ocr.png'))
            check_errors(text)
            return text
        finally:
            self.lib.XDestroyImage(pointer)

    def expect(self, phrase, label, process):
        deadline = time.monotonic() + 25
        while time.monotonic() < deadline:
            self.sequence += 1
            text = self.frame(label + '-' + str(self.sequence))
            if re.search(phrase, text, re.I):
                return text
            require(process.poll() is None, 'SDL2 game exited before visible state: ' + phrase)
        raise AssertionError('SDL2 visible state absent: ' + phrase)


def native_save(root, evidence, label):
    path = root / 'data=proof/faangband/save' / NAME
    require(not (root / 'data').exists(), 'native XDG data path truncated at equals sign')
    files = sorted(p for p in path.parent.rglob('*') if p.is_file())
    require(files == [path] and not path.is_symlink(), 'expected one native private XDG save')
    data = path.read_bytes()
    require(len(data) > 100, 'native save empty/truncated')
    (evidence / (label + '.native-save')).write_bytes(data)  # Never read by game.
    return dict(path=str(path), size=len(data), sha256=hashlib.sha256(data).hexdigest())


def start_audio(root, env, evidence):
    pulse_config = root / 'pulse.pa'
    # External audio-server configuration only; no game configuration writes.
    pulse_config.write_text('load-module module-native-protocol-unix socket=' +
        str(root / 'runtime/pulse-native') + ' auth-anonymous=1\n'
        'load-module module-null-sink sink_name=fa_proof rate=22050 channels=2\n'
        'set-default-sink fa_proof\n')
    with (evidence / 'pulseaudio.stdout').open('xb') as stdout, \
         (evidence / 'pulseaudio.stderr').open('xb') as stderr:
        child = subprocess.Popen([os.environ['PULSEAUDIO'], '--daemonize=no', '-n',
            '--exit-idle-time=-1', '--use-pid-file=no', '--disable-shm=yes',
            '--log-target=stderr', '--file=' + str(pulse_config)], env=env,
            cwd=root / 'work', stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
    deadline = time.monotonic() + 20
    try:
        while not (root / 'runtime/pulse-native').exists():
            require(child.poll() is None and time.monotonic() < deadline, 'private audio server unavailable')
            time.sleep(.1)
    except BaseException:
        child.terminate()
        child.wait(timeout=10)
        raise
    return child


def graphical_audio(output, root, env, evidence, proof):
    children = []
    desktop = None

    def start(label, argv, **kwargs):
        with (evidence / (label + '.stdout')).open('xb') as stdout, \
             (evidence / (label + '.stderr')).open('xb') as stderr:
            child = subprocess.Popen(argv, env=env, cwd=root / 'work', stdin=subprocess.DEVNULL,
                                     stdout=stdout, stderr=stderr, **kwargs)
        children.append(child)
        return child

    try:
        env = dict(env, DISPLAY=':97', SDL_VIDEODRIVER='x11',
                   LIBGL_ALWAYS_SOFTWARE='1', MESA_SHADER_CACHE_DISABLE='true')
        xserver = start('xvfb', [os.environ['XVFB'], ':97', '-screen', '0', '1280x900x24',
                               '-nolisten', 'tcp', '-noreset', '-ac'])
        deadline = time.monotonic() + 20
        while not Path('/tmp/.X11-unix/X97').exists():
            require(xserver.poll() is None and time.monotonic() < deadline, 'private X server unavailable')
            time.sleep(.1)
        desktop = Desktop(env, evidence)
        command = [str(output / 'bin/faangband'), '-msdl2', '-ssdl', '-u' + NAME]
        game = start('sdl2-game', command)
        desktop.expect(r'Press any key to continue', 'sdl2-splash', game)
        # Query the actual SDL-created window, focus with X server calls, then
        # use XTest keyboard input. No synthetic game-event queue is involved.
        windows = subprocess.check_output([os.environ['XDOTOOL'], 'search', '--onlyvisible',
                    '--pid', str(game.pid)], env=env, timeout=10).split()
        require(windows, 'no visible SDL2 window belonging to native process')
        subprocess.run([os.environ['XDOTOOL'], 'windowfocus', '--sync', windows[0].decode()],
                       env=env, check=True, capture_output=True, timeout=10)
        proof['sdl2_process'] = dict(argv=command, namespace=namespace_receipt(Path('/proc') / str(game.pid)))
        desktop.key('space', 'ordinary splash acknowledgement; load native GCU save')
        desktop.key('C', 'show resumed character identity on real SDL2 surface')
        text = desktop.expect(r'OmpProof', 'sdl2-resumed-character', game)
        require(re.search(r'Warrior', text, re.I), 'SDL2 resumed class missing')
        desktop.key('Escape', 'return to native map')
        desktop.key('equal', 'open ordinary options')
        desktop.expect(r'User interface options', 'sdl2-options', game)
        desktop.key('a', 'open user interface options')
        text = desktop.expect(r'Use sound', 'sdl2-sound-before', game)
        # list-options.h puts rogue_like_commands first, use_sound second;
        # tag b selects its row, y sets true (not a blind toggle).
        desktop.key('b', 'select Use sound option')
        desktop.key('y', 'enable ordinary sound option')
        # Native3 shows ':' rasterized as '>' in OCR. Match the same
        # labeled row and option identifier, never a yes from another row.
        text = desktop.expect(r'(?m)^b\)[ \t]+Use sound[ \t]*[:>][ \t]*yes\b[^\n]*use_sound\b',
                              'sdl2-sound-enabled', game)
        desktop.key('Escape', 'leave interface options')
        desktop.key('Escape', 'leave options')
        # Monitor capture begins before E. Silence is not sound proof.
        raw_path = evidence / 'sdl2-food-audio.s16le'
        with raw_path.open('xb') as raw, (evidence / 'parec.stderr').open('xb') as error:
            recorder = subprocess.Popen([os.environ['PAREC'], '--device=fa_proof.monitor',
                '--format=s16le', '--rate=22050', '--channels=2', '--raw'], env=env,
                stdout=raw, stderr=error)
        children.append(recorder)
        time.sleep(.5)
        baseline = raw_path.stat().st_size
        desktop.key('E', 'eat native starting food through ordinary inventory UI')
        text = desktop.frame('sdl2-eat-selection')
        if re.search(r'Eat which food', text, re.I):
            # Native UI labels; choose a visibly identified ration, not a hardcoded
            # inventory slot or a seeded/generated object.
            matches = re.findall(r'\b([a-z])\)\s*[^\n]*(?:ration|food|biscuit|bread)', text, re.I)
            require(matches, 'native edible inventory label not visible')
            desktop.key(matches[0].lower(), 'choose visibly listed native food')
        time.sleep(2)
        eaten = desktop.frame('sdl2-food-consumed')
        # The native starting ration's completed effect says this, whereas
        # generic inventory messages also include failures such as no food.
        require(re.search(r'That tastes good', eaten, re.I) and
                not re.search(r'(Eat which food|You have no food)', eaten, re.I),
                'no visible completed native food-consumption evidence')
        streams = subprocess.run([os.environ['PACTL'], 'list', 'sink-inputs'], env=env,
                                  capture_output=True, text=True, check=True, timeout=10)
        (evidence / 'sdl2-audio-streams.txt').write_text(streams.stdout)
        require(re.search(r'application\.process\.id\s*=\s*"' + str(game.pid) + r'"', streams.stdout),
                'no audio stream owned by native SDL2 process on private server')
        recorder.terminate()
        recorder.wait(timeout=10)
        require(not (evidence / 'parec.stderr').read_bytes(), 'audio capture error')
        data = raw_path.read_bytes()
        require(len(data) > baseline + 22050 * 4, 'audio capture too short')
        end = len(data) // 4 * 4
        baseline = baseline // 4 * 4
        samples = struct.unpack('<' + 'h' * ((end-baseline)//2), data[baseline:end])
        nonzero = sum(abs(value) > 32 for value in samples)
        require(nonzero > 200 and max(map(abs, samples)) > 256, 'SDL2 capture is silent')
        with wave.open(str(evidence / 'sdl2-food-audio.wav'), 'wb') as wav:
            wav.setnchannels(2)
            wav.setsampwidth(2)
            wav.setframerate(22050)
            wav.writeframes(data[:end])
        proof['audio'] = dict(capture='sdl2-food-audio.wav', rate=22050, channels=2,
                              nonzero_samples=nonzero, peak=max(map(abs, samples)),
                              trigger='ordinary E and visible native starting-food selection',
                              monitor='fa_proof.monitor', baseline_bytes=baseline)
        desktop.key('ctrl+x', 'native SDL2 save and quit')
        desktop.expect(r'Press Return.*Escape', 'sdl2-save-complete', game)
        desktop.key('Escape', 'skip optional score display and exit normally')
        require(game.wait(timeout=20) == 0, 'SDL2 native exit nonzero')
        require(not (evidence / 'sdl2-game.stderr').read_bytes(), 'native SDL2 stderr nonempty even with exit zero')
        check_errors((evidence / 'sdl2-game.stdout').read_text(errors='replace'))
        proof['sdl2_save'] = native_save(root, evidence, 'sdl2-final')
    finally:
        if desktop:
            desktop.lib.XCloseDisplay(desktop.display)
        for child in reversed(children):
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()


def inside(output, evidence):
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc') / str(os.getpid()) / 'fd' / str(descriptor)
    proof = dict(success=False, source=SOURCE, revision=REVISION, sessions=[],
                 input='real PTY and XTest only', injected_game_state=False,
                 limits=['Ordinary early-game lifecycle, not a full playthrough.',
                         'GCU proves exact visible identity/turn/map continuity; SDL2 separately proves visible resume and captured audio.'])
    terminal, audio = None, None
    try:
        proof['driver_namespace'] = namespace_receipt(Path('/proc/self'))
        proof['readonly_store'], evidence = isolate(evidence)
        require(output.parent == Path('/gnu/store'), 'not a direct store output')
        for path in [output, *output.rglob('*')]:
            require(path.is_symlink() or not path.stat().st_mode & 0o222,
                    'store output has write bits: ' + str(path))
        root = evidence / 'private'
        root.mkdir(mode=0o700)
        # A valid '=' in XDG_DATA_HOME exercises the native -d parser without
        # changing ordinary game inputs or injecting any game configuration.
        for name in ('home', 'data=proof', 'config', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        # Keep a private passwd home as an escape guard even though the normal
        # package launcher overrides writable paths into XDG_DATA_HOME/faangband.
        # The FD-retained evidence remains reachable beneath a hidden host home.
        passwd_home = Path(pwd.getpwuid(os.getuid()).pw_dir)
        require(passwd_home.is_absolute() and passwd_home.is_dir() and
                passwd_home != Path('/') and not passwd_home.is_relative_to('/gnu/store'),
                'unsafe passwd home mount target')
        mount(root / 'home', passwd_home, 4096)
        proof['private_home'] = dict(passwd_home=str(passwd_home),
                                   source=str(root / 'home'), private_bind=True)
        env = dict(HOME=str(root / 'home'), XDG_DATA_HOME=str(root / 'data=proof'),
                   XDG_CONFIG_HOME=str(root / 'config'), XDG_CACHE_HOME=str(root / 'cache'),
                   XDG_STATE_HOME=str(root / 'state'), XDG_RUNTIME_DIR=str(root / 'runtime'),
                   TMPDIR=str(root / 'tmp'), PATH='', TERM='xterm-256color', LC_ALL='C.UTF-8',
                   DBUS_SESSION_BUS_ADDRESS='unix:path=/run/no-session-bus',
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path=/run/no-system-bus')
        proof['xdg_data_home'] = env['XDG_DATA_HOME']
        for key in ('TERMINFO', 'TERMINFO_DIRS'):
            if os.environ.get(key):
                env[key] = os.environ[key]
        # main.c initializes SDL_mixer even for GCU with use_sound false.
        # Supply real audio before birth, never dummy audio or stderr filtering.
        env.update(SDL_AUDIODRIVER='pulseaudio',
                   PULSE_SERVER='unix:' + str(root / 'runtime/pulse-native'))
        audio = start_audio(root, env, evidence)
        previous, previous_sheet = None, None
        for number in (1, 2):
            terminal = Terminal(output, root, env, evidence, number)
            terminal.enter(number == 2)
            process = namespace_receipt(Path('/proc') / str(terminal.pid))
            initial = terminal.live('initial')
            sheet = terminal.character('initial-character')
            if previous is not None:
                require(initial['position'] == previous['position'], 'resume changed visible player position')
                require(initial['map'] == previous['map'], 'resume changed full visible map')
                require({k:v for k,v in sheet.items() if k != 'frame'} ==
                        {k:v for k,v in previous_sheet.items() if k != 'frame'},
                        'resume changed visible identity, HP, gold or exact turn counters')
                proof['continuity'] = dict(full_visible_map_equal=True, position_equal=True,
                                          identity_and_turns_equal=True)
            movement = terminal.move('ordinary-step')
            advanced = terminal.character('advanced-character')
            require(advanced['Standard'] > sheet['Standard'] and advanced['Game'] > sheet['Game'],
                    'visible movement did not advance native turn counters')
            previous = terminal.live('pre-save')
            previous_sheet = advanced
            terminal.save_exit()
            saved = native_save(root, evidence, 'gcu-' + str(number))
            if proof['sessions']:
                require(saved['sha256'] != proof['sessions'][0]['save']['sha256'], 'continued play save unchanged')
            proof['sessions'].append(dict(argv=terminal.argv, namespace=process, initial=initial,
                character=sheet, movement=movement, advanced_character=advanced, pre_save=previous,
                save=saved, exit_status=terminal.status))
            terminal = None
            write_json(evidence / 'native-gameplay.json', proof)
        graphical_audio(output, root, env, evidence, proof)
        proof['footprint'] = {str(p.relative_to(root)): dict(size=p.stat().st_size, sha256=sha(p))
                              for p in root.rglob('*') if p.is_file()}
        require(all(not p.is_symlink() and p.stat().st_uid == os.getuid() for p in root.rglob('*')),
                'native state symlink or ownership escape')
        require(not (root / 'data').exists(), 'native state escaped into truncated XDG data path')
        proof['xdg_equals_path_preserved'] = True
        proof['success'] = True
        (evidence / 'SUMMARY.txt').write_text(
            'PASS: ordinary character birth, visible one-tile move and increased Game/Standard turns;\n'
            'native save/quit/relaunch, exact visible map/identity/HP/gold/turn resume, continued move;\n'
            'SDL2 visible resume, ordinary sound UI, native food sound recorded from private monitor.\n'
            'Private same-UID/GID user/mount/network/PID namespaces; recursively read-only store.\n'
            'See consumer-receipt.json for before/after NAR, native-gameplay.json, gcu-*.pty/.txt/.json,\n'
            'sdl2-*.png/.txt and sdl2-food-audio.wav. No game state/config was injected.\n')
    except BaseException as error:
        proof['error'] = repr(error)
        proof['traceback'] = traceback.format_exc()
        if terminal:
            terminal.snapshot('failure')
            terminal.abort()
        raise
    finally:
        if audio is not None and audio.poll() is None:
            audio.terminate()
            try:
                audio.wait(timeout=5)
            except subprocess.TimeoutExpired:
                audio.kill()
                audio.wait()
        write_json(evidence / 'native-gameplay.json', proof)
        os.close(descriptor)


def main():
    require(len(sys.argv) in (3, 4), 'usage: faangband-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:3])
    if len(sys.argv) == 4:
        require(sys.argv[3] == '--inside', 'unknown driver argument')
        inside(output, evidence)
        return
    require(output.is_absolute() and output.resolve() == output, 'canonical output required')
    require(evidence.is_absolute() and evidence.resolve() == evidence, 'canonical evidence required')
    keep = ('PYTHON_SITE_PACKAGES', 'UNSHARE', 'XVFB', 'LIBX11', 'XDOTOOL', 'TESSERACT',
            'PULSEAUDIO', 'PACTL', 'PAREC', 'TERMINFO', 'TERMINFO_DIRS')
    env = {key: os.environ[key] for key in keep if os.environ.get(key)}
    env.update(LC_ALL='C.UTF-8', PATH='', FA_HOST_UID=str(os.getuid()), FA_HOST_GID=str(os.getgid()))
    for kind in ('user', 'mnt', 'net', 'pid'):
        env['FA_HOST_' + kind.upper()] = os.readlink('/proc/self/ns/' + kind)
    command = [env['UNSHARE'], '--user', '--map-current-user', '--keep-caps', '--mount',
               '--propagation', 'private', '--net', '--pid', '--mount-proc', '--kill-child', '--fork',
               sys.executable, '-I', '-S', '-B', str(Path(__file__).resolve()),
               str(output), str(evidence), '--inside']
    receipt = dict(argv=command, host={k:v for k,v in env.items() if k.startswith('FA_HOST_')})
    write_json(evidence / 'namespace-launch.json', receipt)
    with (evidence / 'namespace.stdout').open('xb') as stdout, (evidence / 'namespace.stderr').open('xb') as stderr:
        process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        try:
            status = process.wait(timeout=480)
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise
    receipt['exit_status'] = status
    write_json(evidence / 'namespace-launch.json', receipt)
    require(status == 0, 'isolated native proof failed; inspect namespace.stderr and native-gameplay.json')


if __name__ == '__main__':
    main()
