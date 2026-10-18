#!/bin/sh
# Keep immutable game assets in the store and all ordinary state in XDG data.
set -eu
state=${XDG_DATA_HOME:-${HOME:?HOME or XDG_DATA_HOME must be set}/.local/share}/faangband
(umask 077; @MKDIR@ -p -- "$state/user" "$state/save" "$state/scores" \
    "$state/archive" "$state/info" "$state/bone")
# Do not change the caller's working directory: -u and frontend options may
# contain relative paths.  Resolve only the state root to an absolute path.
state=$(CDPATH= cd -- "$state" && pwd -P)
# Seed only the upstream user-help examples; never replace player edits.
# These are documentation, not a preseeded save or game configuration.
for file in user.hlp dummy.txt; do
    if test ! -e "$state/info/$file"; then
        (umask 077; @CP@ --no-clobber -- "@DATA@/user/info/$file" "$state/info/$file")
    fi
done
export TERMINFO_DIRS="@TERMINFO@${TERMINFO_DIRS:+:$TERMINFO_DIRS}"
# Defaults precede user arguments.  In particular, -l and -u must see the
# writable save path immediately, and -- must still delimit frontend options.
# Explicit user -d overrides retain their normal last-option-wins semantics.
exec @GAME@ \
    "-dgamedata=@DATA@/gamedata" "-dpref=@DATA@/customize" \
    "-dhelp=@DATA@/help" "-dscreens=@DATA@/screens" \
    "-dfonts=@DATA@/fonts" "-dtiles=@DATA@/tiles" \
    "-dsounds=@DATA@/sounds" "-dicons=@DATA@/icons" \
    "-dghost=@DATA@/ghost" \
    "-duser=$state/user" "-dsave=$state/save" "-dscores=$state/scores" \
    "-darchive=$state/archive" "-dinfo=$state/info" "-dbone=$state/bone" \
    "$@"
