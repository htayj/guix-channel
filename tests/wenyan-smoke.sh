#!/bin/sh
# External native compiler proof; no installed smoke mode or build of Wenyan.
# Usage: sh tests/wenyan-smoke.sh WENYAN-OUTPUT EVIDENCE-DIRECTORY
set -eu
umask 077
fail () { printf '%s\n' "wenyan smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s WENYAN-OUTPUT EVIDENCE-DIRECTORY\n' "$0" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -- "$1")
case "$out" in /gnu/store/*) ;; *) fail 'expected prebuilt store output' ;; esac
test -x "$out/bin/wenyan" || fail 'missing native CLI'
test -f "$out/share/wenyan/examples/factorial.wy" || fail 'missing installed examples'
guix_bin=$(command -v "${GUIX:-guix}")
if test "${WENYAN_PROOF_ENV:-}" != ready; then
    node_out=$("$guix_bin" build --no-grafts -e '(begin (use-modules (gnu packages node)) node-lts)')
    exec "$guix_bin" shell --pure --no-grafts \
        python util-linux coreutils findutils bash-minimal \
        --preserve='^(GUIX|WENYAN_PROOF_ENV)$' -- \
        env GUIX="$guix_bin" WENYAN_PROOF_ENV=ready WENYAN_NODE_OUT="$node_out" \
        sh "$channel_dir/tests/wenyan-smoke.sh" "$out" "$2"
fi
for cmd in python3 timeout unshare mount find; do
    command -v "$cmd" >/dev/null || fail "missing proof dependency: $cmd"
done
test -x "$WENYAN_NODE_OUT/bin/node" || fail 'missing realized Node interpreter'
mkdir -p -- "$2"
evidence=$(realpath -- "$2")
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'evidence directory must be empty'
case "$evidence/" in "$out/"*) fail 'evidence must be outside output' ;; esac
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'writable installed files'
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
export WENYAN_HOST_USER=$(readlink /proc/self/ns/user)
export WENYAN_HOST_NET=$(readlink /proc/self/ns/net)
export WENYAN_HOST_MNT=$(readlink /proc/self/ns/mnt)
export WENYAN_HOST_PID=$(readlink /proc/self/ns/pid)
export WENYAN_HOST_UID=$(id -u)
unset NODE_PATH NODE_OPTIONS LD_PRELOAD
status=0
timeout --kill-after=5 240 \
    unshare --user --map-current-user --keep-caps --net --mount \
    --mount-proc --pid --fork --kill-child \
    python3 "$channel_dir/tests/wenyan-smoke.py" "$out" "$evidence" "$WENYAN_NODE_OUT" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
test "$before" = "$after" || fail 'installed output NAR changed'
test "$status" -eq 0 || fail "native consumer failed ($status); see $evidence/driver.stderr"
test -s "$evidence/proof.json" || fail 'native consumer receipt missing'
printf '%s\n' 'wenyan smoke: bundled hello; separate compile/run; recursive factorial; embedded stdlib; installed API; offline same-UID namespaces; read-only store; NAR unchanged'
