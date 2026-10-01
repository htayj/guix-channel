#!/usr/bin/env python3
"""Drive NarwhaRL's real curses UI; decode, but never fabricate, its output.

OMP_RUNTIME_RAW_CAPTURE receives the exact restored live session through its map.
OMP_RUNTIME_TEXT_CAPTURE receives that decoded 80 by 54 native screen.
OMP_RUNTIME_TRANSCRIPT receives all complete PTY sessions, concatenated verbatim.
The larger terminal exposes the complete native 50 by 50 map without scrolling.
"""
import errno
import fcntl
import os
from pathlib import Path
import re
import select
import signal
import socket
import struct
import sys
import termios
import time

import pyte


SEED = '424242'
ROWS, COLS = 54, 80
SAVE_FILES = {'map.m', 'creatures.m', 'items.m', 'itemknowledge.txt'}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def capture(variable, data):
    if os.environ.get(variable):
        Path(os.environ[variable]).write_bytes(data)


class Session:
    def __init__(self, executable, env, work, transcript):
        self.raw = bytearray()
        self.transcript = transcript
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            os.chdir(work)
            fcntl.ioctl(0, termios.TIOCSWINSZ,
                        struct.pack('HHHH', ROWS, COLS, 0, 0))
            os.execve(executable, [executable, SEED], env)
        self.alive = True

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
        self.stream.feed(data.decode('ascii'))
        require(len(self.raw) < 4000000, 'excessive native terminal output')
        return True

    def wait(self, predicate, description, timeout=20):
        deadline = time.monotonic() + timeout
        while not predicate():
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.alive = False
                self.settle()
                require(False, description + ': native process exited with '
                        + str(os.waitstatus_to_exitcode(status))
                        + '\nPTY suffix: ' + repr(bytes(self.raw[-1800:])))
            require(time.monotonic() < deadline,
                    description + '\nPTY suffix: ' + repr(bytes(self.raw[-1800:])))
            self.read()

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def marker(self, text):
        self.wait(lambda: text in self.text(), 'missing native prompt ' + text)

    def send(self, data):
        os.write(self.fd, data)

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(0.2):
            require(time.monotonic() < deadline, 'native terminal never settled')

    def positions(self):
        return [(col - 22, row)
                for row, line in enumerate(self.screen.display[:50])
                for col, char in enumerate(line[22:72], 22) if char == '@']

    def gameplay(self):
        self.wait(lambda: len(self.positions()) == 1 and 'HP:' in self.text(),
                  'no native player/map/status display')
        self.settle()
        require(len(self.positions()) == 1, 'ambiguous player position')
        terrain = ''.join(line[22:72] for line in self.screen.display[:50])
        require('#' in terrain and '.' in terrain, 'missing native dungeon terrain')
        return self.positions()[0]

    def character(self):
        # Upstream Player starts at level zero and forces six real skill choices.
        self.marker('Advance skills :')
        for left, key in zip(range(6, 0, -1), (b'a', b'a', b'g', b'g', b'i', b'i')):
            self.marker('Skill points left : ' + str(left))
            self.send(key)
        self.marker('Press any key to continue.')
        self.send(b' ')
        return self.gameplay()

    def inventory(self):
        self.send(b'i')
        self.marker('View Inventory :')
        self.settle()
        screen = self.text()
        self.send(b'\x1b')
        self.gameplay()
        return screen

    def move(self):
        before = self.gameplay()
        x, y = before
        # Choose ordinary visible empty floor, not a wall, door, item or monster.
        # This is a real native turn, not a blind movement/attack key sequence.
        for key, dx, dy in ((b'l', 1, 0), (b'h', -1, 0),
                            (b'j', 0, 1), (b'k', 0, -1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < 50 and 0 <= ny < 50):
                continue
            if self.screen.display[ny][nx + 22] != '.':
                continue
            self.send(key)
            self.settle()
            after = self.gameplay()
            require(after == (nx, ny),
                    'native movement did not reach the chosen adjacent empty floor')
            require('You die' not in self.text(), 'player died during native movement')
            return before, after
        raise RuntimeError('no safe visible cardinal floor adjacent to player')

    def save(self, directory):
        self.send(b'S')
        self.marker("Save and quit? ('Y' or 'N' only)")
        self.send(b'Y')
        deadline = time.monotonic() + 20
        while True:
            self.read()
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.alive = False
                self.settle()
                require(os.waitstatus_to_exitcode(status) == 0, 'native save exit failed')
                break
            require(time.monotonic() < deadline, 'native save did not exit')
        require({p.name for p in directory.iterdir()} == SAVE_FILES,
                'missing or unexpected native save files')
        return read_save(directory)

    def close(self):
        if self.alive:
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)
        self.transcript.extend(self.raw)


def fields(lines):
    result = {}
    for line in lines:
        match = re.fullmatch(r'\[([^]]+)\](?: (.*))?', line)
        require(match is not None, 'malformed native save field: ' + repr(line))
        result.setdefault(match[1], []).append(match[2] or '')
    return result


def ground_items(data):
    # Upstream loadmap adds floor items at each list's head, reversing their
    # serialization order.  Compare complete field records as a multiset.
    records = []
    pending = []
    for line in data.decode('ascii').splitlines():
        if line == '[end]':
            record = fields(pending)
            records.append(tuple(sorted((key, tuple(values))
                                        for key, values in record.items())))
            pending = []
        else:
            pending.append(line)
    require(not pending, 'unterminated native ground item')
    return tuple(sorted(records))


def read_save(directory):
    data = {name: (directory / name).read_bytes() for name in SAVE_FILES}
    # Bitfields are streamed as decimal digits; color is a decimal integer,
    # memory glyph is a literal character, and @ delimits each tile.
    header = data['map.m'].split(b'\n', 5)
    require(len(header) == 6, 'native map header incomplete')
    seed, height, width, depth, maxdepth = map(int, header[:5])
    require(seed == int(SEED) and (height, width) == (50, 50),
            'numeric seed or native map dimensions were not persisted')
    cells = header[5].split(b'@')
    require(cells[-1] == b'' and len(cells) == width * height + 1,
            'native map tile count/delimiters invalid')
    cells.pop()
    require(all(len(cell) >= 10 and all(value in b'01234567'
                                       for value in cell[1:7]) for cell in cells),
            'native map tile flags truncated or malformed')
    # Monsters run before the restored input prompt (saved player time is 4).
    # Door opening/closing is therefore native gameplay, not map regeneration.
    # Compare the full immutable layout, with each native door as one feature.
    terrain = tuple((ord('+') if cell[0] in b'+-' else cell[0], cell[2],
                     None if cell[0] in b'+-' else cell[5], cell[6],
                     int(cell[7:-2]), None if cell[0] in b'+-' else cell[-1])
                    for cell in cells)
    lines = data['creatures.m'].decode('ascii').splitlines()
    creatures = []
    i = 0
    while i < len(lines):
        end = lines.index('[end]', i)
        creature = fields(lines[i:end])
        i = end + 1
        inventory = []
        while i < len(lines) and lines[i] == '[item]':
            end = lines.index('[enditem]', i)
            inventory.append(fields(lines[i + 1:end]))
            i = end + 1
        creatures.append((creature, inventory))
    players = [(actor, inv) for actor, inv in creatures
               if actor.get('isplayer') == ['1']]
    require(len(players) == 1, 'save must contain one native player')
    player, inventory = players[0]
    require(player['symb'] == ['@'] and player['name'] == ['Player'],
            'native persisted player identity invalid')
    position = tuple(map(int, player['x,y'][0].split(',')))
    x, y = position
    require(0 <= x < width and 0 <= y < height and cells[y * width + x][2] == ord('1'),
            'persisted player position is not passable native terrain')
    require(int(player['hp'][0]) > 0, 'persisted player is dead')
    identity = {key: player[key] for key in
                ('name', 'symb', 'isplayer', 'strength', 'dexterity', 'agility',
                 'toughness', 'size', 'level', 'experience', 'maxhp',
                 'maxmp', 'skills')}
    require(player['skills'] == ['2 2 0 2 0 0 0 0 0 0 0 0'],
            'real native initial skill choices were not persisted')
    return {'identity': identity, 'position': position, 'inventory': inventory,
            'terrain': terrain, 'header': (seed, height, width, depth, maxdepth),
            'items': ground_items(data['items.m']), 'knowledge': data['itemknowledge.txt']}


def assert_restore(saved, restored):
    for field in ('identity', 'position', 'inventory', 'terrain', 'header',
                  'items', 'knowledge'):
        require(saved[field] == restored[field],
                'native restore changed persisted ' + field)


def audit_state(root, state):
    expected = {state / 'save' / name for name in SAVE_FILES}
    actual = {p for p in root.rglob('*') if p.is_file() or p.is_symlink()}
    require(actual == expected,
            'game writes escaped fresh user save state: ' + repr(actual ^ expected))
    for path in expected:
        require(not path.is_symlink(), 'save unexpectedly linked outside user state')
    directories = {root / name for name in
                   ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work')}
    directories.update((state, state / 'save'))
    if state.parent != root / 'state':
        directories.update((root / 'home/.local', root / 'home/.local/state'))
    require({p for p in root.rglob('*') if p.is_dir()} == directories,
            'game created directories outside native user save state')


def exercise(executable, root, explicit, transcript, capture_live=False):
    root.mkdir()
    for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
        (root / name).mkdir(mode=0o700)
    env = {'HOME': str(root / 'home'), 'XDG_CONFIG_HOME': str(root / 'config'),
           'XDG_DATA_HOME': str(root / 'data'), 'XDG_CACHE_HOME': str(root / 'cache'),
           'XDG_RUNTIME_DIR': str(root / 'runtime'), 'TMPDIR': str(root / 'tmp'),
           'TERM': 'vt100', 'LC_ALL': 'C', 'PATH': '/nonexistent'}
    if explicit:
        env['XDG_STATE_HOME'] = str(root / 'state')
    state = (root / 'state' if explicit else root / 'home/.local/state') / 'narwharl'
    directory = state / 'save'
    work = root / 'work'
    first = Session(executable, env, work, transcript)
    try:
        first.character()
        start, moved = first.move()
        inventory = first.inventory()
        saved = first.save(directory)
        require(saved['position'] == moved, 'save does not match live moved player')
        require(bool(saved['inventory']) == ('You have nothing.' not in inventory),
                'native inventory display disagrees with save')
    finally:
        first.close()
    audit_state(root, state)

    resumed = Session(executable, env, work, transcript)
    try:
        require(resumed.gameplay() == moved, 'native restore did not recover position')
        require('Advance skills :' not in resumed.text(), 'restore regenerated player')
        if capture_live:
            capture('OMP_RUNTIME_RAW_CAPTURE', bytes(resumed.raw))
            capture('OMP_RUNTIME_TEXT_CAPTURE', resumed.text().encode('ascii'))
        require(resumed.inventory() == inventory, 'native restore changed live inventory')
        restored = resumed.save(directory)
        # A real no-movement save roundtrip compares actual native state.  No
        # fixture, save editing, copied save injection or proof-only flag is used.
        assert_restore(saved, restored)
    finally:
        resumed.close()
    audit_state(root, state)

    continued = Session(executable, env, work, transcript)
    try:
        require(continued.gameplay() == moved, 'second native restore failed')
        before, after = continued.move()
        final = continued.save(directory)
        require(before == moved and final['position'] == after and after != moved,
                'post-restore movement was not preserved by native re-save')
        for field in ('identity', 'inventory', 'terrain', 'header', 'items', 'knowledge'):
            require(final[field] == restored[field],
                    'safe post-restore movement changed persisted ' + field)
    finally:
        continued.close()
    audit_state(root, state)
    print('NARWHARL: %s native player moved %s -> %s, restored same state, '
          'moved again to %s and re-saved four native files'
          % ('XDG' if explicit else 'HOME fallback', start, moved, after))


def main():
    require(len(sys.argv) == 3, 'usage: narwharl-pty-runner.py NARWHARL SCRATCH')
    require(socket.if_nameindex() == [(1, 'lo')], 'proof requires offline network namespace')
    executable = str(Path(sys.argv[1]).absolute())
    scratch = Path(sys.argv[2]).resolve()
    transcript = bytearray()
    try:
        exercise(executable, scratch / 'xdg', True, transcript, capture_live=True)
        exercise(executable, scratch / 'home', False, transcript)
    finally:
        (scratch / 'transcript.raw').write_bytes(transcript)
        capture('OMP_RUNTIME_TRANSCRIPT', bytes(transcript))
    print('NARWHARL-SMOKE: actual-map-movement-save-restore-continued-save-ok')


if __name__ == '__main__':
    main()
