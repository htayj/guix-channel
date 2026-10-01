#!/usr/bin/env python3
"""Exercise the public Pyro launcher, without installing a proof entry point.

Usage: pyro-smoke.py LAUNCHER EVIDENCE_DIRECTORY PYTE_SITE WCWIDTH_SITE

Both games use an 80x25 terminal and the same otherwise-empty isolated tree.
The issue captures are identical, exact prefixes of the first live session,
ending after its fourth verified movement.  Pyro has no save/load command:
its only native persistent file is pyro.log, rewritten on each launch.
Scratch, terminal streams, log copies and a behavioral report are retained.
"""

import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import sys
import tempfile
import termios
import time
import uuid


class Failure(Exception):
    pass


def require(condition, message):
    if not condition:
        raise Failure(message)


# io_curses.PutTile offsets the 79x21 dungeon by two message rows.  The
# status line is row 23; neither it nor the message/menu area is a map.
ROWS, COLUMNS = 25, 80
MAP_TOP, MAP_BOTTOM, MAP_WIDTH = 2, 23, 79
MOVES = {
    "1": (-1, 1), "2": (0, 1), "3": (1, 1), "4": (-1, 0),
    "6": (1, 0), "7": (-1, -1), "8": (0, -1), "9": (1, -1),
}


class Session:
    def __init__(self, launcher, environment, cwd, pyte):
        self.stream = bytearray()
        self.screen = pyte.Screen(COLUMNS, ROWS)
        self.parser = pyte.ByteStream(self.screen)
        self.closed = False
        self.status = None
        self.pid, self.master = pty.fork()
        if self.pid == 0:
            try:
                os.chdir(cwd)
                fcntl.ioctl(0, termios.TIOCSWINSZ,
                            struct.pack("HHHH", ROWS, COLUMNS, 0, 0))
                os.execve(launcher, [launcher], environment)
            except BaseException as error:
                os.write(2, ("launcher failed: %s\n" % error).encode())
                os._exit(127)

    def read(self, timeout):
        if self.closed:
            return False
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

    def text(self):
        return "\n".join(self.screen.display)

    def send(self, key):
        require(not self.closed, "terminal closed before sending %r" % key)
        before = len(self.stream)
        data = key.encode("ascii")
        while data:
            sent = os.write(self.master, data)
            require(sent > 0, "terminal input made no progress")
            data = data[sent:]
        return before

    def wait(self, predicate, description, after=0, more=True):
        """Wait for fresh, quiet output, acknowledging native [more] pauses."""
        deadline = time.monotonic() + 15
        quiet_since = time.monotonic()
        acknowledged = 0
        while time.monotonic() < deadline:
            before = len(self.stream)
            require(self.read(0.05), "terminal exited while waiting for " + description)
            now = time.monotonic()
            if len(self.stream) != before:
                quiet_since = now
                continue
            if now - quiet_since < 0.2 or len(self.stream) <= after:
                continue
            if more and "[more]" in self.screen.display[0]:
                acknowledged += 1
                require(acknowledged <= 32, "too many [more] pauses: " + description)
                after = self.send(" ")
                quiet_since = now
                continue
            result = predicate()
            if result:
                return result
        raise Failure("timed out waiting for " + description + "\n" + self.text())

    def finish(self):
        deadline = time.monotonic() + 10
        while not self.closed:
            require(time.monotonic() < deadline, "game did not close its terminal")
            self.read(0.05)
        while self.pid is not None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = status
                self.pid = None
                break
            require(time.monotonic() < deadline, "game did not exit")
            time.sleep(0.05)
        require(os.WIFEXITED(self.status) and os.WEXITSTATUS(self.status) == 0,
                "launcher exited uncleanly: wait status %r" % self.status)

    def close(self):
        """On every failure, kill the PTY process group and reap the child."""
        if self.pid is not None:
            try:
                os.killpg(self.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            # Reap even when kill reported an already-exited child.
            try:
                _, self.status = os.waitpid(self.pid, 0)
            except ChildProcessError:
                pass
            self.pid = None
        # Retain any final output already queued in the PTY, including errors.
        deadline = time.monotonic() + 1
        while not self.closed and time.monotonic() < deadline:
            self.read(0.05)
        os.close(self.master)


def player_position(session):
    lines = session.screen.display
    if not all(token in lines[MAP_BOTTOM] for token in ("Lvl:", "HP:", "DLvl:")):
        return None
    positions = [(x, y) for y in range(MAP_TOP, MAP_BOTTOM)
                 for x in range(MAP_WIDTH) if lines[y][x] == "@"]
    if len(positions) != 1:
        return None
    position = positions[0]
    if (session.screen.cursor.x, session.screen.cursor.y) != position:
        return None
    return position


def choose_move(session, position, visited):
    """Use only visible neighboring floor; prefer unvisited safe destinations."""
    x, y = position
    lines = session.screen.display
    candidates = []
    for key, (dx, dy) in MOVES.items():
        nx, ny = x + dx, y + dy
        if not (0 <= nx < MAP_WIDTH and MAP_TOP <= ny < MAP_BOTTOM):
            continue
        if lines[ny][nx] != ".":
            continue
        # Prefer destinations away from visible creatures, features and items.
        hazards = sum(lines[ay][ax] not in " .#@"
                      for ay in range(max(MAP_TOP, ny - 1), min(MAP_BOTTOM, ny + 2))
                      for ax in range(max(0, nx - 1), min(MAP_WIDTH, nx + 2)))
        candidates.append(((nx, ny) in visited, hazards, dx != 0 and dy != 0,
                           key, (nx, ny)))
    require(candidates, "no visible neighboring '.' floor at %r" % (position,))
    _, _, _, key, destination = min(candidates)
    return key, destination


def play(launcher, environment, cwd, pyte, evidence, number):
    session = Session(launcher, environment, cwd, pyte)
    name = "PyroProof" + uuid.uuid4().hex[:12]
    report = {"name": name, "movements": []}
    try:
        session.wait(lambda: "What is your name, adventurer?" in session.text(),
                     "the name prompt", more=False)
        after = session.send(name + "\n")
        session.wait(lambda: ("Which god will you follow, " + name in session.text()
                             and "a - Krol" in session.text()),
                     "the first god choice", after, more=False)
        after = session.send("a")
        session.wait(lambda: ("Choose your race, " + name in session.text()
                             and "a - Dwarf of Krol (Warrior)" in session.text()),
                     "the first race choice", after, more=False)
        after = session.send("a")
        position = session.wait(lambda: player_position(session), "the live dungeon", after)
        report["initial_position"] = position
        visited = {position}
        for turn in range(1, 5):
            key, destination = choose_move(session, position, visited)
            after = session.send(key)
            actual = session.wait(lambda: player_position(session),
                                  "movement %d redraw" % turn, after)
            require(actual != position, "numpad %s did not move @ from %r" % (key, position))
            require(actual == destination,
                    "numpad %s moved @ to %r, expected %r" % (key, actual, destination))
            report["movements"].append({"key": key, "from": position, "to": actual})
            visited.add(actual)
            position = actual
        require(len(report["movements"]) >= 4, "fewer than four actual position changes")
        require(player_position(session) == position, "fourth movement was not a live map")
        report["distinct_positions"] = len(visited)
        report["capture_bytes"] = len(session.stream)
        if number == 1:
            # No synthetic redraw, screenshot or exit output: this is the exact
            # live prefix just observed after the fourth successful movement.
            prefix = bytes(session.stream)
            (evidence / "issue-713.raw").write_bytes(prefix)
            (evidence / "issue-477.raw").write_bytes(prefix)
            (evidence / "fourth-movement.txt").write_text(session.text() + "\n")
        after = session.send("i")
        session.wait(lambda: ("Items in backpack:" in session.text()
                             or "You are not carrying anything." in session.text()),
                     "inventory", after, more=False)
        after = session.send(" ")
        returned = session.wait(lambda: player_position(session), "inventory return", after)
        require(returned == position, "inventory changed the player position")
        report["inventory_return"] = True
        after = session.send("?")
        session.wait(lambda: all(token in session.text() for token in
                                 ("- Keyboard Commands -", "Show inventory",
                                  "List all commands", "Quit (immedately)", "[Press any key]")),
                     "public command help", after, more=False)
        after = session.send(" ")
        returned = session.wait(lambda: player_position(session), "help return", after)
        require(returned == position, "command help changed the player position")
        report["help_return"] = True
        after = session.send("q")
        session.wait(lambda: "Really quit the game? [y/n]:" in session.text(),
                     "quit confirmation", after)
        after = session.send("y")
        session.wait(lambda: ("Game over." in session.text()
                             and "[Press any key]" in session.text()),
                     "game-over acknowledgement", after, more=False)
        session.send(" ")
        session.finish()
        report["exit_status"] = os.WEXITSTATUS(session.status)
        return report
    finally:
        try:
            session.close()
        finally:
            (evidence / ("session-%d.raw" % number)).write_bytes(bytes(session.stream))
            (evidence / ("session-%d-final.txt" % number)).write_text(session.text() + "\n")


def verify_tree(scratch):
    empty = ("home", "config", "data", "cache", "runtime", "tmp", "cwd",
             "config-dirs", "data-dirs")
    expected = sorted(list(empty) + ["state", "state/pyro", "state/pyro/pyro.log"])
    written = sorted(str(path.relative_to(scratch)) for path in scratch.rglob("*"))
    require(written == expected, "unexpected scratch paths: %r" % written)
    for name in empty:
        require(not any((scratch / name).iterdir()), name + " was written outside XDG state")
    state = scratch / "state"
    actual = sorted(str(path.relative_to(state)) for path in state.rglob("*"))
    require(actual == ["pyro", "pyro/pyro.log"],
            "unexpected native state paths: %r" % actual)
    require((state / "pyro").is_dir() and not (state / "pyro").is_symlink(),
            "native state directory is not a real directory")
    log = state / "pyro/pyro.log"
    require(log.is_file() and not log.is_symlink(), "native pyro.log is not a regular file")
    contents = log.read_bytes()
    lines = contents.splitlines()
    require(lines and lines[0] == b"Log initialized.", "pyro.log did not begin normally")
    require(lines[-1] == b"Game ended normally.", "pyro.log did not end normally")
    return log, contents


def main():
    require(len(sys.argv) == 5,
            "usage: pyro-smoke.py LAUNCHER EVIDENCE_DIRECTORY PYTE_SITE WCWIDTH_SITE")
    launcher = str(Path(sys.argv[1]).resolve())
    evidence = Path(sys.argv[2]).resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    # Refuse to confuse a previous proof's captures with this run's outcome.
    require(not any((evidence / name).exists() for name in
                    ("issue-713.raw", "issue-477.raw", "session-1.raw", "session-2.raw",
                     "session-1.pyro.log", "session-2.pyro.log", "report.json")),
            "evidence directory already contains Pyro proof files")
    sys.path[:0] = [sys.argv[3], sys.argv[4]]
    import pyte

    scratch = Path(tempfile.mkdtemp(prefix="pyro-scratch.", dir=evidence))
    names = ("home", "config", "data", "cache", "state", "runtime", "tmp", "cwd",
             "config-dirs", "data-dirs")
    for name in names:
        (scratch / name).mkdir(mode=0o700)
    environment = {
        "HOME": str(scratch / "home"),
        "XDG_CONFIG_HOME": str(scratch / "config"),
        "XDG_DATA_HOME": str(scratch / "data"),
        "XDG_CACHE_HOME": str(scratch / "cache"),
        "XDG_STATE_HOME": str(scratch / "state"),
        "XDG_RUNTIME_DIR": str(scratch / "runtime"),
        "XDG_CONFIG_DIRS": str(scratch / "config-dirs"),
        "XDG_DATA_DIRS": str(scratch / "data-dirs"),
        "TMPDIR": str(scratch / "tmp"),
        "TMP": str(scratch / "tmp"),
        "TEMP": str(scratch / "tmp"),
        "TERM": "xterm", "LC_ALL": "C", "PATH": "/nonexistent",
    }
    report = {"scratch": str(scratch), "sessions": [], "save_load": "not supported"}
    try:
        for number in (1, 2):
            report["sessions"].append(play(launcher, environment, str(scratch / "cwd"),
                                            pyte, evidence, number))
            log, contents = verify_tree(scratch)
            (evidence / ("session-%d.pyro.log" % number)).write_bytes(contents)
            if number == 1:
                sentinel = ("Pyro smoke log rewrite sentinel " + uuid.uuid4().hex + "\n").encode("ascii")
                # Modify only the game-created log, between actual launches.
                with log.open("ab") as handle:
                    handle.write(sentinel)
                require(log.read_bytes() == contents + sentinel, "log sentinel was not appended")
                (evidence / "between-sessions.pyro.log").write_bytes(log.read_bytes())
            else:
                require(sentinel not in contents, "second launch retained the old log sentinel")
                report["log_rewrite"] = "second real launch truncated the existing native pyro.log"
        prefix = (evidence / "issue-713.raw").read_bytes()
        require(prefix == (evidence / "issue-477.raw").read_bytes(), "paired live captures differ")
        require((evidence / "session-1.raw").read_bytes().startswith(prefix),
                "live capture is not an exact first-session stream prefix")
        report["confined_native_files"] = ["state/pyro/pyro.log"]
        report["result"] = "passed"
    except BaseException as error:
        report["result"] = "failed"
        report["error"] = str(error)
        raise
    finally:
        (evidence / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    try:
        main()
    except Failure as error:
        raise SystemExit("Pyro smoke failed: " + str(error))
