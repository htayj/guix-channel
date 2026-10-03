#!/usr/bin/env python3
"""Exercise installed Pi 0.84.2 CLI, RPC, persisted sessions, HTML and real TUI.

Usage: python3 tests/pi-smoke.py [STORE_OUTPUT]
GUIX selects the Guix executable; PI_SMOKE_ARTIFACTS selects a persistent
artifact parent (otherwise a fresh directory under /tmp is retained).
No prompts, model completions, provider servers or credentials are used.
"""

import argparse
import base64
import codecs
import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time

VERSION = "0.84.2"
PROVIDER = "pi-smoke-local"
MODEL = "offline-catalog-model"
NAME = "Pi native offline smoke"
FLAGS = ["--no-extensions", "--no-skills", "--no-prompt-templates",
         "--no-themes", "--no-context-files"]
SELECTION = ["--provider", PROVIDER, "--model", MODEL,
             "--api-key", "unused-local-model-metadata"]
TIMEOUT = 30


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def launch(args):
    root = Path(__file__).resolve().parent.parent
    guix = os.environ.get("GUIX", "guix")
    if args.output:
        output = Path(args.output).resolve()
    else:
        result = subprocess.run([guix, "build", "-L", str(root / "guix"),
                                 "pi-coding-agent"], text=True,
                                stdout=subprocess.PIPE, check=True)
        outputs = [Path(line) for line in result.stdout.splitlines()
                   if line.startswith("/gnu/store/") and (Path(line) / "bin/pi").is_file()]
        require(len(outputs) == 1, "build must provide exactly one output with bin/pi")
        output = outputs[0].resolve()
    require(output.parent == Path("/gnu/store") and (output / "bin/pi").is_file(),
            "expected a realized Guix store output containing bin/pi")
    parent = os.environ.get("PI_SMOKE_ARTIFACTS")
    if parent:
        Path(parent).mkdir(parents=True, exist_ok=True)
    evidence = Path(tempfile.mkdtemp(prefix="pi-smoke-", dir=parent)).resolve()
    evidence.chmod(0o700)
    shutil.copyfile(__file__, evidence / "pi-smoke.py")
    # A store item in the manifest roots its closure without resolving a second,
    # possibly conflicting package definition for an explicitly supplied output.
    manifest = evidence / "manifest.scm"
    manifest.write_text(
        '(use-modules (guix profiles) (gnu packages))\n'
        '(concatenate-manifests\n'
        ' (list (specifications->manifest \'("python" "python-pyte" "bash" "coreutils"))\n'
        '       (manifest (list (manifest-entry (name "pi-coding-agent")\n'
        f'                    (version "{VERSION}") (item {json.dumps(str(output))}))))))\n')
    command = [guix, "shell", "--container", "--no-cwd", "--pure",
               "--share=" + str(evidence) + "=/pi-smoke", "-m", str(manifest),
               "--", "python3", "/pi-smoke/pi-smoke.py", "--inside",
               "--host-net-ns", os.readlink("/proc/self/ns/net"), str(output)]
    write_json(evidence / "launch.json", {"command": command, "output": str(output)})
    print("Pi smoke artifacts: " + str(evidence), flush=True)
    result = subprocess.run(command)
    require(result.returncode == 0, "native Pi smoke failed; artifacts: " + str(evidence))


class Rpc:
    def __init__(self, command, env, work, evidence, label):
        self.buffer = bytearray()
        self.serial = 0
        self.transcript = (evidence / (label + ".jsonl")).open("w")
        self.stderr = (evidence / (label + ".stderr")).open("wb")
        self.process = subprocess.Popen(command, cwd=work, env=env,
                                        stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                        stderr=self.stderr)

    def call(self, kind, **fields):
        self.serial += 1
        request = {"id": str(self.serial), "type": kind, **fields}
        self.transcript.write(json.dumps({"direction": "in", "record": request}) + "\n")
        self.transcript.flush()
        self.process.stdin.write((json.dumps(request) + "\n").encode())
        self.process.stdin.flush()
        deadline = time.monotonic() + TIMEOUT
        while True:
            while b"\n" in self.buffer:
                line, _, rest = self.buffer.partition(b"\n")
                self.buffer = bytearray(rest)
                if not line.strip():
                    continue
                value = json.loads(line)
                self.transcript.write(json.dumps({"direction": "out", "record": value}) + "\n")
                self.transcript.flush()
                require(value.get("type") not in ("agent_start", "turn_start", "message_start"),
                        "unexpected model execution during metadata-only smoke")
                if value.get("type") == "response" and value.get("id") == request["id"]:
                    require(value.get("command") == kind and value.get("success") is True,
                            "native RPC failure: " + repr(value))
                    return value.get("data")
            remaining = deadline - time.monotonic()
            require(remaining > 0, "RPC timeout: " + kind)
            ready, _, _ = select.select([self.process.stdout], [], [], remaining)
            require(ready, "RPC timeout: " + kind)
            chunk = os.read(self.process.stdout.fileno(), 65536)
            require(chunk, "RPC closed before response: " + kind)
            self.buffer.extend(chunk)

    def finish(self):
        self.process.stdin.close()
        require(self.process.wait(timeout=TIMEOUT) == 0, "RPC normal EOF shutdown failed")

    def close(self):
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        self.process.stdout.close()
        if not self.process.stdin.closed:
            self.process.stdin.close()
        self.stderr.close()
        self.transcript.close()


class Tui:
    def __init__(self, command, env, work, evidence):
        import pyte

        self.screen = pyte.Screen(120, 80)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder("utf-8")("replace")
        self.raw = bytearray()
        self.capture = (evidence / "tui.pty").open("wb")
        self.evidence = evidence
        self.eof = False
        self.status = None
        self.inputs = []
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            try:
                os.chdir(work)
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 80, 120, 0, 0))
                os.execve(command[0], command, env)
            except BaseException:
                os._exit(127)

    def read(self, delay):
        if self.eof or not select.select([self.fd], [], [], delay)[0]:
            return
        try:
            chunk = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            chunk = b""
        if not chunk:
            self.eof = True
            return
        self.raw.extend(chunk)
        self.capture.write(chunk)
        self.capture.flush()
        self.stream.feed(self.decoder.decode(chunk))

    def text(self):
        return "\n".join(self.screen.display)

    def wait(self, predicate, description):
        deadline = time.monotonic() + TIMEOUT
        while time.monotonic() < deadline:
            self.read(0.1)
            if predicate():
                return
            require(not self.eof, "TUI closed waiting for " + description + "\n" + self.text())
        raise RuntimeError("TUI timeout waiting for " + description + "\n" + self.text())

    def send(self, value):
        self.inputs.append(value.hex())
        os.write(self.fd, value)

    def snapshot(self, name):
        (self.evidence / ("tui-" + name + ".txt")).write_text(self.text() + "\n")
        write_json(self.evidence / ("tui-" + name + ".json"),
                   {"columns": 120, "rows": 80, "display": self.screen.display,
                    "raw_bytes": len(self.raw)})

    def finish(self):
        # Ctrl+D is upstream's normal app.exit action when the editor is empty.
        self.send(b"\x04")
        deadline = time.monotonic() + TIMEOUT
        while self.status is None:
            self.read(0.1)
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
            require(time.monotonic() < deadline, "TUI failed normal Ctrl+D shutdown")
        while not self.eof:
            self.read(0.1)
            require(time.monotonic() < deadline, "TUI PTY did not close")
        require(self.status == 0, "TUI failed: " + str(self.status))

    def close(self):
        self.snapshot("final" if self.status == 0 else "failure")
        write_json(self.evidence / "tui-inputs.json", self.inputs)
        if self.status is None:
            os.kill(self.pid, signal.SIGKILL)
            _, status = os.waitpid(self.pid, 0)
            self.status = os.waitstatus_to_exitcode(status)
        os.close(self.fd)
        self.capture.close()


def inside(args):
    evidence = Path("/pi-smoke")
    output = Path(args.output)
    network = os.readlink("/proc/self/ns/net")
    interfaces = [line.split(":", 1)[0].strip()
                  for line in Path("/proc/net/dev").read_text().splitlines() if ":" in line]
    require(args.host_net_ns and network != args.host_net_ns, "network namespace not isolated")
    require(interfaces == ["lo"], "unexpected network interfaces: " + repr(interfaces))
    write_json(evidence / "isolation.json", {"host_network_namespace": args.host_net_ns,
               "network_namespace": network, "interfaces": interfaces})
    state = evidence / "private"
    for name in ("home", "config", "data", "cache", "state", "runtime", "tmp", "work", "agent", "sessions"):
        (state / name).mkdir(mode=0o700, parents=True, exist_ok=True)
    env = {"PATH": os.environ["PATH"], "HOME": str(state / "home"),
           "TERM": "xterm-256color", "LC_ALL": "C.UTF-8", "TMPDIR": str(state / "tmp"),
           "PI_CODING_AGENT_DIR": str(state / "agent"), "PI_OFFLINE": "1",
           "PI_SKIP_VERSION_CHECK": "1", "PI_TELEMETRY": "0"}
    for key, name in (("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                      ("XDG_CACHE_HOME", "cache"), ("XDG_STATE_HOME", "state"),
                      ("XDG_RUNTIME_DIR", "runtime")):
        env[key] = str(state / name)
    write_json(state / "agent/settings.json", {
        "packages": [], "extensions": [], "skills": [], "prompts": [], "themes": [],
        "enableInstallTelemetry": False, "enableAnalytics": False,
        "lastChangelogVersion": VERSION, "quietStartup": False,
        "defaultProjectTrust": "never", "compaction": {"enabled": False},
        "shellCommandPrefix": "export PI_LOCAL_PROOF=configured"})
    # Catalog metadata only. No apiKey field, no server, and no prompt operation.
    write_json(state / "agent/models.json", {"providers": {PROVIDER: {
        "baseUrl": "http://127.0.0.1:1/v1", "api": "openai-completions",
        "models": [{"id": MODEL, "name": "Offline catalog model", "reasoning": False,
                    "input": ["text"], "contextWindow": 8192, "maxTokens": 1024,
                    "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}}]}}})
    binary = output / "bin/pi"
    require(os.access(binary, os.X_OK), "installed bin/pi is not executable")
    require((output / "libexec/pi").is_dir(), "installed native assets are missing")
    work = state / "work"
    base = [str(binary), *FLAGS, *SELECTION]
    report = {"success": False, "output": str(output), "version": VERSION}
    try:
        for label, arguments in (("help", ["--help"]), ("version", ["--version"]),
                                 ("models", ["--list-models", MODEL])):
            result = subprocess.run(base + arguments, cwd=work, env=env, text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=TIMEOUT)
            (evidence / (label + ".stdout")).write_text(result.stdout)
            (evidence / (label + ".stderr")).write_text(result.stderr)
            require(result.returncode == 0, "native CLI failed: " + label + "\n" + result.stderr)
            if label == "version":
                require(result.stdout.strip() == VERSION, "unexpected native version")
            elif label == "help":
                require("--mode" in result.stdout and "--session" in result.stdout,
                        "native help lacks CLI/RPC/session options")
            else:
                require(PROVIDER in result.stdout and MODEL in result.stdout,
                        "local catalog missing from native model list")
        session_file = state / "sessions/native.jsonl"
        # Upstream initializes an explicitly supplied empty session file itself
        # (_setSessionFile). This also opts into immediate persistence without
        # inventing an assistant response to bypass lazy first-response storage.
        session_file.touch()
        command = base + ["--mode", "rpc", "--session", str(session_file),
                          "--session-dir", str(state / "sessions")]
        rpc = Rpc(command, env, work, evidence, "rpc-first")
        try:
            initial = rpc.call("get_state")
            require(initial["model"]["id"] == MODEL and initial["model"]["provider"] == PROVIDER,
                    "RPC selected a different model")
            require(not initial["isStreaming"] and initial["messageCount"] == 0,
                    "new native session is not idle/empty")
            require(rpc.call("new_session")["cancelled"] is False, "new_session cancelled")
            fresh = rpc.call("get_state")
            require(fresh["sessionId"] != initial["sessionId"] and fresh["messageCount"] == 0,
                    "new_session did not reset session identity/state")
            require(rpc.call("switch_session", sessionPath=str(session_file))["cancelled"] is False,
                    "switch_session cancelled")
            rpc.call("set_session_name", name=NAME)
            shell = "printf 'alpha:17\\nbeta:25\\n' > native-values.txt; total=0; while IFS=: read -r label number; do total=$((total + number)); done < native-values.txt; printf 'settings=%s\\nnative-sum=%s\\n' \"$PI_LOCAL_PROOF\" \"$total\"; cat native-values.txt"
            result = rpc.call("bash", command=shell)
            expected = "settings=configured\nnative-sum=42\nalpha:17\nbeta:25\n"
            require(result["exitCode"] == 0 and result["output"] == expected
                    and not result["cancelled"] and not result["truncated"],
                    "native bash did not calculate/read the local file: " + repr(result))
            require((work / "native-values.txt").read_text() == "alpha:17\nbeta:25\n",
                    "native bash file was not written")
            entries = rpc.call("get_entries")
            bash = [entry for entry in entries["entries"] if entry.get("message", {}).get("role") == "bashExecution"]
            require(len(bash) == 1 and bash[0]["message"]["output"] == expected
                    and bash[0]["message"]["command"] == shell,
                    "native session entries lost the bash operation")
            require(not any(entry.get("message", {}).get("role") == "assistant"
                            for entry in entries["entries"]), "unexpected fabricated/model assistant data")
            saved = rpc.call("get_state")
            require(saved["sessionName"] == NAME and saved["sessionId"] == initial["sessionId"],
                    "native session name/identity mismatch")
            html = evidence / "native-session.html"
            exported = rpc.call("export_html", outputPath=str(html))
            require(Path(exported["path"]) == html and html.is_file(), "native HTML export missing")
            content = html.read_text()
            embedded = re.search(r'<script id="session-data" type="application/json">([^<]+)</script>', content)
            require(embedded, "native HTML export lacks embedded session data")
            exported_data = json.loads(base64.b64decode(embedded.group(1)))
            serialized = json.dumps(exported_data)
            require("native-sum=42" in serialized and NAME in serialized
                    and "bashExecution" in serialized,
                    "native HTML export lacks real session content")
            write_json(evidence / "html-session-data.json", exported_data)
            rpc.finish()
        finally:
            rpc.close()
        disk = [json.loads(line) for line in session_file.read_text().splitlines()]
        require(disk[0]["type"] == "session" and disk[0]["id"] == saved["sessionId"],
                "native session header not persisted")
        require(disk[1:] == entries["entries"], "persisted entries differ from RPC history")
        resumed = Rpc(command, env, work, evidence, "rpc-resumed")
        try:
            restored = resumed.call("get_state")
            require(restored["sessionId"] == saved["sessionId"] and restored["sessionName"] == NAME
                    and restored["messageCount"] == saved["messageCount"],
                    "fresh native RPC process did not restore session state")
            require(resumed.call("get_entries") == entries, "fresh RPC process lost native entries/tree leaf")
            resumed.finish()
        finally:
            resumed.close()
        tui = Tui(base + ["--session", str(session_file)], env, work, evidence)
        try:
            tui.wait(lambda: VERSION in tui.text() and MODEL in tui.text()
                     and b"\x1b]0;" in tui.raw and NAME.encode() in tui.raw,
                     "native title, startup help and selected model")
            tui.snapshot("startup")
            tui.send(b"/session\r")
            tui.wait(lambda: "Session Info" in tui.text() and NAME in tui.text(), "native session panel")
            tui.snapshot("session")
            # /help is not an upstream command; /hotkeys is the real help surface.
            tui.send(b"/hotkeys\r")
            tui.wait(lambda: "Slash commands" in tui.text() and "Exit (when editor is empty)" in tui.text(),
                     "native keyboard help")
            tui.snapshot("hotkeys")
            tui.finish()
        finally:
            tui.close()
        report.update({"success": True, "sessionId": saved["sessionId"], "sessionName": NAME,
                       "bashOutput": expected, "sessionFile": str(session_file),
                       "html": str(html), "rpcRestart": True, "tuiExitStatus": tui.status})
        print("PI SMOKE OK: 0.84.2 CLI/catalog, RPC bash/session/HTML, restart, native PTY help/session and Ctrl+D")
    except BaseException as error:
        report["error"] = str(error)
        raise
    finally:
        write_json(evidence / "report.json", report)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", help="already built /gnu/store output")
    parser.add_argument("--inside", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--host-net-ns", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.inside:
        require(args.output, "internal container invocation needs installed output")
        inside(args)
    else:
        launch(args)


if __name__ == "__main__":
    main()
