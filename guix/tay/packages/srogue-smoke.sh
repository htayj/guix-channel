#!@SHELL@
# srogue --guix-smoke: play, save and restore a real Super-Rogue game in PTYs.
#
# The first session starts a new game as "Smoke Tester" (ROGUEOPTS skips the
# name prompt), lists the food with 'e' '*', takes a turn to eat one piece of
# item a, the food every new character starts with, views the pack with 'i',
# and saves with 'S' 'y'.  The second session restores that save, which the
# game unlinks once it has read it; its pack must be the one the first
# session saved.  It then quits with 'Q' 'y' and
# passes the pack and score screens.  Every key is sent only after the screen
# it answers was drawn, and a session that exits early fails at once with
# its own output.
#
# The first session finds its state through XDG_DATA_HOME and the second
# through the HOME fallback, which name the same directory.  All mutable
# files live below a disposable HOME/XDG tree that is removed on exit; the
# caller's own state is never touched.  The only line written to stdout is
# the success marker.  GOOCASTLE_RUNTIME_RAW_CAPTURE, when set, receives the
# second session's PTY stream up to the restored game's map, before quitting
# leaves the alternate screen.
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
rm=@COREUTILS@/bin/rm
sleep=@COREUTILS@/bin/sleep
stty=@COREUTILS@/bin/stty
tail=@COREUTILS@/bin/tail
timeout=@COREUTILS@/bin/timeout
tr=@COREUTILS@/bin/tr
wc=@COREUTILS@/bin/wc
script=@UTIL_LINUX@/bin/script
output=@OUT@
launcher=@OUT@/bin/srogue

if test "$#" -ne 0; then
    echo 'usage: srogue --guix-smoke' >&2
    exit 64
fi

fail ()
{
    printf 'srogue smoke: %s\n' "$1" >&2
    exit 1
}

tmp=${TMPDIR:-/tmp}
case "$tmp" in
    /*) ;;
    *) fail 'TMPDIR must be an absolute directory' ;;
esac
# The state directory below is TMPDIR plus 39 bytes.  The launcher accepts
# at most 68, and the save prompt, which the restored game redraws, fits on
# one 80-column line only up to 54, so use /tmp when TMPDIR is deeper.
if test "$(LC_ALL=C; printf %s "${#tmp}")" -gt 15; then
    tmp=/tmp
fi
scratch=$("$mktemp" -d "$tmp/srogue.XXXXXX")
trap '"$rm" -rf "$scratch"' EXIT HUP INT TERM
"$mkdir" "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/runtime" "$scratch/tmp" "$scratch/work"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
unset XDG_DATA_HOME XDG_STATE_HOME ROGUEHOME
# The game needs at least 24 lines of 80 columns and a real terminal type.
export TERM=xterm LC_ALL=C SHELL=@SHELL@
export ROGUEOPTS='name=Smoke Tester'
work=$scratch/work
state=$HOME/.local/share/srogue
save=$state/srogue.sav
exited='[srogue smoke: game exited with status'
esc=$(printf '\033')

# text FILE: FILE's PTY stream without NUL bytes.
text ()
{
    "$tr" -d '\000' <"$1"
}

# size FILE: the number of bytes the session has written so far.
size ()
{
    "$wc" -c <"$1"
}

# seen FILE TEXT: TEXT occurs in FILE after its first $mark bytes, which
# were written before the last key was sent.
mark=0
seen ()
{
    test -f "$1" || return 1
    case "$("$tail" -c "+$((mark + 1))" "$1" | "$tr" -d '\000')" in
        *"$2"*) return 0 ;;
    esac
    return 1
}

# ate FILE: the game reported eating the food since the last key.
ate ()
{
    seen "$1" 'Yum, that tasted good.' || \
        seen "$1" 'Yuk, this food tastes like ARA.' || \
        seen "$1" 'My, that was a yummy '
}

# ended FILE: the session's shell reported that the game exited.
ended ()
{
    case "$(text "$1")" in
        *"$exited "*) return 0 ;;
    esac
    return 1
}

# exited_with FILE STATUS: the game exited with STATUS.
exited_with ()
{
    case "$(text "$1")" in
        *"$exited $2]"*) return 0 ;;
    esac
    return 1
}

# wait_until FILE CONDITION [TEXT]: wait up to 30 seconds for CONDITION.
# A game that exits first ends the wait at once.
wait_until ()
{
    tries=0
    until "$2" "$1" "${3-}"; do
        # Test the condition once more: the game may have written it just
        # before exiting.
        if ended "$1" && ! "$2" "$1" "${3-}"; then
            printf 'srogue smoke: the game exited while waiting for %s\n' \
                "${3-$2}" >"$1.why"
            return 1
        fi
        tries=$((tries + 1))
        if test "$tries" -gt 300; then
            printf 'srogue smoke: timed out waiting for %s\n' "${3-$2}" \
                >"$1.why"
            return 1
        fi
        "$sleep" 0.1
    done
}

wait_for ()
{
    wait_until "$1" seen "$2"
}

# key FILE KEY: send KEY and remember how much output preceded it.
key ()
{
    mark=$(size "$1")
    printf %s "$2"
}

# inventory FILE STAGE: keep the pack page drawn since the last key, from the
# screen clear that starts it up to its prompt, as FILE.STAGE.pack.
inventory ()
{
    page=$("$tail" -c "+$((mark + 1))" "$1" | "$tr" -d '\000')
    page=${page##*"$esc[2J"}
    page=${page%%'-- Press space to continue --'*}
    printf '%s\n' "$page" >"$1.$2.pack"
}

# quiet FILE: wait until the session has written nothing for half a second.
quiet ()
{
    tries=0
    last=-1
    while test "$(size "$1")" != "$last"; do
        last=$(size "$1")
        tries=$((tries + 1))
        if test "$tries" -gt 60; then
            printf 'srogue smoke: the screen never settled\n' >"$1.why"
            return 1
        fi
        "$sleep" 0.5
    done
}

# dismiss_more FILE: acknowledge every "-- More --" prompt that ends the
# output since the last key, such as a monster's move after a turn.  At such
# a prompt the game has drawn at most a cursor movement after it.
dismiss_more ()
{
    count=0
    while :; do
        quiet "$1" || return 1
        since=$("$tail" -c "+$((mark + 1))" "$1" | "$tr" -d '\000')
        case "$since" in
            *'-- More --'*) ;;
            *) return 0 ;;
        esac
        after=${since##*'-- More --'}
        test "${#after}" -lt 16 || return 0
        count=$((count + 1))
        if test "$count" -gt 10; then
            printf 'srogue smoke: too many -- More -- prompts\n' >"$1.why"
            return 1
        fi
        key "$1" ' '
    done
}

# map FILE: wait for the map and both status lines to be redrawn.
map ()
{
    wait_for "$1" 'Level: 1  Gold:' || return 1
    wait_for "$1" 'Hp: ' || return 1
    wait_for "$1" 'Carry:' || return 1
}

# feed RAW SESSION: type each key once the game has drawn the screen it
# answers.
feed ()
{
    mark=0
    map "$1" || return 1
    if test "$2" = first; then
        # Eat the ration every new character starts with; that takes a turn.
        key "$1" e
        wait_for "$1" 'eat what (* for the item)?' || return 1
        key "$1" '*'
        # With a single kind of food, the listing is one message.
        wait_for "$1" '-- More --' || return 1
        food=$("$tail" -c "+$((mark + 1))" "$1" | "$tr" -d '\000')
        food=${food#*'a) '}
        food=${food%%"$esc"*}
        case "$food" in
            'Some food.' | *' rations of food.' | *'juicy-fruit'*) ;;
            *) printf 'srogue smoke: unexpected food %s\n' "$food" >"$1.why"
               return 1 ;;
        esac
        printf '%s\n' "$food" >"$1.food"
        key "$1" ' '
        wait_for "$1" 'eat what (* for the item)?' || return 1
        key "$1" a
        wait_until "$1" ate || return 1
        dismiss_more "$1" || return 1
    else
        # The map is drawn only after the save was read and unlinked.
        if test -e "$save"; then
            printf 'srogue smoke: the save was not restored\n' >"$1.why"
            return 1
        fi
    fi
    key "$1" i
    wait_for "$1" 'being worn' || return 1
    wait_for "$1" '-- Press space to continue --' || return 1
    inventory "$1" "$2"
    key "$1" ' '
    map "$1" || return 1
    if test "$2" = first; then
        key "$1" S
        # The prompt names the save's full path, which curses may wrap.
        wait_for "$1" 'Save file (/' || return 1
        wait_for "$1" ')?' || return 1
        key "$1" y
        return 0
    fi
    # Let curses finish this refresh, then keep the stream as written so
    # far: the restored game's map with both status lines.
    "$sleep" 1
    "$cp" "$1" "$work/second.frame.raw"
    key "$1" Q
    # A message still on the top line is acknowledged first.
    dismiss_more "$1" || return 1
    wait_for "$1" 'Really quit? [y/n/s]' || return 1
    key "$1" y
    wait_for "$1" '[Press return to continue]' || return 1
    key "$1" "$(printf '\r')"
    wait_for "$1" 'Contents of your pack when you chickened out:' || return 1
    wait_for "$1" '[Press return to continue]' || return 1
    key "$1" "$(printf '\r')"
    wait_for "$1" 'Top Ten Adventurers:' || return 1
    wait_for "$1" '[Press return to exit]' || return 1
    key "$1" "$(printf '\r')"
}

# play SESSION [ARG]: run one complete PTY session of the installed launcher.
# The keys go through a FIFO so that a session whose screen never appears is
# stopped at once instead of waiting for the timeout.
play ()
{
    raw=$work/$1.raw
    input=$work/$1.input
    : >"$raw"
    "$mkfifo" "$input"
    "$timeout" 50 "$script" -qefc \
        "\"$stty\" rows 24 cols 80 && \"$launcher\" ${2:+\"$2\"}; status=\$?; printf '\\n%s %s]\\n' '$exited' \"\$status\"; exit \"\$status\"" \
        /dev/null <"$input" >"$raw" 2>"$work/$1.err" &
    session=$!
    exec 3>"$input"
    # A key written after the game exited must not kill this shell.
    if ( trap '' PIPE; feed "$raw" "$1" ) >&3; then
        status=0
        wait_until "$raw" ended || status=failed
        exec 3>&-
        wait "$session" || status=$?
    else
        exec 3>&-
        kill "$session" 2>/dev/null || :
        wait "$session" || :
        status=failed
    fi
    if test "$status" != 0; then
        test ! -s "$raw.why" || "$cat" "$raw.why" >&2
        printf 'srogue smoke: last output of the %s session:\n' "$1" >&2
        text "$raw" | "$tr" -c '[:print:]\n' ' ' | "$tail" -n 5 >&2
        "$cat" "$work/$1.err" >&2
        fail "$1 session did not complete (status $status)"
    fi
    exited_with "$raw" 0 || fail "$1 session did not exit cleanly"
}

# The absolute paths keep the launcher's state directory within 68 bytes.
test "$(LC_ALL=C; printf %s "${#state}")" -le 68 || \
    fail 'scratch directory is too long'

# First session: no save exists, so a new game starts.  XDG_DATA_HOME names
# the state directory explicitly.
export XDG_DATA_HOME="$HOME/.local/share"
play first
unset XDG_DATA_HOME
mark=0
seen "$work/first.raw" 'Hello Smoke Tester, One moment while I open the door' \
    || fail 'first session did not start a game for Smoke Tester'
test -s "$save" || fail 'first session did not create srogue.sav'
"$cp" "$save" "$work/first.sav"
# Eating used up one piece of the starting food, item a.
case "$("$cat" "$work/first.raw.first.pack")" in
    *"a) $("$cat" "$work/first.raw.food")"*)
        fail 'eating did not change the food in the pack' ;;
esac

# Second session: XDG_DATA_HOME is unset, so the launcher falls back to the
# same directory below HOME, and the save named on the command line is
# restored.
play second "$save"
test ! -e "$save" || fail 'the restored save was not consumed'
"$cmp" -s "$work/first.raw.first.pack" "$work/second.raw.second.pack" || \
    fail 'the restored game has a different pack'

# The game quit with no gold, so it recorded no score, but it keeps its
# per-user score list of ten empty 180-byte entries in the state directory.
test "$("$ls" -A "$state")" = srogue.scr || fail 'unexpected state files'
test "$(size "$state/srogue.scr")" = 1800 || fail 'unexpected score file'
test "$("$ls" -A "$HOME")" = .local || fail 'unexpected files in HOME'
test "$("$ls" -A "$HOME/.local")" = share || fail 'unexpected files in HOME'
test "$("$ls" -A "$HOME/.local/share")" = srogue || \
    fail 'unexpected files in HOME'
for dir in "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR" \
           "$TMPDIR"; do
    test -z "$("$ls" -A "$dir")" || fail "unexpected files in $dir"
done
for file in "$work/first.sav" "$state/srogue.scr"; do
    case "$(text "$file")" in
        */gnu/store*) fail "$file refers to the store" ;;
    esac
done
test ! -w "$output" || fail 'package output is writable'
for dir in "$output/bin" "$output/libexec/srogue"; do
    test ! -e "$dir/srogue.sav" || fail "save escaped into $dir"
    test ! -e "$dir/srogue.scr" || fail "scores escaped into $dir"
done

# The evidence frame is an unmodified leading part of the second session's
# PTY stream: the restored game's map and status lines, before 'Q' quit it
# and the exit left curses' alternate screen.
frame=$work/second.frame.raw
test -s "$frame" || fail 'no restored gameplay frame was captured'
frame_size=$(size "$frame")
test "$("$head" -c "$frame_size" "$work/second.raw" | "$cksum")" = \
    "$("$cksum" <"$frame")" || fail 'gameplay frame is not a stream prefix'
mark=0
for want in 'Level: 1  Gold:' 'Hp: ' 'Str: ' 'Carry:' 'being worn' \
            '-- Press space to continue --'; do
    seen "$frame" "$want" || fail "gameplay frame lacks '$want'"
done
! seen "$frame" 'Really quit' || fail 'gameplay frame includes the quit'

if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    "$mkdir" -p "$("$dirname" "$GOOCASTLE_RUNTIME_RAW_CAPTURE")"
    "$cp" "$frame" "$GOOCASTLE_RUNTIME_RAW_CAPTURE"
fi

printf '%s\n' SROGUE_GUIX_SMOKE_OK
