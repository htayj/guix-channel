#!/bin/sh
# External consumer of official (gnu packages games) boohu, not a channel recipe.
set -eu
umask 077
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE_DIR (new or empty, outside /gnu/store)" >&2
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
out=$(realpath -e -- "$1")
evidence=$(realpath -m -- "$2")
test -x "$out/bin/boohu"
case "$evidence/" in
    /gnu/store/*|"$out/"*) echo 'evidence must be outside the store/output' >&2; exit 64 ;;
esac
if test -e "$evidence"; then
    test -d "$evidence"
    test -z "$(find "$evidence" -mindepth 1 -maxdepth 1 -print -quit)"
fi
mkdir -p -- "$evidence"
# Serial prerequisite realization; no Guix or network access inside gameplay.
core=$(find_output bin/env coreutils)
util=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
pyte=$(find_output lib python-pyte)
wcwidth=$(find_output lib python-wcwidth)
xorg=$(find_output bin/Xvfb xorg-server)
xterm=$(find_output bin/xterm xterm)
imagemagick=$(find_output bin/import imagemagick)
go=$(find_output bin/go go)
pythonpath=
for package in "$pyte" "$wcwidth"; do
    for directory in "$package"/lib/python*/site-packages; do
        test -d "$directory"
        pythonpath=${pythonpath:+$pythonpath:}$directory
    done
done
before=$("$guix_bin" hash -S nar "$out")
status=0
"$core/bin/env" -i LC_ALL=C.UTF-8 PATH="" PYTHONPATH="$pythonpath" \
    PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    XVFB="$xorg/bin/Xvfb" XTERM="$xterm/bin/xterm" \
    IMPORT="$imagemagick/bin/import" GO="$go/bin/go" MOUNT="$util/bin/mount" \
    HOST_UID="$("$core/bin/id" -u)" HOST_GID="$("$core/bin/id" -g)" \
    HOST_USER_NS="$("$core/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$core/bin/readlink" /proc/self/ns/mnt)" \
    HOST_PID_NS="$("$core/bin/readlink" /proc/self/ns/pid)" \
    HOST_NET_NS="$("$core/bin/readlink" /proc/self/ns/net)" \
    "$core/bin/timeout" --kill-after=10 480 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -B -s "$channel_dir/tests/boohu-native.py" \
    "$out" "$evidence" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'package output changed during native gameplay' >&2
    exit 1
fi
test "$status" -eq 0 || exit "$status"
find "$evidence" -type f -exec chmod a-w -- {} +
printf '%s\n' "BOOHU_NATIVE_SAVE_RESTORE_OK evidence=$evidence"
