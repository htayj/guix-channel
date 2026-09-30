#!/bin/sh
# Prove the curses-only Save Scummer package: its closure, notices, and a real
# two-session gameplay, backup-slot, and save/load PTY proof in a fresh
# HOME/XDG tree without a network.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [savescummer-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes savescummer)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts \
                       --no-substitutes "$package"); do
        if test -x "$output/$program"; then
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

# sha256 FILE: FILE's SHA-256 digest.
sha256 ()
{
    "$coreutils_out/bin/sha256sum" "$1" | "$coreutils_out/bin/cut" -d ' ' -f 1
}

# Installed layout: the rebuilt curses program, its data, the launcher, and
# the smoke program; none of the archive's prebuilt programs, DLLs, or fonts.
test -x "$game_out/bin/savescummer"
test -x "$game_out/libexec/savescummer/savescummer"
test -x "$game_out/libexec/savescummer/savescummer-smoke"
forbidden=$("$find" "$game_out" \( -iname '*.bmp' -o -iname '*.dll' \
    -o -iname '*.exe' -o -iname '*.lib' -o -iname '*.app' \
    -o -iname '*sdl*' -o -iname '*pdcurses*' \) -print)
if test -n "$forbidden"; then
    printf 'savescummer installs excluded upstream files:\n%s\n' \
        "$forbidden" >&2
    exit 1
fi

# The unmodified upstream data and notices from the fixed 002 archive.
data=$game_out/share/savescummer
test "$(sha256 "$data/text.txt")" = \
    d28cee033e853eb51cd9e258d0251dde935f3a3fd92fe86a1e44f1be12094680
test "$(sha256 "$data/rooms/piecelist.map")" = \
    e5476ce7b345db1a5e0309ca304e99412ba69a2040205e088610cfc0431a2af0
doc=$game_out/share/doc/savescummer
test "$(sha256 "$doc/LICENSE.TXT")" = \
    00a74b7494373b5914e5b2211b38c7a4287709800cdf7fce0be711bf55cc3eb1
test "$(sha256 "$doc/README.TXT")" = \
    39b746ec03b1cb36b2172f2274062558b2d1c6b3532189784c563f8df8d104a7
for notice in \
    'Copyright (c) 2005, Jeff Lait' \
    'The .map files are considered public domain.' \
    'Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,' \
    '3. The names of its contributors may not be used to endorse or promote'
do
    "$grep" -F "$notice" "$doc/LICENSE.TXT" >/dev/null
done
"$grep" -F 'It is released into the public domain.' \
    "$data/rooms/piecelist.map" >/dev/null

# Curses only: the program links ncurses and nothing from SDL.
references=$($guix_bin gc --references "$game_out")
if printf '%s\n' "$references" | "$grep" -i -e sdl >/dev/null; then
    echo 'savescummer references SDL' >&2
    exit 1
fi
printf '%s\n' "$references" | "$grep" -e '-ncurses-' >/dev/null
if "$grep" -a -e 'SDL_' "$game_out/libexec/savescummer/savescummer" \
        >/dev/null; then
    echo 'savescummer contains SDL symbols' >&2
    exit 1
fi

if ! "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'savescummer smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$game_out")
scratch=$("$coreutils_out/bin/mktemp" -d \
    "${TMPDIR:-/tmp}/savescummer-test.XXXXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp"
# The evidence harness may supply its own raw-capture path outside scratch.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}

# The contract invocation: savescummer --smoke, from PATH, in a fresh
# HOME/XDG tree and an empty network namespace.
proof=$("$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" PATH="$game_out/bin" \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
    savescummer --smoke)
test "$proof" = SAVESCUMMER_RUNTIME_OK
test -s "$raw"
# The capture is the loaded game's character sheet, taken before quitting.
"$coreutils_out/bin/tr" -d '\000\r' <"$raw" >"$scratch/terminal.txt"
for text in 'Welcome back to Save Scummer!' 'Health:' 'Prob:' \
            'Your character sheet:' 'HP Quartiles:'; do
    "$grep" -F "$text" "$scratch/terminal.txt" >/dev/null
done
if "$grep" -F 'Saving...' "$scratch/terminal.txt" >/dev/null; then
    echo 'savescummer evidence frame includes the quit' >&2
    exit 1
fi

# The smoke program keeps its state in its own disposable tree, which it
# removes; the caller's HOME and XDG directories stay empty.
test -z "$("$find" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"
test -z "$("$find" "$game_out" \( -name savescummer.sav -o -name hiscore.txt \) \
    -print -quit)"
test -z "$("$find" "$game_out" -type f -perm /222 -print -quit)"
after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"

printf '%s\n' "$proof"
