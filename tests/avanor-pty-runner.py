#!/usr/bin/env python3
"""Play, save and restore Avanor through real curses sessions.

Usage: avanor-pty-runner.py GAME SCRATCH CAPTURE

Run inside fresh user, PID and network namespaces.  ncurses sends only the
cells that change, so the PTY output is applied to a 24x80 screen model and
every prompt is matched on the drawn screen; each key is sent only after the
screen that consumes it is shown.  After every assertion has passed, CAPTURE
receives the contiguous raw byte prefix of the restore session, from its
first byte up to the restored gameplay frame; it ends before the quit prompt
and before curses leaves the alternate screen.
"""

import errno
import fcntl
import os
import re
import select
import struct
import subprocess
import sys
import termios
import time

GAME, SCRATCH, CAPTURE = sys.argv[1:4]
STATE = os.path.join(SCRATCH, "state", ".avanor")
SAVE = os.path.join(STATE, "avanor.svg")
NAME = b"smoke"
ROWS, COLS = 24, 80
LEAVE_ALTERNATE_SCREEN = b"\x1b[?1049l"


def fail(message):
    raise SystemExit("avanor smoke: " + message)


def environment():
    return {
        "HOME": os.path.join(SCRATCH, "home"),
        "XDG_CONFIG_HOME": os.path.join(SCRATCH, "config"),
        "XDG_DATA_HOME": os.path.join(SCRATCH, "data"),
        "XDG_CACHE_HOME": os.path.join(SCRATCH, "cache"),
        "XDG_STATE_HOME": os.path.join(SCRATCH, "state"),
        "TMPDIR": os.path.join(SCRATCH, "tmp"),
        "TERM": "xterm-256color",
        "LC_ALL": "C",
        "PATH": "",
    }


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
            elif byte >= 0x20 and byte != 0x7f:
                self._put(byte)
            index += 1
        self.pending = data[index:]


class Session:
    def __init__(self, argv):
        self.pid, self.master = os.forkpty()
        if self.pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack("HHHH", ROWS, COLS, 0, 0))
                os.chdir(os.path.join(SCRATCH, "caller"))
                os.execve(argv[0], argv, environment())
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

    def quit(self):
        self.send(b"Q")
        self.expect(rb"QUIT the game")
        self.send(b"y")
        self.expect(rb"Goodbye!")
        self.send(b" ")
        status = self.wait()
        if status != 0:
            fail(f"game exited with status {status}")

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


def status_shown(screen):
    """XCreature::PutStatus draws the name and HP on the last rows."""
    rows = screen.split(b"\n")
    return (rows[ROWS - 3].startswith(NAME)
            and re.search(rb"HP:\d+\(\d+\)", rows[ROWS - 2]))


def more_shown(screen):
    """The message window, rows 0-1, waits on a (more) prompt."""
    return b"(more)" in b"".join(screen.split(b"\n")[:2])


def gameplay(session, refuse=None, timeout=90):
    """Answer (more) prompts until the quiet screen shows the hero's status.

    Fail as soon as REFUSE is drawn.
    """
    deadline = time.monotonic() + timeout
    while True:
        session.settle()
        screen = session.screen.text()
        if refuse and re.search(refuse, screen):
            fail(f"unexpected screen:\n{session.dump()}")
        if more_shown(screen):
            session.send(b" ")
        elif status_shown(screen):
            return
        elif time.monotonic() > deadline:
            fail(f"no status line; screen:\n{session.dump()}")


def close_view(session, title):
    """Close a list view with Z and wait for the game screen to return."""
    session.send(b"Z")
    session.until(lambda screen: title not in screen and status_shown(screen),
                  f"game screen after closing {title!r}")
    gameplay(session)


def main():
    smoke = subprocess.run([GAME, "--guix-smoke"], env=environment(),
                           stdin=subprocess.DEVNULL, capture_output=True,
                           timeout=30, check=False)
    if smoke.returncode != 0 or smoke.stdout != b"AVANOR_RUNTIME_OK\n":
        fail(f"--guix-smoke failed: {smoke!r}")
    if os.path.exists(SAVE):
        fail("a saved game exists before the first session")

    # First session: create a character, open the manual and inventory,
    # pass a turn, save, and quit.
    session = Session([GAME])
    session.expect(rb"\[N\] - New game")
    session.send(b"N")
    session.expect(rb"Choose a race:")
    session.send(b"a")
    session.expect(rb"Choose a gender:")
    session.send(b"a")
    session.expect(rb"Choose a profession:")
    session.send(b"a")
    session.expect(rb"Enter character name")
    session.send(NAME + b"\r")
    gameplay(session)
    session.send(b"?")
    session.expect(rb"Avanor manual")
    close_view(session, b"Avanor manual")
    session.send(b"i")
    session.expect(rb"### Inventory ###")
    close_view(session, b"### Inventory ###")
    # '5' acts in place: one game turn with no movement prompt.
    session.send(b"5")
    gameplay(session)
    # Saving blocks input until XArchive::StoreGame has closed the file,
    # so the later quit key is read only after the save is complete.
    session.send(b"S")
    session.until(lambda _: os.path.isfile(SAVE) and os.path.getsize(SAVE),
                  "saved game")
    gameplay(session)
    session.quit()
    if not os.path.isfile(SAVE) or os.path.getsize(SAVE) == 0:
        fail("the game was not saved")

    # Second session: restore the saved character.  A failed restore
    # reports it and waits for a key before generating a new game.
    session = Session([GAME])
    session.expect(rb"\[R\] - Restore game")
    session.send(b"R")
    gameplay(session, refuse=rb"There is not a saved game"
                             rb"|Generating game objects|Choose a race:")
    capture = bytes(session.output)
    if LEAVE_ALTERNATE_SCREEN in capture:
        fail("capture left the alternate screen")
    session.quit()

    with open(CAPTURE, "wb") as port:
        port.write(capture)
    print("AVANOR_PTY_OK")


if __name__ == "__main__":
    main()
