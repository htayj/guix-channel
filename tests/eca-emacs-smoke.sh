#!/bin/sh
# Offline proof for eca-emacs: no server download, and real chat/completion
# commands exchanging JSON-RPC with a local fake ECA server over a pipe.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [eca-emacs-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes eca-emacs)
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

find_lisp_dir() {
    root=$1
    name=$2
    file=$(find "$root/share/emacs/site-lisp" -type f \
        \( -name "$name.el" -o -name "$name.elc" \) -print | sed -n '1p')
    test -n "$file"
    dirname "$file"
}

emacs_out=$(find_program_output bin/emacs emacs-minimal)
util_linux_out=$(find_program_output bin/unshare util-linux)
bash_out=$(find_program_output bin/bash bash-minimal)
coreutils_out=$(find_program_output bin/timeout coreutils)
ncurses_out=$(find_program_output bin/tic ncurses)
emacs_bin=$emacs_out/bin/emacs
unshare_bin=$util_linux_out/bin/unshare
script_bin=$util_linux_out/bin/script
bash_bin=$bash_out/bin/bash
timeout_bin=$coreutils_out/bin/timeout
env_bin=$coreutils_out/bin/env

# The finding requires the Apache-2.0 notice in the output documentation.
grep -q 'Apache License' "$package_out/share/doc/eca-emacs/LICENSE"
lisp_dir=$(find_lisp_dir "$package_out" eca)

load_args="-L $lisp_dir"
for dependency in dash:emacs-dash s:emacs-s f:emacs-f \
        markdown-mode:emacs-markdown-mode compat:emacs-compat; do
    feature=${dependency%%:*}
    dependency_out=$($guix_bin build "${dependency#*:}")
    load_args="$load_args -L $(find_lisp_dir "$dependency_out" "$feature")"
done

if ! "$unshare_bin" --user --map-root-user --net --fork true >/dev/null 2>&1; then
    echo 'eca-emacs smoke requires an unprivileged network namespace' >&2
    exit 77
fi

temporary=$(mktemp -d -t eca-emacs-smoke.XXXXXX)
if test -n "${ECA_EMACS_SMOKE_KEEP_SCRATCH:-}"; then
    # Debugging aid: keep logs and the PTY typescript for inspection.
    trap 'echo "eca-emacs smoke: scratch kept at $temporary" >&2' EXIT
else
    trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
fi
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime" \
      "$temporary/tmp" "$temporary/workspace" "$temporary/log" \
      "$temporary/sentinel-bin" "$temporary/path-bin" "$temporary/fake"
chmod 700 "$temporary/runtime"
printf 'first line\nsecond line\n' >"$temporary/workspace/sample.txt"

# PATH holds only download-tool sentinels; each records its use and fails.
for tool in curl wget unzip; do
    {
        printf '#!%s\n' "$bash_bin"
        printf 'printf "%%s %%s\\n" %s "$*" >>"%s/sentinel.log"\n' \
            "$tool" "$temporary/log"
        printf 'exit 97\n'
    } >"$temporary/sentinel-bin/$tool"
    chmod 555 "$temporary/sentinel-bin/$tool"
done

{
    printf '#!%s\n' "$bash_bin"
    cat "$channel_dir/tests/eca-emacs-fake-server.bash"
} >"$temporary/fake/eca"
chmod 555 "$temporary/fake/eca"
# A second copy is used only to prove PATH discovery resolves `eca server'.
cp "$temporary/fake/eca" "$temporary/path-bin/eca"

output_fingerprint() {
    find "$package_out" -xdev -type f -exec sha256sum {} \; | LC_ALL=C sort | sha256sum
}
before_fingerprint=$(output_fingerprint)

run_isolated() {
    "$timeout_bin" 90 "$unshare_bin" --user --map-root-user --net --fork \
        "$env_bin" -i HOME="$temporary/home" \
        XDG_CONFIG_HOME="$temporary/config" XDG_DATA_HOME="$temporary/data" \
        XDG_CACHE_HOME="$temporary/cache" XDG_STATE_HOME="$temporary/state" \
        XDG_RUNTIME_DIR="$temporary/runtime" TMPDIR="$temporary/tmp" \
        LC_ALL=C.UTF-8 PATH="$temporary/sentinel-bin" \
        TERMINFO_DIRS="$ncurses_out/share/terminfo" \
        ECA_SMOKE_FAKE="$temporary/fake/eca" \
        ECA_SMOKE_LOG="$temporary/log" \
        ECA_SMOKE_WORKSPACE="$temporary/workspace" \
        ECA_SMOKE_SENTINEL_BIN="$temporary/sentinel-bin" \
        ECA_SMOKE_PATH_BIN="$temporary/path-bin" \
        "$@"
}

# shellcheck disable=SC2086 # load_args is a list of -L DIR pairs.
batch_output=$(run_isolated "$emacs_bin" --batch -Q $load_args \
    -l "$channel_dir/tests/eca-emacs-smoke.el" \
    --eval '(eca-smoke-run)' 2>"$temporary/log/emacs.stderr") || {
    cat "$temporary/log/emacs.stderr" >&2
    sed 's/^/server: /' "$temporary/log/server.log" >&2 2>/dev/null || true
    exit 1
}
printf '%s\n' "$batch_output"
printf '%s\n' "$batch_output" | grep -qx 'eca-emacs offline protocol smoke passed'

log=$temporary/log/server.log
# Exactly the three fake-server launches, all as `eca server MODE'.
test "$(grep -c '^START ' "$log")" = 3
grep -q '^START pid=[0-9]* mode=protocol argv=server protocol$' "$log"
grep -q '^START pid=[0-9]* mode=malformed argv=server malformed$' "$log"
grep -q '^START pid=[0-9]* mode=early-exit argv=server early-exit$' "$log"
test "$(grep -c '"method":"initialize"' "$log")" = 3
grep -q '^SEND .*FAKE_CHAT_PROMPT_ERROR' "$log"
grep -q '^SEND .*FAKE_COMPLETION_ERROR' "$log"
grep -q '^SEND-MALFORMED ' "$log"
grep -q '^EARLY-EXIT 7$' "$log"
# `eca-stop' sends shutdown, then kills the pipe process after `exit'.
test "$(grep -c '"method":"shutdown"' "$log")" = 2
test "$(grep -c '^SEND {"jsonrpc":"2.0","id":[0-9]*,"result":null}$' "$log")" = 2
# The default chat mode line omits :server-version, so no `eca --version'.
test "$(grep -c '^VERSION$' "$log")" = 0
test "$(grep -c '"method":"chat/prompt"' "$log")" = 1
test "$(grep -c '"method":"completion/inline"' "$log")" = 1
if grep -q '^ARGV-REJECTED\|^BAD-LENGTH\|^SHORT-BODY' "$log"; then
    echo 'eca-emacs smoke: fake server rejected client input' >&2
    exit 1
fi
# Download tools were never executed and nothing was fetched or unpacked.
test ! -e "$temporary/log/sentinel.log"
test -z "$(find "$temporary/home" "$temporary/config" "$temporary/data" \
    "$temporary/cache" "$temporary/state" "$temporary/tmp" \
    "$temporary/workspace" -type f \( -name 'eca' -o -name 'eca.exe' \
    -o -name '*.zip' -o -name 'eca-version' \) -print -quit)"
test ! -e "$temporary/home/.emacs.d/eca"
# Every fake server launched by the smoke has exited.
for pid in $(sed -n 's/^START pid=\([0-9]*\) .*/\1/p' "$log"); do
    if kill -0 "$pid" 2>/dev/null; then
        echo "eca-emacs smoke: fake server $pid is still running" >&2
        exit 1
    fi
done

# Optional raw PTY stream of the real chat and completion commands in a
# terminal Emacs frame, captured in the same isolation.  The exported stream
# is the contiguous log prefix recorded by Emacs after the final redisplay of
# the complete frame, so it ends on the alternate screen before shutdown and
# terminal restoration.
raw_capture=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}
if test -n "$raw_capture"; then
    rm -f "$log" "$temporary/log/tty-scene.ok" "$temporary/log/tty-scene.err" \
        "$temporary/log/tty-frame.bytes"
    script_log=$temporary/log/tty.script
    # Like -Q, but with an isolated init file read before terminal setup so
    # Emacs sends no xterm capability queries (DA, background colour) whose
    # answers a replaying terminal would otherwise inject.
    mkdir -p "$temporary/home/.emacs.d"
    printf '(setq package-enable-at-startup nil)\n' \
        >"$temporary/home/.emacs.d/early-init.el"
    printf '(setq inhibit-default-init t xterm-extra-capabilities nil)\n' \
        >"$temporary/home/.emacs.d/init.el"
    # shellcheck disable=SC2086
    run_isolated TERM=xterm-256color ECA_SMOKE_TTY_LOG="$script_log" \
        "$script_bin" -q -f -e \
        -c "$coreutils_out/bin/stty rows 24 cols 80; exec $emacs_bin -nw \
            --no-site-file --no-site-lisp --no-splash --no-x-resources \
            $load_args -l $channel_dir/tests/eca-emacs-smoke.el \
            --eval '(eca-smoke-tty-scene)'" \
        "$script_log" </dev/null >/dev/null || {
        cat "$temporary/log/tty-scene.err" >&2 2>/dev/null || true
        exit 1
    }
    test -f "$temporary/log/tty-scene.ok"
    test ! -e "$temporary/log/sentinel.log"
    frame_bytes=$(cat "$temporary/log/tty-frame.bytes")
    case $frame_bytes in
        ''|*[!0-9]*) echo 'eca-emacs smoke: invalid frame byte count' >&2; exit 1 ;;
    esac
    # Drop only script(1)'s leading banner line from the recorded prefix.
    "$coreutils_out/bin/head" -c "$frame_bytes" "$script_log" |
        sed -e '1{/^Script started on /d;}' >"$raw_capture"
    grep -aq 'FAKE_COMPLETION_ERROR' "$raw_capture"
    grep -aq 'Started with workspaces' "$raw_capture"
    # Emacs enters and leaves the alternate screen once during terminal
    # start-up, then re-enters it for the session.  The exported prefix must
    # end inside that final alternate-screen session: after the last enter
    # there is no leave, and the completion error is drawn after it.
    esc=$(printf '\033')
    last_enter=$(grep -abo "$esc\[?1049h" "$raw_capture" |
        sed -n '$s/:.*//p')
    test -n "$last_enter"
    last_leave=$(grep -abo "$esc\[?1049l" "$raw_capture" | sed -n '$s/:.*//p')
    if test -n "$last_leave" && test "$last_leave" -gt "$last_enter"; then
        echo 'eca-emacs smoke: exported frame includes terminal restore' >&2
        exit 1
    fi
    last_error=$(grep -abo 'FAKE_COMPLETION_ERROR' "$raw_capture" |
        sed -n '$s/:.*//p')
    test "$last_error" -gt "$last_enter"
    # No terminal queries whose replies a replaying terminal would inject.
    if grep -aq "$(printf '\033')\[>0c\|$(printf '\033')]11;?" "$raw_capture"; then
        echo 'eca-emacs smoke: exported frame contains terminal queries' >&2
        exit 1
    fi
fi

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"
