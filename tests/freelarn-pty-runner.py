#!/usr/bin/env python3
"""Drive the pinned FreeLarn game, not a renderer or scripted substitute.

Usage: freelarn-pty-runner.py FREELARN SCRATCH
Run under a fresh user/network namespace.  Prompts and save format below come
from atsb/freelarn commit 8cd18cbaef70b9763a9f76cdfa11b78524ebcf5e.
GOOCASTLE_RUNTIME_RAW_CAPTURE, if set, receives the exact raw PTY prefix ending
on the restored live game screen, before inventory/quit or terminal teardown.
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


ESCAPES = re.compile(rb"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07]*(?:\x07|\x1b\\)|\x1b[()][0-2A-Z]|\x1b[@-_]")
NAME = b"OMP Smoke"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class Session:
    def __init__(self, executable, root, fallback, transcript):
        environment = {
            "HOME": str(root / "home"),
            "XDG_CONFIG_HOME": str(root / "config"),
            "XDG_DATA_HOME": str(root / "data"),
            "XDG_CACHE_HOME": str(root / "cache"),
            "XDG_RUNTIME_DIR": str(root / "runtime"),
            "TMPDIR": str(root / "tmp"),
            "TERM": "xterm",
            "LC_ALL": "C",
            "PATH": "",
        }
        if not fallback:
            environment["XDG_STATE_HOME"] = str(root / "state")
        self.pid, self.master = os.forkpty()
        if self.pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack("HHHH", 24, 80, 0, 0))
                os.chdir(root / "work")
                os.execve(executable, [executable], environment)
            finally:
                os._exit(127)
        self.raw = bytearray()
        self.mark = 0
        self.status = None
        self.eof = False
        self.transcript = transcript.open("wb")
        self.deadline = time.monotonic() + 30

    def read(self, timeout):
        if self.eof:
            return False
        ready, _, _ = select.select([self.master], [], [], timeout)
        if ready:
            try:
                chunk = os.read(self.master, 65536)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise
                chunk = b""
            self.eof = not chunk
            self.raw.extend(chunk)
            self.transcript.write(chunk)
            self.transcript.flush()
            return bool(chunk)
        return None

    def expect(self, text):
        while True:
            plain = ESCAPES.sub(b"", self.raw[self.mark:])
            if text in plain:
                return
            remaining = self.deadline - time.monotonic()
            if remaining <= 0 or self.read(min(remaining, 0.2)) is False:
                raise RuntimeError(f"missing FreeLarn prompt {text!r}: {plain[-1200:]!r}")

    def send(self, keys):
        self.mark = len(self.raw)
        os.write(self.master, keys)

    def frame(self):
        # FLTerminalDisplay.cpp bot_linex() prints the name, statistics, then
        # class.  No command is sent until this actual redraw has been seen.
        for text in (NAME, b"HP:", b"SPL:", b"Cave Level:", b"Novice Explorer"):
            self.expect(text)

    def inventory(self):
        self.send(b"i")
        self.expect(b"Elapsed time is")
        self.expect(b"mobuls left")
        self.expect(b"to continue ---")
        self.send(b" ")
        self.frame()

    def capture_frame(self, destination):
        # Finish the same redraw; the quiet wait is only for bytes already
        # being rendered, never a substitute for a prompt/action assertion.
        while self.read(0.1):
            require(time.monotonic() < self.deadline, "redraw never settled")
        require(not self.eof, "game exited before live frame capture")
        if destination:
            destination.write_bytes(self.raw)

    def wait(self):
        while self.status is None:
            waited, status = os.waitpid(self.pid, os.WNOHANG)
            if waited:
                self.status = status
                break
            require(time.monotonic() < self.deadline, "FreeLarn did not exit")
            self.read(0.2)
        while self.read(0.1):
            pass
        require(os.waitstatus_to_exitcode(self.status) == 0,
                f"FreeLarn exit status {self.status}")

    def close(self):
        if self.status is None:
            try:
                os.killpg(self.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(self.pid, 0)
        os.close(self.master)
        self.transcript.close()


def pair(executable, root, fallback, capture):
    for name in ("home", "state", "work", "config", "data", "cache", "runtime", "tmp"):
        (root / name).mkdir(parents=True)
    (root / "runtime").chmod(0o700)
    state = ((root / "home/.local/state") if fallback else root / "state") / "freelarn"
    save = state / "fl_savefile.dat"
    first = Session(executable, root, fallback, root / "first.raw")
    try:
        first.expect(b"Welcome to the game of Larn.")
        first.expect(b"to continue:")
        first.send(b"\n")
        first.expect(b"Enter character name:")
        first.send(NAME + b"\n")
        first.frame()
        first.inventory()
        first.send(b"S")
        first.wait()
    finally:
        first.close()
    require(save.is_file(), "save command left no save")
    saved = save.read_bytes()
    # FLSave.cpp writes the 20-byte player-name record first.  This checks
    # the real save content, not merely the presence of an arbitrary file.
    require(saved[:20].split(b"\0", 1)[0] == NAME and len(saved) > 20,
            "save does not contain the chosen character")
    for name in ("fl_scorefile.dat", "fl_messages.txt"):
        require((state / name).is_file() and (state / name).stat().st_size > 0,
                f"missing game state {name}")
    require(not list((root / "work").iterdir()), "game wrote in caller cwd")
    if not fallback:
        require(not list((root / "home").iterdir()), "game ignored XDG_STATE_HOME")

    restored = Session(executable, root, fallback, root / "restore.raw")
    try:
        restored.expect(b"Restoring . . .")
        restored.frame()
        require(not save.exists(), "restore did not consume the saved game")
        require(b"Welcome to the game of Larn." not in restored.raw
                and b"Enter character name:" not in restored.raw,
                "restore started a new character")
        restored.capture_frame(capture)
        restored.inventory()
        restored.send(b"Q")
        restored.expect(b"Do you really want to quit?")
        restored.send(b"y")
        restored.wait()
    finally:
        restored.close()
    require(not save.exists(), "quit recreated a save")
    require(not list((root / "work").iterdir()), "restore wrote in caller cwd")
    require({path.name for path in state.iterdir()} == {
        "fl_scorefile.dat", "fl_savefile.dat", "fl_messages.txt"} - {"fl_savefile.dat"},
        "unexpected persistent state")


def main():
    if len(sys.argv) != 3:
        raise RuntimeError("usage: freelarn-pty-runner.py FREELARN SCRATCH")
    executable = os.path.abspath(sys.argv[1])
    root = Path(sys.argv[2]).resolve()
    require({name for _, name in socket.if_nameindex()} == {"lo"},
            "smoke must run in a fresh network namespace")
    capture = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
    capture = Path(capture).resolve() if capture else None
    pair(executable, root / "xdg", False, capture)
    pair(executable, root / "fallback", True, None)
    print("FREELARN_RUNTIME_OK")

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("freelarn-pty-runner: " + str(error), file=sys.stderr)
        sys.exit(1)
