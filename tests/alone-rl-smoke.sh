#!/bin/sh
# External X11 consumer of the ordinary source-built Swing game; no smoke mode.
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
test -x "$game_out/bin/alone-rl"
find_output ()
{
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 "$2"); do
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "alone-rl smoke: cannot find $1 in $2" >&2
    return 1
}
python_expr='(begin (use-modules (gnu packages) (guix packages))
  (let* ((pillow (specification->package "python-pillow"))
         (entry (assoc-ref (package-development-inputs pillow) "python")))
    (if (pair? entry) (car entry)
        (error "python-pillow: no python development input"))))'
python_bin=
for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
    --no-offload --cores=1 --max-jobs=1 -e "$python_expr"); do
    # Guix's pyproject interpreter is a wrapper exporting bin/python only;
    # non-wrapper CPython inputs instead export bin/python3.
    for command in python python3; do
        if test -x "$output/bin/$command"; then
            python_bin=$output/bin/$command
            break 2
        fi
    done
done
test -n "$python_bin" || {
    echo 'alone-rl smoke: Pillow interpreter input lacks python or python3' >&2
    exit 1
}
pillow_out=$(find_output lib python-pillow)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
xwininfo_out=$(find_output bin/xwininfo xwininfo)
imagemagick_out=$(find_output bin/import imagemagick)
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_path=
for site in "$pillow_out"/lib/python*/site-packages; do
    if test -d "$site"; then
        python_path=${python_path:+$python_path:}$site
    fi
done
test -n "$python_path"
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'alone-rl smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/alone-rl-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" -p "$evidence"
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"
"$coreutils_out/bin/chmod" 700 "$scratch/runtime"
before=$("$guix_bin" hash -S nar "$game_out")
status=0
"$coreutils_out/bin/env" -i HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" LC_ALL=C.UTF-8 PATH="$coreutils_out/bin" \
    PYTHONPATH="$python_path" PYTHONDONTWRITEBYTECODE=1 \
    "$coreutils_out/bin/timeout" --kill-after=10 240 \
    "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork \
    "$python_bin" -B "$channel_dir/tests/alone-rl-x11-runner.py" \
    "$game_out" "$scratch" "$xorg_out/bin/Xvfb" "$xdotool_out/bin/xdotool" \
    "$imagemagick_out/bin/import" "$evidence" "$before" "$xwininfo_out/bin/xwininfo" || status=$?
after=$("$guix_bin" hash -S nar "$game_out")
"$python_bin" - "$evidence" "$status" "$before" "$after" <<'PY'
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
    echo "alone-rl native proof failed (status $status); evidence: $evidence" >&2
    exit 1
fi
printf 'ALONERL_RUNTIME_OK\n'
printf 'alone-rl external Swing/elevation-reload proof passed; evidence: %s\n' "$evidence"
