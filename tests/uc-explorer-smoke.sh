#!/bin/sh
set -eu
guix_bin=${GUIX:-guix}; channel=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=${1:-$($guix_bin build -L "$channel" --no-grafts --no-substitutes uc-explorer)}
util=$($guix_bin build util-linux | sed -n '2p')
test -x "$out/bin/uc-explorer"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
printf '\001\005\002\001\000\003\000\004\000\000\005\000\000\006\000\000\007\000\000\000\000\000\000\010' >"$work/minimal.uc"
"$util/bin/unshare" --user --map-root-user --net --fork sh -c 'HOME="$1/home" XDG_CONFIG_HOME="$1/config" XDG_CACHE_HOME="$1/cache" XDG_DATA_HOME="$1/data" "$2/bin/uc-explorer" "$1/minimal.uc"' sh "$work" "$out" >"$work/output"
grep -F 'valid ucode' "$work/output"; grep -F 'version=0x0001' "$work/output"
for s in 'a-mem length=0' 'b-mem length=0' 'c-mem length=0' 'type-map length=0' 'pico-store length=0'; do grep -F "$s" "$work/output"; done
echo 'uc-explorer offline smoke passed'
