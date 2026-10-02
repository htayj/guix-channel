#!/usr/bin/env python3
"""Offline installed pmatiello/tui proof; launched by tui-smoke.sh only."""

import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
from urllib.parse import unquote, urlparse
import zipfile


TEST_NAMESPACES = (
    "me.pmatiello.tui.core-test",
    "me.pmatiello.tui.internal.ansi-test",
    "me.pmatiello.tui.internal.rendering-test",
)
CORE_MEMBER = "me/pmatiello/tui/core.clj"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def isolation(mount, evidence):
    host_namespace = os.environ["HOST_NET_NS"]
    network = os.readlink("/proc/self/ns/net")
    require(network != host_namespace, "network namespace was not isolated")
    interfaces = [line.split(":", 1)[0].strip()
                  for line in Path("/proc/net/dev").read_text().splitlines() if ":" in line]
    require(interfaces == ["lo"], "unexpected network interfaces: " + repr(interfaces))
    subprocess.run([mount, "--bind", "/gnu/store", "/gnu/store"], check=True)
    subprocess.run([mount, "-o", "remount,bind,ro", "/gnu/store"], check=True)
    readonly = bool(os.statvfs("/gnu/store").f_flag & os.ST_RDONLY)
    require(readonly, "store mount is writable")
    result = {"network_namespace": network, "host_network_namespace": host_namespace,
              "interfaces": interfaces, "store_mount_read_only": readonly}
    write_json(evidence / "isolation.json", result)
    return result


def verify_installation(output, snapshot):
    jar = output / "share/java/tui.jar"
    sources = snapshot / "src"
    require(jar.is_file(), "installed tui.jar is missing")
    expected = {str(path.relative_to(sources)): path.read_bytes()
                for path in sources.rglob("*.clj")}
    require(set(expected) == {CORE_MEMBER, "me/pmatiello/tui/internal/ansi.clj",
                              "me/pmatiello/tui/internal/rendering.clj",
                              "me/pmatiello/tui/internal/specs.clj"},
            "snapshot API source set differs from pinned upstream")
    with zipfile.ZipFile(jar) as archive:
        for member, original in expected.items():
            require(archive.read(member) == original, "installed API source changed: " + member)
        require({name for name in archive.namelist() if name.endswith(".clj")} == set(expected),
                "installed jar contains unexpected Clojure sources")
    installed_tests = output / "share/tui/tests"
    original_tests = snapshot / "test"
    originals = {str(path.relative_to(original_tests)): path.read_bytes()
                 for path in original_tests.rglob("*") if path.is_file()}
    installed = {str(path.relative_to(installed_tests)): path.read_bytes()
                 for path in installed_tests.rglob("*") if path.is_file()}
    require(originals and originals == installed, "installed upstream tests are not untouched")
    return {"jar": str(jar), "api_sources": {
        member: hashlib.sha256(content).hexdigest() for member, content in expected.items()},
        "upstream_tests": str(installed_tests), "upstream_test_files": sorted(originals)}


class Session:
    def __init__(self, command, environment, scratch, evidence, pyte):
        self.command = command
        self.evidence = evidence
        self.screen = pyte.Screen(40, 16)
        self.parser = pyte.ByteStream(self.screen)
        self.raw = bytearray()
        self.capture = (evidence / "tui.raw").open("wb")
        self.master, self.slave = pty.openpty()
        fcntl.ioctl(self.slave, termios.TIOCSWINSZ, struct.pack("HHHH", 16, 40, 0, 0))
        self.original = termios.tcgetattr(self.slave)
        require(self.original[3] & termios.ICANON, "initial PTY is not cooked")
        require(self.original[3] & termios.ECHO, "initial PTY echo is disabled")
        require(self.original[6][termios.VEOF] == b"\x04", "PTY EOF is not Ctrl-D")

        def controlling_terminal():
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        self.process = subprocess.Popen(
            command, cwd=scratch, env=environment,
            stdin=self.slave, stdout=self.slave, stderr=self.slave,
            start_new_session=True, preexec_fn=controlling_terminal)
        self.inputs = []
        self.snapshots = []

    def read(self, timeout):
        ready, _, _ = select.select([self.master], [], [], timeout)
        if not ready:
            return False
        try:
            chunk = os.read(self.master, 65536)
        except OSError as error:
            if error.errno == errno.EIO and self.process.poll() is not None:
                return False
            raise
        if not chunk:
            require(self.process.poll() is not None, "PTY closed before consumer completion")
            return False
        self.raw.extend(chunk)
        self.capture.write(chunk)
        self.capture.flush()
        self.parser.feed(chunk)
        return True

    def wait(self, predicate, description):
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            self.read(0.05)
            if predicate():
                return
            require(self.process.poll() is None,
                    "consumer exited waiting for " + description + "\n" + self.text())
        raise RuntimeError("timed out waiting for " + description + "\n" + self.text())

    def text(self):
        return "\n".join(self.screen.display)

    def send(self, data, expected):
        require(os.write(self.master, data) == len(data), "short PTY input write")
        self.inputs.append({"hex": data.hex(), "expected": expected})

    def cooked(self):
        active = termios.tcgetattr(self.slave)
        require(active[3] & termios.ICANON, "consumer changed PTY to noncanonical input")
        require(active[3] & termios.ECHO, "consumer disabled cooked terminal echo")
        require(active == self.original, "consumer changed terminal attributes")

    def checkpoint(self, name):
        value = {"stage": name, "columns": 40, "rows": 16,
                 "raw_bytes": len(self.raw), "display": list(self.screen.display),
                 "cells": [[self.screen.buffer[y][x]._asdict() for x in range(40)]
                           for y in range(16)]}
        write_json(self.evidence / ("tui-" + name + "-screen.json"), value)
        self.snapshots.append({"stage": name, "raw_bytes": len(self.raw),
                               "screen": "tui-" + name + "-screen.json"})

    def finish(self):
        deadline = time.monotonic() + 30
        while self.process.poll() is None:
            require(time.monotonic() < deadline, "consumer failed to exit after EOF")
            self.read(0.05)
        while self.read(0.05):
            pass
        require(self.process.returncode == 0,
                "consumer failed: " + str(self.process.returncode) + "\n" + self.text())
        self.cooked()
        # This library is an SGR renderer with cooked line input, not a raw
        # terminal lifecycle manager. Do not require or synthesize enter/leave.
        raw = bytes(self.raw)
        for escape in (b"\x1b[?1049h", b"\x1b[?1049l", b"\x1b[?25l", b"\x1b[?25h"):
            require(escape not in raw, "unexpected terminal lifecycle escape: " + repr(escape))
        require(not self.screen.cursor.hidden, "consumer hid the cursor")

    def close(self):
        if self.process.poll() is None:
            os.killpg(self.process.pid, signal.SIGKILL)
            self.process.wait()
        while self.read(0.05):
            pass
        self.capture.close()
        os.close(self.master)
        os.close(self.slave)
        write_json(self.evidence / "tui-inputs.json", self.inputs)


def assert_rows(session, rows):
    for y, text in rows.items():
        expected = text.ljust(40)
        require(session.screen.display[y] == expected,
                "incorrect row %d: %r, expected %r" % (y, session.screen.display[y], expected))


def assert_styles(session, styled):
    for y in range(16):
        for x in range(40):
            cell = session.screen.buffer[y][x]
            expected = styled.get((y, x), ("default", "default", False, False))
            require((cell.fg, cell.bg, cell.bold, cell.underscore) == expected,
                    "incorrect color/style at (%d,%d): %r" % (x, y, cell))
            require(not (cell.italics or cell.reverse or cell.blink or cell.strikethrough),
                    "unexpected style at (%d,%d): %r" % (x, y, cell))


def exercise(command, environment, scratch, evidence, pyte, output, runtime):
    session = Session(command, environment, scratch, evidence, pyte)
    try:
        session.wait(lambda: session.screen.display[6] == "Name> ".ljust(40), "flushed Name prompt")
        border = "+" + "-" * 38 + "+"
        bodies = ("TUI installed consumer", "red on blue", "green underline", "Unicode: café λ")
        initial = {0: border, 5: border, 6: "Name> "}
        initial.update({y: "| " + text.ljust(36) + " |" for y, text in enumerate(bodies, 1)})
        initial.update({y: "" for y in range(7, 16)})
        assert_rows(session, initial)
        styles = {}
        for y, start, end, style in (
                (1, 2, 24, ("cyan", "default", True, False)),
                (2, 2, 13, ("red", "blue", False, False)),
                (3, 2, 17, ("green", "default", False, True))):
            styles.update({(y, x): style for x in range(start, end)})
        assert_styles(session, styles)
        session.cooked()
        session.checkpoint("live")
        live = bytes(session.raw)
        (evidence / "tui-live.raw").write_bytes(live)
        session.send(b"Alice\n", "read-line returns Alice with cooked echo")
        session.wait(lambda: session.screen.display[8] == "Lines (EOF to finish)> ".ljust(40),
                     "read-lines prompt")
        assert_rows(session, {6: "Name> Alice", 7: "Hello, Alice!", 8: "Lines (EOF to finish)> "})
        styles.update({(7, x): ("green", "default", True, False) for x in range(13)})
        assert_styles(session, styles)
        session.cooked()
        session.send(b"first\nsecond\n", "read-lines receives first and second")
        session.wait(lambda: session.screen.display[8] == "Lines (EOF to finish)> first".ljust(40)
                     and session.screen.display[9] == "second".ljust(40)
                     and session.screen.cursor.y == 10 and session.screen.cursor.x == 0,
                     "two cooked echoed lines and fresh EOF line")
        session.cooked()
        session.send(b"\x04", "Ctrl-D at a fresh canonical line ends read-lines")
        session.finish()
        assert_rows(session, {6: "Name> Alice", 7: "Hello, Alice!",
                              8: "Lines (EOF to finish)> first", 9: "second",
                              10: "LINES=first|second", 11: "TUI_RUNTIME_OK",
                              12: "", 13: "", 14: "", 15: ""})
        assert_styles(session, styles)
        session.checkpoint("final")
        consumer = json.loads((evidence / "tui-consumer.json").read_text())
        require(consumer["name"] == "Alice" and consumer["lines"] == ["first", "second"],
                "consumer report input differs from PTY proof")
        require(consumer["render_checks"] is True, "consumer render boundary checks did not pass")
        require(consumer["runtime_version"] == runtime["clojure"], "consumer runtime differs")
        resource = consumer["core_resource"]
        require(resource.startswith("jar:file:") and resource.endswith("!/" + CORE_MEMBER),
                "core did not load from a jar resource: " + resource)
        jar_url, member = resource[4:].split("!/", 1)
        jar = Path(unquote(urlparse(jar_url).path)).resolve()
        require(jar == (output / "share/java/tui.jar").resolve()
                and jar.is_relative_to(output.resolve()) and member == CORE_MEMBER,
                "loaded core resource is outside the selected installed tui jar")
        return {"consumer": consumer, "command": command, "exit_status": session.process.returncode,
                "raw_capture": "tui.raw", "raw_bytes": len(session.raw),
                "live_raw_capture": "tui-live.raw", "live_raw_bytes": len(live),
                "screenshot_replay": {"raw_capture": "tui-live.raw", "columns": 40, "rows": 16,
                                      "checkpoint": "Name prompt before input"},
                "screens": session.snapshots, "input": session.inputs,
                "canonical_input": True, "cooked_echo": True,
                "eof": "Ctrl-D on fresh line", "terminal_attributes_unchanged": True,
                "terminal_lifecycle_escapes": False}
    finally:
        session.close()


def main():
    profile, output, mount, source, directory, snapshot_output = sys.argv[1:]
    profile, output, evidence = Path(profile), Path(output), Path(directory)
    snapshot = Path(snapshot_output) / "share/pmatiello/projects/tui"
    isolation_report = isolation(mount, evidence)
    installation = verify_installation(output, snapshot)
    sites = list(profile.glob("lib/python*/site-packages"))
    require(sites, "fresh profile lacks Python site-packages")
    sys.path[:0] = [str(site) for site in sites]
    import pyte

    with tempfile.TemporaryDirectory(prefix="tui-consumer-") as temporary:
        scratch = Path(temporary)
        for name in ("home", "config", "cache", "data", "state", "tmp"):
            (scratch / name).mkdir()
        environment = {"PATH": str(profile / "bin"), "HOME": str(scratch / "home"),
                       "XDG_CONFIG_HOME": str(scratch / "config"),
                       "XDG_CACHE_HOME": str(scratch / "cache"),
                       "XDG_DATA_HOME": str(scratch / "data"),
                       "XDG_STATE_HOME": str(scratch / "state"), "TMPDIR": str(scratch / "tmp"),
                       "LC_ALL": "C.UTF-8", "TERM": "xterm-256color"}
        launcher = str(output / "bin/tui-clojure")
        runtime_command = [launcher, "-e", '(println (clojure-version)) '
                           '(println (System/getProperty "java.version")) '
                           '(println (System/getProperty "java.home"))']
        result = subprocess.run(runtime_command, cwd=scratch, env=environment, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (evidence / "runtime-version.log").write_text(result.stdout)
        require(result.returncode == 0, "installed launcher failed; see runtime-version.log")
        versions = result.stdout.splitlines()
        require(len(versions) == 3, "unexpected runtime version output; see runtime-version.log")
        runtime = dict(zip(("clojure", "java", "java_home"), versions))
        require(Path(runtime["java_home"]).resolve().is_relative_to(Path("/gnu/store")),
                "launcher did not use a Guix JVM")
        quoted = " ".join("'" + name for name in TEST_NAMESPACES)
        test_expression = ("(require 'clojure.test 'me.pmatiello.tui.fixtures " + quoted + ") "
                           "(let [result (clojure.test/run-tests " + quoted + ")] "
                           "(System/exit (if (zero? (+ (:fail result) (:error result))) 0 1)))")
        test_command = [launcher, "-e", test_expression]
        test_environment = dict(environment, CLASSPATH=installation["upstream_tests"])
        tests = subprocess.run(test_command, cwd=scratch, env=test_environment, text=True,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (evidence / "upstream-tests.log").write_text(tests.stdout)
        require(tests.returncode == 0, "untouched upstream tests failed; see upstream-tests.log")
        consumer = scratch / "consumer.clj"
        shutil.copyfile(source, consumer)
        shutil.copyfile(source, evidence / "consumer.clj")
        command = [launcher, str(consumer), str(evidence / "tui-consumer.json")]
        report = {"runtime": runtime, "runtime_command": runtime_command,
                  "installation": installation, "isolation": isolation_report,
                  "environment": environment, "consumer_source": str(Path(source).resolve()),
                  "consumer_location": str(consumer), "retained_consumer": "consumer.clj",
                  "upstream_tests": {"command": test_command, "environment": test_environment,
                                     "namespaces": list(TEST_NAMESPACES), "exit_status": tests.returncode,
                                     "log": "upstream-tests.log"}}
        report["session"] = exercise(command, environment, scratch, evidence, pyte, output, runtime)
        write_json(evidence / "report.json", report)
        print("TUI: installed jar, untouched upstream tests, render boundaries, geometry, Unicode, "
              "ANSI styles, cooked line input/EOF and unchanged terminal attributes passed")


if __name__ == "__main__":
    main()
