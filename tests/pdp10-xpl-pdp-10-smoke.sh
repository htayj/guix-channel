#!/bin/sh
# Installed host-only pdp10-xpl consumer: the pinned hello.xpl example is
# compiled to hello.rel by the isolated native driver tests/pdp10-xpl-native.py.
# Usage: GUIX=guix sh tests/pdp10-xpl-pdp-10-smoke.sh OUTPUT EVIDENCE
set -eu
fail() { printf 'pdp10-xpl-pdp-10-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -eq 2 || { echo "usage: GUIX=guix sh $0 OUTPUT EVIDENCE" >&2; exit 64; }
out=$1
evidence=$2
case "$out" in /gnu/store/*) ;; *) fail 'OUTPUT must be a realized /gnu/store path' ;; esac
case "$evidence" in /*) ;; *) fail 'EVIDENCE must be absolute' ;; esac
case "$evidence" in /gnu/store|/gnu/store/*) fail 'EVIDENCE must be outside /gnu/store' ;; esac
test -d "$out" || fail 'OUTPUT is not a realized directory'
test ! -e "$evidence" && test ! -L "$evidence" || fail 'EVIDENCE must be a fresh nonexistent directory'
find_output()
{
    program=$1
    shift
    candidates=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 "$@") || return 1
    for output in $candidates; do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    fail "dependency lacks $program: $*"
}
# Every realization is serial and outside the namespace; isolation needs no daemon.
# OUTPUT itself is never built here: it must already be realized.
coreutils=$(find_output bin/timeout coreutils)
util_linux=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
if ! "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --kill-child --fork \
    "$coreutils/bin/true"; then
    echo 'pdp10-xpl smoke requires same-UID user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils/bin/mktemp" -d /tmp/pdp10-xpl-native.XXXXXXXX)
trap '"$coreutils/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils/bin/mkdir" -p "$evidence"
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/output-nar-before.txt"
status=0
"$coreutils/bin/env" -i LC_ALL=C PATH="$coreutils/bin" \
    HOME="$scratch/home" TMPDIR="$scratch/tmp" \
    XDG_CONFIG_HOME="$scratch/config" XDG_CACHE_HOME="$scratch/cache" \
    XDG_DATA_HOME="$scratch/data" XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
    HOST_MNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
    EXPECTED_UID="$("$coreutils/bin/id" -u)" EXPECTED_GID="$("$coreutils/bin/id" -g)" \
    "$coreutils/bin/timeout" --kill-after=10 300 \
    "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --kill-child --fork \
    "$python/bin/python3" -I -B "$channel_dir/tests/pdp10-xpl-native.py" \
    "$out" "$evidence" "$scratch" "$util_linux/bin/mount" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
# Retain both NAR hashes and failed native output, even when assertions fail.
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/output-nar-after.txt"
"$python/bin/python3" -I -B - "$evidence" "$out" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, output, status, before, after = sys.argv[1:]
evidence = Path(root)
record = json.loads((evidence / 'runtime.json').read_text()) if (evidence / 'runtime.json').exists() else {'status': 'failed'}
record.update(output=output, exit_status=int(status),
              output_nar_before=before, output_nar_after=after,
              output_unchanged=before == after)
if int(status) or before != after:
    record['status'] = 'failed'
(evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')
PY
"$coreutils/bin/cat" "$evidence/driver.stdout" "$evidence/driver.stderr"
test "$before" = "$after" || fail "installed output NAR changed; evidence: $evidence"
test "$status" -eq 0 || fail "isolated native proof exited $status; evidence: $evidence"
printf 'pdp10-xpl exact native pinned hello.xpl compile-to-hello.rel proof passed (unchanged NAR); evidence: %s\n' "$evidence"
