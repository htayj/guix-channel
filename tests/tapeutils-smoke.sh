#!/bin/sh
# Offline tapeutils proof: tapewrite creates a two-file Wilson tape image,
# tapedump and tapecopy list it, tapecopy copies it, and taperead extracts the
# copy.  Every result is compared with independently built expectations.  The
# programs run in fresh HOME/XDG trees, time-bounded, with networking unshared.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [tapeutils-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    tapeutils_out=$1
else
    tapeutils_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes tapeutils)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts \
                       --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
timeout_bin=$coreutils_out/bin/timeout
unshare_bin=$util_linux_out/bin/unshare
if ! "$timeout_bin" --kill-after=5 10 \
        "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
        true >/dev/null 2>&1; then
    echo 'tapeutils smoke requires unprivileged user, network, and PID namespaces' >&2
    exit 77
fi

# The NAR hash must remain unchanged after the real tape utilities run, and
# the installed output must contain no writable regular files.
before=$($guix_bin hash -S nar "$tapeutils_out")
test -z "$(find "$tapeutils_out" -xdev -type f -perm /222 -print -quit)"

# Only this task-created directory is removed; a caller's TMPDIR and any
# requested raw-capture path are left in place.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/tapeutils-smoke.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    "$scratch/work/extract" "$scratch/out"

# Two fixture files made of 80-byte card images, so that every tape record is
# full and extraction must reproduce them byte for byte.
card () { printf '%-79s\n' "$1"; }
{
    card 'TAPEUTILS SMOKE FILE A RECORD 0'
    card 'TAPEUTILS SMOKE FILE A RECORD 1'
    card 'TAPEUTILS SMOKE FILE A RECORD 2'
} >"$scratch/work/a.dat"
{
    card 'TAPEUTILS SMOKE FILE B RECORD 0'
    card 'TAPEUTILS SMOKE FILE B RECORD 1'
} >"$scratch/work/b.dat"

# The Wilson image format, built independently: each record is framed by its
# little-endian 32-bit length (80 = octal 120), each file ends with a zero
# length tape mark, and closing the tape adds one more mark.
record () { printf '\120\000\000\000'; card "$1"; printf '\120\000\000\000'; }
mark () { printf '\000\000\000\000'; }
{
    record 'TAPEUTILS SMOKE FILE A RECORD 0'
    record 'TAPEUTILS SMOKE FILE A RECORD 1'
    record 'TAPEUTILS SMOKE FILE A RECORD 2'
    mark
    record 'TAPEUTILS SMOKE FILE B RECORD 0'
    record 'TAPEUTILS SMOKE FILE B RECORD 1'
    mark
    mark
} >"$scratch/expected.img"
test "$(wc -c <"$scratch/expected.img")" -eq 452

out=$scratch/out
bin=$tapeutils_out/bin
cat >"$scratch/run.sh" <<EOF
set -eu
cd "$scratch/work"
"$bin/tapewrite" -n 80 tape.img a.dat b.dat >"$out/tapewrite.out"
"$bin/tapedump" tape.img >"$out/tapedump.out"
"$bin/tapecopy" -v tape.img copy.img >"$out/tapecopy.out"
cd extract
"$bin/taperead" ../copy.img >"$out/taperead.out"
cd ..
# The trailing length of record 0 no longer matches its leading length.
"$coreutils_out/bin/cp" tape.img bad.img
printf '\121' | "$coreutils_out/bin/dd" of=bad.img bs=1 seek=84 conv=notrunc \
    2>/dev/null
status=0
"$bin/tapedump" bad.img >"$out/bad.out" 2>"$out/bad.err" || status=\$?
echo "\$status" >"$out/bad.status"
EOF

status=0
"$timeout_bin" --kill-after=5 60 \
    "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
    "$coreutils_out/bin/env" -i \
    PATH=/nonexistent \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" \
    LC_ALL=C \
    "$(command -v sh)" "$scratch/run.sh" >"$scratch/stdout" 2>"$scratch/stderr" ||
    status=$?
if test "$status" -ne 0; then
    cat "$scratch/stderr" >&2
    echo "isolated tapeutils run exited with status $status" >&2
    exit 1
fi
test ! -s "$scratch/stdout"
test ! -s "$scratch/stderr"

# Creation: tapewrite is silent without -v and wrote exactly the independently
# framed image.
test ! -s "$out/tapewrite.out"
cmp "$scratch/expected.img" "$scratch/work/tape.img"

# Listing: tapedump reports every record and tape mark, and its hex and ASCII
# columns reproduce the payload bytes in order.
test "$(grep -v '^  ' "$out/tapedump.out")" = 'file 0 record 0: length 80
file 0 record 1: length 80
file 0 record 2: length 80
total length of file 0 = 3 records, 240 bytes
start of file 1
file 1 record 0: length 80
file 1 record 1: length 80
total length of file 1 = 2 records, 160 bytes
start of file 2
end of tape'
test "$(grep '^  ' "$out/tapedump.out" | cut -c9-56 | tr -s ' ' '\n' | grep -v '^$')" = \
    "$(cat "$scratch/work/a.dat" "$scratch/work/b.dat" | od -An -v -tx1 |
        tr -s ' ' '\n' | grep -v '^$')"
test "$(grep '^  ' "$out/tapedump.out" | cut -c57- | tr -d '\n')" = \
    "$(cat "$scratch/work/a.dat" "$scratch/work/b.dat" | tr '\n' '.')"

# Copy: tapecopy's verbose summary groups the records per file, and the copy
# holds the same records followed by the end-of-tape mark it writes before
# closing (one mark more than tapewrite).
test "$(cat "$out/tapecopy.out")" = 'file 0 record length 80: 3 records (0..2)
end of file 0, 240 bytes
file 1 record length 80: 2 records (0..1)
end of file 1, 160 bytes
end of tape, 400 total bytes'
{ cat "$scratch/expected.img"; mark; } | cmp - "$scratch/work/copy.img"

# Extraction: taperead of the copy restores each tape file byte for byte in
# its working directory; the empty file after the last mark is upstream's
# end-of-tape artefact.
test ! -s "$out/taperead.out"
cmp "$scratch/work/a.dat" "$scratch/work/extract/file0000"
cmp "$scratch/work/b.dat" "$scratch/work/extract/file0001"
test -f "$scratch/work/extract/file0002"
test ! -s "$scratch/work/extract/file0002"

# A corrupt record frame is detected before the record is listed.
test "$(cat "$out/bad.status")" -eq 1
test ! -s "$out/bad.out"
test "$(cat "$out/bad.err")" = '?Corrupt tape image'

# Nothing escaped the declared working tree.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"
test "$(cd "$scratch/work" && find . -type f | LC_ALL=C sort | tr '\n' ' ')" = \
    './a.dat ./b.dat ./bad.img ./copy.img ./extract/file0000 ./extract/file0001 ./extract/file0002 ./tape.img '

after=$($guix_bin hash -S nar "$tapeutils_out")
test "$before" = "$after"
test -z "$(find "$tapeutils_out" -xdev -type f -perm /222 -print -quit)"

# Evidence runs may ask for the verbatim terminal output of the isolated
# `tapedump tape.img` listing above.  Copy it only after every check passed;
# normal package tests leave no trace.
if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    cp "$out/tapedump.out" "$GOOCASTLE_RUNTIME_RAW_CAPTURE"
fi

echo 'tapeutils: 2 files, 5 records written, listed, copied and extracted'
