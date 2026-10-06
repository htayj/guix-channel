#!/usr/bin/env python3
"""Execute locally assembled, lawful V7 PDP-11 code on installed Apout.

Oracle: DoctorWkt/Apout bd9af21bd8bb2fa956dcda5db0b0aeec2cffc8f7:
aout.h/aout.c load 0407 text/data and dispatch V7 traps; itab.c,
double.c, ea.c and branch.c implement the octal instructions below;
v7trap.h/v7trap.c implement write(4), exit(1), and carry/r0 errno returns.
main.c's APOUT_DONT_ASSUME_ROOT branch rejects an absent APOUT_ROOT with
exit(1) and its exact diagnostic. APOUT_ROOT prefixes absolute paths; it is
NOT a sandbox. Namespace/store isolation here is external to Apout.
No historical executable, firmware, guest filesystem or frontend is used.
"""
import errno
import hashlib
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import sys

COMMIT = 'bd9af21bd8bb2fa956dcda5db0b0aeec2cffc8f7'
SOURCE_BASE = 'https://raw.githubusercontent.com/DoctorWkt/Apout/' + COMMIT + '/'
EXPECTED = b'APOUT_NATIVE cpu=5 write=ok ebadf=9\n'
ROOT_ERROR = b'APOUT_ROOT env variable not set before running apout\n'


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def assemble(exit_status):
    """Resolve labels in this one original program; emit LE words, not responses."""
    words = []
    branches = []
    listing = []

    def emit(description, *values):
        listing.append((len(words) * 2, description, values))
        words.extend(values)

    def branch(description, opcode):
        branches.append(len(words))
        emit(description, opcode)

    # r2 = 3 + 4 - 2 = 5. Conditional branch failure exits 99. This is actual
    # emulated arithmetic, followed by a store into the guest data segment.
    emit('mov #3,r2', 0o012702, 3)
    emit('add #4,r2', 0o062702, 4)
    emit('sub #2,r2', 0o162702, 2)
    emit('cmp #5,r2', 0o022702, 5)
    branch('bne fail', 0o001000)
    emit('add #48,r2', 0o062702, ord('0'))
    emit('movb r2,@#digit', 0o110237, 'digit')
    # V7 write takes fd in r0 and buffer/count inline after sys. The guest
    # requires both C=1 and r0=EBADF for a genuinely invalid fd, not a mock.
    emit('mov #-1,r0', 0o012700, 0xffff)
    emit('sys write; payload; length', 0o104404, 'payload', len(EXPECTED))
    branch('bcc fail', 0o103000)
    emit('cmp #EBADF,r0', 0o022700, errno.EBADF)
    branch('bne fail', 0o001000)
    emit('mov #1,r0', 0o012700, 1)
    emit('sys write; payload; length', 0o104404, 'payload', len(EXPECTED))
    branch('bcs fail', 0o103400)
    emit('cmp #length,r0', 0o022700, len(EXPECTED))
    branch('bne fail', 0o001000)
    emit(f'mov #{exit_status},r0', 0o012700, exit_status)
    emit('sys exit', 0o104401)
    fail = len(words) * 2
    emit('fail: mov #99,r0', 0o012700, 99)
    emit('sys exit', 0o104401)
    text_size = len(words) * 2
    labels = {'payload': text_size, 'digit': text_size + EXPECTED.index(b'5')}
    for index in branches:
        displacement = (fail - (index * 2 + 2)) // 2
        require(-128 <= displacement <= 127, 'guest branch exceeds signed byte')
        words[index] |= displacement & 0xff
    words = [labels[value] if isinstance(value, str) else value for value in words]
    # All guest output except the arithmetic digit is original test data. The
    # '?' must become '5' by MOVB executing inside Apout, never in the driver.
    payload = EXPECTED.replace(b'cpu=5', b'cpu=?')
    header = struct.pack('<8H', 0o407, text_size, len(payload), 0, 0, 0, 0, 1)
    image = header + struct.pack('<' + 'H' * len(words), *words) + payload
    text = ['; Original local V7 PDP-11 consumer, addresses/words are octal',
            f'; text={text_size:o} data={len(payload):o} entry=0 exit={exit_status}']
    for address, description, values in listing:
        count = len(values)
        encoded = ' '.join(f'{word:06o}' for word in words[address // 2:address // 2 + count])
        text.append(f'{address:06o}: {encoded:<24} ; {description}')
    text.append(f'{text_size:06o}: {payload!r} ; data (guest replaces ?)')
    return image, '\n'.join(text) + '\n'


def store_mounts():
    result = []
    for line in Path('/proc/self/mountinfo').read_text().splitlines():
        fields = line.split()
        if fields[4] == '/gnu/store' or fields[4].startswith('/gnu/store/'):
            result.append((fields[4], fields[5].split(',')))
    return result


def main():
    out, evidence, scratch = map(Path, sys.argv[1:4])
    mount = sys.argv[4]
    require(errno.EBADF == 9, 'fixture requires the supported Linux EBADF=9 ABI')
    require(os.getuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name in namespaces:
        require(namespaces[name] != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not isolated')
    require(os.getpid() == 1, 'driver is not PID 1 in private proc mount')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'external network interface present')
    (evidence / 'mountinfo-before.txt').write_text(Path('/proc/self/mountinfo').read_text())
    subprocess.run([mount, '--rbind', '/gnu/store', '/gnu/store'], check=True, timeout=10)
    subprocess.run([mount, '--make-rprivate', '/gnu/store'], check=True, timeout=10)
    for target, _ in sorted(store_mounts(), key=lambda item: len(item[0]), reverse=True):
        subprocess.run([mount, '-o', 'remount,bind,ro', target], check=True, timeout=10)
    mounts = store_mounts()
    require(mounts and all('ro' in options for _, options in mounts), 'store mount is writable')
    require(os.statvfs(out).f_flag & os.ST_RDONLY, 'output filesystem is writable')
    (evidence / 'mountinfo-after.txt').write_text(Path('/proc/self/mountinfo').read_text())
    isolation = {'uid': os.getuid(), 'gid': os.getgid(), 'namespaces': namespaces,
                 'interfaces': interfaces, 'store_mounts': mounts,
                 'uid_map': Path('/proc/self/uid_map').read_text(),
                 'gid_map': Path('/proc/self/gid_map').read_text(), 'store_read_only': True}
    save(evidence / 'isolation.json', isolation)
    (evidence / 'expected.stdout').write_bytes(EXPECTED)
    (evidence / 'unset-root.expected.stderr').write_bytes(ROOT_ERROR)
    images = {}
    for exit_status in (0, 37):
        image, listing = assemble(exit_status)
        images[exit_status] = image
        (evidence / f'v7-exit-{exit_status}.aout').write_bytes(image)
        (evidence / f'v7-exit-{exit_status}.listing').write_text(listing)
    runs = []
    transcripts = []
    for number in (1, 2):
        root = scratch / f'run-{number}'
        root.mkdir(mode=0o700)
        env = {'LC_ALL': 'C', 'PATH': os.environ['PATH'], 'TMPDIR': str(root),
               'APOUT_UNIX_VERSION': 'V7'}
        for key, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_DATA_HOME', 'data'),
                               ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime')):
            path = root / directory
            path.mkdir(mode=0o700)
            env[key] = str(path)
        work = root / 'work'
        work.mkdir(mode=0o700)
        guest_root = root / 'guest-root'
        guest_root.mkdir(mode=0o700)
        env['APOUT_ROOT'] = str(guest_root)
        fixtures = set()
        for exit_status, image in images.items():
            fixture = work / f'v7-exit-{exit_status}.aout'
            fixture.write_bytes(image)
            fixture.chmod(0o600)
            fixtures.add(fixture)
        observed = []
        scenarios = [('exit-0', 0, EXPECTED, b'', env),
                     ('exit-37', 37, EXPECTED, b'', env),
                     ('unset-root', 1, b'', ROOT_ERROR,
                      {key: value for key, value in env.items() if key != 'APOUT_ROOT'})]
        for scenario, status, expected_stdout, expected_stderr, child_env in scenarios:
            fixture_status = 37 if scenario == 'exit-37' else 0
            command = [str(out / 'bin/apout'), f'v7-exit-{fixture_status}.aout']
            stem = f'run-{number}.{scenario}'
            stdout_path = evidence / (stem + '.stdout')
            stderr_path = evidence / (stem + '.stderr')
            with stdout_path.open('wb') as stdout, stderr_path.open('wb') as stderr:
                child = subprocess.run(command, cwd=work, env=child_env,
                                       stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
                                       timeout=10)
            actual_stdout, actual_stderr = stdout_path.read_bytes(), stderr_path.read_bytes()
            observed.append((child.returncode, actual_stdout, actual_stderr))
            record = {'run': number, 'scenario': scenario, 'command': command,
                      'exit_status': child.returncode, 'expected_exit_status': status,
                      'stdout_bytes': len(actual_stdout), 'stderr_bytes': len(actual_stderr),
                      'stdout_sha256': hashlib.sha256(actual_stdout).hexdigest(),
                      'stderr_sha256': hashlib.sha256(actual_stderr).hexdigest(),
                      'exact_source_oracle': (child.returncode == status and
                                              actual_stdout == expected_stdout and
                                              actual_stderr == expected_stderr)}
            runs.append(record)
            save(evidence / 'runs.json', runs)
            require(record['exact_source_oracle'], stem + ' differs from exact exit/stdout/stderr contract')
        transcripts.append(observed)
        require({p for p in root.rglob('*') if not p.is_dir()} == fixtures,
                f'run {number} created unexpected runtime files')
        for exit_status, image in images.items():
            require((work / f'v7-exit-{exit_status}.aout').read_bytes() == image,
                    'guest executable changed')
    require(transcripts[0] == transcripts[1], 'native runs are not deterministic')
    save(evidence / 'runtime.json', {
        'status': 'passed', 'source_commit': COMMIT,
        'source_urls': [SOURCE_BASE + name for name in
                        ('main.c', 'aout.h', 'aout.c', 'magic.c', 'itab.c', 'double.c',
                         'ea.c', 'branch.c', 'v7trap.h', 'v7trap.c')],
        'isolation': isolation, 'runs': runs, 'deterministic': True,
        'fixture_origin': 'original locally assembled lawful V7 PDP-11 program',
        'fixture_sha256': {str(status): hashlib.sha256(image).hexdigest()
                           for status, image in images.items()},
        'guest_contract': {'cpu_arithmetic': '3+4-2=5, MOVB replaces data digit',
                           'write': 'C=0, r0=exact byte count',
                           'invalid_write': 'fd=-1: C=1, r0=EBADF=9',
                           'exit_statuses': [0, 37], 'unset_root_exit_status': 1},
        'limitations': ['V7 0407 guest CPU/write/error/exit only; other Unix ABIs untested',
                        'APOUT_ROOT is a pathname prefix, not a sandbox',
                        'NATIVES host-binary dispatch, sockets and historical guest images untested'],
    })
    print('APOUT_NATIVE_OK runs=2 cpu=5 write=ok ebadf=9 exits=0,37 unset_root=1 deterministic=true')


if __name__ == '__main__':
    main()
