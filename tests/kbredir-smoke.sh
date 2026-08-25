#!/bin/sh
# Exercise kbredir without touching a real console or a host X server.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [kbredir-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    kbredir_out=$1
else
    kbredir_out=$($guix_bin build -L "$channel_dir" --no-grafts kbredir)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
xorg_server_out=$($guix_bin build xorg-server)
xev_out=$($guix_bin build xev)
xdotool_out=$($guix_bin build xdotool)

test -n "$python_out"
test -x "$python_out/bin/python3"
test -x "$xorg_server_out/bin/Xvfb"
test -x "$xev_out/bin/xev"
test -x "$xdotool_out/bin/xdotool"
for program in read_vt220 read_linux_console read_xev write_vt220 \
               write_xsendevent write_xtest; do
    test -x "$kbredir_out/bin/$program"
done
test -f "$kbredir_out/share/doc/kbredir/COPYING"
grep -F 'GNU GENERAL PUBLIC LICENSE' "$kbredir_out/share/doc/kbredir/COPYING" >/dev/null
grep -F 'Version 2, June 1991' "$kbredir_out/share/doc/kbredir/COPYING" >/dev/null
test -z "$(find "$kbredir_out" -type f -perm /222 -print -quit)"

probe_root=$(mktemp -d "${TMPDIR:-/tmp}/kbredir-probes.XXXXXX")
trap 'rm -rf "$probe_root"' EXIT HUP INT TERM
mkdir "$probe_root/home" "$probe_root/config" "$probe_root/data" "$probe_root/cache" "$probe_root/state" "$probe_root/runtime"
chmod 700 "$probe_root/runtime"

# These four programs intentionally have no conventional help interface.  The
# rejected-option probes happen before any terminal interaction, so in
# particular read_linux_console never opens or changes a console tty.
for program in read_vt220 read_linux_console read_xev write_vt220; do
    if HOME="$probe_root/home" XDG_CONFIG_HOME="$probe_root/config" \
       XDG_DATA_HOME="$probe_root/data" XDG_CACHE_HOME="$probe_root/cache" \
       XDG_STATE_HOME="$probe_root/state" \
       XDG_RUNTIME_DIR="$probe_root/runtime" \
       "$kbredir_out/bin/$program" --help </dev/null >"$probe_root/$program.out" 2>&1; then
        echo "$program unexpectedly accepted an option" >&2
        exit 1
    fi
    grep -F "$program takes no options" "$probe_root/$program.out" >/dev/null
done

# This test has no network endpoint.  Xvfb accepts only a private Unix-domain
# display socket; no TCP listener, loopback connection, or host X server is
# involved.
"$python_out/bin/python3" - "$kbredir_out" "$xorg_server_out/bin/Xvfb" \
    "$xev_out/bin/xev" "$xdotool_out/bin/xdotool" <<'PY'
import hashlib
import os
import pathlib
import select
import signal
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb, xev, xdotool = sys.argv[2:]


def digest_tree(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        digest.update(str(path.relative_to(root)).encode())
        if path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


def wait_for_window(environment, name, receiver):
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if receiver.poll() is not None:
            error = receiver.stderr.read()
            raise AssertionError("xev exited before creating its window: " + error)
        result = subprocess.run([xdotool, "search", "--name", name],
                                env=environment, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True)
        windows = result.stdout.split()
        if windows:
            return windows[-1]
        time.sleep(.1)
    raise AssertionError("xev receiver window was not created")


with tempfile.TemporaryDirectory(prefix="kbredir-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home, config, data, cache, state, runtime, work = [root / name for name in
                                                       ("home", "config", "data", "cache", "state", "runtime", "work")]
    for directory in (home, config, data, cache, state, runtime, work):
        directory.mkdir()
    runtime.chmod(0o700)
    environment = {"HOME": str(home), "XDG_CONFIG_HOME": str(config),
                   "XDG_DATA_HOME": str(data), "XDG_CACHE_HOME": str(cache),
                   "XDG_STATE_HOME": str(state), "XDG_RUNTIME_DIR": str(runtime),
                   "LC_ALL": "C.UTF-8", "PATH": ""}
    before = digest_tree(out)
    state_before = digest_tree(root)
    display_read, display_write = os.pipe()
    display = subprocess.Popen([xvfb, "-displayfd", str(display_write),
                               "+extension", "XTEST", "-screen", "0",
                               "800x600x24", "-nolisten", "tcp"], env=environment,
                               pass_fds=(display_write,), stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               start_new_session=True)
    os.close(display_write)
    receiver = None
    try:
        readable, _, _ = select.select([display_read], [], [], 10)
        if not readable or display.poll() is not None:
            if display.poll() is None:
                stop(display)
            raise AssertionError(display.stderr.read().decode("utf-8", "replace"))
        display_number = os.read(display_read, 32).decode("ascii").strip()
        assert display_number.isdigit(), display_number
        display_name = ":" + display_number
        environment["DISPLAY"] = display_name
        receiver = subprocess.Popen([xev, "-name", "kbredir-smoke-receiver", "-event", "keyboard"],
                                    cwd=work, env=environment, stdin=subprocess.DEVNULL,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                    start_new_session=True, text=True)
        window = wait_for_window(environment, "kbredir-smoke-receiver", receiver)
        subprocess.run([xdotool, "windowfocus", "--sync", window], env=environment,
                       check=True, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, timeout=5)
        sent = subprocess.run([str(out / "bin" / "write_xtest"), "--display", display_name,
                               "--window", window], input="a down\na up\n", text=True,
                              cwd=work, env=environment, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, timeout=8)
        assert sent.returncode == 0, sent.stderr
        time.sleep(.3)
        stop(receiver)
        receiver_output = receiver.stdout.read()
        assert receiver.returncode in (0, -signal.SIGTERM, 143), receiver.stderr.read()
        press = receiver_output.find("KeyPress event")
        release = receiver_output.find("KeyRelease event")
        assert press >= 0 and release > press, receiver_output
        assert "(keysym 0x61, a)" in receiver_output, receiver_output
        assert digest_tree(root) == state_before, "kbredir modified isolated user state"
        assert digest_tree(out) == before, "kbredir wrote to its immutable output"
    finally:
        os.close(display_read)
        stop(receiver)
        stop(display)

print("kbredir smoke passed: isolated XTEST press/release and immutable output")
PY
