#!/usr/bin/env python3
"""Play a new Bloatcrawl 2 character through the real terminal UI.

Usage: bloatcrawl2-smoke.py PROGRAM CAPTURE

PROGRAM is the installed console binary; the caller provides a fresh HOME/XDG
environment and CRAWL_DIR.  ncurses sends only the cells that change, so the
PTY output is applied to a 24x80 screen model and every prompt is matched on
the drawn screen; each key is sent only after the screen that consumes it is
shown.

The session creates a seeded Human Fighter, chooses a weapon, begins the game,
waits three turns while the HUD game clock advances, then abandons the
character through the documented quit confirmation and end-game screens.
After every assertion has passed, CAPTURE receives the contiguous raw byte
prefix of the session, from its first byte up to the gameplay frame drawn
after the last turn; it ends before the quit key and before curses leaves the
alternate screen.
"""

import errno
import fcntl
import os
import re
import select
import struct
import sys
import termios
import time

PROGRAM, CAPTURE = sys.argv[1:3]
# -no-save keeps the smoke from leaving a character save behind.
NEW_GAME = [PROGRAM, "-seed", "285", "-no-save", "-name", "Goocastle",
            "-species", "Hu", "-background", "Fi"]
ROWS, COLS = 24, 80
LEAVE_ALTERNATE_SCREEN = b"\x1b[?1049l"
HEALTH = re.compile(rb"Health: *\d+/\d+")
CLOCK = re.compile(rb"Time: *(\d+\.\d)")


def fail(message):
    raise SystemExit("bloatcrawl2 smoke: " + message)


class Screen:
    """The characters an xterm shows after the ncurses output so far."""

    def __init__(self):
        self.rows = [bytearray(b" " * COLS) for _ in range(ROWS)]
        self.row = self.col = 0
        self.top, self.bottom = 0, ROWS - 1
        self.last = ord(" ")
        self.pending = b""

    def text(self):
        return b"\n".join(bytes(row) for row in self.rows)

    def _blank(self):
        return bytearray(b" " * COLS)

    def _scroll_up(self, count, top=None):
        top = self.top if top is None else top
        for _ in range(count):
            del self.rows[top]
            self.rows.insert(self.bottom, self._blank())

    def _scroll_down(self, count, top=None):
        top = self.top if top is None else top
        for _ in range(count):
            del self.rows[self.bottom]
            self.rows.insert(top, self._blank())

    def _linefeed(self):
        if self.row == self.bottom:
            self._scroll_up(1)
        elif self.row < ROWS - 1:
            self.row += 1

    def _put(self, byte):
        if self.col >= COLS:
            self.col = 0
            self._linefeed()
        self.rows[self.row][self.col] = byte
        self.col += 1
        self.last = byte

    def _csi(self, body):
        final = chr(body[-1])
        params = body[:-1]
        if params[:1] in (b"?", b">", b"="):
            return
        values = [int(p) if p.isdigit() else 0
                  for p in params.split(b";")] if params else []

        def arg(index, default=1):
            if index < len(values) and values[index]:
                return values[index]
            return default

        row, col = self.row, min(self.col, COLS - 1)
        if final in "Hf":
            self.row, self.col = arg(0) - 1, arg(1) - 1
        elif final == "d":
            self.row = arg(0) - 1
        elif final in "G`":
            self.col = arg(0) - 1
        elif final == "A":
            self.row -= arg(0)
        elif final == "B":
            self.row += arg(0)
        elif final == "C":
            self.col = col + arg(0)
        elif final == "D":
            self.col = col - arg(0)
        elif final == "E":
            self.row, self.col = row + arg(0), 0
        elif final == "F":
            self.row, self.col = row - arg(0), 0
        elif final == "K":
            mode = arg(0, 0)
            line = self.rows[row]
            start, end = {0: (col, COLS), 1: (0, col + 1)}.get(mode, (0, COLS))
            line[start:end] = b" " * (end - start)
        elif final == "J":
            mode = arg(0, 0)
            if mode == 0:
                self.rows[row][col:] = b" " * (COLS - col)
                targets = range(row + 1, ROWS)
            elif mode == 1:
                self.rows[row][:col + 1] = b" " * (col + 1)
                targets = range(0, row)
            else:
                targets = range(ROWS)
            for index in targets:
                self.rows[index] = self._blank()
        elif final == "X":
            end = min(COLS, col + arg(0))
            self.rows[row][col:end] = b" " * (end - col)
        elif final == "b":
            for _ in range(arg(0)):
                self._put(self.last)
        elif final == "@":
            count = min(arg(0), COLS - col)
            line = self.rows[row]
            line[col:] = (b" " * count + line[col:])[:COLS - col]
        elif final == "P":
            count = min(arg(0), COLS - col)
            line = self.rows[row]
            line[col:] = line[col + count:] + b" " * count
        elif final == "L" and self.top <= row <= self.bottom:
            self._scroll_down(arg(0), row)
        elif final == "M" and self.top <= row <= self.bottom:
            self._scroll_up(arg(0), row)
        elif final == "S":
            self._scroll_up(arg(0))
        elif final == "T":
            self._scroll_down(arg(0))
        elif final == "r":
            self.top, self.bottom = arg(0) - 1, arg(1, ROWS) - 1
            self.row = self.col = 0
        if final in "HfdG`ABCDEFr":
            self.row = max(0, min(ROWS - 1, self.row))
            self.col = max(0, min(COLS - 1, self.col))

    def feed(self, data):
        data = self.pending + data
        self.pending = b""
        index = 0
        while index < len(data):
            byte = data[index]
            if byte == 0x1b:
                if index + 1 >= len(data):
                    break
                kind = data[index + 1]
                if kind == ord("["):
                    end = index + 2
                    while end < len(data) and not 0x40 <= data[end] <= 0x7e:
                        end += 1
                    if end >= len(data):
                        break
                    self._csi(data[index + 2:end + 1])
                    index = end + 1
                elif kind == ord("]"):
                    end = data.find(b"\x07", index)
                    terminator = data.find(b"\x1b\\", index)
                    if end < 0 and terminator < 0:
                        break
                    if end < 0 or 0 <= terminator < end:
                        index = terminator + 2
                    else:
                        index = end + 1
                elif kind in b"()*+":
                    if index + 2 >= len(data):
                        break
                    index += 3
                else:
                    if kind == ord("M"):
                        if self.row == self.top:
                            self._scroll_down(1)
                        elif self.row > 0:
                            self.row -= 1
                    elif kind == ord("D"):
                        self._linefeed()
                    elif kind == ord("E"):
                        self.col = 0
                        self._linefeed()
                    index += 2
                continue
            if byte == 0x0d:
                self.col = 0
            elif byte == 0x0a:
                self._linefeed()
            elif byte == 0x08:
                self.col = max(0, min(self.col, COLS - 1) - 1)
            elif byte == 0x09:
                self.col = min(COLS - 1, (self.col // 8 + 1) * 8)
            elif 0x80 <= byte <= 0xbf:
                # A UTF-8 continuation byte shares its lead byte's cell.
                pass
            elif byte >= 0x20 and byte != 0x7f:
                self._put(byte if byte < 0x80 else ord("?"))
            index += 1
        self.pending = data[index:]


class Session:
    def __init__(self, argv):
        self.pid, self.master = os.forkpty()
        if self.pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack("HHHH", ROWS, COLS, 0, 0))
                os.execv(argv[0], argv)
            finally:
                os._exit(127)
        self.output = bytearray()
        self.screen = Screen()

    def _read(self, timeout):
        ready, _, _ = select.select([self.master], [], [], timeout)
        if not ready:
            return None
        try:
            chunk = os.read(self.master, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            chunk = b""
        self.output.extend(chunk)
        self.screen.feed(chunk)
        return chunk

    def dump(self):
        return self.screen.text().decode("latin-1")

    def until(self, ready, what, timeout=60):
        """Read output until READY(screen text) holds."""
        deadline = time.monotonic() + timeout
        while not ready(self.screen.text()):
            remaining = deadline - time.monotonic()
            if remaining <= 0 or self._read(min(remaining, 0.2)) == b"":
                fail(f"no {what}; screen:\n{self.dump()}")

    def expect(self, pattern, timeout=60):
        regex = re.compile(pattern)
        self.until(lambda screen: regex.search(screen), repr(pattern),
                   timeout)

    def settle(self, quiet=0.8):
        """Read until the screen has been quiet."""
        while self._read(quiet):
            pass

    def send(self, keys):
        os.write(self.master, keys)

    def wait(self, timeout=60):
        deadline = time.monotonic() + timeout
        while True:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                while self._read(0.1):
                    pass
                os.close(self.master)
                return os.waitstatus_to_exitcode(status)
            if time.monotonic() > deadline:
                os.kill(self.pid, 9)
                fail(f"game did not exit; screen:\n{self.dump()}")
            self._read(0.2)


def gameplay(session, refuse=None, timeout=90):
    """Dismiss --more-- until the quiet dungeon screen shows the HUD.

    Return the game clock drawn on the HUD.  Fail as soon as REFUSE is drawn.
    """
    deadline = time.monotonic() + timeout
    while True:
        session.settle()
        screen = session.screen.text()
        if refuse and re.search(refuse, screen):
            fail(f"unexpected screen:\n{session.dump()}")
        clock = CLOCK.search(screen)
        if b"--more--" in screen:
            session.send(b" ")
        elif HEALTH.search(screen) and clock:
            return float(clock.group(1))
        elif time.monotonic() > deadline:
            fail(f"no gameplay HUD; screen:\n{session.dump()}")


def wait_turn(session, clock):
    """'s' waits one turn in place; the HUD clock must advance."""
    session.send(b"s")
    after = gameplay(session)
    if after <= clock:
        fail(f"game clock stayed at {after}; screen:\n{session.dump()}")
    return after


def main():
    session = Session(NEW_GAME)
    session.expect(rb"You have a choice of weapons\.")
    session.send(b"a")
    session.expect(rb"Game Modifiers")
    session.expect(rb"\[Enter\] Begin!")
    session.send(b"\r")
    # The weapon menu's title also says "Welcome, ..."; only the dungeon
    # message area is on screen once the HUD is drawn.
    clock = gameplay(session, refuse=rb"choice of weapons")
    if b"Welcome, Goocastle the Human Fighter." not in session.screen.text():
        fail(f"no new-character welcome; screen:\n{session.dump()}")
    for _ in range(3):
        clock = wait_turn(session, clock)
    capture = bytes(session.output)
    if LEAVE_ALTERNATE_SCREEN in capture:
        fail("capture left the alternate screen")

    # Ctrl-Q abandons the character; this release asks for the literal word
    # "yes", then shows the death pager, the inventory and the goodbye screen.
    session.send(b"\x11")
    session.expect(rb"Are you sure you want to abandon this character")
    session.send(b"yes\r")
    session.expect(rb"--more--")
    session.send(b" ")
    session.expect(rb"Inventory:")
    session.send(b"\x1b")
    session.expect(rb"Goodbye, Goocastle\.")
    session.send(b"\r")
    status = session.wait()
    if status != 0:
        fail(f"game exited with status {status}")

    with open(CAPTURE, "wb") as port:
        port.write(capture)
    print("BLOATCRAWL2_PTY_OK")


if __name__ == "__main__":
    main()
