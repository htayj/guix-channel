#!/usr/bin/env python3
"""Observe real installed GCC -S output, never assemble/link/execute PDP-10 code.

Authority: larsbrinkhoff/pdp10-gcc commit
3c67a2b56b8a02041bdfca00d012bcccbe4168e5:
gcc/config/pdp10/pdp10.md addsi3 (2298), subsi3 (2402), mulsi3 (2478),
cbranchsi (5507), jump (5005); pdp10.c macro_file_start/end (3767/3845),
pdp10_output_return (6992), condition_string (1696); pdp10.h BITS_PER_UNIT,
INT_TYPE_SIZE and FUNCTION_VALUE.  This is a structural assembly observer,
not an assembler, instruction interpreter or guest-runtime claim.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import sys
import traceback

COMMIT = '3c67a2b56b8a02041bdfca00d012bcccbe4168e5'
TARGET = 'pdp10-unknown-tops20'
SOURCE = '''/* No target headers, libc, assembler or linker required. */
typedef char int_is_four_target_bytes[(sizeof(int) == 4) ? 1 : -1];
int arith(int a, int b, int c) { return (a + b) * c - b; }
int flow(int n) {
    int total = 0;
    while (n > 0) {
        if (n < 4) total += n;
        else total -= n;
        n -= 1;
    }
    return total;
}
'''


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def store_mounts(text):
    result = []
    for line in text.splitlines():
        fields = line.split()
        target = re.sub(r'\\([0-7]{3})', lambda match: chr(int(match[1], 8)), fields[4])
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            result.append((target, fields[5].split(',')))
    return result


def isolate(evidence, mount):
    require(os.getuid() == os.geteuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == os.getegid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name in namespaces:
        require(namespaces[name] != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not private')
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
    require(mounts and all('ro' in flags for _, flags in mounts), 'store is not recursively read-only')
    result = {'uid': os.getuid(), 'gid': os.getgid(), 'namespaces': namespaces,
              'interfaces': interfaces, 'store_mounts': mounts,
              'uid_map': Path('/proc/self/uid_map').read_text(),
              'gid_map': Path('/proc/self/gid_map').read_text()}
    save(evidence / 'isolation.json', result)
    return result


def observe_assembly(path):
    text = path.read_text()
    require(re.search(r'^\s*TITLE\s+codegen\s*$', text, re.M), 'missing MACRO source TITLE')
    require(re.search(r'^\s*END\s*$', text, re.M), 'missing complete MACRO END')
    functions = {}
    # C symbols preserve their spelling (pdp10_asm_output_labelref); labels may
    # be uppercased by target options. Internal labels start with % (macro.h).
    for name in ('arith', 'flow'):
        require(re.search(r'^\s*ENTRY\s+' + name + r'\s*$', text, re.M | re.I),
                'missing exported ' + name)
        match = re.search(r'^' + name + r':\s*\n(.*?)(?=^\s*ENTRY\b|^\s*END\b)',
                          text, re.M | re.S | re.I)
        require(match, 'missing function body ' + name)
        body = match[1]
        lines = [line.split(';', 1)[0].strip() for line in body.splitlines()]
        instructions = [line.split(None, 1) for line in lines
                        if line and not line.endswith((':', ':!'))]
        mnemonics = [parts[0].upper() for parts in instructions]
        require(any(parts[0].upper() == 'POPJ' and re.fullmatch(r'17,\s*', parts[1])
                    for parts in instructions if len(parts) == 2), 'missing PDP-10 return in ' + name)
        functions[name] = {'mnemonics': mnemonics, 'body': body}
    arithmetic = functions['arith']['mnemonics']
    for operation, family in [('addition', {'ADD', 'ADDI', 'ADDM', 'ADDB'}),
                              ('multiplication', {'IMUL', 'IMULI', 'IMULM', 'IMULB'}),
                              ('subtraction', {'SUB', 'SUBM', 'SUBB'})]:
        require(family.intersection(arithmetic), 'arith lacks source-backed ' + operation)
    body = functions['flow']['body']
    mnemonics = functions['flow']['mnemonics']
    require({'ADD', 'ADDI', 'ADDM', 'ADDB', 'AOS'}.intersection(mnemonics),
            'flow lacks countdown-loop addition')
    require({'SUB', 'SUBM', 'SUBB'}.intersection(mnemonics),
            'flow lacks signed else-branch subtraction')
    require(any(re.fullmatch(r'(?:JUMP|SKIP|CAI|CAM)(?:L|E|LE|GE|N|G)', op)
                for op in mnemonics), 'flow lacks signed conditional branch/skip')
    labels = {match[1].upper(): match.start() for match in
              re.finditer(r'^(%[A-Za-z0-9.$]+):!?\s*$', body, re.M)}
    jumps = list(re.finditer(r'^\s*JRST\s+(%[A-Za-z0-9.$]+)\s*$', body, re.M | re.I))
    require(labels and jumps, 'flow lacks local control-flow labels/JRST')
    require(all(jump[1].upper() in labels for jump in jumps), 'flow jumps to undefined local label')
    require(any(labels[jump[1].upper()] < jump.start() for jump in jumps), 'flow lacks loop backedge')
    return {'dialect': 'TOPS-20 MACRO', 'source_commit': COMMIT,
            'observer': 'structural output only, not executed semantics',
            'source_operations': {'arith': '(a+b)*c-b',
                                  'flow': 'signed countdown loop; add n for n<4, otherwise subtract n'},
            'function_instructions': {name: info['mnemonics'] for name, info in functions.items()},
            'loop_labels': sorted(labels), 'loop_jumps': [jump[1] for jump in jumps],
            'assembly_sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    out, evidence, scratch = map(Path, sys.argv[1:4])
    mount, bash = sys.argv[4:6]
    record = {'status': 'failed', 'output': str(out), 'source_commit': COMMIT,
              'scope': 'real native cross-GCC preprocessing and -S code generation only',
              'not_proven': ['target assembly', 'target linking', 'PDP-10 execution'], 'commands': []}
    work = scratch / 'work'
    try:
        record['isolation'] = isolate(evidence, mount)
        for variable in ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME',
                         'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'):
            path = Path(os.environ[variable])
            path.mkdir(mode=0o700)
            require(not list(path.iterdir()), variable + ' is not fresh')
        work.mkdir(mode=0o700)
        env = {name: os.environ[name] for name in
               ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME',
                'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'LC_ALL')}
        env['PATH'] = ''
        record['consumer_environment'] = dict(env)
        compiler = str(out / 'bin' / (TARGET + '-gcc'))
        cpp = str(out / 'bin' / (TARGET + '-cpp'))
        for program in (compiler, cpp, str(out / 'lib/gcc-lib' / TARGET / '3.2/cc1')):
            require(os.access(program, os.X_OK), 'missing installed native component ' + program)
        require((out / 'lib/gcc-lib' / TARGET / '3.2/specs').is_file(), 'missing installed specs')
        forbidden = [str(path.relative_to(out)) for path in out.rglob('*')
                     if path.name in ('as', 'ld', 'macro', 'collect2', TARGET + '-as', TARGET + '-ld')
                     or re.fullmatch(r'libgcc.*\.(?:a|o|REL)', path.name)]
        require(not forbidden, 'unsupported target tool/runtime installed: ' + repr(forbidden))
        doc = out / 'share/doc/pdp10-gcc-3.2-20020416'
        notices = {'COPYING': 'GNU GENERAL PUBLIC LICENSE', 'COPYING.LIB': 'GNU LESSER GENERAL PUBLIC LICENSE',
                   'README': 'Permission is hereby granted to use or copy', 'LICENSE': 'Cygnus Solutions',
                   'zlib.h': 'Permission is granted to anyone', 'LIBGCJ_LICENSE': 'special exception'}
        for name, phrase in notices.items():
            require(phrase in (doc / name).read_text(), 'missing license notice ' + name)
        record['notices'] = sorted(notices)

        def run(label, command, success=True, environment=None):
            entry = {'label': label, 'command': command}
            record['commands'].append(entry)
            try:
                result = subprocess.run(command, cwd=work, env=environment or env,
                                        stdin=subprocess.DEVNULL, capture_output=True, timeout=45)
            except subprocess.TimeoutExpired as error:
                (evidence / (label + '.stdout')).write_bytes(error.stdout or b'')
                (evidence / (label + '.stderr')).write_bytes(error.stderr or b'')
                entry['timeout'] = True
                raise
            (evidence / (label + '.stdout')).write_bytes(result.stdout)
            (evidence / (label + '.stderr')).write_bytes(result.stderr)
            entry['returncode'] = result.returncode
            if success:
                require(result.returncode == 0, label + ' exited nonzero')
                # No diagnostic suppression: old GCC can emit native errors
                # while returning zero. Successful compilation must be quiet.
                require(not result.stderr.strip(), label + ' emitted a native diagnostic despite success')
                if label != 'target':
                    require(not result.stdout.strip(), label + ' emitted unexpected native output despite success')
            return result

        require(run('target', [compiler, '-dumpmachine']).stdout.strip().decode() == TARGET,
                'compiler target differs from package contract')
        (work / 'codegen.c').write_text(SOURCE)
        (evidence / 'codegen.c').write_text(SOURCE)
        run('preprocess', [cpp, '-P', 'codegen.c', 'codegen.i'])
        require('int arith' in (work / 'codegen.i').read_text(), 'standalone cpp omitted C consumer')
        shutil.copyfile(work / 'codegen.i', evidence / 'codegen.i')

        traps = work / 'host-tools'
        traps.mkdir()
        marker = work / 'trap-used'
        fixtures = []
        for name in ('as', 'ld', 'collect2', TARGET + '-as', TARGET + '-ld'):
            fixtures.append(traps / name)
        fixtures.append(work / 'macro')  # DEFAULT_ASSEMBLER="macro" used to bypass PATH.
        for path in fixtures:
            path.write_text('#!' + bash + '\nprintf "%s\\n" "' + path.name + '" > "' + str(marker) + '"\nexit 0\n')
            path.chmod(0o700)
            run('fixture-' + path.name, [str(path)])
            require(marker.read_text().strip() == path.name, 'successful trap fixture did not record invocation')
            marker.unlink()
        record['trap_fixture'] = {'deliberately_successful': True, 'not_a_compiler_or_target_tool': True,
                                  'paths': [str(path) for path in fixtures], 'self_proven': True}
        hostile = dict(env, PATH=str(traps))
        run('compile-S', [compiler, '-S', '-O0', '-ffreestanding', '-fno-builtin',
                          '-mregparm=7', 'codegen.c', '-o', 'codegen.s'], environment=hostile)
        require(not marker.exists(), '-S invoked a trap target tool')
        require((work / 'codegen.s').is_file() and (work / 'codegen.s').stat().st_size > 0,
                'compiler produced no assembly')
        shutil.copyfile(work / 'codegen.s', evidence / 'codegen.s')
        record['assembly'] = observe_assembly(work / 'codegen.s')
        save(evidence / 'assembly-observation.json', record['assembly'])

        def unavailable(label, command, tool, product):
            result = run(label, command, success=False, environment=hostile)
            product_path = work / product
            probe = {'expected_unavailable_tool': tool,
                     'returncode': result.returncode,
                     'trap_invoked': marker.exists(),
                     'trap_marker': marker.read_text() if marker.exists() else None,
                     'product_exists': product_path.exists(),
                     'product_bytes': product_path.stat().st_size if product_path.is_file() else None,
                     'cwd_macro_fixture_exists': (work / 'macro').is_file()}
            record.setdefault('unavailable_probes', {})[label] = probe
            save(evidence / (label + '-observation.json'), probe)
            require(result.returncode != 0, label + ' unexpectedly succeeded')
            require(not marker.exists(), label + ' fell back to a successful host-tool trap')
            require(not (work / product).exists(), label + ' produced an unsupported output')
            diagnostic = result.stderr.decode(errors='replace')
            require(re.search(r'(?:cannot exec|No such file|not found)', diagnostic, re.I)
                    and re.search(r'\b' + tool + r'\b', diagnostic),
                    label + ' did not fail specifically for unavailable ' + tool)
            require(not re.search(r'internal compiler error|Segmentation fault|Aborted', diagnostic, re.I),
                    label + ' failed through a native compiler crash')

        unavailable('no-assembler', [compiler, '-c', '-O0', '-ffreestanding',
                                     'codegen.i', '-o', 'codegen.o'], 'as', 'codegen.o')
        # An explicit opaque .o filename bypasses cc1/as and reaches the native
        # linker lookup. This is NOT a target object, nor fake link success.
        (work / 'opaque.o').write_bytes(b'PDP10-GCC smoke linker-lookup fixture, not an assembled object\n')
        shutil.copyfile(work / 'opaque.o', evidence / 'opaque.o')
        record['link_input_fixture'] = 'opaque .o bytes solely to reach missing ld lookup; not a target object'
        unavailable('no-linker', [compiler, '-nostdlib', '-nostartfiles',
                                  'opaque.o', '-o', 'codegen'], 'ld', 'codegen')
        record['status'] = 'passed'
        print('PDP10_GCC_NATIVE_CODEGEN_OK (no target assembly/link/runtime claim)')
    except Exception as error:
        record['error'] = str(error)
        traceback.print_exc()
        raise
    finally:
        save(evidence / 'evidence.json', record)


if __name__ == '__main__':
    main()
