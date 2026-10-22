#!/bin/sh
# Consume an already-built output. Tools are realized serially outside its closure.
# Usage: GOD_OF_CHANGE_SMOKE_ARTIFACTS=/absolute/fresh/path sh tests/god-of-change-smoke.sh OUTPUT
set -eu
umask 077
if test "$#" -ne 1; then
    echo "usage: GOD_OF_CHANGE_SMOKE_ARTIFACTS=/absolute/fresh/path $0 OUTPUT" >&2
    exit 64
fi
case "$1" in /gnu/store/*) ;; *) echo 'OUTPUT must be a canonical store item' >&2; exit 64 ;; esac
out=$(realpath -e -- "$1")
test "$out" = "$1" && test "$(dirname -- "$out")" = /gnu/store && test -d "$out" || exit 64
test -x "$out/bin/god-of-change" || { echo 'missing bin/god-of-change' >&2; exit 1; }
evidence=${GOD_OF_CHANGE_SMOKE_ARTIFACTS:?set GOD_OF_CHANGE_SMOKE_ARTIFACTS to a fresh absolute directory}
case "$evidence" in /*) ;; *) echo 'artifact directory must be absolute' >&2; exit 64 ;; esac
case "$evidence/" in /gnu/store/*) echo 'artifacts must be outside store' >&2; exit 64 ;; esac
test "$(realpath -m -- "$evidence")" = "$evidence" || exit 64
if test -e "$evidence" || test -L "$evidence"; then
    echo 'artifact directory must not already exist' >&2; exit 64
fi
if test "${GUIX+x}" = x; then
    case "$GUIX" in /*) guix_bin=$GUIX ;; *) echo 'GUIX must be absolute' >&2; exit 64 ;; esac
else
    guix_bin=$(command -v guix)
    guix_bin=$(realpath -e -- "$guix_bin")
fi
test -f "$guix_bin" && test -x "$guix_bin" || exit 64
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p -- "$(dirname -- "$evidence")"
mkdir -- "$evidence"
find_output ()
{
    outputs=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$2") || return 1
    for output in $outputs; do
        if test -e "$output/$1"; then printf '%s\n' "$output"; return 0; fi
    done
    echo "missing $1 in Guix prerequisite $2" >&2
    return 1
}
realize_tool ()
{
    if ! realized=$(find_output "$2" "$3" 2> "$evidence/tool-$1-realization.log"); then
        echo "consumer tool realization failed: $1; evidence=$evidence" >&2; exit 1
    fi
    printf '%s\n' "$realized"
}
core=$(realize_tool coreutils bin/env coreutils)
util=$(realize_tool util-linux bin/unshare util-linux)
python=$(realize_tool python bin/python3 python)
xvfb=$(realize_tool xorg-server bin/Xvfb xorg-server)
xdotool=$(realize_tool xdotool bin/xdotool xdotool)
xwd=$(realize_tool xwd bin/xwd xwd)
convert=$(realize_tool imagemagick bin/convert imagemagick)
host_uid=$("$core/bin/id" -u)
host_gid=$("$core/bin/id" -g)
test "$host_uid" = 1000 && test "$host_gid" = 998 || { echo 'requires ordinary UID1000/GID998 caller' >&2; exit 1; }
host_user_ns=$("$core/bin/readlink" /proc/self/ns/user)
host_mount_ns=$("$core/bin/readlink" /proc/self/ns/mnt)
host_net_ns=$("$core/bin/readlink" /proc/self/ns/net)
host_pid_ns=$("$core/bin/readlink" /proc/self/ns/pid)
printf '{"uid":%s,"gid":%s,"user":"%s","mnt":"%s","net":"%s","pid":"%s"}\n' \
    "$host_uid" "$host_gid" "$host_user_ns" "$host_mount_ns" "$host_net_ns" "$host_pid_ns" \
    > "$evidence/host-namespaces.json"
"$guix_bin" gc -R "$out" > "$evidence/runtime-closure.txt"
printf '{"guix":"%s","coreutils":"%s","util-linux":"%s","python":"%s","xorg-server":"%s","xdotool":"%s","xwd":"%s","imagemagick":"%s"}\n' \
    "$guix_bin" "$core" "$util" "$python" "$xvfb" "$xdotool" "$xwd" "$convert" \
    > "$evidence/consumer-tools.json"
before=$("$guix_bin" hash -r -x "$out")
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$core/bin/env" -i PATH='' LC_ALL=C PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$host_uid" HOST_GID="$host_gid" \
    HOST_USER_NS="$host_user_ns" HOST_MOUNT_NS="$host_mount_ns" \
    HOST_NET_NS="$host_net_ns" HOST_PID_NS="$host_pid_ns" \
    "$core/bin/timeout" --kill-after=5 600 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -I -S -B "$channel_dir/tests/god-of-change-native.py" \
    "$out" "$evidence" "$xvfb/bin/Xvfb" "$xdotool/bin/xdotool" "$xwd/bin/xwd" "$convert/bin/convert" \
    > "$evidence/driver.stdout" 2> "$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -r -x "$out")
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
printf '{"driver_status":%s,"nar_before":"%s","nar_after":"%s","nar_unchanged":%s}\n' \
    "$status" "$before" "$after" "$(test "$before" = "$after" && printf true || printf false)" \
    > "$evidence/shell-result.json"
if test -d "$evidence/scratch"; then
    "$core/bin/du" -s -B1 -- "$evidence/scratch" > "$evidence/scratch-allocated-du.txt"
    "$core/bin/du" -s --apparent-size -B1 -- "$evidence/scratch" > "$evidence/scratch-apparent-du.txt"
fi
if test "$before" != "$after"; then
    echo "output NAR changed; retaining evidence=$evidence" >&2; exit 1
fi
if test "$status" -ne 0; then
    echo "native acceptance failed; retaining evidence=$evidence" >&2; exit "$status"
fi
# Retain all scratch for Main's measurement/release; never delete user evidence.
printf '%s\n' "GOD_OF_CHANGE_NATIVE_OK evidence=$evidence"
