#!/bin/sh
# Compile an external consumer against all six installed Miou libraries.
set -eu

guix_tool=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
manifest=$channel_dir/tests/miou-manifest.scm
consumer=$channel_dir/tests/miou-consumer.ml

if test "$#" -gt 1; then
    echo "usage: $0 [prebuilt-miou-store-output]" >&2
    exit 2
fi
if test "$#" -eq 1; then
    miou_out=$1
else
    miou_out=$("$guix_tool" build -L "$channel_dir/guix" --no-grafts --check miou)
fi
case "$miou_out" in
    /gnu/store/*) test -d "$miou_out" ;;
    *) echo "expected a Miou store output: $miou_out" >&2; exit 2 ;;
esac

# Warm the manifest/profile before entering the network-isolated container.
# Rebuild the shell cache because the manifest also imports a channel module.
"$guix_tool" shell -L "$channel_dir/guix" --no-grafts --rebuild-cache \
    --pure -m "$manifest" -- true

reject_writable_files () {
    if find "$miou_out" -type f -perm /222 -print -quit | grep . >/dev/null; then
        echo "Miou output contains writable store files" >&2
        return 1
    fi
}
reject_writable_files
before=$("$guix_tool" hash -x --serializer=nar "$miou_out")

# Guix has no --no-network option: --container creates a fresh network
# namespace unless --network is explicitly requested.  Do not request it.
# --no-cwd excludes the checkout; only the external consumer is exposed.
# No --preserve options: the container receives no host search paths/profile.
status=0
"$guix_tool" shell -L "$channel_dir/guix" --no-grafts --rebuild-cache \
    --container --pure --no-cwd --user=miou-smoke -m "$manifest" \
    --expose="$consumer=/consumer.ml" -- /bin/sh -c '
set -eu
profile=$GUIX_ENVIRONMENT
# Start the actual compilation/run with an explicit, empty-base environment.
# These search paths refer solely to the manifest profile, never a host profile.
exec "$profile/bin/env" -i \
    PATH="$profile/bin" GUIX_ENVIRONMENT="$profile" \
    OCAMLPATH="$profile/lib/ocaml/site-lib" \
    C_INCLUDE_PATH="$profile/include" LIBRARY_PATH="$profile/lib" \
    LC_ALL=C HOME=/home/miou-smoke USER=miou-smoke LOGNAME=miou-smoke \
    /bin/sh -c '\''
set -eu
umask 077
work=$(mktemp -d /tmp/miou-consumer.XXXXXX)
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

# A fresh network namespace has only loopback, never host interfaces.
grep -q "^[[:space:]]*lo:" /proc/net/dev
if grep : /proc/net/dev | grep -Ev "^[[:space:]]*lo:"; then
    echo "container inherited a host network interface" >&2
    exit 1
fi
case $(ocamlopt -version) in
    5.4.1) ;;
    *) echo "Miou consumer requires the manifest OCaml 5.4.1 compiler" >&2; exit 1 ;;
esac
expected=$1
for library in miou miou.unix miou.runtime_events miou.bitv miou.sync miou.backoff; do
    directory=$(readlink -f "$(ocamlfind query "$library")")
    case "$directory" in
        "$expected"/*) ;;
        *) echo "$library resolved outside the tested output: $directory" >&2; exit 1 ;;
    esac
    printf "%s: %s\\n" "$library" "$directory"
done
ocamlfind ocamlopt \
    -package miou.unix,miou.runtime_events,miou.bitv,miou.sync,miou.backoff \
    -linkpkg -o consumer consumer.ml
export MIOU_TRACE=1
export OCAML_RUNTIME_EVENTS_DIR=$work/build
# Keep a hung scheduler, sleep backend, or trace reader from hanging the smoke.
timeout --kill-after=5s 30s ./consumer
'\'' miou-consumer "$1"
' miou-container "$miou_out" || status=$?

after=$("$guix_tool" hash -x --serializer=nar "$miou_out")
if test "$before" != "$after"; then
    echo "Miou output NAR hash changed: $before -> $after" >&2
    exit 1
fi
reject_writable_files
if test "$status" -ne 0; then
    exit "$status"
fi
printf 'miou smoke passed: isolated installed consumer; immutable NAR %s\n' "$after"
