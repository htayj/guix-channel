#!/usr/bin/env python3
"""Play, save, restore and score UltraRogue through real curses sessions.

Usage: urogue-pty-runner.py GAME LIBEXEC-GAME LIBFAKETIME LOCPATH SCRATCH

Run inside fresh user, PID and network namespaces.  libfaketime freezes the
wall clock and the PID namespace fixes process IDs, so the game's seed
(time + pid) and therefore every session below is deterministic.
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

GAME, LIBEXEC_GAME, FAKETIME_LIB, LOCPATH, SCRATCH = sys.argv[1:6]
STATE = os.path.join(SCRATCH, "data", "urogue")
SCORE = os.path.join(STATE, ".rog_score")
SAVE = os.path.join(STATE, "rogue.save")
NAME = "Smoke Tester"
ANSI = re.compile(rb"\x1b(?:\[[0-9;?]*[@-~]|[()][0-9A-Za-z]|[=>])")

# struct sc_ent in rip.c on LP64: long score, char name[76], long gold,
# short flags, short lives, int level, short artifacts, short monster,
# int game_id; ten entries.
SC_ENT = struct.Struct("=q76s4xqhhihhi")
assert SC_ENT.size == 112
EMPTY_LISTING = b"\nTop Ten Adventurers:\nRank  Score    Gold\tName\n"
SEEDED = (500, "Seeded Hero, Level 3 Swordsman", 42, 1, 1, 4, 0, 0, 424242)


def fail(message):
    raise SystemExit("urogue smoke: " + message)


def environment(**overrides):
    env = {
        "HOME": os.path.join(SCRATCH, "home"),
        "XDG_CONFIG_HOME": os.path.join(SCRATCH, "config"),
        "XDG_DATA_HOME": os.path.join(SCRATCH, "data"),
        "XDG_CACHE_HOME": os.path.join(SCRATCH, "cache"),
        "XDG_STATE_HOME": os.path.join(SCRATCH, "state"),
        "TMPDIR": os.path.join(SCRATCH, "tmp"),
        "TERM": "xterm-256color",
        "LC_ALL": "C",
        "PATH": "",
        "SROGUEOPTS": "name=" + NAME,
        "LD_PRELOAD": FAKETIME_LIB,
        "FAKETIME": "2026-01-01 00:00:00",
        "FAKETIME_DONT_FAKE_MONOTONIC": "1",
    }
    env.update(overrides)
    return env


def encode_entry(entry):
    score, name, gold, flags, lives, level, artifacts, monster, game = entry
    return SC_ENT.pack(score, name.encode(), gold, flags, lives, level,
                       artifacts, monster, game)


def decode_scores(path):
    with open(path, "rb") as port:
        data = port.read()
    if len(data) != 10 * SC_ENT.size:
        fail(f"score file has {len(data)} bytes")
    entries = []
    for index in range(10):
        fields = list(SC_ENT.unpack_from(data, index * SC_ENT.size))
        fields[1] = fields[1].split(b"\0", 1)[0].decode()
        entries.append(tuple(fields))
    return entries


def listing_line(entry):
    score, name, gold, flags = entry[:4]
    reason = ("killed", "quit")[flags]
    return (f"      {score:<8} {gold:<8}\t{name}:\n"
            f"\t\t\t{reason} on level {entry[5]}.\n").encode()


def list_scores(**overrides):
    run = subprocess.run([GAME, "-n", "-mc", "-s"], env=environment(**overrides),
                         stdin=subprocess.DEVNULL, capture_output=True,
                         timeout=30, check=False)
    if run.returncode != 0 or run.stderr:
        fail(f"score listing failed {run.returncode}: {run.stderr!r}")
    return run.stdout


class Session:
    def __init__(self, argv, env):
        self.pid, self.master = os.forkpty()
        if self.pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack("HHHH", 24, 80, 0, 0))
                os.chdir(os.path.join(SCRATCH, "work"))
                os.execve(argv[0], argv, env)
            finally:
                os._exit(127)
        self.output = bytearray()
        self.mark = 0
        self.status = None

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
        return chunk

    def expect(self, pattern, timeout=30):
        """Wait for PATTERN in output since the last key; return the match."""
        regex = re.compile(pattern)
        deadline = time.monotonic() + timeout
        while True:
            match = regex.search(self.output, self.mark)
            if match:
                return match
            remaining = deadline - time.monotonic()
            if remaining <= 0 or self._read(min(remaining, 0.2)) == b"":
                fail(f"no {pattern!r} in {bytes(self.output[-2000:])!r}")

    def settle(self, quiet=0.8):
        """Read until the screen has been quiet; return text since the key."""
        while self._read(quiet):
            pass
        return bytes(self.output[self.mark:])

    def send(self, keys):
        self.mark = len(self.output)
        os.write(self.master, keys)

    def dismiss_more(self):
        """Acknowledge every pending --More-- message prompt."""
        for _ in range(10):
            if not ANSI.sub(b"", self.settle()).endswith(b"--More--"):
                return
            self.send(b" ")
        fail("too many --More-- prompts")

    def wait(self, timeout=30):
        deadline = time.monotonic() + timeout
        while True:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                while self._read(0.1):
                    pass
                os.close(self.master)
                self.status = os.waitstatus_to_exitcode(status)
                return self.status
            if time.monotonic() > deadline:
                os.kill(self.pid, 9)
                fail(f"game did not exit: {bytes(self.output[-2000:])!r}")
            self._read(0.2)


def new_character(session):
    session.expect(rb"What character class do you desire\?")
    session.send(b"1")
    session.expect(rb"Would you like to re-roll the character\?")
    session.send(b"n")
    # curses rewrites only "re-roll the" -> "save this" on the prompt line.
    session.expect(rb"save this")
    session.send(b"n")
    session.expect(rb"Welcome to urogue!")
    session.expect(rb"Lvl:1  Au:0  Hp:\d+\(\d+\)  Ac:-?\d+  Exp:1/0  Veteran")


def inventory(session):
    session.send(b"i")
    page = session.expect(rb"(?s)\x1b\[H\x1b\[2J(.*?)--Press space to continue--")
    items = sorted(re.findall(rb"[a-z]\) [^\r\x1b]+", page.group(1)))
    if len(items) < 2:
        fail(f"implausible inventory {items!r}")
    session.send(b" ")
    session.settle()
    return items


def eat_ration(session):
    session.send(b"e")
    session.expect(rb"eat what\? \(\* for list\):")
    session.send(b"*")
    # With a single ration get_item shows it as a message and asks again.
    ration = session.expect(rb"([a-z])\) A food ration\.\x1b\[K--More--")
    session.send(b" ")
    session.expect(rb"eat what\? \(\* for list\):")
    session.send(ration.group(1))
    taste = session.expect(rb"Yuk, this food tastes awful\.|Yum, that tasted good\.")
    session.dismiss_more()
    return taste.group(0).startswith(b"Yuk")


def main():
    raw_capture = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")

    # The reviewed runtime contract: a fresh tree lists an empty table
    # without creating a score file.
    if os.path.exists(STATE):
        fail("state directory already exists")
    if list_scores() != EMPTY_LISTING:
        fail("unexpected empty score listing")
    if os.listdir(STATE):
        fail("listing scores wrote state")

    # A read-only seeded score table is parsed, never rewritten.
    seeded = encode_entry(SEEDED) + bytes(9 * SC_ENT.size)
    with open(SCORE, "wb") as port:
        port.write(seeded)
    os.chmod(SCORE, 0o444)
    # The namespace maps the invoking non-root user, so the mode is enforced.
    if os.geteuid() == 0:
        fail("the runner must not run as root")
    try:
        open(SCORE, "r+b").close()
    except PermissionError:
        pass
    else:
        fail("the read-only score file is writable")
    expected_seeded = EMPTY_LISTING + listing_line(SEEDED)
    if list_scores() != expected_seeded:
        fail("unexpected seeded score listing")
    with open(SCORE, "rb") as port:
        if port.read() != seeded:
            fail("score listing changed the score file")
    os.chmod(SCORE, 0o644)

    # Start fighters until one earns experience from a bad-tasting ration.
    # A zero-experience quit must not record a score or leave a save.
    for second in range(20):
        env = environment(FAKETIME=f"2026-01-01 00:00:{second:02d}")
        session = Session([GAME, "-n", "-mc"], env)
        new_character(session)
        if eat_ration(session):
            break
        session.send(b"Q")
        session.expect(rb"Really quit\?")
        session.send(b"y")
        session.expect(rb"Contents of your pack when you quit:")
        if session.wait() != 0:
            fail("quitting failed")
        with open(SCORE, "rb") as port:
            if port.read() != seeded:
                fail("a zero-score quit changed the score file")
        if os.path.exists(SAVE):
            fail("quitting left a saved game")
    else:
        fail("no fighter found an awful ration")

    saved_items = inventory(session)
    if raw_capture:
        with open(raw_capture, "wb") as port:
            port.write(session.output)
    session.send(b"S")
    session.expect(re.escape(f"Save file [{SAVE}]: ".encode()))
    session.send(b"\r")
    if session.wait() != 0:
        fail("saving failed")
    if not os.path.isfile(SAVE) or os.path.getsize(SAVE) < 1000:
        fail("the game was not saved")

    # Restore consumes the save and brings back the same character.
    session = Session([GAME, "-mc"], environment())
    session.expect(rb"Exp:1/1  Veteran")
    if os.path.exists(SAVE):
        fail("restoring did not consume the save")
    if inventory(session) != saved_items:
        fail("restored inventory differs")
    session.send(b"Q")
    session.expect(rb"Really quit\?")
    session.send(b"y")
    worth = session.expect(rb"Carrying objects worth (\d+) gold pieces")
    session.expect(rb"--More--")
    session.send(b" ")
    session.expect(rb"Top Ten Adventurers:")
    if session.wait() != 0:
        fail("quitting the restored game failed")
    final = ANSI.sub(b"", bytes(session.output)).replace(b"\r", b"")
    played_line = re.escape(
        f"{NAME}, Level 1 Veteran:\n\t\t\tquit on level 1 (just now).\n"
        .encode())
    if not re.search(rb"1     500 .*\n.*\n2     1        \d+ +\t" + played_line,
                     final):
        fail(f"final score table missing the game: {final[-1200:]!r}")

    entries = decode_scores(SCORE)
    if entries[0] != SEEDED:
        fail(f"seeded entry changed: {entries[0]!r}")
    played = entries[1]
    if (played[:2] != (1, f"{NAME}, Level 1 Veteran")
            or played[2] != int(worth.group(1)) or played[3:8] != (1, 1, 1, 0, 0)
            or played[8] in (0, SEEDED[8])):
        fail(f"unexpected recorded game {played!r}")
    if any(entry[0] for entry in entries[2:]):
        fail("unexpected extra score entries")
    if list_scores() != expected_seeded + listing_line(played):
        fail("unexpected final score listing")
    if sorted(os.listdir(STATE)) != [".rog_score"]:
        fail(f"unexpected state files {os.listdir(STATE)!r}")

    # Without an absolute XDG_DATA_HOME the launcher uses HOME.
    fallback = os.path.join(SCRATCH, "fallback-home")
    if list_scores(HOME=fallback, XDG_DATA_HOME="relative") != EMPTY_LISTING:
        fail("unexpected fallback listing")
    if os.listdir(os.path.join(fallback, ".local/share/urogue")):
        fail("fallback listing wrote state")

    # The longest accepted state directory (68 bytes) still saves a game
    # whose 79-byte path fits the game's 80-byte buffers.
    long_root = os.path.join(SCRATCH, "l")
    fits = long_root + "/" + "x" * (61 - len(long_root) - 1)
    if len(fits + "/urogue") != 68:
        fail("scratch directory is too long for the length checks")
    session = Session([GAME, "-n", "-mc"], environment(XDG_DATA_HOME=fits))
    new_character(session)
    session.send(b"S")
    long_save = fits + "/urogue/rogue.save"
    # curses compresses the repeated name and wraps this 80-column prompt.
    session.expect(rb"Save file \[")
    session.send(b"\r")
    if session.wait() != 0 or not os.path.isfile(long_save):
        fail("saving under the longest state directory failed")

    too_long = fits + "y"
    run = subprocess.run([GAME, "-n", "-mc", "-s"],
                         env=environment(XDG_DATA_HOME=too_long),
                         capture_output=True, timeout=30, check=False)
    if (run.returncode != 1 or run.stdout
            or run.stderr != b"urogue: state directory is too long "
                              b"(at most 68 bytes)\n"
            or os.path.exists(too_long)):
        fail(f"launcher accepted a 69-byte state directory: {run!r}")

    # The limit is in bytes: 68 UTF-8 characters that need more than 68
    # bytes are refused in a UTF-8 locale before anything is created.
    if not any(os.path.isfile(os.path.join(LOCPATH, version,
                                           "C.UTF-8", "LC_CTYPE"))
               for version in os.listdir(LOCPATH)):
        fail("no C.UTF-8 locale in " + LOCPATH)
    wide = os.fsencode(long_root) + b"/" + "\u00e9".encode() * (
        61 - len(long_root) - 1)
    if len(wide.decode() + "/urogue") != 68 or len(wide + b"/urogue") <= 68:
        fail("unexpected multibyte state directory length")
    run = subprocess.run([GAME, "-n", "-mc", "-s"],
                         env=environment(XDG_DATA_HOME=wide, LC_ALL="C.UTF-8",
                                         GUIX_LOCPATH=LOCPATH),
                         capture_output=True, timeout=30, check=False)
    if (run.returncode != 1 or run.stdout
            or run.stderr != b"urogue: state directory is too long "
                              b"(at most 68 bytes)\n"
            or os.path.exists(wide)):
        fail(f"launcher accepted a multibyte state directory: {run!r}")

    # The game itself refuses a HOME that would overflow its buffers.
    direct_home = fits + "/urogue" + "z"
    os.mkdir(direct_home)
    run = subprocess.run([LIBEXEC_GAME, "-n", "-mc", "-s"],
                         env=environment(HOME=direct_home),
                         capture_output=True, timeout=30, check=False)
    if (run.returncode != 1 or run.stdout
            or run.stderr != b"urogue: HOME is too long (at most 68 bytes)\n"
            or os.listdir(direct_home)):
        fail(f"the game accepted a 69-byte HOME: {run!r}")

    print("UROGUE_PTY_OK")


if __name__ == "__main__":
    main()
