#!/usr/bin/env python3
"""Optional built-Desktop TLS acceptance; see hermes-desktop-tls.sh.

Public remote discovery is real, unauthenticated and read-only. Local fixture
servers test PKI, not Hermes authentication or backend functionality. No
certificate override, host trust/profile write, provider or vault access occurs.
"""
import argparse
import base64
import contextlib
import hashlib
import http.server
import importlib.util
import json
import os
from pathlib import Path
import re
import secrets
import select
import shutil
import socket
import ssl
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse

# Keep lifecycle, CDP framing, process ownership and sandbox assertions identical
# to broad acceptance without changing that test or running its main().
spec = importlib.util.spec_from_file_location("hermes_smoke", Path(__file__).with_name("hermes-desktop-smoke.py"))
smoke = importlib.util.module_from_spec(spec)
spec.loader.exec_module(smoke)
require, dump = smoke.require, smoke.dump


class Wire(smoke.Wire):
    """Retain CDP network evidence which the broad smoke deliberately discards."""
    def __init__(self, url):
        super().__init__(url, protocol="cdp")
        self.events = []

    def call(self, method, params=None):
        self.sequence += 1
        ident = self.sequence
        self.ws.send(json.dumps({"id": ident, "method": method, "params": params or {}}))
        while True:
            response = json.loads(self.ws.recv())
            if response.get("id") == ident:
                require("error" not in response, f"{method}: {response.get('error')}")
                return response["result"]
            if response.get("method", "").startswith(("Network.", "Log.")):
                self.events.append(response)

    def network(self, start, url):
        ids = set()
        facts = []
        for event in self.events[start:]:
            method, data = event["method"], event.get("params", {})
            request_url = data.get("request", {}).get("url") or data.get("url")
            if request_url == url:
                ids.add(data.get("requestId"))
            response = data.get("response", {})
            if response.get("url") == url:
                ids.add(data.get("requestId"))
        for event in self.events[start:]:
            method, data = event["method"], event.get("params", {})
            if method == "Log.entryAdded":
                entry = data.get("entry", {})
                text = entry.get("text", "")
                if entry.get("source") == "network" and (entry.get("url") == url or url in text):
                    facts.append({"event": method, "source": "network", "error": text,
                                  "level": entry.get("level")})
                continue
            response = data.get("response", {})
            if data.get("requestId") not in ids:
                continue
            # Never save headers, cookies, frames or query credentials.
            if method in {"Network.responseReceived", "Network.webSocketHandshakeResponseReceived"}:
                facts.append({"event": method, "status": response.get("status"),
                              "securityState": response.get("securityState"),
                              "protocol": response.get("protocol")})
            elif method == "Network.responseReceivedExtraInfo":
                facts.append({"event": method, "status": data.get("statusCode")})
            elif method in {"Network.loadingFailed", "Network.webSocketFrameError"}:
                error_key = "errorMessage" if method == "Network.webSocketFrameError" else "errorText"
                facts.append({"event": method, "error": data.get(error_key),
                              "blockedReason": data.get("blockedReason")})
        return facts


def command(argv, log):
    with log.open("ab") as stream:
        subprocess.run(list(map(str, argv)), check=True, stdin=subprocess.DEVNULL,
                       stdout=stream, stderr=subprocess.STDOUT)


def certificates(root, evidence):
    """Critical /32 anchor constraints; fixture private keys never leave tmp."""
    log = evidence / "fixture-openssl.log"
    for name, constrained in (("constrained", True), ("untrusted", False)):
        config = root / f"{name}.cnf"
        config.write_text("[req]\nprompt=no\ndistinguished_name=dn\nx509_extensions=ca\n"
            f"[dn]\nCN=Hermes TLS acceptance {name}\n[ca]\n"
            "basicConstraints=critical,CA:true\nkeyUsage=critical,keyCertSign,cRLSign\n"
            "subjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid:always\n" +
            ("nameConstraints=critical,permitted;IP:127.0.0.1/255.255.255.255\n" if constrained else ""))
        command(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-sha256",
                 "-days", "2", "-config", config, "-keyout", root / f"{name}.key",
                 "-out", root / f"{name}.crt"], log)
    for index, (name, issuer, ips) in enumerate((
            ("permitted", "constrained", ["127.0.0.1"]),
            ("outside", "constrained", ["127.0.0.2"]),
            ("extra-san", "constrained", ["127.0.0.1", "127.0.0.2"]),
            ("wrong-name", "constrained", []),
            ("untrusted", "untrusted", ["127.0.0.1"]))):
        key, csr, cert = (root / f"leaf-{name}.{ext}" for ext in ("key", "csr", "crt"))
        extension = root / f"leaf-{name}.cnf"
        extension.write_text("basicConstraints=critical,CA:false\nkeyUsage=critical,digitalSignature,keyEncipherment\n"
            "extendedKeyUsage=serverAuth\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid,issuer\n"
            "subjectAltName=" + (",".join("IP:" + ip for ip in ips) if ips else "DNS:wrong-name.invalid") + "\n")
        command(["openssl", "req", "-new", "-newkey", "rsa:2048", "-nodes", "-sha256",
                 "-subj", "/CN=Hermes TLS fixture", "-keyout", key, "-out", csr], log)
        command(["openssl", "x509", "-req", "-in", csr, "-CA", root / f"{issuer}.crt",
                 "-CAkey", root / f"{issuer}.key", "-set_serial", str(index + 1),
                 "-days", "2", "-sha256", "-extfile", extension, "-out", cert], log)
        shutil.copyfile(cert, evidence / cert.name)
    shutil.copyfile(root / "constrained.crt", evidence / "fixture-ca.crt")


class Server(http.server.ThreadingHTTPServer):
    daemon_threads = True


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *_args):
        pass

    def do_GET(self):
        path = urllib.parse.urlsplit(self.path).path
        if path == "/api/ws" and self.headers.get("Upgrade", "").lower() == "websocket":
            self.server.facts.append({"path": path, "upgrade": True})
            key = self.headers["Sec-WebSocket-Key"]
            accept = base64.b64encode(hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest()).decode()
            self.send_response(101)
            self.send_header("Upgrade", "websocket")
            self.send_header("Connection", "Upgrade")
            self.send_header("Sec-WebSocket-Accept", accept)
            self.end_headers()
            # A real RFC6455 upgrade/frame, NOT a mock of the Desktop runtime.
            payload = b'{"jsonrpc":"2.0","method":"gateway.event","params":{"type":"gateway.ready"}}'
            self.wfile.write(bytes([0x81, len(payload)]) + payload)
            self.wfile.flush()
            with contextlib.suppress(OSError):
                self.connection.settimeout(5)
                self.connection.recv(4096)
            self.close_connection = True
            return
        self.server.facts.append({"path": path, "upgrade": False,
            "generated_token_header": self.headers.get("X-Hermes-Session-Token") == self.server.token})
        body = json.dumps({"ok": True, "version": "tls-fixture", "auth_required": False}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        if path == "/api/status" and getattr(self.server, "next_certificate", None):
            cert, key = self.server.next_certificate
            self.server.socket.context.load_cert_chain(cert, key)
            self.server.next_certificate = None
        self.wfile.write(body)


@contextlib.contextmanager
def fixture(root, name, host, token):
    server = Server((host, 0), Handler)
    server.facts, server.token = [], token
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(root / f"leaf-{name}.crt", root / f"leaf-{name}.key")
    server.socket = context.wrap_socket(server.socket, server_side=True)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield server, f"https://{host}:{server.server_port}"
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=10)


def renderer_http(wire, base):
    url = base + "/api/status"
    start = len(wire.events)
    result = wire.evaluate("""(async () => {
      try {
        const r = await fetch(%s, {credentials:'omit', cache:'no-store', signal:AbortSignal.timeout(12000)});
        return {ok:true, status:r.status, type:r.type};
      } catch(e) { return {ok:false, error:String(e)}; }
    })()""" % json.dumps(url))
    wire.call("Runtime.evaluate", {"expression": "0"})
    return {"fetch": result, "network": wire.network(start, url)}


def renderer_ws(wire, base):
    url = "wss:" + base.removeprefix("https:") + "/api/ws"
    start = len(wire.events)
    result = wire.evaluate("""new Promise(resolve => {
      const ws = new WebSocket(%s); let opened=false, settled=false;
      const finish = value => { if(settled) return; settled=true; clearTimeout(timer); resolve(value); ws.close(); };
      const timer=setTimeout(() => finish({opened, outcome:'timeout'}), 12000);
      ws.onopen=() => { opened=true; };
      ws.onmessage=() => finish({opened, outcome:'frame'});
      ws.onerror=() => finish({opened, outcome:'error'});
      ws.onclose=e => finish({opened, outcome:'close', code:e.code});
    })""" % json.dumps(url))
    wire.call("Runtime.evaluate", {"expression": "0"})
    return {"websocket": result, "network": wire.network(start, url)}


def check_case(wire, label, base, positive, token=None, remote=False):
    probe = wire.evaluate("window.hermesDesktop.probeConnectionConfig(%s)" % json.dumps(base))
    require(probe.get("reachable") is positive, f"{label}: public probe unexpected: {probe}")
    http = renderer_http(wire, base)
    ws = renderer_ws(wire, base)
    statuses = [fact.get("status") for fact in http["network"] if fact.get("status")]
    ws_statuses = [fact.get("status") for fact in ws["network"] if fact.get("status")]
    if positive:
        require(http["fetch"].get("status") == 200 or (remote and 200 in statuses),
                f"{label}: renderer HTTPS has no HTTP200 evidence: {http}")
        if remote and not (ws["websocket"].get("opened") or any(code in (401, 403) for code in ws_statuses)):
            require(ws["websocket"].get("outcome") in {"error", "close"},
                    f"{label}: renderer WSS timed out; no TLS evidence: {ws}")
            ws["native_netlog_required"] = True
        else:
            require(ws["websocket"].get("opened") or any(code in (401, 403) for code in ws_statuses),
                    f"{label}: renderer WSS has neither upgrade nor HTTP auth rejection: {ws}")
    else:
        require(not http["fetch"].get("ok") and not statuses, f"{label}: renderer HTTP accepted invalid certificate: {http}")
        require(not ws["websocket"].get("opened") and not ws_statuses, f"{label}: renderer WSS accepted invalid certificate: {ws}")
        require("ERR_CERT" in json.dumps(http["network"]),
                f"{label}: HTTP failure lacks Chromium certificate verdict: {http}")
        # Chromium redacts the certificate suffix in renderer WS diagnostics.
        # Preserve the raw evidence; do not invent a verdict. Require actual
        # network failure, not timeout, and zero server requests (caller checks)
        # alongside HTTP's typed cert failure and the permitted WSS control.
        require(ws["websocket"].get("outcome") in {"error", "close"},
                f"{label}: renderer WSS did not report rejection: {ws}")
        require(any(f.get("event") == "Network.webSocketFrameError" or
                    (f.get("event") == "Log.entryAdded" and f.get("level") == "error")
                    for f in ws["network"]),
                f"{label}: renderer WSS rejection lacks observed network error: {ws}")
        require("CERT" in str(probe.get("error", "")).upper(), f"{label}: main probe failure not a certificate verdict: {probe}")
    test = None
    if not remote:
        payload = {"mode": "remote", "remoteUrl": base, "remoteAuthMode": "token", "remoteToken": token}
        # Return just the supported IPC verdict, never the payload/token.
        test = wire.evaluate("""(async () => { try {
          return await window.hermesDesktop.testConnectionConfig(%s);
        } catch(e) { return {ok:false,error:String(e)}; } })()""" % json.dumps(payload))
        if isinstance(test.get("error"), str) and token:
            test["error"] = test["error"].replace(token, "[redacted]")
        require(test.get("ok") is positive, f"{label}: supported two-leg test unexpected: {test}")
        if not positive:
            require("CERT" in str(test.get("error", "")).upper(),
                    f"{label}: supported test failed without certificate verdict: {test}")
    return {"label": label, "base_url": base, "expected_accept": positive,
            "public_probe": probe, "supported_connection_test": test, "renderer_http": http, "renderer_ws": ws}


def main_ws_negative(wire, root, token, cert_name):
    # Main Test remote must reach its WSS leg, rather than fail in HTTP first.
    # The status connection sees the permitted cert; every NEW TLS handshake
    # after status sees the bad cert. Main's isolated WS session must reject it.
    with fixture(root, "permitted", "127.0.0.1", token) as (server, base):
        server.next_certificate = (root / f"leaf-{cert_name}.crt", root / f"leaf-{cert_name}.key")
        payload = {"mode": "remote", "remoteUrl": base, "remoteAuthMode": "token", "remoteToken": token}
        result = wire.evaluate("""(async () => { try {
          return await window.hermesDesktop.testConnectionConfig(%s);
        } catch(e) { return {ok:false,error:String(e)}; } })()""" % json.dumps(payload))
        error = str(result.get("error", "")).replace(token, "[redacted]")
        require(result.get("ok") is False and "live WebSocket" in error,
                f"main WSS {cert_name}: did not reject in WS leg: {error}")
        # Chromium's generic renderer error may win the race with webRequest's
        # detailed net::ERR_CERT event. TLS rejection is evidenced by the bad
        # certificate switch, a failed WS leg and zero HTTP upgrade requests.
        require(any(f.get("generated_token_header") for f in server.facts), "main WSS test did not reach HTTP status")
        require(not any(f.get("upgrade") for f in server.facts), "main WSS accepted invalid certificate")
        return {"label": "main-wss-" + cert_name, "expected_accept": False,
                "error": error, "requests": server.facts, "fixture": "certificate changes after HTTP status"}


def desktop(args, root):
    env = os.environ.copy()
    user_data = Path(env["XDG_CONFIG_HOME"]) / "desktop"
    user_data.mkdir()
    env.update(HERMES_DESKTOP_USER_DATA_DIR=str(user_data), HERMES_DESKTOP_IGNORE_EXISTING="1",
               HERMES_DESKTOP_SKIP_QUIT_CONFIRM="1")
    dump(user_data / "update-check-cache.json", {"fetchedAt": int(time.time() * 1000), "currentSha": smoke.PIN,
        "branch": "main", "status": {"supported": True, "branch": "main", "currentSha": smoke.PIN,
        "behind": 0, "updateAvailable": False, "commits": []}})
    bus_socket = Path(env["XDG_RUNTIME_DIR"]) / "bus"
    env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={bus_socket}"
    bus_config = root / "session.conf"
    bus_config.write_text('<busconfig><type>session</type><listen>unix:path=' + str(bus_socket) +
        '</listen><auth>EXTERNAL</auth><policy context="default"><allow send_destination="*" eavesdrop="true"/>'
        '<allow eavesdrop="true"/><allow own="*"/></policy></busconfig>')
    require(os.geteuid() != 0, "run as ordinary user; never use --no-sandbox")
    with smoke.process(["dbus-daemon", "--nofork", "--config-file=" + str(bus_config)], env, root, args.evidence / "dbus.log") as bus:
        smoke.wait_for(lambda: bus_socket.exists(), bus, "private D-Bus", timeout=20)
        read_fd, write_fd = os.pipe()
        with (args.evidence / "xvfb.log").open("wb") as log:
            xvfb = subprocess.Popen(["Xvfb", "-displayfd", str(write_fd), "-screen", "0", "1440x1000x24", "-nolisten", "tcp"],
                env=env, pass_fds=(write_fd,), stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            os.close(write_fd)
            try:
                require(select.select([read_fd], [], [], 20)[0], "Xvfb did not allocate display")
                display = os.read(read_fd, 64).decode().strip()
                require(display.isdigit(), "Xvfb failed")
                env["DISPLAY"] = ":" + display
                endpoint = f"http://127.0.0.1:{smoke.port()}"
                argv = [args.desktop / "bin/hermes-desktop", "--disable-gpu", "--remote-debugging-address=127.0.0.1",
                        "--remote-debugging-port=" + endpoint.rsplit(":", 1)[1]]
                # Default omits sensitive headers. Keep raw NetLog in disposable
                # state (query tokens can still exist), export only status facts.
                netlog = root / "chromium-netlog.json"
                argv.extend(["--log-net-log=" + str(netlog), "--net-log-capture-mode=Default"])
                with smoke.process(argv, env, root, args.evidence / "electron.log") as child:
                    def target():
                        return next((p for p in smoke.http_json(endpoint + "/json/list") if p.get("type") == "page"
                            and "/share/hermes-desktop/dist/" in p.get("url", "")), None)
                    page = smoke.wait_for(target, child, "built Desktop renderer")
                    wire = Wire(page["webSocketDebuggerUrl"])
                    try:
                        wire.call("Network.enable")
                        wire.call("Log.enable")
                        smoke.wait_for(lambda: wire.evaluate("typeof window.hermesDesktop?.probeConnectionConfig === 'function'"),
                                       child, "supported probe preload")
                        require(wire.evaluate("typeof window.require === 'undefined' && typeof process === 'undefined'"),
                                "renderer Node isolation disabled")
                        version = smoke.http_json(endpoint + "/json/version")
                        browser = smoke.Wire(version["webSocketDebuggerUrl"], protocol="cdp")
                        try:
                            sandbox = smoke.renderer_sandbox(child.pid, browser.call("SystemInfo.getProcessInfo")["processInfo"])
                        finally:
                            browser.close()
                        require(sandbox, "no sandboxed renderer; never weaken sandbox")
                        cases = []
                        def save(value):
                            cases.append(value)
                            dump(args.evidence / "cases.json", cases)
                        token = secrets.token_urlsafe(32)  # fixture-only, no credential lookup or persistence
                        with contextlib.ExitStack() as stack:
                            fixtures = []
                            for name, host, label, accepted in (
                                    ("wrong-name", "127.0.0.1", "wrong-hostname", False),
                                    ("outside", "127.0.0.2", "outside-ip", False),
                                    ("extra-san", "127.0.0.1", "outside-additional-san", False),
                                    ("untrusted", "127.0.0.1", "untrusted-chain", False),
                                    ("permitted", "127.0.0.1", "permitted-ip", True)):
                                server, base = stack.enter_context(fixture(root, name, host, token))
                                fixtures.append((label, server))
                                save(check_case(wire, label, base, accepted, token=token))
                                if accepted:
                                    require(any(f.get("generated_token_header") for f in server.facts),
                                            "supported HTTP leg omitted generated fixture token")
                                    require(sum(bool(f.get("upgrade")) for f in server.facts) >= 2,
                                            "fixture did not observe separate main and renderer WSS upgrades")
                                else:
                                    require(not server.facts, f"{label}: rejected TLS unexpectedly reached HTTP/WS handler")
                            dump(args.evidence / "fixture-requests.json", {label: server.facts for label, server in fixtures})
                        for bad_certificate in ("wrong-name", "outside", "extra-san", "untrusted"):
                            save(main_ws_negative(wire, root, token, bad_certificate))
                        save(check_case(wire, "real-remote", args.remote, True, remote=True))
                        dump(args.evidence / "report.json", {"desktop": str(args.desktop), "backend": str(args.backend),
                            "remote": args.remote, "ca_sha256": hashlib.sha256(args.ca.read_bytes()).hexdigest(),
                            "renderer_sandbox": sandbox, "cases": "cases.json", "model_calls": 0,
                            "credential_source": "none; generated local fixture token only",
                            "trust": "two CAs in disposable HOME/.pki/nssdb; untrusted fixture root not imported",
                            "limits": ["remote unauthenticated; auth rejection is TLS evidence, not gateway.ready",
                                       "local fixture upgrades are TLS/RFC6455 evidence, not actual backend acceptance",
                                       "separate main WSS negatives swap certificate after successful status HTTP",
                                       "remote CORS failure accepted only with CDP HTTP200; no security override"]})
                        dump(args.evidence / "inspection.json", {"cdp_url": endpoint, "target_id": page["id"],
                            "user_data": str(user_data), "home": env["HOME"], "pid": child.pid,
                            "display": env["DISPLAY"], "session_bus": env["DBUS_SESSION_BUS_ADDRESS"],
                            "hold_seconds": args.hold_seconds, "live_until_epoch": time.time() + args.hold_seconds})
                        print(f"TLS fixture/public discovery checks passed; remote WSS native evidence finalizes after exit; isolated CDP {endpoint}; hold {args.hold_seconds}s", flush=True)
                        if args.hold_seconds:
                            time.sleep(args.hold_seconds)
                        # SIGTERM skips Electron's NetLog flush. Ask the actual
                        # browser to shut down normally before lifecycle cleanup.
                        shutdown = smoke.Wire(version["webSocketDebuggerUrl"], protocol="cdp")
                        try:
                            import websocket
                            try:
                                shutdown.call("Browser.close")
                            except websocket.WebSocketConnectionClosedException:
                                # The browser may close CDP before sending its
                                # response. A bounded process wait proves exit.
                                pass
                            child.wait(timeout=30)
                        finally:
                            shutdown.close()
                    finally:
                        wire.close()
                finalize_netlog(args, netlog)
            finally:
                os.close(read_fd)
                smoke.stop_owned(xvfb)


def finalize_netlog(args, path):
    # Browser process shutdown flushes a complete native NetLog. Do not parse
    # an unfinished stream or attribute an unrelated connection's HTTP status.
    data = json.loads(path.read_text())
    names = {value: key for key, value in data["constants"]["logEventTypes"].items()}
    events = data["events"]
    ws_url = "wss:" + args.remote.removeprefix("https:") + "/api/ws"
    urls = {ws_url, args.remote + "/api/ws"}
    seeds, dependencies = set(), {}
    for event in events:
        source = event["source"]["id"]
        params = event.get("params", {})
        if params.get("url") in urls:
            seeds.add(source)
        dependency = params.get("source_dependency", {})
        if isinstance(dependency, dict) and "id" in dependency:
            dependencies.setdefault(source, set()).add(dependency["id"])
    linked = set(seeds)
    while True:
        expanded = linked | {child for owner in linked for child in dependencies.get(owner, ())}
        if expanded == linked:
            break
        linked = expanded
    facts = []
    source_names = {value: key for key, value in data["constants"].get("logSourceType", {}).items()}
    diagnostic = []
    for event in events:
        source = event["source"]
        params = event.get("params", {})
        name = names.get(event["type"], str(event["type"]))
        if source["id"] not in linked and params.get("url") not in urls:
            continue
        item = {"event": name, "source_id": source["id"], "phase": event.get("phase"),
                "source_type": source_names.get(source.get("type"), source.get("type")),
                "parameter_keys": sorted(params)}
        if params.get("url") in urls:
            item["exact_remote_ws_url"] = True
        dependency = params.get("source_dependency", {})
        if isinstance(dependency, dict) and "id" in dependency:
            item["dependency_id"] = dependency["id"]
            item["dependency_type"] = source_names.get(dependency.get("type"), dependency.get("type"))
        # Only numeric status/error and status lines, never full headers or URLs.
        for key in ("net_error", "response_code", "status_code"):
            if isinstance(params.get(key), int):
                item[key] = params[key]
        headers = params.get("headers", [])
        if isinstance(headers, str):
            headers = headers.splitlines()
        item["http_status_lines"] = [h for h in headers if isinstance(h, str)
                                     and h.startswith("HTTP/") and len(h.split()) >= 2
                                     and h.split()[1].isdigit()]
        diagnostic.append(item)
    dump(args.evidence / "netlog-diagnostic.json", {"exact_sources": sorted(seeds),
         "linked_sources": sorted(linked), "events": diagnostic})
    for event in events:
        if event["source"]["id"] not in linked:
            continue
        name = names.get(event["type"], str(event["type"]))
        params = event.get("params", {})
        if name == "WEBSOCKET_UPGRADE_FAILURE":
            # Chromium's WS stream can discard response headers while retaining
            # the exact native upgrade refusal. Extract status, never raw text
            # which might include query credentials from another request.
            message = params.get("message", "")
            match = re.fullmatch(r"Error during WebSocket handshake: Unexpected response code: ([0-9]{3})", message)
            if match:
                facts.append({"event": name, "source_id": event["source"]["id"],
                              "status": int(match.group(1)), "evidence": "native exact handshake-refusal message"})
            continue
        if "READ_RESPONSE_HEADERS" not in name:
            continue
        headers = params.get("headers", [])
        if isinstance(headers, str):
            headers = headers.splitlines()
        for header in headers:
            fields = header.split()
            if len(fields) >= 2 and fields[0].startswith("HTTP/") and fields[1].isdigit():
                facts.append({"event": name, "source_id": event["source"]["id"],
                              "status": int(fields[1])})
    cases = json.loads((args.evidence / "cases.json").read_text())
    remote = next(case for case in cases if case["label"] == "real-remote")
    remote["renderer_ws"]["native_netlog"] = {"url": ws_url, "exact_url_sources": sorted(seeds),
                                             "response_statuses": facts, "capture_mode": "Default"}
    dump(args.evidence / "cases.json", cases)
    if remote["renderer_ws"].get("native_netlog_required"):
        require(seeds and any(f["status"] in (101, 401, 403) for f in facts),
                f"real remote WSS lacks linked native HTTP upgrade/auth status: {facts}")
    print("Hermes built Desktop TLS acceptance passed", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for option in ("desktop", "backend", "ca", "evidence"):
        parser.add_argument("--" + option, type=Path, required=True)
    parser.add_argument("--remote", required=True)
    parser.add_argument("--hold-seconds", type=int, default=0)
    parser.add_argument("--inside", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()
    parsed = urllib.parse.urlsplit(args.remote)
    require(parsed.scheme == "https" and parsed.hostname and not parsed.username and not parsed.password
            and not parsed.query and not parsed.fragment and parsed.path in ("", "/"),
            "remote must be a credential-free HTTPS origin")
    args.remote = args.remote.rstrip("/")
    require(args.hold_seconds >= 0, "hold-seconds must be nonnegative")
    if not args.inside:
        smoke.immutable(args.desktop)
        smoke.immutable(args.backend)
        require(args.ca.is_file(), "CA file missing")
        require(args.evidence.is_absolute(), "evidence must be absolute")
        args.evidence.mkdir(parents=True, exist_ok=True)
        require(not any(args.evidence.iterdir()), "evidence must be empty")
        # Guix NSS's bin output installs tools at the profile root, not bin/.
        # Resolve in the outer pure Guix environment before HOME is isolated.
        certutil = shutil.which("certutil")
        if not certutil:
            profile = os.environ.get("GUIX_ENVIRONMENT")
            require(profile, "certutil not in PATH and GUIX_ENVIRONMENT unavailable")
            candidate = Path(profile) / "certutil"
            require(candidate.is_file() and os.access(candidate, os.X_OK),
                    "NSS certutil missing from pure profile root; select NSS bin output")
            certutil = str(candidate)
        with tempfile.TemporaryDirectory(prefix="hermes-tls-") as temporary:
            root = Path(temporary)
            env = smoke.environment(root)
            certificates(root, args.evidence)
            nss = Path(env["HOME"]) / ".pki/nssdb"
            nss.mkdir(parents=True, mode=0o700)
            log = args.evidence / "nss.log"
            command([certutil, "-N", "-d", "sql:" + str(nss), "--empty-password"], log)
            for name, ca in (("remote-acceptance", args.ca), ("constrained-fixture", root / "constrained.crt")):
                command([certutil, "-A", "-d", "sql:" + str(nss), "-n", name, "-t", "C,,", "-i", ca], log)
            command([certutil, "-L", "-d", "sql:" + str(nss)], log)
            result = subprocess.run([str(args.backend / "bin/hermes-python"), "-B", str(Path(__file__).resolve()),
                                     "--inside", *sys.argv[1:]], cwd=root, env=env, check=False)
            require(result.returncode == 0, f"isolated TLS acceptance exited {result.returncode}")
        return
    for tool in ("Xvfb", "dbus-daemon"):
        require(shutil.which(tool), f"missing tool {tool}")
    desktop(args, Path.cwd())


if __name__ == "__main__":
    main()
