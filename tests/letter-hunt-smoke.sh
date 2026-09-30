#!/bin/sh
# Prove the curses-only Letter Hunt package: its closure, notices, and a real
# two-session save/load PTY proof in a fresh HOME/XDG tree without a network.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [letter-hunt-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes letter-hunt)
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
test -x "$game_out/bin/letter-hunt"
test -x "$game_out/libexec/letter-hunt/letterhunt"
test -x "$game_out/libexec/letter-hunt/letter-hunt-smoke"
forbidden=$("$find" "$game_out" \( -iname '*.bmp' -o -iname '*.dll' \
    -o -iname '*.exe' -o -iname '*.lib' -o -iname 'alphabet*' \
    -o -iname '*sdl*' -o -iname '*pdcurses*' \) -print)
if test -n "$forbidden"; then
    printf 'letter-hunt installs excluded upstream files:\n%s\n' \
        "$forbidden" >&2
    exit 1
fi

# The unmodified upstream data and notices from the fixed 002 archive.
data=$game_out/share/letter-hunt
test "$(sha256 "$data/text.txt")" = \
    fd0814cfc21a0c7b99efd202112f6fdceacf08703573c2d0cfb63f9d25ecf2a7
test "$(sha256 "$data/rooms/piecelist.map")" = \
    93d1fb42ff45a5e5da3f5e47abd1b485ffd6248ebce5f6365a83aab9cdebc0eb
test "$(sha256 "$data/wordlist/wordlist.txt")" = \
    6da5a15e03fb157a34a80436cd5d0624e8c81ff20ae208df1155e6a54b585af4
doc=$game_out/share/doc/letter-hunt
test "$(sha256 "$doc/LICENSE.TXT")" = \
    937d5ffc089201e6a49554bd84629f995d8177281f688f974ac399b60c4ec6f5
test "$(sha256 "$doc/README.TXT")" = \
    4d09d196e5646da0b6cab4142295fd823bd98b0143c8a837df575ff3e0a2527c
for notice in \
    'Copyright (c) 2005, Jeff Lait' \
    'The .map files are considered public domain.' \
    'the public domain.  The wordlist is thus also public domain.' \
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
    echo 'letter-hunt references SDL' >&2
    exit 1
fi
printf '%s\n' "$references" | "$grep" -e '-ncurses-' >/dev/null
if "$grep" -a -e 'SDL_' "$game_out/libexec/letter-hunt/letterhunt" \
        >/dev/null; then
    echo 'letter-hunt contains SDL symbols' >&2
    exit 1
fi

if ! "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'letter-hunt smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$game_out")
scratch=$("$coreutils_out/bin/mktemp" -d \
    "${TMPDIR:-/tmp}/letter-hunt-test.XXXXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp"
# The evidence harness may supply its own raw-capture path outside scratch.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}

# The contract invocation: letter-hunt --guix-smoke, from PATH, in a fresh
# HOME/XDG tree and an empty network namespace.
proof=$("$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" PATH="$game_out/bin" \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
    letter-hunt --guix-smoke)
test "$proof" = LETTER_HUNT_RUNTIME_OK
test -s "$raw"
# The capture is the loaded game's character sheet, taken before quitting.
"$coreutils_out/bin/tr" -d '\000\r' <"$raw" >"$scratch/terminal.txt"
for text in 'Wordlist built!' 'Welcome to Letter Hunt!' 'Pts:' 'Shields:' \
            'Your character sheet:' 'Melee Weapon:'; do
    "$grep" -F "$text" "$scratch/terminal.txt" >/dev/null
done
if "$grep" -F 'Saving...' "$scratch/terminal.txt" >/dev/null; then
    echo 'letter-hunt evidence frame includes the quit' >&2
    exit 1
fi

# The smoke program keeps its state in its own disposable tree, which it
# removes; the caller's HOME and XDG directories stay empty.
test -z "$("$find" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"
test -z "$("$find" "$game_out" \( -name letterhunt.sav -o -name hiscore.txt \) \
    -print -quit)"
test -z "$("$find" "$game_out" -type f -perm /222 -print -quit)"
after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"

printf '%s\n' "$proof"
