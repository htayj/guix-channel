#!/bin/sh
# SPDX-License-Identifier: MIT
# Invoke in a network-isolated Guix container for the offline proof.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=${1:-$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-offload --cores=1 --max-jobs=1 proiel)}
ruby_out=${RUBY_OUT:-$($guix_bin build --no-grafts --no-offload --cores=1 --max-jobs=1 -e '(@ (gnu packages ruby) ruby)')}
test -s "$out/share/proiel/examples/minimal.xml"
test -s "$out/lib/ruby/vendor_ruby/specifications/proiel-1.3.3.gemspec"

before=$($guix_bin hash -S nar "$out")
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir -p "$scratch/home" "$scratch/config" "$scratch/cache" "$scratch/state" "$scratch/gems"
# Guix profiles expand propagated inputs; store references alone do not.
# This ephemeral profile has only the library's runtime gems and interpreter.
cp "$channel_dir/tests/proiel-smoke.rb" "$scratch/consumer.rb"
"$guix_bin" shell -L "$channel_dir/guix" --no-grafts --no-offload --cores=1 --max-jobs=1 \
    --pure --container --no-cwd \
    --share="$scratch" --expose="$out" \
    -e '(@ (gnu packages ruby) ruby)' \
    proiel bash-minimal coreutils-minimal -- \
    sh -c 'cd "$1"; ruby_gems=$(env -i HOME="$1/home" \
      "$2/bin/ruby" -rrubygems -e "print Gem.default_dir"); \
      exec env -i HOME="$1/home" \
      XDG_CONFIG_HOME="$1/config" XDG_CACHE_HOME="$1/cache" \
      XDG_STATE_HOME="$1/state" GEM_HOME="$1/gems" GEM_PATH="$GEM_PATH:$ruby_gems" \
      PATH="$2/bin" "$2/bin/ruby" "$1/consumer.rb" \
      "$3/share/proiel/examples/minimal.xml"' sh "$scratch" "$ruby_out" "$out"
after=$($guix_bin hash -S nar "$out")
test "$before" = "$after"
printf '%s\n' 'proiel isolated offline parsed-token/sentence/attribute smoke passed; output NAR unchanged'
