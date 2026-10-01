#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Exercise the installed upstream Tk game on a private, networkless Xvfb.
# Keep real gameplay/restored PNGs and state evidence for visual review.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [ighalsk-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts ighalsk)
fi
find_output() {
    program=$1
    shift
    for candidate in $($guix_bin build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
image_out=$(find_output bin/import imagemagick)
util_out=$(find_output bin/unshare util-linux)
core_out=$(find_output bin/timeout coreutils)

test -x "$game_out/bin/ighalsk"
test -s "$game_out/share/doc/ighalsk/COPYING"
test -s "$game_out/share/doc/ighalsk/CREDITS"
grep -F 'Version 3' "$game_out/share/doc/ighalsk/COPYING" >/dev/null
grep -Fi 'Mike Anderson' "$game_out/share/doc/ighalsk/CREDITS" >/dev/null
test ! -e "$game_out/share/ighalsk/igh2exe.py"
test -z "$(find "$game_out" -name .svn -o -name '*.pyc')"
test -z "$(find "$game_out" -xdev -type f -perm /222 -print -quit)"
before=$($guix_bin hash -S nar "$game_out")

status=0
"$core_out/bin/timeout" --kill-after=5 240 \
    "$util_out/bin/unshare" --user --map-root-user --mount --net --ipc \
    --pid --kill-child --fork --mount-proc \
    "$python_out/bin/python3" - "$game_out" "$xorg_out/bin/Xvfb" \
    "$image_out/bin/import" "$util_out/bin/mount" <<'PY' || status=$?
import json
import os
from pathlib import Path
import select
import signal
import socket
import subprocess
import sys
import tempfile

out = Path(sys.argv[1]).resolve()
xvfb, capture, mount = sys.argv[2:]
artifacts = Path(os.environ.get("IGHALSK_SMOKE_ARTIFACTS") or
                 tempfile.mkdtemp(prefix="ighalsk-smoke-artifacts-")).resolve()
artifacts.mkdir(parents=True, exist_ok=True)
print("ighalsk artifacts: " + str(artifacts), flush=True)
subprocess.run([mount, "--make-rprivate", "/"], check=True, timeout=5)
if not Path("/tmp/.X11-unix").is_dir():
    raise RuntimeError("smoke requires an existing /tmp/.X11-unix mount point")
subprocess.run([mount, "-t", "tmpfs", "tmpfs", "/tmp/.X11-unix"],
               check=True, timeout=5)
if [name for _, name in socket.if_nameindex()] != ["lo"]:
    raise RuntimeError("smoke did not enter a private network namespace")

with tempfile.TemporaryDirectory(prefix="ighalsk-smoke-") as temporary:
    root = Path(temporary)
    environment = {"PATH": "", "LC_ALL": "C",
                   "IGHALSK_SMOKE_ARTIFACTS": str(artifacts),
                   "IGHALSK_SCREENSHOT_PROGRAM": capture}
    for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                           ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                           ("TMPDIR", "tmp")):
        directory = root / name
        directory.mkdir(mode=0o700)
        environment[variable] = str(directory)
    read_fd, write_fd = os.pipe()
    display = None
    try:
        with (artifacts / "xvfb.log").open("wb") as log:
            display = subprocess.Popen(
                [xvfb, "-displayfd", str(write_fd), "-screen", "0", "1600x1200x24",
                 "-nolock", "-nolisten", "tcp"], env=environment, cwd=root,
                stdout=log, stderr=subprocess.STDOUT, pass_fds=(write_fd,),
                start_new_session=True)
            os.close(write_fd)
            write_fd = None
            if not select.select([read_fd], [], [], 10)[0]:
                raise RuntimeError("Xvfb did not report a ready display")
            number = os.read(read_fd, 32).decode("ascii").strip()
            if not number.isdigit():
                raise RuntimeError("Xvfb failed to allocate a display")
            environment["DISPLAY"] = ":" + number
            completed = subprocess.run([str(out / "bin/ighalsk"), "--guix-smoke"],
                                       env=environment, cwd=root,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       timeout=100)
            (artifacts / "game.log").write_bytes(completed.stdout + completed.stderr)
            if completed.returncode:
                raise RuntimeError("ighalsk --guix-smoke failed; see game.log: " +
                                   completed.stderr.decode("utf-8", "replace"))
            if completed.stdout.strip() != b"ighalsk isolated smoke passed":
                raise RuntimeError("unexpected smoke output: " + repr(completed.stdout))
            for name in ("ighalsk-gameplay.png", "ighalsk-restored.png"):
                with (artifacts / name).open("rb") as image:
                    if image.read(8) != b"\x89PNG\r\n\x1a\n":
                        raise RuntimeError("not a captured PNG: " + name)
            proof = json.loads((artifacts / "state.json").read_text())
            if (proof["before"] != proof["after"] or
                    not proof["compressed_restore_equal"] or
                    not proof["save_observed"] or not proof["save_consumed"] or
                    proof["movement"]["from"] == proof["movement"]["to"] or
                    proof["after"]["name"] != "GuixHero" or
                    proof["after"]["dungeon_level"] != 1 or
                    proof["saved_bytes"] <= 0):
                raise RuntimeError("invalid gameplay/save/load state proof")
            editors = proof["editors"]
            if (not editors["monster_reload_equal"] or
                    not editors["level_reload_equal"] or
                    not editors["template_preserved"] or
                    editors["edited_monster_hp"] != editors["original_monster_hp"] + 17):
                raise RuntimeError("invalid editor save/reload/template proof")
            state = root / "data/ighalsk"
            if list(state.glob("*.sav")):
                raise RuntimeError("upstream load failed to consume its save")
            # Only XDG data owns mutable game state; no writes reach caller HOME
            # or another XDG state directory.  Caches (Tk/fontconfig) are allowed.
            for name in ("home", "config", "state", "runtime"):
                if list((root / name).iterdir()):
                    raise RuntimeError("unexpected state outside XDG data: " + name)
            # The public flag must work on an external display without either
            # capture-only variable.  Run the same real Tk proof in fresh state,
            # not against an output copy or the captured session's saved files.
            no_capture_data = root / "no-capture-data"
            no_capture_data.mkdir(mode=0o700)
            no_capture = dict(environment)
            no_capture.pop("IGHALSK_SMOKE_ARTIFACTS")
            no_capture.pop("IGHALSK_SCREENSHOT_PROGRAM")
            no_capture["XDG_DATA_HOME"] = str(no_capture_data)
            completed = subprocess.run([str(out / "bin/ighalsk"), "--guix-smoke"],
                                       env=no_capture, cwd=root,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       timeout=100)
            (artifacts / "no-capture.log").write_bytes(completed.stdout + completed.stderr)
            if completed.returncode or completed.stdout.strip() != b"ighalsk isolated smoke passed":
                raise RuntimeError("no-capture Tk smoke failed; see no-capture.log")
            no_capture_state = no_capture_data / "ighalsk"
            if (list(no_capture_state.glob("*.sav")) or
                    not (no_capture_state / editors["saved_dictionary"]).is_file() or
                    not (no_capture_state / "data/quests" / editors["saved_level"]).is_file() or
                    list(no_capture_data.rglob("state.json")) or
                    list(no_capture_data.rglob("*.png"))):
                raise RuntimeError("invalid no-capture smoke state")
    finally:
        os.close(read_fd)
        if write_fd is not None:
            os.close(write_fd)
        if display is not None and display.poll() is None:
            os.killpg(display.pid, signal.SIGTERM)
            try:
                display.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(display.pid, signal.SIGKILL)
                display.wait(timeout=5)
print("ighalsk isolated smoke passed")
PY

after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after" || { echo 'ighalsk store output changed' >&2; exit 1; }
test -z "$(find "$game_out" -xdev -type f -perm /222 -print -quit)"
test "$status" -eq 0
