#!/usr/bin/env python3
"""Exercise the original SDL game, retaining unmodified X11 screenshots."""

import ctypes
import os
from pathlib import Path
import subprocess
import sys
import time


def main():
    if len(sys.argv) != 8:
        raise RuntimeError("usage: runner GAME ROOT XVFB XDOTOOL XWD CONVERT ARTIFACTS")
    game, root, xvfb, xdotool, xwd, convert, artifacts = sys.argv[1:]
    root = Path(root)
    artifacts = Path(artifacts)
    artifacts.mkdir(parents=True, exist_ok=True)
    # The caller enters a private mount namespace.  Replace /tmp so both
    # X11 filesystem sockets and .X*-lock files stay away from the host.
    # Retain the caller's scratch and artifact directories through open
    # descriptors before hiding /tmp (either directory may be under /tmp).
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
        mount("tmpfs", "/tmp", "tmpfs", 2 | 4)  # MS_NOSUID | MS_NODEV
        os.chmod("/tmp", 0o1777)
        root = Path("/tmp/aquesttoofar-root")
        artifacts = Path("/tmp/aquesttoofar-artifacts")
        root.mkdir()
        artifacts.mkdir()
        mount("/proc/self/fd/" + str(root_fd), root, flags=4096)  # MS_BIND
        mount("/proc/self/fd/" + str(artifacts_fd), artifacts, flags=4096)
        os.mkdir("/tmp/.X11-unix", 0o1777)
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
    # SDL2's desktop integration asks libdbus for a session bus.  Without an
    # explicit address libdbus may autolaunch dbus-daemon and write ~/.dbus.
    # Neither a host bus nor a private bus is needed for this local game.
    environment.update(SDL_VIDEODRIVER="x11", SDL_AUDIODRIVER="dummy",
                       SDL_RENDER_DRIVER="software", LIBGL_ALWAYS_SOFTWARE="1",
                       MESA_SHADER_CACHE_DISABLE="true",
                       DBUS_SESSION_BUS_ADDRESS="unix:path=" +
                       str(root / "runtime" / "no-session-bus"),
                       DBUS_SYSTEM_BUS_ADDRESS="unix:path=" +
                       str(root / "runtime" / "no-system-bus"))
    server = process = None
    with open(root / "xvfb.log", "wb") as server_log, \
            open(root / "game.log", "wb") as game_log:
        try:
            # Xvfb selects an unused display; no host display or sockets are used.
            read_fd, write_fd = os.pipe()
            try:
                server = subprocess.Popen(
                    [xvfb, "-displayfd", str(write_fd), "-screen", "0",
                     "800x600x24", "-nolisten", "tcp", "-ac"],
                    pass_fds=(write_fd,), stdout=server_log, stderr=server_log,
                    env=environment)
                os.close(write_fd)
                write_fd = None
                with os.fdopen(read_fd, "rb") as display_pipe:
                    display = display_pipe.readline().decode("ascii").strip()
                if not display.isdecimal():
                    raise RuntimeError("Xvfb failed to allocate a display")
            finally:
                if write_fd is not None:
                    os.close(write_fd)
            environment["DISPLAY"] = ":" + display
            process = subprocess.Popen([game], cwd=root / "work", env=environment,
                                       stdout=game_log, stderr=game_log)

            def tool(*args):
                return subprocess.check_output(args, env=environment, timeout=10)

            deadline = time.monotonic() + 15
            window = None
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError("game exited before showing its window")
                found = subprocess.run(
                    [xdotool, "search", "--onlyvisible", "--name", "^A Quest Too Far$"],
                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                    env=environment, timeout=5)
                if found.returncode == 0:
                    window = found.stdout.decode().splitlines()[0]
                    break
                time.sleep(0.1)
            if window is None:
                raise RuntimeError("A Quest Too Far window did not appear")
            # Exact ten-pixel grid cells permit assertions on the real decline
            # field, rather than RNG-sensitive map snapshots or OCR guesses.
            tool(xdotool, "windowsize", "--sync", window, "560", "400")
            tool(xdotool, "windowfocus", "--sync", window)

            def key(name):
                tool(xdotool, "key", "--clearmodifiers", name)
                time.sleep(0.15)

            def capture(name):
                path = artifacts / (name + ".png")
                previous = None
                for _ in range(20):
                    if process.poll() is not None:
                        raise RuntimeError("game exited during " + name)
                    dump = artifacts / (name + ".xwd")
                    tool(xwd, "-silent", "-id", window, "-out", str(dump))
                    tool(convert, str(dump), str(path))
                    geometry = tool(convert, str(path), "-format", "%wx%h", "info:")
                    if geometry != b"560x400":
                        raise RuntimeError("unexpected game framebuffer geometry")
                    pixels = tool(convert, str(path), "-depth", "8", "rgb:-")
                    if len(pixels) != 560 * 400 * 3:
                        raise RuntimeError("incomplete framebuffer capture")
                    if pixels == previous:
                        return pixels
                    previous = pixels
                    time.sleep(0.1)
                raise RuntimeError("framebuffer did not settle during " + name)

            def crop(pixels, left, top, right, bottom):
                return b"".join(pixels[(y * 560 + left) * 3:
                                       (y * 560 + right) * 3]
                                for y in range(top, bottom))

            intro = capture("intro")
            if not any(intro):
                raise RuntimeError("intro framebuffer is blank")
            key("space")
            # Dismiss the entry description if it is awaiting SPACE.  These
            # keys never consume a turn in game_move_hero.
            key("space")
            key("space")
            initial = capture("game")
            if initial == intro or not any(crop(initial, 0, 390, 560, 400)):
                raise RuntimeError("SPACE did not enter the dungeon and its HUD")
            key("question")
            help_screen = capture("help")
            if help_screen == initial:
                raise RuntimeError("help did not open")
            key("Escape")
            resumed = capture("resumed")
            if crop(resumed, 0, 30, 560, 400) != crop(initial, 0, 30, 560, 400):
                raise RuntimeError("ESC did not restore the same dungeon and HUD")
            if resumed == help_screen:
                raise RuntimeError("help screen remained visible")
            def dismiss_messages(name):
                # message.cpp::wait_message accepts only SPACE.  Multiple
                # monster attacks can suspend the turn between messages;
                # period is deliberately ignored until they are acknowledged.
                # MESSAGE_HIGHLIGHT_STLYE uses background RGB 128,128,255
                # for its SPACE prompt; ordinary text has RGB 64,64,128
                # and the dungeon has black backgrounds.  This recognizes
                # the actual prompt, even for consecutive identical attacks.
                frame = capture(name)
                for _ in range(40):
                    message_area = crop(frame, 0, 0, 560, 390)
                    if not any(message_area[index:index + 3] == b"\x80\x80\xff"
                               for index in range(0, len(message_area), 3)):
                        return frame
                    key("space")
                    frame = capture(name)
                raise RuntimeError("message queue did not drain during " + name)

            for turn in range(1, 4):
                previous = dismiss_messages("before-turn-" + str(turn))
                key("period")
                current = capture("turn-" + str(turn))
                # Resting has no RNG-dependent coordinate effect.  The dec:
                # counter (columns 22..26, last row) must change every turn.
                if crop(current, 220, 390, 270, 400) == \
                        crop(previous, 220, 390, 270, 400):
                    raise RuntimeError("rest did not advance decline on turn " + str(turn))
                # The permanent dec: label and dungeon-level field survive.
                for left, right in ((180, 220), (480, 500)):
                    if crop(current, left, 390, right, 400) != \
                            crop(resumed, left, 390, right, 400):
                        raise RuntimeError("rest left the dungeon HUD")
            if process.poll() is not None:
                raise RuntimeError("game did not remain alive after real turns")
        finally:
            for child in (process, server):
                if child is not None and child.poll() is None:
                    child.terminate()
                    try:
                        child.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        child.wait()
    log = (root / "game.log").read_bytes()
    if b"An error has occurred" in log or b"shutting down" in log:
        raise RuntimeError("upstream reported a runtime error: " + log.decode(errors="replace"))
    print("AQUESTTOOFAR gameplay proof passed: intro, help, restoration, three decline turns")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("aquesttoofar smoke: " + str(error), file=sys.stderr)
        sys.exit(1)
