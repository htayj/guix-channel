#!/bin/sh
# External ordinary-player Korean console proof; no installed smoke mode.
set -eu
fail() { printf 'kimchi-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 1 || { echo 'usage: kimchi-smoke.sh [kimchi-output]' >&2; exit 64; }
if test "$#" -eq 1; then
    out=$1
else
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts kimchi)
fi
out=$(CDPATH= cd -- "$out" && pwd)
find_output() {
    relative=$1
    shift
    outputs=$($guix_bin build --no-grafts "$@")
    for directory in $outputs; do
        if test -e "$directory/$relative"; then
            printf '%s\n' "$directory"
            return 0
        fi
    done
    fail "external tool unavailable: $relative"
}
python_out=$(find_output bin/python3 python)
pyte_out=$(find_output lib python-pyte)
wcwidth_out=$(find_output lib python-wcwidth)
xorg_out=$(find_output bin/Xvfb xorg-server)
xterm_out=$(find_output bin/xterm xterm)
image_out=$(find_output bin/import imagemagick)
font_out=$(find_output share/fonts font-google-noto-sans-cjk)
util_out=$(find_output bin/unshare util-linux)
core_out=$(find_output bin/timeout coreutils-minimal)
export PYTHONPATH=
for directory in "$pyte_out"/lib/python*/site-packages "$wcwidth_out"/lib/python*/site-packages; do
    test ! -d "$directory" || PYTHONPATH=${PYTHONPATH:+$PYTHONPATH:}$directory
done
export PYTHONDONTWRITEBYTECODE=1
test -x "$out/bin/kimchi" || fail 'missing installed launcher'
test -x "$out/libexec/kimchi" || fail 'missing source-built native executable'
for file in LICENSE INSTALL.txt CREDITS.txt license/cc0.txt license/lgpl.txt \
    license/libpng-LICENSE.txt license/lualicense.txt license/pcre_license.txt \
    license/worley.txt license/apache-2.0.txt source-notices/json.cc \
    source-notices/json.h source-notices/pcg.cc source-notices/perlin.cc \
    source-notices/perlin.h source-notices/domino.cc source-notices/domino.h \
    source-notices/domino-data.h source-notices/worley.cc source-notices/worley.h \
    source-notices/platform.h; do
    test -s "$out/share/doc/kimchi/$file" \
        || test -s "$out/share/doc/kimchi/$file.gz" || fail "missing notice $file"
done
for file in dat/dlua/loadmaps.lua dat/descript/ko/items.txt dat/descript/ko/species.txt \
    docs/quickstart.txt docs/crawl_manual.txt docs/aptitudes.txt; do
    test -s "$out/share/kimchi/$file" \
        || test -s "$out/share/kimchi/$file.gz" || fail "missing native console data $file"
done
test ! -e "$out/share/kimchi/dat/tiles" || fail 'graphical assets installed'
evidence=${KIMCHI_EVIDENCE_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/kimchi-evidence.XXXXXXXX")}
mkdir -p "$evidence"
evidence=$(CDPATH= cd -- "$evidence" && pwd)
test -z "$(find "$evidence" -mindepth 1 -print -quit)" \
    || fail 'KIMCHI_EVIDENCE_DIR must be new or empty'
scratch=$(mktemp -d "${TMPDIR:-/tmp}/kimchi-native.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT HUP INT TERM
before=$($guix_bin hash -S nar "$out")
status=0
"$python_out/bin/python3" "$channel_dir/tests/kimchi-pty-runner.py" \
    "$out/bin/kimchi" "$scratch" "$evidence" "$before" \
    "$util_out/bin/unshare" "$core_out/bin/timeout" "$xorg_out/bin/Xvfb" \
    "$xterm_out/bin/xterm" "$image_out/bin/import" "$font_out/share/fonts" || status=$?
after=$($guix_bin hash -S nar "$out")
"$python_out/bin/python3" - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
path = Path(root) / 'evidence.json'
record = json.loads(path.read_text())
record.update(output_nar_after=after, output_nar_unchanged=before == after)
if status != '0' or before != after:
    record['status'] = 'failed'
path.write_text(json.dumps(record, indent=2) + '\n')
PY
test "$status" -eq 0 || fail "native consumer failed; retained evidence: $evidence"
test "$before" = "$after" || fail "installed NAR changed; retained evidence: $evidence"
printf 'kimchi native Korean console gameplay/save/restore/continued-turn/quit proof passed; evidence: %s\n' "$evidence"
