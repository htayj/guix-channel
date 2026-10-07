#!/bin/sh
# Consume a prebuilt ordinary Aquarium Arena SDL output, never rebuild it.
# Strict external OUTPUT EVIDENCE GUIX consumer following the established
# atlas-warriors native pattern: tool closures are realized first, then the
# native pygame proof runs inside a same-UID user/mount/net/PID namespace
# with the store recursively remounted read-only.  The package output NAR
# hash must be unchanged afterwards.
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
aquarium_out=$(realpath -e -- "$1")
if test "$aquarium_out" != "$1"; then
    echo 'OUTPUT must be a canonical direct store item' >&2
    exit 64
fi
case "$aquarium_out" in
    /gnu/store/*) test "$(dirname -- "$aquarium_out")" = /gnu/store ;;
    *) echo 'OUTPUT must be a canonical direct store item' >&2; exit 64 ;;
esac
test -x "$aquarium_out/bin/aquarium-arena"
test -f "$aquarium_out/share/aquarium-arena/AquariumArena.py"
evidence_dir=$(realpath -m -- "$2")
case "$evidence_dir/" in
    /gnu/store/*) echo 'evidence must be outside /gnu/store' >&2; exit 64 ;;
esac
if test -e "$evidence_dir"; then
    test -d "$evidence_dir"
    test -z "$(find "$evidence_dir" -mindepth 1 -maxdepth 1 -print -quit)"
fi
mkdir -p -- "$evidence_dir"
# Realize tool closures before entering offline namespaces; honor GUIX throughout.
coreutils_out=$(find_output bin/env coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
x11_out=$(find_output lib/libX11.so.6 libx11)
before=$("$guix_bin" hash -S nar "$aquarium_out")
printf '%s\n' "$before" > "$evidence_dir/output-before.nar-hash"
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
    PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 PYGAME_HIDE_SUPPORT_PROMPT=1 \
    "$coreutils_out/bin/timeout" --kill-after=15 300 \
    "$util_linux_out/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" -s "$channel_dir/tests/aquarium-arena-native.py" \
    "$aquarium_out" "$evidence_dir" || status=$?
after=$("$guix_bin" hash -S nar "$aquarium_out")
printf '%s\n' "$after" > "$evidence_dir/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'package output changed during native gameplay proof' >&2
    exit 1
fi
if test "$status" -ne 0; then
    exit "$status"
fi
find "$evidence_dir" -type f -exec chmod a-w -- {} +
printf '%s\n' "AQUARIUM_ARENA_NATIVE_GAMEPLAY_OK evidence=$evidence_dir"
