#!/usr/bin/env python3
"""Real installed Legcord acceptance, with private HOME/Xvfb/session D-Bus.

No Discord login, host profile, seeded config, mocked frontend, sandbox bypass,
or messages. Onboarding is the actual logged-out settings UI; Discord-integrated
settings and live audio calls require login and are explicitly not claimed.
--hold-seconds leaves the final real renderer available for manual CDP inspection.
"""
import argparse
import base64
import contextlib
import ctypes
import json
import os
from pathlib import Path
import select
import shutil
import signal
import socket
import stat
import subprocess
import tempfile
import time
import urllib.request

PIN = "c8d91f61296019bb0c45f375535de8c93cf26ee1"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def dump(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def environment(root):
    env = {"PATH": os.environ["PATH"], "LANG": "en_US.UTF-8", "LC_ALL": "en_US.UTF-8"}
    for name, leaf in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                       ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                       ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                       ("TMPDIR", "tmp")):
        directory = root / leaf
        directory.mkdir(mode=0o700)
        env[name] = str(directory)
    return env


def immutable(root):
    require(root.parent == Path("/gnu/store") and root.is_dir(), "expected exact store output")
    for item in (root, *root.rglob("*")):
        mode = item.lstat().st_mode
        if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
            require(not mode & 0o222, f"writable store member: {item}")


def descendants(owner):
    table = {}
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            fields = (entry / "stat").read_text().rsplit(")", 1)[1].split()
            table[int(entry.name)] = {"parent": int(fields[1]), "group": int(fields[2]),
                                      "start": fields[19]}
        except (OSError, ValueError, IndexError):
            continue
    owned = {pid for pid, info in table.items() if pid == owner or info["group"] == owner}
    while True:
        children = {pid for pid, info in table.items() if info["parent"] in owned}
        if children <= owned:
            return {pid: table[pid] for pid in owned}
        owned |= children


def stop_owned(owned):
    handles = []
    try:
        for pid, info in owned.items():
            fd = None
            try:
                fd = os.pidfd_open(pid)
                current = Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
                if current[19] != info["start"]:
                    os.close(fd)
                    continue
                handles.append(fd)
            except (ProcessLookupError, FileNotFoundError):
                if fd is not None:
                    os.close(fd)
        for fd in handles:
            with contextlib.suppress(ProcessLookupError):
                signal.pidfd_send_signal(fd, signal.SIGTERM)
        pending = handles[:]
        deadline = time.monotonic() + 10
        while pending and time.monotonic() < deadline:
            exited, _, _ = select.select(pending, [], [], 0.2)
            pending = [fd for fd in pending if fd not in exited]
        for fd in pending:
            with contextlib.suppress(ProcessLookupError):
                signal.pidfd_send_signal(fd, signal.SIGKILL)
        if pending:
            exited, _, _ = select.select(pending, [], [], 10)
            require(len(exited) == len(pending), "owned app descendants failed to exit")
    finally:
        for fd in handles:
            os.close(fd)


@contextlib.contextmanager
def process(argv, env, root, log, cleanup=None):
    with log.open("wb") as stream:
        child = subprocess.Popen(list(map(str, argv)), env=env, cwd=root,
                                 stdin=subprocess.DEVNULL, stdout=stream,
                                 stderr=subprocess.STDOUT, start_new_session=True)
        try:
            yield child
        finally:
            stop_owned(cleanup() if cleanup else descendants(child.pid))
            child.wait(timeout=10)


def wait_for(callback, description, timeout=120, child=None):
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
        if child is not None:
            require(child.poll() is None, f"{description}: process exited {child.returncode}")
        try:
            value = callback()
            if value:
                return value
        except (OSError, ValueError, RuntimeError) as error:
            last = error
        time.sleep(0.2)
    raise RuntimeError(f"timeout waiting for {description}: {last}")


def http_json(url):
    # The explicit environment does not carry proxies; the transport is loopback.
    with urllib.request.urlopen(url, timeout=2) as response:
        return json.load(response)


class CDP:
    def __init__(self, url, deadline=None):
        import websocket
        timeout = 30 if deadline is None else min(5, max(0.001, deadline - time.monotonic()))
        self.ws = websocket.create_connection(url, timeout=timeout, suppress_origin=True)
        self.sequence = 0
        self.deadline = deadline
        self.contexts = {}
        self.main_frame = None

    def observe(self, response):
        method, params = response.get('method'), response.get('params', {})
        if method == 'Runtime.executionContextCreated':
            context = params['context']
            self.contexts[context['id']] = context.get('auxData', {})
        elif method == 'Runtime.executionContextDestroyed':
            self.contexts.pop(params.get('executionContextId'), None)
        elif method == 'Runtime.executionContextsCleared':
            self.contexts.clear()
        elif method == 'Page.frameNavigated' and not params['frame'].get('parentId'):
            self.main_frame = params['frame']['id']

    def receive(self):
        if self.deadline is not None:
            remaining = self.deadline - time.monotonic()
            require(remaining > 0, 'actual Discord readiness deadline expired')
            self.ws.settimeout(min(5, remaining))
        response = json.loads(self.ws.recv())
        self.observe(response)
        return response

    def default_context(self):
        while True:
            for ident, data in self.contexts.items():
                if data.get('isDefault') and data.get('frameId') == self.main_frame:
                    return ident
            self.receive()

    def call(self, method, params=None):
        self.sequence += 1
        ident = self.sequence
        # CDP is NOT JSON-RPC: no "jsonrpc" version member.
        self.ws.send(json.dumps({"id": ident, "method": method, "params": params or {}}))
        while True:
            response = self.receive()
            if response.get("id") == ident:
                require("error" not in response, f"{method}: {response.get('error')}")
                return response["result"]

    def evaluate(self, expression, context_id=None):
        params = {"expression": expression, "awaitPromise": True, "returnByValue": True}
        if context_id is not None:
            params['contextId'] = context_id
        value = self.call("Runtime.evaluate", params)
        require("exceptionDetails" not in value, f"renderer exception: {value}")
        return value.get("result", {}).get("value")

    def close(self):
        self.ws.close()


def dom(wire):
    return wire.evaluate("""({url: location.href, title: document.title,
        text: document.body.innerText.slice(0,12000), width: innerWidth, height: innerHeight,
        visible: document.visibilityState === 'visible',
        node_isolated: typeof window.require === 'undefined' && typeof process === 'undefined'})""")


def capture(wire, path):
    from PIL import Image
    image = wire.call("Page.captureScreenshot", {"format": "png", "captureBeyondViewport": False})
    path.write_bytes(base64.b64decode(image["data"]))
    with Image.open(path) as opened:
        require(opened.width >= 700 and opened.height >= 500, "screenshot viewport too small")
        colors = opened.convert("RGB").getcolors(opened.width * opened.height)
        require(colors is None or len(colors) > 10, "screenshot is blank/flat")


def click(wire, selector, text=None):
    # Dispatch genuine CDP mouse input at the visible upstream control, not an
    # invented callback, fabricated event handler or direct config-file write.
    point = wire.evaluate("""(() => {
      const candidates = [...document.querySelectorAll(%s)];
      const node = candidates.find(n => %s && !n.disabled && n.getBoundingClientRect().width);
      if (!node) return null;
      const r = node.getBoundingClientRect(); return {x:r.x+r.width/2, y:r.y+r.height/2};
    })()""" % (json.dumps(selector), "true" if text is None else
                 "n.innerText.trim() === " + json.dumps(text)))
    require(point, f"visible UI control missing: {selector} {text}")
    wire.call("Input.dispatchMouseEvent", {"type": "mouseMoved", **point})
    wire.call("Input.dispatchMouseEvent", {"type": "mousePressed", "button": "left", "clickCount": 1, **point})
    wire.call("Input.dispatchMouseEvent", {"type": "mouseReleased", "button": "left", "clickCount": 1, **point})


def sandbox(endpoint, app_owned, diagnostic=None, env=None):
    # Navigation can destroy a renderer between browser SystemInfo and /proc.
    # Refresh the entire authoritative list only for a vanished process, never
    # for an extant unowned or unsandboxed renderer.
    for attempt in range(5):
        try:
            return sandbox_snapshot(endpoint, app_owned, diagnostic, env)
        except (FileNotFoundError, ProcessLookupError):
            if attempt == 4:
                raise
            time.sleep(0.1)


def sandbox_snapshot(endpoint, app_owned, diagnostic=None, env=None):
    version = http_json(endpoint + "/json/version")
    wire = CDP(version["webSocketDebuggerUrl"])
    try:
        info = wire.call("SystemInfo.getProcessInfo")["processInfo"]
    finally:
        wire.close()
    # Snapshot ancestry after Chromium's authoritative process list, not before
    # a renderer can be forked during navigation.
    owned = app_owned()
    if diagnostic is not None:
        identities = []
        for item in info:
            pid = int(item['id'])
            entry = Path('/proc') / str(pid)
            identity = {'pid': pid, 'type': item['type'], 'owned': pid in owned}
            try:
                identity['exe'] = str(entry.joinpath('exe').resolve())
                identity['argv'] = entry.joinpath('cmdline').read_bytes().decode().split('\0')
                variables = dict(part.split(b'=', 1) for part in
                    entry.joinpath('environ').read_bytes().split(b'\0') if b'=' in part)
                identity['private_home_matches'] = variables.get(b'HOME') == os.fsencode(env['HOME'])
                identity['private_config_matches'] = variables.get(b'XDG_CONFIG_HOME') == os.fsencode(env['XDG_CONFIG_HOME'])
            except OSError as error:
                identity['identity_error'] = str(error)
            identities.append(identity)
        dump(diagnostic, {'processInfo': info, 'identities': identities,
             'owned': owned, 'expected_private_home': env['HOME']})
    facts = []
    for entry in info:
        if entry.get("type") != "renderer":
            continue
        pid = int(entry["id"])
        start_before = Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[19]
        require(pid in owned, f"CDP renderer is not an owned app descendant: {pid}")
        argv = Path(f"/proc/{pid}/cmdline").read_bytes().decode().split("\0")
        require(not any(arg.startswith(("--no-sandbox", "--disable-seccomp-filter-sandbox")) for arg in argv),
                "Electron disabled sandbox internally; never retry with --no-sandbox")
        fields = dict(line.split(":", 1) for line in Path(f"/proc/{pid}/status").read_text().splitlines() if ":" in line)
        seccomp, nnp = int(fields["Seccomp"]), int(fields["NoNewPrivs"])
        require(seccomp == 2 and nnp == 1, f"renderer {pid} lacks seccomp/no-new-privileges")
        start_after = Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[19]
        if start_before != start_after or owned[pid]['start'] != start_after:
            raise ProcessLookupError(f"renderer {pid} changed identity during snapshot")
        facts.append({"pid": pid, "role": "renderer", "identity_source": "browser CDP SystemInfo",
                      "seccomp": seccomp, "no_new_privs": nnp})
    require(facts, "browser SystemInfo reported no renderer")
    return {"browser": version["Browser"], "renderers": facts}


def settings_file(env):
    paths = list(Path(env["XDG_CONFIG_HOME"]).glob("*/storage/settings.json"))
    require(len(paths) == 1, f"expected single app settings file, found {paths}")
    return paths[0]


def settings_value(env, expected):
    settings = json.loads(settings_file(env).read_text())
    return settings if all(settings.get(key) == value for key, value in expected.items()) else None


def page_target(endpoint, predicate):
    return next((page for page in http_json(endpoint + "/json/list")
                 if page.get("type") == "page" and predicate(page.get("url", ""))), None)

def browser_generation(endpoint, app_owned, previous=None, deadline=None):
    """Admit a new live browser generation, not an old page on reused CDP port."""
    version = http_json(endpoint + '/json/version')
    browser_url = version['webSocketDebuggerUrl']
    if browser_url == previous:
        return None
    wire = CDP(browser_url, deadline=deadline)
    try:
        processes = wire.call('SystemInfo.getProcessInfo')['processInfo']
    finally:
        wire.close()
    browser = next((item for item in processes if item['type'] == 'browser'), None)
    if browser is None:
        return None
    pid = int(browser['id'])
    owned = app_owned()
    require(pid in owned, f'new browser generation is not owned: {pid}')
    start = Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[19]
    require(start == owned[pid]['start'], 'new browser generation changed process identity')
    if not page_target(endpoint, lambda url: url.startswith('https://discord.com/')):
        return None
    return {'browser_websocket_url': browser_url, 'pid': pid, 'start': start}


def wait_browser_generation(endpoint, app_owned, previous, description):
    import websocket
    deadline = time.monotonic() + 120
    last = None
    while time.monotonic() < deadline:
        try:
            generation = browser_generation(endpoint, app_owned, previous, deadline)
            if generation:
                return generation
        except (OSError, ValueError, websocket.WebSocketConnectionClosedException,
                websocket.WebSocketTimeoutException) as error:
            # Only startup/old-browser shutdown transport races at this explicit
            # generation boundary. Security/identity RuntimeErrors are fatal.
            last = error
        time.sleep(0.2)
    raise RuntimeError(f'timeout waiting for {description}: {last}')



def onboarding(endpoint, child, env, evidence, app_owned):
    target = wait_for(lambda: page_target(endpoint, lambda url: url == "legcord://html/setup.html"),
                      "actual upstream onboarding target", child=child)
    wire = CDP(target["webSocketDebuggerUrl"])
    try:
        wait_for(lambda: wire.evaluate("!!document.querySelector('.setup-cta') && typeof window.setup === 'object'"),
                 "actual setup UI and sandboxed preload", child=child)
        before = dom(wire)
        require(before["node_isolated"] and before["visible"], "onboarding isolation/visibility failed")
        guidance = wire.evaluate("document.getElementById('guix-update-guidance')?.innerText")
        require(guidance and "guix pull" in guidance and "guix upgrade legcord" in guidance,
                "actual onboarding lacks package-managed update instructions")
        initial_sandbox = sandbox(endpoint, app_owned)
        capture(wire, evidence / "onboarding.png")
        click(wire, ".setup-cta")
        wait_for(lambda: wire.evaluate("document.querySelectorAll('.setup-option').length === 3"), "window-style controls")
        # Native Window is the second upstream option card; preserve client mods.
        click(wire, ".setup-option:nth-child(2)")
        wait_for(lambda: settings_value(env, {"windowStyle": "native"}), "native window setting persisted")
        require(wire.evaluate("document.querySelector('.setup-option:nth-child(2)').getAttribute('aria-pressed') === 'true'"),
                "native window option did not become selected")
        capture(wire, evidence / "window-settings.png")
        click(wire, ".setup-footer-btn:last-child")
        wait_for(lambda: wire.evaluate("!!document.querySelector('.setup-option-icon')"), "upstream mod choices")
        # Leave upstream Shelter Only selection intact; no arbitrary mod disabling.
        require(settings_value(env, {"mods": []}), "unexpected default mod selection")
        capture(wire, evidence / "mod-settings.png")
        click(wire, ".setup-footer-btn:last-child")
        wait_for(lambda: wire.evaluate("document.querySelectorAll('.setup-option').length === 2"), "tray choices")
        click(wire, ".setup-option:nth-child(2)")
        saved = wait_for(lambda: settings_value(env, {"windowStyle": "native", "tray": "disabled", "mods": []}),
                         "onboarding settings saved to private userData")
        capture(wire, evidence / "tray-settings.png")
        click(wire, ".setup-footer-btn:last-child")
        wait_for(lambda: wire.evaluate("!!document.querySelector('.setup-finish')"), "onboarding finish")
        finished = dom(wire)
        capture(wire, evidence / "setup-finish.png")
        previous_browser = http_json(endpoint + '/json/version')['webSocketDebuggerUrl']
        click(wire, ".setup-cta")
        wait_for(lambda: settings_value(env, {"doneSetup": True}), "genuine launch action saved completion")
        dump(evidence / "onboarding.json", {"before": before, "finish": finished,
             "guix_update_guidance": guidance,
             "saved": {key: saved[key] for key in ("windowStyle", "tray", "mods")},
             "settings_path": str(settings_file(env)), "sandbox": initial_sandbox,
             "save_transport": "upstream option cards → setup-saveSettings IPC → storage/settings.json"})
        return previous_browser
    finally:
        wire.close()


def logged_out(endpoint, env, evidence, app_owned, label, automatic_updates=False, hold_seconds=0):
    import websocket
    deadline = time.monotonic() + 120
    target, wire = None, None
    transitions = []
    dump(evidence / (label + "-targets.json"), http_json(endpoint + "/json/list"))
    try:
        dump(evidence / (label + '-browser-sandbox.json'), sandbox(endpoint, app_owned,
             diagnostic=evidence / (label + '-ownership.json'), env=env))
        state = None
        while time.monotonic() < deadline:
            try:
                current = page_target(endpoint, lambda url: url.startswith('https://discord.com/'))
                if current is None:
                    time.sleep(min(0.2, max(0, deadline - time.monotonic())))
                    continue
                if wire is None or current['id'] != target['id']:
                    if wire is not None:
                        wire.close()
                    target = current
                    wire = CDP(target['webSocketDebuggerUrl'], deadline=deadline)
                    wire.call('Page.enable')
                    wire.call('Runtime.enable')
                    wire.main_frame = wire.call('Page.getFrameTree')['frameTree']['frame']['id']
                    transitions.append({'target_id': target['id'], 'url': target['url'], 'event': 'attached'})
                context_id = wire.default_context()
                state = wire.evaluate("""({url: location.href, title: document.title,
                    text: document.body.innerText.slice(0,12000), width: innerWidth, height: innerHeight,
                    visible: document.visibilityState === 'visible', node_isolated:
                    typeof window.require === 'undefined' && typeof process === 'undefined'})""", context_id)
                if state and state['url'].startswith('https://discord.com/login') and state['visible'] \
                        and 'Log In' in state['text'] and 'Email' in state['text']:
                    break
            except (websocket.WebSocketTimeoutException, websocket.WebSocketConnectionClosedException) as error:
                transitions.append({'event': 'context-transport-reconnect', 'reason': str(error)})
                if wire is not None:
                    wire.close()
                wire = None
            except RuntimeError as error:
                if not any(message in str(error) for message in (
                        'Cannot find context', 'Execution context was destroyed', 'Inspected target navigated')):
                    raise
                transitions.append({'event': 'context-destroyed-reconnect', 'reason': str(error)})
                if wire is not None:
                    wire.close()
                wire = None
            time.sleep(min(0.2, max(0, deadline - time.monotonic())))
        else:
            raise RuntimeError('timeout waiting for actual Discord /app → /login default execution context')
        dump(evidence / (label + '-context-transitions.json'), transitions)
        wire.deadline = None
        wire.ws.settimeout(30)
        require(state["node_isolated"], "Discord renderer Node isolation disabled")
        config = wire.evaluate("window.legcord.settings.getConfig()")
        expected = {"doneSetup": True, "windowStyle": "native", "tray": "disabled", "mods": [],
                    "automaticUpdates": automatic_updates}
        require(all(config.get(key) == value for key, value in expected.items()), "reloaded preload config differs from UI save")
        require(settings_value(env, expected), "persisted settings differ after restart")
        protection = sandbox(endpoint, app_owned)
        capture(wire, evidence / (label + ".png"))
        result = {"dom": state, "persisted_settings": expected, "sandbox": protection,
                  "target_id": target["id"], "electron": wire.evaluate("window.legcord.electron")}
        dump(evidence / (label + ".json"), result)
        return wire, result
    except BaseException as error:
        # Preserve the actual browser surface even if the renderer cannot run
        # JavaScript. These independent observations do not turn failure into a
        # pass or retry with a security bypass.
        with contextlib.suppress(Exception):
            dump(evidence / (label + '-context-transitions.json'), transitions)
            dump(evidence / (label + "-failed-targets.json"), http_json(endpoint + "/json/list"))
        with contextlib.suppress(Exception):
            if wire is not None:
                capture(wire, evidence / (label + "-failure.png"))
        dump(evidence / "inspection.json", {"cdp_url": endpoint, "display": env["DISPLAY"],
             "target_id": target['id'] if target else None, "failed_phase": label, "error": str(error),
             "hold_seconds": hold_seconds, "live_until_epoch": time.time() + hold_seconds})
        print(f"Legcord failure retained for inspection; CDP {endpoint}; DISPLAY {env['DISPLAY']}", flush=True)
        if hold_seconds:
            time.sleep(hold_seconds)
        if wire is not None:
            wire.close()
        raise


def dismiss_update_guidance(env, root, evidence, app_owned):
    title = "Legcord updates are managed by Guix"
    def find_dialog():
        result = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "^" + title + "$"],
                                env=env, cwd=root, capture_output=True, text=True, timeout=10)
        require(result.returncode in (0, 1), "native dialog window search failed")
        return result.stdout.split() if result.returncode == 0 else None
    windows = wait_for(find_dialog, "actual Electron Guix update guidance dialog")
    facts = []
    for window in windows:
        result = subprocess.run(["xdotool", "getwindowpid", window], env=env,
                                cwd=root, capture_output=True, text=True, check=True, timeout=10)
        pid = int(result.stdout.strip())
        require(pid in app_owned(), "update dialog does not belong to owned Electron app")
        facts.append({"window": window, "pid": pid, "title": title})
        subprocess.run(["xdotool", "windowfocus", "--sync", window], env=env, cwd=root,
                       check=True, timeout=10)
        subprocess.run(["xdotool", "key", "--window", window, "Return"], env=env, cwd=root,
                       check=True, timeout=10)
    dump(evidence / "update-dialog.json", {"native_windows": facts, "dismissal": "native Return key",
         "message_verified": False, "limitation": "X11 title/owner observed; dialog message is outside CDP"})


def acceptance(args, root, env):
    update = subprocess.run([str(args.legcord / "bin/legcord"), "--guix-update-info"],
                            env=env, cwd=root, capture_output=True, text=True, timeout=20)
    require(update.returncode == 0 and "guix pull" in update.stdout
            and "guix upgrade legcord" in update.stdout,
            "installed launcher did not provide explicit Guix update instructions")
    dump(args.evidence / "guix-update.json", {"argv": ["legcord", "--guix-update-info"],
         "returncode": update.returncode, "guidance": update.stdout,
         "upgrade_executed": False})
    # Electron app.relaunch() may orphan the new browser. Make this disposable
    # driver its Linux subreaper, so ownership survives the upstream restart.
    libc = ctypes.CDLL(None, use_errno=True)
    require(libc.prctl(36, 1, 0, 0, 0) == 0, "cannot establish owned relaunch subreaper")
    bus_socket = Path(env["XDG_RUNTIME_DIR"]) / "bus"
    env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={bus_socket}"
    bus_config = root / "session.conf"
    bus_config.write_text('<busconfig><type>session</type><listen>unix:path=' + str(bus_socket)
        + '</listen><auth>EXTERNAL</auth><policy context="default">'
        + '<allow send_destination="*" eavesdrop="true"/><allow eavesdrop="true"/>'
        + '<allow own="*"/></policy></busconfig>')
    with process(["dbus-daemon", "--nofork", "--config-file=" + str(bus_config)], env,
                 root, args.evidence / "dbus.log") as bus:
        wait_for(lambda: bus_socket.exists(), "private D-Bus", timeout=20, child=bus)
        read_fd, write_fd = os.pipe()
        with (args.evidence / "xvfb.log").open("wb") as stream:
            xvfb = subprocess.Popen(["Xvfb", "-displayfd", str(write_fd), "-screen", "0",
                "1440x1000x24", "-nolisten", "tcp"], env=env, cwd=root,
                pass_fds=(write_fd,), stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
            os.close(write_fd)
            try:
                require(select.select([read_fd], [], [], 20)[0], "Xvfb did not allocate display")
                display = os.read(read_fd, 64).decode().strip()
                require(display.isdigit(), "Xvfb failed; see xvfb.log")
                env["DISPLAY"] = ":" + display
                with socket.socket() as sock:
                    sock.bind(("127.0.0.1", 0))
                    cdp_port = sock.getsockname()[1]
                endpoint = f"http://127.0.0.1:{cdp_port}"
                argv = [args.legcord / "bin/legcord", "--disable-gpu", "--lang=en-US",
                        "--remote-debugging-address=127.0.0.1", f"--remote-debugging-port={cdp_port}"]
                browser_executable = None
                def detached_browsers():
                    verified = {}
                    if browser_executable is None:
                        return verified
                    for entry in Path('/proc').iterdir():
                        if not entry.name.isdigit():
                            continue
                        try:
                            if entry.joinpath('exe').resolve() != browser_executable:
                                continue
                            command = entry.joinpath('cmdline').read_bytes().split(b'\0')
                            if os.fsencode(args.legcord / 'share/legcord') not in command:
                                continue
                            variables = dict(part.split(b'=', 1) for part in
                                entry.joinpath('environ').read_bytes().split(b'\0') if b'=' in part)
                            if variables.get(b'HOME') != os.fsencode(env['HOME']) or variables.get(
                                    b'XDG_CONFIG_HOME') != os.fsencode(env['XDG_CONFIG_HOME']):
                                continue
                            # Exact executable, package argument and unique fresh
                            # HOME identify app.relaunch's detached browser. No
                            # host process is admitted by CDP role alone.
                            verified.update(descendants(int(entry.name)))
                        except (OSError, ValueError):
                            continue
                    return verified
                def app_owned():
                    excluded = {os.getpid(), *descendants(bus.pid), *descendants(xvfb.pid)}
                    owned = {pid: info for pid, info in descendants(os.getpid()).items() if pid not in excluded}
                    owned.update(detached_browsers())
                    return owned
                with process(argv, env, root, args.evidence / "electron-first.log", app_owned) as child:
                    wait_for(lambda: Path(f'/proc/{child.pid}/exe').resolve().name == 'electron',
                             'wrapper exec into pinned Electron browser', child=child)
                    browser_executable = Path(f'/proc/{child.pid}/exe').resolve()
                    require(browser_executable.is_relative_to('/gnu/store'), 'browser executable outside Guix store')
                    previous_browser = onboarding(endpoint, child, env, args.evidence, app_owned)
                    generation = wait_browser_generation(endpoint, app_owned, previous_browser,
                                                         'actual Launch Legcord replacement browser')
                    dump(args.evidence / 'first-browser-generation.json', generation)
                    wire, first = logged_out(endpoint, env, args.evidence, app_owned, "first-login",
                                             hold_seconds=args.hold_seconds)
                    try:
                        wire.evaluate("window.legcord.settings.setConfig('automaticUpdates', true)")
                        wait_for(lambda: settings_value(env, {"automaticUpdates": True}),
                                 "inherited automatic-update preference saved through actual IPC")
                    finally:
                        wire.close()
                    previous_browser = http_json(endpoint + '/json/version')['webSocketDebuggerUrl']
                # Independent cold launch, same private HOME, not merely a live
                # frontend state echo. No bypass-setup or seeded settings used.
                with process(argv, env, root, args.evidence / "electron-relaunch.log", app_owned):
                    generation = wait_browser_generation(endpoint, app_owned, previous_browser,
                                                         'independent cold-launch browser')
                    dump(args.evidence / 'cold-browser-generation.json', generation)
                    dismiss_update_guidance(env, root, args.evidence, app_owned)
                    wire, final = logged_out(endpoint, env, args.evidence, app_owned, "relaunch-login",
                                             automatic_updates=True, hold_seconds=args.hold_seconds)
                    try:
                        dump(args.evidence / "inspection.json", {"cdp_url": endpoint,
                             "display": env["DISPLAY"],
                             "target_id": final["target_id"], "hold_seconds": args.hold_seconds,
                             "live_until_epoch": time.time() + args.hold_seconds})
                        print(f"Actual Legcord ready; CDP {endpoint}; screenshot {args.evidence / 'relaunch-login.png'}", flush=True)
                        if args.hold_seconds:
                            time.sleep(args.hold_seconds)
                    finally:
                        wire.close()
                dump(args.evidence / "report.json", {"legcord": str(args.legcord), "source_commit": PIN,
                     "onboarding": "onboarding.json", "cold_relaunch": "relaunch-login.json",
                     "inherited_automatic_updates": "update-dialog.json; relaunch-login.json",
                     "nar_evidence": "legcord-nar-before.txt and legcord-nar-after.txt (shell finalizer)",
                     "credentials": "none; fresh HOME and explicit environment allowlist",
                     "discord_login_performed": False, "messages_sent": 0,
                     "post_login_settings_verified": False, "live_audio_call_verified": False,
                     "guix_update_guidance": "guix-update.json; onboarding.json",
                     "argv": list(map(str, argv))})
            finally:
                os.close(read_fd)
                stop_owned(descendants(xvfb.pid))
                xvfb.wait(timeout=10)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--legcord", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--hold-seconds", type=int, default=0)
    args = parser.parse_args()
    require(args.hold_seconds >= 0, "hold seconds must be nonnegative")
    require(os.geteuid() != 0, "Electron sandbox requires an ordinary non-root user")
    require(shutil.which("Xvfb") and shutil.which("dbus-daemon"), "pure test tools missing")
    immutable(args.legcord)
    with tempfile.TemporaryDirectory(prefix="legcord-acceptance-") as temporary:
        root = Path(temporary)
        acceptance(args, root, environment(root))
    print("Legcord native onboarding/save/cold-relaunch/sandbox acceptance passed", flush=True)


if __name__ == "__main__":
    main()
