#!/bin/sh
# Play, save and restore the installed Super-Rogue through its --guix-smoke
# contract, then list, record and bound its scores and state in a second
# fresh HOME, inside networkless user namespaces.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [srogue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        srogue)
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
python_out=$(find_output bin/python3 python-minimal)
locales_out=$($guix_bin build --no-grafts --no-substitutes \
    -e '(@ (gnu packages base) glibc-utf8-locales)')
find=$findutils_out/bin/find
grep=$grep_out/bin/grep

# sha256 FILE: FILE's SHA-256 digest.
sha256 ()
{
    "$coreutils_out/bin/sha256sum" "$1" | "$coreutils_out/bin/cut" -d ' ' -f 1
}

# No setuid or setgid programs and no host-wide score, log or save paths.
test -z "$("$find" "$game_out" \( -path '*/var/*' -o -name '*.scr' \
    -o -name '*.sav' -o -perm -2000 -o -perm -4000 \) -print -quit)"

# The complete, unmodified license from the fixed source release, with every
# attribution and the Super-Rogue naming conditions.
doc=$game_out/share/doc/srogue
test "$(sha256 "$doc/LICENSE.TXT")" = \
    5fc413e5b2463608cbf0b4adf22356eb2a5964688140d3860124a412478a89a2
for notice in \
    'Copyright (C) 1984 Robert D. Kindelberger' \
    'Portions Copyright (C) 1980, 1981 Michael Toy, Ken Arnold and Glenn Wichman' \
    'Portions Copyright (C) 2005 Nicholas J. Kisseberth' \
    'Portions Copyright (C) 1994 David Burren' \
    '4. The name "Super-Rogue" must not be used to endorse or promote products' \
    '5. Products derived from this software may not be called "Super-Rogue",'
do
    "$grep" -F "$notice" "$doc/LICENSE.TXT" >/dev/null
done

unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-current-user --net --fork true \
    >/dev/null 2>&1; then
    echo 'srogue smoke requires unprivileged user and network namespaces' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$game_out")
test -z "$("$find" "$game_out" -xdev -type f -perm /222 -print -quit)"
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/srogue.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
# The runner's longest-path checks need a short scratch directory.
if test "${#scratch}" -gt 40; then
    echo "TMPDIR is too long for the srogue path length checks" >&2
    exit 1
fi
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/fresh"
# The evidence harness may supply its own raw-capture path outside scratch.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}

# The contract invocation: srogue --guix-smoke, from PATH, in a fresh
# HOME/XDG tree and an empty network namespace.
proof=$("$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" TERM=xterm-256color LC_ALL=C.UTF-8 \
    PATH="$game_out/bin" GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$unshare" --user --map-current-user --net --fork \
    srogue --guix-smoke)
test "$proof" = SROGUE_GUIX_SMOKE_OK
test -s "$raw"
# The capture is the restored game's pack and map, taken before quitting.
"$coreutils_out/bin/tr" -d '\000\r' <"$raw" >"$scratch/terminal.txt"
for text in 'Level: 1  Gold:' 'Hp: ' 'Str: ' 'Carry:' '(being worn)' \
            '(weapon in hand)' '-- Press space to continue --'; do
    "$grep" -F -e "$text" "$scratch/terminal.txt" >/dev/null
done
if "$grep" -F -e 'Really quit' -e 'Top Ten Adventurers' \
        "$scratch/terminal.txt" >/dev/null; then
    echo 'srogue evidence frame includes the quit' >&2
    exit 1
fi
# The smoke program kept its state in its own disposable tree, which it
# removed; the caller's HOME and XDG directories stay empty.
test -z "$("$find" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"

# A second fresh HOME without XDG_DATA_HOME: score listing, recording, the
# launcher's fallback, and the path bounds of the launcher and the game.
"$unshare" --user --map-current-user --net --fork \
    "$coreutils_out/bin/env" -i \
    "$python_out/bin/python3" -I "$channel_dir/tests/srogue-pty-runner.py" \
    "$game_out/bin/srogue" "$game_out/libexec/srogue/srogue" \
    "$locales_out/lib/locale" "$scratch/fresh" \
    >"$scratch/runner.out"
"$grep" -Fx 'SROGUE_PTY_OK' "$scratch/runner.out" >/dev/null
test "$("$find" "$scratch/fresh/home" -mindepth 1 -print | \
    LC_ALL=C "$coreutils_out/bin/sort")" = \
    "$(printf '%s\n' "$scratch/fresh/home/.local" \
        "$scratch/fresh/home/.local/share" \
        "$scratch/fresh/home/.local/share/srogue" \
        "$scratch/fresh/home/.local/share/srogue/srogue.scr")"

# The game never wrote into the store.
test -z "$("$find" "$game_out" \( -name srogue.sav -o -name srogue.scr \) \
    -print -quit)"
test -z "$("$find" "$game_out" -type f -perm /222 -print -quit)"
after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"

printf '%s\n' "$proof"
