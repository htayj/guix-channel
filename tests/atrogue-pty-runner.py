#!/usr/bin/env python3
"""Prove Atrogue gameplay and native screenshot persistence in isolated PTYs.

Usage: atrogue-pty-runner.py ATROGUE SCRATCH
Run inside a network namespace (see atrogue-smoke.sh). Optional
OMP_RUNTIME_RAW_CAPTURE receives verbatim live terminal bytes before quitting;
OMP_RUNTIME_NATIVE_CAPTURE receives the actual upstream screenshot file.
No dungeon save/load exists in Atrogue 0.3.0.
"""

import errno
import fcntl
import os
from pathlib import Path
import re
import select
import signal
import socket
import struct
import sys
import termios
import time


ROWS, COLS = 24, 80
VERSION = b"atrogue 0.3.0"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class Session:
    def __init__(self, executable, env, work, logging):
        self.raw = bytearray()
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            os.chdir(work)
            fcntl.ioctl(0, termios.TIOCSWINSZ,
                        struct.pack("HHHH", ROWS, COLS, 0, 0))
            args = [executable, "--colors=off", "--scr-width=80",
                    "--scr-height=24", "--sec-width=60", "--sec-height=20",
                    "--pref=d0rrc0m0f0e0"]
            if logging:
                args.append("--log=on")
            os.execve(executable, args, env)
        self.alive = True

    def read(self, timeout=0.1):
        if not select.select([self.fd], [], [], timeout)[0]:
            return False
        try:
            chunk = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            chunk = b""
        if not chunk:
            return False
        self.raw.extend(chunk)
        require(len(self.raw) < 4000000, "excessive terminal output")
        return True

    def wait(self, predicate, description, timeout=15):
        deadline = time.monotonic() + timeout
        while not predicate():
            require(time.monotonic() < deadline,
                    description + "\nPTY suffix: " + repr(bytes(self.raw[-2000:])))
            self.read()

    def marker(self, marker, start, description):
        self.wait(lambda: marker in self.raw[start:], description)

    def send(self, keys):
        start = len(self.raw)
        os.write(self.fd, keys)
        return start

    def settle(self):
        # Wait for emitted ncurses output to quiesce, not for a guessed delay.
        deadline = time.monotonic() + 5
        while self.read(0.15):
            require(time.monotonic() < deadline, "terminal did not settle")

    def snapshot(self, state, number):
        start = self.send(b"X")
        self.marker(b"extended command?", start, "missing screenshot command prompt")
        self.send(b"s")
        target = state / (".atrogue-screenshot-%02d" % number)
        self.wait(lambda: target.exists() and target.stat().st_size == ROWS * COLS,
                  "native screenshot not written: " + str(target))
        self.settle()
        data = target.read_bytes()
        lines = data.splitlines()
        require(len(lines) == ROWS and all(len(row) == COLS - 1 for row in lines),
                "native screenshot geometry differs from live 80x24 terminal")
        status = re.search(rb"L:.*H:.*S:.*E:.*A:.*M:.*T:(\d+)", lines[-1])
        require(status is not None, "native screenshot lacks gameplay statistics")
        positions = [(y, x) for y, row in enumerate(lines[:-2])
                     for x, byte in enumerate(row) if byte == ord("@")]
        require(len(positions) == 1, "native screenshot lacks unique player")
        require(target.stat().st_mode & 0o077 == 0, "screenshot is not private")
        return data, positions[0], int(status.group(1))

    def quit(self):
        start = self.send(b"Q")
        self.marker(b"really quit?", start, "missing quit confirmation")
        self.send(b"y")
        deadline = time.monotonic() + 10
        while True:
            self.read()
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.alive = False
                require(os.waitstatus_to_exitcode(status) == 0, "game exited unsuccessfully")
                break
            require(time.monotonic() < deadline, "game did not quit")

    def close(self):
        if self.alive:
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)


def exercise(executable, root, explicit, logging, capture=False):
    root.mkdir(parents=True, exist_ok=True)
    # Deliberately longer than upstream's 50-byte HOME limit, to prove the
    # launcher never falls back to a caller-owned cwd for native writes.
    dirs = {key: root / (key.lower() + "-" + "x" * 60)
            for key in ("HOME", "XDG_CONFIG_HOME", "XDG_DATA_HOME",
                        "XDG_CACHE_HOME", "XDG_STATE_HOME", "XDG_RUNTIME_DIR", "TMPDIR")}
    for directory in dirs.values():
        directory.mkdir(mode=0o700, exist_ok=True)
    work = root / "work"
    work.mkdir(exist_ok=True)
    env = {key: str(value) for key, value in dirs.items()}
    env.update(TERM="xterm-256color", LC_ALL="C", PATH="")
    if not explicit:
        del env["XDG_DATA_HOME"]
    state = ((dirs["XDG_DATA_HOME"] if explicit else dirs["HOME"] / ".local/share")
             / "atrogue")
    old = {path.name: path.read_bytes() for path in state.glob(".atrogue-screenshot-*")}
    number = len(old) + 1
    session = Session(executable, env, str(work), logging)
    try:
        session.marker(b"Preferences", 0, "missing real preference screen")
        session.send(b"P")
        session.marker(b"T:", 0, "missing initial dungeon statistics")
        session.settle()
        initial, position, ticks = session.snapshot(state, number)
        number += 1
        moved = False
        # l/j are the research handoff's movement keys; a randomly placed wall
        # may block either, so try remaining adjacent directions if necessary.
        for index, key in enumerate(b"ljhkynbu"):
            session.send(bytes([key]))
            session.settle()
            current, new_position, new_ticks = session.snapshot(state, number)
            number += 1
            moved = moved or new_position != position
            if moved and index >= 1:
                break
        require(moved, "no meaningful player movement occurred")
        # The displayed clock floors internal milliticks, so one valid action
        # need not change the integer. Rest until an observable tick advances.
        after_rest = new_ticks
        for _ in range(6):
            session.send(b".")
            session.settle()
            native, _, after_rest = session.snapshot(state, number)
            number += 1
            if after_rest > new_ticks:
                break
        require(after_rest > new_ticks, "rest commands did not advance dungeon time")
        start = session.send(b"v")
        session.marker(VERSION, start, "missing in-game version message")
        session.settle()
        if capture:
            raw_target = os.environ.get("OMP_RUNTIME_RAW_CAPTURE")
            native_target = os.environ.get("OMP_RUNTIME_NATIVE_CAPTURE")
            if raw_target:
                Path(raw_target).write_bytes(session.raw)
            if native_target:
                Path(native_target).write_bytes(native)
        session.quit()
    finally:
        session.close()
    for name, data in old.items():
        require((state / name).read_bytes() == data,
                "new session overwrote a persistent native screenshot")
    log = state / ".atrogue-log"
    if logging:
        require(VERSION in log.read_bytes(), "opt-in log lacks real gameplay message")
        require(log.stat().st_mode & 0o077 == 0, "log is not private")
    else:
        require(not log.exists(), "logging enabled by default")
    files = [path for path in root.rglob("*") if path.is_file()]
    require(files and all(path.parent == state for path in files),
            "mutable files escaped launcher-owned state directory")
    require(all(path.name == ".atrogue-log" or
                re.fullmatch(r"\.atrogue-screenshot-\d\d", path.name)
                for path in files), "unexpected runtime output")
    print("atrogue: %s %s movement/rest, native screenshots, private state passed" %
          ("XDG" if explicit else "HOME fallback", "log-on" if logging else "default-log-off"))


def main():
    require(len(sys.argv) == 3, "usage: atrogue-pty-runner.py ATROGUE SCRATCH")
    require(socket.if_nameindex() == [(1, "lo")], "proof requires isolated network namespace")
    executable = str(Path(sys.argv[1]).resolve())
    root = Path(sys.argv[2]).resolve()
    exercise(executable, root / "xdg", True, False, True)
    exercise(executable, root / "xdg", True, True)
    exercise(executable, root / "fallback", False, False)
    print("ATROGUE-SMOKE: actual-gameplay-native-state-ok; no dungeon save/load upstream")


if __name__ == "__main__":
    main()
