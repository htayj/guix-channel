#!@SH@
# Preserve upstream's relative linux/ layout without store writes.
set -eu
if test "$#" -ne 0; then
    echo 'usage: babel7drl (graphical game; no command-line options)' >&2
    exit 64
fi
umask 077
data='@DATA@'
state="${XDG_DATA_HOME:-${HOME:?HOME or XDG_DATA_HOME must be set}/.local/share}/babel7drl"
case "$state" in
    /*) ;;
    *) echo 'babel7drl: HOME/XDG_DATA_HOME must be absolute' >&2; exit 1 ;;
esac
'@MKDIR@' -p "$state/linux" "$state/rooms" "$state/save"
if test ! -e "$state/babel.cfg"; then
    '@CP@' "$data/babel.cfg" "$state/babel.cfg"
    '@CHMOD@' 600 "$state/babel.cfg"
fi
'@LN@' -sfn "$data/terminal.png" "$state/linux/terminal.png"
'@LN@' -sfn "$data/rooms/village.map" "$state/rooms/village.map"
'@LN@' -sfn "$data/names.txt" "$state/names.txt"
'@LN@' -sfn "$data/text.txt" "$state/text.txt"
export TCODDIR="$state/linux"
cd "$state/linux"
exec '@REAL@'
