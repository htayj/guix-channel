#!/bin/sh
# Emulate the source-built x86-64 Hello World fixture through Qiling's qltool.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [qiling-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    qiling_out=$1
else
    qiling_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts qiling)
fi

test -x "$qiling_out/bin/qltool"
test -x "$qiling_out/bin/qiling-smoke"
fixture="$qiling_out/share/qiling/rootfs/bin/x8664_hello"
test -x "$fixture"
test -s "$qiling_out/share/qiling/src/x8664_hello.S"
# The guest must be the freestanding static x86-64 ELF assembled at build
# time: ELF64, little endian, SYSV ABI, ET_EXEC, EM_X86_64.
test "$(od -An -tx1 -N20 "$fixture" | tr -d ' \n')" = \
    7f454c4602010100000000000000000002003e00
license=$(find "$qiling_out/share/doc" -type f -name COPYING)
test -n "$license"
# SHA-256 of the complete GPLv2 COPYING in upstream commit
# da210f0757f3581de7e607b2b826b26eaa5aef66.
license_hash=$(sha256sum "$license")
test "${license_hash%% *}" = \
    6f04ae8364d0079a192b14635f4b1da294ce18724c034c39a6a41d1b09df6100

before=$($guix_bin hash -S nar "$qiling_out")
test -z "$(find "$qiling_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d "${TMPDIR:-/tmp}/qiling-smoke.XXXXXXXX")
trap 'rm -rf "$scratch"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"

status=0
(cd "$scratch/work" && env -i \
    PATH=/nonexistent \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" \
    LC_ALL=C \
    "$qiling_out/bin/qiling-smoke" \
    >"$scratch/stdout" 2>"$scratch/stderr") || status=$?
if test "$status" -ne 0; then
    cat "$scratch/stderr" >&2
    echo "qiling-smoke exited with status $status" >&2
    exit 1
fi
test "$(cat "$scratch/stdout")" = 'Hello, World!'
test "$(wc -c <"$scratch/stdout")" -eq 14
# Qiling logs the emulated system calls on stderr: one write of the 14-byte
# message to fd 1, then exit(0).
grep -q 'write(fd = 0x1, buf = 0x[0-9a-f]*, count = 0xe) = 0xe' \
    "$scratch/stderr"
grep -q 'exit(code = 0x0)' "$scratch/stderr"

# Nothing may escape into the isolated HOME/XDG tree or the working
# directory, and the package output must stay unchanged.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work" -mindepth 1 -print -quit)"
after=$($guix_bin hash -S nar "$qiling_out")
test "$before" = "$after"
test -z "$(find "$qiling_out" -xdev -type f -perm /222 -print -quit)"
cat "$scratch/stdout"
