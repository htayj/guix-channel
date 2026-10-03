#!/usr/bin/env python3
"""Observe unmodified SDL pixels and drive real Babel login/gameplay/restart.

Upstream main.cpp randomizes letters unless supported game.easymode=true.
MOB::actionSuicide lowers HP to one on the first use, kills on the second;
main.cpp then presents game::lose, reconnects and rebuilds a fresh level.
No native save/load is claimed: shutdownEverything's saving branch is #if 0.
"""

import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import select
import subprocess
import sys
import time


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    require(len(sys.argv) == 9,
            "usage: runner OUTPUT ROOT XVFB XDOTOOL XWD CONVERT XLIB ARTIFACTS")
    output, root, xvfb, xdotool, xwd, convert, xlib, artifacts = sys.argv[1:]
    output, root, artifacts = Path(output), Path(root), Path(artifacts)
    assets = output / "share/babel7drl"
    namespaces = {}
    for kind, variable in (("user", "HOST_USER_NS"), ("mnt", "HOST_MOUNT_NS"),
                           ("net", "HOST_NET_NS"), ("pid", "HOST_PID_NS")):
        actual = os.readlink("/proc/self/ns/" + kind)
        require(actual != os.environ[variable], "host " + kind + " namespace leaked")
        namespaces[kind] = actual
    interfaces = sorted(line.split(":", 1)[0].strip()
                        for line in Path("/proc/net/dev").read_text().splitlines()[2:])
    require(interfaces == ["lo"], "non-loopback network interface leaked")
    for path in [output, *output.rglob("*")]:
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, "writable store path: " + str(path))
        require(path.suffix.lower() not in (".exe", ".dll"), "foreign bundled binary")
    asset_hashes = {
        "babel.cfg": "8f5a3c6df9eb8761eace8f37f40dd7862ed587dddbf8ce174ee448dedd0df91d",
        "names.txt": "b74f739404e837aca46355b429092c39da7a52894e589806d39f6585199a7df6",
        "text.txt": "c049d4c4b04ef518a296da4742dbc252af9cdd7ea3282987d2d9ae91efeb7d9f",
        "rooms/village.map": "2945569c915aaeb2c8eab17533a0332677476d0e59e2043107513788d200f831",
        "terminal.png": "7ed1cc4cc91e35b4b10330dcaac8ab2d4635174e69b8a9adc553f8067fc09c1f",
    }
    for name, digest in asset_hashes.items():
        require(hashlib.sha256((assets / name).read_bytes()).hexdigest() == digest,
                "modified canonical asset: " + name)

    # Same private-/tmp bind-mount convention as six-two-one-x11-runner.py.
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    artifacts_fd = os.open(artifacts, os.O_RDONLY | os.O_DIRECTORY)
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int

    def mount(source, target, filesystem=None, flags=0):
        if libc.mount(os.fsencode(source), os.fsencode(target),
                      None if filesystem is None else os.fsencode(filesystem),
                      flags, None) != 0:
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), str(target))

    try:
        mount("tmpfs", "/tmp", "tmpfs", 2 | 4)
        os.chmod("/tmp", 0o1777)
        root = Path("/tmp/babel7drl-root")
        artifacts = Path("/tmp/babel7drl-evidence")
        root.mkdir()
        artifacts.mkdir()
        mount("/proc/self/fd/" + str(root_fd), root, flags=4096)
        mount("/proc/self/fd/" + str(artifacts_fd), artifacts, flags=4096)
        Path("/tmp/.X11-unix").mkdir()
        os.chmod("/tmp/.X11-unix", 0o1777)
    finally:
        os.close(root_fd)
        os.close(artifacts_fd)
    for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                                ("TMPDIR", "tmp")):
        os.environ[variable] = str(root / directory)
    environment = dict(os.environ)
    environment.update(SDL_VIDEODRIVER="x11", SDL_AUDIODRIVER="dummy",
                       LIBGL_ALWAYS_SOFTWARE="1", MESA_SHADER_CACHE_DISABLE="true",
                       DBUS_SESSION_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-bus"),
                       DBUS_SYSTEM_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-system-bus"))
    state = root / "data/babel7drl"
    events = []

    def tool(*args):
        return subprocess.check_output(args, env=environment, timeout=10)

    # Read the original ASCII_INCOL 16x16 font by magic, not its misleading suffix.
    fw, fh = map(int, tool(convert, str(assets / "terminal.png"),
                          "-format", "%w %h", "info:").split())
    require(fw % 16 == 0 and fh % 16 == 0, "invalid font grid")
    cw, ch = fw // 16, fh // 16
    width, height = cw * 80, ch * 40  # gfxengine.h SCR_WIDTH/HEIGHT
    font = tool(convert, str(assets / "terminal.png"), "-depth", "8", "rgba:-")
    require(len(font) == fw * fh * 4, "incomplete original font")
    transparent = any(font[i] < 255 for i in range(3, len(font), 4))
    space = ((32 % 16) * ch + ch // 2) * fw + (32 // 16) * cw + cw // 2
    invert = font[space * 4] > 128
    glyphs = {}
    for code in range(32, 127):
        values = []
        for y in range((code % 16) * ch, (code % 16 + 1) * ch):
            for x in range((code // 16) * cw, (code // 16 + 1) * cw):
                i = (y * fw + x) * 4
                values.append(font[i + 3] if transparent else
                              255 - font[i] if invert else font[i])
        peak = max(values)
        glyphs[chr(code)] = sum(1 << i for i, value in enumerate(values)
                               if peak and value > peak / 3)

    def read_surface(pixels):
        rows = []
        for row in range(40):
            line = ""
            for column in range(80):
                cell = [tuple(pixels[((row * ch + y) * width + column * cw + x) * 3:
                                     ((row * ch + y) * width + column * cw + x) * 3 + 3])
                        for y in range(ch) for x in range(cw)]
                background = max(set(cell), key=cell.count)
                distances = [sum((a - b) ** 2 for a, b in zip(p, background)) ** 0.5
                             for p in cell]
                peak = max(distances)
                mask = sum(1 << i for i, distance in enumerate(distances)
                           if peak and distance > peak / 3)
                error, character = min(((mask ^ glyph).bit_count(), character)
                                       for character, glyph in glyphs.items())
                line += character if error <= cw * ch * 0.08 else "~"
            rows.append(line)
        return "\n".join(rows)

    # A window manager would deliver this ICCCM close request. SDL's X11 backend
    # translates WM_DELETE_WINDOW into SDL_QUIT; no signal/preload/debug API.
    class ClientMessage(ctypes.Structure):
        _fields_ = [("type", ctypes.c_int), ("serial", ctypes.c_ulong),
                    ("send_event", ctypes.c_int), ("display", ctypes.c_void_p),
                    ("window", ctypes.c_ulong), ("message_type", ctypes.c_ulong),
                    ("format", ctypes.c_int), ("data", ctypes.c_long * 5)]

    class XEvent(ctypes.Union):
        _fields_ = [("client", ClientMessage), ("padding", ctypes.c_long * 24)]

    x11 = ctypes.CDLL(xlib)
    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
    x11.XInternAtom.restype = ctypes.c_ulong
    x11.XSendEvent.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int,
                              ctypes.c_long, ctypes.POINTER(XEvent)]
    x11.XSendEvent.restype = ctypes.c_int
    x11.XFlush.argtypes = [ctypes.c_void_p]
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]

    process = server = None
    with open(artifacts / "xvfb.log", "wb") as server_log:
        try:
            read_fd, write_fd = os.pipe()
            try:
                server = subprocess.Popen(
                    [xvfb, "-displayfd", str(write_fd), "-screen", "0",
                     f"{max(1024, width)}x{max(768, height)}x24", "-nolisten", "tcp", "-ac"],
                    pass_fds=(write_fd,), stdout=server_log, stderr=server_log, env=environment)
                os.close(write_fd)
                write_fd = None
                require(select.select([read_fd], [], [], 15)[0], "Xvfb display timed out")
                with os.fdopen(read_fd, "rb") as pipe:
                    display = pipe.readline().decode("ascii").strip()
                require(display.isdecimal(), "Xvfb did not allocate display")
            finally:
                if write_fd is not None:
                    os.close(write_fd)
            environment["DISPLAY"] = ":" + display

            def launch(label):
                nonlocal process
                with open(artifacts / ("game-" + label + ".log"), "wb") as log:
                    process = subprocess.Popen([str(output / "bin/babel7drl")],
                                               cwd=root / "work", env=environment,
                                               stdout=log, stderr=log)
                deadline = time.monotonic() + 20
                while time.monotonic() < deadline:
                    require(process.poll() is None, "game exited before login")
                    found = subprocess.run(
                        [xdotool, "search", "--onlyvisible", "--name", "^Tower of Babel$"],
                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                        env=environment, timeout=5)
                    if found.returncode == 0:
                        window = found.stdout.decode().splitlines()[0]
                        tool(xdotool, "windowfocus", "--sync", window)
                        require(Path(os.readlink(f"/proc/{process.pid}/cwd")) == state / "linux",
                                "launcher did not use caller XDG linux directory")
                        require(Path(os.readlink(f"/proc/{process.pid}/exe")).resolve() ==
                                (output / "libexec/babel7drl").resolve(),
                                "launcher did not exec source-built game")
                        return window
                    time.sleep(0.1)
                raise RuntimeError("native SDL window timed out")

            def key(name):
                tool(xdotool, "key", "--clearmodifiers", name)
                events.append({"key": name})
                time.sleep(0.25)

            def capture(label, window):
                require(process.poll() is None, "game exited during " + label)
                dump, png = artifacts / (label + ".xwd"), artifacts / (label + ".png")
                tool(xwd, "-silent", "-id", window, "-out", str(dump))
                tool(convert, str(dump), str(png))
                require(tuple(map(int, tool(convert, str(png), "-format", "%w %h", "info:").split()))
                        == (width, height), "unexpected native framebuffer dimensions")
                pixels = tool(convert, str(png), "-depth", "8", "rgb:-")
                require(len(pixels) == width * height * 3, "incomplete framebuffer")
                surface = read_surface(pixels)
                (artifacts / (label + "-surface.txt")).write_text(surface + "\n")
                return surface

            def await_surface(label, window, predicate, timeout=15):
                deadline = time.monotonic() + timeout
                while time.monotonic() < deadline:
                    surface = capture(label, window)
                    if predicate(surface):
                        return surface
                    time.sleep(0.2)
                raise RuntimeError("native surface assertion timed out: " + label)

            def close(window):
                connection = x11.XOpenDisplay(environment["DISPLAY"].encode())
                require(connection, "cannot open private X display for close request")
                try:
                    event = XEvent()
                    event.client.type = 33  # ClientMessage
                    event.client.display = connection
                    event.client.window = int(window)
                    event.client.message_type = x11.XInternAtom(connection, b"WM_PROTOCOLS", 0)
                    event.client.format = 32
                    event.client.data[0] = x11.XInternAtom(connection, b"WM_DELETE_WINDOW", 0)
                    require(x11.XSendEvent(connection, int(window), 0, 0, ctypes.byref(event)),
                            "native window close request failed")
                    x11.XFlush(connection)
                finally:
                    x11.XCloseDisplay(connection)
                require(process.wait(timeout=15) == 0, "game did not cleanly handle SDL_QUIT")
                events.append({"window_close": "WM_DELETE_WINDOW", "exit_status": 0})

            def login(label, window, name):
                await_surface(label + "-login", window,
                              lambda text: "WELCOME TO THE TOWER OF BABEL." in text and
                              "LOGIN NAME:" in text)
                tool(xdotool, "type", "--clearmodifiers", "--delay", "100", name)
                events.append({"login": name})
                key("Return")
                await_surface(label + "-welcome", window,
                              lambda text: "prized" in text and "recover it" in text)
                key("space")
                return await_surface(label + "-initial", window,
                                     lambda text: "Depth: 1" in text and name in text)

            window = launch("default")
            initial = login("default", window, "DefaultUI")
            require((state / "babel.cfg").read_bytes() == (assets / "babel.cfg").read_bytes(),
                    "default launch changed canonical caller configuration")
            key("F3")
            await_surface("default-help", window,
                          lambda text: "mapping" in text and "remap keys using F1" in text)
            key("space")
            await_surface("default-help-dismissed", window, lambda text: "Depth: 1" in text)
            close(window)

            config = state / "babel.cfg"
            original_config = config.read_text()
            require(original_config.count("easymode = false") == 1,
                    "canonical supported EasyMode setting missing")
            config.write_text(original_config.replace("easymode = false", "easymode = true"))
            (artifacts / "gameplay-babel.cfg").write_text(config.read_text())
            window = launch("gameplay")
            initial = login("gameplay", window, "NativePlay")
            key("c")  # source.txt KEY_CLIMB, MOB::actionClimb
            climbed = await_surface("climb", window,
                                    lambda text: "cannot climb without" in text or
                                    "nothing to climb" in text)
            require("Depth: 1" in climbed, "failed surface climb changed depth")

            # DISPLAY is avatar-centred. A successful real move reveals '<' at
            # the old spawn, shifted opposite the input relative to '@'. This
            # compares actual game glyph locations, not animated pixel hashes.
            base = climbed.splitlines()
            avatar = [(x, y) for y in range(1, 29) for x in range(50) if base[y][x] == "@"]
            require(len(avatar) == 1, "cannot identify actual avatar glyph")
            ax, ay = avatar[0]
            movement = None
            for number, (name, dx, dy) in enumerate(
                    (("l", 1, 0), ("h", -1, 0), ("j", 0, 1), ("k", 0, -1),
                     ("u", 1, -1), ("y", -1, -1), ("n", 1, 1), ("b", -1, 1))):
                key(name)
                moved = capture("movement-" + str(number), window)
                rows = moved.splitlines()
                if rows[ay][ax] == "@" and rows[ay - dy][ax - dx] == "<":
                    movement = {"key": name, "delta": [dx, dy], "avatar": [ax, ay],
                                "previous_spawn_stair": [ax - dx, ay - dy]}
                    break
                require("Depth: 1" in moved and "NativePlay" in moved,
                        "player died before directional movement proof")
            require(movement is not None, "directional input did not shift spawn stair relative to avatar")
            # The action sets HP=1, then the normal food/regeneration heartbeat
            # may heal it (ai.cpp). HUD labels are randomized, but remain stable
            # for this run: identify the changing numeric field, not its label.
            before_stats = dict(re.findall(r"([A-Z][a-z]):\s*(\d+)", moved.splitlines()[29]))
            require(len(before_stats) == 6, "native pre-action statline unreadable")
            key("a")  # supported native KEY_SUICIDE, first attempt then heartbeat
            attempt = capture("native-death-attempt", window)
            after_stats = dict(re.findall(r"([A-Z][a-z]):\s*(\d+)", attempt.splitlines()[29]))
            require(before_stats.keys() == after_stats.keys(), "native statline labels changed")
            reductions = {label: [int(before_stats[label]), int(value)]
                          for label, value in after_stats.items()
                          if int(value) < int(before_stats[label])}
            attempt_notes = ("Blearily, you wake up.", "Sanity barely intervenes.",
                             "give it a good try, but fail.", "open your cartoid artery.",
                             "doesn't hit you fully.", "commend all but a spark to the void.",
                             "quick reminder of why they deserve respect.")
            normalized = " ".join(attempt.split())
            require(len(reductions) == 1 and
                    all(after in (1, 2, 3) for before, after in reductions.values()) and
                    all(after_stats[label] == value for label, value in before_stats.items()
                        if label not in reductions) and
                    ("At Death's Gate" in attempt or "Critically Injured" in attempt) and
                    any(note in normalized for note in attempt_notes),
                    "native first death action did not lower health to its post-heartbeat boundary with its attempt message")
            key("a")  # myHasTriedSuicide ensures actual HP=0 on the second action
            await_surface("native-loss", window,
                          lambda text: "life blood bleeds out" in text and "another universe" in text,
                          timeout=30)
            key("space")
            restarted = login("restart", window, "Restarted")
            require("Depth: 1" in restarted and "Restarted" in restarted and
                    "NativePlay" not in restarted, "native death/reconnect did not create new player run")
            close(window)

            # No persistence fabricated for a build with native saving disabled.
            require(not list((state / "save").iterdir()), "unexpected native save output")
            links = {"names.txt": assets / "names.txt", "text.txt": assets / "text.txt",
                     "rooms/village.map": assets / "rooms/village.map",
                     "linux/terminal.png": assets / "terminal.png"}
            for relative, target in links.items():
                path = state / relative
                require(path.is_symlink() and path.resolve() == target.resolve(),
                        "mutable/copied immutable asset: " + relative)
            require(config.is_file() and not config.is_symlink() and config.stat().st_mode & 0o200,
                    "configuration is not caller-writable")
            expected = {"linux", "rooms", "save", "babel.cfg", *links}
            actual = set()
            for parent, directories, files in os.walk(state, followlinks=False):
                actual.update(str((Path(parent) / name).relative_to(state))
                              for name in directories + files)
            require(actual == expected, "unexpected state paths: " + repr(actual ^ expected))
            for directory in ("home", "config", "cache", "state", "runtime", "work", "tmp"):
                require(not list((root / directory).iterdir()),
                        "game wrote outside XDG data: " + directory)
            require(list((root / "data").iterdir()) == [state], "unexpected XDG data sibling")
            proof = {"namespaces": namespaces, "interfaces": interfaces,
                     "assets": asset_hashes, "framebuffer": {"width": width, "height": height},
                     "default_randomized_ui": True, "supported_easymode": True,
                     "movement": movement, "native_loss_and_restart": True,
                     "native_health_reduction": reductions,
                     "normal_window_close_exit": 0, "state_confinement": True,
                     "save_files": [], "events": events,
                     "limitations": ["Upstream saving on shutdown disabled; no resume proof",
                                     "Hayes/server text is local UI, not a network connection",
                                     "Floor descent, combat, boss victory unexercised"]}
            (artifacts / "proof.json").write_text(json.dumps(proof, indent=2) + "\n")
            print(json.dumps(proof, indent=2), flush=True)
        finally:
            for child in (process, server):
                if child is not None and child.poll() is None:
                    child.terminate()
                    try:
                        child.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        child.wait()
    print("TOWER OF BABEL: native movement, climb feedback, death/reconnect and clean SDL shutdown")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("babel7drl native: " + str(error), file=sys.stderr, flush=True)
        sys.exit(1)
