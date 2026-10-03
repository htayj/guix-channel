#!/usr/bin/env python3
"""Actual Hellcrawl dungeon/save/reload proof; launched by hellcrawl-smoke.sh."""

import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time

import pyte


def require(condition, message):
    if not condition:
        raise RuntimeError(message)

def persistent_state(text):
    """Compare saved gameplay fields, not dump time or message history."""
    fields = {}
    for label in ("Health", "Magic", "AC", "EV", "SH", "Str", "Int", "Dex", "Gold"):
        match = re.search(r"\b" + label + r":\s*([0-9]+(?:/[0-9]+)?)", text)
        require(match is not None, "native dump lacks persistent field: " + label)
        fields[label] = match.group(1)
    location = re.search(r"^You are (?:on|in) .+\.$", text, re.MULTILINE)
    require(location is not None, "native dump lacks dungeon location")
    fields["location"] = location.group(0)
    equipment = re.findall(r"^ [A-Za-z] - .+$", text, re.MULTILINE)
    require(equipment, "native dump lacks character equipment")
    fields["equipment"] = equipment
    return fields


class Session:
    def __init__(self, command, environment, root, evidence, name):
        self.name = name
        self.evidence = evidence
        self.inputs = []
        self.screen = pyte.Screen(80, 24)
        self.parser = pyte.ByteStream(self.screen)
        self.raw = (evidence / (name + ".raw")).open("wb")
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))

        def controlling_terminal():
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        try:
            self.process = subprocess.Popen(
                command, cwd=root, env=environment, stdin=slave, stdout=slave,
                stderr=slave, start_new_session=True, preexec_fn=controlling_terminal)
        finally:
            os.close(slave)

    def text(self):
        return "\n".join(self.screen.display)

    def read(self, timeout=0.05):
        ready, _, _ = select.select([self.master], [], [], timeout)
        if not ready:
            return False
        try:
            chunk = os.read(self.master, 65536)
        except OSError as error:
            if error.errno == errno.EIO:
                return False
            raise
        if not chunk:
            return False
        self.raw.write(chunk)
        self.raw.flush()
        self.parser.feed(chunk)
        return True

    def wait(self, predicate, description):
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            self.read()
            if predicate():
                return
            require(self.process.poll() is None,
                    "game exited waiting for " + description + "\n" + self.text())
        raise RuntimeError("timed out waiting for " + description + "\n" + self.text())

    def send(self, keys, description):
        require(os.write(self.master, keys) == len(keys), "short PTY write")
        self.inputs.append({"keys_hex": keys.hex(), "purpose": description})

    def checkpoint(self, stage):
        text = self.text()
        (self.evidence / (self.name + "-" + stage + ".txt")).write_text(text + "\n")
        print("=== " + self.name + " " + stage + " ===\n" + text, flush=True)
        require("HellcrawlProof" in text and "Health:" in text and "@" in text,
                "checkpoint lacks the real character, status or dungeon player glyph")
        return text

    def finish(self):
        self.wait(lambda: self.process.poll() is not None, "normal save exit")
        while self.read():
            pass
        require(self.process.returncode == 0,
                "save exit failed: " + str(self.process.returncode) + "\n" + self.text())

    def close(self):
        if self.process.poll() is None:
            os.killpg(self.process.pid, signal.SIGKILL)
            self.process.wait()
        while self.read():
            pass
        self.raw.close()
        os.close(self.master)
        (self.evidence / (self.name + "-inputs.json")).write_text(
            json.dumps(self.inputs, indent=2) + "\n")


def main():
    profile, output, evidence = map(Path, sys.argv[1:])
    network = os.readlink("/proc/self/ns/net")
    require(network != os.environ["HOST_NET_NS"], "network namespace was not isolated")
    interfaces = [line.split(":", 1)[0].strip()
                  for line in Path("/proc/net/dev").read_text().splitlines() if ":" in line]
    require(interfaces == ["lo"], "unexpected network interfaces: " + repr(interfaces))
    mount = str(profile / "bin/mount")
    subprocess.run([mount, "--bind", "/gnu/store", "/gnu/store"], check=True)
    subprocess.run([mount, "-o", "remount,bind,ro", "/gnu/store"], check=True)
    require(os.statvfs("/gnu/store").f_flag & os.ST_RDONLY, "store mount is writable")

    root = evidence / "state-root"
    root.mkdir()
    environment = {"PATH": str(profile / "bin"), "TERM": "xterm-256color", "LC_ALL": "C"}
    for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                                ("TMPDIR", "tmp")):
        path = root / directory
        path.mkdir(mode=0o700)
        environment[variable] = str(path)
    state = root / "data/hellcrawl"
    state.mkdir()
    morgue = state / "morgue"
    morgue.mkdir()
    rc = root / "hellcrawl.rc"
    rc.write_text("show_more = false\nshow_game_time = false\n")
    base = [str(output / "bin/hellcrawl"), "-rc", str(rc), "-morgue", str(morgue),
            "-name", "HellcrawlProof"]
    dump = morgue / "HellcrawlProof.txt"
    turns = []

    def character_dump(session, expected):
        if dump.exists():
            dump.unlink()
        def completed():
            if not dump.is_file() or "Char dumped to" not in session.text():
                return False
            # The game creates the text dump in place.  Its message is drawn
            # with cursor updates, so raw bytes need not contain the phrase.
            # A recreated file with no writer FD proves native fclose has run,
            # even when the prior dump message remains on the visible screen.
            for descriptor in Path(f"/proc/{session.process.pid}/fd").iterdir():
                try:
                    if descriptor.resolve() == dump:
                        return False
                except FileNotFoundError:
                    pass
            return True

        session.send(b"#", "native character dump")
        session.wait(completed, "complete native character dump")
        text = dump.read_text()
        match = re.search(r"Turns:\s*(\d+)", text)
        require(match is not None, "native dump lacks turn counter")
        count = int(match.group(1))
        require(count == expected, "expected turn " + str(expected) + ", got " + str(count))
        require("HellcrawlProof" in text and "Dungeon" in text,
                "dump lacks actual character/dungeon state")
        target = evidence / (session.name + "-turn-" + str(count) + ".dump")
        target.write_text(text)
        turns.append(count)
        return text

    def save(session):
        session.send(b"S", "native save and exit prompt")
        session.wait(lambda: "Save game and exit?" in session.text(), "native save confirmation")
        session.send(b"S", "confirm native save")
        session.finish()
        saves = list(state.rglob("*.cs"))
        require(len(saves) == 1 and saves[0].stat().st_size > 0, "missing native save file")
        return saves[0]

    session = Session(base + ["-seed", "285", "-species", "Hu", "-background", "Fi"],
                      environment, root, evidence, "new-game")
    try:
        session.wait(lambda: "Select the desired difficulty." in session.text(), "difficulty menu")
        session.send(b"n", "normal difficulty")
        session.wait(lambda: "choice of weapons" in session.text(), "fighter weapon menu")
        session.send(b"+", "native recommended fighter weapon")
        session.wait(lambda: "Welcome, HellcrawlProof" in session.text()
                     and "Health:" in session.text() and "@" in session.text(), "dungeon entry")
        session.checkpoint("dungeon")
        character_dump(session, 0)
        session.send(b".", "wait exactly one dungeon turn")
        before = character_dump(session, 1)
        session.checkpoint("turn-one")
        savefile = save(session)
    finally:
        session.close()
    saved_hash = hashlib.sha256(savefile.read_bytes()).hexdigest()

    session = Session(base, environment, root, evidence, "reload")
    try:
        session.wait(lambda: "Welcome back, HellcrawlProof" in session.text()
                     and "Health:" in session.text() and "@" in session.text(), "restored dungeon")
        session.checkpoint("restored")
        restored = character_dump(session, 1)
        require(persistent_state(before) == persistent_state(restored),
                "native persistent character state differs after save/reload")
        session.send(b".", "wait one further turn after restore")
        character_dump(session, 2)
        session.checkpoint("turn-two")
        save(session)
    finally:
        session.close()

    require(hashlib.sha256(savefile.read_bytes()).hexdigest() != saved_hash,
            "second native save did not change after gameplay")
    for directory in ("home", "config", "cache", "state", "runtime"):
        require(not any((root / directory).iterdir()), "unexpected writes outside game data: " + directory)
    report = {"character": "HellcrawlProof", "turns": turns,
              "native_character_state_restored": True,
              "restored_state": persistent_state(restored),
              "save_file": str(savefile.relative_to(evidence)),
              "save_sha256_before_reload": saved_hash,
              "save_sha256_after_second_turn": hashlib.sha256(savefile.read_bytes()).hexdigest(),
              "network_namespace": network, "interfaces": interfaces,
              "store_mount_read_only": True}
    (evidence / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Hellcrawl native dungeon turn/save/reload passed: turns 0 -> 1 -> restored 1 -> 2", flush=True)


if __name__ == "__main__":
    main()
