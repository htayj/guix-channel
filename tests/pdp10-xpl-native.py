#!/usr/bin/env python3
"""Compile installed hello.xpl and independently observe its PDP-10 REL meaning.

Format authority: PDP-10/xpl-pdp-10 at
0e57cbd9e2e2997134332f6784dccc262a069d99, port/nexcom.xpl:
write_file (596), flush_*_buffer (1055), emitlabel/refcheck (1306),
emitbyte/emitdesc (1239/1455), radix50 (1091), and compile footer (4071).
port/dump.xpl independently documents the packed 36-bit reader and block tags.
This is an object observer, not a PDP-10 executor or compiler replacement.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import traceback

COMMIT = '0e57cbd9e2e2997134332f6784dccc262a069d99'
MASK18 = (1 << 18) - 1
MASK36 = (1 << 36) - 1
HIGH = 0o400000
HELLO = b'Hello world!'
SOURCE = b"output = 'Hello world!';\neof;\n"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def radix50(text):
    alphabet = ' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.$%'
    value = 0
    for char in (text.upper() + '      ')[:6]:
        value = value * 40 + alphabet.index(char)
    return value


def store_mounts(text):
    result = []
    for line in text.splitlines():
        fields = line.split()
        target = re.sub(r'\\([0-7]{3})', lambda match: chr(int(match[1], 8)), fields[4])
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            result.append((target, fields[5].split(',')))
    return result


def isolate(evidence, mount):
    require(os.getuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name in namespaces:
        require(namespaces[name] != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not private')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'network namespace has external interfaces')
    before = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-before.txt').write_text(before)
    subprocess.run([mount, '--rbind', '/gnu/store', '/gnu/store'], check=True, timeout=20)
    subprocess.run([mount, '--make-rprivate', '/gnu/store'], check=True, timeout=20)
    for target in sorted({target for target, _ in store_mounts(
            Path('/proc/self/mountinfo').read_text())}, key=len, reverse=True):
        subprocess.run([mount, '-o', 'remount,bind,ro', target], check=True, timeout=20)
    after = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-after.txt').write_text(after)
    mounts = store_mounts(after)
    require(mounts and all('ro' in flags for _, flags in mounts),
            'recursive store bind is not entirely read-only')
    result = {'uid': os.getuid(), 'gid': os.getgid(), 'namespaces': namespaces,
              'interfaces': interfaces, 'store_mounts': mounts,
              'uid_map': Path('/proc/self/uid_map').read_text(),
              'gid_map': Path('/proc/self/gid_map').read_text()}
    save(evidence / 'isolation.json', result)
    return result


def observe_rel(path):
    raw = path.read_bytes()
    require(raw and len(raw) % 9 == 0, 'REL is not packed pairs of 36-bit words')
    words = []
    for offset in range(0, len(raw), 9):
        pair = int.from_bytes(raw[offset:offset + 9], 'big')
        words.extend((pair >> 36, pair & MASK36))
    records = []
    cursor = 0
    ended = False
    # Block lengths count payload words, excluding each 18-word relocation bitmap.
    while cursor < len(words):
        if ended:
            require(words[cursor:] in ([], [0]), 'unexpected words after END block')
            break
        header = words[cursor]
        cursor += 1
        require(header <= 0o17777777, 'invalid REL block header')
        kind, length = header >> 18, header & MASK18
        require(kind in (1, 2, 3, 5, 6, 7, 8), 'unknown REL block type')
        require(length > 0, 'empty REL block')
        payload, relocations = [], []
        remaining = length
        while remaining:
            count = min(18, remaining)
            require(cursor + count < len(words), 'truncated REL block')
            bitmap = words[cursor]
            cursor += 1
            for index in range(count):
                payload.append(words[cursor])
                relocations.append((bitmap >> (34 - 2 * index)) & 3)
                cursor += 1
            require(bitmap & ((1 << (36 - 2 * count)) - 1) == 0,
                    'nonzero unused relocation bits')
            remaining -= count
        records.append({'kind': kind, 'payload': payload, 'relocation': relocations})
        ended = kind == 5
    require(ended, 'REL lacks END block')
    kinds = [record['kind'] for record in records]
    require(kinds[:2] == [6, 3], 'REL lacks NAME/HISEG prologue')
    require(kinds.count(6) == kinds.count(3) == kinds.count(5) == kinds.count(7) == 1,
            'duplicate or missing structural REL block')
    name, hiseg = records[0], records[1]
    # The type-17 control word is the SECOND payload word of NAME_TYPE+2,
    # not a freestanding block; nexcom writes no additional bitmap before it.
    require(name['payload'] == [radix50('hello.'), 0o17000000]
            and name['relocation'] == [0, 0],
            'NAME does not identify installed hello.xpl and its control word')
    require(hiseg['payload'] == [0o400000400000] and hiseg['relocation'] == [1],
            'HISEG does not define the PDP-10 high segment')
    memory = {}
    requests = []
    for record in records:
        kind, payload, rel = record['kind'], record['payload'], record['relocation']
        if kind == 1:
            require(len(payload) >= 2 and rel[0] == 1, 'invalid code/data load address')
            address = payload[0]
            for index, word in enumerate(payload[1:]):
                location = address + index
                require(location not in memory, 'overlapping code/data block')
                memory[location] = word
        elif kind == 8:
            require(all(value == 3 for value in rel), 'invalid internal-request relocation')
            requests.extend(payload)
    original = memory.copy()
    for request in requests:
        link, target = request >> 18, request & MASK18
        visited = set()
        while link:
            require(link in memory and link not in visited, 'invalid internal reference chain')
            visited.add(link)
            word = memory[link]
            memory[link] = (word & ~MASK18) | target
            link = word & MASK18
    start = next(record for record in records if record['kind'] == 7)
    end = next(record for record in records if record['kind'] == 5)
    require(len(start['payload']) == 1 and start['relocation'] == [1], 'invalid START block')
    require(len(end['payload']) == 2 and end['relocation'] == [1, 1], 'invalid END sizes')
    entry = start['payload'][0]
    code_end, data_end = end['payload']
    require(HIGH <= entry < code_end and entry in memory, 'START lies outside code segment')
    require(code_end > HIGH and data_end > 0, 'empty code/data segment')
    require(all(address < data_end if address < HIGH else address < code_end
                for address in memory), 'code/data exceeds END sizes')
    symbols = [record for record in records if record['kind'] == 2]
    require(len(symbols) == 1 and len(symbols[0]['payload']) == 2,
            'missing runtime external symbol')
    require(symbols[0]['payload'][0] == 0o600000000000 + radix50('xpllib')
            and symbols[0]['relocation'] == [0, 1],
            'external symbol is not a relocated XPLLIB reference')
    descriptors = []
    for address, word in memory.items():
        if address >= HIGH or word >> 27 != len(HELLO):
            continue
        byte_address = word & ((1 << 27) - 1)
        chars = []
        for index in range(len(HELLO)):
            position = byte_address + index
            location, lane = divmod(position, 4)
            if location not in memory or location >= HIGH:
                break
            chars.append((memory[location] >> (9 * (3 - lane))) & 0o777)
        if chars == list(HELLO):
            descriptors.append(address)
    require(descriptors, 'no 9-bit Hello world! string and length/address descriptor')
    outputs = []
    for address in sorted(memory):
        if address < entry or address >= code_end:
            continue
        word = memory[address]
        if word >> 27 != 3 or (word & ((1 << 23) - 1)) != 0:
            continue
        register = (word >> 23) & 15
        previous = memory.get(address - 1, 0)
        if (previous >> 27 == 0o200 and (previous >> 23) & 15 == register
                and (previous >> 18) & 0o37 == 0
                and previous & MASK18 in descriptors):
            outputs.append({'address_octal': format(address, 'o'), 'register': register,
                            'descriptor_address_octal': format(previous & MASK18, 'o')})
    require(outputs, 'hello descriptor is not loaded into the .outp. register')
    require(memory.get(code_end - 1) == 4 << 27, 'program does not end with .exit.')
    return {'format_source_commit': COMMIT, 'sha256': hashlib.sha256(raw).hexdigest(),
            'byte_count': len(raw), 'word_count': len(words), 'block_types': kinds,
            'entry_octal': format(entry, 'o'), 'code_end_octal': format(code_end, 'o'),
            'data_end_octal': format(data_end, 'o'), 'internal_requests': len(requests),
            'code_words': sum(address >= HIGH for address in original),
            'data_words': sum(address < HIGH for address in original),
            'hello_output_calls': outputs, 'string': HELLO.decode('ascii'),
            'runtime_external_symbol': 'XPLLIB', 'terminal_opcode': '.exit.'}


def main():
    out, evidence, scratch = map(Path, sys.argv[1:4])
    mount = sys.argv[4]
    evidence = evidence.resolve()
    runtime = {'status': 'failed', 'scope': 'installed-compiler REL semantics, not PDP-10 execution'}
    try:
        runtime['isolation'] = isolate(evidence, mount)
        for variable in ('HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_DATA_HOME',
                         'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'TMPDIR'):
            Path(os.environ[variable]).mkdir(parents=True, exist_ok=True)
        os.chmod(os.environ['XDG_RUNTIME_DIR'], 0o700)
        work = scratch / 'work'
        work.mkdir()
        require(not list(work.iterdir()), 'consumer work directory is not empty')
        source = out / 'share/pdp10-xpl/hello.xpl'
        require(source.read_bytes() == SOURCE, 'installed hello.xpl differs from pinned upstream')
        (evidence / 'hello.xpl').write_bytes(source.read_bytes())
        command = [str(out / 'bin/xpl'), '-K', '-o', 'hello.rel', str(source)]
        result = subprocess.run(command, cwd=work, stdin=subprocess.DEVNULL,
                                capture_output=True, timeout=240)
        (evidence / 'compiler.stdout').write_bytes(result.stdout)
        (evidence / 'compiler.stderr').write_bytes(result.stderr)
        runtime['compiler'] = {'command': command, 'returncode': result.returncode}
        require(result.returncode == 0, 'installed compiler exited nonzero')
        require(b'no errors were detected.' in result.stdout,
                'compiler did not report error-free compilation')
        obj = work / 'hello.rel'
        (evidence / 'hello.rel').write_bytes(obj.read_bytes())
        runtime['rel'] = observe_rel(obj)
        save(evidence / 'rel-observation.json', runtime['rel'])
        runtime['status'] = 'passed'
        print('PDP10_XPL_NATIVE_OBJECT_OK')
    except Exception as error:
        runtime['error'] = str(error)
        traceback.print_exc()
        raise
    finally:
        save(evidence / 'runtime.json', runtime)


if __name__ == '__main__':
    main()
