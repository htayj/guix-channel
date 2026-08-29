#!/bin/sh
# Isolated installed-library proof for scala-ts.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=${1:-$($guix_bin build -L "$channel_dir" --no-grafts scala-ts)}
node_out=${NODE_OUT:-$($guix_bin build -L "$channel_dir" --no-grafts node-lts)}
module=$out/lib/node_modules/scala-ts

test -s "$module/dist/scala-ts.js"
test -s "$module/dist/scala-ts.d.ts"
test -s "$module/legacy/scala-ts.umd.js"
test -s "$module/LICENSE"
test -s "$module/README.md"
test -s "$module/node_modules/immutable/LICENSE"
grep -q 'Apache License' "$module/LICENSE"
grep -q 'MIT License' "$module/node_modules/immutable/LICENSE"
grep -q '"main": "legacy/scala-ts.umd.js"' "$module/package.json"
grep -q '"types": "dist/scala-ts.d.ts"' "$module/package.json"
grep -q '"version": "4.0.0-rc.12"' "$module/node_modules/immutable/package.json"

before=$($guix_bin hash -S nar "$out")
scratch=$(mktemp -d)
cleanup() {
  rm -rf "$scratch"
}
trap cleanup EXIT INT TERM
mkdir -p "$scratch/home" "$scratch/config" "$scratch/cache" "$scratch/state"

cat >"$scratch/smoke.js" <<'EOF'
const assert = require('assert');
const scala = require(process.env.SCALA_TS_MODULE);
const immutable = require(process.env.SCALA_TS_MODULE + '/node_modules/immutable');

const option = scala.Option.Option(7).map(x => x + 5);
assert.deepStrictEqual(option.toList().toArray(), [12]);
assert.deepStrictEqual(option.toSet().toArray(), [12]);
assert.deepStrictEqual(scala.Either.Right(3).map(x => x * 4).toArray(), [12]);
assert.strictEqual(scala.Try.Try(() => 7).map(x => x + 5).get(), 12);
assert.strictEqual(immutable.List.of(1, 2, 3).size, 3);
EOF

# The module and its runtime dependency are store paths; this process writes
# only to the newly-created XDG state tree and makes no network request.
HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
SCALA_TS_MODULE="$module" \
  "${NODE:-$node_out/bin/node}" "$scratch/smoke.js"

after=$($guix_bin hash -S nar "$out")
test "$before" = "$after"
printf '%s\n' 'scala-ts isolated Option/Either/Try/immutable smoke passed'
