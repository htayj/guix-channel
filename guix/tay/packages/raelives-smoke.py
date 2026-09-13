#!/usr/bin/env python3
"""Drive the installed Rae Lives binary through a fixed-size PTY."""

import errno
import fcntl
import os
import pty
import select
import signal
import struct
import sys
import termios
import time


ROWS = 24
COLS = 80


class Screen:
    """Small ANSI/VT parser sufficient for ncurses' screen updates."""

    def __init__(self):
        self.cells = [[" "] * COLS for _ in range(ROWS)]
        self.row = 0
        self.col = 0

    def clear(self):
        self.cells = [[" "] * COLS for _ in range(ROWS)]
        self.row = 0
        self.col = 0

    def put(self, char):
        if 0 <= self.row < ROWS and 0 <= self.col < COLS:
            self.cells[self.row][self.col] = char
        if self.col < COLS - 1:
            self.col += 1

    def csi(self, params, final):
        private = params.startswith("?")
        if private:
            params = params[1:]
        values = [] if not params else [int(value or 0)
                                        for value in params.split(";")]
        first = values[0] if values else 0
        if final in ("H", "f"):
            row = values[0] if values else 1
            col = values[1] if len(values) > 1 else 1
            self.row = max(0, min(ROWS - 1, row - 1))
            self.col = max(0, min(COLS - 1, col - 1))
        elif final == "A":
            self.row = max(0, self.row - (first or 1))
        elif final == "B":
            self.row = min(ROWS - 1, self.row + (first or 1))
        elif final == "C":
            self.col = min(COLS - 1, self.col + (first or 1))
        elif final == "D":
            self.col = max(0, self.col - (first or 1))
        elif final == "G":
            self.col = max(0, min(COLS - 1, (first or 1) - 1))
        elif final == "d":
            self.row = max(0, min(ROWS - 1, (first or 1) - 1))
        elif final == "J" and first in (0, 2, 3):
            self.clear()
        elif final == "K":
            start = self.col if first == 0 else 0
            end = COLS if first != 1 else min(COLS, self.col + 1)
            for col in range(start, end):
                self.cells[self.row][col] = " "

    def feed(self, data):
        index = 0
        while index < len(data):
            byte = data[index]
            if byte == 0x1b:
                if index + 1 >= len(data):
                    break
                command = data[index + 1]
                if command == ord("["):
                    end = index + 2
                    while end < len(data) and not (0x40 <= data[end] <= 0x7e):
                        end += 1
                    if end == len(data):
                        break
                    self.csi(data[index + 2:end].decode("ascii", "ignore"),
                             chr(data[end]))
                    index = end + 1
                    continue
                if command == ord("]"):
                    end = index + 2
                    while end < len(data) and data[end] not in (7, 27):
                        end += 1
                    index = min(len(data), end + 1)
                    continue
                # Character-set selection and other two-byte controls.
                index += 2
                continue
            if byte in (10, 11, 12):
                self.row = min(ROWS - 1, self.row + 1)
            elif byte == 13:
                self.col = 0
            elif byte == 8:
                self.col = max(0, self.col - 1)
            elif 32 <= byte <= 126:
                self.put(chr(byte))
            index += 1

    def text(self):
        return "\n".join("".join(row) for row in self.cells)

    def players(self):
        return [(row, col)
                for row in range(ROWS)
                for col in range(COLS)
                if self.cells[row][col] == "@"]


def fail(message):
    raise RuntimeError("raelives smoke: " + message)


def check_no_store_path(work):
    if "/gnu/store" in os.path.abspath(work):
        fail("work directory is inside the store")
    for root, directories, files in os.walk(work, followlinks=False):
        for name in directories + files:
            path = os.path.join(root, name)
            if "/gnu/store" in path or os.path.islink(path):
                fail("work directory contains a store path")
            if os.path.isfile(path):
                with open(path, "rb") as stream:
                    if b"/gnu/store/" in stream.read():
                        fail("work file contains a store path")


def run(real, work):
    raw = bytearray()
    screen = Screen()
    master = None
    pid = None
    status = None
    eof = False
    moved = False
    quit_sent = False
    initial_position = None
    deadline = time.monotonic() + 15

    try:
        pid, master = pty.fork()
        if pid == 0:
            os.chdir(work)
            fcntl.ioctl(0, termios.TIOCSWINSZ,
                        struct.pack("HHHH", ROWS, COLS, 0, 0))
            os.execv(real, [real])

        os.set_blocking(master, False)
        while True:
            if time.monotonic() >= deadline:
                fail("timed out waiting for the game")

            ready, _, _ = select.select([master], [], [], 0.25)
            if ready:
                try:
                    chunk = os.read(master, 4096)
                except OSError as error:
                    if error.errno == errno.EIO:
                        eof = True
                        chunk = b""
                    else:
                        raise
                if chunk:
                    raw.extend(chunk)
                    screen.feed(chunk)

            if not moved:
                text = screen.text()
                positions = screen.players()
                if ("Rae" in text and positions and
                        any("#" in row and "." in row
                            for row in text.splitlines())):
                    initial_position = positions[0]
                    os.write(master, b"l")
                    moved = True

            if moved and not quit_sent and initial_position is not None:
                row, col = initial_position
                if ((row, col + 1) in screen.players() and
                        (row, col) not in screen.players()):
                    os.write(master, b"Q")
                    quit_sent = True

            waited, child_status = os.waitpid(pid, os.WNOHANG)
            if waited:
                status = child_status
                if not quit_sent:
                    fail("game exited before movement and Q exit")
                if eof:
                    break

            if status is not None and eof:
                break

        if not moved:
            fail("did not find the Rae/map screen")
        if not quit_sent:
            fail("movement was not followed by a clean Q exit")
        if not os.WIFEXITED(status) or os.WEXITSTATUS(status) != 0:
            fail("Q did not produce a clean exit")

        os.makedirs(work, exist_ok=True)
        transcript = os.path.join(work, "terminal.raw")
        with open(transcript, "wb") as stream:
            stream.write(raw)
        check_no_store_path(work)

        capture = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
        if capture:
            parent = os.path.dirname(capture)
            if parent:
                os.makedirs(parent, exist_ok=True)
            with open(capture, "wb") as stream:
                stream.write(raw)
    except Exception:
        if pid is not None and status is None:
            try:
                os.kill(pid, signal.SIGTERM)
                os.waitpid(pid, 0)
            except OSError:
                pass
        raise
    finally:
        if master is not None:
            try:
                os.close(master)
            except OSError:
                pass


def main():
    if len(sys.argv) != 3:
        print("usage: raelives-smoke.py REAL WORK", file=sys.stderr)
        return 64
    try:
        run(sys.argv[1], sys.argv[2])
    except Exception as error:
        print(str(error), file=sys.stderr)
        return 1
    print("RAELIVES_RUNTIME_OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
