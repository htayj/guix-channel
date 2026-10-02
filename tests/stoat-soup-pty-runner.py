#!/usr/bin/env python3
"""Exercise the packaged console game through ordinary player input only.

Invocation: python3 stoat-soup-pty-runner.py LAUNCHER FRESH_SCRATCH.
The caller supplies an offline network namespace. Python needs pyte.
OMP_RUNTIME_RAW_CAPTURE is the contiguous restored PTY prefix, captured before
any further gameplay keys or alternate-screen teardown; TEXT_CAPTURE is its
plain pyte screen. TRANSCRIPT is both complete sessions, in order. Native save
snapshots, read-only --edit-save extraction, and character dumps remain below
SCRATCH/proof. No image is rendered by this driver.
"""
import codecs
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
# The native CLI parses hexadecimal; literal -seed 285 selects numeric 645.
ARGS = ['-name', NAME, '-species', 'Human', '-background', 'Fighter',
        '-seed', SEED]
CAPTURES = {key: os.environ.get(key) for key in
            ('OMP_RUNTIME_RAW_CAPTURE', 'OMP_RUNTIME_TEXT_CAPTURE',
             'OMP_RUNTIME_TRANSCRIPT')}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def capture(key, data):
    if CAPTURES[key]:
        Path(CAPTURES[key]).write_bytes(data)


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
        welcome = False
        more_count = 0
        while True:
            self.read()
            text = self.text()
            welcome |= 'Welcome back' in text and NAME in text
            if '--more--' in text.lower():
                require(more_count < 10, 'too many startup more prompts')
                self.send(b' ')
                more_count += 1
                self.settle()
                continue
            if self.live() is not None:
                result = self.gameplay()
                require(welcome if restored else chosen,
                        'missing native welcome-back' if restored
                        else 'new character skipped ordinary weapon selection')
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
    state = root / 'state' / 'stoat-soup'
    state.mkdir(mode=0o700)
    (state / 'tmp').mkdir(mode=0o700)
    proof = root / 'proof'
    env = {'HOME': str(root / 'home'), 'XDG_CONFIG_HOME': str(root / 'config'),
           'XDG_DATA_HOME': str(root / 'data'), 'XDG_CACHE_HOME': str(root / 'cache'),
           'XDG_RUNTIME_DIR': str(root / 'runtime'),
           'XDG_STATE_HOME': str(root / 'state'), 'TMPDIR': str(state / 'tmp'),
           'TERM': 'vt100', 'LC_ALL': 'C', 'LANG': 'C', 'PATH': '/nonexistent'}
    # Do not inherit host rc files, preload/search paths, Crawl/Lua options,
    # credentials, display sockets, or terminal overrides in child processes.
    os.environ.clear()
    os.environ.update(env)
    first = Session(launcher, env, state, transcript)
    try:
        start = first.enter(False)
        waited = [first.turn() for _ in range(3)]
        saved_live = waited[-1]
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
        # Freeze both representations now: exact output from this independent
        # process, not a reconstructed redraw or a suffix after leaving curses.
        raw, text = bytes(resumed.raw), resumed.text().encode('utf-8')
        (proof / 'restored-prefix.raw').write_bytes(raw)
        (proof / 'restored-screen.txt').write_bytes(text)
        capture('OMP_RUNTIME_RAW_CAPTURE', raw)
        capture('OMP_RUNTIME_TEXT_CAPTURE', text)
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
    audit(root, state, proof)
    (proof / 'observations.json').write_text(
        json.dumps({'seed_argument': SEED, 'numeric_seed': int(SEED, 16),
                    'initial': start, 'waits': waited,
                    'saved': saved_live, 'restored': restored, 'continued': continued,
                    'first_dump': first_dump, 'restored_dump': restored_dump,
                    'continued_dump': continued_dump}, indent=2) + '\n',
        encoding='utf-8')
    print('STOAT-SOUP: OmpProof HuFi -seed 285 (hexadecimal = 645); '
          'three native advancing waits; '
          'independent welcome-back, clock/coordinates/HP/stats/dump restored; '
          'one further native turn and ordinary re-save; native chunks retained')
    print('STOAT-SOUP-SMOKE: native-gameplay-save-restore-continued-save-ok')


def main():
    require(len(sys.argv) == 3, 'usage: stoat-soup-pty-runner.py LAUNCHER SCRATCH')
    require(socket.if_nameindex() == [(1, 'lo')],
            'proof requires an offline network namespace')
    launcher = str(Path(sys.argv[1]).absolute())
    root = Path(sys.argv[2]).resolve()
    root.mkdir(mode=0o700, exist_ok=True)
    transcript = bytearray()
    try:
        exercise(launcher, root, transcript)
    finally:
        (root / 'transcript.raw').write_bytes(transcript)
        capture('OMP_RUNTIME_TRANSCRIPT', bytes(transcript))


if __name__ == '__main__':
    main()
