#!/bin/sh
# Exercise the installed original SDL UI and its native save/load protocol.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [six-two-one-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts six-two-one)
fi
case "$game_out" in
    /gnu/store/*) ;;
    *) echo 'six-two-one output must be a realized /gnu/store path' >&2; exit 64 ;;
esac

find_output ()
{
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts "$2"); do
        if test -x "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
coreutils_out=$(find_output bin/mktemp coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
xwd_out=$(find_output bin/xwd xwd)
imagemagick_out=$(find_output bin/convert imagemagick)

fail ()
{
    echo "six-two-one smoke: $*" >&2
    exit 1
}
test -x "$game_out/bin/six-two-one" || fail 'missing launcher'
test -x "$game_out/libexec/six-two-one" || fail 'missing source-built executable'
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'six-two-one smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
before=$($guix_bin hash -S nar "$game_out") || fail 'cannot hash output'
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/six-two-one.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"
"$coreutils_out/bin/chmod" 700 "$scratch/runtime"
# Set this to an absolute directory to retain unmodified window captures,
# native saves and logs.  The default is retained too, separately from scratch.
artifacts=${SIX_TWO_ONE_SMOKE_ARTIFACTS:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/six-two-one-artifacts.XXXXXX")}
case "$artifacts" in
    /*) ;;
    *) fail 'SIX_TWO_ONE_SMOKE_ARTIFACTS must be absolute' ;;
esac
"$coreutils_out/bin/mkdir" -p "$artifacts"
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
# Namespace identities are compared by the child; env -i removes host display,
# bus, profile, audio, HOME and XDG settings before the game is launched.
status=0
"$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" LC_ALL=C PATH="$coreutils_out/bin" \
    HOST_USER_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/pid)" \
    "$coreutils_out/bin/timeout" --kill-after=10 150 \
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" "$channel_dir/tests/six-two-one-x11-runner.py" \
    "$game_out" "$scratch" "$xorg_out/bin/Xvfb" \
    "$xdotool_out/bin/xdotool" "$xwd_out/bin/xwd" \
    "$imagemagick_out/bin/convert" "$artifacts" \
    >"$artifacts/proof.log" 2>&1 || status=$?
# Hash even on failure: a failed graphical assertion must not hide store writes.
after=$($guix_bin hash -S nar "$game_out") || fail 'cannot hash output after play'
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
"$coreutils_out/bin/cat" "$artifacts/proof.log"
test "$before" = "$after" || fail "output NAR changed from $before to $after"
if test "$status" -ne 0; then
    for log in "$artifacts"/game-*.log "$artifacts/xvfb.log"; do
        test ! -f "$log" || "$coreutils_out/bin/cat" "$log" >&2
    done
    fail "graphical proof exited with status $status; artifacts: $artifacts"
fi
printf '%s\n' "six-two-one isolated graphical persistence smoke passed; artifacts: $artifacts"
