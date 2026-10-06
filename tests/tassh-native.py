#!/usr/bin/env python3
"""Real installed tassh/clipboard transfers; explicitly fixture-backed integration.

Pinned oracle: drbeefsupreme/tassh 672569a55e6f2a0ae4274103a99b8b9abac87f4d,
src/{cli,daemon,main,setup,pid_watcher,display}.rs. The normal daemon has no
bind-address option and runs `tailscale ip -4` unconditionally. Only that
address-discovery command is replaced for the private loopback mesh. Setup's
systemctl/loginctl commands are recording fixtures, not a live user service.
A real sleep PID supplies session lifetime, not an authenticated SSH session.
No replacement daemon, protocol, clipboard backend or rendering frontend.
"""
import hashlib
import json
import os
from pathlib import Path
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import time
import traceback
import zlib

COMMIT = '672569a55e6f2a0ae4274103a99b8b9abac87f4d'
BOUNDARIES = {
    'real': ['installed tassh CLI and two daemons', 'Unix-socket notify/status/inject IPC',
             'loopback TCP relay', 'Xvfb/xclip PNG clipboard',
             'headless Sway/wl-copy/wl-paste Wayland PNG clipboard', 'PID exit cleanup'],
    'fixtures': {
        'tailscale': 'only ip -4: returns per-daemon 127/8 bind address; no tailnet',
        'systemctl/loginctl': 'record setup requests and exit zero; no service manager',
        'ssh_pid': 'real coreutils sleep PID, passed to notify; no SSH authentication',
        'images': 'three distinct, generated valid 1x1 RGBA PNG inputs'},
    'not_proven': ['real Tailscale or authenticated SSH integration',
                   'systemd-user activation or linger', 'desktop session integration'],
}


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def png(pixel):
    def chunk(kind, data):
        return (struct.pack('!I', len(data)) + kind + data +
                struct.pack('!I', zlib.crc32(kind + data) & 0xffffffff))
    return (b'\x89PNG\r\n\x1a\n' +
            chunk(b'IHDR', struct.pack('!IIBBBBB', 1, 1, 8, 6, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress(b'\0' + bytes(pixel))) + chunk(b'IEND', b''))


def namespace_proof(pid):
    proc = Path('/proc') / str(pid)
    namespaces = {name: os.readlink(proc / 'ns' / name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, value in namespaces.items():
        require(value != os.environ['HOST_' + name.upper() + '_NS'],
                'inherited host namespace: ' + name)
        require(value == os.readlink('/proc/self/ns/' + name),
                'child escaped namespace: ' + name)
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            identity[key] = [int(part) for part in value.split()]
    for name, key in (('uid', 'Uid'), ('gid', 'Gid')):
        expected = int(os.environ['HOST_' + name.upper()])
        require(identity[key] == [expected] * 4, 'caller ' + name + ' changed')
        require([int(part) for part in (proc / (name + '_map')).read_text().split()]
                == [expected, expected, 1], 'incorrect ' + name + ' mapping')
    return {'namespaces': namespaces, 'identity': identity}


def isolate(out, evidence):
    require(os.getpid() == 1, 'driver must be PID 1 in private proc')
    identity = namespace_proof(1)
    commands = []

    def mount(*args):
        result = subprocess.run([os.environ['MOUNT'], *args], capture_output=True,
                                text=True, timeout=15, check=False)
        commands.append({'args': args, 'status': result.returncode,
                         'stdout': result.stdout, 'stderr': result.stderr})
        save(evidence / 'mount-commands.json', commands)
        require(result.returncode == 0, 'mount failed: ' + result.stderr)

    def store_mounts():
        text = Path('/proc/self/mountinfo').read_text()
        entries = []
        for line in text.splitlines():
            fields = line.split()
            target = fields[4]
            if target == '/gnu/store' or target.startswith('/gnu/store/'):
                entries.append((target, fields[5].split(','), fields[6:fields.index('-')]))
        return text, entries

    (evidence / 'mountinfo-before.txt').write_text(store_mounts()[0])
    mount('--rbind', '/gnu/store', '/gnu/store')
    mount('--make-rprivate', '/gnu/store')
    for target, _, _ in sorted(store_mounts()[1], key=lambda entry: len(entry[0]), reverse=True):
        mount('-o', 'remount,bind,ro', target)
    _, entries = store_mounts()
    require(entries and all('ro' in opts and 'rw' not in opts and
                            not any(v.startswith(('shared:', 'master:')) for v in optional)
                            for _, opts, optional in entries), 'store not private/read-only')
    require(os.statvfs(out).f_flag & os.ST_RDONLY, 'output filesystem writable')
    # Hide host X11, Wayland, D-Bus and service-manager sockets. Evidence has an
    # open directory FD, so even /tmp-based evidence survives this private mount.
    for target in ('/tmp', '/run'):
        mount('-t', 'tmpfs', '-o', 'mode=1777,nosuid,nodev', 'tmpfs', target)
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'external network interface present')
    subprocess.run([os.environ['IP'], 'link', 'set', 'lo', 'up'], check=True, timeout=10)
    routes = subprocess.check_output([os.environ['IP'], 'route', 'show'], text=True, timeout=10)
    require(not routes.strip(), 'non-loopback route present')
    (evidence / 'mountinfo-after.txt').write_text(Path('/proc/self/mountinfo').read_text())
    save(evidence / 'isolation.json', dict(identity, interfaces=interfaces,
         routes=routes, store_mounts=entries, store_read_only=True,
         private_tmp=True, private_run=True))


class Consumer:
    def __init__(self, out, evidence, root):
        self.out, self.evidence, self.root = out, evidence, root
        self.processes = []
        self.commands = []
        self.transfers = []
        self.cleanups = []
        self.stopped = set()
        self.log_number = 0

    def run(self, binary, *args, env, input=None, timeout=10):
        result = subprocess.run([str(binary), *args], input=input, env=env,
                                cwd=self.root, capture_output=True, timeout=timeout,
                                check=False)
        self.log_number += 1
        prefix = 'command-%03d' % self.log_number
        (self.evidence / (prefix + '.stdout')).write_bytes(result.stdout)
        (self.evidence / (prefix + '.stderr')).write_bytes(result.stderr)
        self.commands.append({'argv': [str(binary), *args], 'status': result.returncode,
                              'stdout': prefix + '.stdout', 'stderr': prefix + '.stderr'})
        save(self.evidence / 'commands.json', self.commands)
        return result

    def launch(self, name, argv, env, input=None):
        stdout = (self.evidence / (name + '.stdout')).open('wb')
        stderr = (self.evidence / (name + '.stderr')).open('wb')
        try:
            process = subprocess.Popen([str(arg) for arg in argv], env=env, cwd=self.root,
                                       stdin=subprocess.PIPE if input is not None else subprocess.DEVNULL,
                                       stdout=stdout, stderr=stderr, start_new_session=True)
        finally:
            stdout.close()
            stderr.close()
        self.processes.append((name, process))
        save(self.evidence / (name + '.process.json'),
             dict(namespace_proof(process.pid), pid=process.pid,
                  argv=[str(arg) for arg in argv], environment=env))
        if input is not None:
            process.stdin.write(input)
            process.stdin.close()
        return process

    def stop(self, process):
        # Only our recorded process groups, never global process-name cleanup.
        if process is None or process.pid in self.stopped:
            return
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=8)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=8)
        # Some clipboard commands fork and their parent exits before the owner.
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        self.stopped.add(process.pid)
        self.cleanups.append({'pid': process.pid, 'status': process.returncode})
        save(self.evidence / 'process-cleanup.json', self.cleanups)

    def alive(self, process):
        status = process.poll()
        if status is None:
            return
        name = next(name for name, child in self.processes if child is process)
        stderr = (self.evidence / (name + '.stderr')).read_text(errors='replace')
        save(self.evidence / (name + '.exit.json'), {'pid': process.pid, 'status': status})
        raise AssertionError('%s exited %s: %s' % (name, status, stderr.strip()))

    def wait_for(self, predicate, message, process=None, timeout=15):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if process is not None:
                self.alive(process)
            if predicate():
                return
            time.sleep(.1)
        raise AssertionError(message)

    def status(self, env):
        result = self.run(self.out / 'bin/tassh', 'status', env=env)
        require(result.returncode == 0, 'status failed')
        return result.stdout.decode('utf-8', 'replace')

    def sessions(self, env_a, env_b, connected):
        marker = '-- syncing (1 SSH session)' if connected else 'no active connections'
        def ready():
            a, b = self.status(env_a), self.status(env_b)
            return (a.count(marker) == 1 and b.count(marker) == 1)
        self.wait_for(ready, 'both daemon statuses did not reach ' + marker)

    def transfer(self, name, payload, env, processes=()):
        display_file = Path(env['HOME']) / '.tassh/display'
        self.wait_for(display_file.exists, 'destination display not published')
        display = display_file.read_text().splitlines()[0].split('=', 1)[1]
        (self.evidence / (name + '.display')).write_text(display_file.read_text())
        (self.evidence / (name + '.expected.png')).write_bytes(payload)
        expected_hash = hashlib.sha256(payload).hexdigest()
        received = b''
        result = None
        def arrived():
            nonlocal received, result
            for process in processes:
                self.alive(process)
            result = self.run(os.environ['XCLIP'], '-selection', 'clipboard', '-t',
                              'image/png', '-o', '-display', display,
                              env={**env, 'DISPLAY': display}, timeout=3)
            received = result.stdout
            error = result.stderr.decode('utf-8', 'replace').strip()
            if result.returncode != 0:
                require(result.returncode == 1 and error == 'Error: target image/png not available',
                        'X11 clipboard failed (%s): %s' % (result.returncode, error))
            else:
                require(not error, 'X11 clipboard stderr: ' + error)
            return result.returncode == 0 and received == payload
        try:
            self.wait_for(arrived, name + ' PNG was not relayed byte-for-byte', timeout=12)
        finally:
            (self.evidence / (name + '.received.png')).write_bytes(received)
            self.transfers.append({'scenario': name, 'expected_sha256': expected_hash,
                                   'received_sha256': hashlib.sha256(received).hexdigest(),
                                   'bytes': len(received), 'equal': received == payload,
                                   'read_status': None if result is None else result.returncode})
            save(self.evidence / 'transfers.json', self.transfers)

    def wayland_clipboard(self, env, process, payload=None):
        received = b''
        result = None

        def ready():
            nonlocal received, result
            self.alive(process)
            args = ('--list-types',) if payload is None else ('--no-newline', '--type', 'image/png')
            result = self.run(os.environ['WLPASTE'], *args, env=env, timeout=3)
            received = result.stdout
            error = result.stderr.decode('utf-8', 'replace').strip()
            # Empty selection is the sole expected native error while a source
            # is being initialized. Missing seat/protocol/connection is fatal.
            if result.returncode != 0:
                require(result.returncode == 1 and error == 'Nothing is copied',
                        'Wayland clipboard failed (%s): %s' % (result.returncode, error))
                return payload is None
            require(not error, 'Wayland clipboard stderr: ' + error)
            if payload is None:
                raise AssertionError('Wayland clipboard was not initially empty')
            return received == payload

        try:
            self.wait_for(ready, 'native Wayland source PNG was not published', process)
        finally:
            if payload is not None:
                (self.evidence / 'wayland-source.received.png').write_bytes(received)
                save(self.evidence / 'wayland-source.json', {
                    'expected_sha256': hashlib.sha256(payload).hexdigest(),
                    'received_sha256': hashlib.sha256(received).hexdigest(),
                    'bytes': len(received), 'equal': received == payload,
                    'read_status': None if result is None else result.returncode})

    def environment(self, name, address, fixture):
        home, runtime = self.root / (name + '-home'), self.root / (name + '-runtime')
        home.mkdir(mode=0o700)
        runtime.mkdir(mode=0o700)
        env = {'HOME': str(home), 'XDG_RUNTIME_DIR': str(runtime), 'TMPDIR': '/tmp',
               'PATH': str(fixture), 'TASSH_TEST_IP': address, 'LC_ALL': 'C.UTF-8',
               'RUST_LOG': 'debug'}
        for key, directory in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state')):
            (home / directory).mkdir(mode=0o700)
            env[key] = str(home / directory)
        return env

    def daemon(self, name, env):
        process = self.launch(name, [self.out / 'bin/tassh', 'daemon', '--port', '19987'], env)
        path = Path(env['HOME']) / '.tassh/daemon.sock'
        self.wait_for(path.exists, name + ' socket absent', process)
        self.wait_for(lambda: 'clipboard: no image on clipboard at startup' in
                      (self.evidence / (name + '.stdout')).read_text(errors='replace'),
                      name + ' watcher did not acknowledge empty initial clipboard', process)
        return process

    def exercise(self):
        fixture = self.root / 'address-fixture'
        fixture.mkdir(mode=0o700)
        # An argument-checked discovery fixture, not a Tailscale simulator.
        tailscale = fixture / 'tailscale'
        tailscale.write_text('#!' + os.environ['SH'] + '\n'
                             'test "$#" -eq 2 && test "$1" = ip && test "$2" = -4 || exit 64\n'
                             'printf "%s\\n" "$TASSH_TEST_IP"\n')
        tailscale.chmod(0o700)
        (self.evidence / 'tailscale-fixture.sh').write_text(tailscale.read_text())
        env_a = self.environment('a', '127.0.0.1', fixture)
        env_b = self.environment('b', '127.0.0.2', fixture)
        # All help/version-like executions happen inside the same isolation.
        for args in ((), ('daemon',), ('notify',), ('status',),
                     ('inject',), ('setup',), ('setup', 'daemon')):
            result = self.run(self.out / 'bin/tassh', *args, '--help', env=env_a)
            require(result.returncode == 0, 'help command failed: ' + str(args))
        require('daemon not running' in self.status(env_a), 'unexpected initial daemon')
        license_path = self.out / 'share/doc/tassh/LICENSE'
        require(license_path.is_file() and license_path.stat().st_size, 'missing MIT license')
        notices = list((self.out / 'share/doc/tassh/third-party-licenses').rglob('*'))
        require(sum(path.is_file() for path in notices) >= 181, 'missing crate notices')

        # Keep setup coverage separate: direct transfer PATH never contains these.
        setup_fixture = self.root / 'setup-fixture'
        setup_fixture.mkdir(mode=0o700)
        setup_log = self.root / 'setup-commands.log'
        for command in ('systemctl', 'loginctl'):
            path = setup_fixture / command
            path.write_text('#!' + os.environ['SH'] + '\n'
                            'printf "%s %s\\n" "' + command + '" "$*" >> "$TASSH_SETUP_LOG"\n')
            path.chmod(0o700)
            (self.evidence / (command + '-fixture.sh')).write_text(path.read_text())
        setup_env = self.environment('setup', '127.0.0.3', setup_fixture)
        setup_env['TASSH_SETUP_LOG'] = str(setup_log)
        configured = self.run(self.out / 'bin/tassh', 'setup', 'daemon', '--yes',
                              '--port', '19987', env=setup_env)
        require(configured.returncode == 0, 'fixture-backed setup failed')
        unit = Path(setup_env['HOME']) / '.config/systemd/user/tassh-daemon.service'
        require('ExecStart=' + str(self.out) + '/bin/tassh daemon --port 19987' in unit.read_text(),
                'setup did not use installed wrapper')
        expected_setup = ['systemctl --user daemon-reload',
                          'systemctl --user enable tassh-daemon.service',
                          'systemctl --user start tassh-daemon.service', 'loginctl enable-linger']
        require(setup_log.read_text().splitlines() == expected_setup, 'wrong setup commands')
        (self.evidence / 'setup-unit.service').write_text(unit.read_text())
        (self.evidence / 'setup-commands.log').write_text(setup_log.read_text())
        (self.evidence / 'setup-ssh-config').write_text(
            (Path(setup_env['HOME']) / '.ssh/config').read_text())

        daemon_b = self.daemon('daemon-b', env_b)
        source_xvfb = self.launch('source-xvfb', [os.environ['XVFB'], ':99', '-screen',
                                  '0', '1x1x24', '-nolisten', 'tcp'], env_a)
        self.wait_for(lambda: Path('/tmp/.X11-unix/X99').exists(),
                      'source Xvfb socket absent', source_xvfb)
        x11_env = {**env_a, 'DISPLAY': ':99'}
        daemon_a = self.daemon('daemon-a-x11', x11_env)
        helper = self.launch('session-lifetime-x11', [os.environ['SLEEP'], '300'], env_a)
        notified = self.run(self.out / 'bin/tassh', 'notify', '--host', '127.0.0.2',
                            '--ssh-pid', str(helper.pid), env=env_a)
        require(notified.returncode == 0, 'notify failed')
        # notify's exit zero alone proves nothing: statuses and PNG bytes do.
        self.sessions(env_a, env_b, True)
        x11_png = png((255, 0, 0, 255))
        source_clip = self.launch('source-xclip', [os.environ['XCLIP'], '-quiet', '-selection',
                                 'clipboard', '-t', 'image/png', '-i', '-display', ':99'],
                                  x11_env, input=x11_png)
        self.transfer('x11-watch', x11_png, env_b, (source_clip, source_xvfb, daemon_a, daemon_b))
        self.stop(source_clip)
        inject_png = png((0, 255, 0, 255))
        inject_file = self.root / 'inject.png'
        inject_file.write_bytes(inject_png)
        injected = self.run(self.out / 'bin/tassh', 'inject', '--png-file', str(inject_file), env=env_a)
        require(injected.returncode == 0, 'inject failed')
        self.transfer('inject', inject_png, env_b, (source_xvfb, daemon_a, daemon_b))
        self.stop(helper)
        self.sessions(env_a, env_b, False)
        require(daemon_a.poll() is None and daemon_b.poll() is None, 'daemon died after session exit')
        self.stop(daemon_a)
        self.stop(source_xvfb)
        require(not (Path(env_a['HOME']) / '.tassh/daemon.sock').exists(), 'daemon socket not cleaned')

        # Weston 10's headless backend has no wl_seat. Sway creates seat0
        # without physical devices and supplies data-control (no focus trick).
        # Force CPU/headless rendering, disable Xwayland and use no host config.
        sway_config = self.root / 'sway.conf'
        sway_config.write_text('xwayland disable\nseat seat0 fallback true\n')
        (self.evidence / 'sway.conf').write_text(sway_config.read_text())
        compositor_env = {**env_a, 'WLR_BACKENDS': 'headless',
                          'WLR_RENDERER': 'pixman', 'WLR_HEADLESS_OUTPUTS': '1'}
        sway = self.launch('sway', [os.environ['SWAY'], '--debug', '--config', sway_config],
                           compositor_env)
        runtime = Path(env_a['XDG_RUNTIME_DIR'])
        sockets = []
        def socket_ready():
            nonlocal sockets
            sockets = [path for path in runtime.glob('wayland-*') if path.is_socket()]
            return bool(sockets)
        self.wait_for(socket_ready, 'Sway Wayland socket absent', sway)
        require(len(sockets) == 1, 'ambiguous private Wayland sockets')
        wayland_env = {**env_a, 'WAYLAND_DISPLAY': sockets[0].name}
        self.wayland_clipboard(wayland_env, sway)
        daemon_a = self.daemon('daemon-a-wayland', wayland_env)
        require('clipboard: using Wayland (' in
                (self.evidence / 'daemon-a-wayland.stdout').read_text(errors='replace'),
                'daemon did not select the real Wayland watcher')
        helper = self.launch('session-lifetime-wayland', [os.environ['SLEEP'], '300'], env_a)
        notified = self.run(self.out / 'bin/tassh', 'notify', '--host', '127.0.0.2',
                            '--ssh-pid', str(helper.pid), env=wayland_env)
        require(notified.returncode == 0, 'Wayland notify failed')
        self.sessions(wayland_env, env_b, True)
        wayland_png = png((0, 0, 255, 255))
        wayland_clip = self.launch('source-wl-copy', [os.environ['WLCOPY'], '--foreground', '--type', 'image/png'],
                                   wayland_env, input=wayland_png)
        # Prove publication on the source before checking the relay; native
        # errors must not masquerade as a destination timeout or stale PNG.
        self.wayland_clipboard(wayland_env, wayland_clip, wayland_png)
        self.transfer('wayland-watch', wayland_png, env_b,
                      (wayland_clip, sway, daemon_a, daemon_b))
        self.stop(wayland_clip)
        self.stop(helper)
        self.sessions(wayland_env, env_b, False)
        require(daemon_a.poll() is None and daemon_b.poll() is None, 'daemon died after Wayland session exit')
        self.stop(daemon_a)
        self.stop(daemon_b)
        self.stop(sway)
        require(not (Path(env_a['HOME']) / '.tassh/daemon.sock').exists() and
                not (Path(env_b['HOME']) / '.tassh/daemon.sock').exists(), 'daemon sockets not cleaned')

    def cleanup(self):
        for _, process in reversed(self.processes):
            self.stop(process)
        # PID 1 adopts forked clipboard owners. Reap only private-namespace children.
        deadline = time.monotonic() + 5
        remaining = []
        while time.monotonic() < deadline:
            try:
                while os.waitpid(-1, os.WNOHANG)[0]:
                    pass
            except ChildProcessError:
                pass
            remaining = [int(path.name) for path in Path('/proc').iterdir()
                         if path.name.isdecimal() and path.name != '1']
            if not remaining:
                break
            time.sleep(.1)
        save(self.evidence / 'remaining-processes.json', remaining)
        require(not remaining, 'owned child processes survived cleanup: ' + str(remaining))


def main():
    out = Path(sys.argv[1]).resolve(strict=True)
    original_evidence = Path(sys.argv[2]).resolve(strict=True)
    require(out.parent == Path('/gnu/store'), 'OUTPUT must be a direct store item')
    fd = os.open(original_evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc/self/fd/' + str(fd))
    save(evidence / 'fixture-boundaries.json', BOUNDARIES)
    report = {'status': 'failed', 'output': str(out), 'upstream_commit': COMMIT,
              'fixture_boundaries': BOUNDARIES}
    consumer = None
    try:
        isolate(out, evidence)
        with tempfile.TemporaryDirectory(prefix='tassh-native-', dir='/tmp') as temporary:
            consumer = Consumer(out, evidence, Path(temporary))
            try:
                consumer.exercise()
            finally:
                consumer.cleanup()
        report['status'] = 'passed'
        report['transfers'] = consumer.transfers
        print('TASSH_NATIVE_LOOPBACK_CLIPBOARD_OK x11=true inject=true wayland=true fixture_backed=true')
    except BaseException as error:
        report['error'] = str(error)
        (evidence / 'failure.txt').write_text(traceback.format_exc())
        raise
    finally:
        save(evidence / 'runtime.json', report)
        os.close(fd)


if __name__ == '__main__':
    main()
