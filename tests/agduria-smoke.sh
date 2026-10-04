#!/bin/sh
# External consumer of the ordinary source-built ncurses game, no smoke mode.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -ne 2; then
    echo "usage: GUIX=guix sh $0 OUTPUT EVIDENCE" >&2
    exit 64
fi
game_out=$1
evidence=$2
case "$game_out:$evidence" in
    /*:/*) ;;
    *) echo 'OUTPUT and EVIDENCE must be absolute' >&2; exit 64 ;;
esac
test -x "$game_out/bin/agduria"
find_output ()
{
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 "$2"); do
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "agduria consumer: cannot find $1 in $2" >&2
    return 1
}
# Resolve every proof dependency before entering the offline namespace.
python_out=$(find_output bin/python3 python)
pyte_out=$(find_output lib python-pyte)
wcwidth_out=$(find_output lib python-wcwidth)
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
xorg_out=$(find_output bin/Xvfb xorg-server)
xterm_out=$(find_output bin/xterm xterm)
font_out=$(find_output share/fonts/X11/misc font-misc-misc)
imagemagick_out=$(find_output bin/import imagemagick)
python_path=
for dependency in "$pyte_out" "$wcwidth_out"; do
    for site in "$dependency"/lib/python*/site-packages; do
        if test -d "$site"; then
            python_path=${python_path:+$python_path:}$site
        fi
    done
done
test -n "$python_path"
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'agduria consumer requires user, mount, network and PID namespaces' >&2
    exit 77
fi
if test -e "$evidence"; then
    echo 'EVIDENCE must be a fresh, nonexistent directory' >&2
    exit 64
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/agduria-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" -p "$evidence"
expected_uid=$("$coreutils_out/bin/id" -u)
expected_gid=$("$coreutils_out/bin/id" -g)
before=$("$guix_bin" hash -S nar "$game_out")
status=0
"$coreutils_out/bin/env" -i LC_ALL=C.UTF-8 PATH="$coreutils_out/bin" \
    PYTHONPATH="$python_path" PYTHONDONTWRITEBYTECODE=1 \
    AGDURIA_EXPECTED_UID="$expected_uid" AGDURIA_EXPECTED_GID="$expected_gid" \
    AGDURIA_XVFB="$xorg_out/bin/Xvfb" AGDURIA_XTERM="$xterm_out/bin/xterm" \
    AGDURIA_FONT="$font_out/share/fonts/X11/misc" \
    AGDURIA_IMPORT="$imagemagick_out/bin/import" \
    "$coreutils_out/bin/timeout" --kill-after=10 180 \
    "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork \
    "$python_out/bin/python3" -B "$channel_dir/tests/agduria-pty-runner.py" \
    "$game_out" "$scratch" "$evidence" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$game_out")
"$python_out/bin/python3" - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
path = Path(root) / 'evidence.json'
record = json.loads(path.read_text()) if path.exists() else {
    'status': 'failed', 'error': 'runner ended without final evidence'}
record.update(exit_status=int(status), output_nar_before=before,
              output_nar_after=after, output_unchanged=before == after)
if int(status) or before != after:
    record['status'] = 'failed'
path.write_text(json.dumps(record, indent=2) + '\n')
PY
if test "$status" -ne 0 || test "$before" != "$after"; then
    echo "agduria native proof failed (status $status); evidence: $evidence" >&2
    exit 1
fi
printf 'AGDURIA_RUNTIME_OK\n'
printf 'agduria external gameplay proof passed; evidence: %s\n' "$evidence"
