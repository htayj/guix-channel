#!/usr/bin/env python3
"""External acceptance for canonical ludviglundgren/qbittorrent-cli v2.3.0.

Only the shell consumer may launch this driver: it resolves proof dependencies
before creating same-UID user/mount/network/PID namespaces. HTTP here is solely
an independent observer of the real packaged daemon, never a mocked server.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import traceback
import urllib.error
import urllib.request

COMMIT = '7b5f87de149d699c0bd955867fe5d57418b6ec68'
PORT = 18080
BASE = f'http://127.0.0.1:{PORT}'


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def interfaces():
    return sorted(line.split(':', 1)[0].strip()
                  for line in Path('/proc/net/dev').read_text().splitlines()[2:])


def run(argv, env=None):
    return subprocess.run(argv, check=True, env=env, timeout=10,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def isolate(output, original_evidence):
    namespaces = {}
    for kind in ('net', 'mnt', 'pid', 'user'):
        current = os.readlink(f'/proc/self/ns/{kind}')
        host = os.environ.get(f'QBT_PROOF_HOST_{kind.upper()}NS')
        require(host and current != host, f'a fresh {kind} namespace is required')
        namespaces[kind] = {'host': host, 'proof': current}
    require(str(os.getuid()) == os.environ.get('QBT_PROOF_HOST_UID'),
            'namespace must preserve the caller UID, not map to root')
    require(interfaces() == ['lo'], 'network namespace has non-loopback interfaces')
    require(not Path(__file__).resolve().is_relative_to('/tmp') and
            not Path(sys.executable).resolve().is_relative_to('/tmp'),
            'checkout and Python must be outside host /tmp')
    daemon = Path(shutil.which('qbittorrent-nox')).resolve()
    require(str(daemon).startswith('/gnu/store/'), 'daemon must be Guix packaged')
    run(['mount', '--make-rprivate', '/'])
    run(['mount', '--bind', '/gnu/store', '/gnu/store'])
    run(['mount', '-o', 'remount,bind,ro', '/gnu/store'])
    mounts = [line.split() for line in Path('/proc/self/mountinfo').read_text().splitlines()]
    store = [fields for fields in mounts if fields[4] == '/gnu/store']
    require(store and 'ro' in store[-1][5].split(','), '/gnu/store is not read-only')
    fd = os.open(original_evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        run(['mount', '-t', 'tmpfs', '-o', 'mode=1777,nosuid,nodev', 'tmpfs', '/tmp'])
        evidence = Path('/tmp/qbt-native-evidence')
        evidence.mkdir(mode=0o700)
        subprocess.run(['mount', '--no-canonicalize', '--bind',
                        f'/proc/self/fd/{fd}', str(evidence)], pass_fds=(fd,),
                       check=True, timeout=10)
    finally:
        os.close(fd)
    # Hide user profiles and host runtime sockets after retaining only evidence.
    for directory in ('/home', '/root', '/run', '/var/tmp'):
        if Path(directory).is_dir():
            run(['mount', '-t', 'tmpfs', '-o', 'mode=700,nosuid,nodev', 'tmpfs', directory])
    os.chdir('/tmp')
    env = {'PATH': os.environ['PATH'], 'LC_ALL': 'C.UTF-8', 'LANG': 'C.UTF-8'}
    for key, leaf in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                      ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                      ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'),
                      ('TMPDIR', 'tmp')):
        path = evidence / leaf
        path.mkdir(mode=0o700)
        env[key] = str(path)
    run(['ip', 'link', 'set', 'lo', 'up'], env)
    (evidence / 'namespace-mountinfo.txt').write_text(Path('/proc/self/mountinfo').read_text())
    (evidence / 'namespace-network.txt').write_text(Path('/proc/net/dev').read_text())
    (evidence / 'namespace-addresses.json').write_bytes(run(['ip', '-json', 'address'], env).stdout)
    return evidence, env, daemon, namespaces


class Consumer:
    def __init__(self, output, evidence, env):
        self.binary = str(output / 'bin/qbt')
        self.alias = str(output / 'bin/qbittorrent-cli')
        self.evidence = evidence
        self.env = env
        self.commands = []
        self.config = evidence / 'scratch-qbt.toml'
        # Explicitly disable proxy discovery; this observer can only reach lo.
        self.http = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def cli(self, name, args, configured=True, alias=False):
        command = [self.alias if alias else self.binary]
        if configured:
            command += ['--config', str(self.config)]
        command += args
        result = subprocess.run(command, env=self.env, cwd='/tmp', timeout=20,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        (self.evidence / f'{name}.stdout').write_bytes(result.stdout)
        (self.evidence / f'{name}.stderr').write_bytes(result.stderr)
        entry = {'name': name, 'argv': command, 'exit_code': result.returncode,
                 'stdout': f'{name}.stdout', 'stderr': f'{name}.stderr'}
        self.commands.append(entry)
        (self.evidence / 'cli-transcripts.json').write_text(json.dumps(self.commands, indent=2) + '\n')
        require(result.returncode == 0,
                f'{name}: native CLI exit {result.returncode}; see {name}.stderr')
        return result

    def api(self, endpoint, data=None):
        request = urllib.request.Request(BASE + '/api/v2/' + endpoint, data=data,
                                         headers={'Referer': BASE + '/'})
        with self.http.open(request, timeout=2) as response:
            return response.read()

    def json_api(self, name, endpoint):
        value = json.loads(self.api(endpoint))
        (self.evidence / f'{name}.json').write_text(json.dumps(value, indent=2) + '\n')
        return value

    def wait_torrents(self, daemon, expected):
        deadline = time.monotonic() + 20
        while True:
            require(daemon.poll() is None, 'native daemon exited during transaction')
            torrents = json.loads(self.api('torrents/info'))
            if len(torrents) == expected:
                return torrents
            require(time.monotonic() < deadline, f'daemon did not reach {expected} torrents')
            time.sleep(0.1)


def bencode(value):
    # Canonical BEP 3 encoding; only the generated local fixture uses this.
    if isinstance(value, int):
        return b'i' + str(value).encode() + b'e'
    if isinstance(value, bytes):
        return str(len(value)).encode() + b':' + value
    if isinstance(value, dict):
        return b'd' + b''.join(bencode(key) + bencode(value[key])
                               for key in sorted(value)) + b'e'
    raise TypeError(type(value))


def daemon_config(profile, payload_dir):
    directory = profile / 'qBittorrent/config'
    directory.mkdir(parents=True, mode=0o700)
    config = directory / 'qBittorrent.conf'
    # Keys from qBittorrent release-5.1.4 preferences.cpp/sessionimpl.cpp;
    # CustomProfile maps --profile=P to P/qBittorrent/config/qBittorrent.conf.
    config.write_text(f'''[Preferences]
WebUI\\Address=127.0.0.1
WebUI\\Port={PORT}
WebUI\\LocalHostAuth=false
WebUI\\AuthSubnetWhitelistEnabled=false
WebUI\\UseUPnP=false
WebUI\\CSRFProtection=true
WebUI\\HostHeaderValidation=true

[BitTorrent]
Session\\DHTEnabled=false
Session\\LSDEnabled=false
Session\\PeXEnabled=false
Session\\Interface=lo
Session\\InterfaceName=lo
Session\\InterfaceAddress=127.0.0.1
Session\\Port=16881
Session\\AddTrackersEnabled=false
Session\\AddTrackersFromURLEnabled=false
Session\\DisableAutoTMMByDefault=true
Session\\DefaultSavePath={payload_dir}/

[Network]
PortForwardingEnabled=false
''')
    return config


def installed_compliance(output):
    doc = output / 'share/doc/ludviglundgren-qbittorrent-cli'
    for name in ('LICENSE', 'README.md', 'go.mod', 'go.sum'):
        path = doc / name
        require(path.is_file() and path.stat().st_size > 0, f'missing installed {path}')
    licenses = doc / 'licenses'
    modules = sorted(path for path in licenses.glob('go-qbt-*') if path.is_dir())
    require(len(modules) == 67, f'expected 67 module notice groups, found {len(modules)}')
    notices = {}
    for group in modules + [licenses / 'go-toolchain', licenses / 'go-standard-library']:
        files = sorted(path for path in group.rglob('*') if path.is_file())
        require(files and all(path.stat().st_size > 0 for path in files),
                f'empty or missing installed notice group: {group}')
        notices[group.name] = [str(path.relative_to(doc)) for path in files]
    source_modules = {
        'go-qbt-github-com-anacrolix-torrent': 'github.com/anacrolix/torrent',
        'go-qbt-github-com-anacrolix-generics': 'github.com/anacrolix/generics',
        'go-qbt-github-com-hashicorp-golang-lru-v2': 'github.com/hashicorp/golang-lru/v2',
        'go-qbt-golang-org-x-net': 'golang.org/x/net',
    }
    sources = doc / 'sources'
    require({path.name for path in sources.iterdir()} == set(source_modules),
            'installed MPL corresponding-source groups differ')
    for group, import_path in source_modules.items():
        root = sources / group / import_path
        require((root / 'go.mod').is_file() and (root / 'go.mod').stat().st_size > 0 and
                any(path.is_file() for path in root.rglob('*.go')),
                f'missing MPL corresponding module source: {root}')
    suffix = sources / 'go-qbt-golang-org-x-net/golang.org/x/net/publicsuffix'
    for name in ('public_suffix_list.dat', 'LICENSE-MPL-2.0'):
        path = suffix / name
        require(path.is_file() and path.stat().st_size > 0,
                f'missing MPL publicsuffix corresponding source or license: {path}')
    return {'documentation': str(doc), 'notice_groups': notices,
            'mpl_source_modules': source_modules}


def prove(output, evidence, env, daemon_binary, namespaces):
    consumer = Consumer(output, evidence, env)
    config_paths = [Path(env['HOME']), Path(env['XDG_CONFIG_HOME'])]
    compliance = installed_compliance(output)
    require(all(not list(path.iterdir()) for path in config_paths), 'fresh config is not empty')
    help_result = consumer.cli('help-no-config', ['--help'], configured=False)
    require(b'Manage qBittorrent from command line.' in help_result.stdout and
            b'torrent' in help_result.stdout and b'category' in help_result.stdout,
            'upstream help lacks canonical identity or native commands')
    version = json.loads(consumer.cli('version-no-config', ['version', '--output', 'json'],
                                     configured=False).stdout)
    require(version['version'] == '2.3.0' and version['commit'] == COMMIT,
            f'wrong canonical version metadata: {version}')
    alias_version = json.loads(consumer.cli('alias-version-no-config', ['version', '--output', 'json'],
                                           configured=False, alias=True).stdout)
    require(alias_version == version, 'alias reports different metadata')
    require(all(not list(path.iterdir()) for path in config_paths) and
            not Path('/tmp/.qbt.toml').exists(), 'help/version created configuration')
    payload_dir = evidence / 'payload'
    payload_dir.mkdir(mode=0o700)
    payload = payload_dir / 'offline-proof.bin'
    data = (b'Canonical qbt native offline payload\n' * 2000)
    payload.write_bytes(data)
    piece_length = 16384
    info = {b'length': len(data), b'name': payload.name.encode(),
            b'piece length': piece_length,
            b'pieces': b''.join(hashlib.sha1(data[start:start + piece_length]).digest()
                                for start in range(0, len(data), piece_length)), b'private': 1}
    info_hash = hashlib.sha1(bencode(info)).hexdigest()
    torrent = evidence / 'offline-proof.torrent'
    torrent.write_bytes(bencode({b'info': info}))  # No announce, announce-list or web seeds.
    original_digest = hashlib.sha256(data).hexdigest()
    profile = evidence / 'daemon-profile'
    config = daemon_config(profile, payload_dir)
    consumer.config.write_text(f'[qbittorrent]\naddr = "{BASE}"\nlogin = ""\npassword = ""\n')
    daemon_version = run([str(daemon_binary), '--version'], env).stdout.decode().strip()
    stdout = open(evidence / 'daemon.stdout', 'wb')
    stderr = open(evidence / 'daemon.stderr', 'wb')
    daemon = subprocess.Popen([str(daemon_binary), f'--profile={profile}',
                               '--confirm-legal-notice'], env=env, cwd='/tmp',
                              stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
    ready = False
    try:
        deadline = time.monotonic() + 30
        while not ready:
            require(daemon.poll() is None, 'qBittorrent-nox exited before WebUI readiness')
            try:
                server_version = consumer.api('app/version').decode()
                ready = True
            except urllib.error.URLError as error:
                # Startup can refuse TCP before the listener exists. HTTP errors
                # are real daemon errors, not readiness failures to hide.
                require(not isinstance(error, urllib.error.HTTPError), str(error))
                require(time.monotonic() < deadline, f'WebUI not ready: {error}')
                time.sleep(0.1)
        require(consumer.json_api('daemon-initial-torrents', 'torrents/info') == [],
                'fresh daemon already contains torrents')
        preferences = consumer.json_api('daemon-preferences', 'app/preferences')
        require(preferences['web_ui_address'] == '127.0.0.1' and
                preferences['web_ui_port'] == PORT and
                preferences['bypass_local_auth'] is True,
                'explicit loopback-only WebUI profile was not honored')
        require(all(preferences[key] is False for key in ('dht', 'lsd', 'pex', 'upnp')),
                'daemon discovery or port forwarding is enabled')
        consumer.cli('category-create', ['category', 'add', 'native-proof', '--save-path', str(payload_dir)])
        consumer.cli('tag-create', ['tag', 'add', 'native-offline'])
        # v2.3.0 assigns arbitrary torrent tags on add, not torrent tag add.
        consumer.cli('torrent-add', ['torrent', 'add', str(torrent), '--paused',
                                     '--save-path', str(payload_dir), '--tags', 'native-offline'])
        consumer.wait_torrents(daemon, 1)
        first = json.loads(consumer.cli('torrent-list-added', ['torrent', 'list', '--output', 'json']).stdout)
        require(len(first) == 1 and first[0]['hash'] == info_hash and
                first[0]['name'] == payload.name and first[0]['size'] == len(data),
                'CLI JSON does not identify the locally generated torrent')
        consumer.cli('category-assign', ['torrent', 'category', 'set', 'native-proof', '--hashes', info_hash])
        assigned = json.loads(consumer.cli('torrent-list-assigned', ['torrent', 'list', '--output', 'json']).stdout)
        require(len(assigned) == 1 and assigned[0]['hash'] == info_hash and
                assigned[0]['category'] == 'native-proof' and
                {tag.strip() for tag in assigned[0]['tags'].split(',')} == {'native-offline'},
                'category/tag assignment is missing from native CLI JSON')
        categories = json.loads(consumer.cli('category-list', ['category', 'list', '--output', 'json']).stdout)
        tags = json.loads(consumer.cli('tag-list', ['tag', 'list', '--output', 'json']).stdout)
        require('native-proof' in categories and tags == ['native-offline'],
                'native category/tag inventory differs')
        observed = consumer.json_api('daemon-assigned-torrents', 'torrents/info')
        require(len(observed) == 1 and observed[0]['hash'] == info_hash and
                observed[0]['category'] == 'native-proof' and observed[0]['tags'] == 'native-offline',
                'real daemon did not receive native CLI mutations')
        consumer.cli('torrent-remove-retain-data', ['torrent', 'remove', '--hashes', info_hash])
        consumer.wait_torrents(daemon, 0)
        final = consumer.json_api('daemon-final-torrents', 'torrents/info')
        require(final == [], 'daemon still has torrent after native remove')
        empty = consumer.cli('torrent-list-empty', ['torrent', 'list', '--output', 'json'])
        # Pinned torrent_list.go returns before JSON marshal when empty; do not
        # invent a JSON [] or silently reinterpret malformed/nonempty output.
        require(empty.stdout == b'' and b'No torrents found with filter: all' in empty.stderr,
                'CLI did not report its upstream empty-list state')
        require(payload.is_file() and hashlib.sha256(payload.read_bytes()).hexdigest() == original_digest,
                'remove without --delete-files changed or removed payload')
        require(interfaces() == ['lo'], 'proof introduced a non-loopback interface')
        proof = {'complete': True, 'output': str(output), 'version': version,
                 'help_version_created_no_config': True, 'namespaces': namespaces,
                 'uid': os.getuid(), 'interfaces': interfaces(), 'store_read_only': True,
                 'installed_compliance': compliance,
                 'daemon': {'binary': str(daemon_binary), 'version_output': daemon_version,
                            'app_version': server_version, 'profile': str(profile),
                            'config': str(config), 'webui': BASE, 'initial_torrents': [],
                            'final_torrents': final},
                 'torrent': {'info_hash': info_hash, 'trackerless': True, 'name': payload.name,
                             'bytes': len(data), 'category': 'native-proof', 'tag': 'native-offline',
                             'payload_sha256_before': original_digest,
                             'payload_sha256_after': hashlib.sha256(payload.read_bytes()).hexdigest(),
                             'removed_without_deleting_data': True}, 'commands': consumer.commands}
    finally:
        try:
            if daemon.poll() is None:
                require(ready, 'daemon not ready for isolated API shutdown')
                consumer.api('app/shutdown', data=b'')
                require(daemon.wait(timeout=10) == 0, 'native daemon shutdown failed')
        finally:
            stdout.close()
            stderr.close()
    proof['daemon']['shutdown_exit_code'] = daemon.returncode
    (evidence / 'proof.json').write_text(json.dumps(proof, indent=2) + '\n')
    print('canonical qbt native offline daemon transactions complete')


def main(argv):
    require(len(argv) == 2, 'use the .sh consumer with OUTPUT EVIDENCE')
    output, evidence = [Path(argument).resolve() for argument in argv]
    evidence, env, daemon, namespaces = isolate(output, evidence)
    prove(output, evidence, env, daemon, namespaces)


if __name__ == '__main__':
    try:
        main(sys.argv[1:])
    except Exception:
        traceback.print_exc()
        sys.exit(1)
