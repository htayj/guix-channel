#!/usr/bin/env python3
"""Ordinary SDL1.2 input/save/restore consumer for Cracks and Crevices 0.5.

The oracle is the recovered 0.5 archive (SHA256
 a00cf6ab0a189673fe152f9325b14c1a6b6a531a8510d1cc321c44ccdeb9fb66):
main.c, keyboard.c, map00.c, save.c, memhandle.c, global.c, pcode.h,
actor.h and fuzion.h. Only XTest keyboard input enters the application.
Screens are native XGetImage captures, not a replacement game renderer.
Save decoding is read-only and occurs after native exit. Never seed the RNG,
write configuration/save data, import game code, or use engine hooks.
"""
import ctypes as C
import hashlib
import json
import os
from pathlib import Path
import re
import select
import stat
import struct
import subprocess
import sys
import time
import traceback
import zlib

SOURCE_SHA256 = 'a00cf6ab0a189673fe152f9325b14c1a6b6a531a8510d1cc321c44ccdeb9fb66'
SOURCE_URL = ('https://web.archive.org/web/20150804175538if_/'
              'https://redmine.bloodycactus.com/attachments/download/32/'
              'cracks_and_crevices-0.5.tar.bz2')


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def namespace_proof(proc, target):
    receipt = {}
    for kind, key in [('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                      ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')]:
        value = os.readlink(proc / 'ns' / kind)
        require(value != os.environ[key], 'host namespace leaked: ' + kind)
        require(value == os.readlink('/proc/self/ns/' + kind), 'namespace escaped: ' + kind)
        receipt[kind] = value
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            identity[key] = [int(x) for x in value.split()]
    for kind, key in [('Uid', 'HOST_UID'), ('Gid', 'HOST_GID')]:
        require(identity[kind] == [int(os.environ[key])] * 4, 'caller identity changed')
    for name, key in [('uid_map', 'HOST_UID'), ('gid_map', 'HOST_GID')]:
        mapping = (proc / name).read_text()
        require([int(x) for x in mapping.split()] ==
                [int(os.environ[key]), int(os.environ[key]), 1], 'not map-current-user')
        receipt[name] = mapping
    dev = (proc / 'net/dev').read_text()
    route = (proc / 'net/route').read_text()
    ipv6_route = (proc / 'net/ipv6_route').read_text()
    interfaces = sorted(line.split(':')[0].strip() for line in dev.splitlines()[2:]
                        if ':' in line)
    require(interfaces == ['lo'], 'external network interface present')
    require(not route.splitlines()[1:], 'IPv4 route present')
    require(all(line.split()[-1] == 'lo' for line in ipv6_route.splitlines()),
            'external IPv6 route present')
    receipt.update(identity=identity, interfaces=interfaces, net_dev=dev,
                   net_route=route, ipv6_route=ipv6_route)
    write_json(target, receipt)
    return receipt


def isolate_store(evidence):
    commands = []

    def mount(*args):
        command = [os.environ['MOUNT'], *args]
        result = subprocess.run(command, capture_output=True, text=True, timeout=15)
        commands.append(dict(command=command, returncode=result.returncode,
                             stdout=result.stdout, stderr=result.stderr))
        write_json(evidence / 'mount-commands.json', commands)
        require(result.returncode == 0, 'mount failed: ' + result.stderr)

    def entries():
        text = Path('/proc/self/mountinfo').read_text()
        found = []
        for line in text.splitlines():
            fields = line.split()
            target = fields[4]
            for escaped, literal in [('\\040', ' '), ('\\011', '\t'),
                                     ('\\012', '\n'), ('\\134', '\\')]:
                target = target.replace(escaped, literal)
            if target == '/gnu/store' or target.startswith('/gnu/store/'):
                found.append((target, fields[5].split(','), fields[6:fields.index('-')]))
        return text, found

    (evidence / 'mountinfo-before.txt').write_text(entries()[0])
    mount('--rbind', '/gnu/store', '/gnu/store')
    mount('--make-rprivate', '/gnu/store')
    targets = sorted({item[0] for item in entries()[1]}, key=len, reverse=True)
    require('/gnu/store' in targets, 'store recursive bind missing')
    for target in targets:
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    require(found and all('ro' in options and 'rw' not in options and
                         not any(x.startswith(('shared:', 'master:')) for x in optional)
                         for _, options, optional in found), 'store is not recursive private RO')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store statvfs is writable')
    (evidence / 'mountinfo-store-readonly.txt').write_text(text)
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        source = '/proc/' + str(os.getpid()) + '/fd/' + str(descriptor)
        # The mount helper writes its receipt after the syscall: anchor the
        # evidence NOW, before /tmp can hide the caller's original path.
        evidence = Path(source)
        mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/tmp')
        retained = Path('/tmp/cracks-evidence')
        retained.mkdir(mode=0o700)
        mount('--bind', source, str(retained))
        evidence = retained
    finally:
        os.close(descriptor)
    mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/run')
    (evidence / 'mountinfo-isolated.txt').write_text(Path('/proc/self/mountinfo').read_text())
    return evidence, dict(recursive_readonly=True, store_mounts=found,
                          private_tmp=True, private_run=True)


class XImage(C.Structure):
    _fields_ = [('width', C.c_int), ('height', C.c_int), ('xoffset', C.c_int),
                ('format', C.c_int), ('data', C.c_void_p), ('byte_order', C.c_int),
                ('bitmap_unit', C.c_int), ('bitmap_bit_order', C.c_int),
                ('bitmap_pad', C.c_int), ('depth', C.c_int),
                ('bytes_per_line', C.c_int), ('bits_per_pixel', C.c_int),
                ('red_mask', C.c_ulong), ('green_mask', C.c_ulong), ('blue_mask', C.c_ulong)]


class Capture:
    def __init__(self, display):
        self.lib = C.CDLL(os.environ['LIBX11'])
        for name, args, result in [
                ('XOpenDisplay', [C.c_char_p], C.c_void_p),
                ('XGetImage', [C.c_void_p, C.c_ulong, C.c_int, C.c_int,
                               C.c_uint, C.c_uint, C.c_ulong, C.c_int], C.c_void_p),
                ('XDestroyImage', [C.c_void_p], C.c_int),
                ('XCloseDisplay', [C.c_void_p], C.c_int)]:
            function = getattr(self.lib, name)
            function.argtypes, function.restype = args, result
        self.display = self.lib.XOpenDisplay(display.encode())
        require(self.display, 'cannot open private display')

    def png(self, window, path, width=960, height=480):
        image = self.lib.XGetImage(self.display, window, 0, 0, width, height,
                                   C.c_ulong(-1).value, 2)
        require(image, 'native XGetImage failed')
        try:
            header = C.cast(image, C.POINTER(XImage)).contents
            require((header.depth, header.bits_per_pixel, header.byte_order,
                     header.red_mask, header.green_mask, header.blue_mask) ==
                    (24, 32, 0, 0xff0000, 0xff00, 0xff), 'unexpected Xvfb format')
            raw = C.string_at(header.data, header.bytes_per_line * height)
            rgb = bytearray(width * height * 3)
            for y in range(height):
                row = raw[y * header.bytes_per_line:y * header.bytes_per_line + width * 4]
                offset = y * width * 3
                rgb[offset:offset + width * 3:3] = row[2::4]
                rgb[offset + 1:offset + width * 3:3] = row[1::4]
                rgb[offset + 2:offset + width * 3:3] = row[0::4]
            require(len(set(rgb)) > 2, 'native capture is blank')
            rows = b''.join(b'\0' + rgb[y * width * 3:(y + 1) * width * 3]
                            for y in range(height))

            def chunk(kind, body):
                return (struct.pack('>I', len(body)) + kind + body +
                        struct.pack('>I', zlib.crc32(kind + body)))

            path.write_bytes(b'\x89PNG\r\n\x1a\n' +
                             chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) +
                             chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))
            return dict(file=path.name, width=width, height=height,
                        rgb_sha256=hashlib.sha256(rgb).hexdigest(),
                        png_sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        finally:
            self.lib.XDestroyImage(image)

    def close(self):
        self.lib.XCloseDisplay(self.display)


def decode_save(data):
    """Decode only real post-exit files; no executable deserialization.

    memhandle.c dumps size+4 bytes starting at the allocation (the extra four
    bytes are TRAILING slack). global.h uses direct enum indices, not offsets.
    data.h resets #pragma pack at line 203 before actor/journal headers;
    only Level/ITEM are packed. mhdlist.h uses natural pointer alignment.
    """
    require(C.sizeof(C.c_void_p) == 8 and C.sizeof(C.c_int) == 4,
            'save oracle requires the supported LP64 native build')
    magic = struct.pack('=I', 0xDEADBEEF)
    require(data[:4] == magic and data[-8:] == magic * 2, 'save magic/trailer differs')
    records = {}
    cursor = 4
    while cursor < len(data) - 8:
        require(cursor + 8 <= len(data) - 8, 'truncated record header')
        size, handle = struct.unpack_from('=II', data, cursor)
        cursor += 8
        require(size > 0 and cursor + size + 4 <= len(data) - 8,
                'invalid native heap record length')
        require(handle not in records, 'duplicate native heap handle')
        records[handle] = data[cursor:cursor + size]
        cursor += size + 4
    require(cursor == len(data) - 8, 'native save framing differs')

    def record(handle, size=None):
        require(handle in records, 'missing referenced heap handle: ' + str(handle))
        value = records[handle]
        require(size is None or len(value) == size, 'native record ABI size differs')
        return value

    handles = struct.unpack('=14I', record(1, 56))
    record(0, 36)
    variables = struct.unpack('=410i', record(handles[3], 1640))
    # ITEM: header 124 bytes + 8 item_info records of 12 = 220 bytes;
    # Actor: 96-byte prefix + 16*220 inventory + 36-byte tail = 3652.
    player = record(handles[8], 3652)
    actor_type, tile, colour, gold, level, xp = struct.unpack_from('=iiIiii', player, 68)
    require(actor_type == 0 and tile == ord('@'), 'saved G_PLAYER is not native human player')

    def walk(handle):
        head, tail, count = struct.unpack_from('=IIi', record(handle, 24))
        require(0 <= count <= len(records), 'invalid saved list size')
        result, seen = [], set()
        previous = 0xffffffff
        while head != 0xffffffff:
            require(head not in seen, 'cycle in saved handle list')
            seen.add(head)
            prev, following, value = struct.unpack('=III', record(head, 12))
            require(prev == previous, 'saved list backlink differs')
            result.append(record(value))
            previous, head = head, following
        require(len(result) == count and (not count or previous == tail),
                'saved list length/tail differs')
        return result

    levels = []
    current_name = None
    for raw in walk(handles[4]):
        require(len(raw) == 34, 'packed Level ABI differs')
        ident, width, height, map_handle, name_handle = struct.unpack_from('=HHHII', raw)
        name = record(name_handle).split(b'\0', 1)[0].decode('ascii')
        map_data = record(map_handle, width * height * 2)
        levels.append(dict(id=ident, width=width, height=height, name=name,
                           terrain_sha256=hashlib.sha256(map_data[::2]).hexdigest()))
        if ident == variables[1]:
            current_name = name
    require(variables[1] == 1 and current_name == 'Danforths Outcrop',
            'native town map was not retained')
    journal = []
    for raw in walk(handles[9]):
        require(len(raw) == 24, 'native journal ABI differs')
        kind = raw[0]
        moves, minute, hour, day, month, year = struct.unpack_from('=IBBBBH', raw, 4)
        journal.append(dict(type=kind, moves=moves, minute=minute, hour=hour,
                            day=day, month=month, year=year, data_hex=raw[16:].hex()))
    saved_entries = sorted((entry for entry in journal if entry['type'] == 7),
                           key=lambda entry: entry['moves'])
    require(saved_entries and saved_entries[-1]['moves'] == variables[406],
            'native save journal does not agree with move count')
    return dict(byte_order=sys.byteorder, record_count=len(records),
                player_handle=handles[8], current_map=variables[1], map_name=current_name,
                player_row=variables[2], player_col=variables[3], facing=variables[5],
                hours=variables[6], minutes=variables[7], days=variables[8],
                months=variables[9], years=variables[10], move_count=variables[406],
                tick_count=variables[407], skill_level=variables[409],
                gold=gold, actor_level=level, experience=xp,
                base_stats=list(struct.unpack_from('=7h', player, 20)),
                skills=list(struct.unpack_from('=9h', player, 48)),
                inventory_sha256=hashlib.sha256(player[96:3616]).hexdigest(),
                levels=sorted(levels, key=lambda entry: entry['id']),
                journal=journal, saved_entries=saved_entries)


def assert_continuity(previous, current):
    for field in ['player_handle', 'current_map', 'map_name', 'gold', 'actor_level',
                  'experience', 'base_stats', 'skills', 'inventory_sha256', 'levels',
                  'days', 'months', 'years', 'skill_level']:
        require(previous[field] == current[field], 'restore lineage differs: ' + field)
    require(current['move_count'] >= previous['move_count'] + 3,
            'restored movement/rest/save did not advance ordinary input turns')
    require(current['tick_count'] >= previous['tick_count'], 'restored play ticks went backwards')
    require(current['hours'] * 60 + current['minutes'] >
            previous['hours'] * 60 + previous['minutes'], 'restored game clock did not advance')
    require(len(current['saved_entries']) == len(previous['saved_entries']) + 1,
            'restored save journal did not grow')
    require(current['saved_entries'][:-1] == previous['saved_entries'],
            'prior native save journal history lost on restore')


def main():
    output, evidence = map(Path, sys.argv[1:])
    proof = dict(status='failed', version='0.5 / build 757', source_url=SOURCE_URL,
                 source_sha256=SOURCE_SHA256, inputs=[], captures=[], processes=[], saves=[])
    children = []
    handles = []
    capture = None
    initial_evidence = evidence

    def persist():
        write_json(evidence / 'runtime.json', proof)

    try:
        require(os.getuid() != 0, 'native game rejects root')
        require(output.resolve() == output and output.parent == Path('/gnu/store'),
                'OUTPUT not canonical direct store item')
        launcher = output / 'bin/cracks-and-crevices'
        proof['installed_executable'] = dict(entry=str(launcher), resolved=str(launcher.resolve()),
                                             sha256=hashlib.sha256(launcher.read_bytes()).hexdigest())
        require(os.access(launcher, os.X_OK), 'ordinary installed executable missing')
        for path in [output, *output.rglob('*')]:
            mode = path.lstat().st_mode
            if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
                require(not mode & 0o222, 'writable store member: ' + str(path))
        proof['observer_namespace'] = namespace_proof(Path('/proc/self'), evidence / 'namespace-observer.json')
        evidence, proof['mounts'] = isolate_store(evidence)
        work = evidence / 'private'
        for name in ['home', 'state', 'config', 'cache', 'data', 'runtime', 'tmp', 'work']:
            (work / name).mkdir(parents=True, mode=0o700)
        state = work / 'state/cracks-and-crevices'
        save_path = state / 'save.bin'
        env = dict(LC_ALL='C', PATH='', HOME=str(work / 'home'),
                   XDG_STATE_HOME=str(work / 'state'), XDG_CONFIG_HOME=str(work / 'config'),
                   XDG_CACHE_HOME=str(work / 'cache'), XDG_DATA_HOME=str(work / 'data'),
                   XDG_RUNTIME_DIR=str(work / 'runtime'), TMPDIR=str(work / 'tmp'),
                   SDL_VIDEODRIVER='x11', SDL_AUDIODRIVER='dummy')
        # Established native-consumer convention: no host/session bus exists
        # in this proof. Explicit private non-existent endpoints prevent SDL's
        # optional D-Bus client from autolaunching a bus and writing HOME.
        env['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=' + str(work / 'runtime/no-session')
        env['DBUS_SYSTEM_BUS_ADDRESS'] = 'unix:path=' + str(work / 'runtime/no-system')
        proof['environment'] = env.copy()
        read_fd, write_fd = os.pipe()
        log = (evidence / 'xvfb.log').open('wb')
        handles.append(log)
        server = subprocess.Popen([os.environ['XVFB'], '-displayfd', str(write_fd),
                                   '-screen', '0', '1280x960x24', '-nolisten', 'tcp', '-ac'],
                                  pass_fds=(write_fd,), stdout=log, stderr=log, env=env)
        children.append(server)
        os.close(write_fd)
        try:
            require(select.select([read_fd], [], [], 15)[0], 'Xvfb readiness timed out')
            number = os.read(read_fd, 64).decode().strip()
            require(number.isdigit(), 'invalid Xvfb displayfd result')
        finally:
            os.close(read_fd)
        env['DISPLAY'] = ':' + number
        capture = Capture(env['DISPLAY'])
        proof['xvfb_namespace'] = namespace_proof(Path('/proc') / str(server.pid), evidence / 'namespace-xvfb.json')

        def xdo(*args, check=True):
            command = [os.environ['XDOTOOL'], *map(str, args)]
            result = subprocess.run(command, capture_output=True, text=True, env=env, timeout=10)
            with (evidence / 'xdotool.jsonl').open('a') as stream:
                stream.write(json.dumps(dict(command=command, returncode=result.returncode,
                                             stdout=result.stdout, stderr=result.stderr)) + '\n')
            if check:
                require(result.returncode == 0, 'xdotool failed: ' + result.stderr)
            return result

        def wait_for(test, message, app=None, timeout=15):
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                if test():
                    return
                if app is not None:
                    require(app.poll() is None, 'game exited early while ' + message)
                time.sleep(0.05)
            raise AssertionError(message + ' timed out')

        def snapshot(window, label):
            require(xdo('getwindowgeometry', '--shell', window).stdout.find('WIDTH=960') >= 0,
                    'native window width differs')
            receipt = capture.png(window, evidence / (label + '.png'))
            proof['captures'].append(receipt)
            persist()
            return receipt['rgb_sha256']

        def key(app, window, value):
            require(app.poll() is None, 'game exited before ordinary input')
            receipt = dict(pid=app.pid, window=window, keysym=value, time=time.monotonic())
            proof['inputs'].append(receipt)
            with (evidence / 'inputs.jsonl').open('a') as stream:
                stream.write(json.dumps(receipt) + '\n')
            xdo('key', '--clearmodifiers', value)
            time.sleep(0.18)

        def native_log(label):
            return (evidence / (label + '.stderr')).read_text(errors='replace')

        def launch(label, restoring):
            if restoring:
                require(save_path.is_file(), 'native save missing before restore')
                restore_sha256 = hashlib.sha256(save_path.read_bytes()).hexdigest()
                require(restore_sha256 == proof['saves'][-1]['sha256'],
                        'native saved file changed before independent restore')
            else:
                require(not state.exists(), 'initial game state is not fresh')
            stdout = (evidence / (label + '.stdout')).open('wb')
            stderr = (evidence / (label + '.stderr')).open('wb')
            handles.extend([stdout, stderr])
            command = [str(launcher), '-width', '960', '-height', '480', '-font', 'small']
            app = subprocess.Popen(command, cwd=work / 'work', env=env,
                                   stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
            children.append(app)
            holder = []

            def window_ready():
                result = xdo('search', '--onlyvisible', '--pid', app.pid, check=False)
                if result.returncode == 0 and result.stdout.strip():
                    holder[:] = [int(result.stdout.splitlines()[0])]
                    return True
                return False

            wait_for(window_ready, 'native SDL window', app)
            window = holder[0]
            xdo('windowfocus', '--sync', window)
            proc = Path('/proc') / str(app.pid)
            record = dict(label=label, pid=app.pid, command=command,
                          exe=os.readlink(proc / 'exe'),
                          cmdline=(proc / 'cmdline').read_bytes().replace(b'\0', b' ').decode(),
                          environment=(proc / 'environ').read_bytes().replace(b'\0', b'\n').decode(),
                          maps=(proc / 'maps').read_text(),
                          namespace=namespace_proof(proc, evidence / ('namespace-' + label + '.json')))
            require(Path(record['exe']).resolve() == launcher.resolve(), 'unexpected native process image')
            require('libSDL' in record['maps'], 'ordinary native process did not load SDL')
            proof['processes'].append(record)
            if restoring:
                wait_for(lambda: not save_path.exists() and 'reloading player' in native_log(label),
                         'native save consumed and player restored', app)
                require('Loading from ' in native_log(label), 'no native restore record')
                record['restore'] = dict(consumed_save_sha256=restore_sha256,
                                         native_save_deleted=True,
                                         native_player_rebound=True)
                time.sleep(0.3)
                snapshot(window, label + '-restored')
            else:
                time.sleep(0.3)
                snapshot(window, label + '-menu')
                key(app, window, 'e')
                time.sleep(1.0)
                snapshot(window, label + '-shop')
                key(app, window, 'l')
                time.sleep(0.3)
                snapshot(window, label + '-birth')
            persist()
            return app, window

        def finish(app, window, label, saving):
            key(app, window, 'shift+s' if saving else 'shift+q')
            if saving:
                wait_for(lambda: save_path.is_file() and save_path.stat().st_size > 8,
                         'ordinary save created', app)
            snapshot(window, label + ('-saved-prompt' if saving else '-quit-prompt'))
            key(app, window, 'space')
            status = app.wait(timeout=15)
            proof['processes'][-1].update(returncode=status, natural_exit=True)
            require(status == 0, 'native process did not exit successfully')
            text = native_log(label)
            require(not re.search(r'(?m)^\S+\.c\(\d+\)\s*:', text),
                    'native LogError reported: ' + text)
            require(not re.search(r'(?i)assertion|segmentation fault|could not|unable to|error in save|cant remove', text),
                    'native runtime error: ' + text)
            if saving:
                require('saving to ' in text, 'native save call absent')
                data = save_path.read_bytes()
                retained = evidence / (label + '-save.bin')
                retained.write_bytes(data)
                fields = decode_save(data)
                fields.update(file=retained.name, sha256=hashlib.sha256(data).hexdigest())
                proof['saves'].append(fields)
                write_json(evidence / (label + '-save.json'), fields)
            persist()

        # map00.c:73 native birth=(21,17); map00.c:399/398/397 safe public
        # corridor. No merchants, doors, combat, RNG outcome or injected state.
        scenarios = [('first', 'Left', (21, 16)), ('second', 'Left', (21, 15)),
                     ('third', 'Up', (20, 15))]
        for index, (label, movement, position) in enumerate(scenarios):
            app, window = launch(label, index != 0)
            before_screen = snapshot(window, label + '-before-move')
            key(app, window, movement)
            after_screen = snapshot(window, label + '-after-move')
            require(before_screen != after_screen, 'movement did not change native screen')
            key(app, window, 'period')
            snapshot(window, label + '-after-rest')
            finish(app, window, label, True)
            current = proof['saves'][-1]
            require((current['player_row'], current['player_col']) == position,
                    'ordinary movement save position differs')
            require(current['move_count'] >= 3, 'no ordinary movement/rest/save inputs recorded')
            require(current['skill_level'] == 3000 and
                    len(current['saved_entries']) == index + 1,
                    'native easy-game save journal lineage differs')
            if index:
                previous = proof['saves'][-2]
                assert_continuity(previous, current)
            persist()
        app, window = launch('final', True)
        key(app, window, 'Down')
        key(app, window, 'period')
        snapshot(window, 'final-continued')
        finish(app, window, 'final', False)
        require(not save_path.exists(), 'final quit unexpectedly retained save')
        dump = state / 'chardump.txt'
        require(dump.is_file(), 'ordinary quit character dump absent')
        text = dump.read_text()
        require(text.count('You saved your game') >= 3, 'restored journal lineage lost')
        (evidence / 'final-chardump.txt').write_bytes(dump.read_bytes())
        proof['final_dump_sha256'] = hashlib.sha256(dump.read_bytes()).hexdigest()
        final_clock = re.search(r'The time was\s+(\d+):(\d+)(AM|PM)', text)
        require(final_clock, 'final native dump clock absent')
        hour, minute = map(int, final_clock.groups()[:2])
        hour = hour % 12 + (12 if final_clock.group(3) == 'PM' else 0)
        require(hour * 60 + minute >
                proof['saves'][-1]['hours'] * 60 + proof['saves'][-1]['minutes'],
                'final independently restored game did not continue turns')
        proof['final_clock'] = dict(hours=hour, minutes=minute)
        require(not list((work / 'home').iterdir()), 'game wrote legacy HOME state')
        require(stat.S_IMODE(state.stat().st_mode) == 0o700, 'private state permissions differ')
        proof['state_files'] = [dict(path=str(p.relative_to(work)), size=p.stat().st_size,
                                    sha256=hashlib.sha256(p.read_bytes()).hexdigest())
                                for p in state.rglob('*') if p.is_file()]
        proof['status'] = 'passed'
        proof['native_save_restore_continuity'] = True
        proof['limits'] = ['Read-only decoder targets the recovered LP64 native-endian 0.5 save ABI.',
                           'Bounded town movement/rest/save/restore/quit; no dungeon combat or victory claim.',
                           'PNG captures are raw native observations, not OCR or a replacement renderer.']
    except BaseException:
        proof['error'] = traceback.format_exc()
        raise
    finally:
        if capture:
            capture.close()
        cleanup = []
        for child in reversed(children):
            running = child.poll() is None
            if running:
                child.terminate()
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait(timeout=5)
            cleanup.append(dict(pid=child.pid, running_before_cleanup=running,
                                returncode=child.returncode,
                                role='xvfb' if child is children[0] else 'game'))
        for handle in handles:
            handle.close()
        proof['cleanup'] = cleanup
        proof['cleanup_complete'] = all(child.poll() is not None for child in children)
        if proof['status'] == 'passed' and any(
                item['role'] == 'game' and item['running_before_cleanup'] for item in cleanup):
            proof['status'] = 'failed'
            proof['error'] = 'successful gameplay cannot require signal cleanup'
        # Keep private state and native copies as evidence; mount/PID namespace
        # destruction removes only this harness's isolated servers/overlays.
        if evidence.exists():
            persist()
        elif initial_evidence.exists():
            write_json(initial_evidence / 'runtime.json', proof)


if __name__ == '__main__':
    main()
