#!/usr/bin/env python3
"""Exercise the installed ECA server and installed Emacs client, without a model.

The parent resolves Guix inputs; the child runs in a fresh network namespace
with an allowlisted environment and temporary HOME/XDG/workspace directories.
The existing fake-server test is a separate client protocol unit fixture.
"""
import hashlib
import json
import os
from pathlib import Path
import queue
import shutil
import subprocess
import sys
import tempfile
import threading

ROOT = Path(__file__).resolve().parent.parent


def build(name):
    result = subprocess.check_output(
        [os.environ.get("GUIX", "guix"), "build", "-L", str(ROOT / "guix"), name],
        text=True,
    )
    return [Path(line) for line in result.splitlines() if line.startswith("/gnu/store/")]


def program(package, relative):
    for output in build(package):
        path = output / relative
        if path.exists():
            return path
    raise RuntimeError(f"{package} does not provide {relative}")


def lisp(package, feature):
    for output in build(package):
        for path in output.glob(f"share/emacs/site-lisp/**/{feature}.el*"):
            return path.parent
    raise RuntimeError(f"{package} does not provide {feature}")


def fingerprint(output):
    digest = hashlib.sha256()
    for path in sorted(output.rglob("*")):
        if path.is_file():
            digest.update(str(path.relative_to(output)).encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()


class Server:
    def __init__(self, binary, scratch):
        self.messages = queue.Queue()
        self.received = []
        self.serial = 0
        self.stderr = (scratch / "server.stderr").open("w")
        self.process = subprocess.Popen(
            [str(binary), "server"], stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=self.stderr,
        )
        threading.Thread(target=self.read_frames, daemon=True).start()

    def read_frames(self):
        try:
            while True:
                headers = {}
                while True:
                    line = self.process.stdout.readline()
                    if not line:
                        raise EOFError("ECA stdout closed")
                    if line in (b"\r\n", b"\n"):
                        break
                    key, value = line.decode("ascii").split(":", 1)
                    headers[key.lower()] = value.strip()
                length = int(headers["content-length"])
                body = self.process.stdout.read(length)
                if len(body) != length:
                    raise EOFError("Truncated JSON-RPC body")
                self.messages.put(json.loads(body))
        except Exception as error:
            self.messages.put(error)

    def send(self, method, params=None, request=True):
        message = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            message["params"] = params
        if request:
            self.serial += 1
            message["id"] = self.serial
        body = json.dumps(message).encode()
        self.process.stdin.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
        self.process.stdin.flush()
        return message.get("id")

    def until(self, predicate):
        for message in self.received:
            if predicate(message):
                return message
        while True:
            message = self.messages.get(timeout=60)
            if isinstance(message, Exception):
                raise message
            self.received.append(message)
            if predicate(message):
                return message
            if "method" in message and "id" in message:
                raise RuntimeError(f"Unexpected server request: {message}")

    def request(self, method, params=None):
        ident = self.send(method, params)
        return self.until(lambda message: message.get("id") == ident)

    def close(self):
        if self.process.poll() is None:
            self.process.kill()
        self.process.wait()
        self.stderr.close()


def isolated(output, emacs, directories, scratch):
    binary = output / "bin/eca"
    version = subprocess.check_output([str(binary), "--version"], text=True)
    assert "0.154.0" in version, version
    server = Server(binary, scratch)
    try:
        initialized = server.request("initialize", {
            "clientInfo": {"name": "guix-offline-smoke", "version": "1"},
            "capabilities": {"codeAssistant": {"chat": True,
                "chatCapabilities": {"askQuestion": True}}},
            "workspaceFolders": [{"uri": (scratch / "workspace").as_uri(), "name": "workspace"}],
        })
        assert "Welcome to ECA" in initialized["result"]["chatWelcomeMessage"], initialized
        server.send("initialized", request=False)
        config = server.until(lambda message: message.get("method") == "config/updated"
                              and "chat" in message.get("params", {}))
        assert "code" in config["params"]["chat"]["agents"], config
        commands = server.request("chat/queryCommands", {"chatId": "local", "query": "doctor"})
        assert any(command["name"] == "doctor" for command in commands["result"]["commands"]), commands
        # /doctor is a real local command, not a model response or a test echo.
        prompt = server.request("chat/prompt", {"chatId": "local", "message": "/doctor", "contexts": []})
        assert prompt["result"]["chatId"] == "local", prompt
        server.until(lambda message: message.get("method") == "chat/contentReceived"
                     and message.get("params", {}).get("chatId") == "local"
                     and "ECA" in message.get("params", {}).get("content", {}).get("text", ""))
        missing = server.request("chat/history", {"chatId": "absent"})
        assert missing["error"]["code"] == "chat_not_found", missing
        unknown = server.request("guix/nonexistent")
        assert unknown["error"]["code"] == -32601, unknown
        assert server.request("shutdown")["result"] is None
        server.send("exit", request=False)
        assert server.process.wait(timeout=20) == 0
        print("eca: initialize/welcome, capability config, local /doctor, application and JSON-RPC errors, shutdown/exit passed")
    finally:
        (scratch / "protocol.json").write_text(json.dumps(server.received, indent=2))
        server.close()
    args = [str(emacs), "--batch", "-Q"]
    for directory in directories:
        args.extend(["-L", str(directory)])
    args.extend(["-l", str(ROOT / "tests/eca-server-emacs-smoke.el"),
                 "--eval", "(eca-server-smoke-run)"])
    subprocess.run(args, check=True, timeout=90)


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--isolated":
        isolated(Path(sys.argv[2]), Path(sys.argv[3]),
                 [Path(path) for path in sys.argv[5:]], Path(sys.argv[4]))
        return
    if len(sys.argv) > 2:
        raise SystemExit("usage: eca-server-smoke.py [ECA-PACKAGE-OUTPUT]")
    output = Path(sys.argv[1]) if len(sys.argv) == 2 else build("eca")[0]
    emacs = program("emacs-minimal", "bin/emacs")
    unshare = program("util-linux", "bin/unshare")
    dirs = [lisp(package, feature) for package, feature in (
        ("eca-emacs", "eca"), ("emacs-dash", "dash"), ("emacs-s", "s"),
        ("emacs-f", "f"), ("emacs-markdown-mode", "markdown-mode"), ("emacs-compat", "compat"))]
    subprocess.run([str(unshare), "--user", "--map-root-user", "--net", "--fork", "true"], check=True)
    scratch = Path(tempfile.mkdtemp(prefix="eca-server-smoke."))
    before = fingerprint(output)
    try:
        for directory in ("home", "config", "data", "cache", "state", "runtime", "tmp", "workspace"):
            (scratch / directory).mkdir(mode=0o700)
        (scratch / "workspace/sample.txt").write_text("local editor workspace\n")
        # Replace the default plugin map with an empty sequence (an empty map
        # would deep-merge and preserve the upstream remote plugin).  Each
        # default provider's catalog fetching is disabled, without inventing
        # a provider or passing any credential to the isolated environment.
        config = {"plugins": [], "mcpServers": {}, "hooks": {},
                  "providers": {name: {"fetchModels": False} for name in
                    ("openai", "anthropic", "github-copilot", "google", "ollama")},
                  "remote": {"enabled": False}}
        environment = {
            "HOME": str(scratch / "home"), "XDG_CONFIG_HOME": str(scratch / "config"),
            "XDG_DATA_HOME": str(scratch / "data"), "XDG_CACHE_HOME": str(scratch / "cache"),
            "XDG_STATE_HOME": str(scratch / "state"), "XDG_RUNTIME_DIR": str(scratch / "runtime"),
            "TMPDIR": str(scratch / "tmp"), "PATH": str(output / "bin"),
            "LANG": "C", "ECA_CONFIG": json.dumps(config),
            "JAVA_TOOL_OPTIONS": f"-Duser.home={scratch / 'home'}",
            "ECA_SMOKE_WORKSPACE": str(scratch / "workspace"),
            "ECA_SMOKE_DIRECTORY": str(scratch),
            "OTEL_SDK_DISABLED": "true",
        }
        subprocess.run([str(unshare), "--user", "--map-root-user", "--net", "--fork",
                        sys.executable, str(Path(__file__).resolve()), "--isolated",
                        str(output), str(emacs), str(scratch), *map(str, dirs)],
                       env=environment, cwd=scratch / "workspace", check=True, timeout=180)
        assert fingerprint(output) == before, "Installed output was modified"
        print("eca + eca-emacs real offline integration passed (network namespace; no provider credentials)")
    finally:
        if os.environ.get("ECA_SMOKE_KEEP_SCRATCH"):
            print(f"ECA smoke scratch retained: {scratch}")
        else:
            shutil.rmtree(scratch)


if __name__ == "__main__":
    main()
