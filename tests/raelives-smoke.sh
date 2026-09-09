#!/bin/sh
# Exercise Rae Lives through the installed launcher in an isolated PTY.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
node_bin=${GOOCASTLE_NODE:-/usr/bin/node}
test -x "$node_bin" || node_bin=$(command -v node)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [raelives-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    raelives_out=$1
else
    raelives_out=$($guix_bin build -L . --no-grafts --no-substitutes raelives)
fi

test -x "$raelives_out/bin/raelives"
test -x "$raelives_out/libexec/raelives"
test -x "$raelives_out/libexec/raelives-smoke.py"
test ! -e "$raelives_out/bin/raelives-real"
test ! -e "$raelives_out/libexec/testmap"

doc=$raelives_out/share/doc/raelives
for file in COPYING AUTHORS README TODO; do
    test -s "$doc/$file"
done
grep -F 'Permission is hereby granted' "$doc/COPYING" >/dev/null
grep -F 'Clayton G. Hobbs' "$doc/AUTHORS" >/dev/null
grep -F 'TheDarklingWolf' "$doc/AUTHORS" >/dev/null
grep -F 'Saving and loading' "$doc/TODO" >/dev/null

# The issue-specific executable, invocation, marker, and artifact are a
# required part of this proof, not an advisory record.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 699' "$contract" >/dev/null
grep -F '"packageName": "raelives"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/raelives.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-699.png"' \
    "$contract" >/dev/null
grep -F '"executable": "raelives"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
grep -F '"successMarker": "RAELIVES_RUNTIME_OK"' "$contract" >/dev/null

util_linux_out=
for candidate in $($guix_bin build -L . --no-grafts --no-substitutes util-linux); do
    if test -x "$candidate/bin/unshare"; then
        util_linux_out=$candidate
        break
    fi
done
test -n "$util_linux_out"
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'raelives smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash covers every installed file, mode, and symlink.  It must remain
# identical after the real game runs, and the output must contain no writable
# regular files.
before=$($guix_bin hash -S nar "$raelives_out")
test -z "$(find "$raelives_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d /tmp/goocastle-agent-raelives-XXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$scratch"
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/caller"

raw=$scratch/terminal.raw
proof=$(cd "$scratch/caller" && env -i \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    LC_ALL=C \
    "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$raelives_out/bin/raelives" --smoke)
test "$proof" = RAELIVES_RUNTIME_OK
test -s "$raw"
grep -aF 'Rae' "$raw" >/dev/null
grep -aF '@' "$raw" >/dev/null

# The wrapper creates its temporary work directory below XDG_STATE_HOME.  It
# may retain the transcript for evidence, but it must not contain a store
# path or symlink back into the store.
work=$(find "$scratch/state/raelives" -mindepth 1 -maxdepth 1 \
    -type d -name 'smoke.*' -print -quit)
test -n "$work"
test -z "$(find "$work" -type l -print -quit)"
test -z "$(grep -R -F '/gnu/store/' "$work" || true)"
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/runtime" "$scratch/tmp" -mindepth 1 \
    -print -quit)"

after=$($guix_bin hash -S nar "$raelives_out")
test "$before" = "$after"
test ! -w "$raelives_out"
printf '%s\n' "$proof"
