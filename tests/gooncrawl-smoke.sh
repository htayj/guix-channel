#!/bin/sh
# Actual terminal and SDL2 gameplay, native saves/restores and immutable NAR.
# Usage: sh tests/gooncrawl-smoke.sh [gooncrawl-output [evidence-directory]]
# The second argument or GOONCRAWL_SMOKE_ARTIFACTS names a new/empty absolute evidence directory.
set -eu
umask 077
fail() { printf 'gooncrawl-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 2 || fail "usage: $0 [gooncrawl-output [evidence-directory]]"
if test "$#" -ge 1; then out=$1
else out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
    --cores=1 --max-jobs=1 --no-offload --keep-failed gooncrawl); fi
case "$out" in /gnu/store/*) test -d "$out" || fail 'missing output';; *) fail 'expected realized store output';; esac
for frontend in gooncrawl gooncrawl-tiles; do
    test -x "$out/bin/$frontend" || fail "missing launcher: $frontend"
    test -x "$out/libexec/gooncrawl/$frontend" || fail "missing native binary: $frontend"
done
test -d "$out/share/gooncrawl/dat/tiles" || fail 'missing original tile assets'
# Realize consumer-only dependencies serially, before entering the offline game.
temporary=$(mktemp -d "${TMPDIR:-/tmp}/gooncrawl-consumer.XXXXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
"$guix_bin" package --no-grafts --cores=1 --max-jobs=1 --no-offload --keep-failed \
    -p "$temporary/profile" -i \
    python-debug:out python-pyte coreutils util-linux xorg-server xdotool xwd imagemagick tesseract-ocr pulseaudio
profile=$(readlink -f "$temporary/profile")
for tool in python3 unshare timeout env readlink id Xvfb xdotool xwd convert tesseract pulseaudio pactl; do
    test -x "$profile/bin/$tool" || fail "consumer profile lacks $tool"
done
requested_artifacts=${2:-}
set -- "$profile"/lib/python3.*/site-packages
test "$#" -eq 1 && test -d "$1" || fail 'missing Python module directory'
python_path=$1
artifacts=${requested_artifacts:-${GOONCRAWL_SMOKE_ARTIFACTS:-$(mktemp -d "${TMPDIR:-/tmp}/gooncrawl-artifacts.XXXXXXXX")}}
case "$artifacts" in /*) ;; *) fail 'artifact path must be absolute';; esac
mkdir -p "$artifacts"
"$profile/bin/python3" -I -B - "$artifacts" "$out" <<'PY'
from pathlib import Path
import stat
import sys
root, output = map(Path, sys.argv[1:])
if any(root.iterdir()):
    raise SystemExit('Evidence directory must be empty: ' + str(root))
for path in [output, *output.rglob('*')]:
    mode = path.lstat().st_mode
    if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
        raise SystemExit('Writable store member: ' + str(path))
PY
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
"$guix_bin" gc --requisites "$out" >"$artifacts/runtime-closure.txt"
"$profile/bin/python3" -I -B - "$profile" "$artifacts" <<'PY'
import json
from pathlib import Path
import sys
profile, root = map(Path, sys.argv[1:])
closure = set((root / 'runtime-closure.txt').read_text().splitlines())
if str(profile) in closure:
    raise SystemExit('Consumer profile belongs to game runtime closure')
tools = {}
observers = {'python3', 'Xvfb', 'xdotool', 'xwd', 'convert', 'tesseract'}
for name in ('python3', 'unshare', 'timeout', 'env', 'readlink', 'id',
             'Xvfb', 'xdotool', 'xwd', 'convert', 'tesseract', 'pulseaudio', 'pactl'):
    path = (profile / 'bin' / name).resolve(strict=True)
    store_root = str(Path(*path.parts[:4]))
    member = store_root in closure
    tools[name] = {'executable': str(path), 'runtime_closure_member': member}
(root / 'consumer-tools.json').write_text(json.dumps({
    'profile': str(profile), 'profile_outside_runtime_closure': True, 'tools': tools,
    'boundary': 'Observation tools outside closure; support dependencies may overlap.'
}, indent=2) + '\n')
overlap = sorted(name for name in observers if tools[name]['runtime_closure_member'])
if overlap:
    raise SystemExit('Consumer observation tool leaked into game runtime closure: ' + ', '.join(overlap))
PY
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
    "$profile/bin/python3" -I -B "$channel_dir/tests/gooncrawl-native.py" \
    "$profile" "$out" "$artifacts" >"$artifacts/proof.log" 2>&1 || status=$?
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
report['immutable_nar'] = sys.argv[2]
report['nar_unchanged'] = True
(root / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
PY
printf '%s\n' "Gooncrawl terminal + native SDL2 turn/movement/save/restore passed; unchanged NAR: $after; evidence: $artifacts"
