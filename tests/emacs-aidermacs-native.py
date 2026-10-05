#!/usr/bin/env python3
"""External native Emacs consumer: terminal keys and pyte observation only.

Ordinary startup configuration loads the installed extension; no test advice,
callbacks or replacement Lisp run in the TTY Emacs. pyte only decodes unchanged
Emacs output. The separate batch preflight retains the original pure transform
and missing-tool checks. No backend, credentials, model responses or fabricated
session state exists, so no Aider or LLM session is claimed.
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
import signal
import socket
import struct
import subprocess
import sys
import termios
import time
import traceback

import pyte

ROWS, COLS = 32, 132
SOURCE = ('class NativeWidget:\n'
          '    def native_total(self, value):\n'
          '        return value + 7\n\n'
          'def consumer():\n'
          '    return NativeWidget().native_total(2)\n')
TEMPLATE = ('# aidermacs Prompt File - Command Reference:\n'
            '# C-c C-n or C-<return>: Send current line or selected region line by line\n'
            '# C-c C-c: Send current block or selected region as a whole\n'
            '# C-c C-z: Switch to aidermacs buffer\n\n'
            '* Sample task:\n\n'
            '/ask what this repo is about?\n')
TASK = '/ask Explain native_total in sample.py without changing it.\n'
MISSING = 'Aider executable not found. Checked: (aider-ce aider)'


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, timeout=20)


def store_mounts(text):
    result = []
    for line in text.splitlines():
        fields = line.split()
        target = re.sub(r'\\([0-7]{3})', lambda m: chr(int(m[1], 8)), fields[4])
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            result.append((target, fields[5].split(',')))
    return result


def identity(pid):
    result = {}
    for line in Path(f'/proc/{pid}/status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            result[key] = [int(part) for part in value.split()]
    require(result.get('Uid') == [int(os.environ['HOST_UID'])] * 4,
            'native Emacs changed the caller UID')
    require(result.get('Gid') == [int(os.environ['HOST_GID'])] * 4,
            'native Emacs changed the caller GID')
    return result


def isolate(root, evidence, mount):
    before = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-before.txt').write_text(before)
    run(mount, '--rbind', '/gnu/store', '/gnu/store')
    run(mount, '--make-rprivate', '/gnu/store')
    for target in sorted({t for t, _ in store_mounts(Path('/proc/self/mountinfo').read_text())},
                         key=len, reverse=True):
        run(mount, '-o', 'remount,bind,ro', target)
    after = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-after.txt').write_text(after)
    mounts = store_mounts(after)
    require(mounts and all('ro' in opts for _, opts in mounts), 'store is not read-only')
    # Hide caller /tmp sockets (including X11/agents) while retaining only the
    # two task-owned writable directories through open directory descriptors.
    fds = [os.open(p, os.O_RDONLY | os.O_DIRECTORY) for p in (root, evidence)]
    try:
        run(mount, '-t', 'tmpfs', '-o', 'mode=1777,nosuid,nodev', 'tmpfs', '/tmp')
        root, evidence = Path('/tmp/aidermacs-root'), Path('/tmp/aidermacs-evidence')
        for fd, path in zip(fds, (root, evidence)):
            path.mkdir()
            run(mount, '--bind', f'/proc/{os.getpid()}/fd/{fd}', str(path))
    finally:
        for fd in fds:
            os.close(fd)
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, variable in (('net', 'HOST_NET_NS'), ('mnt', 'HOST_MNT_NS'), ('pid', 'HOST_PID_NS')):
        require(namespaces[name] != os.environ[variable], name + ' namespace is not private')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'network namespace has external interfaces')
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

    def assert_buffer(self, content):
        # Exact contiguous rows in the actual terminal frame, not buffer text
        # obtained through Lisp. The row below the final newline must be blank.
        expected = content.splitlines()
        rows = [line.rstrip() for line in self.screen.display]
        starts = [row for row in range(ROWS - len(expected))
                  if rows[row:row + len(expected)] == expected]
        require(len(starts) == 1, 'visible Emacs buffer differs\n' + self.text())
        require(rows[starts[0] + len(expected)] == '',
                'unexpected visible buffer content\n' + self.text())

    def assert_minor_mode(self):
        require(re.search(r'\(Org[^)\n]* aidermacs\b[^)\n]*\)', self.text()),
                'aidermacs minor-mode lighter absent from Org mode line\n' + self.text())

    def finish(self):
        self.send(b'\x18\x03', 'C-x C-c (normal Emacs exit)')
        deadline = time.monotonic() + 10
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'normal Emacs exit timed out')
        require(self.status == 0, 'Emacs exit status ' + str(self.status))

    def close(self):
        (self.evidence / 'session.raw').write_bytes(self.raw)
        save(self.evidence / 'input-events.json', self.events)
        if self.alive and not self.exited():
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)


def main():
    output, evidence, root = map(lambda p: Path(p).resolve(), sys.argv[1:4])
    mount, emacs = sys.argv[4:6]
    load_args = sys.argv[6:]
    record = {'status': 'failed', 'output': str(output), 'llm_session': False,
              'aider_session': False, 'model_calls': False,
              'boundary': 'installed extension only; missing external Aider is expected'}
    session = None
    try:
        root, evidence, isolation = isolate(root, evidence, mount)
        record['isolation'] = isolation
        for directory in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
            (root / directory).mkdir(mode=0o700)
        work = root / 'work'
        source = work / 'sample.py'
        source.write_text(SOURCE)
        source_digest = hashlib.sha256(source.read_bytes()).hexdigest()
        env = {'HOME': str(root / 'home'), 'TERM': 'xterm-256color',
               'LC_ALL': 'C.UTF-8', 'PATH': '', 'TMPDIR': str(root / 'tmp')}
        for variable, directory in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                                    ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                                    ('XDG_RUNTIME_DIR', 'runtime')):
            env[variable] = str(root / directory)
        # Original meaningful local-only checks, not commandp/feature wiring.
        preflight = r'''(progn
(require 'aidermacs)
(unless (string= (aidermacs--process-message-if-multi-line "one\ntwo")
                 "{aidermacs\none\ntwo\naidermacs}")
  (error "multi-line message transformation failed"))
(unless (string= (aidermacs--process-message-if-multi-line "single line") "single line")
  (error "single-line message transformation failed"))
(unless (string= (aidermacs--process-message-if-multi-line "{aidermacs\nonly\naidermacs}")
                 "{aidermacs\nonly\naidermacs}")
  (error "wrapped message was wrapped again"))
(setq exec-path nil)
(clrhash aidermacs--resolved-programs)
(condition-case err
    (progn (aidermacs-get-program) (error "missing Aider was accepted"))
  (error (unless (string= (error-message-string err)
                         "Aider executable not found. Checked: (aider-ce aider)")
           (signal (car err) (cdr err))))))'''
        batch = subprocess.run([emacs, '--batch', '-Q', *load_args, '--eval', preflight],
                               env=env, cwd=work, capture_output=True, timeout=30)
        (evidence / 'batch.stdout').write_bytes(batch.stdout)
        (evidence / 'batch.stderr').write_bytes(batch.stderr)
        require(batch.returncode == 0, 'pure local preflight failed; see batch.stderr')
        # Ordinary fresh user config only: no callbacks/test scene/application
        # replacement. Disable terminal capability queries before TTY startup.
        emacs_home = root / 'home' / '.emacs.d'
        emacs_home.mkdir()
        (emacs_home / 'early-init.el').write_text('(setq package-enable-at-startup nil)\n')
        (emacs_home / 'init.el').write_text(
            '(setq inhibit-default-init t xterm-extra-capabilities nil)\n')
        args = [emacs, '-nw', '--no-site-file', '--no-site-lisp', '--no-splash',
                '--no-x-resources', *load_args, '--eval', "(require 'aidermacs)", str(source)]
        record['emacs_argv'] = args
        session = Session(args, env, work, evidence)
        session.wait(lambda: 'sample.py' in session.text() and 'native_total' in session.text(),
                     'source fixture visible in native Emacs')
        record['native_identity'] = identity(session.pid)
        session.assert_buffer(SOURCE)
        session.capture('01-source')
        # The installed transient UI computes live session state for the source
        # buffer; it must truthfully report that no Aider session is running.
        session.command('aidermacs-transient-menu')
        session.wait(lambda: 'Aidermacs: AI Pair Programming' in session.text() and
                     'Start Session (NOT RUNNING)' in session.text() and
                     'Add Current File' in session.text(), 'native transient menu')
        session.capture('02-transient-not-running')
        session.send(b'\x07', 'C-g (quit transient without action)')
        session.wait(lambda: 'Aidermacs: AI Pair Programming' not in session.text(),
                     'transient dismissed')
        session.assert_buffer(SOURCE)
        session.command('aidermacs-setup-minor-mode')
        session.command('aidermacs-open-prompt-file')
        prompt = work / '.aider.prompt.org'
        session.wait(lambda: prompt.exists() and '.aider.prompt.org' in session.text(),
                     'upstream prompt-file creation')
        session.send(b'\x181\x1b<', 'C-x 1, M-< (show entire prompt file)')
        session.assert_buffer(TEMPLATE)
        require(prompt.read_text() == TEMPLATE, 'upstream-created template differs')
        session.assert_minor_mode()
        session.capture('03-created-prompt')
        session.send(b'\x1b>' + TASK.rstrip('\n').encode() + b'\r\x18\x13',
                     'M->, type local source-specific task, RET, C-x C-s')
        expected = TEMPLATE + TASK
        session.wait(lambda: prompt.read_text() == expected, 'prompt task persisted through Emacs save')
        session.send(b'\x1b<', 'M-< (view saved task)')
        session.assert_buffer(expected)
        session.capture('04-saved-prompt')
        # Kill the file buffer and open again through the real package command:
        # this covers its existing-file branch and find-file minor-mode hook.
        session.command('kill-current-buffer')
        session.wait(lambda: '# aidermacs Prompt File' not in session.text() and
                     '.aider.prompt.org' not in session.text(),
                     'prompt buffer killed through ordinary Emacs command')
        session.command('aidermacs-open-prompt-file')
        session.send(b'\x181\x1b<', 'C-x 1, M-< (view reopened prompt)')
        session.assert_buffer(expected)
        require(prompt.read_text() == expected, 'reopening duplicated or changed prompt file')
        session.assert_minor_mode()
        session.capture('05-reopened-prompt')
        # C-c C-n is the upstream key path, not a direct call to an internal
        # send helper. With no Aider installed it must retain the editable file
        # and show the real missing-executable error rather than claim a chat.
        session.send(b'\x1b>\x10\x01\x03\x0e', 'M->, C-p, C-a, C-c C-n (send task line)')
        session.wait(lambda: MISSING in session.text(), 'genuine missing-Aider key-path diagnostic')
        session.assert_buffer(expected)
        session.capture('06-missing-aider')
        require(prompt.read_text() == expected, 'failed send changed persisted prompt')
        require(source.read_text() == SOURCE, 'failed send changed source fixture')
        # Show the genuine Messages buffer so the diagnostic remains durable
        # in terminal evidence beyond the ephemeral echo-area message.
        session.send(b'\x18b*Messages*\r\x1b>', 'C-x b *Messages*, M->')
        session.wait(lambda: MISSING in session.text() and '*Messages*' in session.text(),
                     'native Messages diagnostic')
        session.capture('07-native-messages')
        session.finish()
        (evidence / 'source-fixture.py').write_bytes(source.read_bytes())
        (evidence / 'saved-prompt.org').write_bytes(prompt.read_bytes())
        record.update(status='passed', batch_exit_status=batch.returncode,
                      native_exit_status=session.status, missing_aider_message=MISSING,
                      exact_visible_prompt=expected, source_sha256=source_digest,
                      source_unchanged=hashlib.sha256(source.read_bytes()).hexdigest() == source_digest,
                      commands=['aidermacs-transient-menu', 'C-g', 'aidermacs-setup-minor-mode',
                                'aidermacs-open-prompt-file', 'save-buffer', 'kill-current-buffer',
                                'aidermacs-open-prompt-file',
                                'C-c C-n -> aidermacs-send-line-or-region'],
                      proof='real terminal UI, exact prompt creation/save/reopen, genuine missing-Aider failure')
        print('AIDERMACS_NATIVE_PROMPT_OK (no Aider or LLM session)')
    except BaseException as error:
        record.update(error=str(error), traceback=traceback.format_exc())
        raise
    finally:
        if session is not None:
            session.close()
        save(evidence / 'evidence.json', record)


if __name__ == '__main__':
    main()
