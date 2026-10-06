#!/usr/bin/env python3
"""Compile and execute a genuine external consumer of the installed crate."""
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

COMMIT = 'd7fe96deb196fed0a222d0d3b796145f78420f39'


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


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


def main():
    out, evidence, scratch, templates = map(Path, sys.argv[1:5])
    mount, rust, cargo, gcc = sys.argv[5:9]
    source = out / 'share/cargo/src/rust-effects-0.1.0'
    config = out / 'share/rust-effects/cargo-config.toml'
    record = {'status': 'failed', 'output': str(out), 'source_commit': COMMIT,
              'scope': 'installed library upstream tests and independent offline Cargo consumer',
              'commands': []}
    try:
        record['isolation'] = isolate(evidence, mount)
        for variable in ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME',
                         'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'CARGO_HOME'):
            path = Path(os.environ[variable])
            path.mkdir(mode=0o700)
            require(not list(path.iterdir()), variable + ' is not fresh')
        work = scratch / 'consumer'
        work.mkdir(mode=0o700)
        for name in ('Cargo.toml', 'Cargo.lock'):
            shutil.copyfile(templates / name, work / name)
        shutil.copytree(templates / 'src', work / 'src')
        require(source.is_dir(), 'missing installed library source')
        for member in ('Cargo.toml', 'Cargo.lock', 'src/lib.rs'):
            require((source / member).is_file(), 'missing installed source ' + member)
        archive = out / 'share/cargo/registry/rust-effects-0.1.0.crate'
        require(archive.is_file(), 'missing installed crate archive')
        require('Permission is hereby granted' in (out / 'share/doc/rust-effects/LICENSE').read_text(),
                'installed MIT license absent')
        config_data = config.read_text()
        require(str(out / 'share/rust-effects/vendor') in config_data and 'offline = true' in config_data,
                'installed Cargo config does not select its offline vendor')
        patch = work / 'installed-source.toml'
        patch.write_text('[patch.crates-io]\nrust-effects = { path = ' + json.dumps(str(source)) + ' }\n')
        shutil.copytree(work, evidence / 'consumer-source')
        shutil.copyfile(config, evidence / 'installed-cargo-config.toml')
        shutil.copyfile(source / 'Cargo.toml', evidence / 'installed-Cargo.toml')
        shutil.copyfile(source / 'Cargo.lock', evidence / 'installed-Cargo.lock')
        env = {name: os.environ[name] for name in
               ('HOME', 'TMPDIR', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME',
                'XDG_STATE_HOME', 'XDG_RUNTIME_DIR', 'LC_ALL', 'CARGO_HOME')}
        env.update(PATH=gcc + '/bin:' + rust + '/bin:' + cargo + '/bin',
                   RUSTC=rust + '/bin/rustc', RUSTDOC=rust + '/bin/rustdoc',
                   CARGO_NET_OFFLINE='true', CARGO_BUILD_JOBS='1',
                   CARGO_TARGET_DIR=str(scratch / 'consumer-target'))
        record['consumer_environment'] = dict(env)
        cargo_bin = cargo + '/bin/cargo'

        def run(label, command, environment=None, timeout=300):
            entry = {'label': label, 'command': command}
            record['commands'].append(entry)
            try:
                result = subprocess.run(command, cwd=work, env=environment or env,
                                        stdin=subprocess.DEVNULL, capture_output=True, timeout=timeout)
            except subprocess.TimeoutExpired as error:
                (evidence / (label + '.stdout')).write_bytes(error.stdout or b'')
                (evidence / (label + '.stderr')).write_bytes(error.stderr or b'')
                entry['timeout'] = True
                raise
            (evidence / (label + '.stdout')).write_bytes(result.stdout)
            (evidence / (label + '.stderr')).write_bytes(result.stderr)
            entry['returncode'] = result.returncode
            require(result.returncode == 0, label + ' exited nonzero; inspect captured logs')
            return result

        for label, binary in [('rustc-version', env['RUSTC']), ('cargo-version', cargo_bin),
                              ('rustdoc-version', env['RUSTDOC'])]:
            run(label, [binary, '--version'])
        upstream_env = dict(env, CARGO_TARGET_DIR=str(scratch / 'upstream-target'))
        upstream = run('upstream-tests', [cargo_bin, '--config', str(config), 'test', '--offline',
                       '--locked', '--jobs', '1', '--manifest-path', str(source / 'Cargo.toml'),
                       '--', '--test-threads=1'], upstream_env)
        upstream_output = (upstream.stdout + upstream.stderr).decode(errors='replace')
        totals = re.findall(r'test result: ok\. (\d+) passed; (\d+) failed;', upstream_output)
        require('Doc-tests rust_effects' in upstream_output and len(totals) >= 2,
                'upstream unit/doc-test evidence absent')
        require(all(int(failed) == 0 for _, failed in totals)
                and sum(int(passed) for passed, _ in totals) > 0,
                'upstream tests did not exercise real tests')
        record['upstream_test_results'] = [{'passed': int(passed), 'failed': int(failed)}
                                           for passed, failed in totals]
        base = [cargo_bin, '--config', str(config), '--config', str(patch)]
        metadata = run('consumer-metadata', base + ['metadata', '--offline', '--locked',
                                                   '--format-version', '1'])
        graph = json.loads(metadata.stdout)
        libraries = [package for package in graph['packages'] if package['name'] == 'rust-effects']
        require(len(libraries) == 1 and libraries[0]['source'] is None
                and Path(libraries[0]['manifest_path']).resolve() == source / 'Cargo.toml',
                'consumer did not resolve installed rust-effects path source')
        require(str(work / 'Cargo.toml') != libraries[0]['manifest_path'], 'consumer not external')
        record['installed_dependency_manifest'] = libraries[0]['manifest_path']
        lock_before = hashlib.sha256((work / 'Cargo.lock').read_bytes()).hexdigest()
        run('consumer-build', base + ['build', '--offline', '--locked', '--jobs', '1'])
        require(hashlib.sha256((work / 'Cargo.lock').read_bytes()).hexdigest() == lock_before,
                'consumer lock graph changed')
        executable = scratch / 'consumer-target/debug/rust-effects-consumer'
        require(executable.is_file(), 'Cargo did not compile external consumer')
        result = run('consumer-runtime', [str(executable)], timeout=20)
        lines = result.stdout.decode().splitlines()
        require(lines[-1:] == ['RUST_EFFECTS_NATIVE_RUNTIME_OK'], 'missing consumer completion marker')
        observations = [json.loads(line) for line in lines[:-1]]
        expected = [
            {'case': 'custom-effect-dispatch', 'result': [6, 5], 'trace': [
                'dispatch:add:1:2', 'dispatch:multiply:3:4', 'dispatch:add:8:2',
                'bind:3', 'bind:12', 'bind:10', 'map:12', 'map:10']},
            {'case': 'short-circuit', 'result': None, 'trace': ['reject:9']},
            {'case': 'map-only', 'result': [4, 6]},
            {'case': 'cfuture-completion', 'result': 26, 'shared_result': 26, 'trace': [
                'async:fold', 'async:start:7', 'async:complete', 'async:bind:8', 'async:map:24']},
        ]
        require(observations == expected, 'runtime result/effect trace did not match contract')
        record.update(observations=observations, consumer_lock_sha256=lock_before,
                      executable_sha256=hashlib.sha256(executable.read_bytes()).hexdigest(),
                      installed_crate_sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),
                      status='passed')
        save(evidence / 'observations.json', observations)
        print('RUST_EFFECTS_NATIVE_RUNTIME_OK')
    except Exception as error:
        record['error'] = str(error)
        traceback.print_exc()
        raise
    finally:
        save(evidence / 'evidence.json', record)


if __name__ == '__main__':
    main()
