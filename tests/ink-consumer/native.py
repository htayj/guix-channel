#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Offline external PTY consumer of an installed node-ink output.

Runs inside private user/mount/net/PID namespaces as the caller's UID with a
recursively read-only /gnu/store.  An ordinary React component written only
against Ink's public render/useInput/useApp/Box/Text API runs as its own Node
process on a real 100x34 pseudo-terminal.  The driver only types bytes at the
PTY master and decodes Ink's actual ANSI output with pyte; it never injects
events or state into the component.
"""
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import socket
import struct
import subprocess
import sys
import termios
import time
import traceback

INK_VERSION = '7.1.1'
REACT_VERSION = '19.2.4'
NESTED = {'yoga-layout': '3.2.1', 'react-reconciler': '0.33.0', 'scheduler': '0.27.0'}
ROWS, COLS = 34, 100
BOX_INNER = 36
TITLE = 'Ink カウンター ✓'
HELP = 'a: +1 · q: quit'
CONTROL = re.compile(rb'\x1b\[[0-?]*[ -/]*[@-~]')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def store_mounts(text):
    mounts = []
    for line in text.splitlines():
        fields = line.split()
        target = re.sub(r'\\([0-7]{3})', lambda match: chr(int(match[1], 8)), fields[4])
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            mounts.append((target, fields[5].split(',')))
    return mounts


def isolate(evidence, mount, module):
    require(os.getuid() == os.geteuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == os.getegid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, identity in namespaces.items():
        require(identity != os.environ['HOST_' + name.upper() + '_NS'], name + ' namespace not private')
    require(os.getpid() == 1, 'driver is not PID 1 of the private PID namespace')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'network namespace has external interfaces')
    (evidence / 'mountinfo-before.txt').write_text(Path('/proc/self/mountinfo').read_text())
    subprocess.run([mount, '--rbind', '/gnu/store', '/gnu/store'], check=True, timeout=20)
    subprocess.run([mount, '--make-rprivate', '/gnu/store'], check=True, timeout=20)
    for target in sorted({target for target, _ in store_mounts(
            Path('/proc/self/mountinfo').read_text())}, key=len, reverse=True):
        subprocess.run([mount, '-o', 'remount,bind,ro', target], check=True, timeout=20)
    after = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-after.txt').write_text(after)
    mounts = store_mounts(after)
    require(mounts and all('ro' in flags for _, flags in mounts), 'store not recursively read-only')
    # A real write attempt into the tested package must hit the read-only mount.
    try:
        os.open(module / '.ink-consumer-write-probe', os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        raise RuntimeError('installed package accepted a write')
    except OSError as error:
        require(error.errno == errno.EROFS, 'store write failed without EROFS: ' + str(error))
        write_probe = errno.errorcode[error.errno]
    result = {'uid': os.getuid(), 'gid': os.getgid(), 'pid': os.getpid(),
              'namespaces': namespaces, 'interfaces': interfaces, 'store_mounts': mounts,
              'store_write_probe': write_probe,
              'uid_map': Path('/proc/self/uid_map').read_text(),
              'gid_map': Path('/proc/self/gid_map').read_text()}
    save(evidence / 'isolation.json', result)
    return result


def manifest(directory):
    return json.loads((directory / 'package.json').read_text())


def inside(path, root):
    return Path(os.path.realpath(path)).is_relative_to(Path(os.path.realpath(root)))


def inspect_installed(out):
    """The output installs Ink, its private runtime and one sibling peer React."""
    modules = out / 'lib/node_modules'
    ink, react = modules / 'ink', modules / 'react'
    for directory in (ink, react):
        require(directory.is_dir() and not directory.is_symlink(), 'missing installed ' + directory.name)
    ink_manifest, react_manifest = manifest(ink), manifest(react)
    require(ink_manifest['name'] == 'ink' and ink_manifest['version'] == INK_VERSION, 'wrong Ink version')
    require(ink_manifest.get('type') == 'module', 'Ink is not an ES module package')
    require(react_manifest['name'] == 'react' and react_manifest['version'] == REACT_VERSION,
            'wrong peer React version')
    peer = ink_manifest.get('peerDependencies', {}).get('react')
    require(peer is not None, 'Ink does not declare its React peer')
    entry = ink / 'build/index.js'
    require(entry.is_file() and (ink / 'build/index.d.ts').is_file(), 'Ink build/types missing')
    # The single React instance is the sibling; Ink must not carry its own copy.
    require(not (ink / 'node_modules/react').exists(), 'Ink bundles a second React')
    nested = {}
    for name, version in NESTED.items():
        directory = ink / 'node_modules' / name
        require(directory.is_dir(), 'missing nested ' + name)
        require(inside(directory, out), name + ' resolves outside OUTPUT')
        require(manifest(directory)['version'] == version, 'wrong nested ' + name + ' version')
        nested[name] = {'path': str(directory), 'realpath': os.path.realpath(directory),
                        'symlink': directory.is_symlink(), 'version': version}
    return {'ink': str(ink), 'react': str(react), 'ink_version': INK_VERSION,
            'react_version': REACT_VERSION, 'react_peer_range': peer,
            'ink_exports': ink_manifest.get('exports'), 'nested': nested,
            'entry_sha256': sha256(entry)}


def preflight(app, out, node, env, evidence):
    """Record every module the consumer's imports resolve to, outside the PTY."""
    trace = app / 'resolve-trace.jsonl'
    command = [str(node / 'bin/node'), '--import', './resolve-trace.mjs', 'resolution-probe.mjs']
    with (evidence / 'resolution.stdout').open('wb') as stdout, \
            (evidence / 'resolution.stderr').open('wb') as stderr:
        subprocess.run(command, cwd=app, env=dict(env, INK_RESOLVE_TRACE=str(trace)),
                       stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
                       check=True, timeout=120)
    require((evidence / 'resolution.stderr').read_bytes() == b'', 'resolution probe wrote stderr')
    probe = json.loads((evidence / 'resolution.stdout').read_text())
    require(probe['reactVersion'] == REACT_VERSION, 'consumer loaded another React')
    # Box is a React.forwardRef object; the others are plain functions.
    require(probe['api'] == {'render': 'function', 'useInput': 'function', 'useApp': 'function',
                             'Box': 'object', 'Text': 'function'}, 'public Ink API incomplete')
    entries = [json.loads(line) for line in trace.read_text().splitlines()]
    shutil.copyfile(trace, evidence / 'resolve-trace.jsonl')
    files, builtins = set(), set()
    react_roots = set()
    for entry in entries:
        url = entry['url']
        if url.startswith('node:'):
            builtins.add(url)
            continue
        require(url.startswith('file://'), 'unexpected module URL ' + url)
        path = Path(url[len('file://'):])
        real = Path(os.path.realpath(path))
        if real.is_relative_to(app.resolve()):
            require(real.name in {'resolution-probe.mjs', 'resolve-trace.mjs'},
                    'consumer resolved unexpected local file ' + str(real))
            continue
        require(real.is_relative_to(out), 'module resolved outside OUTPUT: ' + str(real))
        files.add(str(real))
        if entry['specifier'] == 'react' or entry['specifier'].startswith('react/'):
            react_roots.add(str(real))
    react_entry = os.path.realpath(out / 'lib/node_modules/react/index.js')
    react_main = {f for f in react_roots if Path(f).name == 'index.js'}
    require(react_main == {react_entry}, 'react resolved to more than the sibling instance')
    yoga = [f for f in files if '/yoga-layout/' in f]
    require(yoga and all(Path(f).is_relative_to(os.path.realpath(
        out / 'lib/node_modules/ink/node_modules/yoga-layout')) for f in yoga),
        'yoga-layout did not resolve to the installed source-built binding')
    result = {'command': command, 'probe': probe, 'module_files': sorted(files),
              'module_file_count': len(files), 'builtins': sorted(builtins),
              'react_resolutions': sorted(react_roots), 'yoga_files': sorted(yoga)}
    save(evidence / 'resolution.json', result)
    return result


def char_tuple(char):
    return (char.data, char.fg, char.bg, char.bold, char.italics, char.underscore,
            char.strikethrough, char.reverse, char.blink)


def expected_frame(count, wcwidth):
    """Exact cell grid (data, fg, bg, bold, ...) of the counter box."""
    blank = (' ', 'default', 'default', False, False, False, False, False, False)
    grid = [[blank] * COLS for _ in range(ROWS)]

    def put(row, column, text, fg='default', bold=False):
        for character in text:
            width = wcwidth(character)
            require(width in (1, 2), 'unexpected width for ' + repr(character))
            grid[row][column] = (character, fg, 'default', bold, False, False, False, False, False)
            if width == 2:
                grid[row][column + 1] = ('', fg, 'default', bold, False, False, False, False, False)
            column += width
        return column

    def width(text):
        return sum(wcwidth(character) for character in text)

    put(0, 0, '╭' + '─' * (BOX_INNER + 2) + '╮', 'cyan')
    for row in (1, 2, 3):
        put(row, 0, '│', 'cyan')
        put(row, BOX_INNER + 3, '│', 'cyan')
    put(1, 2, TITLE, 'green', True)
    # pyte names SGR 33 (Ink/chalk "yellow") by its ECMA-48 name "brown".
    put(2, put(2, 2, 'count: '), str(count), 'brown', True)
    put(3, 2, HELP, 'magenta')
    put(4, 0, '╰' + '─' * (BOX_INNER + 2) + '╯', 'cyan')
    require(width(TITLE) == 16 and width(HELP) == 15, 'unexpected oracle widths')
    return grid


class Terminal:
    def __init__(self, pyte, evidence):
        self.master, self.slave = os.openpty()
        fcntl.ioctl(self.master, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.ByteStream(self.screen)
        self.raw = bytearray()
        self.evidence = evidence
        self.snapshots = []

    def pump(self, seconds, predicate):
        end = time.monotonic() + seconds
        while True:
            ready, _, _ = select.select([self.master], [], [], 0.05)
            if ready:
                try:
                    data = os.read(self.master, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    data = b''
                if data:
                    self.raw.extend(data)
                    self.stream.feed(data)
            if predicate():
                return True
            if time.monotonic() >= end:
                return False

    def grid(self):
        return [[char_tuple(self.screen.buffer[row][column]) for column in range(COLS)]
                for row in range(ROWS)]

    def snapshot(self, label):
        display = list(self.screen.display)
        record = {'label': label, 'raw_offset': len(self.raw),
                  'cursor': [self.screen.cursor.x, self.screen.cursor.y],
                  'cursor_hidden': self.screen.cursor.hidden, 'display': display}
        self.snapshots.append(record)
        (self.evidence / ('screen-%02d-%s.txt' % (len(self.snapshots), label))).write_text(
            '\n'.join(display) + '\n')
        save(self.evidence / ('cells-%02d-%s.json' % (len(self.snapshots), label)), {
            'fields': ['data', 'fg', 'bg', 'bold', 'italics', 'underscore',
                       'strikethrough', 'reverse', 'blink'],
            'geometry': [COLS, ROWS], 'cursor': record['cursor'],
            'cursor_hidden': record['cursor_hidden'], 'cells': self.grid(),
        })
        return record


def drive(app, node, env, evidence, pyte, wcwidth):
    term = Terminal(pyte, evidence)
    termios_before = termios.tcgetattr(term.slave)
    require(termios_before[3] & termios.ICANON and termios_before[3] & termios.ECHO,
            'PTY did not start in cooked mode')

    def set_controlling_terminal():
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    def frame_matches(count, extra_rows=()):
        expected = expected_frame(count, wcwidth)
        for row, text in extra_rows:
            for column, character in enumerate(text):
                expected[row][column] = (character, 'default', 'default',
                                         False, False, False, False, False, False)
        return lambda: term.grid() == expected

    command = [str(node / 'bin/node'), 'counter.mjs']
    child = subprocess.Popen(command, cwd=app, env=env, stdin=term.slave, stdout=term.slave,
                             stderr=term.slave, close_fds=True, start_new_session=True,
                             preexec_fn=set_controlling_terminal)
    steps = []
    try:
        require(term.pump(60, frame_matches(0)), 'initial counter=0 frame was not rendered exactly')
        require(term.pump(30, lambda: not termios.tcgetattr(term.slave)[3] & termios.ICANON),
                'Ink never put the terminal into raw mode')
        termios_running = termios.tcgetattr(term.slave)
        require(not termios_running[3] & termios.ECHO, 'raw mode left echo enabled')
        initial = term.snapshot('initial')
        require(initial['cursor'] == [0, 5] and initial['cursor_hidden'],
                'running cursor is not hidden below the frame')
        steps.append({'input': None, 'count': 0, 'screen': initial})
        for count in (1, 2):
            os.write(term.master, b'a')
            require(term.pump(30, frame_matches(count)), f'key a did not render counter={count}')
            shot = term.snapshot(f'after-a-{count}')
            require(shot['cursor'] == [0, 5] and shot['cursor_hidden'], 'cursor moved or reappeared')
            steps.append({'input': 'a', 'count': count, 'screen': shot})
        os.write(term.master, b'q')
        deadline = time.monotonic() + 30
        while child.poll() is None and time.monotonic() < deadline:
            term.pump(0.05, lambda: False)
        require(child.poll() is not None, 'q did not terminate the consumer')
        term.pump(1, lambda: False)
    finally:
        if child.poll() is None:
            child.kill()
            child.wait()
        (evidence / 'tty-stream.bin').write_bytes(bytes(term.raw))
        term.snapshot('process-ended')
    exit_status = child.returncode
    termios_after = termios.tcgetattr(term.slave)
    require(exit_status == 0, f'consumer exited {exit_status}')
    require(termios_after == termios_before, 'terminal modes were not restored')
    final_line = 'INK_COUNTER_EXIT count=2'
    require(frame_matches(2, [(5, final_line)])(), 'final screen differs from count=2 + exit line')
    final = term.snapshot('final')
    require(final['cursor'] == [0, 6] and not final['cursor_hidden'], 'cursor not restored at exit')
    steps.append({'input': 'q', 'count': 2, 'screen': final})
    os.close(term.slave)
    os.close(term.master)
    raw = bytes(term.raw)
    raw.decode('utf-8')
    controls = CONTROL.findall(raw)
    private = [c.decode() for c in controls if c.startswith(b'\x1b[?')]
    require('\x1b[?1049h' not in private, 'unexpected alternate screen')
    hide = [i for i, c in enumerate(private) if c == '\x1b[?25l']
    show = [i for i, c in enumerate(private) if c == '\x1b[?25h']
    require(hide and show and max(show) > max(hide), 'cursor visibility not restored')
    sync = [c for c in private if c in ('\x1b[?2026h', '\x1b[?2026l')]
    require(sync == ['\x1b[?2026h', '\x1b[?2026l'] * (len(sync) // 2),
            'synchronized-output brackets are unbalanced')
    sgr = sorted({c.decode() for c in controls if c.endswith(b'm')})
    for code in ('\x1b[36m', '\x1b[32m', '\x1b[33m', '\x1b[35m', '\x1b[1m', '\x1b[22m', '\x1b[39m'):
        require(code in sgr, 'missing SGR ' + repr(code))
    return {'command': command, 'geometry': {'columns': COLS, 'rows': ROWS},
            'steps': [{k: v for k, v in step.items() if k != 'screen'} |
                      {'display_rows_0_6': step['screen']['display'][:7],
                       'cursor': step['screen']['cursor'],
                       'cursor_hidden': step['screen']['cursor_hidden']} for step in steps],
            'exit_status': exit_status, 'stdout_exit_line': final_line,
            'termios_before': repr(termios_before), 'termios_running': repr(termios_running),
            'termios_after': repr(termios_after), 'private_modes': private,
            'sgr': sgr, 'tty_bytes': len(raw), 'tty_sha256': hashlib.sha256(raw).hexdigest()}


def main():
    out, evidence, scratch, templates = map(Path, sys.argv[1:5])
    mount, node = sys.argv[5], Path(sys.argv[6])
    for site in sys.argv[7:]:
        sys.path.insert(0, site)
    record = {'status': 'failed', 'output': str(out)}
    try:
        import pyte
        from wcwidth import wcwidth
        module = out / 'lib/node_modules/ink'
        record['isolation'] = isolate(evidence, mount, module)
        record['installed'] = inspect_installed(out)
        env = {'PATH': '', 'LC_ALL': 'C.UTF-8', 'TERM': 'xterm-256color'}
        for key in ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME',
                    'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'):
            Path(os.environ[key]).mkdir(mode=0o700, parents=True)
            env[key] = os.environ[key]
        version = subprocess.run([str(node / 'bin/node'), '--version'], env=env, check=True,
                                 capture_output=True, text=True, timeout=60).stdout.strip()
        require(int(version.lstrip('v').split('.')[0]) >= 22, 'Node does not satisfy Ink engines >=22')
        record['node'] = {'path': str(node), 'version': version}
        app = scratch / 'app'
        (app / 'node_modules').mkdir(parents=True)
        for name in ('counter.mjs', 'resolution-probe.mjs', 'resolve-trace.mjs'):
            shutil.copyfile(templates / name, app / name)
            shutil.copyfile(templates / name, evidence / name)
        (app / 'package.json').write_text(json.dumps(
            {'name': 'ink-external-consumer', 'private': True, 'type': 'module'}) + '\n')
        for name in ('ink', 'react'):
            os.symlink(out / 'lib/node_modules' / name, app / 'node_modules' / name)
        record['consumer'] = {'counter_sha256': sha256(app / 'counter.mjs'),
                              'links': {name: os.readlink(app / 'node_modules' / name)
                                        for name in ('ink', 'react')}}
        record['resolution'] = preflight(app, out, node, env, evidence)
        record['pty'] = drive(app, node, env, evidence, pyte, wcwidth)
        record['status'] = 'passed'
        record['limitations'] = [
            'pyte models the terminal; no physical terminal emulator renders the stream',
            'Only ordinary single-byte keys a and q are exercised; resize, paste and Ctrl+C are not',
        ]
        print('INK_PTY_COUNTER_OK counts=0,1,2 exit=0 geometry=100x34')
    except BaseException as error:
        record['error'] = ''.join(traceback.format_exception(error))
        raise
    finally:
        save(evidence / 'evidence.json', record)


if __name__ == '__main__':
    main()
