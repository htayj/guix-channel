#!/bin/sh
# Real upstream tty/curses gameplay and native save/restore, offline and read-only.
# Usage: sh tests/gnollhack-smoke.sh [gnollhack-output]
# GNOLLHACK_SMOKE_ARTIFACTS must name a new/empty absolute evidence directory.
set -eu
umask 077
fail() { printf 'gnollhack-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 1 || fail "usage: $0 [gnollhack-output]"
if test "$#" -eq 1; then out=$1
else out=$("$guix_bin" build -L "$channel_dir/guix" --cores=1 --max-jobs=1 \
    --no-grafts --no-offload --keep-failed gnollhack); fi
case "$out" in /gnu/store/*) test -d "$out" || fail 'missing output';; *) fail 'expected realized store output';; esac
test -x "$out/bin/gnollhack" || fail 'missing ordinary launcher'
# Realize dependencies serially, before entering the offline namespace.
temporary=$(mktemp -d "${TMPDIR:-/tmp}/gnollhack-consumer.XXXXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
"$guix_bin" package --cores=1 --max-jobs=1 --no-grafts --no-offload --keep-failed \
    -p "$temporary/profile" -i python python-pyte coreutils util-linux
profile=$(readlink -f "$temporary/profile")
for tool in python3 unshare timeout env readlink id; do
    test -x "$profile/bin/$tool" || fail "consumer profile lacks $tool"
done
set -- "$profile"/lib/python3.*/site-packages
test "$#" -eq 1 && test -d "$1" || fail 'missing Python module directory'
python_path=$1
artifacts=${GNOLLHACK_SMOKE_ARTIFACTS:-$(mktemp -d "${TMPDIR:-/tmp}/gnollhack-artifacts.XXXXXXXX")}
case "$artifacts" in /*) ;; *) fail 'artifact path must be absolute';; esac
mkdir -p "$artifacts"
"$profile/bin/python3" -I -B - "$artifacts" "$out" <<'PY'
from pathlib import Path
import stat
import sys
root, output = map(Path, sys.argv[1:])
if any(root.iterdir()):
    raise SystemExit('Evidence directory must be empty: ' + str(root))
if output.parent != Path('/gnu/store'):
    raise SystemExit('Expected direct store output')
for path in [output, *output.rglob('*')]:
    mode = path.lstat().st_mode
    if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
        raise SystemExit('Writable store member: ' + str(path))
PY
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
"$guix_bin" gc --requisites "$out" >"$artifacts/runtime-closure.txt"
status=0
"$profile/bin/env" -i LC_ALL=C TERM=xterm-256color PATH="$profile/bin" \
    GUIX_PYTHONPATH="$python_path" \
    HOST_UID="$("$profile/bin/id" -u)" HOST_GID="$("$profile/bin/id" -g)" \
    HOST_USER_NS="$("$profile/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$profile/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$profile/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$profile/bin/readlink" /proc/self/ns/pid)" \
    "$profile/bin/timeout" --kill-after=10 420 \
    "$profile/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$profile/bin/python3" -I -B "$channel_dir/tests/gnollhack-native.py" \
    "$out" "$artifacts" >"$artifacts/proof.log" 2>&1 || status=$?
cat "$artifacts/proof.log"
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
test "$before" = "$after" || fail "output NAR changed; evidence: $artifacts"
test "$status" -eq 0 || fail "native proof failed ($status); evidence: $artifacts"
"$profile/bin/python3" -I -B - "$artifacts" "$after" <<'PY'
import json
from pathlib import Path
import sys
root = Path(sys.argv[1])
report = json.loads((root / 'report.json').read_text())
if not report['success']:
    raise SystemExit('Native gameplay did not pass')
report.update(immutable_nar=sys.argv[2], nar_unchanged=True)
(root / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
PY
printf '%s\n' "GnollHack tty + curses native movement/turns/save/restore/resave passed; unchanged NAR: $after; evidence: $artifacts"
