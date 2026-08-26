#!/bin/sh
# Offline smoke test for the local PDP-10 ITS DUMP tape-image tool.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [itstar-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    itstar_out=$1
else
    itstar_out=$($guix_bin build -L "$channel_dir" --no-grafts itstar)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build --no-grafts "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

coreutils_out=$(find_output bin/mktemp coreutils)
diffutils_out=$(find_output bin/cmp diffutils)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
gzip_out=$(find_output bin/gzip gzip)
util_linux_out=$(find_output bin/unshare util-linux)

test -x "$itstar_out/bin/itstar"
doc=$itstar_out/share/doc/itstar-1.10-0.b709cd8
for file in README itstar.doc COPYING 'Relicensing Permission.txt'; do
    test -f "$doc/$file"
done
"$grep_out/bin/grep" -F 'GNU GENERAL PUBLIC LICENSE' "$doc/COPYING"
"$itstar_out/bin/itstar" -h 2>&1 | "$grep_out/bin/grep" -F 'GPLv3+'

temporary=$($coreutils_out/bin/mktemp -d "${TMPDIR:-/tmp}/itstar-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$temporary/home" "$temporary/config" \
    "$temporary/data" "$temporary/cache" "$temporary/state" "$temporary/work"

record_manifest ()
{
    "$findutils_out/bin/find" "$itstar_out" -printf '%P %m %s %T@\n' | \
        "$coreutils_out/bin/sort" >"$1"
    "$findutils_out/bin/find" "$itstar_out" -type f -exec \
        "$coreutils_out/bin/sha256sum" {} + | "$coreutils_out/bin/sort" >>"$1"
}
record_manifest "$temporary/before"

export ITSTAR_SMOKE_OUT=$itstar_out
export ITSTAR_SMOKE_COREUTILS=$coreutils_out
export ITSTAR_SMOKE_DIFFUTILS=$diffutils_out
export ITSTAR_SMOKE_GREP=$grep_out
export ITSTAR_SMOKE_GZIP=$gzip_out
export ITSTAR_SMOKE_WORK=$temporary/work
export HOME=$temporary/home
export XDG_CONFIG_HOME=$temporary/config
export XDG_DATA_HOME=$temporary/data
export XDG_CACHE_HOME=$temporary/cache
export XDG_STATE_HOME=$temporary/state
export LC_ALL=C

# The package works exclusively on local tape-image paths; no network device
# is available while proving create, list, compressed input, and extraction.
"$util_linux_out/bin/unshare" --user --map-root-user --net --fork sh -eu -c '
    cd "$ITSTAR_SMOKE_WORK"
    mkdir source extracted
    printf "Guix itstar smoke\\n" >expected
    cp expected source/hello.txt
    "$ITSTAR_SMOKE_GZIP/bin/gzip" -c source/hello.txt >source/hello.txt.Z
    rm source/hello.txt
    "$ITSTAR_SMOKE_OUT/bin/itstar" -c -f dump.tap source/hello.txt.Z
    "$ITSTAR_SMOKE_OUT/bin/itstar" -t -f dump.tap >listing
    "$ITSTAR_SMOKE_GREP/bin/grep" -F "SOURCE;HELLO TXT" listing
    "$ITSTAR_SMOKE_OUT/bin/itstar" -x -C extracted -f dump.tap
    "$ITSTAR_SMOKE_DIFFUTILS/bin/cmp" expected extracted/source/hello.txt
    if "$ITSTAR_SMOKE_OUT/bin/itstar" -t -f host:/dev/nst0 >remote.out 2>remote.err; then
        echo "itstar unexpectedly accepted remote rmt tape access" >&2
        exit 1
    fi
    "$ITSTAR_SMOKE_GREP/bin/grep" -F "unsupported" remote.err
'

record_manifest "$temporary/after"
"$diffutils_out/bin/cmp" "$temporary/before" "$temporary/after"
printf '%s\n' 'itstar offline smoke passed: compressed local DUMP round trip'
