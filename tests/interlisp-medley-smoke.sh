#!/bin/sh
# External observation of the installed upstream Medley boot image and native REPL.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 2; then
    echo "usage: GUIX=guix $0 [OUTPUT [EVIDENCE]]" >&2
    exit 64
fi
build_output ()
{
    "$guix_bin" build -L "$channel_dir/guix" --no-grafts --no-offload \
        --cores=1 --max-jobs=1 "$@"
}
find_output ()
{
    for candidate in $(build_output "$2"); do
        if test -e "$candidate/$1"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "interlisp-medley smoke: cannot find $1 in $2" >&2
    return 1
}
output=${1:-${OUTPUT:-}}
if test -z "$output"; then
    output=$(build_output -e '(@ (tay packages interlisp-medley) interlisp-medley)')
fi
case "$output" in
    /gnu/store/*) ;;
    *) echo 'OUTPUT must be a realized /gnu/store path' >&2; exit 64 ;;
esac
test -x "$output/bin/medley"
# Realize all observer dependencies before entering the offline namespaces.
coreutils_out=$(find_output bin/mktemp coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
xwd_out=$(find_output bin/xwd xwd)
imagemagick_out=$(find_output bin/convert imagemagick)
unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'interlisp-medley smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/interlisp-medley.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
evidence=${2:-${EVIDENCE:-${INTERLISP_MEDLEY_SMOKE_ARTIFACTS:-}}}
if test -z "$evidence"; then
    evidence=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/interlisp-medley-evidence.XXXXXX")
fi
case "$evidence" in
    /*) ;;
    *) echo 'EVIDENCE must be absolute' >&2; exit 64 ;;
esac
"$coreutils_out/bin/mkdir" -p "$evidence"
before=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$before" >"$evidence/output-nar-before.txt"
status=0
"$coreutils_out/bin/env" -i LC_ALL=C PATH="$coreutils_out/bin" \
    PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$("$coreutils_out/bin/id" -u)" \
    HOST_USER_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/pid)" \
    "$coreutils_out/bin/timeout" --kill-after=10 240 \
    "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --kill-child --fork \
    "$python_out/bin/python3" -B "$channel_dir/tests/interlisp-medley-consumer.py" \
    "$output" "$scratch" "$evidence" "$xorg_out/bin/Xvfb" \
    "$xdotool_out/bin/xdotool" "$xwd_out/bin/xwd" \
    "$imagemagick_out/bin/convert" >"$evidence/proof.log" 2>&1 || status=$?
after=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$after" >"$evidence/output-nar-after.txt"
"$coreutils_out/bin/cat" "$evidence/proof.log"
if test "$before" != "$after"; then
    echo "interlisp-medley output NAR changed; evidence: $evidence" >&2
    exit 1
fi
if test "$status" -ne 0; then
    echo "interlisp-medley native proof failed ($status); evidence: $evidence" >&2
    exit "$status"
fi
printf 'interlisp-medley native REPL, screenshot, saved virtualmem and zero-exit logout passed; unchanged NAR: %s; evidence: %s\n' "$after" "$evidence"
