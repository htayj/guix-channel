#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# External consumer of the prebuilt sbcl-imago output; fresh evidence only.
# No installed test hook, no Quicklisp, no host ASDF state.
# Usage: sh tests/imago-smoke.sh IMAGO-OUTPUT EVIDENCE-DIRECTORY
set -eu
umask 077
fail () { printf '%s\n' "imago smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s OUTPUT EVIDENCE-DIRECTORY\n' "$0" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -- "$1")
case "$out" in /gnu/store/*) ;; *) fail 'expected prebuilt sbcl-imago store output' ;; esac
test -d "$out/lib/common-lisp/sbcl/imago" || fail 'missing installed SBCL fasl tree'
test -d "$out/share/common-lisp/sbcl/imago" || fail 'missing installed ASDF source tree'
# Resolve to an absolute path before entering the pure shell: PATH is
# stripped there, so a bare command name would not survive.
guix_bin=$(readlink -f -- "$(command -v "${GUIX:-guix}")")
case "$guix_bin" in /*) ;; *) fail 'could not resolve absolute guix path' ;; esac
if test "${IMAGO_PROOF_ENV:-}" != ready; then
    # Only generic dependencies are realized before isolation: sbcl
    # plus the transitive propagated-input closure of sbcl-imago,
    # evaluated from the channel (no package build, no sbcl-imago
    # substitution into the profile).  The passed prebuilt OUTPUT is
    # consumed directly via IMAGO_OUTPUT.
    exec "$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
        -L "$channel_dir/guix" \
        -e '(begin (use-modules (guix packages) (gnu packages lisp)
                           (tay packages imago))
              (cons sbcl (map cadr
                              (package-transitive-propagated-inputs
                               sbcl-imago))))' \
        coreutils findutils bash-minimal util-linux \
        --preserve='^(GUIX|IMAGO_PROOF_ENV)$' -- \
        env GUIX="$guix_bin" IMAGO_PROOF_ENV=ready IMAGO_OUTPUT="$out" \
        sh "$channel_dir/tests/imago-smoke.sh" "$out" "$2"
fi
for cmd in sbcl timeout unshare mount find; do
    command -v "$cmd" >/dev/null || fail "missing proof dependency: $cmd"
done
# guix is only used by absolute path (resolved before the pure shell).
test -x "$guix_bin" || fail "unusable guix path: $guix_bin"
out=$(realpath -- "$IMAGO_OUTPUT")
case "$out" in /gnu/store/*) ;; *) fail 'expected realized sbcl-imago store output' ;; esac
test -d "$out/etc/xdg/common-lisp/source-registry.conf.d" \
    || fail 'output lacks ASDF source-registry configuration'
test -d "$out/etc/xdg/common-lisp/asdf-output-translations.conf.d" \
    || fail 'output lacks ASDF output-translations configuration'
# The passed OUTPUT's own ASDF configuration registers imago (source
# tree plus delivered fasl translations); the profile's carries the
# dependency closure.  Both are read via XDG_CONFIG_DIRS.
export XDG_CONFIG_DIRS="$out/etc/xdg:$GUIX_ENVIRONMENT/etc/xdg"
mkdir -p -- "$2"
evidence=$(realpath -- "$2")
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'evidence directory must be empty'
case "$evidence/" in "$out/"*) fail 'evidence must be outside installed output' ;; esac
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'writable installed files'
before_out=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before_out" >"$evidence/imago-nar-before.txt"
for ns in user net mnt pid ipc; do
    value=$(readlink "/proc/self/ns/$ns")
    case "$ns" in
        user) export IMAGO_HOST_USER="$value" ;;
        net) export IMAGO_HOST_NET="$value" ;;
        mnt) export IMAGO_HOST_MNT="$value" ;;
        pid) export IMAGO_HOST_PID="$value" ;;
        ipc) export IMAGO_HOST_IPC="$value" ;;
    esac
done
export IMAGO_HOST_UID=$(id -ru)
export IMAGO_HOST_EUID=$(id -u)
unset LD_PRELOAD LD_LIBRARY_PATH CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS SBCL_HOME
consumer_dir=$evidence/consumer
mkdir -m 700 -- "$consumer_dir"
export IMAGO_WORK="$consumer_dir"
# Keep ASDF configuration, caches and dependency-created user data away
# from the caller's HOME even in a pure shell (which retains HOME).
export HOME="$consumer_dir/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p -- "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
export IMAGO_RECEIPT="$evidence/proof.json"
status=0
timeout --kill-after=5 240 \
    unshare --user --map-current-user --keep-caps --net --mount --ipc \
    --mount-proc --pid --fork --kill-child \
    sbcl --noinform --no-userinit --script "$channel_dir/tests/imago-native.lisp" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after_out=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after_out" >"$evidence/imago-nar-after.txt"
test "$before_out" = "$after_out" || fail 'installed output NAR changed'
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'installed files became writable'
test "$status" -eq 0 || fail "native consumer failed ($status); see $evidence/driver.stderr"
test -s "$evidence/proof.json" || fail 'native consumer receipt missing'
printf '%s\n' 'imago smoke: loaded all six delivered systems; synthetic PNG/PPM in-memory and file roundtrips; JPEG, TIFF and HEIF lossy roundtrips with asserted dimensions/channels/pixels; transforms with exact assertions; error behavior verified; offline same-UID namespaces, read-only store, NAR unchanged'
