#!/bin/sh
# Exercise ChessRogue's installed curses frontend with isolated state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [chessrogue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    chessrogue_out=$1
else
    chessrogue_out=$($guix_bin build -L . --no-grafts --no-substitutes chessrogue)
fi

test -x "$chessrogue_out/bin/chessrogue"
test -x "$chessrogue_out/libexec/chessrogue"
test -x "$chessrogue_out/libexec/chessrogue-smoke-runner.py"
test -s "$chessrogue_out/share/chessrogue/crkeymap.txt"
test ! -e "$chessrogue_out/share/chessrogue/crtiles.bmp"

doc=$chessrogue_out/share/doc/chessrogue
for file in COPYING.txt COPYING.pcre.txt COPYING.sdl.txt README.txt INSTALL.txt \
    CHANGELOG.txt HINTS.txt crkeymap.txt; do
    test -s "$doc/$file"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/COPYING.txt" >/dev/null
grep -F 'BSD' "$doc/COPYING.pcre.txt" >/dev/null
test -s "$doc/kaya/COPYING"
test -s "$doc/kaya/LGPL2.1"
grep -F 'GNU LESSER GENERAL PUBLIC LICENSE' "$doc/kaya/LGPL2.1" >/dev/null

contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 667' "$contract" >/dev/null
grep -F '"packageName": "chessrogue"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-667.png"' \
    "$contract" >/dev/null
grep -F '"executable": "chessrogue"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
grep -F '"successMarker": "chessrogue isolated smoke passed"' \
    "$contract" >/dev/null

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
    echo 'chessrogue smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$chessrogue_out")
test -z "$(find "$chessrogue_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d /tmp/goocastle-agent-chessrogue-XXXXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$scratch"
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
    node "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$chessrogue_out/bin/chessrogue" --smoke)
test "$proof" = 'chessrogue isolated smoke passed'
test -s "$raw"
grep -aiF 'level 1' "$raw" >/dev/null
grep -aF '@' "$raw" >/dev/null
grep -aF 'Movement' "$raw" >/dev/null

state="$scratch/data/chessrogue/.smoke/home"
test -s "$state/.crsave"
test -s "$state/crkeymap.txt"
test -z "$(find "$scratch" -type f \( -name '.crsave' -o -name '.crscore' \
    -o -name 'score.*.txt' \) ! -path "$state/*" -print -quit)"

after=$($guix_bin hash -S nar "$chessrogue_out")
test "$before" = "$after"
test -z "$(find "$chessrogue_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$chessrogue_out"
printf '%s\n' "$proof"
