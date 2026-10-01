#!/bin/sh
# Prove installed advice lifecycle and a real graphical Org capture, offline.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [emacs-org-popup-posframe-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        emacs-org-popup-posframe)
fi

output_with_program() {
    program=$1
    shift
    for output in $($guix_bin build "$@"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix outputs for $*" >&2
    return 1
}
emacs_out=$(output_with_program bin/emacs emacs)
posframe_out=$($guix_bin build emacs-posframe)
python_out=$(output_with_program bin/python3 python)
xorg_out=$(output_with_program bin/Xvfb xorg-server)
util_linux_out=$(output_with_program bin/unshare util-linux)
coreutils_out=$(output_with_program bin/timeout coreutils)
imagemagick_out=$(output_with_program bin/import imagemagick)

license="$package_out/share/doc/emacs-org-popup-posframe/LICENSE"
test -f "$license"
grep -q 'GNU GENERAL PUBLIC LICENSE' "$license"
grep -q 'Version 3, 29 June 2007' "$license"
# Source screenshots are not installed runtime assets.
test -z "$(find "$package_out" -type f -iname '*.png' -print)"
test -z "$(find "$package_out" -type f -perm /222 -print -quit)"
before=$($guix_bin hash -S nar "$package_out")

# An external timeout bounds startup, nested Org input, and X capture.  Private
# mount/network/PID namespaces prevent host display/socket access and ensure
# the Emacs/Xvfb descendants disappear even when a runtime assertion fails.
set +e
"$coreutils_out/bin/timeout" --kill-after=5s 90s \
    "$util_linux_out/bin/unshare" --user --map-root-user --mount --net --ipc \
    --pid --kill-child --fork --mount-proc \
    "$python_out/bin/python3" - "$package_out" "$posframe_out" \
    "$emacs_out/bin/emacs" "$xorg_out/bin/Xvfb" \
    "$util_linux_out/bin/mount" "$imagemagick_out/bin/import" \
    "$channel_dir/tests/emacs-org-popup-posframe-smoke.el" <<'PY'
import os
import pathlib
import select
import signal
import socket
import struct
import subprocess
import sys
import tempfile

out, posframe = map(pathlib.Path, sys.argv[1:3])
emacs, xvfb, mount, capture, helper = sys.argv[3:]
artifacts = pathlib.Path(os.environ.get("ORG_POPUP_SMOKE_ARTIFACTS") or
                         tempfile.mkdtemp(prefix="org-popup-smoke-artifacts-")).resolve()
artifacts.mkdir(parents=True, exist_ok=True)
if artifacts == out.resolve() or out.resolve() in artifacts.parents:
    raise RuntimeError("capture artifacts must not be inside the package output")
print(f"Org popup screenshots and logs: {artifacts}", flush=True)


def lisp_directory(output, filename):
    matches = list(output.rglob(filename))
    if len(matches) != 1:
        raise RuntimeError(f"expected one installed {filename}: {matches}")
    return str(matches[0].parent)


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=3)


# Network namespaces isolate abstract X11 sockets; the private mount isolates
# pathname sockets.  -nolock prevents Xvfb creating a host /tmp/.X*-lock file.
subprocess.run([mount, "--make-rprivate", "/"], check=True, timeout=5)
if not pathlib.Path("/tmp/.X11-unix").is_dir():
    raise RuntimeError("smoke requires an existing /tmp/.X11-unix mount point")
subprocess.run([mount, "-t", "tmpfs", "tmpfs", "/tmp/.X11-unix"],
               check=True, timeout=5)
if [name for _, name in socket.if_nameindex()] != ["lo"]:
    raise RuntimeError("smoke did not enter a private network namespace")

with tempfile.TemporaryDirectory(prefix="org-popup-smoke-") as temporary:
    root = pathlib.Path(temporary)
    environment = {"PATH": "", "LC_ALL": "C", "LIBGL_ALWAYS_SOFTWARE": "1"}
    for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                           ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                           ("TMPDIR", "tmp")):
        directory = root / name
        directory.mkdir(mode=0o700)
        environment[variable] = str(directory)
    work = root / "work"
    work.mkdir()
    arguments = [emacs, "-Q", "-L", lisp_directory(out, "org-popup-posframe.el"),
                 "-L", lisp_directory(posframe, "posframe.el"), "-l", helper]
    batch = subprocess.run(arguments + ["--batch"], cwd=work, env=environment,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           timeout=20)
    (artifacts / "batch.log").write_bytes(batch.stdout)
    if batch.returncode or b"ORG_POPUP_BATCH_OK" not in batch.stdout:
        raise RuntimeError("batch advice lifecycle failed: " +
                           batch.stdout.decode("utf-8", "replace"))

    display = client = None
    read_fd, write_fd = os.pipe()
    png = artifacts / "org-capture-menu.png"
    environment.update({"ORG_POPUP_SMOKE_IMPORT": capture,
                        "ORG_POPUP_SMOKE_PNG": str(png)})
    with (artifacts / "xvfb.log").open("wb") as display_log, \
            (artifacts / "gui.log").open("wb") as client_log:
        try:
            display = subprocess.Popen(
                [xvfb, "-displayfd", str(write_fd), "-screen", "0", "1280x900x24",
                 "-nolock", "-nolisten", "tcp"], cwd=work, env=environment,
                stdout=display_log, stderr=subprocess.STDOUT, pass_fds=(write_fd,),
                start_new_session=True)
            os.close(write_fd)
            write_fd = None
            if not select.select([read_fd], [], [], 10)[0]:
                raise RuntimeError("Xvfb did not report a ready display")
            number = os.read(read_fd, 32).decode("ascii").strip()
            if not number.isdigit():
                raise RuntimeError("Xvfb failed; see xvfb.log")
            environment["DISPLAY"] = ":" + number
            client = subprocess.Popen(
                arguments + ["--eval", "(run-at-time 0.5 nil #'org-popup-smoke-gui)"],
                cwd=work, env=environment, stdin=subprocess.DEVNULL,
                stdout=client_log, stderr=subprocess.STDOUT, start_new_session=True)
            if client.wait(timeout=40):
                raise RuntimeError("graphical Org operation failed; see gui.log")
            if b"ORG_POPUP_GUI_OK" not in (artifacts / "gui.log").read_bytes():
                raise RuntimeError("graphical operation did not complete")
            image = png.read_bytes()
            if image[:8] != b"\x89PNG\r\n\x1a\n" or \
                    struct.unpack(">II", image[16:24]) != (1280, 900):
                raise RuntimeError("capture is not the private Xvfb root PNG")
        finally:
            stop(client)
            stop(display)
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
print("ORG_POPUP_RUNTIME_OK: batch lifecycle, rendered capture menu, selected template, "
      "finalized capture, popup hide/delete, isolated state")
PY
status=$?
set -e
# NAR hashing covers names, contents, symlinks, and executable modes, not just
# file bytes.  Verify immutability even when the runtime fails or times out.
after=$($guix_bin hash -S nar "$package_out")
test "$before" = "$after"
test -z "$(find "$package_out" -type f -perm /222 -print -quit)"
exit "$status"
