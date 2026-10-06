#!/bin/sh
# Installed SDL panel/PDP-5 memory proof; never realizes the target itself.
# Usage: GUIX=guix sh tests/blincolnlights-smoke.sh OUTPUT EVIDENCE
set -eu
fail() { printf 'blincolnlights-smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: GUIX=guix sh %s OUTPUT EVIDENCE\n' "$0" >&2; exit 64; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$1
evidence=$2
case "$out" in /gnu/store/*) ;; *) fail 'OUTPUT must be a realized /gnu/store item' ;; esac
case "$evidence" in /*) ;; *) fail 'EVIDENCE must be absolute' ;; esac
case "$evidence" in /gnu/store|/gnu/store/*) fail 'EVIDENCE must be outside the store' ;; esac
test -d "$out" || fail 'OUTPUT is not realized'
test ! -e "$evidence" && test ! -L "$evidence" || fail 'EVIDENCE must be fresh and nonexistent'
find_output()
{
    program=$1
    shift
    candidates=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$@") || return 1
    for candidate in $candidates; do
        if test -e "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    fail "dependency lacks $program: $*"
}
# Only generic proof dependencies are realized, serially, before isolation.
python=$(find_output bin/python3 python)
coreutils=$(find_output bin/env coreutils)
util_linux=$(find_output bin/unshare util-linux)
xorg=$(find_output bin/Xvfb xorg-server)
xwininfo=$(find_output bin/xwininfo xwininfo)
xdotool=$(find_output bin/xdotool xdotool)
imagemagick=$(find_output bin/import imagemagick)
test -x "$imagemagick/bin/convert" || fail 'imagemagick lacks convert'
libx11=$(find_output lib/libX11.so.6 libx11)
canonical_out=$("$coreutils/bin/realpath" -e -- "$out")
test "$out" = "$canonical_out" || fail 'OUTPUT must be canonical'
case "${out#/gnu/store/}" in ''|*/*) fail 'OUTPUT must be one direct store item' ;; esac
test "$evidence" = "$("$coreutils/bin/realpath" -m -- "$evidence")" || fail 'EVIDENCE must be canonical'
"$coreutils/bin/mkdir" -- "$evidence"
status=0
before=$("$guix_bin" hash -S nar "$out" 2>"$evidence/output-before.nar-hash.stderr") || status=$?
printf '%s\n' "$before" >"$evidence/output-before.nar-hash"
if test "$status" -eq 0; then
    "$coreutils/bin/env" -i LC_ALL=C.UTF-8 PATH='' \
        HOST_UID="$("$coreutils/bin/id" -u)" HOST_GID="$("$coreutils/bin/id" -g)" \
        HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
        HOST_MOUNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
        HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
        HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
        XVFB="$xorg/bin/Xvfb" XWININFO="$xwininfo/bin/xwininfo" \
        XDOTOOL="$xdotool/bin/xdotool" IMPORT="$imagemagick/bin/import" \
        CONVERT="$imagemagick/bin/convert" XLIB="$libx11/lib/libX11.so.6" \
        "$coreutils/bin/timeout" --kill-after=10 180 \
        "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
        --mount --propagation private --net --pid --mount-proc --kill-child --fork \
        "$python/bin/python3" -I -B "$channel_dir/tests/blincolnlights-native.py" \
        "$out" "$evidence" >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
fi
hash_status=0
after=$("$guix_bin" hash -S nar "$out" 2>"$evidence/output-after.nar-hash.stderr") || hash_status=$?
printf '%s\n' "$after" >"$evidence/output-after.nar-hash"
if test "$status" -eq 0 && test "$hash_status" -ne 0; then status=$hash_status; fi
if "$coreutils/bin/env" -i LC_ALL=C.UTF-8 PATH='' \
    "$python/bin/python3" -I -B - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
path = Path(root) / 'evidence.json'
try:
    record = json.loads(path.read_text())
    if not isinstance(record, dict):
        raise ValueError('native evidence is not an object')
except (OSError, ValueError) as error:
    record = {'status': 'failed', 'shell_evidence_error': str(error)}
unchanged = bool(before) and before == after
exit_status = int(status)
if exit_status or not unchanged or record.get('status') != 'passed':
    record['status'] = 'failed'
    exit_status = exit_status or 1
record.update(exit_status=exit_status, output_nar_before=before,
              output_nar_after=after, output_unchanged=unchanged)
path.write_text(json.dumps(record, indent=2) + '\n')
raise SystemExit(0 if record['status'] == 'passed' else 1)
PY
then :; else if test "$status" -eq 0; then status=1; fi; fi
if test "$status" -ne 0; then
    printf 'blincolnlights-smoke: native proof failed (exit %s); evidence: %s\n' "$status" "$evidence" >&2
    exit "$status"
fi
printf 'BLINCOLNLIGHTS_NATIVE_PANEL_MEMORY_OK evidence=%s\n' "$evidence"
