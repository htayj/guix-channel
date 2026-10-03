#!/usr/bin/env python3
"""Exercise only upstream scenes and human controls; inspect native saves externally.

No script/scene/configuration is injected into Godot. Screenshots come from its
actual X11 window; logs and saved resources provide the authoritative turn/state.
"""
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import signal
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
        # Recursively make every inherited mount read-only, not just /gnu/store.
        # mount_setattr is Linux syscall 442 on Guix's x86_64/aarch64 targets.
        mount('/', '/', flags=4096 | 16384)
        attrs = (ctypes.c_uint64 * 4)(1, 0, 0, 0)  # MOUNT_ATTR_RDONLY
        if libc.syscall(ctypes.c_long(442), ctypes.c_int(-100), ctypes.c_char_p(b'/'),
                        ctypes.c_uint(0x8000), ctypes.byref(attrs), ctypes.sizeof(attrs)):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), 'recursive read-only root')
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, evidence = Path('/tmp/revengate-root'), Path('/tmp/revengate-evidence')
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
               DBUS_SESSION_BUS_ADDRESS='unix:path=/tmp/no-session-bus',
               DBUS_SYSTEM_BUS_ADDRESS='unix:path=/tmp/no-system-bus')
    return base, env


class Session:
    def __init__(self, name, executable, evidence, base, env, tools, record):
        self.name, self.env, self.tools = name, env, tools
        self.directory = evidence / name
        self.directory.mkdir()
        self.log_path = self.directory / 'godot.log'
        self.log = self.log_path.open('wb', buffering=0)
        flags = ['--verbose', '--display-driver', 'x11', '--rendering-method', 'gl_compatibility',
                 '--audio-driver', 'Dummy', '--resolution', '1280x720', '--position', '0,0']
        self.events, self.images = [], []
        self.window = None
        self.record = {'name': name, 'arguments': flags,
                       'events': self.events, 'screenshots': self.images}
        record['sessions'].append(self.record)
        self.process = subprocess.Popen([str(executable), *flags], env=env,
                                        cwd=base / 'work', stdout=self.log, stderr=self.log,
                                        start_new_session=True)
        self.wait(lambda: self.find_window(), 'visible native Godot X11 window')
        time.sleep(2)

    def tool(self, *args, check=True):
        return subprocess.run(args, env=self.env, check=check, timeout=15,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def find_window(self):
        result = self.tool(self.tools['xdotool'], 'search', '--onlyvisible',
                           '--pid', str(self.process.pid), check=False)
        if result.returncode == 0 and result.stdout.split():
            self.window = result.stdout.split()[-1].decode()
            return True
        return False

    def text(self):
        return self.log_path.read_text(errors='replace')

    def wait(self, predicate, label, timeout=30):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            require(self.process.poll() is None, 'native game exited awaiting ' + label)
            if predicate():
                return
            time.sleep(0.1)
        if self.window:
            self.image('failure')
        raise RuntimeError('timed out awaiting ' + label + '; see ' + self.name + '/godot.log')

    def focus(self):
        self.tool(self.tools['xdotool'], 'windowfocus', '--sync', self.window)

    def click(self, x, y, label):
        self.focus()
        self.tool(self.tools['xdotool'], 'mousemove', '--window', self.window, str(x), str(y))
        self.tool(self.tools['xdotool'], 'click', '1')
        self.events.append({'click': [x, y], 'label': label, 'time_ns': time.monotonic_ns()})
        # Move pointer away from buttons to avoid hover differences in evidence.
        self.tool(self.tools['xdotool'], 'mousemove', '--window', self.window, '640', '500')

    def key(self, key):
        self.focus()
        self.tool(self.tools['xdotool'], 'key', '--clearmodifiers', key)
        self.events.append({'key': key, 'time_ns': time.monotonic_ns()})

    def image(self, name):
        path = self.directory / ('%02d-' % len(self.images) + name + '.png')
        self.tool(self.tools['import'], '-window', self.window, str(path))
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', 'native X capture is not PNG')
        width, height = struct.unpack('>II', data[16:24])
        require((width, height) == (1280, 720), 'unexpected Godot window geometry')
        self.images.append({'path': self.name + '/' + path.name,
                            'sha256': digest(data), 'width': width, 'height': height})

    def turns(self):
        return [int(value) for value in re.findall(r'^Turn (\d+) is done\.$',
                                                  self.text(), re.MULTILINE)]

    def move(self, keys=('d',)):
        previous = self.turns()
        for key in keys:
            self.key(key)
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                require(self.process.poll() is None, 'game exited during human movement')
                current = self.turns()
                if len(current) > len(previous):
                    require(current[-1] > (previous[-1] if previous else -1),
                            'human movement did not advance native turn')
                    time.sleep(0.5)
                    return current[-1]
                time.sleep(0.1)
        self.image('movement-failure')
        raise RuntimeError('no ordinary movement direction advanced a native turn')

    def save_menu(self, save_dir):
        offset = len(self.text())
        self.click(1238, 48, 'HUD GoMain: native abort_run saves and returns to menu')
        self.wait(lambda: re.search(r'^Saving at turn \d+$', self.text()[offset:], re.MULTILINE)
                  and (save_dir / 'bundle.tres').exists(), 'native main-menu save')
        time.sleep(1.5)
        self.image('saved-main-menu')
        return int(re.findall(r'^Saving at turn (\d+)$', self.text()[offset:], re.MULTILINE)[-1])

    def resume(self):
        offset = len(self.text())
        self.click(640, 386, 'Resume saved native game')
        self.wait(lambda: 'New active board, world loc is:' in self.text()[offset:]
                  and re.search(r'^=== Start of turn \d+ ===$', self.text()[offset:], re.MULTILINE),
                  'native board restoration and resumed turn queue')
        time.sleep(1)
        self.image('restored-board')
        return int(re.findall(r'^=== Start of turn (\d+) ===$',
                              self.text()[offset:], re.MULTILINE)[-1])

    def quit_menu(self):
        self.focus()
        self.tool(self.tools['xdotool'], 'mousemove', '--window', self.window, '1151', '617')
        self.tool(self.tools['xdotool'], 'click', '1')
        self.events.append({'click': [1151, 617], 'label': 'Exit Game: native get_tree().quit()',
                            'time_ns': time.monotonic_ns()})
        code = self.process.wait(timeout=15)
        self.close()
        require(code == 0, 'native Exit Game did not exit cleanly; see ' + self.name + '/godot.log')

    def close(self):
        stop(self.process)
        self.log.close()
        self.record['exit_status'] = self.process.returncode


class BinaryScene:
    """Read Godot 4 binary resources, without loading code or resolving scripts.

    Format: godotengine/godot@4.3/4.6 core/io/resource_format_binary.{cpp,h}.
    PackedScene: SceneState::get_bundled_scene in scene/resources/packed_scene.cpp.
    ResourceSaver.save() uses uncompressed RSRC; strings are NOT padded,
    unlike packed byte arrays. Resource references stay inert tuples.
    """
    def __init__(self, path):
        self.data = path.read_bytes()
        self.offset = 0
        self.strings = []
        require(self.take(4) == b'RSRC', 'native board is not an uncompressed binary resource')
        require(self.number('I') == 0, 'unsupported big-endian board resource')
        self.number('I')  # historical real64 field, ignored by Godot 4
        require(self.number('I') == 4, 'native board does not use Godot 4 resource format')
        self.number('I')  # engine minor
        require(self.number('I') in (4, 5, 6), 'unsupported binary resource format')
        require(self.string() == 'PackedScene', 'native board is not a PackedScene')
        self.number('Q')  # import metadata offset
        flags = self.number('I')
        self.real = 'd' if flags & 4 else 'f'
        self.number('Q')  # resource UID
        if flags & 8:
            self.string()  # script class name
        self.take(11 * 4)  # RESERVED_FIELDS in resource_format_binary.h
        self.strings = [self.string() for _ in range(self.number('I'))]
        self.external = []
        for _ in range(self.number('I')):
            resource = (self.string(), self.string())
            if flags & 2:
                self.number('Q')
            self.external.append(resource)
        self.internal = [(self.string(), self.number('Q')) for _ in range(self.number('I'))]

    def take(self, size):
        require(0 <= size <= len(self.data) - self.offset, 'truncated native board resource')
        data = self.data[self.offset:self.offset + size]
        self.offset += size
        return data

    def number(self, fmt):
        return struct.unpack('<' + fmt, self.take(struct.calcsize('<' + fmt)))[0]

    def string(self, size=None):
        if size is None:
            size = self.number('I')
        return self.take(size).rstrip(b'\0').decode('utf-8')

    def name(self):
        index = self.number('I')
        return self.string(index & 0x7fffffff) if index & 0x80000000 else self.strings[index]

    def variant(self):
        kind = self.number('I')
        if kind in (1, 42, 43):
            return None
        if kind == 2:
            return bool(self.number('I'))
        if kind in (3, 40, 23):
            return self.number({3: 'i', 40: 'q', 23: 'I'}[kind])
        if kind in (4, 41):
            return self.number(self.real if kind == 4 else 'd')
        if kind in (5, 44):
            return self.string()
        real_counts = {10: 2, 11: 4, 12: 3, 13: 4, 14: 4, 15: 6,
                       16: 9, 17: 12, 18: 6, 20: 4, 50: 4, 52: 16}
        int_counts = {45: 2, 46: 4, 47: 3, 51: 4}
        if kind in real_counts or kind in int_counts:
            fmt = 'i' if kind in int_counts else ('f' if kind == 20 else self.real)
            return tuple(self.number(fmt) for _ in range((int_counts | real_counts)[kind]))
        if kind == 22:
            count, subcount = self.number('H'), self.number('H')
            names = tuple(self.name() for _ in range(count + (subcount & 0x7fff)))
            return ('NodePath', bool(subcount & 0x8000), names)
        if kind == 24:
            reference = self.number('I')
            if reference == 0:
                return None
            if reference == 1:
                return ('external', self.string(), self.string())
            require(reference in (2, 3), 'unsupported binary resource reference')
            index = self.number('I')
            return ('internal', index) if reference == 2 else ('external', self.external[index])
        if kind in (26, 30):
            count = self.number('I') & 0x7fffffff
            if kind == 30:
                return [self.variant() for _ in range(count)]
            pairs = []
            for _ in range(count):
                key = self.variant()
                pairs.append((key, self.variant()))
            # Dictionary keys can themselves be arrays/Vector2i; preserve them
            # without pretending arbitrary Godot variants are Python hashable.
            return dict(pairs) if all(isinstance(k, str) for k, _ in pairs) else ('Dictionary', pairs)
        if kind == 31:
            size = self.number('I')
            result = self.take(size)
            self.take((-size) % 4)
            return result
        if kind == 34:
            return [self.string() for _ in range(self.number('I'))]
        packed = {32: ('i', 1), 33: ('f', 1), 35: (self.real, 3),
                  36: ('f', 4), 37: (self.real, 2), 48: ('q', 1),
                  49: ('d', 1), 53: (self.real, 4)}
        require(kind in packed, 'unsupported binary native save variant %d' % kind)
        fmt, width = packed[kind]
        count = self.number('I')
        values = [self.number(fmt) for _ in range(count * width)]
        return values if width == 1 else [tuple(values[i:i + width]) for i in range(0, len(values), width)]

    def bundled(self):
        # The saved scene is the final internal resource; its dependencies may
        # include many local Resource instances as well as external scripts.
        self.offset = self.internal[-1][1]
        require(self.string() == 'PackedScene', 'last resource is not saved board scene')
        properties = {}
        for _ in range(self.number('I')):
            name = self.strings[self.number('I')]
            properties[name] = self.variant()
        require('_bundled' in properties, 'saved PackedScene missing _bundled')
        return properties['_bundled']


def board_state(path):
    bundled = BinaryScene(path).bundled()
    require(bundled.get('version') == 3, 'unsupported native PackedScene version')
    names, values, raw = bundled['names'], bundled['variants'], bundled['nodes']
    offset, nodes = 0, []
    for _ in range(bundled['node_count']):
        parent, owner, node_type, node_name, instance = raw[offset:offset + 5]
        offset += 5
        count = raw[offset]
        offset += 1
        props = {}
        for _ in range(count):
            key, value = raw[offset:offset + 2]
            offset += 2
            props[names[key & 0x3fffffff]] = values[value & 0x3fffffff]
        count = raw[offset]
        offset += 1 + count  # groups
        nodes.append((names[node_name & 0xffff], props))
    require(offset == len(raw), 'native scene node records have trailing or missing data')
    heroes = [props for name, props in nodes if name == 'Hero']
    require(len(heroes) == 1 and 'position' in heroes[0], 'saved board has no unambiguous Hero position')
    tiles = [props['tile_map_data'] for _, props in nodes if 'tile_map_data' in props]
    # TileMapLayer::get_tile_map_data_as_array writes a uint16 version header,
    # followed by 12 bytes per cell (Godot 4.6 scene/2d/tile_map_layer.cpp).
    require(tiles and all(isinstance(data, bytes) and len(data) > 2
                         and (len(data) - 2) % 12 == 0 for data in tiles),
            'saved board lacks complete versioned native 12-byte terrain cells')
    root = nodes[0][1]
    return {'hero_position': list(heroes[0]['position']),
            'hero_dest': list(heroes[0].get('dest', (-1, -1))),
            'board_id': root.get('board_id'), 'size': root.get('size'),
            'world_loc': root.get('world_loc'), 'dungeon_name': root.get('dungeon_name'),
            # Godot can reorder TileMap serialization after load. Compare the
            # set of native 12-byte cell records rather than incidental order.
            'terrain_sha256': sorted(digest(data[:2] + b''.join(sorted(data[i:i + 12]
                for i in range(2, len(data), 12)))) for data in tiles)}


def bundle_state(save_dir):
    text = (save_dir / 'bundle.tres').read_text()
    def integer(name):
        match = re.search(r'^' + name + r' = (-?\d+)$', text, re.MULTILINE)
        require(match is not None, 'native save bundle missing ' + name)
        return int(match[1])
    return {'turn': integer('turn'), 'active_board_id': integer('active_board_id'),
            'start_board_id': integer('start_board_id')}


def save_snapshot(save_dir, evidence, name):
    state = bundle_state(save_dir)
    board_path = save_dir / ('board-%d.scn' % state['active_board_id'])
    require(board_path.is_file(), 'saved active board missing')
    target = evidence / name
    target.mkdir()
    state['files'] = []
    for path in sorted(save_dir.iterdir()):
        if path.is_file():
            data = path.read_bytes()
            shutil.copy2(path, target / path.name)
            state['files'].append({'path': name + '/' + path.name,
                                   'bytes': len(data), 'sha256': digest(data)})
    state['board'] = board_state(target / board_path.name)
    (target / 'state.json').write_text(json.dumps(state, indent=2) + '\n')
    return state


def main():
    output, scratch, xvfb, xdotool, image_import, artifacts, nar = sys.argv[1:]
    output, root, evidence = map(Path, (output, scratch, artifacts))
    record = {'status': 'running', 'consumer': 'unmodified Godot scenes and native X11 human input',
              'upstream_commit': '21b0cb49a84a1fada7e171064b68f1183818c32c',
              'output': str(output), 'output_nar_before': nar,
              'sessions': [], 'assertions': [], 'saves': {}}
    server = simulation = session = None
    server_log = simulation_log = None

    def report():
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')

    report()
    try:
        root, evidence = isolate(root, evidence)
        record['isolation'] = ('offline user/mount/network/PID namespaces; recursively read-only '
                               'root and output; private writable scratch/evidence/tmp; '
                               'separate fresh simulation and graphical HOME/XDG')
        executable = output / 'bin/revengate'
        sim_base, sim_env = fresh_environment(root, 'simulation')
        flags = ['--headless', '--scene', 'src/combat/combat_sim.tscn']
        record['simulation'] = {'arguments': flags, 'log': 'combat-simulation.log'}
        simulation_log = (evidence / 'combat-simulation.log').open('wb')
        simulation = subprocess.Popen([str(executable), *flags], env=sim_env,
                                      cwd=sim_base / 'work', stdout=simulation_log,
                                      stderr=simulation_log, start_new_session=True)
        code = simulation.wait(timeout=1500)
        simulation_log.close()
        simulation_log = None
        text = (evidence / 'combat-simulation.log').read_text(errors='replace')
        record['simulation'].update(exit_status=code, done_marker=bool(re.search(r'^Done!$', text, re.MULTILINE)))
        record['simulation']['errors'] = re.findall(r'^(?:SCRIPT ERROR|ERROR):.*$', text, re.MULTILINE)
        require(not record['simulation']['errors'], 'upstream combat scene reported Godot errors; see combat-simulation.log')
        require(code == 0 and record['simulation']['done_marker'], 'upstream combat simulation did not finish with Done!')
        record['assertions'].append('legitimate upstream combat scene completes independently with Done!')
        base, env = fresh_environment(root, 'graphical')
        require(not list((base / 'data').iterdir()) and not list((base / 'home').iterdir()),
                'graphical game does not have fresh user state')
        server_log = (evidence / 'xvfb.log').open('wb')
        read_fd, write_fd = os.pipe()
        try:
            server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                       '1280x720x24', '-nolisten', 'tcp', '-ac'],
                                      pass_fds=(write_fd,), stdout=server_log, stderr=server_log,
                                      env=env, start_new_session=True)
            os.close(write_fd)
            write_fd = None
            require(select.select([read_fd], [], [], 15)[0], 'Xvfb allocation timed out')
            display = os.read(read_fd, 128).decode().strip()
            require(display.isdecimal(), 'Xvfb failed to allocate display')
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
        env['DISPLAY'] = ':' + display
        tools = {'xdotool': xdotool, 'import': image_import}
        save_dir = base / 'data/Revengate/saves/current'
        session = Session('new-game', executable, evidence, base, env, tools, record)
        session.image('initial-main-menu')
        session.click(640, 325, 'New Game through native main menu')
        session.wait(lambda: 'New active board, world loc is:' in session.text(), 'new native board')
        time.sleep(1)
        session.image('chapter-story')
        session.click(640, 695, 'Next: dismiss native chapter story')
        time.sleep(1)
        session.image('initial-board')
        first_turn = session.move()
        session.image('after-human-movement')
        saved_turn = session.save_menu(save_dir)
        saved = save_snapshot(save_dir, evidence, 'first-save')
        record['saves']['first'] = saved
        require(saved['turn'] == saved_turn and saved_turn >= first_turn,
                'save bundle turn disagrees with native save log')
        require(saved['board']['hero_position'] == [144.0, 48.0],
                'one human east move did not save Hero at adjacent corridor cell (4,1)')
        require(saved['board']['board_id'] == saved['active_board_id'],
                'native board resource identity disagrees with bundle')
        session.quit_menu()
        session = None
        # Entire game process is restarted before clicking native Resume.
        session = Session('restored-game', executable, evidence, base, env, tools, record)
        session.image('restart-main-menu')
        resumed_turn = session.resume()
        require(resumed_turn == saved_turn, 'restart/resume did not restore queue turn')
        restored_turn = session.save_menu(save_dir)
        restored = save_snapshot(save_dir, evidence, 'restored-save')
        record['saves']['restored'] = restored
        # Native abort_run shuts down with skip_turn(true), so returning to the
        # main menu completes the interrupted turn and increments the queue.
        require(restored_turn == saved_turn + 1 and restored['turn'] == restored_turn,
                'main-menu resave did not complete exactly the interrupted restored turn')
        require(restored['active_board_id'] == saved['active_board_id']
                and restored['start_board_id'] == saved['start_board_id']
                and restored['board'] == saved['board'],
                'native restart/resume changed saved board or Hero state')
        record['assertions'].append('process restart/resume restores saved queue turn, active/start board, terrain and Hero position')
        require(session.resume() == restored_turn, 'second Resume changed saved queue turn')
        continued_turn = session.move()
        require(continued_turn == restored_turn, 'first completed resumed turn does not match restored queue turn')
        session.image('continued-human-movement')
        continued_save_turn = session.save_menu(save_dir)
        continued = save_snapshot(save_dir, evidence, 'continued-save')
        record['saves']['continued'] = continued
        require(continued_save_turn > saved_turn and continued['turn'] == continued_save_turn,
                'resumed input did not continue saved native turn sequence')
        require(continued['board']['hero_position'] == [176.0, 48.0],
                'one resumed east move did not save Hero at adjacent corridor cell (5,1)')
        record['assertions'].append('ordinary movement after resume changes Hero position and advances saved turns')
        session.quit_menu()
        session = None
        record['assertions'].append('both game processes exit zero through the native Exit Game button')
        state_target = evidence / 'native-user-state'
        shutil.copytree(base / 'data/Revengate', state_target)
        record['native_user_state'] = sorted(str(p.relative_to(evidence)) for p in state_target.rglob('*') if p.is_file())
        record['graphical_errors'] = {}
        for item in record['sessions']:
            text = (evidence / item['name'] / 'godot.log').read_text(errors='replace')
            errors = re.findall(r'^(?:SCRIPT ERROR|ERROR):.*$', text, re.MULTILINE)
            record['graphical_errors'][item['name']] = errors
            require(not errors, 'native graphical game reported Godot errors; see ' + item['name'] + '/godot.log')
        record['status'] = 'passed'
        print('REVENGATE-SMOKE: upstream-combat-native-x11-movement-save-restart-resume-ok')
    except Exception as error:
        record.update(status='failed', error=str(error), traceback=traceback.format_exc())
        raise
    finally:
        if session is not None:
            session.close()
        stop(simulation)
        stop(server)
        if simulation_log is not None:
            simulation_log.close()
        if server_log is not None:
            server_log.close()
        report()


if __name__ == '__main__':
    main()
