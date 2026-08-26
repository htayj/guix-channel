#!/bin/sh
# Exercise the installed compiler from an empty, network-isolated directory.
set -eu

out=${1:?usage: pdp10-xpl-pdp-10-smoke.sh PACKAGE-OUTPUT}
test -x "$out/bin/xpl"
test -f "$out/share/pdp10-xpl/xpl.lib"
test -f "$out/share/pdp10-xpl/hello.xpl"

proof_root=$(mktemp -d -t pdp10-xpl-smoke.XXXXXX)
trap 'rm -rf "$proof_root"' EXIT HUP INT TERM
mkdir "$proof_root/home" "$proof_root/work"

unshare --user --map-root-user --net sh -ceu '
  export HOME="$1/home"
  export XDG_CACHE_HOME="$HOME/.cache"
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$HOME/.local/share"
  cd "$1/work"
  "$2/bin/xpl" "$2/share/pdp10-xpl/hello.xpl" -o "$PWD/hello.rel"
  test -s "$PWD/hello.rel"
' sh "$proof_root" "$out"
