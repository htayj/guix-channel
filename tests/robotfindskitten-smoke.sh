#!/bin/sh
# Offline native ncurses gameplay proof; no production smoke mode or adapters.
set -eu

guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [robotfindskitten-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    out=$1
else
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes robotfindskitten)
fi
case "$out" in
    /gnu/store/*-robotfindskitten-3.0000000.726) ;;
    *) echo 'robotfindskitten smoke: expected native release store output' >&2; exit 1 ;;
esac

test -x "$out/bin/robotfindskitten"
test ! -e "$out/libexec/robotfindskitten-real"
test ! -e "$out/libexec/robotfindskitten-smoke.py"
test ! -e "$out/games/robotfindskitten"
for file in share/games/robotfindskitten/vanilla.nki \
    share/man/man6/robotfindskitten.6.zst \
    share/info/robotfindskitten.info.gz \
    share/applications/robotfindskitten.desktop \
    share/metainfo/org.robotfindskitten.robotfindskitten.metainfo.xml \
    share/icons/hicolor/512x512/apps/robotfindskitten.png \
    share/icons/hicolor/scalable/apps/robotfindskitten.svg; do
    test -s "$out/$file"
done
for file in AUTHORS BUGS ChangeLog COPYING NEWS README.md REUSE.toml GPL-2.0-or-later.txt; do
    test -s "$out/share/doc/robotfindskitten/$file"
done

# Runtime helpers are TEST-ONLY; none are dependencies of the shipped game.
ncurses_out=$($guix_bin build --no-grafts --no-substitutes ncurses)
before=$($guix_bin hash -S nar "$out")
test -z "$(find "$out" -xdev -perm /222 -print -quit)"
test ! -w "$out"

# Retain genuine raw ncurses output, never masquerade it as a PNG. Main can
# replay terminal.raw in xterm and capture an actual graphical screenshot.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/robotfindskitten-proof-XXXXXXXX")
chmod 700 "$scratch"
raw=${ROBOTFINDSKITTEN_RAW_CAPTURE:-$scratch/terminal.raw}
printf '%s\n' "robotfindskitten private proof state: $scratch"

$guix_bin shell -L "$channel_dir/guix" --pure --no-grafts --no-substitutes \
    python python-pyte util-linux coreutils -- \
    unshare --user --map-root-user --net --fork -- \
    env TERMINFO="$ncurses_out/share/terminfo" \
    python3 "$channel_dir/tests/robotfindskitten-smoke.py" \
    "$out/bin/robotfindskitten" "$scratch" --raw "$raw"

after=$($guix_bin hash -S nar "$out")
test "$before" = "$after"
test -z "$(find "$out" -xdev -perm /222 -print -quit)"
test ! -w "$out"
test -s "$raw"
printf '%s\n' "robotfindskitten: unchanged read-only NAR $after; raw frame $raw"
