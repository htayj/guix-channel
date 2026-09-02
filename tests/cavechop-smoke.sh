#!/bin/sh
# Exercise Cave Chop's installed terminal UI in isolated XDG state and a
# networkless PTY.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [cavechop-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    cavechop_out=$1
else
    cavechop_out=$($guix_bin build -L . --no-grafts --no-substitutes cavechop)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir" --no-grafts \
                       --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

coreutils_out=$(find_output bin/mktemp coreutils-minimal)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
util_linux_out=$(find_output bin/unshare util-linux)

test -x "$cavechop_out/bin/cavechop"
test -x "$cavechop_out/libexec/cavechop"
test -s "$cavechop_out/share/doc/cavechop/notes.txt"
"$grep_out/bin/grep" -F 'Copyright 2012 Martin Read.' \
    "$cavechop_out/share/doc/cavechop/notes.txt" >/dev/null
"$grep_out/bin/grep" -F 'Redistribution and use in source and binary forms' \
    "$cavechop_out/share/doc/cavechop/notes.txt" >/dev/null
"$grep_out/bin/grep" -F 'THIS SOFTWARE IS PROVIDED BY THE AUTHOR' \
    "$cavechop_out/share/doc/cavechop/notes.txt" >/dev/null

# The reviewed issue contract is part of the executable proof.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
"$grep_out/bin/grep" -F '"issueNumber": 666' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"packageName": "cavechop"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"artifactPath": ".goocastle/evidence/issue-666.png"' \
    "$contract" >/dev/null
"$grep_out/bin/grep" -F '"executable": "cavechop"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"--smoke"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"successMarker": "CAVECHOP_RUNTIME_OK"' \
    "$contract" >/dev/null

test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"

# A NAR hash covers all installed files, modes, and symlinks.  It must remain
# unchanged after the real game runs, catching accidental store writes.
before=$($guix_bin hash -S nar "$cavechop_out")
test -z "$($findutils_out/bin/find "$cavechop_out" -xdev -type f \
    -perm /222 -print -quit)"

scratch=$($coreutils_out/bin/mktemp -d \
    "${TMPDIR:-/tmp}/cavechop-smoke.XXXXXXXX")
"$coreutils_out/bin/mkdir" -p "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/state" \
    "$scratch/runtime" "$scratch/tmp" "$scratch/work"

export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export TERM=xterm-256color
export LC_ALL=C

# The fresh user/net namespace has no network interfaces.  The bounded
# executor owns the complete process group, including both script sessions.
proof=$(cd "$scratch/work" && node "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$cavechop_out/bin/cavechop" --smoke)
test "$proof" = CAVECHOP_RUNTIME_OK

# The package wrapper makes the actual PTY transcripts available to the host
# screenshot phase only when that phase requests them.  Ordinary smoke runs
# keep the evidence below the disposable tree.
if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    test -s "$scratch/state/cavechop/smoke/first.raw"
    "$coreutils_out/bin/cp" "$scratch/state/cavechop/smoke/first.raw" \
        "$GOOCASTLE_RUNTIME_RAW_CAPTURE"
fi

# The first session's save was loaded and consumed by the second session.
test -s "$scratch/state/cavechop/smoke/first.raw"
test -s "$scratch/state/cavechop/smoke/load.raw"
test ! -e "$scratch/state/cavechop/cavechop.sav.gz"
test -z "$($findutils_out/bin/find "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work" -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$cavechop_out")
test "$before" = "$after"
test ! -w "$cavechop_out"
printf '%s\n' "$proof"
