#!/usr/bin/env python3
"""Unseeded installed Gnollcrawl consumer: real PTY and actual SDL2/X11.

No game hooks, prewritten rc, seeded state, screen painting or synthetic save.
Only public UI input and the game's own # dumps establish gameplay state.
"""
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
import signal
import stat
import struct
import subprocess
import sys
import termios
import time
import traceback

import pyte


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def mount(source, target, flags, filesystem=None, data=None):
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_char_p]
    libc.mount.restype = ctypes.c_int
    encode = lambda x: None if x is None else os.fsencode(x)
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
    interfaces = [row.split(':')[0].strip() for row in files['net/dev'].splitlines() if ':' in row]
    require(interfaces == ['lo'], 'external network interface exists')
    require(len(files['net/route'].splitlines()) <= 1, 'IPv4 route exists')
    require(all(row.split()[-1] == 'lo' for row in files['net/ipv6_route'].splitlines() if row.strip()),
            'external IPv6 route exists')
    return {'namespaces': actual, 'host_namespaces': host, 'files': files}


def isolate(evidence):
    require(os.getpid() == 1, 'driver must be private PID1')
    proof = namespace_proof('self')
    mount('/gnu/store', '/gnu/store', 4096 | 16384)
    mount(None, '/gnu/store', 262144 | 16384)  # recursively private
    def store_mounts():
        entries = []
        for line in Path('/proc/self/mountinfo').read_text().splitlines():
            fields = line.split()
            if fields[4] == '/gnu/store' or fields[4].startswith('/gnu/store/'):
                entries.append((fields[4], fields[5].split(','), fields[6:fields.index('-')]))
        return entries
    for target, _, _ in sorted(store_mounts(), key=lambda item: len(item[0]), reverse=True):
        mount(target, target, 4096 | 32 | 1)
    entries = store_mounts()
    require(entries and all('ro' in opts and 'rw' not in opts and not
                           any(x.startswith(('shared:', 'master:')) for x in optional)
                           for _, opts, optional in entries), 'store is not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store writable')
    fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
        mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=0755')
        retained = Path('/tmp/gnollcrawl-evidence')
        retained.mkdir(mode=0o700)
        mount('/proc/self/fd/' + str(fd), retained, 4096)
    finally:
        os.close(fd)
    # Neither frontend can consult the host's configuration or save files.
    for path in ('/home', '/root'):
        if Path(path).is_dir():
            mount('tmpfs', path, 2 | 4, 'tmpfs', 'mode=0755')
    Path('/tmp/.X11-unix').mkdir(mode=0o1777)
    os.chmod('/tmp/.X11-unix', 0o1777)
    (retained / 'mountinfo-isolated.txt').write_text(Path('/proc/self/mountinfo').read_text())
    proof['store_mounts'] = entries
    return retained, proof


def drop_capabilities():
    libc = ctypes.CDLL(None, use_errno=True)
    libc.prctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong,
                           ctypes.c_ulong, ctypes.c_ulong]
    libc.prctl.restype = ctypes.c_int
    def prctl(option, arg=0):
        if libc.prctl(option, arg, 0, 0, 0) < 0:
            number = ctypes.get_errno()
            raise OSError(number, os.strerror(number))
    capability = 0
    while libc.prctl(23, capability, 0, 0, 0) >= 0:
        prctl(24, capability)
        capability += 1
    require(ctypes.get_errno() == errno.EINVAL and capability > 0, 'capability enumeration failed')
    if libc.prctl(47, 4, 0, 0, 0) < 0:  # ambient clear all
        raise OSError(ctypes.get_errno(), 'ambient capabilities not cleared')
    prctl(38, 1)  # no_new_privs
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


def child_terminal():
    fcntl.ioctl(0, termios.TIOCSCTTY, 0)
    drop_capabilities()


def state(text, name):
    require(name in text and 'Human Fighter' in text and 'Dungeon' in text,
            'native dump lacks selected character/dungeon')
    fields = {}
    for label in ('Health', 'Magic', 'AC', 'EV', 'SH', 'Str', 'Int', 'Dex', 'Gold'):
        match = re.search(r'\b' + label + r':\s*([0-9]+(?:/[0-9]+)?)', text)
        require(match is not None, 'native dump lacks field: ' + label)
        fields[label] = match[1]
    location = re.search(r'^You are (?:on|in) .+\.$', text, re.M)
    require(location is not None, 'native dump lacks dungeon location')
    fields['location'] = location[0]
    fields['inventory'] = re.findall(r'^ [A-Za-z] - .+$', text, re.M)
    require(len(fields['inventory']) >= 3, 'native dump lacks genuine fighter inventory')
    return fields


def actor(grid):
    positions = [(x, y) for y, row in enumerate(grid) for x, char in enumerate(row) if char == '@']
    require(len(positions) == 1, 'native character-dump viewport lacks unique player')
    return positions[0]


def native_viewport(text):
    # chardump.cc _sdump_screenshot embeds view.cc screenshot(): unlike
    # the separate .map file, it explicitly renders you.pos() as '@'.
    # Keep the native bytes, not an overlaid or repainted player marker.
    candidates = []
    for block in text.split('\n\n'):
        rows = block.splitlines()
        if (len(rows) >= 2 and sum(row.count('@') for row in rows) == 1
                and all(':' not in row for row in rows)
                and sum(row.count('#') + row.count('.') for row in rows) >= 8):
            candidates.append(rows)
    require(len(candidates) == 1, 'native dump has no unambiguous screenshot section')
    actor(candidates[0])
    return candidates[0]


def movement_delta(before, after):
    # screenshot() trims the current native viewport, which can expand or
    # crop as the player moves. Align overlapping observed terrain only.
    candidates = []
    width_before = max(map(len, before))
    width_after = max(map(len, after))
    for sy in range(1 - len(before), len(after)):
        for sx in range(1 - width_before, width_after):
            matches = mismatches = landmarks = 0
            for y, row in enumerate(before):
                for x, char in enumerate(row):
                    ny, nx = y + sy, x + sx
                    if 0 <= ny < len(after) and 0 <= nx < len(after[ny]):
                        other = after[ny][nx]
                        if char not in ' @' and other not in ' @':
                            matches += char == other
                            mismatches += char != other
                            landmarks += char == other and char != '.'
            if matches >= 8 and landmarks >= 2:
                candidates.append((matches - 4 * mismatches, -mismatches, sx, sy))
    require(candidates, 'no shared native terrain for position proof')
    candidates.sort(reverse=True)
    require(len(candidates) == 1 or candidates[0][:2] != candidates[1][:2],
            'ambiguous native map alignment')
    _, _, sx, sy = candidates[0]
    bx, by = actor(before)
    ax, ay = actor(after)
    return [ax - bx - sx, ay - by - sy]


class Session:
    def __init__(self, profile, output, environment, root, evidence, mode, phase, display):
        self.profile, self.output, self.env = profile, output, environment
        self.root, self.evidence, self.mode = root, evidence, mode
        self.label, self.display = mode + '-' + phase, display
        self.inputs, self.commands = [], []
        self.capture_count = 0
        self.screen = pyte.Screen(100, 32)
        self.parser = pyte.ByteStream(self.screen)
        self.raw = (evidence / (self.label + '.raw')).open('wb')
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 32, 100, 0, 0))
        command = [str(output / 'bin' / ('gnollcrawl' if mode == 'terminal' else 'gnollcrawl-tiles')),
                   '-name', 'GnollProof', '-species', 'Hu', '-background', 'Fi']
        try:
            self.process = subprocess.Popen(command, env=environment, cwd=root / 'work',
                                            stdin=slave, stdout=slave, stderr=slave,
                                            start_new_session=True, preexec_fn=child_terminal)
        finally:
            os.close(slave)
        self.window = None
        self.last_text = ''

    def tool(self, tool, *args, allowed=(0,)):
        command = [str(self.profile / 'bin' / tool), *map(str, args)]
        result = subprocess.run(command, env=self.env, capture_output=True, timeout=20,
                                preexec_fn=drop_capabilities)
        self.commands.append({'argv': command, 'status': result.returncode,
                              'stderr': result.stderr.decode(errors='replace')})
        record(self.evidence / (self.label + '-tools.json'), self.commands)
        require(result.returncode in allowed, 'consumer command failed: ' + repr(command) +
                '\n' + result.stderr.decode(errors='replace'))
        return result

    def read(self, timeout=0.05):
        if not select.select([self.master], [], [], timeout)[0]:
            return False
        try:
            chunk = os.read(self.master, 65536)
        except OSError as error:
            if error.errno == errno.EIO:
                return False
            raise
        if not chunk:
            return False
        self.raw.write(chunk)
        self.raw.flush()
        self.parser.feed(chunk)
        return True

    def capture(self, label):
        self.capture_count += 1
        label = '%04d-%s' % (self.capture_count, label)
        while self.read(0):
            pass
        if self.mode == 'terminal':
            text = '\n'.join(self.screen.display)
        else:
            if self.window is None:
                found = self.tool('xdotool', 'search', '--onlyvisible', '--pid', self.process.pid,
                                  allowed=(0, 1))
                if found.returncode:
                    return ''
                windows = found.stdout.decode().splitlines()
                require(len(windows) == 1, 'native SDL window not unique')
                self.window = windows[0]
                self.tool('xdotool', 'windowfocus', '--sync', self.window)
            prefix = self.evidence / (self.label + '-' + label)
            self.tool('xwd', '-silent', '-id', self.window, '-out', str(prefix) + '.xwd')
            self.tool('convert', str(prefix) + '.xwd', str(prefix) + '.png')
            result = self.tool('tesseract', str(prefix) + '.png', 'stdout', '--psm', '11')
            text = result.stdout.decode(errors='replace')
            # Native title messages are small white text at TitleRegion's
            # origin above a randomly selected, high-detail title image.
            # Full-window sparse OCR misses that real line (native2 evidence).
            # Magnify only the top occupied raster band, retaining both the
            # untouched screenshot and the derived OCR crop. No painted text.
            instruction = str(prefix) + '-top-band.png'
            self.tool('convert', str(prefix) + '.png', '-trim', '+repage',
                      '-gravity', 'North', '-crop', '100%x48+0+0', '+repage',
                      '-resize', '300%', '-colorspace', 'Gray', instruction)
            top = self.tool('tesseract', instruction, 'stdout', '--psm', '6')
            text += '\n' + top.stdout.decode(errors='replace')
        (self.evidence / (self.label + '-' + label + '.txt')).write_text(text + '\n')
        self.last_text = text
        return text

    def wait(self, predicate, description, seconds=35):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            self.read()
            if predicate():
                return
            require(self.process.poll() is None, 'game exited waiting for ' + description + '\n' + self.last_text)
        raise RuntimeError('timed out waiting for ' + description + '\n' + self.last_text)

    def expect(self, pattern, description):
        def observed():
            text = self.capture('await-' + description)
            if self.mode == 'tiles' and re.search(r'press\s+any\s+key\s+to\s+start', text, re.I):
                self.send(' ', 'dismiss observed original SDL title screen')
                return False
            return re.search(pattern, text, re.I) is not None
        self.wait(observed, description)

    def send(self, keys, description):
        self.inputs.append({'keys': keys, 'purpose': description, 'monotonic': time.monotonic(),
                            'transport': 'PTY' if self.mode == 'terminal' else 'focused native XTEST'})
        record(self.evidence / (self.label + '-inputs.json'), self.inputs)
        if self.mode == 'terminal':
            value = keys.encode()
            require(os.write(self.master, value) == len(value), 'short PTY write')
        else:
            key = {'#': 'numbersign', '.': 'period', '+': 'plus', 'S': 'S',
                   '\x1b': 'Escape', ' ': 'space'}.get(keys, keys)
            self.tool('xdotool', 'key', '--clearmodifiers', key)
        time.sleep(0.12)

    def proof(self):
        proc = Path('/proc') / str(self.process.pid)
        report = namespace_proof(self.process.pid)
        status = (proc / 'status').read_text()
        for field in ('CapInh', 'CapPrm', 'CapEff', 'CapBnd', 'CapAmb'):
            match = re.search(r'^' + field + r':\s*([0-9a-f]+)$', status, re.M)
            require(match and int(match[1], 16) == 0, 'capabilities not dropped: ' + field)
        require(re.search(r'^NoNewPrivs:\s*1$', status, re.M), 'no_new_privs absent')
        executable = os.readlink(proc / 'exe')
        expected = self.output / 'libexec' / ('gnollcrawl' if self.mode == 'terminal' else 'gnollcrawl-tiles')
        require(Path(executable) == expected and expected.read_bytes()[:4] == b'\x7fELF',
                'not installed native game ELF: ' + executable)
        for name in ('status', 'maps', 'environ', 'cmdline', 'mountinfo'):
            (self.evidence / (self.label + '-process-' + name + '.raw')).write_bytes((proc / name).read_bytes())
        actual_env = dict(item.split(b'=', 1) for item in (proc / 'environ').read_bytes().split(b'\0') if b'=' in item)
        require(actual_env[b'HOME'].decode() == self.env['HOME'], 'launcher changed HOME')
        require(actual_env[b'CRAWL_DIR'].decode().rstrip('/') == str(self.root / 'data/gnollcrawl'),
                'launcher did not use isolated XDG game state')
        maps = (proc / 'maps').read_text()
        if self.mode == 'tiles':
            require('libSDL2-' in maps and 'libSDL2_mixer' in maps and 'libSDL2_image' in maps,
                    'actual tiles process lacks SDL2/image/audio libraries')
            require(self.window is not None, 'no actual SDL window')
            report['audio'] = self.audio_proof()
        report.update(executable=executable, pid=self.process.pid, window=self.window,
                      home_unchanged=True, dropped_capabilities=True, no_new_privs=True)
        return report

    def audio_proof(self):
        """Observe this native PID's opened stream on the private real server."""
        def blocks(text, kind):
            return re.split(r'(?m)(?=^' + re.escape(kind) + r' #\d+\s*$)', text)
        def field(block, name):
            match = re.search(r'(?m)^\s*' + re.escape(name) + r':\s*(.+)$', block)
            return match[1].strip() if match else None
        def owner(block):
            match = re.search(r'application\.process\.id\s*=\s*"(\d+)"', block)
            return int(match[1]) if match else None
        observed = {}
        def opened():
            snapshots = {}
            for kind in ('sinks', 'clients', 'sink-inputs'):
                result = self.tool('pactl', 'list', kind)
                text = result.stdout.decode(errors='replace')
                (self.evidence / (self.label + '-pulse-' + kind + '.txt')).write_text(text)
                snapshots[kind] = text
            sinks = {}
            for block in blocks(snapshots['sinks'], 'Sink'):
                index = re.match(r'Sink #(\d+)', block)
                if index and field(block, 'Name') == 'gnollcrawl_native':
                    sinks[index[1]] = block
            require(len(sinks) == 1, 'private native PulseAudio sink absent or ambiguous')
            clients = {}
            for block in blocks(snapshots['clients'], 'Client'):
                index = re.match(r'Client #(\d+)', block)
                if index:
                    clients[index[1]] = owner(block)
            matches = []
            for block in blocks(snapshots['sink-inputs'], 'Sink Input'):
                index = re.match(r'Sink Input #(\d+)', block)
                if not index:
                    continue
                stream_pid = owner(block)
                client_pid = clients.get(field(block, 'Client'))
                if (stream_pid == self.process.pid or client_pid == self.process.pid) and field(block, 'Sink') in sinks:
                    specification = field(block, 'Sample Specification')
                    require(specification and re.search(r'\b[1-9]\d*Hz\b', specification),
                            'native audio stream has no real sample specification')
                    matches.append({'sink_input_index': int(index[1]), 'sink_index': int(field(block, 'Sink')),
                                    'sink_name': 'gnollcrawl_native', 'native_game_pid': self.process.pid,
                                    'stream_property_pid': stream_pid, 'client_property_pid': client_pid,
                                    'sample_specification': specification,
                                    'corked': field(block, 'Corked'), 'mute': field(block, 'Mute')})
            if not matches:
                return False
            observed['streams'] = matches
            return True
        self.wait(opened, 'native PID audio sink input on private PulseAudio server', seconds=15)
        observed['opened_native_audio_stream'] = True
        record(self.evidence / (self.label + '-audio-proof.json'), observed)
        return observed

    def dungeon(self, restored=False):
        welcome = r'Welcome\s+back[,\s]+GnollProof' if restored else r'Welcome[,\s]+GnollProof'
        def observed():
            text = self.capture('restored-dungeon' if restored else 'dungeon')
            if self.mode == 'tiles' and re.search(r'press\s+any\s+key\s+to\s+start', text, re.I):
                self.send(' ', 'dismiss observed original SDL title on restore')
                return False
            ready = re.search(welcome, text, re.I) and re.search(r'Health\s*:', text, re.I)
            if self.mode == 'terminal':
                ready = ready and '@' in text
            return ready
        self.wait(observed, 'native dungeon HUD and welcome')
        if re.search(r'(?:--more--|press.+continue)', self.last_text, re.I):
            self.send(' ', 'dismiss observed original welcome pagination')

    def close(self):
        if self.process.poll() is None:
            if self.mode == 'tiles':
                try:
                    self.capture('failure-last-frame')
                except Exception:
                    pass
            os.killpg(self.process.pid, signal.SIGKILL)
            self.process.wait()
        while self.read(0):
            pass
        self.raw.close()
        os.close(self.master)
        raw = (self.evidence / (self.label + '.raw')).read_bytes().decode(errors='replace')
        require(not re.search(r'Segmentation fault|Assertion .+ failed|terminate called|'
                              r'Error opening file|Could not initialize SDL|'
                              r'ALSA lib .*(?:error|failed)|failed to (?:load|open)', raw, re.I),
                'native game reported a runtime error; inspect retained raw PTY')


def dump(session, game_state, expected, label):
    path = game_state / 'morgue/GnollProof.txt'
    if path.exists():
        path.unlink()
    session.send('#', 'native character dump: ' + label)
    def complete():
        if not path.is_file():
            return False
        try:
            if not re.search(r'Turns:\s*\d+', path.read_text()):
                return False
            for fd in Path('/proc/' + str(session.process.pid) + '/fd').iterdir():
                if fd.resolve() == path:
                    return False
        except FileNotFoundError:
            return False
        return True
    session.wait(complete, 'complete native dump')
    text = path.read_text()
    turns = int(re.search(r'Turns:\s*(\d+)', text)[1])
    require(turns == expected, 'native turn mismatch: expected %d got %d' % (expected, turns))
    fields = state(text, 'GnollProof')
    map_path = path.with_suffix('.map')
    require(map_path.is_file(), 'native map dump missing')
    grid = native_viewport(text)
    prefix = session.evidence / (session.label + '-' + label)
    prefix.with_suffix('.dump').write_text(text)
    prefix.with_suffix('.map').write_bytes(map_path.read_bytes())
    prefix.with_suffix('.viewport').write_text('\n'.join(grid) + '\n')
    session.capture(label)
    return {'turn': turns, 'character': fields, 'grid': grid, 'map_sha256': sha(map_path)}


def save(session, game_state):
    session.send('S', 'native save-and-exit prompt')
    session.expect(r'Save\s+game\s+and\s+exit\s*\?', 'save-confirmation')
    session.capture('save-confirmation')
    session.send('S', 'confirm native S save')
    session.wait(lambda: session.process.poll() is not None, 'normal native save exit')
    require(session.process.returncode == 0, 'native save exit failed')
    saves = list(game_state.rglob('*.cs'))
    require(len(saves) == 1 and saves[0].stat().st_size > 0, 'native save file missing/ambiguous')
    return saves[0]


def play(profile, output, evidence, mode, display_env):
    root = evidence / (mode + '-state-root')
    root.mkdir(mode=0o700)
    environment = {'PATH': str(profile / 'bin'), 'TERM': 'xterm-256color', 'LC_ALL': 'C', **display_env}
    for variable, directory in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                ('TMPDIR', 'tmp')]:
        path = root / directory
        path.mkdir(mode=0o700)
        environment[variable] = str(path)
    (root / 'work').mkdir()
    require(not any((root / 'data').iterdir()) and not any((root / 'home').iterdir()),
            'first run not empty')
    game_state = root / 'data/gnollcrawl'
    report = {'fresh_home_xdg': True, 'seeded_state_or_rc': False, 'turns': []}
    session = Session(profile, output, environment, root, evidence, mode, 'new-game', display_env)
    try:
        # Public CLI selects name/Human/Fighter; actual weapon selection is UI.
        session.expect(r'choice\s+of\s+weapons', 'weapon-menu')
        session.capture('character-creation')
        session.send('+', 'choose native recommended fighter weapon')
        session.dungeon()
        report['process'] = session.proof()
        first = dump(session, game_state, 0, 'initial')
        report['turns'].append(first['turn'])
        session.send('.', 'wait one native turn')
        waited = dump(session, game_state, 1, 'waited')
        require(first['character']['inventory'] == waited['character']['inventory'], 'wait altered inventory')
        require(first['grid'] == waited['grid'], 'wait unexpectedly changed player/map')
        report['turns'].append(waited['turn'])
        x, y = actor(waited['grid'])
        choices = [('h', -1, 0), ('l', 1, 0), ('k', 0, -1), ('j', 0, 1),
                   ('y', -1, -1), ('u', 1, -1), ('b', -1, 1), ('n', 1, 1)]
        chosen = next(((key, dx, dy) for key, dx, dy in choices
                       if 0 <= y + dy < len(waited['grid']) and
                       0 <= x + dx < len(waited['grid'][y + dy]) and
                       waited['grid'][y + dy][x + dx] == '.'), None)
        require(chosen is not None, 'no observed adjacent native floor to move onto')
        key, dx, dy = chosen
        session.send(key, 'move onto floor observed in native # known-map dump')
        before = dump(session, game_state, 2, 'moved')
        observed = movement_delta(waited['grid'], before['grid'])
        require(observed == [dx, dy], 'native map does not prove requested spatial move: ' + repr(observed))
        report['movement'] = {'key': key, 'selected_visible_delta': [dx, dy], 'observed_map_delta': observed}
        report['turns'].append(before['turn'])
        savefile = save(session, game_state)
        saved_hash = sha(savefile)
    finally:
        session.close()
    session = Session(profile, output, environment, root, evidence, mode, 'reload', display_env)
    try:
        session.dungeon(restored=True)
        report['restored_process'] = session.proof()
        restored = dump(session, game_state, 2, 'restored')
        require(before['character'] == restored['character'], 'character/inventory not restored')
        require(before['grid'] == restored['grid'], 'native dungeon/player position not restored')
        report['turns'].append(restored['turn'])
        session.send('.', 'next ordinary turn after native restore')
        final = dump(session, game_state, 3, 'next-turn')
        require(final['grid'] == restored['grid'], 'restored wait changed map/player position')
        report['turns'].append(final['turn'])
        require(final['character']['inventory'] == restored['character']['inventory'], 'restored wait altered inventory')
        save(session, game_state)
        final_hash = sha(savefile)
        require(final_hash != saved_hash, 'resave after next turn did not change native save')
    finally:
        session.close()
    require(not any((root / 'work').iterdir()), 'game wrote to arbitrary launch CWD')
    for directory in ('home', 'config', 'cache', 'state', 'runtime', 'tmp'):
        require(not list((root / directory).rglob('*.cs')), 'save escaped XDG game root: ' + directory)
        require(not list((root / directory).rglob('GnollProof.*')), 'character dump escaped XDG game root')
    require(all(path == game_state for path in (root / 'data').iterdir()), 'unexpected data outside game root')
    inventory = {}
    for path in root.rglob('*'):
        info = path.lstat()
        require(info.st_uid == int(os.environ['HOST_UID']), 'foreign-owned consumer state')
        if path.is_file():
            inventory[str(path.relative_to(root))] = {'bytes': info.st_size, 'sha256': sha(path)}
    record(evidence / (mode + '-state-inventory.json'), inventory)
    report.update(native_character_inventory_restored=True, native_player_position_restored=True,
                  restored_character=restored['character'], save=str(savefile.relative_to(evidence)),
                  first_save_sha256=saved_hash, resave_sha256=final_hash,
                  input_and_raw_captures_retained=True)
    return report


def start_display(profile, evidence):
    env = {'PATH': str(profile / 'bin'), 'LC_ALL': 'C', 'HOME': '/tmp', 'XDG_RUNTIME_DIR': '/tmp'}
    read_fd, write_fd = os.pipe()
    try:
        with (evidence / 'xvfb.log').open('wb') as log:
            server = subprocess.Popen([str(profile / 'bin/Xvfb'), '-displayfd', str(write_fd),
                                       '-screen', '0', '1280x960x24', '-nolisten', 'tcp', '-ac', '-r'],
                                      env=env, stdout=log, stderr=log, pass_fds=(write_fd,),
                                      preexec_fn=drop_capabilities)
        os.close(write_fd)
        write_fd = None
        require(select.select([read_fd], [], [], 20)[0], 'private Xvfb allocation timeout')
        display = os.read(read_fd, 128).decode().strip()
        require(display.isdecimal(), 'Xvfb failed to allocate actual native display')
    finally:
        os.close(read_fd)
        if write_fd is not None:
            os.close(write_fd)
    pulse_root = Path('/tmp/gnollcrawl-audio')
    pulse_root.mkdir(mode=0o700)
    (pulse_root / 'home').mkdir(mode=0o700)
    pulse_env = {**env, 'HOME': str(pulse_root / 'home'), 'XDG_RUNTIME_DIR': str(pulse_root)}
    socket = pulse_root / 'native'
    with (evidence / 'pulseaudio.log').open('wb') as log:
        pulse = subprocess.Popen([str(profile / 'bin/pulseaudio'), '--daemonize=no', '--exit-idle-time=-1',
                                  '--use-pid-file=no', '--disallow-exit', '-n',
                                  '--load=module-native-protocol-unix socket=' + str(socket) + ' auth-anonymous=1',
                                  '--load=module-null-sink sink_name=gnollcrawl_native'],
                                 env=pulse_env, stdout=log, stderr=log, preexec_fn=drop_capabilities)
    deadline = time.monotonic() + 20
    while not socket.exists():
        require(pulse.poll() is None and time.monotonic() < deadline, 'private real audio server failed')
        time.sleep(0.1)
    return server, pulse, {'DISPLAY': ':' + display, 'SDL_VIDEODRIVER': 'x11',
                           'SDL_AUDIODRIVER': 'pulseaudio', 'PULSE_SERVER': 'unix:' + str(socket)}


def main():
    profile, output, evidence = map(Path, sys.argv[1:])
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    retained = Path('/proc/self/fd/' + str(evidence_fd))
    report = {'success': False, 'output': str(output), 'source_commit': 'a8ffd03080715e6321eadab873c62b14f58ff646'}
    server = pulse = None
    try:
        retained, report['isolation'] = isolate(retained)
        os.chdir('/tmp')
        report['terminal'] = play(profile, output, retained, 'terminal', {})
        server, pulse, display = start_display(profile, retained)
        report['tiles'] = play(profile, output, retained, 'tiles', display)
        require(server.poll() is None and pulse.poll() is None, 'native display/audio server exited')
        for mode in ('terminal', 'tiles'):
            for phase in ('new-game', 'reload'):
                raw = retained / (mode + '-' + phase + '.raw')
                require(raw.is_file() and (mode == 'tiles' or raw.stat().st_size > 0),
                        'missing actual process PTY raw capture')
        for phase in ('new-game', 'reload'):
            require(any(retained.glob('tiles-' + phase + '-*.png')), 'missing actual SDL window captures')
        report['success'] = True
    except BaseException as error:
        report['error'] = repr(error)
        (retained / 'failure.txt').write_text(traceback.format_exc())
        raise
    finally:
        for process in (pulse, server):
            if process is not None and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        record(retained / 'report.json', report)
        os.close(evidence_fd)
    print('GNOLLCRAWL_NATIVE_OK: both frontends turns 0 -> wait 1 -> move 2 -> restored 2 -> next 3', flush=True)


if __name__ == '__main__':
    main()
