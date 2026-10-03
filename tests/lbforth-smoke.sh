#!/bin/sh
# Run native installed-language acceptance; no Goocastle adapters or source tree.
set -eu

if test "$#" -gt 1; then
    echo "usage: $0 [lbforth-output]" >&2
    exit 64
fi
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -eq 1; then
    package_out=$1
else
    guix_bin=${GUIX:-guix}
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        -e '(@ (tay packages lbforth) lbforth)')
fi
exec python3 "$channel_dir/tests/lbforth-smoke.py" "$package_out"
