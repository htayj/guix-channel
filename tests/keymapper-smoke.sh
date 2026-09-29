#!/bin/sh
# Exercise keymapper's installed configuration checker in a fresh,
# networkless XDG tree.  Neither keymapperd nor any input device, uinput
# node, udev rule or service is used: the daemon needs explicit device
# permission and is only asked to reject an unknown option.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [keymapper-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    keymapper_out=$1
else
    keymapper_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes keymapper)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

bash_out=$(find_output bin/bash bash)
coreutils_out=$(find_output bin/mktemp coreutils)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
util_linux_out=$(find_output bin/script util-linux)
grep_bin=$grep_out/bin/grep
find_bin=$findutils_out/bin/find

version='5.6.0-2-g2ddd5cc'
doc=$keymapper_out/share/doc/keymapper

# Installed layout: the three programs, desktop integration kept inside the
# output with absolute store references, notices, and no udev rule.
for program in keymapper keymapperd keymapperctl; do
    test -x "$keymapper_out/bin/$program"
done
"$grep_bin" -Fx "ExecStart=$keymapper_out/bin/keymapperd" \
    "$keymapper_out/lib/systemd/system/keymapperd.service" >/dev/null
"$grep_bin" -Fx "Exec=$keymapper_out/bin/keymapper -u" \
    "$keymapper_out/share/keymapper/xdg/autostart/keymapper.desktop" >/dev/null
# Nothing is placed where a profile would activate it: $out/etc/xdg is on
# XDG_CONFIG_DIRS, so an autostart entry there would run at every login.
test ! -e "$keymapper_out/etc/xdg"
test -s "$keymapper_out/share/icons/hicolor/scalable/apps/io.github.houmain.keymapper.svg"
test -s "$keymapper_out/share/gnome-shell/extensions/keymapper@houmain.github.com/extension.js"
test -s "$keymapper_out/share/kwin/scripts/keymapper/contents/code/main.js"
"$grep_bin" -F 'GNU GENERAL PUBLIC LICENSE' "$doc/LICENSE" >/dev/null
"$grep_bin" -F 'Version 3, 29 June 2007' "$doc/LICENSE" >/dev/null
"$grep_bin" -F 'Copyright © 2018 Ilia Bozhinov' \
    "$doc/wlr-foreign-toplevel-management-unstable-v1.xml" >/dev/null
test -s "$doc/keymapper.conf"
test ! -e "$keymapper_out/lib/udev"
test ! -e "$keymapper_out/etc/udev"
test -z "$("$find_bin" "$keymapper_out" -name '*.rules' -print -quit)"
# Helper programs are fixed store paths rather than PATH lookups.
"$grep_bin" -aE '/gnu/store/[a-z0-9]{32}-bash-minimal-[^/]*/bin/sh' \
    "$keymapper_out/bin/keymapper" >/dev/null
"$grep_bin" -aE '/gnu/store/[a-z0-9]{32}-libnotify-[^/]*/bin/notify-send' \
    "$keymapper_out/bin/keymapper" >/dev/null
"$grep_bin" -aE '/gnu/store/[a-z0-9]{32}-xdg-utils-[^/]*/bin/xdg-open' \
    "$keymapper_out/bin/keymapper" >/dev/null

before=$($guix_bin hash -S nar "$keymapper_out")
test -z "$("$find_bin" "$keymapper_out" -xdev -type f -perm /222 -print -quit)"

umask 077
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/keymapper-smoke-XXXXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
      "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
      "$scratch/out"

printf '%s\n' \
    '# temporary smoke fixture' \
    'Ext = IntlBackslash' \
    'Ext >>' \
    'CapsLock >> Backspace' \
    'Ext{I} >> ArrowUp' \
    '' \
    '[title="Terminal"]' \
    'Control{Q} >> Control{W}' >"$scratch/work/valid.conf"
printf '%s\n' \
    'CapsLock >> Backspace' \
    'CapsLock >> >>' >"$scratch/work/invalid.conf"
printf '%s\n' 'ScrollLock >> Virtual1' >"$scratch/config/keymapper.conf"

# Run a packaged program with only scratch HOME/XDG locations and no
# inherited environment.
isolated_env ()
{
    (cd "$scratch/work" && \
        env -i HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
            XDG_DATA_HOME="$scratch/data" XDG_CACHE_HOME="$scratch/cache" \
            XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch/runtime" \
            TMPDIR="$scratch/tmp" LC_ALL=C PATH="$keymapper_out/bin" "$@")
}

# Additionally give it no network interfaces and its own PID namespace.
# Upstream forwards a rejected configuration to notify-send even under
# --no-notify; the PID namespace ends that detached helper together with
# keymapper, and there is no session bus for it to reach.
unshare_command="$util_linux_out/bin/unshare --user --map-root-user --net --pid --fork --kill-child"
run_isolated ()
{
    # shellcheck disable=SC2086 # the fixed option list is split on purpose
    isolated_env $unshare_command "$@"
}

expect_status ()
{
    expected=$1
    output=$2
    shift 2
    set +e
    run_isolated "$@" >"$output" 2>&1
    status=$?
    set -e
    if test "$status" -ne "$expected"; then
        echo "keymapper-smoke: expected exit $expected, got $status from: $*" >&2
        cat "$output" >&2
        exit 1
    fi
}

# Valid configuration: the actual checker accepts it and exits zero.
expect_status 0 "$scratch/out/valid" \
    keymapper --check --no-notify --config valid.conf
"$grep_bin" -Fx 'The configuration is valid' "$scratch/out/valid" >/dev/null
if "$grep_bin" -F 'ERROR:' "$scratch/out/valid" >/dev/null; then
    echo 'keymapper-smoke: valid configuration reported an error' >&2
    exit 1
fi

# Invalid configuration: rejected with a located parse error and exit 1.
expect_status 1 "$scratch/out/invalid" \
    keymapper --check --no-notify --config invalid.conf
"$grep_bin" -Fx 'ERROR: Unexpected symbol > at [>>] in line 2' \
    "$scratch/out/invalid" >/dev/null
if "$grep_bin" -F 'The configuration is valid' "$scratch/out/invalid" >/dev/null; then
    echo 'keymapper-smoke: invalid configuration was reported valid' >&2
    exit 1
fi

# Without --config the checker uses the isolated $XDG_CONFIG_HOME file.
expect_status 0 "$scratch/out/default" \
    keymapper --check --no-notify --verbose
"$grep_bin" -Fx 'The configuration is valid' "$scratch/out/default" >/dev/null

# Command-line boundaries of the client, control tool and daemon; none of
# these connects to a server or opens a device.
expect_status 1 "$scratch/out/client-usage" keymapper --no-such-option
"$grep_bin" -Fx "keymapper $version" "$scratch/out/client-usage" >/dev/null
"$grep_bin" -F -- '--check              check the config for errors and exit.' \
    "$scratch/out/client-usage" >/dev/null
expect_status 2 "$scratch/out/control-usage" keymapperctl
"$grep_bin" -Fx "keymapperctl $version" "$scratch/out/control-usage" >/dev/null
"$grep_bin" -F -- '--print "string"' "$scratch/out/control-usage" >/dev/null
expect_status 1 "$scratch/out/daemon-usage" keymapperd --no-such-option
"$grep_bin" -Fx "keymapperd $version" "$scratch/out/daemon-usage" >/dev/null

# Terminal evidence: the same checks, traced by a real shell on a PTY.  The
# namespaces sit below `script`, so the PTY owner never becomes the reaper
# for the killed notification helper.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/out/terminal.raw}
isolated_env "$util_linux_out/bin/script" -q -e -E never -c \
    "$unshare_command $bash_out/bin/bash --noprofile --norc -c 'PS4=\"\\\$ \"; set -x; keymapper --check --no-notify --config valid.conf; keymapper --check --no-notify --config invalid.conf || :'" \
    "$raw" >/dev/null
"$grep_bin" -aF 'keymapper --check --no-notify --config valid.conf' "$raw" >/dev/null
"$grep_bin" -aF 'The configuration is valid' "$raw" >/dev/null
"$grep_bin" -aF 'ERROR: Unexpected symbol > at [>>] in line 2' "$raw" >/dev/null

# Only the fixtures remain; nothing was written to HOME or any XDG location
# other than the cache directory a killed notification helper may create.
test -z "$("$find_bin" "$scratch/home" "$scratch/data" "$scratch/state" \
    "$scratch/runtime" "$scratch/tmp" -mindepth 1 -print -quit)"
test "$("$find_bin" "$scratch/config" -mindepth 1 -print)" = \
    "$scratch/config/keymapper.conf"
test -z "$("$find_bin" "$scratch/cache" -mindepth 1 -type f -print -quit)"
test -z "$("$find_bin" "$scratch/work" -mindepth 1 ! -name valid.conf \
    ! -name invalid.conf -print -quit)"

after=$($guix_bin hash -S nar "$keymapper_out")
test "$before" = "$after"
test -z "$("$find_bin" "$keymapper_out" -xdev -type f -perm /222 -print -quit)"
printf '%s\n' 'KEYMAPPER_RUNTIME_OK'
