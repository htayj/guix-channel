#!/bin/sh
# Source-built original game, no Goocastle adapter or synthetic smoke mode.
set -eu
fail() { printf 'umoria-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 1 || { echo "usage: $0 [umoria-output]" >&2; exit 64; }
if test "$#" -eq 1; then
    out=$1
else
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts umoria)
fi
out=$(CDPATH= cd -- "$out" && pwd)
# Realize all dependencies before entering the offline namespace.  guix shell
# sets Python's search path for the terminal-emulator dependency, too.
$guix_bin build --no-grafts python python-pyte util-linux coreutils-minimal >/dev/null
test -x "$out/bin/umoria" || fail 'missing launcher'
test -x "$out/libexec/umoria/umoria" || fail 'missing source-built executable'
for file in AUTHORS LICENSE scores.dat data/splash.txt data/versions.txt \
    data/help.txt data/rl_help.txt data/help_wizard.txt data/rl_help_wizard.txt \
    data/welcome.txt data/death_tomb.txt data/death_royal.txt; do
    test -f "$out/share/umoria/$file" || fail "missing game resource $file"
done
for file in AUTHORS LICENSE README.md CHANGELOG.md historical/README.md; do
    test -s "$out/share/doc/umoria/$file" || fail "missing documentation $file"
done
test -z "$(find "$out" -xdev \( -type f -o -type d \) -perm /222 -print)" \
    || fail 'installed output contains writable files/directories'
before=$(find "$out" -xdev -type f -exec sha256sum {} \; | sort)
temporary=$(mktemp -d "${TMPDIR:-/tmp}/umoria-smoke.XXXXXXXX")
$guix_bin shell --no-grafts python python-pyte util-linux coreutils-minimal -- \
    timeout --kill-after=5 240 \
    unshare --user --map-root-user --net --pid --fork --kill-child \
    python3 "$channel_dir/tests/umoria-pty-runner.py" "$out/bin/umoria" "$temporary" \
    || fail "isolated real movement/save/resume proof failed; scratch retained: $temporary"
test "$before" = "$(find "$out" -xdev -type f -exec sha256sum {} \; | sort)" \
    || fail 'installed output changed during gameplay'
rm -rf "$temporary"
printf '%s\n' 'umoria movement/save/resume, exact native character sheet, XDG/HOME/custom-save paths, offline namespace and immutable output proof passed'
