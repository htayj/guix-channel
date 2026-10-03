#!/bin/sh
# External consumer: installed upstream regression, then native curses persistence.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: GUIX=guix PLOMROGUE_EVIDENCE_DIR=/absolute/new-or-empty/path $0 [OUTPUT]" >&2
    exit 64
fi
find_output ()
{
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts "$2"); do
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "plomrogue smoke: cannot find $1 in $2" >&2
    return 1
}
game_out=${1:-}
if test -z "$game_out"; then
    game_out=$(find_output bin/plomrogue plomrogue)
fi
case "$game_out" in
    /gnu/store/*) ;;
    *) echo 'OUTPUT must be an absolute /gnu/store output' >&2; exit 64 ;;
esac
test -x "$game_out/bin/plomrogue"
python_out=$(find_output bin/python3 python)
pyte_out=$(find_output lib python-pyte)
wcwidth_out=$(find_output lib python-wcwidth)
xorg_out=$(find_output bin/Xvfb xorg-server)
xterm_out=$(find_output bin/xterm xterm)
imagemagick_out=$(find_output bin/import imagemagick)
font_out=$(find_output share/fonts/truetype/DejaVuSansMono.ttf font-dejavu)
ncurses_out=$(find_output share/terminfo ncurses)
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
# Realize the compiler/header closure before entering the offline namespace.
gcc_out=$(find_output bin/gcc gcc-toolchain)
grep_out=$(find_output bin/grep grep)
diff_out=$(find_output bin/cmp diffutils)
bash_out=$(find_output bin/bash bash)
python_path=
for dependency in "$pyte_out" "$wcwidth_out"; do
    found=
    for site in "$dependency"/lib/python*/site-packages; do
        if test -d "$site"; then
            python_path=${python_path:+$python_path:}$site
            found=yes
        fi
    done
    test -n "$found"
done
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/plomrogue-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
evidence=${PLOMROGUE_EVIDENCE_DIR:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/plomrogue-evidence.XXXXXX")}
case "$evidence" in
    /*) ;;
    *) echo 'PLOMROGUE_EVIDENCE_DIR must be absolute' >&2; exit 64 ;;
esac
# The runner checks emptiness before creating its receipt; never overwrite evidence.
"$coreutils_out/bin/mkdir" -p "$evidence"
before=$("$guix_bin" hash -S nar "$game_out")
status=0
"$coreutils_out/bin/env" -i LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH="$python_path" TERMINFO_DIRS="$ncurses_out/share/terminfo" \
    PATH="$python_out/bin:$coreutils_out/bin:$gcc_out/bin:$grep_out/bin:$diff_out/bin:$bash_out/bin" \
    "$python_out/bin/python3" -B "$channel_dir/tests/plomrogue-pty-runner.py" \
    "$game_out" "$scratch" "$evidence" "$before" \
    "$util_linux_out/bin/unshare" "$coreutils_out/bin/timeout" \
    "$xorg_out/bin/Xvfb" "$xterm_out/bin/xterm" \
    "$imagemagick_out/bin/import" "$font_out/share/fonts/truetype" || status=$?
after=$("$guix_bin" hash -S nar "$game_out")
"$python_out/bin/python3" - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
path = Path(root) / 'evidence.json'
# Refused nonempty evidence must remain untouched.
if int(status) == 64:
    raise SystemExit(0)
record = json.loads(path.read_text()) if path.exists() else {
    'status': 'failed', 'error': 'runner ended without a receipt'}
record.update(exit_status=int(status), output_nar_before=before,
              output_nar_after=after, output_unchanged=before == after)
if int(status) or before != after:
    record['status'] = 'failed'
path.write_text(json.dumps(record, indent=2) + '\n')
PY
if test "$status" -ne 0 || test "$before" != "$after"; then
    echo "plomrogue native proof failed (status $status); evidence: $evidence" >&2
    exit 1
fi
"$python_out/bin/python3" - "$evidence" <<'PY'
import json
from pathlib import Path
import sys
root = Path(sys.argv[1])
record = json.loads((root / 'evidence.json').read_text())
upstream = record['upstream_regression']
assert record['status'] == 'passed' and upstream['upstream_reference_matches']
assert record['continuation']['exact_continuation']
print('plomrogue original upstream oracle, native move/save/two-exact-restores and '
      '90-versus-45/reload/45 exact continuation proof passed; evidence: %s' % root)
PY
