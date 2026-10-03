#!/bin/sh
# Drive the original installed graphical game in networkless namespaces.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [dungeon-monkey-unlimited-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes dungeon-monkey-unlimited)
fi
case "$game_out" in
    /*) ;;
    *) echo 'game output must be absolute' >&2; exit 64 ;;
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
    echo "Dungeon Monkey native smoke: $*" >&2
    exit 1
}
test -x "$game_out/bin/dungeon-monkey-unlimited" || fail 'missing launcher'
test -x "$game_out/libexec/dungeon-monkey-unlimited-real" || fail 'missing source-built game'
test ! -e "$game_out/libexec/dungeon-monkey-unlimited-smoke" || fail 'obsolete proof executable installed'
data=$game_out/share/dungeon-monkey-unlimited
doc=$game_out/share/doc/dungeon-monkey-unlimited
for file in gamedata/messages.txt gamedata/advcom_core_introduction.txt \
    image/title_screen.png image/VeraBd.ttf; do
    test -s "$data/$file" || fail "missing asset $file"
done
for file in license.txt readme.txt credits.txt THIRD-PARTY-NOTICES.txt \
    Bitstream-Vera-COPYRIGHT.TXT upstream-doc/effects_ref.txt; do
    test -s "$doc/$file" || fail "missing notice/document $file"
done
expect_sha256 ()
{
    actual=$("$coreutils_out/bin/sha256sum" "$1" | "$coreutils_out/bin/cut" -d ' ' -f 1)
    test "$actual" = "$2" || fail "altered upstream license/font $1"
}
expect_sha256 "$doc/license.txt" \
    df5a498f85ecfc3871b382f24b001de809378d6dc249d5c6020722a90001b9d6
expect_sha256 "$doc/credits.txt" \
    773c67603dde28a056300d9c32ca47985e6f383df5c26b4b5d0d91e1088892d8
expect_sha256 "$data/image/VeraBd.ttf" \
    cc037385e4d55bfde89b13e03091ee93bf40c0c52ddd391ff031ab276f13b8e9
for forbidden in image/augie.ttf image/Thumbs.db image/debug.txt convert32.pas \
    testit.pas mtest.pas; do
    test ! -e "$data/$forbidden" || fail "unneeded or unlicensed file $forbidden"
done
forbidden=$("$find" "$game_out" \( -iname '*.exe' -o -iname '*.dll' \
    -o -perm -2000 -o -perm -4000 -o -type f -perm /222 \) -print -quit)
test -z "$forbidden" || fail "forbidden or writable output $forbidden"
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'DMU smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
before=$($guix_bin hash -S nar "$game_out") || fail 'cannot hash output'
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/dmu-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"
"$coreutils_out/bin/chmod" 700 "$scratch/runtime"
artifacts=${DMU_SMOKE_ARTIFACTS:-$scratch/artifacts}
case "$artifacts" in
    /*) ;;
    *) fail 'DMU_SMOKE_ARTIFACTS must be absolute' ;;
esac
status=0
"$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" LC_ALL=C PATH="$coreutils_out/bin" \
    "$coreutils_out/bin/timeout" --kill-after=10 150 \
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork \
    "$python_out/bin/python3" "$channel_dir/tests/dungeon-monkey-unlimited-x11-runner.py" \
    "$game_out/bin/dungeon-monkey-unlimited" "$scratch" "$xorg_out/bin/Xvfb" \
    "$xdotool_out/bin/xdotool" "$xwd_out/bin/xwd" \
    "$imagemagick_out/bin/convert" "$artifacts" || status=$?
if test "$status" -ne 0; then
    for log in "$scratch/game.log" "$scratch/xvfb.log"; do
        test ! -f "$log" || "$coreutils_out/bin/cat" "$log" >&2
    done
    fail "native acceptance exited with status $status"
fi
state=$scratch/data/dungeon-monkey-unlimited
test -s "$state/savegame/cha_NativeHero.txt" || fail 'no native character save'
test -s "$state/savegame/rpg_NativeCampaign.txt" || fail 'no native campaign save'
test -s "$state/config.cfg" || fail 'no native configuration'
for resource in gamedata image; do
    test -L "$state/$resource" || fail "resource $resource was copied or not linked"
    test "$("$coreutils_out/bin/readlink" "$state/$resource")" = "$data/$resource" \
        || fail "wrong immutable resource target $resource"
done
unexpected=$("$find" "$scratch/home" "$scratch/config" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/work" -mindepth 1 -print -quit)
test -z "$unexpected" || fail "state escaped XDG data $unexpected"
unexpected=$("$find" "$state" -type f ! -name config.cfg ! -name cha_NativeHero.txt \
    ! -name rpg_NativeCampaign.txt ! -name debug.txt -print -quit)
test -z "$unexpected" || fail "unexpected game state $unexpected"
after=$($guix_bin hash -S nar "$game_out") || fail 'cannot hash output after play'
test "$before" = "$after" || fail "output NAR changed from $before to $after"
printf '%s\n' 'Dungeon Monkey Unlimited isolated native graphical acceptance passed'
