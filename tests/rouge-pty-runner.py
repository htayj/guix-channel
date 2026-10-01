#!/usr/bin/env python3
"""Exercise original Rougelike 1.61 in real, isolated curses PTYs.

Usage: rouge-pty-runner.py ROUGE SCRATCH
GOOCASTLE_RUNTIME_RAW_CAPTURE receives the exact live PTY prefix before Q,
not a re-created terminal image. Only the Python standard library is needed.
"""

import errno
import fcntl
import hashlib
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


ROWS, COLS = 25, 80  # Upstream prompts explicitly use row 24 (zero-based).
NAMES = ("OMPRouge", "OMPRougeTwo")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class Screen:
    """Observe ncurses' incremental VT output without synthesizing capture bytes."""

    def __init__(self):
        self.cells = [[" "] * COLS for _ in range(ROWS)]
        self.y = self.x = 0
        self.saved = (0, 0)
        self.pending = bytearray()
        self.last_character = " "

    def feed(self, chunk):
        self.pending.extend(chunk)
        data = self.pending
        offset = 0
        while offset < len(data):
            byte = data[offset]
            if byte == 27:
                if offset + 1 == len(data):
                    break
                kind = data[offset + 1]
                if kind == ord("["):
                    end = offset + 2
                    while end < len(data) and not 64 <= data[end] <= 126:
                        end += 1
                    if end == len(data):
                        break
                    body = bytes(data[offset + 2:end]).decode("ascii")
                    self.csi(body, chr(data[end]))
                    offset = end + 1
                    continue
                if kind == ord("]"):
                    end = offset + 2
                    while end < len(data) and data[end] != 7 and data[end:end + 2] != b"\x1b\\":
                        end += 1
                    if end == len(data):
                        break
                    offset = end + (1 if data[end] == 7 else 2)
                    continue
                if kind in b"()*+":
                    if offset + 2 == len(data):
                        break
                    offset += 3
                    continue
                if kind == ord("7"):
                    self.saved = self.y, self.x
                elif kind == ord("8"):
                    self.y, self.x = self.saved
                elif kind in b"DE":
                    self.y = min(ROWS - 1, self.y + 1)
                    if kind == ord("E"):
                        self.x = 0
                elif kind == ord("M"):
                    self.y = max(0, self.y - 1)
                offset += 2
                continue
            if byte == 13:
                self.x = 0
            elif byte in (10, 11, 12):
                self.y = min(ROWS - 1, self.y + 1)
            elif byte == 8:
                self.x = max(0, self.x - 1)
            elif byte == 9:
                self.x = min(COLS - 1, (self.x // 8 + 1) * 8)
            elif byte >= 32 and byte != 127:
                self.cells[self.y][self.x] = chr(byte)
                self.last_character = chr(byte)
                self.x = min(COLS - 1, self.x + 1)
            offset += 1
        del data[:offset]

    def csi(self, body, command):
        if body.startswith(("?", ">", "!")):
            return  # Modes, cursor visibility, and device attributes.
        values = [int(part or "0") for part in body.split(";")]
        amount = values[0] or 1
        if command == "b":
            # Ncurses emits REP for long walls/floors (e.g. # ESC[75b).
            # Without expansion the observed @ coordinate differs from the
            # real terminal cursor position even though status labels exist.
            for _ in range(amount):
                self.cells[self.y][self.x] = self.last_character
                self.x = min(COLS - 1, self.x + 1)
        elif command in "Hf":
            self.y = (values[0] or 1) - 1
            self.x = ((values[1] if len(values) > 1 else 1) or 1) - 1
        elif command == "A":
            self.y -= amount
        elif command in "Be":
            self.y += amount
        elif command in "Ca":
            self.x += amount
        elif command == "D":
            self.x -= amount
        elif command in "EF":
            self.y += amount if command == "E" else -amount
            self.x = 0
        elif command in "G`":
            self.x = amount - 1
        elif command == "d":
            self.y = amount - 1
        elif command == "J":
            start = self.y * COLS + self.x
            if values[0] in (2, 3):
                self.cells = [[" "] * COLS for _ in range(ROWS)]
            else:
                positions = (range(start, ROWS * COLS) if values[0] == 0
                             else range(start + 1))
                for position in positions:
                    self.cells[position // COLS][position % COLS] = " "
        elif command == "K":
            positions = (range(self.x, COLS) if values[0] == 0 else
                         range(self.x + 1) if values[0] == 1 else range(COLS))
            for position in positions:
                self.cells[self.y][position] = " "
        elif command == "X":
            for position in range(self.x, min(COLS, self.x + amount)):
                self.cells[self.y][position] = " "
        elif command == "P":
            row = self.cells[self.y]
            row[self.x:] = (row[self.x + amount:] + [" "] * amount)[:COLS - self.x]
        elif command == "@":
            row = self.cells[self.y]
            row[self.x:] = ([" "] * amount + row[self.x:])[:COLS - self.x]
        elif command == "s":
            self.saved = self.y, self.x
        elif command == "u":
            self.y, self.x = self.saved
        self.y = max(0, min(ROWS - 1, self.y))
        self.x = max(0, min(COLS - 1, self.x))

    def text(self):
        return "\n".join("".join(row) for row in self.cells)

    def player_turn(self):
        return (self.cells[self.y][self.x] == "@"
                and all(label in "".join(self.cells[22])
                        for label in ("HP:", "Karma:", "Rouge:")))


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
                            struct.pack("HHHH", ROWS, COLS, 0, 0))
                os.chdir(root / "work")
                os.execve(executable, [executable], environment)
            finally:
                os._exit(127)
        self.raw = bytearray()
        self.screen = Screen()
        self.mark = 0
        self.status = None
        self.eof = False
        self.transcript = transcript.open("wb")
        self.deadline = time.monotonic() + 35

    def read(self, timeout):
        if self.eof:
            return False
        ready, _, _ = select.select([self.master], [], [], timeout)
        if not ready:
            return None
        try:
            chunk = os.read(self.master, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            chunk = b""
        self.eof = not chunk
        self.raw.extend(chunk)
        self.screen.feed(chunk)
        self.transcript.write(chunk)
        self.transcript.flush()
        return bool(chunk)

    def await_condition(self, predicate, description):
        while not predicate():
            remaining = self.deadline - time.monotonic()
            if remaining <= 0 or self.read(min(remaining, 0.2)) is False:
                waited, status = os.waitpid(self.pid, os.WNOHANG)
                if waited:
                    self.status = status
                exit_code = (os.waitstatus_to_exitcode(self.status)
                             if self.status is not None else "running")
                raise RuntimeError(
                    f"missing {description}; child={exit_code}; "
                    f"raw suffix={bytes(self.raw[-12000:])!r}; "
                    f"screen={self.screen.text()!r}")

    def expect(self, text):
        self.await_condition(lambda: text in self.screen.text(), text)

    def send(self, keys):
        self.mark = len(self.raw)
        os.write(self.master, keys)

    def settle(self):
        while self.read(0.08):
            require(time.monotonic() < self.deadline, "redraw never settled")
        require(not self.eof, "game exited before live player turn")

    def turn(self, key=None, message=None):
        if key is not None:
            self.send(key)
        acknowledgement = f"[{key[0]}]" if key is not None else None
        self.await_condition(
            lambda: self.screen.player_turn()
            and (acknowledgement is None or
                 (len(self.raw) > self.mark
                  and acknowledgement in "".join(self.screen.cells[24])))
            and (message is None or message in self.screen.text()),
            f"rendered player turn after {key!r}, message {message!r}")
        # getch first refreshes the numeric key on row 24. Only the subsequent
        # AI turn restores the cursor to @; unchanged status text need not be
        # retransmitted by ncurses. Wait for that actual rendered return.
        self.settle()
        require(self.screen.player_turn(), "redraw did not finish at the player")

    def start(self):
        self.expect("The Rougelike! 1.6")
        self.expect("[press any key to continue]")
        self.send(b" ")
        self.turn()

    def finish(self, name, previous=None):
        self.send(b"Q")
        self.expect("Congratulations! You made the top ten!")
        self.expect("Enter your name:")
        self.send(name.encode("ascii") + b"\n")
        self.expect("Top Rouge Admins:")
        self.expect(name)
        if previous:
            self.expect(previous)
        self.expect("[press any key to quit]")
        self.send(b" ")
        while self.status is None:
            waited, status = os.waitpid(self.pid, os.WNOHANG)
            if waited:
                self.status = status
                break
            require(time.monotonic() < self.deadline, "Rougelike did not exit")
            self.read(0.2)
        while self.read(0.1):
            pass
        require(os.waitstatus_to_exitcode(self.status) == 0,
                f"Rougelike exit status {self.status}")

    def close(self):
        if self.status is None:
            try:
                os.killpg(self.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(self.pid, 0)
        os.close(self.master)
        self.transcript.close()


# save-hiscore writes (16 MD5 octets), then a Lisp list of (name . score).
# genmd5 hashes the readable ~s representation of the latter, without newline.
SCORE = re.compile(r'\(\s*"((?:\\.|[^"\\])*)"\s*\.\s*(-?\d+)\s*\)')


def scores(path):
    raw = path.read_text(encoding="utf-8")
    digest = re.match(r"\s*\(\s*((?:\d+\s*){16})\)\s*", raw)
    require(digest is not None, "hiscore missing 16-octet MD5 header")
    octets = [int(value) for value in digest[1].split()]
    require(len(octets) == 16 and all(0 <= value <= 255 for value in octets),
            "invalid hiscore MD5 octets")
    body = raw[digest.end():].strip()
    require(body.startswith("(") and body.endswith(")"), "invalid scorelist")
    entries = []
    position = 1
    while position < len(body) - 1:
        if body[position].isspace():
            position += 1
            continue
        entry = SCORE.match(body, position)
        require(entry is not None, "unexpected data in real scorelist")
        require("\\" not in entry[1], "unexpected escaped smoke name")
        entries.append((entry[1], int(entry[2])))
        position = entry.end()
    canonical = "(" + " ".join(f'("{name}" . {score})' for name, score in entries) + ")"
    require(hashlib.md5(canonical.encode("utf-8")).digest() == bytes(octets),
            "hiscore checksum does not match upstream genmd5 readable format")
    require([score for _, score in entries] == sorted(
        (score for _, score in entries), reverse=True), "scores not sorted")
    return entries


def pair(executable, root, fallback, capture):
    for name in ("home", "state", "work", "config", "data", "cache", "runtime", "tmp"):
        (root / name).mkdir(parents=True)
    (root / "runtime").chmod(0o700)
    state = ((root / "home/.local/state") if fallback else root / "state") / "rouge"
    hiscore = state / "hiscore"
    first = Session(executable, root, fallback, root / "first.raw")
    try:
        first.start()
        first.turn(b"5")
        first.turn(b"w", "You are now using banhammer as a primary weapon.")
        first.turn(b"w", "You are now using word as a primary weapon.")
        if capture:
            capture.write_bytes(first.raw)
        first.finish(NAMES[0])
    finally:
        first.close()
    original = scores(hiscore)
    require(len(original) == 1 and original[0][0] == NAMES[0],
            "fresh state did not persist the chosen name and exactly one score")
    require(not list((root / "work").iterdir()), "game wrote in caller cwd")

    # Override the installed controls in the second explicit-XDG session only.
    # Removing 5 and adding . proves the real loader honors user remapping,
    # rather than checking source text or accepting any key acknowledgement.
    override = not fallback
    if override:
        config = root / "config/rouge"
        config.mkdir()
        (config / "controls.cfg").write_text(
            "(((wait) 46) ((quit-game) 81) ((switch-weapon) 119))\n",
            encoding="ascii")
    second = Session(executable, root, fallback, root / "second.raw")
    try:
        second.start()
        if override:
            second.turn(b"5", "No action bound to key: 53")
            second.turn(b".")
        else:
            second.turn(b"5")
        second.turn(b"w", "You are now using banhammer as a primary weapon.")
        second.finish(NAMES[1], NAMES[0])
    finally:
        second.close()
    persisted = scores(hiscore)
    require(len(persisted) == 2 and sorted(name for name, _ in persisted) == sorted(NAMES),
            "second game did not retain the first score and add exactly one new score")
    require(original[0] in persisted, "original score changed on reload")
    require(not list((root / "work").iterdir()), "second game wrote in caller cwd")
    require({path.name for path in state.iterdir()} == {"hiscore"},
            "unexpected persistent state")
    if not fallback:
        require(not list((root / "home").iterdir()), "game ignored XDG_STATE_HOME")
    else:
        require(not list((root / "state").iterdir()), "HOME fallback used unrelated XDG state")


def main():
    require(len(sys.argv) == 3, "usage: rouge-pty-runner.py ROUGE SCRATCH")
    executable = os.path.abspath(sys.argv[1])
    root = Path(sys.argv[2]).resolve()
    require({name for _, name in socket.if_nameindex()} == {"lo"},
            "smoke must run in a fresh network namespace")
    destination = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
    capture = Path(destination).resolve() if destination else None
    pair(executable, root / "xdg", False, capture)
    pair(executable, root / "fallback", True, None)
    print("ROUGE_RUNTIME_OK")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("rouge-pty-runner: " + str(error), file=sys.stderr)
        sys.exit(1)
