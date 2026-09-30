#!/bin/sh
# Play, save and restore the installed Avanor in a fresh XDG tree, inside
# networkless user and PID namespaces.
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
    avanor_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes avanor)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes "$package"); do
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
python_out=$(find_output bin/python3 python-minimal)

test -x "$avanor_out/bin/avanor"
test -s "$avanor_out/share/avanor/manual/index.html"
# The installed license notices cover the source and manual.
for notice in COPYING gpl.txt README.txt; do
    test -s "$avanor_out/share/doc/avanor/$notice"
done
"$grep_out/bin/grep" -F 'GNU GENERAL PUBLIC LICENSE' \
    "$avanor_out/share/doc/avanor/COPYING" >/dev/null
"$grep_out/bin/grep" -F 'version 2' \
    "$avanor_out/share/doc/avanor/gpl.txt" >/dev/null

timeout=$coreutils_out/bin/timeout
unshare=$util_linux_out/bin/unshare
if ! "$timeout" --kill-after=5 10 "$unshare" --user --map-root-user --net \
    --pid --kill-child --fork true >/dev/null 2>&1; then
    echo 'avanor smoke requires unprivileged user, PID and network namespaces' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$avanor_out")
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/avanor-smoke.XXXXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/tmp" "$scratch/caller" \
    "$scratch/work"

# The Goocastle runtime-evidence gate supplies a path for the raw PTY capture;
# normal package tests keep it in scratch.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/work/terminal.raw}

# The runner drives the real ncurses game on its prompts through character
# creation, the manual, the inventory, a turn, saving, quitting, and a second
# session that restores the saved character.
"$timeout" --kill-after=5 240 "$unshare" --user --map-root-user --net --pid \
    --kill-child --fork \
    "$python_out/bin/python3" -I "$channel_dir/tests/avanor-pty-runner.py" \
    "$avanor_out/bin/avanor" "$scratch" "$raw" >"$scratch/work/runner.out"
"$grep_out/bin/grep" -Fx 'AVANOR_PTY_OK' "$scratch/work/runner.out" >/dev/null
test -s "$raw"

# The game kept all of its state in the XDG state directory.
test -s "$scratch/state/.avanor/avanor.svg"
test -s "$scratch/state/.avanor/recipies.txt"
test -f "$scratch/state/.avanor/avanor.hsc"
test -z "$("$findutils_out/bin/find" "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/tmp" "$scratch/caller" \
    -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$avanor_out")
test "$before" = "$after"
printf '%s\n' 'AVANOR_RUNTIME_OK'
