#!/usr/bin/env python3
"""Consume normal Brogue CE 1.15.1; retain native save/restore evidence.

Only brogue-smoke.sh supplies dependencies and namespaces. No app patches,
installed helper, synthetic image, OCR, or recording injection are used.
Terminal frames are decoded exactly with pyte on a 100x34 grid. SDL movement
is gated by completed native gameplay PrintScreen captures; restore also
waits for native save consumption. Movement/save/restore are proven from the
game's native recording bytes and process identity, never fuzzy text matching.
"""

from contextlib import contextmanager
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pty
import pyte
import select
import shutil
import signal
import stat
import struct
import subprocess
import sys
import termios
import time
import traceback
import zlib


class ProofError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise ProofError(message)


def json_file(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def interfaces(path):
    return sorted(line.split(":", 1)[0].strip()
                  for line in path.read_text().splitlines()[2:] if ":" in line)


def identity(proc):
    status = {}
    for line in (proc / "status").read_text().splitlines():
        key, _, value = line.partition(":")
        if key in ("Uid", "Gid", "Groups"):
            status[key] = [int(part) for part in value.split()]
    expected_uid = int(os.environ["HOST_UID"])
    expected_gid = int(os.environ["HOST_GID"])
    require(status.get("Uid") == [expected_uid] * 4, "process changed caller UID identity")
    require(status.get("Gid") == [expected_gid] * 4, "process changed caller GID identity")
    return status


def namespace_evidence():
    proc = Path("/proc/self")
    current = os.readlink(proc / "ns/net")
    host = os.environ.get("HOST_NET_NS")
    require(host and current != host, "consumer is not in a private network namespace")
    devices = interfaces(proc / "net/dev")
    require(devices == ["lo"], "private network must contain only loopback")
    return {"host_network_namespace": host, "network_namespace": current,
            "interfaces": devices, "identity": identity(proc),
            "uid_map": (proc / "uid_map").read_text(),
            "gid_map": (proc / "gid_map").read_text()}


def mount_path(field):
    # mountinfo escapes whitespace and backslashes as octal sequences.
    for escaped, literal in (("\\040", " "), ("\\011", "\t"),
                             ("\\012", "\n"), ("\\134", "\\")):
        field = field.replace(escaped, literal)
    return field


def store_mounts(text):
    mounts = []
    for line in text.splitlines():
        fields = line.split()
        target = mount_path(fields[4])
        if target == "/gnu/store" or target.startswith("/gnu/store/"):
            mounts.append({"target": target, "options": fields[5].split(","),
                           "optional": fields[6:fields.index("-")], "line": line})
    return mounts


def readonly_store(evidence):
    executable = Path(os.environ.get("MOUNT", ""))
    require(executable.is_absolute() and os.access(executable, os.X_OK),
            "MOUNT must be the supplied absolute mount executable")
    before = Path("/proc/self/mountinfo").read_text()
    (evidence / "mountinfo-before.txt").write_text(before)
    commands = []

    def mount(*args):
        result = subprocess.run([str(executable), *args], capture_output=True,
                                text=True, timeout=15)
        commands.append({"command": [str(executable), *args], "returncode": result.returncode,
                         "stdout": result.stdout, "stderr": result.stderr})
        json_file(evidence / "mount-commands.json", commands)
        require(result.returncode == 0, "cannot protect store: " + result.stderr)

    # The shell already made this mount namespace private. A recursive bind
    # preserves every nested store mount; each is then remounted read-only.
    mount("--rbind", "/gnu/store", "/gnu/store")
    mount("--make-rprivate", "/gnu/store")
    bound = store_mounts(Path("/proc/self/mountinfo").read_text())
    targets = sorted({entry["target"] for entry in bound}, key=len, reverse=True)
    require("/gnu/store" in targets, "recursive store bind mount missing")
    for target in targets:
        mount("-o", "remount,bind,ro", target)
    after = Path("/proc/self/mountinfo").read_text()
    (evidence / "mountinfo-after.txt").write_text(after)
    mounts = store_mounts(after)
    require(mounts and all("ro" in entry["options"] and "rw" not in entry["options"]
                           for entry in mounts), "store mount is not recursively read-only")
    require(all(not any(option.startswith(("shared:", "master:"))
                        for option in entry["optional"]) for entry in mounts),
            "store bind mount is not private")
    proof = {"recursive_bind": True, "recursive_readonly": True, "mounts": mounts}
    json_file(evidence / "store.json", proof)
    return proof


def environment(root):
    env = os.environ.copy()
    dirs = {"HOME": "home", "XDG_CONFIG_HOME": "config", "XDG_CONFIG_DIRS": "config-dirs",
            "XDG_DATA_HOME": "data", "XDG_DATA_DIRS": "data-dirs", "XDG_CACHE_HOME": "cache",
            "XDG_STATE_HOME": "state", "XDG_RUNTIME_DIR": "runtime", "TMPDIR": "tmp"}
    for variable, name in dirs.items():
        path = root / name
        path.mkdir(mode=0o700)
        env[variable] = str(path)
    (root / "work").mkdir()
    # Force the game onto the private Xvfb display rather than any default
    # driver selection; --no-gpu still selects the software renderer.
    env.update(TERM="xterm-256color", LC_ALL="C", SDL_VIDEODRIVER="x11")
    json_file(root / "environment.json",
              {key: env[key] for key in list(dirs) + ["TERM", "LC_ALL", "SDL_VIDEODRIVER"]})
    return env


def terminate(process):
    # Only process groups this consumer created; never global session cleanup.
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=2)


@contextmanager
def private_display(evidence):
    executable = Path(os.environ.get("XVFB", ""))
    require(executable.is_absolute() and os.access(executable, os.X_OK),
            "XVFB must be the supplied absolute executable")
    root = evidence / "xserver"
    root.mkdir()
    env = environment(root)
    env.pop("DISPLAY", None)
    env.pop("XAUTHORITY", None)
    read_fd, write_fd = os.pipe()
    process = None
    previous_display = os.environ.pop("DISPLAY", None)
    previous_auth = os.environ.pop("XAUTHORITY", None)
    try:
        with (root / "Xvfb.raw").open("wb") as log:
            process = subprocess.Popen([str(executable), "-displayfd", str(write_fd),
                                        "-screen", "0", "1280x1024x24", "-nolisten", "tcp"],
                                       env=env, cwd=root / "work", pass_fds=(write_fd,),
                                       stdin=subprocess.DEVNULL, stdout=log, stderr=log,
                                       start_new_session=True)
            os.close(write_fd)
            write_fd = None
            data = b""
            deadline = time.monotonic() + 15
            while b"\n" not in data and time.monotonic() < deadline:
                require(process.poll() is None, "private Xvfb exited before readiness")
                if select.select([read_fd], [], [], 0.1)[0]:
                    chunk = os.read(read_fd, 128)
                    require(chunk, "Xvfb displayfd closed before readiness")
                    data += chunk
            require(data.endswith(b"\n") and data[:-1].isdigit(), "invalid Xvfb display number")
            os.environ["DISPLAY"] = ":" + data[:-1].decode("ascii")
            info = {"display": os.environ["DISPLAY"], "executable": str(executable),
                    "tcp_disabled": True,
                    "identity": identity(Path("/proc") / str(process.pid))}
            json_file(root / "display.json", info)
            yield info
    finally:
        terminate(process)
        if write_fd is not None:
            os.close(write_fd)
        os.close(read_fd)
        os.environ.pop("DISPLAY", None)
        if previous_display is not None:
            os.environ["DISPLAY"] = previous_display
        if previous_auth is not None:
            os.environ["XAUTHORITY"] = previous_auth


def recording(data):
    """Decode a native .broguesave exactly as pinned Recordings.c writes it.

    Header (writeHeaderInfo): versionString bytes 0-14 NUL padded, mode byte 15,
    seed bytes 16-23 big endian, playerTurnNumber 24-27, deepestLevel 28-31,
    file length 32-35. Events follow: KEYSTROKE/mouse per recordEvent, and the
    two-byte RNG_CHECK (type 6 plus one rand_range(0,255) byte) that RNGCheck()
    appends once per turn.
    """
    require(len(data) > 36, "native recording is empty/truncated")
    seed, turns, depth, length = struct.unpack(">QIII", data[16:36])
    version = data[:15].split(b"\0", 1)[0].decode("ascii")
    require(version == "CE 1.15.1", "recording version differs from pinned Brogue CE")
    require(data[15] == 0, "wizard mode is not normal gameplay")
    require(length == len(data), "native recording header length differs from actual bytes")
    events = []
    index = 36
    while index < len(data):
        kind = data[index]
        require(kind <= 7, "unexpected native event type")
        size = 3 if kind == 0 else 4 if 1 <= kind <= 5 else 2 if kind == 6 else 1
        require(index + size <= len(data), "native event truncated")
        events.append({"offset": index, "bytes": list(data[index:index + size])})
        index += size
    return {"header": {"version": version, "seed": seed, "turns": turns,
                       "depth": depth, "length": length, "wizard": False},
            "events": events, "sha256": digest(data)}


def png(data, geometry):
    require(data[:8] == b"\x89PNG\r\n\x1a\n", "native capture lacks PNG signature")
    offset = 8
    chunks = []
    compressed = bytearray()
    ihdr = None
    while offset < len(data):
        require(offset + 12 <= len(data), "truncated PNG chunk")
        size = struct.unpack(">I", data[offset:offset + 4])[0]
        end = offset + 12 + size
        require(end <= len(data), "truncated PNG payload")
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:end - 4]
        crc = struct.unpack(">I", data[end - 4:end])[0]
        require(zlib.crc32(kind + payload) & 0xffffffff == crc, "native PNG CRC mismatch")
        chunks.append(kind.decode("ascii"))
        if kind == b"IHDR":
            require(ihdr is None and offset == 8 and size == 13, "invalid native PNG IHDR")
            ihdr = struct.unpack(">IIBBBBB", payload)
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            require(size == 0 and end == len(data), "native PNG has trailing/incomplete data")
        offset = end
    require(chunks and chunks[-1] == "IEND" and ihdr is not None and compressed,
            "native PNG missing required chunks")
    width, height, bits, color, compression, filtering, interlace = ihdr
    require((width, height) == geometry, "native capture differs from SDL window geometry")
    # tiles.c captureScreen: ARGB8888 surface via IMG_SavePNG → RGBA, 8-bit.
    require(bits == 8 and color == 6 and (compression, filtering, interlace) == (0, 0, 0),
            "native screenshot is not an eight-bit RGBA non-interlaced PNG")
    decoded = zlib.decompress(compressed)
    stride = width * 4 + 1
    require(len(decoded) == height * stride, "native PNG scanline length differs")
    require(all(decoded[row * stride] <= 4 for row in range(height)),
            "invalid native PNG row filter")
    return {"width": width, "height": height, "bit_depth": bits, "color_type": color,
            "compression": compression, "filter_method": filtering, "interlace": interlace,
            "chunks": chunks, "sha256": digest(data)}


class Session:
    def __init__(self, command, root, env, label, terminal):
        self.root, self.label, self.terminal = root, label, terminal
        self.state = root / "state/brogue"
        self.window = None
        self.deadline = time.monotonic() + 100
        # Exact pinned terminal geometry: COLS 100, ROWS 34.
        self.screen = pyte.Screen(100, 34)
        self.stream = pyte.ByteStream(self.screen)
        self.snapshots = []
        self.screenshots = []
        self.diagnostics = b""
        self.raw = (root / (label + ".raw")).open("wb")
        self.inputs = (root / (label + ".inputs.jsonl")).open("w")
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 34, 100, 0, 0))
        try:
            self.process = subprocess.Popen(command, env=env, cwd=root / "work",
                                            stdin=slave, stdout=slave, stderr=slave,
                                            preexec_fn=self.controlling_terminal)
        except BaseException:
            os.close(self.master)
            self.raw.close()
            self.inputs.close()
            raise
        finally:
            os.close(slave)
        os.set_blocking(self.master, False)
        self.log({"command": command, "frontend": "terminal" if terminal else "SDL"})

    @staticmethod
    def controlling_terminal():
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    def log(self, value):
        self.inputs.write(json.dumps(value) + "\n")
        self.inputs.flush()

    def text(self):
        # Exact pyte-visible 100x34 cell grid including all trailing spaces.
        return "\n".join(self.screen.display) + "\n"

    def snapshot(self, label):
        if self.terminal:
            name = f"{self.label}-{label}.screen.txt"
            (self.root / name).write_text(self.text())
            self.snapshots.append(name)

    def pump(self, seconds=0.1):
        end = min(time.monotonic() + seconds, self.deadline)
        while time.monotonic() < end:
            timeout = min(0.1, end - time.monotonic())
            if timeout <= 0:
                break
            if select.select([self.master], [], [], timeout)[0]:
                try:
                    data = os.read(self.master, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        return
                    raise
                if not data:
                    return
                self.raw.write(data)
                self.raw.flush()
                self.diagnostics = (self.diagnostics + data)[-8192:]
                require(not any(message in self.diagnostics.lower() for message in
                                (b"out of sync", b"event type mismatch", b"expected rng output")),
                        "native recording desynchronization diagnostic")
                if self.terminal:
                    self.stream.feed(data)
        require(time.monotonic() < self.deadline, "session deadline exceeded")

    def until(self, predicate, description, seconds=15):
        end = min(time.monotonic() + seconds, self.deadline)
        while time.monotonic() < end:
            self.pump()
            if predicate():
                return
            require(self.process.poll() is None, f"game exited awaiting {description}")
        raise ProofError(f"timeout awaiting {description}")

    def visible(self, label, *texts, seconds=15):
        self.until(lambda: all(text in self.text() for text in texts),
                   " / ".join(texts), seconds=seconds)
        self.snapshot(label)

    def default_name(self):
        """Read the prefilled save dialog default from the exact decoded grid.

        Pinned IO.c getInputTextString(dialog) draws the default entry as
        literal text in the dialog; Return with no edits saves exactly that
        displayed name (Recordings.c saveGame).
        """
        # IO.c dialog: default row = ROWS / 2 - 1, x = (COLS-maxLength)/2.
        # maxLength = COLS-12, so the filename begins at column 6, row 16.
        # It is followed immediately by the suffix, which is displayed but
        # not part of the editable default entry.
        line = self.screen.display[16][6:]
        suffix = ".broguesave"
        require(suffix in line, "native default save filename is not visible")
        candidate = line.split(suffix, 1)[0]
        require(bool(candidate), "native default save filename is empty")
        return candidate

    @staticmethod
    def default_matches(candidate, path):
        # getAvailableFilePath appends " (n)" only on name collisions; the
        # dialog may also show the suffix after the prefilled default.
        return bool(candidate) and (candidate in (path.stem, path.name)
                                    or path.stem.startswith(candidate + " ("))

    def xdo(self, *args):
        result = subprocess.run(["xdotool", *args], capture_output=True, text=True, timeout=4)
        self.log({"xdotool": list(args), "returncode": result.returncode,
                  "stdout": result.stdout, "stderr": result.stderr})
        return result

    def locate_window(self):
        def locate():
            result = self.xdo("search", "--onlyvisible", "--pid", str(self.process.pid))
            windows = result.stdout.split()
            if result.returncode == 0 and windows:
                require(len(windows) == 1, "ambiguous SDL game window")
                self.window = windows[0]
                return True
            return False
        self.until(locate, "native SDL window")
        require(self.xdo("windowfocus", "--sync", self.window).returncode == 0,
                "cannot focus private SDL window")
        self.pump(1)

    def key(self, key, reason):
        terminal, x11 = {"S": (b"S", "shift+s"), "y": (b"y", "y"),
                         "Return": (b"\r", "Return"), "space": (b" ", "space"),
                         "q": (b"q", "q"), "Print": (b"", "Print")}.get(
                             key, (key.encode("ascii"), key))
        self.log({"key": key, "bytes": list(terminal), "x11_key": x11, "reason": reason})
        if self.terminal:
            require(terminal, "PrintScreen is SDL-only")
            require(os.write(self.master, terminal) == len(terminal), "short terminal input write")
        else:
            require(self.xdo("windowfocus", "--sync", self.window).returncode == 0,
                    "cannot focus target game before input")
            # SDL's printable ASCII path is SDL_TEXTINPUT; Return/Print use
            # SDL_KEYDOWN (sdl2-platform.c pollBrogueEvent/eventFromKey).
            # No --window: that selects XSendEvent rather than focused XTest.
            if len(key) == 1 or key == "space":
                text = " " if key == "space" else key
                result = self.xdo("type", "--clearmodifiers", "--delay", "100", "--", text)
            else:
                result = self.xdo("key", "--clearmodifiers", "--delay", "100", x11)
            require(result.returncode == 0, "cannot send real SDL input")
        self.pump(0.5)

    def capture(self, label):
        if self.terminal:
            self.snapshot(label)
            return
        previous = set(self.state.glob("Screenshot*.png"))
        self.key("Print", "native PrintScreen: " + label)
        self.until(lambda: bool(set(self.state.glob("Screenshot*.png")) - previous),
                   "native screenshot " + label)
        created = set(self.state.glob("Screenshot*.png")) - previous
        require(len(created) == 1, "ambiguous native screenshot")
        path = created.pop()
        self.pump(2.3)  # upstream screenshot success alert lasts two seconds
        geometry = self.xdo("getwindowgeometry", "--shell", self.window)
        require(geometry.returncode == 0, "cannot read SDL geometry")
        values = dict(line.split("=", 1) for line in geometry.stdout.splitlines() if "=" in line)
        info = png(path.read_bytes(), (int(values["WIDTH"]), int(values["HEIGHT"])))
        name = f"{self.label}-{label}.png"
        shutil.copyfile(path, self.root / name)
        info.update(file=name, native_file=str(path))
        self.screenshots.append(info)
        json_file(self.root / f"{self.label}.screenshots.json", self.screenshots)

    def position(self):
        """Locate the player in the exact pinned map window.

        Rogue.h maps dungeon cell (x, y) to window column x + STAT_BAR_WIDTH + 1
        and row y + MESSAGE_LINES: columns 21..99, rows 3..31 of the 100x34
        grid. Everything outside that rectangle is sidebar, messages, flavor
        and menu rows.
        """
        positions = [(x, y) for y in range(3, 32) for x in range(21, 100)
                     if self.screen.display[y][x] == "@"]
        require(len(positions) == 1, "dungeon must contain exactly one visible player @")
        return positions[0]

    def direction(self):
        x, y = self.position()
        for key, dx, dy in (("h", -1, 0), ("l", 1, 0), ("k", 0, -1), ("j", 0, 1)):
            nx, ny = x + dx, y + dy
            if 21 <= nx < 100 and 3 <= ny < 32 and self.screen.display[ny][nx] == ".":
                return {"key": key, "dx": dx, "dy": dy,
                        "inverse": {"h": "l", "l": "h", "k": "j", "j": "k"}[key],
                        "before": [x, y], "after": [nx, ny]}
        raise ProofError("seeded player has no cardinal adjacent visible floor")

    def process_proof(self, binary):
        binary = binary.resolve(strict=True)
        proc = Path("/proc") / str(self.process.pid)
        cwd = (proc / "cwd").resolve(strict=True)
        executable = (proc / "exe").resolve(strict=True)
        netns = os.readlink(proc / "ns/net")
        keymap = self.state / "keymap.txt"
        packaged_keymap = binary.parent.parent / "share/brogue/keymap.txt"
        require(keymap.is_file() and not keymap.is_symlink(),
                "normal launcher must copy a user-owned state keymap")
        user_keymap = keymap.read_bytes()
        require(user_keymap == packaged_keymap.read_bytes(),
                "normal launcher altered the packaged default keymap")
        info = {"pid": self.process.pid, "cwd": str(cwd), "executable": str(executable),
                "network_namespace": netns, "interfaces": interfaces(proc / "net/dev"),
                "identity": identity(proc),
                "cmdline": [part.decode() for part in
                            (proc / "cmdline").read_bytes().split(b"\0")[:-1]]}
        info["keymap"] = {"path": str(keymap), "sha256": digest(user_keymap),
                          "matches_packaged_default": True}
        json_file(self.root / f"{self.label}.process.json", info)
        require(cwd == self.state, "normal launcher did not use XDG_STATE_HOME/brogue cwd")
        require(executable == (binary.parent.parent / "libexec/brogue").resolve(strict=True),
                "game /proc exe is not supplied libexec/brogue")
        require(netns == os.readlink("/proc/self/ns/net") and info["interfaces"] == ["lo"],
                "game escaped isolated loopback-only namespace")
        return info

    def save(self, label):
        previous = set(self.state.glob("*.broguesave"))
        self.key("S", "normal save-and-exit command")
        default = None
        if self.terminal:
            self.visible("confirm-save", "Save this game and exit?")
            self.key("y", "confirm save")
            self.visible("filename", "Save game as")
            default = self.default_name()
            self.log({"derived_default_filename": default, "session": label})
        else:
            self.key("y", "confirm save")
            self.pump(0.5)
        self.key("Return", "accept native default filename")
        self.until(lambda: bool(set(self.state.glob("*.broguesave")) - previous), "native saved file")
        created = set(self.state.glob("*.broguesave")) - previous
        require(len(created) == 1, "ambiguous native save filename")
        path = created.pop()
        if default is not None:
            require(self.default_matches(default, path),
                    "saved filename differs from decoded native default prompt")
        removals = sorted(entry.name for entry in previous - set(self.state.glob("*.broguesave")))
        if self.terminal:
            self.visible("saved", "Saved.")
        else:
            self.pump(1)
        data = path.read_bytes()
        archive = self.root / f"{self.label}.broguesave"
        archive.write_bytes(data)  # preserve native bytes even if later checks fail
        proof = recording(data)
        proof.update(file=path.name, renamed_away=removals,
                     derived_default_filename=default)
        json_file(self.root / f"{self.label}.recording.json", proof)
        self.key("space", "acknowledge Saved. without abandoning game")
        if self.terminal:
            # Pinned MainMenu.c buttons render literally "New Game" and "Quit".
            self.visible("title-menu", "New Game", "Quit")
        else:
            self.pump(2)  # title screen; PrintScreen is gameplay-only in IO.c
        self.key("q", "normal title-menu quit")
        end = time.monotonic() + 8
        while self.process.poll() is None and time.monotonic() < end:
            self.pump()
        require(self.process.poll() == 0, "game did not quit cleanly via normal title menu")
        self.pump(0.1)
        require(path.read_bytes() == data, "clean menu quit changed native saved bytes")
        return path, data, proof

    def close(self):
        try:
            self.snapshot("final")
            terminate(self.process)
            try:
                self.pump(0.1)
            except ProofError:
                pass
        finally:
            os.close(self.master)
            self.raw.close()
            self.inputs.close()


def verify_recordings(first, second, movement):
    a, b = recording(first), recording(second)
    require(a["header"]["seed"] == b["header"]["seed"] == 1, "native seed changed")
    require(a["header"]["turns"] == 1, "initial movement did not advance exactly one turn")
    require(b["header"]["turns"] == a["header"]["turns"] + 1,
            "continued movement did not advance exactly one further turn")
    require(a["header"]["depth"] == b["header"]["depth"] == 1, "native depth changed")
    require(second[36:].startswith(first[36:] + bytes([7])),
            "restore lacks preserved native events followed by SAVED_GAME_LOADED")
    initial = [event["bytes"] for event in a["events"]]
    continued = [event["bytes"] for event in b["events"]
                 if event["offset"] >= len(first) + 1]
    require([event[0] for event in initial] == [6, 0, 6] and
            [event[0] for event in continued] == [0, 6],
            "native event sequence must be initial RNG, movement/RNG, then continued movement/RNG")
    require([event for event in initial if event[0] == 0] == [[0, ord(movement["key"]), 0]],
            "initial recording does not contain exactly the requested native movement key")
    require([event for event in continued if event[0] == 0] == [[0, ord(movement["inverse"]), 0]],
            "restored recording does not contain exactly the requested continued movement key")
    # startLevel calls RNGCheck() once before turn zero, so the initial
    # recording carries one extra RNG_CHECK versus the continued session.
    require(sum(event[0] == 6 for event in initial) == 2 and
            sum(event[0] == 6 for event in continued) == 1,
            "movement turns lack their deterministic RNG checks")
    return {"first": a, "restored": b, "preserved_event_prefix": True,
            "saved_game_loaded_event": True, "movement": movement,
            "initial_turns": 1, "continued_turns": 1}


def prove(binary, root, terminal, movement=None):
    root.mkdir()
    env = environment(root)
    frontend = ["-t"] if terminal else ["--no-gpu"]
    resume = None
    archives = []
    processes = []
    captures = []
    for label in ("initial", "restored"):
        command = [str(binary), *frontend] + (["-o", str(resume)] if resume else ["-s", "1", "-n"])
        session = Session(command, root, env, label, terminal)
        try:
            if terminal:
                # First curses _delayUpTo(short) narrows epoch milliseconds
                # with lastDelayTime=0 and can sleep up to 32767ms. A visible
                # ready grid is flushed before that delay; it does not prove
                # input has been consumed. Both readiness and movement below
                # therefore allow that bounded native delay, without resends.
                session.visible("ready", "Depth: 1", seconds=40)
                if label == "initial":
                    movement = session.direction()
                    json_file(root / "movement.json", movement)
                else:
                    require(not resume.exists(),
                            "loading a save must delete the original save file upstream")
                    require(list(session.position()) == movement["after"],
                            "restore did not recover the exact saved player coordinate")
            else:
                session.locate_window()
                if label == "restored":
                    # A mapped SDL window precedes native replay completion.
                    # switchToPlaying removes the input save only after replay
                    # succeeds; PrintScreen below then gates gameplay input.
                    session.until(lambda: not resume.exists(),
                                  "native restore consumed original save", seconds=40)
                    # Allow any one-second native replay alert to finish
                    # before asking the gameplay loop for a native capture.
                    session.pump(1.1)
            processes.append(session.process_proof(binary))
            session.capture("before-movement")
            key = movement["key"] if label == "initial" else movement["inverse"]
            session.key(key, "one native movement turn" if label == "initial"
                        else "continued movement after restore")
            if terminal:
                expected = movement["after"] if label == "initial" else movement["before"]
                # curses_nextKeyOrMouseEvent refreshes the frame before
                # polling and its first delay. Send exactly one key, then
                # synchronize on its exact rendered coordinate, not pacing.
                session.until(lambda: list(session.position()) == expected,
                              "exact player position delta", seconds=40)
            session.capture("after-movement")
            resume, data, info = session.save(label)
            archives.append(data)
            captures.extend(session.screenshots)
        finally:
            session.close()
    proof = verify_recordings(*archives, movement)
    proof.update(frontend="ncurses terminal -t" if terminal else "SDL --no-gpu software renderer",
                 process_identity=processes, native_screenshots=captures,
                 exact_terminal_position_delta=terminal)
    json_file(root / "proof.json", proof)
    return proof, archives, movement


def validate_output(output):
    require(os.access(output / "bin/brogue", os.X_OK), "normal brogue launcher missing")
    require(os.access(output / "libexec/brogue", os.X_OK), "native libexec/brogue missing")
    resources = ("share/brogue/keymap.txt", "share/brogue/assets/tiles.png",
                 "share/brogue/assets/tiles.bin", "share/doc/brogue/README.md",
                 "share/doc/brogue/CHANGELOG.md", "share/doc/brogue/LICENSE.txt",
                 "share/doc/brogue/assets/LICENSE.txt")
    proof = {}
    for name in resources:
        path = output / name
        require(path.is_file() and path.stat().st_size > 0, "missing packaged resource/notice: " + name)
        proof[name] = {"bytes": path.stat().st_size, "sha256": digest(path.read_bytes())}
    require("GNU AFFERO GENERAL PUBLIC LICENSE" in (output / resources[-2]).read_text(),
            "upstream code license notice missing")
    asset_license = (output / resources[-1]).read_text()
    require("Creative Commons Attribution-ShareAlike 4.0" in asset_license and
            "Oryx Design Lab" in asset_license, "upstream asset license/attribution missing")
    require(not (output / "share/brogue/assets/icon.png").exists(),
            "unlicensed icon is unexpectedly installed")
    for parent, dirs, files in os.walk(output):
        for name in dirs + files:
            require("smoke" not in name.lower(), "installed smoke helper is forbidden: " + name)
        for name in files:
            path = Path(parent) / name
            require(not stat.S_IMODE(path.stat().st_mode) & 0o222,
                    "package file is writable: " + str(path))
    for name in ("bin/brogue", "libexec/brogue"):
        require(b"--guix-smoke" not in (output / name).read_bytes(),
                "installed smoke mode is forbidden")
    proof.update(omitted_icon=True, no_installed_smoke_helper_or_mode=True)
    return proof


def main():
    require(len(sys.argv) == 3, "usage: brogue-smoke.py OUTPUT EVIDENCE_DIR")
    output = Path(sys.argv[1]).resolve(strict=True)
    evidence = Path(sys.argv[2]).resolve(strict=True)
    require(evidence.is_dir() and not any(evidence.iterdir()),
            "evidence directory must be precreated and empty")
    require(evidence != output and output not in evidence.parents and
            Path("/gnu/store") not in evidence.parents,
            "evidence must be outside package output/store")
    try:
        network = namespace_evidence()
        json_file(evidence / "network.json", network)
        store = readonly_store(evidence)
        package = validate_output(output)
        json_file(evidence / "package.json", package)
        require(shutil.which("xdotool"), "shell must supply xdotool")
        terminal, terminal_bytes, movement = prove(output / "bin/brogue", evidence / "terminal", True)
        with private_display(evidence) as display:
            sdl, sdl_bytes, _ = prove(output / "bin/brogue", evidence / "graphics", False, movement)
        require(all(a[36:] == b[36:] for a, b in zip(terminal_bytes, sdl_bytes)),
                "terminal and SDL native movement/restore event streams differ")
        require(all(recording(a)["header"] == recording(b)["header"]
                    for a, b in zip(terminal_bytes, sdl_bytes)),
                "terminal and SDL native movement/restore headers differ")
        json_file(evidence / "proof.json", {
            "output": str(output), "network": network, "readonly_store": store,
            "package": package, "terminal": terminal, "SDL": sdl, "private_display": display,
            "frontend_native_event_and_header_parity": True,
            "limits": ["SDL save dialogs use source-derived paced XTest inputs; native save/restore bytes and clean exit prove lifecycle, not OCR.",
                       "Each SDL movement follows a completed native gameplay PrintScreen; restored readiness additionally requires native save consumption. Screenshots are inspection evidence; exact movement keys/turns/RNG and preserved restore events are asserted from native recordings.",
                       "SDL --no-gpu software rendering is exercised; GPU acceleration and desktop window-manager integration are not."]})
        print("BROGUE_NATIVE_SAVE_RESTORE_OK")
    except BaseException:
        (evidence / "failure.txt").write_text(traceback.format_exc())
        raise


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Brogue native proof failed: {error}", file=sys.stderr)
        sys.exit(1)
