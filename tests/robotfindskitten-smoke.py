#!/usr/bin/env python3
"""Observe and navigate the installed, unmodified ncurses game; no fake game.

Test-only dependency: pyte.  Run via robotfindskitten-smoke.sh for the network
namespace, store-immutability gate, and isolated terminfo dependency.
"""

import argparse
from collections import deque
import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import signal
import socket
import struct
import subprocess
import termios
import time

import pyte

ROWS, COLS = 24, 80
WIN = "You found kitten! Way to go, robot!"
DIRECTIONS = ((0, -1, b"h"), (0, 1, b"l"), (-1, 0, b"k"), (1, 0, b"j"))


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class Screen(pyte.Screen):
    """pyte plus ECMA-48 REP, emitted by current ncurses xterm terminfo."""

    def draw(self, text):
        super().draw(text)
        if text:
            self.last_character = text[-1]

    def repeat_character(self, count=1):
        super().draw(getattr(self, "last_character", " ") * (count or 1))


class Stream(pyte.ByteStream):
    csi = dict(pyte.ByteStream.csi, b="repeat_character")
    events = pyte.ByteStream.events | {"repeat_character"}


class Game:
    def __init__(self, binary, environment, work):
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.raw = bytearray()
        self.status = None
        # Size the slave BEFORE exec: pty.fork followed by a parent ioctl races
        # initscr and can leave the child with a 0x0 terminal.
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ,
                    struct.pack("HHHH", ROWS, COLS, 0, 0))
        self.pid = os.fork()
        if self.pid == 0:
            os.close(self.master)
            os.setsid()
            fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
            for descriptor in (0, 1, 2):
                os.dup2(slave, descriptor)
            if slave > 2:
                os.close(slave)
            os.chdir(work)
            os.execve(binary, [binary, "-n", "1", "-s", "0"], environment)
        os.close(slave)
        os.set_blocking(self.master, False)

    def read(self, delay=0.05):
        if select.select([self.master], [], [], delay)[0]:
            try:
                chunk = os.read(self.master, 65536)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise
                chunk = b""
            if chunk:
                self.raw.extend(chunk)
                self.stream.feed(chunk)
        if self.status is None:
            waited, status = os.waitpid(self.pid, os.WNOHANG)
            if waited:
                self.status = status

    def until(self, predicate, label, timeout=6):
        deadline = time.monotonic() + timeout
        while not predicate():
            self.read()
            require(self.status is None or predicate(),
                    f"game exited before {label}; frame={self.screen.display!r}")
            require(time.monotonic() < deadline, f"timed out waiting for {label}")

    def key(self, value):
        os.write(self.master, value)

    def robot(self):
        positions = [(y, x) for y in range(3, ROWS - 1)
                     for x in range(1, COLS - 1)
                     if self.screen.display[y][x] == "#"]
        require(len(positions) == 1, f"expected one robot, got {positions}")
        return positions[0]

    def objects(self):
        return [(y, x) for y in range(3, ROWS - 1)
                for x in range(1, COLS - 1)
                if self.screen.display[y][x] not in (" ", "#")]

    def close(self):
        if self.status is None:
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
        os.close(self.master)


def path_to_neighbor(start, target, objects):
    """BFS only through empty cells: objects are impassable until touched."""
    queue = deque([(start, [])])
    seen = {start}
    while queue:
        position, path = queue.popleft()
        for dy, dx, key in DIRECTIONS:
            neighbor = (position[0] + dy, position[1] + dx)
            if neighbor == target:
                return path, key
            if (3 <= neighbor[0] < ROWS - 1 and 1 <= neighbor[1] < COLS - 1
                    and neighbor not in objects and neighbor not in seen):
                seen.add(neighbor)
                queue.append((neighbor, path + [(neighbor, key)]))
    raise RuntimeError("no empty-cell route to object")


def play(binary, environment, work, reverse, messages, capture, expected=None):
    game = Game(binary, environment, work)
    touched_nki = False
    moves = 0
    try:
        game.until(lambda: any("Press any key to start." in line
                               for line in game.screen.display), "introduction")
        require("robotfindskitten 3.0000000.726" in game.screen.display[0],
                "wrong introduction version")
        game.key(b" ")
        game.until(lambda: game.screen.display[2][0] != " "
                   and len(game.objects()) == 2, "playfield with two objects")
        initial = (game.robot(), tuple(game.objects()))
        require(expected is None or initial == expected,
                "fixed-seed replay did not reproduce the same field")
        targets = list(reversed(initial[1])) if reverse else list(initial[1])
        require(game.screen.buffer[initial[0][0]][initial[0][1]].fg == "white",
                "robot is not rendered with ncurses color")
        for target in targets:
            route, touch = path_to_neighbor(game.robot(), target, set(initial[1]))
            for destination, key in route:
                previous = game.robot()
                game.key(key)
                game.until(lambda: game.screen.display[destination[0]][destination[1]] == "#"
                           and game.screen.display[previous[0]][previous[1]] == " ",
                           "visible robot movement")
                require(game.robot() == destination, "robot moved to an unexpected cell")
                moves += 1
            before = game.robot()
            game.key(touch)
            game.until(lambda: WIN in game.screen.display[1]
                       or game.screen.display[1].rstrip() in messages,
                       "non-kitten description or kitten animation")
            if WIN in game.screen.display[1]:
                require(moves > 0, "no robot movement observed")
                # Save exactly what the real terminal emitted BEFORE endwin.
                # No fabricated frame, marker, terminal exit, or .png copy.
                capture.write_bytes(game.raw)
                capture.with_suffix(".txt").write_text(
                    "\n".join(game.screen.display) + "\n", encoding="utf-8")
                game.until(lambda: game.status is not None, "successful game exit")
                require(os.waitstatus_to_exitcode(game.status) == 0, "game failed after win")
                return initial, touched_nki, moves
            require(game.robot() == before, "touching NKI unexpectedly moved robot")
            require(tuple(game.objects()) == initial[1], "NKI touch changed playfield objects")
            touched_nki = True
            # Empty status line avoids confusing the next touch with old text.
            game.key(b"\x0c")
            game.until(lambda: not game.screen.display[1].strip(), "native redraw")
        raise RuntimeError("neither object produced the kitten win")
    except Exception:
        capture.with_suffix(".failure.raw").write_bytes(game.raw)
        raise
    finally:
        game.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("root", type=Path)
    parser.add_argument("--raw", type=Path)
    args = parser.parse_args()
    binary = str(args.binary.resolve(strict=True))
    root = args.root.resolve(strict=True)
    require(root.is_dir() and not any(root.iterdir()), "private root must be empty")
    # The shell creates a fresh network namespace. Refuse accidental online use.
    interfaces = [line.split(":", 1)[0].strip() for line in
                  Path("/proc/net/dev").read_text().splitlines()[2:]]
    require(interfaces == ["lo"], f"not an offline namespace: {interfaces}")
    # Query flags in this namespace; inherited sysfs may show the parent.
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as query:
        flags = fcntl.ioctl(query, 0x8913, struct.pack("256s", b"lo"))
    require(not struct.unpack_from("H", flags, 16)[0] & 1,
            "namespace loopback unexpectedly up")
    environment = {"TERM": "xterm", "LC_ALL": "C", "PATH": "",
                   "TERMINFO": os.environ["TERMINFO"],
                   "TERMINFO_DIRS": os.environ["TERMINFO"]}
    for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_DATA_HOME", "data"), ("XDG_STATE_HOME", "state"),
                           ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "runtime"),
                           ("TMPDIR", "tmp")):
        directory = root / name
        directory.mkdir(mode=0o700)
        environment[variable] = str(directory)
    work = root / "work"
    work.mkdir(mode=0o700)
    data = args.binary.resolve().parent.parent / "share/games/robotfindskitten/vanilla.nki"
    messages = {line[:COLS] for line in data.read_text().splitlines()
                if line and not line.startswith(("#", "%"))}
    require(messages, "installed NKI collection has no descriptions")
    version = subprocess.run([binary, "-V"], env=environment, cwd=work,
                             check=True, capture_output=True, timeout=5)
    require(version.stdout == b"robotfindskitten: 3.0000000.726\n", "wrong native version")
    capture = args.raw.resolve() if args.raw else root / "terminal.raw"
    initial, touched_nki, moves = play(binary, environment, work, False, messages, capture)
    if not touched_nki:
        # We identified kitten by actually touching it, not guessing its glyph.
        # Replaying the SAME native seed with reverse target order guarantees NKI.
        _, touched_nki, moves = play(binary, environment, work, True, messages,
                                     capture, expected=initial)
    require(touched_nki, "no installed NKI description observed")
    for variable in ("HOME", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME",
                     "XDG_CACHE_HOME", "XDG_RUNTIME_DIR", "TMPDIR"):
        require(not any(Path(environment[variable]).iterdir()),
                f"game wrote unexpected state in {variable}")
    require(not any(work.iterdir()), "game wrote to private working directory")
    print(f"robotfindskitten: observed {moves} moves, installed NKI interaction, "
          f"kitten win and exit 0; pre-exit PTY capture: {capture}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        raise SystemExit(f"robotfindskitten smoke: {error}")
