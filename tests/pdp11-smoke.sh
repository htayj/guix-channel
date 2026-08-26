#!/bin/sh
# Offline smoke test for PDP-11/45's built-in microcode diagnostic.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [pdp11-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    pdp11_out=$1
else
    pdp11_out=$($guix_bin build -L "$channel_dir" --no-grafts pdp11)
fi

find_output ()
{
    program=$1 package=$2
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
util_linux_out=$(find_output bin/unshare util-linux)

for program in pdp1105 pdp1120 pdp1140 pdp1145; do
    test -x "$pdp11_out/bin/$program"
done
test -f "$pdp11_out/share/doc/pdp11-0-5b5b734/LICENSE"

temporary=$($coreutils_out/bin/mktemp -d "${TMPDIR:-/tmp}/pdp11-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$temporary/home" "$temporary/config" \
    "$temporary/data" "$temporary/cache" "$temporary/state" "$temporary/work"

record_manifest ()
{
    "$findutils_out/bin/find" "$pdp11_out" -printf '%P %m %s %T@\n' | \
        "$coreutils_out/bin/sort" >"$1"
    "$findutils_out/bin/find" "$pdp11_out" -type f -exec \
        "$coreutils_out/bin/sha256sum" {} + | "$coreutils_out/bin/sort" >>"$1"
}
record_manifest "$temporary/before"

export PDP11_SMOKE_OUT=$pdp11_out
export PDP11_SMOKE_COREUTILS=$coreutils_out
export PDP11_SMOKE_GREP=$grep_out
export PDP11_SMOKE_WORK=$temporary/work
export HOME=$temporary/home
export XDG_CONFIG_HOME=$temporary/config
export XDG_DATA_HOME=$temporary/data
export XDG_CACHE_HOME=$temporary/cache
export XDG_STATE_HOME=$temporary/state
export LC_ALL=C

"$util_linux_out/bin/unshare" --user --map-root-user --net --fork sh -eu -c '
    cd "$PDP11_SMOKE_WORK"
    "$PDP11_SMOKE_COREUTILS/bin/timeout" 10s "$PDP11_SMOKE_OUT/bin/pdp1145" >diagnostic
    "$PDP11_SMOKE_GREP/bin/grep" -F "T1" diagnostic
    "$PDP11_SMOKE_GREP/bin/grep" -F "T5" diagnostic
    "$PDP11_SMOKE_GREP/bin/grep" -F -- "----------" diagnostic
    test "$(find . -maxdepth 1 -type f | wc -l)" -eq 1
'

record_manifest "$temporary/after"
"$diffutils_out/bin/cmp" "$temporary/before" "$temporary/after"
printf '%s\n' 'pdp11 offline smoke passed: PDP-11/45 built-in diagnostic'
