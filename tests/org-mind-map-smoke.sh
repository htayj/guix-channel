#!/bin/sh
# Render real installed org-mind-map SVGs, without profiles or network access.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [org-mind-map-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        -e '(@ (tay packages org-mind-map) org-mind-map)')
fi

find_program_output() {
    program=$1
    shift
    for candidate in $($guix_bin build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "could not locate $program in Guix outputs" >&2
    return 1
}

find_lisp_directory() {
    output=$1
    library=$2
    directory=
    for file in $(find "$output/share/emacs/site-lisp" -type f \
        \( -name "$library.el" -o -name "$library.elc" \) -print); do
        candidate=$(dirname "$file")
        if test -n "$directory" && test "$directory" != "$candidate"; then
            echo "ambiguous installed library: $library" >&2
            return 1
        fi
        directory=$candidate
    done
    test -n "$directory"
    printf '%s\n' "$directory"
}

emacs_out=$(find_program_output bin/emacs emacs-minimal)
unshare_out=$(find_program_output bin/unshare util-linux)
shell_out=$(find_program_output bin/sh bash-minimal)
dash_out=$($guix_bin build emacs-dash)
lisp_dir=$(find_lisp_directory "$package_out" org-mind-map)
dash_dir=$(find_lisp_directory "$dash_out" dash)
env_bin=$(command -v env)

temporary=$(mktemp -d -t org-mind-map-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime"
chmod 700 "$temporary/runtime"

if test -n "${ORG_MIND_MAP_SMOKE_ARTIFACT_DIR:-}"; then
    mkdir -p -- "$ORG_MIND_MAP_SMOKE_ARTIFACT_DIR"
    artifact_root=$(CDPATH= cd -- "$ORG_MIND_MAP_SMOKE_ARTIFACT_DIR" && pwd)
    artifacts=$(mktemp -d "$artifact_root/org-mind-map.XXXXXX")
    echo "retaining Org/DOT/SVG/PNG artifacts in $artifacts" >&2
else
    artifacts=$temporary/artifacts
    mkdir "$artifacts"
fi

# A failed namespace setup is an error, never an online fallback.  Guix build
# and output resolution happen before this entirely offline runtime proof.
"$unshare_out/bin/unshare" --user --map-root-user --net --fork \
    "$env_bin" -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
    TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' SHELL="$shell_out/bin/sh" \
    ORG_MIND_MAP_SMOKE_ARTIFACTS="$artifacts" \
    ORG_MIND_MAP_SMOKE_PACKAGE="$package_out" \
    "$emacs_out/bin/emacs" --batch -Q -L "$dash_dir" -L "$lisp_dir" \
    -l "$channel_dir/tests/org-mind-map-smoke.el" \
    --eval '(org-mind-map-smoke-run)'
