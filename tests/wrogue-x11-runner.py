#!/usr/bin/env python3
"""Consume the unmodified Warp Rogue SDL GUI and its native RDB saves."""

import collections
import ctypes
import hashlib
import json
import os
from pathlib import Path
import select
import shutil
import signal
import struct
import subprocess
import sys
import time
import traceback


def stop(process):
    if process is not None and process.poll() is None:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            process.wait(timeout=3)
            return
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait(timeout=3)

def fields(path):
    # src/lib/rdb.c: ':' terminates tokens; '\\' escapes ':' and '\\'.
    for line in path.read_text().splitlines():
        if not line or line.startswith("#"):
            continue
        tokens, token, escape = [], [], False
        for char in line:
            if escape:
                token.append(char)
                escape = False
            elif char == "\\":
                escape = True
            elif char == ":":
                tokens.append("".join(token))
                token = []
            else:
                token.append(char)
        if escape or token:
            raise RuntimeError("incomplete native RDB field in " + str(path))
        yield tokens


def player_state(save_dir):
    area = save_dir / "sp_area.rdb"
    state = save_dir / "state.rdb"
    rows = list(fields(area))
    players = [row for row in rows if row[0] == "C" and len(row) >= 23
               and row[3:6] == ["0", "0", "0"]]
    # loadsave.c::character_write_attributes: name/script/type/controller/party,
    # 15 more attributes through sn_data, then location y,x. Enum PC/player=0.
    if len(players) != 1:
        raise RuntimeError("expected exactly one native player-controlled PC")
    player = players[0]
    # header_write emits N(name), W(z,y,x) first. Later N fields are event
    # counts, not area names; field identifiers are context-dependent.
    if len(rows) < 2 or rows[0][0] != "N" or len(rows[0]) != 2 or \
            rows[1][0] != "W" or len(rows[1]) != 4:
        raise RuntimeError("invalid native area header")
    return {"name": player[1], "type": int(player[3]),
            "controller": int(player[4]), "party": int(player[5]),
            "area": rows[0][1], "world_zyx": list(map(int, rows[1][1:4])),
            "location_yx": list(map(int, player[21:23])),
            "state_sha256": hashlib.sha256(state.read_bytes()).hexdigest(),
            "area_sha256": hashlib.sha256(area.read_bytes()).hexdigest()}


def identity(state):
    return {key: state[key] for key in
            ("name", "type", "controller", "party", "area", "world_zyx", "location_yx")}


def font_glyphs(path):
    # platform_sdl.c renders palette index 1 from a fixed 8x16 bitmap font.
    # Decode those exact glyph masks, not guessed OCR or synthesized output.
    data = path.read_bytes()
    offset = struct.unpack_from("<I", data, 10)[0]
    width, height = struct.unpack_from("<ii", data, 18)
    bpp = struct.unpack_from("<H", data, 28)[0]
    compression = struct.unpack_from("<I", data, 30)[0]
    if data[:2] != b"BM" or bpp not in (1, 4, 8) or compression or abs(height) != 16:
        raise RuntimeError("unsupported upstream bitmap font format")
    stride = ((width * bpp + 31) // 32) * 4
    glyphs = {}
    for code in range(33, 127):
        mask = 0
        for y in range(16):
            row = y if height < 0 else height - 1 - y
            for x in range(8):
                column = (code - 32) * 8 + x
                byte = data[offset + row * stride + column * bpp // 8]
                pixel = (byte >> (8 - bpp - column * bpp % 8)) & ((1 << bpp) - 1)
                if pixel == 1:
                    mask |= 1 << (y * 8 + x)
        if mask:
            glyphs[mask] = chr(code)
    return glyphs


def screen_text(pixels, glyphs):
    lines = []
    for row in range(37):
        line = []
        for column in range(100):
            colours = collections.defaultdict(int)
            for y in range(16):
                start = ((row * 16 + y) * 800 + column * 8) * 3
                for x in range(8):
                    rgb = pixels[start + x * 3:start + x * 3 + 3]
                    colours[rgb] |= 1 << (y * 8 + x)
            candidates = [glyphs[mask] for mask in colours.values() if mask in glyphs]
            line.append(candidates[0] if len(candidates) == 1 else " ")
        lines.append("".join(line).rstrip())
    return "\n".join(lines)


def main():
    game_out, root, xvfb, xdotool, xwd, convert, evidence, nar_before = sys.argv[1:]
    game_out, root, evidence = map(Path, (game_out, root, evidence))
    evidence.mkdir(parents=True, exist_ok=True)
    record = {"status": "running", "consumer": "unmodified SDL GUI via X11 events",
              "upstream_commit": "675bb5db48434469582367c420b907b129bd6543",
              "output": str(game_out), "output_nar_before": nar_before,
              "events": [], "saves": [], "screenshots": []}
    report_path = evidence / "evidence.json"
    server = process = None
    logs = []
    stage = "isolating X11"

    def report():
        report_path.write_text(json.dumps(record, indent=2) + "\n")

    report()
    try:
        # Private /tmp prevents even X11 sockets/locks from reaching caller state.
        root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
        evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
        libc = ctypes.CDLL(None, use_errno=True)
        libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                               ctypes.c_ulong, ctypes.c_void_p]
        libc.mount.restype = ctypes.c_int

        def mount(source, target, filesystem=None, flags=0):
            if libc.mount(os.fsencode(source), os.fsencode(target),
                          None if filesystem is None else os.fsencode(filesystem),
                          flags, None):
                error = ctypes.get_errno()
                raise OSError(error, os.strerror(error), str(target))

        try:
            mount("tmpfs", "/tmp", "tmpfs", 2 | 4)
            os.chmod("/tmp", 0o1777)
            root, evidence = Path("/tmp/wrogue-root"), Path("/tmp/wrogue-evidence")
            root.mkdir()
            evidence.mkdir()
            mount("/proc/self/fd/" + str(root_fd), root, flags=4096)
            mount("/proc/self/fd/" + str(evidence_fd), evidence, flags=4096)
            Path("/tmp/.X11-unix").mkdir(mode=0o1777)
            os.chmod("/tmp/.X11-unix", 0o1777)
        finally:
            os.close(root_fd)
            os.close(evidence_fd)
        report_path = evidence / "evidence.json"
        environment = dict(os.environ)
        for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                    ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                    ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                                    ("TMPDIR", "tmp")):
            environment[variable] = str(root / directory)
        environment.update(SDL_VIDEODRIVER="x11", SDL_AUDIODRIVER="dummy",
                           SDL_RENDER_DRIVER="software", LIBGL_ALWAYS_SOFTWARE="1",
                           MESA_SHADER_CACHE_DISABLE="true",
                           DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/no-session-bus",
                           DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/no-system-bus")
        glyphs = font_glyphs(game_out / "share/wrogue/data/ui/font.bmp")
        server_log = open(evidence / "xvfb.log", "wb")
        logs.append(server_log)
        read_fd, write_fd = os.pipe()
        try:
            server = subprocess.Popen([xvfb, "-displayfd", str(write_fd), "-screen", "0",
                                       "800x600x24", "-nolisten", "tcp", "-ac"],
                                      pass_fds=(write_fd,), stdout=server_log,
                                      stderr=server_log, env=environment, start_new_session=True)
            os.close(write_fd)
            write_fd = None
            if not select.select([read_fd], [], [], 10)[0]:
                raise RuntimeError("Xvfb display allocation timed out")
            display = os.read(read_fd, 128).decode("ascii").strip()
            if not display.isdecimal():
                raise RuntimeError("Xvfb failed to allocate a display")
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
        environment["DISPLAY"] = ":" + display
        save_dir = root / "home/.wrogue"
        window = None

        def tool(*args):
            return subprocess.check_output(args, env=environment, timeout=10)

        def frame():
            if process.poll() is not None:
                raise RuntimeError("game exited during " + stage)
            dump = root / "frame.xwd"
            tool(xwd, "-silent", "-id", window, "-out", str(dump))
            pixels = tool(convert, str(dump), "-depth", "8", "rgb:-")
            if len(pixels) != 800 * 600 * 3:
                raise RuntimeError("unexpected native framebuffer geometry")
            return pixels

        def capture(name):
            pixels = frame()
            path = evidence / (name + ".png")
            tool(convert, str(root / "frame.xwd"), str(path))
            text = screen_text(pixels, glyphs)
            (evidence / (name + ".txt")).write_text(text + "\n")
            record["screenshots"].append({"file": path.name,
                                          "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
            report()
            return text

        def await_text(expected, timeout=15):
            deadline = time.monotonic() + timeout
            last = ""
            while time.monotonic() < deadline:
                last = screen_text(frame(), glyphs)
                if expected in last:
                    return
                time.sleep(0.1)
            capture("failure-screen")
            raise RuntimeError("timed out waiting for native screen text " + repr(expected) +
                               "; last decoded screen: " + last)

        def key(name):
            record["events"].append({"stage": stage, "key": name})
            report()
            tool(xdotool, "key", "--clearmodifiers", name)
            time.sleep(0.15)

        def launch(label):
            nonlocal process, window, stage
            stage = label + ": title"
            log = open(evidence / (label + ".log"), "wb")
            logs.append(log)
            process = subprocess.Popen([str(game_out / "bin/wrogue")], cwd=root / "work",
                                       env=environment, stdout=log, stderr=log,
                                       start_new_session=True)
            deadline = time.monotonic() + 15
            window = None
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError("game exited before its native window appeared")
                result = subprocess.run([xdotool, "search", "--onlyvisible", "--pid",
                                         str(process.pid), "--name", "Warp Rogue"],
                                        env=environment, stdout=subprocess.PIPE,
                                        stderr=subprocess.DEVNULL, timeout=5)
                if result.returncode == 0:
                    window = result.stdout.decode().splitlines()[0]
                    break
                time.sleep(0.1)
            if window is None:
                raise RuntimeError("native Warp Rogue window did not appear")
            tool(xdotool, "windowfocus", "--sync", window)
            await_text("New game")
            capture(label + "-title")

        def save(label):
            nonlocal stage
            stage = label + ": save and quit"
            key("G")
            await_text("Game Controls")
            key("Return")
            code = process.wait(timeout=15)
            if code != 0:
                raise RuntimeError("Save and quit exited with status " + str(code))
            for filename in ("state.rdb", "sp_area.rdb"):
                shutil.copyfile(save_dir / filename, evidence / (label + "-" + filename))
            state = player_state(save_dir)
            record["saves"].append({"label": label, **state})
            report()
            return state

        def resume(label, name):
            nonlocal stage
            launch(label)
            stage = label + ": Continue game"
            key("2")  # CM_DOWN; Continue game is title menu's second item.
            key("Return")
            await_text(name)
            capture(label + "-loaded")

        launch("new")
        stage = "new game: scenario intro"
        key("Return")
        await_text("Intro")
        capture("scenario-intro")
        key("Return")
        # Galaxy generation may take time; do not queue keys into that stage.
        await_text("Choose Difficulty", timeout=90)
        capture("difficulty")
        for heading, label in (("Choose Gender", "gender"),
                               ("Initial Career", "career"),
                               ("Roll Stats", "stats"),
                               ("Free Advance", "free-advance")):
            stage = "new game: " + label
            key("Return")
            await_text(heading)
            capture(label)
        stage = "new game: enter gameplay"
        key("Return")
        await_text("Press '?'", timeout=20)
        capture("gameplay")
        # Upstream rolls the name automatically; rename through its actual GUI
        # to give subsequent player identity assertions a known value.
        stage = "new game: name character"
        key("C")
        await_text("Character")
        key("r")
        await_text("Name Character")
        tool(xdotool, "type", "--clearmodifiers", "--delay", "80", "NativeConsumer")
        key("Return")
        await_text("NativeConsumer")
        key("Escape")
        capture("named-gameplay")
        first = save("initial")
        if first["name"] != "NativeConsumer" or first["world_zyx"] != [7, 6, 34]:
            raise RuntimeError("new game did not save the expected player/start area")
        resume("roundtrip", first["name"])
        roundtrip = save("roundtrip")
        if identity(first) != identity(roundtrip):
            raise RuntimeError("Continue/save changed native player identity or location")
        record["serialization_roundtrip"] = {"passed": True, "identity": identity(roundtrip)}
        # Try each single-step direction until the real serialized location
        # changes. Obstacles are RNG-dependent; no save editing/teleporting.
        baseline = roundtrip
        moved = None
        for index, direction in enumerate(("6", "2", "4", "8", "3", "1", "7", "9"), 1):
            label = "move-" + str(index)
            resume(label, first["name"])
            stage = label + ": native movement " + direction
            key(direction)
            capture(label + "-gameplay")
            candidate = save(label)
            if candidate["name"] != first["name"] or candidate["world_zyx"] != first["world_zyx"]:
                raise RuntimeError("movement unexpectedly changed player identity/world")
            if candidate["location_yx"] != baseline["location_yx"]:
                if candidate["area_sha256"] == baseline["area_sha256"]:
                    raise RuntimeError("movement state changed without a changed native area file")
                moved = candidate
                record["native_action"] = {"key": direction, "before": identity(baseline),
                                           "after": identity(moved), "passed": True}
                break
            baseline = candidate
        if moved is None:
            raise RuntimeError("no native movement key changed saved player coordinates")
        resume("moved-roundtrip", moved["name"])
        final = save("moved-roundtrip")
        if identity(final) != identity(moved):
            raise RuntimeError("moved player location did not survive Continue/save")
        record["moved_serialization_roundtrip"] = {"passed": True, "identity": identity(final)}
        record["status"] = "passed"
    except BaseException as error:
        record.update(status="failed", stage=stage, error=str(error),
                      traceback=traceback.format_exc())
        raise
    finally:
        stop(process)
        stop(server)
        for log in logs:
            log.close()
        report()


if __name__ == "__main__":
    main()
