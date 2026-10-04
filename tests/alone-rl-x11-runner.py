#!/usr/bin/env python3
"""Observe native Swing pixels and terrain bytes; send only external X11 keys.

Main/AsciiPanel use the shipped TALRYTH 15x15 atlas at 55x55 cells.
MapSystem saves only row-major elevation bytes; fresh Continue creates objects.
This proof deliberately does not claim player, inventory, or clock persistence.
"""
import collections
import ctypes
import hashlib
import io
import json
import os
from pathlib import Path
import re
import select
import signal
import subprocess
import sys
import time
import traceback
import zipfile

from PIL import Image


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def stop(process):
    if process is not None and process.poll() is None:
        try:
            os.killpg(process.pid, signal.SIGTERM)
            process.wait(timeout=5)
        except ProcessLookupError:
            pass
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
        # Linux x86_64 mount_setattr: recursively protect all caller mounts,
        # including /gnu/store. Only our fresh scratch and evidence are writable.
        mount('/', '/', flags=4096 | 16384)
        attrs = (ctypes.c_uint64 * 4)(1, 0, 0, 0)
        if libc.syscall(ctypes.c_long(442), ctypes.c_int(-100), ctypes.c_char_p(b'/'),
                        ctypes.c_uint(0x8000), ctypes.byref(attrs), ctypes.sizeof(attrs)):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), 'recursive read-only root')
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, evidence = Path('/tmp/alone-rl-root'), Path('/tmp/alone-rl-evidence')
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


def glyphs_from_jar(path):
    with zipfile.ZipFile(path) as archive:
        atlas = Image.open(io.BytesIO(archive.read('talryth_square_15x15.png'))).convert('RGB')
    require(atlas.size == (240, 240), 'unexpected native TALRYTH atlas geometry')
    masks = collections.defaultdict(list)
    for code in range(256):
        tile = atlas.crop(((code % 16) * 15, (code // 16) * 15,
                           (code % 16 + 1) * 15, (code // 16 + 1) * 15))
        # AsciiPanel.colorOp maps component index 0 to BG, every other to FG.
        mask = sum(1 << index for index, rgb in enumerate(tile.getdata()) if rgb[0])
        if mask:
            masks[mask].append(code)
    return masks


def observe(image, masks):
    require(image.size == (825, 825), 'unexpected Swing content geometry: ' + str(image.size))
    lines, cells, backgrounds = [], {}, {}
    for y in range(55):
        line = []
        for x in range(55):
            tile = image.crop((x * 15, y * 15, (x + 1) * 15, (y + 1) * 15))
            colors = collections.defaultdict(int)
            pixels = list(tile.getdata())
            for index, rgb in enumerate(pixels):
                colors[rgb] |= 1 << index
            codes = set()
            for mask in colors.values():
                codes.update(masks.get(mask, []))
            ascii_codes = [code for code in codes if 33 <= code < 127]
            line.append(chr(ascii_codes[0]) if len(ascii_codes) == 1 else ' ')
            cells[x, y] = tile.tobytes()
            backgrounds[x, y] = collections.Counter(pixels).most_common(1)[0][0]
        lines.append(''.join(line).rstrip())
    return '\n'.join(lines), cells, backgrounds


# data/map/terrain.yml thresholds and colors; MapSystem uses strictly higherKey.
TERRAIN = [(0.01, 'deep-water', (51, 102, 153)),
           (0.05, 'shallow-water', (20, 152, 204)),
           (0.08, 'sand', (170, 170, 0)), (0.1, 'ground', (184, 134, 11)),
           (0.4, 'grass', (31, 138, 19)), (0.7, 'hill-grass', (74, 105, 4)),
           (0.8, 'hill', (119, 93, 61)), (0.9, 'mountain', (76, 70, 50)),
           (1.1, 'high-mountain', (255, 240, 220))]


def terrain(byte):
    return next((name, color) for threshold, name, color in TERRAIN if byte / 255 < threshold)


def main():
    game_out, root, xvfb, xdotool, image_import, evidence, nar_before, xwininfo = sys.argv[1:]
    game_out, root, evidence = map(Path, (game_out, root, evidence))
    record = {'status': 'running', 'consumer': 'ordinary Swing GUI via external X11 events',
              'upstream_commit': 'de2ab3f0023cbfb0f9ab5a68e3d48fabf4b17de8',
              'output': str(game_out), 'output_nar_before': nar_before,
              'events': [], 'screenshots': [], 'elevation': [], 'moves': [],
              'persistence_scope': 'terrain elevation only; same-process Continue keeps loaded objects, fresh-process Continue creates them anew; no character, inventory, position or time persistence claimed'}
    process = server = None
    handles = []
    stage = 'namespace isolation'
    report_path = evidence / 'evidence.json'

    def report():
        report_path.write_text(json.dumps(record, indent=2) + '\n')

    report()
    try:
        root, evidence = isolate(root, evidence)
        report_path = evidence / 'evidence.json'
        uid_map = Path('/proc/self/uid_map').read_text().split()
        require(len(uid_map) == 3 and uid_map[0] == uid_map[1] and uid_map[2] == '1',
                'namespace did not preserve caller UID')
        interfaces = sorted(line.split(':', 1)[0].strip()
                            for line in Path('/proc/net/dev').read_text().splitlines()[2:])
        require(interfaces == ['lo'], 'network namespace has an external interface')
        require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, '/gnu/store is writable')
        record['isolation'] = {'uid_map': uid_map, 'interfaces': interfaces,
                               'store_read_only': True, 'caller_mounts_read_only': True,
                               'private_tmp': True, 'fresh_home_xdg': True}
        env = dict(os.environ)
        for variable, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                    ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                    ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                    ('TMPDIR', 'tmp')):
            env[variable] = str(root / directory)
        env.update(DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/no-session-bus',
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path=/tmp/no-system-bus')
        masks = glyphs_from_jar(game_out / 'share/alone-rl/alone-rl.jar')
        read_fd, write_fd = os.pipe()
        server_log = open(evidence / 'xvfb.log', 'wb')
        handles.append(server_log)
        try:
            server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                       '1024x1024x24', '-nolisten', 'tcp', '-ac'],
                                      pass_fds=(write_fd,), stdout=server_log, stderr=server_log,
                                      env=env, start_new_session=True)
            os.close(write_fd)
            write_fd = None
            require(select.select([read_fd], [], [], 10)[0], 'Xvfb startup timed out')
            display = os.read(read_fd, 128).decode().strip()
            require(display.isdecimal(), 'Xvfb did not allocate a display')
            env['DISPLAY'] = ':' + display
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
        runtime_paths = []

        def launch(label):
            nonlocal process
            runtime_path = evidence / (label + '-runtime.log')
            runtime_paths.append(runtime_path)
            record['runtime_transcripts'] = [path.name for path in runtime_paths]
            report()
            runtime_log = open(runtime_path, 'wb')
            handles.append(runtime_log)
            process = subprocess.Popen([str(game_out / 'bin/alone-rl')], cwd=root / 'work',
                                       stdout=runtime_log, stderr=runtime_log, env=env,
                                       start_new_session=True)

        def tool(*args):
            return subprocess.check_output(args, env=env, timeout=10)

        def clean_log():
            for runtime_path in runtime_paths:
                text = runtime_path.read_text(errors='replace')
                require(not re.search(r'Exception|\bERROR\b|\bFATAL\b|[\w.$]+Error(?:[:\s]|$)|'
                                      r'Caused by:|error while loading|Could not|failed to|panicked at|'
                                      r'\bat [\w.$]+\([^\n]+\.java:\d+\)', text, re.I),
                        'native runtime error in retained ' + runtime_path.name)

        window = None

        def focus_native():
            nonlocal window
            window = None
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                clean_log()
                require(process.poll() is None, 'game exited before opening native Swing window')
                found = subprocess.run([xdotool, 'search', '--onlyvisible', '--pid',
                                        str(process.pid), '--name', '.*'], env=env,
                                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=5)
                if found.returncode == 0:
                    for candidate in found.stdout.decode().splitlines():
                        geometry = tool(xdotool, 'getwindowgeometry', '--shell', candidate).decode()
                        if 'WIDTH=825\n' in geometry and 'HEIGHT=825\n' in geometry:
                            window = candidate
                            break
                    if window:
                        break
                time.sleep(0.1)
            require(window, '825x825 native Swing window did not appear')
            tool(xdotool, 'windowfocus', '--sync', window)

        launch('new-game')
        focus_native()

        def frame():
            clean_log()
            require(process.poll() is None, 'native game exited during ' + stage)
            data = tool(image_import, '-window', window, 'png:-')
            image = Image.open(io.BytesIO(data)).convert('RGB')
            return data, observe(image, masks)

        def capture(name):
            data, observation = frame()
            path = evidence / (name + '.png')
            path.write_bytes(data)
            (evidence / (name + '.txt')).write_text(observation[0] + '\n')
            record['screenshots'].append({'file': path.name,
                                          'sha256': hashlib.sha256(data).hexdigest()})
            report()
            return observation

        def expect(needle, name):
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                if needle in frame()[1][0]:
                    return capture(name)
                time.sleep(0.1)
            capture('failure-screen')
            raise RuntimeError('timed out awaiting native text ' + repr(needle))

        def expect_play(name):
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                text = frame()[1][0].splitlines()
                if (text[3].startswith('[') and text[3].endswith(']')
                        and text[4].startswith('[') and text[4].endswith(']')
                        and '@' in text[26]):
                    return capture(name)
                time.sleep(0.1)
            capture('failure-play-screen')
            raise RuntimeError('native PlayScreen HUD/player did not appear')

        def key(name, reason):
            # Swing routes keyboard input through its real native FocusProxy,
            # not the 825x825 shell used for screenshots (nor a WM ancestor).
            tree = tool(xwininfo, '-id', window, '-tree').decode()
            candidates = re.findall(r'^\s*(0x[0-9a-fA-F]+) "FocusProxy"',
                                    tree, re.MULTILINE)
            require(len(candidates) == 1, 'expected one descendant native AWT FocusProxy')
            input_window = str(int(candidates[0], 16))
            tool(xdotool, 'windowfocus', '--sync', input_window)
            focused = tool(xdotool, 'getwindowfocus', '-f').decode().strip()
            require(focused == input_window, 'AWT FocusProxy does not own X input focus')
            record['events'].append({'stage': stage, 'key': name, 'reason': reason})
            report()
            # No --window: use XTEST events delivered to the focused real window.
            # Hold through the native 60ms input cadence; movement translation
            # below detects the actual step count if more than one is consumed.
            tool(xdotool, 'keydown', '--clearmodifiers', name)
            time.sleep(0.08)
            tool(xdotool, 'keyup', name)
            time.sleep(0.3)

        save_path = root / 'data/alone-rl/map/elevation.data'
        saved = None

        def elevation(label):
            data = save_path.read_bytes()
            require(len(data) == 1024 * 1024, 'native elevation save has wrong byte count')
            if saved is not None:
                require(data == saved, 'native elevation changed across Continue/continued play')
            path = evidence / (label + '-elevation.data')
            path.write_bytes(data)
            counts = collections.Counter()
            for byte, count in collections.Counter(data).items():
                counts[terrain(byte)[0]] += count
            samples = [{'x': x, 'y': y, 'byte': data[y * 1024 + x],
                        'terrain': terrain(data[y * 1024 + x])[0]}
                       for x, y in [(0, 0), (256, 256), (512, 512), (768, 768), (1023, 1023)]]
            record['elevation'].append({'file': path.name, 'bytes': len(data),
                                        'sha256': hashlib.sha256(data).hexdigest(),
                                        'width': 1024, 'height': 1024, 'layout': 'row-major unsigned bytes',
                                        'terrain_histogram': dict(counts), 'selected_fields': samples})
            report()
            return data

        position = [512, 512]

        def moves(label, count):
            # PlayScreen keeps the player centered (27,26). Prove real movement
            # by translation of native map cells, not changed AI/status pixels.
            directions = [('Right', 1, 0), ('Down', 0, 1), ('Left', -1, 0), ('Up', 0, -1)]
            successes = 0
            for attempt in range(24):
                if successes == count:
                    break
                name, dx, dy = directions[attempt % len(directions)]
                before_cells = capture(label + '-attempt-' + str(attempt) + '-before')[1]
                key(name, 'native directional movement; verify translated viewport')
                after = capture(label + '-attempt-' + str(attempt) + '-after')
                # Use the full overlap of the native map viewport, beyond
                # sight18 with a margin for up to three observed steps.
                pairs = [(x, y) for y in range(9, 45) for x in range(3, 52)
                         if (x - 27) ** 2 + (y - 26) ** 2 > 22 ** 2]
                stationary = sum(after[1][x, y] == before_cells[x, y] for x, y in pairs)
                candidates = [(sum(after[1][x, y] == before_cells[x + dx * steps, y + dy * steps]
                                   for x, y in pairs), steps) for steps in (1, 2, 3)]
                translated, steps = max(candidates, key=lambda candidate: (candidate[0], -candidate[1]))
                # Stable outer terrain beyond sight 18; moving creatures cannot
                # certify translation. Require discriminatory changed cells.
                if translated >= len(pairs) * 0.85 and translated - stationary >= 8:
                    require('@' in after[0].splitlines()[26], 'native centered player not visible')
                    successes += 1
                    position[0] += dx * steps
                    position[1] += dy * steps
                    record['moves'].append({'label': label, 'key': name, 'delta': [dx * steps, dy * steps],
                                            'translated_cells': translated, 'stationary_cells': stationary,
                                            'compared_cells': len(pairs), 'success_index': successes,
                                            'observed_world_xy': list(position)})
                    report()
            require(successes == count, 'could not prove ' + str(count) + ' native viewport moves')

        stage = 'start menu'
        expect('[N]ew', 'start')
        stage = 'New world generation'
        key('n', 'StartScreen N resets world and opens MapScreen')
        expect('World Generation:', 'worldgen')
        stage = 'confirm world generation'
        key('Return', 'MapScreen ENTER saves real generated elevation and opens CharScreen')
        expect('Character Generation', 'charactergen')
        saved = elevation('generated')
        stage = 'confirm character generation'
        key('Return', 'CharScreen ENTER creates native player and opens PlayScreen')
        expect_play('play-before-moves')
        key('F1', 'existing native PlayScreen F1 zeroes movement delay (not an injected helper)')
        stage = 'multiple native moves'
        moves('new-game', 2)
        stage = 'native Craft screen'
        key('c', 'PlayScreen C opens CraftScreen')
        expect('Craft item:', 'craft')
        key('Escape', 'CraftScreen ESC returns to play')
        expect_play('craft-back-play')
        stage = 'back to native Start screen'
        key('Escape', 'PlayScreen ESC pauses and opens StartScreen')
        expect('[C]ontinue', 'before-continue')
        elevation('before-continue')
        stage = 'Continue elevation reload'
        key('c', 'StartScreen C rereads elevation; same-process objects remain loaded')
        expect_play('same-process-continued-play')
        elevation('same-process-after-continue')
        stage = 'same-process continued native gameplay'
        moves('same-process-continued', 2)
        capture('same-process-after-continued-play')
        elevation('same-process-after-continued-play')
        stage = 'native quit before fresh-process Continue'
        key('Escape', 'PlayScreen ESC returns to StartScreen')
        expect('Save & [Q]uit', 'before-restart-quit-menu')
        key('q', 'native clean quit, preserving only previously saved elevation')
        first_code = process.wait(timeout=15)
        require(first_code == 0, 'first native quit failed')
        clean_log()
        record['first_native_exit_status'] = first_code
        stage = 'fresh-process Continue elevation reload'
        launch('continue')
        focus_native()
        expect('[C]ontinue', 'fresh-process-start')
        elevation('fresh-process-before-continue')
        key('c', 'fresh StartScreen C loads saved elevation and creates new native objects')
        expect_play('continued-play')
        position[:] = [512, 512]
        elevation('after-continue')
        # Match sampled outer-ring rendered terrain against the saved bytes.
        # Player is freshly placed at world (512,512); unseen terrain is darker
        # three times, per PlayScreen. This establishes load, not just file survival.
        _, _, backgrounds = capture('reload-terrain-verification')
        checked = []
        for x, y in [(2, 8), (52, 8), (2, 44), (52, 44), (0, 26), (54, 26)]:
            wx, wy = 512 + x - 27, 512 + y - 26
            byte = saved[wy * 1024 + wx]
            name, color = terrain(byte)
            for _ in range(3):
                color = tuple(int(channel * 0.7) for channel in color)
            require(backgrounds[x, y] == color, 'Continue pixels disagree with saved terrain at ' + str((wx, wy)))
            checked.append({'world_xy': [wx, wy], 'screen_xy': [x, y], 'byte': byte,
                            'terrain': name, 'background_rgb': list(backgrounds[x, y])})
        record['reload_terrain_selected_fields'] = checked
        key('F1', 'native movement-delay control on recreated player')
        stage = 'continued native gameplay'
        moves('continued', 2)
        capture('after-continued-play')
        elevation('after-continued-play')
        stage = 'clean native quit'
        key('Escape', 'return to StartScreen')
        expect('Save & [Q]uit', 'quit-menu')
        key('q', 'StartScreen Q clears Main.keepRunning; no save injection')
        code = process.wait(timeout=15)
        require(code == 0, 'native quit returned nonzero status ' + str(code))
        clean_log()
        record['native_exit_status'] = code
        record['runtime_transcripts'] = [path.name for path in runtime_paths]
        record['status'] = 'passed'
        record['assertions'] = ['native New/world/character/Craft/back/Continue/quit screens decoded from actual PNGs',
                                'external F1 and multiple moves before and after Continue',
                                'saved elevation bytes preserved and loaded terrain pixels match selected native fields',
                                'no native error or stacktrace in runtime transcript',
                                'read-only caller mounts/store; sameUID isolated network/HOME/XDG']
        report()
    except BaseException as error:
        record.update(status='failed', stage=stage, error=str(error), traceback=traceback.format_exc())
        report()
        print('alone-rl external GUI proof failed at ' + stage + ': ' + str(error), file=sys.stderr)
        return 1
    finally:
        stop(process)
        stop(server)
        for handle in handles:
            handle.close()
    return 0


if __name__ == '__main__':
    sys.exit(main())
