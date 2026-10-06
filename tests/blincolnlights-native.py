#!/usr/bin/env python3
"""Read-only oracle for the installed SDL PDP-1 panel and native PDP-5.

Pinned aap/blincolnlights 932d2cedfaec3368d6e1890b15645decc4815429:
vpanel_pdp1/{main.c,elements.inc} defines the 800x448 grid and mouse controls;
panel_pidp1.h defines the 15 native int shared words; pdp5/panel1.c maps
TA's low 12 bits (NOT TW) to PDP-5 SR, right START to LOAD ADDRESS,
right DEPOSIT to memory write, left EXAMINE to memory read. pdp5/pdp5.c
sp0..sp3/tick execute those operations. pdp5/main.c handles SIGTERM by
exit(0), atexit dumpmem(coremem), lightsoff, and loads coremem on restart.
No panel/shared-memory/core writes by this driver; all state comes from UI.
"""
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import select
import signal
import stat
import struct
import subprocess
import sys
import time
import traceback

COMMIT = '932d2cedfaec3368d6e1890b15645decc4815429'
POWER = 0o200000
SOURCE = 'https://github.com/aap/blincolnlights/blob/' + COMMIT + '/'


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def main():
    output, evidence = map(Path, sys.argv[1:])
    record = {'status': 'failed', 'source_commit': COMMIT, 'inputs': [],
              'source': [SOURCE + name for name in ('vpanel_pdp1/main.c',
                         'vpanel_pdp1/elements.inc', 'panel_pidp1.h',
                         'pdp5/panel1.c', 'pdp5/pdp5.c', 'pdp5/main.c')],
              'limits': ['Host SDL software rendering and PDP-5 only; no GPIO, '
                         'Raspberry Pi, physical panel, audio, peripheral or Lua hardware proof.',
                         'Other installed panel/emulator variants are scope/ELF checked, not operated.',
                         'PDP-5 has no quit command: native SIGTERM handler performs exit(0), '
                         'coremem persistence and lamps-off; signal alone is not a success criterion.',
                         'Private network contains only down loopback; native fixed-port listener '
                         'is confined, no host/tailnet TCP or guest TTY traffic is exercised.']}

    def save():
        (evidence / 'runtime.json').write_text(json.dumps(record, indent=2) + '\n')
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')

    try:
        require(output.parent == Path('/gnu/store') and output.resolve() == output,
                'OUTPUT must be canonical direct store item')
        panels = ['b18', 'pdp1', 'whirlwind']
        emulators = ['pdp1', 'pdp1-b18', 'pdp5', 'tx0-pdp1', 'tx0-b18',
                     'whirlwind', 'whirlwind-b18']
        native = ['bin/blincolnlights-panel-' + name for name in panels] + \
                 ['libexec/blincolnlights/' + name for name in emulators] + \
                 ['bin/mkptyfl', 'bin/mkptyfio']
        require({p.name for p in (output / 'bin').iterdir()} ==
                {'blincolnlights-panel-' + name for name in panels} |
                {'blincolnlights-' + name for name in emulators} | {'mkptyfl', 'mkptyfio'},
                'unexpected installed programs (host-only scope changed)')
        require({p.name for p in (output / 'libexec/blincolnlights').iterdir()} == set(emulators),
                'unexpected raw emulator scope')
        for name in native:
            path = output / name
            require(path.is_file() and not path.is_symlink() and os.access(path, os.X_OK),
                    'missing native executable: ' + name)
            with path.open('rb') as stream:
                require(stream.read(4) == b'\x7fELF', 'not native ELF: ' + name)
        for name in emulators:
            launcher = (output / ('bin/blincolnlights-' + name)).read_text()
            require('XDG_STATE_HOME' in launcher and 'exec "' + str(output / 'libexec/blincolnlights' / name) + '"' in launcher,
                    'launcher does not execute installed emulator in XDG state')
        require('MIT License' in (output / 'share/doc/blincolnlights/LICENSE').read_text(),
                'installed MIT notice missing')
        require('/tmp/pdp1_panel' in (output / 'share/doc/blincolnlights/README.guix').read_text(),
                'installed state/collision documentation missing')
        require(os.readlink(output / 'share/blincolnlights/pdp1/tapes/dpys5.rim') == 'ddt.rim',
                'packaged tape compatibility link changed')
        for path in [output, *output.rglob('*')]:
            mode = path.lstat().st_mode
            if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
                require(not mode & 0o222, 'writable store member: ' + str(path))
        require(os.getuid() == int(os.environ['HOST_UID']) and os.getgid() == int(os.environ['HOST_GID']),
                'caller UID/GID changed')
        namespaces = {}
        for kind, key in [('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                          ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')]:
            namespaces[kind] = os.readlink('/proc/self/ns/' + kind)
            require(namespaces[kind] != os.environ[key], 'host namespace leaked: ' + kind)
        interfaces = sorted(line.split(':', 1)[0].strip() for line in
                            Path('/proc/net/dev').read_text().splitlines()[2:])
        require(interfaces == ['lo'], 'network is not private loopback-only')
        record['isolation'] = {'uid': os.getuid(), 'gid': os.getgid(),
                               'namespaces': namespaces, 'interfaces': interfaces}
        (evidence / 'mountinfo-before.txt').write_text(Path('/proc/self/mountinfo').read_text())
        evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
        libc = ctypes.CDLL(None, use_errno=True)
        libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                               ctypes.c_ulong, ctypes.c_void_p]
        libc.mount.restype = ctypes.c_int

        def mount(source, target, filesystem=None, flags=0):
            if libc.mount(None if source is None else os.fsencode(source), os.fsencode(target),
                          None if filesystem is None else os.fsencode(filesystem), flags, None):
                error = ctypes.get_errno()
                raise OSError(error, os.strerror(error), str(target))

        try:
            mount('/gnu/store', '/gnu/store', flags=4096)
            mount(None, '/gnu/store', flags=4096 | 32 | 1)
            mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
            os.chmod('/tmp', 0o1777)
            retained = Path('/tmp/blincoln-evidence')
            retained.mkdir()
            mount('/proc/self/fd/' + str(evidence_fd), retained, flags=4096)
            evidence = retained
        finally:
            os.close(evidence_fd)
        mounts = Path('/proc/self/mountinfo').read_text()
        store_mounts = [line.split() for line in mounts.splitlines() if line.split()[4] == '/gnu/store']
        require(store_mounts and 'ro' in store_mounts[-1][5].split(','), 'store bind not read-only')
        (evidence / 'mountinfo-after.txt').write_text(mounts)
        record['isolation']['store_read_only'] = True
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
        root = Path('/tmp/blincoln-state')
        root.mkdir(mode=0o700)
        env = {'PATH': '', 'LC_ALL': 'C.UTF-8', 'SDL_VIDEODRIVER': 'x11',
               'SDL_AUDIODRIVER': 'dummy', 'SDL_RENDER_DRIVER': 'software',
               'LIBGL_ALWAYS_SOFTWARE': '1', 'MESA_SHADER_CACHE_DISABLE': 'true'}
        for key, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                          ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                          ('XDG_RUNTIME_DIR', 'runtime'), ('TMPDIR', 'tmp')]:
            directory = root / name
            directory.mkdir(mode=0o700)
            env[key] = str(directory)
        work = root / 'work'
        work.mkdir()
        env['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=' + str(root / 'runtime/no-session')
        env['DBUS_SYSTEM_BUS_ADDRESS'] = 'unix:path=' + str(root / 'runtime/no-system')
        record['environment'] = env.copy()
        record['clean_state_before'] = {key: sorted(os.listdir(env[key])) for key in
                                        ('HOME', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME',
                                         'XDG_STATE_HOME', 'XDG_RUNTIME_DIR')}
        require(not any(record['clean_state_before'].values()), 'HOME/XDG state is not clean')

        def tool(*args):
            return subprocess.check_output(args, env=env, cwd=work, stderr=subprocess.STDOUT, timeout=10)

        def launch(label, program):
            with (evidence / (label + '.log')).open('wb') as log:
                process = subprocess.Popen([str(program)], env=env, cwd=work, stdin=subprocess.DEVNULL,
                                           stdout=log, stderr=log)
            return process

        readfd, writefd = os.pipe()
        with (evidence / 'xvfb.log').open('wb') as log:
            xserver = subprocess.Popen([os.environ['XVFB'], '-displayfd', str(writefd), '-screen', '0',
                                        '1024x768x24', '-nolisten', 'tcp', '-noreset'],
                                       pass_fds=(writefd,), env=env, cwd=work, stdout=log, stderr=log)
        os.close(writefd)
        ready = select.select([readfd], [], [], 10)[0]
        require(ready and xserver.poll() is None, 'Xvfb readiness absent')
        number = os.read(readfd, 64).decode().strip()
        os.close(readfd)
        require(number.isdigit(), 'invalid Xvfb displayfd')
        env['DISPLAY'] = ':' + number
        panel = launch('panel', output / 'bin/blincolnlights-panel-pdp1')
        panel_file = Path('/tmp/pdp1_panel')
        window = None
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            require(panel.poll() is None, 'installed SDL panel exited before controls')
            tree = tool(os.environ['XWININFO'], '-root', '-tree').decode()
            found = re.findall(r'(0x[0-9a-fA-F]+) "PDP-1 console"', tree)
            if len(found) == 1 and panel_file.exists():
                window = found[0]
                break
            time.sleep(.1)
        (evidence / 'window-tree.txt').write_text(tree)
        require(window is not None and panel_file.stat().st_size == 15 * 4,
                'installed SDL window/native Panel ABI absent')
        info = tool(os.environ['XWININFO'], '-id', window).decode()
        (evidence / 'window-info.txt').write_text(info)
        require(re.search(r'Width: 800\b', info) and re.search(r'Height: 448\b', info),
                'source-backed 800x448 native panel layout changed')
        tool(os.environ['XDOTOOL'], 'windowfocus', '--sync', window)

        def words():
            # File read only: never mmap writable, seed, truncate, or inject state.
            return struct.unpack('=15i', panel_file.read_bytes())

        def wait_for(predicate, message):
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                require(panel.poll() is None, 'SDL panel exited during operation')
                require(emulator.poll() is None, 'PDP-5 exited during operation')
                state = words()
                if predicate(state):
                    time.sleep(.12)
                    return words()
                time.sleep(.03)
            raise AssertionError(message + ': ' + repr(words()))

        def point(column, row, grid=1):
            sx, sy = 12.95 * 1.6, 12.9 * 1.6
            xoff = (4.5 if grid == 1 else 1.05) * 1.6 + sx / 2
            # putongrid truncates the rectangle origin; centers differ <1px.
            return int(xoff + sx * column), int(2.56 * 1.6 + sy * row)

        def click(label, column, row, button=1, grid=1):
            x, y = point(column, row, grid)
            record['inputs'].append({'control': label, 'x': x, 'y': y, 'button': button})
            tool(os.environ['XDOTOOL'], 'mousemove', '--window', window, str(x), str(y),
                 'mousedown', str(button), 'sleep', '0.15', 'mouseup', str(button))
            time.sleep(.15)

        def set_sr(value):
            # SDL middle button unconditionally sets switch on; right clears.
            for bit in range(12):
                click('TA/SR bit ' + str(11 - bit), 9 + bit, 13,
                      button=2 if value & (1 << (11 - bit)) else 3)
            wait_for(lambda s: s[0] & 0o7777 == value, 'native TA/SR input mismatch')

        def capture(label):
            path = evidence / (label + '.png')
            tool(os.environ['IMPORT'], '-window', window, str(path))
            raw = path.read_bytes()
            require(raw[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II', raw[16:24]) == (800, 448),
                    'capture is not the real native 800x448 window')
            rgb = tool(os.environ['CONVERT'], str(path), '-depth', '8', 'RGB:-')
            require(len(rgb) == 800 * 448 * 3, 'incomplete native window pixels')
            require(len(set(zip(rgb[0::3], rgb[1::3], rgb[2::3]))) > 32, 'blank SDL panel')
            record.setdefault('captures', []).append({'file': path.name, 'sha256': hashlib.sha256(raw).hexdigest(),
                                                       'panel_words': list(words())})
            return rgb

        def cell(rgb, column, row, grid=1):
            x, y = point(column, row, grid)
            # Central 10x10 opaque lamp pixels, excluding texture transparent edge.
            return b''.join(rgb[((y + dy) * 800 + x - 5) * 3:((y + dy) * 800 + x + 5) * 3]
                            for dy in range(-5, 5))

        def lamp_bits(off, on, start, row, count):
            return [int(sum(abs(a - b) > 24 for a, b in zip(cell(off, start + i, row),
                                                          cell(on, start + i, row))) > 12)
                    for i in range(count)]

        emulator = launch('pdp5-first', output / 'bin/blincolnlights-pdp5')
        wait_for(lambda s: all(value == 0 for value in s[4:14]), 'power-off lamps not zero')
        off = capture('01-native-power-off')
        click('POWER on', 30.5, 3, grid=2)
        wait_for(lambda s: s[9] & 4, 'native emulator POWER lamp missing')
        powered = capture('02-native-power-on')
        require(cell(off, 29, 3, 2) != cell(powered, 29, 3, 2), 'visible POWER lamp did not change')
        # pdp5/pdp5.c: LOAD ADDRESS sets MA=SR in sp1/sp2; DEPOSIT (DCA) and
        # EXAMINE (TAD) run one E1 cycle at MA, then tp1 COUNT_MA increments.
        # So MA is asserted only after LOAD ADDRESS, never after DEP/EXAM.
        address, pattern = 0o100, 0o5252
        set_sr(address)
        click('LOAD ADDRESS (START up)', 4, 19, button=3)
        wait_for(lambda s: s[5] == address, 'native load-address MA mismatch')
        capture('03-native-address-loaded')
        set_sr(pattern)
        click('DEPOSIT up', 16, 19, button=3)
        wait_for(lambda s: s[6] == pattern, 'native deposit MB mismatch')
        capture('04-native-memory-deposited')
        set_sr(0o102)
        click('LOAD ADDRESS adjacent zero', 4, 19, button=3)
        wait_for(lambda s: s[5] == 0o102, 'adjacent load-address MA mismatch')
        click('EXAMINE adjacent zero', 13, 19)
        wait_for(lambda s: s[6] == 0, 'untouched adjacent memory not zero')
        zero = capture('05-native-adjacent-zero-examined')
        set_sr(address)
        click('LOAD ADDRESS deposited word', 4, 19, button=3)
        wait_for(lambda s: s[5] == address, 'reloaded MA mismatch')
        # Clear SR before EXAMINE: displayed data must come from native memory,
        # not from switches, DEPOSIT residue, a fake frontend, or our reader.
        set_sr(0)
        click('EXAMINE persisted word', 13, 19)
        wait_for(lambda s: s[6] == pattern, 'native memory examine mismatch')
        examined = capture('06-native-word-examined-with-zero-SR')
        expected = [int(bit) for bit in f'{pattern:018b}']
        require(lamp_bits(zero, examined, 3, 7, 18) == expected,
                'real MB lamp image does not display the examined 12-bit word')
        record['panel_memory'] = {'address_octal': f'{address:04o}', 'word_octal': f'{pattern:04o}',
                                  'adjacent_zero_octal': '0102', 'sr_cleared_before_examine': True,
                                  'visible_mb_bits': expected}

        def native_exit(process, label):
            record['inputs'].append({'native_signal': 'SIGTERM', 'process': label,
                                      'source_handler': 'pdp5/main.c:sighandler -> exit(0) -> exitcleanup'})
            process.send_signal(signal.SIGTERM)
            require(process.wait(timeout=10) == 0, 'upstream PDP-5 exit handler failed')
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline and any(words()[4:14]):
                time.sleep(.03)
            require(not any(words()[4:14]), 'upstream exitcleanup did not extinguish lamps')
            time.sleep(.15)  # let the 30 ms SDL loop redraw extinguished lamps

        state = Path(env['XDG_STATE_HOME']) / 'blincolnlights/blincolnlights-pdp5'
        native_exit(emulator, 'pdp5-first')
        require((state / 'maindec').resolve() == output / 'share/blincolnlights/pdp1/maindec' and
                (state / 'tapes').resolve() == output / 'share/blincolnlights/pdp1/tapes',
                'XDG launcher links do not reference installed data')
        core = (state / 'coremem').read_text()
        (evidence / 'coremem-first.native').write_text(core)
        memory, cursor = {}, 0
        for token in re.findall(r'[0-7]+:?', core):
            if token.endswith(':'):
                cursor = int(token[:-1], 8)
            else:
                memory[cursor] = int(token, 8)
                cursor += 1
        require(memory.get(address) == pattern and memory.get(0o102, 0) == 0,
                'native coremem dump disagrees with real DEPOSIT/EXAMINE')
        emulator = launch('pdp5-restored', output / 'bin/blincolnlights-pdp5')
        wait_for(lambda s: s[9] & 4, 'restored native POWER missing')
        set_sr(0o102)
        click('LOAD ADDRESS restored adjacent zero', 4, 19, button=3)
        wait_for(lambda s: s[5] == 0o102, 'restored adjacent MA mismatch')
        click('EXAMINE restored adjacent zero', 13, 19)
        wait_for(lambda s: s[6] == 0, 'restored adjacent word not zero')
        restored_zero = capture('07-restarted-adjacent-zero')
        set_sr(address)
        click('LOAD ADDRESS restored word', 4, 19, button=3)
        wait_for(lambda s: s[5] == address, 'restored word MA mismatch')
        set_sr(0)
        click('EXAMINE restored native coremem', 13, 19)
        wait_for(lambda s: s[6] == pattern, 'installed launcher failed native core restore')
        restored = capture('08-restarted-word-restored')
        require(lamp_bits(restored_zero, restored, 3, 7, 18) == expected,
                'real lamps do not show the restored native memory')
        native_exit(emulator, 'pdp5-restored')
        (evidence / 'coremem-restored.native').write_bytes((state / 'coremem').read_bytes())
        exited = capture('09-native-exit-lamps-off')
        require(cell(off, 29, 3, 2) == cell(exited, 29, 3, 2), 'POWER lamp remained on after native exit')
        record['persistence'] = {'coremem_decoded_word_octal': f'{memory[address]:04o}',
                                  'installed_launcher_restart_examined_same_word': True,
                                  'native_exit_statuses': [0, 0], 'exitcleanup_lamps_off': True}
        # xdotool windowclose destroys a window, so send the source SDL_QUIT
        # path's WM_DELETE_WINDOW client message, without a window manager.
        x = ctypes.CDLL(os.environ['XLIB'])
        x.XOpenDisplay.argtypes = [ctypes.c_char_p]
        x.XOpenDisplay.restype = ctypes.c_void_p
        x.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
        x.XInternAtom.restype = ctypes.c_ulong
        class Client(ctypes.Structure):
            _fields_ = [('type', ctypes.c_int), ('serial', ctypes.c_ulong), ('send_event', ctypes.c_int),
                        ('display', ctypes.c_void_p), ('window', ctypes.c_ulong),
                        ('message_type', ctypes.c_ulong), ('format', ctypes.c_int), ('data', ctypes.c_long * 5)]
        class Event(ctypes.Union):
            _fields_ = [('client', Client), ('pad', ctypes.c_long * 24)]
        x.XSendEvent.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_long, ctypes.POINTER(Event)]
        x.XFlush.argtypes = [ctypes.c_void_p]
        x.XCloseDisplay.argtypes = [ctypes.c_void_p]
        display = x.XOpenDisplay(env['DISPLAY'].encode())
        require(display, 'XOpenDisplay failed for native close')
        event = Event()
        event.client.type = 33
        event.client.display = display
        event.client.window = int(window, 16)
        event.client.message_type = x.XInternAtom(display, b'WM_PROTOCOLS', 0)
        event.client.format = 32
        event.client.data[0] = x.XInternAtom(display, b'WM_DELETE_WINDOW', 0)
        require(x.XSendEvent(display, int(window, 16), 0, 0, ctypes.byref(event)), 'native close event not sent')
        x.XFlush(display)
        x.XCloseDisplay(display)
        require(panel.wait(timeout=10) == 0, 'installed panel SDL_QUIT failed')
        record['panel_quit'] = {'method': 'WM_DELETE_WINDOW -> SDL_QUIT', 'exit_status': 0}
        record['status'] = 'passed'
        save()
        print('BLINCOLNLIGHTS_NATIVE_PANEL_MEMORY_OK deposit/examine/zero/restore/visible-lamps/native-exit')
        # Namespace init exits; private Xvfb and /tmp are disposed with it.
    except BaseException as error:
        record['error'] = str(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        save()
        raise


if __name__ == '__main__':
    main()
