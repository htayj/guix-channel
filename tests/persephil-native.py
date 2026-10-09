#!/usr/bin/env python3
"""Consume legacy KWIC HTML through the installed CLI and inspect its real XLSX."""
from datetime import datetime, timedelta, timezone
import hashlib
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
from pathlib import Path
import posixpath
import re
import socket
import stat
import subprocess
import sys
import threading
import traceback
import xml.etree.ElementTree as ET
import zipfile


# nextSibling must be the citation element, not intervening HTML whitespace.
# The nested spans are ordinary legacy KWIC emphasis: upstream recognizes a
# text node as bold when its grandparent is B.
HTML = b'''<!DOCTYPE html>
<html lang="la"><head><meta charset="utf-8"><title>Latin KWIC results</title></head>
<body><h1>Latin corpus concordance</h1>
<div class="content"><span>  Gallia est </span><b><span>omnis</span></b><span> divisa in partes tres.  </span></div><div class="citation"><b>  Caesar, De bello Gallico  </b><a href="/Latin/Caesar/1.1">  1.1  </a></div>
<div class="content"> \t<span>Arma </span><b><span>virumque</span></b><span> </span><b><span>cano</span></b><span>, Troiae qui primus ab oris.</span>\n </div><div class="citation"><b>Vergil, Aeneid</b><a href="/Latin/Vergil/1.1">1.1</a></div>
<div class="content"><span>  Nihil &amp; </span><b><span>virt&#363;s</span></b><span> sine labore. </span></div><div class="citation"><b>Seneca, Epistulae morales</b><a href="/Latin/Seneca/67.4">67.4</a></div>
</body></html>
'''
EXPECTED = [
    {'text': [('Gallia est ', False), ('omnis', True),
              (' divisa in partes tres.', False)],
     'extract': [('omnis', True)],
     'work': 'Caesar, De bello Gallico', 'passage': '1.1'},
    {'text': [('Arma ', False), ('virumque', True), (' ', False),
              ('cano', True), (', Troiae qui primus ab oris.', False)],
     'extract': [('virumque', True), (' ', False), ('cano', True)],
     'work': 'Vergil, Aeneid', 'passage': '1.1'},
    {'text': [('Nihil & ', False), ('virtūs', True), (' sine labore.', False)],
     'extract': [('virtūs', True)],
     'work': 'Seneca, Epistulae morales', 'passage': '67.4'},
]
ROUTE = '/legacy/Latin/kwic?kwic=omnis&fixture=persephil'
NS = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
      'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
      'p': 'http://schemas.openxmlformats.org/package/2006/relationships'}


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def store_mounts():
    result = []
    for line in Path('/proc/self/mountinfo').read_text().splitlines():
        fields = line.split()
        if fields[4] == '/gnu/store' or fields[4].startswith('/gnu/store/'):
            result.append((fields[4], fields[5].split(',')))
    return result


def isolate(out, evidence, mount, ip):
    require(os.getuid() == int(os.environ['EXPECTED_UID']), 'caller UID changed')
    require(os.getgid() == int(os.environ['EXPECTED_GID']), 'caller GID changed')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    for name, value in namespaces.items():
        require(value != os.environ['HOST_' + name.upper() + '_NS'],
                name + ' namespace is not isolated')
    require(os.getpid() == 1, 'driver is not PID 1 in private proc mount')
    interfaces = [name for _, name in socket.if_nameindex()]
    require(interfaces == ['lo'], 'external network interface present')
    (evidence / 'mountinfo-before.txt').write_text(Path('/proc/self/mountinfo').read_text())
    for command in ([mount, '--rbind', '/gnu/store', '/gnu/store'],
                    [mount, '--make-rprivate', '/gnu/store']):
        subprocess.run(command, check=True, timeout=10)
    for target, _ in sorted(store_mounts(), key=lambda item: len(item[0]), reverse=True):
        subprocess.run([mount, '-o', 'remount,bind,ro', target], check=True, timeout=10)
    mounts = store_mounts()
    require(mounts and all('ro' in options for _, options in mounts), 'store mount writable')
    require(os.statvfs(out).f_flag & os.ST_RDONLY, 'output filesystem writable')
    subprocess.run([ip, 'link', 'set', 'dev', 'lo', 'up'], check=True, timeout=10)
    (evidence / 'mountinfo-after.txt').write_text(Path('/proc/self/mountinfo').read_text())
    save(evidence / 'isolation.json', {
        'uid': os.getuid(), 'gid': os.getgid(), 'namespaces': namespaces,
        'host_namespaces': {name: os.environ['HOST_' + name.upper() + '_NS']
                            for name in namespaces},
        'expected_uid': int(os.environ['EXPECTED_UID']),
        'expected_gid': int(os.environ['EXPECTED_GID']),
        'interfaces': interfaces, 'store_mounts': mounts, 'store_read_only': True,
        'loopback_enabled': True, 'driver_pid': os.getpid(),
        'uid_map': Path('/proc/self/uid_map').read_text(),
        'gid_map': Path('/proc/self/gid_map').read_text(),
    })


def inventory(root):
    result = {}
    for path in sorted(root.rglob('*')):
        mode = path.lstat().st_mode
        entry = {'mode': stat.S_IMODE(mode)}
        if stat.S_ISLNK(mode):
            entry.update(type='symlink', target=os.readlink(path))
        elif stat.S_ISREG(mode):
            data = path.read_bytes()
            entry.update(type='file', size=len(data), sha256=digest(data))
        elif stat.S_ISDIR(mode):
            entry.update(type='directory')
        else:
            raise AssertionError('unexpected filesystem object: ' + str(path))
        result[str(path.relative_to(root))] = entry
    return result


def string_value(element):
    runs = []
    for run in element.findall('s:r', NS):
        text = run.find('s:t', NS)
        props = run.find('s:rPr', NS)
        bold = None if props is None else props.find('s:b', NS)
        font = None if props is None else props.find('s:rFont', NS)
        runs.append({'text': '' if text is None else text.text or '',
                     'bold': bold is not None and bold.get('val', '1') not in ('0', 'false'),
                     'font': None if font is None else font.get('val')})
    return {'text': ''.join(element.itertext()) if not runs else ''.join(r['text'] for r in runs),
            'runs': runs}


def inspect_xlsx(path, evidence):
    with zipfile.ZipFile(path) as archive:
        require(archive.testzip() is None, 'corrupt XLSX ZIP member')
        workbook = ET.fromstring(archive.read('xl/workbook.xml'))
        sheets = workbook.findall('s:sheets/s:sheet', NS)
        require(len(sheets) == 1 and sheets[0].get('name') == 'Data',
                'expected exactly the Data worksheet')
        relation = sheets[0].get('{' + NS['r'] + '}id')
        relations = ET.fromstring(archive.read('xl/_rels/workbook.xml.rels'))
        targets = [rel.get('Target') for rel in relations.findall('p:Relationship', NS)
                   if rel.get('Id') == relation and rel.get('TargetMode') != 'External']
        require(len(targets) == 1, 'missing Data worksheet relationship')
        target = targets[0]
        sheet_path = target.lstrip('/') if target.startswith('/') else posixpath.normpath('xl/' + target)
        require(sheet_path.startswith('xl/'), 'worksheet relationship escapes xl/')
        shared = []
        if 'xl/sharedStrings.xml' in archive.namelist():
            shared = [string_value(item) for item in
                      ET.fromstring(archive.read('xl/sharedStrings.xml')).findall('s:si', NS)]
        sheet = ET.fromstring(archive.read(sheet_path))
        rows = sheet.findall('s:sheetData/s:row', NS)
        require([row.get('r') for row in rows] == ['1', '2', '3', '4'],
                'wrong number/order of result rows')
        cells = {}
        for row in rows:
            for cell in row.findall('s:c', NS):
                ref = cell.get('r')
                kind = cell.get('t')
                if kind == 's':
                    value = shared[int(cell.find('s:v', NS).text)]
                elif kind == 'inlineStr':
                    value = string_value(cell.find('s:is', NS))
                else:
                    raise AssertionError('expected string cell at ' + str(ref))
                cells[ref] = value
        require(set(cells) == {f'{col}{row}' for col in 'ABCD' for row in range(1, 5)},
                'unexpected worksheet cells')
        require([cells[col + '1']['text'] for col in 'ABCD'] ==
                ['Text', 'Extract', 'Work', 'Passage'], 'wrong worksheet headers')
        for row, expected in enumerate(EXPECTED, 2):
            for col, key in [('A', 'text'), ('B', 'extract')]:
                value = cells[f'{col}{row}']
                require([(run['text'], run['bold']) for run in value['runs']] == expected[key],
                        f'{col}{row}: rich-text runs/emphasis do not match fixture')
                require(all(run['font'] == 'Times New Roman' for run in value['runs']),
                        f'{col}{row}: rich-text font lost')
            require(cells[f'C{row}']['text'] == expected['work'], f'C{row}: work mismatch')
            require(cells[f'D{row}']['text'] == expected['passage'], f'D{row}: passage mismatch')
        xml_dir = evidence / 'xlsx-xml'
        xml_dir.mkdir()
        for name in ['xl/workbook.xml', 'xl/_rels/workbook.xml.rels', sheet_path,
                     'xl/sharedStrings.xml', 'xl/styles.xml']:
            if name in archive.namelist():
                (xml_dir / name.replace('/', '__')).write_bytes(archive.read(name))
        save(evidence / 'xlsx-cells.json', cells)
        return {'sheet': 'Data', 'result_rows': len(EXPECTED),
                'zip_members': archive.namelist(), 'rich_text_verified': True}


def consume(out, evidence, scratch, record):
    work = scratch / 'caller'
    work.mkdir()
    home, temporary = scratch / 'home', scratch / 'tmp'
    home.mkdir()
    temporary.mkdir()
    originals = {'unrelated.txt': b'Caller-owned bytes.  \nDo not rewrite.\n',
                 'existing.xlsx': b'Unrelated caller workbook sentinel, not test output.\n',
                 'notes/keep.txt': b'Nested unrelated file\n'}
    (work / 'notes').mkdir()
    for name, data in originals.items():
        (work / name).write_bytes(data)
        copy = evidence / 'caller-inputs' / name
        copy.parent.mkdir(parents=True, exist_ok=True)
        copy.write_bytes(data)
    (work / 'keep-link').symlink_to('notes/keep.txt')
    before = inventory(work)
    save(evidence / 'caller-before.json', before)
    (evidence / 'input.html').write_bytes(HTML)
    (evidence / 'stdin.raw').write_bytes(b'')
    save(evidence / 'expected-rows.json', EXPECTED)
    requests = []

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            requests.append({'method': self.command, 'path': self.path,
                             'http_version': self.request_version,
                             'headers': list(self.headers.items()),
                             'peer': list(self.client_address)})
            with (evidence / 'http-request-lines.raw').open('ab') as stream:
                stream.write(self.raw_requestline)
            body = HTML if self.path == ROUTE else b'Not found\n'
            self.send_response(200 if self.path == ROUTE else 404)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            self.wfile.flush()

        def log_message(self, fmt, *args):
            with (evidence / 'http-server.log').open('a') as stream:
                stream.write((fmt % args) + '\n')

    server = HTTPServer(('127.0.0.1', 0), Handler)
    server.timeout = 5
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    command = [str(out / 'bin/persephil'),
               f'http://127.0.0.1:{server.server_port}{ROUTE}']
    env = {'HOME': str(home), 'TMPDIR': str(temporary),
           'XDG_CACHE_HOME': str(home / '.cache'), 'XDG_CONFIG_HOME': str(home / '.config'),
           'PATH': '/nonexistent', 'LC_ALL': 'C', 'LANG': 'C', 'TZ': 'UTC'}
    save(evidence / 'command.json', {'argv': command, 'cwd': str(work), 'env': env,
                                  'stdin': 'closed; no injected application data'})
    record.update(command=command, cwd=str(work), natural_exit=False, forced_cleanup=False)
    process = None
    started = datetime.now(timezone.utc)
    try:
        with (evidence / 'cli.stdout.raw').open('wb') as stdout, \
                (evidence / 'cli.stderr.raw').open('wb') as stderr:
            process = subprocess.Popen(command, cwd=work, env=env,
                                       stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
            record['exit_status'] = process.wait(timeout=60)
            record['natural_exit'] = True
        ended = datetime.now(timezone.utc)
        require(process.returncode == 0, 'CLI did not naturally exit zero')
        require(len(requests) == 1 and requests[0]['method'] == 'GET' and
                requests[0]['path'] == ROUTE, 'CLI did not GET the supplied fixture URL exactly once')
        require(not (evidence / 'cli.stderr.raw').read_bytes(), 'CLI reported stderr errors')
        stdout = (evidence / 'cli.stdout.raw').read_text()
        lines = stdout.splitlines()
        require(len(lines) == 1, 'CLI stdout must contain only the generated filename, not errors')
        filename = lines[0]
        require(re.fullmatch(r'Latin corpus search \d{2}-\d{2}-\d{2} \d{2} \d{2} \d{2}\.xlsx', filename),
                'CLI did not print its ordinary dated XLSX filename')
        stamped = datetime.strptime(filename[len('Latin corpus search '):-len('.xlsx')],
                                    '%m-%d-%y %H %M %S').replace(tzinfo=timezone.utc)
        require(started - timedelta(seconds=1) <= stamped <= ended + timedelta(seconds=1),
                'generated filename does not use the ordinary runtime clock')
        after = inventory(work)
        save(evidence / 'caller-after.json', after)
        require(set(after) - set(before) == {filename}, 'CLI wrote unexpected caller files')
        require(all(after.get(name) == value for name, value in before.items()),
                'CLI changed an unrelated caller file, mode, directory or symlink')
        require(not inventory(home) and not inventory(temporary), 'CLI wrote unexpected home/tmp state')
        workbook = work / filename
        require(workbook.is_file() and not workbook.is_symlink(), 'missing generated regular XLSX')
        (evidence / filename).write_bytes(workbook.read_bytes())
        record['xlsx'] = inspect_xlsx(workbook, evidence)
        record.update(filename=filename, filename_clock_start=started.isoformat(),
                      filename_clock_end=ended.isoformat(),
                      input_html_sha256=digest(HTML), xlsx_sha256=digest(workbook.read_bytes()),
                      unrelated_files_preserved=True, only_expected_xlsx_written=True,
                      actual_http_request=True)
    finally:
        if process is not None and process.poll() is None:
            record['forced_cleanup'] = True
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)
        save(evidence / 'http-requests.json', requests)
        save(evidence / 'caller-final.json', inventory(work))
        record.update(cli_reaped=process is None or process.poll() is not None,
                      fixture_server_closed=True, fixture_thread_exited=not thread.is_alive())
        save(evidence / 'native-cleanup.json', {
            key: record[key] for key in ('cli_reaped', 'fixture_server_closed',
                                        'fixture_thread_exited', 'forced_cleanup')})
        require(not thread.is_alive(), 'fixture HTTP server thread did not exit')


def main():
    require(len(sys.argv) == 6, 'expected OUT EVIDENCE SCRATCH MOUNT IP')
    out, evidence, scratch = map(Path, sys.argv[1:4])
    record = {'status': 'failed', 'mechanism': 'ordinary loopback HTTP legacy KWIC HTML to real XLSX'}
    try:
        isolate(out, evidence, sys.argv[4], sys.argv[5])
        consume(out, evidence, scratch, record)
        record['status'] = 'passed'
        print('PERSEPHIL_NATIVE_RUNTIME_OK')
    except BaseException as exc:
        record['error'] = str(exc)
        traceback.print_exc()
        raise
    finally:
        save(evidence / 'runtime.json', record)
        files = {str(path.relative_to(evidence)): digest(path.read_bytes())
                 for path in sorted(evidence.rglob('*')) if path.is_file()
                 and path.name not in ('driver.stdout', 'driver.stderr')}
        save(evidence / 'native-file-hashes.json', files)


if __name__ == '__main__':
    main()
