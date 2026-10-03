#!/usr/bin/env python3
"""Drive the installed crashRun window, never import or modify game code."""

import hashlib
import os
from pathlib import Path
import pickletools
import signal
import subprocess
import sys
import tarfile
import tempfile
import time


out, xvfb, xdotool, capture, convert, tesseract = map(Path, sys.argv[1:])


def digest(root):
    result = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        result.update(str(path.relative_to(root)).encode())
        result.update(str(path.lstat().st_mode).encode())
        if path.is_symlink():
            result.update(os.readlink(path).encode())
        elif path.is_file():
            result.update(path.read_bytes())
    return result.digest()


def saved_turn(archive):
    # Read only the two initial integer fields of the game's real save tuple;
    # no importing game classes and no executing pickle payloads.
    with tarfile.open(archive, "r:gz") as stream:
        member = stream.getmember("guix-smoke.crsf")
        assert member.isfile() and member.size > 0
        payload = stream.extractfile(member).read()
    values = []
    for opcode, value, _ in pickletools.genops(payload):
        if opcode.name in ("INT", "BININT", "BININT1", "BININT2", "LONG", "LONG1", "LONG4"):
            values.append(value)
            if len(values) == 2:
                return values[0]
        elif opcode.name in ("GLOBAL", "STACK_GLOBAL", "REDUCE", "NEWOBJ"):
            raise AssertionError("save tuple does not begin with turn counters")
    raise AssertionError("save has no turn counters")


before = digest(out)
assert not (out / "share/crashrun/crashrun-smoke.py").exists()
with tempfile.TemporaryDirectory(prefix="crashrun-smoke-") as temporary:
    root = Path(temporary)
    roots = {name: root / name for name in
             ("home", "config", "data", "cache", "state", "runtime", "tmp")}
    for path in roots.values():
        path.mkdir(mode=0o700)
    env = {
        "HOME": str(roots["home"]), "XDG_CONFIG_HOME": str(roots["config"]),
        "XDG_DATA_HOME": str(roots["data"]), "XDG_CACHE_HOME": str(roots["cache"]),
        "XDG_STATE_HOME": str(roots["state"]), "XDG_RUNTIME_DIR": str(roots["runtime"]),
        "TMPDIR": str(roots["tmp"]), "PATH": "", "LC_ALL": "C.UTF-8",
        "SDL_VIDEODRIVER": "x11", "SDL_AUDIODRIVER": "dummy",
        "LIBGL_ALWAYS_SOFTWARE": "1",
        # crashRun has no bus feature.  Do not permit libSDL to autolaunch a
        # desktop session daemon or consult the host's system/session bus.
        "DBUS_SESSION_BUS_ADDRESS": "unix:path=" + str(root / "no-session-bus"),
        "DBUS_SYSTEM_BUS_ADDRESS": "unix:path=" + str(root / "no-system-bus"),
        # Mesa's optional shader cache belongs to the graphical test backend,
        # not persistent gameplay.  Keep the fresh-XDG assertion strict.
        "MESA_SHADER_CACHE_DISABLE": "true",
    }
    game = None
    window = None
    read_fd, write_fd = os.pipe()
    xlog = (root / "xserver.log").open("wb")
    xserver = subprocess.Popen(
        [str(xvfb), "-displayfd", str(write_fd), "-screen", "0", "1200x900x24",
         "-nolisten", "tcp", "-ac", "-noreset"], pass_fds=(write_fd,), env=env,
        stdout=xlog, stderr=xlog, start_new_session=True)
    os.close(write_fd)
    try:
        import select
        assert select.select([read_fd], [], [], 15)[0], "Xvfb did not become ready"
        display = os.read(read_fd, 32).decode().strip()
        assert display.isdecimal(), "Xvfb did not allocate a display"
        env["DISPLAY"] = ":" + display

        def run(command):
            return subprocess.run([str(item) for item in command], env=env,
                                  check=True, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, text=True, timeout=15).stdout

        def text():
            run([capture, "-window", window, root / "screen.png"])
            # SDL draws the first glyph directly at x=0.  Give OCR a margin
            # and dark text on white without changing the evidence capture.
            run([convert, root / "screen.png", "-negate", "-bordercolor", "white",
                 "-border", "20", root / "ocr.png"])
            return run([tesseract, root / "ocr.png", "stdout", "--psm", "6"])

        def expect(needle):
            deadline = time.monotonic() + 20
            observed = ""
            while time.monotonic() < deadline:
                if game.poll() is not None:
                    raise AssertionError("game exited before " + needle + ": " +
                                         (root / "game.log").read_text())
                observed = text()
                if needle.lower() in observed.lower():
                    return observed
                time.sleep(.1)
            raise AssertionError("expected " + needle + "; rendered screen:\n" + observed)

        def key(value):
            run([xdotool, "windowfocus", "--sync", window])
            run([xdotool, "key", "--clearmodifiers", value])
            # The original SDL loop returns after one key, discarding the
            # other events in that batch.  Send one key per observed prompt.
            time.sleep(.12)

        def start():
            global game, window
            log = (root / "game.log").open("ab")
            game = subprocess.Popen([str(out / "bin/crashrun")], env=env, cwd=root,
                                    stdout=log, stderr=log, start_new_session=True)
            log.close()
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                # Match SDL's _NET_WM_PID, not WM_NAME: Xlib's UTF-8 title
                # conversion can fail in an empty locale environment.
                found = subprocess.run([str(xdotool), "search", "--onlyvisible",
                                        "--pid", str(game.pid)],
                                       env=env, text=True, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, timeout=5)
                if found.returncode == 0 and found.stdout.strip():
                    window = found.stdout.splitlines()[0]
                    break
                if game.poll() is not None:
                    raise AssertionError((root / "game.log").read_text())
                time.sleep(.1)
            else:
                raise AssertionError("crashRun window did not appear: " + found.stderr)
            expect("Welcome to crashRun")
            key("space")
            expect("What is your name")
            for character in "guix-smoke":
                key(character if character != "-" else "minus")
            key("Return")

        def save():
            key("shift+s")
            expect("sure you wish to save")
            key("y")
            expect("Top crashRunners")
            key("Return")
            expect("Be seeing you")
            key("Return")
            game.wait(timeout=10)
            assert game.returncode == 0, (root / "game.log").read_text()
            archive = roots["state"] / "crashrun/guix-smoke.crsg"
            assert archive.is_file(), "UI save did not create an archive"
            assert not archive.with_suffix(".crsf").exists(), "save left unpacked state"
            return saved_turn(archive)

        start()
        expect("Your initial stats")
        key("space")
        expect("Next you will select your skills")
        key("space")
        for points in range(6, 0, -1):
            expect("You have " + str(points) + " skill point")
            key("1")
            expect("category you wish to improve")
            key("a")
        expect("You are trained")
        key("space")
        expect("standard kit")
        key("s")
        expect("Outside")
        # Inventory and actual timed actions in the normal command context.
        key("i")
        expect("shotgun")
        key("space")
        expect("Outside")
        key("period")
        key("period")
        expect("Outside")
        run([capture, "-window", window, root / "gameplay.png"])
        first_turn = save()
        assert first_turn >= 3, "pass commands did not advance real game turns"

        start()
        # A loaded game skips stat rolls/skills and restores the outdoor map.
        expect("Outside")
        key("i")
        expect("shotgun")
        key("space")
        expect("Outside")
        key("period")
        expect("Outside")
        second_turn = save()
        assert second_turn > first_turn, (first_turn, second_turn)
        for name, path in roots.items():
            if name != "state":
                unexpected = [str(item.relative_to(root)) for item in path.rglob("*")]
                assert not unexpected, "game wrote outside XDG state: " + repr(unexpected)
        assert not any(path.is_symlink() for path in roots["state"].rglob("*"))
        assert digest(out) == before, "installed store output changed"
        print("crashrun native smoke passed: SDL UI, creation, inventory, turns, save/load/resave, isolated state, unchanged store")
    finally:
        os.close(read_fd)
        for process in (game, xserver):
            if process is not None and process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
        xlog.close()
        evidence = os.environ.get("CRASHRUN_SMOKE_EVIDENCE")
        if evidence:
            target = Path(evidence)
            target.mkdir(parents=True, exist_ok=True)
            for name in ("gameplay.png", "screen.png", "game.log", "xserver.log"):
                source = root / name
                if source.is_file():
                    (target / name).write_bytes(source.read_bytes())
            (target / "state-files.txt").write_text("\n".join(
                str(path.relative_to(root)) for path in sorted(root.rglob("*"))))
