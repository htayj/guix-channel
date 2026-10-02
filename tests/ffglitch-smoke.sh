#!/bin/sh
# Real native bitstream editing, independent decoding and live SDL preview.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [ffglitch-output]" >&2
    exit 64
fi
build_output ()
{
    "$guix_bin" build -L "$channel_dir/guix" --no-grafts --no-offload \
        --cores=1 --max-jobs=1 "$@"
}
if test "$#" -eq 1; then
    output=$1
else
    output=$(build_output ffglitch)
fi
case "$output" in
    /gnu/store/*) ;;
    *) echo 'ffglitch output must be a realized /gnu/store path' >&2; exit 64 ;;
esac
find_output ()
{
    for candidate in $(build_output "$2"); do
        if test -x "$candidate/$1"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
coreutils_out=$(find_output bin/mktemp coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
ffmpeg_out=$(find_output bin/ffmpeg ffmpeg)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
xwd_out=$(find_output bin/xwd xwd)
imagemagick_out=$(find_output bin/convert imagemagick)
for tool in bin/ffgac bin/ffedit bin/fflive bin/ffglitch-ffprobe libexec/ffglitch/qjs; do
    test -x "$output/$tool" || { echo "missing $output/$tool" >&2; exit 1; }
done
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'ffglitch smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/ffglitch.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp"
"$coreutils_out/bin/chmod" 700 "$scratch/runtime"
artifacts=${FFGLITCH_SMOKE_ARTIFACTS:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/ffglitch-artifacts.XXXXXX")}
case "$artifacts" in
    /*) ;;
    *) echo 'FFGLITCH_SMOKE_ARTIFACTS must be absolute' >&2; exit 64 ;;
esac
"$coreutils_out/bin/mkdir" -p "$artifacts"
before=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
status=0
"$coreutils_out/bin/env" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" LC_ALL=C PATH="$coreutils_out/bin" \
    HOST_USER_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/pid)" \
    "$coreutils_out/bin/timeout" --kill-after=10 240 \
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" "$channel_dir/tests/ffglitch-smoke.py" \
    "$output" "$scratch" "$artifacts" "$ffmpeg_out/bin/ffmpeg" \
    "$ffmpeg_out/bin/ffprobe" "$xorg_out/bin/Xvfb" \
    "$xdotool_out/bin/xdotool" "$xwd_out/bin/xwd" \
    "$imagemagick_out/bin/convert" >"$artifacts/proof.log" 2>&1 || status=$?
after=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
"$coreutils_out/bin/cat" "$artifacts/proof.log"
test "$before" = "$after" || { echo 'ffglitch output NAR changed' >&2; exit 1; }
if test "$status" -ne 0; then
    echo "ffglitch smoke failed ($status); retained evidence: $artifacts" >&2
    exit "$status"
fi
printf '%s\n' "FFglitch isolated native editing and live preview passed; evidence: $artifacts"
