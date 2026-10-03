#!/bin/sh
# Drive the installed upstream SDL game; no game-side proof hooks.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -ne 0; then
    echo "usage: GUIX=guix WROGUE_OUTPUT=/gnu/store/... WROGUE_EVIDENCE_DIR=/absolute/path $0" >&2
    exit 64
fi
find_output ()
{
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts "$2"); do
        if test -x "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "wrogue smoke: cannot find $1 in $2" >&2
    return 1
}
game_out=${WROGUE_OUTPUT:-}
if test -z "$game_out"; then
    game_out=$(find_output bin/wrogue wrogue)
fi
case "$game_out" in
    /*) ;;
    *) echo 'WROGUE_OUTPUT must be absolute' >&2; exit 64 ;;
esac
test -x "$game_out/bin/wrogue" || { echo 'missing bin/wrogue' >&2; exit 1; }
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
xwd_out=$(find_output bin/xwd xwd)
imagemagick_out=$(find_output bin/convert imagemagick)
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'wrogue smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/wrogue-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
# Retain evidence by default, including honest failure JSON and logs.
evidence=${WROGUE_EVIDENCE_DIR:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/wrogue-evidence.XXXXXX")}
case "$evidence" in
    /*) ;;
    *) echo 'WROGUE_EVIDENCE_DIR must be absolute' >&2; exit 64 ;;
esac
"$coreutils_out/bin/mkdir" -p "$evidence"
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"
"$coreutils_out/bin/chmod" 700 "$scratch/runtime"
before=$($guix_bin hash -S nar "$game_out")
status=0
"$coreutils_out/bin/env" -i HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" LC_ALL=C PATH="$coreutils_out/bin" \
    "$coreutils_out/bin/timeout" --kill-after=10 240 \
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork \
    "$python_out/bin/python3" "$channel_dir/tests/wrogue-x11-runner.py" \
    "$game_out" "$scratch" "$xorg_out/bin/Xvfb" "$xdotool_out/bin/xdotool" \
    "$xwd_out/bin/xwd" "$imagemagick_out/bin/convert" "$evidence" "$before" || status=$?
after=$($guix_bin hash -S nar "$game_out")
# Finish the evidence even if timeout or an OS signal prevented Python cleanup.
"$python_out/bin/python3" - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
path = Path(root) / "evidence.json"
record = json.loads(path.read_text()) if path.exists() else {
    "status": "failed", "error": "runner ended without final evidence"}
record.update(exit_status=int(status), output_nar_before=before, output_nar_after=after,
              output_unchanged=before == after)
if int(status) or before != after:
    record["status"] = "failed"
path.write_text(json.dumps(record, indent=2) + "\n")
PY
if test "$status" -ne 0 || test "$before" != "$after"; then
    echo "wrogue native proof failed (status $status); evidence: $evidence" >&2
    exit 1
fi
printf 'wrogue native gameplay/save-load proof passed; evidence: %s\n' "$evidence"
