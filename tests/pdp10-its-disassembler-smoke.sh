#!/bin/sh
# Offline utility proof for pdp10-its-disassembler: the installed dis10 decodes
# a hand-encoded PDP-10 program and an upstream MIDAS-assembled SBLK binary;
# itsarc lists an included archive.  Each transcript must match known content.
# Every run happens under a PTY inside private user, network and PID
# namespaces with a fresh HOME/XDG tree, an empty PATH and a time bound.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [pdp10-its-disassembler-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes pdp10-its-disassembler)
fi
# The pinned upstream checkout supplies the MIDAS-assembled sample, the ARC
# archive and the expected transcripts upstream maintains for both.
source_dir=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
    --no-substitutes --source pdp10-its-disassembler)

find_output ()
{
    program=$1
    shift
    for candidate in $($guix_bin build --no-grafts --no-substitutes "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "could not find $program in Guix package $*" >&2
    return 1
}

python_bin=$(find_output bin/python3 python)/bin/python3
timeout_bin=$(find_output bin/timeout coreutils)/bin/timeout
unshare_bin=$(find_output bin/unshare util-linux)/bin/unshare

test -x "$package_out/bin/dis10"
test -x "$package_out/bin/itsarc"
test -f "$source_dir/samples/visib3.bin"
test -f "$source_dir/test/visib3.bin.dasm"
test -f "$source_dir/samples/arc.code"
test -f "$source_dir/test/arc.code.list"

if ! "$timeout_bin" --kill-after=5 10 \
        "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
        true >/dev/null 2>&1; then
    echo 'pdp10-its-disassembler smoke requires unprivileged user, network, and PID namespaces' >&2
    exit 77
fi

# The NAR hash covers every installed file, mode and symlink; running the
# utilities must leave the immutable output unchanged.
before=$($guix_bin hash -S nar "$package_out")

scratch=$(mktemp -d "${TMPDIR:-/tmp}/pdp10-its-disassembler-smoke.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"
chmod 700 "$scratch/runtime"

cat >"$scratch/runner.py" <<'PY'
import os
import pathlib
import select
import subprocess
import sys
import time

dis10, source, work = sys.argv[1], pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3])
itsarc = str(pathlib.Path(dis10).with_name("itsarc"))


def pty_run(*args, executable=dis10):
    """Run an installed utility on a fresh PTY and return all terminal bytes."""
    master, slave = os.openpty()
    process = subprocess.Popen([executable, *args], stdin=slave, stdout=slave,
                               stderr=slave, cwd=work, close_fds=True)
    os.close(slave)
    received = bytearray()
    deadline = time.monotonic() + 20
    try:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                process.kill()
                raise SystemExit(f"{executable} {args} did not finish within 20s")
            ready, _, _ = select.select([master], [], [], remaining)
            if not ready:
                continue
            try:
                chunk = os.read(master, 65536)
            except OSError:  # EIO: the slave side has closed.
                break
            if not chunk:
                break
            received += chunk
    finally:
        os.close(master)
    status = process.wait(timeout=5)
    if status != 0:
        raise SystemExit(f"{executable} {args} exited {status}: {bytes(received)!r}")
    return bytes(received)


def terminal(text):
    """The PTY's ONLCR translation turns every newline into CR LF."""
    return text.replace(b"\n", b"\r\n")


def require(actual, expected, label):
    if actual != expected:
        raise SystemExit(f"{label}: unexpected utility terminal output\n"
                         f"expected: {expected!r}\nactual:   {actual!r}")


# A small PDP-10 program assembled by hand: sum 5+4+3+2+1 into location 13,
# call a subroutine that increments it, then halt.  Word 6 is ADJBP 3,14,
# a byte-pointer instruction the KL10 has and the KA10 lacks; word 14 is the
# byte pointer it would adjust.  Pairs of 36-bit words are packed into nine
# bytes, the "bin" word format selected with -Wbin.
program = [
    0o201040000005,  # movei 1, 5
    0o201100000000,  # movei 2, 0
    0o271101000000,  # addi 2, (1)
    0o367040000002,  # sojg 1, 2
    0o202100000013,  # movem 2, 13
    0o260740000011,  # pushj 17, 11
    0o133140000014,  # adjbp 3, 14 (KL10 only)
    0o254200000000,  # halt 0
    0o000000000000,
    0o350000000013,  # aos 13
    0o263740000000,  # popj 17,
    0o000000000000,  # the sum
    0o440600000013,  # byte pointer (also decodes as andcb 14, 13)
    0o000000000000,
]
(work / "sum.bin").write_bytes(b"".join(
    ((program[i] << 36) | program[i + 1]).to_bytes(9, "big")
    for i in range(0, len(program), 2)))

kl10_listing = rb'''Raw format

Disassembly:

000000:  201040000005  movei    1, 5            ;"0(@  %"
000001:  201100000000  movei    2, 0            ;"0)    " " $\0\0\0"
000002:  271101000000  addi     2, (1)          ;"7)!   "
000003:  367040000002  sojg     1, 2            ;">X@  ""
000004:  202100000013  movem    2, 13           ;"01   +"
000005:  260740000011  pushj    17, 11          ;"6'@  )"
000006:  133140000014  adjbp    3, 14           ;"+9@  ,"
000007:  254200000000  halt     0               ;"5B    "
000010:  000000000000                           ;"      "
000011:  350000000013  aos      13              ;"=    +"
000012:  263740000000  popj     17,             ;"6?@   "
000013:  000000000000                           ;"      "
000014:  440600000013  andcb    14, 13          ;"D&   +"
000015:  000000000000                           ;"      "
'''
kl10 = pty_run("-r", "-Wbin", "-mkl10", "sum.bin")
require(kl10, terminal(kl10_listing), "KL10 raw program")
# The KA10 has no ADJBP, so the same word is left undecoded.
ka10_listing = kl10_listing.replace(
    b"000006:  133140000014  adjbp    3, 14           ;",
    b"000006:  133140000014                           ;")
assert ka10_listing != kl10_listing
require(pty_run("-r", "-Wbin", "-mka10", "sum.bin"), terminal(ka10_listing),
        "KA10 raw program")

# VISIB3 is MIDAS output of "A=1 / HKSYM==42 / BEG: MOVEM A,HKSYM" carrying
# its own symbol table.  With every symbol enabled the listing must equal the
# transcript upstream maintains; DDT mode must hide the half-killed HKSYM
# while still naming the accumulator and the BEG label.
sample = source / "samples" / "visib3.bin"
all_listing = (source / "test" / "visib3.bin.dasm").read_bytes()
require(pty_run("-Sall", str(sample)), terminal(all_listing), "SBLK -Sall")
ddt_listing = all_listing.replace(
    b"movem    a, hksym        ;", b"movem    a, 42           ;")
assert ddt_listing != all_listing
require(pty_run("-Sddt", str(sample)), terminal(ddt_listing), "SBLK -Sddt")

# ARC.CODE is an included ITS archive with nine members, from ACKERM 1 to
# WIRES 2.  Listing mode must decode their names, word counts, timestamps and
# byte sizes exactly as recorded upstream, not merely produce some output.
# itsarc writes this listing to stderr, which shares the PTY with stdout.
# -t leaves the archive and working directory untouched; -x is not needed.
archive_listing = (source / "test" / "arc.code.list").read_bytes()
require(pty_run("-t", str(source / "samples" / "arc.code"), executable=itsarc),
        terminal(archive_listing), "ITS archive member listing")

# Retain the actual KL10 terminal byte stream for evidence capture.
(work / "terminal.raw").write_bytes(kl10)
print("dis10: raw KL10/KA10 program and SBLK symbol listings matched; "
      "itsarc: included archive member listing matched")
PY

status=0
(cd "$scratch/work" && "$timeout_bin" --kill-after=5 120 \
    "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
    env -i \
    PATH=/nonexistent \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" \
    TERM=dumb \
    LC_ALL=C \
    TZ=UTC0 \
    "$python_bin" "$scratch/runner.py" "$package_out/bin/dis10" \
    "$source_dir" "$scratch/work" >"$scratch/stdout" 2>"$scratch/stderr") ||
    status=$?
if test "$status" -ne 0; then
    cat "$scratch/stderr" >&2
    echo "isolated utility run exited with status $status" >&2
    exit 1
fi
test ! -s "$scratch/stderr"
test "$(cat "$scratch/stdout")" = \
    'dis10: raw KL10/KA10 program and SBLK symbol listings matched; itsarc: included archive member listing matched'

# Only the fixture and the retained terminal capture exist; nothing escaped
# into the fresh HOME/XDG/TMPDIR tree or the package output.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"
test "$(cd "$scratch/work" && find . -mindepth 1 | LC_ALL=C sort | tr '\n' ' ')" = \
    './sum.bin ./terminal.raw '
after=$($guix_bin hash -S nar "$package_out")
test "$before" = "$after"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"

# Evidence runs may ask for the verbatim PTY bytes of the KL10 disassembly
# checked above.  Copy them only after every check has passed.
if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    cp "$scratch/work/terminal.raw" "$GOOCASTLE_RUNTIME_RAW_CAPTURE"
fi

printf '%s\n' 'pdp10-its-disassembler offline smoke passed: dis10 KL10/KA10 decoding and SBLK symbol modes; itsarc archive listing'
