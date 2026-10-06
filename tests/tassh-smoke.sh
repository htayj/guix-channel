#!/bin/sh
# External installed consumer; real loopback clipboards, fixture-backed host integration.
# Realize tassh separately, then: GUIX=guix sh tests/tassh-smoke.sh OUTPUT EVIDENCE
set -eu
umask 077
fail() { printf 'tassh-smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -eq 2 || { echo "usage: GUIX=guix sh $0 OUTPUT EVIDENCE" >&2; exit 64; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -e -- "$1")
evidence=$(realpath -m -- "$2")
case "$out" in /gnu/store/*) ;; *) fail 'OUTPUT must be a realized /gnu/store item' ;; esac
case "$evidence/" in /gnu/store/*|"$out/"*) fail 'EVIDENCE must be outside the store/output' ;; esac
test -x "$out/bin/tassh" || fail 'OUTPUT lacks installed bin/tassh'
if test -e "$evidence"; then
    test -d "$evidence" || fail 'EVIDENCE is not a directory'
    test -z "$(find "$evidence" -mindepth 1 -maxdepth 1 -print -quit)" || fail 'EVIDENCE is not empty'
fi
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
# Serial prerequisite realization, never build tassh here or invoke Guix inside.
core=$(find_output bin/timeout coreutils)
util=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
bash=$(find_output bin/sh bash-minimal)
xclip=$(find_output bin/xclip xclip)
xorg=$(find_output bin/Xvfb xorg-server)
sway=$(find_output bin/sway sway)
wl_clipboard=$(find_output bin/wl-copy wl-clipboard)
iproute=$(find_output sbin/ip iproute2)
"$core/bin/mkdir" -p -- "$evidence"
check_output()
{
    "$python/bin/python3" -I -B - "$out" <<'PY'
import os
from pathlib import Path
import stat
import sys
out = Path(sys.argv[1]).resolve(strict=True)
if out.parent != Path('/gnu/store'):
    raise SystemExit('OUTPUT must resolve to a direct store item')
if not (out / 'bin/tassh').is_file() or not os.access(out / 'bin/tassh', os.X_OK):
    raise SystemExit('missing installed CLI')
license_path = out / 'share/doc/tassh/LICENSE'
if not license_path.is_file() or b'MIT License' not in license_path.read_bytes():
    raise SystemExit('missing installed MIT license')
notices = out / 'share/doc/tassh/third-party-licenses'
if sum(p.is_file() for p in notices.rglob('*')) < 181:
    raise SystemExit('missing installed third-party notices')
for path in (out, *out.rglob('*')):
    mode = path.lstat().st_mode
    if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
        raise SystemExit('writable store member: ' + str(path))
PY
}
check_output
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/output-nar-before.txt"
status=0
"$core/bin/env" -i LC_ALL=C.UTF-8 PATH="" \
    SH="$bash/bin/sh" SLEEP="$core/bin/sleep" MOUNT="$util/bin/mount" \
    XCLIP="$xclip/bin/xclip" XVFB="$xorg/bin/Xvfb" SWAY="$sway/bin/sway" \
    WLCOPY="$wl_clipboard/bin/wl-copy" WLPASTE="$wl_clipboard/bin/wl-paste" IP="$iproute/sbin/ip" \
    HOST_UID="$("$core/bin/id" -u)" HOST_GID="$("$core/bin/id" -g)" \
    HOST_USER_NS="$("$core/bin/readlink" /proc/self/ns/user)" \
    HOST_MNT_NS="$("$core/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$core/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$core/bin/readlink" /proc/self/ns/pid)" \
    "$core/bin/timeout" --kill-after=10 240 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -I -B "$channel_dir/tests/tassh-native.py" \
    "$out" "$evidence" >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
# Preserve hashes and failed logs; private /tmp is destroyed with the namespace.
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
"$core/bin/cat" "$evidence/driver.stdout" "$evidence/driver.stderr" \
    "$evidence/output-check-after.stdout" "$evidence/output-check-after.stderr"
test "$before" = "$after" || fail "output NAR changed; evidence: $evidence"
test "$modes" -eq 0 || fail "output modes changed; evidence: $evidence"
test "$status" -eq 0 || fail "native fixture-backed consumer exited $status; evidence: $evidence"
printf 'tassh real loopback X11/inject/Wayland transfers passed; Tailscale, SSH-session and service-manager integration fixture-backed, not proven; evidence: %s\n' "$evidence"
