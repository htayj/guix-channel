#!/bin/sh
# Installed ITS DUMP proof; dependency realization may fetch, runtime cannot.
# Usage: sh tests/itstar-smoke.sh [itstar-output]
# ITSTAR_SMOKE_ARTIFACTS selects a new absolute evidence directory.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [itstar-output]" >&2
    exit 64
fi
build_output ()
{
    "$guix_bin" build -L "$channel_dir/guix" --no-grafts --no-offload \
        --cores=1 --max-jobs=1 "$@"
}
if test "$#" -eq 1; then output=$1; else output=$(build_output itstar); fi
case "$output" in
    /gnu/store/*) test -d "$output" ;;
    *) echo 'itstar output must be a realized store path' >&2; exit 64 ;;
esac
find_output ()
{
    for candidate in $(build_output "$2"); do
        if test -x "$candidate/$1"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "missing $1 from $2" >&2
    return 1
}
coreutils_out=$(find_output bin/mktemp coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
gzip_out=$(find_output bin/gzip gzip)
test -x "$output/bin/itstar"
test -x "$util_linux_out/bin/mount"

umask 077
if test -n "${ITSTAR_SMOKE_ARTIFACTS:-}"; then
    artifacts=$ITSTAR_SMOKE_ARTIFACTS
    case "$artifacts" in
        /*) ;;
        *) echo 'ITSTAR_SMOKE_ARTIFACTS must be absolute' >&2; exit 64 ;;
    esac
    # Fail rather than overwrite evidence from an earlier run.
    "$coreutils_out/bin/mkdir" "$artifacts"
else
    artifacts=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/itstar-artifacts.XXXXXXXX")
fi
before=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
status=0
"$coreutils_out/bin/env" -i LC_ALL=C PATH="$coreutils_out/bin" \
    HOST_USER_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    HOST_IPC_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/ipc)" \
    HOST_PID_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/pid)" \
    "$coreutils_out/bin/timeout" --kill-after=10 180 \
    "$util_linux_out/bin/unshare" --user --map-root-user --mount \
    --propagation private --net --ipc --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" -I -B "$channel_dir/tests/itstar-smoke.py" \
    "$output" "$util_linux_out/bin/mount" "$gzip_out/bin/gzip" "$artifacts" \
    >"$artifacts/proof.log" 2>&1 || status=$?
# Record immutability even when a namespace or application assertion fails.
after=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
"$coreutils_out/bin/cat" "$artifacts/proof.log"
if test "$before" != "$after"; then
    echo "itstar output NAR changed; evidence: $artifacts" >&2
    exit 1
fi
if test "$status" -ne 0; then
    echo "itstar smoke failed ($status); evidence: $artifacts" >&2
    exit "$status"
fi
printf '%s\n' "itstar offline byte-exact DUMP create/list/extract/append passed; unchanged NAR: $after; evidence: $artifacts"
