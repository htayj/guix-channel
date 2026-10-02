#!/bin/sh
# Real, guest-free KLH10 console and conversion proof in isolated namespaces.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then echo "usage: $0 [klh10-output]" >&2; exit 64; fi
build_output ()
{
    "$guix_bin" build -L "$channel_dir/guix" --no-grafts --no-offload \
        --cores=1 --max-jobs=1 "$@"
}
if test "$#" -eq 1; then output=$1; else output=$(build_output klh10); fi
case "$output" in /gnu/store/*) ;; *) echo 'KLH10 output must be a realized store path' >&2; exit 64 ;; esac
find_output ()
{
    for candidate in $(build_output "$2"); do
        if test -x "$candidate/$1"; then printf '%s\n' "$candidate"; return 0; fi
    done
    echo "missing $1 from $2" >&2; return 1
}
coreutils_out=$(find_output bin/mktemp coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --ipc --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'KLH10 smoke requires user, mount, network, IPC and PID namespaces' >&2; exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/klh10.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
artifacts=${KLH10_SMOKE_ARTIFACTS:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/klh10-artifacts.XXXXXX")}
case "$artifacts" in /*) ;; *) echo 'KLH10_SMOKE_ARTIFACTS must be absolute' >&2; exit 64 ;; esac
"$coreutils_out/bin/mkdir" -p "$artifacts"
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
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --ipc --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" "$channel_dir/tests/klh10-smoke.py" \
    "$output" "$scratch" "$artifacts" >"$artifacts/proof.log" 2>&1 || status=$?
after=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
"$coreutils_out/bin/cat" "$artifacts/proof.log"
test "$before" = "$after" || { echo 'KLH10 output NAR changed' >&2; exit 1; }
if test "$status" -ne 0; then
    echo "KLH10 smoke failed ($status); evidence: $artifacts" >&2; exit "$status"
fi
printf '%s\n' "KLH10 offline 3-model console and disk/tape roundtrips passed; unchanged NAR: $after; evidence: $artifacts"
