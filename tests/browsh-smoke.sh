#!/bin/sh
# External native consumer: GUIX=guix sh tests/browsh-smoke.sh OUTPUT EVIDENCE
# OUTPUT is already realized.  Only generic test tools are built here; the
# isolated driver owns the browser proof and writes runtime.json.
set -eu
umask 077
fail() { printf 'browsh-smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -eq 2 || { echo "usage: GUIX=guix sh $0 OUTPUT EVIDENCE" >&2; exit 64; }
out=$1
evidence=$2
case "$out" in /gnu/store/*) ;; *) fail 'OUTPUT must be an absolute direct /gnu/store item' ;; esac
case "$evidence" in /*) ;; *) fail 'EVIDENCE must be absolute' ;; esac
case "$evidence" in /gnu/store|/gnu/store/*) fail 'EVIDENCE must be outside /gnu/store' ;; esac
test -d "$out" || fail 'OUTPUT is not a realized directory'
test ! -e "$evidence" && test ! -L "$evidence" || fail 'EVIDENCE must be fresh (including no dangling symlink)'
guix_bin=$(command -v "${GUIX:-guix}") || fail 'GUIX executable not found'
test -x "$guix_bin" && test ! -d "$guix_bin" || fail 'GUIX must name an executable command'
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
find_output()
{
    member=$1
    shift
    candidates=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$@") || return 1
    for output in $candidates; do
        # Module markers deliberately expand only inside each realized output.
        for path in "$output"/$member; do
            case "$member" in
                bin/*) test -x "$path" && test ! -d "$path" || continue ;;
                *) test -f "$path" || continue ;;
            esac
            printf '%s\n' "$output"
            return 0
        done
    done
    fail "dependency lacks $member: $*"
}
# Resolve every dependency before creating evidence or entering namespaces.
# Never realize Browsh, its sources, or a development profile here.
coreutils=$(find_output bin/timeout coreutils)
util_linux=$(find_output bin/unshare util-linux)
test -x "$util_linux/bin/mount" || fail 'util-linux output lacks bin/mount'
python=$(find_output bin/python3 python)
iproute=$(find_output sbin/ip iproute2)
test -x "$iproute/sbin/ip" || fail 'iproute2 output lacks executable sbin/ip'
pyte=$(find_output 'lib/python*/site-packages/pyte/__init__.py' python-pyte)
wcwidth=$(find_output 'lib/python*/site-packages/wcwidth/__init__.py' python-wcwidth)
pythonpath=$("$python/bin/python3" -s -B - "$pyte" "$wcwidth" <<'PY'
from pathlib import Path
import sys
sites = []
for output, module in zip(sys.argv[1:], ('pyte', 'wcwidth')):
    markers = list(Path(output).glob('lib/python*/site-packages/' + module + '/__init__.py'))
    if len(markers) != 1:
        raise SystemExit('expected one direct site-packages directory for ' + module)
    sites.append(str(markers[0].parent.parent))
print(':'.join(sites))
PY
)
# Resolve and validate canonical paths with Python, including evidence parents
# that are symlinks into the store.  A direct item, not a profile, is required.
paths=$("$python/bin/python3" -s -B - "$out" "$evidence" <<'PY'
import os
from pathlib import Path
import sys
output, evidence = map(Path, sys.argv[1:])
root = output.resolve(strict=True)
if not output.is_absolute() or root.parent != Path('/gnu/store') or str(root) != sys.argv[1]:
    raise SystemExit('OUTPUT must be one canonical direct /gnu/store directory')
if not root.is_dir():
    raise SystemExit('OUTPUT is not a directory')
if not evidence.is_absolute() or os.path.lexists(evidence):
    raise SystemExit('EVIDENCE must be an absolute fresh nonexistent directory')
parent = evidence.parent.resolve(strict=True)
if not parent.is_dir() or evidence.name in ('', '.', '..'):
    raise SystemExit('EVIDENCE must have an existing directory parent')
canonical = parent / evidence.name
store = Path('/gnu/store').resolve(strict=True)
if canonical == store or store in canonical.parents:
    raise SystemExit('EVIDENCE must resolve outside /gnu/store')
if os.path.lexists(canonical):
    raise SystemExit('canonical EVIDENCE already exists')
# Newlines would make the shell's two-line path exchange ambiguous.
if '\n' in str(root) or '\n' in str(canonical):
    raise SystemExit('OUTPUT and EVIDENCE must not contain newlines')
print(root)
print(canonical)
PY
)
out=${paths%%
*}
evidence=${paths#*
}
# No -p: this is the final freshness check after dependency realization.
"$coreutils/bin/mkdir" -- "$evidence"
printf '%s\n' "$out" >"$evidence/store-output.txt"
scratch=
cleanup()
{
    result=$?
    trap - 0 HUP INT TERM
    clean_status=0
    if test -n "$scratch"; then
        "$coreutils/bin/rm" -rf -- "$scratch" || clean_status=$?
    fi
    receipt_status=0
    "$python/bin/python3" -s -B - "$evidence" "$scratch" "$clean_status" <<'PY' || receipt_status=$?
import json
import os
from pathlib import Path
import sys
root, scratch, status = sys.argv[1:]
clean = bool(scratch) and not os.path.lexists(scratch) and int(status) == 0
record = {'scratch': scratch, 'clean': clean, 'cleanup_exit_status': int(status)}
(Path(root) / 'cleanup.json').write_text(json.dumps(record, indent=2) + '\n')
if not clean:
    raise SystemExit(1)
PY
    if test "$result" -eq 0 && { test "$clean_status" -ne 0 || test "$receipt_status" -ne 0; }; then
        result=1
    fi
    exit "$result"
}
trap cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
scratch=$("$coreutils/bin/mktemp" -d /tmp/browsh-native.XXXXXXXX)
printf '%s\n' "$scratch" >"$evidence/scratch-path.txt"
check_output()
{
    "$python/bin/python3" -s -B - "$out" <<'PY'
import os
from pathlib import Path
import stat
import sys
root = Path(sys.argv[1])
if root.resolve(strict=True) != root or root.parent != Path('/gnu/store') or not root.is_dir():
    raise SystemExit('OUTPUT is no longer a canonical direct store directory')
program = root / 'bin/browsh'
# Installed wrappers and symlinks are allowed; the launched member must execute.
if not program.is_file() or not os.access(program, os.X_OK):
    raise SystemExit('OUTPUT lacks executable bin/browsh')
for path in [root, *root.rglob('*')]:
    mode = path.lstat().st_mode
    if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
        raise SystemExit('writable installed store member: ' + str(path))
PY
}
status=0
closure_status=0
"$guix_bin" gc -R "$out" >"$evidence/runtime-closure.txt" 2>"$evidence/runtime-closure.stderr" || closure_status=$?
before_status=0
before=$("$guix_bin" hash -S nar "$out" 2>"$evidence/output-nar-before.stderr") || before_status=$?
printf '%s\n' "$before" >"$evidence/output-nar-before.txt"
modes_before=0
check_output >"$evidence/output-check-before.stdout" 2>"$evidence/output-check-before.stderr" || modes_before=$?
# Preflight failures do not enter isolation, but still retain after-state proof.
if test "$closure_status" -ne 0 || test "$before_status" -ne 0 || test "$modes_before" -ne 0; then
    status=1
else
    "$coreutils/bin/env" -i LC_ALL=C.UTF-8 PATH="$coreutils/bin" \
        HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
        HOST_MNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
        HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
        HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
        EXPECTED_UID="$("$coreutils/bin/id" -u)" EXPECTED_GID="$("$coreutils/bin/id" -g)" \
        PYTHONPATH="$pythonpath" \
        "$coreutils/bin/timeout" --kill-after=10 300 \
        "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
        --mount --propagation private --net --pid --mount-proc --kill-child --fork \
        "$python/bin/python3" -s -B "$channel_dir/tests/browsh-native.py" \
        "$out" "$evidence" "$scratch" "$util_linux/bin/mount" "$iproute/sbin/ip" \
        >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
fi
after_status=0
after=$("$guix_bin" hash -S nar "$out" 2>"$evidence/output-nar-after.stderr") || after_status=$?
printf '%s\n' "$after" >"$evidence/output-nar-after.txt"
modes=0
check_output >"$evidence/output-check-after.stdout" 2>"$evidence/output-check-after.stderr" || modes=$?
merge_status=0
"$python/bin/python3" -s -B - "$evidence" "$out" "$status" "$modes_before" "$modes" \
    "$before" "$after" "$before_status" "$after_status" "$closure_status" <<'PY' || merge_status=$?
import json
from pathlib import Path
import sys
root, output, status, modes_before, modes, before, after, before_status, after_status, closure_status = sys.argv[1:]
evidence = Path(root)
record = {'status': 'failed'}
runtime_error = None
try:
    record = json.loads((evidence / 'runtime.json').read_text())
    if not isinstance(record, dict):
        raise ValueError('runtime.json must contain an object')
except (OSError, ValueError) as error:
    record = {'status': 'failed'}
    runtime_error = str(error)
immutable = bool(before) and before == after and not any(map(int, (before_status, after_status, modes_before, modes)))
record.update(output=output, exit_status=int(status), output_check_before_status=int(modes_before),
              output_check_after_status=int(modes), output_nar_before=before, output_nar_after=after,
              output_nar_before_status=int(before_status), output_nar_after_status=int(after_status),
              runtime_closure_status=int(closure_status), immutable_output=immutable)
if runtime_error is not None:
    record['runtime_error'] = runtime_error
if int(status) or int(closure_status) or not immutable or runtime_error is not None:
    record['status'] = 'failed'
(evidence / 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')
if runtime_error is not None:
    raise SystemExit(1)
PY
# A runner failure keeps its exact code, unless store integrity itself failed.
if test "$before_status" -ne 0 || test "$after_status" -ne 0 || test -z "$before" || \
    test "$before" != "$after" || test "$modes_before" -ne 0 || test "$modes" -ne 0; then
    fail "installed output NAR/modes failed; evidence: $evidence"
fi
if test "$status" -ne 0; then
    printf 'browsh-smoke: native consumer exited %s; evidence: %s\n' "$status" "$evidence" >&2
    exit "$status"
fi
test "$merge_status" -eq 0 || fail "runtime evidence missing or invalid; evidence: $evidence"
printf 'Browsh native consumer passed with immutable output; evidence: %s\n' "$evidence"
