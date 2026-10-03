#!/bin/sh
# Drive the installed Babel SDL game, not a terminal replacement or save fixture.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -ne 0; then
    echo "usage: GUIX=guix BABEL7DRL_NATIVE_STORE=/gnu/store/... $0" >&2
    exit 64
fi
game_out=${BABEL7DRL_NATIVE_STORE:-$($guix_bin build -L "$channel_dir/guix" --no-grafts babel7drl)}
case "$game_out" in
    /gnu/store/*) ;;
    *) echo 'BABEL7DRL_NATIVE_STORE must be a realized /gnu/store output' >&2; exit 64 ;;
esac
find_output ()
{
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts "$2"); do
        if test -e "$output/$1"; then
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
xlib_out=$(find_output lib/libX11.so.6 libx11)
fail ()
{
    echo "babel7drl native: $*" >&2
    exit 1
}
test -x "$game_out/bin/babel7drl" || fail 'missing installed game launcher'
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'babel7drl native requires user, mount, network and PID namespaces' >&2
    exit 77
fi
before=$($guix_bin hash -S nar "$game_out") || fail 'cannot hash output'
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/babel7drl-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"
"$coreutils_out/bin/chmod" 700 "$scratch/runtime"
# Retain screenshots/logs separately from disposable HOME/XDG, even by default.
artifacts=${BABEL7DRL_NATIVE_OUTPUT:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/babel7drl-evidence.XXXXXX")}
case "$artifacts" in
    /*) ;;
    *) fail 'BABEL7DRL_NATIVE_OUTPUT must be an absolute directory' ;;
esac
"$coreutils_out/bin/mkdir" -p "$artifacts"
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
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
    "$coreutils_out/bin/timeout" --kill-after=10 180 \
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" "$channel_dir/tests/babel7drl-smoke.py" \
    "$game_out" "$scratch" "$xorg_out/bin/Xvfb" \
    "$xdotool_out/bin/xdotool" "$xwd_out/bin/xwd" \
    "$imagemagick_out/bin/convert" "$xlib_out/lib/libX11.so.6" "$artifacts" \
    >"$artifacts/proof.log" 2>&1 || status=$?
after=$($guix_bin hash -S nar "$game_out") || fail 'cannot hash output after gameplay'
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
"$coreutils_out/bin/cat" "$artifacts/proof.log"
test "$before" = "$after" || fail 'gameplay changed immutable output'
if test "$status" -ne 0; then
    for log in "$artifacts"/game-*.log "$artifacts/xvfb.log"; do
        test ! -f "$log" || "$coreutils_out/bin/cat" "$log" >&2
    done
    fail "native gameplay exited with status $status; evidence: $artifacts"
fi
printf '%s\n' "TOWER OF BABEL native gameplay passed; evidence: $artifacts"
