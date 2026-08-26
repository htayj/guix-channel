#!/bin/sh
# Exercise installed notion-river integration in a private XDG environment.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [notion-river-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    notion_river_out=$1
else
    notion_river_out=$($guix_bin build -L "$channel_dir" --no-grafts notion-river)
fi

test -x "$notion_river_out/bin/notion-river"
test -x "$notion_river_out/bin/notion-ctl"
test -x "$notion_river_out/bin/notion-river-session"
test -s "$notion_river_out/share/doc/notion-river/LICENSE"
test -s "$notion_river_out/share/doc/notion-river/protocol/river-window-management-v1.xml"
test -s "$notion_river_out/share/doc/notion-river/protocol/river-xkb-bindings-v1.xml"
test -s "$notion_river_out/share/doc/notion-river/protocol/river-layer-shell-v1.xml"
test -s "$notion_river_out/share/doc/notion-river/protocol/viewporter.xml"
test -s "$notion_river_out/share/doc/notion-river/protocol/wlr-output-management-unstable-v1.xml"
test -d "$notion_river_out/share/doc/notion-river/third-party-licenses"
test -n "$(find "$notion_river_out/share/doc/notion-river/third-party-licenses" -type f -print -quit)"

tmp=$(mktemp -d -t notion-river-smoke.XXXXXX)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir "$tmp/home" "$tmp/config" "$tmp/runtime" "$tmp/fake-bin"
chmod 700 "$tmp/runtime"

# The marker makes an output write observable even on a host with permissive
# store mounts; normal Guix outputs must stay immutable throughout the smoke.
touch "$tmp/output-before-smoke"

version=$(env -i HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" \
    XDG_RUNTIME_DIR="$tmp/runtime" PATH="$tmp/fake-bin" \
    "$notion_river_out/bin/notion-river" --version)
test "$version" = "notion-river 0.5.3"
test -z "$(find "$tmp/home" "$tmp/config" -mindepth 1 -print -quit)"

# notion-ctl must reject an empty command with its documented usage and must
# resolve its IPC endpoint beneath this private XDG_RUNTIME_DIR, never /tmp or
# a user's live Wayland-session socket.
if env -i HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" \
       XDG_RUNTIME_DIR="$tmp/runtime" PATH="$tmp/fake-bin" \
       "$notion_river_out/bin/notion-ctl" >"$tmp/ctl-empty.out" 2>&1; then
    echo "notion-ctl accepted an empty command" >&2
    exit 1
else
    status=$?
fi
test "$status" -eq 2
grep -q '^usage:' "$tmp/ctl-empty.out"
if env -i HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" \
       XDG_RUNTIME_DIR="$tmp/runtime" PATH="$tmp/fake-bin" \
       "$notion_river_out/bin/notion-ctl" list-workspaces >"$tmp/ctl-ipc.out" 2>&1; then
    echo "notion-ctl unexpectedly found an IPC server" >&2
    exit 1
else
    status=$?
fi
test "$status" -eq 1
grep -Fq "$tmp/runtime/notion-river.sock" "$tmp/ctl-ipc.out"
test ! -e "$tmp/runtime/notion-river.sock"

# A stand-in River proves the session wrapper obtains River from PATH and
# uses its default command.  It is not a compositor and cannot reach a host
# display or network.
cat >"$tmp/fake-bin/river" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$NOTION_RIVER_FAKE_ARGS"
printf '%s\n' "$XDG_CONFIG_HOME" >"$NOTION_RIVER_FAKE_CONFIG"
EOF
chmod 700 "$tmp/fake-bin/river"

NOTION_RIVER_FAKE_ARGS="$tmp/default.args" \
NOTION_RIVER_FAKE_CONFIG="$tmp/default.config" \
env -i HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" \
    XDG_RUNTIME_DIR="$tmp/runtime" PATH="$tmp/fake-bin" \
    NOTION_RIVER_FAKE_ARGS="$tmp/default.args" \
    NOTION_RIVER_FAKE_CONFIG="$tmp/default.config" \
    "$notion_river_out/bin/notion-river-session"
test "$(sed -n '1p' "$tmp/default.args")" = "-c"
test "$(sed -n '2p' "$tmp/default.args")" = "notion-river"
test "$(cat "$tmp/default.config")" = "$tmp/config"

# The wrapper must use XDG_CONFIG_HOME, rather than the historical hard-coded
# $HOME/.config path, when a user's River init script exists.
mkdir "$tmp/config/river"
touch "$tmp/config/river/init"
chmod 700 "$tmp/config/river/init"
NOTION_RIVER_FAKE_ARGS="$tmp/init.args" \
NOTION_RIVER_FAKE_CONFIG="$tmp/init.config" \
env -i HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" \
    XDG_RUNTIME_DIR="$tmp/runtime" PATH="$tmp/fake-bin" \
    NOTION_RIVER_FAKE_ARGS="$tmp/init.args" \
    NOTION_RIVER_FAKE_CONFIG="$tmp/init.config" \
    "$notion_river_out/bin/notion-river-session"
test "$(sed -n '1p' "$tmp/init.args")" = "-c"
test "$(sed -n '2p' "$tmp/init.args")" = "$tmp/config/river/init"

grep -q 'MIT License' "$notion_river_out/share/doc/notion-river/LICENSE"
grep -q 'SPDX-License-Identifier: MIT' \
    "$notion_river_out/share/doc/notion-river/protocol/river-window-management-v1.xml"
grep -q 'Permission to use, copy, modify, distribute, and sell' \
    "$notion_river_out/share/doc/notion-river/protocol/wlr-output-management-unstable-v1.xml"
grep -Fq "Exec=$notion_river_out/bin/notion-river-session" \
    "$notion_river_out/share/wayland-sessions/notion-river.desktop"
grep -Fq "$notion_river_out/share/notion-river/examples" \
    "$notion_river_out/share/notion-river/examples/river-init"
test -s "$notion_river_out/share/notion-river/examples/config.toml"
test -z "$(find "$notion_river_out" -xdev -newer "$tmp/output-before-smoke" -print -quit)"
test -z "$(find "$notion_river_out" -xdev -type f -perm /222 -print -quit)"

echo "notion-river smoke passed: private XDG, session PATH contract, IPC path, notices, immutable output"
