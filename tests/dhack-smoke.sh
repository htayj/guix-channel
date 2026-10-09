#!/bin/sh
# Consume a prebuilt DreamHack output through its ordinary native launcher.
set -eu
umask 077
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE (prebuilt store output; fresh absolute directory)" >&2
    exit 64
fi
case "$1" in /gnu/store/*) ;; *) echo 'OUTPUT must be an absolute store path' >&2; exit 64 ;; esac
case "$2" in /*) ;; *) echo 'EVIDENCE must be absolute' >&2; exit 64 ;; esac
guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -e -- "$1")
case "$out" in /gnu/store/*/*) echo 'OUTPUT must be a store item, not a subdirectory' >&2; exit 64 ;; /gnu/store/*) ;; *) exit 64 ;; esac
test -d "$out"
test -x "$out/bin/dhack"
test -x "$out/libexec/dhack-real"
evidence=$(realpath -m -- "$2")
case "$evidence/" in /gnu/store/*) echo 'EVIDENCE must be outside the store' >&2; exit 64 ;; esac
if test -e "$evidence" || test -L "$evidence"; then
    echo 'EVIDENCE must not already exist' >&2
    exit 64
fi
mkdir -p -- "$(dirname -- "$evidence")"
mkdir -- "$evidence"
find_output ()
{
    for output in $("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$2"); do
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "missing $1 in Guix prerequisite $2" >&2
    return 1
}
# Realize only harness tools, serially, before entering the offline namespace.
core=$(find_output bin/env coreutils)
util=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
pyte=$(find_output lib python-pyte)
wcwidth=$(find_output lib python-wcwidth)
pythonpath=
for package in "$pyte" "$wcwidth"; do
    for directory in "$package"/lib/python*/site-packages; do
        test -d "$directory"
        pythonpath=${pythonpath:+$pythonpath:}$directory
    done
done
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$core/bin/env" -i PATH='' LC_ALL=C PYTHONPATH="$pythonpath" \
    PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 MOUNT="$util/bin/mount" \
    HOST_UID="$("$core/bin/id" -u)" HOST_GID="$("$core/bin/id" -g)" \
    HOST_USER_NS="$("$core/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$core/bin/readlink" /proc/self/ns/mnt)" \
    HOST_PID_NS="$("$core/bin/readlink" /proc/self/ns/pid)" \
    HOST_NET_NS="$("$core/bin/readlink" /proc/self/ns/net)" \
    "$core/bin/timeout" --kill-after=5 90 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -B -s "$channel_dir/tests/dhack-native.py" \
    "$out" "$evidence" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'DreamHack output NAR changed during ordinary gameplay' >&2
    exit 1
fi
test "$status" -eq 0 || exit "$status"
printf '%s\n' "DHACK_NATIVE_OK evidence=$evidence"
