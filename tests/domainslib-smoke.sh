#!/bin/sh
# Compile an external native consumer against the installed Domainslib library.
set -eu

guix_tool=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
manifest=$channel_dir/tests/domainslib-manifest.scm
consumer=$channel_dir/tests/domainslib-consumer.ml

if test "$#" -gt 1; then
    echo "usage: $0 [prebuilt-domainslib-store-output]" >&2
    exit 2
fi
if test "$#" -eq 1; then
    domainslib_out=$1
else
    domainslib_out=$("$guix_tool" build -L "$channel_dir/guix" --no-grafts --check domainslib)
fi
case "$domainslib_out" in
    /gnu/store/*) test -d "$domainslib_out" ;;
    *) echo "expected a Domainslib store output: $domainslib_out" >&2; exit 2 ;;
esac

# Warm the profile outside the network-isolated container; no host profile is used.
"$guix_tool" shell -L "$channel_dir/guix" --no-grafts --rebuild-cache \
    --pure -m "$manifest" -- true

reject_writable_files () {
    if find "$domainslib_out" -type f -perm /222 -print -quit | grep . >/dev/null; then
        echo "Domainslib output contains writable store files" >&2
        return 1
    fi
}
reject_writable_files
before=$("$guix_tool" hash -x --serializer=nar "$domainslib_out")

# --container creates a fresh network namespace unless --network is requested.
# --no-cwd excludes the checkout; expose only the consumer, never host profiles.
status=0
"$guix_tool" shell -L "$channel_dir/guix" --no-grafts --rebuild-cache \
    --container --pure --no-cwd --user=domainslib-smoke -m "$manifest" \
    --expose="$consumer=/consumer.ml" -- /bin/sh -c '
set -eu
profile=$GUIX_ENVIRONMENT
exec "$profile/bin/env" -i \
    PATH="$profile/bin" GUIX_ENVIRONMENT="$profile" \
    OCAMLPATH="$profile/lib/ocaml/site-lib" \
    C_INCLUDE_PATH="$profile/include" LIBRARY_PATH="$profile/lib" \
    LC_ALL=C HOME=/home/domainslib-smoke USER=domainslib-smoke LOGNAME=domainslib-smoke \
    /bin/sh -c '\''
set -eu
umask 077
work=$(mktemp -d /tmp/domainslib-consumer.XXXXXX)
export HOME=$work/home
export XDG_CONFIG_HOME=$work/xdg/config
export XDG_CACHE_HOME=$work/xdg/cache
export XDG_DATA_HOME=$work/xdg/data
export XDG_STATE_HOME=$work/xdg/state
export XDG_RUNTIME_DIR=$work/xdg/runtime
export TMPDIR=$work/tmp
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" \
    "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR" "$TMPDIR" "$work/build"
cd "$work/build"
cp /consumer.ml consumer.ml

grep -q "^[[:space:]]*lo:" /proc/net/dev
if grep : /proc/net/dev | grep -Ev "^[[:space:]]*lo:"; then
    echo "container inherited a host network interface" >&2
    exit 1
fi
case $(ocamlopt -version) in
    5.4.1) ;;
    *) echo "Domainslib consumer requires the manifest OCaml 5.4.1 compiler" >&2; exit 1 ;;
esac
expected=$1
directory=$(readlink -f "$(ocamlfind query domainslib)")
case "$directory" in
    "$expected"/*) ;;
    *) echo "domainslib resolved outside the tested output: $directory" >&2; exit 1 ;;
esac
printf "domainslib: %s\\n" "$directory"
ocamlfind ocamlopt -thread -package domainslib -linkpkg -o consumer consumer.ml
timeout --kill-after=5s 30s ./consumer >actual
# The expected transcript is independent of the parallel algorithms and
# contains exact closed-form oracle results, not merely a success substring.
printf "fib=317811 reduction=500500 channel=358438400\\ndomainslib consumer passed\\n" >expected
if ! cmp -s expected actual; then
    cat actual >&2
    echo "Domainslib consumer transcript differs from the independent oracle" >&2
    exit 1
fi
cat actual
'\'' domainslib-consumer "$1"
' domainslib-container "$domainslib_out" || status=$?

after=$("$guix_tool" hash -x --serializer=nar "$domainslib_out")
if test "$before" != "$after"; then
    echo "Domainslib output NAR hash changed: $before -> $after" >&2
    exit 1
fi
reject_writable_files
if test "$status" -ne 0; then
    exit "$status"
fi
printf 'domainslib smoke passed: isolated native consumer; immutable NAR %s\n' "$after"
