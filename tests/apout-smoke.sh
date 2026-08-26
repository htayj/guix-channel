#!/bin/sh
# Offline smoke test for a locally generated V7 PDP-11 echo a.out fixture.
# The fixture is generated from documented PDP-11 instructions so the package
# proof has no dependency on redistribution-restricted historical binaries.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [apout-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    apout_out=$1
else
    apout_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes apout)
fi

find_output ()
{
    program=$1
    package=$2
    for candidate in $($guix_bin build --no-grafts --no-substitutes "$package"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

bash_out=$(find_output bin/bash bash)
coreutils_out=$(find_output bin/sha256sum coreutils)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
diffutils_out=$(find_output bin/cmp diffutils)
util_linux_out=$(find_output bin/unshare util-linux)

test -x "$apout_out/bin/apout"
test -f "$apout_out/share/man/man1/apout.1.zst"
for document in README CHANGES LIMITATIONS TODO LICENSE COPYRIGHT; do
    test -f "$apout_out/share/doc/apout-0-bd9af21/$document"
done
"$grep_out/bin/grep" -F "GNU GENERAL PUBLIC LICENSE" \
    "$apout_out/share/doc/apout-0-bd9af21/LICENSE"
"$grep_out/bin/grep" -F "Warren Toomey" \
    "$apout_out/share/doc/apout-0-bd9af21/COPYRIGHT"
"$grep_out/bin/grep" -F "Eric A. Edwards" \
    "$apout_out/share/doc/apout-0-bd9af21/COPYRIGHT"

temporary=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/apout-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$temporary/home" "$temporary/config" \
    "$temporary/data" "$temporary/cache" "$temporary/state" \
    "$temporary/work" "$temporary/root"
# PDP-11 a.out header followed by a V7 program that writes A P O U T _ S M O K E
# and a newline to stdout, then exits.  The header and instructions are emitted
# little-endian, as required by the package-supported PDP-11 target.
"$coreutils_out/bin/printf" \
    '\007\001\030\000\014\000\000\000\000\000\000\000\000\000\000\000\100\003\001\000\101\003\030\000\102\003\014\000\004\021\030\000\014\000\100\003\000\000\001\021APOUT_SMOKE\n' \
    >"$temporary/work/v7-echo"

# Record package contents and metadata before execution.  The store output is
# immutable; this catches accidental writes if that invariant is ever broken.
manifest_before=$temporary/manifest-before
manifest_after=$temporary/manifest-after
record_manifest ()
{
    output=$1
    manifest=$2
    "$findutils_out/bin/find" "$output" -printf '%P %m %s %T@\n' | \
        "$coreutils_out/bin/sort" >"$manifest"
    "$findutils_out/bin/find" "$output" -type f \
        -exec "$coreutils_out/bin/sha256sum" {} + | \
        "$coreutils_out/bin/sort" >>"$manifest"
}
record_manifest "$apout_out" "$manifest_before"

# A V7 echo a.out needs no guest executable lookup: it is loaded from the
# supplied fixture and performs a native write(2).  The expected transcript is
# fixed so a cleared fixture cannot turn this into an arbitrary host command.
export APOUT_SMOKE_APOUT=$apout_out/bin/apout
export APOUT_SMOKE_FIXTURE=v7-echo
export APOUT_SMOKE_COREUTILS=$coreutils_out
export APOUT_SMOKE_GREP=$grep_out
export APOUT_SMOKE_DIFFUTILS=$diffutils_out
export APOUT_SMOKE_WORK=$temporary/work
export APOUT_SMOKE_ROOT=$temporary/root
export HOME=$temporary/home
export XDG_CONFIG_HOME=$temporary/config
export XDG_DATA_HOME=$temporary/data
export XDG_CACHE_HOME=$temporary/cache
export XDG_STATE_HOME=$temporary/state
export LC_ALL=C

"$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$bash_out/bin/bash" -eu -c '
      cd "$APOUT_SMOKE_WORK"
      export APOUT_ROOT="$APOUT_SMOKE_ROOT"
      export APOUT_UNIX_VERSION=V7
      "$APOUT_SMOKE_APOUT" "$APOUT_SMOKE_FIXTURE" APOUT_SMOKE >actual 2>stderr
      "$APOUT_SMOKE_COREUTILS/bin/printf" "APOUT_SMOKE\\n" >expected
      "$APOUT_SMOKE_DIFFUTILS/bin/cmp" expected actual
      if "$APOUT_SMOKE_COREUTILS/bin/env" -u APOUT_ROOT \
          "$APOUT_SMOKE_APOUT" "$APOUT_SMOKE_FIXTURE" \
          >no-root.stdout 2>no-root.stderr; then
        echo "apout unexpectedly accepted an unset APOUT_ROOT" >&2
        exit 1
      fi
      "$APOUT_SMOKE_GREP/bin/grep" -F \
        "APOUT_ROOT env variable not set before running apout" no-root.stderr
    '

record_manifest "$apout_out" "$manifest_after"
"$diffutils_out/bin/cmp" "$manifest_before" "$manifest_after"

printf '%s\n' "apout offline smoke passed: V7 echo, APOUT_ROOT contract, and GPL notices"
