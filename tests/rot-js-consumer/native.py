#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Offline external consumer of an installed rot-js output.

Runs inside private user/mount/net/PID namespaces as the caller's UID with a
recursively read-only /gnu/store.  It compiles a strict TypeScript 4.5.4
consumer against the installed public declarations, executes the emitted
program against the installed package, rejects two typed misuse fixtures and
drives the native ESM, readable UMD and minified UMD builds through exact
seeded Digger connectivity/path, FOV and scheduler semantics.
"""
import errno
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

VERSION = '2.2.1'
COMPILER_VERSION = '4.5.4'
REJECTED = {'actor.ts': 2322, 'topology.ts': 2322}
ACCEPTED_STDOUT = ('{"arenaFloors":9,"path":[[1,1],[2,1],[3,1]],"visible":9,'
                   '"actor":"typed-hero","time":0.5,"seed":151}\n')
RUNTIME_STDOUT = ('ROT_JS_RUNTIME_OK builds=3 seed=151 connectivity=all-floors '
                  'shortest-paths=all-floors fov=exact schedulers=exact\n')
BUILDS = ('lib/index.js', 'dist/rot.js', 'dist/rot.min.js')
DIAGNOSTIC = re.compile(r'^(.+?)\((\d+),(\d+)\): error TS(\d+): (.*)$')
RESOLVED = re.compile(r"^======== Module name 'rot-js' was successfully resolved to '([^']+)'")


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


def isolate(evidence, mount, module):
    require(os.getuid() == os.geteuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == os.getegid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, identity in namespaces.items():
        require(identity != os.environ['HOST_' + name.upper() + '_NS'], name + ' namespace not private')
    require(os.getpid() == 1, 'driver is not PID 1 of the private PID namespace')
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
    # A real write attempt into the tested package must hit the read-only mount.
    try:
        os.open(module / '.rot-js-consumer-write-probe', os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        raise RuntimeError('installed package accepted a write')
    except OSError as error:
        require(error.errno == errno.EROFS, 'store write failed without EROFS: ' + str(error))
        write_probe = errno.errorcode[error.errno]
    result = {'uid': os.getuid(), 'gid': os.getgid(), 'pid': os.getpid(),
              'namespaces': namespaces, 'interfaces': interfaces, 'store_mounts': mounts,
              'store_write_probe': write_probe,
              'uid_map': Path('/proc/self/uid_map').read_text(),
              'gid_map': Path('/proc/self/gid_map').read_text()}
    save(evidence / 'isolation.json', result)
    return result


def inspect_installed(module):
    """The installed public package exposes its upstream entries and generated builds."""
    require(module.is_dir() and not module.is_symlink(), 'missing installed rot-js module')
    metadata = json.loads((module / 'package.json').read_text())
    require(metadata.get('name') == 'rot-js' and metadata.get('version') == VERSION
            and metadata.get('license') == 'BSD-3-Clause', 'installed package identity changed')
    require(metadata.get('main') == 'dist/rot.js' and metadata.get('module') == 'lib/index.js'
            and metadata.get('types') == './lib/index.d.ts', 'installed entries are not upstream')
    require('exports' not in metadata and 'type' not in metadata, 'installed metadata gained entries')
    require('Redistribution and use in source and binary forms' in (module / 'license.txt').read_text(),
            'installed BSD license absent')
    require(not (module / 'src').exists() and not (module / 'node_modules').exists(),
            'installed package carries checkout sources or a dependency tree')
    readable = (module / 'dist/rot.js').read_text()
    minified = (module / 'dist/rot.min.js').read_text()
    require("typeof exports === 'object' && typeof module !== 'undefined'" in readable,
            'readable bundle is not the Rollup UMD build')
    require(readable.count('\n') > 4 * max(1, minified.count('\n'))
            and len(minified) < len(readable), 'minified bundle is not a compacted build')
    files = sorted(path for path in module.rglob('*') if path.is_file())
    declarations = [path for path in files
                    if path.name.endswith('.d.ts') and (module / 'lib') in path.parents]
    require((module / 'lib/index.d.ts') in declarations, 'installed index.d.ts absent')
    for declaration in declarations:
        require(declaration.with_name(declaration.name[:-5] + '.js').is_file(),
                'declaration without generated module: ' + str(declaration))
    return {'package_json': metadata,
            'builds': {name: {'sha256': sha256(module / name),
                              'bytes': (module / name).stat().st_size,
                              'lines': (module / name).read_text().count('\n')}
                       for name in BUILDS},
            'declarations': {str(path.relative_to(module)): sha256(path) for path in declarations}}


def extract_compiler(archive, destination):
    """Unpack the rot.js lock-pinned TypeScript archive without trusting member paths."""
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
            'compiler archive is not TypeScript ' + COMPILER_VERSION)
    return metadata['version']


def marker(path):
    found = [(number, int(match[1])) for number, line in
             enumerate(path.read_text().splitlines(), 1)
             for match in [re.search(r'// expect TS(\d+)$', line)] if match]
    require(len(found) == 1, 'rejected fixture must have exactly one expectation: ' + path.name)
    return found[0]


def main():
    out, evidence, scratch, templates = map(Path, sys.argv[1:5])
    mount, node, archive = sys.argv[5], Path(sys.argv[6]), Path(sys.argv[7])
    module = out / 'lib/node_modules/rot-js'
    record = {'status': 'failed', 'output': str(out), 'module': str(module),
              'scope': 'installed rot-js consumed offline by a strict TypeScript '
                       + COMPILER_VERSION + ' program and by Node through ESM, readable '
                       'UMD and minified UMD builds',
              'compiler_archive': str(archive), 'node': str(node), 'commands': []}
    try:
        record['isolation'] = isolate(evidence, mount, module)
        for variable in ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME',
                         'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'):
            path = Path(os.environ[variable])
            path.mkdir(mode=0o700)
            require(not list(path.iterdir()), variable + ' is not fresh')
        record['installed'] = inspect_installed(module)
        save(evidence / 'installed.json', record['installed'])
        compiler = scratch / 'compiler'
        record['compiler_version'] = extract_compiler(archive, compiler)
        record['compiler_archive_sha256'] = sha256(archive)
        tsc = compiler / 'bin/tsc'

        # External consumer project: fixtures plus one link to the installed package.
        work = scratch / 'consumer'
        work.mkdir(mode=0o700)
        for name in ('accepted.ts', 'runtime.cjs'):
            shutil.copyfile(templates / name, work / name)
        shutil.copytree(templates / 'rejected', work / 'rejected')
        (work / 'node_modules').mkdir()
        (work / 'node_modules/rot-js').symlink_to(module)
        require(sorted(path.name for path in (work / 'rejected').iterdir())
                == sorted(REJECTED), 'rejected fixture set differs from expectations')
        shutil.copytree(work, evidence / 'consumer-source', symlinks=True)

        env = {name: os.environ[name] for name in
               ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME',
                'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'LC_ALL')}
        env['PATH'] = str(node / 'bin')
        record['consumer_environment'] = dict(env)
        options = {'strict': True, 'noImplicitReturns': True, 'noUnusedLocals': True,
                   'noUnusedParameters': True, 'target': 'es2020', 'lib': ['es2020', 'dom'],
                   'module': 'commonjs', 'moduleResolution': 'node',
                   'forceConsistentCasingInFileNames': True, 'types': [],
                   'pretty': False, 'listFiles': True}

        def run(label, command, timeout=300):
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
            return result.returncode, result.stdout.decode()

        def tsc_run(label, arguments):
            return run(label, [str(node / 'bin/node'), str(tsc)] + arguments)

        def project(name, root, emit, trace=False):
            config = work / ('tsconfig.' + name + '.json')
            compiler_options = dict(options, traceResolution=trace)
            if emit:
                compiler_options.update(outDir='build', rootDir='.')
            else:
                compiler_options['noEmit'] = True
            save(config, {'compilerOptions': compiler_options, 'files': [root]})
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

        code, text = tsc_run('tsc-version', ['--version'])
        require(code == 0 and text == 'Version ' + COMPILER_VERSION + '\n', 'unexpected compiler version')

        code, text = tsc_run('accepted-compile', project('accepted', 'accepted.ts', emit=True, trace=True))
        lines = text.splitlines()
        diagnostics = [line for line in lines if DIAGNOSTIC.match(line)]
        require(code == 0 and not diagnostics, 'accepted consumer did not type-check cleanly')
        resolutions = {match[1] for line in lines for match in [RESOLVED.match(line)] if match}
        require(resolutions == {str(module / 'lib/index.d.ts')},
                'rot-js did not resolve to the installed types entry')
        loaded = program_files(lines)
        require(module / 'lib/index.d.ts' in loaded, 'installed index.d.ts was not loaded')
        require(sorted(path.name for path in (work / 'build').iterdir()) == ['accepted.js'],
                'typed consumer emitted unexpected files')
        shutil.copyfile(work / 'build/accepted.js', evidence / 'accepted.emitted.js')
        record['accepted'] = {'resolved_types': sorted(resolutions),
                              'package_declarations_loaded': sorted(
                                  str(path) for path in loaded if module in path.parents)}

        # Execute the compiled consumer; 'rot-js' resolves through package.json main.
        code, text = run('accepted-run', [str(node / 'bin/node'), 'build/accepted.js'])
        require(code == 0 and text == ACCEPTED_STDOUT, 'compiled typed consumer transcript differs')
        record['accepted']['stdout'] = text

        record['rejected'] = {}
        for name, expected in sorted(REJECTED.items()):
            line_number, declared = marker(work / 'rejected' / name)
            require(declared == expected, name + ' marker disagrees with expected diagnostic')
            label = 'rejected-' + name[:-3]
            code, text = tsc_run(label, project(label, 'rejected/' + name, emit=False))
            lines = text.splitlines()
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

        semantics = evidence / 'runtime-semantics.json'
        code, text = run('runtime', [str(node / 'bin/node'),
                                     '--disable-warning=MODULE_TYPELESS_PACKAGE_JSON',
                                     'runtime.cjs', str(module), str(semantics)], timeout=900)
        require(code == 0 and text == RUNTIME_STDOUT, 'runtime consumer transcript differs')
        reports = json.loads(semantics.read_text())
        require([report['bundle'] for report in reports] == list(BUILDS),
                'runtime did not exercise every installed build')
        for report in reports:
            require(report['sha256'] == record['installed']['builds'][report['bundle']]['sha256'],
                    'runtime loaded different bytes than inspected: ' + report['bundle'])
        dungeon = reports[0]['semantics']['dungeon']
        record['runtime'] = {'builds': [report['bundle'] for report in reports],
                             'floors': dungeon['floors'], 'connected': dungeon['connected'],
                             'rooms': len(dungeon['rooms']), 'corridors': dungeon['corridors'],
                             'maximum_distance': dungeon['maximumDistance'],
                             'route_digests': dungeon['routes'], 'map': dungeon['rows']}
        record['status'] = 'passed'
        print('ROT_JS_CONSUMER_OK')
    except Exception as error:
        record['error'] = str(error)
        traceback.print_exc()
        raise
    finally:
        save(evidence / 'evidence.json', record)


if __name__ == '__main__':
    main()
