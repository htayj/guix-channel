#!/usr/bin/env python3
"""Compile the installed upstream Minttea basic example and drive it on a PTY."""
import ctypes
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import struct
import subprocess
import sys
import termios
import time

out, evidence, scratch = map(Path, sys.argv[1:4])
compiler, findlib, gcc = map(Path, sys.argv[4:7])
profile = Path(sys.argv[7])

SOURCE_COMMIT = '40ee44920bda53bd2838065374c9b188c06f8cba'
# Git blob id of examples/basic/main.ml at SOURCE_COMMIT (2623 bytes).
BASIC_BLOB = '40b4891184ca911e5e367cf1c6e9abc275fa2d87'
CHOICES = ['Buy empanadas \U0001F95F', 'Buy carrots \U0001F955',
           'Buy cupcakes \U0001F9C1']


def require(condition, message):
    if not condition:
        raise AssertionError(message)


require(os.getuid() == int(os.environ['EXPECTED_UID']), 'namespace changed UID')
require(os.getgid() == int(os.environ['EXPECTED_GID']), 'namespace changed GID')
libc = ctypes.CDLL(None, use_errno=True)
libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                       ctypes.c_ulong, ctypes.c_void_p]
for source, target, kind, flags in [
    (b'/gnu/store', b'/gnu/store', None, 4096),
    (b'/gnu/store', b'/gnu/store', None, 4096 | 32 | 1 | 2 | 4),
    (b'proc', b'/proc', b'proc', 2 | 4 | 8),
]:
    if libc.mount(source, target, kind, flags, None):
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), os.fsdecode(target))
require(bool(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY), 'store is writable')
net_ns = os.readlink('/proc/self/ns/net')
pid_ns = os.readlink('/proc/self/ns/pid')
require(net_ns != os.environ['HOST_NET_NS'], 'network namespace not isolated')
require(pid_ns != os.environ['HOST_PID_NS'], 'PID namespace not isolated')
require(os.getpid() == 1, 'private proc mount lacks PID namespace')
interfaces = [line.split(':')[0].strip()
              for line in Path('/proc/net/dev').read_text().splitlines() if ':' in line]
require(interfaces == ['lo'], 'external network interface present')
for key in ('HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_DATA_HOME',
            'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'):
    Path(os.environ[key]).mkdir(mode=0o700)
os.chdir(scratch)

# The profile's generated environment is the only search-path source.
require(os.environ.get('GUIX_PROFILE') == str(profile), 'wrong temporary profile')
ocamlopt = shutil.which('ocamlopt')
ocamlfind = shutil.which('ocamlfind')
require(ocamlopt and Path(ocamlopt).resolve() ==
        (compiler / 'bin/ocamlopt').resolve(), 'profile selected another compiler')
require(ocamlfind and Path(ocamlfind).resolve() ==
        (findlib / 'bin/ocamlfind').resolve(), 'profile selected another findlib')
require(Path(shutil.which('gcc') or '').resolve() ==
        (gcc / 'bin/gcc').resolve(), 'profile did not export GCC')
profile_environment = {key: os.environ.get(key) for key in
    ('GUIX_PROFILE', 'PATH', 'OCAMLPATH', 'CAML_LD_LIBRARY_PATH', 'OCAMLLIB',
     'LIBRARY_PATH', 'C_INCLUDE_PATH')}
(evidence / 'profile-discovery.json').write_text(
    json.dumps(profile_environment, indent=2) + '\n')


def run(label, command, cwd=None):
    with (evidence / (label + '.stdout')).open('wb') as stdout, \
         (evidence / (label + '.stderr')).open('wb') as stderr:
        subprocess.run(list(map(str, command)), stdin=subprocess.DEVNULL,
                       stdout=stdout, stderr=stderr, check=True, timeout=180,
                       cwd=cwd)
    return (evidence / (label + '.stdout')).read_text()


version = run('compiler-version', [ocamlopt, '-version']).strip()
require(version.startswith('5.2.'), 'recorded compiler is not OCaml 5.2')
findlib_version = run('findlib-compiler-version',
                      [ocamlfind, 'ocamlopt', '-version']).strip()
require(version == findlib_version, 'findlib selected a different compiler')
commit = (out / 'share/minttea/source-commit').read_text().strip()
require(commit == SOURCE_COMMIT, 'wrong source commit')

# Every library the link resolves must come from the recorded toolchain or the
# package's exported dependency closure, never an unrelated OCaml installation.
closure = [Path(line) for line in
           (out / 'share/minttea/consumer-closure').read_text().splitlines() if line]
require(closure and closure[0] == out, 'closure does not start with the output')
for prefix in closure:
    require(str(prefix).startswith('/gnu/store/') and prefix.is_dir(),
            'unrealized closure member ' + str(prefix))
roots = [p.resolve() for p in closure + [compiler, findlib]]
spices_provider = Path((out / 'share/minttea/spices-provider').read_text().strip())
require(spices_provider in closure, 'Spices provider absent from exact closure')
require(spices_provider != out, 'Spices must have its sole standalone provider')
resolution = []
for line in run('query-closure', [ocamlfind, 'query', '-r', '-format',
                                  '%p\t%d\t%m\t%v', 'minttea', 'leaves',
                                  'spices']).splitlines():
    name, directory, meta, package_version = line.split('\t')
    directory, meta = Path(directory).resolve(), Path(meta).resolve()
    for path in (directory, meta):
        require(any(path.is_relative_to(root) for root in roots),
                f'{name} resolved outside the exact closure: {path}')
    provider = {'minttea': out, 'leaves': out, 'spices': spices_provider}.get(name)
    if provider is not None:
        for path in (directory, meta, directory / (name + '.cmxa')):
            require(path.is_file() or path.is_dir(), 'missing artifact: ' + str(path))
            require(path.resolve().is_relative_to(provider.resolve()),
                    'profile discovered another provider of ' + name)
    resolution.append({'package': name, 'directory': str(directory),
                       'meta': str(meta), 'version': package_version})
require({'riot', 'tty', 'minttea', 'leaves', 'spices'} <=
        {entry['package'] for entry in resolution}, 'incomplete library closure')

# Preserve the exact pinned source, then allow only its stale event-pattern
# arity migration to the installed API's (key, modifier) payload.
installed_example = out / 'share/minttea/examples/basic/main.ml'
example_bytes = installed_example.read_bytes()
blob = hashlib.sha1(b'blob %d\0' % len(example_bytes) + example_bytes).hexdigest()
require(blob == BASIC_BLOB, 'installed basic example differs from upstream')
example_text = example_bytes.decode('utf-8')
for choice in CHOICES:
    require(f'"{choice}"' in example_text, 'oracle choice absent from example')
replacements = [
    ('Event.KeyDown (Key "q" | Escape)', 'Event.KeyDown ((Key "q" | Escape), _modifier)'),
    ('Event.KeyDown (Up | Key "k")', 'Event.KeyDown ((Up | Key "k"), _modifier)'),
    ('Event.KeyDown (Down | Key "j")', 'Event.KeyDown ((Down | Key "j"), _modifier)'),
    ('Event.KeyDown (Enter | Space)', 'Event.KeyDown ((Enter | Space), _modifier)'),
]
migrated_text = example_text
for old, new in replacements:
    require(migrated_text.count(old) == 1, 'unexpected upstream pattern: ' + old)
    migrated_text = migrated_text.replace(old, new)
migrated_bytes = migrated_text.encode('utf-8')
(evidence / 'upstream-basic.ml').write_bytes(example_bytes)
(evidence / 'consumer-basic.ml').write_bytes(migrated_bytes)
(evidence / 'source-migration.json').write_text(json.dumps({
    'upstream_git_blob': blob,
    'replacements': replacements,
    'consumer_sha256': hashlib.sha256(migrated_bytes).hexdigest(),
}, indent=2) + '\n')
build_dir = scratch / 'basic'
build_dir.mkdir()
(build_dir / 'main.ml').write_bytes(migrated_bytes)
compile_command = [ocamlfind, 'ocamlopt', '-verbose', '-thread', '-package',
                   'minttea,spices,leaves', '-linkpkg', 'main.ml',
                   '-o', 'minttea-basic.native']
run('link-plan', compile_command[:2] + ['-only-show'] + compile_command[2:],
    cwd=build_dir)
run('compile-basic', compile_command, cwd=build_dir)
binary = build_dir / 'minttea-basic.native'
require(binary.read_bytes()[:4] == b'\x7fELF', 'basic example is not native ELF')


def frame(cursor, selected):
    options = '\n'.join(
        f"{'>' if index == cursor else ' '} [{'x' if index in selected else ' '}] {name}"
        for index, name in enumerate(CHOICES))
    # Upstream view text plus the renderer's trailing newline.
    return ('\nWhat should we buy at the market?\n\n' + options +
            '\n\nPress q to quit.\n\n  \n')


ESC = re.compile(r'\x1b\[[0-?]*[ -/]*[@-~]')
ROW = re.compile(r'^([ >]) \[([ x])\] (.+)$', re.M)
# (label, bytes typed at the terminal, cursor, selected set after the key)
script = [
    ('j', b'j', 1, set()),
    ('k', b'k', 0, set()),
    ('down', b'\x1b[B', 1, set()),
    ('space', b' ', 1, {1}),
    ('down', b'\x1b[B', 2, {1}),
    ('enter', b'\r', 2, {1, 2}),
    ('up', b'\x1b[A', 1, {1, 2}),
    ('space', b' ', 1, {2}),
    ('j', b'j', 2, {2}),
    ('j-wrap', b'j', 0, {2}),
    ('k-wrap', b'k', 2, {2}),
    ('enter', b'\r', 2, set()),
    ('up', b'\x1b[A', 1, set()),
    ('space', b' ', 1, {1}),
]
states = [(0, set())] + [(cursor, selected) for _, _, cursor, selected in script]
# Quit renders the unchanged final view once more before the renderer flushes.
expected_frames = [frame(*state) for state in states] + [frame(*states[-1])]

master, slave = os.openpty()
fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 80, 0, 0))
termios_before = termios.tcgetattr(slave)
require(termios_before[0] & termios.ICRNL, 'PTY Enter would not arrive as newline')
require(termios_before[3] & termios.ICANON and termios_before[3] & termios.ECHO,
        'PTY did not start in cooked mode')
stream = bytearray()


def clean_text(strict=False):
    text = bytes(stream).decode('utf-8', 'strict' if strict else 'ignore')
    return ESC.sub('', text).replace('\r', '')


def pump(seconds, predicate):
    end = time.monotonic() + seconds
    while True:
        ready, _, _ = select.select([master], [], [], 0.05)
        if ready:
            stream.extend(os.read(master, 65536))
        if predicate():
            return True
        if time.monotonic() >= end:
            return False


def shows(count):
    return lambda: clean_text() == ''.join(expected_frames[:count])


def set_controlling_terminal():
    fcntl.ioctl(0, termios.TIOCSCTTY, 0)


stderr_log = (evidence / 'basic.stderr').open('wb')
child = subprocess.Popen([str(binary)], stdin=slave, stdout=slave, stderr=stderr_log,
                         cwd=build_dir, close_fds=True, start_new_session=True,
                         preexec_fn=set_controlling_terminal)
keys = []
try:
    require(pump(30, shows(1)), 'initial upstream view was not rendered')
    require(pump(30, lambda: not termios.tcgetattr(slave)[3] & termios.ICANON),
            'example never entered raw input mode')
    termios_running = termios.tcgetattr(slave)
    require(not termios_running[3] & termios.ECHO, 'raw mode left echo enabled')
    for index, (label, data, cursor, selected) in enumerate(script, start=2):
        os.write(master, data)
        require(pump(30, shows(index)),
                f'key {label} did not produce cursor={cursor} selected={sorted(selected)}')
        keys.append({'key': label, 'bytes': data.decode('ascii'),
                     'cursor': cursor, 'selected': sorted(selected)})
    os.write(master, b'q')
    deadline = time.monotonic() + 30
    while child.poll() is None and time.monotonic() < deadline:
        pump(0.05, lambda: False)
    require(child.poll() is not None, 'q did not terminate the example')
    pump(0.5, lambda: False)
finally:
    if child.poll() is None:
        child.kill()
        child.wait()
    stderr_log.close()
    (evidence / 'tty-stream.bin').write_bytes(bytes(stream))
exit_status = child.returncode
termios_after = termios.tcgetattr(slave)
os.close(slave)
os.close(master)
require(exit_status == 0, f'example exited {exit_status}')
require(termios_after == termios_before, 'terminal modes were not restored')

decoded = clean_text(strict=True)
(evidence / 'tty-decoded.txt').write_text(decoded)
require(decoded == ''.join(expected_frames), 'decoded terminal text differs')
# Independently decode model state from the rendered glyphs.
observed = []
for body in decoded.split('\nWhat should we buy at the market?\n\n')[1:]:
    rows = ROW.findall(body)
    require([name for _, _, name in rows] == CHOICES, 'rendered choices differ')
    observed.append(([marker for marker, _, _ in rows].index('>'),
                     {i for i, (_, mark, _) in enumerate(rows) if mark == 'x'}))
require(observed == states + [states[-1]], 'rendered model states differ')
controls = ESC.findall(bytes(stream).decode('utf-8'))
for opened, closed in (('\x1b[?1049h', '\x1b[?1049l'), ('\x1b[?25l', '\x1b[?25h')):
    last_open = max((i for i, c in enumerate(controls) if c == opened), default=-1)
    last_close = max((i for i, c in enumerate(controls) if c == closed), default=-1)
    require(last_open <= last_close, 'terminal left in ' + repr(opened))

(evidence / 'runtime.json').write_text(json.dumps({
    'status': 'passed', 'uid': os.getuid(), 'gid': os.getgid(),
    'store_read_only': True, 'network_namespace': net_ns, 'pid_namespace': pid_ns,
    'host_network_namespace': os.environ['HOST_NET_NS'],
    'host_pid_namespace': os.environ['HOST_PID_NS'], 'interfaces': interfaces,
    'source_commit': commit, 'basic_example_git_blob': blob,
    'source_migration': replacements,
    'consumer_source_sha256': hashlib.sha256(migrated_bytes).hexdigest(),
    'compiler': str(compiler), 'findlib': str(findlib), 'gcc': str(gcc),
    'spices_provider': str(spices_provider),
    'compiler_version': version, 'library_resolution': resolution,
    'temporary_profile': str(profile),
    'temporary_profile_store': str(profile.resolve()),
    'profile_exported_environment': profile_environment,
    'compiled_binary': str(binary), 'compile_command': list(map(str, compile_command)),
    'pty_keys': keys, 'quit_key': 'q', 'exit_status': exit_status,
    'rendered_states': [{'cursor': c, 'selected': sorted(s)} for c, s in observed],
    'termios_before': repr(termios_before), 'termios_running': repr(termios_running),
    'termios_after': repr(termios_after), 'terminal_controls': sorted(set(controls)),
    'limitations': ['Upstream Dune/mdx suites run in the package build, not here',
                    'Only the basic example is driven on a PTY'],
}, indent=2) + '\n')
print('MINTTEA_BASIC_PTY_OK states=%d keys=%d' % (len(observed), len(keys)))
