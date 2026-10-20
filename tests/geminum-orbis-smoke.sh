#!/bin/sh
# External consumer of a prebuilt game; none of these tools enters its closure.
set -eu
umask 077
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE (canonical store item; fresh absolute directory)" >&2
    exit 64
fi
case "$1" in /gnu/store/*) ;; *) echo 'OUTPUT must be an absolute store item' >&2; exit 64 ;; esac
case "$2" in /*) ;; *) echo 'EVIDENCE must be absolute' >&2; exit 64 ;; esac
if test "${GUIX+x}" = x; then
    case "$GUIX" in /*) ;; *) echo 'GUIX must be absolute' >&2; exit 64 ;; esac
    guix_bin=$GUIX
else
    guix_bin=$(command -v guix) || exit 64
    guix_bin=$(realpath -e -- "$guix_bin") || exit 64
fi
test -f "$guix_bin" && test -x "$guix_bin" || exit 64
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -e -- "$1") || exit 64
case "$out" in /gnu/store/*/*) exit 64 ;; /gnu/store/*) ;; *) exit 64 ;; esac
test "$1" = "$out" && test -d "$out" || exit 64
test -x "$out/bin/geminum-orbis" || { echo 'missing bin/geminum-orbis' >&2; exit 1; }
if test -e "$2" || test -L "$2"; then
    echo 'EVIDENCE must not already exist' >&2; exit 64
fi
evidence=$(realpath -m -- "$2") || exit 64
case "$evidence/" in /gnu/store/*) echo 'EVIDENCE must be outside store' >&2; exit 64 ;; esac
if test -e "$evidence" || test -L "$evidence"; then exit 64; fi
mkdir -p -- "$(dirname -- "$evidence")"
mkdir -- "$evidence"
find_output ()
{
    outputs=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$2") || return 1
    for output in $outputs; do
        if test -e "$output/$1"; then printf '%s\n' "$output"; return 0; fi
    done
    echo "missing $1 in Guix consumer prerequisite $2" >&2
    return 1
}
realize_tool ()
{
    if ! realized=$(find_output "$2" "$3" 2> "$evidence/tool-$1-realization.log"); then
        echo "consumer prerequisite failed: $1; evidence=$evidence" >&2
        exit 1
    fi
    printf '%s\n' "$realized"
}
# Serial realization happens only when this consumer is invoked, never at build.
core=$(realize_tool coreutils bin/env coreutils)
util=$(realize_tool util-linux bin/unshare util-linux)
python=$(realize_tool python bin/python3 python)
pyte=$(realize_tool pyte lib python-pyte)
wcwidth=$(realize_tool wcwidth lib python-wcwidth)
pillow=$(realize_tool pillow lib python-pillow)
font=$(realize_tool font share/fonts/truetype/DejaVuSansMono.ttf font-dejavu)
pythonpath=
for package in "$pyte" "$wcwidth" "$pillow"; do
    found=false
    for site in "$package"/lib/python*/site-packages; do
        if test -d "$site"; then
            pythonpath=${pythonpath:+$pythonpath:}$site
            found=true
        fi
    done
    test "$found" = true || { echo "missing Python site-packages: $package" >&2; exit 1; }
done
host_uid=$("$core/bin/id" -u)
host_gid=$("$core/bin/id" -g)
test "$host_uid" -ne 0 && test "$host_gid" -ne 0 || { echo 'refusing root UID/GID' >&2; exit 1; }
host_user_ns=$("$core/bin/readlink" /proc/self/ns/user)
host_mount_ns=$("$core/bin/readlink" /proc/self/ns/mnt)
host_net_ns=$("$core/bin/readlink" /proc/self/ns/net)
host_pid_ns=$("$core/bin/readlink" /proc/self/ns/pid)
printf '{"uid":%s,"gid":%s,"user":"%s","mnt":"%s","net":"%s","pid":"%s"}\n' \
    "$host_uid" "$host_gid" "$host_user_ns" "$host_mount_ns" "$host_net_ns" "$host_pid_ns" \
    > "$evidence/host-namespaces.json"
"$guix_bin" gc -R "$out" > "$evidence/runtime-closure.txt"
printf '{"guix":"%s","coreutils":"%s","util-linux":"%s","python":"%s","pyte":"%s","wcwidth":"%s","pillow":"%s","font":"%s"}\n' \
    "$guix_bin" "$core" "$util" "$python" "$pyte" "$wcwidth" "$pillow" "$font" \
    > "$evidence/consumer-tools.json"
before=$("$guix_bin" hash -r -x "$out")
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$core/bin/env" -i PATH='' LC_ALL=C.UTF-8 PYTHONPATH="$pythonpath" \
    PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$host_uid" HOST_GID="$host_gid" \
    HOST_USER_NS="$host_user_ns" HOST_MOUNT_NS="$host_mount_ns" \
    HOST_NET_NS="$host_net_ns" HOST_PID_NS="$host_pid_ns" \
    "$core/bin/timeout" --kill-after=5 1200 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -B -s "$channel_dir/tests/geminum-orbis-native.py" \
    "$out" "$evidence" "$font/share/fonts/truetype/DejaVuSansMono.ttf" \
    > "$evidence/driver.stdout" 2> "$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -r -x "$out")
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
printf '{"driver_status":%s,"nar_unchanged":%s}\n' "$status" \
    "$(test "$before" = "$after" && printf true || printf false)" > "$evidence/shell-result.json"
if test -d "$evidence/scratch"; then
    "$core/bin/du" -s -B1 -- "$evidence/scratch" > "$evidence/scratch-allocated-du.txt"
    "$core/bin/du" -s --apparent-size -B1 -- "$evidence/scratch" > "$evidence/scratch-apparent-du.txt"
fi
if test "$before" != "$after"; then
    echo "Geminum Orbis output NAR changed; evidence=$evidence" >&2; exit 1
fi
if test "$status" -ne 0; then
    echo "Geminum Orbis consumer failed; retaining scratch and evidence=$evidence" >&2
    exit "$status"
fi
"$core/bin/rm" -rf -- "$evidence/scratch"
test ! -e "$evidence/scratch"
printf '{"scratch_removed":true,"evidence_retained":true}\n' > "$evidence/cleanup.json"
printf '%s\n' "GEMINUM_ORBIS_NATIVE_OK evidence=$evidence"
