#!/bin/sh
# Consume a built normal Wanderers output, preserving native gameplay proof.
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
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
wanderers_out=$(realpath -e -- "$1")
evidence_dir=$(realpath -m -- "$2")
case "$evidence_dir/" in
    /gnu/store/*|"$wanderers_out/"*)
        echo 'evidence must be outside the store and package output' >&2
        exit 64 ;;
esac
if test -e "$evidence_dir"; then
    test -d "$evidence_dir"
    test -z "$(find "$evidence_dir" -mindepth 1 -maxdepth 1 -print -quit)"
fi
mkdir -p -- "$evidence_dir"
# Realize all dependencies serially before entering the offline namespaces.
coreutils_out=$(find_output bin/env coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
x11_out=$(find_output lib/libX11.so.6 libx11)
before=$("$guix_bin" hash -S nar "$wanderers_out")
status=0
"$coreutils_out/bin/env" -i LC_ALL=C PATH="" \
    XVFB="$xorg_out/bin/Xvfb" MOUNT="$util_linux_out/bin/mount" \
    XDOTOOL="$xdotool_out/bin/xdotool" LIBX11="$x11_out/lib/libX11.so.6" \
    HOST_UID="$("$coreutils_out/bin/id" -u)" \
    HOST_GID="$("$coreutils_out/bin/id" -g)" \
    HOST_USER_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/mnt)" \
    HOST_PID_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/pid)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    PYTHONNOUSERSITE=1 \
    "$coreutils_out/bin/timeout" --kill-after=10 480 \
    "$util_linux_out/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" -s "$channel_dir/tests/wanderers-native.py" \
    "$wanderers_out" "$evidence_dir" || status=$?
after=$("$guix_bin" hash -S nar "$wanderers_out")
printf '%s\n' "$before" > "$evidence_dir/output-before.nar-hash"
printf '%s\n' "$after" > "$evidence_dir/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'package output changed during native gameplay proof' >&2
    exit 1
fi
if test "$status" -ne 0; then
    exit "$status"
fi
find "$evidence_dir" -type f -exec chmod a-w -- {} +
printf '%s\n' "WANDERERS_NATIVE_SAVE_RESTORE_OK evidence=$evidence_dir"
