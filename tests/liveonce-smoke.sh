#!/bin/sh
# Prove the curses-only You Only Live Once package: its closure, notices, and
# a real save/load PTY session in a fresh HOME/XDG tree without a network.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [liveonce-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes liveonce)
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

# Installed layout: the rebuilt curses program, its data, the launcher, and
# the smoke program; none of the archive's prebuilt programs, DLLs, or fonts.
test -x "$game_out/bin/liveonce"
test -x "$game_out/bin/liveonce-smoke"
test -x "$game_out/libexec/liveonce/liveonce"
for file in text.txt valley.map piecelist.map; do
    test -s "$game_out/share/liveonce/$file"
done
forbidden=$("$find" "$game_out" \( -iname '*.bmp' -o -iname '*.dll' \
    -o -iname '*.exe' -o -iname '*.lib' -o -iname 'alphabet*' \
    -o -iname '*sdl*' \) -print)
if test -n "$forbidden"; then
    printf 'liveonce installs excluded upstream files:\n%s\n' "$forbidden" >&2
    exit 1
fi

# The unmodified upstream notices from the fixed 005 archive.
doc=$game_out/share/doc/liveonce
test "$("$coreutils_out/bin/sha256sum" "$doc/LICENSE.TXT" | \
    "$coreutils_out/bin/cut" -d ' ' -f 1)" = \
    1563b2084b83b1e5ae4b5976e073d7de8c7e44a260ab35a0c21a365deb87e00e
test "$("$coreutils_out/bin/sha256sum" "$doc/README.TXT" | \
    "$coreutils_out/bin/cut" -d ' ' -f 1)" = \
    275c056d32036fb4d6c059c87d3aa232dd5da9db2956bad9b325911ceb49f25b
for notice in \
    'Copyright (c) 2005, Jeff Lait' \
    'The .map files are considered public domain.' \
    'Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,' \
    '3. The names of its contributors may not be used to endorse or promote'
do
    "$grep" -F "$notice" "$doc/LICENSE.TXT" >/dev/null
done
"$grep" -F 'It is released into the Public Domain' \
    "$game_out/share/liveonce/valley.map" >/dev/null

# Curses only: the program links ncurses and nothing from SDL.
references=$($guix_bin gc --references "$game_out")
if printf '%s\n' "$references" | "$grep" -i -e sdl >/dev/null; then
    echo 'liveonce references SDL' >&2
    exit 1
fi
printf '%s\n' "$references" | "$grep" -e '-ncurses-' >/dev/null
if "$grep" -a -e 'SDL_' "$game_out/libexec/liveonce/liveonce" >/dev/null; then
    echo 'liveonce contains SDL symbols' >&2
    exit 1
fi

if ! "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'liveonce smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$game_out")
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/liveonce-test.XXXXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp"
# The evidence harness may supply its own raw-capture path outside scratch.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}

# The contract invocation: liveonce-smoke with no arguments, from PATH, in a
# fresh HOME/XDG tree and an empty network namespace.
proof=$("$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" PATH="$game_out/bin" \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
    liveonce-smoke)
test "$proof" = Done.
test -s "$raw"
# The capture is the loaded game's gameplay frame, taken before quitting.
"$coreutils_out/bin/tr" -d '\000\r' <"$raw" >"$scratch/terminal.txt"
for text in 'You are Timmy.' 'Welcome Message:'; do
    "$grep" -F "$text" "$scratch/terminal.txt" >/dev/null
done
if "$grep" -F 'Saving...' "$scratch/terminal.txt" >/dev/null; then
    echo 'liveonce capture extends past the gameplay frame' >&2
    exit 1
fi

# The smoke program keeps its state in its own disposable tree, which it
# removes; the caller's HOME and XDG directories stay empty.
test -z "$("$find" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"
test -z "$("$find" "$game_out" -name valley.sav -print -quit)"
test -z "$("$find" "$game_out" -type f -perm /222 -print -quit)"
after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"

printf '%s\n' "$proof"
