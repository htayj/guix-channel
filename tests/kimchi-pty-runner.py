#!/usr/bin/env python3
"""Exercise the packaged console game through ordinary player input only.

Invocation: kimchi-pty-runner.py LAUNCHER SCRATCH EVIDENCE NAR TOOL_PATHS...
The supervisor supplies private mount/PID/user/network namespaces. Python needs
pyte. Real xterm/Xvfb pixels and native Korean item descriptions are captured.
EVIDENCE/proof/restored-prefix.raw is the contiguous restored PTY prefix before
further gameplay or teardown; restored-screen.txt is its plain pyte screen.
EVIDENCE/transcript.raw contains all sessions. Native saves, read-only
--edit-save chunks, dumps and real Xvfb screenshots are under EVIDENCE/proof.
"""
import codecs
import ctypes
import tty
from decimal import Decimal
import errno
import fcntl
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

import pyte


ROWS, COLS = 30, 80
NAME, SEED = 'OmpProof', '285'
# The native CLI parses an unsigned decimal seed.
ARGS = ['-name', NAME, '-species', 'Human', '-background', 'Fighter',
        '-seed', SEED, '-extra-opt-last', 'language=ko',
        '-extra-opt-last', 'show_game_time=true',
        '-extra-opt-last', 'restart_after_game=false']


def write_all(fd, data):
    while data:
        count = os.write(fd, data)
        require(count > 0, 'short terminal write')
        data = data[count:]


def require(condition, message):
    if not condition:
        raise RuntimeError(message)




class Session:
    def __init__(self, launcher, env, state, transcript):
        self.raw = bytearray()
        self.transcript = transcript
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.alive = True
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(state)
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(launcher, [launcher] + ARGS, env)
            except BaseException:
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def read(self, timeout=0.1):
        ready = select.select([self.fd, 0], [], [], timeout)[0]
        if 0 in ready:
            reply = os.read(0, 4096)
            if reply:
                write_all(self.fd, reply)
        if self.fd not in ready:
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
        write_all(1, data)
        require(len(self.raw) <= 4000000, 'excessive native terminal output')
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
                raise RuntimeError(description + ': native process exited '
                                   + str(self.status) + '\n' + self.text())
            require(time.monotonic() < deadline,
                    description + ': timed out\n' + self.text())

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(0.25):
            require(time.monotonic() < deadline, 'native output never settled')

    def send(self, data):
        require(not self.exited(), 'cannot send keys to an exited game')
        os.write(self.fd, data)

    def live(self):
        text = self.text()
        title = next(((row, line.index(NAME))
                      for row, line in enumerate(self.screen.display[:3])
                      if NAME in line), None)
        if title is None:
            return None
        hud_x = title[1]
        positions = [(x, y) for y, line in enumerate(self.screen.display[:21])
                     for x, char in enumerate(line[:hud_x]) if char == '@']
        hp = re.search(r'(?:Health|HP):\s*(\d+)\s*/\s*(\d+)', text)
        clock = re.search(r'Time:\s*(\d+(?:\.\d+)?)', text)
        place = re.search(r'Place:\s*(Dungeon:1)\b', text)
        if len(positions) != 1 or not hp or not clock or not place:
            return None
        stats = {}
        for field in ('AC', 'EV', 'SH', 'Str', 'Int', 'Dex', 'XL'):
            match = re.search(r'\b' + field + r':\s*(\d+)', text)
            if not match:
                return None
            stats[field] = int(match[1])
        return {'name': NAME, 'position': positions[0],
                'position_kind': 'zero-based console viewport coordinates',
                'hp': tuple(map(int, hp.groups())), 'stats': stats,
                'place': place[1], 'clock': clock[1]}

    def gameplay(self):
        self.wait(lambda: self.live() is not None, 'missing native gameplay HUD/map')
        self.settle()
        result = self.live()
        require(result is not None, 'gameplay display did not settle')
        require(result['hp'][0] > 0, 'player died')
        require('You die' not in self.text(), 'player died')
        return result

    def enter(self, restored):
        deadline = time.monotonic() + 25
        chosen = False
        more_count = 0
        while True:
            self.read()
            text = self.text()
            if '--more--' in text.lower():
                require(more_count < 10, 'too many startup more prompts')
                self.send(b' ')
                more_count += 1
                self.settle()
                continue
            if self.live() is not None:
                result = self.gameplay()
                require(restored or chosen,
                        'new character skipped ordinary weapon selection')
                return result
            if not restored and not chosen and re.search(r'weapon', text, re.I) \
                    and re.search(r'\ba\s*[-+)]', text):
                self.send(b'a')
                chosen = True
                self.settle()
                continue
            require(not self.exited(), 'game exited before character gameplay\n' + text)
            require(time.monotonic() < deadline, 'startup timed out\n' + text)

    def turn(self):
        before = self.gameplay()
        self.send(b'.')
        self.wait(lambda: self.live() is not None and
                  Decimal(self.live()['clock']) > Decimal(before['clock']),
                  'ordinary wait did not advance native gameplay time')
        after = self.gameplay()
        require(after['position'] == before['position'], 'wait changed player position')
        return after

    def dump(self, state, destination):
        self.send(b'#')
        self.wait(lambda: 'Char dumped' in self.text(), 'native character dump failed')
        self.settle()
        candidates = list(state.rglob(NAME + '.txt'))
        require(len(candidates) == 1, 'missing or ambiguous native character dump')
        source = candidates[0]
        shutil.copy2(source, destination)
        text = source.read_text(encoding='utf-8')
        require(NAME in text and ('Human Fighter' in text or '(HuFi)' in text),
                'native dump has wrong character identity')
        require('(console)' in text, 'native dump is not console gameplay')
        return dump_fields(text)

    def save(self):
        self.send(b'S')
        self.wait(lambda: 'Save game and' in self.text(), 'missing ordinary save prompt')
        self.send(b'y')
        deadline = time.monotonic() + 20
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'native save did not exit')
        self.settle()
        require(self.status == 0, 'native save exited unsuccessfully')

    def picture(self, proof, label):
        self.settle()
        (proof / (label + '.raw')).write_bytes(self.raw)
        (proof / (label + '.txt')).write_text(self.text(), encoding='utf-8')
        path = proof / (label + '.png')
        subprocess.run([os.environ['KIMCHI_IMPORT'], '-display', os.environ['DISPLAY'],
                        '-window', 'root', str(path)],
                       env=dict(os.environ, HOME=os.environ['KIMCHI_X_HOME']),
                       check=True, timeout=20)
        require(path.read_bytes().startswith(b'\x89PNG\r\n\x1a\n'),
                'real xterm screenshot is not PNG')

    def korean(self, proof):
        self.send(b'i')
        self.wait(lambda: 'shield' in self.text().lower() and
                  re.search(r'[a-z]\s*[-+]\s.*shield', self.text(), re.I),
                  'ordinary inventory lacks starting shield')
        self.settle()
        match = re.search(r'([a-z])\s*[-+]\s[^\n]*shield', self.text(), re.I)
        require(match is not None, 'shield inventory letter unavailable')
        self.send(match[1].lower().encode('ascii'))
        self.wait(lambda: re.search('[가-힣]', self.text()),
                  'native language=ko shield inspection lacks Hangul')
        self.picture(proof, 'korean-description')
        self.send(b'\x1b')
        self.settle()
        if self.live() is None:
            self.send(b'\x1b')
        self.gameplay()

    def quit(self):
        self.send(b'\x11')
        self.wait(lambda: 'abandon this character' in self.text(),
                  'missing ordinary native quit confirmation')
        self.send(b'yes\r')
        deadline = time.monotonic() + 20
        while not self.exited():
            self.read()
            if '--more--' in self.text().lower():
                self.send(b' ')
                self.settle()
            elif 'Goodbye, ' + NAME in self.text():
                self.send(b' ')
                self.settle()
            elif re.search(r'[a-z]\s*[-+]\s[^\n]*shield', self.text(), re.I):
                # Native end.cc displays inventory before its goodbye popup.
                self.send(b'\x1b')
                self.settle()
            require(time.monotonic() < deadline, 'confirmed native quit timed out')
        self.settle()
        require(self.status == 0, 'confirmed native quit failed')

    def close(self):
        try:
            if self.alive:
                # forkpty gives the game its own session; close descendants too.
                try:
                    os.killpg(self.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                os.waitpid(self.pid, 0)
                self.alive = False
        finally:
            os.close(self.fd)
            self.transcript.extend(self.raw)


def dump_fields(text):
    fields = {}
    for name, pattern in (
            ('turns', r'\bTurns:\s*(\d+)'),
            ('hp', r'(?:Health|HP):\s*(\d+\s*/\s*\d+)'),
            ('AC', r'\bAC:\s*(\d+)'), ('EV', r'\bEV:\s*(\d+)'),
            ('SH', r'\bSH:\s*(\d+)'), ('Str', r'\bStr:\s*(\d+)'),
            ('Int', r'\bInt:\s*(\d+)'), ('Dex', r'\bDex:\s*(\d+)')):
        match = re.search(pattern, text)
        require(match is not None, 'native character dump missing ' + name)
        fields[name] = re.sub(r'\s+', '', match[1])
    # Dump Time is wall time, unlike the HUD's simulated gameplay Time.
    return fields


def snapshot(launcher, env, state, proof, label, expected_dump):
    saves = list(state.rglob(NAME + '.cs'))
    require(len(saves) == 1, 'missing or ambiguous native OmpProof.cs save')
    destination = proof / label
    destination.mkdir()
    saved = destination / saves[0].name
    shutil.copy2(saves[0], saved)
    dumps = list(state.rglob(NAME + '.txt'))
    require(len(dumps) == 1, 'missing native save-time character dump')
    require(dump_fields(dumps[0].read_text(encoding='utf-8')) == expected_dump,
            'native save-time dump changed played character state')
    shutil.copy2(dumps[0], destination / dumps[0].name)

    def inspect(*args):
        result = subprocess.run([launcher, '--edit-save', str(saved), *args],
                                env=env, cwd=state, stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                timeout=20, check=False)
        require(result.returncode == 0, 'native save inspector failed')
        require(not result.stderr, 'native save inspector error: '
                + result.stderr.decode('utf-8', 'replace'))
        return result.stdout

    listing = inspect('ls')
    (destination / 'chunks.txt').write_bytes(listing)
    # ls/get can return zero on a caught error: require the actual listing
    # and extracted native chunks rather than accepting only the exit status.
    chunk_names = set(listing.decode('ascii').split())
    for chunk in ('chr', 'you', 'D:1'):
        require(chunk in chunk_names, 'native save lacks listed chunk ' + chunk)
        target = destination / (chunk.replace(':', '-') + '.chunk')
        output = inspect('get', chunk, str(target))
        (destination / (target.stem + '-get.txt')).write_bytes(output)
        require(target.is_file() and target.stat().st_size > 0,
                'native inspector did not extract ' + chunk)
    return destination


def audit(root, state, proof):
    for path in root.rglob('*'):
        require(not path.is_symlink(), 'unexpected game-created symlink: ' + str(path))
        if path.is_dir() and not path.is_relative_to(state) \
                and not path.is_relative_to(proof):
            require(path.parent == root,
                    'native game created directories outside XDG state: ' + str(path))
        if path.is_file():
            require(path.is_relative_to(state) or path.is_relative_to(proof),
                    'native game wrote outside XDG state: ' + str(path))


def exercise(launcher, root, transcript):
    require(not any(root.iterdir()), 'scratch must be freshly empty')
    for name in ('home', 'config', 'data', 'cache', 'runtime', 'state', 'proof'):
        (root / name).mkdir(mode=0o700)
    state = root / 'data' / 'kimchi'
    state.mkdir(mode=0o700)
    (state / 'tmp').mkdir(mode=0o700)
    proof = root / 'proof'
    env = {'HOME': str(root / 'home'), 'XDG_CONFIG_HOME': str(root / 'config'),
           'XDG_DATA_HOME': str(root / 'data'), 'XDG_CACHE_HOME': str(root / 'cache'),
           'XDG_RUNTIME_DIR': str(root / 'runtime'),
           'XDG_STATE_HOME': str(root / 'state'), 'TMPDIR': str(state / 'tmp'),
           'TERM': 'xterm-256color', 'LC_ALL': 'C.UTF-8', 'LANG': 'C.UTF-8',
           'PATH': '/nonexistent', 'DISPLAY': os.environ['DISPLAY'],
           'KIMCHI_IMPORT': os.environ['KIMCHI_IMPORT'],
           'FONTCONFIG_FILE': os.environ['FONTCONFIG_FILE'],
           'KIMCHI_X_HOME': os.environ['KIMCHI_X_HOME']}
    # Do not inherit host rc files, preload/search paths, Crawl/Lua options,
    # credentials, display sockets, or terminal overrides in child processes.
    os.environ.clear()
    os.environ.update(env)
    first = Session(launcher, env, state, transcript)
    try:
        start = first.enter(False)
        first.picture(proof, 'initial')
        first.korean(proof)
        require(first.gameplay() == start, 'inventory inspection advanced gameplay')
        waited = [first.turn() for _ in range(3)]
        saved_live = waited[-1]
        first.picture(proof, 'played')
        require(Decimal(saved_live['clock']) - Decimal(start['clock']) >= 3,
                'fewer than three genuine advancing waits')
        (proof / 'first-screen.txt').write_text(first.text(), encoding='utf-8')
        first_dump = first.dump(state, proof / 'first-character.txt')
        require(int(first_dump['turns']) >= 3, 'native dump lacks three played turns')
        first.save()
    finally:
        first.close()
    snapshot(launcher, env, state, proof, 'first', first_dump)
    audit(root, state, proof)

    resumed = Session(launcher, env, state, transcript)
    try:
        restored = resumed.enter(True)
        resumed.picture(proof, 'restored')
        # Freeze both representations now: exact output from this independent
        # process, not a reconstructed redraw or a suffix after leaving curses.
        raw, text = bytes(resumed.raw), resumed.text().encode('utf-8')
        (proof / 'restored-prefix.raw').write_bytes(raw)
        (proof / 'restored-screen.txt').write_bytes(text)
        require(restored == saved_live,
                'independent restore changed clock/name/map coordinates/HP/stats')
        restored_dump = resumed.dump(state, proof / 'restored-character.txt')
        require(restored_dump == first_dump,
                'native restore changed meaningful character dump fields')
        continued = resumed.turn()
        continued_dump = resumed.dump(state, proof / 'continued-character.txt')
        require(int(continued_dump['turns']) == int(first_dump['turns']) + 1,
                'post-restore wait did not increment native turn count once')
        resumed.save()
    finally:
        resumed.close()
    snapshot(launcher, env, state, proof, 'resumed', continued_dump)
    final = Session(launcher, env, state, transcript)
    try:
        require(final.enter(True) == continued, 'final restore lost continued turn')
        final.quit()
    finally:
        final.close()
    require(not list(state.rglob(NAME + '.cs')), 'ordinary abandonment left active save')
    audit(root, state, proof)
    (proof / 'observations.json').write_text(
        json.dumps({'seed_argument': SEED, 'numeric_seed': int(SEED),
                    'initial': start, 'waits': waited,
                    'saved': saved_live, 'restored': restored, 'continued': continued,
                    'first_dump': first_dump, 'restored_dump': restored_dump,
                    'continued_dump': continued_dump}, indent=2) + '\n',
        encoding='utf-8')
    print('KIMCHI: OmpProof HuFi -seed 285 (decimal); '
          'three native advancing waits; '
          'independent clock/coordinates/HP/stats/dump restored; '
          'one further native turn, re-save and ordinary confirmed quit; native chunks retained')
    print('KIMCHI-SMOKE: native-gameplay-save-restore-continued-save-ok')


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
        mount('/gnu/store', '/gnu/store', flags=4096)
        mount('/gnu/store', '/gnu/store', flags=4096 | 32 | 1 | 2 | 4)
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, evidence = Path('/tmp/kimchi-root'), Path('/tmp/kimchi-evidence')
        root.mkdir()
        evidence.mkdir()
        mount('/proc/self/fd/' + str(root_fd), root, flags=4096)
        mount('/proc/self/fd/' + str(evidence_fd), evidence, flags=4096)
        mount('proc', '/proc', 'proc', 2 | 4 | 8)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
    finally:
        os.close(root_fd)
        os.close(evidence_fd)
    return root, evidence


def namespaces():
    return {name: os.readlink('/proc/self/ns/' + name) for name in ('user', 'mnt', 'net', 'pid')}


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


def isolated(arguments):
    launcher, root, evidence, xvfb, xterm, image_import, fonts = arguments
    root, evidence = isolate(Path(root), Path(evidence))
    require(socket.if_nameindex() == [(1, 'lo')], 'offline namespace required')
    mounts = Path('/proc/self/mountinfo').read_text()
    store = [line for line in mounts.splitlines() if line.split()[4] == '/gnu/store']
    require(store and 'ro' in store[-1].split()[5].split(','), 'store must be read-only')
    scope = json.loads((evidence / 'scope.json').read_text())
    scope['isolated_namespaces'] = namespaces()
    require(all(scope['host_namespaces'][key] != scope['isolated_namespaces'][key]
                for key in scope['host_namespaces']), 'namespace identities did not change')
    scope.update(interfaces=socket.if_nameindex(), store_read_only=True, private_tmp=True)
    (evidence / 'scope.json').write_text(json.dumps(scope, indent=2) + '\n')
    (evidence / 'mountinfo.txt').write_text(mounts)
    (evidence / 'net-dev.txt').write_text(Path('/proc/net/dev').read_text())
    # Infrastructure state is distinct from the completely fresh game root.
    infrastructure = Path('/tmp/kimchi-x11')
    infrastructure.mkdir()
    for name in ('home', 'tmp', 'font-cache'):
        (infrastructure / name).mkdir()
    configuration = infrastructure / 'fonts.conf'
    configuration.write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">'
                             '<fontconfig><dir>' + fonts + '</dir><cachedir>'
                             + str(infrastructure / 'font-cache') + '</cachedir></fontconfig>')
    environment = dict(os.environ, HOME=str(infrastructure / 'home'),
                       TMPDIR=str(infrastructure / 'tmp'), FONTCONFIG_FILE=str(configuration),
                       KIMCHI_IMPORT=image_import, KIMCHI_X_HOME=str(infrastructure / 'home'),
                       LC_ALL='C.UTF-8', LANG='C.UTF-8', PYTHONDONTWRITEBYTECODE='1')
    server = terminal = None
    read_fd, write_fd = os.pipe()
    try:
        with (evidence / 'xvfb.log').open('wb') as log:
            server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                       '1600x1100x24', '-nolisten', 'tcp', '-ac'],
                                      pass_fds=(write_fd,), stdout=log, stderr=log,
                                      env=environment, start_new_session=True)
        os.close(write_fd)
        write_fd = None
        require(select.select([read_fd], [], [], 20)[0], 'Xvfb display allocation timed out')
        display = os.read(read_fd, 100).decode().strip()
        require(display.isdecimal(), 'invalid Xvfb display number')
        environment['DISPLAY'] = ':' + display
        with (evidence / 'xterm.log').open('wb') as log:
            terminal = subprocess.Popen([xterm, '-display', ':' + display,
                                         '-geometry', '%dx%d+0+0' % (COLS, ROWS),
                                         '-fa', 'Noto Sans Mono CJK KR', '-fs', '14',
                                         '-xrm', 'XTerm*allowTitleOps: false', '-e',
                                         sys.executable, '-B', str(root / 'runner.py'),
                                         '--terminal', launcher, str(root), str(evidence)],
                                        stdout=log, stderr=log, env=environment,
                                        start_new_session=True)
        require(terminal.wait(timeout=180) == 0 and
                (evidence / 'proof/observations.json').is_file(),
                'native terminal consumer failed; see terminal.log/failure.txt')
    finally:
        os.close(read_fd)
        if write_fd is not None:
            os.close(write_fd)
        stop(terminal)
        stop(server)


def terminal(arguments):
    launcher, root, evidence = arguments
    root, evidence = Path(root) / 'game', Path(evidence)
    root.mkdir(mode=0o700)
    sys.stderr = (evidence / 'terminal.log').open('w', buffering=1)
    original = termios.tcgetattr(0)
    transcript = bytearray()
    tty.setraw(0)
    try:
        exercise(launcher, root, transcript)
    except BaseException as error:
        (evidence / 'failure.txt').write_text(str(error) + '\n')
        raise
    finally:
        termios.tcsetattr(0, termios.TCSANOW, original)
        (evidence / 'transcript.raw').write_bytes(transcript)
        if (root / 'proof').exists():
            shutil.copytree(root / 'proof', evidence / 'proof')


def main():
    if sys.argv[1] == '--terminal':
        terminal(sys.argv[2:])
        return 0
    if sys.argv[1] == '--isolated':
        isolated(sys.argv[2:])
        return 0
    launcher, root, evidence, nar, unshare, timeout, xvfb, xterm, image_import, fonts = sys.argv[1:]
    root, evidence = Path(root).resolve(), Path(evidence).resolve()
    require(not any(evidence.iterdir()), 'KIMCHI_EVIDENCE_DIR must be new or empty')
    record = {'status': 'running', 'consumer': 'ordinary native console in real xterm/Xvfb',
              'source_commit': '8f533dcfe5fe76833cb636531bae56e3bf106556',
              'output': str(Path(launcher).parent.parent), 'output_nar_before': nar,
              'limits': 'Three ordinary waits, same-character restore, one further turn, '
                        're-save and confirmed quit; no exhaustive future RNG-continuation claim.'}
    (evidence / 'scope.json').write_text(json.dumps({'host_namespaces': namespaces()}, indent=2) + '\n')
    runner = root / 'runner.py'
    shutil.copyfile(__file__, runner)
    try:
        with (evidence / 'namespace.log').open('wb') as log:
            result = subprocess.run([timeout, '--kill-after=10', '240', unshare,
                                     '--user', '--map-current-user', '--keep-caps', '--mount',
                                     '--propagation', 'private', '--net', '--pid', '--fork',
                                     '--kill-child', sys.executable, '-B', str(runner),
                                     '--isolated', launcher, str(root), str(evidence),
                                     xvfb, xterm, image_import, fonts],
                                    stdout=log, stderr=subprocess.STDOUT, timeout=260)
        require(result.returncode == 0, 'isolated native consumer failed')
        record.update(status='passed', native_status='passed',
                      gameplay=json.loads((evidence / 'proof/observations.json').read_text()),
                      scope=json.loads((evidence / 'scope.json').read_text()))
        return 0
    except BaseException as error:
        record.update(status='failed', error=str(error))
        return 1
    finally:
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')
        runner.unlink()


if __name__ == '__main__':
    sys.exit(main())
