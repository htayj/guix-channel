#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Exercise the unmodified installed GenEd process through native X events.

GENED_SMOKE_ACTIONS may name a JSON array of xdotool argument arrays, with
{scene}, {reopened}, {text}, {window} placeholders, and named checkpoint
objects: {"capture": "opened"}, {"assert_saved": true},
{"assert_reopened": true}.  Coordinates are surface-specific, not Lisp calls.
"""
import json
import os
from pathlib import Path
import select
import socket
import subprocess
import sys
import tempfile
import time

package, artifact_arg, xvfb, capture, mount, xdotool = sys.argv[1:]
artifacts = Path(artifact_arg).resolve()
artifacts.mkdir(parents=True, exist_ok=True)
action_path = os.environ.get("GENED_SMOKE_ACTIONS")
inspect_seconds = int(os.environ.get("GENED_SMOKE_INSPECT_SECONDS", "0"))
if action_path is None:
    action_path = str(Path(__file__).with_name("gened-actions.json"))
actions = [] if inspect_seconds else json.loads(Path(action_path).read_text())
subprocess.run([mount, "--make-rprivate", "/"], check=True)
subprocess.run([mount, "-t", "tmpfs", "tmpfs", "/tmp/.X11-unix"], check=True)
if [name for _, name in socket.if_nameindex()] != ["lo"]:
    raise RuntimeError("GenEd proof requires a private network namespace")

with tempfile.TemporaryDirectory(prefix="gened-native-") as temporary:
    root = Path(temporary)
    environment = {"PATH": "", "LC_ALL": "C", "LANG": "C"}
    for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                           ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                           ("TMPDIR", "tmp")):
        directory = root / name
        directory.mkdir(mode=0o700)
        environment[variable] = str(directory)
    read_fd, write_fd = os.pipe()
    server = application = None
    saved = reopened = False
    text = "GenEd native exact text 750"
    scene = root / "edited.scene"
    second = root / "reopened.scene"
    try:
        with (artifacts / "xvfb.log").open("wb") as log:
            server = subprocess.Popen(
                [xvfb, "-displayfd", str(write_fd), "-screen", "0", "1600x1200x24",
                 "-nolock", "-nolisten", "tcp"], env=environment,
                stdout=log, stderr=subprocess.STDOUT, pass_fds=(write_fd,))
        os.close(write_fd)
        write_fd = None
        if not select.select([read_fd], [], [], 10)[0]:
            raise RuntimeError("Xvfb did not report a display")
        number = os.read(read_fd, 32).decode().strip()
        if not number.isdigit():
            raise RuntimeError("Xvfb did not allocate a display")
        environment["DISPLAY"] = ":" + number
        with (artifacts / "gened.log").open("wb") as log:
            application = subprocess.Popen([str(Path(package) / "bin/gened")],
                                           env=environment, cwd=root, stdout=log,
                                           stderr=subprocess.STDOUT)
        window = None
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            if application.poll() is not None:
                raise RuntimeError("GenEd exited before native GUI appeared")
            result = subprocess.run([xdotool, "search", "--onlyvisible", "--name", "GenEd"],
                                    env=environment, capture_output=True, text=True)
            if result.returncode == 0:
                window = result.stdout.splitlines()[0]
                break
            time.sleep(0.2)
        if window is None:
            raise RuntimeError("Native GenEd window did not appear")

        def screenshot(name):
            subprocess.run([capture, "-window", "root", str(artifacts / (name + ".png"))],
                           env=environment, check=True, timeout=10)

        def scene_tokens(path):
            # Upstream serializes Lisp objects one datum per line; retain
            # every slot and string exactly, ignoring newline encoding only.
            return path.read_text().splitlines()

        screenshot("launched")
        if inspect_seconds:
            print("GenEd inspection DISPLAY=" + environment["DISPLAY"], flush=True)
            time.sleep(inspect_seconds)
            screenshot("inspection")
            print("Inspection only; editor persistence proof not performed", flush=True)
            sys.exit(0)
        values = {"scene": str(scene), "reopened": str(second), "text": text,
                  "window": window,
                  "sample": str(root / "data/gened/scenes/noname")}
        for index, action in enumerate(actions):
            if application.poll() is not None:
                raise RuntimeError("GenEd exited during native interaction")
            if isinstance(action, list):
                subprocess.run([xdotool] + [item.format(**values) for item in action],
                               env=environment, check=True, timeout=10)
                time.sleep(0.5)
            elif "capture" in action:
                screenshot(action["capture"])
            elif "sleep" in action:
                time.sleep(action["sleep"])
            elif action.get("assert_saved"):
                if '"' + text + '"' not in scene_tokens(scene):
                    raise AssertionError("Saved native scene lacks exact edited text")
                (artifacts / "edited.scene").write_bytes(scene.read_bytes())
                saved = True
            elif action.get("assert_reopened"):
                if not saved:
                    raise AssertionError("Reopen must follow native save")
                if scene_tokens(scene) != scene_tokens(second):
                    raise AssertionError("Reopened/resaved native scene changed content")
                (artifacts / "reopened.scene").write_bytes(second.read_bytes())
                reopened = True
            else:
                raise ValueError(f"Unsupported native action {index}: {action}")
        if not (saved and reopened):
            raise AssertionError("Proof must save exact text, reopen and resave equal content")
        screenshot("reopened")
        (artifacts / "result.json").write_text(json.dumps({
            "package": package, "text": text, "native_window": window,
            "saved_exact_text": saved, "reopened_identical_scene": reopened,
            "network": "private namespace; loopback only"}, indent=2) + "\n")
        print("GenEd native open/edit/save/reopen passed")
    except BaseException:
        if server is not None and server.poll() is None and "DISPLAY" in environment:
            subprocess.run([capture, "-window", "root", str(artifacts / "failure.png")],
                           env=environment, timeout=10)
        raise
    finally:
        os.close(read_fd)
        if write_fd is not None:
            os.close(write_fd)
        for process in (application, server):
            if process is not None and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
