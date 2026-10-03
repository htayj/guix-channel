#!/usr/bin/env python3
"""Drive unmodified DMU character/campaign UI and inspect its own text saves."""

import ctypes
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def read_campaign(path):
    """Decode gears.pp::WriteCGears and gamebook.pp::WriteCampaign, read-only."""
    lines = iter(path.read_text().splitlines())

    def gears():
        result = []
        while True:
            header = next(lines).strip()
            if header == '-1':
                return result
            fields = list(map(int, header.split()))
            if len(fields) != 4 or fields[0] != 0:
                raise RuntimeError('invalid gear header ' + header)
            stats = next(lines).split()
            if stats[0] != 'Stats' or len(stats) % 2 != 1:
                raise RuntimeError('invalid Stats record')
            attributes = {}
            while True:
                record = next(lines).strip()
                if record == '-1':
                    break
                zero, group, slot, value = map(int, record.split())
                if zero != 0:
                    raise RuntimeError('invalid numeric attribute')
                attributes[str(group) + ':' + str(slot)] = value
            strings = []
            while True:
                record = next(lines)
                if record == 'Z':
                    break
                strings.append(record)
            result.append(dict(kind=fields[1:], stats=stats[1:], attributes=attributes,
                               strings=strings, inventory=gears(), components=gears()))

    source = gears()
    boards = []
    while True:
        width = int(next(lines))
        if width == 0:
            break
        height, identity = int(next(lines)), int(next(lines))
        if next(lines) != '*** Dungeon Monkey Unlimited Map ***':
            raise RuntimeError('invalid map header')
        channels = []
        for _ in range(3):
            channel = []
            while len(channel) < width * height:
                count, value = int(next(lines)), int(next(lines))
                if count < 0 or len(channel) + count > width * height:
                    raise RuntimeError('invalid terrain run')
                channel.extend([value] * count)
            channels.append(channel)
        visibility, value = [], False
        while len(visibility) < width * height:
            count = int(next(lines))
            if count < 0 or len(visibility) + count > width * height:
                raise RuntimeError('invalid visibility run')
            visibility.extend([value] * count)
            value = not value
        boards.append(dict(width=width, height=height, identity=identity,
                           channels=channels, visibility=visibility, contents=gears()))
    if not source or not boards:
        raise RuntimeError('saved campaign lacks source or board')
    board_id = source[0]['attributes']['16:2']
    board = next(b for b in boards if b['identity'] == board_id)
    party = [g for g in board['contents'] if g['attributes'].get('16:1') == 1]
    if len(party) != 1 or party[0]['kind'][:2] != [1, 1]:
        raise RuntimeError('saved campaign lacks real party member')
    player = party[0]
    return dict(source=source, board=board, player=player)


def position(campaign):
    return [campaign['player']['attributes']['4:1'],
            campaign['player']['attributes']['4:2']]


def continuity(campaign):
    board = campaign['board']
    return dict(source=campaign['source'], board_id=board['identity'],
                dimensions=[board['width'], board['height']], terrain=board['channels'],
                player=campaign['player'])


def main():
    if len(sys.argv) != 8:
        raise RuntimeError('usage: runner GAME ROOT XVFB XDOTOOL XWD CONVERT ARTIFACTS')
    game, root, xvfb, xdotool, xwd, convert, artifacts = sys.argv[1:]
    root, artifacts = Path(root), Path(artifacts)
    artifacts.mkdir(parents=True, exist_ok=True)
    # Retain evidence/root when hiding host /tmp, including its X11 sockets.
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    artifacts_fd = os.open(artifacts, os.O_RDONLY | os.O_DIRECTORY)
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int

    def mount(source, target, filesystem=None, flags=0):
        if libc.mount(os.fsencode(source), os.fsencode(target),
                      None if filesystem is None else os.fsencode(filesystem),
                      flags, None) != 0:
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), str(target))

    try:
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, artifacts = Path('/tmp/dmu-root'), Path('/tmp/dmu-artifacts')
        root.mkdir()
        artifacts.mkdir()
        mount('/proc/self/fd/' + str(root_fd), root, flags=4096)
        mount('/proc/self/fd/' + str(artifacts_fd), artifacts, flags=4096)
        os.mkdir('/tmp/.X11-unix', 0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
    finally:
        os.close(root_fd)
        os.close(artifacts_fd)
    for variable, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                ('TMPDIR', 'tmp')):
        os.environ[variable] = str(root / directory)
    environment = dict(os.environ, SDL_VIDEODRIVER='x11', SDL_AUDIODRIVER='dummy',
                       SDL_RENDER_DRIVER='software', LIBGL_ALWAYS_SOFTWARE='1',
                       SDL_FRAMEBUFFER_ACCELERATION='0',
                       SDL_VIDEO_X11_FORCE_EGL='0',
                       MESA_LOADER_DRIVER_OVERRIDE='llvmpipe', GALLIUM_DRIVER='llvmpipe',
                       MESA_SHADER_CACHE_DISABLE='true',
                       DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-bus'),
                       DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-system-bus'))
    state = root / 'data/dungeon-monkey-unlimited'
    save = state / 'savegame/rpg_NativeCampaign.txt'
    process = server = None
    events = []
    with open(root / 'xvfb.log', 'wb') as server_log, \
            open(root / 'game.log', 'wb') as game_log:
        try:
            read_fd, write_fd = os.pipe()
            try:
                server = subprocess.Popen(
                    [xvfb, '-displayfd', str(write_fd), '-screen', '0', '800x600x24',
                     '-nolisten', 'tcp', '-ac'], pass_fds=(write_fd,),
                    stdout=server_log, stderr=server_log, env=environment)
                os.close(write_fd)
                write_fd = None
                with os.fdopen(read_fd, 'rb') as pipe:
                    display = pipe.readline().decode().strip()
                if not display.isdecimal():
                    raise RuntimeError('Xvfb failed to allocate display')
            finally:
                if write_fd is not None:
                    os.close(write_fd)
            environment['DISPLAY'] = ':' + display

            def tool(*args):
                return subprocess.check_output(args, env=environment, timeout=10)

            def start():
                nonlocal process
                process = subprocess.Popen([game], cwd=root / 'work', env=environment,
                                           stdout=game_log, stderr=game_log)
                deadline = time.monotonic() + 20
                while time.monotonic() < deadline:
                    if process.poll() is not None:
                        raise RuntimeError('game exited before opening its window: status ' +
                                           str(process.returncode))
                    found = subprocess.run(
                        [xdotool, 'search', '--onlyvisible', '--name', '^Dungeon Monkey Unlimited$'],
                        env=environment, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                        timeout=5)
                    if found.returncode == 0:
                        window = found.stdout.decode().splitlines()[0]
                        tool(xdotool, 'windowfocus', '--sync', window)
                        tool(xdotool, 'mousemove', '--window', window, '200', '300')
                        time.sleep(0.5)
                        return window
                    time.sleep(0.1)
                raise RuntimeError('native window did not appear')

            def key(name):
                events.append(dict(key=name))
                tool(xdotool, 'key', '--clearmodifiers', name)
                time.sleep(0.25)

            def text(value):
                events.append(dict(text=value))
                tool(xdotool, 'type', '--clearmodifiers', '--delay', '80', value)
                time.sleep(1)
                capture(value + '-typed')
                # GetStringFromUser accepts ESC and returns the typed value
                # unchanged. SDL12-compat can translate Return to LF, while
                # this upstream text dialog checks only CR or ESC.
                key('Escape')

            def capture(name):
                if process.poll() is not None:
                    raise RuntimeError('game exited during ' + name)
                dump, image = artifacts / (name + '.xwd'), artifacts / (name + '.png')
                tool(xwd, '-silent', '-id', window, '-out', str(dump))
                tool(convert, str(dump), str(image))
                if tool(convert, str(image), '-format', '%wx%h', 'info:') != b'800x600':
                    raise RuntimeError('unexpected native framebuffer dimensions')
                return hashlib.sha256(tool(convert, str(image), '-depth', '8', 'rgb:-')).hexdigest()

            def snapshot(name, previous=None):
                key('shift+x')  # ExplorationMode's native SaveCampaign key.
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    if save.exists():
                        data = save.read_bytes()
                        if data and (previous is None or data != previous):
                            try:
                                campaign = read_campaign(save)
                            except (StopIteration, ValueError, KeyError):
                                time.sleep(0.1)
                                continue
                            (artifacts / (name + '.save.txt')).write_bytes(data)
                            return campaign, data
                    time.sleep(0.1)
                raise RuntimeError('native save did not complete during ' + name)

            window = start()
            menu = capture('main-menu')
            key('Return')  # Create Character.
            capture('gender')
            key('Return')  # Female.
            capture('species')
            key('Return')  # Human.
            capture('class')
            key('Up')  # Choose a legal class preceding the selected Reroll entry.
            key('Return')
            capture('avatar')
            key('Escape')  # Native avatar Done/cancel value is -1.
            capture('name-entry')
            text('NativeHero')
            character = state / 'savegame/cha_NativeHero.txt'
            if not character.is_file() or b'name <NativeHero>' not in character.read_bytes():
                saved_files = {str(path.relative_to(state)): path.read_text(errors='replace')
                               for path in state.rglob('*.txt') if path.is_file()}
                (artifacts / 'character-save-diagnostic.json').write_text(
                    json.dumps(saved_files, indent=2) + '\n')
                raise RuntimeError('character creation did not save NativeHero; files=' +
                                   repr(list(saved_files)))
            (artifacts / 'character.txt').write_bytes(character.read_bytes())
            key('Down')
            key('Down')
            key('Return')  # Start Campaign.
            time.sleep(1)
            capture('select-party')
            key('Return')  # Only one saved character, so party selection ends.
            text('NativeCampaign')
            # Intro scripts use MoreKey (SPACE/ESC), never consume turns.
            for _ in range(12):
                key('space')
            initial_frame = capture('campaign-initial')
            if initial_frame == menu:
                raise RuntimeError('campaign did not enter native world')
            initial, initial_bytes = snapshot('initial')

            def move(campaign, label):
                px, py = position(campaign)
                board = campaign['board']
                for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1)):
                    tx, ty = px + dx, py + dy
                    if not (1 <= tx <= board['width'] and 1 <= ty <= board['height']):
                        continue
                    index = tx + (ty - 1) * board['width'] - 1
                    if board['channels'][1][index] != 0:
                        continue
                    if any(g['attributes'].get('4:1') == tx and
                           g['attributes'].get('4:2') == ty for g in board['contents']):
                        continue
                    tool(xdotool, 'mousemove', '--window', window, '200', '300')
                    key('h')  # Native Center binding from uiconfig.pp.
                    # Match FocusOnTile/CheckOrigin, including edge clamping;
                    # RenderMap's floor hit diamond is at sprite origin +27,+47.
                    origin_x = max(-27 * (board['height'] - 1),
                                   min(27 * (board['width'] - 1), 27 * (px - py) - 400))
                    origin_y = max(0, min(13 * (board['width'] + board['height'] - 2),
                                          13 * (px + py - 2) - 300))
                    sx = 27 * (tx - ty) - origin_x + 27
                    sy = 13 * (tx + ty - 2) - origin_y + 47
                    events.append(dict(click=[sx, sy], destination=[tx, ty]))
                    tool(xdotool, 'mousemove', '--window', window, str(sx), str(sy))
                    time.sleep(0.2)
                    tool(xdotool, 'click', '1')
                    time.sleep(1)
                    updated, data = snapshot(label)
                    if position(updated) != [tx, ty]:
                        raise RuntimeError('native mouse move did not reach selected neighboring tile')
                    if position(updated) == position(campaign):
                        raise RuntimeError('gameplay position did not change')
                    capture(label)
                    return updated, data
                raise RuntimeError('no unoccupied adjacent walkable tile in generated hometown')

            moved, moved_bytes = move(initial, 'moved')
            key('shift+q')  # Save and return to main menu.
            time.sleep(0.5)
            key('Escape')  # Quit Game.
            if process.wait(timeout=10) != 0:
                raise RuntimeError('first native session exited unsuccessfully')
            saved = read_campaign(save)
            window = start()
            capture('relaunch-menu')
            key('Down')
            key('Return')  # Load Campaign.
            capture('load-campaign')
            key('Return')
            time.sleep(0.5)
            for _ in range(4):
                key('space')
            capture('restored')
            restored, restored_bytes = snapshot('restored')
            if continuity(restored) != continuity(saved):
                raise RuntimeError('load did not preserve source, board terrain and complete player state')
            if position(restored) != position(moved):
                raise RuntimeError('reload lost gameplay movement')
            advanced, _ = move(restored, 'advanced-after-reload')
            key('shift+q')
            time.sleep(0.5)
            key('Escape')
            if process.wait(timeout=10) != 0:
                raise RuntimeError('reloaded session exited unsuccessfully')
            report = dict(initial_position=position(initial), saved_position=position(saved),
                          restored_position=position(restored), advanced_position=position(advanced),
                          board_id=saved['board']['identity'],
                          save_sha256=hashlib.sha256(moved_bytes).hexdigest(),
                          native_save_load_continuity=True, second_session_movement=True,
                          network_namespace=True, isolated_x11=True)
            (artifacts / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
        finally:
            (artifacts / 'inputs.json').write_text(json.dumps(events, indent=2) + '\n')
            if state.exists():
                (artifacts / 'state-files.json').write_text(json.dumps(
                    [str(path.relative_to(state)) for path in state.rglob('*')], indent=2) + '\n')
            if process is not None and process.poll() is None:
                try:
                    capture('failure')
                except Exception:
                    pass
            for child in (process, server):
                if child is not None and child.poll() is None:
                    child.terminate()
                    try:
                        child.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        child.wait()
            (artifacts / 'game.log').write_bytes((root / 'game.log').read_bytes())
            server_log.flush()
            (artifacts / 'xvfb.log').write_bytes((root / 'xvfb.log').read_bytes())
    print('DMU native proof passed: created character, generated campaign, moved, saved, reloaded, moved again')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print('Dungeon Monkey native smoke: ' + str(error), file=sys.stderr)
        sys.exit(1)
