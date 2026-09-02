#!/bin/sh
# Regression test for ncurses CSI REP sequences in terminal evidence frames.
set -eu

channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
raw=$(mktemp -t goocastle-terminal-raw.XXXXXX)
text=$(mktemp -t goocastle-terminal-text.XXXXXX)
trap 'rm -f "$raw" "$text"' EXIT HUP INT TERM

# A representative ncurses frame: ACS box glyphs are represented by their
# terminal byte-stream characters, and CSI REP fills the long borders/spaces.
printf '\033[H\033[2J\033(0\033[0mlq\033[75bk\033(B\r\033[2;1H\033(0\033[0mx\033(B.\033[72b\033(0\033[0mx\033(B\r\033[3;1H\033(0\033[0mx\033(B|...@.\033[68b|\033(0\033[0mx\033(B\r\033[24;1Hfloor:1 gold:0 hp:500/500\n' >"$raw"

python3 "$channel_dir/.goocastle/render-terminal-screenshot.py" "$raw" "$text"

test "$(sed -n '1p' "$text")" = "┌$(printf '%076d' 0 | tr 0 '─')┐"
test "$(sed -n '2p' "$text")" = "│$(printf '%075d' 0 | tr 0 '-') │"
test "$(sed -n '3p' "$text")" = "│|...@.$(printf '%068d' 0 | tr 0 '.')| │"
grep -F 'floor:1 gold:0 hp:500/500' "$text" >/dev/null
