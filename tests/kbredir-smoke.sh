#!/bin/sh
# Isolated installed-runtime proof for kbredir: real VT220 escape sequences
# through pipes and a PTY, plus XTEST and XSendEvent key delivery into a
# private Xvfb, with no real console, host X server, network, or store writes.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [kbredir-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    kbredir_out=$1
else
    kbredir_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts kbredir)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build --no-grafts "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

python_out=$(find_output bin/python3 python)
xorg_server_out=$(find_output bin/Xvfb xorg-server)
xev_out=$(find_output bin/xev xev)
xdotool_out=$(find_output bin/xdotool xdotool)
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
timeout_bin=$coreutils_out/bin/timeout
unshare_bin=$util_linux_out/bin/unshare

for program in read_vt220 read_linux_console read_xev write_vt220 \
               write_xsendevent write_xtest; do
    test -x "$kbredir_out/bin/$program"
done
test -f "$kbredir_out/share/doc/kbredir/COPYING"
grep -F 'GNU GENERAL PUBLIC LICENSE' "$kbredir_out/share/doc/kbredir/COPYING" >/dev/null
grep -F 'Version 2, June 1991' "$kbredir_out/share/doc/kbredir/COPYING" >/dev/null

marker='kbredir smoke: VT220 round trips and isolated XTEST/XSendEvent delivery OK'

if ! "$timeout_bin" --kill-after=5 10 \
        "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
        true >/dev/null 2>&1; then
    echo 'kbredir smoke requires unprivileged user, network, and PID namespaces' >&2
    exit 77
fi

# A NAR hash covers all installed files, modes, and symlinks.  It must remain
# identical after the real programs run; this catches a regression that
# directs state back to the immutable package output.
before=$($guix_bin hash -S nar "$kbredir_out")
test -z "$(find "$kbredir_out" -xdev -type f -perm /222 -print -quit)"

# Only this task-created directory is removed; a caller's TMPDIR and any
# requested raw-capture path are left in place.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/kbredir-smoke.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
      "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
      "$scratch/xwd"

# The readers and write_vt220 accept no options at all; the X writers reject
# a --display without a value before they open any display.  Every probe is
# fed closed input and fails before touching a console tty or X server.
probe_root=$scratch/probes
mkdir "$probe_root"
for program in read_vt220 read_linux_console read_xev write_vt220; do
    if HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
       XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
       XDG_STATE_HOME="$scratch/state" \
       XDG_RUNTIME_DIR="$scratch/runtime" \
       "$kbredir_out/bin/$program" --help \
           </dev/null >"$probe_root/$program.out" 2>&1; then
        echo "$program unexpectedly accepted an option" >&2
        exit 1
    fi
    grep -F "$program takes no options" "$probe_root/$program.out" >/dev/null
done
for program in write_xsendevent write_xtest; do
    if HOME="$scratch/home" DISPLAY= \
       "$kbredir_out/bin/$program" --display \
           </dev/null >"$probe_root/$program.out" 2>&1; then
        echo "$program unexpectedly accepted a dangling option" >&2
        exit 1
    fi
    grep -F -- '--display takes an argument' \
        "$probe_root/$program.out" >/dev/null
done
rm -rf "$probe_root"

# The Python proof runs directly inside a user/network/PID namespace bounded
# by timeout: no executor wrapper, no TCP listener (Xvfb also refuses tcp), no
# host X server, and every descendant reaped if the bound expires.  It leaves
# two exact capture artifacts: the PTY byte stream of a real read_vt220
# terminal session, and Xvfb's framebuffer dump of the displayed xev window.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/state/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$timeout_bin" --kill-after=5 180 \
    "$unshare_bin" --user --map-root-user --mount --net --pid --kill-child --fork \
    "$python_out/bin/python3" - "$kbredir_out" "$xorg_server_out/bin/Xvfb" \
    "$xev_out/bin/xev" "$xdotool_out/bin/xdotool" \
    "$util_linux_out/bin/mount" <<'PY'
import fcntl
import os
import pathlib
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time


out = pathlib.Path(sys.argv[1])
xvfb, xev, xdotool, mount = sys.argv[2:6]
binaries = out / "bin"


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


def wait_for_window(environment, name, receiver, work):
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if receiver.poll() is not None:
            raise AssertionError(
                "xev exited before creating its window: "
                + receiver.stderr.read())
        result = subprocess.run([xdotool, "search", "--name", name],
                                cwd=work, env=environment,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True)
        windows = result.stdout.split()
        if windows:
            return windows[-1]
        time.sleep(.1)
    raise AssertionError("xev receiver window was not created")



# A private tmpfs over /tmp/.X11-unix keeps Xvfb's display socket, and -nolock
# keeps its lock files, entirely inside this namespace: nothing in the host's
# /tmp is read, replaced, or created.
subprocess.run([mount, "--make-rprivate", "/"], check=True)
pathlib.Path("/tmp/.X11-unix").mkdir(parents=True, exist_ok=True)
subprocess.run([mount, "-t", "tmpfs", "tmpfs", "/tmp/.X11-unix"], check=True)
with tempfile.TemporaryDirectory(prefix="kbredir-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home, config, data, cache, state, runtime, tmp, work, xwd = [
        root / name for name in ("home", "config", "data", "cache", "state",
                                 "runtime", "tmp", "work", "xwd")]
    for directory in (home, config, data, cache, state, runtime, tmp, work,
                      xwd):
        directory.mkdir()
    environment = {"HOME": str(home), "XDG_CONFIG_HOME": str(config),
                   "XDG_DATA_HOME": str(data), "XDG_CACHE_HOME": str(cache),
                   "XDG_STATE_HOME": str(state),
                   "XDG_RUNTIME_DIR": str(runtime), "TMPDIR": str(tmp),
                   "LC_ALL": "C", "PATH": ""}


    def run(program, feed=b""):
        return subprocess.run([str(binaries / program)], input=feed,
                              cwd=work, env=environment,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=10)

    # Real VT220 input: printable, shifted, F6 and Home escape sequences, and
    # the quit key, decoded to the line protocol.
    expected = ["a down", "a up", "Shift down", "b down", "b up", "Shift up",
                "F6 down", "F6 up", "Home down", "Home up"]
    result = run("read_vt220", b"aB\x1b[17~\x1b[1~q")
    assert result.returncode == 0, result.stderr
    assert result.stdout.decode("ascii").splitlines() == expected, result.stdout

    # The line protocol encodes back to the same VT220 escape sequences.
    feed = b"x down\nx up\nF6 down\nF6 up\nHome down\nHome up\n"
    result = run("write_vt220", feed)
    assert result.returncode == 0, result.stderr
    assert result.stdout == b"x\x1b[17~\x1b[1~", result.stdout
    # A Control-composed key encodes to its control character.
    result = run("write_vt220", b"Control-c down\nControl-c up\n")
    assert result.returncode == 0, result.stderr
    assert result.stdout == b"\x03", result.stdout

    # A real terminal session: read_vt220 puts its tty into raw mode, prints
    # its banner, decodes the same input, restores the tty, and quits on 'q'.
    # The full PTY byte stream is the terminal capture artifact.
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ,
                struct.pack("HHHH", 24, 80, 0, 0))
    attributes_before = termios.tcgetattr(slave)
    session = subprocess.Popen([str(binaries / "read_vt220")],
                               stdin=slave, stdout=slave, stderr=slave,
                               cwd=work, env=environment,
                               start_new_session=True)
    capture = bytearray()
    fed = False
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        readable, _, _ = select.select([master], [], [], .2)
        if readable:
            try:
                chunk = os.read(master, 4096)
            except OSError:
                break
            if not chunk:
                break
            capture += chunk
            if not fed and b"to quit" in capture:
                os.write(master, b"aB\x1b[17~\x1b[1~q")
                fed = True
        elif fed and session.poll() is not None:
            break
    session.wait(timeout=5)
    attributes_after = termios.tcgetattr(slave)
    os.close(master)
    os.close(slave)
    assert session.returncode == 0, session.returncode
    assert attributes_after == attributes_before, "tty attributes not restored"
    terminal_text = capture.decode("utf-8", "replace")
    assert "to quit" in terminal_text, capture
    for line in expected:
        assert line + "\r\n" in terminal_text, capture

    # Xvfb owns a private display socket in the namespace's /tmp; it refuses
    # every TCP transport, so no network endpoint exists.
    display_read, display_write = os.pipe()
    display = subprocess.Popen(
        [xvfb, "-displayfd", str(display_write), "-nolock",
         "+extension", "XTEST", "-screen", "0", "800x600x24",
         "-fbdir", str(xwd), "-nolisten", "tcp"],
        pass_fds=(display_write,), env=environment,
        cwd=work, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, start_new_session=True)
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
        receiver = subprocess.Popen(
            [xev, "-name", "kbredir-smoke-receiver", "-event", "keyboard"],
            cwd=work, env=environment, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            start_new_session=True, text=True)
        window = wait_for_window(environment, "kbredir-smoke-receiver",
                                 receiver, work)
        subprocess.run([xdotool, "windowfocus", "--sync", window],
                       cwd=work, env=environment, check=True,
                       stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, timeout=5)
        # XTEST: real server-side key events for 'a' and F6.
        sent = subprocess.run([str(binaries / "write_xtest"),
                               "--window", window,
                               "--display", display_name],
                              input="a down\na up\nF6 down\nF6 up\n", text=True,
                              cwd=work, env=environment,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=15)
        assert sent.returncode == 0, sent.stderr
        # XSendEvent: synthetic events for 'b' to the same window.
        sent = subprocess.run([str(binaries / "write_xsendevent"),
                               "--window", window,
                               "--display", display_name],
                              input="b down\nb up\n", text=True,
                              cwd=work, env=environment,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=15)
        assert sent.returncode == 0, sent.stderr
        time.sleep(.4)
        # The framebuffer dump is the exact X server capture of the displayed
        # xev window receiving those events.
        dumps = sorted(xwd.iterdir())
        assert dumps, "Xvfb wrote no framebuffer dump"
        xwd_bytes = dumps[0].read_bytes()
        assert len(xwd_bytes) > 800 * 600 * 4, len(xwd_bytes)
        stop(receiver)
        receiver_output = receiver.stdout.read()
        assert receiver.returncode in (0, -signal.SIGTERM, 143), receiver.stderr.read()
        press = receiver_output.find("KeyPress event")
        release = receiver_output.find("KeyRelease event")
        assert press >= 0 and release > press, receiver_output
        assert "(keysym 0x61, a)" in receiver_output, receiver_output
        assert "(keysym 0xffc3, F6)" in receiver_output, receiver_output
        assert "(keysym 0x62, b)" in receiver_output, receiver_output
        assert receiver_output.count("synthetic YES") == 2, receiver_output
        # read_xev parses the captured xev report back into the line protocol.
        result = run("read_xev", receiver_output.encode("ascii"))
        assert result.returncode == 0, result.stderr
        assert result.stdout.decode("ascii").splitlines() == [
            "a down", "a up", "F6 down", "F6 up", "b down", "b up"], result.stdout
    finally:
        os.close(display_read)
        stop(receiver)
        stop(display)

    # Everything the test provided stays empty except the capture artifacts.
    for directory in (home, config, data, cache, runtime, tmp, work):
        assert not any(directory.iterdir()), directory

    raw = pathlib.Path(os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE",
                                      str(state / "terminal.raw")))
    raw.parent.mkdir(parents=True, exist_ok=True)
    raw.write_bytes(bytes(capture))
    raw_xwd = raw.with_name(raw.name + ".xwd")
    raw_xwd.write_bytes(xwd_bytes)

print("kbredir smoke: VT220 round trips and isolated XTEST/XSendEvent delivery OK")
PY
)
test "$proof" = "$marker"

# The terminal capture holds the real read_vt220 session: its raw-mode banner
# and the protocol lines for every decoded key, with no echoed input.
test -s "$raw"
grep -aF 'to quit' "$raw" >/dev/null
grep -aF "$(printf 'F6 down\r')" "$raw" >/dev/null
if grep -aF "$(printf '\033\[17~')" "$raw" >/dev/null; then
    echo 'kbredir smoke: terminal capture contains echoed input' >&2
    exit 1
fi
# The X capture is Xvfb's own framebuffer dump of the displayed xev window.
test -s "$raw.xwd"

test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    -mindepth 1 -print -quit)"
test -z "$(find "$scratch/state" -mindepth 1 ! -path "$raw" \
    ! -path "$raw.xwd" -print -quit)"

after=$($guix_bin hash -S nar "$kbredir_out")
test "$before" = "$after"
test ! -w "$kbredir_out"

printf '%s\n' "$marker"
