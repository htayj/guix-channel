#!/usr/bin/env python3
"""Companion to hermes-desktop-smoke.sh; consumes realized store outputs only.

The outer pure Python supervises fresh state. It re-enters hermes-python (without
-I, because the installed wrapper intentionally supplies PYTHONPATH) for native
imports, actual backend and CDP. No host env, provider key, fake backend, model
completion or bootstrap bypass is used. Evidence survives; disposable HOME does
not. --hold-seconds retains the real renderer's CDP endpoint for manual inspection.
"""
import argparse
import base64
import contextlib
import importlib
import io
import json
import os
from pathlib import Path
import select
import shutil
import re
import signal
import socket
import stat
import subprocess
import sys
import tempfile
import time
import urllib.request


PIN = "f97608f178d1ffeca59860195ab7da295f7c8e5f"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def dump(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def environment(root):
    env = {"PATH": os.environ["PATH"], "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8",
           "PYTHONNOUSERSITE": "1", "PYTHONDONTWRITEBYTECODE": "1",
           "HF_HUB_OFFLINE": "1", "TRANSFORMERS_OFFLINE": "1",
           "DO_NOT_TRACK": "1"}
    for name, leaf in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                       ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                       ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                       ("TMPDIR", "tmp"), ("HERMES_HOME", "hermes")):
        directory = root / leaf
        directory.mkdir(mode=0o700)
        env[name] = str(directory)
    return env


def immutable(root):
    require(root.is_absolute() and root.parent == Path("/gnu/store"),
            f"expected exact /gnu/store output: {root}")
    require(root.is_dir(), f"missing output: {root}")
    for item in (root, *root.rglob("*")):
        mode = item.lstat().st_mode
        if stat.S_ISREG(mode) or stat.S_ISDIR(mode):
            require(not mode & 0o222, f"writable store member: {item}")


def owned_processes(owner):
    table = {}
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            # comm may contain spaces or parentheses: numeric fields begin
            # only after its final ')'. starttime prevents PID-reuse mistakes.
            fields = entry.joinpath("stat").read_text().rsplit(")", 1)[1].split()
            table[int(entry.name)] = {"state": fields[0], "parent": int(fields[1]),
                                      "group": int(fields[2]), "start": fields[19]}
        except (OSError, ValueError, IndexError):
            continue
    owned = {pid for pid, info in table.items() if pid == owner or info["group"] == owner}
    while True:
        descendants = {pid for pid, info in table.items() if info["parent"] in owned}
        if descendants <= owned:
            return {pid: table[pid] for pid in owned}
        owned |= descendants


def stop_owned(child):
    captured = owned_processes(child.pid)
    handles = {}
    try:
        for pid, info in captured.items():
            fd = None
            try:
                fd = os.pidfd_open(pid)
                # Identity could change between snapshot and pidfd_open.
                fields = Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
                if fields[19] != info["start"]:
                    os.close(fd)
                    continue
                handles[pid] = fd
            except (ProcessLookupError, FileNotFoundError):
                if fd is not None:
                    os.close(fd)
                continue
        for fd in handles.values():
            with contextlib.suppress(ProcessLookupError):
                signal.pidfd_send_signal(fd, signal.SIGTERM)
        # Waiting for the browser leader alone misses backend children which
        # still flush/write HOME. pidfds track detached descendants as well.
        pending = list(handles.values())
        deadline = time.monotonic() + 10
        while pending and time.monotonic() < deadline:
            exited, _, _ = select.select(pending, [], [], 0.2)
            pending = [fd for fd in pending if fd not in exited]
        for fd in pending:
            with contextlib.suppress(ProcessLookupError):
                signal.pidfd_send_signal(fd, signal.SIGKILL)
        if pending:
            exited, _, _ = select.select(pending, [], [], 10)
            require(len(exited) == len(pending), "owned descendants did not exit after SIGKILL")
        child.wait(timeout=10)
    finally:
        for fd in handles.values():
            os.close(fd)


@contextlib.contextmanager
def process(argv, env, cwd, log):
    with log.open("wb") as stream:
        child = subprocess.Popen(list(map(str, argv)), env=env, cwd=cwd,
                                 stdin=subprocess.DEVNULL, stdout=stream,
                                 stderr=subprocess.STDOUT, start_new_session=True)
        try:
            yield child
        finally:
            # Only descendants/groups of this spawned process; pidfds prevent
            # signaling reused PIDs or unrelated host services/credential agents.
            stop_owned(child)
            # Upstream diagnostics may echo local backend URLs. Retain errors,
            # not even disposable auth values, in the saved evidence logs.
            text = log.read_text(errors="replace")
            text = re.sub(r'([?&](?:token|ticket|internal)=)[^\s&"\'<>]+', r'\1[redacted]', text)
            token = env.get("HERMES_DASHBOARD_SESSION_TOKEN")
            if token:
                text = text.replace(token, "[redacted]")
            log.write_text(text)


def wait_for(callback, child, description, timeout=120):
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
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
    with urllib.request.urlopen(url, timeout=2) as response:
        return json.load(response)


class Wire:
    def __init__(self, url, *, protocol):
        import websocket
        # Suppress Origin instead of weakening Chromium's origin restrictions.
        self.ws = websocket.create_connection(url, timeout=30, suppress_origin=True)
        self.sequence = 0
        require(protocol in {"jsonrpc", "cdp"}, f"unsupported wire protocol: {protocol}")
        self.protocol = protocol

    def call(self, method, params=None):
        self.sequence += 1
        ident = self.sequence
        request = {"id": ident, "method": method, "params": params or {}}
        # Chromium CDP rejects the JSON-RPC version member; Hermes requires it.
        if self.protocol == "jsonrpc":
            request["jsonrpc"] = "2.0"
        self.ws.send(json.dumps(request))
        while True:
            response = json.loads(self.ws.recv())
            if response.get("id") == ident:
                require("error" not in response, f"{method}: {response.get('error')}")
                return response["result"]

    def evaluate(self, expression):
        value = self.call("Runtime.evaluate", {"expression": expression,
            "awaitPromise": True, "returnByValue": True})
        require("exceptionDetails" not in value, f"renderer exception: {value}")
        return value.get("result", {}).get("value")

    def close(self):
        self.ws.close()


def native(evidence):
    # These imports load compiled extension dependencies, not merely metadata.
    names = ("av", "PIL._imaging", "pillow_heif", "_pillow_heif", "ctranslate2",
             "sherpa_onnx", "sherpa_onnx.lib._sherpa_onnx", "tflite_runtime.interpreter",
             "tflite_runtime._pywrap_tensorflow_interpreter_wrapper", "onnxruntime",
             "numpy", "scipy", "tokenizers", "sounddevice", "openwakeword", "pvporcupine")
    modules = {name: importlib.import_module(name) for name in names}
    import numpy as np
    import av
    from PIL import Image
    import pillow_heif
    image = Image.fromarray(np.full((16, 16, 3), [30, 80, 140], dtype=np.uint8))
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    buffer.seek(0)
    require(Image.open(buffer).getpixel((0, 0)) == (30, 80, 140), "Pillow PNG roundtrip")
    frame = av.VideoFrame.from_ndarray(np.zeros((16, 16, 3), dtype=np.uint8), format="rgb24")
    require(frame.reformat(format="yuv420p").width == 16, "PyAV native conversion")
    # Real libheif encode/decode exercises the source-built wrapper and codecs.
    heif = pillow_heif.from_pillow(image)
    heif_path = evidence / "native.heic"
    heif.save(heif_path, quality=80)
    require(pillow_heif.open_heif(heif_path).size == image.size, "HEIF native roundtrip")
    import ctranslate2
    require("float32" in ctranslate2.get_supported_compute_types("cpu"), "CTranslate2 CPU ABI")
    from tflite_runtime.interpreter import Interpreter
    # Construction crosses the NumPy/C-extension boundary (an import alone misses
    # the common NumPy 1.x-vs-2.x ABI mismatch). No model is bundled or downloaded.
    try:
        Interpreter(model_content=b"invalid-local-smoke-model")
    except ValueError as error:
        tflite_error = str(error)
    else:
        raise RuntimeError("TFLite accepted invalid model")
    from sherpa_onnx.lib._sherpa_onnx import FeatureExtractorConfig
    # Same native class used by Sherpa's public KeywordSpotter wrapper.
    sherpa_config = FeatureExtractorConfig(sampling_rate=16000, feature_dim=80)
    require(sherpa_config.sampling_rate == 16000 and sherpa_config.feature_dim == 80,
            "Sherpa native feature configuration")
    from tools.wake_word_engines import _OpenWakeWordEngine, _SherpaKwsEngine, _PorcupineEngine
    missing = []
    for engine, cfg, setting in (
        (_OpenWakeWordEngine, {"openwakeword": {"inference_framework": "onnx"}}, "wake_word.openwakeword.model"),
        (_SherpaKwsEngine, {}, "wake_word.sherpa.model_dir"),
        (_PorcupineEngine, {}, "PORCUPINE_ACCESS_KEY")):
        try:
            instance = engine(cfg)
        except RuntimeError as error:
            message = str(error)
            require(setting in message, f"missing wake asset not actionable: {message}")
            missing.append({"engine": engine.__name__, "error": message})
        else:
            instance.close()
            raise RuntimeError(f"wake engine unexpectedly armed without user assets: {engine.__name__}")
    # An explicitly synthetic, process-local key lets the real Porcupine guard
    # reach the licensed-file check. It never reaches pvporcupine.create/network.
    os.environ["PORCUPINE_ACCESS_KEY"] = "local-acceptance-invalid-not-a-credential"
    try:
        try:
            _PorcupineEngine({"porcupine": {"keyword": str(evidence / "missing.ppn")}})
        except RuntimeError as error:
            require("wake_word.porcupine.keyword" in str(error) and "not found" in str(error),
                    f"missing licensed Porcupine asset not actionable: {error}")
            missing.append({"engine": "Porcupine missing keyword asset", "error": str(error)})
        else:
            raise RuntimeError("Porcupine accepted absent licensed keyword asset")
    finally:
        del os.environ["PORCUPINE_ACCESS_KEY"]
    dump(evidence / "native.json", {"imports": {name: getattr(module, "__file__", None)
        for name, module in modules.items()}, "media_roundtrips": ["png", "heif", "av-rgb-yuv"],
        "tflite_invalid_model_error": tflite_error, "wake_missing_assets": missing,
        "live_wake_verified": False, "model_calls": 0})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--backend", type=Path, required=True)
    parser.add_argument("--desktop", default="")
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--hold-seconds", type=int, default=0)
    parser.add_argument("--inside", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if not args.inside:
        immutable(args.backend)
        if args.desktop:
            immutable(Path(args.desktop))
        with tempfile.TemporaryDirectory(prefix="hermes-acceptance-") as temporary:
            root = Path(temporary)
            env = environment(root)
            result = subprocess.run([str(args.backend / "bin/hermes-python"), "-B",
                str(Path(__file__).resolve()), "--inside", *sys.argv[1:]], env=env,
                cwd=root, check=False)
            require(result.returncode == 0, f"isolated acceptance exited {result.returncode}")
        return
    native(args.evidence)
    backend_acceptance(args)
    if args.desktop:
        desktop_acceptance(args)
    dump(args.evidence / "report.json", {"backend": str(args.backend), "desktop": args.desktop,
         "source_commit": PIN, "model_calls": 0, "live_wake_verified": False,
         "native": "native.json", "backend_evidence": "backend.json",
         "desktop_evidence": "desktop.json" if args.desktop else None,
         "nar_evidence": "*-nar-before.txt and *-nar-after.txt (shell finalizer)",
         "credential_source": "none; fresh HOME and explicit environment allowlist"})
    print("Hermes native/backend" + ("/Electron" if args.desktop else "") + " acceptance passed", flush=True)


def backend_acceptance(args):
    import secrets
    import yaml
    env = os.environ.copy()  # Already the helper-created allowlisted environment.
    token = secrets.token_urlsafe(32)  # Disposable local credential; never printed.
    env["HERMES_DASHBOARD_SESSION_TOKEN"] = token
    chosen = port()
    base = f"http://127.0.0.1:{chosen}"
    config = Path(env["HERMES_HOME"]) / "config.yaml"
    config.write_text("display:\n  tui_theme: auto\nmcp_servers: {}\n")
    with process([args.backend / "bin/hermes", "serve", "--isolated", "--host",
                  "127.0.0.1", "--port", str(chosen)], env, Path.cwd(),
                 args.evidence / "serve.log") as child:
        health = wait_for(lambda: http_json(base + "/api/health"), child, "headless health")
        require(health.get("ok") is True, f"unhealthy headless serve: {health}")
        request = urllib.request.Request(base + "/api/host/identity",
            headers={"X-Hermes-Session-Token": token})
        with urllib.request.urlopen(request, timeout=10) as response:
            identity = json.load(response)
        require(identity.get("role") == "serve" and identity.get("servesSpa") is False,
                f"not a headless backend: {identity}")
        wire = Wire(f"ws://127.0.0.1:{chosen}/api/ws?token={token}", protocol="jsonrpc")
        try:
            ready = json.loads(wire.ws.recv())
            require(ready.get("params", {}).get("type") == "gateway.ready", f"no ready event: {ready}")
            require(wire.call("gateway.ping").get("ok") is True, "gateway ping failed")
            original = wire.call("config.get", {"key": "theme"})
            saved = wire.call("config.set", {"key": "theme", "value": "light"})
            require(saved.get("value") == "light", f"config save failed: {saved}")
            require(wire.call("config.get", {"key": "theme"}).get("value") == "light",
                    "config.get did not observe saved theme")
            require(yaml.safe_load(config.read_text())["display"]["tui_theme"] == "light",
                    "RPC config did not persist to temporary writable home")
            wire.call("config.set", {"key": "theme", "value": original["value"]})
        finally:
            wire.close()
        request = urllib.request.Request(base + "/api/hermes/update", data=b"{}", method="POST",
            headers={"X-Hermes-Session-Token": token, "Content-Type": "application/json"})
        with urllib.request.urlopen(request, timeout=10) as response:
            refusal = json.load(response)
        require(refusal.get("ok") is False and refusal.get("pid") is None
                and refusal.get("error") == "guix_update_unsupported"
                and "guix" in refusal.get("update_command", "").lower(),
                f"update was not refused by actual Guix admission API: {refusal}")
        dump(args.evidence / "backend.json", {"health": health, "identity": identity,
            "gateway_ready": ready, "config_roundtrip": {"key": "theme", "saved": "light",
            "restored": original["value"], "persisted": True}, "update_refusal": refusal,
            "transport": "actual hermes serve /api/ws", "model_calls": 0})


def desktop_acceptance(args):
    env = os.environ.copy()
    user_data = Path(env["XDG_CONFIG_HOME"]) / "desktop"
    user_data.mkdir()
    env["HERMES_DESKTOP_USER_DATA_DIR"] = str(user_data)
    env["HERMES_DESKTOP_IGNORE_EXISTING"] = "1"
    env["HERMES_DESKTOP_SKIP_QUIT_CONFIRM"] = "1"
    # Seed only the passive read-only notification cache, not any renderer,
    # backend, installation marker or readiness state. Not an update claim.
    now = int(time.time() * 1000)
    dump(user_data / "update-check-cache.json", {"fetchedAt": now, "currentSha": PIN,
        "branch": "main", "status": {"supported": True, "branch": "main",
        "currentSha": PIN, "behind": 0, "updateAvailable": False, "commits": []}})
    bus_socket = Path(env["XDG_RUNTIME_DIR"]) / "bus"
    env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={bus_socket}"
    bus_config = Path(env["TMPDIR"]) / "session.conf"
    bus_config.write_text('<busconfig><type>session</type><listen>unix:path=' + str(bus_socket)
        + '</listen><auth>EXTERNAL</auth><policy context="default">'
        + '<allow send_destination="*" eavesdrop="true"/><allow eavesdrop="true"/>'
        + '<allow own="*"/></policy></busconfig>')
    require(os.geteuid() != 0, "Electron sandbox requires an ordinary non-root user")
    require(shutil.which("Xvfb") and shutil.which("dbus-daemon"), "pure test tools missing")
    with process(["dbus-daemon", "--nofork", "--config-file=" + str(bus_config)],
                 env, Path.cwd(), args.evidence / "dbus.log") as bus:
        wait_for(lambda: bus_socket.exists(), bus, "private D-Bus", timeout=20)
        # Xvfb chooses an unused private display and reports it through a pipe.
        read_fd, write_fd = os.pipe()
        with (args.evidence / "xvfb.log").open("wb") as log:
            xvfb = subprocess.Popen(["Xvfb", "-displayfd", str(write_fd), "-screen", "0",
                "1440x1000x24", "-nolisten", "tcp"], env=env, cwd=Path.cwd(),
                pass_fds=(write_fd,), stdout=log, stderr=subprocess.STDOUT,
                start_new_session=True)
            os.close(write_fd)
            try:
                require(select.select([read_fd], [], [], 20)[0], "Xvfb did not allocate display")
                display = os.read(read_fd, 64).decode().strip()
                require(display.isdigit(), "Xvfb failed; see xvfb.log")
                env["DISPLAY"] = ":" + display
                cdp_port = port()
                argv = [Path(args.desktop) / "bin/hermes-desktop", "--disable-gpu",
                    "--remote-debugging-address=127.0.0.1", f"--remote-debugging-port={cdp_port}"]
                with process(argv, env, Path.cwd(), args.evidence / "electron.log") as child:
                    endpoint = f"http://127.0.0.1:{cdp_port}"
                    def target():
                        pages = http_json(endpoint + "/json/list")
                        return next((page for page in pages if page.get("type") == "page"
                            and "/share/hermes-desktop/dist/" in page.get("url", "")), None)
                    page = wait_for(target, child, "installed Electron renderer")
                    wire = Wire(page["webSocketDebuggerUrl"], protocol="cdp")
                    try:
                        wait_for(lambda: wire.evaluate("typeof window.hermesDesktop === 'object'"),
                                 child, "real preload bridge")
                        descriptor = wire.evaluate("window.hermesDesktop.getConnection()")
                        require(descriptor.get("mode") == "local", "desktop did not spawn local backend")
                        # Never persist descriptor tokens/ws URLs; use them only
                        # in memory to verify the actual Electron-owned backend.
                        base = descriptor["baseUrl"]
                        require(base.startswith("http://127.0.0.1:"), "non-loopback desktop backend")
                        require(http_json(base + "/api/health").get("ok") is True,
                                "Electron-owned backend unhealthy")
                        backend_wire = Wire(descriptor["wsUrl"], protocol="jsonrpc")
                        try:
                            ready = json.loads(backend_wire.ws.recv())
                            require(ready.get("params", {}).get("type") == "gateway.ready", "desktop gateway not ready")
                            require(backend_wire.call("gateway.ping").get("ok") is True, "desktop gateway ping failed")
                        finally:
                            backend_wire.close()
                        def boot_ready():
                            boot = wire.evaluate("window.hermesDesktop.getBootProgress()")
                            require(not boot.get("error") and not boot.get("fakeMode"), f"boot failed/fake: {boot}")
                            return boot if boot.get("phase") == "backend.ready" else None
                        boot = wait_for(boot_ready, child, "real backend boot phase")
                        wait_for(lambda: wire.evaluate("document.visibilityState === 'visible'"),
                                 child, "visible native renderer document")
                        # Fresh no-provider HOME must render actual onboarding or
                        # the composer, never call a real provider to force chat.
                        expression = """(() => {
                          const root = document.getElementById('root');
                          if (!root || !root.children.length) return false;
                          const text = root.innerText || '';
                          if (/Desktop boot failed|Reinstalling Hermes|Repair Hermes/.test(text)) return false;
                          const composer = document.querySelector('textarea,[contenteditable="true"]');
                          const onboarding = /Choose.*provider|Choose.*Provider|API key|Sign in/.test(text);
                          if (!composer && !onboarding) return false;
                          if (!onboarding) {
                            let node = document.elementFromPoint(innerWidth/2, innerHeight/2);
                            if (!node) return false;
                            while (node) {
                              const rect = node.getBoundingClientRect();
                              if (getComputedStyle(node).position === 'fixed' && rect.left <= 0 &&
                                  rect.top <= 0 && rect.right >= innerWidth && rect.bottom >= innerHeight) return false;
                              node = node.parentElement;
                            }
                          }
                          return {surface: onboarding ? 'no-provider-onboarding' : 'composer',
                            title: document.title, url: location.href, text: text.slice(0,12000),
                            width: innerWidth, height: innerHeight};
                        })()"""
                        dom = wait_for(lambda: wire.evaluate(expression), child, "real application DOM")
                        require(dom["width"] >= 800 and dom["height"] >= 500, "renderer viewport too small")
                        # Main-process apply IPC must return instructions, without
                        # updater subprocess, in-place store mutation or network.
                        manual = wire.evaluate("window.hermesDesktop.updates.apply({})")
                        require(manual.get("manual") is True and manual.get("command") ==
                            "guix upgrade hermes-desktop", f"desktop update not package-managed: {manual}")
                        require(wire.evaluate("typeof window.require === 'undefined' && typeof process === 'undefined'"),
                                "renderer Node isolation disabled")
                        version = http_json(endpoint + "/json/version")
                        browser_wire = Wire(version["webSocketDebuggerUrl"], protocol="cdp")
                        try:
                            processes = browser_wire.call("SystemInfo.getProcessInfo")["processInfo"]
                            sandbox = renderer_sandbox(child.pid, processes)
                        finally:
                            browser_wire.close()
                        require(sandbox, "no sandboxed Electron renderer found; never retry with --no-sandbox")
                        capture = wire.call("Page.captureScreenshot", {"format": "png", "captureBeyondViewport": False})
                        screenshot = args.evidence / "desktop.png"
                        screenshot.write_bytes(base64.b64decode(capture["data"]))
                        from PIL import Image
                        with Image.open(screenshot) as image:
                            require(image.width >= 800 and image.height >= 500, "screenshot too small")
                            require(len(image.convert("RGB").getcolors(image.width * image.height) or []) > 10,
                                    "screenshot is blank/flat")
                        dump(args.evidence / "desktop.json", {"dom": dom, "boot": boot,
                            "backend": {"base_url": base, "gateway_ready": ready, "mode": "local"},
                            "manual_update": manual, "renderer_sandbox": sandbox,
                            "screenshot": str(screenshot), "cdp_url": endpoint,
                            "passive_update_cache": "synthetic fresh cache; not upstream version verification",
                            "model_calls": 0, "argv": list(map(str, argv))})
                        dump(args.evidence / "inspection.json", {"cdp_url": endpoint,
                            "target_id": page["id"], "screenshot": str(screenshot),
                            "hold_seconds": args.hold_seconds, "live_until_epoch": time.time() + args.hold_seconds})
                        print(f"Actual Electron ready; CDP {endpoint}; screenshot {screenshot}", flush=True)
                        if args.hold_seconds:
                            time.sleep(args.hold_seconds)
                    finally:
                        wire.close()
            finally:
                os.close(read_fd)
                with contextlib.suppress(ProcessLookupError):
                    os.killpg(xvfb.pid, signal.SIGTERM)
                try:
                    xvfb.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    with contextlib.suppress(ProcessLookupError):
                        os.killpg(xvfb.pid, signal.SIGKILL)
                    xvfb.wait(timeout=10)


def renderer_sandbox(owner, processes):
    facts = []
    owned = owned_processes(owner)
    # Chromium's forked renderer retains a zygote argv on Linux. Browser CDP
    # provides actual process roles; argv substring inference is insufficient.
    for process_info in processes:
        if process_info.get("type") != "renderer":
            continue
        pid = int(process_info["id"])
        require(pid in owned, f"CDP renderer is not an owned Electron descendant: {pid}")
        entry = Path("/proc") / str(pid)
        argv = entry.joinpath("cmdline").read_bytes().decode().split("\0")
        require("--no-sandbox" not in argv, "Electron disabled sandbox internally")
        status = entry.joinpath("status").read_text()
        require("Seccomp:\t2" in status and "NoNewPrivs:\t1" in status,
                f"renderer {pid} has no seccomp/no-new-privileges sandbox")
        facts.append({"pid": pid, "role": "renderer", "identity_source": "browser CDP SystemInfo",
                      "seccomp": 2, "no_new_privs": 1})
    return facts




if __name__ == "__main__":
    main()
