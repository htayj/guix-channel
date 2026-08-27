#!/bin/sh
# Isolated installed-library proof for react-blessed.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=${1:-$($guix_bin build -L "$channel_dir" --no-grafts react-blessed)}
node_out=${NODE_OUT:-$($guix_bin build -L "$channel_dir" --no-grafts node)}
# util-linux has lib, out, and static outputs; script is in the unsuffixed out.
util_linux=${UTIL_LINUX:-$($guix_bin build -L "$channel_dir" --no-grafts util-linux \
  | grep -E -- '-util-linux-[0-9.]+$')}
module=$out/lib/node_modules/react-blessed

test -s "$module/dist/index.js"
test -s "$module/dist/index.es.js"
test -s "$out/share/doc/react-blessed/LICENSE.txt"
test -s "$out/share/doc/react-blessed/README.md"
grep -q 'Permission is hereby granted' "$out/share/doc/react-blessed/LICENSE.txt"
grep -q 'MIT' "$module/package.json"
grep -q 'SIL Open Font License' "$module/node_modules/blessed/usr/fonts/LICENSE"
! grep -q 'react-devtools-core' "$module/package.json"
test ! -e "$module/node_modules/react-devtools-core"
test -d "$module/node_modules/react-reconciler"
test -d "$module/node_modules/react"
test -d "$module/node_modules/blessed"

before=$($guix_bin hash -S nar "$out")
scratch=$(mktemp -d)
cleanup() {
  rm -rf "$scratch"
}
trap cleanup EXIT INT TERM
mkdir -p "$scratch/home" "$scratch/state" "$scratch/cache"

cat >"$scratch/smoke.js" <<'EOF'
const React = require('react');
const blessed = require('blessed');
const {render} = require('react-blessed');

const screen = blessed.screen({smartCSR: false});
render(React.createElement('box', {
  width: 20,
  height: 3,
  content: 'react-blessed-guix-smoke'
}), screen, () => setTimeout(() => screen.destroy(), 50));
EOF

HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
TERM=xterm-256color NODE_PATH="$out/lib/node_modules:$module/node_modules" \
  "$util_linux/bin/script" -q -e -c "${NODE:-$node_out/bin/node} '$scratch/smoke.js'" /dev/null >"$scratch/pty.out" 2>&1

# Blessed's output is ANSI-heavy; the marker itself must reach the PTY.
tr -d '\r' <"$scratch/pty.out" | grep -q 'react-blessed-guix-smoke'
after=$($guix_bin hash -S nar "$out")
test "$before" = "$after"
printf '%s\n' 'react-blessed isolated React/Fiber/Blessed smoke passed'
