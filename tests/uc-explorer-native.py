#!/usr/bin/env python3
"""Exercise the installed Symbolics microcode parser on original local fixtures.

Oracle: larsbrinkhoff/uc-explorer fc4f9f3324d3497f553512b661ad37cbdde89ccb
src/ucode.rs. Format: section 1 + magic 5; 2 + u16 LE version; 3 + byte length
+ comment; 4/5 A/B runs (u16 count, u16 start, count 5-byte words) ended by
count 0; 6 C runs of 14-byte LE words, each followed by zero-terminated extra
codes; 7 type map (u16 count, u16 zero pad, bytes, u16 zero end); then 8, or 10
+ 255 pico-store (u16, u32) words + 0xffff + 8. src/main.rs reports parse
failures on stdout yet exits 0, and exits 1 when the input cannot be opened.
Assertions cover decoded semantics, not incidental Rust, Clap or banner prose.
Fixtures are original parser inputs, not Symbolics microcode or emulator state.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import struct
import subprocess
import sys

COMMIT = 'fc4f9f3324d3497f553512b661ad37cbdde89ccb'
SOURCE_BASE = 'https://raw.githubusercontent.com/larsbrinkhoff/uc-explorer/' + COMMIT + '/'
PARSE_FAILURE = 'Unable to parse microcode:'
LENGTHS = ('a-mem', 'b-mem', 'c-mem', 'type-map', 'pico-store')
# Exact acceptance fixture: header, version 1, empty comment/A/B/C/type map, EOF.
MINIMAL = bytes.fromhex('01 05 02 01 00 03 00 04 00 00 05 00 00 06 00 00 '
                        '07 00 00 00 00 00 00 08')
MINIMAL_FIELDS = {'version': '0x0001', 'comment': '',
                  'lengths': {name: 0 for name in LENGTHS}}
# One 112-bit control word, LE: low 0x0fedcba987654321, high 0x6996c33ca55a.
# The probed fields straddle both halves and the byte-8 split; values were
# derived by hand from MicroInstruction::new shifts/masks, shown in octal.
CWORD = bytes.fromhex('21 43 65 87 a9 cb ed 0f 5a a5 3c c3 96 69')
CWORD_FIELDS = {
    'A Mem Read Address': 0o1441,  # low bits 11-0 = 0x321
    'U COND FUNC': 0,              # low bits 63-62 of 0x0f...
    'U ALU': 0o12,                 # high bits 3-0 = 0xa
    'U NAF': 0o1474,               # high bits 29-16 = 0x033c
    'U AU OP': 0o246,              # high bits 45-38
}
POPULATED_FIELDS = {'version': '0x1234', 'comment': 'UCX\u00e9',
                    'lengths': {'a-mem': 3, 'b-mem': 1, 'c-mem': 1,
                                'type-map': 3, 'pico-store': 255}}


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def u16(value):
    return struct.pack('<H', value)


def type_map(entries, pad=0, end=0):
    return b'\x07' + u16(len(entries)) + u16(pad) + bytes(entries) + u16(end)


def pico_store(words, trailer=0xffff, eof=8):
    body = b''.join(struct.pack('<HI', address, data) for address, data in words)
    return b'\x0a' + body + u16(trailer) + bytes([eof])


PREFIX = bytes.fromhex('01 05 02 01 00 03 00')
EMPTY_MEMS = bytes.fromhex('04 00 00 05 00 00 06 00 00')
EMPTY_TAIL = PREFIX + EMPTY_MEMS + type_map([])
PICO = [(index, 0x01000000 | index * 0x10101) for index in range(255)]


def populated():
    # Two A runs (2+1 words), one B word, one C word whose extra codes 07 03
    # must be consumed through their zero terminator before C's count=0.
    a_mem = (b'\x04' + u16(2) + u16(0x0010) + bytes.fromhex('11 22 33 44 55 66 77 88 99 aa') +
             u16(1) + u16(0x0020) + bytes.fromhex('01 02 03 04 05') + u16(0))
    b_mem = b'\x05' + u16(1) + u16(0x0100) + bytes.fromhex('fe dc ba 98 76') + u16(0)
    c_mem = b'\x06' + u16(1) + u16(0o102) + CWORD + bytes.fromhex('07 03 00') + u16(0)
    return (bytes.fromhex('01 05 02 34 12 03 04') + b'UCX\xe9' + a_mem + b_mem + c_mem +
            type_map([1, 2, 3]) + pico_store(PICO))


# (name, bytes, ucode.rs section reason or None for a truncated read)
MALFORMED = [
    ('empty', b'', None),
    ('missing-eof', MINIMAL[:-1], None),
    ('header-section', b'\x00' + MINIMAL[1:], 'Invalid header'),
    ('header-magic', b'\x01\x04' + MINIMAL[2:], 'Invalid header'),
    ('version-section', b'\x01\x05\x03' + MINIMAL[3:], 'Invalid version'),
    ('comment-section', MINIMAL[:5] + b'\x04' + MINIMAL[6:], 'Invalid comment'),
    ('a-mem-section', PREFIX + b'\x05' + EMPTY_MEMS[1:], 'Invalid A/B memory'),
    ('b-mem-section', PREFIX + bytes.fromhex('04 00 00 06 00 00'), 'Invalid A/B memory'),
    ('a-mem-truncated-word', PREFIX + b'\x04' + u16(1) + u16(0) + b'\x01\x02', None),
    ('c-mem-section', PREFIX + bytes.fromhex('04 00 00 05 00 00 07 00 00'), 'Invalid C memory'),
    ('c-mem-unterminated-extra', PREFIX + bytes.fromhex('04 00 00 05 00 00 06') + u16(1) +
     u16(0) + CWORD + b'\x07', None),
    ('type-map-section', PREFIX + EMPTY_MEMS + b'\x08', 'Invalid Type Map'),
    ('type-map-pad', PREFIX + EMPTY_MEMS + type_map([], pad=1), 'Invalid Type Map'),
    ('type-map-end', PREFIX + EMPTY_MEMS + type_map([], end=1), 'Invalid Type Map'),
    ('pico-store-section', EMPTY_TAIL + b'\x09', 'Invalid Pico-store'),
    ('pico-store-254-words', EMPTY_TAIL + pico_store(PICO[:254]), None),
    ('pico-store-trailer', EMPTY_TAIL + pico_store(PICO, trailer=0xfffe), 'Invalid Pico-store'),
    ('pico-store-eof', EMPTY_TAIL + pico_store(PICO, eof=7), 'Invalid Pico-store EOF'),
]


def decode_state(stdout):
    """Return the semantic fields printed by Microcode's Display impl."""
    text = stdout.decode('utf-8')
    require('valid ucode' in text.splitlines(), 'missing valid ucode marker')
    require(PARSE_FAILURE not in text, 'valid result also reports a parse failure')
    version = re.search(r'^version=(0x[0-9a-f]{4})$', text, re.M)
    comment = re.search(r"^comment='(.*)'$", text, re.M)
    require(version and comment, 'missing version/comment fields')
    lengths = {}
    for name in LENGTHS:
        match = re.search(r'^' + re.escape(name) + r' length=(\d+)$', text, re.M)
        require(match, 'missing length field: ' + name)
        lengths[name] = int(match.group(1))
    addresses = re.findall(r'^([0-7]{5})>$', text, re.M)
    fields = {}
    for label in CWORD_FIELDS:
        values = re.findall(r'^' + re.escape(label) + r':?\s+([0-7]+)$', text, re.M)
        if values:
            fields[label] = [int(value, 8) for value in values]
    return {'version': version.group(1), 'comment': comment.group(1), 'lengths': lengths,
            'c_mem_addresses': addresses, 'c_word_fields': fields}


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
    require(len(MINIMAL) == 24, 'acceptance fixture must be exactly 24 bytes')
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

    root = scratch / 'run'
    root.mkdir(mode=0o700)
    env = {'LC_ALL': 'C', 'PATH': os.environ['PATH'], 'TMPDIR': str(root)}
    clean_dirs = []
    for key, directory in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                           ('XDG_CACHE_HOME', 'cache'), ('XDG_DATA_HOME', 'data'),
                           ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime')):
        path = root / directory
        path.mkdir(mode=0o700)
        env[key] = str(path)
        clean_dirs.append(path)
    work = root / 'work'
    work.mkdir(mode=0o700)
    fixture_dir = evidence / 'fixtures'
    fixture_dir.mkdir()
    inputs = {}
    for name, data in ([('minimal', MINIMAL), ('minimal-trailing-bytes', MINIMAL + b'\xff\x00'),
                        ('populated', populated())] + [(n, d) for n, d, _ in MALFORMED]):
        (fixture_dir / (name + '.uc')).write_bytes(data)
        path = work / (name + '.uc')
        path.write_bytes(data)
        path.chmod(0o400)
        inputs[name] = (path, data)
    program = str(out / 'bin/uc-explorer')
    runs = []

    def run(scenario, arguments):
        stem = f'{len(runs):02d}.{scenario}'
        stdout_path = evidence / (stem + '.stdout')
        stderr_path = evidence / (stem + '.stderr')
        command = [program, *arguments]
        with stdout_path.open('wb') as stdout, stderr_path.open('wb') as stderr:
            child = subprocess.run(command, cwd=work, env=env, stdin=subprocess.DEVNULL,
                                   stdout=stdout, stderr=stderr, timeout=10)
        actual_stdout, actual_stderr = stdout_path.read_bytes(), stderr_path.read_bytes()
        runs.append({'scenario': scenario, 'command': command, 'exit_status': child.returncode,
                     'stdout_sha256': hashlib.sha256(actual_stdout).hexdigest(),
                     'stderr_sha256': hashlib.sha256(actual_stderr).hexdigest()})
        save(evidence / 'runs.json', runs)
        return child.returncode, actual_stdout, actual_stderr

    def accept(scenario, expected):
        status, stdout, stderr = run(scenario, [str(inputs[scenario][0])])
        require(status == 0 and stderr == b'', scenario + ': valid input did not exit 0 cleanly')
        decoded = decode_state(stdout)
        save(evidence / (scenario + '.decoded.json'), decoded)
        for key, value in expected.items():
            require(decoded[key] == value, f'{scenario}: decoded {key} {decoded[key]!r} != {value!r}')
        return decoded, stdout

    minimal, _ = accept('minimal', MINIMAL_FIELDS)
    require(minimal['c_mem_addresses'] == [] and minimal['c_word_fields'] == {},
            'minimal input decoded control-memory words')
    # Section 8 ends parsing; trailing bytes are not examined by ucode.rs.
    trailing, _ = accept('minimal-trailing-bytes', MINIMAL_FIELDS)
    require(trailing == minimal, 'trailing bytes after section 8 changed the decoded state')
    decoded, first_stdout = accept('populated', POPULATED_FIELDS)
    require(decoded['c_mem_addresses'] == ['00102'], 'C word start address not decoded')
    require(decoded['c_word_fields'] == {label: [value] for label, value in CWORD_FIELDS.items()},
            'populated C word fields decoded wrongly: ' + repr(decoded['c_word_fields']))
    # Determinism: one representative populated input decoded twice.
    _, second_stdout = accept('populated', POPULATED_FIELDS)
    require(first_stdout == second_stdout, 'populated decode is not deterministic')

    for name, _, reason in MALFORMED:
        status, stdout, stderr = run(name, [str(inputs[name][0])])
        text = stdout.decode('utf-8', 'replace')
        lines = text.splitlines()
        # ucode.rs failures are reported, not signalled: exit 0, one stdout line.
        require(status == 0 and stderr == b'', name + ': parse failure changed exit/stderr handling')
        require(len(lines) == 1 and lines[0].startswith(PARSE_FAILURE),
                name + ': malformed input was not rejected')
        require('valid ucode' not in text, name + ': malformed input reported valid')
        detail = lines[0][len(PARSE_FAILURE):].strip()
        if reason is None:
            require(detail and not detail.startswith('Invalid '),
                    name + ': truncation not reported as an I/O read failure')
        else:
            require(detail == reason, f'{name}: rejected as {detail!r}, expected {reason!r}')

    absent = work / 'absent.uc'
    status, stdout, stderr = run('missing-file', [str(absent)])
    require(status == 1 and stdout == b'', 'missing input file did not fail with exit 1')
    require(str(absent).encode() in stderr, 'open failure does not name the input path')
    status, stdout, stderr = run('missing-input-argument', [])
    require(status != 0 and stdout == b'' and stderr, 'missing INPUT argument was accepted')

    require(all(not any(path.iterdir()) for path in clean_dirs), 'HOME/XDG state was written')
    require({p for p in work.iterdir()} == {path for path, _ in inputs.values()},
            'parser created files beside its inputs')
    for path, data in inputs.values():
        require(path.read_bytes() == data, 'parser input changed: ' + path.name)
    save(evidence / 'runtime.json', {
        'status': 'passed', 'source_commit': COMMIT,
        'source_urls': [SOURCE_BASE + 'src/main.rs', SOURCE_BASE + 'src/ucode.rs'],
        'isolation': isolation, 'runs': runs, 'deterministic': True,
        'fixture_origin': 'original local parser inputs; no Symbolics microcode',
        'fixture_sha256': {name: hashlib.sha256(data).hexdigest()
                           for name, (_, data) in inputs.items()},
        'decoded_contract': {'minimal': MINIMAL_FIELDS, 'populated': POPULATED_FIELDS,
                             'populated_c_word': {'address': '00102', **CWORD_FIELDS}},
        'error_contract': {'malformed_sections': 'stdout parse failure naming the section, exit 0',
                           'truncation': 'stdout parse failure from the read error, exit 0',
                           'open_failure': 'stderr names input path, exit 1',
                           'missing_argument': 'stderr, nonzero exit'},
        'limitations': ['A/B/type-map/pico-store contents are not printed; only their counts are observable',
                        'Bytes after section 8 are not checked by the parser',
                        'No authentic Symbolics microcode file was exercised'],
    })
    print('UC_EXPLORER_NATIVE_OK minimal=version:0x0001,lengths:0 '
          'populated=a3,b1,c1@00102,type3,pico255 malformed=%d deterministic=true' % len(MALFORMED))


if __name__ == '__main__':
    main()
