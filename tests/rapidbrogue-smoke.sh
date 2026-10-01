#!/bin/sh
# Prove real SDL and terminal save/resume in a private X11/network namespace.
# The game output is already built; only proof tools are resolved through Guix.
set -eu

if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE_DIR (new or empty, outside /gnu/store)" >&2
    exit 64
fi

guix_bin=${GUIX:-guix}
find_output ()
{
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts "$2"); do
        if test -x "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
rapidbrogue_out=$(realpath -e -- "$1")
evidence_dir=$(realpath -m -- "$2")
case "$evidence_dir/" in
    /gnu/store/*|"$rapidbrogue_out/"*)
        echo 'evidence must be outside the store and package output' >&2
        exit 64 ;;
esac
if test -e "$evidence_dir"; then
    test -d "$evidence_dir"
    test -z "$(find "$evidence_dir" -mindepth 1 -maxdepth 1 -print -quit)"
fi
mkdir -p -- "$evidence_dir"

coreutils_out=$(find_output bin/env coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
if test -n "${PYTHON:-}"; then
    python_bin=$(command -v "$PYTHON")
else
    python_out=$(find_output bin/python3 python)
    python_bin=$python_out/bin/python3
fi
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
unshare=$util_linux_out/bin/unshare

if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'rapidbrogue proof requires user, mount, network and PID namespaces' >&2
    exit 77
fi

before=$("$guix_bin" hash -S nar "$rapidbrogue_out")
status=0
"$coreutils_out/bin/env" -i \
    LC_ALL=C PATH="$coreutils_out/bin:$xdotool_out/bin" \
    XVFB="$xorg_out/bin/Xvfb" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    "$coreutils_out/bin/timeout" --kill-after=10 480 \
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$python_bin" "$channel_dir/tests/rapidbrogue-smoke.py" \
    "$rapidbrogue_out" "$evidence_dir" || status=$?
# Retain both hashes even when the interactive proof fails.
after=$("$guix_bin" hash -S nar "$rapidbrogue_out")
printf '%s\n' "$before" > "$evidence_dir/output-before.nar-hash"
printf '%s\n' "$after" > "$evidence_dir/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'package output changed during save/resume proof' >&2
    exit 1
fi
if test "$status" -ne 0; then
    exit "$status"
fi
find "$evidence_dir" -type f -exec chmod a-w -- {} +
printf '%s\n' "RAPIDBROGUE_SAVE_RESUME_OK evidence=$evidence_dir"
