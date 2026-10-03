#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# The installed native editor is the only application under test.
set -eu
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
guix_bin=${GUIX:-guix}
package=
artifacts=${GENED_SMOKE_ARTIFACTS:-}
while test "$#" -gt 0; do
    case "$1" in
        --package) package=$2; shift 2 ;;
        --artifacts) artifacts=$2; shift 2 ;;
        --help) echo "usage: $0 [--package STORE] [--artifacts DIR] [STORE]"; exit 0 ;;
        -*) echo "unknown option: $1" >&2; exit 64 ;;
        *) test -z "$package"; package=$1; shift ;;
    esac
done
if test -z "$package"; then
    package=$($guix_bin build -L "$channel_dir/guix" --no-grafts gened)
fi
find_output() {
    program=$1; shift
    for output in $($guix_bin build "$@"); do
        if test -x "$output/$program"; then printf '%s\n' "$output"; return; fi
    done
    return 1
}
python=$(find_output bin/python3 python)
xorg=$(find_output bin/Xvfb xorg-server)
image=$(find_output bin/import imagemagick)
util=$(find_output bin/unshare util-linux)
core=$(find_output bin/timeout coreutils)
xdotool=$(find_output bin/xdotool xdotool)
if test -z "$artifacts"; then artifacts=$(mktemp -d /tmp/gened-artifacts-XXXXXX); fi
mkdir -p "$artifacts"
echo "GenEd native proof artifacts: $artifacts"
exec "$core/bin/timeout" --kill-after=5 600 \
    "$util/bin/unshare" --user --map-root-user --mount --net --ipc \
    --pid --kill-child --fork --mount-proc \
    "$python/bin/python3" "$channel_dir/tests/gened-smoke.py" \
    "$package" "$artifacts" "$xorg/bin/Xvfb" "$image/bin/import" \
    "$util/bin/mount" "$xdotool/bin/xdotool"
