#!/bin/sh
# Play the installed LineRogue through its package-owned --smoke contract in
# a fresh HOME/XDG tree inside networkless user namespaces, and check its
# license notices, its gameplay capture and that its store output is intact.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [linerogue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes linerogue)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts \
                       --no-substitutes "$package"); do
        if test -e "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

coreutils_out=$(find_output bin/mktemp coreutils)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
util_linux_out=$(find_output bin/unshare util-linux)
find=$findutils_out/bin/find
grep=$grep_out/bin/grep

# fail MESSAGE...: report the failed assertion and stop.
fail ()
{
    echo "linerogue smoke: $*" >&2
    exit 1
}

# sha256 FILE: FILE's SHA-256 digest.
sha256 ()
{
    "$coreutils_out/bin/sha256sum" "$1" | "$coreutils_out/bin/cut" -d ' ' -f 1
}

# expect_sha256 FILE DIGEST: FILE is the unmodified upstream notice.
expect_sha256 ()
{
    actual=$(sha256 "$1")
    test "$actual" = "$2" ||
        fail "$1 has SHA-256 $actual, expected $2"
}

# expect_text FILE TEXT: FILE contains TEXT.
expect_text ()
{
    "$grep" -F -e "$2" "$1" >/dev/null ||
        fail "$1 does not contain '$2'"
}

# Nothing is setuid or setgid.
special=$("$find" "$game_out" \( -perm -2000 -o -perm -4000 \) -print -quit)
test -z "$special" || fail "setuid or setgid file in the output: $special"

# The unmodified notices of the fixed source release and the Kaya runtime
# that is linked into the executable.
doc=$game_out/share/doc/linerogue
expect_sha256 "$doc/COPYING" \
    cb7592a01efc180bfe786da0c9c4f25296edaecff90b3288b716e56304ac4ea0
expect_sha256 "$doc/GPL-2" \
    32b1062f7da84967e7019d01ab805935caa7ab7321a7ced0e30ebe75e5df1670
expect_sha256 "$doc/COPYING.pcre" \
    accdcf2455c07b99abea59016b3663eaef926a92092d103bfaa25fed27cf6b24
expect_text "$doc/COPYING" 'LineRogue copyright 2005 Chris Morris'
expect_text "$doc/COPYING" 'either version 2 of the License, or'
expect_text "$doc/kaya/COPYING" 'Lesser GNU Public License version 2.1'
test -s "$doc/kaya/LGPL2.1" || fail "$doc/kaya/LGPL2.1 is missing or empty"
test -s "$doc/README" || fail "$doc/README is missing or empty"

unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-current-user --net --pid --kill-child --fork \
    true >/dev/null 2>&1; then
    echo 'linerogue smoke requires unprivileged user, network and PID' \
        'namespaces' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$game_out") ||
    fail "could not hash $game_out"
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/linerogue.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp"
# The evidence harness may supply its own raw-capture path outside scratch.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}

# The contract invocation: linerogue --smoke, from PATH, in a fresh HOME/XDG
# tree and empty network and PID namespaces.  The outer timeout bounds the
# whole run; --kill-child and the PID namespace make sure no game process
# outlives unshare.
status=0
proof=$("$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" TERM=xterm-256color LC_ALL=C.UTF-8 \
    PATH="$game_out/bin" GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$coreutils_out/bin/timeout" --kill-after=10 180 \
    "$unshare" --user --map-current-user --net --pid --kill-child --fork \
    linerogue --smoke) || status=$?
test "$status" -eq 0 ||
    fail "linerogue --smoke exited with status $status; stdout: $proof"
test "$proof" = 'linerogue isolated smoke passed' ||
    fail "unexpected linerogue --smoke output: $proof"

# The capture is a prefix of the smoke run's PTY stream that ends on a live
# turn.  (If the wall-clock-seeded first game crashes before that turn, the
# prefix also spans its Game Over screen and the replay.)  curses sets a
# colour attribute before each map glyph, so the stream is searched for the
# texts the game prints in one call -- the HUD, the player and its trail,
# and the wall glyphs -- not for literal map rows.
test -s "$raw" || fail "raw capture $raw is missing or empty"
"$coreutils_out/bin/tr" -d '\000\r' <"$raw" >"$scratch/terminal.txt"
for text in 'Power: ' 'Score: ' '@' '*' '|' '-'; do
    expect_text "$scratch/terminal.txt" "$text"
done
if "$grep" -F -e 'Oops!' "$scratch/terminal.txt" >/dev/null; then
    fail 'the raw capture contains an uncaught Kaya exception'
fi

# The smoke run kept its high scores in its own disposable tree, which it
# removed; the caller's HOME and XDG directories stay empty.
leftover=$("$find" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)
test -z "$leftover" || fail "the smoke run left $leftover in the caller's tree"

# The game never wrote into the store.
written=$("$find" "$game_out" \( -name highscore -o -type f -perm /222 \) \
    -print -quit)
test -z "$written" || fail "writable or high-score file in the output: $written"
after=$($guix_bin hash -S nar "$game_out") ||
    fail "could not hash $game_out"
test "$before" = "$after" ||
    fail "the store output changed from $before to $after"

printf '%s\n' "$proof"
