#!/usr/bin/env python3
"""Offline installed Notty consumer proof; launched by notty-smoke.sh only."""

import fcntl
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


class Session:
    def __init__(self, consumer, backend, environment, scratch, evidence, pyte):
        self.backend = backend
        self.evidence = evidence
        # Notty uses ESC E (NEL), which moves down AND returns to column 1.
        # pyte 0.8 dispatches NEL as LF, incorrectly making CR conditional on
        # LNM.  Correct that event rather than changing captured bytes or
        # weakening the image geometry assertions.  LF retains its semantics.
        class AnsiScreen(pyte.Screen):
            def next_line(self):
                self.index()
                self.carriage_return()

        class AnsiByteStream(pyte.ByteStream):
            escape = dict(pyte.ByteStream.escape, E="next_line")
            events = pyte.ByteStream.events | {"next_line"}

        self.screen = AnsiScreen(40, 12)
        self.parser = AnsiByteStream(self.screen)
        self.raw = bytearray()
        self.capture = (evidence / (backend + ".raw")).open("wb")
        self.master, self.slave = pty.openpty()
        fcntl.ioctl(self.slave, termios.TIOCSWINSZ, struct.pack("HHHH", 12, 40, 0, 0))
        self.original = termios.tcgetattr(self.slave)
        self.consumer_report = evidence / (backend + "-consumer.json")

        def controlling_terminal():
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        self.process = subprocess.Popen(
            [str(consumer), backend, str(self.consumer_report)], cwd=scratch,
            env=environment, stdin=self.slave, stdout=self.slave, stderr=self.slave,
            start_new_session=True, preexec_fn=controlling_terminal)
        self.inputs = []
        self.snapshots = []

    def read(self, timeout):
        ready, _, _ = select.select([self.master], [], [], timeout)
        if ready:
            chunk = os.read(self.master, 65536)
            require(chunk, "PTY closed before consumer completion")
            self.raw.extend(chunk)
            self.capture.write(chunk)
            self.capture.flush()
            self.parser.feed(chunk)
            return True
        return False

    def wait(self, predicate, description):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            self.read(0.05)
            if predicate():
                return
            require(self.process.poll() is None,
                    "consumer exited waiting for " + description + "\n" + self.text())
        raise RuntimeError("timed out waiting for " + description + "\n" + self.text())

    def text(self):
        return "\n".join(self.screen.display)

    def checkpoint(self, name):
        cells = [[self.screen.buffer[y][x]._asdict() for x in range(self.screen.columns)]
                 for y in range(self.screen.lines)]
        value = {"stage": name, "raw_bytes": len(self.raw), "display": self.screen.display,
                 "cells": cells}
        write_json(self.evidence / (self.backend + "-" + name + "-screen.json"), value)
        self.snapshots.append({"stage": name, "raw_bytes": len(self.raw)})

    def finish(self):
        deadline = time.monotonic() + 15
        while self.process.poll() is None:
            require(time.monotonic() < deadline, "consumer failed to exit")
            self.read(0.05)
        while self.read(0.05):
            pass
        require(self.process.returncode == 0,
                "consumer failed: " + str(self.process.returncode) + "\n" + self.text())
        require(termios.tcgetattr(self.slave) == self.original, "PTY attributes not restored")
        raw = bytes(self.raw)
        for enter, leave in ((b"\x1b[?1049h", b"\x1b[?1049l"),
                             (b"\x1b[?25l", b"\x1b[?25h")):
            require(enter in raw and leave in raw, "terminal enter/restore sequence missing")
            require(raw.rfind(leave) > raw.rfind(enter), "terminal restore before enter")
        require(not self.screen.cursor.hidden, "cursor still hidden after release")
        return json.loads(self.consumer_report.read_text())

    def close(self):
        if self.process.poll() is None:
            os.killpg(self.process.pid, signal.SIGKILL)
            self.process.wait()
        while self.read(0.05):
            pass
        self.capture.close()
        os.close(self.master)
        os.close(self.slave)
        write_json(self.evidence / (self.backend + "-inputs.json"), self.inputs)


def colors_and_geometry(session):
    lines = session.screen.display
    expected = {0: "NOTTY " + session.backend.upper(),
                1: "RED CUBE TRUE GRAY", 2: "abTOPfg", 3: "bcd", 4: "界é"}
    for y, text in expected.items():
        require(lines[y].rstrip() == text, "incorrect rendered row %d: %r" % (y, lines[y]))
    checks = [(0, 3, "red", "blue", True), (4, 8, "ff0000", "default", False),
              (9, 13, "123456", "default", False), (14, 18, "808080", "default", False)]
    evidence = []
    for start, end, fg, bg, bold in checks:
        for x in range(start, end):
            cell = session.screen.buffer[1][x]
            require((cell.fg, cell.bg, cell.bold) == (fg, bg, bold),
                    "wrong color/style at column %d: %r" % (x, cell))
        evidence.append({"columns": [start, end], "fg": fg, "bg": bg, "bold": bold})
    for x in range(2, 5):
        require(session.screen.buffer[2][x].fg == "cyan", "overlay foreground missing")
    raw = bytes(session.raw)
    require(b";31;44;1m" in raw, "ANSI red/blue/bold SGR missing")
    require(b";38;5;196m" in raw, "ANSI cube SGR missing")
    require(b";38;2;18;52;86m" in raw, "ANSI truecolor SGR missing")
    require(b";38;5;244m" in raw, "ANSI grayscale SGR missing")
    return evidence


def exercise(consumer, backend, environment, scratch, evidence, pyte):
    session = Session(consumer, backend, environment, scratch, evidence, pyte)
    try:
        session.wait(lambda: session.screen.display[7].rstrip() == "STATE ready", "initial image")
        require(session.screen.display[5].rstrip() == "SIZE 40x12", "initial size missing")
        active = termios.tcgetattr(session.slave)
        require(not (active[3] & (termios.ICANON | termios.ECHO)), "PTY did not enter raw input mode")
        color_evidence = colors_and_geometry(session)
        session.checkpoint("ready")
        fcntl.ioctl(session.slave, termios.TIOCSWINSZ, struct.pack("HHHH", 16, 52, 0, 0))
        session.screen.resize(lines=16, columns=52)
        os.kill(session.process.pid, signal.SIGWINCH)
        session.wait(lambda: session.screen.display[5].rstrip() == "SIZE 52x16"
                     and session.screen.display[7].rstrip() == "STATE resized", "resize event")
        session.checkpoint("resized")
        decoded = []
        for name, data in (("UP", b"\x1b[A"), ("DOWN", b"\x1b[B"),
                           ("LEFT", b"\x1b[D"), ("RIGHT", b"\x1b[C"), ("x", b"x")):
            os.write(session.master, data)
            decoded.append(name)
            session.inputs.append({"hex": data.hex(), "expected": name})
            expected = "EVENTS " + " ".join(decoded)
            session.wait(lambda: session.screen.display[6].rstrip() == expected, name + " decoded")
        session.checkpoint("inputs")
        # Exact contiguous captured prefix, before release exits the alternate
        # screen.  Replaying it shows the verified live surface, not a synthetic
        # rendering of the screen model.  Full capture still includes cleanup.
        live_raw = bytes(session.raw)
        (evidence / (backend + "-live.raw")).write_bytes(live_raw)
        os.write(session.master, b"q")
        session.inputs.append({"hex": "71", "expected": "q"})
        report = session.finish()
        require(report["inputs"] == decoded + ["q"], "consumer input report differs from PTY proof")
        require(report["termios_restored"], "consumer did not observe terminal restoration")
        report.update({"raw_capture": backend + ".raw", "raw_bytes": len(session.raw),
                       "live_raw_capture": backend + "-live.raw",
                       "live_raw_bytes": len(live_raw),
                       "colors": color_evidence, "snapshots": session.snapshots,
                       "parent_termios_restored": True, "cursor_restored": True,
                       "alternate_screen_restored": True})
        return report
    finally:
        session.close()


def main():
    profile, output, mount, source, directory = sys.argv[1:]
    profile, output, evidence = Path(profile), Path(output), Path(directory)
    isolation_report = isolation(mount, evidence)
    # -I ignores host Python paths; add only fresh-profile installed dependencies.
    sites = list(profile.glob("lib/python*/site-packages"))
    require(sites, "fresh profile lacks Python site-packages")
    sys.path[:0] = [str(site) for site in sites]
    import pyte

    with tempfile.TemporaryDirectory(prefix="notty-consumer-") as temporary:
        scratch = Path(temporary)
        for name in ("home", "config", "cache", "data", "state"):
            (scratch / name).mkdir()
        environment = {"PATH": str(profile / "bin"), "HOME": str(scratch / "home"),
                       "XDG_CONFIG_HOME": str(scratch / "config"),
                       "XDG_CACHE_HOME": str(scratch / "cache"),
                       "XDG_DATA_HOME": str(scratch / "data"),
                       "XDG_STATE_HOME": str(scratch / "state"), "LC_ALL": "C.UTF-8",
                       "TERM": "xterm-256color", "OCAMLPATH": str(profile / "lib/ocaml/site-lib"),
                       "C_INCLUDE_PATH": str(profile / "include"),
                       "LIBRARY_PATH": str(profile / "lib")}
        findlib = profile / "bin/ocamlfind"
        packages = {}
        for package in ("notty", "notty.unix", "notty.lwt", "notty.top"):
            result = subprocess.run([str(findlib), "query", package], env=environment,
                                    text=True, capture_output=True, check=True)
            location = Path(result.stdout.strip()).resolve()
            require(location.is_relative_to(output.resolve()),
                    package + " resolved outside selected installed output: " + str(location))
            packages[package] = str(location)
        async_query = subprocess.run([str(findlib), "query", "notty.async"], env=environment,
                                     text=True, capture_output=True)
        require(async_query.returncode != 0, "unexpected Notty Async backend")
        compiler = subprocess.run([str(profile / "bin/ocamlopt"), "-version"], env=environment,
                                  text=True, capture_output=True, check=True).stdout.strip()
        require(compiler.startswith("4.14."), "consumer compiler is not OCaml 4.14: " + compiler)
        shutil.copyfile(source, scratch / "consumer.ml")
        consumer = scratch / "consumer"
        command = [str(findlib), "ocamlopt", "-thread", "-package", "notty,notty.unix,notty.lwt",
                   "-linkpkg", "-o", str(consumer), "consumer.ml"]
        result = subprocess.run(command, cwd=scratch, env=environment, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (evidence / "compile.log").write_text(result.stdout)
        require(result.returncode == 0, "installed consumer compile/link failed; see compile.log")
        report = {"compiler": compiler, "findlib": packages, "async_backend": False,
                  "isolation": isolation_report, "sessions": []}
        for backend in ("unix", "lwt"):
            report["sessions"].append(exercise(consumer, backend, environment, scratch, evidence, pyte))
            write_json(evidence / "report.json", report)
        print("Notty Unix/Lwt: geometry, Unicode, ANSI colors, PTY resize, arrow/ASCII input and restore passed")


if __name__ == "__main__":
    main()
