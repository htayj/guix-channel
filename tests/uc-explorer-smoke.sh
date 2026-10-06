#!/bin/sh
# Installed native parser only; fixtures and oracle live outside the store.
# Usage: GUIX=guix sh tests/uc-explorer-smoke.sh OUTPUT EVIDENCE
set -eu
fail() { printf 'uc-explorer-smoke: %s\n' "$*" >&2; exit 1; }
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
    candidates=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$@") || return 1
    for output in $candidates; do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    fail "dependency lacks $program: $*"
}
# Realize generic dependencies before entering namespaces, never uc-explorer.
coreutils=$(find_output bin/timeout coreutils)
util_linux=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
scratch=$("$coreutils/bin/mktemp" -d /tmp/uc-explorer-native.XXXXXXXX)
trap '"$coreutils/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils/bin/mkdir" -p "$evidence"
check_output()
{
    "$python/bin/python3" -I -B - "$out" <<'PY'
import os
from pathlib import Path
import stat
import sys
root = Path(sys.argv[1]).resolve(strict=True)
if root.parent != Path('/gnu/store'):
    raise SystemExit('OUTPUT must resolve to one direct /gnu/store item')
required = {'bin/uc-explorer', 'share/doc/uc-explorer-0.1.0/COPYING'}
files = {str(p.relative_to(root)) for p in root.rglob('*') if not p.is_dir()}
if files - {'etc/ld.so.cache'} != required:
    raise SystemExit('output contains files outside installed uc-explorer scope')
for name in required:
    path = root / name
    if path.is_symlink() or not path.is_file() or not path.stat().st_size:
        raise SystemExit('installed member is not regular non-empty file: ' + name)
program = root / 'bin/uc-explorer'
if not os.access(program, os.X_OK):
    raise SystemExit('installed uc-explorer is not executable')
with program.open('rb') as stream:
    if stream.read(4) != b'\x7fELF':
        raise SystemExit('installed uc-explorer is not native ELF')
if b'GNU GENERAL PUBLIC LICENSE' not in (root / 'share/doc/uc-explorer-0.1.0/COPYING').read_bytes():
    raise SystemExit('missing installed GNU GPL license text')
cache = root / 'etc/ld.so.cache'
if cache.exists() and (cache.is_symlink() or not cache.is_file() or cache.stat().st_mode & 0o111):
    raise SystemExit('Guix ld.so.cache must be regular non-executable metadata')
for path in [root, *root.rglob('*')]:
    mode = path.lstat().st_mode
    if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
        raise SystemExit('writable installed store member: ' + str(path))
PY
}
check_output
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/output-nar-before.txt"
status=0
"$coreutils/bin/env" -i LC_ALL=C PATH="$coreutils/bin" \
    HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
    HOST_MNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
    EXPECTED_UID="$("$coreutils/bin/id" -u)" EXPECTED_GID="$("$coreutils/bin/id" -g)" \
    "$coreutils/bin/timeout" --kill-after=10 90 \
    "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -I -B "$channel_dir/tests/uc-explorer-native.py" \
    "$out" "$evidence" "$scratch" "$util_linux/bin/mount" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
# Preserve native failures and both NAR hashes even when the driver fails.
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/output-nar-after.txt"
modes=0
check_output >"$evidence/output-check-after.stdout" 2>"$evidence/output-check-after.stderr" || modes=$?
"$python/bin/python3" -I -B - "$evidence" "$out" "$status" "$modes" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, output, status, modes, before, after = sys.argv[1:]
evidence = Path(root)
record = json.loads((evidence / 'runtime.json').read_text()) if (evidence / 'runtime.json').exists() else {'status': 'failed'}
record.update(output=output, exit_status=int(status), output_check_after_status=int(modes),
              output_nar_before=before, output_nar_after=after, output_unchanged=before == after)
if int(status) or int(modes) or before != after:
    record['status'] = 'failed'
(evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')
PY
"$coreutils/bin/cat" "$evidence/driver.stdout" "$evidence/driver.stderr" \
    "$evidence/output-check-after.stdout" "$evidence/output-check-after.stderr"
test "$before" = "$after" || fail "installed output NAR changed; evidence: $evidence"
test "$modes" -eq 0 || fail "installed output scope/modes changed; evidence: $evidence"
test "$status" -eq 0 || fail "isolated native proof exited $status; evidence: $evidence"
printf 'uc-explorer native parser proof passed (decoded fixtures, malformed rejections, unchanged NAR); evidence: %s\n' "$evidence"
