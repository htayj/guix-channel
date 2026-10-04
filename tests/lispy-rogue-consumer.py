#!/usr/bin/env python3
"""Observe only installed upstream X11 pixels and send ordinary native inputs.

Invoke via lispy-rogue-smoke.sh. No Lisp instrumentation, renderer, save state,
or game configuration is introduced. Raw XWD captures are the evidence.
"""
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import select
import signal
import struct
import subprocess
import sys
import time
import traceback
import importlib.util

spec = importlib.util.spec_from_file_location('lispy_rogue_glyphs',
                                             Path(__file__).with_name('lispy-rogue-glyphs.py'))
glyphs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(glyphs)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def isolate(root, evidence):
    fds = [os.open(path, os.O_RDONLY | os.O_DIRECTORY) for path in (root, evidence)]
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
        # x86_64 Linux mount_setattr, with AT_RECURSIVE and MOUNT_ATTR_RDONLY.
        # All host mounts (including store and HOME) become read-only first.
        mount('/', '/', flags=4096 | 16384)
        attrs = (ctypes.c_uint64 * 4)(1, 0, 0, 0)
        if libc.syscall(ctypes.c_long(442), ctypes.c_int(-100), ctypes.c_char_p(b'/'),
                        ctypes.c_uint(0x8000), ctypes.byref(attrs), ctypes.sizeof(attrs)):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), 'recursive read-only root')
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, evidence = Path('/tmp/lispy-rogue-root'), Path('/tmp/lispy-rogue-evidence')
        for fd, target in zip(fds, (root, evidence)):
            target.mkdir()
            mount('/proc/self/fd/' + str(fd), target, flags=4096)
            mount(str(target), target, flags=4096 | 32 | 2 | 4)
        mount('proc', '/proc', 'proc', 1 | 2 | 4 | 8)
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
    finally:
        for fd in fds:
            os.close(fd)
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store is not mounted read-only')
    return root, evidence


def close_window(library, display_name, window):
    """Send the same ICCCM ClientMessage a real window manager sends on close."""
    class Data(ctypes.Union):
        _fields_ = [('b', ctypes.c_char * 20), ('s', ctypes.c_short * 10),
                    ('l', ctypes.c_long * 5)]

    class ClientMessage(ctypes.Structure):
        _fields_ = [('type', ctypes.c_int), ('serial', ctypes.c_ulong),
                    ('send_event', ctypes.c_int), ('display', ctypes.c_void_p),
                    ('window', ctypes.c_ulong), ('message_type', ctypes.c_ulong),
                    ('format', ctypes.c_int), ('data', Data)]

    class Event(ctypes.Union):
        _fields_ = [('client', ClientMessage), ('pad', ctypes.c_long * 24)]

    x11 = ctypes.CDLL(library)
    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
    x11.XInternAtom.restype = ctypes.c_ulong
    x11.XGetWMProtocols.argtypes = [ctypes.c_void_p, ctypes.c_ulong,
                                    ctypes.POINTER(ctypes.POINTER(ctypes.c_ulong)),
                                    ctypes.POINTER(ctypes.c_int)]
    x11.XSendEvent.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int,
                               ctypes.c_long, ctypes.POINTER(Event)]
    x11.XFlush.argtypes = [ctypes.c_void_p]
    x11.XFree.argtypes = [ctypes.c_void_p]
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
    display = x11.XOpenDisplay(display_name.encode())
    require(display, 'cannot open native X display for WM_DELETE_WINDOW')
    try:
        protocols = x11.XInternAtom(display, b'WM_PROTOCOLS', 0)
        delete = x11.XInternAtom(display, b'WM_DELETE_WINDOW', 0)
        atoms = ctypes.POINTER(ctypes.c_ulong)()
        count = ctypes.c_int()
        require(x11.XGetWMProtocols(display, window, ctypes.byref(atoms), ctypes.byref(count)),
                'native window does not expose WM_PROTOCOLS')
        try:
            require(delete in [atoms[i] for i in range(count.value)],
                    'native window does not advertise WM_DELETE_WINDOW')
        finally:
            x11.XFree(atoms)
        event = Event()
        event.client.type = 33
        event.client.send_event = 1
        event.client.display = display
        event.client.window = window
        event.client.message_type = protocols
        event.client.format = 32
        event.client.data.l[0] = delete
        event.client.data.l[1] = 0  # CurrentTime
        require(x11.XSendEvent(display, window, 0, 0, ctypes.byref(event)),
                'XSendEvent rejected WM_DELETE_WINDOW')
        x11.XFlush(display)
    finally:
        x11.XCloseDisplay(display)


def main():
    require(len(sys.argv) == 12,
            'usage: consumer OUTPUT ROOT EVIDENCE XVFB XDOTOOL XWD CONVERT ALLEGRO XLIB PULSE PACTL')
    output, root, evidence = map(Path, sys.argv[1:4])
    xvfb, xdotool, xwd, convert, allegro, xlib, pulse, pactl = sys.argv[4:]
    namespaces = {}
    for kind, variable in (('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                           ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')):
        actual = os.readlink('/proc/self/ns/' + kind)
        require(actual != os.environ[variable], 'host namespace leaked: ' + kind)
        namespaces[kind] = actual
    root, evidence = isolate(root, evidence)
    interfaces = sorted(line.split(':', 1)[0].strip()
                        for line in Path('/proc/net/dev').read_text().splitlines()[2:])
    require(interfaces == ['lo'], 'private network has non-loopback interfaces')
    record = {'status': 'failed', 'namespaces': namespaces, 'interfaces': interfaces,
              'store_read_only': True, 'commands': [], 'screenshots': [], 'inputs': [],
              'save_proof': 'Not applicable: pinned upstream has no save implementation.'}
    environment = dict(os.environ)
    for variable, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                ('TMPDIR', 'tmp')):
        path = root / directory
        path.mkdir(mode=0o700)
        environment[variable] = str(path)
    work = root / 'unrelated-working-directory'
    work.mkdir()
    environment.update(LIBGL_ALWAYS_SOFTWARE='1', GALLIUM_DRIVER='llvmpipe',
                       MESA_SHADER_CACHE_DISABLE='true', PYTHONNOUSERSITE='1',
                       PULSE_SERVER='unix:' + str(root / 'runtime/pulse-native'),
                       # Guix Allegro audio is OpenAL; avoid silent ALSA/null fallback.
                       ALSOFT_DRIVERS='pulse',
                       DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-bus'),
                       DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-system-bus'))
    # Guix OpenAL dlopens libpulse: an isolated user daemon, never the host daemon.
    pulse_config = root / 'pulse.pa'
    pulse_config.write_text('load-module module-native-protocol-unix socket=' +
                            str(root / 'runtime/pulse-native') + ' auth-anonymous=1\n'
                            'load-module module-null-sink sink_name=lispy_smoke\n'
                            'set-default-sink lispy_smoke\n')
    processes, logs = [], []
    game = None
    decoder = None

    def run(label, *args, check=True):
        args = list(map(str, args))
        record['commands'].append({'label': label, 'argv': args})
        result = subprocess.run(args, env=environment, cwd=work, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=15)
        (evidence / (label + '.stderr')).write_bytes(result.stderr)
        if check:
            require(result.returncode == 0, label + ' failed: ' + result.stderr.decode(errors='replace'))
        return result

    def start(label, args, **kwargs):
        args = list(map(str, args))
        record['commands'].append({'label': label, 'argv': args})
        log = (evidence / (label + '.log')).open('wb')
        logs.append(log)
        process = subprocess.Popen(args, cwd=work, env=environment, stdout=log,
                                   stderr=subprocess.STDOUT, start_new_session=True, **kwargs)
        processes.append(process)
        return process

    def wait(predicate, label, timeout=30):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            require(game is None or game.poll() is None, 'game exited awaiting ' + label)
            value = predicate()
            if value:
                return value
            time.sleep(0.2)
        raise RuntimeError('timed out awaiting ' + label)

    try:
        for name in ('dungeon.ogg', 'urizen-tileset.png', 'urizen-tileset.tsx',
                     'fantasque-sans-mono.ttf', 'inconsolata.ttf'):
            require((output / 'Resources' / name).is_file(), 'missing runtime asset: ' + name)
        notices = output / 'share/doc/lispy-rogue'
        for name in ('LICENSE', 'ASSET-NOTICES', 'Fantasque-OFL-1.1.txt',
                     'Inconsolata-OFL-1.1.txt'):
            require((notices / name).is_file(), 'missing license notice: ' + name)
        audio = start('pulseaudio', [pulse, '--daemonize=no', '--exit-idle-time=-1',
                                    '--use-pid-file=no', '--disable-shm=yes',
                                    '--log-target=stderr', '-n', '--file=' + str(pulse_config)])
        wait(lambda: (root / 'runtime/pulse-native').exists() or audio.poll() is not None,
             'isolated audio socket')
        require(audio.poll() is None, 'isolated PulseAudio failed')
        info = run('pulse-info', pactl, 'info').stdout.decode()
        require('lispy_smoke' in info, 'PulseAudio did not select the null sink')
        (evidence / 'pulse-info.txt').write_text(info)
        display_read, display_write = os.pipe()
        try:
            server = start('xvfb', [xvfb, '-displayfd', str(display_write), '-screen', '0',
                                    '1280x800x24', '-nolisten', 'tcp', '-ac'],
                           pass_fds=(display_write,))
            os.close(display_write)
            display_write = None
            require(select.select([display_read], [], [], 20)[0], 'Xvfb display allocation timed out')
            display_number = os.read(display_read, 64).strip().decode()
            require(display_number.isdigit(), 'Xvfb failed to allocate display')
            environment['DISPLAY'] = ':' + display_number
        finally:
            os.close(display_read)
            if display_write is not None:
                os.close(display_write)
        game = start('lispy-rogue', [output / 'bin/lispy-rogue'])

        def find_window():
            result = run('window-search', xdotool, 'search', '--onlyvisible', '--name',
                         '^Lispy Rogue$', check=False)
            return result.stdout.split()[0].decode() if result.returncode == 0 and result.stdout.split() else None

        window = wait(find_window, 'native Lispy Rogue window')
        record['window'] = window
        record['native_argv'] = (Path('/proc') / str(game.pid) / 'cmdline').read_bytes().decode().split('\0')[:-1]

        sink_inputs = wait(lambda: run('pulse-sink-inputs', pactl, 'list', 'short',
                                       'sink-inputs').stdout.decode().strip(),
                           'game audio stream on isolated null sink')
        record['pulse_sink_inputs'] = sink_inputs.splitlines()

        def capture(label):
            label = '%02d-%s' % (len(record['screenshots']), label)
            raw, image = evidence / (label + '.xwd'), evidence / (label + '.png')
            run(label + '-capture', xwd, '-silent', '-id', window, '-out', raw)
            run(label + '-convert', convert, raw, image)
            data = image.read_bytes()
            require(data[:8] == b'\x89PNG\r\n\x1a\n', 'not a real PNG capture')
            width, height = struct.unpack('>II', data[16:24])
            require((width, height) == (1280, 800), 'unexpected native window geometry')
            pixels = run(label + '-pixels', convert, image, '-depth', '8', 'rgb:-').stdout
            record['screenshots'].append({'path': image.name, 'xwd': raw.name,
                                           'sha256': hashlib.sha256(data).hexdigest()})
            return pixels

        # In-process font decoding uses the same private display/state tree;
        # it never opens a display or publishes a replacement UI.
        os.environ.update(environment)
        decoder = glyphs.GlyphDecoder(allegro, output / 'Resources/fantasque-sans-mono.ttf')

        def observe(label, text):
            def detect():
                matches = decoder.match(capture(label), 1280, 800, text)
                if matches:
                    record['screenshots'][-1]['exact_glyph_match'] = {'text': text, 'boxes': matches}
                return matches
            return wait(detect, label)

        def key(value):
            run('focus', xdotool, 'windowfocus', '--sync', window)
            # Hold through multiple Allegro frames; keys are polled, not event commands.
            run('keydown-' + value, xdotool, 'keydown', '--clearmodifiers', value)
            time.sleep(0.12)
            run('keyup-' + value, xdotool, 'keyup', value)
            record['inputs'].append({'key': value, 'hold_seconds': 0.12})
            time.sleep(0.3)

        observe('startup-help', '                                            CONTROLS')
        key('Escape')
        observe('dungeon', 'You enter the dungeon.')
        key('r')
        observe('native-turn', 'You stand still.')
        # This is an upstream turn action, proven by its source-visible message,
        # not a generic screenshot-difference or invented internal turn counter.
        record['turn_proof'] = 'r -> native You stand still. message'
        key('i')
        observe('inventory', 'Inventory')
        key('Escape')
        key('F1')
        observe('reopened-help', '                                            CONTROLS')
        key('Escape')
        capture('before-close')
        close_window(xlib, environment['DISPLAY'], int(window))
        record['close_event'] = 'WM_PROTOCOLS/WM_DELETE_WINDOW'
        record['exit_status'] = game.wait(timeout=20)
        require(record['exit_status'] == 0, 'native WM_DELETE_WINDOW did not exit zero')
        record['state_files'] = sorted(str(path.relative_to(root)) for path in root.rglob('*') if path.is_file())
        allowed = {'lispy-rogue-root', 'lispy-rogue-evidence', '.X11-unix',
                   '.X%s-lock' % display_number}
        # Private tmpfs only; Xvfb may leave its compiled XKB keymap there.
        stray = sorted(name for name in set(os.listdir('/tmp')) - allowed
                       if not re.fullmatch(r'server-\d+\.xkm', name))
        sockets = sorted(os.listdir('/tmp/.X11-unix'))
        require(not stray and sockets in ([], ['X' + display_number]),
                'files created outside temporary HOME/XDG tree: %r %r' % (stray, sockets))
        record['status'] = 'passed'
        print('Observed native startup help, dungeon, genuine wait turn, inventory, help toggle and zero-exit WM_DELETE_WINDOW.')
    except Exception:
        record['error'] = traceback.format_exc()
        raise
    finally:
        # Close the decoder's Allegro X connection while Xvfb is still alive.
        # Killing the server first would trigger fatal Xlib I/O during teardown.
        if decoder is not None:
            decoder.close()
        for process in reversed(processes):
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=5)
        for log in logs:
            log.close()
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')


if __name__ == '__main__':
    main()
