#!/bin/sh
# Isolated installed-runtime proof for crashRun.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
node_bin=${GOOCASTLE_NODE:-/usr/bin/node}
test -x "$node_bin" || node_bin=$(command -v node)

if test "$#" -gt 1; then
    echo "usage: $0 [crashrun-output]" >&2
    exit 64
fi

# The game has no network feature.  Run the package proof in an empty network
# namespace so an accidental future network path cannot reach the host.
if test "${CRASHRUN_SMOKE_NAMESPACED:-}" != 1; then
    unshare_bin=
    for candidate in $($guix_bin build util-linux); do
        if test -x "$candidate/bin/unshare"; then
            unshare_bin=$candidate/bin/unshare
            break
        fi
    done
    test -n "$unshare_bin" || {
        echo "crashrun-smoke: unshare is required" >&2
        exit 125
    }
    export CRASHRUN_SMOKE_NAMESPACED=1
    bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
    exec "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
        "$unshare_bin" --user --map-root-user --net --fork "$0" "$@"
fi

if test "$#" -eq 1; then
    crashrun_out=$1
else
    crashrun_out=$($guix_bin build -L "$channel_dir" --no-grafts crashrun)
fi

test -x "$crashrun_out/bin/crashrun"
test -f "$crashrun_out/share/crashrun/crashRun.py"
test -f "$crashrun_out/share/crashrun/VeraMono.ttf"
test -f "$crashrun_out/share/doc/crashrun/license.txt"
test -f "$crashrun_out/share/doc/crashrun/COPYRIGHT.TXT"
grep -F 'GNU GENERAL PUBLIC LICENSE' \
    "$crashrun_out/share/doc/crashrun/license.txt" >/dev/null
grep -F 'Bitstream Vera Fonts Copyright' \
    "$crashrun_out/share/doc/crashrun/COPYRIGHT.TXT" >/dev/null
grep -F 'shall be included in all copies' \
    "$crashrun_out/share/doc/crashrun/COPYRIGHT.TXT" >/dev/null

contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 670' "$contract" >/dev/null
grep -F '"packageName": "crashrun"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-670.png"' \
    "$contract" >/dev/null
grep -F '"executable": "crashrun"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
grep -F 'crashrun smoke passed: new-game, turn, save-load, and isolated-state' \
    "$contract" >/dev/null

before=$($guix_bin hash -S nar "$crashrun_out")
test -z "$(find "$crashrun_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d /tmp/goocastle-agent-crashrun-XXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-crashrun-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$scratch"
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp"
frame=$scratch/state/crashrun-smoke.png

proof=$(env -i \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" \
    SDL_VIDEODRIVER=dummy \
    SDL_AUDIODRIVER=dummy \
    CRASHRUN_SMOKE_SCREENSHOT="$frame" \
    LC_ALL=C.UTF-8 \
    PATH="$crashrun_out/bin" \
    "$node_bin" "${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}" \
    --timeout-ms 30000 -- "$crashrun_out/bin/crashrun" --smoke)
test "$proof" = 'crashrun smoke passed: new-game, turn, save-load, and isolated-state'
test -s "$frame"

# The only files allowed in the fresh environment are the package-owned smoke
# state and its rendered frame, both below XDG_STATE_HOME.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/runtime" "$scratch/tmp" -mindepth 1 \
    -print -quit)"
test -n "$(find "$scratch/state" -mindepth 1 -print -quit)"
test -z "$(find "$scratch/state" -type l -print -quit)"

after=$($guix_bin hash -S nar "$crashrun_out")
test "$before" = "$after"
test ! -w "$crashrun_out"

if test -n "${GOOCASTLE_SCREENSHOT:-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'crashrun-smoke: screenshot must be a channel evidence PNG' >&2; exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$frame" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
