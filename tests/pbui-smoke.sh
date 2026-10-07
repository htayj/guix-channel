#!/bin/sh
# External native consumer for a prebuilt emacs-pbui output.  Ordinary TTY
# Emacs loads the installed Dired presentations; keys select real file and
# directory presentations and run PBUI commands.  No installed test entry,
# test Lisp, mocked UI or injected application state; the contacts demo
# (network fetch) is not exercised.
# Usage: GUIX=guix sh tests/pbui-smoke.sh OUTPUT EVIDENCE
set -eu
umask 077
fail () { printf 'pbui-smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: GUIX=guix sh %s OUTPUT EVIDENCE\n' "$0" >&2; exit 64; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$1
case "$2" in /*) ;; *) fail 'EVIDENCE must be absolute' ;; esac
case "$out" in /gnu/store/*/*|/gnu/store/.*) fail 'OUTPUT must be a top-level store item' ;; esac
case "$out" in /gnu/store/?*) ;; *) fail 'OUTPUT must be a realized /gnu/store item' ;; esac
test -d "$out" || fail 'OUTPUT is not realized'
evidence=$(realpath -m -- "$2")
case "$evidence/" in /gnu/store/*) fail 'EVIDENCE must be outside the store' ;; esac
test ! -L "$2" || fail 'EVIDENCE must not be a symlink'
mkdir -p -- "$evidence"
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'EVIDENCE must be fresh and empty'
find_output () {
    program=$1
    shift
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 "$@"); do
        if test -e "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    fail "cannot resolve proof dependency $program ($*)"
}
# Proof tools and Lisp dependencies are resolved serially, outside isolation.
emacs_out=$(find_output bin/emacs emacs-minimal)
python_out=$(find_output bin/python3 python)
pyte_out=$(find_output lib python-pyte)
wcwidth_out=$(find_output lib python-wcwidth)
core_out=$(find_output bin/ls coreutils)
diff_out=$(find_output bin/cmp diffutils)
util_out=$(find_output bin/unshare util-linux)
source_out=$(find_output share/mmontone/projects/pbui/pbui.el -e \
    '(@ (tay packages starred-i-m) mmontone-pbui-source)')
canonical_out=$("$core_out/bin/realpath" -e -- "$out")
test "$out" = "$canonical_out" || fail 'OUTPUT must be canonical'
# The package's own transitive propagated closure (dash, inspector, request,
# s and theirs), as its build's EMACSLOADPATH saw it.
closure_outs=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
    --no-offload --cores=1 --max-jobs=1 -e \
    "(map cadr ((@ (guix packages) package-transitive-propagated-inputs)
               (@ (tay packages pbui) emacs-pbui)))")
test -n "$closure_outs" || fail 'empty propagated dependency closure'
lisp_files=$(find "$out/share/emacs/site-lisp" -type f -name pbui.el -print)
case "$lisp_files" in ''|*'
'*) fail 'missing or ambiguous installed pbui.el' ;; esac
lisp_dir=$(dirname -- "$lisp_files")
source_dir=$source_out/share/mmontone/projects/pbui
for library in pbui pbui-util pbui-standard-commands pbui-dired pbui-org \
               pbui-calendar pbui-email pbui-contacts-app; do
    test -f "$lisp_dir/$library.el" || fail "missing $library.el"
    test -f "$lisp_dir/$library.elc" || fail "missing $library.elc"
done
test -f "$lisp_dir/pbui-autoloads.el" || fail 'missing pbui-autoloads.el'
# Record upstream and installed GPL notices as documentation, not behavioral
# acceptance assertions. Package source-file wiring is not a consumer proof.
for library in pbui pbui-standard-commands pbui-dired pbui-calendar pbui-contacts-app; do
    "$core_out/bin/head" -n 26 "$source_dir/$library.el" >"$evidence/$library-source-header.txt"
    "$core_out/bin/head" -n 26 "$lisp_dir/$library.el" >"$evidence/$library-installed-header.txt"
    if "$diff_out/bin/cmp" -s "$evidence/$library-source-header.txt" \
        "$evidence/$library-installed-header.txt"; then
        printf '%s: identical\n' "$library"
    else
        printf '%s: differing\n' "$library"
    fi
done >"$evidence/license-header-observations.txt"
set -- -L "$lisp_dir"
closure_dirs=
for dependency in $closure_outs; do
    for directory in "$dependency"/share/emacs/site-lisp "$dependency"/share/emacs/site-lisp/*/; do
        directory=${directory%/}
        if test -d "$directory" && test -n "$(find "$directory" -maxdepth 1 -name '*.el' -print -quit)"; then
            set -- "$@" -L "$directory"
            closure_dirs="$closure_dirs $directory"
        fi
    done
done
for library in dash s request inspector; do
    found=
    for directory in $closure_dirs; do
        if test -f "$directory/$library.el"; then found=$directory; fi
    done
    test -n "$found" || fail "propagated closure lacks $library.el"
done
python_path=
for dependency in "$pyte_out" "$wcwidth_out"; do
    for site in "$dependency"/lib/python*/site-packages; do
        if test -d "$site"; then python_path=${python_path:+$python_path:}$site; fi
    done
done
test -n "$python_path" || fail 'no pyte/wcwidth site-packages'
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'writable package files'
scratch=$("$core_out/bin/mktemp" -d "${TMPDIR:-/tmp}/pbui-native.XXXXXX")
trap '"$core_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
status=0
"$core_out/bin/env" -i LC_ALL=C.UTF-8 PATH="$core_out/bin" \
    PYTHONPATH="$python_path" PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$("$core_out/bin/id" -u)" HOST_GID="$("$core_out/bin/id" -g)" \
    HOST_USER_NS="$("$core_out/bin/readlink" /proc/self/ns/user)" \
    HOST_NET_NS="$("$core_out/bin/readlink" /proc/self/ns/net)" \
    HOST_MNT_NS="$("$core_out/bin/readlink" /proc/self/ns/mnt)" \
    HOST_PID_NS="$("$core_out/bin/readlink" /proc/self/ns/pid)" \
    "$core_out/bin/timeout" --kill-after=10 240 \
    "$util_out/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" -B "$channel_dir/tests/pbui-native.py" \
    "$out" "$evidence" "$scratch" "$util_out/bin/mount" "$emacs_out/bin/emacs" \
    "$core_out" "$@" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
"$python_out/bin/python3" - "$evidence" "$status" "$before" "$after" \
    "$source_out" "$emacs_out" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after, source, emacs = sys.argv[1:]
path = Path(root) / 'evidence.json'
record = json.loads(path.read_text()) if path.exists() else {
    'status': 'failed', 'error': 'driver ended without final evidence'}
record.update(exit_status=int(status), output_nar_before=before,
              output_nar_after=after, output_unchanged=before == after,
              pinned_source=source, emacs=emacs,
              license_headers_recorded=True)
if int(status) or before != after:
    record['status'] = 'failed'
path.write_text(json.dumps(record, indent=2) + '\n')
sys.exit(0 if record['status'] == 'passed' else 1)
PY
printf 'PBUI native Dired selection/copy/open/edit proof passed; evidence: %s\n' "$evidence"
