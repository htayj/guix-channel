#!/bin/sh
# Exercise robotfindskitten's installed ncurses runtime in an isolated PTY.
set -eu

guix_bin=$(command -v "${GUIX:-guix}")
node_bin=${GOOCASTLE_NODE:-$(command -v node)}
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [robotfindskitten-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    robotfindskitten_out=$1
else
    robotfindskitten_out=$($guix_bin build -L . --no-grafts --no-substitutes \
        robotfindskitten)
fi

test -x "$robotfindskitten_out/bin/robotfindskitten"
test -x "$robotfindskitten_out/libexec/robotfindskitten-real"
test -x "$robotfindskitten_out/libexec/robotfindskitten-smoke.py"
test ! -e "$robotfindskitten_out/games/robotfindskitten"

data="$robotfindskitten_out/share/games/robotfindskitten"
test -s "$data/vanilla.nki"
test -s "$robotfindskitten_out/share/man/man6/robotfindskitten.6.zst"
test -s "$robotfindskitten_out/share/info/robotfindskitten.info.gz"
test -s "$robotfindskitten_out/share/applications/robotfindskitten.desktop"
test -s "$robotfindskitten_out/share/metainfo/org.robotfindskitten.robotfindskitten.metainfo.xml"
test -s "$robotfindskitten_out/share/icons/hicolor/512x512/apps/robotfindskitten.png"
test -s "$robotfindskitten_out/share/icons/hicolor/scalable/apps/robotfindskitten.svg"

doc="$robotfindskitten_out/share/doc/robotfindskitten"
for file in AUTHORS BUGS ChangeLog COPYING NEWS README.md REUSE.toml \
    GPL-2.0-or-later.txt; do
    test -s "$doc/$file"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/COPYING" >/dev/null
grep -F 'SPDX-License-Identifier = "GPL-2.0-or-later"' "$doc/REUSE.toml" >/dev/null
grep -F '<metadata_license>CC-BY-SA-4.0</metadata_license>' \
    "$robotfindskitten_out/share/metainfo/org.robotfindskitten.robotfindskitten.metainfo.xml" \
    >/dev/null

# The reviewed runtime contract is part of this package-specific proof.
contract="$channel_dir/.goocastle/runtime-evidence-contracts.json"
test -s "$contract"
grep -F '"issueNumber": 717' "$contract" >/dev/null
grep -F '"packageName": "robotfindskitten"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/robotfindskitten.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-717.png"' \
    "$contract" >/dev/null
grep -F '"executable": "robotfindskitten"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "GUIX_SMOKE_OK robotfindskitten"' \
    "$contract" >/dev/null

test -r "$bounded_validation"
test -x "$node_bin"
util_linux_out=
for candidate in $($guix_bin build -L . --no-grafts --no-substitutes util-linux); do
    if test -x "$candidate/bin/unshare"; then
        util_linux_out=$candidate
        break
    fi
done
test -n "$util_linux_out"

# The output NAR and file modes are checked before and after running the
# wrapper, proving that the installed code and assets remain immutable.
before=$($guix_bin hash -S nar "$robotfindskitten_out")
test -z "$(find "$robotfindskitten_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$robotfindskitten_out"

if test -n "${GOOCASTLE_DISPOSABLE_WORKSPACE-}"; then
    disposable_workspace=$GOOCASTLE_DISPOSABLE_WORKSPACE
else
    disposable_workspace=$(mktemp -d /tmp/goocastle-agent-XXXXXXXX)
fi
case "$disposable_workspace" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$disposable_workspace"
scratch=$(mktemp -d "$disposable_workspace/robotfindskitten-smoke-XXXXXXXX")
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" \
      "$scratch/tmp" "$scratch/work"
chmod 700 "$scratch/runtime"

raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}
version=$(env -i HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_STATE_HOME="$scratch/state" \
    XDG_CACHE_HOME="$scratch/cache" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" TERM=xterm LC_ALL=C PATH= \
    "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
    "$robotfindskitten_out/bin/robotfindskitten" -V)
test "$version" = 'robotfindskitten: 3.0000000.726'

# PTY and package-runtime control are delegated to the bounded argv-only
# executor.  The child is placed in a network namespace with no interfaces;
# the game itself has no network path and needs no local protocol.
proof=$(cd "$scratch/work" && \
    env -i HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" XDG_STATE_HOME="$scratch/state" \
    XDG_CACHE_HOME="$scratch/cache" XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" TERM=xterm LC_ALL=C PATH= \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$robotfindskitten_out/bin/robotfindskitten" --guix-smoke)
test "$proof" = 'GUIX_SMOKE_OK robotfindskitten'
test -s "$raw"
if ! grep -aF 'robotfindskitten 3.0000000.726' "$raw" >/dev/null; then
    grep -aF "$(printf '%s\033[6b%s' 'robotfindskitten 3.0' '.726')" \
        "$raw" >/dev/null
fi
grep -aF 'In this game, you are robot (#).' "$raw" >/dev/null

# The helper's HOME, all XDG locations, and working directory are private;
# its temporary root is the only expected content below the fresh TMPDIR.
# The package output itself must have the same NAR identity after execution.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/work" \
    -mindepth 1 -print -quit)"
test -n "$(find "$scratch/tmp" -mindepth 1 -print -quit)"
test -z "$(find "$scratch/tmp" -type l -print -quit)"
after=$($guix_bin hash -S nar "$robotfindskitten_out")
test "$before" = "$after"
test -z "$(find "$robotfindskitten_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$robotfindskitten_out"

if test -n "${GOOCASTLE_SCREENSHOT-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/issue-717.png) ;;
        *) echo 'robotfindskitten smoke: screenshot must use issue-717.png' >&2
           exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
