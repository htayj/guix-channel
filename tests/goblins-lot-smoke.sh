#!/bin/sh
# External installed-output acceptance; never rebuild or instrument the game.
set -eu
umask 077
if test "$#" -ne 1; then
    echo "usage: GOBLINS_LOT_SMOKE_ARTIFACTS=/absolute/fresh/path sh $0 /gnu/store/OUTPUT" >&2
    exit 64
fi
channel=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -e -- "$1")
case "$out" in /gnu/store/*/*) exit 64 ;; /gnu/store/*) ;; *) exit 64 ;; esac
test "$out" = "$1" && test -x "$out/bin/goblins-lot" || exit 64
: "${GOBLINS_LOT_SMOKE_ARTIFACTS:?set a fresh absolute evidence directory}"
evidence=$(realpath -m -- "$GOBLINS_LOT_SMOKE_ARTIFACTS")
case "$evidence" in /gnu/store/*) exit 64 ;; /*) ;; *) exit 64 ;; esac
test "$evidence" = "$GOBLINS_LOT_SMOKE_ARTIFACTS" || exit 64
if test -e "$evidence" || test -L "$evidence"; then
    echo 'evidence directory must not already exist' >&2; exit 64
fi
guix_bin=$(realpath -e -- "${GUIX:-$(command -v guix)}")
mkdir -p -- "$evidence"
find_tool ()
{
    if test -n "${GOBLINS_LOT_SMOKE_TOOLS:-}"; then
        test -x "$GOBLINS_LOT_SMOKE_TOOLS/$1" || return 1
        realpath -e -- "$GOBLINS_LOT_SMOKE_TOOLS/$1"
    else
        outputs=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$2" 2> "$evidence/tool-$2.log") || return 1
        for output in $outputs; do
            if test -x "$output/$1"; then printf '%s\n' "$output/$1"; return 0; fi
        done
        return 1
    fi
}
# Optional GOBLINS_LOT_SMOKE_TOOLS is a Guix profile containing these packages.
core_env=$(find_tool bin/env coreutils)
core=${core_env%/bin/env}
unshare=$(find_tool bin/unshare util-linux)
python=$(find_tool bin/python3 python)
xvfb=$(find_tool bin/Xvfb xorg-server)
xdotool=$(find_tool bin/xdotool xdotool)
xwd=$(find_tool bin/xwd xwd)
convert=$(find_tool bin/convert imagemagick)
uid=$("$core/bin/id" -u)
gid=$("$core/bin/id" -g)
test "$uid" -ne 0 && test "$gid" -ne 0 || { echo 'ordinary non-root UID/GID required' >&2; exit 1; }
"$guix_bin" gc -R "$out" > "$evidence/runtime-closure.txt"
printf '%s\n' "$out" > "$evidence/output.txt"
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$core/bin/env" -i PATH='' LC_ALL=C PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$uid" HOST_GID="$gid" \
    HOST_USER_NS="$("$core/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$core/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$core/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$core/bin/readlink" /proc/self/ns/pid)" \
    "$core/bin/timeout" --kill-after=10 900 \
    "$unshare" --user --map-current-user --keep-caps --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$python" -I -S -B "$channel/tests/goblins-lot-native.py" \
    "$out" "$evidence" "$xvfb" "$xdotool" "$xwd" "$convert" \
    > "$evidence/driver.stdout" 2> "$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
unchanged=false
if test "$before" = "$after"; then unchanged=true; fi
printf '{"driver_status":%s,"nar_unchanged":%s}\n' "$status" "$unchanged" > "$evidence/shell-result.json"
# Keep native HOME/config/font/log/saves and all original XWD/PNG/input evidence,
# including failures. No host process, user state or vault session is cleaned up.
if test "$unchanged" != true; then echo "output NAR changed; evidence=$evidence" >&2; exit 1; fi
if test "$status" -ne 0; then echo "native acceptance failed; evidence=$evidence" >&2; exit "$status"; fi
printf '%s\n' "GOBLINS_LOT_NATIVE_ACCEPTANCE_OK evidence=$evidence"
