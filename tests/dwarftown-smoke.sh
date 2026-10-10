#!/bin/sh
# Consume a prebuilt native Dwarftown output; realize only external
# consumer tools, then run the native driver inside a private namespace.
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
    guix_bin=$(realpath -e -- "$guix_bin") || exit 64
fi
test -f "$guix_bin" && test -x "$guix_bin" || { echo 'GUIX must be an executable file' >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -e -- "$1") || exit 64
case "$out" in /gnu/store/*/*) echo 'OUTPUT must be a direct store item' >&2; exit 64 ;; /gnu/store/*) ;; *) exit 64 ;; esac
test "$1" = "$out" && test -d "$out" || { echo 'OUTPUT must be canonical' >&2; exit 64; }
test -f "$out/bin/dwarftown" && test -x "$out/bin/dwarftown" \
    || { echo 'missing bin/dwarftown' >&2; exit 1; }
if test -e "$2" || test -L "$2"; then
    echo 'EVIDENCE must not already exist' >&2; exit 64
fi
evidence=$(realpath -m -- "$2") || exit 64
test "$2" = "$evidence" || { echo 'EVIDENCE must be canonical' >&2; exit 64; }
case "$evidence/" in /gnu/store/*) echo 'EVIDENCE must be outside the store' >&2; exit 64 ;; esac
if test -e "$evidence" || test -L "$evidence"; then
    echo 'EVIDENCE must not already exist' >&2; exit 64
fi
test -r "$channel_dir/tests/dwarftown-native.py" || exit 1
mkdir -p -- "$(dirname -- "$evidence")"
mkdir -- "$evidence"
find_output ()
{
    outputs=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$2") || return 1
    for output in $outputs; do
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "missing $1 in Guix prerequisite $2" >&2
    return 1
}
# Tools are realized serially before entering the offline namespace.  Guix
# progress goes to a per-tool log retained as evidence; a realization failure
# appends a summary to the same log before exiting.
realize_tool ()
{
    tool_name=$1
    tool_file=$2
    tool_pkg=$3
    tool_log="$evidence/tool-$tool_name-realization.log"
    if ! realize_out=$(find_output "$tool_file" "$tool_pkg" 2> "$tool_log"); then
        printf '{"failed":true,"tool":"%s","package":"%s","file":"%s"}\n' \
            "$tool_name" "$tool_pkg" "$tool_file" >> "$tool_log"
        echo "tool realization failed: $tool_name ($tool_pkg); see $tool_log" >&2
        exit 1
    fi
    printf '{"failed":false,"tool":"%s"}\n' "$tool_name" >> "$tool_log"
    printf '%s\n' "$realize_out"
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
if test "$host_uid" -eq 0 || test "$host_gid" -eq 0; then
    echo 'refusing to run as root: caller UID/GID must be nonzero' >&2
    exit 1
fi
host_user_ns=$("$core/bin/readlink" /proc/self/ns/user)
host_mount_ns=$("$core/bin/readlink" /proc/self/ns/mnt)
host_net_ns=$("$core/bin/readlink" /proc/self/ns/net)
host_pid_ns=$("$core/bin/readlink" /proc/self/ns/pid)
printf '{"uid":%s,"gid":%s,"user":"%s","mnt":"%s","net":"%s","pid":"%s"}\n' \
    "$host_uid" "$host_gid" \
    "$host_user_ns" "$host_mount_ns" "$host_net_ns" "$host_pid_ns" \
    > "$evidence/host-namespaces.json"
"$guix_bin" gc -R "$out" > "$evidence/runtime-closure.txt"
printf '{"guix":"%s","coreutils":"%s","util-linux":"%s","python":"%s","xorg-server":"%s","xdotool":"%s","xwd":"%s","imagemagick":"%s"}\n' \
    "$guix_bin" "$core" "$util" "$python" "$xvfb" "$xdotool" "$xwd" "$convert" \
    > "$evidence/consumer-tools.json"
before=$("$guix_bin" hash -r -x "$out") || exit 1
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$core/bin/env" -i PATH='' LC_ALL=C \
    PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$host_uid" HOST_GID="$host_gid" \
    HOST_USER_NS="$host_user_ns" HOST_MOUNT_NS="$host_mount_ns" \
    HOST_NET_NS="$host_net_ns" HOST_PID_NS="$host_pid_ns" \
    "$core/bin/timeout" --kill-after=5 300 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -B -s "$channel_dir/tests/dwarftown-native.py" \
    "$out" "$evidence" \
    "$xvfb/bin/Xvfb" "$xdotool/bin/xdotool" "$xwd/bin/xwd" "$convert/bin/convert" \
    > "$evidence/driver.stdout" 2> "$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -r -x "$out") || exit 1
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
printf '{"driver_status":%s,"nar_unchanged":%s}\n' "$status" \
    "$(test "$before" = "$after" && printf true || printf false)" > "$evidence/shell-result.json"
if test "$before" != "$after"; then
    echo 'Dwarftown output NAR changed during native gameplay' >&2; exit 1
fi
test "$status" -eq 0 || exit "$status"
printf '%s\n' "DWARFTOWN_NATIVE_OK evidence=$evidence"
