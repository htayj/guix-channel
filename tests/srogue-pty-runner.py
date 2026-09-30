#!/usr/bin/env python3
"""Exercise Super-Rogue's launcher, score file and path bounds in a fresh HOME.

Usage: srogue-pty-runner.py GAME LIBEXEC-GAME LOCPATH SCRATCH

Run inside fresh user and network namespaces, as the invoking non-root
user.  XDG_DATA_HOME is unset, so the launcher uses the
HOME/.local/share/srogue fallback.
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

GAME, LIBEXEC_GAME, LOCPATH, SCRATCH = sys.argv[1:5]
HOME = os.path.join(SCRATCH, "home")
STATE = os.path.join(HOME, ".local", "share", "srogue")
SCORE = os.path.join(STATE, "srogue.scr")
SAVE = os.path.join(STATE, "srogue.sav")
NAME = "Smoke Tester"
TOO_LONG = b"srogue: state directory is too long (at most 68 bytes)\n"

# encwrite() in state.c XORs every record with this key, restarting it for
# each record.  A score entry is an 80-byte name and a 100-byte line
# " score flags level uid monster explvl exppts date(hex) \n".
KEY = (b"\354\251\243\332A\201|\301\321p\210\251\327\"\257\365t\341%3\271^`~"
       b"\203z{\341};\f\341\231\222e\234\351]\321")
LINE = re.compile(rb" (-?\d+) (\d+) (\d+) (\d+) (\d+) (\d+) (\d+) ([0-9a-f]+) \n")
# 2026-01-01 00:00:00 UTC
SEEDED = (500, "Seeded Hero", 1, 3, 4242, 0, 2, 15, 0x6955B900)
# showtop() lists only positive scores, and a new score ranks above the
# first entry it exceeds, so these placeholders let a zero-gold quit enter
# the table.
PLACEHOLDER = (-1, "", 0, 0, 0, 0, 0, 0, 0)
HEADER = b"Top Ten Adventurers:\nRank\tScore\tName\n"
SEEDED_LINE = (b"1\t500\tSeeded Hero: Thu Jan  1 00:00:00 2026\n"
               b"\t\t--> Chickened out on level 3 [Exp: 2/15]\n")


def fail(message):
    raise SystemExit("srogue smoke: " + message)


def crypt(data):
    return bytes(byte ^ KEY[index % len(KEY)] for index, byte in enumerate(data))


def encode_entry(entry):
    score, name, flags, level, uid, monster, explvl, exppts, date = entry
    line = (f" {score} {flags} {level} {uid} {monster} {explvl} {exppts} "
            f"{date:x} \n").encode()
    return crypt(name.encode().ljust(80, b"\0")) + crypt(line.ljust(100, b"\0"))


def decode_scores(path):
    with open(path, "rb") as port:
        data = port.read()
    if len(data) != 10 * 180:
        fail(f"score file has {len(data)} bytes")
    entries = []
    for index in range(10):
        name = crypt(data[index * 180:index * 180 + 80]).split(b"\0", 1)[0]
        line = crypt(data[index * 180 + 80:index * 180 + 180])
        match = LINE.match(line)
        if not match:
            fail(f"unreadable score line {line!r}")
        fields = [int(value) for value in match.groups()[:7]]
        entries.append((fields[0], name.decode("latin-1"), *fields[1:],
                        int(match.group(8), 16)))
    return entries


def environment(**overrides):
    env = {
        "HOME": HOME,
        "XDG_CONFIG_HOME": os.path.join(SCRATCH, "config"),
        "XDG_CACHE_HOME": os.path.join(SCRATCH, "cache"),
        "XDG_STATE_HOME": os.path.join(SCRATCH, "state"),
        "TMPDIR": os.path.join(SCRATCH, "tmp"),
        "TERM": "xterm-256color",
        "LC_ALL": "C",
        "TZ": "UTC0",
        "PATH": "",
        "ROGUEOPTS": "name=" + NAME,
    }
    env.update(overrides)
    return {key: value for key, value in env.items() if value is not None}


def run(argv, **overrides):
    return subprocess.run(argv, env=environment(**overrides),
                          cwd=os.path.join(SCRATCH, "work"),
                          stdin=subprocess.DEVNULL, capture_output=True,
                          timeout=30, check=False)


def list_scores(**overrides):
    result = run([GAME, "-s"], **overrides)
    if result.returncode != 0 or result.stderr:
        fail(f"score listing failed: {result!r}")
    return result.stdout


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
        while self._read(quiet):
            pass
        return bytes(self.output[self.mark:])

    def send(self, keys):
        self.mark = len(self.output)
        os.write(self.master, keys)

    def dismiss_more(self):
        """Acknowledge every "-- More --" prompt left by the last key."""
        for _ in range(10):
            since = self.settle()
            at = since.rfind(b"-- More --")
            if at < 0 or len(since) - at > 26:
                return
            self.send(b" ")
        fail("too many -- More -- prompts")

    def wait(self, timeout=30):
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
                fail(f"game did not exit: {bytes(self.output[-2000:])!r}")
            self._read(0.2)


def experience(session):
    """The level and points on the last full status line the game drew."""
    shown = re.findall(rb"Exp: (-?\d+)/(-?\d+)", session.output)
    if not shown:
        fail("no experience on the status line")
    return shown[-1]


def start(**overrides):
    session = Session([GAME], environment(**overrides))
    session.expect(re.escape(f"Hello {NAME}, One moment while I open the "
                             "door to the dungeon...".encode()))
    session.expect(rb"Level: 1  Gold:     0  Hp: +\d+\( *\d+\)")
    session.expect(rb"Str: .*Carry:")
    return session


def main():
    if os.geteuid() == 0:
        fail("the runner must not run as root")
    others = [os.path.join(SCRATCH, name)
              for name in ("config", "cache", "state", "tmp", "work")]
    for directory in [HOME, os.path.join(SCRATCH, "l"), *others]:
        os.mkdir(directory)

    # A fresh HOME has no score file: listing prints nothing and creates only
    # the empty state directory.
    if list_scores() != b"":
        fail("unexpected listing without a score file")
    if os.listdir(STATE):
        fail("listing scores wrote state")

    # A read-only seeded table is listed and never rewritten.
    seeded = encode_entry(SEEDED) + encode_entry(PLACEHOLDER) * 9
    with open(SCORE, "wb") as port:
        port.write(seeded)
    os.chmod(SCORE, 0o444)
    try:
        open(SCORE, "r+b").close()
    except PermissionError:
        pass
    else:
        fail("the read-only score file is writable")
    if list_scores() != HEADER + SEEDED_LINE:
        fail(f"unexpected seeded listing {list_scores()!r}")
    with open(SCORE, "rb") as port:
        if port.read() != seeded:
            fail("listing changed the score file")
    os.chmod(SCORE, 0o644)

    # A real game: search for a turn, then quit.  The quit is recorded in the
    # user's own score file below the seeded entry.
    before = time.time()
    session = start()
    session.send(b"s")
    session.dismiss_more()
    session.send(b"Q")
    session.dismiss_more()
    session.expect(re.escape(b"Really quit? [y/n/s]"))
    session.send(b"y")
    session.expect(re.escape(b"[Press return to continue]"))
    session.send(b"\r")
    session.expect(rb"Contents of your pack when you chickened out:")
    session.expect(re.escape(b"[Press return to continue]"))
    session.send(b"\r")
    session.expect(re.escape(HEADER.replace(b"\n", b"\r\n") + SEEDED_LINE
                             .replace(b"\n", b"\r\n")))
    session.expect(re.escape(b"[Press return to exit]"))
    session.send(b"\r")
    if session.wait() != 0:
        fail("quitting failed")
    entries = decode_scores(SCORE)
    if entries[0] != SEEDED:
        fail(f"seeded entry changed: {entries[0]!r}")
    played = entries[1]
    if (played[:4] != (0, NAME, 1, 1) or played[4] != os.getuid()
            or played[6] != 1 or not before - 1 <= played[8] <= time.time() + 1):
        fail(f"unexpected recorded game {played!r}")
    if any(entry[0] != -1 for entry in entries[2:]):
        fail("unexpected extra score entries")
    if sorted(os.listdir(STATE)) != ["srogue.scr"]:
        fail(f"unexpected state files {os.listdir(STATE)!r}")

    # A relative XDG_DATA_HOME is ignored in favour of the HOME fallback.
    if list_scores(XDG_DATA_HOME="relative") != HEADER + SEEDED_LINE:
        fail("relative XDG_DATA_HOME was not ignored")
    if os.path.exists(os.path.join(SCRATCH, "work", "relative")):
        fail("relative XDG_DATA_HOME was used")

    # The longest accepted state directory (68 bytes) saves and restores a
    # game whose 79-byte save path fills the game's 80-byte buffers; the
    # 94-byte save prompt is longer than the last-message buffer.
    long_root = os.path.join(SCRATCH, "l")
    fits = long_root + "/" + "x" * (61 - len(long_root) - 1)
    if len(fits + "/srogue") != 68:
        fail("scratch directory is too long for the length checks")
    long_save = fits + "/srogue/srogue.sav"
    session = start(XDG_DATA_HOME=fits)
    saved = experience(session)
    session.send(b"S")
    # curses compresses the repeated name and wraps this prompt.
    session.expect(rb"Save file \(")
    session.settle()
    session.send(b"y")
    if session.wait() != 0 or not os.path.isfile(long_save):
        fail("saving under the longest state directory failed")
    session = Session([GAME, long_save], environment(XDG_DATA_HOME=fits))
    session.expect(rb"Level: 1  Gold:     0  Hp: ")
    session.expect(rb"Carry:")
    if os.path.exists(long_save):
        fail("restoring did not consume the long save")
    # Experience is a long in the save file; a 64-bit build must restore
    # the level and points the game showed when it saved.
    if experience(session) != saved:
        fail(f"restored experience {experience(session)!r} is not {saved!r}")
    session.send(b"S")
    # The restored screen still shows the end of the first prompt, so
    # curses rewrites only its start.
    session.expect(rb"Save file \(")
    session.settle()
    session.send(b"y")
    if session.wait() != 0 or not os.path.isfile(long_save):
        fail("saving the restored game failed")

    too_long = fits + "y"
    result = run([GAME, "-s"], XDG_DATA_HOME=too_long)
    if (result.returncode != 1 or result.stdout or result.stderr != TOO_LONG
            or os.path.exists(too_long)):
        fail(f"launcher accepted a 69-byte state directory: {result!r}")

    # The limit is in bytes: 68 UTF-8 characters that need more than 68
    # bytes are refused in a UTF-8 locale before anything is created.
    if not any(os.path.isfile(os.path.join(LOCPATH, version, "C.UTF-8",
                                           "LC_CTYPE"))
               for version in os.listdir(LOCPATH)):
        fail("no C.UTF-8 locale in " + LOCPATH)
    wide = os.fsencode(long_root) + b"/" + "\u00e9".encode() * (
        61 - len(long_root) - 1)
    if len(wide.decode() + "/srogue") != 68 or len(wide + b"/srogue") <= 68:
        fail("unexpected multibyte state directory length")
    result = run([GAME, "-s"], XDG_DATA_HOME=wide, LC_ALL="C.UTF-8",
                 GUIX_LOCPATH=LOCPATH)
    if (result.returncode != 1 or result.stdout or result.stderr != TOO_LONG
            or os.path.exists(wide)):
        fail(f"launcher accepted a multibyte state directory: {result!r}")

    # The game itself refuses a HOME that would overflow its buffers.
    direct_home = fits + "/srogue" + "z"
    os.mkdir(direct_home)
    result = run([LIBEXEC_GAME, "-s"], HOME=direct_home)
    if (result.returncode != 1 or result.stdout
            or result.stderr != b"srogue: HOME is too long (at most 68 bytes)\n"
            or os.listdir(direct_home)):
        fail(f"the game accepted a 69-byte HOME: {result!r}")
    os.rmdir(direct_home)

    # Nothing but the launcher's state directories was written.
    for directory in others:
        if os.listdir(directory):
            fail(f"unexpected files in {directory}")
    if sorted(os.listdir(fits)) != ["srogue"]:
        fail(f"unexpected files in {fits}")

    print("SROGUE_PTY_OK")


if __name__ == "__main__":
    main()
