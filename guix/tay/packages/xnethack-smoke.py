#!/usr/bin/env python3
"""Drive xNetHack through new game, save, restore, and quit in a real PTY."""

import fcntl
import glob
import os
import pty
import re
import select
import struct
import sys
import termios
import time

# plname[] holds at most PL_NSIZ-1 (31) bytes, so a long -u NAME-role-race-...
# suffix is truncated before plnamesuffix() parses it.  Give the character
# facets as regular options instead; all four being set skips every prompt.
NAME = "goocastle"
OPTIONS = ("role:tourist,race:human,gender:male,alignment:neutral,"
           "!tutorial,!legacy,!splash_screen,!news,!mail,!autopickup,"
           "!bones,!autoopen,time,mention_walls,disclose:-i -a -v -g -c -o")
DIRECTIONS = "hjklyubn"
TURN = re.compile(r"T:(\d+)")
DEADLINE = time.monotonic() + 90.0
ESCAPES = re.compile(
    rb"\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b[()*+][0-9A-Za-z]|\x1b[^\[()*+]|[\x0e\x0f]")


def fail(message, session=None):
    if session is not None:
        session.stop()
        sys.stderr.write(session.text()[-2000:] + "\n")
    sys.stderr.write("xnethack smoke: " + message + "\n")
    sys.exit(1)


class Session:
    def __init__(self, real):
        env = dict(os.environ)
        env["XNETHACKOPTIONS"] = OPTIONS
        pid, fd = pty.fork()
        if pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack("HHHH", 24, 80, 0, 0))
                os.execve(real, [real, "-u", NAME], env)
            finally:
                os._exit(127)
        self.pid = pid
        self.fd = fd
        self.raw = bytearray()
        self.mark = 0
        self.mores = 0
        self.eof = False
        self.status = None

    def text(self):
        return ESCAPES.sub(b"", bytes(self.raw[self.mark:])).decode("latin-1")

    def pump(self, timeout):
        remaining = DEADLINE - time.monotonic()
        if remaining <= 0:
            fail("deadline exceeded", self)
        if self.eof:
            return False
        ready, _, _ = select.select([self.fd], [], [], min(timeout, remaining))
        if not ready:
            return False
        try:
            data = os.read(self.fd, 65536)
        except OSError:
            data = b""
        if not data:
            self.eof = True
            return False
        self.raw += data
        return True

    def write(self, data):
        try:
            os.write(self.fd, data)
        except OSError:
            if not self.eof:
                raise

    def send(self, keys):
        self.mark = len(self.raw)
        self.mores = 0
        self.write(keys.encode("ascii"))

    def dismiss_more(self):
        count = self.text().count("--More--")
        if count > self.mores:
            self.mores = count
            self.write(b" ")

    def expect(self, pattern, what):
        regex = re.compile(pattern)
        while True:
            if regex.search(self.text()):
                return
            if self.eof:
                fail("game exited before " + what, self)
            self.pump(0.5)
            if not regex.search(self.text()):
                self.dismiss_more()

    def settle(self, quiet=0.5):
        while self.pump(quiet):
            self.dismiss_more()

    def finish(self, what):
        """Answer continuation prompts until the game closes its PTY."""
        while not self.eof:
            if not self.pump(1.0) and not self.eof:
                self.write(b" ")
            else:
                self.dismiss_more()
        while self.status is None:
            if time.monotonic() > DEADLINE:
                fail("game did not exit after " + what, self)
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
            else:
                time.sleep(0.1)
        os.close(self.fd)
        if self.status != 0:
            fail("%s exited with status %d" % (what, self.status), self)

    def stop(self):
        if self.status is None:
            try:
                os.kill(self.pid, 9)
                os.waitpid(self.pid, 0)
            except OSError:
                pass
            self.status = -9


def saves(state):
    return glob.glob(os.path.join(state, "save", "*goocastle*"))


def current_turn(session):
    stripped = ESCAPES.sub(b"", bytes(session.raw)).decode("latin-1")
    turns = TURN.findall(stripped)
    if not turns:
        fail("the status line shows no turn counter", session)
    return int(turns[-1])


def prove_movement(session):
    """Walk one square: a direction key must advance the turn counter."""
    for key in DIRECTIONS:
        before = current_turn(session)
        session.send(key)
        session.settle()
        text = session.text()
        if re.search(r"Really attack|\[yn[aq]*\]", text):
            session.send("\x1b")
            session.settle()
            continue
        if re.search(r"You (hit|miss|kill|displace)", text):
            continue
        if current_turn(session) > before:
            return
    fail("no direction key moved the hero", session)


def main():
    if len(sys.argv) != 3:
        fail("usage: xnethack-smoke.py REAL STATE")
    real, state = sys.argv[1], sys.argv[2]
    if saves(state):
        fail("state directory already contains a save file")

    first = Session(real)
    first.expect(r"welcome to xNetHack!", "the new-game welcome")
    first.expect(r"Dlvl:\s*1", "the status line")
    first.settle()
    prove_movement(first)
    saved_turn = current_turn(first)
    first.send("S")
    first.expect(r"Really save\?", "the save prompt")
    first.send("y")
    first.finish("the saving session")
    saved = saves(state)
    if len(saved) != 1:
        fail("expected one save file, found %r" % (saved,))

    second = Session(real)
    second.expect(r"Restoring save file", "the restore notice")
    second.expect(r"welcome back to xNetHack!", "the restore welcome")
    second.settle()
    restored_turn = current_turn(second)
    if restored_turn != saved_turn:
        fail("restored turn T:%d differs from saved turn T:%d"
             % (restored_turn, saved_turn), second)
    # Live restored game screen; exported only after every assertion passes.
    screen = bytes(second.raw)
    second.send("#")
    second.settle(0.3)
    second.write(b"quit\r")
    second.expect(r"Really quit", "the quit prompt")
    second.send("y")
    second.finish("the restored session")
    if saves(state):
        fail("save file was not consumed by the restore")
    with open(os.path.join(state, "xlogfile"), encoding="latin-1") as port:
        if "name=goocastle" not in port.read():
            fail("xlogfile does not record the finished game")

    capture = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
    if capture:
        os.makedirs(os.path.dirname(os.path.abspath(capture)), exist_ok=True)
        with open(capture, "wb") as port:
            port.write(screen)

    sys.stdout.write("xnethack guix smoke passed\n")
    sys.stdout.flush()


if __name__ == "__main__":
    main()
