#!/usr/bin/env python3
"""Drive the installed astx CLI with a controlling terminal, never --yes."""
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pty
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


JS = b'''// Keep this comment: data.hasOwnProperty(key) is not code.
const data = { present: 7 };
const key = "present";
const found = data.hasOwnProperty(key);
const absent = data.hasOwnProperty("missing");
const unrelated = "data.hasOwnProperty(key)";
console.log(JSON.stringify({ found, absent, unrelated, value: data.present }));
'''
TS = b'''// TypeScript annotations and unrelated bytes must survive.
const typed: Record<string, number> = { answer: 42 };
const field: string = "answer";
export const owned: boolean = typed.hasOwnProperty(field);
export const value: number = typed.answer;
'''
UNRELATED = b'''// Unmatched file: preserve these spaces and blank lines exactly.  
export const untouched: number = 42;

'''
TRANSFORM = b'''// .cts requires the installed TypeScript/esbuild loader, not plain require.
export const find: string = `$a.hasOwnProperty($b)`;
export const replace: string = `Object.hasOwn($a, $b)`;
'''
EXPECTED = {
    'fixture.js': JS.replace(b'data.hasOwnProperty(key);', b'Object.hasOwn(data, key);')
                    .replace(b'data.hasOwnProperty("missing");', b'Object.hasOwn(data, "missing");'),
    'fixture.ts': TS.replace(b'typed.hasOwnProperty(field);', b'Object.hasOwn(typed, field);'),
    'unrelated.ts': UNRELATED,
}
ANSI = re.compile(rb'\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07]*(?:\x07|\x1b\\)')
PROMPT = re.compile(rb'Apply changes[^\r\n]*\(y/N\)', re.I)


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def store_mounts():
    result = []
    for line in Path('/proc/self/mountinfo').read_text().splitlines():
        fields = line.split()
        if fields[4] == '/gnu/store' or fields[4].startswith('/gnu/store/'):
            result.append((fields[4], fields[5].split(',')))
    return result


def isolate(out, evidence, mount):
    require(os.getuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, value in namespaces.items():
        require(value != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not isolated')
    require(os.getpid() == 1, 'driver is not PID 1 in private proc mount')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'external network interface present')
    (evidence / 'mountinfo-before.txt').write_text(Path('/proc/self/mountinfo').read_text())
    for command in ([mount, '--rbind', '/gnu/store', '/gnu/store'],
                    [mount, '--make-rprivate', '/gnu/store']):
        subprocess.run(command, check=True, timeout=10)
    for target, _ in sorted(store_mounts(), key=lambda item: len(item[0]), reverse=True):
        subprocess.run([mount, '-o', 'remount,bind,ro', target], check=True, timeout=10)
    mounts = store_mounts()
    require(mounts and all('ro' in options for _, options in mounts), 'store mount writable')
    require(os.statvfs(out).f_flag & os.ST_RDONLY, 'output filesystem writable')
    (evidence / 'mountinfo-after.txt').write_text(Path('/proc/self/mountinfo').read_text())
    save(evidence / 'isolation.json', {
        'uid': os.getuid(), 'gid': os.getgid(), 'namespaces': namespaces,
        'host_namespaces': {name: os.environ['HOST_' + name.upper() + '_NS']
                            for name in namespaces},
        'expected_uid': int(os.environ['EXPECTED_UID']),
        'expected_gid': int(os.environ['EXPECTED_GID']),
        'interfaces': interfaces, 'store_mounts': mounts, 'store_read_only': True,
        'uid_map': Path('/proc/self/uid_map').read_text(),
        'gid_map': Path('/proc/self/gid_map').read_text(),
    })


def snapshot(work, destination):
    destination.mkdir()
    hashes = {}
    for path in sorted(work.iterdir()):
        if path.is_file():
            data = path.read_bytes()
            (destination / path.name).write_bytes(data)
            hashes[path.name] = digest(data)
    return hashes


def drive(command, work, evidence, env, phase, answer, original):
    record = {'command': command, 'phase': phase, 'answer': answer.decode().strip(),
              'prompt_seen': False, 'natural_exit': False, 'forced_cleanup': False}
    save(evidence / (phase + '.command.json'), {'argv': command, 'cwd': str(work), 'env': env})
    pid, master = pty.fork()
    if pid == 0:
        try:
            os.chdir(work)
            os.execve(command[0], command, env)
        except BaseException:
            traceback.print_exc()
            os._exit(127)
    fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 140, 0, 0))
    transcript = bytearray()
    sent = False
    status = None
    error = None
    deadline = time.monotonic() + 60
    with (evidence / (phase + '.pty.raw')).open('wb') as output, \
            (evidence / (phase + '.input.raw')).open('wb') as inputs:
        try:
            eof = False
            while status is None or not eof:
                require(time.monotonic() < deadline, phase + ': CLI exceeded deadline')
                if not eof and select.select([master], [], [], 0.1)[0]:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError as exc:
                        if exc.errno != errno.EIO:
                            raise
                        chunk = b''
                    if not chunk:
                        eof = True
                    else:
                        output.write(chunk)
                        output.flush()
                        transcript.extend(chunk)
                plain = ANSI.sub(b'', bytes(transcript))
                if not sent and PROMPT.search(plain):
                    record['prompt_seen'] = True
                    # Neither the displayed diff nor prompting may write before consent.
                    require(all((work / name).read_bytes() == data
                                for name, data in original.items()),
                            phase + ': input changed before confirmation')
                    require(b'Object.hasOwn' in plain and b'hasOwnProperty' in plain,
                            phase + ': no actual before/after structural diff')
                    require(b'2 files changed' in plain and b'1 file unchanged' in plain,
                            phase + ': unexpected match/change counts')
                    require(not re.search(rb'[1-9][0-9]* files? errored', plain),
                            phase + ': runtime errors reported')
                    os.write(master, answer)
                    inputs.write(answer)
                    inputs.flush()
                    sent = True
                if status is None:
                    waited, value = os.waitpid(pid, os.WNOHANG)
                    if waited:
                        status = value
            record['natural_exit'] = True
            record['exit_status'] = os.waitstatus_to_exitcode(status)
            require(sent, phase + ': CLI exited without ordinary confirmation')
            require(record['exit_status'] == 0, phase + ': CLI did not naturally exit zero')
            plain = ANSI.sub(b'', bytes(transcript))
            require(not re.search(rb'[1-9][0-9]* files? errored', plain),
                    phase + ': runtime errors reported despite exit zero')
            require(b'Error:' not in plain and b'Unhandled' not in plain,
                    phase + ': runtime exception in transcript')
            if phase == 'decline':
                require(b'Wrote ' not in plain, 'decline reported a write')
            else:
                require(plain.count(b'Wrote ') == 2, 'accept did not report both real writes')
        except BaseException as exc:
            error = exc
        finally:
            if status is None:
                record['forced_cleanup'] = True
                try:
                    os.killpg(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                _, status = os.waitpid(pid, 0)
                record['exit_status'] = os.waitstatus_to_exitcode(status)
            os.close(master)
            (evidence / (phase + '.pty.txt')).write_bytes(ANSI.sub(b'', bytes(transcript)))
            record['child_reaped'] = True
            record['pty_closed'] = True
            if error:
                record['error'] = str(error)
            save(evidence / (phase + '.json'), record)
    if error:
        raise error
    return record


def semantics(node, work, evidence, env, phase):
    command = [str(node), str(work / 'fixture.js')]
    result = subprocess.run(command, cwd=work, env=env, capture_output=True, timeout=10)
    (evidence / (phase + '.semantics.stdout')).write_bytes(result.stdout)
    (evidence / (phase + '.semantics.stderr')).write_bytes(result.stderr)
    save(evidence / (phase + '.semantics.json'), {'command': command, 'exit_status': result.returncode})
    require(result.returncode == 0 and not result.stderr, phase + ': JS evaluation failed')
    value = json.loads(result.stdout)
    require(value == {'found': True, 'absent': False, 'unrelated': 'data.hasOwnProperty(key)',
                      'value': 7}, phase + ': unexpected fixture semantics')
    return value


def main():
    out, evidence, scratch = map(Path, sys.argv[1:4])
    isolate(out, evidence, sys.argv[4])
    work = scratch / 'work'
    work.mkdir()
    env = dict(os.environ)
    env.update(HOME=str(scratch / 'home'), TMPDIR=str(scratch / 'tmp'),
               TERM='xterm-256color', ASTX_WORKERS='1', LC_ALL='C')
    for key in ('HOME', 'TMPDIR'):
        Path(env[key]).mkdir()
    for name in ('CACHE', 'CONFIG', 'DATA', 'STATE'):
        directory = scratch / 'xdg' / name.lower()
        directory.mkdir(parents=True)
        env['XDG_' + name + '_HOME'] = str(directory)
    # Pin local config and disable optional prettier discovery; preserve unrelated
    # nodes verbatim using the native public configuration/CLI controls.
    (work / '.astxrc.json').write_text(json.dumps({
        'parser': 'babel/auto',
        'prettier': False, 'preferSimpleReplacement': True,
    }) + '\n')
    original = {'fixture.js': JS, 'fixture.ts': TS, 'unrelated.ts': UNRELATED}
    for name, data in original.items():
        (work / name).write_bytes(data)
    (work / 'has-own.cts').write_bytes(TRANSFORM)
    expected_dir = evidence / 'expected'
    expected_dir.mkdir()
    for name, data in EXPECTED.items():
        (expected_dir / name).write_bytes(data)
    # The installed wrapper, not a host Node or fake executor, is the CLI under
    # test.  Use its actual source-built runtime solely to evaluate JS semantics.
    wrapper = (out / 'bin/astx').read_text()
    (evidence / 'installed-wrapper.txt').write_text(wrapper)
    runtime = re.search(r'^exec (/gnu/store/[^\s]+/bin/node) ', wrapper, re.M)
    require(runtime is not None, 'installed wrapper lacks fixed Guix Node runtime')
    node = Path(runtime.group(1))
    require(node.is_file() and os.access(node, os.X_OK), 'installed Node runtime missing')
    helper = re.search(r'(/gnu/store/[^\s}]+/bin/esbuild)', wrapper)
    require(helper is not None, 'installed wrapper lacks fixed Guix esbuild helper')
    esbuild = Path(helper.group(1))
    require(esbuild.is_file() and os.access(esbuild, os.X_OK), 'installed esbuild missing')
    require(esbuild.read_bytes()[:4] == b'\x7fELF', 'esbuild helper is not native ELF')
    save(evidence / 'runtime-tools.json', {
        'node': str(node), 'node_sha256': digest(node.read_bytes()),
        'esbuild': str(esbuild), 'esbuild_sha256': digest(esbuild.read_bytes()),
        'wrapper_sha256': digest(wrapper.encode()), 'ASTX_WORKERS': env['ASTX_WORKERS'],
    })
    command = [str(out / 'bin/astx'), '--transform', str(work / 'has-own.cts'),
               *[str(work / name) for name in original]]
    before = snapshot(work, evidence / 'before')
    value_before = semantics(node, work, evidence, env, 'before')
    decline = drive(command, work, evidence, env, 'decline', b'n\n', original)
    declined = snapshot(work, evidence / 'declined')
    require(before == declined, 'decline changed fixture, transform or config bytes')
    accept = drive(command, work, evidence, env, 'accept', b'y\n', original)
    accepted = snapshot(work, evidence / 'accepted')
    for name, data in EXPECTED.items():
        require((work / name).read_bytes() == data,
                'structural rewrite or unrelated-byte preservation failed: ' + name)
    for name in ('has-own.cts', '.astxrc.json'):
        require(before[name] == accepted[name], 'CLI modified its input config/transform')
    value_after = semantics(node, work, evidence, env, 'after')
    require(value_before == value_after, 'rewrite changed JS fixture semantics')
    # PID 1 must reap naturally exited esbuild service descendants as well as
    # the CLI itself.  Never kill a leftover process and count that as success.
    reaped = []
    deadline = time.monotonic() + 5
    while True:
        while True:
            try:
                pid, status = os.waitpid(-1, os.WNOHANG)
            except ChildProcessError:
                break
            if not pid:
                break
            reaped.append({'pid': pid, 'exit_status': os.waitstatus_to_exitcode(status)})
        remaining = [p.name for p in Path('/proc').iterdir() if p.name.isdigit() and p.name != '1']
        if not remaining or time.monotonic() >= deadline:
            break
        time.sleep(0.05)
    require(not remaining, 'native consumer left child processes: ' + repr(remaining))
    save(evidence / 'runtime.json', {
        'status': 'passed', 'contract': 'actual .cts public CLI structural rewrite with PTY consent',
        'before_sha256': before, 'declined_sha256': declined, 'accepted_sha256': accepted,
        'decline_unchanged': True, 'accept_exact_bytes': True, 'semantics_equal': True,
        'runs': [decline, accept], 'remaining_child_pids': remaining,
        'naturally_reaped_descendants': reaped,
        'networkless': True, 'store_read_only': True,
    })
    print('ASTX_NATIVE_OK cts_loader=real decline=unchanged accept=rewritten semantics=equal exits=0,0')


if __name__ == '__main__':
    try:
        main()
    except BaseException as exc:
        evidence = Path(sys.argv[2])
        work = Path(sys.argv[3]) / 'work'
        if work.is_dir():
            snapshot(work, evidence / 'failed-files')
        save(evidence / 'runtime.json', {'status': 'failed', 'error': str(exc)})
        traceback.print_exc()
        sys.exit(1)
