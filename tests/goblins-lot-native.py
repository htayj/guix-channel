#!/usr/bin/env python3
"""Unseeded external X11 consumer of Goblins' Lot 497febbb.

Only ordinary native keyboard/mouse input changes game state. Font/tileset image
bytes are read for framebuffer recognition, never replaced. No process memory,
engine bindings, developer console, config writes or save decoding are used.
Source controls: GCamp.cpp MainMenu/SaveMenu/LoadMenu/TilesetsMenu; UI.cpp;
UI/ConstructionDialog.cpp; Stockpile.cpp GetTooltip; gcamp_core/tutorial.py.
"""
import ctypes
import errno
import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import stat
import subprocess
import sys
import time
import traceback

ERROR = re.compile(r'Traceback|Segmentation fault|symbol lookup error|terminate called|'
                   r'critical error occurred|Could not (?:load|save) the game|'
                   r'Assertion .+ failed|Cannot load user config|Permission denied', re.I)


def require(value, message):
    if not value:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def mount(source, target, flags, filesystem=None, data=None):
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_char_p]
    encode = lambda x: None if x is None else os.fsencode(x)
    if libc.mount(encode(source), encode(target), encode(filesystem), flags, encode(data)):
        number = ctypes.get_errno()
        raise OSError(number, os.strerror(number), str(target))


def namespace_proof(pid):
    proc = Path('/proc') / str(pid)
    proof = {'files': {}, 'namespaces': {}}
    for kind, label in [('user', 'USER'), ('mnt', 'MOUNT'), ('net', 'NET'), ('pid', 'PID')]:
        value = os.readlink(proc / 'ns' / kind)
        require(value != os.environ['HOST_' + label + '_NS'], 'host namespace leaked: ' + kind)
        require(value == os.readlink('/proc/self/ns/' + kind), 'namespace escape: ' + kind)
        proof['namespaces'][kind] = value
    for name in ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route'):
        proof['files'][name] = (proc / name).read_text()
    for kind, label in [('uid', 'Uid'), ('gid', 'Gid')]:
        identity = int(os.environ['HOST_' + kind.upper()])
        values = re.search(r'^' + label + r':\s*(.+)$', proof['files']['status'], re.M)
        require(identity != 0 and values and list(map(int, values[1].split())) == [identity] * 4,
                'not same ordinary caller identity: ' + kind)
        require(list(map(int, proof['files'][kind + '_map'].split())) == [identity, identity, 1],
                'not map-current-user: ' + kind)
    interfaces = [line.split(':')[0].strip() for line in proof['files']['net/dev'].splitlines() if ':' in line]
    require(interfaces == ['lo'], 'external network interface present')
    require(len(proof['files']['net/route'].splitlines()) <= 1, 'external IPv4 route present')
    require(all(row.split()[-1] == 'lo' for row in proof['files']['net/ipv6_route'].splitlines() if row.strip()),
            'external IPv6 route present')
    return proof


def isolate(evidence):
    require(os.getpid() == 1, 'driver must be private PID1')
    proof = namespace_proof('self')
    mount('/gnu/store', '/gnu/store', 4096 | 16384)
    mount(None, '/gnu/store', 262144 | 16384)
    entries = []
    for line in Path('/proc/self/mountinfo').read_text().splitlines():
        fields = line.split()
        if fields[4] == '/gnu/store' or fields[4].startswith('/gnu/store/'):
            entries.append(fields[4])
    for target in sorted(set(entries), key=len, reverse=True):
        mount(target, target, 4096 | 32 | 1)
    text = Path('/proc/self/mountinfo').read_text()
    for line in text.splitlines():
        fields = line.split()
        if fields[4] == '/gnu/store' or fields[4].startswith('/gnu/store/'):
            require('ro' in fields[5].split(',') and not any(
                value.startswith(('shared:', 'master:')) for value in fields[6:fields.index('-')]),
                'store is not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store statvfs is writable')
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
        mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=0755')
        retained = Path('/tmp/goblins-lot-evidence')
        retained.mkdir(mode=0o700)
        mount('/proc/self/fd/' + str(descriptor), retained, 4096)
    finally:
        os.close(descriptor)
    os.chdir('/tmp')
    for path in ('/home', '/root'):
        if Path(path).is_dir():
            mount('tmpfs', path, 2 | 4, 'tmpfs', 'mode=0755')
    Path('/tmp/.X11-unix').mkdir(mode=0o1777)
    os.chmod('/tmp/.X11-unix', 0o1777)
    (retained / 'mountinfo-isolated.txt').write_text(Path('/proc/self/mountinfo').read_text())
    proof['read_only_store_mounts'] = entries
    return retained, proof


def drop_capabilities():
    libc = ctypes.CDLL(None, use_errno=True)
    libc.prctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_ulong]
    capability = 0
    while libc.prctl(23, capability, 0, 0, 0) >= 0:
        require(libc.prctl(24, capability, 0, 0, 0) == 0, 'capability bounding drop failed')
        capability += 1
    require(ctypes.get_errno() == errno.EINVAL and capability > 0, 'capability enumeration failed')
    require(libc.prctl(47, 4, 0, 0, 0) == 0, 'ambient capabilities clear failed')
    require(libc.prctl(38, 1, 0, 0, 0) == 0, 'NoNewPrivs failed')

    class Header(ctypes.Structure):
        _fields_ = [('version', ctypes.c_uint32), ('pid', ctypes.c_int)]

    class Data(ctypes.Structure):
        _fields_ = [('effective', ctypes.c_uint32), ('permitted', ctypes.c_uint32),
                    ('inheritable', ctypes.c_uint32)]

    header, data = Header(0x20080522, 0), (Data * 2)()
    libc.capset.argtypes = [ctypes.POINTER(Header), ctypes.POINTER(Data)]
    require(libc.capset(ctypes.byref(header), data) == 0, 'capset failed')


def inventory(root):
    result = {}
    for path in sorted(root.rglob('*')):
        info = path.lstat()
        item = {'uid': info.st_uid, 'gid': info.st_gid, 'mode': stat.S_IMODE(info.st_mode)}
        if path.is_symlink():
            item.update(type='symlink', target=os.readlink(path))
        elif path.is_file():
            data = path.read_bytes()
            item.update(type='file', bytes=len(data), sha256=digest(data))
        else:
            item['type'] = 'directory' if path.is_dir() else 'other'
        result[str(path.relative_to(root))] = item
    return result


def rectangle(rgb, width, x, y, w, h):
    return b''.join(rgb[((y + row) * width + x) * 3:((y + row) * width + x + w) * 3]
                    for row in range(h))


class Observer:
    """Read original ASCII-in-column font masks from installed terminal.png."""
    def __init__(self, session):
        font = session.output / 'share/games/goblins-lot/terminal.png'
        width, height, rgb = session.image(font)
        require(width % 16 == height % 16 == 0, 'native 16x16 font atlas geometry changed')
        self.w, self.h = width // 16, height // 16
        self.glyphs, self.cache = {}, {}
        for code in range(256):
            tile = rectangle(rgb, width, (code // 16) * self.w, (code % 16) * self.h, self.w, self.h)
            self.glyphs[(code, 'native')] = self.mask(tile)
            # Retained native1 screenshot matches nearest sampling of a
            # (w-1)x(h-1) glyph source into the full wxh output cell. This
            # observation does not identify the configured renderer. Keep
            # the unscaled original too; both derive solely from the installed
            # immutable font, not from expected menu labels or OCR guesses.
            sampled = bytearray()
            for y in range(self.h):
                sy = int((y + .5) * (self.h - 1) / self.h)
                for x in range(self.w):
                    sx = int((x + .5) * (self.w - 1) / self.w)
                    start = (sy * self.w + sx) * 3
                    sampled.extend(tile[start:start + 3])
            self.glyphs[(code, 'inset-sampling')] = self.mask(sampled)
        require(len(set(self.glyphs.values())) > 100, 'original font masks not distinguishable')
        self.font_sha = digest(font.read_bytes())

    @staticmethod
    def mask(tile):
        colors = [tuple(tile[i:i + 3]) for i in range(0, len(tile), 3)]
        background = max(set(colors), key=colors.count)
        distances = [sum(abs(a - b) for a, b in zip(color, background)) for color in colors]
        peak = max(distances)
        return sum(1 << i for i, value in enumerate(distances) if peak and value > peak / 3)

    def decode(self, rgb, width, height):
        rows = []
        for y in range(0, height - self.h + 1, self.h):
            chars = []
            for x in range(0, width - self.w + 1, self.w):
                tile = rectangle(rgb, width, x, y, self.w, self.h)
                if tile not in self.cache:
                    mask = self.mask(tile)
                    if not mask:
                        char = ' '
                    else:
                        error, code = min(((mask ^ glyph).bit_count(), key[0])
                                          for key, glyph in self.glyphs.items())
                        char = chr(code) if error <= 12 else '\ufffd'
                    self.cache[tile] = char
                chars.append(self.cache[tile])
            rows.append(''.join(chars))
        # Avoid retaining every animated terrain cell through long simulation.
        if len(self.cache) > 30000:
            self.cache.clear()
        return rows


class Session:
    def __init__(self, output, evidence, root, tools):
        self.output, self.evidence, self.root = output, evidence, root
        self.xvfb, self.xdotool, self.xwd, self.convert = tools
        self.server = self.process = self.window = None
        self.inputs, self.commands, self.sessions = [], [], []
        self.sequence = self.launches = 0
        self.mode = 'ascii'
        self.env = {'PATH': '', 'LC_ALL': 'C', 'SDL_VIDEODRIVER': 'x11', 'SDL_AUDIODRIVER': 'dummy',
                    'LIBGL_ALWAYS_SOFTWARE': '1', 'MESA_SHADER_CACHE_DISABLE': 'true',
                    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=/run/no-session',
                    'DBUS_SYSTEM_BUS_ADDRESS': 'unix:path=/run/no-system'}
        for variable, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                               ('XDG_RUNTIME_DIR', 'runtime'), ('TMPDIR', 'tmp')]:
            self.env[variable] = str(root / name)
        self.state = root / 'config/goblins-lot'
        self.observer = Observer(self)
        self.pile = None
        # Legacy TCOD key.c receives SDL letter keycodes without Shift case
        # conversion. Native textboxes therefore type lowercase letters even
        # for uppercase X keysyms; choose supported exact unique identities.
        self.pile_name = 'nativepile' + str(os.getpid()) + str(time.time_ns())[-7:]
        self.save_name = 'native' + str(time.time_ns())[-12:]

    def tool(self, *args, statuses=(0,)):
        result = subprocess.run(args, env=self.env, capture_output=True, timeout=20)
        self.commands.append({'argv': args, 'status': result.returncode,
                              'stdout_sha256': digest(result.stdout),
                              'stderr': result.stderr.decode(errors='replace')})
        record(self.evidence / 'consumer-commands.json', self.commands)
        require(result.returncode in statuses, 'consumer tool failed: ' + repr(args))
        return result.stdout

    def image(self, path):
        width, height = map(int, self.tool(self.convert, str(path), '-format', '%w %h', 'info:').split())
        rgb = self.tool(self.convert, str(path), '-alpha', 'off', '-depth', '8', 'rgb:-')
        require(len(rgb) == width * height * 3, 'incomplete image pixels')
        return width, height, rgb

    def start_display(self):
        readfd, writefd = os.pipe()
        try:
            with (self.evidence / 'xvfb.log').open('wb') as log:
                self.server = subprocess.Popen([self.xvfb, '-displayfd', str(writefd), '-screen', '0',
                    '1920x1080x24', '-nolisten', 'tcp', '-noreset', '-ac'], env=self.env,
                    pass_fds=(writefd,), stdout=log, stderr=log)
            os.close(writefd)
            writefd = None
            require(select.select([readfd], [], [], 20)[0] and self.server.poll() is None,
                    'private Xvfb readiness absent')
            display = os.read(readfd, 128).decode().strip()
            require(display.isdecimal(), 'bad displayfd response')
            self.env['DISPLAY'] = ':' + display
        finally:
            os.close(readfd)
            if writefd is not None:
                os.close(writefd)

    def launch(self):
        self.launches += 1
        with (self.evidence / ('game-' + str(self.launches) + '.log')).open('wb') as log:
            self.process = subprocess.Popen([str(self.output / 'bin/goblins-lot')], env=self.env,
                cwd=self.root / 'work', stdin=subprocess.DEVNULL, stdout=log, stderr=log)
        self.window = None
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'native game exited before window readiness')
            ids = self.tool(self.xdotool, 'search', '--onlyvisible', '--pid', str(self.process.pid),
                            '--name', "^Goblins' Lot$", statuses=(0, 1)).decode().splitlines()
            if ids:
                require(len(ids) == 1, 'native game window is not unique')
                self.window = ids[0]
                break
            time.sleep(.15)
        require(self.window, 'native window readiness timeout')
        self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
        proc = Path('/proc') / str(self.process.pid)
        proof = namespace_proof(self.process.pid)
        proof.update(pid=self.process.pid, executable=os.readlink(proc / 'exe'), cwd=os.readlink(proc / 'cwd'))
        require(Path(proof['executable']).resolve() == (self.output / 'bin/goblins-lot').resolve(),
                'not installed native executable')
        require(Path(proof['cwd']) == self.root / 'work', 'game not in unrelated empty working directory')
        status = proof['files']['status']
        for field in ('CapInh', 'CapPrm', 'CapEff', 'CapBnd', 'CapAmb'):
            require(int(re.search(r'^' + field + r':\s*(\w+)', status, re.M)[1], 16) == 0,
                    'game capability retained: ' + field)
        require(re.search(r'^NoNewPrivs:\s*1$', status, re.M), 'NoNewPrivs missing')
        for name in ('status', 'maps', 'mountinfo', 'cmdline'):
            (self.evidence / ('process-' + str(self.launches) + '-' + name + '.raw')).write_bytes((proc / name).read_bytes())
        self.sessions.append(proof)
        record(self.evidence / 'processes.json', self.sessions)
        self.wait('main-menu', lambda f: 'Main Menu' in f['text'] and 'New Game' in f['text'], 60)
        self.key('o', 'inspect native root console resolution settings')
        settings = self.wait('native-resolution', lambda f: 'Resolution (width)' in f['text'])
        values = []
        for label in ('Resolution (width)', 'Resolution (height)'):
            row = next(y for y, text in enumerate(settings['rows']) if label in text)
            number = re.search(r'\d+', settings['rows'][row + 1])
            require(number, 'native resolution field unreadable')
            values.append(int(number[0]))
        require(values[0] // self.observer.w == settings['cols'] and
                values[1] // self.observer.h == settings['lines'],
                'observed resolution and native root font grid disagree')
        record(self.evidence / ('native-geometry-' + str(self.launches) + '.json'),
               {'resolution': values, 'font_cell': [self.observer.w, self.observer.h],
                'root_console': [settings['cols'], settings['lines']], 'artifact': settings['artifact']})
        self.key('Escape', 'discard unchanged native settings')
        self.wait('settings-return-menu', lambda f: 'Main Menu' in f['text'])

    def event(self, label, **value):
        self.inputs.append(dict(label=label, monotonic=time.monotonic(), session=self.launches,
                                transport='native focused XTEST', **value))
        record(self.evidence / 'native-inputs.json', self.inputs)

    def key(self, key, label):
        require(self.process.poll() is None, 'game exited before input')
        self.event(label, key=key)
        self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
        # Explicit press/release: main menu consumes releases; gameplay presses.
        self.tool(self.xdotool, 'keydown', '--clearmodifiers', key)
        time.sleep(.07)
        self.tool(self.xdotool, 'keyup', key)
        time.sleep(.12)

    def move(self, x, y, label):
        self.event(label, pixel=[x, y])
        self.tool(self.xdotool, 'mousemove', '--window', self.window, str(x), str(y))
        time.sleep(.08)

    def click(self, x, y, label, button=1):
        self.move(x, y, label)
        self.event(label, button=button)
        self.tool(self.xdotool, 'mousedown', str(button))
        time.sleep(.09)
        self.tool(self.xdotool, 'mouseup', str(button))
        time.sleep(.15)

    def cell(self, x, y):
        return int((x + .5) * self.observer.w), int((y + .5) * self.observer.h)

    def click_text(self, frame, text, label):
        matches = [(row.index(text) + len(text) / 2, y) for y, row in enumerate(frame['rows']) if text in row]
        require(matches, 'visible control not found: ' + text)
        self.click(*self.cell(*matches[0]), label)

    def capture(self, label):
        require(self.process.poll() is None, 'native game exited during ' + label)
        self.sequence += 1
        stem = '%04d-%s' % (self.sequence, label)
        dump, png = self.evidence / (stem + '.xwd'), self.evidence / (stem + '.png')
        self.tool(self.xwd, '-silent', '-id', self.window, '-out', str(dump))
        self.tool(self.convert, str(dump), str(png))
        width, height, rgb = self.image(png)
        # Keep every raw evidence name but share storage for identical frames
        # from timeout polling. Existing failure evidence is never rewritten.
        previous = getattr(self, 'last', None)
        if previous and previous['rgb'] == rgb:
            for path in (dump, png):
                prior = self.evidence / (previous['artifact'] + path.suffix)
                path.unlink()
                os.link(prior, path)
        require(width % self.observer.w == height % self.observer.h == 0, 'window not native font-cell aligned')
        rows = self.observer.decode(rgb, width, height)
        text = '\n'.join(rows)
        require(not ERROR.search(text), 'native visible failure: ' + stem)
        frame = {'rows': rows, 'text': text, 'width': width, 'height': height, 'rgb': rgb,
                 'cols': width // self.observer.w, 'lines': height // self.observer.h,
                 'artifact': stem, 'png_sha256': digest(png.read_bytes())}
        (self.evidence / (stem + '.screen.txt')).write_text(text + '\n')
        record(self.evidence / (stem + '.json'), {k: v for k, v in frame.items() if k not in ('rgb', 'text')})
        self.last = frame
        return frame

    def tutorial(self, frame):
        text = frame['text']
        if any(marker in text for marker in ('Welcome to the Goblin Camp tutorial', 'Good work!',
                                             'Next you should do two things',
                                             'Now would be a good time to designate a farm plot.',
                                             'Alright, now you have wood logs!')):
            # MessageBox.hpp defaults to the ordinary visible "Ok" button.
            self.click_text(frame, 'Ok', 'acknowledge visible native tutorial')
            self.start_tutorial_seen = getattr(self, 'start_tutorial_seen', False) or 'Welcome to the Goblin Camp tutorial' in text
            return True
        return False

    def wait(self, label, predicate, timeout=20, tutorials=False):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            frame = self.capture(label)
            if tutorials and self.tutorial(frame):
                continue
            if predicate(frame):
                return frame
            time.sleep(.2)
        raise RuntimeError('observable native state timeout: ' + label)

    def world(self, label, timeout=30):
        return self.wait(label, lambda f: re.search(r'Orcs: \d+\s+Goblins: \d+', f['rows'][0])
                         and 'Main Menu' not in f['text'] and 'Saved games' not in f['text'],
                         timeout, tutorials=True)

    def pause(self, wanted):
        frame = self.world('pause-state')
        if ('PAUSED' in frame['rows'][1]) != wanted:
            self.key('space', 'native pause toggle')
            frame = self.wait('paused' if wanted else 'running',
                              lambda f: ('PAUSED' in f['rows'][1]) == wanted, tutorials=True)
        return frame

    def menu(self):
        for _ in range(3):
            frame = self.capture('main-menu-transition')
            if 'Main Menu' in frame['text'] and 'Tilesets' in frame['text']:
                return frame
            if self.tutorial(frame):
                continue
            self.key('Escape', 'native close panel or return to main menu')
        return self.wait('main-menu', lambda f: 'Main Menu' in f['text'] and 'Tilesets' in f['text'])

    def continue_game(self):
        self.key('c', 'main menu Continue release')
        return self.world('continued-world')

    def world_pixel(self, offset, frame):
        if self.mode == 'ascii':
            return self.cell(frame['cols'] // 2 + offset[0], frame['lines'] // 2 + offset[1])
        size = 16 if self.mode == 'default' else 32
        # GCamp CenterOn/ReturnToMark focus on tile center (+0.5), whereas
        # TCODMapRenderer floors focus before subtracting half console cells.
        return int(frame['width'] / 2 + offset[0] * size), int(frame['height'] / 2 + offset[1] * size)

    def inspect_pile(self, label, name=None, timeout=20):
        name = self.pile_name if name is None else name
        frame = self.world('before-pile-inspection')
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            # Tutorial acknowledgement moves the real pointer to its Ok
            # button. Re-establish this observation's hover afterwards; a
            # passive wait would watch unrelated ground for its whole timeout.
            self.move(*self.world_pixel(self.pile, frame), 'hover native player-created pile')
            frame = self.capture(label)
            if self.tutorial(frame):
                continue
            if name in frame['text']:
                return frame
            time.sleep(.2)
        raise RuntimeError('observable native state timeout: ' + label)

    def stock_amounts(self, frame, name):
        # Tooltip.cpp draws a rectangular darkestYellow (63,63,0) background
        # at one column for every entry. Find its actual framebuffer bounds
        # around the exact pile-name row; never scan terrain/announcements on
        # either side of that rectangle for category-looking text.
        hits = [(y, row.index(name)) for y, row in enumerate(frame['rows']) if name in row]
        require(len(hits) == 1, 'ambiguous/missing exact native pile tooltip identity')
        y, x = hits[0]
        w, h = self.observer.w, self.observer.h
        background = bytes((63, 63, 0))

        def painted(column, row):
            tile = rectangle(frame['rgb'], frame['width'], column * w, row * h, w, h)
            return sum(tile[i:i + 3] == background for i in range(0, len(tile), 3)) >= w * h // 16

        left, right = x, x + len(name)
        require(all(painted(column, y) for column in range(left, right)),
                'pile identity is not on native tooltip background')
        while left > 0 and painted(left - 1, y):
            left -= 1
        while right < frame['cols'] and painted(right, y):
            right += 1
        require(frame['rows'][y][left:right].rstrip() == name,
                'pile name does not begin exact native tooltip rectangle')
        amounts = {}
        for row in range(y + 1, frame['lines']):
            cells = [painted(column, row) for column in range(left, right)]
            if not any(cells):
                break
            require(all(cells) and (left == 0 or not painted(left - 1, row)) and
                    (right == frame['cols'] or not painted(right, row)),
                    'incomplete/ambiguous native pile tooltip rectangle')
            entry = frame['rows'][row][left:right]
            # Native Stockpile::GetTooltip prints one leading space for a
            # parent category, or literal tab+space for a child category.
            match = re.fullmatch(r'(?: |\t )([^\x00-\x1f\x7f\ufffd]+?) x([1-9][0-9]*) *', entry)
            require(match is not None, 'unreadable/truncated native pile category: ' + repr(entry))
            category = match[1]
            require(category == category.strip() and category not in amounts,
                    'ambiguous native pile category identity: ' + repr(category))
            amounts[category] = int(match[2])
        return amounts

    def create_pile(self):
        frame = self.pause(True)
        # A pile changes Camp::Center (Camp.cpp:77-93). Preserve the original
        # observed camera through the ordinary persistent F1 map mark rather
        # than assuming the new colony center is unchanged.
        self.key('shift+F1', 'set ordinary native camera mark before construction')
        # Retain only positions visibly occupied by original tree glyphs in
        # the initial ASCII world. Later modes must confirm species tooltip
        # before issuing an ordinary tree-felling job at each position.
        self.tree_candidates = sorted(
            [(dx, dy) for dy in range(-8, 9) for dx in range(-12, 13)
             if frame['rows'][frame['lines'] // 2 + dy][frame['cols'] // 2 + dx] in (chr(6), chr(215))],
            key=lambda p: abs(p[0]) + abs(p[1]))
        require(len(self.tree_candidates) >= 4, 'fewer than four observed nearby trees; retaining original RNG world')
        require(re.search(r'Orcs: 6\s+Goblins: 15', frame['rows'][0]), 'original 6 orcs/15 goblins not observed')
        # Choose a nearby 3x3 rectangle of actual visible grass glyphs, not an
        # invented coordinate or a restart until a convenient map appears.
        candidates = []
        for dy in range(-10, 11):
            for dx in range(-16, 12):
                if abs(dx) < 6 and abs(dy) < 6:
                    continue
                x, y = frame['cols'] // 2 + dx, frame['lines'] // 2 + dy
                if all(frame['rows'][yy][xx] in ".,:'" for yy in range(y, y + 3) for xx in range(x, x + 3)):
                    candidates.append((abs(dx) + abs(dy), dx, dy))
        require(candidates, 'no observed clear nearby 3x3 grass; retaining unmodified RNG world')
        _, dx, dy = min(candidates)
        self.pile = (dx, dy)
        self.move(*self.cell(4, 8), 'position native Basics menu')
        self.key('b', 'open native Basics construction menu')
        basics = self.wait('basics-menu', lambda f: 'Pile' in f['text'] and 'Farm plot' in f['text'])
        self.click_text(basics, 'Pile', 'choose native Pile')
        start = self.world_pixel((dx, dy), frame)
        self.move(*start, 'observe valid pile placement cursor')
        cursor = self.capture('native-placement-validity')
        tile = rectangle(cursor['rgb'], cursor['width'], start[0] - self.observer.w // 2,
                         start[1] - self.observer.h // 2, self.observer.w, self.observer.h)
        require(any(tile[i + 1] > tile[i] + 30 and tile[i + 1] > tile[i + 2] + 30
                    for i in range(0, len(tile), 3)), 'native green valid-placement cursor absent')
        # UI::ChooseStockpile uses native single-tile placement for Pile;
        # only farm plots have the rectangle cursor. Pile expands itself.
        self.click(*start, 'place original native single-tile Pile')
        self.click(*start, 'cancel remaining native placement cursor', button=3)
        self.inspect_pile('created-native-pile', 'Pile')
        renamed = self.rename_pile('Pile', self.pile_name)
        require(not self.stock_amounts(renamed, self.pile_name),
                'fresh paused player-created pile is unexpectedly nonempty')
        return {'offset_from_original_camera': self.pile, 'initial_native_tiles': 1,
                'placement': 'ordinary Pile single-tile cursor; automatic growth',
                'native_name': self.pile_name}

    def rename_pile(self, old, new):
        require(len(new) <= 28, 'native construction name exceeds textbox width')
        frame = self.pause(True)
        self.inspect_pile('pile-before-rename', old)
        dialog = None
        # A worker on the original tile sorts before constructions in native
        # HandleUnderCursor. Try observed adjacent expanded pile tiles, never
        # changing the world or assuming the first context belongs to a pile.
        original = self.pile
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            offset = (original[0] + dx, original[1] + dy)
            self.move(*self.world_pixel(offset, frame), 'observe pile context candidate')
            hovered = self.capture('pile-context-candidate')
            if old not in hovered['text']:
                continue
            self.click(*self.world_pixel(offset, frame), 'open native pile context', button=3)
            candidate = self.capture('native-context-opened')
            if 'Rename' in candidate['text'] and 'Dismantle' in candidate['text']:
                dialog = candidate
                break
            self.key('Escape', 'close visible non-construction context')
        require(dialog is not None, 'no visible construction context for player-created pile')
        self.click_text(dialog, 'Rename', 'native construction Rename')
        rename = self.wait('rename-dialog', lambda f: any(
            'Rename' in row for row in f['rows'][(f['lines'] - 8) // 2:(f['lines'] - 8) // 2 + 1]))
        require(old in rename['text'], 'rename dialog does not show selected pile name')
        for _ in old:
            self.key('BackSpace', 'remove original name in native textbox')
        for char in new:
            self.key(char, 'type native pile name')
        self.wait('rename-visible-value', lambda f: new in f['text'])
        self.key('Return', 'confirm native pile Rename')
        self.key('Escape', 'close native construction context')
        self.pile_name = new
        return self.inspect_pile('renamed-pile-visible')

    def aggregate(self, label, timeout=90):
        self.pause(False)
        end = time.monotonic() + timeout
        observations = []
        while time.monotonic() < end:
            frame = self.inspect_pile(label, timeout=10)
            amounts = self.stock_amounts(frame, self.pile_name)
            observations.append({'artifact': frame['artifact'], 'amounts': amounts})
            if amounts:
                record(self.evidence / (label + '-aggregation.json'), observations)
                return amounts
            time.sleep(.4)
        record(self.evidence / (label + '-aggregation.json'), observations)
        raise RuntimeError('native pile did not visibly aggregate stored items: ' + label)

    def worker_transition(self, label):
        self.pause(True)
        before = self.inspect_pile(label + '-before-work')
        previous = self.stock_amounts(before, self.pile_name)
        require(previous, 'worker transition needs existing stored native pile')
        selected = None
        while self.tree_candidates:
            offset = self.tree_candidates.pop(0)
            self.move(*self.world_pixel(offset, before), 'observe original native tree in ' + label)
            tree = self.capture(label + '-tree-before-order')
            species = re.search(r'\b(Pine|Birch|Spruce)\b', tree['text'])
            if species:
                selected = (offset, tree, species[0])
                break
        require(selected, 'no remaining observed log-producing tree for ' + label)
        offset, tree, species = selected
        self.move(*self.cell(4, 8), 'position native Orders menu')
        self.key('o', 'open ordinary native Orders menu')
        orders = self.wait(label + '-orders', lambda f: 'Fell trees' in f['text'])
        self.click_text(orders, 'Fell trees', 'choose direct native worker felling order')
        point = self.world_pixel(offset, before)
        self.move(*point, 'target observed native ' + species)
        self.tool(self.xdotool, 'mousedown', '1')
        time.sleep(.12)
        self.tool(self.xdotool, 'mouseup', '1')
        self.event('commit ordinary one-tree felling rectangle', pixel=point, species=species)
        time.sleep(.2)
        # Native rectangle logic deliberately leaves equal drag endpoints
        # pending on first release; a second ordinary click commits a 1x1
        # rectangle (UI.cpp:356-395), rather than canceling the unissued job.
        self.click(*point, 'commit second corner of native one-tree rectangle')
        self.click(*point, 'cancel remaining native felling cursor', button=3)
        self.key('j', 'inspect freshly queued native worker job while paused')
        jobs = self.wait(label + '-queued-felling-job', lambda f: 'Jobs' in f['text'])
        self.key('Escape', 'close native job list before workers run')
        # Each selected species produces five logs. No saw pit or consumption
        # order is created: requiring five NEW stored logs proves both the
        # felling job and subsequent worker deliveries, even when the original
        # pile was already full of previously collected items.
        baseline = previous.get('Log', 0)
        self.pause(False)
        end = time.monotonic() + 120
        observations = []
        while time.monotonic() < end:
            current = self.inspect_pile(label + '-worker-delivery')
            amounts = self.stock_amounts(current, self.pile_name)
            observations.append({'artifact': current['artifact'], 'amounts': amounts})
            if amounts.get('Log', 0) >= baseline + 5:
                self.pause(True)
                self.move(*point, 'observe tree after native worker felling')
                removed = self.capture(label + '-tree-after-work')
                require(not re.search(r'\b' + species + r'\b', removed['text']),
                        'new stored logs observed but targeted tree remains')
                proof = {'pile_name': self.pile_name, 'species': species, 'tree_offset': offset,
                         'before': previous, 'after': amounts, 'required_new_stored_logs': 5,
                         'tree_before_artifact': tree['artifact'], 'queued_job_artifact': jobs['artifact'],
                         'felling_job_visible': 'Fell tree' in jobs['text'],
                         'tree_after_artifact': removed['artifact'], 'deliveries': observations}
                record(self.evidence / (label + '-worker-transition.json'), proof)
                return proof
            time.sleep(.4)
        record(self.evidence / (label + '-worker-transition-failure.json'), observations)
        raise RuntimeError('native felling/hauling did not add five stored logs: ' + label)

    def expansion_proof(self):
        self.pause(True)
        frame = self.inspect_pile('pile-before-expansion-inspection')
        occupied = []
        # Only the original single tile was placed. The same unique tooltip
        # on an adjacent native world tile proves automatic pile expansion.
        for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            offset = (self.pile[0] + dx, self.pile[1] + dy)
            self.move(*self.world_pixel(offset, frame), 'inspect neighboring native pile tile')
            observed = self.capture('native-pile-expansion')
            if self.pile_name in observed['text']:
                occupied.append({'offset': offset, 'artifact': observed['artifact']})
        require(occupied, 'player-created pile did not automatically grow beyond original tile')
        return occupied

    def map_proof(self, frame):
        if self.mode == 'ascii':
            terrain = sum(char in ".,:'" for row in frame['rows'][8:-8] for char in row[8:-16])
            require(terrain > 100, 'original ASCII terrain absent')
            return {'terrain_glyphs': terrain, 'artifact': frame['artifact']}
        # Require authentic original grass tile interiors at many actual map
        # positions. A blank canvas with a perfectly working UI fails here.
        size = 16 if self.mode == 'default' else 32
        atlas = self.output / ('share/games/goblins-lot/lib/tilesets_core/' + self.mode + '/terrain.png')
        aw, ah, pixels = self.image(atlas)
        require(aw % size == ah % size == 0, 'original terrain atlas dimensions invalid')
        side = size - 4
        originals = {}
        for index in range(20, 29):
            x, y = (index % (aw // size)) * size + 2, (index // (aw // size)) * size + 2
            tile = rectangle(pixels, aw, x, y, side, side)
            originals[tile] = index
        matches = []
        # Native camera mark focuses on a world tile center (+0.5).
        origin_x = int(frame['width'] / 2 - size / 2) % size
        origin_y = int(frame['height'] / 2 - size / 2) % size
        for y in range(origin_y + size * 3, frame['height'] - size * 3, size):
            for x in range(origin_x + size * 3, frame['width'] - size * 3, size):
                sample = rectangle(frame['rgb'], frame['width'], x + 2, y + 2, side, side)
                if sample in originals:
                    matches.append([x, y, originals[sample]])
        regions = {(int(x * 4 / frame['width']), int(y * 4 / frame['height'])) for x, y, _ in matches}
        require(len(matches) >= 8 and len(regions) >= 4,
                'genuine ' + self.mode + ' map absent: original grass tile matches=' + str(len(matches)))
        return {'artifact': frame['artifact'], 'atlas_sha256': digest(atlas.read_bytes()),
                'original_grass_tile_matches': matches, 'regions': sorted(regions)}

    def tileset(self, mode):
        self.pause(True)
        self.menu()
        self.key('t', 'main menu native Tilesets release')
        frame = self.wait('tilesets-menu', lambda f: 'Classical Text Mode' in f['text'] and 'Details' in f['text'])
        label = {'ascii': 'Classical Text Mode', 'default': 'Default Tileset',
                 'default_x2': 'Default Tileset x 2'}[mode]
        # Select exact left-list row rather than matching the Details duplicate.
        rows = [(y, row[:frame['cols'] // 3]) for y, row in enumerate(frame['rows'])]
        matches = [(y, row) for y, row in rows if row.strip().strip(chr(179)).strip() == label]
        # Borders are extended font symbols; literal content is enough only if
        # its right-hand suffix contains no other printable name characters.
        if not matches:
            matches = [(y, row) for y, row in rows if label in row and
                       not row[row.index(label) + len(label):].strip(' ' + chr(179))]
        require(len(matches) == 1, 'exact native tileset list entry absent: ' + label)
        self.click(*self.cell(4, matches[0][0]), 'select original ' + mode + ' via native tileset list')
        selected = self.wait('tileset-selected-' + mode, lambda f: 'Name:    ' + label in f['text'])
        if mode != 'ascii':
            size = 16 if mode == 'default' else 32
            require('Size:    %dx%d' % (size, size) in selected['text'], 'selected wrong original tile dimensions')
        self.click_text(selected, 'Ok', 'apply native tileset with Ok')
        self.wait('tileset-return-menu', lambda f: 'Main Menu' in f['text'])
        self.mode = mode
        self.continue_game()
        self.key('F1', 'return to original native camera mark after renderer change')
        frame = self.world('genuine-map-' + mode)
        proof = self.map_proof(frame)
        self.inspect_pile('pile-in-' + mode)
        old = self.pile_name
        suffix = {'default': 'd', 'default_x2': 'x', 'ascii': 'a'}[mode]
        self.rename_pile(old, old + suffix)
        proof['worker_transition'] = self.worker_transition('workers-' + mode)
        proof['stored_items'] = proof['worker_transition']['after']
        return proof

    def save(self, label):
        self.pause(True)
        frame = self.inspect_pile(label + '-pile')
        amounts = self.stock_amounts(frame, self.pile_name)
        require(amounts, 'save needs visible nonempty player-created pile')
        self.menu()
        self.key('s', 'main menu native Save release')
        self.wait('save-dialog', lambda f: 'Save name' in f['text'])
        for char in self.save_name:
            self.key(char, 'type unique native save filename')
        self.wait('typed-save-name', lambda f: self.save_name in f['text'])
        self.key('Return', 'commit native save')
        path = self.state / ('saves/' + self.save_name + '.sav')
        end = time.monotonic() + 30
        while time.monotonic() < end:
            visible = self.capture('save-completion')
            if 'Save game exists, overwrite?' in visible['text']:
                self.click_text(visible, 'Yes', 'native overwrite confirmation')
                continue
            if 'Main Menu' in visible['text'] and path.is_file() and path.stat().st_size > 33:
                break
            time.sleep(.2)
        else:
            raise RuntimeError('native save did not complete')
        data = path.read_bytes()
        require(data[:4] == b'GCMP' and data[4] == 1 and data[5] in (0, 1) and len(data) > 1024,
                'invalid/truncated native 33-byte-header GCMP save')
        target = self.evidence / (label + '.sav')
        shutil.copyfile(path, target)
        return {'name': self.save_name, 'pile_name': self.pile_name, 'amounts': amounts,
                'bytes': len(data), 'sha256': digest(data), 'header_hex': data[:33].hex(),
                'artifact': frame['artifact'], 'save_artifact': target.name}

    def normal_exit(self):
        self.menu()
        self.key('q', 'normal native main menu Exit release')
        require(self.process.wait(timeout=20) == 0, 'native normal Exit was nonzero')
        self.sessions[-1]['normal_exit_status'] = self.process.returncode
        record(self.evidence / 'processes.json', self.sessions)
        self.window = None

    def restore(self, saved):
        self.launch()
        self.key('l', 'main menu native Load release')
        frame = self.wait('saved-games-dialog', lambda f: 'Saved games' in f['text'] and self.save_name in f['text'])
        self.click_text(frame, self.save_name, 'real mouse press/release saved game row')
        frame = self.world('restored-world', 90)
        require('PAUSED' in frame['rows'][1], 'native Load did not pause restored world')
        self.key('F1', 'return to saved ordinary native camera mark')
        frame = self.inspect_pile('restored-unique-player-pile')
        actual = self.stock_amounts(frame, saved['pile_name'])
        require(actual == saved['amounts'], 'native restored unique pile contents differ')
        require(re.search(r'Orcs: 6\s+Goblins: 15', frame['rows'][0]), 'restored original colony count differs')
        return {'artifact': frame['artifact'], 'restored_pile_name': self.pile_name,
                'exact_visible_stored_items': actual}

    def cleanup(self):
        result = []
        for label, process in [('game', self.process), ('Xvfb', self.server)]:
            if process is None:
                continue
            forced = process.poll() is None
            if forced:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)
            result.append({'task_owned': label, 'pid': process.pid, 'status': process.returncode,
                           'forced_failure_cleanup': forced if label == 'game' else False,
                           'reaped': not (Path('/proc') / str(process.pid)).exists()})
        record(self.evidence / 'cleanup.json', result)
        return result


def play(session):
    session.start_display()
    session.launch()
    session.key('n', 'original native New Game release')
    initial = session.world('original-new-world', 120)
    # First tutorial arrives after 100 native ticks; observe and respond rather
    # than modifying its cvar. No input is sent merely because time elapsed.
    if not getattr(session, 'start_tutorial_seen', False):
        session.wait('native-start-tutorial', lambda f: 'Welcome to the Goblin Camp tutorial' in f['text'], 35)
        session.tutorial(session.last)
    pile = session.create_pile()
    ascii_map = session.map_proof(session.world('ascii-created-colony'))
    first_items = session.aggregate('ascii-workers-stored-items')
    pile['automatic_expansion'] = session.expansion_proof()
    modes = {'ascii': dict(ascii_map, stored_items=first_items)}
    for mode in ('default', 'default_x2'):
        modes[mode] = session.tileset(mode)
    modes['ascii-return'] = session.tileset('ascii')
    saved = session.save('first-native-save')
    session.normal_exit()
    restored = session.restore(saved)
    # Preserve the same original player pile across processes, then require
    # a new ordinary felling job and five new stored logs before resaving.
    old = session.pile_name
    session.rename_pile(old, old + 'r')
    resumed_work = session.worker_transition('post-load-workers')
    resumed_items = resumed_work['after']
    second = session.save('resaved-native-game')
    require(second['sha256'] != saved['sha256'] and second['pile_name'] != saved['pile_name'],
            'native post-load colony action/resave not persisted')
    session.normal_exit()
    # Restore the resave as well: confirms the post-load native rename itself
    # persisted, not simply a changed timestamp or GCMP file header.
    final_restore = session.restore(second)
    session.normal_exit()
    return {'initial_hud': initial['rows'][0], 'pile': pile, 'modes': modes,
            'first_save': saved, 'restart_load': restored, 'resumed_items': resumed_items,
            'resumed_worker_transition': resumed_work,
            'resave': second, 'resave_reload': final_restore}


def main():
    require(len(sys.argv) == 7, 'usage: native.py OUTPUT EVIDENCE XVFB XDOTOOL XWD CONVERT')
    output, original_evidence = map(Path, sys.argv[1:3])
    require(output.parent == Path('/gnu/store') and output.is_dir(), 'canonical direct store output required')
    require((output / 'bin/goblins-lot').read_bytes()[:4] == b'\x7fELF', 'installed native ELF required')
    descriptor = os.open(original_evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc/self/fd/' + str(descriptor))
    root = session = None
    report = {'success': False, 'output': str(output), 'upstream_commit': '497febbb3d1c807d475b7ba5299cb4527d5f8bd3',
              'injected_seed_config_save_assets': False, 'observation': 'original native X11 framebuffer and user files only'}
    failure = None
    try:
        evidence, report['isolation'] = isolate(evidence)
        root = evidence / 'private'
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        record(evidence / 'private-before.json', inventory(root))
        drop_capabilities()
        session = Session(output, evidence, root, sys.argv[3:])
        report['font_sha256'] = session.observer.font_sha
        report['gameplay'] = play(session)
        require(not list((root / 'work').iterdir()), 'native game wrote to unrelated caller cwd')
        require(session.state.is_dir() and list((root / 'config').iterdir()) == [session.state],
                'native private XDG_CONFIG_HOME/goblins-lot footprint wrong')
        for name in ('config.py', 'terminal.png', 'goblin-camp.log'):
            require((session.state / name).is_file(), 'native generated file absent: ' + name)
        require(digest((session.state / 'terminal.png').read_bytes()) == session.observer.font_sha,
                'native copied font differs from original installed font')
        for relative, item in inventory(root).items():
            require(item['uid'] == os.getuid() and item['gid'] == os.getgid(),
                    'native footprint changed ordinary ownership: ' + relative)
        logs = list(evidence.glob('game-*.log')) + list(root.rglob('*.log'))
        for path in logs:
            require(not ERROR.search(path.read_text(errors='replace')), 'native error in ' + str(path))
        report['success'] = True
    except BaseException as error:
        failure = error
        report['error'] = repr(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        if session is not None and session.window and session.process.poll() is None:
            try:
                session.capture('failure-last-native-frame')
            except BaseException as capture_error:
                report['failure_capture_error'] = repr(capture_error)
    finally:
        if session is not None:
            report['cleanup'] = session.cleanup()
        if root is not None:
            record(evidence / 'private-after.json', inventory(root))
        record(evidence / 'native-result.json', report)
        os.close(descriptor)
    require(report['success'] and failure is None, 'native acceptance failed: ' + repr(failure))


if __name__ == '__main__':
    main()
