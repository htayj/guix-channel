#!/bin/sh
# Separate external upstream benchmark; the installed GUI default is unchanged.
set -eu
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
export LAMBDAHACK_CONSUMER_MODE=benchmark
if test -n "${LAMBDAHACK_BENCHMARK_ARTIFACTS:-}"; then
    export LAMBDAHACK_SMOKE_ARTIFACTS=$LAMBDAHACK_BENCHMARK_ARTIFACTS
fi
exec sh "$channel_dir/tests/lambdahack-smoke.sh" "$@"
