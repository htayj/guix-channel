#!/usr/bin/env python3
"""Play the installed LineRogue through its public launcher in a PTY.

Usage: linerogue-smoke LAUNCHER OUTPUT PYTE-SITE WCWIDTH-SITE

The level layout is seeded from the wall clock, so the player reads the
emulated screen before every turn and steers onto open floor.  Two sessions
share one disposable XDG data tree.  The first steers the bike through at
least ten verified turns, crashes it into its own trail and declines another
game at the Game Over prompt; its high-score file must decode to the table it
displayed.  Because a short game often scores 0, which leaves the default
table unchanged, the smoke then rewrites the integers in that game-written
file (keeping the marshalling header the executable produced) to a distinct
sentinel table.  The second session's Game Over screen and rewritten file must
show that sentinel table merged with the second score, which the default
table cannot produce.  Nothing outside the disposable tree may change.
"""

import errno
import fcntl
import os
import pty
import re
import select
import shutil
import signal
import stat
import struct
import sys
import tempfile
import termios
import time
from pathlib import Path

if len(sys.argv) != 5:
    raise SystemExit("usage: linerogue-smoke LAUNCHER OUTPUT PYTE WCWIDTH")

launcher, output = sys.argv[1], Path(sys.argv[2])
sys.path[:0] = [sys.argv[3], sys.argv[4]]
import pyte  # noqa: E402

ROWS, COLUMNS = 24, 80
# Kaya's Constants.k: the map spans x 0..72 and y 0..21; the HUD follows.
X_SIZE, Y_SIZE = 72, 21
# getCommand() finishes each turn by blanking the HUD marker cells, the last
# of which is (59, ySize+2); curses then parks the cursor after it.
COMMAND_CURSOR = (Y_SIZE + 2, 60)
# endGame() prints "Play again? (Y/n)" at (29, 16) and then reads a key.
AGAIN_PROMPT = "Play again? (Y/n)"
AGAIN_CURSOR = (16, 29 + len(AGAIN_PROMPT))
MOVES = {"h": (-1, 0), "j": (0, 1), "k": (0, -1), "l": (1, 0)}
REVERSE = {"h": "l", "l": "h", "j": "k", "k": "j"}
SAFE = set(".!X")
CREATURES = set("<>^v")
EVIDENCE_TURNS = 5
PLAYED_TURNS = 10
MAX_GAMES = 5
# A descending five-entry table no played game can produce from the default
# [0, 0, 0, 0, 0] in one short session.
SENTINEL_TABLE = (9105, 7304, 5203, 3102, 1001)
# DiskCache.toCache() writes Kaya's text marshalling of the [Int] table:
# "[cache-id hash][function-table hash]" then "A[[0][capacity]", one
# "I[n]" per entry and "]" (rts/sizes.h.in, rts/ValueFuns.cc).
HIGHSCORE = re.compile(
    r"(\[-?\d+\]\[-?\d+\]A\[\[0\]\[\d+\])((?:I\[-?\d+\])*)(\]\s*)\Z")


class Failure(Exception):
    pass


def snapshot(root):
    """Return every path below ROOT with its type, mode, size and mtime."""
    entries = {}
    for directory, names, files in os.walk(root):
        for name in names + files:
            path = os.path.join(directory, name)
            info = os.lstat(path)
            entries[os.path.relpath(path, root)] = (
                stat.S_IFMT(info.st_mode), stat.S_IMODE(info.st_mode),
                info.st_size, info.st_mtime_ns)
    return entries


class Session:
    """One run of the public launcher in an 80x24 PTY."""

    def __init__(self, environment):
        self.stream = bytearray()
        self.screen = pyte.Screen(COLUMNS, ROWS)
        self.parser = pyte.ByteStream(self.screen)
        self.closed = False
        self.status = None
        self.pid, self.master = pty.fork()
        if self.pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack("HHHH", ROWS, COLUMNS, 0, 0))
                os.execve(launcher, [launcher], environment)
            finally:
                os._exit(127)

    def read(self, timeout):
        """Read available output; return False once the child closed it."""
        ready, _, _ = select.select([self.master], [], [], timeout)
        if not ready:
            return True
        try:
            chunk = os.read(self.master, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            chunk = b""
        if not chunk:
            self.closed = True
            return False
        self.stream.extend(chunk)
        self.parser.feed(chunk)
        return True

    def send(self, key):
        os.write(self.master, key.encode("ascii"))

    def cursor(self):
        return self.screen.cursor.y, self.screen.cursor.x

    def lines(self):
        return self.screen.display

    def text(self):
        return "\n".join(self.lines())

    def wait(self, deadline):
        """Return 'command', 'again', 'exited' or 'other' once quiet."""
        quiet_since = time.monotonic()
        while True:
            if time.monotonic() > deadline:
                raise Failure("LineRogue smoke timed out")
            before = len(self.stream)
            if not self.read(0.05):
                return "exited"
            now = time.monotonic()
            if len(self.stream) != before:
                quiet_since = now
                continue
            quiet = now - quiet_since
            if quiet < 0.2:
                continue
            lines = self.lines()
            if (self.cursor() == COMMAND_CURSOR
                    and lines[Y_SIZE + 1].startswith("Power: ")
                    and lines[Y_SIZE + 2].startswith("Score: ")):
                return "command"
            if AGAIN_PROMPT in lines[16] and self.cursor() == AGAIN_CURSOR:
                return "again"
            if quiet >= 2.0:
                return "other"

    def finish(self, deadline):
        while not self.closed:
            if time.monotonic() > deadline:
                raise Failure("LineRogue did not exit after declining")
            self.read(0.1)
        _, self.status = os.waitpid(self.pid, 0)
        os.close(self.master)
        self.pid = None

    def kill(self):
        if self.pid is not None:
            try:
                os.kill(self.pid, signal.SIGKILL)
                os.waitpid(self.pid, 0)
            except (ProcessLookupError, ChildProcessError):
                pass
            os.close(self.master)
            self.pid = None


def find_player(lines):
    for y in range(Y_SIZE + 1):
        x = lines[y].find("@", 0, X_SIZE + 1)
        if x >= 0:
            return x, y
    return None


def choose_move(lines, position, heading):
    """Pick the direction with the longest run of open floor ahead."""
    x, y = position
    best, best_score = None, None
    for key, (dx, dy) in MOVES.items():
        run = 0
        cx, cy = x + dx, y + dy
        while (run < 8 and 0 <= cx <= X_SIZE and 0 <= cy <= Y_SIZE
               and lines[cy][cx] in SAFE):
            run += 1
            cx, cy = cx + dx, cy + dy
        if run == 0:
            continue
        score = run * 4 + (1 if key == heading else 0)
        tx, ty = x + dx, y + dy
        for ny in range(max(0, ty - 2), min(Y_SIZE, ty + 2) + 1):
            for nx in range(max(0, tx - 2), min(X_SIZE, tx + 2) + 1):
                if (abs(nx - tx) + abs(ny - ty) <= 2
                        and lines[ny][nx] in CREATURES):
                    score -= 12
        if best_score is None or score > best_score:
            best, best_score = key, score
    return best


def game_over(session):
    text = session.text()
    scored = re.search(r"You scored (-?\d+) points\.", text)
    level = re.search(r"You were killed on level (\d+)\.", text)
    table = [int(value) for _, value in sorted(
        re.findall(r"([1-5]): (-?\d+) points", text))]
    if "Game Over" not in text or not scored or not level or len(table) != 5:
        raise Failure("LineRogue Game Over screen was incomplete")
    return int(scored.group(1)), table


def read_highscore(path):
    """Split a game-written high-score file into header, table and footer."""
    text = path.read_text(encoding="ascii")
    match = HIGHSCORE.match(text)
    if not match:
        raise Failure("LineRogue high-score file is not a marshalled [Int]: "
                      "%r" % text)
    scores = [int(value) for value in re.findall(r"I\[(-?\d+)\]",
                                                 match.group(2))]
    return match.group(1), scores, match.group(3)


def expect_table(previous, score, table):
    expected = sorted(previous + [score], reverse=True)[:5]
    if table != expected:
        raise Failure("LineRogue high-score table was not updated from %r "
                      "with %d: %r" % (previous, score, table))


def play(session, deadline, table, verified_goal, capture):
    """Play games until one survives VERIFIED_GOAL turns, then crash it.

    Return (updated high-score table, raw evidence length or None)."""
    evidence = None
    last_live = None
    games = 0
    turns = 0
    heading = None
    crashing = 0
    waiting_for_summary = False
    state = session.wait(deadline)
    while True:
        if state == "exited":
            raise Failure("LineRogue exited during play")
        if state == "again":
            score, shown = game_over(session)
            expect_table(table, score, shown)
            table = shown
            if capture and evidence is None:
                # The game ended before the evidence turn; keep its latest
                # live turn, if any, so the capture still ends in play.
                evidence = last_live
            games += 1
            if crashing:
                return table, evidence
            if games >= MAX_GAMES:
                raise Failure("LineRogue bike never survived %d turns"
                              % verified_goal)
            session.send("y")
            turns, heading, crashing = 0, None, 0
            state = session.wait(deadline)
            continue
        if state == "other":
            if waiting_for_summary:
                raise Failure("LineRogue stopped at an unrecognised screen:\n"
                              + session.text())
            # The bike crashed: endGame() discards one key before its
            # summary.
            waiting_for_summary = True
            session.send(" ")
            state = session.wait(deadline)
            continue
        waiting_for_summary = False
        lines = session.lines()
        position = find_player(lines)
        if position is None:
            raise Failure("LineRogue map has no player")
        if capture and evidence is None and turns > 0:
            last_live = len(session.stream)
            if turns >= EVIDENCE_TURNS:
                evidence = last_live
        if turns >= verified_goal:
            if crashing >= 5:
                raise Failure("LineRogue bike could not be crashed")
            # Reverse into the bike's own trail: a certain collision.
            crashing += 1
            heading = REVERSE[heading]
            session.send(heading)
            state = session.wait(deadline)
            continue
        key = choose_move(lines, position, heading)
        if key is None:
            key = heading or "l"
        session.send(key)
        state = session.wait(deadline)
        if state == "command":
            dx, dy = MOVES[key]
            x, y = position
            after = session.lines()
            if (find_player(after) == (x + dx, y + dy)
                    and after[y][x] == "*"):
                turns += 1
                heading = key


def run_session(environment, deadline, table, verified_goal, capture):
    session = Session(environment)
    try:
        table, evidence = play(session, deadline, table, verified_goal,
                               capture)
        session.send("n")
        session.finish(deadline)
    finally:
        session.kill()
    if not os.WIFEXITED(session.status) or os.WEXITSTATUS(session.status):
        raise Failure("LineRogue exited unsuccessfully")
    if b"Oops!" in session.stream:
        raise Failure("LineRogue reported an uncaught exception")
    return table, evidence, bytes(session.stream)


def main():
    scratch = Path(tempfile.mkdtemp(prefix="linerogue-smoke.",
                                    dir=os.environ.get("TMPDIR")))
    try:
        names = ("home", "config", "data", "cache", "state", "runtime", "tmp")
        for name in names:
            (scratch / name).mkdir()
        environment = {
            "HOME": str(scratch / "home"),
            "XDG_CONFIG_HOME": str(scratch / "config"),
            "XDG_DATA_HOME": str(scratch / "data"),
            "XDG_CACHE_HOME": str(scratch / "cache"),
            "XDG_STATE_HOME": str(scratch / "state"),
            "XDG_RUNTIME_DIR": str(scratch / "runtime"),
            "TMPDIR": str(scratch / "tmp"),
            # A colour terminal without REP or insert/delete-line updates,
            # so every map cell is drawn explicitly in the captured stream.
            "TERM": "xterm-color",
            "LC_ALL": "C",
            "PATH": "/nonexistent",
        }
        store_before = snapshot(output)
        deadline = time.monotonic() + 100
        table, evidence, stream = run_session(
            environment, deadline, [0] * 5, PLAYED_TURNS, True)
        highscore = scratch / "data/linerogue/.linerogue/highscore"
        if not highscore.is_file() or highscore.stat().st_size == 0:
            raise Failure("LineRogue did not write its high-score table")
        # Persistence oracle.  The fixture is limited to the integers of this
        # run's own game-written file: the marshalling header (the cache-id
        # and function-table hashes of this executable) and the array layout
        # are kept exactly as the game wrote them.
        header, first_table, footer = read_highscore(highscore)
        if first_table != table:
            raise Failure("LineRogue high-score file holds %r but showed %r"
                          % (first_table, table))
        highscore.write_text(header + "".join(
            "I[%d]" % score for score in SENTINEL_TABLE) + footer,
            encoding="ascii")
        table, _, _ = run_session(environment, deadline,
                                  list(SENTINEL_TABLE), 1, False)
        _, written_table, _ = read_highscore(highscore)
        if written_table != table:
            raise Failure("LineRogue high-score file holds %r but showed %r"
                          % (written_table, table))
        written = sorted(str(path.relative_to(scratch))
                         for path in scratch.rglob("*"))
        if written != ["cache", "config", "data", "data/linerogue",
                       "data/linerogue/.linerogue",
                       "data/linerogue/.linerogue/highscore",
                       "home", "runtime", "state", "tmp"]:
            raise Failure("LineRogue wrote unexpected files: %r" % written)
        if snapshot(output) != store_before:
            raise Failure("LineRogue modified its store output")
        if evidence is None:
            raise Failure("LineRogue gameplay frame was not captured")
        raw_capture = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
        if raw_capture:
            capture = Path(raw_capture)
            capture.parent.mkdir(parents=True, exist_ok=True)
            # An exact prefix of the first session's PTY stream, ending on
            # a live turn with the map, trail and Power/Score HUD drawn.
            capture.write_bytes(stream[:evidence])
    except Failure as error:
        raise SystemExit(str(error))
    finally:
        shutil.rmtree(scratch, ignore_errors=True)
    print("linerogue isolated smoke passed")


main()
