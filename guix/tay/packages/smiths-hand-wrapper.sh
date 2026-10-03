#!@SH@
# Keep the original relative asset/save layout outside the read-only store.
set -eu
if test "$#" -ne 0; then
    echo 'usage: smith (graphical game; no command-line options)' >&2
    exit 64
fi
umask 077
data='@DATA@'
state="${XDG_DATA_HOME:-${HOME:?HOME or XDG_DATA_HOME must be set}/.local/share}/the-smiths-hand"
case "$state" in
    /*) ;;
    *) echo 'smith: HOME/XDG_DATA_HOME must be absolute' >&2; exit 1 ;;
esac
'@MKDIR@' -p "$state/linux" "$state/rooms"
if test ! -e "$state/smith.cfg"; then
    '@CP@' "$data/smith.cfg" "$state/smith.cfg"
    '@CHMOD@' 600 "$state/smith.cfg"
fi
'@LN@' -sfn "$data/terminal.png" "$state/linux/terminal.png"
'@LN@' -sfn "$data/rooms/village.map" "$state/rooms/village.map"
'@LN@' -sfn "$data/text.txt" "$state/text.txt"
cd "$state/linux"
exec '@REAL@'
