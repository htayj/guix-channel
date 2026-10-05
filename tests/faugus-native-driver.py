#!/usr/bin/env python3
"""External GTK consumer: AT-SPI observations, X11 input, native persistence.

The installed launcher is always invoked normally, with no test mode, imported
application module, pre-created library/configuration, or replacement frontend.
Accessibility is read-only: all activation and typing use real X11 events.
"""
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
import time
import traceback
from xml.sax.saxutils import escape


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def run(*args, env=None):
    return subprocess.run(args, env=env, check=True, capture_output=True,
                          timeout=20)


def mount_targets(text):
    targets = []
    for line in text.splitlines():
        fields = line.split()
        target = re.sub(r'\\([0-7]{3})',
                        lambda m: chr(int(m[1], 8)), fields[4])
        if target == '/gnu/store' or target.startswith('/gnu/store/'):
            targets.append((target, fields[5].split(',')))
    return targets


def identity(pid):
    fields = {}
    for line in Path(f'/proc/{pid}/status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            fields[key] = [int(part) for part in value.split()]
    require(fields.get('Uid') == [int(os.environ['HOST_UID'])] * 4,
            'native process changed caller UID')
    require(fields.get('Gid') == [int(os.environ['HOST_GID'])] * 4,
            'native process changed caller GID')
    return fields


def isolate(root, evidence, mount):
    before = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-before.txt').write_text(before)
    run(mount, '--rbind', '/gnu/store', '/gnu/store')
    run(mount, '--make-rprivate', '/gnu/store')
    targets = mount_targets(Path('/proc/self/mountinfo').read_text())
    for target in sorted({target for target, _ in targets}, key=len, reverse=True):
        run(mount, '-o', 'remount,bind,ro', target)
    after = Path('/proc/self/mountinfo').read_text()
    (evidence / 'mountinfo-after.txt').write_text(after)
    require(mount_targets(after) and all('ro' in opts for _, opts in mount_targets(after)),
            'not all store mounts are read-only')
    fds = [os.open(path, os.O_RDONLY | os.O_DIRECTORY) for path in (root, evidence)]
    try:
        run(mount, '-t', 'tmpfs', '-o', 'mode=1777,nosuid,nodev', 'tmpfs', '/tmp')
        root, evidence = Path('/tmp/faugus-root'), Path('/tmp/faugus-evidence')
        for fd, path in zip(fds, (root, evidence)):
            path.mkdir()
            run(mount, '--bind', f'/proc/{os.getpid()}/fd/{fd}', str(path))
    finally:
        for fd in fds:
            os.close(fd)
    network = os.readlink('/proc/self/ns/net')
    require(network != os.environ['HOST_NET_NS'], 'network namespace is not private')
    require([name for _, name in socket.if_nameindex()] == ['lo'],
            'network namespace has non-loopback interface')
    namespaces = {name: os.readlink('/proc/self/ns/' + name)
                  for name in ('user', 'mnt', 'net', 'pid')}
    save(evidence / 'isolation.json', {
        'identity': identity('self'), 'namespaces': namespaces,
        'host_network_namespace': os.environ['HOST_NET_NS'],
        'interfaces': [name for _, name in socket.if_nameindex()],
        'uid_map': Path('/proc/self/uid_map').read_text(),
        'gid_map': Path('/proc/self/gid_map').read_text(),
        'store_mounts': mount_targets(after)})
    return root, evidence


class Proof:
    def __init__(self, out, evidence, root, tools, env, atspi):
        self.out, self.evidence, self.root = out, evidence, root
        self.tools, self.env, self.Atspi = tools, env, atspi
        self.process = None
        self.log = None
        self.events, self.captures = [], []
        self.app = None
        self.session = 0

    def check(self):
        require(self.process is not None and self.process.poll() is None,
                'normal native launcher exited prematurely, including exit status 0')
        text = self.log_path.read_text(errors='replace')
        require(not re.search(r'Traceback \(most recent call last\)|'
                              r'\bCRITICAL\b|\bERROR\b|\bException:|Segmentation fault',
                              text, re.IGNORECASE),
                'native launcher reported an error; see native log')

    def start(self):
        self.session += 1
        self.app = None
        self.log_path = self.evidence / f'native-{self.session}.log'
        self.log = self.log_path.open('wb')
        self.process = subprocess.Popen([str(self.out / 'bin/faugus-launcher')],
                                        env=self.env, cwd=self.root,
                                        stdout=self.log, stderr=self.log)
        self.await_tree(lambda rows: any(r['name'] == 'Faugus' and
                                        r['showing'] for _, r in rows),
                        'normal launcher main window')

    def tree(self):
        desktop = self.Atspi.get_desktop(0)
        desktop.set_cache_mask(self.Atspi.Cache.NONE)
        if self.app is None:
            for i in range(desktop.get_child_count()):
                app = desktop.get_child_at_index(i)
                if app.get_process_id() == self.process.pid:
                    self.app = app
                    self.app.set_cache_mask(self.Atspi.Cache.NONE)
                    identity(app.get_process_id())
                    break
        if self.app is None:
            return []
        rows = []

        def walk(node, path, window_name=None):
            if node is None or len(path) > 32:
                return
            states = node.get_state_set()
            showing = (states.contains(self.Atspi.StateType.SHOWING) and
                       states.contains(self.Atspi.StateType.VISIBLE))
            role = node.get_role_name()
            if role in ('frame', 'dialog'):
                window_name = node.get_name()
            rect = None
            component = node.get_component_iface()
            if showing and component:
                # GTK 4.22 deliberately returns (0, 0) for SCREEN coordinates.
                # WINDOW preserves actual widget offsets in its native client.
                box = self.Atspi.Component.get_extents(component, self.Atspi.CoordType.WINDOW)
                rect = [box.x, box.y, box.width, box.height]
            text_iface = node.get_text_iface()
            text = self.Atspi.Text.get_text(text_iface, 0, -1) if text_iface else None
            # GtkModelButton (popover menu item) names come from a
            # labelled-by relation to a presentation-role GtkLabel; GTK 4.22
            # leaves that computed name empty, but exports the relation and
            # the label's own Text interface. Record that native label text.
            labelled_by = []
            if showing:
                for relation in node.get_relation_set():
                    if relation.get_relation_type() != self.Atspi.RelationType.LABELLED_BY:
                        continue
                    for i in range(relation.get_n_targets()):
                        target = relation.get_target(i)
                        target_text = target.get_text_iface()
                        labelled_by.append(self.Atspi.Text.get_text(target_text, 0, -1)
                                           if target_text else target.get_name())
            rows.append((node, {'path': path, 'name': node.get_name(),
                                'role': role, 'text': text, 'window_name': window_name,
                                'labelled_by': labelled_by,
                                'showing': showing, 'rectangle': rect,
                                'focused': states.contains(self.Atspi.StateType.FOCUSED),
                                'attributes': dict(node.get_attributes()),
                                'process_id': node.get_process_id()}))
            for i in range(node.get_child_count()):
                walk(node.get_child_at_index(i), path + [i], window_name)
        walk(self.app, [])
        return rows

    def await_tree(self, predicate, description, timeout=30):
        deadline = time.monotonic() + timeout
        rows = []
        while time.monotonic() < deadline:
            self.check()
            rows = self.tree()
            if predicate(rows):
                return rows
            time.sleep(0.15)
        save(self.evidence / 'failure-accessibility.json', [r for _, r in rows])
        raise RuntimeError('timed out awaiting ' + description)

    def find(self, name, role=None):
        rows = self.await_tree(lambda rows: any(r['showing'] and r['name'] == name and
                                             (role is None or r['role'] == role)
                                             for _, r in rows), name)
        matches = [(n, r) for n, r in rows if r['showing'] and r['name'] == name and
                   (role is None or r['role'] == role)]
        # Labels and their containing button can share a name: choose the
        # semantic actionable widget, never a text-label rectangle by accident.
        if role is None:
            actionable = [(n, r) for n, r in matches if n.get_action_iface()]
            if actionable:
                matches = actionable
        require(len(matches) == 1, 'ambiguous accessible control ' + repr(name))
        return matches[0]

    def click(self, name, role=None, button='1'):
        _, row = self.find(name, role)
        self.click_row(row, button)

    def click_row(self, row, button='1'):
        rect = row['rectangle']
        require(rect and rect[2] > 0 and rect[3] > 0, 'control has no visible geometry')
        require(row['window_name'], 'control has no accessible native window')
        ids = run(self.tools['xdotool'], 'search', '--onlyvisible', '--pid',
                  str(self.process.pid), env=self.env).stdout.split()
        windows = [xid.decode() for xid in ids if
                   run(self.tools['xdotool'], 'getwindowname', xid.decode(),
                       env=self.env).stdout.decode().rstrip('\n') == row['window_name']]
        require(len(windows) == 1, 'cannot identify exact native X11 window ' + row['window_name'])
        geometry = run(self.tools['xdotool'], 'getwindowgeometry', '--shell',
                       windows[0], env=self.env).stdout.decode()
        origin = dict(line.split('=', 1) for line in geometry.splitlines() if '=' in line)
        x = int(origin['X']) + rect[0] + rect[2] // 2
        y = int(origin['Y']) + rect[1] + rect[3] // 2
        run(self.tools['xdotool'], 'mousemove', '--sync', str(x), str(y),
            'click', button, env=self.env)
        self.events.append({'kind': 'mouse', 'button': button, 'control': row,
                            'window_id': windows[0], 'window_geometry': origin,
                            'screen_position': [x, y]})
        time.sleep(0.3)
        self.check()

    def key(self, *keys):
        run(self.tools['xdotool'], 'key', '--clearmodifiers', '--delay', '100',
            *keys, env=self.env)
        self.events.append({'kind': 'key', 'keys': list(keys)})
        time.sleep(0.2)
        self.check()

    def type(self, value):
        run(self.tools['xdotool'], 'type', '--clearmodifiers', '--delay', '25',
            '--', value, env=self.env)
        self.events.append({'kind': 'text', 'value': value})
        time.sleep(0.2)
        self.check()

    def capture(self, name, labels):
        # GTK exposes entry placeholders as the exact AT-SPI attribute
        # "placeholder-text", not as the entry's name or editable contents.
        rows = self.await_tree(lambda rows: all(any(r['showing'] and
                             (r['name'] == label or r['text'] == label or
                              r['attributes'].get('placeholder-text') == label)
                             for _, r in rows) for label in labels),
                             'exact native labels/placeholders for ' + name)
        window_ids = run(self.tools['xdotool'], 'search', '--onlyvisible', '--pid',
                         str(self.process.pid), env=self.env).stdout.split()
        require(window_ids, 'native launcher has no visible X11 window')
        screenshots = []
        for index, xid in enumerate(window_ids):
            path = self.evidence / f'{name}-{index}.png'
            run(self.tools['import'], '-window', xid.decode(), str(path), env=self.env)
            data = path.read_bytes()
            require(data[:8] == b'\x89PNG\r\n\x1a\n', 'window capture is not PNG')
            width, height = struct.unpack('>II', data[16:24])
            require(width > 50 and height > 50, 'native window screenshot too small')
            pixels = run(self.tools['convert'], str(path), '-depth', '8',
                         'rgb:-', env=self.env).stdout
            require(len(set(pixels)) > 8, 'native window screenshot blank')
            screenshots.append({'file': path.name, 'window_id': xid.decode(),
                                'width': width, 'height': height,
                                'sha256': hashlib.sha256(data).hexdigest()})
        record = {'labels': labels, 'accessibility': [r for _, r in rows],
                  'screenshots': screenshots, 'native_pid': self.process.pid}
        save(self.evidence / (name + '-accessibility.json'), record)
        self.captures.append({'name': name, 'labels': labels, 'screenshots': screenshots})

    def close(self):
        self.check()
        # Normal upstream keyboard close, not a timeout accepted as success.
        run(self.tools['xdotool'], 'key', '--clearmodifiers', 'alt+F4', env=self.env)
        self.events.append({'kind': 'key', 'keys': ['alt+F4'], 'purpose': 'normal close'})
        code = self.process.wait(timeout=15)
        require(code == 0, 'native launcher returned nonzero on normal close')
        text = self.log_path.read_text(errors='replace')
        require(not re.search(r'Traceback \(most recent call last\)|\bCRITICAL\b|'
                              r'\bERROR\b|\bException:|Segmentation fault', text, re.IGNORECASE),
                'native close reported an error, even with exit status 0')
        self.log.close()
        self.process = None
        self.app = None


def entry_for_label(proof, label):
    # GTK's source places each label above its Gtk.Entry in one Gtk.Grid,
    # without an explicit labelled-by relation. Match that observed geometry,
    # restricted to the visible dialog, instead of hardcoded pixel positions.
    _, reference = proof.find(label, 'label')
    x, y, width, height = reference['rectangle']
    candidates = []
    for _, row in proof.tree():
        if (not row['showing'] or row['role'] not in ('text', 'entry') or
                not row['rectangle'] or row['window_name'] != reference['window_name']):
            continue
        rx, ry, rw, rh = row['rectangle']
        if 0 <= ry - (y + height) < 45 and rx <= x + width and x <= rx + rw:
            candidates.append(row)
    require(len(candidates) == 1, 'cannot identify native entry beneath label ' + label)
    return candidates[0]


def native_label(row):
    # The accessible name, or else the single native labelled-by label text.
    if row['name']:
        return row['name']
    return row['labelled_by'][0] if len(row['labelled_by']) == 1 else None


def focused_choice(rows, window):
    # Accept only the exact focused native item: either it is labelled itself
    # (GtkModelButton menu item, via name or labelled-by) or it contains one
    # named label (GtkDropDown factory row).
    for _, row in rows:
        if not (row['focused'] and row['showing'] and row['window_name'] == window):
            continue
        if native_label(row):
            return native_label(row)
        labels = [r['name'] for _, r in rows if r['showing'] and r['role'] == 'label' and
                  r['name'] and r['path'][:len(row['path'])] == row['path']]
        if len(labels) == 1:
            return labels[0]
    return None


def choose_focused(proof, window, wanted, limit):
    # Native popovers are separate surfaces without a parent-window pointer
    # origin, so use their own keyboard navigation and Return activation.
    for _ in range(limit + 1):
        if focused_choice(proof.tree(), window) == wanted:
            proof.key('Return')
            return
        proof.key('Down')
    raise RuntimeError('native popup focus never reached ' + wanted)


def choose_dropdown_item(proof, current, wanted):
    _, combo = proof.find(current, 'combo box')
    proof.click(current, 'toggle button')
    # Bounded by populate_combobox_with_launchers' eleven native entries.
    choose_focused(proof, combo['window_name'], wanted, 11)
    proof.await_tree(lambda rows: any(r['path'] == combo['path'] and r['role'] == 'combo box' and
                                      r['attributes'].get('valuetext') == wanted
                                      for _, r in rows),
                     'native dropdown selection ' + wanted)



def fill(proof, label, value):
    entry = entry_for_label(proof, label)
    proof.click_row(entry)
    # GtkWindow only sets has-focus on its focus widget while the toplevel is
    # active (gtkwindow.c set_focus/_gtk_window_set_is_active), and GtkEntry
    # reports its GtkText delegate's focus. Waiting for this exact entry to be
    # FOCUSED proves the freshly mapped dialog owns keyboard input first.
    proof.await_tree(lambda rows: any(r['path'] == entry['path'] and r['showing'] and r['focused']
                                      for _, r in rows),
                     'native keyboard focus in ' + label + ' entry')
    proof.key('ctrl+a')
    proof.type(value)
    # xdotool returns once X events are sent; GTK applies them asynchronously.
    # Wait for the same native entry's exact text rather than sampling once.
    proof.await_tree(lambda rows: any(r['path'] == entry['path'] and r['showing'] and
                                      r['text'] == value for _, r in rows),
                     'typed value in native ' + label + ' entry')


def library(proof, title, executable, arguments):
    path = proof.root / 'data/faugus-launcher/games.json'
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        proof.check()
        if path.exists():
            games = json.loads(path.read_text())
            if (len(games) == 1 and games[0].get('title') == title and
                    games[0].get('game_arguments') == arguments):
                game = games[0]
                require(game.get('path') == executable, 'native saved executable changed')
                require(game.get('runner') == 'Linux-Native', 'native saved wrong runner')
                require(game.get('disable_umu') is True, 'native saved runtime bypass checkbox incorrectly')
                return games
        time.sleep(0.1)
    raise RuntimeError('native library did not persist ' + title + ' with game arguments ' + repr(arguments))


def edit(proof, title):
    # The native game row's real context menu owns Edit, not a private API.
    _, row = proof.find(title, 'label')
    proof.click_row(row, '3')
    rows = proof.await_tree(lambda rows: [native_label(r) for _, r in rows
                                          if r['showing'] and r['role'] == 'menu item'].count('Edit') == 1,
                            'native context menu Edit item')
    # Keyboard Down cannot be used here: GtkPopoverMenu's move-focus is
    # re-emitted on the toplevel (gtkwidget.c real_move_focus), and the
    # toplevel focus chain runs through the FlowBoxChild the menu is parented
    # to, whose focus vfunc only descends into its content child
    # (gtkflowbox.c), so focus leaves the popover and it pops down. Every
    # ancestor of these GtkModelButtons is a widget, so their WINDOW extents
    # are toplevel-relative (the popover allocation transform maps
    # final_rect into toplevel space) and match the grabbed popup surface.
    item = [r for _, r in rows if r['showing'] and r['role'] == 'menu item' and
            native_label(r) == 'Edit'][0]
    require(item['window_name'] == row['window_name'], 'native Edit item outside launcher window')
    proof.click_row(item)
    proof.capture('edit-open-' + str(proof.session), ['Edit ' + title, 'Title', 'Path', 'Ok'])


def workflow(proof, executable):
    source = proof.out / 'lib'
    launchers = list(source.glob('python*/site-packages/faugus/launcher.py'))
    require(len(launchers) == 1, 'installed native launcher source missing')
    data = launchers[0].read_bytes()
    native_source = data.decode()
    # The source is provenance only. Never execute it in the observer.
    require('self.button_add = create_button("faugus-add-symbolic", self.on_button_add_clicked)' in native_source,
            'native add-toolbar source contract changed')
    save(proof.evidence / 'source-provenance.json', {
        'file': str(launchers[0]), 'sha256': hashlib.sha256(data).hexdigest(),
        'references': ['Main.__init__: title Faugus', 'build_interface: add/settings/kill/play toolbar',
                       'AddGame: Title/Path labels above native entries',
                       'AddGame Tools page: Game Arguments label above native entry',
                       'on_button_edit_clicked: Title entry deliberately insensitive',
                       'populate_combobox_with_launchers: Linux Game',
                       'on_dialog_response / on_edit_dialog_response / save_games']})
    proof.start()
    proof.capture('fresh-launcher', ['Faugus', 'Search...'])
    rows = proof.tree()
    # The four icon-only toolbar buttons are created in add/settings/kill/play
    # order, with 50x50 minimum geometry. Select the first in their actual
    # accessibility sibling group, and verify the observed dialog afterward.
    groups = {}
    for node, row in rows:
        box = row['rectangle']
        if row['showing'] and row['role'] == 'push button' and box and 45 <= box[2] <= 70 and 45 <= box[3] <= 70:
            groups.setdefault(tuple(row['path'][:-1]), []).append(row)
    toolbars = [sorted(group, key=lambda r: r['path'][-1])
                for group in groups.values() if len(group) == 4]
    require(len(toolbars) == 1, 'cannot identify exact native icon toolbar group')
    proof.click_row(toolbars[0][0])
    proof.capture('new-entry', ['New Game/App', 'Windows Game', 'Title', 'Path', 'Ok', 'Cancel'])
    # IdComboBox is Gtk.DropDown: its combo, toggle, and child label share
    # the selected text. Open it with the native toggle, then select by keyboard.
    choose_dropdown_item(proof, 'Windows Game', 'Linux Game')
    title = 'Offline Native Entry'
    arguments = '--offline-native-proof'
    fill(proof, 'Title', title)
    fill(proof, 'Path', executable)
    proof.click('Disable UMU', 'check box')
    proof.capture('native-entry-filled', ['New Game/App', 'Linux Game', 'Disable UMU', title, executable])
    proof.click('Ok', 'push button')
    proof.capture('entry-saved', ['Faugus', title])
    save(proof.evidence / 'library-added.json', library(proof, title, executable, ''))
    edit(proof, title)
    require(entry_for_label(proof, 'Title')['text'] == title, 'edit did not load saved title')
    require(entry_for_label(proof, 'Path')['text'] == executable, 'edit did not load saved path')
    # Faugus's Edit dialog makes Title insensitive (on_button_edit_clicked),
    # so the supported native edit is the Tools page's Game Arguments entry,
    # which on_edit_dialog_response saves as game_arguments.
    proof.click('Tools', 'toggle button')
    fill(proof, 'Game Arguments', arguments)
    proof.capture('entry-edited', ['Edit ' + title, 'Game Arguments', arguments, 'Ok'])
    proof.click('Ok', 'push button')
    proof.await_tree(lambda rows: not any(r['showing'] and r['role'] == 'dialog' and
                                          r['name'] == 'Edit ' + title for _, r in rows),
                     'native Edit dialog closed after Ok')
    proof.capture('edit-saved', ['Faugus', title])
    saved = library(proof, title, executable, arguments)
    save(proof.evidence / 'library-edited.json', saved)
    proof.close()
    proof.start()
    proof.capture('reopened-launcher', ['Faugus', title])
    require(library(proof, title, executable, arguments) == saved, 'native reopen changed persisted entry')
    edit(proof, title)
    require(entry_for_label(proof, 'Title')['text'] == title, 'reopen edit lost saved title')
    require(entry_for_label(proof, 'Path')['text'] == executable, 'reopen edit lost native executable')
    proof.capture('reopened-entry', ['Edit ' + title, title, executable, 'Disable UMU', 'Cancel'])
    proof.click('Tools', 'toggle button')
    proof.await_tree(lambda rows: any(r['showing'] and r['role'] == 'label' and r['name'] == 'Game Arguments'
                                      for _, r in rows), 'native Tools page after reopen')
    require(entry_for_label(proof, 'Game Arguments')['text'] == arguments,
            'reopen edit lost native game arguments')
    proof.capture('reopened-tools', ['Edit ' + title, 'Game Arguments', arguments, 'Cancel'])
    proof.click('Cancel', 'push button')
    proof.await_tree(lambda rows: not any(r['showing'] and r['role'] == 'dialog' and
                                          r['name'] == 'Edit ' + title for _, r in rows),
                     'native Edit dialog closed after Cancel')
    proof.close()
    files = []
    for path in proof.root.rglob('*'):
        if not path.is_file():
            continue
        relative = str(path.relative_to(proof.root))
        require(not re.search(r'(^|/)(?:umu|proton|steamrt|SteamLinuxRuntime)(?:/|[-_])', relative, re.I),
                'launcher created downloaded runtime content: ' + relative)
        files.append({'path': relative, 'size': path.stat().st_size,
                      'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    save(proof.evidence / 'fresh-home-files.json', files)


def main():
    (out, evidence, root, pygobject, glib, atspi, xvfb, xdotool,
     image_import, convert, dbus, mount, fonts, local_executable, wm,
     introspection) = sys.argv[1:]
    out, evidence, root = Path(out), Path(evidence), Path(root)
    children = []
    logs = []
    proof = None
    record = {'status': 'failed', 'output': str(out)}
    try:
        root, evidence = isolate(root, evidence, mount)
        for name in ('home', 'config', 'data', 'state', 'cache', 'runtime'):
            (root / name).mkdir(mode=0o700)
        # Xvfb as an unprivileged mapped user cannot create this on fresh tmpfs.
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        os.chmod('/tmp/.X11-unix', 0o1777)
        env = dict(os.environ, HOME=str(root / 'home'),
                   XDG_CONFIG_HOME=str(root / 'config'),
                   XDG_DATA_HOME=str(root / 'data'), XDG_STATE_HOME=str(root / 'state'),
                   XDG_CACHE_HOME=str(root / 'cache'), XDG_RUNTIME_DIR=str(root / 'runtime'),
                   XDG_DATA_DIRS=f'{atspi}/share:{glib}/share',
                   GTK_A11Y='atspi', GDK_BACKEND='x11', GSK_RENDERER='cairo',
                   # Cairo draws GTK normally, but GDK otherwise probes EGL
                   # while initializing X11 even with a cairo GSK renderer.
                   # No GPU/DRI device belongs to this headless proof display.
                   GDK_DISABLE='gl,vulkan,dmabuf',
                   FAUGUS_DISABLE_UPDATES='1', UMU_RUNTIME_UPDATE='0',
                   NO_AT_BRIDGE='0', LANGUAGE='en_US', LC_ALL='C.UTF-8')
        fontconf = root / 'fonts.conf'
        fontconf.write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">'
                            '<fontconfig><dir>' + escape(fonts + '/share/fonts') + '</dir>'
                            '<cachedir>' + escape(str(root / 'cache/fonts')) + '</cachedir></fontconfig>')
        env['FONTCONFIG_FILE'] = str(fontconf)
        read_fd, write_fd = os.pipe()
        xlog = (evidence / 'xvfb.log').open('wb')
        logs.append(xlog)
        server = subprocess.Popen([xvfb, '-displayfd', str(write_fd), '-screen', '0',
                                   '1600x1000x24', '-nolisten', 'tcp', '-ac'], env=env,
                                  pass_fds=(write_fd,), stdout=xlog, stderr=xlog)
        children.append(server)
        os.close(write_fd)
        require(select.select([read_fd], [], [], 20)[0], 'Xvfb did not report readiness')
        display = os.read(read_fd, 32).decode().strip()
        os.close(read_fd)
        require(display.isdigit(), 'invalid Xvfb display')
        env['DISPLAY'] = ':' + display
        dbusconf = root / 'session-bus.conf'
        dbusconf.write_text('<busconfig><type>session</type><listen>unix:path=' +
                            escape(str(root / 'runtime/session-bus')) + '</listen>'
                            '<auth>EXTERNAL</auth><servicedir>' + escape(atspi + '/share/dbus-1/services') +
                            '</servicedir><policy context="default"><allow own="*"/>'
                            '<allow send_destination="*"/><allow receive_sender="*"/>'
                            '</policy></busconfig>')
        dlog = (evidence / 'dbus.log').open('wb')
        logs.append(dlog)
        bus = subprocess.Popen([dbus, '--nofork', '--config-file=' + str(dbusconf),
                                '--print-address=1'], env=env, stdout=subprocess.PIPE, stderr=dlog)
        children.append(bus)
        require(select.select([bus.stdout], [], [], 20)[0], 'D-Bus did not report readiness')
        address = bus.stdout.readline().decode().strip()
        require(address.startswith('unix:'), 'invalid D-Bus address')
        env['DBUS_SESSION_BUS_ADDRESS'] = address
        wlog = (evidence / 'window-manager.log').open('wb')
        logs.append(wlog)
        # Openbox finds its installed default theme via XDG_DATA_DIRS; the
        # launcher env deliberately omits it, so extend only the WM's view.
        wm_root = Path(wm).parent.parent
        wm_env = dict(env, XDG_DATA_DIRS=str(wm_root / 'share') + ':' + env['XDG_DATA_DIRS'],
                      XDG_CONFIG_DIRS=str(wm_root / 'etc/xdg'))
        manager = subprocess.Popen([wm, '--sm-disable'], env=wm_env, stdout=wlog, stderr=wlog)
        children.append(manager)
        time.sleep(0.5)
        require(manager.poll() is None, 'window manager did not start')
        os.environ.update(env)
        os.environ['GI_TYPELIB_PATH'] = ':'.join(
            path + '/lib/girepository-1.0' for path in (atspi, introspection, glib))
        sys.path[:0] = [str(path) for path in Path(pygobject).glob('lib/python*/site-packages')]
        import gi
        gi.require_version('Atspi', '2.0')
        from gi.repository import Atspi
        Atspi.init()
        tools = {'xdotool': xdotool, 'import': image_import, 'convert': convert}
        proof = Proof(out, evidence, root, tools, env, Atspi)
        workflow(proof, local_executable)
        require(server.poll() is None and bus.poll() is None, 'GUI observation service exited')
        record.update(status='passed', events=proof.events, captures=proof.captures,
                      proof='normal installed GTK launcher; read-only AT-SPI, real X11 input')
    except Exception as error:
        record.update(error=str(error), traceback=traceback.format_exc())
        if proof:
            record.update(events=proof.events, captures=proof.captures)
        traceback.print_exc()
    finally:
        if proof and proof.process and proof.process.poll() is None:
            proof.process.terminate()
            try:
                proof.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proof.process.kill()
                proof.process.wait()
        for process in reversed(children):
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        for log in logs:
            log.close()
        save(evidence / 'evidence.json', record)
    return 0 if record['status'] == 'passed' else 1


if __name__ == '__main__':
    sys.exit(main())
