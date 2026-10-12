#!/bin/sh
# External consumer of a prebuilt ordinary Enemy Trench output.  No game build.
# Usage: OUTPUT and EVIDENCE are canonical absolute paths; EVIDENCE must not exist.
set -eu
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE_DIR (fresh absolute path outside /gnu/store)" >&2
    exit 64
fi
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
find_output ()
{
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts "$2"); do
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
game_out=$(realpath -e -- "$1")
if test "$game_out" != "$1"; then
    echo 'OUTPUT must be a canonical direct store item' >&2
    exit 64
fi
case "$game_out" in
    /gnu/store/*) test "$(dirname -- "$game_out")" = /gnu/store ;;
    *) echo 'OUTPUT must be a canonical direct store item' >&2; exit 64 ;;
esac
test -x "$game_out/bin/enemy-trench"
test -f "$game_out/share/enemy-trench/launch.py"
evidence=$(realpath -m -- "$2")
if test "$evidence" != "$2" || test -e "$evidence" || test -L "$evidence"; then
    echo 'EVIDENCE must be a fresh nonexistent canonical absolute path' >&2
    exit 64
fi
case "$evidence/" in
    /gnu/store/*) echo 'EVIDENCE must be outside /gnu/store' >&2; exit 64 ;;
esac
# Resolve all generic tools while Guix/network are still available.
coreutils=$(find_output bin/env coreutils)
util_linux=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
xorg=$(find_output bin/Xvfb xorg-server)
xdotool=$(find_output bin/xdotool xdotool)
xlib=$(find_output lib/libX11.so.6 libx11)
pulse=$(find_output bin/pulseaudio pulseaudio)
test -x "$pulse/bin/pactl"
mkdir -p -- "$evidence"
before=$("$guix_bin" hash -S nar "$game_out")
printf '%s\n' "$before" >"$evidence/output-before.nar-hash"
status=0
"$coreutils/bin/env" -i LC_ALL=C PATH="" \
    XVFB="$xorg/bin/Xvfb" MOUNT="$util_linux/bin/mount" \
    XDOTOOL="$xdotool/bin/xdotool" LIBX11="$xlib/lib/libX11.so.6" \
    PULSEAUDIO="$pulse/bin/pulseaudio" PACTL="$pulse/bin/pactl" \
    HOST_UID="$("$coreutils/bin/id" -u)" HOST_GID="$("$coreutils/bin/id" -g)" \
    HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
    "$coreutils/bin/timeout" --kill-after=15 300 \
    "$util_linux/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -I -S -B "$channel_dir/tests/enemy-trench-native.py" \
    "$game_out" "$evidence" >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$game_out")
printf '%s\n' "$after" >"$evidence/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'package output changed during native consumer' >&2
    exit 1
fi
if test "$status" -ne 0; then
    echo "native consumer failed (status $status); evidence=$evidence" >&2
    exit "$status"
fi
find "$evidence" -type f -exec chmod a-w -- {} +
printf '%s\n' "ENEMY_TRENCH_NATIVE_GAMEPLAY_OK evidence=$evidence"
