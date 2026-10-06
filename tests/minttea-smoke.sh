#!/bin/sh
# Compile the exact installed upstream basic example, then drive its native TTY.
set -eu
fail() { printf 'minttea-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -eq 2 || { echo "usage: GUIX=guix sh $0 OUTPUT EVIDENCE" >&2; exit 64; }
out=$1
evidence=$2
case "$out" in /gnu/store/*) ;; *) fail 'OUTPUT must be a realized /gnu/store path' ;; esac
case "$evidence" in /*) ;; *) fail 'EVIDENCE must be absolute' ;; esac
test ! -e "$evidence" || fail 'EVIDENCE must be a fresh nonexistent directory'
for member in lib/ocaml/site-lib/minttea/META lib/ocaml/site-lib/minttea/minttea.cmxa \
    lib/ocaml/site-lib/leaves/META lib/ocaml/site-lib/leaves/leaves.cmxa \
    share/minttea/source-commit share/minttea/consumer-toolchain \
    share/minttea/consumer-closure share/minttea/spices-provider \
    share/minttea/examples/basic/main.ml; do
    test -s "$out/$member" || fail "missing installed artifact $member"
done
{
    IFS= read -r compiler
    IFS= read -r findlib
} <"$out/share/minttea/consumer-toolchain"
for dependency in "$compiler" "$findlib"; do
    case "$dependency" in /gnu/store/*) ;; *) fail 'toolchain metadata is not store-backed' ;; esac
    test -d "$dependency" || fail "unrealized recorded toolchain $dependency"
done
test -x "$compiler/bin/ocamlopt" || fail 'recorded compiler lacks ocamlopt'
test -x "$findlib/bin/ocamlfind" || fail 'recorded findlib lacks ocamlfind'
find_output()
{
    program=$1
    shift
    candidates=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 "$@") || return 1
    for output in $candidates; do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    fail "dependency lacks $program: $*"
}
# Every realization is serial and outside the namespace; isolation needs no daemon.
coreutils=$(find_output bin/timeout coreutils)
util_linux=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
gcc=$(find_output bin/gcc -e '(@ (gnu packages commencement) gcc-toolchain)')
shell=$(find_output bin/sh bash-minimal)
if ! "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --kill-child --fork "$coreutils/bin/true"; then
    echo 'minttea smoke requires same-UID user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils/bin/mktemp" -d /tmp/minttea-native.XXXXXXXX)
trap '"$coreutils/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils/bin/mkdir" -p "$evidence"
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/output-nar-before.txt"
profile="$evidence/profile"
"$guix_bin" build -L "$channel_dir/guix" --no-grafts --no-offload \
    --cores=1 --max-jobs=1 --manifest="$channel_dir/tests/minttea-profile-manifest.scm" \
    >"$evidence/prerealization.stdout" 2>"$evidence/prerealization.stderr"
# Store-item installs lose search-path metadata; this is an actual package manifest.
"$guix_bin" package -L "$channel_dir/guix" --no-grafts --no-offload \
    --cores=1 --max-jobs=1 --profile="$profile" \
    --manifest="$channel_dir/tests/minttea-profile-manifest.scm" \
    >"$evidence/profile-install.stdout" 2>"$evidence/profile-install.stderr"
"$guix_bin" package --profile="$profile" --list-installed \
    >"$evidence/profile-installed.txt"
for identity in "$out" "$compiler" "$findlib" "$gcc"; do
    "$coreutils/bin/cut" -f4 "$evidence/profile-installed.txt" |
        "$coreutils/bin/sort" -u | {
            while IFS= read -r installed; do
                test "$installed" = "$identity" && exit 0
            done
            exit 1
        } || fail "temporary profile does not install prebuilt identity $identity"
done
test -r "$profile/etc/profile" || fail 'temporary profile lacks exported search paths'
"$coreutils/bin/cp" "$profile/etc/profile" "$evidence/profile-environment.sh"
status=0
"$coreutils/bin/env" -i LC_ALL=C.UTF-8 TERM=xterm-256color PATH="$coreutils/bin" \
    HOME="$scratch/home" TMPDIR="$scratch" \
    XDG_CONFIG_HOME="$scratch/config" XDG_CACHE_HOME="$scratch/cache" \
    XDG_DATA_HOME="$scratch/data" XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
    EXPECTED_UID="$("$coreutils/bin/id" -u)" EXPECTED_GID="$("$coreutils/bin/id" -g)" \
    "$coreutils/bin/timeout" --kill-after=10 300 \
    "$util_linux/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --kill-child --fork \
    "$shell/bin/sh" -c '
        GUIX_PROFILE=$1
        export GUIX_PROFILE
        . "$GUIX_PROFILE/etc/profile"
        shift
        exec "$@"
    ' minttea-profile "$profile" \
    "$python/bin/python3" -I -B "$channel_dir/tests/minttea-native.py" \
    "$out" "$evidence" "$scratch" "$compiler" "$findlib" "$gcc" "$profile" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/output-nar-after.txt"
"$python/bin/python3" -I -B - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
p = Path(root, 'runtime.json')
record = json.loads(p.read_text()) if p.exists() else {'status': 'failed'}
record.update(exit_status=int(status), output_nar_before=before,
              output_nar_after=after, output_unchanged=before == after)
if int(status) or before != after:
    record['status'] = 'failed'
Path(root, 'evidence.json').write_text(json.dumps(record, indent=2) + '\n')
PY
"$coreutils/bin/cat" "$evidence/driver.stdout" "$evidence/driver.stderr"
test "$before" = "$after" || fail "installed output NAR changed; evidence: $evidence"
test "$status" -eq 0 || fail "isolated native proof exited $status; evidence: $evidence"
printf 'MINTTEA_NATIVE_RUNTIME_OK\n'
printf 'minttea exact upstream native basic example and terminal restoration passed; evidence: %s\n' "$evidence"
