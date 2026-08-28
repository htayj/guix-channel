#!/bin/sh
# Isolated, non-interactive proof of astx's TypeScript transform loader.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=${1:-$($guix_bin build -L "$channel_dir" --no-grafts astx)}

test -x "$out/bin/astx"
test -s "$out/share/doc/astx/LICENSE.md"
grep -q 'MIT License' "$out/share/doc/astx/LICENSE.md"
test -d "$out/share/doc/astx/node-modules-notices"
test "$(stat -c '%a' "$out")" = 555

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir -p "$scratch/home" "$scratch/xdg/cache" "$scratch/xdg/config" \
  "$scratch/xdg/data" "$scratch/xdg/state"

fixture=$scratch/fixture.ts
transform=$scratch/no-match.cts
printf '%s\n' 'export const value: number = 42' >"$fixture"
printf '%s\n' 'export const find = `definitelyAbsent($value)`' \
  'export const replace = `stillAbsent($value)`' >"$transform"
before=$(sha256sum "$fixture" | awk '{print $1}')

# The transform is local and the proxy settings make accidental network access
# fail locally.  No --yes is supplied: unchanged inputs must never be written.
HOME="$scratch/home" XDG_CACHE_HOME="$scratch/xdg/cache" \
XDG_CONFIG_HOME="$scratch/xdg/config" XDG_DATA_HOME="$scratch/xdg/data" \
XDG_STATE_HOME="$scratch/xdg/state" ASTX_WORKERS=1 \
HTTP_PROXY=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 ALL_PROXY=http://127.0.0.1:9 \
  "$out/bin/astx" --transform "$transform" "$fixture" >"$scratch/stdout" 2>"$scratch/stderr"

after=$(sha256sum "$fixture" | awk '{print $1}')
test "$before" = "$after"
grep -q '1 file unchanged' "$scratch/stderr"
printf '%s\n' 'astx isolated TypeScript no-match smoke passed'
