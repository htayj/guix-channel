#!/bin/sh
# Exercise the installed game in a fresh XDG tree and a networkless PTY.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [bell-labs-rogue7-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L . --no-grafts --no-substitutes \
        bell-labs-rogue7)
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

bash_out=$(find_output bin/bash bash)
coreutils_out=$(find_output bin/mktemp coreutils)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
util_linux_out=$(find_output bin/script util-linux)

test -x "$game_out/bin/bell-labs-rogue7"
test -x "$game_out/libexec/bell-labs-rogue7"
for document in LICENSE.TXT aguide.mm arogue77.html; do
    test -s "$game_out/share/doc/bell-labs-rogue7/$document"
done

# Check the complete license/notices that cover installed code and documents.
license=$game_out/share/doc/bell-labs-rogue7/LICENSE.TXT
test "$("$coreutils_out/bin/sha256sum" "$license" | \
    "$coreutils_out/bin/cut" -d ' ' -f 1)" = \
    de8c8864e21c63dde8be961367c9ed9a47b8078e2f7f01142ee9c543fc8ce637
"$grep_out/bin/grep" -F 'Products derived from this software may not be called' \
    "$license" >/dev/null
"$grep_out/bin/grep" -F 'Copyright (C) 2005 Nicholas J. Kisseberth' \
    "$license" >/dev/null
"$grep_out/bin/grep" -F 'Copyright (C) 1994 David Burren' \
    "$license" >/dev/null
"$grep_out/bin/grep" -F 'See the file LICENSE.TXT' \
    "$game_out/share/doc/bell-labs-rogue7/aguide.mm" >/dev/null
"$grep_out/bin/grep" -F 'See the file LICENSE.TXT' \
    "$game_out/share/doc/bell-labs-rogue7/arogue77.html" >/dev/null

# The per-issue runtime-evidence contract is part of this package proof.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
"$grep_out/bin/grep" -F '"issueNumber": 651' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"packageName": "bell-labs-rogue7"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"artifactPath": ".goocastle/evidence/issue-651.png"' \
    "$contract" >/dev/null
"$grep_out/bin/grep" -F '"successMarker": "Top 10 Adventurers:"' \
    "$contract" >/dev/null

test -x "$util_linux_out/bin/unshare"
test -x "$util_linux_out/bin/script"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    true >/dev/null 2>&1; then
    echo 'bell-labs-rogue7 smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$game_out")
scratch=$("$coreutils_out/bin/mktemp" -d \
    "${TMPDIR:-/tmp}/bell-labs-rogue7-smoke.XXXXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" -p "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/state" "$scratch/tmp" \
    "$scratch/work"

export BELL_LABS_ROGUE7_GAME=$game_out/bin/bell-labs-rogue7
export BELL_LABS_ROGUE7_SCRIPT=$util_linux_out/bin/script
export BELL_LABS_ROGUE7_HOME=$scratch/home
export BELL_LABS_ROGUE7_CONFIG=$scratch/config
export BELL_LABS_ROGUE7_DATA=$scratch/data
export BELL_LABS_ROGUE7_CACHE=$scratch/cache
export BELL_LABS_ROGUE7_STATE=$scratch/state
export BELL_LABS_ROGUE7_TMP=$scratch/tmp
export BELL_LABS_ROGUE7_WORK=$scratch/work

# A user namespace maps the test user to uid 0 only inside the namespace,
# making the historical game's author check deterministic.  Its new network
# namespace has no network interfaces; all installed behavior runs there.
"$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$bash_out/bin/bash" -eu -c '
      export HOME="$BELL_LABS_ROGUE7_HOME"
      export XDG_CONFIG_HOME="$BELL_LABS_ROGUE7_CONFIG"
      export XDG_DATA_HOME="$BELL_LABS_ROGUE7_DATA"
      export XDG_CACHE_HOME="$BELL_LABS_ROGUE7_CACHE"
      export XDG_STATE_HOME="$BELL_LABS_ROGUE7_STATE"
      export TMPDIR="$BELL_LABS_ROGUE7_TMP"
      export TERM=xterm-256color
      export LC_ALL=C.UTF-8

      "$BELL_LABS_ROGUE7_GAME" -s >"$BELL_LABS_ROGUE7_WORK/scores"

      # Select class 1, accept maximum remaining attributes with Escape,
      # confirm the character, move safely, inspect inventory, and save.
      printf "1\\033yhliSy" | "$BELL_LABS_ROGUE7_SCRIPT" -qefc \
        "stty rows 24 cols 80; exec $BELL_LABS_ROGUE7_GAME" /dev/null \
        >"$BELL_LABS_ROGUE7_WORK/first.raw"
      test -f "$BELL_LABS_ROGUE7_DATA/bell-labs-rogue7/arogue77.sav"

      # Restart from that save, make another safe movement, and save again.
      # This avoids the historical line-oriented quit confirmation while
      # proving that the restored game remains playable and writable.
      printf "hliSy" | "$BELL_LABS_ROGUE7_SCRIPT" -qefc \
        "stty rows 24 cols 80; exec $BELL_LABS_ROGUE7_GAME -r" /dev/null \
        >"$BELL_LABS_ROGUE7_WORK/restore.raw"
    '

"$grep_out/bin/grep" -Fx 'Top 10 Adventurers:' "$scratch/work/scores" >/dev/null
tr -d '\r' <"$scratch/work/first.raw" >"$scratch/work/first.txt"
tr -d '\r' <"$scratch/work/restore.raw" >"$scratch/work/restore.txt"
"$grep_out/bin/grep" -F 'What character class do you desire?' \
    "$scratch/work/first.txt" >/dev/null
"$grep_out/bin/grep" -F 'You are empty handed.' \
    "$scratch/work/first.txt" >/dev/null
"$grep_out/bin/grep" -F 'Save file (' "$scratch/work/first.txt" >/dev/null
"$grep_out/bin/grep" -F 'Lvl:' "$scratch/work/first.txt" >/dev/null
"$grep_out/bin/grep" -F 'arogue77.sav:' "$scratch/work/restore.txt" >/dev/null
"$grep_out/bin/grep" -F 'Lvl:' "$scratch/work/restore.txt" >/dev/null
if "$grep_out/bin/grep" -E 'Cannot restore file|Cannot restart the game' \
    "$scratch/work/restore.txt" >/dev/null; then
    echo 'bell-labs-rogue7 failed to restore its save' >&2
    exit 1
fi

# The score file and both saves were confined to the wrapper's XDG directory;
# no other XDG location changed.
test -s "$scratch/data/bell-labs-rogue7/arogue77.sav"
test -s "$scratch/data/bell-labs-rogue7/arogue77.scr"
test -z "$("$findutils_out/bin/find" "$scratch/home" "$scratch/config" \
    "$scratch/cache" "$scratch/state" "$scratch/tmp" -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"
printf '%s\n' 'BELL_LABS_ROGUE7_RUNTIME_OK'
