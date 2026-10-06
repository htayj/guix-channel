#!/usr/bin/env python3
"""Observe the installed PDP-11/45 built-in diagnostic, not guest execution.

Oracle: aap/pdp11 commit 5b5b734f9b574cc3257670595eee6be084f2c8aa,
u_kb11a.c: dumpromw, dumpstate, update_state, t1..t5, power and test;
ucode/ucode_45.inc: ZAP.00, BRK.01, CON.00, EXM.10 at octal
200/352/170/070 respectively (array addresses, not label suffixes).
The upstream Makefile links pdp1145 solely from u_kb11a.o. No firmware,
macroinstruction, other CPU runtime, disk, network or graphical claim is made.
"""
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import sys

COMMIT = '5b5b734f9b574cc3257670595eee6be084f2c8aa'
SOURCE_BASE = 'https://raw.githubusercontent.com/aap/pdp11/' + COMMIT + '/'


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


# Exact 27 printed Uword fields in struct order; name/page are not printed.
# Constants come from the pinned ROM, not from a captured run.
ROM = [
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 7, 6, 0, 0, 0, 0, 2, 0, 0o6, 0o352),
    (1, 1, 0, 0, 1, 0, 0, 0, 0, 2, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0o12, 0o130),
    (1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0o14, 0o70),
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 2, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0o153),
]
FIELDS = ('A', 'B', 'BA', 'ALU', 'SHFR', 'PCA', 'PCB', 'SR', 'DR', 'BR', 'IR')
# test initializes PCB=01234, DR=04321, SW=0112233, UNIBUSD=0123321.
# ZAP.00 selects A=DR, B=1, BA=PCB and ALU=A. T1 still has the
# zero-initialized shf=0, so SHFR=swap16(04321)=0150410; T2 latches shf=2.
FIRST_T1 = (0o4321, 1, 0o1234, 0o4321, 0o150410, 0, 0o1234, 0, 0o4321, 0, 0)
FIRST_REST = (0o4321, 1, 0o1234, 0o4321, 0o4321, 0, 0o1234, 0, 0o4321, 0, 0)
# The unbraced upstream t1 assignment n.br=brmx is unconditional even with
# brk=0. BRK.01 selects A=PCB, ALU=A and BA=PCB. At T2 its bsd=1
# selects UNIBUSD; T3 uses bef=012: adr=0130 | (conf<<5 | !brq<<4)
# = 0130 | 060 = 0170, selecting CON.00, not a ZAP label successor.
SECOND = (0o1234, 1, 0o1234, 0o1234, 0o1234, 0, 0o1234, 0, 0o4321, 0o4321, 0)
# Third T1 loads SR from previous SHFR=01234 (srk=1, srx=0), and BR
# from UNIBUSD=0123321 (brx=1, sel_int=0 -> selector 4). CON.00
# selects A=DR, ALU=A, BA=PCB; ibs=1 then selects switch register SW.
THIRD = (0o4321, 1, 0o1234, 0o4321, 0o4321, 0, 0o1234, 0o1234, 0o4321, 0o123321, 0)
# Final T1 loads BR=SW=0112233 (selector 6); EXM.10's alu=0
# complements DR, with buffered shf still 2 until a T2 not exercised here.
FINAL = (0o4321, 1, 0o1234, 0o173456, 0o173456, 0, 0o1234, 0o1234, 0o4321, 0o112233, 0)
STATES = [FIRST_T1] + [FIRST_REST] * 4 + [SECOND] * 5 + [THIRD] * 5 + [FINAL]


def state_text(values):
    a, b, ba, alu, shfr, pca, pcb, sr, dr, br, ir = values
    return (f'A/{a:06o} B/{b:06o} BA/{ba:06o}\n'
            f'ALU/{alu:07o} SHFR/{shfr:06o}\n'
            f'PCA/{pca:06o} PCB/{pcb:06o}\n'
            f'SR/{sr:06o} DR/{dr:06o}\n'
            f'BR/{br:06o} IR/{ir:06o}\n')


def rom_text(values):
    return '\t'.join(format(value, 'o') for value in values) + '\n'


def oracle():
    text = rom_text(ROM[0])  # power -> zap -> update_rom
    for cycle, address in enumerate((0o352, 0o170, 0o70)):
        for phase in range(1, 6):
            text += f'T{phase}\n'
            if cycle == 2 and phase == 1:
                text += 'load BR 4 123321\n'
            if phase == 3:
                text += f'getting new address {address:o}\n'
                if cycle == 0:
                    text += '\tBEND (TODO)\n\tBRQ STROBE (TODO)\n'
                text += rom_text(ROM[cycle + 1])
            text += state_text(STATES[cycle * 5 + phase - 1])
            if cycle == 1 and phase == 2:
                text += '\tINTR PAUSE\n'
        text += '----------\n'
    return (text + 'T1\nload BR 6 112233\n' + state_text(FINAL)).encode('ascii')


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
    require(os.getuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name in namespaces:
        require(namespaces[name] != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not isolated')
    require(os.getpid() == 1, 'driver is not PID 1 in the private proc mount')
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
    # No firmware, macroinstructions or synthetic responses are injected. Both
    # executions launch the unchanged installed binary, with stdin closed.
    expected = oracle()
    (evidence / 'expected.stdout').write_bytes(expected)
    runs = []
    transcripts = []
    for number in (1, 2):
        root = scratch / f'run-{number}'
        root.mkdir(mode=0o700)
        env = {'LC_ALL': 'C', 'PATH': os.environ['PATH'], 'TMPDIR': str(root)}
        for key, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_DATA_HOME', 'data'),
                               ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime')):
            path = root / directory
            path.mkdir(mode=0o700)
            env[key] = str(path)
        work = root / 'work'
        work.mkdir(mode=0o700)
        stdout_path = evidence / f'run-{number}.stdout'
        stderr_path = evidence / f'run-{number}.stderr'
        with stdout_path.open('wb') as stdout, stderr_path.open('wb') as stderr:
            child = subprocess.run([str(out / 'bin/pdp1145')], cwd=work, env=env,
                                   stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr,
                                   timeout=10)
        transcript = stdout_path.read_bytes()
        transcripts.append(transcript)
        runs.append({'run': number, 'command': [str(out / 'bin/pdp1145')],
                     'exit_status': child.returncode, 'stdout_bytes': len(transcript),
                     'stdout_sha256': hashlib.sha256(transcript).hexdigest(),
                     'stderr_bytes': stderr_path.stat().st_size,
                     'exact_source_oracle': transcript == expected})
        save(evidence / 'runs.json', runs)
        require(child.returncode == 0, f'run {number} exited {child.returncode}')
        require(stderr_path.stat().st_size == 0, f'run {number} wrote stderr')
        require(transcript == expected, f'run {number} differs from pinned exact oracle; compare expected.stdout and run-{number}.stdout')
        require(not any(path.is_file() or path.is_symlink() for path in root.rglob('*')),
                f'run {number} created unexpected runtime files')
    require(transcripts[0] == transcripts[1], 'two actual diagnostic runs are not deterministic')
    save(evidence / 'runtime.json', {
        'status': 'passed', 'source_commit': COMMIT,
        'source_urls': [SOURCE_BASE + name for name in ('u_kb11a.c', 'ucode/ucode_45.inc', 'Makefile')],
        'isolation': isolation, 'runs': runs, 'deterministic': True,
        'oracle_sha256': hashlib.sha256(expected).hexdigest(),
        'rom_addresses_octal': ['200', '352', '170', '70'],
        'states_octal': [{'cycle': index // 5 + 1, 'phase': 'T' + str(index % 5 + 1),
                         **{field: format(value, 'o') for field, value in zip(FIELDS, values)}}
                        for index, values in enumerate(STATES)],
        'limitations': ['Only pdp1145 built-in three microcycles plus final T1 are executed',
                        'No firmware or macroinstruction execution is proved',
                        'pdp1105, pdp1120 and pdp1140 are checked as installed ELF files only',
                        'Upstream BEND and BRQ STROBE TODO messages are observations, not implemented bus behavior'],
    })
    print('PDP11_NATIVE_MICROCYCLE_OK runs=2 exact_states_per_run=16 deterministic=true')


if __name__ == '__main__':
    main()
