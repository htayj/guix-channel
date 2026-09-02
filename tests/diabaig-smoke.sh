#!/bin/sh
# Exercise Diabaig's installed terminal game in isolated XDG state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [diabaig-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    diabaig_out=$1
else
    diabaig_out=$($guix_bin build -L . --no-grafts --no-substitutes diabaig)
fi

test -f "$diabaig_out/bin/diabaig"
test -x "$diabaig_out/bin/diabaig"
test -f "$diabaig_out/libexec/diabaig"
test -x "$diabaig_out/libexec/diabaig"
test -f "$diabaig_out/libexec/diabaig-smoke-runner.py"
test -x "$diabaig_out/libexec/diabaig-smoke-runner.py"
test ! -e "$diabaig_out/bin/diabaig-real"

doc=$diabaig_out/share/doc/diabaig
for file in LICENSE README.md guide.txt credits.txt; do
    test -s "$doc/$file"
done
grep -F 'MIT License' "$doc/LICENSE" >/dev/null
grep -F 'Copyright (c) 2025 conornally' "$doc/LICENSE" >/dev/null
grep -F 'source code: https://github.com/conornally/diabaig' \
    "$doc/credits.txt" >/dev/null
test -s "$diabaig_out/share/man/man6/diabaig.6"
grep -F 'Version: 1.0.1' "$diabaig_out/share/man/man6/diabaig.6" >/dev/null

# The issue-specific runtime contract is part of this package proof.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 674' "$contract" >/dev/null
grep -F '"packageName": "diabaig"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-674.png"' \
    "$contract" >/dev/null
grep -F '"executable": "diabaig"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
grep -F '"successMarker": "DIABAIG_RUNTIME_OK"' "$contract" >/dev/null

find_program_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L . --no-grafts "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

util_linux_out=$(find_program_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'diabaig smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# The NAR hash covers the installed files, modes, and symlinks.  It must be
# identical after the launcher and the real game have run.
before=$($guix_bin hash -S nar "$diabaig_out")
test -z "$(find "$diabaig_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d "${TMPDIR:-/tmp}/diabaig-smoke.XXXXXXXX")
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export TERM=xterm-256color
export LC_ALL=C

# The package's own --smoke mode owns the PTY transcript.  The unprivileged
# network namespace provides an additional assertion that this behavior does
# not depend on network access.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/work/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    node "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$diabaig_out/bin/diabaig" --smoke)
test "$proof" = 'DIABAIG_RUNTIME_OK'
test -s "$raw"
grep -aF 'Floor:' "$raw" >/dev/null
grep -aF '@' "$raw" >/dev/null

# The runner creates all application state below its private TMPDIR tree and
# removes the save files before returning.  Nothing may escape into the outer
# HOME/XDG trees, and the immutable package output must remain unchanged.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" -type f \
    -print -quit)"
test -z "$(find "$scratch/tmp" -type f -print -quit)"
after=$($guix_bin hash -S nar "$diabaig_out")
test "$before" = "$after"
test -z "$(find "$diabaig_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$diabaig_out"
printf '%s\n' "$proof"
