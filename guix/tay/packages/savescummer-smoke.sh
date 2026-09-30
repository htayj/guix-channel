#!@SHELL@
# savescummer --smoke: play, save, and reload a real Save Scummer game in PTYs.
#
# The first session starts a new game: it accepts the rolled character with
# the right arrow, advances time three turns with the right arrow (the hero's
# own AI acts and the monsters move), writes backup slot 0 with 's', advances
# one more turn, restores slot 0 with 'r', inspects the character sheet with
# 'i', and quits with 'Q', which writes savescummer.sav.  Should the hero die
# during a turn, the left arrow undoes that turn as the game offers.  The
# second session must load that save (the game unlinks savescummer.sav right
# after load_stuff() read it, before the first key is read), shows the
# character sheet again, and saves again; both saves must record the same
# score, avatar, and dungeon level.  The first session finds its state through
# XDG_STATE_HOME and the second through the HOME fallback, which name the same
# directory.  Every key is sent only after the screen it answers was drawn,
# and a session that exits early fails at once with its own output.
#
# All mutable files live below a disposable HOME/XDG tree that is removed on
# exit; the caller's own save is never touched.  The only line written to
# stdout is the success marker.  GOOCASTLE_RUNTIME_RAW_CAPTURE, when set,
# receives the second session's PTY stream up to the restored game's
# character sheet, before quitting leaves the alternate screen.
set -eu

cat=@COREUTILS@/bin/cat
cksum=@COREUTILS@/bin/cksum
cmp=@DIFFUTILS@/bin/cmp
cp=@COREUTILS@/bin/cp
dirname=@COREUTILS@/bin/dirname
head=@COREUTILS@/bin/head
ls=@COREUTILS@/bin/ls
mkdir=@COREUTILS@/bin/mkdir
mkfifo=@COREUTILS@/bin/mkfifo
mktemp=@COREUTILS@/bin/mktemp
od=@COREUTILS@/bin/od
rm=@COREUTILS@/bin/rm
sleep=@COREUTILS@/bin/sleep
stty=@COREUTILS@/bin/stty
tail=@COREUTILS@/bin/tail
timeout=@COREUTILS@/bin/timeout
tr=@COREUTILS@/bin/tr
wc=@COREUTILS@/bin/wc
script=@UTIL_LINUX@/bin/script
output=@OUT@
launcher=@OUT@/bin/savescummer

if test "$#" -ne 0; then
    echo 'usage: savescummer --smoke' >&2
    exit 64
fi

fail ()
{
    printf 'savescummer smoke: %s\n' "$1" >&2
    exit 1
}

tmp=${TMPDIR:-/tmp}
case "$tmp" in
    /*) ;;
    *) fail 'TMPDIR must be an absolute directory' ;;
esac
scratch=$("$mktemp" -d "$tmp/savescummer-smoke.XXXXXXXX")
trap '"$rm" -rf "$scratch"' EXIT HUP INT TERM
"$mkdir" "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/runtime" "$scratch/tmp" "$scratch/work"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
unset XDG_STATE_HOME
# The curses port draws an 80x30 screen; script's PTY is resized to exactly
# that before the launcher runs.  Under TERM=xterm, curses enables the
# keypad's application mode, in which the arrow keys send ESC O C and ESC O D.
export TERM=xterm LC_ALL=C SHELL=@SHELL@
right=$(printf '\033OC')
left=$(printf '\033OD')
work=$scratch/work
state=$HOME/.local/state/savescummer
save=$state/savescummer.sav
exited='[savescummer smoke: game exited with status'
died='Hit Q to Start Again, Left Arrow to Undo.'

# text FILE: FILE's PTY stream without NUL bytes.
text ()
{
    "$tr" -d '\000' <"$1"
}

# contains FILE TEXT: FILE exists and its stream contains TEXT.
contains ()
{
    test -f "$1" || return 1
    case "$(text "$1")" in
        *"$2"*) return 0 ;;
    esac
    return 1
}

# size FILE: the number of bytes the session has written so far.
size ()
{
    "$wc" -c <"$1"
}

# wait_until FILE CONDITION ARG: wait up to 30 seconds for CONDITION FILE ARG.
# A game that exits first ends the wait at once.
wait_until ()
{
    tries=0
    until "$2" "$1" "$3"; do
        if contains "$1" "$exited"; then
            printf 'savescummer smoke: the game exited early\n' >"$1.why"
            return 1
        fi
        tries=$((tries + 1))
        if test "$tries" -gt 300; then
            printf 'savescummer smoke: timed out waiting for %s\n' "$3" \
                >"$1.why"
            return 1
        fi
        "$sleep" 0.1
    done
}

wait_for ()
{
    wait_until "$1" contains "$2"
}

# grown FILE SIZE: FILE is now longer than SIZE bytes.
grown ()
{
    test "$(size "$1")" -gt "$2"
}

# settle FILE: wait until the game has stopped drawing, that is, until FILE
# did not grow for half a second.
settle ()
{
    tries=0
    last=$(size "$1")
    while :; do
        "$sleep" 0.5
        now=$(size "$1")
        test "$now" != "$last" || return 0
        last=$now
        tries=$((tries + 1))
        if test "$tries" -gt 60; then
            printf 'savescummer smoke: the screen never settled\n' >"$1.why"
            return 1
        fi
    done
}

# drawn_since FILE OFFSET TEXT: TEXT occurs in FILE after its first OFFSET
# bytes.
drawn_since ()
{
    case "$("$tail" -c +"$(($2 + 1))" "$1" | "$tr" -d '\000')" in
        *"$3"*) return 0 ;;
    esac
    return 1
}

# turn FILE: advance time by one turn and wait until it has been drawn.  A
# turn that killed the hero is undone with the left arrow.
turn ()
{
    before=$(size "$1")
    printf '%s' "$right"
    wait_until "$1" grown "$before" || return 1
    settle "$1" || return 1
    if drawn_since "$1" "$before" "$died"; then
        before=$(size "$1")
        printf '%s' "$left"
        wait_until "$1" grown "$before" || return 1
        settle "$1" || return 1
    fi
}

# sheet FILE: show the character sheet.
sheet ()
{
    printf i
    wait_for "$1" 'Your character sheet:' || return 1
    wait_for "$1" 'HP Quartiles:' || return 1
    settle "$1"
}

# feed RAW SESSION: type each key once the game has drawn the screen it
# answers.
feed ()
{
    if test "$2" = first; then
        # A new game: the welcome text and the rolled character.
        wait_for "$1" 'Welcome to Save Scummer!' || return 1
        wait_for "$1" '(Left: reroll.  Right: accept.)' || return 1
        settle "$1" || return 1
        # The reroll screen already shows the status line, so the accepted
        # game is recognized by the output it draws after the key.
        before=$(size "$1")
        printf '%s' "$right"
        wait_until "$1" grown "$before" || return 1
        settle "$1" || return 1
        turn "$1" || return 1
        turn "$1" || return 1
        turn "$1" || return 1
        printf s
        wait_for "$1" 'Which slot? [0-9]' || return 1
        settle "$1" || return 1
        printf 0
        wait_for "$1" 'Slot written.' || return 1
        settle "$1" || return 1
        turn "$1" || return 1
        printf r
        wait_for "$1" 'Restore which backup file...' || return 1
        settle "$1" || return 1
        printf 0
        wait_for "$1" 'Restored save game.' || return 1
        settle "$1" || return 1
        sheet "$1" || return 1
    else
        # The loaded game: the welcome-back text and the status line.  The
        # game unlinked the save it restored before reading the first key.
        wait_for "$1" 'Welcome back to Save Scummer!' || return 1
        wait_for "$1" 'Health:' || return 1
        settle "$1" || return 1
        if test -e "$save"; then
            printf 'savescummer smoke: the save was not loaded\n' >"$1.why"
            return 1
        fi
        sheet "$1" || return 1
        # Keep the stream as written so far: the restored game's map,
        # status line, and character sheet.
        "$cp" "$1" "$work/second.frame.raw"
    fi
    printf Q
    wait_for "$1" 'Saving...' || return 1
    wait_for "$1" 'Done.  Hit a key to quit.' || return 1
    # The game discards keys typed before it clears its key buffer, so keep
    # offering one until it exits.
    tries=0
    until contains "$1" "$exited"; do
        tries=$((tries + 1))
        if test "$tries" -gt 150; then
            printf 'savescummer smoke: the game did not quit\n' >"$1.why"
            return 1
        fi
        printf ' '
        "$sleep" 0.2
    done
}

# play SESSION: run one complete PTY session of the installed launcher.  The
# keys go through a FIFO so that a session whose screen never appears is
# stopped at once instead of waiting for the timeout.
play ()
{
    raw=$work/$1.raw
    input=$work/$1.input
    : >"$raw"
    "$mkfifo" "$input"
    "$timeout" 180 "$script" -qefc \
        "\"$stty\" rows 30 cols 80 && \"$launcher\"; status=\$?; printf '\\n%s %s]\\n' '$exited' \"\$status\"; exit \"\$status\"" \
        /dev/null <"$input" >"$raw" 2>"$work/$1.err" &
    session=$!
    exec 3>"$input"
    # A key written after the game exited must not kill this shell.
    if ( trap '' PIPE; feed "$raw" "$1" ) >&3; then
        exec 3>&-
        status=0
        wait "$session" || status=$?
    else
        exec 3>&-
        kill "$session" 2>/dev/null || :
        wait "$session" || :
        status=failed
    fi
    if test "$status" != 0; then
        test ! -s "$raw.why" || "$cat" "$raw.why" >&2
        printf 'savescummer smoke: last output of the %s session:\n' "$1" >&2
        text "$raw" | "$tr" -c '[:print:]\n' ' ' | "$tail" -n 5 >&2
        "$cat" "$work/$1.err" >&2
        fail "$1 session did not complete (status $status)"
    fi
    contains "$raw" "$exited 0]" || fail "$1 session did not exit cleanly"
}

# before_first FILE FIRST SECOND: FIRST occurs in FILE before SECOND.
before_first ()
{
    stream=$(text "$1")
    prefix=${stream%%"$3"*}
    test "$prefix" != "$stream" || return 1
    case "$prefix" in
        *"$2"*) return 0 ;;
    esac
    return 1
}

# First session: no save exists, so a new game starts.  XDG_STATE_HOME names
# the state directory explicitly.
export XDG_STATE_HOME="$HOME/.local/state"
play first
unset XDG_STATE_HOME
test -s "$save" || fail 'first session did not create savescummer.sav'
before_first "$work/first.raw" 'Slot written.' 'Restored save game.' || \
    fail 'first session did not write a backup slot before restoring it'
before_first "$work/first.raw" 'Your character sheet:' 'Saving...' || \
    fail 'first session did not show the character sheet before saving'
"$cp" "$save" "$work/first.sav"

# Second session: XDG_STATE_HOME is unset, so the launcher falls back to the
# same directory below HOME, loads the save, and saves again.
play second
test -s "$save" || fail 'second session did not save again'
before_first "$work/second.raw" 'Welcome back to Save Scummer!' \
    'Your character sheet:' || fail 'second session did not load the save'
before_first "$work/second.raw" 'Your character sheet:' 'Saving...' || \
    fail 'second session did not show the character sheet before saving'

# int FILE OFFSET: the native 32-bit integer at OFFSET in FILE.
int ()
{
    value=$("$od" -An -v -td4 -j "$2" -N 4 "$1" | "$tr" -d ' ')
    test -n "$value" || return 1
    printf '%s\n' "$value"
}

# header_size FILE: the length of the save up to the first map's creature
# list: the score (4), the avatar's mana, probability, exponent, race, role,
# and playback delay (28), its HP distribution (bounds 8, 8 per value), the
# map marker (1), the map size (8), its tile and flag arrays, and its room
# count (4).
header_size ()
{
    low=$(int "$1" 32) || return 1
    high=$(int "$1" 36) || return 1
    test "$high" -ge "$low" || return 1
    map=$((40 + (high - low + 1) * 8))
    width=$(int "$1" $((map + 1))) || return 1
    height=$(int "$1" $((map + 5))) || return 1
    test "$width" -gt 0 && test "$height" -gt 0 || return 1
    header=$((map + 1 + 8 + 2 * width * height + 4))
    test "$(size "$1")" -gt "$header" || return 1
    printf '%s\n' "$header"
}

# No turn passed in the second session, so the re-saved game has the same
# size and begins with the same score, avatar, HP distribution, and dungeon
# map.  Only the order of the map's creature and item lists, which loading
# reverses, may differ.
header=$(header_size "$work/first.sav") || fail 'the first save is truncated'
test "$(header_size "$save")" = "$header" || \
    fail 'the reloaded game saved a different map'
test "$(size "$work/first.sav")" = "$(size "$save")" || \
    fail 'the reloaded game saved a different game'
"$cmp" -s -n "$header" "$work/first.sav" "$save" || \
    fail 'the reloaded game saved a different score, avatar, or map'

# The only mutable file is the save in the launcher's state directory; the
# game wrote no high score because no death was accepted.
test "$("$ls" -A "$state")" = savescummer.sav || fail 'unexpected state files'
test "$("$ls" -A "$HOME")" = .local || fail 'unexpected files in HOME'
for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" \
           "$XDG_RUNTIME_DIR" "$TMPDIR"; do
    test -z "$("$ls" -A "$dir")" || fail "unexpected files in $dir"
done
test ! -w "$output" || fail 'package output is writable'
for dir in "$output/bin" "$output/libexec/savescummer" \
           "$output/share/savescummer"; do
    test ! -e "$dir/savescummer.sav" || fail "save escaped into $dir"
    test ! -e "$dir/hiscore.txt" || fail "high scores escaped into $dir"
done

# The evidence frame is an unmodified leading part of the second session's
# PTY stream: the loaded game with its character sheet, before 'Q' saved it
# and the exit left curses' alternate screen.
frame=$work/second.frame.raw
test -s "$frame" || fail 'no post-load gameplay frame was captured'
frame_size=$(size "$frame")
test "$("$head" -c "$frame_size" "$work/second.raw" | "$cksum")" = \
    "$("$cksum" <"$frame")" || fail 'gameplay frame is not a stream prefix'
for want in 'Welcome back to Save Scummer!' 'Health:' 'Prob:' \
            'Your character sheet:' 'HP Quartiles:'; do
    contains "$frame" "$want" || fail "gameplay frame lacks '$want'"
done
! contains "$frame" 'Saving...' || fail 'gameplay frame includes the quit'

if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    "$mkdir" -p "$("$dirname" "$GOOCASTLE_RUNTIME_RAW_CAPTURE")"
    "$cp" "$frame" "$GOOCASTLE_RUNTIME_RAW_CAPTURE"
fi

printf '%s\n' SAVESCUMMER_RUNTIME_OK
