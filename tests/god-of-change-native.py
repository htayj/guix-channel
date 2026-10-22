#!/usr/bin/env python3
"""Observe the unseeded original game with X11 screenshots and XTEST keys.

The source oracle is GodOfChange.cpp in the official 2011-03-12 source ZIP.
No game code is imported, no process memory is read, and no state is injected.
The external FOR consumer supplies existing namespace/mount/inventory/tool
helpers; the installed authentic font supplies exact, binary glyph silhouettes.
"""
from collections import Counter
import ctypes
import errno
import importlib.util
import json
import os
from pathlib import Path
import re
import select
import struct
import subprocess
import sys
import traceback
import time

# Reuse test infrastructure, never the installed game's source or private APIs.
_helper_path = Path(__file__).resolve().with_name('for-roguelike-native.py')
_spec = importlib.util.spec_from_file_location('native_consumer_helpers', _helper_path)
helpers = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(helpers)
require, record, sha = helpers.require, helpers.record, helpers.sha
COLS, ROWS, CELL = 95, 61, 8
WIDTH, HEIGHT = COLS * CELL, ROWS * CELL
FONT_SHA256 = '2ecd9e9556b2aab8c36122a6b066ebac4e47b293520d55315451acec09f589e6'
SOURCE = ('https://storage.googleapis.com/google-code-archive-downloads/v2/'
          'code.google.com/godofchange/God%20of%20Change%20-%20Source.zip')
DIRECTIONS = [('Right', 1, 0), ('Down', 0, 1), ('Left', -1, 0), ('Up', 0, -1)]
SPECIES_GLYPHS = {'Goblin': 'g', 'Kobold': 'k', 'Spider': 's', 'Dwarf': 'd',
                  'Wolf': 'w', 'Ooze': 'o', 'Imp': 'i', 'Halfling': 'h',
                  'Lizardman': 'l', 'Troglodyte': 't', 'Bugbear': 'b', 'Faerie': 'f'}
MONSTERS = set(SPECIES_GLYPHS.values())
TRAITS = {'Allied', 'Friendly', 'Apathetic', 'Cowardly', 'Territorial', 'Aggressive',
          'Teleporting', 'Web-spinning', 'Acidic', 'Stealthy', 'Strong', 'Poisonous',
          'Fire-breathing', 'Lightning', 'Tentacled', 'Hardened', 'Ghostly', 'Shocking',
          'Regenerating', 'Undead', 'Telepathic', 'Hive mind', 'Reproducing', 'Rallying'}


def drop_capabilities():
    """The existing gnollcrawl/geminum native consumers' Linux deprivileging."""
    libc = ctypes.CDLL(None, use_errno=True)
    libc.prctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_ulong,
                           ctypes.c_ulong, ctypes.c_ulong]
    libc.prctl.restype = ctypes.c_int

    def prctl(option, argument=0):
        if libc.prctl(option, argument, 0, 0, 0) < 0:
            number = ctypes.get_errno()
            raise OSError(number, os.strerror(number))

    capability = 0
    while libc.prctl(23, capability, 0, 0, 0) >= 0:
        prctl(24, capability)
        capability += 1
    require(ctypes.get_errno() == errno.EINVAL and capability > 0,
            'cannot enumerate capability bounding set')
    if libc.prctl(47, 4, 0, 0, 0) < 0:
        raise OSError(ctypes.get_errno(), 'ambient capabilities not cleared')
    prctl(38, 1)

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


def identity(proc):
    proof = helpers.namespaces(proc)
    status = proof['files']['status']
    require(int(os.environ['HOST_UID']) == 1000 and int(os.environ['HOST_GID']) == 998,
            'requires unchanged UID1000/GID998')
    for field in ('CapInh', 'CapPrm', 'CapEff', 'CapBnd', 'CapAmb'):
        match = re.search(r'^' + field + r':\s*([0-9a-f]+)$', status, re.M)
        require(match and int(match[1], 16) == 0, 'nonzero child capability: ' + field)
    require(re.search(r'^NoNewPrivs:\s*1$', status, re.M), 'no_new_privs not set')
    _, mounts = helpers.store_entries()
    require(mounts and all('ro' in entry['options'] for entry in mounts),
            'store read-only mount lost after dropping capabilities')
    proof['read_only_store_mounts'] = mounts
    return proof


class Glyphs:
    def __init__(self, font, tool, convert):
        require(sha(font.read_bytes()) == FONT_SHA256, 'authentic installed font differs')
        require(tool(convert, str(font), '-format', '%w %h', 'info:').strip() == b'128 128',
                'original font atlas is not 128x128')
        rgba = tool(convert, str(font), '-depth', '8', 'rgba:-')
        require(len(rgba) == 128 * 128 * 4, 'incomplete font decode')
        require(set(tuple(rgba[i:i + 4]) for i in range(0, len(rgba), 4)) ==
                {(0, 0, 0, 255), (255, 255, 255, 255)},
                'original non-greyscale binary color-key font changed')
        self.masks, self.cache = {}, {}
        # Exact ASCII_INCOL: x=code//16, y=code%16. Restrict to the actual
        # source's alphabet, avoiding visually identical unused CP437 slots.
        codes = [*range(32, 127), 4, 15, 16, 17, 177, 179, 190, 206, 219, 244, 245]
        for code in codes:
            mask = bytes(rgba[(((code % 16) * CELL + y) * 128 +
                               (code // 16) * CELL + x) * 4] == 255
                         for y in range(CELL) for x in range(CELL))
            require(mask not in self.masks, 'ambiguous used original font glyph')
            self.masks[mask] = code
        require(self.masks[bytes(64)] == 32 and self.masks[bytes([1]) * 64] == 219,
                'original space/full-block shapes differ')

    def tile(self, tile):
        if tile in self.cache:
            return self.cache[tile]
        colors = Counter(tile[i:i + 3] for i in range(0, len(tile), 3))
        if len(colors) == 1:
            # With this exact binary font a solid map cell is unseen black
            # space or a full-block wall, never silently a decoded actor.
            color = next(iter(colors))
            result = (32 if color == b'\0\0\0' else 219, list(color), list(color))
        elif len(colors) == 2:
            results = []
            for foreground in colors:
                mask = bytes(tile[i:i + 3] == foreground for i in range(0, len(tile), 3))
                if mask in self.masks:
                    background = next(c for c in colors if c != foreground)
                    results.append((self.masks[mask], list(foreground), list(background)))
            result = results[0] if len(results) == 1 else (-1, [], [])
        else:
            result = (-1, [], [])
        self.cache[tile] = result
        return result

    def read(self, rgb):
        require(len(rgb) == WIDTH * HEIGHT * 3, 'incomplete native framebuffer')
        codes, colors = [], []
        for row in range(ROWS):
            line, palette = [], []
            for col in range(COLS):
                tile = b''.join(rgb[((row * CELL + y) * WIDTH + col * CELL) * 3:
                                   ((row * CELL + y) * WIDTH + col * CELL + CELL) * 3]
                                for y in range(CELL))
                code, fg, bg = self.tile(tile)
                line.append(code)
                palette.append({'foreground': fg, 'background': bg})
            codes.append(line)
            colors.append(palette)
        return Frame(codes, colors)


class Frame:
    def __init__(self, codes, colors):
        self.codes, self.colors = codes, colors
        rows = []
        for y, row in enumerate(codes):
            chars = []
            for x, code in enumerate(row):
                # Space is color-keyed through, so title/HUD padding has a
                # solid nonblack background. Map walls retain their block.
                if code == 219 and colors[y][x]['foreground'] == colors[y][x]['background']:
                    chars.append('█' if 3 <= y < 46 and 3 <= x < 73 else ' ')
                elif 32 <= code < 127:
                    chars.append(chr(code))
                elif code >= 0:
                    chars.append(bytes([code]).decode('cp437'))
                else:
                    chars.append('\ufffd')
            rows.append(''.join(chars))
        self.rows = rows

    def state(self):
        require('Dungeon 1' in self.rows[2] and 'Bestiary' in self.rows[2],
                'original Dungeon1/Bestiary headers absent')
        health = re.search(r'Health:\s+(\d+)\s+/\s+20', self.rows[50])
        require(health and 'Weapon:' in self.rows[53] and 'Armour:' in self.rows[56],
                'original adventurer HUD not exactly decoded')
        require('Messages' in self.rows[47] and 'Inventory' in self.rows[47],
                'original inventory/messages headers absent')
        board = [row[3:73] for row in self.codes[3:46]]
        require(all(c != -1 for row in board for c in row), 'unidentified exact map glyph')
        players = [(x, y) for y, row in enumerate(board) for x, code in enumerate(row) if code == 64]
        require(len(players) == 1, 'unique original @ player absent')
        species = []
        for i in range(6):
            row = 4 + i * 7
            name = self.rows[row][76:88].strip()
            glyph = self.rows[row][89]
            traits = [self.rows[row + dy][77:93].strip() for dy in range(2, 6)]
            traits = [trait for trait in traits if trait]
            require(name in SPECIES_GLYPHS and glyph == SPECIES_GLYPHS[name] and traits and
                    all(trait in TRAITS for trait in traits),
                    'original six-species bestiary not exactly decoded')
            species.append({'name': name, 'glyph': glyph, 'traits': traits})
        require(len({s['name'] for s in species}) == 6, 'duplicate native species')
        monsters = [{'position': [x, y], 'glyph': chr(code),
                     'foreground': self.colors[y + 3][x + 3]['foreground']}
                    for y, row in enumerate(board) for x, code in enumerate(row)
                    if chr(code) in MONSTERS]
        messages = [row[46:94].rstrip() for row in self.rows[49:60]]
        dead = int(health[1]) == 0 or any('You have died!' in row for row in messages)
        player = list(players[0])
        player_color = self.colors[player[1] + 3][player[0] + 3]['foreground']
        require(player_color == ([191, 0, 0] if dead else [0, 127, 127]),
                'player does not have original live/dead palette')
        return {'position': player, 'health': int(health[1]), 'dead': dead,
                'board': board, 'species': species, 'monsters': monsters,
                'messages': messages, 'inventory': [row[23:44] for row in self.rows[50:60]]}


class Session(helpers.Session):
    def __init__(self, output, evidence, root, tools):
        self.output, self.evidence, self.root = output, evidence, root
        self.xvfb, self.xdotool, self.xwd, self.convert = tools
        self.process = self.server = self.window = None
        self.inputs, self.commands = [], []
        self.env = {'PATH': '', 'LC_ALL': 'C', 'SDL_VIDEODRIVER': 'x11',
                    'SDL_AUDIODRIVER': 'dummy', 'LIBGL_ALWAYS_SOFTWARE': '1',
                    'MESA_SHADER_CACHE_DISABLE': 'true',
                    'DBUS_SESSION_BUS_ADDRESS': 'unix:path=/run/no-session',
                    'DBUS_SYSTEM_BUS_ADDRESS': 'unix:path=/run/no-system'}
        for variable, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                               ('XDG_DATA_HOME', 'data'), ('XDG_STATE_HOME', 'state'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_RUNTIME_DIR', 'runtime'),
                               ('TMPDIR', 'tmp')]:
            self.env[variable] = str(root / name)
        self.observer = Glyphs(output / 'share/god-of-change/terminal.png', self.tool, self.convert)

    def launch(self):
        readfd, writefd = os.pipe()
        try:
            with (self.evidence / 'xvfb.log').open('wb') as log:
                self.server = subprocess.Popen([self.xvfb, '-displayfd', str(writefd), '-screen', '0',
                    '1024x768x24', '-nolisten', 'tcp', '-noreset', '-ac', '-r'],
                    env=self.env, pass_fds=(writefd,), stdout=log, stderr=log)
            os.close(writefd)
            writefd = None
            require(select.select([readfd], [], [], 20)[0] and self.server.poll() is None,
                    'private Xvfb readiness absent')
            display = os.read(readfd, 128).decode().strip()
            require(display.isdecimal(), 'invalid Xvfb displayfd')
            self.env['DISPLAY'] = ':' + display
        finally:
            os.close(readfd)
            if writefd is not None:
                os.close(writefd)
        with (self.evidence / 'game.log').open('wb') as log:
            self.process = subprocess.Popen([str(self.output / 'bin/god-of-change')],
                env=self.env, cwd=self.root / 'work', stdin=subprocess.DEVNULL, stdout=log, stderr=log)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'game exited before SDL window')
            windows = self.tool(self.xdotool, 'search', '--onlyvisible', '--name',
                                '^God of Change$', statuses=(0, 1)).decode().splitlines()
            if windows:
                require(len(windows) == 1, 'native window not unique')
                self.window = windows[0]
                break
            time.sleep(.1)
        else:
            raise RuntimeError('native window readiness timeout')
        self.tool(self.xdotool, 'windowfocus', '--sync', self.window)
        time.sleep(.5)
        proc = Path('/proc') / str(self.process.pid)
        proof = identity(proc)
        proof.update(pid=self.process.pid, executable=os.readlink(proc / 'exe'), cwd=os.readlink(proc / 'cwd'))
        require(Path(proof['executable']).resolve() == (self.output / 'bin/god-of-change').resolve(),
                'process is not installed native game ELF')
        require(Path(proof['executable']).read_bytes()[:4] == b'\x7fELF', 'game is not ELF')
        require(Path(proof['cwd']) == self.root / 'work', 'game changed fresh private CWD')
        maps = (proc / 'maps').read_text()
        for library in ('libtcod.so', 'libtcodxx.so'):
            require(re.search(r'/gnu/store/[^/]+-dwarftown-libtcod-1\.5\.1/lib/' + re.escape(library), maps),
                    'private source-built libtcod1.5.1 not mapped: ' + library)
        require(re.search(r'/gnu/store/[^/]+/lib/libSDL[^/\s]*\.so', maps), 'native SDL not mapped')
        for name in ('status', 'maps', 'mountinfo', 'cmdline'):
            (self.evidence / ('process-' + name + '.raw')).write_bytes((proc / name).read_bytes())
        return proof

    def capture(self, label):
        require(self.process.poll() is None, 'game exited during ' + label)
        dump, png = self.evidence / (label + '.xwd'), self.evidence / (label + '.png')
        self.tool(self.xwd, '-silent', '-id', self.window, '-out', str(dump))
        self.tool(self.convert, str(dump), str(png))
        image = png.read_bytes()
        require(image[:8] == b'\x89PNG\r\n\x1a\n' and
                struct.unpack_from('>II', image, 16) == (WIDTH, HEIGHT),
                'original 95x61 console / 760x488 native window differs')
        rgb = self.tool(self.convert, str(png), '-depth', '8', 'rgb:-')
        frame = self.observer.read(rgb)
        (self.evidence / (label + '.screen.txt')).write_text('\n'.join(frame.rows) + '\n')
        record(self.evidence / (label + '.screen.json'),
               {'codes': frame.codes, 'colors': frame.colors, 'png_sha256': sha(image), 'rgb_sha256': sha(rgb)})
        require(not helpers.ERRORS.search('\n'.join(frame.rows)), 'native error visible in framebuffer')
        return frame

    def settled(self, label):
        # Only observation is retried, never an input, world or process launch.
        # Ranged monsters animate synchronously; wait for two matching complete
        # map/HUD states rather than mistake a transient attack sprite for play.
        previous = None
        deadline = time.monotonic() + 15
        errors = []
        for number in range(12):
            frame = self.capture(label + '-sample-%02d' % number)
            try:
                state = frame.state()
            except RuntimeError as error:
                errors.append(str(error))
                state = None
            if state is not None and state == previous:
                return frame, state
            previous = state
            if time.monotonic() >= deadline:
                break
            time.sleep(.2)
        raise RuntimeError('native framebuffer failed to settle: ' + repr(errors))


def summary(state):
    return {key: value for key, value in state.items() if key != 'board'}


def choose(state, visited):
    """Use only the visible raster: avoid all monsters, acid, webs and portals."""
    x, y = state['position']
    threats = [monster['position'] for monster in state['monsters']]
    choices = []
    for key, dx, dy in DIRECTIONS:
        nx, ny = x + dx, y + dy
        if not (0 <= nx < 70 and 0 <= ny < 43):
            continue
        if state['board'][ny][nx] != ord('.'):
            continue
        # Adjacent floor is necessarily in player FOV; a live actor on it
        # would be drawn and decoded above. Monster separation breaks ties.
        safety = min((abs(nx - mx) + abs(ny - my) for mx, my in threats), default=99)
        choices.append((safety, -visited[(nx, ny)], key, dx, dy))
    if choices:
        _, _, key, dx, dy = max(choices)
        return key, [x + dx, y + dy], 'observed adjacent floor, maximizing monster separation then novelty'
    return 'space', [x, y], 'no observed plain adjacent floor; one observed wait, not a blind batch'


def play(session, proof):
    proof['process'] = session.launch()
    _, initial = session.settled('01-initial')
    require(initial['health'] == 20 and not initial['dead'], 'fresh original adventurer not alive at20HP')
    proof['initial'] = summary(initial)
    proof['actions'], proof['movements'], proof['monster_changes'] = [], [], []
    visited = Counter([tuple(initial['position'])])
    current = initial
    # Source starts changeTimer at45, but no invisible counter is asserted.
    # Every ordinary action is observed, and death terminates immediately.
    # Stop when a real bestiary/world change is observed, never after an
    # assumed safe80waits. The bound limits coverage, not RNG selection.
    for number in range(1, 57):
        if current['dead']:
            break
        key, expected, reason = choose(current, visited)
        healing = any(re.search(r'Healing x[1-9]', row) for row in current['inventory'])
        if current['health'] <= 10 and healing:
            key, expected, reason = '1', current['position'], 'ordinary collected Healing scroll at low visibleHP'
        before = current
        label = '02-action-%02d-%s' % (number, key)
        session.key(label, key)
        _, current = session.settled(label)
        entry = {'number': number, 'key': key, 'reason': reason,
                 'expected_destination': expected, 'before': summary(before), 'after': summary(current)}
        proof['actions'].append(entry)
        visited[tuple(current['position'])] += 1
        if before['position'] != current['position']:
            require(key in {direction[0] for direction in DIRECTIONS} and current['position'] == expected,
                    'actual movement differs from requested adjacent ordinary tile')
            bx, by = before['position']
            require(current['board'][by][bx] != 64, 'duplicate player left at old position')
            landmarks = [[x, y, before['board'][y][x]] for y in range(43) for x in range(70)
                         if before['board'][y][x] in (46, 219) and
                         before['board'][y][x] == current['board'][y][x]]
            require(len(landmarks) >= 8, 'movement lacks stable real terrain landmarks')
            proof['movements'].append({'action': number, 'key': key, 'before': before['position'],
                                      'after': current['position'], 'stable_landmarks': landmarks})
        # These are actual decoded actor-cell changes, not claimed persistent
        # monster identities or motion when fog merely reveals another actor.
        changes = [[x, y, before['board'][y][x], current['board'][y][x]]
                   for y in range(43) for x in range(70)
                   if before['board'][y][x] != current['board'][y][x] and
                   (chr(before['board'][y][x]) in MONSTERS or chr(current['board'][y][x]) in MONSTERS)]
        if changes:
            proof['monster_changes'].append({'action': number, 'actor_cells': changes})
        if current['species'] != initial['species']:
            proof['core_change'] = {'kind': 'native species trait mutation', 'action': number,
                                    'before': initial['species'], 'after': current['species'],
                                    'messages': current['messages']}
        terrain = [[x, y, before['board'][y][x], current['board'][y][x]]
                   for y in range(43) for x in range(70)
                   if {before['board'][y][x], current['board'][y][x]} == {46, 219}]
        if terrain:
            proof['core_change'] = {'kind': 'visible native wall/floor mutation',
                                    'action': number, 'terrain': terrain, 'messages': current['messages']}
        record(session.evidence / 'gameplay-progress.json', proof)
        if current['dead'] or (proof['movements'] and 'core_change' in proof):
            break
    _, final = session.settled('03-meaningful-gameplay-final')
    proof['final'] = summary(final)
    proof['outcome'] = 'native-death' if final['dead'] else 'alive-normal-exit'
    # Preserve a final real window screenshot before ESC destroys the window.
    session.capture('04-exit-before-escape')
    session.key('ordinary-escape-exit', 'Escape')
    proof['ordinary_exit_status'] = session.process.wait(timeout=15)
    require(proof['ordinary_exit_status'] == 0, 'ordinary ESC did not exit0')
    require(not final['dead'], 'actual native death: retained without reroll or false success')
    require(proof['movements'], 'no observable real player movement attained')
    # Core trait/world mutation is preferred, but truthful bounded monster
    # simulation is meaningful if the particular live run did not reach it.
    require('core_change' in proof or proof['monster_changes'],
            'bounded run did not visibly demonstrate world/monster simulation')


def main():
    require(len(sys.argv) == 7, 'usage: native.py OUTPUT EVIDENCE XVFB XDOTOOL XWD CONVERT')
    output, evidence = map(Path, sys.argv[1:3])
    require(output.parent == Path('/gnu/store') and output.is_dir(), 'canonical store output required')
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc/self/fd/' + str(descriptor))
    proof = {'success': False, 'output': str(output), 'source': SOURCE,
             'font_sha256': FONT_SHA256, 'font_layout': 'ASCII_INCOL 16x16, exact binary8x8 masks',
             'window_pixels': [WIDTH, HEIGHT], 'console_cells': [COLS, ROWS],
             'injected_seed_config_save_hooks': False, 'launch_count': 1,
             'helper': str(_helper_path), 'claim_limits': [
                 'Single native time-seeded world; no reroll or RNG override.',
                 'No save system exists; no persistence/save/load claim.',
                 'No fullscreen claim: upstream F5 handler is commented out.',
                 'Bounded visible movement, monster cells and any attained trait/world mutation only.',
                 'No full dungeon progression, boss, victory or hidden monster-identity claim.']}
    session = root = None
    failure = None
    try:
        require(os.getpid() == 1, 'driver is not private PID1')
        evidence, mounts = helpers.isolate(evidence)
        proof['read_only_store_mounts'] = mounts
        drop_capabilities()
        proof['driver_namespace'] = identity(Path('/proc/self'))
        closure = (evidence / 'runtime-closure.txt').read_text().splitlines()
        tools = json.loads((evidence / 'consumer-tools.json').read_text())
        leaks = {name: tools[name] for name in ('python', 'xorg-server', 'xdotool', 'xwd', 'imagemagick')
                 if tools[name] in closure}
        require(str(output) in closure and not leaks, 'consumer tools leaked into game closure')
        proof['runtime_closure'], proof['consumer_outputs'] = closure, tools
        root = evidence / 'scratch'
        root.mkdir(mode=0o700)
        for name in ('home', 'config', 'data', 'state', 'cache', 'runtime', 'tmp', 'work'):
            (root / name).mkdir(mode=0o700)
        record(evidence / 'private-before.json', helpers.inventory(root))
        session = Session(output, evidence, root, sys.argv[3:])
        play(session, proof)
        # The complete upstream has no file-writing/save APIs. Observe every
        # fresh HOME/XDG/CWD rather than fabricate a persistence acceptance.
        generated = [str(path.relative_to(root)) for path in root.rglob('*') if path.is_file()]
        proof['native_generated_files'] = generated
        require(not generated, 'unexpected file output from original no-save game')
        proof['success'] = True
    except BaseException as error:
        failure = error
        proof['error'] = repr(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
    finally:
        cleanup_errors = session.stop() if session is not None else []
        if session is not None:
            proof['cleanup'] = {'game_exit_status': None if session.process is None else session.process.poll(),
                                'xvfb_exit_status': None if session.server is None else session.server.poll(),
                                'errors': cleanup_errors}
        if root is not None and root.exists():
            record(evidence / 'private-after.json', helpers.inventory(root))
        for name in ('game.log', 'xvfb.log'):
            path = evidence / name
            if path.exists() and helpers.ERRORS.search(path.read_text(errors='replace')):
                cleanup_errors.append('native error retained in ' + name)
        if cleanup_errors:
            proof['success'] = False
            proof['cleanup_errors'] = cleanup_errors
        record(evidence / 'native-result.json', proof)
        os.close(descriptor)
    require(proof['success'] and failure is None, 'native consumer failed: ' + repr(failure or cleanup_errors))
    print('GOD_OF_CHANGE_NATIVE_GAMEPLAY_OK')


if __name__ == '__main__':
    main()
