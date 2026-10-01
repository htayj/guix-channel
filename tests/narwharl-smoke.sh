#!/bin/sh
# Exercise only the original source-built game and its native save format.
set -eu
fail() { printf 'narwharl-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 1 || { echo "usage: $0 [narwharl-output]" >&2; exit 64; }
if test "$#" -eq 1; then
    out=$1
else
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts narwharl)
fi
out=$(CDPATH= cd -- "$out" && pwd)
# Realize the tools and pyte before entering the offline namespace.
$guix_bin build --no-grafts python python-pyte util-linux coreutils-minimal >/dev/null
test -x "$out/bin/narwharl" || fail 'missing installed launcher'
test -x "$out/libexec/narwharl" || fail 'missing source-built native executable'
for file in README INSTALL CHANGELOG gpl-2.0.txt mtrand/mtrand.h \
    mtrand/mtreadme.txt source-notices/main.cpp THIRD-PARTY-NOTICES; do
    test -s "$out/share/doc/narwharl/$file" \
        || test -s "$out/share/doc/narwharl/$file.gz" \
        || fail "missing documentation or notice $file"
done
for file in monsters.txt weapons.txt launchers.txt armor.txt potions.txt spells.txt; do
    test -s "$out/share/narwharl/defs/$file" || fail "missing native definition $file"
done
before=$($guix_bin hash -S nar "$out")
temporary=$(mktemp -d "${TMPDIR:-/tmp}/narwharl-smoke.XXXXXXXX")
$guix_bin shell --no-grafts python python-pyte util-linux coreutils-minimal -- \
    timeout --kill-after=5 240 \
    unshare --user --map-root-user --net --pid --fork --kill-child \
    python3 "$channel_dir/tests/narwharl-pty-runner.py" "$out/bin/narwharl" "$temporary" \
    || fail "offline native movement/save/restore proof failed; scratch retained: $temporary"
test "$before" = "$($guix_bin hash -S nar "$out")" \
    || fail "installed output NAR changed; scratch retained: $temporary"
# Preserve real saves alongside requested captures; ordinary suite runs clean up.
if test -n "${OMP_RUNTIME_RAW_CAPTURE:-}${OMP_RUNTIME_TEXT_CAPTURE:-}${OMP_RUNTIME_TRANSCRIPT:-}"; then
    printf 'NARWHARL: native save evidence retained: %s\n' "$temporary"
else
    rm -rf "$temporary"
fi
printf '%s\n' 'narwharl native map/movement/save/same-state restore/post-restore movement, XDG/HOME state, notices, offline namespace and unchanged output NAR proof passed'
