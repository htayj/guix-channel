#!/bin/sh
# Exercise the source-built console frontend, never a package smoke mode.
set -eu
fail() { printf 'stoat-soup-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 1 || { echo 'usage: stoat-soup-smoke.sh [stoat-soup-output]' >&2; exit 64; }
if test "$#" -eq 1; then
    out=$1
else
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts stoat-soup)
fi
out=$(CDPATH= cd -- "$out" && pwd)
# Realize external verification tools before the offline namespace.
$guix_bin build --no-grafts python python-pyte util-linux coreutils-minimal >/dev/null
test -x "$out/bin/stoat-soup" || fail 'missing installed launcher'
test -x "$out/libexec/stoat-soup" || fail 'missing source-built native executable'
for file in LICENCE README.md INSTALL.md CREDITS.txt license/cc0.txt \
    license/lgpl.txt license/libpng-LICENSE.txt license/lualicense.txt \
    license/pcre_license.txt license/worley.txt license/apache-2.0.txt \
    source-notices/json.cc source-notices/json.h source-notices/pcg.cc \
    source-notices/perlin.cc source-notices/perlin.h source-notices/domino.cc \
    source-notices/domino.h source-notices/domino-data.h; do
    test -s "$out/share/doc/stoat-soup/$file" \
        || test -s "$out/share/doc/stoat-soup/$file.gz" \
        || fail "missing installed documentation or notice $file"
done
for directory in dat/des dat/dlua dat/clua dat/database dat/defaults dat/descript \
    docs/license settings; do
    test -d "$out/share/stoat-soup/$directory" || fail "missing native assets $directory"
done
# Native scripts/maps/descriptions must actually be shipped, not empty directories.
for file in dat/dlua/loadmaps.lua dat/descript/species.txt docs/quickstart.txt \
    docs/crawl_manual.txt docs/aptitudes.txt; do
    test -s "$out/share/stoat-soup/$file" \
        || test -s "$out/share/stoat-soup/$file.gz" \
        || fail "missing native game data $file"
done
before=$($guix_bin hash -S nar "$out")
scratch=$(mktemp -d "${TMPDIR:-/tmp}/stoat-soup-smoke.XXXXXXXX")
$guix_bin shell --no-grafts python python-pyte util-linux coreutils-minimal -- \
    timeout --kill-after=5 240 \
    unshare --user --map-root-user --net --pid --fork --kill-child \
    python3 "$channel_dir/tests/stoat-soup-pty-runner.py" "$out/bin/stoat-soup" "$scratch" \
    || fail "offline native gameplay/save/resume proof failed; scratch retained: $scratch"
test "$before" = "$($guix_bin hash -S nar "$out")" \
    || fail "installed output NAR changed; scratch retained: $scratch"
if test -n "${OMP_RUNTIME_RAW_CAPTURE:-}${OMP_RUNTIME_TEXT_CAPTURE:-}${OMP_RUNTIME_TRANSCRIPT:-}"; then
    printf 'STOAT-SOUP: native save evidence retained: %s\n' "$scratch"
else
    rm -rf "$scratch"
fi
printf '%s\n' 'stoat-soup native gameplay/save/same-state resume/post-resume gameplay, HOME/XDG isolation, licenses, offline namespace and unchanged output NAR proof passed'
