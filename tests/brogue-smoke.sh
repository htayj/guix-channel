#!/bin/sh
# Consume an already-built Brogue output; retain normal native save/restore proof.
# No game build, installed test mode, Goocastle executor, or root UID mapping.
set -eu

if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE_DIR (new or empty, outside /gnu/store)" >&2
    exit 64
fi

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
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
brogue_out=$(realpath -e -- "$1")
evidence_dir=$(realpath -m -- "$2")
case "$evidence_dir/" in
    /gnu/store/*|"$brogue_out/"*)
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
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
mount=$util_linux_out/bin/mount
pyte_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts python-pyte)
wcwidth_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts python-wcwidth)
python_path=
for dependency in "$pyte_out" "$wcwidth_out"; do
    for site in "$dependency"/lib/python*/site-packages; do
        test -d "$site"
        python_path=${python_path:+$python_path:}$site
    done
done
unshare=$util_linux_out/bin/unshare

before=$("$guix_bin" hash -S nar "$brogue_out")
status=0
"$coreutils_out/bin/env" -i \
    LC_ALL=C PATH="$coreutils_out/bin:$xdotool_out/bin" \
    XVFB="$xorg_out/bin/Xvfb" MOUNT="$mount" \
    HOST_UID="$("$coreutils_out/bin/id" -u)" \
    HOST_GID="$("$coreutils_out/bin/id" -g)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    PYTHONPATH="$python_path" PYTHONNOUSERSITE=1 \
    "$coreutils_out/bin/timeout" --kill-after=10 480 \
    "$unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" -s "$channel_dir/tests/brogue-smoke.py" \
    "$brogue_out" "$evidence_dir" || status=$?
# Hash the output even on native failures; preserve diagnostics without fallback.
after=$("$guix_bin" hash -S nar "$brogue_out")
printf '%s\n' "$before" > "$evidence_dir/output-before.nar-hash"
printf '%s\n' "$after" > "$evidence_dir/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'package output changed during native save/restore proof' >&2
    exit 1
fi
if test "$status" -ne 0; then
    exit "$status"
fi
find "$evidence_dir" -type f -exec chmod a-w -- {} +
printf '%s\n' "BROGUE_NATIVE_SAVE_RESTORE_OK evidence=$evidence_dir"
