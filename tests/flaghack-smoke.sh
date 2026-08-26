#!/bin/sh
# A local-only contract proof for the installed Flag Hack server.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=${1:-$($guix_bin build -L "$channel_dir" --no-grafts flaghack)}
test -x "$out/bin/flaghack-server"
test -x "$out/bin/flaghack"
test -s "$out/share/doc/flaghack/LICENSE"

scratch=$(mktemp -d)
cleanup() {
  test -n "${server_pid:-}" && kill -TERM "$server_pid" 2>/dev/null || true
  test -n "${server_pid:-}" && wait "$server_pid" 2>/dev/null || true
  rm -rf "$scratch"
}
trap cleanup EXIT INT TERM

port=32123
HOME="$scratch/home" XDG_STATE_HOME="$scratch/state" \
FLAGHACK_SAVE_PATH="$scratch/save.json" FLAGHACK_PORT="$port" \
  "$out/bin/flaghack-server" >"$scratch/server.log" 2>&1 &
server_pid=$!

for attempt in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:$port/client-state" >"$scratch/state.json"; then
    break
  fi
  sleep 1
done
test -s "$scratch/state.json"
grep -q '"roles"' "$scratch/state.json"
curl -fsS --max-time 5 -H 'Accept: text/event-stream' \
  "http://127.0.0.1:$port/client-state/stream" >"$scratch/stream.txt" || true
grep -q 'event: client-state' "$scratch/stream.txt"
session="flaghack-smoke-$$"
tmux -L "$session" -f /dev/null new-session -d -s run -x 120 -y 40 \
  "env HOME='$scratch/home' FLAGHACK_API_URL=http://127.0.0.1:$port '$out/bin/flaghack'"
sleep 3
tmux -L "$session" capture-pane -pt run:0.0 >"$scratch/charm.txt"
tmux -L "$session" kill-server
grep -q 'Choose a role' "$scratch/charm.txt"
kill -TERM "$server_pid"
wait "$server_pid"
server_pid=
test -s "$scratch/save.json"
printf '%s\n' 'flaghack isolated server, SSE, and Charm UI smoke passed'
