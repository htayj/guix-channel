#!@SH@
# Upstream resolves assets and saves relative to linux/.  Preserve that layout
# outside the store, with only configuration and saves writable.
set -eu
if test "$#" -ne 0; then
    echo 'usage: six-two-one (graphical game; no command-line options)' >&2
    exit 64
fi
umask 077
data='@DATA@'
state="${XDG_DATA_HOME:-${HOME:?HOME or XDG_DATA_HOME must be set}/.local/share}/six-two-one"
case "$state" in
    /*) ;;
    *) echo 'six-two-one: HOME/XDG_DATA_HOME must be absolute' >&2; exit 1 ;;
esac
'@MKDIR@' -p "$state/linux" "$state/rooms" "$state/wordlist" "$state/save"
if test ! -e "$state/sixtwoone.cfg"; then
    '@CP@' "$data/sixtwoone.cfg" "$state/sixtwoone.cfg"
    '@CHMOD@' 600 "$state/sixtwoone.cfg"
fi
'@LN@' -sfn "$data/terminal.png" "$state/linux/terminal.png"
'@LN@' -sfn "$data/rooms/village.map" "$state/rooms/village.map"
'@LN@' -sfn "$data/wordlist/wordlist.txt" "$state/wordlist/wordlist.txt"
'@LN@' -sfn "$data/text.txt" "$state/text.txt"
cd "$state/linux"
exec '@REAL@'
