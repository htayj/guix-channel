#!/bin/sh
# External proof; never installed in the package or connected to a live daemon.
# Usage: sh tests/ludviglundgren-qbittorrent-cli-smoke.sh OUTPUT EMPTY-EVIDENCE
set -eu
umask 077
fail () { printf '%s\n' "ludviglundgren-qbittorrent-cli smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s OUTPUT EVIDENCE\n' "$0" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -- "$1")
case "$out" in /gnu/store/*) ;; *) fail 'output must be a prebuilt Guix store directory' ;; esac
test -x "$out/bin/qbt" || fail 'missing native qbt'
test -L "$out/bin/qbittorrent-cli" || fail 'missing qbittorrent-cli symlink'
test "$(realpath -- "$out/bin/qbittorrent-cli")" = "$out/bin/qbt" || fail 'alias does not resolve to qbt'
guix_bin=$(command -v "${GUIX:-guix}")
if test "${QBT_NATIVE_PROOF_ENV:-}" != ready; then
    exec "$guix_bin" shell --pure --no-grafts \
        python qbittorrent-no-x iproute2 util-linux coreutils findutils bash-minimal \
        --preserve='^(GUIX|QBT_NATIVE_PROOF_ENV)$' -- \
        env GUIX="$guix_bin" QBT_NATIVE_PROOF_ENV=ready \
        sh "$channel_dir/tests/ludviglundgren-qbittorrent-cli-smoke.sh" "$out" "$2"
fi
for cmd in python3 qbittorrent-nox ip timeout unshare mount find; do
    command -v "$cmd" >/dev/null || fail "missing proof dependency: $cmd"
done
mkdir -p -- "$2"
evidence=$(realpath -- "$2")
case "$evidence/" in /gnu/store/*) fail 'evidence must be outside the store' ;; esac
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'evidence directory must be empty'
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'package contains writable files'
if ! timeout --kill-after=5 10 unshare --user --map-current-user --keep-caps \
        --net --mount --mount-proc --pid --fork --kill-child true; then
    printf '%s\n' 'native qbt proof requires same-user, mount, network and PID namespaces' >&2
    exit 77
fi
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
export QBT_PROOF_HOST_NETNS="$(readlink /proc/self/ns/net)"
export QBT_PROOF_HOST_MNTNS="$(readlink /proc/self/ns/mnt)"
export QBT_PROOF_HOST_PIDNS="$(readlink /proc/self/ns/pid)"
export QBT_PROOF_HOST_USERNS="$(readlink /proc/self/ns/user)"
export QBT_PROOF_HOST_UID="$(id -u)"
unset LD_PRELOAD LD_LIBRARY_PATH DISPLAY WAYLAND_DISPLAY
status=0
timeout --kill-after=5 180 \
    unshare --user --map-current-user --keep-caps --net --mount \
    --mount-proc --pid --fork --kill-child \
    python3 "$channel_dir/tests/ludviglundgren-qbittorrent-cli-smoke.py" "$out" "$evidence" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
test "$before" = "$after" || fail 'installed NAR changed during daemon proof'
test "$status" -eq 0 || fail "native driver failed ($status); see $evidence/driver.stderr"
test -s "$evidence/proof.json" || fail 'driver produced no complete proof'
python3 - "$evidence" "$before" "$after" <<'PY'
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1])
proof = json.loads((root / 'proof.json').read_text())
assert proof['complete'] is True
assert sys.argv[2] == sys.argv[3]
proof['nar'] = {'before': sys.argv[2], 'after': sys.argv[3], 'unchanged': True}
(root / 'proof.json').write_text(json.dumps(proof, indent=2) + '\n')
PY
printf '%s\n' 'native qbt proof: help/version without config; real isolated qBittorrent add/list/category/tag/remove; payload retained; NAR unchanged'
