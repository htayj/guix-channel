#!/usr/bin/env python3
"""Offline visual acceptance of the installed, unmodified native companion.

The busy session is a local rendering fixture, not a provider conversation.
Plugin-produced idle state is covered separately by the plugin host helper.
"""

import contextlib
import ctypes
import json
import os
from pathlib import Path
import select
import shutil
import signal
import socket
import subprocess
import sys
import time


TITLE = "oh-my-opencode-slim-companion"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=3)


def private_tmp(root, artifacts):
    """Keep evidence reachable while hiding every host X socket and lock."""
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

    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    artifacts_fd = os.open(artifacts, os.O_RDONLY | os.O_DIRECTORY)
    try:
        mount("none", "/", flags=(1 << 18) | 16384)  # MS_PRIVATE | MS_REC
        mount("tmpfs", "/tmp", "tmpfs", 2 | 4)  # MS_NOSUID | MS_NODEV
        os.chmod("/tmp", 0o1777)
        root = Path("/tmp/slim-companion-work")
        artifacts = Path("/tmp/slim-companion-evidence")
        root.mkdir()
        artifacts.mkdir()
        mount("/proc/self/fd/" + str(root_fd), root, flags=4096)
        mount("/proc/self/fd/" + str(artifacts_fd), artifacts, flags=4096)
        os.mkdir("/tmp/.X11-unix", 0o1777)
        os.chmod("/tmp/.X11-unix", 0o1777)
    finally:
        os.close(root_fd)
        os.close(artifacts_fd)
    return root, artifacts


def crop(pixels, width, left, top, right, bottom):
    return b"".join(pixels[(y * width + left) * 3:(y * width + right) * 3]
                    for y in range(top, bottom))


def changed_pixels(first, second):
    require(len(first) == len(second), "pixel comparison geometry changed")
    return sum(max(abs(first[i + channel] - second[i + channel])
                   for channel in range(3)) > 25
               for i in range(0, len(first), 3))


def color_regions(pixels, width, height, color):
    """Locate actual painted menu controls; do not infer click targets from logs."""
    points = {i // 3 for i in range(0, len(pixels), 3)
              if pixels[i:i + 3] == bytes(color)}
    regions = []
    while points:
        start = points.pop()
        pending = [start]
        component = [start]
        while pending:
            current = pending.pop()
            x, y = current % width, current // width
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    neighbor = ny * width + nx
                    if neighbor in points:
                        points.remove(neighbor)
                        pending.append(neighbor)
                        component.append(neighbor)
        if len(component) >= 100:
            xs = [p % width for p in component]
            ys = [p // width for p in component]
            regions.append((min(xs), min(ys), max(xs), max(ys)))
    return regions


def main():
    require(len(sys.argv) == 4, "usage: driver COMPANION-OUTPUT ARTIFACTS SCRATCH")
    output = Path(sys.argv[1]).resolve()
    evidence = Path(sys.argv[2]).resolve()
    program = output / "bin" / TITLE
    source = output / "share/doc" / TITLE / "source"
    tools = {name: shutil.which(name) for name in
             ("Xvfb", "xdotool", "import", "convert", "identify")}
    require(all(tools.values()), "Guix test tools are incomplete")
    require([name for _, name in socket.if_nameindex()] == ["lo"],
            "runtime did not enter a private network namespace")
    metrics = {"fixture": "local rendering fixture; no provider turns",
               "output": str(output), "steps": []}
    # The outer shell removes the original scratch after the namespace exits;
    # its host path is deliberately invisible after replacing /tmp below.
    with contextlib.nullcontext(sys.argv[3]) as temporary:
        root, artifacts = private_tmp(Path(temporary), evidence)
        # Deliberately do not copy host environment, credentials, DISPLAY,
        # WAYLAND_DISPLAY, NIRI_SOCKET, provider URLs or DBus addresses.
        environment = {"PATH": os.environ["PATH"], "LC_ALL": "C",
                       "LIBGL_ALWAYS_SOFTWARE": "1", "GALLIUM_DRIVER": "llvmpipe",
                       "MESA_SHADER_CACHE_DISABLE": "true", "WINIT_UNIX_BACKEND": "x11",
                       "OH_MY_OPENCODE_SLIM_COMPANION_SESSION_ID": "guix-local-proof",
                       "OH_MY_OPENCODE_SLIM_COMPANION_DEBUG": "1"}
        for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                               ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                               ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                               ("TMPDIR", "tmp")):
            directory = root / name
            directory.mkdir(mode=0o700)
            environment[variable] = str(directory)
        environment["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=" + str(root / "runtime/no-session-bus")
        environment["DBUS_SYSTEM_BUS_ADDRESS"] = "unix:path=" + str(root / "runtime/no-system-bus")
        project = root / "LOCAL-A"
        project.mkdir()
        state_path = root / "data/opencode/storage/oh-my-opencode-slim/companion-state.json"
        state_path.parent.mkdir(parents=True)
        state = {"version": 1, "sessions": [{"session_id": "guix-local-proof",
                 "cwd": str(project), "active_agents": ["designer", "explorer"],
                 "status": "busy", "pid": os.getpid()}],
                 "config": {"enabled": True, "position": "top-left", "size": "medium",
                            "gifPack": "default", "loopStyle": "classic", "speed": 1}}

        def write_state(name):
            temporary_state = state_path.with_suffix(".tmp")
            temporary_state.write_text(json.dumps(state))
            temporary_state.replace(state_path)
            (artifacts / (name + ".json")).write_text(json.dumps(state, indent=2) + "\n")

        def tool(name, *arguments):
            return subprocess.check_output([tools[name], *map(str, arguments)],
                                           env=environment, cwd=root, timeout=10)

        def wait_for(description, predicate, seconds=10):
            deadline = time.monotonic() + seconds
            while time.monotonic() < deadline:
                require(companion is None or companion.poll() is None,
                        "companion exited while waiting for " + description)
                result = predicate()
                if result:
                    return result
                time.sleep(0.1)
            raise RuntimeError("timed out waiting for " + description)

        write_state("initial-local-state")
        with (artifacts / "xvfb.log").open("wb") as xlog, \
                (artifacts / "companion-stdio.log").open("wb") as clog:
            try:
                read_fd, write_fd = os.pipe()
                try:
                    server = subprocess.Popen(
                        [tools["Xvfb"], "-displayfd", str(write_fd), "-screen", "0",
                         "800x600x24", "-nolisten", "tcp", "-ac"],
                        env=environment, cwd=root, stdout=xlog, stderr=xlog,
                        pass_fds=(write_fd,), start_new_session=True)
                    os.close(write_fd)
                    write_fd = None
                    require(select.select([read_fd], [], [], 10)[0], "Xvfb did not become ready")
                    display = os.read(read_fd, 32).decode("ascii").strip()
                    require(display.isdecimal(), "Xvfb did not allocate a display")
                    environment["DISPLAY"] = ":" + display
                finally:
                    os.close(read_fd)
                    if write_fd is not None:
                        os.close(write_fd)
                companion = subprocess.Popen([str(program)], env=environment, cwd=project,
                                             stdout=clog, stderr=clog, start_new_session=True)

                def find_window():
                    result = subprocess.run(
                        [tools["xdotool"], "search", "--all", "--onlyvisible", "--pid", str(companion.pid),
                         "--name", "^" + TITLE + "$"], env=environment,
                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=5)
                    found = result.stdout.decode().splitlines()
                    return found[0] if result.returncode == 0 and len(found) == 1 else None

                window = wait_for("native titled window", find_window, 20)
                with Path(f"/proc/{companion.pid}/exe").open("rb") as executable:
                    require(executable.read(4) == b"\x7fELF", "window process is not a native ELF")
                require(tool("xdotool", "getwindowname", window).decode().strip() == TITLE,
                        "unexpected native window title")
                tool("xdotool", "windowfocus", "--sync", window)
                tool("xdotool", "mousemove", "790", "590")

                def geometry():
                    values = tool("xdotool", "getwindowgeometry", "--shell", window).decode()
                    return {key: int(value) for key, value in
                            (line.split("=", 1) for line in values.splitlines())}

                def expect_geometry(width, height, position=None):
                    def matches():
                        actual = geometry()
                        if (actual["WIDTH"], actual["HEIGHT"]) != (width, height):
                            return None
                        if position is not None and (actual["X"], actual["Y"]) != position:
                            return None
                        return actual
                    result = wait_for(f"geometry {width}x{height} at {position}", matches)
                    metrics["steps"].append({"geometry": result})
                    # Geometry events can arrive one repaint before new pixels.
                    time.sleep(0.25)
                    return result

                def capture(name):
                    size = geometry()
                    destination = artifacts / (name + ".png")
                    tool("import", "-window", window, destination)
                    dimensions = tool("identify", "-format", "%wx%h", destination)
                    require(dimensions == f'{size["WIDTH"]}x{size["HEIGHT"]}'.encode(),
                            "screenshot does not match native window geometry")
                    pixels = tool("convert", destination, "-depth", "8", "RGB:-")
                    require(len(pixels) == size["WIDTH"] * size["HEIGHT"] * 3,
                            "incomplete framebuffer capture")
                    return pixels

                expect_geometry(240, 120, (10, 10))
                initial = capture("medium-two-agents")
                frames = [initial]
                for index in range(1, 6):
                    time.sleep(0.17)
                    frames.append(capture(f"animation-{index}"))
                for column, agent in enumerate(("designer", "explorer")):
                    # Compare the actual picture area, excluding project text,
                    # menu/cursor and texture-boundary filtering artifacts.
                    live = [crop(frame, 240, column * 120 + 9, 9,
                                 column * 120 + 113, 89) for frame in frames]
                    changes = max(changed_pixels(live[0], frame) for frame in live[1:])
                    require(changes > 50, agent + " image did not animate")
                    sheet = source / "animations" / (agent + ".jpg")
                    dimensions = tool("identify", "-format", "%w %h", sheet).decode().split()
                    width, height = map(int, dimensions)
                    require(width % 12 == 0 and height % 6 == 0, "invalid retained sprite sheet")
                    references = tool("convert", sheet, "-crop", f"{width // 12}x{height // 6}",
                                      "+repage", "-filter", "Triangle", "-resize", "118x118!",
                                      "-crop", "104x80+8+8", "+repage", "-depth", "8", "RGB:-")
                    frame_bytes = 104 * 80 * 3
                    require(len(references) == 72 * frame_bytes, "incomplete reference sprite sheet")
                    # Sample every fourth pixel; reference decoding/resizing is
                    # independent of the native OpenGL texture renderer.
                    errors = [sum(abs(live[0][i] - references[offset + i])
                                  for i in range(0, frame_bytes, 12)) / len(range(0, frame_bytes, 12))
                              for offset in range(0, len(references), frame_bytes)]
                    require(min(errors) < 25, agent + " rendered image does not match its embedded sheet")
                    metrics[agent] = {"changed_pixels": changes, "best_reference_mae": min(errors)}

                def right_click():
                    tool("xdotool", "mousemove", "--window", window, "20", "20")
                    tool("xdotool", "click", "3")
                    time.sleep(0.25)

                right_click()
                menu = capture("size-menu-medium")
                active = color_regions(menu, 240, 120, (58, 72, 102))
                buttons = color_regions(menu, 240, 120, (30, 30, 32))
                require(len(active) == 1 and len(buttons) >= 3,
                        "Size menu did not render active M and S/L/XL buttons")
                left, top, right, bottom = active[0]
                require(20 <= left < right < 110 and 20 <= top < bottom < 95,
                        "active size button is outside the rendered popup")
                # The adjacent actual button is L (S/M/L/XL in upstream UI).
                tool("xdotool", "mousemove", "--window", window,
                     (left + right) // 2 + 18, (top + bottom) // 2)
                tool("xdotool", "click", "1")
                expect_geometry(320, 160, (10, 10))
                capture("large-selected-through-menu")
                metrics["steps"].append({"menu": "right-click Size; selected L; 240x120 -> 320x160"})

                # Changing state alone must preserve a local size selection.
                project_b = root / "LOCAL-B"
                project_b.mkdir()
                label_before = capture("project-label-before")
                state["sessions"][0]["cwd"] = str(project_b)
                write_state("project-update-local-state")

                def bright_label(pixels):
                    strip = crop(pixels, 320, 80, 137, 240, 158)
                    return bytes(min(strip[i:i + 3]) > 180 for i in range(0, len(strip), 3))

                before_mask = bright_label(label_before)
                require(sum(before_mask) > 20, "project label was not rendered")
                deadline = time.monotonic() + 8
                label_changes = 0
                while time.monotonic() < deadline:
                    label_after = capture("project-label-after")
                    after_mask = bright_label(label_after)
                    label_changes = sum(a != b for a, b in zip(before_mask, after_mask))
                    if sum(after_mask) > 20 and label_changes > 5:
                        break
                    time.sleep(0.2)
                require(label_changes > 5, "state cwd update did not change rendered project label")
                expect_geometry(320, 160)
                metrics["label_changed_pixels"] = label_changes
                state["config"].update(size="small", position="bottom-right")
                write_state("config-update-local-state")
                expect_geometry(160, 80, (630, 510))
                capture("small-config-reload")
                state["sessions"][0]["active_agents"] = ["explorer"]
                write_state("agents-update-local-state")
                expect_geometry(80, 80, (710, 510))
                capture("single-agent-state-reload")

                right_click()
                close_menu = capture("close-menu")
                close_regions = color_regions(close_menu, 80, 80, (38, 24, 26))
                require(len(close_regions) == 1, "Close button was not painted")
                left, top, right, bottom = close_regions[0]
                require(right - left > 40 and bottom - top > 8, "invalid rendered Close button")
                tool("xdotool", "mousemove", "--window", window,
                     (left + right) // 2, (top + bottom) // 2)
                tool("xdotool", "click", "1")
                require(companion.wait(timeout=10) == 0, "Close did not exit cleanly")
                result = subprocess.run([tools["xdotool"], "search", "--onlyvisible", "--name",
                                         "^" + TITLE + "$"], env=environment,
                                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=5)
                require(result.returncode == 1 and not result.stdout, "Close left a native window visible")
                debug = root / "data/opencode/log" / f"{TITLE}.{companion.pid}.log"
                debug_text = debug.read_text()
                for agent in ("designer", "explorer"):
                    require("animation lazy-load name=" + agent in debug_text,
                            "native embedded image lazy-load was not observed: " + agent)
                require("animation decode failed" not in debug_text, "native image decoder failed")
                metrics["steps"].append({"close": "actual painted Close button; process exit 0; window removed"})
                metrics["passed"] = True
                print("Slim companion GUI passed: native ELF/title, embedded animated pixels, Size/L, "
                      "state label/config/agent geometry reload, safe Close.", flush=True)
            finally:
                stop(companion)
                stop(server)
                log_directory = root / "data/opencode/log"
                if log_directory.exists():
                    for path in log_directory.glob("*.log"):
                        shutil.copyfile(path, artifacts / path.name)
                (artifacts / "metrics.json").write_text(json.dumps(metrics, indent=2) + "\n")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("Slim companion GUI proof failed: " + str(error), file=sys.stderr)
        sys.exit(1)
