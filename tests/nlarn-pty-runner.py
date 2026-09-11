#!/usr/bin/env python3
"""Drive NLarn's curses UI through two isolated save/restore sessions."""

import errno
import fcntl
import os
import pty
import select
import struct
import sys
import termios
import time


def fail(message):
    raise RuntimeError(message)


def run_session(executable, root, resume, raw):
    environment = {
        "HOME": os.path.join(root, "home"),
        "XDG_CONFIG_HOME": os.path.join(root, "config"),
        "XDG_DATA_HOME": os.path.join(root, "data"),
        "XDG_CACHE_HOME": os.path.join(root, "cache"),
        "XDG_STATE_HOME": os.path.join(root, "state"),
        "XDG_RUNTIME_DIR": os.path.join(root, "runtime"),
        "TMPDIR": os.path.join(root, "tmp"),
        "TERM": "xterm-256color",
        "LC_ALL": "C",
        "PATH": "",
    }

    pid, master = pty.fork()
    if pid == 0:
        os.chdir(os.path.join(root, "work"))
        os.execve(executable, [executable], environment)

    fcntl.ioctl(master, termios.TIOCSWINSZ,
                struct.pack("HHHH", 30, 100, 0, 0))
    seen = bytearray()
    sent = set()
    moved_at = None
    deadline = time.monotonic() + 30

    while True:
        if time.monotonic() > deadline:
            fail("NLarn PTY session exceeded its deadline")
        readable, _, _ = select.select([master], [], [], 0.25)
        if readable:
            try:
                chunk = os.read(master, 65536)
            except OSError as error:
                if error.errno == errno.EIO:
                    chunk = b""
                else:
                    raise
            if chunk:
                seen.extend(chunk)
                raw.extend(chunk)

        if b"Welcome to the game of NLarn!" in seen and "welcome" not in sent:
            os.write(master, b" ")
            sent.add("welcome")

        if not resume and b"New Game" in seen and "new" not in sent:
            os.write(master, b"a")
            sent.add("new")
        elif resume and b"Continue saved Game" in seen and "continue" not in sent:
            os.write(master, b"a")
            sent.add("continue")

        if not resume and b"By what name shall " in seen \
                and "name" not in sent:
            os.write(master, b"Goocastle\r")
            sent.add("name")

        if not resume and b"Are you male or female?" in seen \
                and "gender" not in sent:
            os.write(master, b"m")
            sent.add("gender")

        if not resume and b"Choose a character build" in seen \
                and "stats" not in sent:
            os.write(master, b"a")
            sent.add("stats")

        in_game = ((resume and "continue" in sent)
                   or (not resume and "stats" in sent))
        if in_game and b"Lvl:" in seen and "move" not in sent:
            # The initial town tile can block one direction.  Try each
            # cardinal/diagonal vi-key once; at least one is a legal move
            # from the deterministic starting position.
            os.write(master, b"ljhkyubn")
            sent.add("move")
            moved_at = time.monotonic()

        if moved_at is not None and time.monotonic() - moved_at > 0.25 \
                and "save" not in sent:
            os.write(master, b"\x13")
            sent.add("save")

        try:
            waited, status = os.waitpid(pid, os.WNOHANG)
        except ChildProcessError:
            waited, status = pid, 1
        if waited == pid:
            if not os.WIFEXITED(status) or os.WEXITSTATUS(status) != 0:
                fail("NLarn session exited unsuccessfully")
            break

    required = {"welcome", "continue" if resume else "new", "move", "save"}
    if not required.issubset(sent):
        fail("NLarn PTY session missed: " + ", ".join(sorted(required - sent)))
    if not resume and not {"name", "gender", "stats"}.issubset(sent):
        fail("NLarn character setup was incomplete")


def main():
    if len(sys.argv) != 3:
        print("usage: nlarn-pty-runner.py NLARN ROOT", file=sys.stderr)
        return 64

    executable, root = sys.argv[1:]
    raw = bytearray()
    raw_path = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
    try:
        run_session(executable, root, False, raw)
        save_file = os.path.join(root, "home", ".nlarn", "nlarn.sav")
        config_file = os.path.join(root, "home", ".nlarn", "nlarn.ini")
        if not os.path.isfile(save_file) or not os.path.isfile(config_file):
            fail("first session did not leave the expected save/config files")

        run_session(executable, root, True, raw)
        if not os.path.isfile(save_file):
            fail("continued session did not preserve the save file")
    finally:
        if raw_path:
            with open(raw_path, "wb") as output:
                output.write(raw)

    print("NLARN PTY save/restore passed")
    return 0


try:
    sys.exit(main())
except Exception as error:
    print("nlarn-pty-runner: " + str(error), file=sys.stderr)
    sys.exit(1)
