#!/bin/sh
# Exercise CoreRL's installed curses game in an isolated PTY.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [corerl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    corerl_out=$1
else
    corerl_out=$($guix_bin build -L . --no-grafts --no-substitutes corerl)
fi

test -x "$corerl_out/bin/corerl"
test -x "$corerl_out/libexec/corerl"
notice=$corerl_out/share/doc/corerl/NOTICE
test -s "$notice"
grep -F 'https://www.roguelikeeducation.org/vault/core/1kcore.c' \
    "$notice" >/dev/null
grep -F 'released into the public domain' "$notice" >/dev/null
grep -F '1kib-20131024' "$notice" >/dev/null

# The issue-specific executable, invocation, marker, and screenshot artifact
# are a required part of this proof, not an advisory record.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 668' "$contract" >/dev/null
grep -F '"packageName": "corerl"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-668.png"' \
    "$contract" >/dev/null
grep -F '"executable": "corerl"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
marker=CORERL_RUNTIME_OK
grep -F '"successMarker": "CORERL_RUNTIME_OK"' "$contract" >/dev/null

util_linux_out=$($guix_bin build -L . --no-grafts --no-substitutes util-linux)
test -x "$util_linux_out/bin/script"
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! node "$bounded_validation" --timeout-ms 5000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork true \
    >/dev/null 2>&1; then
    echo 'corerl smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash covers every installed file, mode, and symlink.  It must remain
# identical after the real game runs; the output must also contain no writable
# regular files.
before=$($guix_bin hash -S nar "$corerl_out")
test -z "$(find "$corerl_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d /tmp/goocastle-agent-corerl-XXXXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$scratch"
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" \
      "$scratch/tmp" "$scratch/work" "$scratch/caller"

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
    node "$bounded_validation" --timeout-ms 20000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$corerl_out/bin/corerl" --smoke)
test "$proof" = "$marker"
test -s "$raw"
grep -aF '@' "$raw" >/dev/null
grep -aF 'e' "$raw" >/dev/null
grep -aF '<' "$raw" >/dev/null
grep -aF 'Quit on level 1.' "$raw" >/dev/null

# CoreRL has no stateful features; its package-owned smoke scratch and all
# caller HOME/XDG trees must be empty after the transcript is captured.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work" -mindepth 1 -print -quit)"
after=$($guix_bin hash -S nar "$corerl_out")
test "$before" = "$after"
test ! -w "$corerl_out"
printf '%s\n' "$proof"
