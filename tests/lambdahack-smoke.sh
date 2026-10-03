#!/bin/sh
# External consumer of the authentic, default SDL frontend.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: GUIX=guix LAMBDAHACK_SMOKE_ARTIFACTS=/absolute/path $0 [OUTPUT]" >&2
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
    echo "lambdahack consumer: cannot find $1 in $2" >&2
    return 1
}
game_out=${1:-}
if test -z "$game_out"; then
    game_out=$(find_output bin/LambdaHack lambdahack)
fi
case "$game_out" in
    /*) ;;
    *) echo 'OUTPUT must be absolute' >&2; exit 64 ;;
esac
test -x "$game_out/bin/LambdaHack"
test -x "$game_out/bin/lambdahack"
mode=${LAMBDAHACK_CONSUMER_MODE:-gui}
case "$mode" in gui|benchmark) ;; *) echo 'invalid consumer mode' >&2; exit 64 ;; esac
python_out=$(find_output bin/python3 python)
xorg_out=/unused
xdotool_out=/unused
imagemagick_out=/unused
if test "$mode" = gui; then
    xorg_out=$(find_output bin/Xvfb xorg-server)
    xdotool_out=$(find_output bin/xdotool xdotool)
    imagemagick_out=$(find_output bin/import imagemagick)
fi
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'lambdahack consumer requires user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/lambdahack-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
evidence=${LAMBDAHACK_SMOKE_ARTIFACTS:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/lambdahack-evidence.XXXXXX")}
case "$evidence" in
    /*) ;;
    *) echo 'LAMBDAHACK_SMOKE_ARTIFACTS must be absolute' >&2; exit 64 ;;
esac
"$coreutils_out/bin/mkdir" -p "$evidence"
before=$("$guix_bin" hash -S nar "$game_out")
status=0
"$coreutils_out/bin/env" -i LC_ALL=C.UTF-8 PATH="$coreutils_out/bin" \
    PYTHONDONTWRITEBYTECODE=1 \
    "$coreutils_out/bin/timeout" --kill-after=10 600 \
    "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork \
    "$python_out/bin/python3" -B "$channel_dir/tests/lambdahack-x11-runner.py" \
    "$mode" "$game_out" "$scratch" "$xorg_out/bin/Xvfb" \
    "$xdotool_out/bin/xdotool" "$imagemagick_out/bin/import" \
    "$imagemagick_out/bin/convert" \
    "$evidence" "$before" || status=$?
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
    echo "lambdahack $mode proof failed (status $status); evidence: $evidence" >&2
    exit 1
fi
printf 'lambdahack %s consumer passed; evidence: %s\n' "$mode" "$evidence"
