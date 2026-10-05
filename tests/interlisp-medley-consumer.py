#!/usr/bin/env python3
"""Native X11 Medley consumer; no REM.CM, greetfile or acceptance Lisp injected.

Invoke through interlisp-medley-smoke.sh. Source-font exact bitmap matching is
used only outside the application, against retained raw screenshots.
"""
import ctypes
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import time
import traceback

spec = importlib.util.spec_from_file_location(
    'medley_glyphs', Path(__file__).with_name('interlisp-medley-glyphs.py'))
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
        mount('/', '/', flags=4096 | 16384)
        attrs = (ctypes.c_uint64 * 4)(1, 0, 0, 0)
        if libc.syscall(ctypes.c_long(442), ctypes.c_int(-100), ctypes.c_char_p(b'/'),
                        ctypes.c_uint(0x8000), ctypes.byref(attrs), ctypes.sizeof(attrs)):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), 'recursive read-only root')
        mount('tmpfs', '/tmp', 'tmpfs', 2 | 4)
        os.chmod('/tmp', 0o1777)
        root, evidence = Path('/tmp/medley-root'), Path('/tmp/medley-evidence')
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
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store is not read-only')
    return root, evidence


def main():
    require(len(sys.argv) == 8, 'usage: consumer OUTPUT ROOT EVIDENCE XVFB XDOTOOL XWD CONVERT')
    output, root, evidence = map(Path, sys.argv[1:4])
    xvfb, xdotool, xwd, convert = sys.argv[4:]
    require(os.getuid() == int(os.environ['HOST_UID']), 'namespace changed numeric user ID')
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
              'uid': os.getuid(), 'store_read_only': True, 'commands': [],
              'screenshots': [], 'inputs': []}
    environment = dict(os.environ)
    for variable, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                                ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                                ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                                ('TMPDIR', 'tmp')):
        path = root / directory
        path.mkdir(mode=0o700)
        environment[variable] = str(path)
    environment.update(DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-bus'),
                       DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + str(root / 'runtime/no-system-bus'),
                       PYTHONNOUSERSITE='1')
    work = root / 'unrelated-working-directory'
    work.mkdir()
    processes, logs = [], []
    medley = None

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

    def wait(predicate, label, timeout=60):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            require(medley is None or medley.poll() is None, 'Medley exited awaiting ' + label)
            value = predicate()
            if value:
                return value
            time.sleep(0.3)
        raise RuntimeError('timed out awaiting ' + label)

    window = None

    def capture(label):
        raw, png, pgm = [evidence / (label + extension) for extension in ('.xwd', '.png', '.pgm')]
        run(label + '-xwd', xwd, '-silent', '-id', window, '-out', raw)
        run(label + '-png', convert, raw, png)
        run(label + '-pgm', convert, raw, '-colorspace', 'Gray', '-depth', '8', pgm)
        screenshot = {'label': label, 'xwd': raw.name, 'png': png.name,
                      'sha256': hashlib.sha256(raw.read_bytes()).hexdigest()}
        # Polling overwrites its diagnostic capture; record only the final bytes
        # retained at that path, never stale hashes of discarded screenshots.
        record['screenshots'] = [item for item in record['screenshots'] if item['label'] != label]
        record['screenshots'].append(screenshot)
        return glyphs.read_pgm(pgm)

    def type_form(label, form):
        record['inputs'].append({'kind': 'keyboard', 'form': form})
        run(label + '-type', xdotool, 'type', '--clearmodifiers', '--delay', '45', form)
        run(label + '-return', xdotool, 'key', '--clearmodifiers', 'Return')

    try:
        medley_dir = output / 'libexec/medley'
        sysout = medley_dir / 'loadups/full.sysout'
        require(sysout.is_file(), 'missing exact upstream full boot image')
        record['boot_image'] = {'path': str(sysout), 'sha256': hashlib.sha256(sysout.read_bytes()).hexdigest()}
        fonts = glyphs.load_fonts(medley_dir / 'fonts')
        record['fonts'] = [font['provenance'] for font in fonts]
        require(fonts, 'no source bitmap fonts available to observe native REPL')
        display_read, display_write = os.pipe()
        try:
            start('xvfb', [xvfb, '-displayfd', str(display_write), '-screen', '0',
                           '1280x1024x24', '-nolisten', 'tcp', '-ac'], pass_fds=(display_write,))
            os.close(display_write)
            display_write = None
            require(select.select([display_read], [], [], 20)[0], 'Xvfb display allocation timed out')
            number = os.read(display_read, 64).strip().decode()
            require(number.isdigit(), 'Xvfb failed to allocate display')
            environment['DISPLAY'] = ':' + number
        finally:
            os.close(display_read)
            if display_write is not None:
                os.close(display_write)
        logindir = root / 'home/il'
        virtualmem = logindir / 'vmem/lisp.virtualmem'
        # --vmem validates its parent during argument parsing, before the
        # launcher creates LOGINDIR/vmem. Prepare only the private directory;
        # the virtualmem file itself must still come from native SAVEVM.
        virtualmem.parent.mkdir(parents=True, mode=0o700)
        title = 'Medley native upstream smoke'
        medley = start('medley', [output / 'bin/medley', '--config', '-', '--greet', '-',
                                 '--full', '--geometry', '1024x768',
                                 '--screensize', '1024x768', '--noscroll', '--title', title,
                                 '--logindir', logindir, '--vmem', virtualmem, '--rem.cm', '-'])

        def find_window():
            result = run('window-search', xdotool, 'search', '--onlyvisible', '--name',
                         '^' + title + '$', check=False)
            return result.stdout.split()[0].decode() if result.returncode == 0 and result.stdout.split() else None

        window = wait(find_window, 'native Maiko X window')
        # ldeboot forks a small Unix-communication helper that stays `lde`,
        # then execs the actual X11 VM as `ldex` (src/ldeboot.c, unixfork.c).
        # Count actual VMs, without disabling the normal native helper.
        emulators, helpers = [], []
        for proc in Path('/proc').iterdir():
            if not proc.name.isdigit():
                continue
            try:
                executable = (proc / 'exe').resolve(strict=True)
                argv = (proc / 'cmdline').read_bytes().rstrip(b'\0').split(b'\0')
                if executable.name in ('lde', 'ldex', 'ldeinit'):
                    identity = {'pid': int(proc.name), 'executable': str(executable),
                                'argv': [arg.decode() for arg in argv]}
                    identity['ppid'] = int(next(line.split()[1] for line in
                        (proc / 'status').read_text().splitlines() if line.startswith('PPid:')))
                    (helpers if executable.name == 'lde' else emulators).append(identity)
            except (FileNotFoundError, PermissionError):
                continue
        record['emulator_candidates'] = emulators
        record['unix_helpers'] = helpers
        require(len(emulators) == 1, 'expected exactly one native source-built Maiko emulator; '
                + repr(emulators))
        require(Path(emulators[0]['executable']).name == 'ldex',
                'normal full-image boot did not launch the native X11 VM')
        require(str(sysout) in emulators[0]['argv'], 'actual Maiko did not launch the upstream full image')
        expected_maiko = (output / 'libexec/maiko').resolve()
        require(Path(emulators[0]['executable']).is_relative_to(expected_maiko),
                'actual emulator executable is outside installed Maiko closure')
        require(len(helpers) == 1, 'expected exactly one native Maiko Unix helper; ' + repr(helpers))
        require(Path(helpers[0]['executable']).is_relative_to(expected_maiko)
                and helpers[0]['ppid'] == emulators[0]['pid'],
                'native Unix helper is not a child of the installed Maiko emulator')
        record['emulator'] = emulators[0]
        run('window-focus', xdotool, 'windowfocus', '--sync', window)

        def boot_ready():
            image = capture('boot-pending')
            return glyphs.find_repl(image, fonts)

        repl = wait(boot_ready, 'source-font native REPL title')
        record['repl'] = repl
        # Native left-button input selects the existing upstream listener; it does
        # not create a window, load code or alter the boot image.
        x, y = repl['click']
        run('repl-click', xdotool, 'mousemove', '--window', window, str(x), str(y), 'click', '1')
        record['inputs'].append({'kind': 'mouse', 'button': 1, 'window': window, 'x': x, 'y': y})
        run('pointer-away', xdotool, 'mousemove', '--window', window, '1000', '740')
        before = capture('native-boot')
        expression, result = '(IL:PLUS 273819 640572)', '914391'
        require(not glyphs.find_text(before, fonts, result), 'arithmetic result already visible before input')
        type_form('arithmetic', expression)

        def evaluated():
            image = capture('evaluation-pending')
            matches = glyphs.find_text(image, fonts, result)
            echoes = glyphs.find_text(image, fonts, expression)
            # The exact result must be below the exact input echo in the same
            # native listener. Its digits occur in neither operand or boot UI.
            matches = [match for match in matches if any(
                echo['y'] < match['y'] <= echo['y'] + 5 * echo['height']
                and abs(echo['x'] - match['x']) <= 80 for echo in echoes)]
            if matches:
                record['evaluation_echoes'] = echoes
            return matches

        matches = wait(evaluated, 'exact arithmetic result pixels')
        record['evaluation'] = {'expression': expression, 'expected': result,
                                'absent_before': True, 'source_bitmap_matches': matches}
        final_image = capture('native-evaluated-before-logout')
        require(glyphs.find_text(final_image, fonts, result),
                'result pixels disappeared before pre-logout screenshot')
        require(not virtualmem.exists(), 'virtualmem existed before native SAVEVM')
        # FAST=T logout intentionally does not flush virtual memory (ADIR
        # LOGOUT0; Maiko LISPFINISH). Use ordinary native REPL SAVEVM first.
        type_form('savevm', '(IL:SAVEVM)')
        def saved_virtualmem():
            if not virtualmem.is_file() or virtualmem.stat().st_size == 0:
                return None
            image = capture('savevm-pending')
            return glyphs.find_text(image, fonts, '(IL:SAVEVM)')

        record['savevm_echoes'] = wait(saved_virtualmem, 'native user virtualmem atomically saved')
        prior_virtualmem = hashlib.sha256(virtualmem.read_bytes()).hexdigest()
        record['virtualmem_before_logout_sha256'] = prior_virtualmem
        saved_image = capture('native-saved-before-logout')
        require(glyphs.find_text(saved_image, fonts, result),
                'arithmetic result not retained after native SAVEVM')
        type_form('logout', '(IL:LOGOUT T 0)')
        status = medley.wait(timeout=60)
        record['exit_status'] = status
        require(status == 0, 'native logout exited with nonzero status: ' + str(status))
        require(virtualmem.is_file() and virtualmem.stat().st_size > 0,
                'native saved user virtualmem did not survive logout')
        saved = evidence / 'lisp.virtualmem'
        # Retain the actual emulator state file, never a manufactured fixture.
        saved.write_bytes(virtualmem.read_bytes())
        record['virtualmem'] = {'path': str(virtualmem), 'retained': saved.name,
                                'size': saved.stat().st_size,
                                'sha256': hashlib.sha256(saved.read_bytes()).hexdigest()}
        require(record['virtualmem']['sha256'] == prior_virtualmem,
                'fast logout unexpectedly altered native SAVEVM image')
        record['status'] = 'passed'
        print('Observed exact source-font native arithmetic result, screenshot before logout, saved user virtualmem and zero exit.')
    except Exception:
        record['error'] = traceback.format_exc()
        print(record['error'], file=sys.stderr)
        raise
    finally:
        if window and medley and medley.poll() is None:
            try:
                capture('failure-native-screen')
            except Exception:
                pass
        for process in reversed(processes):
            if process.poll() is None:
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                    process.wait(timeout=5)
                except (ProcessLookupError, subprocess.TimeoutExpired):
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    process.wait()
        for log in logs:
            log.close()
        (evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')


if __name__ == '__main__':
    main()
