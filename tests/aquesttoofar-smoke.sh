#!/bin/sh
# Exercise the original, installed SDL game inside networkless namespaces.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [aquesttoofar-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes aquesttoofar)
fi
case "$game_out" in
    /*) ;;
    *) echo 'aquesttoofar output must be an absolute path' >&2; exit 64 ;;
esac

find_output ()
{
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts \
                       --no-substitutes "$2"); do
        if test -x "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
coreutils_out=$(find_output bin/mktemp coreutils)
findutils_out=$(find_output bin/find findutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
xwd_out=$(find_output bin/xwd xwd)
imagemagick_out=$(find_output bin/convert imagemagick)
find=$findutils_out/bin/find

fail ()
{
    echo "aquesttoofar smoke: $*" >&2
    exit 1
}
expect_sha256 ()
{
    actual=$("$coreutils_out/bin/sha256sum" "$1" | "$coreutils_out/bin/cut" -d ' ' -f 1)
    test "$actual" = "$2" || fail "modified or missing upstream file $1"
}

test -x "$game_out/bin/aquesttoofar" || fail 'missing launcher'
test -x "$game_out/libexec/AQuestTooFar" || fail 'missing source-built executable'
expect_sha256 "$game_out/share/doc/aquesttoofar/readme.txt" \
    cc1a432150692bf0bf51e4b364c385571155b97576e578f3ea68a7db5902dff4
expect_sha256 "$game_out/share/doc/aquesttoofar/gpl-3.0.txt" \
    0b383d5a63da644f628d99c33976ea6487ed89aaa59f0b3257992deac1171e6b
expect_sha256 "$game_out/share/aquesttoofar/Data/icon32.bmp" \
    126553aae6f3550001fc59ebb359fbbb1d6683ce270b58c508f56a1e6ad46666
expect_sha256 "$game_out/share/aquesttoofar/Data/tiles_ascii.bmp" \
    0c48615c36da4e3c08fd1577e765451e222649737bf128d4d3282878031e7aca
forbidden=$("$find" "$game_out" \( -iname '*.exe' -o -iname '*.dll' \
    -o -perm -2000 -o -perm -4000 -o -type f -perm /222 \) -print -quit)
test -z "$forbidden" || fail "forbidden or writable output file $forbidden"

unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork \
    "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'aquesttoofar smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
before=$($guix_bin hash -S nar "$game_out") || fail 'cannot hash output'
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/aquesttoofar.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"
"$coreutils_out/bin/chmod" 700 "$scratch/runtime"
# This optional directory receives real window dumps and unmodified PNGs, not
# a rendered terminal approximation.  Use an absolute path outside scratch to
# retain the screenshots.  No Goocastle executor/renderer is involved.
artifacts=${AQUESTTOOFAR_SMOKE_ARTIFACTS:-$scratch/artifacts}
case "$artifacts" in
    /*) ;;
    *) fail 'AQUESTTOOFAR_SMOKE_ARTIFACTS must be absolute' ;;
esac
status=0
"$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" LC_ALL=C PATH="$coreutils_out/bin" \
    "$coreutils_out/bin/timeout" --kill-after=10 90 \
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork \
    "$python_out/bin/python3" "$channel_dir/tests/aquesttoofar-x11-runner.py" \
    "$game_out/bin/aquesttoofar" "$scratch" "$xorg_out/bin/Xvfb" \
    "$xdotool_out/bin/xdotool" "$xwd_out/bin/xwd" \
    "$imagemagick_out/bin/convert" "$artifacts" || status=$?
if test "$status" -ne 0; then
    for log in "$scratch/game.log" "$scratch/xvfb.log"; do
        test ! -f "$log" || "$coreutils_out/bin/cat" "$log" >&2
    done
    fail "graphical proof exited with status $status"
fi
leftover=$("$find" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/work" \
    -mindepth 1 -print -quit)
test -z "$leftover" || fail "game left caller state $leftover"
after=$($guix_bin hash -S nar "$game_out") || fail 'cannot hash output after play'
test "$before" = "$after" || fail "output NAR changed from $before to $after"
printf '%s\n' 'aquesttoofar isolated graphical smoke passed'
