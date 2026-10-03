#!/bin/sh
# Compile and execute a consumer of the installed Scala-style TypeScript APIs.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=${1:-$($guix_bin build -L "$channel_dir/guix" --no-grafts scala-ts)}
node_out=${NODE_OUT:-$($guix_bin build -L "$channel_dir/guix" --no-grafts \
  -e '(begin (use-modules (gnu packages node)) node-lts)')}
typescript_source=${TYPESCRIPT_SOURCE:-$($guix_bin build -L "$channel_dir/guix" \
  --no-grafts -e '(begin (use-modules (tay packages scala-ts-npm-sources)) (assoc-ref %scala-ts-npm-sources "typescript@4.2.4"))')}
module=$out/lib/node_modules/scala-ts

before=$($guix_bin hash -S nar "$out")
scratch=$(mktemp -d)
cleanup() {
  rm -rf "$scratch"
}
trap cleanup EXIT INT TERM
mkdir -p "$scratch/home" "$scratch/config" "$scratch/cache" "$scratch/state" \
  "$scratch/compiler" "$scratch/node_modules"
tar xzf "$typescript_source" -C "$scratch/compiler" --strip-components=1
ln -s "$module" "$scratch/node_modules/scala-ts"

cat >"$scratch/consumer.ts" <<'EOF'
import { Option, Either, Try } from 'scala-ts';

export function summarize(values: Array<number | undefined>) {
  // Option lifts absent values into empty immutable collections.  Filtering,
  // mapping, concatenating and deduplication use the installed peer library.
  const scores = values.reduce((result, value) => result.concat(
    Option.Option(value).filter(score => score > 0)
      .map(score => score * 2).toList()),
    Option.OptionEmpty<number>().toList());
  const total = scores.reduce((sum, score) => sum + score, 0);
  const verdict: Either.Either<string, number> = total > 0
    ? Either.Right<number, string>(total)
    : Either.Left<string, number>('no positive scores');
  return {
    scores: scores.toArray(),
    unique: scores.toSet().toArray(),
    total,
    verdict: verdict.fold(error => error, value => String(value)),
    first: Option.Option(scores.first()).getOrElse(() => 99)
  };
}

export function parseScore(text: string) {
  const parsed: Try.Try<number> = Try.Try(() => {
    const value: unknown = JSON.parse(text);
    if (typeof value !== 'number') throw new Error('not a number');
    return value;
  });
  return {
    failed: parsed.isFailure,
    score: parsed.map(value => value * 2).getOrElse(() => -1),
    recovered: parsed.recover(() => 0).get(),
    optional: parsed.toOption().toArray()
  };
}
EOF

cat >"$scratch/consumer.js" <<'EOF'
const assert = require('assert');
const consumer = require('./generated/consumer');

const report = {
  populated: consumer.summarize([7, undefined, -2, 12, 7, 0]),
  empty: consumer.summarize([undefined, -1, 0]),
  parsed: consumer.parseScore('7'),
  malformed: consumer.parseScore('not json'),
  wrongType: consumer.parseScore('"seven"')
};
assert.deepStrictEqual(report, {
  populated: {
    scores: [14, 24, 14], unique: [14, 24], total: 52,
    verdict: '52', first: 14
  },
  empty: {
    scores: [], unique: [], total: 0,
    verdict: 'no positive scores', first: 99
  },
  parsed: {failed: false, score: 14, recovered: 7, optional: [7]},
  malformed: {failed: true, score: -1, recovered: 0, optional: []},
  wrongType: {failed: true, score: -1, recovered: 0, optional: []}
});
console.log(JSON.stringify(report, null, 2));
EOF

# Normal package imports resolve through a scratch node_modules symlink, not a
# source checkout or an injected runtime probe.  No npm resolution is involved.
export HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
  XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state"
unset NODE_PATH NODE_OPTIONS
"${NODE:-$node_out/bin/node}" "$scratch/compiler/bin/tsc" \
  --strict --noEmitOnError --module commonjs --moduleResolution node \
  --target es2017 --outDir "$scratch/generated" "$scratch/consumer.ts"
"${NODE:-$node_out/bin/node}" "$scratch/consumer.js"

after=$($guix_bin hash -S nar "$out")
test "$before" = "$after"
printf '%s\n' 'scala-ts compiled installed-consumer smoke passed; store unchanged'
