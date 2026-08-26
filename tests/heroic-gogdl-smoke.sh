#!/bin/sh
# Offline smoke test for the installed Heroic GOGDL command and extension.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [heroic-gogdl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    gogdl_out=$1
else
    gogdl_out=$($guix_bin build -L "$channel_dir" --no-grafts heroic-gogdl)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
test -x "$gogdl_out/bin/gogdl"

parent_license=$gogdl_out/share/doc/heroic-gogdl/LICENSE
xdelta_license=$gogdl_out/share/doc/heroic-gogdl/xdelta3-LICENSE
test -f "$parent_license"
test -f "$xdelta_license"
grep -q 'GNU GENERAL PUBLIC LICENSE' "$parent_license"
grep -q 'Apache License' "$xdelta_license"

site_packages=$(find "$gogdl_out/lib" -type d -path '*/site-packages' -print -quit)
test -n "$site_packages"
test -f "$site_packages/gogdl_xdelta3.abi3.so"

# An installed Guix output must be immutable.  Hashing before and after also
# catches an accidental write that a permissive test environment might allow.
test ! -w "$gogdl_out"
before_digest=$($guix_bin hash -r "$gogdl_out")

temporary=$(mktemp -d "${TMPDIR:-/tmp}/heroic-gogdl-smoke.XXXXXX")
cleanup() {
    rm -rf "$temporary"
}
trap cleanup EXIT HUP INT TERM

home=$temporary/home
xdg_config=$temporary/xdg-config
gogdl_config=$temporary/gogdl-config
work=$temporary/work
mkdir "$home" "$xdg_config" "$gogdl_config" "$work"

# Parser-only invocations need no network.  Prefer a network namespace where
# it is available; otherwise the controlled commands below never create an
# API client or issue a request, and all proxy variables are removed.
namespace_prefix=
if command -v unshare >/dev/null 2>&1 \
   && unshare --user --map-root-user --net true >/dev/null 2>&1; then
    namespace_prefix='unshare --user --map-root-user --net --'
fi

run_isolated() {
    if test -n "$namespace_prefix"; then
        # shellcheck disable=SC2086
        $namespace_prefix env -i \
            HOME="$home" XDG_CONFIG_HOME="$xdg_config" \
            GOGDL_CONFIG_PATH="$gogdl_config" \
            GUIX_PYTHONPATH="$site_packages" \
            PATH="$gogdl_out/bin:$python_out/bin" \
            LC_ALL=C.UTF-8 PYTHONNOUSERSITE=1 \
            "$@"
    else
        env -i \
            HOME="$home" XDG_CONFIG_HOME="$xdg_config" \
            GOGDL_CONFIG_PATH="$gogdl_config" \
            GUIX_PYTHONPATH="$site_packages" \
            PATH="$gogdl_out/bin:$python_out/bin" \
            LC_ALL=C.UTF-8 PYTHONNOUSERSITE=1 \
            "$@"
    fi
}

test "$(run_isolated "$gogdl_out/bin/gogdl" --version)" = 1.3.0
help_output=$(run_isolated "$gogdl_out/bin/gogdl" --help)
printf '%s\n' "$help_output" | grep -q 'download'
printf '%s\n' "$help_output" | grep -q 'auth'

run_isolated "$python_out/bin/python3" - <<'PY'
import sys

import gogdl.args
import gogdl_xdelta3

sys.argv[:] = ["gogdl", "lang-match", "en"]
arguments, unknown = gogdl.args.init_parser()
assert arguments.command == "lang-match", arguments
assert arguments.language == "en", arguments
assert unknown == [], unknown
assert gogdl_xdelta3.__file__.endswith(".abi3.so"), gogdl_xdelta3.__file__
PY

test -z "$(find "$home" "$xdg_config" "$gogdl_config" "$work" -mindepth 1 -print -quit)"
after_digest=$($guix_bin hash -r "$gogdl_out")
test "$before_digest" = "$after_digest"
test ! -w "$gogdl_out"

printf '%s\n' 'heroic-gogdl offline smoke passed'
