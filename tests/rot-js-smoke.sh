#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-or-later
# Installed-package external consumer proof for rot-js; never realizes or
# rebuilds the target package.  Usage: GUIX=guix sh tests/rot-js-smoke.sh OUTPUT EVIDENCE
set -eu
fail() { printf 'rot-js-smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: GUIX=guix sh %s OUTPUT EVIDENCE\n' "$0" >&2; exit 64; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$1
evidence=$2
case "$out" in /gnu/store/*) ;; *) fail 'OUTPUT must be a realized /gnu/store item' ;; esac
case "$evidence" in /*) ;; *) fail 'EVIDENCE must be absolute' ;; esac
case "$evidence" in /gnu/store|/gnu/store/*) fail 'EVIDENCE must be outside the store' ;; esac
test -d "$out" || fail 'OUTPUT is not realized'
test -d "$out/lib/node_modules/rot-js" || fail 'OUTPUT lacks lib/node_modules/rot-js'
test ! -e "$evidence" && test ! -L "$evidence" || fail 'EVIDENCE must be fresh and nonexistent'
find_output()
{
    program=$1
    shift
    candidates=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$@") || return 1
    for candidate in $candidates; do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    fail "dependency lacks $program: $*"
}
# Realize only generic proof tools and the fixed compiler archive before
# entering the offline namespaces.  OUTPUT is supplied by the caller.
python=$(find_output bin/python3 python)
coreutils=$(find_output bin/env coreutils)
util_linux=$(find_output bin/unshare util-linux)
node=$(find_output bin/node -e '(@ (gnu packages node) node-lts)')
# The same lock-pinned TypeScript 4.5.4 archive rot.js's upstream build uses.
compiler=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 \
    -L "$channel_dir/guix" \
    -e '(assoc-ref (@ (tay packages rot-js-npm-sources) %rot-js-npm-sources) "typescript@4.5.4")')
test -f "$compiler" || fail 'TypeScript 4.5.4 source archive is not a file'
canonical_out=$("$coreutils/bin/realpath" -e -- "$out")
test "$out" = "$canonical_out" || fail 'OUTPUT must be canonical'
case "${out#/gnu/store/}" in ''|*/*) fail 'OUTPUT must be one direct store item' ;; esac
test "$evidence" = "$("$coreutils/bin/realpath" -m -- "$evidence")" || fail 'EVIDENCE must be canonical'
"$coreutils/bin/mkdir" -- "$evidence"
scratch=$("$coreutils/bin/mktemp" -d /tmp/rot-js-consumer.XXXXXXXX)
trap '"$coreutils/bin/rm" -rf -- "$scratch"' EXIT HUP INT TERM
status=0
before=$("$guix_bin" hash -S nar "$out" 2>"$evidence/output-before.nar-hash.stderr") || status=$?
printf '%s\n' "$before" >"$evidence/output-before.nar-hash"
if test "$status" -eq 0; then
    "$coreutils/bin/env" -i LC_ALL=C PATH='' \
        HOME="$scratch/home" TMPDIR="$scratch/tmp" \
        XDG_CONFIG_HOME="$scratch/config" XDG_DATA_HOME="$scratch/data" \
        XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
        XDG_RUNTIME_DIR="$scratch/runtime" \
        EXPECTED_UID="$("$coreutils/bin/id" -u)" EXPECTED_GID="$("$coreutils/bin/id" -g)" \
        HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
        HOST_MNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
        HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
        HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
        "$coreutils/bin/timeout" --kill-after=10 1800 \
        "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
        --mount --propagation private --net --pid --mount-proc --kill-child --fork \
        "$python/bin/python3" -I -B "$channel_dir/tests/rot-js-consumer/native.py" \
        "$out" "$evidence" "$scratch" "$channel_dir/tests/rot-js-consumer" \
        "$util_linux/bin/mount" "$node" "$compiler" \
        >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
fi
# Always record the final NAR, including a failed namespace/compile/assertion.
hash_status=0
after=$("$guix_bin" hash -S nar "$out" 2>"$evidence/output-after.nar-hash.stderr") || hash_status=$?
printf '%s\n' "$after" >"$evidence/output-after.nar-hash"
if test "$status" -eq 0 && test "$hash_status" -ne 0; then status=$hash_status; fi
if "$coreutils/bin/env" -i LC_ALL=C PATH='' \
    "$python/bin/python3" -I -B - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
path = Path(root) / 'evidence.json'
try:
    record = json.loads(path.read_text())
    if not isinstance(record, dict):
        raise ValueError('consumer evidence is not an object')
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
    printf 'rot-js-smoke: consumer proof failed (exit %s); evidence: %s\n' "$status" "$evidence" >&2
    exit "$status"
fi
printf 'ROT_JS_CONSUMER_OK evidence=%s\n' "$evidence"
