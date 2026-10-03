#!/usr/bin/env python3
"""Conventional external consumer of the installed Slim CLI and OpenCode HTTP API.

No prompts, provider credentials, mock hosts, or source-text proof assertions.
SLIM_ARTIFACTS optionally retains local logs and actual API/state evidence.
"""
import json
import os
from pathlib import Path
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request


AGENTS = {"orchestrator", "explorer", "librarian", "oracle", "designer", "fixer"}
TOOLS = {"cancel_task", "wait_for_user", "webfetch", "ast_grep_search", "ast_grep_replace"}
SKILLS = {"simplify", "codemap", "clonedeps", "deepwork", "verification-planning",
          "reflect", "oh-my-opencode-slim", "worktrees"}


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def load(path):
    return json.loads(path.read_text())


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


class ReadOnlyConfigs:
    """Use OpenCode's real Npm.install non-writable-config early return.

    The pinned host otherwise bootstraps @opencode-ai/plugin from the registry.
    This proves offline read-only configuration, not arbitrary writable setups.
    """
    def __init__(self, directories):
        self.directories = directories
        self.mounted = []

    def freeze(self):
        for directory in self.directories:
            directory.mkdir(parents=True, exist_ok=True)
            (directory / ".gitignore").touch()
            subprocess.run(["mount", "--bind", str(directory), str(directory)], check=True)
            self.mounted.append(directory)
            subprocess.run(["mount", "-o", "remount,bind,ro", str(directory)], check=True)
            require(not os.access(directory, os.W_OK), "configuration bind mount is not read-only")

    def thaw(self):
        while self.mounted:
            directory = self.mounted[-1]
            subprocess.run(["umount", str(directory)], check=True)
            self.mounted.pop()




class Host:
    def __init__(self, binary, env, project, log):
        with socket.socket() as reservation:
            reservation.bind(("127.0.0.1", 0))
            port = reservation.getsockname()[1]
        self.url = f"http://127.0.0.1:{port}"
        self.directory = str(project)
        self.log = log
        self.stream = log.open("w")
        self.process = subprocess.Popen(
            [str(binary), "serve", "--hostname", "127.0.0.1", "--port", str(port),
             "--print-logs", "--log-level", "DEBUG"],
            cwd=project, env=env, stdout=self.stream, stderr=subprocess.STDOUT,
            start_new_session=True)
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def request(self, route, body=None):
        separator = "&" if "?" in route else "?"
        route += separator + urllib.parse.urlencode({"directory": self.directory})
        request = urllib.request.Request(
            self.url + route, data=None if body is None else json.dumps(body).encode(),
            headers={"Content-Type": "application/json"})
        with self.opener.open(request, timeout=5) as response:
            return json.load(response)

    def ready(self):
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            require(self.process.poll() is None, "OpenCode exited before becoming healthy")
            try:
                health = self.request("/global/health")
                if health.get("healthy") is True:
                    return health
            except (OSError, urllib.error.URLError):
                pass
            time.sleep(0.2)
        raise AssertionError("OpenCode did not become healthy in 60 seconds")

    def stop(self):
        if self.process.poll() is None:
            os.killpg(self.process.pid, signal.SIGTERM)
            try:
                self.process.wait(timeout=8)
            except subprocess.TimeoutExpired:
                os.killpg(self.process.pid, signal.SIGKILL)
                self.process.wait(timeout=5)
        self.stream.close()


def companion_native(binary):
    wrapper = binary.resolve()
    return wrapper.with_name(".oh-my-opencode-slim-companion-real").resolve()


def stop_owned_companion(storage, binary):
    """The plugin detaches its GUI child; kill only its isolated, verified PID."""
    pidfile = storage / "companion.pid"
    if not pidfile.exists():
        return
    try:
        pid = int(pidfile.read_text().strip())
        actual = Path(f"/proc/{pid}/exe").resolve(strict=True)
        if actual == companion_native(binary):
            os.kill(pid, signal.SIGTERM)
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline and Path(f"/proc/{pid}/exe").exists():
                time.sleep(0.1)
            if Path(f"/proc/{pid}/exe").exists():
                if Path(f"/proc/{pid}/exe").resolve(strict=True) == companion_native(binary):
                    os.kill(pid, signal.SIGKILL)
    except (ValueError, FileNotFoundError, ProcessLookupError):
        pass


def run_cli(command, env, project, destination):
    try:
        result = subprocess.run(command, cwd=project, env=env, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=90)
    except subprocess.TimeoutExpired as error:
        captured = error.stdout or b""
        destination.write_text(captured.decode(errors="replace") if isinstance(captured, bytes) else captured)
        raise
    destination.write_text(result.stdout)
    require(result.returncode == 0, f"CLI failed ({result.returncode}): {command}")
    return result.stdout


def main():
    require(len(sys.argv) == 4, "internal usage: helper PACKAGE_OUTPUT OPENCODE_OUTPUT COMPANION_OUTPUT")
    signal.signal(signal.SIGTERM, lambda _signal, _frame: sys.exit(143))
    signal.signal(signal.SIGHUP, lambda _signal, _frame: sys.exit(129))
    subprocess.run(["mount", "--make-rprivate", "/"], check=True)
    subprocess.run(["ip", "link", "set", "lo", "up"], check=True)
    package, opencode, companion_output = map(Path, sys.argv[1:])
    cli = package / "bin/oh-my-opencode-slim"
    host_binary = opencode / "bin/opencode"
    require(os.access(cli, os.X_OK), "installed Slim CLI is not executable")
    require(os.access(host_binary, os.X_OK), "installed OpenCode is not executable")
    artifacts = Path(os.environ["SLIM_ARTIFACTS"]).absolute() if os.environ.get("SLIM_ARTIFACTS") else None
    if artifacts:
        artifacts.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="oh-my-opencode-slim-consumer-") as temporary:
        scratch = Path(temporary)
        project = scratch / "project"
        config = scratch / "config/opencode"
        for name in ("home", "config/opencode", "cache", "data", "state", "runtime", "project", "tmp"):
            (scratch / name).mkdir(parents=True, exist_ok=True)
        (scratch / "runtime").chmod(0o700)
        env = {key: os.environ[key] for key in ("PATH", "LANG", "LC_ALL")
               if key in os.environ}
        env.update({
            "PATH": str(opencode / "bin") + ":" + env.get("PATH", "/usr/bin:/bin"),
            "HOME": str(scratch / "home"), "XDG_CONFIG_HOME": str(scratch / "config"),
            "XDG_CACHE_HOME": str(scratch / "cache"), "XDG_DATA_HOME": str(scratch / "data"),
            "XDG_STATE_HOME": str(scratch / "state"), "XDG_RUNTIME_DIR": str(scratch / "runtime"),
            "TMPDIR": str(scratch / "tmp"), "OPENCODE_CONFIG_DIR": str(config),
            "OPENCODE_DISABLE_AUTOUPDATE": "true", "OPENCODE_DISABLE_MODELS_FETCH": "true",
            "OPENCODE_DISABLE_DEFAULT_PLUGINS": "true", "NO_COLOR": "1",
            "OPENCODE_CONFIG_CONTENT": json.dumps({"autoupdate": False, "share": "disabled", "snapshot": False}),
        })
        for key in ("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "http_proxy", "https_proxy", "all_proxy"):
            env[key] = "http://127.0.0.1:9"
        env["NO_PROXY"] = env["no_proxy"] = "127.0.0.1,localhost"
        storage = scratch / "data/opencode/storage/oh-my-opencode-slim"
        companion = companion_output / "bin/oh-my-opencode-slim-companion"
        host = None
        readonly = ReadOnlyConfigs([config, project / ".opencode"])
        evidence = {}
        try:
            version = run_cli([str(host_binary), "--version"], env, project, scratch / "version.log").strip()
            require(version == "1.18.18", f"unexpected host version: {version}")
            run_cli([str(cli), "install", "--no-tui", "--skills=yes", "--companion=yes",
                     "--background-subagents=no", "--preset=openai"], env, project, scratch / "install.log")
            installed = load(config / "opencode.json")
            registrations = installed.get("plugin", [])
            root = package / "share/oh-my-opencode-slim"
            require(any(str(root) in (entry[0] if isinstance(entry, list) else entry)
                        for entry in registrations), "installer did not register the local store plugin")
            require(all(not (entry[0] if isinstance(entry, list) else entry).startswith("oh-my-opencode-slim")
                        for entry in registrations), "installer retained registry-based Slim registration")
            slim_path = config / "oh-my-opencode-slim.json"
            slim = load(slim_path)
            require(slim.get("preset") == "openai" and "openai" in slim.get("presets", {}), "openai preset missing")
            require(slim.get("companion", {}).get("enabled") is True, "real installer did not enable companion")
            require(os.access(companion, os.X_OK), "packaged store companion is not executable")
            for skill in sorted(SKILLS):
                content = (config / "skills" / skill / "SKILL.md").read_text()
                require(f"name: {skill}" in content, f"installed skill identity is wrong: {skill}")
            doctor = json.loads(run_cli([str(cli), "doctor", "--json"], env, project, scratch / "doctor.json"))
            require(doctor.get("ok") is True and doctor.get("presetCheck") == {"preset": "openai", "ok": True},
                    "installed configuration failed real doctor")
            require(any(row.get("scope") == "user" and row.get("exists") and row.get("ok")
                        for row in doctor.get("configs", [])), "doctor did not read installed user configuration")
            # Keep the actual installer registration and provider preset. Disable only
            # unsolicited updates and external MCPs; never replace a provider.
            slim.update({"autoUpdate": False, "disabled_mcps": ["context7", "gh_grep"]})
            save(slim_path, slim)
            readonly.freeze()
            host = Host(host_binary, env, project, scratch / "opencode.log")
            evidence["health"] = host.ready()
            require(evidence["health"].get("version") == "1.18.18", "running host version differs from pinned CLI")
            agents = host.request("/agent")
            tools = host.request("/experimental/tool/ids")
            effective = host.request("/config")
            require(effective.get("default_agent") == "orchestrator", "plugin did not make orchestrator default")
            by_name = {row["name"]: row for row in agents}
            require(AGENTS <= by_name.keys(), f"host lacks plugin agents: {AGENTS - by_name.keys()}")
            require(by_name["orchestrator"].get("mode") == "primary", "orchestrator is not a primary agent")
            require(all(by_name[name].get("mode") == "subagent" for name in AGENTS - {"orchestrator"}),
                    "specialists are not real host subagents")
            require(TOOLS <= set(tools), f"host lacks plugin tools: {TOOLS - set(tools)}")
            require(not effective.get("mcp"), "external MCPs remain enabled")
            session = host.request("/session", {"title": "Guix Slim local consumer proof"})
            require(session.get("id", "").startswith("ses_"), "host did not create a real local session")
            require(host.request("/session/" + session["id"]).get("id") == session["id"],
                    "created session could not be read back")
            require(host.request("/session/" + session["id"] + "/message") == [],
                    "local session unexpectedly contains model turns")
            state_path = storage / "companion-state.json"
            deadline = time.monotonic() + 10
            while not state_path.exists() and time.monotonic() < deadline:
                time.sleep(0.1)
            state = load(state_path)
            require(state.get("version") == 1 and state.get("config", {}).get("enabled") is True,
                    "host plugin did not write enabled companion state")
            owner = next((row for row in state.get("sessions", []) if row.get("pid") == host.process.pid), None)
            require(owner is not None and owner.get("session_id") == f"proc_{host.process.pid}"
                    and owner.get("cwd") == str(project) and owner.get("active_agents") == ["intro"]
                    and owner.get("status") == "idle", "companion state is not produced by the live plugin")
            save(scratch / "companion-state.json", state)
            evidence.update({"config": effective, "agents": agents, "tools": tools, "session": session})
            stop_owned_companion(storage, companion)
            host.stop()
            host = None
            readonly.thaw()
            # A real project-local plugin override must change the host-visible
            # agent, not merely be accepted by the configuration parser.
            marker = "Guix project-local explorer override"
            save(project / ".opencode/oh-my-opencode-slim.json",
                 {"agents": {"explorer": {"temperature": 0.123, "description": marker}}})
            run_cli([str(cli), "doctor", "--json"], env, project, scratch / "override-doctor.json")
            readonly.freeze()
            host = Host(host_binary, env, project, scratch / "override-opencode.log")
            host.ready()
            overridden = {row["name"]: row for row in host.request("/agent")}
            require(overridden["explorer"].get("temperature") == 0.123
                    and overridden["explorer"].get("description") == marker,
                    "project-local Slim override did not affect the actual host agent")
            require(by_name["explorer"].get("description") != marker,
                    "override proof did not establish a before/after difference")
            evidence["overridden_explorer"] = overridden["explorer"]
            save(scratch / "host-result.json", evidence)
            print(json.dumps({"package": str(package), "opencode_version": version,
                              "default_agent": effective["default_agent"], "agents": sorted(AGENTS),
                              "tools": sorted(TOOLS), "skills": sorted(SKILLS),
                              "companion_state": "real plugin-produced idle state",
                              "project_override": True, "prompts_sent": 0}))
        except BaseException:
            for log in sorted(scratch.glob("*.log")):
                print(f"\n--- {log.name} ---\n{log.read_text(errors='replace')}", file=sys.stderr)
            raise
        finally:
            # The GUI child is detached; terminate only the isolated verified PID
            # before graceful host exit can remove its ownership pidfile.
            stop_owned_companion(storage, companion)
            if host:
                host.stop()
            readonly.thaw()
            if artifacts:
                for path in scratch.iterdir():
                    if path.is_file():
                        shutil.copy2(path, artifacts / path.name)


if __name__ == "__main__":
    main()
