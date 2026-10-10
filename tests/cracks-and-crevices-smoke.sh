#!/bin/sh
# Strict consumer of a supplied prebuilt ordinary Cracks and Crevices output.
# Generic tools alone may be realized before the offline native proof.
set -eu
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT /absolute/fresh/EVIDENCE_DIR (GUIX required)" >&2
    exit 64
fi
: "${GUIX:?set GUIX to the Guix executable}"
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
find_output ()
{
    for output in $("$GUIX" build -L "$channel_dir/guix" --no-grafts "$2"); do
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
output=$(realpath -e -- "$1")
if test "$output" != "$1" || test "$(dirname -- "$output")" != /gnu/store; then
    echo 'OUTPUT must be an already-realized canonical direct /gnu/store item' >&2
    exit 64
fi
test -x "$output/bin/cracks-and-crevices"
case "$2" in
    /*) ;;
    *) echo 'EVIDENCE must be absolute' >&2; exit 64 ;;
esac
evidence=$(realpath -m -- "$2")
if test "$evidence" != "$2"; then
    echo 'EVIDENCE must be a canonical fresh absolute path' >&2
    exit 64
fi
case "$evidence/" in
    /gnu/store/*) echo 'EVIDENCE must be outside /gnu/store' >&2; exit 64 ;;
esac
if test -e "$evidence" || test -L "$evidence"; then
    echo 'EVIDENCE must not already exist' >&2
    exit 64
fi
mkdir -m 700 -- "$evidence"
coreutils=$(find_output bin/env coreutils)
util_linux=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
xorg=$(find_output bin/Xvfb xorg-server)
xdotool=$(find_output bin/xdotool xdotool)
x11=$(find_output lib/libX11.so.6 libx11)
before=$("$GUIX" hash -S nar "$output")
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$coreutils/bin/env" -i LC_ALL=C PATH="" \
    XVFB="$xorg/bin/Xvfb" MOUNT="$util_linux/bin/mount" \
    XDOTOOL="$xdotool/bin/xdotool" LIBX11="$x11/lib/libX11.so.6" \
    HOST_UID="$("$coreutils/bin/id" -u)" HOST_GID="$("$coreutils/bin/id" -g)" \
    HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
    HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
    HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
    PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    "$coreutils/bin/timeout" --kill-after=15 240 \
    "$util_linux/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -s "$channel_dir/tests/cracks-and-crevices-native.py" \
    "$output" "$evidence" || status=$?
after=$("$GUIX" hash -S nar "$output")
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
printf 'native_exit_status=%s\noutput_nar_unchanged=%s\n' "$status" \
    "$(test "$before" = "$after" && printf true || printf false)" \
    > "$evidence/consumer-result.txt"
if test "$before" != "$after"; then
    echo 'package output NAR changed during native proof' >&2
    exit 1
fi
if test "$status" -ne 0; then
    exit "$status"
fi
find "$evidence" -type f -exec chmod a-w -- {} +
printf '%s\n' "CRACKS_AND_CREVICES_NATIVE_GAMEPLAY_OK evidence=$evidence"
