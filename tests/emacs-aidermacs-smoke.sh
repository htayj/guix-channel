#!/bin/sh
# Consume a prebuilt extension in genuine offline Emacs, never an Aider session.
set -eu
umask 077
fail () { printf '%s\n' "aidermacs smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: GUIX=guix sh %s OUTPUT EVIDENCE\n' "$0" >&2; exit 64; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -e -- "$1")
evidence=$(realpath -m -- "$2")
case "$out" in /gnu/store/*) ;; *) fail 'OUTPUT must be a prebuilt store directory' ;; esac
case "$evidence/" in /gnu/store/*) fail 'EVIDENCE must be outside the store' ;; esac
mkdir -p -- "$evidence"
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'EVIDENCE must be empty'
test -f "$out/share/doc/emacs-aidermacs/LICENSE"
grep -q 'Apache License' "$out/share/doc/emacs-aidermacs/LICENSE"
grep -q 'Version 2.0, January 2004' "$out/share/doc/emacs-aidermacs/LICENSE"
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
find_lisp_dir () {
    files=$(find "$1/share/emacs/site-lisp" -type f -name "$2.el" -print)
    case "$files" in ''|*'
'*) fail "missing or ambiguous installed library: $2" ;; esac
    dirname -- "$files"
}
# Resolve proof tools and Lisp dependencies serially, outside the namespace.
emacs_out=$(find_output bin/emacs emacs-minimal)
python_out=$(find_output bin/python3 python)
pyte_out=$(find_output lib python-pyte)
wcwidth_out=$(find_output lib python-wcwidth)
core_out=$(find_output bin/timeout coreutils)
util_out=$(find_output bin/unshare util-linux)
# Load the package's complete transitive propagated closure from its own
# definition, as its build's EMACSLOADPATH did (transient propagates llama
# and cond-let), instead of naming only direct inputs.
closure_outs=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
    --no-offload --cores=1 --max-jobs=1 -e \
    "(map cadr ((@ (guix packages) package-transitive-propagated-inputs)
               (@ (tay packages aidermacs) emacs-aidermacs)))")
test -n "$closure_outs" || fail 'empty propagated dependency closure'
lisp_dir=$(find_lisp_dir "$out" aidermacs)
for library in aidermacs aidermacs-backend-comint aidermacs-backend-vterm \
               aidermacs-backends aidermacs-models aidermacs-output; do
    test -f "$lisp_dir/$library.el"
    test -f "$lisp_dir/$library.elc"
done
test ! -e "$lisp_dir/aidermacs.png"
test ! -e "$lisp_dir/introscreen.png"
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
for library in transient compat cond-let llama markdown-mode; do
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
test -n "$python_path"
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'writable package files'
scratch=$("$core_out/bin/mktemp" -d "${TMPDIR:-/tmp}/aidermacs-native.XXXXXX")
trap '"$core_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
status=0
"$core_out/bin/env" -i LC_ALL=C.UTF-8 PATH="$core_out/bin" \
    PYTHONPATH="$python_path" PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$("$core_out/bin/id" -u)" HOST_GID="$("$core_out/bin/id" -g)" \
    HOST_NET_NS="$("$core_out/bin/readlink" /proc/self/ns/net)" \
    HOST_MNT_NS="$("$core_out/bin/readlink" /proc/self/ns/mnt)" \
    HOST_PID_NS="$("$core_out/bin/readlink" /proc/self/ns/pid)" \
    "$core_out/bin/timeout" --kill-after=10 180 \
    "$util_out/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" -B "$channel_dir/tests/emacs-aidermacs-native.py" \
    "$out" "$evidence" "$scratch" "$util_out/bin/mount" "$emacs_out/bin/emacs" "$@" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
"$python_out/bin/python3" - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
path = Path(root) / 'evidence.json'
record = json.loads(path.read_text()) if path.exists() else {
    'status': 'failed', 'error': 'driver ended without final evidence'}
record.update(exit_status=int(status), output_nar_before=before,
              output_nar_after=after, output_unchanged=before == after)
if int(status) or before != after:
    record['status'] = 'failed'
path.write_text(json.dumps(record, indent=2) + '\n')
sys.exit(0 if record['status'] == 'passed' else 1)
PY
printf 'Aidermacs native prompt-file/save/reopen/key-path proof passed; no Aider or LLM session; evidence: %s\n' "$evidence"
