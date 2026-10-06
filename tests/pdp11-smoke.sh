#!/bin/sh
# Installed host-only PDP11 consumer: exact source-derived built-in microcycles.
# Usage: GUIX=guix sh tests/pdp11-smoke.sh OUTPUT EVIDENCE
set -eu
fail() { printf 'pdp11-smoke: %s\n' "$*" >&2; exit 1; }
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
# All generic dependencies are realized before namespace entry. No package
# build, profile mutation, firmware download or host UI occurs inside it.
coreutils=$(find_output bin/timeout coreutils)
util_linux=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
scratch=$("$coreutils/bin/mktemp" -d /tmp/pdp11-native.XXXXXXXX)
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
expected = {'pdp1105', 'pdp1120', 'pdp1140', 'pdp1145'}
if {p.name for p in (root / 'bin').iterdir()} != expected:
    raise SystemExit('installed bin scope differs from the four host-only binaries')
for name in expected:
    program = root / 'bin' / name
    if not program.is_file() or program.is_symlink() or not os.access(program, os.X_OK):
        raise SystemExit('missing real installed executable: ' + name)
    with program.open('rb') as stream:
        if stream.read(4) != b'\x7fELF':
            raise SystemExit('installed executable is not native ELF: ' + name)
license_path = root / 'share/doc/pdp11-0-5b5b734/LICENSE'
if not license_path.is_file() or not license_path.stat().st_size:
    raise SystemExit('missing installed license')
# The recipe installs the four binaries and root license; Guix's standard
# ldconfig phase additionally generates this exact non-executable metadata.
# No firmware, disk image, libexec target or mutable fixture is allowed.
files = {str(p.relative_to(root)) for p in root.rglob('*') if not p.is_dir()}
required = {'bin/' + name for name in expected} | {'share/doc/pdp11-0-5b5b734/LICENSE'}
if files - {'etc/ld.so.cache'} != required:
    raise SystemExit('output contains files outside the host-only scope')
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
    "$python/bin/python3" -I -B "$channel_dir/tests/pdp11-native.py" \
    "$out" "$evidence" "$scratch" "$util_linux/bin/mount" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
# Retain both NAR hashes and failed native output, even when assertions fail.
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
              output_nar_before=before, output_nar_after=after,
              output_unchanged=before == after)
if int(status) or int(modes) or before != after:
    record['status'] = 'failed'
(evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')
PY
"$coreutils/bin/cat" "$evidence/driver.stdout" "$evidence/driver.stderr" \
    "$evidence/output-check-after.stdout" "$evidence/output-check-after.stderr"
test "$before" = "$after" || fail "installed output NAR changed; evidence: $evidence"
test "$modes" -eq 0 || fail "installed output scope/modes changed; evidence: $evidence"
test "$status" -eq 0 || fail "isolated native proof exited $status; evidence: $evidence"
printf 'pdp11 exact native microcycle proof passed (two deterministic runs, unchanged NAR); evidence: %s\n' "$evidence"
