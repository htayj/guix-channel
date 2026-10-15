#!@SH@
# Upstream resolves assets and saves relative to linux/.  Preserve that layout
# outside the store, with only configuration and saves writable.
set -eu
if test "$#" -ne 0; then
    echo 'usage: everything-is-fodder (graphical game; no command-line options)' >&2
    exit 64
fi
umask 077
data='@DATA@'
state="${XDG_DATA_HOME:-${HOME:?HOME or XDG_DATA_HOME must be set}/.local/share}/everything-is-fodder"
case "$state" in
    /*) ;;
    *) echo 'everything-is-fodder: HOME/XDG_DATA_HOME must be absolute' >&2; exit 1 ;;
esac
'@MKDIR@' -p "$state/linux" "$state/rooms" "$state/save"
if test ! -e "$state/fodder.cfg"; then
    '@CP@' "$data/fodder.cfg" "$state/fodder.cfg"
    '@CHMOD@' 600 "$state/fodder.cfg"
fi
'@LN@' -sfn "$data/terminal.png" "$state/linux/terminal.png"
'@LN@' -sfn "$data/rooms/village.map" "$state/rooms/village.map"
'@LN@' -sfn "$data/text.txt" "$state/text.txt"
cd "$state/linux"
exec '@REAL@'
