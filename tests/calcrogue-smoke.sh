#!/bin/sh
# Drive the ordinary native CalcRogue launcher; never build the target.
set -eu
umask 077
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE (prebuilt store output; fresh absolute directory)" >&2
    exit 64
fi
case "$1" in /gnu/store/*) ;; *) echo 'OUTPUT must be an absolute store path' >&2; exit 64 ;; esac
case "$2" in /*) ;; *) echo 'EVIDENCE must be absolute' >&2; exit 64 ;; esac
if test "${GUIX+x}" = x; then
    case "$GUIX" in /*) ;; *) echo 'GUIX must be an absolute executable path' >&2; exit 64 ;; esac
    guix_bin=$GUIX
else
    guix_bin=$(command -v guix) || { echo 'GUIX executable not found' >&2; exit 64; }
    guix_bin=$(realpath -e -- "$guix_bin") || { echo 'GUIX cannot be resolved' >&2; exit 64; }
fi
test -f "$guix_bin" && test -x "$guix_bin" || { echo 'GUIX must be an executable file' >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd) || { echo 'cannot resolve native consumer directory' >&2; exit 1; }
out=$(realpath -e -- "$1") || { echo 'OUTPUT cannot be resolved' >&2; exit 64; }
case "$out" in /gnu/store/*/*) echo 'OUTPUT must be a store item, not a subdirectory' >&2; exit 64 ;; /gnu/store/*) ;; *) echo 'resolved OUTPUT is outside the store' >&2; exit 64 ;; esac
test "$1" = "$out" || { echo 'OUTPUT must be the canonical store item path' >&2; exit 64; }
test -d "$out" || { echo "OUTPUT is not a directory: $out" >&2; exit 64; }
test -f "$out/bin/calcrogue" && test -x "$out/bin/calcrogue" || { echo "missing launcher: $out/bin/calcrogue" >&2; exit 1; }
if test -e "$2" || test -L "$2"; then
    echo 'EVIDENCE must not already exist' >&2
    exit 64
fi
evidence=$(realpath -m -- "$2") || { echo 'EVIDENCE cannot be resolved' >&2; exit 64; }
case "$evidence/" in /gnu/store/*|"$out/"*) echo 'EVIDENCE must be outside the store' >&2; exit 64 ;; esac
if test -e "$evidence" || test -L "$evidence"; then
    echo 'EVIDENCE must not already exist' >&2
    exit 64
fi
test -r "$channel_dir/tests/calcrogue-native.py" || { echo 'native consumer is not readable' >&2; exit 1; }
mkdir -p -- "$(dirname -- "$evidence")" || { echo 'cannot create evidence parent' >&2; exit 1; }
mkdir -- "$evidence" || { echo 'cannot create fresh evidence directory' >&2; exit 1; }
mkdir -- "$evidence/home" "$evidence/state" "$evidence/config" "$evidence/data"
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
# Realize only consumer tools, serially, before offline ordinary gameplay.
core=$(find_output bin/env coreutils)
util=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
pyte=$(find_output lib python-pyte)
wcwidth=$(find_output lib python-wcwidth)
pythonpath=
for package in "$pyte" "$wcwidth"; do
    for directory in "$package"/lib/python*/site-packages; do
        test -d "$directory" || { echo "missing Python consumer site-packages: $directory" >&2; exit 1; }
        pythonpath=${pythonpath:+$pythonpath:}$directory
    done
done
host_uid=$("$core/bin/id" -u)
host_gid=$("$core/bin/id" -g)
host_user_ns=$("$core/bin/readlink" /proc/self/ns/user)
host_mount_ns=$("$core/bin/readlink" /proc/self/ns/mnt)
host_net_ns=$("$core/bin/readlink" /proc/self/ns/net)
host_pid_ns=$("$core/bin/readlink" /proc/self/ns/pid)
host_namespaces="$evidence/host-namespaces.json"
printf '{"user":"%s","mnt":"%s","net":"%s","pid":"%s"}\n' \
    "$host_user_ns" "$host_mount_ns" "$host_net_ns" "$host_pid_ns" > "$host_namespaces"
before=$("$guix_bin" hash -r -x "$out") || { echo 'cannot hash prebuilt OUTPUT before gameplay' >&2; exit 1; }
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$core/bin/env" -i PATH='' LC_ALL=C.UTF-8 TERM=xterm-256color \
    HOME="$evidence/home" XDG_STATE_HOME="$evidence/state" \
    XDG_CONFIG_HOME="$evidence/config" XDG_DATA_HOME="$evidence/data" \
    PYTHONPATH="$pythonpath" PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    MOUNT="$util/bin/mount" HOST_UID="$host_uid" HOST_GID="$host_gid" \
    HOST_USER_NS="$host_user_ns" HOST_MOUNT_NS="$host_mount_ns" \
    HOST_NET_NS="$host_net_ns" HOST_PID_NS="$host_pid_ns" \
    "$core/bin/timeout" --kill-after=5 300 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -B -s "$channel_dir/tests/calcrogue-native.py" \
    "$out" "$evidence" "$host_uid" "$host_gid" "$host_namespaces" || status=$?
after=$("$guix_bin" hash -r -x "$out") || { echo 'cannot hash prebuilt OUTPUT after gameplay' >&2; exit 1; }
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'CalcRogue output NAR changed during ordinary gameplay' >&2
    exit 1
fi
test "$status" -eq 0 || exit "$status"
printf '%s\n' "CALCROGUE_NATIVE_OK evidence=$evidence"
