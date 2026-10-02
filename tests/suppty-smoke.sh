#!/bin/sh
# Original localhost SUPDUP exchange through the real CLI and GTK terminal.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [pdp10-suppty-output]" >&2
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
    output=$(build_output -e '(@ (tay packages suppty) pdp10-suppty)')
fi
case "$output" in
    /gnu/store/*) ;;
    *) echo 'SUPPTY output must be a realized /gnu/store path' >&2; exit 64 ;;
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
iproute_out=$(find_output sbin/ip iproute2)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
xwd_out=$(find_output bin/xwd xwd)
imagemagick_out=$(find_output bin/convert imagemagick)
font_out=$(build_output font-dejavu)
for command in suppty suppty-plink; do test -x "$output/bin/$command"; done
for command in putty puttytel plink pscp psftp pterm puttygen; do
    test ! -e "$output/bin/$command"
done
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'SUPPTY smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/suppty.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
artifacts=${SUPPTY_SMOKE_ARTIFACTS:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/suppty-artifacts.XXXXXX")}
case "$artifacts" in
    /*) ;;
    *) echo 'SUPPTY_SMOKE_ARTIFACTS must be absolute' >&2; exit 64 ;;
esac
"$coreutils_out/bin/mkdir" -p "$artifacts"
before=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
status=0
"$coreutils_out/bin/env" -i LC_ALL=C PATH="$coreutils_out/bin" \
    HOST_USER_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/pid)" \
    "$coreutils_out/bin/timeout" --kill-after=10 180 \
    "$unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" "$channel_dir/tests/suppty-smoke.py" \
    "$output" "$scratch" "$artifacts" "$iproute_out/sbin/ip" \
    "$xorg_out/bin/Xvfb" "$xdotool_out/bin/xdotool" "$xwd_out/bin/xwd" \
    "$imagemagick_out/bin/convert" "$font_out" \
    >"$artifacts/proof.log" 2>&1 || status=$?
after=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
"$coreutils_out/bin/cat" "$artifacts/proof.log"
test "$before" = "$after" || { echo 'SUPPTY output NAR changed' >&2; exit 1; }
if test "$status" -ne 0; then
    echo "SUPPTY smoke failed ($status); retained evidence: $artifacts" >&2
    exit "$status"
fi
printf '%s\n' "SUPPTY offline CLI and live GTK protocol exchange passed; unchanged NAR: $after; evidence: $artifacts"
