#!/usr/bin/env python3
"""Type-check an external consumer of the installed meta-typing declarations."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import sys
import tarfile
import traceback

COMMIT = '03a4927933e3a6e6439d42f29d656353512fe308'
COMPILER_VERSION = '3.7.4'
# Fixture -> compiler diagnostic each original rejected assignment must raise.
REJECTED = {
    'wrong-sum.ts': 2322,
    'unsupported-overflow.ts': 2322,
    'unsorted.ts': 2322,
    'duplicate-kept.ts': 2322,
    'depth-order-for-breadth.ts': 2322,
    'inexact-quotient.ts': 2344,
    'string-element.ts': 2344,
}
DIAGNOSTIC = re.compile(r'^(.+?)\((\d+),(\d+)\): error TS(\d+): (.*)$')
RESOLVED = re.compile(r"^======== Module name 'meta-typing' was successfully resolved to '([^']+)'")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


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


def isolate(evidence, mount):
    require(os.getuid() == os.geteuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == os.getegid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, identity in namespaces.items():
        require(identity != os.environ['HOST_' + name.upper() + '_NS'], name + ' namespace not private')
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
    result = {'uid': os.getuid(), 'gid': os.getgid(), 'namespaces': namespaces,
              'interfaces': interfaces, 'store_mounts': mounts,
              'uid_map': Path('/proc/self/uid_map').read_text(),
              'gid_map': Path('/proc/self/gid_map').read_text()}
    save(evidence / 'isolation.json', result)
    return result


def inspect_installed(out, module):
    """The public package is declaration-only and exposes its upstream types entry."""
    require(module.is_dir() and not module.is_symlink(), 'missing installed meta-typing module')
    metadata = json.loads((module / 'package.json').read_text())
    require(metadata.get('name') == 'meta-typing' and metadata.get('version') == '0.1.0'
            and metadata.get('license') == 'MIT', 'installed package identity changed')
    require(metadata.get('types') == './src/index.d.ts', 'installed types entry is not upstream')
    require(not {'main', 'module', 'exports', 'bin', 'browser'} & set(metadata),
            'installed package advertises a runtime entry')
    require('Permission is hereby granted' in (module / 'LICENSE').read_text(),
            'installed MIT license absent')
    files = sorted(path for path in module.rglob('*') if path.is_file())
    declarations = [path for path in files if path.name.endswith('.d.ts')]
    require((module / 'src/index.d.ts') in declarations, 'installed index.d.ts absent')
    require(not [path for path in files if path.name.endswith('.test-d.ts')],
            'author tsd tests installed as public declarations')
    require(not [path for path in files if path.suffix in ('.js', '.mjs', '.cjs', '.ts')
                 and not path.name.endswith('.d.ts')], 'installed package contains runtime/source code')
    return {'package_json': metadata,
            'declarations': {str(path.relative_to(module)): sha256(path) for path in declarations}}


def extract_compiler(archive, destination):
    """Unpack the fixed npm archive without trusting member paths or links."""
    staging = destination.parent / 'compiler-archive'
    staging.mkdir(mode=0o700)
    with tarfile.open(archive) as tar:
        members = tar.getmembers()
        for member in members:
            parts = Path(member.name).parts
            require(parts and parts[0] == 'package' and '..' not in parts
                    and not member.name.startswith('/'), 'unsafe compiler archive member')
            require(member.isfile() or member.isdir(), 'compiler archive contains links/devices')
        tar.extractall(staging, members=members, filter='data')
    (staging / 'package').rename(destination)
    staging.rmdir()
    metadata = json.loads((destination / 'package.json').read_text())
    require(metadata.get('name') == 'typescript' and metadata.get('version') == COMPILER_VERSION,
            'compiler archive is not standalone TypeScript ' + COMPILER_VERSION)
    return metadata['version']


def marker(path):
    """Line and diagnostic code that a rejected fixture declares inline."""
    found = [(number, int(match[1])) for number, line in
             enumerate(path.read_text().splitlines(), 1)
             for match in [re.search(r'// expect TS(\d+)$', line)] if match]
    require(len(found) == 1, 'rejected fixture must have exactly one expectation: ' + path.name)
    return found[0]


def main():
    out, evidence, scratch, templates = map(Path, sys.argv[1:5])
    mount, node, archive = sys.argv[5], Path(sys.argv[6]), Path(sys.argv[7])
    module = out / 'lib/node_modules/meta-typing'
    record = {'status': 'failed', 'output': str(out), 'source_commit': COMMIT,
              'scope': 'installed declaration-only package compiled by an external '
                       'strict TypeScript ' + COMPILER_VERSION + ' consumer',
              'compiler_archive': str(archive), 'commands': []}
    try:
        record['isolation'] = isolate(evidence, mount)
        for variable in ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME',
                         'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'):
            path = Path(os.environ[variable])
            path.mkdir(mode=0o700)
            require(not list(path.iterdir()), variable + ' is not fresh')
        record['installed'] = inspect_installed(out, module)
        save(evidence / 'installed.json', record['installed'])
        compiler = scratch / 'compiler'
        record['compiler_version'] = extract_compiler(archive, compiler)
        record['compiler_archive_sha256'] = sha256(archive)
        tsc = compiler / 'bin/tsc'

        # External consumer project: original fixtures plus one package link.
        work = scratch / 'consumer'
        work.mkdir(mode=0o700)
        shutil.copyfile(templates / 'accepted.ts', work / 'accepted.ts')
        shutil.copytree(templates / 'rejected', work / 'rejected')
        (work / 'node_modules').mkdir()
        (work / 'node_modules/meta-typing').symlink_to(module)
        require(sorted(path.name for path in (work / 'rejected').iterdir())
                == sorted(REJECTED), 'rejected fixture set differs from expectations')
        shutil.copytree(work, evidence / 'consumer-source', symlinks=True)

        env = {name: os.environ[name] for name in
               ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME',
                'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'LC_ALL')}
        env['PATH'] = str(node / 'bin')
        record['consumer_environment'] = dict(env)
        options = {'strict': True, 'noEmit': True, 'target': 'es5', 'lib': ['esnext'],
                   'module': 'commonjs', 'moduleResolution': 'node',
                   'forceConsistentCasingInFileNames': True, 'types': [],
                   'pretty': False, 'listFiles': True}

        def run(label, arguments, timeout=300):
            command = [str(node / 'bin/node'), str(tsc)] + arguments
            entry = {'label': label, 'command': command}
            record['commands'].append(entry)
            try:
                result = subprocess.run(command, cwd=work, env=env, stdin=subprocess.DEVNULL,
                                        capture_output=True, timeout=timeout)
            except subprocess.TimeoutExpired as error:
                (evidence / (label + '.stdout')).write_bytes(error.stdout or b'')
                (evidence / (label + '.stderr')).write_bytes(error.stderr or b'')
                entry['timeout'] = True
                raise
            (evidence / (label + '.stdout')).write_bytes(result.stdout)
            (evidence / (label + '.stderr')).write_bytes(result.stderr)
            entry['returncode'] = result.returncode
            require(not result.stderr, label + ' wrote to stderr; inspect captured logs')
            return result.returncode, result.stdout.decode().splitlines()

        def project(name, root, trace=False):
            config = work / ('tsconfig.' + name + '.json')
            save(config, {'compilerOptions': dict(options, traceResolution=trace),
                          'files': [root]})
            shutil.copyfile(config, evidence / config.name)
            return ['-p', str(config)]

        def program_files(lines):
            files = [Path(line) for line in lines if line.startswith('/')]
            bases = [base.resolve() for base in (work, compiler / 'lib', module)]
            for path in files:
                path = path.resolve()
                require(any(path == base or base in path.parents for base in bases),
                        'program loaded a file outside consumer/compiler/package: ' + str(path))
            return files

        code, lines = run('tsc-version', ['--version'])
        require(code == 0 and lines == ['Version ' + COMPILER_VERSION], 'unexpected compiler version')

        code, lines = run('accepted', project('accepted', 'accepted.ts', trace=True))
        diagnostics = [line for line in lines if DIAGNOSTIC.match(line)]
        require(code == 0 and not diagnostics, 'accepted consumer did not type-check cleanly')
        resolutions = {match[1] for line in lines for match in [RESOLVED.match(line)] if match}
        require(resolutions == {str(module / 'src/index.d.ts')},
                'meta-typing did not resolve to the installed types entry')
        loaded = program_files(lines)
        installed = {module / name for name in record['installed']['declarations']}
        require(installed <= set(loaded), 'accepted program did not load every public declaration')
        record['accepted'] = {'resolved_types': sorted(resolutions),
                              'program_files': [str(path) for path in loaded]}

        record['rejected'] = {}
        for name, expected in sorted(REJECTED.items()):
            line_number, declared = marker(work / 'rejected' / name)
            require(declared == expected, name + ' marker disagrees with expected diagnostic')
            label = 'rejected-' + name[:-3]
            code, lines = run(label, project(label, 'rejected/' + name))
            found = [DIAGNOSTIC.match(line) for line in lines]
            found = [{'file': match[1], 'line': int(match[2]), 'column': int(match[3]),
                      'code': int(match[4]), 'message': match[5]} for match in found if match]
            require(code in (1, 2), name + ' compiler did not report diagnostics normally')
            require(found and all((work / item['file']).resolve()
                                  == (work / 'rejected' / name).resolve()
                                  and item['line'] == line_number
                                  and item['code'] == expected for item in found),
                    name + ' was not rejected only by TS' + str(expected) + ' at its marker')
            program_files(lines)
            record['rejected'][name] = found
        save(evidence / 'rejections.json', record['rejected'])
        record['status'] = 'passed'
        print('META_TYPING_CONSUMER_OK')
    except Exception as error:
        record['error'] = str(error)
        traceback.print_exc()
        raise
    finally:
        save(evidence / 'evidence.json', record)


if __name__ == '__main__':
    main()
