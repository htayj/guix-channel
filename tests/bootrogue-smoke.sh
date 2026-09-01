#!/bin/sh
# Exercise BootRogue's installed i386 boot image through QEMU's monitor.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [bootrogue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    bootrogue_out=$1
else
    bootrogue_out=$($guix_bin build -L . --no-grafts --no-substitutes bootrogue)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build --no-grafts "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

coreutils_out=$(find_output bin/od coreutils-minimal)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
util_linux_out=$(find_output bin/unshare util-linux)

image=$bootrogue_out/share/bootrogue/rogue.img
doc=$bootrogue_out/share/doc/bootrogue
test -x "$bootrogue_out/bin/bootrogue"
test -f "$image"
test "$($coreutils_out/bin/wc -c < "$image")" -eq 512
test ! -e "$bootrogue_out/share/bootrogue/rogue.com"
test ! -e "$bootrogue_out/share/bootrogue/rogue.lst"
test -s "$doc/LICENSE"
$grep_out/bin/grep -F 'Copyright (c) 2019 Oscar Toledo G.' \
    "$doc/LICENSE" >/dev/null
$grep_out/bin/grep -F 'Redistribution and use in source and binary forms' \
    "$doc/LICENSE" >/dev/null
$grep_out/bin/grep -F 'ANY EXPRESS OR IMPLIED WARRANTIES' \
    "$doc/LICENSE" >/dev/null
"$coreutils_out/bin/sha256sum" "$doc/LICENSE" | \
    "$grep_out/bin/grep" -F \
    b752a941b6a80602d7121ebb89e6d20bec35d8b16b979e07a5b245e694632155 \
    >/dev/null

# The issue-specific executable, invocation, marker, and artifact are a
# required part of this proof, not an advisory record.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
"$grep_out/bin/grep" -F '"issueNumber": 662' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"packageName": "bootrogue"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"artifactPath": ".goocastle/evidence/issue-662.png"' \
    "$contract" >/dev/null
"$grep_out/bin/grep" -F '"executable": "bootrogue"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"--smoke"' "$contract" >/dev/null
marker=BOOTROGUE_RUNTIME_OK
"$grep_out/bin/grep" -F '"successMarker": "BOOTROGUE_RUNTIME_OK"' \
    "$contract" >/dev/null

test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'bootrogue smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash covers every installed file, mode, and symlink.  It must be
# unchanged after QEMU and the launcher have run.
before=$($guix_bin hash -S nar "$bootrogue_out")
test -z "$($findutils_out/bin/find "$bootrogue_out" -xdev -type f \
    -perm /222 -print -quit)"

scratch=$($coreutils_out/bin/mktemp -d "${TMPDIR:-/tmp}/bootrogue-smoke.XXXXXXXX")
trap '$coreutils_out/bin/rm -rf "$scratch"' EXIT HUP INT TERM
$coreutils_out/bin/mkdir -p "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/state" \
    "$scratch/runtime" "$scratch/tmp" "$scratch/work"
export HOME=$scratch/home
export XDG_CONFIG_HOME=$scratch/config
export XDG_DATA_HOME=$scratch/data
export XDG_CACHE_HOME=$scratch/cache
export XDG_STATE_HOME=$scratch/state
export XDG_RUNTIME_DIR=$scratch/runtime
export TMPDIR=$scratch/tmp
export BOOTROGUE_SMOKE_SCREENSHOT=$scratch/bootrogue.ppm
export LC_ALL=C

# The package-owned --smoke mode sends fixed safe arrow keys to the QEMU
# monitor, captures a real VGA frame with `screendump`, verifies it is a
# nonblank PPM, and emits the marker only after the guest has quit.  The
# bounded executor owns the complete namespace/process group.
proof=$(cd "$scratch/work" && node "$bounded_validation" --timeout-ms 20000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$bootrogue_out/bin/bootrogue" --smoke)
test "$proof" = "$marker"
test -s "$BOOTROGUE_SMOKE_SCREENSHOT"
test "$($coreutils_out/bin/head -c 2 "$BOOTROGUE_SMOKE_SCREENSHOT")" = P6
pixel_values=$($coreutils_out/bin/od -An -v -tu1 -j 15 \
    "$BOOTROGUE_SMOKE_SCREENSHOT" | \
    $coreutils_out/bin/tr -s ' ' '\n' | \
    $coreutils_out/bin/sort -nu | $coreutils_out/bin/wc -l)
# Numeric sorting collapses od's empty field with zero, so a uniformly black
# frame has one unique value.
test "$pixel_values" -gt 1

# This is an actual frame derived from QEMU's PPM screendump.  The screenshot
# runner sets this variable during its proof replay; ordinary package smoke
# runs keep all generated files below the disposable scratch tree.
if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    artifact=$channel_dir/.goocastle/evidence/issue-662.png
    test -d "$channel_dir/.goocastle/evidence"
    convert "$BOOTROGUE_SMOKE_SCREENSHOT" "PNG24:$artifact"
    test -s "$artifact"
fi

# The launcher runs from scratch/work and uses only the fresh HOME/XDG/TMPDIR
# tree.  In particular, it must not create files beside the package output or
# in the caller's current directory.
test -z "$($findutils_out/bin/find "$scratch/work" -mindepth 1 \
    -print -quit)"
test -z "$($findutils_out/bin/find "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/state" \
    "$scratch/runtime" -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$bootrogue_out")
test "$before" = "$after"
test -z "$($findutils_out/bin/find "$bootrogue_out" -xdev -type f \
    -perm /222 -print -quit)"
test ! -w "$bootrogue_out"
printf '%s\n' "$proof"
