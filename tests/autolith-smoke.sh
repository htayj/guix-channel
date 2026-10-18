#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Ordinary external consumer of an already-built output, never a package build.
# GUIX=/absolute/path/to/guix sh tests/autolith-smoke.sh OUTPUT EVIDENCE
set -eu
umask 077
fail () { printf 'autolith smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s OUTPUT EVIDENCE\n' "$0" >&2; exit 64; }
guix_bin=$(readlink -f -- "$(command -v "${GUIX:-guix}")")
output=$(realpath -e -- "$1")
test "$output" = "$1" && test "$(dirname -- "$output")" = /gnu/store \
    || fail 'OUTPUT must be a canonical direct /gnu/store output'
test -x "$output/bin/autolith" || fail 'missing native autolith launcher'
evidence=$(realpath -m -- "$2")
test "$evidence" = "$2" && test ! -e "$evidence" && test ! -L "$evidence" \
    || fail 'EVIDENCE must be a fresh nonexistent canonical absolute path'
case "$evidence/" in /gnu/store/*) fail 'EVIDENCE must be outside store' ;; esac
find_output () {
    file=$1
    shift
    for item in $("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$@"); do
        if test -e "$item/$file"; then printf '%s\n' "$item"; return 0; fi
    done
    fail "cannot resolve external observer: $file"
}
# Only generic observers are realized; OUTPUT and Autolith sources are not built.
python=$(find_output bin/python3 '--expression=(@ (gnu packages python) python)')
pyte=$(find_output / '--expression=(@ (gnu packages python-xyz) python-pyte)')
wcwidth=$(find_output / '--expression=(@ (gnu packages python-xyz) python-wcwidth)')
unshare=$(find_output bin/unshare util-linux)
xorg=$(find_output bin/Xvfb xorg-server)
xterm=$(find_output bin/xterm xterm)
font=$(find_output share/fonts/X11/misc font-misc-misc)
magick=$(find_output bin/import imagemagick)
modules=
for directory in "$pyte"/lib/python*/site-packages "$wcwidth"/lib/python*/site-packages; do
    test -d "$directory" || fail 'missing observer Python modules'
    modules=${modules:+$modules:}$directory
done
mkdir -p -- "$evidence"
printf '%s\n' "$output" >"$evidence/store-output.txt"
"$guix_bin" gc -R "$output" >"$evidence/runtime-closure.txt"
before=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
# Keep the exact external observer with the evidence. It never imports Autolith,
# changes source, injects user configuration, or invokes a private Lisp API.
cat >"$evidence/consumer.py" <<'PY'
import codecs
from copy import deepcopy
import ctypes as C
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import select
import signal
import socket
import struct
import subprocess
import sys
import termios
import time
import traceback
import tty

for directory in os.environ['OBSERVER_MODULES'].split(':'):
    sys.path.append(directory)
import pyte

ROWS, COLS = 48, 120
REVISION = '68db763eaae60f5e930c195eba4c76ac029b0781'


def require(value, message):
    if not value:
        raise AssertionError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def enable_private_loopback():
    # A fresh net namespace has lo DOWN. Autolith's native local daemons
    # require localhost TCP, not Internet access. Raise only this namespace's
    # loopback using retained user-namespace capabilities; preserve its flags.
    require(socket.if_nameindex() == [(1, 'lo')], 'network interface leaked')
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as control:
        request = struct.pack('16sH22x', b'lo', 0)
        before = struct.unpack_from('H', fcntl.ioctl(control, 0x8913, request), 16)[0]
        fcntl.ioctl(control, 0x8914, struct.pack('16sH22x', b'lo', before | 1))
        after = struct.unpack_from('H', fcntl.ioctl(control, 0x8913, request), 16)[0]
    require(after & 1 and after & 8, 'private lo is not UP and LOOPBACK')
    require((after & before) == before, 'loopback flags were lost')
    require(socket.if_nameindex() == [(1, 'lo')], 'external interface appeared')
    ipv4_routes = Path('/proc/net/route').read_text()
    require(len(ipv4_routes.splitlines()) <= 1, 'external IPv4 route leaked')
    ipv6_routes = Path('/proc/net/ipv6_route').read_text()
    for line in ipv6_routes.splitlines():
        fields = line.split()
        # Linux also reports unreachable ::/0 sentinels on lo. They do not
        # provide an egress route; the only reachable destination may be ::1.
        require(fields[-1] == 'lo' and fields[4] == '0' * 32 and
                ((fields[0] == '0' * 31 + '1' and fields[1] == '80') or
                 (fields[0] == '0' * 32 and int(fields[8], 16) & 0x200)),
                'external IPv6 route leaked')
    payload = b'autolith-private-localhost-transport'
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.settimeout(3)
        listener.bind(('127.0.0.1', 0))
        listener.listen(1)
        address = listener.getsockname()
        with socket.create_connection(address, timeout=3) as client:
            with listener.accept()[0] as server:
                server.settimeout(3)
                client.sendall(payload)
                received = b''
                while len(received) < len(payload):
                    chunk = server.recv(len(payload) - len(received))
                    require(chunk, 'private TCP probe closed early')
                    received += chunk
                require(received == payload, 'private TCP request changed')
                server.sendall(received)
                echoed = b''
                while len(echoed) < len(payload):
                    chunk = client.recv(len(payload) - len(echoed))
                    require(chunk, 'private TCP echo closed early')
                    echoed += chunk
                require(echoed == payload, 'private TCP response changed')
    return dict(flags_before=before, flags_after=after, up=True, loopback=True,
                tcp_roundtrip=True, tcp_address=list(address),
                ipv4_routes=ipv4_routes, ipv6_routes=ipv6_routes,
                interfaces=socket.if_nameindex())


def mount(source, target, flags, filesystem=None, data=None):
    libc = C.CDLL(None, use_errno=True)
    libc.mount.argtypes = [C.c_char_p, C.c_char_p, C.c_char_p, C.c_ulong, C.c_char_p]
    libc.mount.restype = C.c_int
    encode = lambda value: None if value is None else os.fsencode(value)
    if libc.mount(encode(source), encode(target), encode(filesystem), flags, encode(data)):
        error = C.get_errno()
        raise OSError(error, os.strerror(error), str(target))


def store_mounts():
    text = Path('/proc/self/mountinfo').read_text()
    entries = []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in [('\\040', ' '), ('\\011', '\t'), ('\\012', '\n'), ('\\134', '\\')]:
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            entries.append(dict(target=target, options=fields[5].split(','),
                                optional=fields[6:fields.index('-')]))
    return text, entries


def identity(pid):
    proc = Path('/proc') / str(pid)
    result = dict(pid=pid, namespaces={})
    for kind in ('user', 'mnt', 'net', 'pid'):
        actual = os.readlink(proc / 'ns' / kind)
        require(actual != os.environ['HOST_' + kind.upper()], 'host namespace leaked: ' + kind)
        require(actual == os.readlink('/proc/self/ns/' + kind), 'native process escaped namespace')
        result['namespaces'][kind] = actual
    fields = dict(line.split(':', 1) for line in (proc / 'status').read_text().splitlines() if ':' in line)
    for key, field in [('uid', 'Uid'), ('gid', 'Gid')]:
        expected = int(os.environ['HOST_' + key.upper()])
        require([int(x) for x in fields[field].split()] == [expected] * 4,
                'native caller identity changed: ' + field)
        mapping = (proc / (key + '_map')).read_text()
        require([int(x) for x in mapping.split()] == [expected, expected, 1],
                'not an exact same-identity mapping')
        result[key + '_map'] = mapping
    result['exe'] = os.readlink(proc / 'exe')
    return result


def errors(text):
    # Do not mistake help descriptions mentioning recovery/errors for failures.
    pattern = (r'(?im)(unhandled .*condition|debugger invoked|fatal error|'
               r'Autolith could not start|Autolith bootstrap failed|'
               r'failed to (?:load|save|build|open|initialize)|'
               r'cannot (?:load|open|find)|undefined (?:function|symbol)|'
               r'segmentation fault|corruption warning|'
               r'Pristine recovery image is missing|fast startup image is missing|'
               r'^\s*(?:error:|✗ error|WARNING:)|ASDF/[A-Z-]+:.*ERROR)')
    found = re.search(pattern, text)
    require(found is None, 'native diagnostic even if exit zero: ' + (found.group(0) if found else ''))


def images(data):
    active = list(data.rglob('autolith-active.core'))
    recovery = list(data.rglob('autolith-recovery.core'))
    require(len(active) == len(recovery) == 1, 'expected exactly one materialized active/recovery pair')
    require(active[0].parent.parent == recovery[0].parent.parent, 'image pair not published together')
    pair = active[0].parent.parent
    require((pair / 'identity').is_file(), 'missing image identity')
    result = {}
    for core, marker in [(active[0], '(:SBCL-GENERATIONS-IMAGE-MANIFEST :VERSION 1'),
                         (recovery[0], '(:RECOVERY-IMAGE :VERSION 2')]:
        manifest = core.parent / 'manifest.sexp'
        require(manifest.read_text().startswith(marker), 'invalid native image manifest')
        for path in (core, manifest):
            require(path.is_file() and not path.is_symlink(), 'image artifact is not a regular file')
            stat = path.stat()
            require(stat.st_size > 0 and stat.st_uid == os.getuid(), 'empty or foreign-owned image artifact')
            result[str(path.relative_to(data))] = dict(sha256=sha(path), size=stat.st_size,
                                                     inode=stat.st_ino, mtime_ns=stat.st_mtime_ns)
    require(active[0].stat().st_mode & 0o200, 'active core is not user mutable')
    result[str((pair / 'identity').relative_to(data))] = dict(sha256=sha(pair / 'identity'))
    return result


def cli(executable, args, env, root, evidence, label):
    # Stop before exec so even very short --version processes have a checked
    # native namespace/identity. exec preserves that identity and namespaces.
    pid = os.fork()
    if pid == 0:
        try:
            os.chdir(root / 'work')
            for fd, name in [(0, '/dev/null'), (1, str(evidence / (label + '.stdout'))),
                             (2, str(evidence / (label + '.stderr')))]:
                opened = os.open(name, os.O_RDONLY if fd == 0 else os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                os.dup2(opened, fd)
                if opened > 2:
                    os.close(opened)
            os.kill(os.getpid(), signal.SIGSTOP)
            os.execve(str(executable), [str(executable)] + args, env)
        except BaseException:
            os.write(2, traceback.format_exc().encode())
            os._exit(127)
    try:
        _, status = os.waitpid(pid, os.WUNTRACED)
        require(os.WIFSTOPPED(status), 'CLI child failed before native exec')
        receipt = identity(pid)
        os.kill(pid, signal.SIGCONT)
        deadline = time.monotonic() + 900
        while True:
            done, status = os.waitpid(pid, os.WNOHANG)
            if done:
                break
            require(time.monotonic() < deadline, label + ' timeout')
            time.sleep(.1)
        receipt.update(argv=[str(executable)] + args, exit_status=os.waitstatus_to_exitcode(status))
        record(evidence / (label + '.json'), receipt)
        text = (evidence / (label + '.stdout')).read_text()
        stderr = (evidence / (label + '.stderr')).read_text()
        errors(text + '\n' + stderr)
        require(receipt['exit_status'] == 0, label + ' failed')
        return text
    except BaseException:
        try:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
        except ProcessLookupError:
            pass
        raise


class Screen(pyte.Screen):
    last_graphic = ''
    def draw(self, data):
        super().draw(data)
        if data:
            self.last_graphic = data[-1]
    def repeat_character(self, count=1):
        if self.last_graphic:
            super().draw(self.last_graphic * (count or 1))

    def set_mode(self, *modes, **kwargs):
        if kwargs.get('private') and any(mode in (47, 1047, 1049) for mode in modes):
            if getattr(self, '_primary', None) is None:
                self._primary = {name: deepcopy(getattr(self, name)) for name in
                                 ('buffer', 'cursor', 'savepoints', 'margins', 'mode',
                                  'charset', 'g0_charset', 'g1_charset', 'tabstops')}
                super().reset()
        super().set_mode(*modes, **kwargs)

    def reset_mode(self, *modes, **kwargs):
        super().reset_mode(*modes, **kwargs)
        if kwargs.get('private') and any(mode in (47, 1047, 1049) for mode in modes):
            if getattr(self, '_primary', None) is not None:
                for name, value in self._primary.items():
                    setattr(self, name, value)
                self._primary = None
                self.dirty.update(range(self.lines))


class Stream(pyte.Stream):
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Terminal:
    def __init__(self, executable, env, root, evidence):
        self.evidence = evidence
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.raw = (evidence / 'terminal.pty').open('xb')
        self.inputs = []
        self.status = None
        self.eof = False
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(str(executable), [str(executable)], env)
            except BaseException:
                os.write(2, traceback.format_exc().encode())
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display)

    def read(self, delay=.1):
        # Relay only responses emitted by the actual xterm. All interactive
        # application input, including terminal protocol replies, uses its PTY.
        if not self.eof and select.select([0], [], [], 0)[0]:
            response = os.read(0, 4096)
            require(response, 'xterm input stream closed')
            self.send(response)
        if not self.eof and select.select([self.fd], [], [], delay)[0]:
            try:
                data = os.read(self.fd, 65536)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise
                data = b''
            if data:
                self.raw.write(data)
                self.raw.flush()
                self.stream.feed(self.decoder.decode(data))
                # Forward unchanged bytes to the actual live xterm renderer.
                os.write(1, data)
                errors(self.text())
            else:
                self.eof = True
        if self.status is None:
            done, status = os.waitpid(self.pid, os.WNOHANG)
            if done:
                self.status = os.waitstatus_to_exitcode(status)

    def wait(self, predicate, label, seconds=90):
        deadline = time.monotonic() + seconds
        while True:
            self.read()
            if predicate(self.text()):
                self.snapshot(label)
                return
            require(self.status is None, 'native session exited before ' + label)
            require(time.monotonic() < deadline, 'timed out waiting for ' + label + '\n' + self.text())

    def send(self, data):
        self.inputs.append(dict(bytes_hex=data.hex(), time=time.monotonic()))
        record(self.evidence / 'terminal-input.json', self.inputs)
        os.write(self.fd, data)

    def submit_form(self, form, label):
        # Pinned Clinedi transport.lisp deliberately treats a multi-character
        # burst containing CR/LF as unbracketed paste, never as submission.
        # Type the form, observe the actual editor draft, then press Enter
        # separately, after its 2ms input-burst collection window.
        self.send(form.encode('utf-8'))
        self.wait(lambda text: any(line.rstrip() == '* ' + form
                                  for line in text.splitlines()), label + '-draft')
        time.sleep(.02)
        self.send(b'\r')

    def snapshot(self, label):
        (self.evidence / ('terminal-' + label + '.txt')).write_text(self.text() + '\n')

    def stop(self):
        if self.status is None:
            try:
                os.killpg(self.pid, signal.SIGKILL)
                os.waitpid(self.pid, 0)
            except ProcessLookupError:
                pass
        os.close(self.fd)
        self.raw.close()


def play(output, root, evidence, env):
    original = termios.tcgetattr(0)
    tty.setraw(0)
    terminal = None
    try:
        terminal = Terminal(output / 'bin/autolith', env, root, evidence)
        terminal.wait(lambda text: 'Press Space to start onboarding.' in text, 'first-boot')
        record(evidence / 'terminal-native-identity.json', identity(terminal.pid))
        # The stable launcher waits on SBCL. Inspect every live descendant,
        # including the actual saved-image runtime, not only the shell parent.
        descendants = []
        pending = [terminal.pid]
        while pending:
            pid = pending.pop()
            descendants.append(identity(pid))
            children = Path('/proc') / str(pid) / 'task' / str(pid) / 'children'
            pending.extend(int(child) for child in children.read_text().split())
        require(any('/sbcl' in item['exe'] for item in descendants), 'no native SBCL runtime observed')
        record(evidence / 'terminal-native-processes.json', descendants)
        terminal.send(b' ')
        terminal.wait(lambda text: 'Welcome to Autolith' in text and 'Esc' in text, 'onboarding')
        terminal.send(b'\x1b')
        # The authored Escape path exits the tour, not the application.
        terminal.wait(lambda text: 'Welcome to Autolith' not in text and
                      '❯ Ask Autolith anything. Type (help) for operations.' in text, 'listener')
        terminal.submit_form('(help)', 'help')
        terminal.wait(lambda text: 'Autolith help' in text and 'Everyday commands' in text and
                      'Help topics' in text, 'help')
        # Both the PTY parser and real xterm see identical bytes, but the
        # X server paints asynchronously. Allow the already-asserted frame
        # to reach the native window before capturing actual pixels.
        time.sleep(.3)
        subprocess.run([os.environ['IMPORT'], '-display', os.environ['DISPLAY'], '-window', 'root',
                        str(evidence / 'terminal-help.png')], check=True, timeout=20, env=env)
        screenshot = evidence / 'terminal-help.png'
        require(screenshot.read_bytes().startswith(b'\x89PNG\r\n\x1a\n'), 'native capture is not PNG')
        terminal.submit_form("(help 'quit)", 'quit-help')
        terminal.wait(lambda text: 'leave Autolith' in text and 'exits cleanly' in text, 'quit-help')
        terminal.submit_form('(+ 20 22)', 'local-lisp-42')
        terminal.wait(lambda text: re.search(r'⇒\s+42\b', text) is not None, 'local-lisp-42')
        terminal.submit_form('(quit)', 'quit')
        deadline = time.monotonic() + 60
        while terminal.status is None or not terminal.eof:
            terminal.read()
            require(time.monotonic() < deadline, 'ordinary (quit) did not terminate cleanly')
        errors((evidence / 'terminal.pty').read_text(errors='replace'))
        require(terminal.status == 0, 'native terminal exited nonzero')
        record(evidence / 'terminal-result.json', dict(success=True, exit_status=terminal.status,
               help=True, quit_help=True, local_lisp_result=42, screenshot=screenshot.name,
               screenshot_sha256=sha(screenshot), input='real PTY bytes only'))
    except BaseException:
        if terminal:
            terminal.snapshot('failure')
        (evidence / 'terminal-failure.txt').write_text(traceback.format_exc())
        raise
    finally:
        if terminal:
            terminal.stop()
        termios.tcsetattr(0, termios.TCSANOW, original)


def native_environment(root):
    env = dict(HOME=str(root / 'home'), PATH='', TERM='xterm-256color', LC_ALL='C.UTF-8',
               TMPDIR=str(root / 'tmp'), XDG_CONFIG_HOME=str(root / 'config'),
               XDG_DATA_HOME=str(root / 'data'), XDG_STATE_HOME=str(root / 'state'),
               XDG_CACHE_HOME=str(root / 'cache'), XDG_RUNTIME_DIR=str(root / 'runtime'),
               AUTOLITH_SESSION_STYLE='direct', AUTOLITH_NO_UPDATE_CHECK='1')
    for variable in ('DISPLAY', 'TERMINFO', 'TERMINFO_DIRS'):
        if os.environ.get(variable):
            env[variable] = os.environ[variable]
    return env


def inside(output, evidence):
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    proof = dict(success=False, upstream_revision=REVISION, config_injected=False,
                 provider_authentication_requested=False, inference_input_sent=False,
                 credentials_inherited=False,
                 primary_sources=[
                     'https://github.com/lambda-symbolics/autolith/blob/' + REVISION + '/' + path
                     for path in ('docs/guide.org', 'docs/onboarding-sources.org',
                                  'src/application/runtime.lisp', 'src/application/help.lisp',
                                  'src/application/commands.lisp', 'nix/package.nix')])
    server = terminal = None
    read_fd = write_fd = None
    try:
        proof['namespace'] = identity(os.getpid())
        mount(None, '/', 16384 | 262144)
        (evidence / 'mountinfo-before.txt').write_text(store_mounts()[0])
        mount('/gnu/store', '/gnu/store', 4096 | 16384)
        mount('/gnu/store', '/gnu/store', 262144 | 16384)
        for target in sorted({entry['target'] for entry in store_mounts()[1]}, key=len, reverse=True):
            mount(target, target, 4096 | 32 | 1)
        text, entries = store_mounts()
        require(entries and all('ro' in entry['options'] and 'rw' not in entry['options'] and
                not any(x.startswith(('shared:', 'master:')) for x in entry['optional'])
                for entry in entries), 'store is not recursively read-only/private')
        (evidence / 'mountinfo-after.txt').write_text(text)
        mount('tmpfs', '/tmp', 2 | 4, 'tmpfs', 'mode=1777')
        retained = Path('/tmp/autolith-evidence')
        retained.mkdir(mode=0o700)
        mount('/proc/self/fd/' + str(descriptor), retained, 4096)
        evidence = retained
        mount('tmpfs', '/run', 2 | 4, 'tmpfs', 'mode=755')
        proof['private_loopback'] = enable_private_loopback()
        proof['network_interfaces'] = socket.if_nameindex()
        root = Path('/tmp/autolith-work')
        root.mkdir(mode=0o700)
        for name in ('home', 'work', 'tmp', 'config', 'data', 'state', 'cache', 'runtime'):
            (root / name).mkdir(mode=0o700)
        env = native_environment(root)
        require(not list((root / 'data').iterdir()), 'initial user data is not empty')
        require(not list((root / 'state').iterdir()), 'initial XDG state is not empty')
        first = cli(output / 'bin/autolith', ['--version'], env, root, evidence, 'version-first')
        require(first.splitlines().count('autolith version 0.66.0') == 1 and
                first.rstrip().endswith('autolith version 0.66.0'), 'wrong first native version')
        baseline = images(root)
        record(evidence / 'images-first.json', baseline)
        second = cli(output / 'bin/autolith', ['--version'], env, root, evidence, 'version-second')
        require(second == 'autolith version 0.66.0\n', 'second version rebuilt images or wrong version')
        require(images(root) == baseline, 'second invocation did not reuse unchanged image artifacts')
        record(evidence / 'images-second.json', images(root))
        help_text = cli(output / 'bin/autolith', ['--help'], env, root, evidence, 'cli-help')
        require('autolith' in help_text and '--immutable' in help_text and
                '--permissions' in help_text and 'acp' in help_text, 'incomplete ordinary CLI help')
        require(images(root) == baseline, 'CLI help changed materialized image artifacts')
        read_fd, write_fd = os.pipe()
        with (evidence / 'xvfb.log').open('xb') as log:
            server = subprocess.Popen([os.environ['XVFB'], '-displayfd', str(write_fd), '-screen', '0',
                                       '1280x1024x24', '-nolisten', 'tcp', '-ac', '-fp', os.environ['FONT']],
                                      env=env, pass_fds=(write_fd,), stdout=log, stderr=log)
        os.close(write_fd)
        write_fd = None
        require(select.select([read_fd], [], [], 20)[0], 'Xvfb did not publish display')
        display = ':' + os.read(read_fd, 100).decode().strip()
        require(re.fullmatch(r':\d+', display), 'invalid private display')
        observer_env = dict(os.environ, **env, DISPLAY=display)
        with (evidence / 'xterm.log').open('xb') as log:
            terminal = subprocess.Popen([os.environ['XTERM'], '-display', display, '-geometry', '120x48+0+0',
                                         '-fn', 'fixed', '-xrm', 'XTerm*allowTitleOps: false',
                                         '-e', sys.executable, '-I', '-S', '-B', str(evidence / 'consumer.py'),
                                         str(output), str(evidence), '--terminal', str(root)],
                                        env=observer_env, stdout=log, stderr=log)
        require(terminal.wait(timeout=300) == 0, 'native xterm consumer failed; inspect terminal-failure.txt')
        proof['terminal'] = json.loads((evidence / 'terminal-result.json').read_text())
        require(proof['terminal']['success'], 'terminal receipt failed')
        final_images = images(root)
        record(evidence / 'images-final.json', final_images)
        require(final_images == baseline, 'read-only local help session changed image bytes or replaced images')
        proof.update(success=True, version='0.66.0', image_materialization=True,
                     image_reuse=True, native_cli_help=True, store_read_only=True)
    except BaseException:
        proof['error'] = traceback.format_exc()
        raise
    finally:
        for process in (terminal, server):
            if process and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        for fd in (read_fd, write_fd):
            if fd is not None:
                os.close(fd)
        record(evidence / 'native-proof.json', proof)
        os.close(descriptor)


def main():
    output, evidence = map(Path, sys.argv[1:3])
    if len(sys.argv) > 3 and sys.argv[3] == '--terminal':
        root = Path(sys.argv[4])
        play(output, root, evidence, native_environment(root))
        return
    if len(sys.argv) > 3 and sys.argv[3] == '--inside':
        inside(output, evidence)
        return
    keep = ('OBSERVER_MODULES', 'UNSHARE', 'XVFB', 'XTERM', 'FONT', 'IMPORT', 'TERMINFO', 'TERMINFO_DIRS')
    env = {name: os.environ[name] for name in keep if os.environ.get(name)}
    env.update(PATH='', LC_ALL='C.UTF-8', HOST_UID=str(os.getuid()), HOST_GID=str(os.getgid()))
    for kind in ('user', 'mnt', 'net', 'pid'):
        env['HOST_' + kind.upper()] = os.readlink('/proc/self/ns/' + kind)
    command = [env['UNSHARE'], '--user', '--map-current-user', '--keep-caps', '--mount',
               '--propagation', 'private', '--net', '--pid', '--mount-proc', '--kill-child', '--fork',
               sys.executable, '-I', '-S', '-B', str(evidence / 'consumer.py'),
               str(output), str(evidence), '--inside']
    record(evidence / 'namespace-launch.json', dict(argv=command,
           host={key: value for key, value in env.items() if key.startswith('HOST_')}))
    with (evidence / 'namespace.stdout').open('xb') as stdout, (evidence / 'namespace.stderr').open('xb') as stderr:
        process = subprocess.Popen(command, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        try:
            status = process.wait(timeout=2100)
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise
    require(status == 0, 'isolated native consumer failed; see namespace.stderr and native-proof.json')


if __name__ == '__main__':
    main()
PY
status=0
OBSERVER_MODULES="$modules" UNSHARE="$unshare/bin/unshare" \
XVFB="$xorg/bin/Xvfb" XTERM="$xterm/bin/xterm" FONT="$font/share/fonts/X11/misc" \
IMPORT="$magick/bin/import" \
    "$python/bin/python3" -I -S -B "$evidence/consumer.py" "$output" "$evidence" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
printf '%s\n' "$status" >"$evidence/consumer-exit-status.txt"
"$python/bin/python3" -I -S -B - "$evidence" "$before" "$after" "$status" <<'PY'
import json
from pathlib import Path
import sys
root, before, after, status = sys.argv[1:]
root = Path(root)
path = root / 'native-proof.json'
proof = json.loads(path.read_text()) if path.exists() else {}
success = int(status) == 0 and before == after and proof.get('success') is True
(root / 'consumer-receipt.json').write_text(json.dumps(dict(
    success=success, nar_before=before, nar_after=after, output_unchanged=before == after,
    driver_status=int(status)), indent=2) + '\n')
if not success:
    sys.exit(1)
PY
printf 'Autolith 0.66.0 native version/help, image reuse, PTY Lisp/help/clean quit; offline same-UID/GID namespaces, read-only store, unchanged NAR: %s\nEvidence: %s\n' "$after" "$evidence"
