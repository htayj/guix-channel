#!/bin/sh
# Exercise the installed emacs-mentor-pinned package without user state or a
# network, exactly as defined at the pinned revision in this channel.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [emacs-mentor-pinned-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        emacs-mentor-pinned)
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
    return 1
}

emacs_out=$(find_program_output bin/emacs emacs-minimal)
unshare_out=$(find_program_output bin/unshare util-linux)
async_out=$($guix_bin build emacs-async)
url_scgi_out=$($guix_bin build emacs-url-scgi)
xml_rpc_out=$($guix_bin build emacs-xml-rpc)
emacs_bin=$emacs_out/bin/emacs
unshare_bin=$unshare_out/bin/unshare

test -x "$emacs_bin"
test -x "$unshare_bin"

license=$package_out/share/doc/emacs-mentor-pinned/COPYING
test -f "$license"
grep -q 'GNU GENERAL PUBLIC LICENSE' "$license"
grep -q 'Version 3, 29 June 2007' "$license"

package_lisp=$(find "$package_out/share/emacs/site-lisp" -type f \
    \( -name mentor.el -o -name mentor.elc \) -print | sed -n '1p')
test -n "$package_lisp"
package_lisp_dir=$(dirname "$package_lisp")
for runtime_file in mentor.el mentor-data.el mentor-files.el \
                    mentor-rpc.el mentor-trackers.el; do
    if ! test -f "$package_lisp_dir/$runtime_file" || \
       ! test -f "$package_lisp_dir/${runtime_file%.el}.elc"; then
        echo "missing source and compiled pair for $runtime_file" >&2
        exit 1
    fi
done

find_lisp_dir() {
    root=$1
    name=$2
    file=$(find "$root/share/emacs/site-lisp" -type f \
        \( -name "$name.el" -o -name "$name.elc" \) -print | sed -n '1p')
    test -n "$file"
    dirname "$file"
}

async_lisp_dir=$(find_lisp_dir "$async_out" async)
url_scgi_lisp_dir=$(find_lisp_dir "$url_scgi_out" url-scgi)
xml_rpc_lisp_dir=$(find_lisp_dir "$xml_rpc_out" xml-rpc)

temporary=$(mktemp -d -t emacs-mentor-pinned-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime" \
      "$temporary/workspace"
chmod 700 "$temporary/runtime"

output_fingerprint() {
    find "$package_out" -xdev -type f -exec sha256sum {} \; | LC_ALL=C sort | sha256sum
}

before_fingerprint=$(output_fingerprint)

# A private network namespace gives this test a fail-closed network boundary.
run_isolated() {
    "$unshare_bin" --user --map-root-user --net --fork \
        env -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
        XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
        XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
        TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' \
        "$@"
}

run_isolated "$emacs_bin" --batch -Q \
    -L "$package_lisp_dir" -L "$async_lisp_dir" -L "$url_scgi_lisp_dir" \
    -L "$xml_rpc_lisp_dir" \
    --load "$channel_dir/tests/emacs-mentor-pinned-smoke.el" \
    -f ert-run-tests-batch-and-exit

# Capture the real terminal Mentor scene, not a substitute display command.
# The byte boundary written after redisplay keeps the exported PTY prefix
# inside the final alternate screen, before Emacs restores the terminal.
raw_capture=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}
if test -n "$raw_capture"; then
    script_out=$(find_program_output bin/script util-linux)
    stty_out=$(find_program_output bin/stty coreutils)
    head_out=$(find_program_output bin/head coreutils)
    script_bin=$script_out/bin/script
    stty_bin=$stty_out/bin/stty
    head_bin=$head_out/bin/head
    test -x "$script_bin"
    test -x "$stty_bin"
    test -x "$head_bin"
    script_log=$temporary/tty.script
    # Isolated init files are read before terminal setup, unlike -Q, so
    # xterm query replies cannot be injected by a replaying terminal.
    mkdir -p "$temporary/home/.emacs.d"
    printf '(setq package-enable-at-startup nil)\n' \
        >"$temporary/home/.emacs.d/early-init.el"
    printf '(setq inhibit-default-init t xterm-extra-capabilities nil)\n' \
        >"$temporary/home/.emacs.d/init.el"
    run_isolated TERM=xterm-256color MENTOR_SMOKE_TTY_LOG="$script_log" \
        MENTOR_SMOKE_EVIDENCE="$temporary" \
        "$script_bin" -q -f -e \
        -c "$stty_bin rows 24 cols 80; exec $emacs_bin -nw \
            --no-site-file --no-site-lisp --no-splash --no-x-resources \
            -L $package_lisp_dir -L $async_lisp_dir -L $url_scgi_lisp_dir \
            -L $xml_rpc_lisp_dir \
            -l $channel_dir/tests/emacs-mentor-pinned-smoke.el \
            --eval '(mentor-smoke-tty-scene)'" \
        "$script_log" </dev/null >/dev/null || {
        cat "$temporary/tty-scene.err" >&2 2>/dev/null || true
        exit 1
    }
    test -f "$temporary/tty-scene.ok"
    test ! -e "$temporary/tty-scene.err"
    frame_bytes=$(cat "$temporary/tty-frame.bytes")
    case $frame_bytes in
        ''|*[!0-9]*) echo 'mentor pinned smoke: invalid frame byte count' >&2; exit 1 ;;
    esac
    # Drop only script(1)'s leading banner from the recorded frame prefix.
    "$head_bin" -c "$frame_bytes" "$script_log" |
        sed -e '1{/^Script started on /d;}' >"$raw_capture"
    esc=$(printf '\033')
    last_enter=$(grep -abo "$esc\[?1049h" "$raw_capture" | sed -n '$s/:.*//p')
    test -n "$last_enter"
    last_leave=$(grep -abo "$esc\[?1049l" "$raw_capture" | sed -n '$s/:.*//p')
    if test -n "$last_leave" && test "$last_leave" -gt "$last_enter"; then
        echo 'mentor pinned smoke: exported frame includes terminal restore' >&2
        exit 1
    fi
    for proof in 'Alpha example.iso' 'Zulu example.iso' 'Mentor offline client'; do
        last_proof=$(grep -abo "$proof" "$raw_capture" | sed -n '$s/:.*//p')
        test -n "$last_proof"
        test "$last_proof" -gt "$last_enter"
    done
    if grep -aq "$esc\[>0c\|$esc]11;?" "$raw_capture"; then
        echo 'mentor pinned smoke: exported frame contains terminal queries' >&2
        exit 1
    fi
fi

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"
