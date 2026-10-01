#!/bin/sh
# Umoria's data is immutable; only per-user scores and saves are writable.
set -eu
state=${XDG_STATE_HOME:-${HOME:?HOME must be set}/.local/state}/umoria
(umask 077; @MKDIR@ -p -- "$state")
# Make the default save path absolute without changing the caller's working
# directory: explicit SAVEGAME and character-sheet paths retain upstream meaning.
state=$(CDPATH= cd -- "$state" && pwd -P)
if test ! -e "$state/scores.dat"; then
    @CP@ --no-clobber -- "@DATA@/scores.dat" "$state/scores.dat"
    @CHMOD@ 600 "$state/scores.dat"
fi
export UMORIA_STATE_DIRECTORY="$state"
exec @GAME@ "$@"
