#!@SH@
# Exalt resolves its assets, SQLite cache, saves and XML log against cwd.
# Keep immutable assets in the store and writable game state outside it.
set -eu
if test "$#" -ne 0; then
    echo 'usage: exalt (graphical game; no command-line options)' >&2
    exit 64
fi
umask 077
data='@DATA@'
state="${XDG_DATA_HOME:-${HOME:?HOME or XDG_DATA_HOME must be set}/.local/share}/exalt"
case "$state" in
    /*) ;;
    *) echo 'exalt: HOME/XDG_DATA_HOME must be absolute' >&2; exit 1 ;;
esac
'@MKDIR@' -p "$state/data/save"
for asset in display fonts help templates worlds; do
    '@LN@' -sfnT "$data/$asset" "$state/data/$asset"
done
'@LN@' -sfnT "$data/log.xsl" "$state/data/log.xsl"
# SQLite creates the FILE data/db itself.  data/save remains a real directory;
# log.xml is written here.  No save/resume functionality is added by this port.
cd "$state"
exec '@REAL@'
