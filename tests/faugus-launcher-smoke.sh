#!/bin/sh
set -eu

out=${1:?usage: faugus-launcher-smoke.sh PACKAGE-OUTPUT}
test -x "$out/bin/faugus-launcher"
test -f "$out/share/licenses/faugus-launcher/LICENSE"
test -f "$out/share/licenses/faugus-launcher/ASSETS-LICENSE"
"$out/bin/faugus-launcher" --help | grep -F 'Usage: faugus-launcher'

proof_root=$(mktemp -d -t faugus-launcher-smoke.XXXXXX)
trap 'rm -rf "$proof_root"' EXIT HUP INT TERM
mkdir "$proof_root/home" "$proof_root/config" "$proof_root/data" "$proof_root/state"

timeout 15 unshare --user --map-root-user --net sh -ceu '
  export HOME="$1/home" XDG_CONFIG_HOME="$1/config" XDG_DATA_HOME="$1/data" XDG_STATE_HOME="$1/state"
  export FAUGUS_DISABLE_UPDATES=1 UMU_RUNTIME_UPDATE=0
  exec dbus-run-session xvfb-run -a "$2/bin/faugus-launcher"
' sh "$proof_root" "$out" 2>"$proof_root/stderr" || test "$?" = 124
! grep -Fq Traceback "$proof_root/stderr"
! find "$proof_root" -type f \( -name '*umu*' -o -name '*proton*' \) -print -quit | grep -q .
