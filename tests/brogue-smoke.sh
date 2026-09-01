#!/bin/sh
# Exercise Brogue CE's installed terminal frontend in isolated XDG state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [brogue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    brogue_out=$1
else
    brogue_out=$($guix_bin build -L . --no-grafts --no-substitutes brogue)
fi

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

test -f "$brogue_out/bin/brogue" && test -x "$brogue_out/bin/brogue"
test -f "$brogue_out/libexec/brogue" && test -x "$brogue_out/libexec/brogue"
test -f "$brogue_out/libexec/brogue-smoke-runner.py" && \
    test -x "$brogue_out/libexec/brogue-smoke-runner.py"
test -s "$brogue_out/share/brogue/assets/tiles.png"
test -s "$brogue_out/share/brogue/assets/tiles.bin"
test -s "$brogue_out/share/brogue/keymap.txt"
test ! -e "$brogue_out/share/brogue/assets/icon.png"

doc=$brogue_out/share/doc/brogue
test -s "$doc/README.md"
test -s "$doc/CHANGELOG.md"
test -s "$doc/LICENSE.txt"
test -s "$doc/assets/LICENSE.txt"
grep -F 'GNU AFFERO GENERAL PUBLIC LICENSE' "$doc/LICENSE.txt" >/dev/null
grep -F 'Creative Commons Attribution-ShareAlike 4.0' \
    "$doc/assets/LICENSE.txt" >/dev/null
grep -F 'Oryx Design Lab' "$doc/assets/LICENSE.txt" >/dev/null

# The issue-specific runtime contract is part of this proof.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 663' "$contract" >/dev/null
grep -F '"packageName": "brogue"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-663.png"' \
    "$contract" >/dev/null
grep -F '"executable": "brogue"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "brogue isolated smoke passed"' \
    "$contract" >/dev/null

util_linux_out=$(find_program_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'brogue smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# The NAR hash includes all installed bytes, modes, and symlinks.  It must be
# unchanged after the launcher and the real terminal game have run.
before=$($guix_bin hash -S nar "$brogue_out")
test -z "$(find "$brogue_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d "${TMPDIR:-/tmp}/brogue-smoke.XXXXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
      "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export TERM=xterm-256color
export LC_ALL=C

# Run the package's own mode through the bounded argv-only executor.  The
# network namespace has no interfaces, and the wrapper creates a second fresh
# HOME/XDG tree below its private TMPDIR before it launches the PTY frontend.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    node "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$brogue_out/bin/brogue" --guix-smoke)
test "$proof" = 'brogue isolated smoke passed'
test -s "$raw"
grep -aF 'Dungeons of Doom' "$raw" >/dev/null
grep -aE 'HP|Health' "$raw" >/dev/null
grep -aE 'Depth|Level' "$raw" >/dev/null
grep -aF '@' "$raw" >/dev/null

after=$($guix_bin hash -S nar "$brogue_out")
test "$before" = "$after"
test -z "$(find "$brogue_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$brogue_out"
printf '%s\n' "$proof"
