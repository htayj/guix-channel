#!@SHELL@
# Exercise the installed You Only Live Once curses game in a real PTY.
#
# A fresh game is started, shows its welcome message on the "w" key, and is
# quit with "Q", which writes valley.sav.  A second, identical session must
# load that save (the game unlinks valley.sav only after a successful load),
# show the same message without starting a new game, and save again.  All
# mutable files live below a disposable HOME/XDG tree; the caller's own save
# is never touched.  The only line written to stdout is the success marker.
# GOOCASTLE_RUNTIME_RAW_CAPTURE receives the second session's PTY stream up to
# the restored game's screen, before quitting leaves the alternate screen.
set -eu

cat=@COREUTILS@/bin/cat
cksum=@COREUTILS@/bin/cksum
head=@COREUTILS@/bin/head
tr=@COREUTILS@/bin/tr
wc=@COREUTILS@/bin/wc
cp=@COREUTILS@/bin/cp
dirname=@COREUTILS@/bin/dirname
ls=@COREUTILS@/bin/ls
mkdir=@COREUTILS@/bin/mkdir
mktemp=@COREUTILS@/bin/mktemp
rm=@COREUTILS@/bin/rm
sleep=@COREUTILS@/bin/sleep
stty=@COREUTILS@/bin/stty
timeout=@COREUTILS@/bin/timeout
script=@UTIL_LINUX@/bin/script
output=@OUT@
launcher=@OUT@/bin/liveonce

if test "$#" -ne 0; then
    echo 'usage: liveonce-smoke' >&2
    exit 64
fi

fail ()
{
    printf 'liveonce-smoke: %s\n' "$1" >&2
    exit 1
}

scratch=$("$mktemp" -d "${TMPDIR:-/tmp}/liveonce-smoke.XXXXXXXX")
trap '"$rm" -rf "$scratch"' EXIT HUP INT TERM
"$mkdir" "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/work"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
# The game refuses anything but an 80-column terminal of at least 30 lines;
# script's PTY is resized to exactly that before the launcher runs.
export TERM=xterm LC_ALL=C SHELL=@SHELL@ ESCDELAY=100
work=$scratch/work
state=$XDG_DATA_HOME/liveonce
save=$state/valley.sav

# contains FILE TEXT: FILE exists and contains TEXT.
contains ()
{
    test -f "$1" || return 1
    case "$("$tr" -d '\000' <"$1")" in
        *"$2"*) return 0 ;;
    esac
    return 1
}

# wait_for FILE TEXT: wait up to 30 seconds for TEXT to appear in FILE.
wait_for ()
{
    tries=0
    until contains "$1" "$2"; do
        tries=$((tries + 1))
        test "$tries" -le 300 || return 1
        "$sleep" 0.1
    done
}

# feed RAW SESSION: type keys into the game once it has drawn each screen.
feed ()
{
    wait_for "$1" 'You are Timmy.' || return 1
    if test "$2" = second; then
        # The status line is drawn only after load_stuff() succeeded and
        # the game unlinked the save it restored.
        test ! -e "$save" || return 1
    fi
    printf w
    wait_for "$1" 'Welcome Message:' || return 1
    if test "$2" = second; then
        # Let curses finish this refresh, then keep the stream as written so
        # far: the restored game's map, status line, and requested message,
        # before quitting leaves the alternate screen.
        "$sleep" 1
        "$cp" "$1" "$work/second.frame.raw"
    fi
    printf '\033'
    "$sleep" 1
    printf Q
    wait_for "$1" 'Done.' || return 1
    test -s "$save" || return 1
    # The game drops one pending key before waiting for the final one.
    "$sleep" 0.5
    printf ' '
}

# play SESSION: run one complete PTY session of the installed launcher.
play ()
{
    raw=$work/$1.raw
    : >"$raw"
    if ! { feed "$raw" "$1" || : >"$work/$1.feed-failed"; } | \
            "$timeout" 120 "$script" -qefc \
            "\"$stty\" rows 30 cols 80; exec \"$launcher\"" /dev/null \
            >"$raw" 2>"$work/$1.err"; then
        "$cat" "$work/$1.err" >&2
        fail "$1 session did not exit cleanly"
    fi
    test ! -e "$work/$1.feed-failed" || fail "$1 session did not respond"
    contains "$raw" 'Saving...' || fail "$1 session did not save"
    contains "$raw" 'Done.  Hit a key to quit.' || fail "$1 session did not finish"
}

# before_first FILE FIRST SECOND: FIRST occurs in FILE before SECOND.
before_first ()
{
    text=$("$tr" -d '\000' <"$1")
    prefix=${text%%"$3"*}
    test "$prefix" != "$text" || return 1
    case "$prefix" in
        *"$2"*) return 0 ;;
    esac
    return 1
}

welcome='Welcome to You Only Live Once!'

# First session: no save exists, so a new game starts with Timmy's welcome.
"$rm" -f "$save"
play first
test -s "$save" || fail 'first session did not create valley.sav'
before_first "$work/first.raw" "$welcome" 'Welcome Message:' || \
    fail 'first session did not start a new game'
"$cp" "$save" "$work/first.sav"

# Second session: the save is loaded instead, so no new-game welcome is shown
# before the requested one, and quitting saves again.
play second
test -s "$save" || fail 'second session did not save again'
before_first "$work/second.raw" 'Welcome Message:' "$welcome" || \
    fail 'second session did not load the saved game'

# The only mutable file is the save in the launcher's XDG data directory.
test "$("$ls" -A "$state")" = valley.sav || fail 'unexpected state files'
test "$("$ls" -A "$scratch/data")" = liveonce || fail 'unexpected data files'
for dir in "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" \
           "$XDG_RUNTIME_DIR"; do
    test -z "$("$ls" -A "$dir")" || fail "unexpected files in $dir"
done
test ! -w "$output" || fail 'package output is writable'
for dir in "$output/bin" "$output/libexec" "$output/share/liveonce"; do
    test ! -e "$dir/valley.sav" || fail "save escaped into $dir"
done

# The evidence frame is an unmodified leading part of the second session's
# PTY stream: the loaded game on screen after "w", before "Q" saved it and
# the exit left curses' alternate screen.
frame=$work/second.frame.raw
test -s "$frame" || fail 'no post-load gameplay frame was captured'
frame_size=$("$wc" -c <"$frame")
test "$("$head" -c "$frame_size" "$work/second.raw" | "$cksum")" = \
    "$("$cksum" <"$frame")" || fail 'gameplay frame is not a stream prefix'
contains "$frame" 'You are Timmy.' || fail 'gameplay frame lacks the status'
before_first "$frame" 'Welcome Message:' "$welcome" || \
    fail 'gameplay frame does not show the loaded game'
! contains "$frame" 'Saving...' || fail 'gameplay frame includes the quit'

if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    "$mkdir" -p "$("$dirname" "$GOOCASTLE_RUNTIME_RAW_CAPTURE")"
    "$cp" "$frame" "$GOOCASTLE_RUNTIME_RAW_CAPTURE"
fi

printf '%s\n' 'Done.'
