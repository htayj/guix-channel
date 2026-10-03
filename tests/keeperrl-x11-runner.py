#!/usr/bin/env python3
"""Observe KeeperRL through its native X window, menus and upstream CLI.

No game code, settings or save state is written by this consumer. OCR is an
external observer; original window captures and native save bytes are retained.
"""
import csv
import ctypes
import gzip
import hashlib
import io
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
import time
import traceback


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


def isolate(root, evidence):
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int

    def mount(source, target, filesystem=None, flags=0):
        if libc.mount(os.fsencode(source), os.fsencode(target),
                      None if filesystem is None else os.fsencode(filesystem), flags, None):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), str(target))

    try:
        mount('/', '/', flags=4096 | 16384)
        attrs = (ctypes.c_uint64 * 4)(1, 0, 0, 0)
        if libc.syscall(ctypes.c_long(442), ctypes.c_int(-100), ctypes.c_char_p(b'/'),
                        ctypes.c_uint(0x8000), ctypes.byref(attrs), ctypes.sizeof(attrs)):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), 'recursive read-only root')
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, evidence = Path('/tmp/keeperrl-root'), Path('/tmp/keeperrl-evidence')
        root.mkdir()
        evidence.mkdir()
        for fd, target in ((root_fd, root), (evidence_fd, evidence)):
            mount('/proc/self/fd/' + str(fd), target, flags=4096)
            mount(str(target), target, flags=4096 | 32 | 2 | 4)
        mount('proc', '/proc', 'proc', 1 | 2 | 4 | 8)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
    finally:
        os.close(root_fd)
        os.close(evidence_fd)
    return root, evidence


def fresh_environment(root, name):
    base = root / name
    base.mkdir()
    env = dict(os.environ)
    for variable, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                ('TMPDIR', 'tmp')):
        path = base / directory
        path.mkdir(mode=0o700)
        env[variable] = str(path)
    (base / 'work').mkdir()
    env.update(LIBGL_ALWAYS_SOFTWARE='1', MESA_SHADER_CACHE_DISABLE='true',
               SDL_AUDIODRIVER='dummy',
               DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/no-session-bus',
               DBUS_SYSTEM_BUS_ADDRESS='unix:path=/tmp/no-system-bus')
    return base, env


class Session:
    def __init__(self, name, executable, evidence, base, env, tools, record):
        self.name, self.env, self.tools = name, env, tools
        self.directory = evidence / name
        self.directory.mkdir()
        self.log_path = self.directory / 'keeper.log'
        self.log = self.log_path.open('wb', buffering=0)
        self.events, self.images = [], []
        self.window = None
        self.record = {'name': name, 'command': [str(executable), '--stderr'],
                       'events': self.events, 'screenshots': self.images}
        record['sessions'].append(self.record)
        self.process = subprocess.Popen([str(executable), '--stderr'], env=env,
                                        cwd=base / 'work', stdout=self.log, stderr=self.log,
                                        start_new_session=True)
        try:
            self.wait(self.find_window, 'visible native KeeperRL X11 window', 60)
            self.record['native_command'] = (Path('/proc') / str(self.process.pid) / 'cmdline').read_bytes().decode().split('\0')[:-1]
            time.sleep(2)
            self.wait(lambda: re.search(r'without\s+graphical\s+tiles',
                                        '\n'.join(line['text'] for line in self.observe()), re.I),
                      'native free ASCII startup notice')
            self.image('native-free-version-notice')
            self.key('Return', 'Dismiss upstream native free ASCII notice')
            self.wait(lambda: any(re.fullmatch(r'Play', line['text'], re.I)
                                  for line in self.observe()), 'native main menu after free notice')
        except Exception:
            self.close()
            raise

    def tool(self, *args, check=True):
        return subprocess.run(args, env=self.env, check=check, timeout=20,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def find_window(self):
        result = self.tool(self.tools['xdotool'], 'search', '--onlyvisible',
                           '--pid', str(self.process.pid), check=False)
        if result.returncode == 0 and result.stdout.split():
            self.window = result.stdout.split()[-1].decode()
            return True
        return False

    def wait(self, predicate, label, timeout=45):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'native game exited awaiting ' + label)
            value = predicate()
            if value:
                return value
            time.sleep(0.25)
        if self.window:
            self.image('failure')
        raise RuntimeError('timed out awaiting ' + label + '; see ' + self.name + '/keeper.log')

    def focus(self):
        self.tool(self.tools['xdotool'], 'windowfocus', '--sync', self.window)

    def key(self, key, label):
        self.focus()
        self.tool(self.tools['xdotool'], 'key', '--clearmodifiers', key)
        self.events.append({'key': key, 'label': label, 'time_ns': time.monotonic_ns()})
        time.sleep(0.4)

    def click(self, x, y, label, departing=False):
        self.focus()
        self.tool(self.tools['xdotool'], 'mousemove', '--window', self.window, str(x), str(y))
        self.tool(self.tools['xdotool'], 'click', '1')
        self.events.append({'click': [x, y], 'label': label, 'time_ns': time.monotonic_ns()})
        if not departing:
            self.tool(self.tools['xdotool'], 'mousemove', '--window', self.window, '10', '10')
        time.sleep(0.4)

    def capture(self, path):
        self.tool(self.tools['import'], '-window', self.window, str(path))
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'native X capture is not PNG')
        return data

    def observe(self, path=None, words=False):
        if path is None:
            path = self.directory / 'observation.png'
            self.capture(path)
        result = self.tool(self.tools['tesseract'], str(path), 'stdout', '--psm', '11', 'tsv')
        rows = csv.DictReader(io.StringIO(result.stdout.decode(errors='replace')), delimiter='\t')
        lines = {}
        for row in rows:
            text = row.get('text', '').strip()
            if not text:
                continue
            key = tuple(row[field] for field in ('page_num', 'block_num', 'par_num', 'line_num'))
            if words:
                key += (row['word_num'],)
            item = lines.setdefault(key, {'words': [], 'left': 99999, 'top': 99999, 'right': 0, 'bottom': 0})
            x, y, w, h = (int(row[field]) for field in ('left', 'top', 'width', 'height'))
            item['words'].append(text)
            item.update(left=min(item['left'], x), top=min(item['top'], y),
                        right=max(item['right'], x + w), bottom=max(item['bottom'], y + h))
        return [{'text': ' '.join(item.pop('words')), **item} for item in lines.values()]

    def image(self, name):
        path = self.directory / ('%02d-' % len(self.images) + name + '.png')
        data = self.capture(path)
        width, height = struct.unpack('>II', data[16:24])
        text = '\n'.join(line['text'] for line in self.observe(path))
        path.with_suffix('.txt').write_text(text + '\n')
        self.images.append({'path': self.name + '/' + path.name,
                            'sha256': digest(data), 'width': width, 'height': height,
                            'ocr': text})
        return text

    def menu(self, pattern, label, timeout=45, words=False, departing=False):
        def find():
            matches = [line for line in self.observe(words=words)
                       if re.search(pattern, line['text'], re.I)]
            require(len(matches) <= 1, 'ambiguous native OCR menu target: ' + label)
            return matches[0] if matches else None
        item = self.wait(find, label, timeout)
        self.events.append({'observed_menu': item, 'pattern': pattern, 'label': label})
        self.click((item['left'] + item['right']) // 2,
                   (item['top'] + item['bottom']) // 2, label, departing=departing)

    def hud(self):
        lines = self.observe()
        text = '\n'.join(line['text'] for line in lines)
        turns = re.findall(r'\bT\s*:\s*(\d+)\b', text)
        if re.search(r'Exit control mode', text, re.I):
            # Actual 1200x720 direct-control HUD: clock starts at x648,y697.
            # Isolate native pixels instead of accepting misread `Tr` aliases.
            clock_image = self.directory / 'native-clock.png'
            convert = str(Path(self.tools['import']).with_name('convert'))
            self.tool(convert, str(self.directory / 'observation.png'),
                      '-crop', '135x28+644+692', '+repage', '-resize', '400%',
                      '-colorspace', 'Gray', '-negate', '-threshold', '50%',
                      str(clock_image))
            clock = self.tool(self.tools['tesseract'], str(clock_image), 'stdout',
                              '--psm', '7', '-c',
                              'tessedit_char_whitelist=T:0123456789').stdout.decode(errors='replace')
            turns = re.findall(r'\bT\s*:\s*(\d+)\b', clock)
            self.record.setdefault('native_clock_reads', []).append(
                {'session': self.name, 'ocr': clock.strip(),
                 'image': self.name + '/native-clock.png'})
        if len(turns) != 1:
            return None
        return {'turn': int(turns[0]), 'paused': bool(re.search(r'\bpaused\b', text, re.I)),
                'ocr': text}

    def paused_state(self, label):
        state = self.wait(self.hud, 'native HUD clock ' + label, 120)
        if not state['paused']:
            self.key('space', 'Pause native simulation before state observation')
        def paused():
            current = self.hud()
            return current if current and current['paused'] else None
        state = self.wait(paused, 'paused native HUD ' + label)
        self.image(label)
        require((self.hud() or {}).get('turn') == state['turn'], 'paused native game clock is unstable')
        return state

    def campaign_confirm(self):
        self.wait(lambda: re.search(r'World name:',
                                   '\n'.join(line['text'] for line in self.observe()))
                  and re.search(r'World map style:',
                                '\n'.join(line['text'] for line in self.observe())),
                  'native campaign picker with world name and world map style')
        self.image('native-confirm-button')
        self.click(480, 667, 'Click visually verified native Confirm button (1200x720)')
        deadline = time.monotonic() + 180
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'game exited during native campaign generation')
            lines = self.observe()
            text = '\n'.join(line['text'] for line in lines)
            if re.search(r'imps.*sad|retired dungeons.*Continue', text, re.I):
                self.image('native-campaign-confirmation')
                self.menu(r'^[‘\x27]?Confirm$', 'Confirm campaign without retired dungeons',
                          words=True)
                return
            if re.search(r'Welcome to KeeperRL|start with the tutorial|\bSpeed\b', text, re.I):
                return
            time.sleep(0.5)
        raise RuntimeError('native campaign generation did not reach gameplay or intro')

    def dismiss_intros(self):
        # Native present_text blocks input and binds Enter to dismissal. Only
        # dismiss while the normal keeper speed HUD is absent.
        deadline = time.monotonic() + 120
        count = 0
        while time.monotonic() < deadline:
            text = '\n'.join(line['text'] for line in self.observe())
            if re.search(r'Welcome to KeeperRL|start with the tutorial', text, re.I):
                self.image('campaign-intro-' + str(count))
                self.key('Return', 'Dismiss upstream native campaign intro')
                count += 1
            elif (state := self.hud()) and re.search(r'\bSpeed\b', state['ocr'], re.I):
                return
            else:
                time.sleep(0.5)
        raise RuntimeError('native campaign did not reach normal gameplay HUD')

    def control_state(self, label):
        def controlled():
            current = self.hud()
            return current if current and re.search(r'Exit control mode', current['ocr'], re.I) else None
        state = self.wait(controlled, 'native direct-control HUD ' + label, 120)
        self.image(label)
        require((self.hud() or {}).get('turn') == state['turn'], 'direct-control turn advanced without human input')
        return state

    def enter_control(self):
        self.paused_state('keeper-management-before-control')
        # Source layout: window_view sidebar width330/margins20; four 50px
        # icons centered in gui_builder drawRightBandInfo. Second icon = MINION.
        self.click(140, 50, 'Native minion sidebar tab (source-derived icon geometry)')
        self.image('native-minion-list')
        # avatar_info.cpp renames Classic wizard's bare/stack name to Keeper.
        self.menu(r'\bkeeper\b', 'Select default Classic Keeper native minion group')
        self.image('native-minion-page')
        self.menu(r'^Control$', 'Native minion Control enters turn-based gameplay')
        return self.control_state('gameplay-before-action')

    def advance(self, before, label):
        self.key('space', 'Native SKIP_TURN: controlled creature waits one turn')
        self.wait(lambda: (self.hud() or {}).get('turn', -1) > before['turn'],
                  'controlled creature native wait advances GlobalTime')
        after = self.control_state(label)
        require(after['turn'] > before['turn'], 'human wait did not advance native turn')
        return after

    def save_exit(self, save_dir):
        self.key('Escape', 'Open native gameplay exit menu')
        self.image('exit-menu')
        self.wait(lambda: re.search(r'\bSave and\b',
                                   '\n'.join(line['text'] for line in self.observe()))
                  and re.search(r'\bAbandon\b',
                                '\n'.join(line['text'] for line in self.observe())),
                  'native four-button exit menu')
        self.click(360, 331, 'Click visually verified native Save and exit button (1200x720)')
        self.menu(r'^Confirm$', 'Confirm native save and exit')
        self.wait(lambda: list(save_dir.glob('*.kep')), 'native .kep save creation', 120)
        self.wait(lambda: any(re.fullmatch(r'Play', line['text'], re.I)
                              for line in self.observe()), 'return to native main menu', 120)
        self.image('saved-main-menu')

    def quit_menu(self):
        self.menu(r'^Quit$', 'Quit native application', departing=True)
        code = self.process.wait(timeout=20)
        self.close()
        require(code == 0, 'native Quit did not exit cleanly')

    def close(self):
        stop(self.process)
        self.log.close()
        self.record['exit_status'] = self.process.returncode


def run_native(executable, arguments, base, env, evidence, name, timeout, record):
    command = [str(executable), *arguments]
    item = {'command': command, 'log': name + '.log'}
    record['upstream_runs'].append(item)
    process = None
    with (evidence / item['log']).open('wb') as log:
        try:
            process = subprocess.Popen(command, cwd=base / 'work', env=env,
                                       stdout=log, stderr=log, start_new_session=True)
            time.sleep(0.1)
            cmdline = Path('/proc') / str(process.pid) / 'cmdline'
            if cmdline.exists():
                item['native_command'] = cmdline.read_bytes().decode().split('\0')[:-1]
            item['exit_status'] = process.wait(timeout=timeout)
            require(item['exit_status'] == 0, name + ' failed; see ' + item['log'])
        finally:
            stop(process)


def start_xvfb(xvfb, env, log):
    read_fd, write_fd = os.pipe()
    server = None
    try:
        server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                   '1280x900x24', '-nolisten', 'tcp', '-ac'],
                                  pass_fds=(write_fd,), stdout=log, stderr=log,
                                  env=env, start_new_session=True)
        os.close(write_fd)
        write_fd = None
        require(select.select([read_fd], [], [], 15)[0], 'Xvfb allocation timed out')
        display = os.read(read_fd, 128).decode().strip()
        require(display.isdecimal(), 'Xvfb failed to allocate display')
        env['DISPLAY'] = ':' + display
        return server
    except Exception:
        stop(server)
        raise
    finally:
        os.close(read_fd)
        if write_fd is not None:
            os.close(write_fd)


def save_snapshot(save_dir, evidence, name):
    paths = list(save_dir.glob('*.kep'))
    require(len(paths) == 1, 'expected exactly one native Keeper save')
    path = paths[0]
    packed = path.read_bytes()
    # main_loop.cpp:135-142: gzip/cereal binary archive begins int saveVersion,
    # uint64 string length, displayName bytes. Do not deserialize/write Game.
    raw = gzip.decompress(packed)
    require(len(raw) >= 12, 'truncated native gzip save header')
    version, length = struct.unpack_from('<iQ', raw)
    require(0 < length < 4096 and 12 + length < len(raw), 'invalid native save display name')
    display_name = raw[12:12 + length].decode('utf-8')
    target = evidence / (name + '.kep')
    target.write_bytes(packed)
    return {'filename': path.name, 'path': target.name, 'save_version': version,
            'display_name': display_name, 'gzip_bytes': len(packed),
            'sha256': digest(packed), 'decompressed_sha256': digest(raw)}


def main():
    output, scratch, xvfb, xdotool, image_import, tesseract, artifacts, nar = sys.argv[1:]
    output, root, evidence = map(Path, (output, scratch, artifacts))
    record = {'status': 'running', 'consumer': 'unmodified native graphical ASCII UI and upstream CLI',
              'upstream_commit': '95d2be4e97db2243210a71918e36a533ad94dcd1',
              'output': str(output), 'output_nar_before': nar,
              'sessions': [], 'assertions': [], 'upstream_runs': [], 'saves': {}, 'states': {}}
    session = server = None
    server_log = None

    def report():
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')

    report()
    try:
        root, evidence = isolate(root, evidence)
        mounts = Path('/proc/self/mountinfo').read_text()
        mount_rows = [line.split() for line in mounts.splitlines()]
        store_mounts = [row for row in mount_rows if row[4] == '/gnu/store']
        require(store_mounts and 'ro' in store_mounts[-1][5].split(','),
                'inherited Guix store mount is not read-only')
        interfaces = socket.if_nameindex()
        require(interfaces == [(1, 'lo')], 'offline namespace exposes non-loopback interfaces')
        uid_map = Path('/proc/self/uid_map').read_text()
        mapped_uid = uid_map.split()
        require(len(mapped_uid) == 3 and int(mapped_uid[0]) == os.getuid()
                and int(mapped_uid[1]) == os.getuid() and int(mapped_uid[2]) == 1,
                'namespace did not map the current user without root identity')
        record['isolation_observed'] = {'uid': os.getuid(), 'uid_map': uid_map,
                                        'interfaces': interfaces, 'store_read_only': True,
                                        'namespaces': {name: os.readlink('/proc/self/ns/' + name)
                                                       for name in ('user', 'mnt', 'net', 'pid')}}
        (evidence / 'mountinfo.txt').write_text(mounts)
        (evidence / 'net-dev.txt').write_text(Path('/proc/net/dev').read_text())
        record['isolation'] = ('offline current-user/mount/network/PID namespaces; recursively '
                               'read-only inherited roots; private writable tmp/scratch/evidence; '
                               'fresh HOME/XDG, independent second profile')
        executable = output / 'bin/keeper'
        data = output / 'share/keeperrl'
        forbidden = [str(path.relative_to(data)) for path in data.rglob('*')
                     if path.is_file() and path.suffix.lower() in
                     ('.ogg', '.ogv', '.mp3', '.wav', '.mp4')]
        require(not forbidden and not (data / 'data_contrib').exists(),
                'free native package includes forbidden commercial media/data_contrib')
        native_binary = (output / 'libexec/keeperrl/keeper').read_bytes()
        font_paths = set(re.findall(rb'/gnu/store/[^\x00\s"]+/share/fonts/truetype/DejaVuSans(?:-Bold)?\.ttf',
                                    native_binary))
        fonts = [Path(path.decode()) for path in sorted(font_paths)]
        require({path.name for path in fonts} == {'DejaVuSans.ttf', 'DejaVuSans-Bold.ttf'}
                and all(path.is_file() for path in fonts),
                'native binary does not reference both real packaged DejaVu fonts')
        record['package_data'] = {'commercial_media': forbidden, 'data_contrib_present': False,
                                  'native_font_references': [{'path': str(path),
                                                              'sha256': digest(path.read_bytes())}
                                                             for path in fonts]}
        base, env = fresh_environment(root, 'primary')
        require(not list((base / 'data').iterdir()), 'primary XDG data is not fresh')
        save_dir = base / 'data/KeeperRL'
        server_log = (evidence / 'xvfb.log').open('wb')
        server = start_xvfb(xvfb, env, server_log)
        tools = {'xdotool': xdotool, 'import': image_import, 'tesseract': tesseract}
        # These unconditional upstream switches do not enter custom smoke code.
        # The wrapper uses read-only packaged data CWD for --run_tests' native
        # relative config read; worldgen and normal gameplay use writable user CWD.
        run_native(executable, ['--run_tests'], base, env, evidence, 'run-tests', 180, record)
        test_text = (evidence / 'run-tests.log').read_text(errors='replace')
        require('-----===== OK =====-----' in test_text,
                'upstream testAll completion marker missing (release no-op is not proof)')
        record['upstream_runs'][-1]['completion_marker'] = '-----===== OK =====-----'
        run_native(executable, ['--stderr', '--worldgen_test', '20', '--worldgen_maps', 'campaign_base'],
                   base, env, evidence, 'worldgen', 600, record)
        worldgen = save_dir / 'worldgen_out.txt'
        require(worldgen.is_file(), 'upstream worldgen did not write native result file')
        worldgen_text = worldgen.read_text(errors='replace')
        generated = re.findall(r'^Testing (campaign_base [^\n]+)\n(.*?)(?=^Testing |\Z)',
                               worldgen_text, re.MULTILINE | re.DOTALL)
        require(generated, 'native campaign base worldgen produced no cases')
        counts = []
        for name, result in generated:
            match = re.search(r'^(\d+) / (\d+)\. MinT:', result, re.MULTILINE)
            require(match and int(match[2]) == 20 and 0 <= int(match[1]) <= 20,
                    'invalid native campaign generation diagnostic: ' + name)
            counts.append({'case': name, 'successful_proposals': int(match[1]),
                           'attempts': int(match[2])})
        record['upstream_runs'][-1]['generated_cases'] = counts
        shutil.copy2(worldgen, evidence / 'worldgen_out.txt')
        record['assertions'].append('upstream --run_tests completes; native campaign generation probability diagnostic records every alignment/biome case without treating rejected proposals as game failures')
        require(not list(save_dir.glob('*.kep')) and not list(save_dir.glob('*.aut')),
                'upstream test commands unexpectedly left gameplay saves')
        session = Session('new-game', executable, evidence, base, env, tools, record)
        session.image('initial-main-menu')
        session.menu(r'^Play$', 'Play through native main menu')
        session.image('fresh-tutorial-prompt')
        session.menu(r'^No$', 'Decline unavailable tutorial and create a real campaign')
        session.image('native-avatar-menu')
        session.menu(r'^Start new game$', 'Start native default Classic keeper campaign')
        session.wait(lambda: re.search(r'Please enable online features',
                                      '\n'.join(line['text'] for line in session.observe()), re.I),
                     'native offline retired-dungeon information')
        session.image('native-offline-information')
        session.key('Return', 'Acknowledge native offline information without enabling online features')
        session.wait(lambda: re.search(r'Welcome to the campaign mode',
                                      '\n'.join(line['text'] for line in session.observe()), re.I),
                     'native campaign introduction')
        session.image('native-campaign-introduction')
        session.menu(r'^Welcome to the campaign mode',
                     'Click observed campaign help overlay to dismiss it')
        session.image('native-campaign-menu')
        # Empty offline profiles have no retired games, so the upstream optional
        # no-retired-dungeons confirmation is normally bypassed.
        session.campaign_confirm()
        session.dismiss_intros()
        initial = session.enter_control()
        record['states']['initial'] = initial
        first = session.advance(initial, 'gameplay-after-action')
        record['states']['first_action'] = first
        session.save_exit(save_dir)
        saved = save_snapshot(save_dir, evidence, 'first-save')
        record['saves']['first'] = saved
        session.quit_menu()
        session = None
        session = Session('reloaded-game', executable, evidence, base, env, tools, record)
        session.image('restart-main-menu')
        session.menu(r'^Play$', 'Play opens native saved-game selector')
        selector = session.image('native-save-selector')
        require('Load' in selector, 'native save selector has no Load control')
        session.menu(r'^Load game$', 'Load native persisted .kep game')
        restored = session.control_state('reloaded-gameplay')
        record['states']['restored'] = restored
        load_log = session.log_path.read_text(errors='replace')
        require('Loading from ' in load_log and saved['filename'] in load_log,
                'native restore log does not identify the persisted primary save')
        session.record['native_load_filename'] = saved['filename']
        require(restored['turn'] == first['turn'],
                'native reload did not restore controlled creature saved GlobalTime')
        second = session.advance(restored, 'continued-gameplay-after-action')
        record['states']['second_action'] = second
        session.save_exit(save_dir)
        continued = save_snapshot(save_dir, evidence, 'continued-save')
        record['saves']['continued'] = continued
        require(continued['filename'] == saved['filename']
                and continued['display_name'] == saved['display_name']
                and continued['save_version'] == saved['save_version'],
                'native restart/action/resave changed persistent game identity')
        require(continued['decompressed_sha256'] != saved['decompressed_sha256'],
                'continued native simulation did not change decompressed game save')
        session.quit_menu()
        session = None
        record['assertions'].extend([
            'native Control enters creature turn-based mode and human wait advances GlobalTime',
            'native Load restores serialized controlled creature and exact saved GlobalTime',
            'continued human wait advances GlobalTime and resaves the same native game identity'])
        other_base, other_env = fresh_environment(root, 'independent')
        other_env['DISPLAY'] = env['DISPLAY']
        session = Session('independent-profile', executable, evidence, other_base, other_env, tools, record)
        session.image('fresh-independent-main-menu')
        session.menu(r'^Play$', 'Independent profile Play cannot find primary save')
        session.wait(lambda: any(re.search(r'tutorial', line['text'], re.I)
                                 for line in session.observe()), 'fresh profile tutorial prompt')
        independent_text = session.image('fresh-independent-no-save')
        require(not re.search(r'\bLoad\b', independent_text), 'primary save leaked into independent native menu')
        require(not list((other_base / 'data/KeeperRL').glob('*.kep'))
                and not list((other_base / 'data/KeeperRL').glob('*.aut')),
                'independent profile contains gameplay saves')
        session.menu(r'^No$', 'Decline independent tutorial without creating gameplay state')
        session.key('Escape', 'Cancel native avatar chooser back to main menu')
        session.quit_menu()
        session = None
        session = Session('continued-save-verification', executable, evidence, base, env, tools, record)
        session.menu(r'^Play$', 'Verify continued save via native selector')
        session.image('continued-save-selector')
        session.menu(r'^Load game$', 'Load continued native save after second process exit')
        final_state = session.control_state('continued-save-restored-gameplay')
        require(final_state['turn'] == second['turn'], 'second save rolled back continued GlobalTime')
        record['states']['continued_save_restored'] = final_state
        session.save_exit(save_dir)
        record['saves']['verified'] = save_snapshot(save_dir, evidence, 'verified-save')
        session.quit_menu()
        session = None
        record['assertions'].append('second process restart restores resaved controlled creature and exact continued GlobalTime')
        record['assertions'].append('second fresh HOME/XDG has no primary save and native Play offers tutorial instead of Load')
        shutil.copytree(save_dir, evidence / 'native-user-state')
        record['native_user_state'] = sorted(str(p.relative_to(evidence))
                                            for p in (evidence / 'native-user-state').rglob('*') if p.is_file())
        record['status'] = 'passed'
        print('KEEPERRL-SMOKE: upstream-tests-worldgen-native-ascii-action-save-reload-ok')
    except Exception as error:
        record.update(status='failed', error=str(error), traceback=traceback.format_exc())
        if session is not None and session.window is not None and session.process.poll() is None:
            try:
                session.image('failure-diagnostic')
            except Exception:
                pass
        try:
            for profile in root.iterdir():
                native_state = profile / 'data/KeeperRL'
                if native_state.is_dir():
                    target = evidence / ('failure-user-state-' + profile.name)
                    shutil.copytree(native_state, target, dirs_exist_ok=True)
        except Exception as diagnostic_error:
            record['diagnostic_copy_error'] = str(diagnostic_error)
        raise
    finally:
        if session is not None:
            session.close()
        stop(server)
        if server_log is not None:
            server_log.close()
        report()


if __name__ == '__main__':
    main()
