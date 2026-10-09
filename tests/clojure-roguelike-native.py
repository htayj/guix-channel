#!/usr/bin/env python3
"""Consume an already built one-shot prototype; send no terminal input.

The pinned upstream -main prints (showblock (roomBlock 8 8 3 8 0 0)) and
returns. This proves that render and normal exit, not nonexistent gameplay.
"""
import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import socket
import stat
import struct
import subprocess
import sys
import tempfile
import termios
import time
import traceback
import zipfile

EXPECTED = ('########\n#......#\n#......#\n.......#\n'
            '#......#\n#......#\n#......#\n########\n')
SOURCE = ('https://github.com/charlesrosenbauer/Clojure-Roguelike/'
          'blob/16102d6/src/roguelike/core.clj')


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def check_output(out):
    require(out.resolve(strict=True) == out and out.parent == Path('/gnu/store')
            and out.is_dir(), 'OUTPUT must be a canonical direct store directory')
    for path in [out, *out.rglob('*')]:
        mode = path.lstat().st_mode
        require(not ((stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222),
                'writable installed store member: ' + str(path))
    launcher = out / 'bin/clojure-roguelike'
    require(launcher.is_file() and os.access(launcher, os.X_OK), 'missing executable wrapper')
    jar = out / 'share/java/clojure-roguelike.jar'
    require(list((out / 'share/java').glob('*.jar')) == [jar], 'expected one packaged jar')
    launch = re.fullmatch(r'#!(/gnu/store/[^\s]+/bin/sh)\n'
                         r'exec (/gnu/store/[^\s]+/bin/java) -jar '
                         + re.escape(str(jar)) + r' "\$@"\n', launcher.read_text())
    require(launch is not None, 'wrapper must ordinarily exec the packaged jar')
    java = launch.group(2)
    require(os.access(java, os.X_OK), 'packaged Java runtime is missing')
    with zipfile.ZipFile(jar) as archive:
        manifest = archive.read('META-INF/MANIFEST.MF').decode().replace('\r\n', '\n')
        require('Main-Class: roguelike.core' in manifest.splitlines(), 'incorrect main class')
        names = set(archive.namelist())
        require({'roguelike/core__init.class', 'clojure/lang/Compiler.class'} <= names,
                'jar lacks application AOT or Clojure runtime')
    doc = out / 'share/doc/clojure-roguelike'
    for name in ('LICENSE', 'README.md', 'CHANGELOG.md'):
        require((doc / name).is_file() and (doc / name).stat().st_size > 0,
                'missing installed documentation: ' + name)
    for name, text in (('LICENSE', 'ECLIPSE PUBLIC'),
                       ('clojure-runtime-notices/readme.txt', 'ASM bytecode engineering library'),
                       ('clojure-runtime-notices/readme.txt', 'Guava Murmur3 hash implementation'),
                       ('clojure-runtime-notices/epl-v10.html', 'Eclipse Public License - v 1.0')):
        require(text in (doc / name).read_text(), 'missing runtime/license notice: ' + text)
    return {'launcher': str(launcher), 'jar': str(jar), 'java': java,
            'main_class': 'roguelike.core', 'store_modes_read_only': True}


def store_mounts():
    text = Path('/proc/self/mountinfo').read_text()
    result = []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in (('\\040', ' '), ('\\011', '\t'),
                                 ('\\012', '\n'), ('\\134', '\\')):
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            result.append({'target': target, 'options': fields[5].split(','),
                           'optional': fields[6:fields.index('-')]})
    return text, result


def isolate(out, evidence, mount):
    require(os.getuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    require(os.getpid() == 1, 'consumer must be PID 1 with private proc')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, value in namespaces.items():
        require(value != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not isolated')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'namespace has external network interfaces')
    # A fresh network namespace keeps loopback down: no fixture or networking is
    # needed by this one-shot application. Retain the actual interface flags.
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        interface = fcntl.ioctl(probe.fileno(), 0x8913, struct.pack('256s', b'lo'))
    flags = struct.unpack_from('H', interface, 16)[0]
    require(not flags & 1, 'loopback unexpectedly up')
    routes = Path('/proc/net/route').read_text()
    (evidence / 'network-route.txt').write_text(routes)
    route_rows = [line.split() for line in routes.splitlines() if line.strip()]
    if route_rows and route_rows[0][:2] == ['Iface', 'Destination']:
        route_rows = route_rows[1:]
    require(not route_rows, 'namespace has IPv4 routes')
    (evidence / 'network-ipv6-route.txt').write_text(Path('/proc/net/ipv6_route').read_text())
    (evidence / 'mountinfo-before.txt').write_text(store_mounts()[0])
    subprocess.run([mount, '--rbind', '/gnu/store', '/gnu/store'], check=True, timeout=10)
    subprocess.run([mount, '--make-rprivate', '/gnu/store'], check=True, timeout=10)
    for entry in sorted(store_mounts()[1], key=lambda item: len(item['target']), reverse=True):
        subprocess.run([mount, '-o', 'remount,bind,ro', entry['target']], check=True, timeout=10)
    text, mounts = store_mounts()
    require(mounts and any(item['target'] == '/gnu/store' for item in mounts)
            and all('ro' in item['options'] and 'rw' not in item['options'] and
                    not any(value.startswith(('shared:', 'master:')) for value in item['optional'])
                    for item in mounts), 'store is not recursively private/read-only')
    require(os.statvfs(out).f_flag & os.ST_RDONLY, 'output filesystem is writable')
    (evidence / 'mountinfo-after.txt').write_text(text)
    receipt = {'uid': os.getuid(), 'gid': os.getgid(), 'pid': os.getpid(),
               'expected_uid': int(os.environ['EXPECTED_UID']),
               'expected_gid': int(os.environ['EXPECTED_GID']), 'namespaces': namespaces,
               'host_namespaces': {name: os.environ['HOST_' + name.upper() + '_NS']
                                   for name in namespaces},
               'uid_map': Path('/proc/self/uid_map').read_text(),
               'gid_map': Path('/proc/self/gid_map').read_text(),
               'interfaces': interfaces, 'loopback_flags': flags,
               'store_read_only': True, 'store_mounts': mounts}
    save(evidence / 'isolation.json', receipt)
    return receipt


def render(out, evidence, scratch):
    dirs = {name: scratch / name for name in
            ('home', 'config', 'data', 'cache', 'state', 'tmp', 'caller')}
    for path in dirs.values():
        path.mkdir()
    env = {'HOME': str(dirs['home']), 'XDG_CONFIG_HOME': str(dirs['config']),
           'XDG_DATA_HOME': str(dirs['data']), 'XDG_CACHE_HOME': str(dirs['cache']),
           'XDG_STATE_HOME': str(dirs['state']), 'TMPDIR': str(dirs['tmp']),
           'TERM': 'xterm-256color', 'LC_ALL': 'C.UTF-8', 'PATH': '/nonexistent'}
    command = [str(out / 'bin/clojure-roguelike')]
    pid, master = pty.fork()
    if pid == 0:
        try:
            os.chdir(dirs['caller'])
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 80, 0, 0))
            os.execve(command[0], command, env)
        except BaseException:
            traceback.print_exc()
            os._exit(127)
    raw = bytearray()
    status = None
    eof = False
    deadline = time.monotonic() + 45
    identity = None
    try:
        while status is None or not eof:
            require(time.monotonic() < deadline, 'packaged application did not exit normally within 45 seconds')
            if identity is None:
                try:
                    cmdline = Path('/proc/' + str(pid) + '/cmdline').read_bytes().split(b'\0')
                    if b'-jar' in cmdline:
                        identity = {'pid': pid,
                                    'exe': os.readlink('/proc/' + str(pid) + '/exe'),
                                    'cmdline': [arg.decode() for arg in cmdline if arg],
                                    'status': Path('/proc/' + str(pid) + '/status').read_text()}
                except (FileNotFoundError, ProcessLookupError):
                    pass
            if not eof and select.select([master], [], [], 0.05)[0]:
                try:
                    data = os.read(master, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    data = b''
                if data:
                    raw.extend(data)
                    require(len(raw) <= 1024 * 1024, 'unexpectedly large terminal output')
                else:
                    eof = True
            elif eof:
                time.sleep(0.01)
            if status is None:
                waited, result = os.waitpid(pid, os.WNOHANG)
                if waited:
                    status = result
    finally:
        (evidence / 'terminal.raw').write_bytes(raw)
        os.close(master)
        if status is None:
            try:
                os.killpg(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(pid, 0)
    code = os.waitstatus_to_exitcode(status)
    text = raw.decode('utf-8', errors='strict').replace('\r\n', '\n')
    (evidence / 'terminal.txt').write_text(text)
    save(evidence / 'launch.json', {'command': command, 'cwd': str(dirs['caller']),
                                  'environment': env, 'pty': True, 'input_bytes_sent': 0,
                                  'wait_status': status, 'exit_status': code,
                                  'observed_java_process': identity})
    require(code == 0, 'packaged application exited ' + str(code))
    require(text == EXPECTED, 'actual terminal output differs from the pinned 8x8 room')
    leaked = [str(path) for directory in dirs.values() for path in directory.rglob('*')]
    save(evidence / 'mutable-state.json', {'paths': leaked, 'empty': not leaked})
    require(not leaked, 'one-shot application left mutable state')
    return {'normal_exit': True, 'application_exit_status': code, 'room_rows': text.splitlines(),
            'room_dimensions': [8, 8], 'input_bytes_sent': 0, 'mutable_state_empty': True}


def native(out, evidence, scratch, mount):
    record = {'status': 'failed', 'scope': 'upstream one-shot 8x8 room render only',
              'source': SOURCE, 'gameplay': False, 'input_bytes_sent': 0}
    try:
        record['isolation'] = isolate(out, evidence, mount)
        record['installed_output'] = check_output(out)
        record.update(render(out, evidence, scratch))
        record['status'] = 'passed'
        return 0
    except BaseException as error:
        record['error'] = str(error)
        traceback.print_exc()
        return 1
    finally:
        save(evidence / 'runtime.json', record)


def capture(command, evidence, name):
    with (evidence / (name + '.stderr')).open('wb') as errors:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=errors, timeout=60)
    (evidence / (name + '.txt')).write_bytes(result.stdout)
    return result.returncode, result.stdout.decode().strip()


def host(args):
    require(len(args) == 7, 'expected OUTPUT EVIDENCE GUIX PYTHON UNSHARE MOUNT TIMEOUT')
    output, destination, *tools = args
    out = Path(output)
    require(out.is_absolute() and str(out) == output, 'OUTPUT must be an absolute canonical path')
    require(out.resolve(strict=True) == out and out.parent == Path('/gnu/store') and out.is_dir(),
            'OUTPUT must be one canonical direct realized /gnu/store directory')
    evidence = Path(destination)
    require(evidence.is_absolute() and not os.path.lexists(evidence),
            'EVIDENCE must be an absolute fresh nonexistent directory')
    parent = evidence.parent.resolve(strict=True)
    require(parent.is_dir() and evidence.name not in ('', '.', '..'), 'invalid EVIDENCE parent/name')
    evidence = parent / evidence.name
    require(not os.path.lexists(evidence), 'canonical EVIDENCE already exists')
    require(evidence != Path('/gnu/store') and Path('/gnu/store') not in evidence.parents,
            'EVIDENCE must resolve outside /gnu/store')
    resolved = []
    for tool in tools:
        executable = shutil.which(tool)
        require(executable is not None and os.access(executable, os.X_OK), 'tool not executable: ' + tool)
        resolved.append(str(Path(executable).resolve(strict=True)))
    guix, python, unshare, mount, timeout = resolved
    evidence.mkdir(mode=0o700)  # Deliberately no exist_ok: final freshness gate.
    (evidence / 'store-output.txt').write_text(str(out) + '\n')
    save(evidence / 'tools.json', dict(zip(('guix', 'python', 'unshare', 'mount', 'timeout'), resolved)))
    record = {'status': 'failed', 'output': str(out), 'scope': 'one-shot prototype render only'}
    scratch = None
    status = 1
    before = after = ''
    try:
        scratch = Path(tempfile.mkdtemp(prefix='clojure-roguelike-native.', dir='/tmp'))
        (evidence / 'scratch-path.txt').write_text(str(scratch) + '\n')
        closure_status, _ = capture([guix, 'gc', '-R', str(out)], evidence, 'runtime-closure')
        record['runtime_closure_status'] = closure_status
        before_status, before = capture([guix, 'hash', '-S', 'nar', str(out)], evidence, 'output-nar-before')
        record['output_nar_before_status'] = before_status
        record['output_nar_before'] = before
        record['installed_output_before'] = check_output(out)
        require(closure_status == 0 and before_status == 0 and bool(before), 'closure/NAR preflight failed')
        env = {'LC_ALL': 'C.UTF-8', 'EXPECTED_UID': str(os.getuid()), 'EXPECTED_GID': str(os.getgid())}
        for name in ('user', 'mnt', 'net', 'pid'):
            env['HOST_' + name.upper() + '_NS'] = os.readlink('/proc/self/ns/' + name)
        command = [timeout, '--kill-after=10', '90', unshare, '--user', '--map-current-user',
                   '--keep-caps', '--mount', '--propagation', 'private', '--net', '--pid',
                   '--mount-proc', '--kill-child', '--fork', python, '-s', '-B',
                   str(Path(__file__).resolve()), '--native', str(out), str(evidence), str(scratch), mount]
        save(evidence / 'driver-command.json', {'command': command, 'environment': env})
        with (evidence / 'driver.stdout').open('wb') as stdout, (evidence / 'driver.stderr').open('wb') as stderr:
            status = subprocess.run(command, env=env, stdout=stdout, stderr=stderr, timeout=110).returncode
        record['driver_exit_status'] = status
        runtime = json.loads((evidence / 'runtime.json').read_text())
        record['runtime'] = runtime
        require(status == 0 and runtime.get('status') == 'passed', 'native one-shot consumer failed')
        record['status'] = 'passed'
    except BaseException as error:
        record['error'] = str(error)
        traceback.print_exc()
    finally:
        try:
            after_status, after = capture([guix, 'hash', '-S', 'nar', str(out)], evidence, 'output-nar-after')
            record['output_nar_after_status'] = after_status
            record['output_nar_after'] = after
            record['installed_output_after'] = check_output(out)
            immutable = bool(before) and before == after and after_status == 0
            record['immutable_output'] = immutable
            require(immutable, 'installed output NAR changed or hash failed')
        except BaseException as error:
            record['status'] = 'failed'
            record['integrity_error'] = str(error)
            traceback.print_exc()
        clean = False
        try:
            if scratch is not None:
                shutil.rmtree(scratch)
                clean = not os.path.lexists(scratch)
            require(clean, 'scratch cleanup failed')
        except BaseException as error:
            record['status'] = 'failed'
            record['cleanup_error'] = str(error)
            traceback.print_exc()
        save(evidence / 'cleanup.json', {'scratch': str(scratch) if scratch else None, 'clean': clean})
        save(evidence / 'evidence.json', record)
    if record['status'] != 'passed':
        print('clojure-roguelike native consumer failed; evidence: ' + str(evidence), file=sys.stderr)
        return status if status > 0 else 1
    print('clojure-roguelike one-shot PTY render passed with immutable output; evidence: ' + str(evidence))
    return 0


if __name__ == '__main__':
    if sys.argv[1:2] == ['--native']:
        require(len(sys.argv) == 6, 'expected isolated OUTPUT EVIDENCE SCRATCH MOUNT')
        sys.exit(native(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]), sys.argv[5]))
    sys.exit(host(sys.argv[1:]))
