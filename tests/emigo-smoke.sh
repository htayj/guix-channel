#!/bin/sh
# Real installed Emacs/Python EPC plus local repository mapping, without credentials.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [emigo-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts --no-substitutes emigo)
fi
find_output() {
    program=$1
    shift
    for candidate in $("$guix_bin" build --no-grafts "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}
find_lisp_dir() {
    files=$(find "$1/share/emacs/site-lisp" -type f -name "$2.el" -print)
    case $files in
        ''|*'
'*) echo "missing or ambiguous installed library: $2" >&2; return 1 ;;
    esac
    dirname -- "$files"
}
emacs_out=$(find_output bin/emacs emacs-minimal)
util_out=$(find_output bin/unshare util-linux)
core_out=$(find_output bin/timeout coreutils)
ip_out=$(find_output sbin/ip iproute2)
bash_out=$(find_output bin/sh bash-minimal)
lisp_dir=$(find_lisp_dir "$package_out" emigo)
set -- -L "$lisp_dir"
for dependency in compat:emacs-compat transient:emacs-transient markdown-mode:emacs-markdown-mode; do
    dependency_out=$("$guix_bin" build --no-grafts "${dependency#*:}")
    set -- "$@" -L "$(find_lisp_dir "$dependency_out" "${dependency%%:*}")"
done
test -f "$lisp_dir/emigo.elc"
test -x "$package_out/bin/emigo-python"
test -f "$package_out/share/doc/emigo/LICENSE"
test -f "$package_out/share/emigo/backend/queries/tree-sitter-languages/README.md"
if ! "$util_out/bin/unshare" --user --map-root-user --net --fork true; then
    echo 'emigo smoke requires an unprivileged network namespace' >&2
    exit 77
fi
scratch=$(mktemp -d -t emigo-smoke.XXXXXX)
trap 'rm -rf -- "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/workspace" "$scratch/cache" "$scratch/tmp"
printf 'class NativeWidget:\n    def native_total(self, value):\n        return value + 7\n\ndef consumer():\n    return NativeWidget().native_total(2)\n' >"$scratch/workspace/sample.py"
printf 'outside must stay outside\n' >"$scratch/outside.py"
ln -s ../outside.py "$scratch/workspace/escape.py"
printf 'escape.py\n' >"$scratch/workspace/.gitignore"
# Pure environment: no inherited provider keys, profile load paths or Python packages.
# The new net namespace has no external interfaces/routes; only lo is raised for EPC.
"$core_out/bin/timeout" 120 "$util_out/bin/unshare" --user --map-root-user --net --fork \
    "$core_out/bin/env" -i HOME="$scratch/home" TMPDIR="$scratch/tmp" \
    XDG_CACHE_HOME="$scratch/cache" LC_ALL=C.UTF-8 PATH="$core_out/bin" \
    EMIGO_SMOKE_OUTPUT="$package_out" EMIGO_SMOKE_WORKSPACE="$scratch/workspace" \
    "$bash_out/bin/sh" -c '
        set -eu
        "$1" link set lo up
        shift
        out=$1; channel=$2; emacs=$3
        shift 3
        backend=$out/share/emigo/backend
        cd "$backend"
        "$out/bin/emigo-python" test_setup.py
        "$out/bin/emigo-python" repomapper.py --help
        "$out/bin/emigo-python" "$channel/tests/emigo-local-smoke.py"
        "$out/bin/emigo-python" "$channel/tests/emigo-ca-smoke.py"
        # Upstream emigo.py is an EPC entry point, not a --help CLI.
        # Its genuine no-port error must fail nonzero instead of starting services.
        status=0
        "$out/bin/emigo-python" "$backend/emigo.py" 2>"$TMPDIR/no-port.log" || status=$?
        if test "$status" -ne 1; then
            echo "emigo missing EPC port exited $status instead of 1" >&2
            cat "$TMPDIR/no-port.log" >&2
            exit 1
        fi
        case $(cat "$TMPDIR/no-port.log") in
            *"ERROR: Missing EPC server port argument."*) ;;
            *) cat "$TMPDIR/no-port.log" >&2; exit 1 ;;
        esac
        "$emacs" --batch -Q "$@" -l "$channel/tests/emigo-smoke.el"
    ' emigo-smoke "$ip_out/sbin/ip" "$package_out" "$channel_dir" \
    "$emacs_out/bin/emacs" "$@"
printf 'emigo smoke passed: native IPC and local backend in egress-free namespace\n'
