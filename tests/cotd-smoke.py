#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Drive the installed SDL game; inspect its actual CL-STORE saves read-only."""
import json
import os
from pathlib import Path
import select
import socket
import subprocess
import sys
import tempfile
import time

package_arg, artifact_arg, xvfb, capture, mount, xdotool, sbcl, ocr = sys.argv[1:]
package = Path(package_arg)
artifacts = Path(artifact_arg).resolve()
artifacts.mkdir(parents=True, exist_ok=True)
subprocess.run([mount, "--make-rprivate", "/"], check=True)
subprocess.run([mount, "-t", "tmpfs", "tmpfs", "/tmp/.X11-unix"], check=True)
if [name for _, name in socket.if_nameindex()] != ["lo"]:
    raise RuntimeError("CotD proof requires a private network namespace")

with tempfile.TemporaryDirectory(prefix="cotd-native-") as temporary:
    root = Path(temporary)
    environment = {"PATH": "", "LC_ALL": "C", "LANG": "C",
                   "SDL_VIDEODRIVER": "x11", "SDL_AUDIODRIVER": "dummy",
                   "LIBGL_ALWAYS_SOFTWARE": "1", "SDL_RENDER_DRIVER": "software",
                   "SDL_FRAMEBUFFER_ACCELERATION": "0"}
    for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                           ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                           ("TMPDIR", "tmp")):
        directory = root / name
        directory.mkdir(mode=0o700)
        environment[variable] = str(directory)
    read_fd, write_fd = os.pipe()
    server = application = None
    window = None
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

        def launch(name):
            global application, window
            with (artifacts / (name + ".log")).open("wb") as log:
                application = subprocess.Popen([str(package / "bin/cotd")],
                                               env=environment, cwd=root, stdout=log,
                                               stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 60
            while time.monotonic() < deadline:
                status = application.poll()
                if status is not None:
                    raise RuntimeError("CotD exited before its native SDL window appeared: "
                                       + str(status))
                result = subprocess.run(
                    [xdotool, "search", "--onlyvisible", "--name", "The City of the Damned"],
                    env=environment, capture_output=True, text=True)
                if result.returncode == 0:
                    window = result.stdout.splitlines()[0]
                    subprocess.run([xdotool, "windowfocus", "--sync", window],
                                   env=environment, check=True)
                    return
                time.sleep(0.2)
            raise RuntimeError("Native CotD window did not appear")

        def key(*keys):
            if application.poll() is not None:
                raise RuntimeError("CotD exited during native interaction")
            subprocess.run([xdotool, "key", "--clearmodifiers", "--delay", "150", *keys],
                           env=environment, check=True, timeout=10)
            time.sleep(0.5)

        def screenshot(name):
            path = artifacts / (name + ".png")
            subprocess.run([capture, "-window", window or "root", str(path)],
                           env=environment, check=True, timeout=10)
            return path

        def text():
            image = screenshot("current")
            result = subprocess.run([ocr, str(image), "stdout", "--psm", "11"],
                                    env=environment, capture_output=True, text=True,
                                    check=True, timeout=15)
            return result.stdout.lower()

        def expect(phrase, dismiss=False):
            deadline = time.monotonic() + 90
            latest = ""
            while time.monotonic() < deadline:
                latest = text()
                if dismiss and ("welcome to" in latest
                                or "save game loaded successfully" in latest):
                    key("space")
                    continue
                if dismiss and "situation report" in latest and "campaign map" not in latest:
                    key("Escape")
                    continue
                if phrase.lower() in latest:
                    return
                if "error:" in latest:
                    raise RuntimeError("Native CotD error dialog: " + latest)
                time.sleep(0.5)
            raise AssertionError("Native UI did not show " + phrase + ": " + latest)

        def load_campaign():
            expect("new campaign")
            # Letter shortcut moves the selection; Enter commits it.
            key("b", "Return")
            expect("load campaign")
            key("Return")
            expect("campaign map", dismiss=True)

        def save_and_exit(label):
            key("Escape")
            expect("save campaign")
            key("Return")
            expect("new campaign")
            key("Escape")
            if application.wait(timeout=20) != 0:
                raise AssertionError("Native CotD did not exit cleanly")
            saved = Path(environment["XDG_STATE_HOME"]) / "cotd/saves/campaign/save0/game"
            if not saved.is_file():
                raise AssertionError("Native campaign save was not written")
            (artifacts / (label + ".game")).write_bytes(saved.read_bytes())
            return saved

        # Read-only inspector loads the installed compiled system with exactly
        # the package registry, then calls upstream LOAD-GAME-FROM-DISK.  It
        # neither creates the campaign nor changes the application under test.
        entry = (package / "libexec/cotd.lisp").read_text()
        initialization = entry.rsplit("(cotd::cotd-exec)", 1)[0]
        inspector = root / "inspect.lisp"
        inspector.write_text(initialization + r'''
(let* ((saved (cotd::load-game-from-disk (pathname (first uiop:*command-line-arguments*))))
       (destination (second uiop:*command-line-arguments*)))
  (assert saved)
  (assert (eq (cotd::serialized-game/save-type saved) :save-campaign))
  (assert (= (cotd::world/player-specific-faction cotd::*world*)
             cotd::+specific-faction-type-angel-chrome+))
  (with-open-file (stream destination :direction :output :if-exists :supersede)
    (format stream "~D~%" (cotd::world-game-time cotd::*world*))
    (let ((cells (cotd::cells (cotd::world-map cotd::*world*))))
      (print (list (cotd::world/player-specific-faction cotd::*world*)
                   (array-dimensions cells)
                   (loop for x below (array-dimension cells 0) collect
                     (loop for y below (array-dimension cells 1)
                           for cell = (aref cells x y)
                           collect (list (cotd::wtype cell)
                                         (cotd::controlled-by cell)
                                         (cotd::feats cell)
                                         (cotd::items cell))))) stream))))
''')

        def inspect(saved, name):
            destination = artifacts / (name + ".state")
            inspector_env = dict(environment)
            inspector_env["COTD_ASDF_CONFIG"] = str(package / "etc/xdg/common-lisp")
            with (artifacts / (name + "-inspect.log")).open("wb") as log:
                subprocess.run([sbcl, "--noinform", "--no-userinit", "--no-sysinit",
                                "--script", str(inspector), str(saved), str(destination)],
                               env=inspector_env, stdout=log, stderr=subprocess.STDOUT,
                               check=True, timeout=60)
            return destination.read_text()

        launch("created")
        expect("new campaign")
        screenshot("launched")
        key("Return")
        expect("chrome angel")
        key("Return")
        # Name entry has no fixed header; default Player is already filled.
        time.sleep(1)
        key("Return")
        expect("new campaign")  # World generation preview.
        key("Return")          # Accept map, generate missions.
        expect("campaign map", dismiss=True)
        screenshot("campaign")
        baseline = inspect(save_and_exit("baseline"), "baseline")

        launch("played")
        load_campaign()
        key("n")               # Genuine strategy gameplay: advance one day.
        expect("select a command")
        key("Return")          # Select the required faction command.
        expect("campaign map", dismiss=True)
        screenshot("played")
        played = inspect(save_and_exit("played"), "played")
        if int(played.splitlines()[0]) <= int(baseline.splitlines()[0]):
            raise AssertionError("Native Next day action did not advance campaign time")

        launch("restored")
        load_campaign()
        screenshot("restored")
        restored = inspect(save_and_exit("restored"), "restored")
        if restored != played:
            raise AssertionError("Native resume/resave changed time, faction or world map")
        (artifacts / "result.json").write_text(json.dumps({
            "package": str(package), "native_window": window,
            "campaign_faction": "Chrome angel", "action": "Next day",
            "initial_time": int(baseline.splitlines()[0]),
            "played_time": int(played.splitlines()[0]),
            "native_resume_preserves_time_faction_map": True,
            "network": "private namespace; loopback only",
            "scope": "campaign strategy action and campaign save/resume, not tactical combat"
        }, indent=2) + "\n")
        print("CotD native campaign gameplay and save/resume passed")
    except BaseException:
        game_state = Path(environment["XDG_STATE_HOME"]) / "cotd"
        if game_state.is_dir():
            for log in game_state.glob("log.txt*"):
                if log.is_file():
                    (artifacts / ("native-" + log.name)).write_bytes(log.read_bytes())
        if server is not None and server.poll() is None and "DISPLAY" in environment:
            screenshot("failure")
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
