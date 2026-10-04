#!/bin/sh
# External consumer: unchanged native Allure SDL, no injected game state.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -ne 2; then
    echo "usage: GUIX=guix $0 OUTPUT EVIDENCE" >&2
    exit 64
fi
game_out=$1
evidence=$2
case "$game_out:$evidence" in
    /*:/*) ;;
    *) echo 'OUTPUT and EVIDENCE must be absolute' >&2; exit 64 ;;
esac
test -x "$game_out/bin/Allure"
find_output ()
{
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 "$2"); do
        if test -x "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "allure consumer: cannot find $1 in $2" >&2
    return 1
}
# Resolve every proof dependency before entering the offline namespace.
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
imagemagick_out=$(find_output bin/import imagemagick)
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'allure consumer requires user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/allure-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
if test -e "$evidence"; then
    echo 'EVIDENCE must be a fresh, nonexistent directory' >&2
    exit 64
fi
"$coreutils_out/bin/mkdir" -p "$evidence"
expected_uid=$("$coreutils_out/bin/id" -u)
expected_gid=$("$coreutils_out/bin/id" -g)
before=$("$guix_bin" hash -S nar "$game_out")
status=0
"$coreutils_out/bin/env" -i LC_ALL=C.UTF-8 PATH="$coreutils_out/bin" \
    PYTHONDONTWRITEBYTECODE=1 ALLURE_EXPECTED_UID="$expected_uid" \
    ALLURE_EXPECTED_GID="$expected_gid" \
    "$coreutils_out/bin/timeout" --kill-after=10 600 \
    "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork \
    "$python_out/bin/python3" -B "$channel_dir/tests/allure-x11-runner.py" \
    "$game_out" "$scratch" "$xorg_out/bin/Xvfb" \
    "$xdotool_out/bin/xdotool" "$imagemagick_out/bin/import" \
    "$imagemagick_out/bin/convert" "$evidence" "$before" \
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
    echo "allure native proof failed (status $status); evidence: $evidence" >&2
    exit 1
fi
printf 'allure native consumer passed; evidence: %s\n' "$evidence"
