#!/bin/sh
# Offline smoke test for the PDP-10 GCC code-generation backend.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [pdp10-gcc-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    pdp10_out=$1
else
    pdp10_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes pdp10-gcc)
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
coreutils_out=$(find_output bin/coreutils coreutils)
diffutils_out=$(find_output bin/cmp diffutils)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
util_linux_out=$(find_output bin/unshare util-linux)

target=pdp10-unknown-tops20
compiler=$pdp10_out/bin/$target-gcc
preprocessor=$pdp10_out/bin/$target-cpp
license_dir=$pdp10_out/share/doc/pdp10-gcc-3.2-20020416

test -x "$compiler"
test -x "$preprocessor"
test -x "$pdp10_out/lib/gcc-lib/$target/3.2/cc1"
test ! -e "$pdp10_out/bin/$target-as"
test ! -e "$pdp10_out/bin/$target-ld"
if "$findutils_out/bin/find" "$pdp10_out" -type f \
    \( -name 'libgcc*.a' -o -name 'libgcc*.o' \) -print |
    "$grep_out/bin/grep" -q .; then
    echo "pdp10-gcc unexpectedly installed target libgcc material" >&2
    exit 1
fi
for notice in COPYING COPYING.LIB README LICENSE zlib.h LIBGCJ_LICENSE; do
    test -f "$license_dir/$notice"
done
"$grep_out/bin/grep" -F "GNU GENERAL PUBLIC LICENSE" "$license_dir/COPYING"
"$grep_out/bin/grep" -F "GNU LESSER GENERAL PUBLIC LICENSE" "$license_dir/COPYING.LIB"
"$grep_out/bin/grep" -F "Permission is hereby granted to use or copy" \
    "$license_dir/README"
"$grep_out/bin/grep" -F "Cygnus Solutions" "$license_dir/LICENSE"
"$grep_out/bin/grep" -F "Permission is granted to anyone" "$license_dir/zlib.h"
"$grep_out/bin/grep" -F "special exception" "$license_dir/LIBGCJ_LICENSE"

temporary=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/pdp10-gcc-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$temporary/home" "$temporary/config" \
    "$temporary/data" "$temporary/cache" "$temporary/state" "$temporary/work" \
    "$temporary/work/host-tools"

# Record store contents before execution.  A package output must never change
# while a compiler is running, even if its old driver has an unexpected path.
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
record_manifest "$pdp10_out" "$manifest_before"

export PDP10_GCC_SMOKE_COMPILER=$compiler
export PDP10_GCC_SMOKE_PREPROCESSOR=$preprocessor
export PDP10_GCC_SMOKE_COREUTILS=$coreutils_out
export PDP10_GCC_SMOKE_BASH=$bash_out/bin/bash
export PDP10_GCC_SMOKE_DIFFUTILS=$diffutils_out
export PDP10_GCC_SMOKE_GREP=$grep_out
export PDP10_GCC_SMOKE_WORK=$temporary/work
export HOME=$temporary/home
export XDG_CONFIG_HOME=$temporary/config
export XDG_DATA_HOME=$temporary/data
export XDG_CACHE_HOME=$temporary/cache
export XDG_STATE_HOME=$temporary/state
export LC_ALL=C

# No guest runtime or target binutils are packaged.  A network namespace and a
# package-only PATH make the -S proof isolated and ensure a -c attempt cannot
# silently discover a host assembler or linker.
"$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$bash_out/bin/bash" -eu -c '
      cd "$PDP10_GCC_SMOKE_WORK"
      export PATH=/nonexistent
      "$PDP10_GCC_SMOKE_COREUTILS/bin/printf" "%s\n" \
        "int add(int a,int b){return a+b;}" >add.c
      "$PDP10_GCC_SMOKE_PREPROCESSOR" -P add.c add.i
      "$PDP10_GCC_SMOKE_GREP/bin/grep" -F "int add" add.i

      # These deliberately successful fake host tools detect an unsafe
      # fallback: a compiler without the package wrapper would find them in
      # PATH during -c or linking.
      "$PDP10_GCC_SMOKE_COREUTILS/bin/printf" '#!%s\n: > "$PDP10_GCC_SMOKE_WORK/as-used"\nexit 0\n' \
        "$PDP10_GCC_SMOKE_BASH" >host-tools/as
      "$PDP10_GCC_SMOKE_COREUTILS/bin/printf" '#!%s\n: > "$PDP10_GCC_SMOKE_WORK/ld-used"\nexit 0\n' \
        "$PDP10_GCC_SMOKE_BASH" >host-tools/ld
      "$PDP10_GCC_SMOKE_COREUTILS/bin/chmod" 755 host-tools/as host-tools/ld

      "$PDP10_GCC_SMOKE_COMPILER" -S -O0 -ffreestanding add.c -o add.s
      test -s add.s
      "$PDP10_GCC_SMOKE_GREP/bin/grep" -E "MOVE|ADD|POPJ" add.s
      export PATH="$PDP10_GCC_SMOKE_WORK/host-tools"
      if "$PDP10_GCC_SMOKE_COMPILER" -c add.c -o add.o \
          >assemble.stdout 2>assemble.stderr; then
        echo "pdp10-gcc unexpectedly assembled with an unavailable target assembler" >&2
        exit 1
      fi
      test ! -e add.o
      test ! -e as-used
      if "$PDP10_GCC_SMOKE_COMPILER" add.c -o add \
          >link.stdout 2>link.stderr; then
        echo "pdp10-gcc unexpectedly linked with unavailable target tools" >&2
        exit 1
      fi
      test ! -e add
      test ! -e ld-used
    '

record_manifest "$pdp10_out" "$manifest_after"
"$diffutils_out/bin/cmp" "$manifest_before" "$manifest_after"

printf '%s\n' "pdp10-gcc offline smoke passed: PDP-10 assembly, notices, and no target tool fallback"
