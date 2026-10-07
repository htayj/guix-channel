#!/usr/bin/env python3
"""Drive the installed PBUI Dired extension through ordinary Emacs terminal keys.

No Lisp test entry point, advice, presentation construction, application-state
injection, or replacement UI is used. pyte decodes real PTY output only.
"""
import codecs
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import select
import socket
import struct
import subprocess
import sys
import termios
import time
import traceback

import pyte

ROWS, COLS = 36, 140
FIXTURES = {'alpha.txt': b'PBUI alpha: native Dired file action\n',
            'beta.txt': b'PBUI beta: second selected file\n'}
EDIT = b'Edited and saved through native Emacs.\n'


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def run(*args):
    subprocess.run(args, check=True, capture_output=True, timeout=20)


def store_mounts(text):
    mounts = []
    for line in text.splitlines():
        fields = line.split()
        target = re.sub(r'\\([0-7]{3})', lambda m: chr(int(m[1], 8)), fields[4])
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            mounts.append((target, fields[5].split(',')))
    return mounts


def identity(pid):
    result = {}
    for line in Path(f'/proc/{pid}/status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            result[key] = [int(part) for part in value.split()]
    for key, variable in (('Uid', 'HOST_UID'), ('Gid', 'HOST_GID')):
        require(result.get(key) == [int(os.environ[variable])] * 4,
                'native consumer changed caller ' + key)
    return result


def isolate(root, evidence, mount):
    before = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-before.txt').write_text(before)
    run(mount, '--rbind', '/gnu/store', '/gnu/store')
    run(mount, '--make-rprivate', '/gnu/store')
    for target in sorted({p for p, _ in store_mounts(Path('/proc/self/mountinfo').read_text())},
                         key=len, reverse=True):
        run(mount, '-o', 'remount,bind,ro', target)
    after = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-after.txt').write_text(after)
    mounts = store_mounts(after)
    require(mounts and all('ro' in opts for _, opts in mounts), 'store is not read-only')
    # Hide host /tmp agent/X sockets; retain only task-owned writable paths.
    fds = [os.open(p, os.O_RDONLY | os.O_DIRECTORY) for p in (root, evidence)]
    try:
        run(mount, '-t', 'tmpfs', '-o', 'mode=1777,nosuid,nodev', 'tmpfs', '/tmp')
        root, evidence = Path('/tmp/pbui-root'), Path('/tmp/pbui-evidence')
        for fd, path in zip(fds, (root, evidence)):
            path.mkdir()
            run(mount, '--bind', f'/proc/{os.getpid()}/fd/{fd}', str(path))
    finally:
        for fd in fds:
            os.close(fd)
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name in namespaces:
        require(namespaces[name] != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not private')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'network namespace exposes external interfaces')
    isolation = {'identity': identity('self'), 'namespaces': namespaces,
                 'interfaces': interfaces, 'store_mounts': mounts,
                 'uid_map': Path('/proc/self/uid_map').read_text(),
                 'gid_map': Path('/proc/self/gid_map').read_text()}
    save(evidence / 'isolation.json', isolation)
    return root, evidence, isolation


class Session:
    def __init__(self, args, env, work, evidence):
        self.raw = bytearray()
        self.events = []
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('replace')
        self.evidence = evidence
        self.alive = True
        self.status = None
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(work)
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(args[0], args, env)
            except BaseException:
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def exited(self):
        if not self.alive:
            return True
        pid, status = os.waitpid(self.pid, os.WNOHANG)
        if pid:
            self.alive = False
            self.status = os.waitstatus_to_exitcode(status)
            return True
        return False

    def read(self, timeout=0.1):
        if not select.select([self.fd], [], [], timeout)[0]:
            return False
        try:
            data = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        if not data:
            return False
        self.raw.extend(data)
        require(len(self.raw) < 4000000, 'unbounded native Emacs output')
        self.stream.feed(self.decoder.decode(data))
        return True

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(0.2):
            require(time.monotonic() < deadline, 'Emacs terminal never became idle')

    def wait(self, predicate, description, timeout=15):
        deadline = time.monotonic() + timeout
        while not predicate():
            self.read()
            require(not self.exited(), description + ': Emacs exited\n' + self.text())
            require(time.monotonic() < deadline, description + ': timed out\n' + self.text())
        self.settle()

    def send(self, data, description):
        require(not self.exited(), 'Emacs exited before ' + description)
        self.events.append({'command': description, 'input_hex': data.hex(),
                            'raw_offset_before': len(self.raw)})
        os.write(self.fd, data)
        self.read(0.2)
        self.settle()

    def command(self, name):
        self.send(b'\x1bx' + name.encode() + b'\r', 'M-x ' + name)

    def capture(self, name):
        self.settle()
        (self.evidence / (name + '.raw')).write_bytes(self.raw)
        (self.evidence / (name + '.txt')).write_text(self.text())
        save(self.evidence / (name + '-frame.json'),
             {'rows': ROWS, 'columns': COLS, 'cursor': [self.screen.cursor.x, self.screen.cursor.y],
              'raw_bytes': len(self.raw), 'display': self.screen.display})

    def dired(self, directory):
        self.send(b'\x18d\x01\x0b' + str(directory).encode() + b'/\r',
                  'C-x d, C-a C-k, type ' + str(directory) + '/, RET')
        self.wait(lambda: str(directory) + ':' in self.text(), 'Dired header ' + str(directory))

    def search(self, name):
        # Isearch is normal buffer navigation; back up into the filename so SPC
        # operates on the presentation attached by installed pbui-dired itself.
        self.send(b'\x1b<\x13' + name.encode() + b'\r\x02',
                  'M-<, C-s ' + name + ', RET, C-b')
        row = self.screen.display[self.screen.cursor.y]
        require(name in row, 'cursor not on Dired filename ' + name + '\n' + self.text())

    def select(self, name):
        self.search(name)
        self.send(b' ', 'PBUI SPC select ' + name)
        self.wait(lambda: 'Selected: /tmp/pbui-root/work/' + name in self.text(),
                  'PBUI selected actual Dired presentation ' + name)

    def choose(self, prefix, title):
        self.send(b'x', 'PBUI x (matching presentation commands)')
        self.wait(lambda: 'Command:' in self.text(), 'PBUI command minibuffer')
        # TAB uses the minibuffer's ordinary completion over the commands
        # PBUI computed as matching the selected presentation types.
        self.send(prefix.encode() + b'\t', 'type ' + prefix + ', TAB (complete PBUI command)')
        self.wait(lambda: 'Command: ' + title in self.text(), 'unique completion ' + title)
        self.capture('command-' + prefix.lower())
        self.send(b'\r', 'RET choose ' + title)

    def assert_buffer(self, content):
        expected = content.decode().splitlines()
        rows = [line.rstrip() for line in self.screen.display]
        starts = [row for row in range(ROWS - len(expected))
                  if rows[row:row + len(expected)] == expected]
        require(len(starts) == 1 and rows[starts[0] + len(expected)] == '',
                'exact native buffer content differs\n' + self.text())

    def finish(self):
        self.send(b'\x18\x03', 'C-x C-c (normal Emacs exit)')
        deadline = time.monotonic() + 10
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'normal Emacs exit timed out')
        require(self.status == 0, 'native Emacs exit status ' + str(self.status))

    def close(self):
        (self.evidence / 'session.raw').write_bytes(self.raw)
        save(self.evidence / 'input-events.json', self.events)
        # Namespace/timeout supervision owns failed-session teardown. No host
        # process lookup or signals, and no user/vault session cleanup.
        os.close(self.fd)


def main():
    output, evidence, root = map(Path, sys.argv[1:4])
    mount, emacs, core = sys.argv[4:7]
    load_args = sys.argv[7:]
    record = {'status': 'failed', 'output': str(output),
              'source_commit': '19a606d95cc63ed388e8b1e3459f68eaf8c4659e',
              'proof': 'native Dired presentations, multi-file copy, open/edit/save/reopen',
              'contacts_network_demo_exercised': False}
    session = None
    try:
        root, evidence, isolation = isolate(root, evidence, mount)
        record['isolation'] = isolation
        for directory in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / directory).mkdir(mode=0o700)
        work = root / 'work'
        (work / 'archive').mkdir()
        for name, content in FIXTURES.items():
            (work / name).write_bytes(content)
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color',
               'LC_ALL': 'C.UTF-8', 'PATH': '', 'TMPDIR': str(root / 'tmp')}
        for variable, directory in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                    ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                    ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / directory)
        # Emacs processes -L action arguments after init.el. EMACSLOADPATH is
        # applied before ordinary startup requires; the trailing empty entry
        # retains Emacs's own built-in library directories.
        require(len(load_args) % 2 == 0 and all(arg == '-L' for arg in load_args[::2]),
                'invalid installed Lisp directory arguments')
        env['EMACSLOADPATH'] = os.pathsep.join(load_args[1::2]) + os.pathsep
        record['emacs_load_path'] = env['EMACSLOADPATH']
        # Ordinary user configuration only: load installed PBUI/Dired and use
        # the declared absolute ls from the proof dependency. No test Lisp.
        emacs_home = root / 'home' / '.emacs.d'
        emacs_home.mkdir()
        (emacs_home / 'early-init.el').write_text('(setq package-enable-at-startup nil)\n')
        (emacs_home / 'init.el').write_text(
            '(setq inhibit-default-init t xterm-extra-capabilities nil)\n'
            '(setq make-backup-files nil)\n'
            '(setq insert-directory-program ' + json.dumps(core + '/bin/ls') + ')\n'
            "(require 'pbui-dired)\n")
        args = [emacs, '-nw', '--no-site-file', '--no-site-lisp', '--no-splash',
                '--no-x-resources', str(work) + '/']
        record['emacs_argv'] = args
        session = Session(args, env, work, evidence)
        session.wait(lambda: all(name in session.text() for name in (*FIXTURES, 'archive'))
                     and 'Dired' in session.text(), 'real Dired fixture listing')
        record['native_identity'] = identity(session.pid)
        session.capture('01-dired')
        session.command('pbui-modal-mode')
        session.wait(lambda: 'PBUI' in session.text(), 'PBUI mode lighter')
        session.select('alpha.txt')
        session.select('beta.txt')
        session.select('archive')
        session.send(b'v', 'PBUI v (visualize selected presentations)')
        session.wait(lambda: all('/tmp/pbui-root/work/' + name + ' [' + kind + ']' in session.text()
                                 for name, kind in (('alpha.txt', 'file'), ('beta.txt', 'file'),
                                                    ('archive', 'directory'))),
                     'native selected objects and exact types')
        session.capture('02-three-selected-presentations')
        # First visualization displays without switching. C-x 1 retains Dired.
        session.send(b'\x181', 'C-x 1 (retain Dired window)')
        require('Dired' in session.text(), 'Dired lost while dismissing selection view')
        session.choose('Copy', 'Copy file(s) to directory')
        session.wait(lambda: all((work / 'archive' / name).exists() for name in FIXTURES)
                     and 'Selected presentations reseted' in session.text(),
                     'PBUI multi-file copy persisted and selection reset')
        for name, content in FIXTURES.items():
            require((work / name).read_bytes() == content, 'copy changed original ' + name)
            require((work / 'archive' / name).read_bytes() == content,
                    'PBUI copy bytes differ for ' + name)
        session.dired(work / 'archive')
        session.wait(lambda: all(name in session.text() for name in FIXTURES),
                     'Dired lists both PBUI copies')
        session.capture('03-copy-in-archive-dired')
        session.send(b'\x08e', 'C-h e (view echo-area message log)')
        session.wait(lambda: '2 files copied to ' + str(work / 'archive') in session.text()
                     and 'Selected presentations reseted' in session.text(),
                     'exact upstream copy and reset messages')
        session.capture('04-command-messages')
        session.command('visualize-selected-presentations')
        session.wait(lambda: 'There are not presentations selected' in session.text(),
                     'upstream resets selections after the command')
        session.capture('05-selection-reset')
        session.dired(work)
        session.send(b'\x181', 'C-x 1 (one Dired window)')
        session.command('pbui-modal-mode')
        session.select('alpha.txt')
        session.choose('Open', 'Open file(s)')
        session.wait(lambda: FIXTURES['alpha.txt'].decode().strip() in session.text()
                     and 'alpha.txt' in session.text(), 'PBUI opens selected file')
        session.assert_buffer(FIXTURES['alpha.txt'])
        session.capture('06-opened-file')
        # RET (not C-j) is the ordinary terminal newline key.
        session.send(b'\x1b>' + EDIT.replace(b'\n', b'\r') + b'\x18\x13',
                     'M->, type edit line, RET, C-x C-s')
        expected = FIXTURES['alpha.txt'] + EDIT
        session.wait(lambda: (work / 'alpha.txt').read_bytes() == expected
                     and 'Wrote ' + str(work / 'alpha.txt') in session.text(), 'native edit/save')
        session.send(b'\x1b<', 'M-< (show entire saved file)')
        session.assert_buffer(expected)
        session.capture('07-saved-edit')
        session.command('kill-current-buffer')
        session.send(b'\x18\x06\x01\x0b' + str(work / 'alpha.txt').encode() + b'\r',
                     'C-x C-f, C-a C-k, type saved path, RET (reopen)')
        session.send(b'\x181\x1b<', 'C-x 1, M-< (show entire reopened file)')
        session.wait(lambda: EDIT.decode().strip() in session.text(), 'reopened saved file')
        session.assert_buffer(expected)
        session.capture('08-reopened-edit')
        session.finish()
        tree = sorted(str(path.relative_to(work)) for path in work.rglob('*'))
        require(tree == ['alpha.txt', 'archive', 'archive/alpha.txt', 'archive/beta.txt',
                         'beta.txt'], 'unexpected fixture tree: ' + repr(tree))
        actual = {}
        for relative in ('alpha.txt', 'beta.txt', 'archive/alpha.txt', 'archive/beta.txt'):
            data = (work / relative).read_bytes()
            wanted = expected if relative == 'alpha.txt' else FIXTURES[Path(relative).name]
            require(data == wanted, 'final file differs: ' + relative)
            (evidence / relative.replace('/', '-')).write_bytes(data)
            actual[relative] = {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                                'text': data.decode()}
        record.update(status='passed', native_exit_status=session.status, final_files=actual,
                      selected_types=['file', 'file', 'directory'], selections_reset=True,
                      copied_files=2, reopened_edit_exact=True)
        print('PBUI_NATIVE_DIRED_COPY_EDIT_OK')
    except BaseException as error:
        record.update(error=str(error), traceback=traceback.format_exc())
        raise
    finally:
        if session is not None:
            session.capture('final-observed-frame')
            session.close()
        save(evidence / 'evidence.json', record)


if __name__ == '__main__':
    main()
