#!/bin/sh
# Exercise Herdr's local server API in a fresh, networkless XDG tree.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
validator=/opt/goocastle/bin/bounded-validation.mjs

if test "${1:-}" = --networkless; then
    shift
    herdr_out=$1
else
    if test "$#" -gt 1; then
        echo "usage: $0 [herdr-output]" >&2
        exit 64
    fi
    if test "$#" -eq 1; then
        herdr_out=$1
    else
        herdr_out=$($guix_bin build -L "$channel_dir" --no-grafts herdr)
    fi
    test -x "$herdr_out/bin/herdr"
    test -r "$validator"
    exec unshare --user --map-root-user --net --fork "$0" --networkless "$herdr_out"
fi

herdr=$herdr_out/bin/herdr
test -x "$herdr"
umask 077
scratch=$(mktemp -d "${TMPDIR:-/tmp}/herdr-smoke.XXXXXXXX")
mkdir -p "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/tmp" "$scratch/workspace"
export HOME=$scratch/home
export XDG_CONFIG_HOME=$scratch/config
export XDG_DATA_HOME=$scratch/data
export XDG_CACHE_HOME=$scratch/cache
export XDG_STATE_HOME=$scratch/state
export TMPDIR=$scratch/tmp
export HERDR_CONFIG_PATH=$scratch/config/herdr/config.toml
export HERDR_SOCKET_PATH=$scratch/herdr.sock
export SHELL=/bin/sh

before=$($guix_bin hash -S nar "$herdr_out")

node "$validator" --timeout-ms 5000 -- "$herdr" --help >"$scratch/help"
grep -Fx 'herdr — terminal workspace manager for AI coding agents' "$scratch/help" >/dev/null

# The validator supervises the complete persistent server process group.  The
# subsequent stop command lets it exit normally, rather than relying on a
# timeout for cleanup.
node "$validator" --timeout-ms 20000 -- "$herdr" server >"$scratch/server.log" 2>&1 &
server_runner=$!
ready=false
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if test -S "$HERDR_SOCKET_PATH"; then
        ready=true
        break
    fi
    sleep 1
done
test "$ready" = true

node "$validator" --timeout-ms 5000 -- "$herdr" status server --json \
    >"$scratch/status.json"
grep -E '"running"[[:space:]]*:[[:space:]]*true' "$scratch/status.json" >/dev/null

node "$validator" --timeout-ms 5000 -- "$herdr" workspace create \
    --cwd "$scratch/workspace" --label guix-smoke --no-focus \
    >"$scratch/create.json"
grep -F 'guix-smoke' "$scratch/create.json" >/dev/null
workspace_id=$(sed -n 's/.*"workspace_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$scratch/create.json" | sed -n '1p')
test -n "$workspace_id"

node "$validator" --timeout-ms 5000 -- "$herdr" workspace list \
    >"$scratch/list.json"
grep -F 'guix-smoke' "$scratch/list.json" >/dev/null
node "$validator" --timeout-ms 5000 -- "$herdr" workspace close "$workspace_id" \
    >"$scratch/close.json"
node "$validator" --timeout-ms 5000 -- "$herdr" server stop >"$scratch/stop.json"
wait "$server_runner"
test ! -e "$HERDR_SOCKET_PATH"

# Preserve actual server API responses in the proof transcript.  The
# screenshot gate uses its tail, so a closed package ticket visibly proves a
# running server and the create/list/close workspace lifecycle rather than
# merely displaying the command help.
printf '%s\n' '=== Herdr server status ==='
cat "$scratch/status.json"
printf '%s\n' '=== Herdr workspace create ==='
cat "$scratch/create.json"
printf '%s\n' '=== Herdr workspace list ==='
cat "$scratch/list.json"
printf '%s\n' '=== Herdr workspace close ==='
cat "$scratch/close.json"

# The package retains the source and vendor license material for the installed
# executable, including the non-lazy Zig dependencies' notices.
doc=$herdr_out/share/doc/herdr
for notice in herdr-APACHE-2.0 libghostty-vt-MIT portable-pty-MIT afl++-MIT \
              simdutf.h simdutf.cpp uucode-0.2.0.tar.gz highway-66486a.tar.gz; do
    test -s "$doc/$notice"
done
grep -F 'Apache License' "$doc/herdr-APACHE-2.0" >/dev/null
grep -F 'MIT License' "$doc/libghostty-vt-MIT" >/dev/null
grep -F 'MIT License' "$doc/portable-pty-MIT" >/dev/null
grep -F 'Copyright 2022 Google LLC' "$doc/simdutf.h" >/dev/null || \
    grep -F 'Google Fuchsia (Apache Licensed)' "$doc/simdutf.h" >/dev/null
tar tzf "$doc/uucode-0.2.0.tar.gz" | grep -F 'licenses/LICENSE_unicode' >/dev/null
tar tzf "$doc/uucode-0.2.0.tar.gz" | grep -F 'licenses/LICENSE_Bjoern_Hoehrmann' >/dev/null
tar xOf "$doc/highway-66486a.tar.gz" \
    highway-66486a10623fa0d72fe91260f96c892e41aceb06/LICENSE | \
    grep -F 'Apache License' >/dev/null

contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 655' "$contract" >/dev/null
grep -F '"packageName": "herdr"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-655.png"' "$contract" >/dev/null
grep -F '"successMarker": "herdr — terminal workspace manager for AI coding agents"' \
    "$contract" >/dev/null

# All state remains under this fresh tree.  There are no package-output or
# store mutations while the local server and workspace are exercised.
find "$scratch" -xdev -type f -print >/dev/null
test -z "$(find "$herdr_out" -xdev -type f -perm /222 -print -quit)"
after=$($guix_bin hash -S nar "$herdr_out")
test "$before" = "$after"
printf '%s\n' 'HERDR_RUNTIME_OK'
