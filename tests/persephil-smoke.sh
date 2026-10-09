#!/bin/sh
# Installed persephil consumer: ordinary HTTP legacy KWIC input and real XLSX.
# The package under test must already be built; only harness tools are realized.
# Usage: GUIX=guix sh tests/persephil-smoke.sh OUTPUT EVIDENCE
set -eu
fail() { printf 'persephil-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=$(command -v "${GUIX:-guix}") || fail 'GUIX executable not found'
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
# Realize only generic harness tools before isolation, never persephil here.
coreutils=$(find_output bin/timeout coreutils)
util_linux=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
iproute2=$(find_output sbin/ip iproute2)
"$python/bin/python3" -I -B - "$out" "$evidence" <<'PY'
from pathlib import Path
import sys
output, evidence = map(Path, sys.argv[1:])
if output.resolve(strict=True) != output or output.parent != Path('/gnu/store'):
    raise SystemExit('OUTPUT must be one canonical direct store item')
resolved = evidence.resolve()
if resolved == Path('/gnu/store') or Path('/gnu/store') in resolved.parents:
    raise SystemExit('EVIDENCE must resolve outside the store')
if evidence.exists() or evidence.is_symlink():
    raise SystemExit('EVIDENCE must be fresh')
if not evidence.parent.is_dir():
    raise SystemExit('EVIDENCE parent directory must already exist')
PY
"$coreutils/bin/mkdir" "$evidence"
scratch=$("$coreutils/bin/mktemp" -d /tmp/persephil-native.XXXXXXXX)
cleanup()
{
    "$coreutils/bin/rm" -rf "$scratch"
    if test ! -e "$scratch"; then
        printf 'scratch_removed=true\nscratch=%s\n' "$scratch" >"$evidence/cleanup.txt"
    else
        printf 'scratch_removed=false\nscratch=%s\n' "$scratch" >"$evidence/cleanup.txt"
        return 1
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' HUP TERM
"$coreutils/bin/sha256sum" "$channel_dir/tests/persephil-native.py" "$0" \
    >"$evidence/test-driver-sha256.txt"
printf '%s\n' "$out" >"$evidence/store-output.txt"
printf 'coreutils=%s\nutil_linux=%s\npython=%s\niproute2=%s\n' \
    "$coreutils" "$util_linux" "$python" "$iproute2" >"$evidence/harness-tools.txt"
"$guix_bin" gc -R "$out" >"$evidence/runtime-closure.txt"
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
if not os.access(root / 'bin/persephil', os.X_OK):
    raise SystemExit('missing installed bin/persephil')
for path in [root, *root.rglob('*')]:
    mode = path.lstat().st_mode
    if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
        raise SystemExit('writable store member: ' + str(path))
PY
}
check_output >"$evidence/output-check-before.stdout" 2>"$evidence/output-check-before.stderr"
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/output-nar-before.txt"
status=0
"$coreutils/bin/env" -i LC_ALL=C PATH="$coreutils/bin" \
    HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
    HOST_MNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
    EXPECTED_UID="$("$coreutils/bin/id" -u)" EXPECTED_GID="$("$coreutils/bin/id" -g)" \
    "$coreutils/bin/timeout" --kill-after=10 180 \
    "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -I -B "$channel_dir/tests/persephil-native.py" \
    "$out" "$evidence" "$scratch" "$util_linux/bin/mount" "$iproute2/sbin/ip" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
# Hash and retain failed output too: runtime errors must not masquerade as a pass.
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/output-nar-after.txt"
modes=0
check_output >"$evidence/output-check-after.stdout" 2>"$evidence/output-check-after.stderr" || modes=$?
printf '%s\n' "$status" >"$evidence/consumer-exit-status.txt"
cleanup
trap - EXIT
"$python/bin/python3" -I -B - "$evidence" "$out" "$status" "$modes" "$before" "$after" <<'PY'
import hashlib
import json
from pathlib import Path
import sys
root, output, status, modes, before, after = sys.argv[1:]
evidence = Path(root)
record = json.loads((evidence / 'runtime.json').read_text()) if (evidence / 'runtime.json').exists() else {'status': 'failed'}
record.update(output=output, exit_status=int(status), output_check_after_status=int(modes),
              output_nar_before=before, output_nar_after=after,
              output_unchanged=before == after, scratch_removed=True,
              namespace_process_exited=True)
if int(status) or int(modes) or before != after:
    record['status'] = 'failed'
(evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')
hashes = {str(path.relative_to(evidence)): hashlib.sha256(path.read_bytes()).hexdigest()
          for path in sorted(evidence.rglob('*')) if path.is_file()
          and path.name != 'file-hashes.json'}
(evidence / 'file-hashes.json').write_text(json.dumps(hashes, indent=2) + '\n')
PY
"$coreutils/bin/cat" "$evidence/driver.stdout" "$evidence/driver.stderr" \
    "$evidence/output-check-after.stdout" "$evidence/output-check-after.stderr"
test "$before" = "$after" || fail "installed output NAR changed; evidence: $evidence"
test "$modes" -eq 0 || fail "installed output modes changed; evidence: $evidence"
test "$status" -eq 0 || fail "isolated native proof exited $status; evidence: $evidence"
printf 'persephil native driver proof passed; evidence: %s\n' "$evidence"
