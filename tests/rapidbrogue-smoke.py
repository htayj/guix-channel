#!/usr/bin/env python3
"""Real SDL and terminal save/resume proof in a private network namespace.

Usage: python3 tests/rapidbrogue-smoke.py OUTPUT EVIDENCE_DIR
Requires an already-built output, Python 3, xdotool and XVFB executable path.
The shell supplies HOST_NET_NS and a private network namespace. No builds run.
SDL evidence is exclusively the game's native PrintScreen PNGs. Terminal
snapshots decode upstream's explicit truecolor cursor positions, not artwork.
All state, raw output, inputs, saves and failure artifacts remain in EVIDENCE_DIR.
The shell entrypoint additionally compares output NAR hashes and seals files.
"""

from contextlib import contextmanager
import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import stat
import struct
import subprocess
import sys
import termios
import time


class ProofError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise ProofError(message)


def header(path):
    # Recordings.c writeHeaderInfo/numberToString: 36 bytes, big endian.
    data = path.read_bytes()
    require(len(data) > 36, f"empty/truncated recording: {path}")
    seed, turns, depth, length = struct.unpack(">QIII", data[16:36])
    require(length == len(data), f"recorded file length differs: {path}")
    require(not data[15], f"wizard save is not normal gameplay: {path}")
    require(data[:15].split(b"\0", 1)[0] == b"RB 1.4.0", "save is not pinned RapidBrogue 1.4.0")
    return {"version": data[:15].split(b"\0", 1)[0].decode("ascii"),
            "seed": seed, "turns": turns, "depth": depth, "length": length}


def recording_events(data):
    # Rogue.h enum eventTypes and Recordings.c recordEvent/OOSCheck.
    events = []
    i = 36
    while i < len(data):
        kind = data[i]
        size = 3 if kind == 0 else 4 if 1 <= kind <= 5 else 2 if kind == 6 else 1
        require(kind <= 7 and i + size <= len(data), "unexpected recording event")
        events.append(tuple(data[i:i + size]))
        i += size
    return events


def verify_restore(first, second, added_rests):
    a, b = header(first), header(second)
    require(a["seed"] == b["seed"] == 1, "save/resume changed deterministic seed")
    require(a["turns"] > 0, "initial rest inputs did not advance gameplay")
    require(b["turns"] == a["turns"] + added_rests,
            "restored live rest inputs did not advance exactly the requested turns")
    require(a["version"] == b["version"] and a["depth"] == b["depth"],
            "resumed save differs in version/depth")
    old, new = first.read_bytes(), second.read_bytes()
    require(new[36:].startswith(old[36:] + bytes([7])),
            "resumed save did not preserve original events and SAVED_GAME_LOADED marker")
    suffix = bytes(36) + new[36 + len(old[36:]) + 1:]
    live = recording_events(suffix)
    rests = [event for event in live if event == (0, ord("z"), 0)]
    require(len(rests) == added_rests, "resumed save lacks actual live rest key events")
    require(sum(event[0] == 6 for event in live) == added_rests,
            "resumed turns lack deterministic RNG checks")
    return {"first": a, "resumed": b, "live_rest_events": len(rests),
            "original_event_prefix_preserved": True, "saved_game_loaded_event": True}


class Screen:
    """Decode the upstream truecolor ASCII protocol for visible PTY text only."""
    def __init__(self):
        self.cells = [[" "] * 100 for _ in range(34)]
        self.x = self.y = 0
        self.pending = b""

    def feed(self, data):
        data = self.pending + data
        self.pending = b""
        i = 0
        while i < len(data):
            if data[i] == 27:
                if i + 1 == len(data):
                    break
                if data[i + 1] == ord("["):
                    match = re.match(rb"\x1b\[([0-?]*)([ -/]*)([@-~])", data[i:])
                    if not match:
                        break
                    args, _, end = match.groups()
                    values = [int(v or b"0") for v in args.split(b";")] if not args.startswith(b"?") else []
                    if end in (b"H", b"f"):
                        self.y = (values[0] or 1) - 1
                        self.x = ((values[1] if len(values) > 1 else 1) or 1) - 1
                    elif end == b"J" and values == [2]:
                        self.cells = [[" "] * 100 for _ in range(34)]
                    # SGR/mode/window/title sequences do not draw text.
                    i += len(match.group())
                    continue
                if data[i + 1] == ord("]"):
                    match = re.match(rb"\x1b\].*?(?:\x07|\x1b\\)", data[i:], re.S)
                    if not match:
                        break
                    i += len(match.group())
                    continue
                i += 3 if data[i + 1] in (ord("("), ord(")")) else 2
                continue
            c = data[i]
            if c == 13:
                self.x = 0
            elif c == 10:
                self.y += 1
            elif c == 8:
                self.x = max(0, self.x - 1)
            elif 32 <= c < 127:
                if 0 <= self.y < 34 and 0 <= self.x < 100:
                    self.cells[self.y][self.x] = chr(c)
                self.x += 1
            i += 1
        self.pending = data[i:]

    def text(self):
        return "\n".join("".join(row) for row in self.cells) + "\n"


class Session:
    def __init__(self, command, root, env, label, terminal=False):
        self.root = root
        self.label = label
        self.terminal = terminal
        self.deadline = time.monotonic() + 100
        self.screen = Screen()
        self.window = None
        self.diagnostics = b""
        self.inputs = (root / f"{label}.inputs.jsonl").open("w")
        self.raw = (root / f"{label}.raw").open("wb")
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 34, 100, 0, 0))
        self.master = master
        # A real controlling terminal for curses; only the spawned child is altered.
        try:
            self.process = subprocess.Popen(command, cwd=root / "work", env=env,
                                            stdin=slave, stdout=slave, stderr=slave,
                                            preexec_fn=self.child_terminal)
        except BaseException:
            os.close(master)
            self.raw.close()
            self.inputs.close()
            raise
        finally:
            os.close(slave)
        os.set_blocking(master, False)
        self.inputs.write(json.dumps({"command": command, "mode": "terminal" if terminal else "SDL"}) + "\n")
        self.inputs.flush()

    @staticmethod
    def child_terminal():
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    def pump(self, seconds=0.1):
        end = min(time.monotonic() + seconds, self.deadline)
        while time.monotonic() < end:
            if select.select([self.master], [], [], min(0.1, end - time.monotonic()))[0]:
                try:
                    data = os.read(self.master, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    return
                if not data:
                    return
                self.raw.write(data)
                self.raw.flush()
                self.diagnostics = (self.diagnostics + data)[-4096:]
                require(not any(text in self.diagnostics.lower() for text in
                                (b"out of sync", b"event type mismatch", b"expected rng output")),
                        "playback RNG/desynchronization diagnostic observed")
                if self.terminal:
                    self.screen.feed(data)
                    require("out of sync" not in self.screen.text().lower(), "playback desynchronized")
        require(time.monotonic() < self.deadline, f"{self.label}: overall deadline exceeded")

    def until(self, predicate, description, seconds=15):
        end = min(time.monotonic() + seconds, self.deadline)
        while time.monotonic() < end:
            self.pump()
            if predicate():
                return
            require(self.process.poll() is None, f"{self.label}: exited awaiting {description}")
        raise ProofError(f"{self.label}: timeout awaiting {description}")

    def xdo(self, *args):
        return subprocess.run(["xdotool", *args], stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, text=True, timeout=3)

    def locate_window(self):
        def locate():
            result = self.xdo("search", "--onlyvisible", "--pid", str(self.process.pid))
            if result.returncode == 0 and result.stdout.split():
                self.window = result.stdout.split()[0]
                return True
            return False
        self.until(locate, "visible SDL window")
        require(self.xdo("windowfocus", "--sync", self.window).returncode == 0,
                "cannot focus SDL window on caller display")
        self.pump(1)

    def key(self, terminal_key, x11_key, reason):
        self.inputs.write(json.dumps({"elapsed_deadline_remaining": self.deadline - time.monotonic(),
                                      "key": x11_key if not self.terminal else terminal_key.decode("ascii"),
                                      "reason": reason}) + "\n")
        self.inputs.flush()
        if self.terminal:
            os.write(self.master, terminal_key)
        else:
            require(self.xdo("windowfocus", "--sync", self.window).returncode == 0,
                    "cannot focus target SDL window before input")
            require(self.xdo("key", "--clearmodifiers", x11_key).returncode == 0,
                    f"cannot send real X11 key: {x11_key}")
        self.pump(0.4)

    def visible(self, text, label):
        self.until(lambda: text in self.screen.text(), text)
        (self.root / f"{self.label}-{label}.screen.txt").write_text(self.screen.text())

    def capture(self, label):
        if self.terminal:
            (self.root / f"{self.label}-{label}.screen.txt").write_text(self.screen.text())
            return
        state = self.root / "state" / "rapidbrogue"
        previous = set(state.glob("Screenshot*.png"))
        self.key(b"", "Print", "native SDL screenshot: " + label)
        self.until(lambda: bool(set(state.glob("Screenshot*.png")) - previous), "native screenshot " + label)
        created = set(state.glob("Screenshot*.png")) - previous
        require(len(created) == 1, "native screenshot count ambiguous")
        path = created.pop()
        self.until(lambda: path.stat().st_size > 24, "complete native PNG")
        self.pump(2.2)  # upstream screenshot-success alert lasts two seconds
        data = path.read_bytes()
        require(data[:8] == b"\x89PNG\r\n\x1a\n" and data[12:16] == b"IHDR", "native capture is not PNG")
        width, height = struct.unpack(">II", data[16:24])
        require(width >= 100 and height >= 34, "native capture has invalid dimensions")
        require(data[-12:-8] == bytes(4) and data[-8:-4] == b"IEND", "incomplete native PNG")
        shutil.copyfile(path, self.root / f"{self.label}-{label}.png")

    def save(self):
        state = self.root / "state" / "rapidbrogue"
        previous = set(state.glob("*.broguesave"))
        self.key(b"S", "shift+s", "save and exit")
        if self.terminal:
            self.visible("Save this game and exit?", "confirm-save")
        self.key(b"y", "y", "confirm save")
        if self.terminal:
            self.visible("Save game as", "filename-prompt")
        # Accept getDefaultFilePath/getAvailableFilePath's actual default.
        self.key(b"\r", "Return", "accept upstream default filename")
        self.until(lambda: bool(set(state.glob("*.broguesave")) - previous), "native saved game")
        created = set(state.glob("*.broguesave")) - previous
        require(len(created) == 1, "save filename is ambiguous")
        path = created.pop()
        if self.terminal:
            self.visible("Saved.", "saved-acknowledgment")
        self.pump(0.5)
        header(path)
        self.key(b" ", "space", "acknowledge Saved. message")
        if self.terminal:
            self.visible("Quit", "title-menu")
        else:
            self.pump(2)  # title animation; q is the upstream menu shortcut
        self.key(b"q", "q", "quit from title menu without abandoning save")
        end = time.monotonic() + 8
        while self.process.poll() is None and time.monotonic() < end:
            self.pump()
        require(self.process.poll() == 0, "game did not quit cleanly via title menu")
        self.pump(0.1)
        return path

    def close(self):
        if self.process.poll() is None:
            os.killpg(self.process.pid, signal.SIGTERM)
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                os.killpg(self.process.pid, signal.SIGKILL)
                self.process.wait(timeout=2)
        # Drain retained output even on failure; never discard evidence.
        try:
            self.pump(0.1)
        except ProofError:
            pass
        os.close(self.master)
        self.raw.close()
        self.inputs.close()


def isolated_environment(root):
    env = os.environ.copy()
    dirs = {"HOME": "home", "XDG_CONFIG_HOME": "config", "XDG_CONFIG_DIRS": "config-dirs",
            "XDG_DATA_HOME": "data", "XDG_DATA_DIRS": "data-dirs", "XDG_CACHE_HOME": "cache",
            "XDG_STATE_HOME": "state", "XDG_RUNTIME_DIR": "runtime", "TMPDIR": "tmp"}
    for variable, directory in dirs.items():
        path = root / directory
        path.mkdir(mode=0o700)
        env[variable] = str(path)
    (root / "work").mkdir()
    env.update(TERM="xterm-256color", COLORTERM="truecolor", LC_ALL="C")
    # Force a genuine private X11 display, not SDL's dummy/offscreen drivers.
    env["SDL_VIDEODRIVER"] = "x11"
    return env


def namespace_evidence():
    current = os.readlink("/proc/self/ns/net")
    host = os.environ.get("HOST_NET_NS")
    require(host and current != host, "proof must run outside caller network namespace")
    interfaces = sorted(line.split(":", 1)[0].strip() for line in
                        Path("/proc/net/dev").read_text().splitlines()[2:] if ":" in line)
    require(set(interfaces) <= {"lo"}, "private network namespace has non-loopback interfaces")
    return {"host_namespace": host, "proof_namespace": current, "interfaces": interfaces}


@contextmanager
def private_display(evidence):
    executable = Path(os.environ.get("XVFB", ""))
    require(executable.is_absolute() and os.access(executable, os.X_OK),
            "XVFB must name an absolute executable supplied by shell")
    root = evidence / "xserver"
    root.mkdir()
    env = isolated_environment(root)
    env.pop("DISPLAY", None)
    env.pop("XAUTHORITY", None)
    read_fd, write_fd = os.pipe()
    process = None
    log = (root / "Xvfb.raw").open("wb")
    previous_display = os.environ.pop("DISPLAY", None)
    previous_auth = os.environ.pop("XAUTHORITY", None)
    try:
        process = subprocess.Popen([str(executable), "-displayfd", str(write_fd),
                                    "-screen", "0", "1280x720x24", "-nolisten", "tcp"],
                                   cwd=root / "work", env=env, pass_fds=(write_fd,),
                                   stdin=subprocess.DEVNULL, stdout=log, stderr=log,
                                   start_new_session=True)
        os.close(write_fd)
        write_fd = None
        os.set_blocking(read_fd, False)
        display = b""
        deadline = time.monotonic() + 15
        while b"\n" not in display and time.monotonic() < deadline:
            require(process.poll() is None, "private Xvfb exited before readiness")
            if select.select([read_fd], [], [], 0.1)[0]:
                chunk = os.read(read_fd, 128)
                require(chunk, "Xvfb displayfd closed before readiness")
                display += chunk
        require(re.fullmatch(rb"[0-9]+\n", display), "private Xvfb did not report a display")
        os.environ["DISPLAY"] = ":" + display.decode("ascii").strip()
        info = {"display": os.environ["DISPLAY"], "executable": str(executable),
                "screen": "1280x720x24", "tcp_disabled": True}
        (root / "display.json").write_text(json.dumps(info, indent=2) + "\n")
        yield info
    finally:
        if write_fd is not None:
            os.close(write_fd)
        os.close(read_fd)
        if process is not None and process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=2)
        log.close()
        os.environ.pop("DISPLAY", None)
        if previous_display is not None:
            os.environ["DISPLAY"] = previous_display
        if previous_auth is not None:
            os.environ["XAUTHORITY"] = previous_auth


def prove(binary, root, terminal=False):
    root.mkdir()
    env = isolated_environment(root)
    frontend = ["-t"] if terminal else ["--no-gpu"]
    results = []
    resume = None
    archived = root / "initial.broguesave"
    for label, rests in (("initial", 3), ("resumed", 2)):
        command = [str(binary), *frontend] + (["-o", str(resume)] if resume else ["-s", "1", "-n"])
        session = Session(command, root, env, label, terminal)
        try:
            if terminal:
                session.visible("Depth: 1", "ready")
                require("@" in session.screen.text(), "terminal dungeon has no visible player")
            else:
                session.locate_window()
            proc = Path("/proc") / str(session.process.pid)
            cwd = (proc / "cwd").resolve(strict=True)
            executable = (proc / "exe").resolve(strict=True)
            require(cwd == root / "state" / "rapidbrogue",
                    "normal launcher did not confine game cwd to XDG state")
            require(executable == (binary.parent.parent / "libexec" / "rapidbrogue").resolve(strict=True),
                    "running process is not the supplied package's real game executable")
            require(os.readlink(proc / "ns" / "net") == os.readlink("/proc/self/ns/net"),
                    "game escaped private network namespace")
            (root / f"{label}.process.json").write_text(json.dumps({
                "pid": session.process.pid, "cwd": str(cwd), "executable": str(executable),
                "network_namespace": os.readlink(proc / "ns" / "net")}, indent=2) + "\n")
            session.capture("text-before-rest")
            for _ in range(rests):
                session.key(b"z", "z", "one deterministic rest turn")
            session.capture("text-after-rest")
            if not terminal and label == "initial":
                session.key(b"G", "shift+g", "switch from original text to graphical tiles")
                session.capture("tiles")
                session.key(b"G", "shift+g", "switch graphical tiles to hybrid")
                session.capture("hybrid")
                session.key(b"G", "shift+g", "restore original text graphics")
                session.capture("original-text")
            resume = session.save()
            results.append(header(resume))
            if label == "initial":
                require(results[-1]["seed"] == 1 and results[-1]["turns"] == rests,
                        "initial native save does not contain the three requested rest turns")
                require(sum(e == (0, ord("z"), 0) for e in recording_events(resume.read_bytes())) == rests,
                        "initial recording lacks actual rest events")
                shutil.copyfile(resume, archived)  # upstream may delete original when loading
            else:
                shutil.copyfile(resume, root / "resumed.broguesave")
        finally:
            session.close()
    proof = verify_restore(archived, root / "resumed.broguesave", 2)
    proof["mode"] = "terminal" if terminal else "SDL software renderer, original text/tiles/hybrid"
    proof["native_screenshots"] = [p.name for p in sorted(root.glob("*.png"))]
    (root / "proof.json").write_text(json.dumps(proof, indent=2) + "\n")
    return proof


def validate_output(output):
    require(os.access(output / "bin" / "rapidbrogue", os.X_OK), "normal game launcher missing")
    resources = ["share/rapidbrogue/keymap.txt", "share/rapidbrogue/assets/tiles.png",
                 "share/rapidbrogue/assets/tiles.bin", "share/rapidbrogue/assets/icon.png",
                 "share/doc/rapidbrogue/LICENSE.txt", "share/doc/rapidbrogue/assets/LICENSE.txt"]
    for name in resources:
        require((output / name).is_file() and (output / name).stat().st_size > 0,
                "missing packaged resource/license: " + name)
    require("GNU AFFERO GENERAL PUBLIC LICENSE" in (output / resources[-2]).read_text(), "code license missing")
    require("Creative Commons Attribution-ShareAlike 4.0" in (output / resources[-1]).read_text(), "asset license missing")
    for parent, dirs, files in os.walk(output):
        for name in files:
            path = Path(parent) / name
            require(not path.stat().st_mode & 0o222, f"writable package file: {path}")


def main():
    require(len(sys.argv) == 3, "usage: rapidbrogue-smoke.py OUTPUT EVIDENCE_DIR")
    output = Path(sys.argv[1]).resolve(strict=True)
    evidence = Path(sys.argv[2]).resolve()
    require(evidence != output and output not in evidence.parents and
            Path("/gnu/store") not in evidence.parents, "evidence must be outside store/output")
    if evidence.exists():
        require(evidence.is_dir() and not any(evidence.iterdir()), "evidence directory must be empty")
    else:
        evidence.mkdir(parents=True)
    try:
        validate_output(output)
        network = namespace_evidence()
        (evidence / "network.json").write_text(json.dumps(network, indent=2) + "\n")
        require(shutil.which("xdotool"), "shell must supply xdotool on PATH")
        with private_display(evidence) as display:
            proofs = [prove(output / "bin" / "rapidbrogue", evidence / "graphics"),
                      prove(output / "bin" / "rapidbrogue", evidence / "terminal", True)]
        summary = {"output": str(output), "proofs": proofs, "network": network,
                   "private_display": display,
                   "limits": ["SDL prompts are driven with paced source-derived inputs; successful native saves and clean menu exit verify them.",
                              "PNG files are native SDL captures for human inspection, not OCR assertions or movement proof.",
                              "Software SDL renderer exercised; GPU acceleration and desktop window-manager integration not tested."]}
        (evidence / "proof.json").write_text(json.dumps(summary, indent=2) + "\n")
        print("RAPIDBROGUE_INTERACTIVE_SAVE_RESUME_OK")
    except Exception as error:
        (evidence / "failure.txt").write_text(f"{type(error).__name__}: {error}\n")
        raise
    # Preserve directories for caller inspection; seal only evidence files.
    for parent, dirs, files in os.walk(evidence):
        for name in files:
            path = Path(parent) / name
            if not path.is_symlink():
                path.chmod(stat.S_IMODE(path.stat().st_mode) & ~0o222)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"rapidbrogue proof failed: {error}", file=sys.stderr)
        sys.exit(1)
