#!/bin/sh
# Exercise RapidBrogue's installed terminal frontend in isolated XDG state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [rapidbrogue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    rapidbrogue_out=$1
else
    rapidbrogue_out=$($guix_bin build -L . --no-grafts --no-substitutes rapidbrogue)
fi

test -x "$rapidbrogue_out/bin/rapidbrogue"
test -x "$rapidbrogue_out/libexec/rapidbrogue"
test -x "$rapidbrogue_out/libexec/rapidbrogue-smoke-runner.py"
test -s "$rapidbrogue_out/share/rapidbrogue/keymap.txt"
test ! -e "$rapidbrogue_out/share/rapidbrogue/assets"

doc=$rapidbrogue_out/share/doc/rapidbrogue
for notice in BUILD.md README.md CHANGELOG.md LICENSE.txt; do
    test -s "$doc/$notice"
done
test -s "$doc/assets/LICENSE.txt"
grep -F 'GNU AFFERO GENERAL PUBLIC LICENSE' "$doc/LICENSE.txt" >/dev/null
grep -F 'Creative Commons Attribution-ShareAlike 4.0' \
    "$doc/assets/LICENSE.txt" >/dev/null

# The reviewed executable contract is part of this proof.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 714' "$contract" >/dev/null
grep -F '"packageName": "rapidbrogue"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/rapidbrogue.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-714.png"' \
    "$contract" >/dev/null
grep -F '"executable": "rapidbrogue"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "RAPIDBROGUE_GUIX_SMOKE_OK"' \
    "$contract" >/dev/null

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

util_linux_out=$(find_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'rapidbrogue smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash and write-bit check prove that the wrapper and game do not mutate
# the package output or its immutable store contents.
before=$($guix_bin hash -S nar "$rapidbrogue_out")
test -z "$(find "$rapidbrogue_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d "${TMPDIR:-/tmp}/rapidbrogue-smoke.XXXXXXXX")
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

raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    node "$bounded_validation" --timeout-ms 45000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$rapidbrogue_out/bin/rapidbrogue" --guix-smoke)
test "$proof" = 'RAPIDBROGUE_GUIX_SMOKE_OK'
test -s "$raw"
grep -aF 'Dungeons of Doom' "$raw" >/dev/null
grep -aF '@' "$raw" >/dev/null

after=$($guix_bin hash -S nar "$rapidbrogue_out")
test "$before" = "$after"
test -z "$(find "$rapidbrogue_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$rapidbrogue_out"
printf '%s\n' "$proof"
