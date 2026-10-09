#!/usr/bin/env python3
"""External offline consumer of the ordinary packaged Browsh and Firefox.

The fixture is original HTML served over private loopback, not an addon/socket
mock.  Only ordinary terminal input is sent; no browser DOM or game state is
injected.  See SOURCE_ANCHORS for the pinned upstream controls.
"""
import codecs
import errno
import fcntl
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import select
import signal
import socket
import struct
import subprocess
import sys
import termios
import threading
import time
from urllib.parse import parse_qs, urlsplit

import pyte

COMMIT = '499ef386d45cd1e2b5457dd04887c017f77b7e27'
ROWS, COLS = 36, 120
DOC_ONE = 'NATIVE DOCUMENT ONE'
DOC_TWO = 'NATIVE DOCUMENT TWO'
RESULT = 'NATIVE FORM RECEIVED'
INPUT = 'OFFLINE_INPUT'
LINK = 'Follow offline link'
SOURCE_ANCHORS = {
    'terminal': 'interfacer/src/browsh/tty.go:32,60-105,118-144,188-210: '
                'tcell mouse; Ctrl-L URL bar; Ctrl-Q Marionette quit; key/mouse forwarding',
    'input': 'interfacer/src/browsh/input_box.go:135-155,197-225: '
             'local text editing; native input box synchronization',
    'focus': 'interfacer/src/browsh/frame_builder.go:316-331: '
             'ordinary mouse coordinates focus input box',
    'input_sync': 'interfacer/src/browsh/input_cursor.go: '
                  'cursorInsertRune/cursorBackspace call sendInputBoxToBrowser per key',
    'transparent_cells': 'interfacer/src/browsh/frame_builder.go: '
                         'buildCell/isCharacterTransparent replace whitespace with U+2584 '
                         'for pixel colour; normalized text maps only that rune to space',
    'url': 'interfacer/src/browsh/ui.go:83-95 and '
           'webext/src/background/tty_commands_mixin.js: '
           'Ctrl-L select-all; URL Enter calls browser.tabs.update',
    'browser_events': 'webext/src/dom/commands_mixin.js: '
                      '_handleMouse/_getDOMCoordsFromMouseCoords/_handleInputBoxContent: '
                      'Browsh native cell-to-DOM click and input synchronization',
    'runtime': 'interfacer/src/browsh/firefox.go:84-114,230-242: '
               'ordinary headless Firefox; embedded extension Marionette install',
}
SOURCE_BASE = 'https://github.com/browsh-org/browsh/blob/' + COMMIT + '/'


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def store_mounts():
    text = Path('/proc/self/mountinfo').read_text()
    mounts = []
    for line in text.splitlines():
        fields = line.split()
        target = fields[4]
        for escaped, literal in (('\\040', ' '), ('\\011', '\t'),
                                 ('\\012', '\n'), ('\\134', '\\')):
            target = target.replace(escaped, literal)
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            mounts.append({'target': target, 'options': fields[5].split(','),
                           'optional': fields[6:fields.index('-')]})
    return text, mounts


def isolate(out, evidence, mount, ip):
    require(os.getuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    require(os.getpid() == 1, 'consumer must be PID 1 with private proc')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, value in namespaces.items():
        require(value != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not isolated')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'namespace has non-loopback network interfaces')
    (evidence / 'mountinfo-before.txt').write_text(store_mounts()[0])
    subprocess.run([mount, '--rbind', '/gnu/store', '/gnu/store'], check=True, timeout=10)
    subprocess.run([mount, '--make-rprivate', '/gnu/store'], check=True, timeout=10)
    for entry in sorted(store_mounts()[1], key=lambda item: len(item['target']), reverse=True):
        subprocess.run([mount, '-o', 'remount,bind,ro', entry['target']], check=True, timeout=10)
    text, mounts = store_mounts()
    require(mounts and all('ro' in item['options'] and 'rw' not in item['options'] and
                          not any(value.startswith(('shared:', 'master:'))
                                  for value in item['optional']) for item in mounts),
            'store is not recursively private/read-only')
    require(os.statvfs(out).f_flag & os.ST_RDONLY, 'output filesystem is writable')
    (evidence / 'mountinfo-after.txt').write_text(text)
    subprocess.run([ip, 'link', 'set', 'lo', 'up'], check=True, timeout=10)
    routes = subprocess.check_output([ip, '-j', 'route', 'show', 'table', 'all'], timeout=10)
    route_data = json.loads(routes)
    require(all(route.get('dev') in (None, 'lo') and route.get('dst') != 'default'
                for route in route_data), 'namespace has external/default route')
    receipt = {'uid': os.getuid(), 'gid': os.getgid(), 'namespaces': namespaces,
               'uid_map': Path('/proc/self/uid_map').read_text(),
               'gid_map': Path('/proc/self/gid_map').read_text(),
               'interfaces': interfaces, 'routes': route_data,
               'store_read_only': True, 'store_mounts': mounts}
    save(evidence / 'isolation.json', receipt)
    return receipt


def html(body):
    return ('<!doctype html><html lang="en"><head><meta charset="utf-8">'
            '<title>Offline native browser</title><style>'
            'body{font:16px monospace;color:black;background:white;margin:16px}'
            'input{font:16px monospace;display:block;width:320px;height:64px;'
            'box-sizing:border-box}label{display:block}p{margin:12px 0}'
            '</style></head><body>' + body + '</body></html>').encode()


DOCUMENTS = {
    '/start': html('<p>OFFLINE BROWSER READY</p><p>Awaiting ordinary URL keys.</p>'),
    '/doc': html('<p>' + DOC_ONE + '</p><p>Original offline HTML consumer.</p>'
                 '<p><a href="/next">' + LINK + '</a></p>'),
    '/next': html('<p>' + DOC_TWO + '</p><p>Link navigation reached a new document.</p>'
                  '<form action="/submitted" method="get"><label for="entry">Offline entry</label>'
                  '<input id="entry" name="word" autocomplete="off">'
                  '<button type="submit">Submit entry</button></form>'),
    '/submitted': html('<p>' + RESULT + '</p><p>Submitted text: ' + INPUT + '</p>'),
}


class Fixture(BaseHTTPRequestHandler):
    requests = []
    evidence = None

    def do_GET(self):
        url = urlsplit(self.path)
        record = {'method': 'GET', 'path': url.path, 'query': parse_qs(url.query),
                  'peer': self.client_address[0],
                  'user_agent': self.headers.get('User-Agent', '')}
        self.requests.append(record)
        save(self.evidence / 'http-requests.json', self.requests)
        require(self.client_address[0] == '127.0.0.1', 'non-loopback fixture request')
        document = DOCUMENTS.get(url.path)
        if url.path == '/submitted' and parse_qs(url.query) != {'word': [INPUT]}:
            document = None
        if document is None:
            self.send_response(404)
            self.end_headers()
            return
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(document)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(document)

    def log_message(self, *args):
        pass


def processes():
    """Private PID namespace contains only this driver and its own children."""
    result = []
    for path in Path('/proc').iterdir():
        if not path.name.isdecimal() or int(path.name) == os.getpid():
            continue
        try:
            status = (path / 'status').read_text()
            command = (path / 'cmdline').read_bytes().rstrip(b'\0').split(b'\0')
            executable = os.readlink(path / 'exe')
            parent = int(next(line.split()[1] for line in status.splitlines()
                              if line.startswith('PPid:')))
            result.append({'pid': int(path.name), 'exe': executable,
                           'argv': [value.decode('utf-8', 'replace') for value in command],
                           'parent_pid': parent,
                           'status': status,
                           'namespaces': {name: os.readlink(path / 'ns' / name)
                                          for name in ('user', 'mnt', 'net', 'pid')}})
        except (FileNotFoundError, ProcessLookupError):
            pass
    return result


def reap():
    while True:
        try:
            pid, _ = os.waitpid(-1, os.WNOHANG)
        except ChildProcessError:
            return
        if not pid:
            return


class Screen(pyte.Screen):
    last_graphic = ''

    def draw(self, data):
        super().draw(data)
        if data:
            self.last_graphic = data[-1]

    def repeat_character(self, count=1):
        if self.last_graphic:
            super().draw(self.last_graphic * (count or 1))


class Stream(pyte.Stream):
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


class Terminal:
    def __init__(self, command, env, work, evidence):
        self.evidence = evidence
        self.raw = (evidence / 'terminal.raw').open('xb')
        self.frames = (evidence / 'terminal-frames.jsonl').open('x')
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.stream.use_utf8 = False
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.bytes = 0
        self.inputs = []
        self.status = None
        self.eof = False
        self.pid, self.fd = os.forkpty()
        if not self.pid:
            try:
                os.chdir(work)
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                os.execve(command[0], command, env)
            except BaseException as error:
                os.write(2, ('exec failed: ' + repr(error) + '\n').encode())
                os._exit(127)

    def text(self):
        return '\n'.join(self.screen.display)

    def body(self):
        # Browsh's tab/address bars are not document-content evidence.
        return '\n'.join(self.document_rows())

    def document_rows(self):
        # Native Browsh renders every transparent/whitespace cell as U+2584
        # (frame_builder.go buildCell). Preserve one cell and its position when
        # extracting text. Raw/display evidence remains unchanged; never drop
        # non-whitespace characters or search debug logs instead of the screen.
        return [row.replace('▄', ' ') for row in self.screen.display[2:]]

    def exited(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
        return self.status is not None

    def read(self, delay=0.1):
        if self.eof or not select.select([self.fd], [], [], delay)[0]:
            return
        try:
            data = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        if not data:
            self.eof = True
            return
        self.bytes += len(data)
        require(self.bytes < 15000000, 'excessive terminal output')
        self.raw.write(data)
        self.raw.flush()
        self.stream.feed(self.decoder.decode(data))
        self.frames.write(json.dumps({'raw_offset': self.bytes,
                                      'rows': self.screen.display,
                                      'cursor': [self.screen.cursor.x, self.screen.cursor.y]}) + '\n')
        self.frames.flush()

    def wait(self, predicate, description, seconds=35):
        deadline = time.monotonic() + seconds
        stable = None
        while True:
            self.read()
            if predicate():
                if stable is None:
                    stable = time.monotonic()
                if time.monotonic() - stable >= 0.5:
                    return
            else:
                stable = None
            require(not self.exited(), description + ': Browsh exited\n' + self.text())
            require(time.monotonic() < deadline, description + ': timed out\n' + self.text())

    def send(self, data, description):
        require(not self.exited(), 'cannot send keys to exited Browsh')
        self.inputs.append({'raw_offset': self.bytes, 'description': description,
                            'bytes_hex': data.hex()})
        save(self.evidence / 'terminal-inputs.json', self.inputs)
        require(os.write(self.fd, data) == len(data), 'partial PTY input write')

    def snapshot(self, label):
        (self.evidence / (label + '.screen.txt')).write_text(self.text() + '\n')
        (self.evidence / (label + '.document.txt')).write_text(self.body() + '\n')
        save(self.evidence / (label + '.frame.json'),
             {'raw_offset': self.bytes, 'rows': self.screen.display,
              'cursor': [self.screen.cursor.x, self.screen.cursor.y]})

    def text_position(self, text):
        matches = [(row.index(text), y + 2) for y, row in enumerate(self.document_rows())
                   if text in row]
        require(len(matches) == 1, 'expected one rendered text anchor: ' + text)
        return matches[0]

    def click(self, x, y, description):
        require(0 <= x < COLS and 2 <= y < ROWS, 'click outside displayed document')
        self.send(f'\x1b[<0;{x + 1};{y + 1}M\x1b[<0;{x + 1};{y + 1}m'.encode(),
                  'ordinary terminal mouse click: ' + description)

    def click_text(self, text):
        x, y = self.text_position(text)
        self.click(x + max(1, len(text) // 2), y, 'rendered ' + text)

    def click_input(self):
        # Empty native input boxes overlay placeholder/value text with spaces.
        # The original fixture puts a 64px-tall block field immediately beneath
        # this visible label. Two rendered rows down lies inside the field;
        # the anchor comes only from actual terminal output, never browser DOM.
        x, y = self.text_position('Offline entry')
        self.click(x + 2, y + 2, 'blank native field beneath rendered Offline entry label')

    def quit(self):
        self.send(b'\x11', 'ordinary Ctrl-Q quit')
        deadline = time.monotonic() + 20
        while not self.exited() or not self.eof:
            self.read()
            require(time.monotonic() < deadline, 'ordinary quit did not exit')
        require(self.status == 0, 'ordinary quit exit status: ' + str(self.status))
        self.snapshot('ordinary-quit')

    def close(self):
        os.close(self.fd)
        self.raw.close()
        self.frames.close()


def browser_identity(out, runtime, evidence, isolation):
    found = processes()
    browsh = [item for item in found if item['exe'].startswith(str(out) + '/')]
    browser = [item for item in found if item['exe'].startswith(str(runtime) + '/') and
               any(value in ('--headless', '-headless') for value in item['argv'])]
    save(evidence / 'processes-live.json', found)
    require(browsh, 'no real installed Browsh process observed')
    require(len(browser) == 1, 'expected one actual packaged Firefox headless parent')
    for process in browsh + browser:
        require(not any('test' in value or value in ('--http-server-mode', '--time-limit')
                        for value in process['argv'][1:]), 'nonordinary browser/test invocation')
        require(process['namespaces'] == isolation['namespaces'], 'process escaped isolation')
        with Path(process['exe']).open('rb') as stream:
            require(stream.read(4) == b'\x7fELF', 'observed runtime process is not native ELF')
    require('--marionette' in browser[0]['argv'], 'actual Firefox lacks native Marionette')
    ancestors = {item['pid']: item['parent_pid'] for item in found}
    pid = browser[0]['pid']
    chain = []
    while pid in ancestors and pid not in chain:
        chain.append(pid)
        pid = ancestors[pid]
    require(any(item['pid'] in chain for item in browsh), 'Firefox is not a packaged Browsh child')
    for item in browsh:
        tty = os.readlink(f"/proc/{item['pid']}/fd/0")
        require(tty.startswith('/dev/pts/'), 'Browsh is not using a real PTY')
        item['stdin_tty'] = tty
    browser[0]['parent_chain'] = chain
    return {'browsh': browsh, 'firefox': browser[0]}


def main():
    out, evidence, scratch = map(Path, sys.argv[1:4])
    mount, ip = sys.argv[4:6]
    report = {'status': 'failed', 'source_commit': COMMIT, 'source_anchors': SOURCE_ANCHORS,
              'fixture_origin': 'original static HTML; native browser GET form; no script',
              'limitations': ['offline loopback HTML navigation/input only; no external sites',
                              'headless Firefox rendering, not a graphical browser window']}
    report['source_urls'] = [SOURCE_BASE + path for path in
                             ('interfacer/src/browsh/tty.go', 'interfacer/src/browsh/input_box.go',
                              'interfacer/src/browsh/frame_builder.go', 'interfacer/src/browsh/ui.go',
                              'interfacer/src/browsh/firefox.go',
                              'interfacer/src/browsh/input_cursor.go',
                              'webext/src/dom/commands_mixin.js',
                              'webext/src/background/tty_commands_mixin.js')]
    session = server = thread = None
    failed = None
    owned_namespace = (os.getpid() == 1 and
                       os.readlink('/proc/self/ns/pid') != os.environ['HOST_PID_NS'])
    try:
        isolation = isolate(out, evidence, mount, ip)
        report['isolation'] = isolation
        configured = (out / 'share/browsh/firefox-path').read_text().strip()
        require(configured.startswith('/gnu/store/') and configured.endswith('/bin/firefox'),
                'packaged Firefox runtime metadata missing or invalid')
        runtime = Path('/gnu/store') / Path(configured).parts[3]
        require(str(runtime) in (evidence / 'runtime-closure.txt').read_text().splitlines(),
                'default Firefox runtime absent from installed output closure')
        require(Path(configured).is_file() and os.access(configured, os.X_OK),
                'packaged Firefox default is not executable')
        env = {'PATH': os.environ['PATH'], 'PYTHONPATH': os.environ.get('PYTHONPATH', ''),
               'TERM': 'xterm-256color', 'LC_ALL': 'C.UTF-8', 'LANG': 'C.UTF-8',
               'TMPDIR': str(scratch / 'tmp')}
        (scratch / 'tmp').mkdir(mode=0o700)
        for variable, name in (('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                               ('XDG_CACHE_HOME', 'cache'), ('XDG_DATA_HOME', 'data'),
                               ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime')):
            path = scratch / name
            path.mkdir(mode=0o700)
            env[variable] = str(path)
        work = scratch / 'work'
        work.mkdir(mode=0o700)
        save(evidence / 'private-environment.json', env)
        # --debug is an ordinary documented logging flag, not developer/test
        # mode. The source otherwise discards all Marionette/addon diagnostics.
        report['diagnostics'] = 'ordinary --debug writes private work/debug.log'
        fixtures = evidence / 'fixture'
        fixtures.mkdir(mode=0o700)
        for path, content in DOCUMENTS.items():
            (fixtures / (path[1:] + '.html')).write_bytes(content)
        report['fixture_sha256'] = {path: hashlib.sha256(content).hexdigest()
                                    for path, content in DOCUMENTS.items()}
        Fixture.evidence = evidence
        server = ThreadingHTTPServer(('127.0.0.1', 0), Fixture)
        server.daemon_threads = True
        base_url = f'http://127.0.0.1:{server.server_port}'
        url = base_url + '/start'
        command = [str(out / 'bin/browsh'), '--debug', '--startup-url', url]
        report['command'] = command
        report['configured_firefox'] = configured
        session = Terminal(command, env, work, evidence)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        session.wait(lambda: 'OFFLINE BROWSER READY' in session.body(),
                     'actual startup document rendered', 60)
        session.snapshot('browser-ready')
        report['process_identity'] = browser_identity(out, runtime, evidence, isolation)
        session.send(b'\x0c', 'ordinary Ctrl-L URL bar select-all')
        session.send((base_url + '/doc').encode(), 'ordinary typing document URL')
        session.send(b'\r', 'ordinary URL bar Enter navigation')
        session.wait(lambda: DOC_ONE in session.body() and
                     'OFFLINE BROWSER READY' not in session.body(),
                     'actual document rendered after ordinary URL keys')
        session.snapshot('document-one')
        session.click_text(LINK)
        session.wait(lambda: DOC_TWO in session.body() and DOC_ONE not in session.body(),
                     'native link reached changed document')
        session.snapshot('document-two')
        session.click_input()
        session.send(INPUT.encode(), 'ordinary typing into native HTML input')
        session.wait(lambda: INPUT in session.body(), 'typed input rendered in terminal')
        session.snapshot('typed-input')
        session.click_text('Submit entry')
        session.wait(lambda: RESULT in session.body() and INPUT in session.body() and
                     DOC_TWO not in session.body(), 'native HTML form response rendered')
        session.snapshot('form-result')
        require(any(item['path'] == '/submitted' and item['query'] == {'word': [INPUT]}
                    for item in Fixture.requests), 'actual form request was not received')
        require(all('Firefox/' in item['user_agent'] for item in Fixture.requests),
                'fixture was not consumed by actual Firefox')
        report['process_identity_after_navigation'] = browser_identity(out, runtime, evidence, isolation)
        session.quit()
        report['ordinary_quit_status'] = session.status
        deadline = time.monotonic() + 15
        while True:
            reap()
            live = processes()
            if not live:
                break
            require(time.monotonic() < deadline,
                    'browser children survived ordinary quit: ' + repr(live))
            time.sleep(0.1)
        save(evidence / 'processes-after-quit.json', live)
        report.update(status='passed', actual_terminal_render=True,
                      actual_document_key_navigation=True,
                      actual_link_navigation=True, actual_native_form_submission=True,
                      ordinary_quit=True, browser_children_shutdown=True)
    except BaseException as error:
        failed = error
        report['error'] = repr(error)
        save(evidence / 'processes-at-failure.json', processes() if owned_namespace else [])
        if session:
            session.snapshot('failure')
    finally:
        # Failure teardown targets ONLY processes inside this owned PID namespace.
        # Forced cleanup is never counted as ordinary browser shutdown acceptance.
        cleanup = []
        for process in processes() if owned_namespace else []:
            try:
                os.kill(process['pid'], signal.SIGKILL)
                cleanup.append(process['pid'])
            except ProcessLookupError:
                pass
        report['forced_cleanup_pids'] = cleanup
        if session:
            session.close()
        if server:
            server.shutdown()
            server.server_close()
        if thread:
            thread.join(timeout=5)
        profile_receipts = {}
        for name in ('extensions.json', 'addonStartup.json.lz4', 'prefs.js'):
            for path in sorted(scratch.rglob(name)):
                target = evidence / ('profile-' + name)
                target.write_bytes(path.read_bytes())
                profile_receipts[name] = str(target)
        report['profile_diagnostic_files'] = profile_receipts
        report['http_requests'] = Fixture.requests
        # Native logs/profile are evidence, not persistent user state. Never copy
        # the profile or extension bytes into the package output.
        for index, log in enumerate(sorted(scratch.rglob('*.log'))):
            if log.is_file():
                (evidence / f'native-{index}-{log.name}').write_bytes(log.read_bytes())
        save(evidence / 'runtime.json', report)
    if failed:
        raise failed
    print('BROWSH_NATIVE_OK real Firefox document/link/form terminal rendering; ordinary quit')


if __name__ == '__main__':
    main()
