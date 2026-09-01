#!/bin/sh
# Exercise Avanor's installed terminal game in a fresh, networkless XDG tree.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [avanor-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    avanor_out=$1
else
    avanor_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes avanor)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes "$package"); do
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

test -x "$avanor_out/bin/avanor"
test -x "$avanor_out/libexec/avanor"
test -s "$avanor_out/share/avanor/manual/index.html"
test -s "$avanor_out/share/avanor/manual/credits.html"
for notice in COPYING gpl.txt README.txt; do
    test -s "$avanor_out/share/doc/avanor/$notice"
done
"$grep_out/bin/grep" -F 'GNU GENERAL PUBLIC LICENSE' \
    "$avanor_out/share/doc/avanor/COPYING" >/dev/null
"$grep_out/bin/grep" -F 'version 2' \
    "$avanor_out/share/doc/avanor/gpl.txt" >/dev/null
"$grep_out/bin/grep" -F 'Vadim Gaidukevich' \
    "$avanor_out/share/avanor/manual/credits.html" >/dev/null

# The runtime evidence contract is checked as part of this package proof.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
"$grep_out/bin/grep" -F '"issueNumber": 659' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"packageName": "avanor"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"artifactPath": ".goocastle/evidence/issue-659.png"' \
    "$contract" >/dev/null
"$grep_out/bin/grep" -F '"successMarker": "AVANOR_RUNTIME_OK"' \
    "$contract" >/dev/null

test -x "$util_linux_out/bin/unshare"
test -x "$util_linux_out/bin/script"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    true >/dev/null 2>&1; then
    echo 'avanor smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$avanor_out")
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/avanor-smoke.XXXXXXXX")
"$coreutils_out/bin/mkdir" -p "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/state" "$scratch/tmp" \
    "$scratch/work" "$scratch/caller"

export AVANOR_GAME=$avanor_out/bin/avanor
export AVANOR_SCRIPT=$util_linux_out/bin/script
export AVANOR_SLEEP=$coreutils_out/bin/sleep
export AVANOR_HOME=$scratch/home
export AVANOR_CONFIG=$scratch/config
export AVANOR_DATA=$scratch/data
export AVANOR_CACHE=$scratch/cache
export AVANOR_STATE=$scratch/state
export AVANOR_TMP=$scratch/tmp
export AVANOR_WORK=$scratch/work
export AVANOR_CALLER=$scratch/caller

# The user/net namespace provides an empty network namespace.  The PTY drives
# the actual installed ncurses executable through character creation, manual
# and inventory views, a safe movement, saving, restoring, and quitting.
"$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$bash_out/bin/bash" -eu -c '
      export HOME="$AVANOR_HOME"
      export XDG_CONFIG_HOME="$AVANOR_CONFIG"
      export XDG_DATA_HOME="$AVANOR_DATA"
      export XDG_CACHE_HOME="$AVANOR_CACHE"
      export XDG_STATE_HOME="$AVANOR_STATE"
      export TMPDIR="$AVANOR_TMP"
      export TERM=xterm-256color
      export LC_ALL=C.UTF-8
      cd "$AVANOR_CALLER"

      test "$("$AVANOR_GAME" --guix-smoke)" = AVANOR_RUNTIME_OK
      # Feed only after ncurses has entered raw mode; otherwise a pipe can
      # leave characters in the initial canonical terminal queue.
      { "$AVANOR_SLEEP" 1; printf N; "$AVANOR_SLEEP" 2; printf aaa; \
        "$AVANOR_SLEEP" 1; printf "smoke\\r"; "$AVANOR_SLEEP" 1; \
        printf '?'; "$AVANOR_SLEEP" 1; printf Z; "$AVANOR_SLEEP" 1; \
        printf i; "$AVANOR_SLEEP" 1; printf Z; "$AVANOR_SLEEP" 1; \
        printf h; "$AVANOR_SLEEP" 1; printf S; "$AVANOR_SLEEP" 1; \
        printf Q; "$AVANOR_SLEEP" 1; printf y; "$AVANOR_SLEEP" 1; \
        printf Z; } | "$AVANOR_SCRIPT" -qefc \
        "stty rows 24 cols 80; exec $AVANOR_GAME" /dev/null \
        >"$AVANOR_WORK/first.raw"
      test -s "$AVANOR_STATE/.avanor/avanor.svg"
      test -s "$AVANOR_STATE/.avanor/recipies.txt"
      test -f "$AVANOR_STATE/.avanor/avanor.hsc"

      { "$AVANOR_SLEEP" 1; printf R; "$AVANOR_SLEEP" 3; printf h; \
        "$AVANOR_SLEEP" 1; printf Q; "$AVANOR_SLEEP" 1; printf y; \
        "$AVANOR_SLEEP" 1; printf Z; } | "$AVANOR_SCRIPT" -qefc \
        "stty rows 24 cols 80; exec $AVANOR_GAME" /dev/null \
        >"$AVANOR_WORK/restore.raw"
    '

"$grep_out/bin/grep" -F 'Choose a race:' "$scratch/work/first.raw" >/dev/null
"$grep_out/bin/grep" -F 'profession:' "$scratch/work/first.raw" >/dev/null
"$grep_out/bin/grep" -F 'Avanor manual' "$scratch/work/first.raw" >/dev/null
"$grep_out/bin/grep" -F 'Inventory' "$scratch/work/first.raw" >/dev/null
"$grep_out/bin/grep" -F 'Storing the game:' "$scratch/work/first.raw" >/dev/null
"$grep_out/bin/grep" -F 'Restoring game objects, please wait...' \
    "$scratch/work/restore.raw" >/dev/null
test -s "$scratch/state/.avanor/avanor.svg"
test -s "$scratch/state/.avanor/recipies.txt"
test -z "$("$findutils_out/bin/find" "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/tmp" -mindepth 1 -print -quit)"
test -z "$("$findutils_out/bin/find" "$scratch/caller" -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$avanor_out")
test "$before" = "$after"
printf '%s\n' 'AVANOR_RUNTIME_OK'
