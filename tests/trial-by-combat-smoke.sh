#!/bin/sh
# Isolated offline proof for the installed trial-by-combat server.
#
# The package vendors its renderer and arcade face, so a packaged run must
# serve a playable board without reaching any CDN.  Prove that inside a private
# network namespace whose only interface is loopback: nothing outside this
# process can be contacted, yet the documented HTTP surface still answers, the
# bounded `--smoke-host' self-check passes, and a real browser renders the
# spectator and admin consoles of a running match.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

find_program_output() {
    program=$1
    shift
    candidates=$($guix_bin build "$@") || return 1
    for candidate in $candidates; do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

# Usage: trial-by-combat-smoke.sh [--evidence[=PNG]] [OUTPUT [NODE-OUTPUT]]
# --evidence copies the rendered spectator board of the running match to PNG,
# by default the canonical .goocastle/evidence/issue-749.png.  Without it, all
# generated files stay in the disposable scratch tree.
evidence=
case "${1:-}" in
    --evidence)
        evidence=$channel_dir/.goocastle/evidence/issue-749.png
        shift
        ;;
    --evidence=?*)
        evidence=${1#--evidence=}
        shift
        ;;
esac
case "$evidence" in
    ''|/*) ;;
    *) evidence=$PWD/$evidence ;;
esac

if test "$#" -ge 1; then
    out=$1
else
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts trial-by-combat)
fi

if test "$#" -ge 2; then
    node_out=$2
else
    node_out=$(find_program_output bin/node node)
fi

util_linux_out=$(find_program_output bin/unshare util-linux)
iproute_out=$(find_program_output bin/ip iproute2 || \
              find_program_output sbin/ip iproute2)
if test -x "$iproute_out/bin/ip"; then
    ip_bin=$iproute_out/bin/ip
else
    ip_bin=$iproute_out/sbin/ip
fi
chromium_out=$(find_program_output bin/chromium ungoogled-chromium)
imagemagick_out=$(find_program_output bin/identify imagemagick)

module=$out/lib/node_modules/trial-by-combat

# Installed layout and the notices that must travel with the vendored code.
test -x "$out/bin/trial-by-combat"
test -s "$module/public/vendor/pixi.min.js"
test -s "$module/public/vendor/PressStart2P-v16.ttf"
test -s "$out/share/doc/trial-by-combat/LICENSE"
test -s "$out/share/doc/trial-by-combat/pixi.js-LICENSE"
test -s "$out/share/doc/trial-by-combat/PressStart2P-OFL.txt"

# The development-only linter and its prebuilt platform binaries must not have
# been installed.
test ! -e "$module/node_modules/@biomejs"

# No network namespace is inherited by the package process.  The server needs a
# loopback device, so the re-executed stage brings up only that interface.
if test "${TRIAL_BY_COMBAT_SMOKE_IN_NETNS:-}" != 1; then
    if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork true; then
        echo "trial-by-combat-smoke: user and network namespaces are required" >&2
        exit 1
    fi
    exec env TRIAL_BY_COMBAT_SMOKE_IN_NETNS=1 GUIX="$guix_bin" IP_BIN="$ip_bin" \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        "$0" ${evidence:+"--evidence=$evidence"} "$out" "$node_out"
fi

"${IP_BIN:-$ip_bin}" link set lo up

before=$($guix_bin hash -S nar "$out")
scratch=$(mktemp -d)
cleanup() {
    if test -n "${server_pid:-}"; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    rm -rf "$scratch"
}
trap cleanup EXIT INT TERM
mkdir -p "$scratch/home" "$scratch/config" "$scratch/cache" "$scratch/state"

marker='Trial by Combat listening on http://localhost:4178'

# The bounded self-check drives the player API and both browser consoles
# through a match, prints the exact listening marker, and exits 0.
if ! HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
        XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
        TMPDIR="$scratch" \
        "$out/bin/trial-by-combat" --smoke-host >"$scratch/smoke-host.out" 2>&1; then
    echo 'trial-by-combat smoke: --smoke-host failed' >&2
    sed -n '1,60p' "$scratch/smoke-host.out" >&2
    exit 1
fi
grep -Fx "$marker" "$scratch/smoke-host.out" >/dev/null
grep -Fx 'admin console: best-of-3 series, pause and resume applied' \
    "$scratch/smoke-host.out" >/dev/null
grep -Fx 'smoke host: server closed cleanly' "$scratch/smoke-host.out" >/dev/null

port=4178
server_pid=
# A fresh HOME and XDG tree, no inherited host state, and match logging left at
# the package default so nothing attempts to write into the read-only store.
HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
PORT="$port" TMPDIR="$scratch" \
    "$out/bin/trial-by-combat" >"$scratch/server.out" 2>&1 &
server_pid=$!

ready=
waited=0
while test "$waited" -lt 100; do
    if ! kill -0 "$server_pid" 2>/dev/null; then
        break
    fi
    if grep -qF "$marker" "$scratch/server.out" 2>/dev/null; then
        ready=1
        break
    fi
    sleep 0.2
    waited=$((waited + 1))
done

if test "$ready" != 1; then
    echo 'trial-by-combat smoke: the server never announced its listening port' >&2
    sed -n '1,40p' "$scratch/server.out" >&2
    exit 1
fi

# Deterministic same-origin requests over loopback only.  Each must answer 200
# and carry the documented role-specific content.
fetch() {
    path=$1
    body=$2
    status=$("$node_out/bin/node" -e '
const http = require("node:http");
const fs = require("node:fs");
http.get({host: "127.0.0.1", port: Number(process.argv[2]), path: process.argv[1]}, (res) => {
  const chunks = [];
  res.on("data", (c) => chunks.push(c));
  res.on("end", () => {
    fs.writeFileSync(process.argv[3], Buffer.concat(chunks));
    process.stdout.write(String(res.statusCode));
  });
}).on("error", (err) => {
  process.stderr.write(String(err));
  process.exit(1);
});
' "$path" "$port" "$body")
    test "$status" = 200
}

fetch '/?player=spectate' "$scratch/spectate.html"
fetch '/player1?nowait=true' "$scratch/player1.txt"
fetch '/?player=admin' "$scratch/admin.html"

# The served board must load the vendored renderer, never the CDN.
grep -q '/client/vendor/pixi.min.js' "$scratch/spectate.html"
grep -q '/client/vendor/pixi.min.js' "$scratch/admin.html"
if grep -q 'cdn.jsdelivr.net' "$scratch/spectate.html" "$scratch/admin.html"; then
    echo 'trial-by-combat smoke: the served HTML still points at a CDN' >&2
    exit 1
fi

# ...and its stylesheet must resolve the arcade face from the local vendor
# directory rather than Google Fonts.
fetch '/client/styles.css' "$scratch/styles.css"
grep -q '/client/vendor/PressStart2P-v16.ttf' "$scratch/styles.css"
if grep -q 'fonts.googleapis.com\|fonts.gstatic.com' "$scratch/styles.css"; then
    echo 'trial-by-combat smoke: the served stylesheet still points at a webfont host' >&2
    exit 1
fi

# The vendored renderer and face are actually served, not merely referenced.
fetch '/client/vendor/pixi.min.js' "$scratch/pixi.min.js"
fetch '/client/vendor/PressStart2P-v16.ttf' "$scratch/font.ttf"
test -s "$scratch/pixi.min.js"
same_bytes() {
    "$node_out/bin/node" -e '
const fs = require("node:fs");
const a = fs.readFileSync(process.argv[1]);
const b = fs.readFileSync(process.argv[2]);
if (!a.equals(b)) {
  process.stderr.write(`served bytes differ from the installed file: ${process.argv[2]}`);
  process.exit(1);
}
' "$1" "$2"
}

same_bytes "$scratch/pixi.min.js" "$module/public/vendor/pixi.min.js"
same_bytes "$scratch/font.ttf" "$module/public/vendor/PressStart2P-v16.ttf"

# Stable role markers prove the engine answered, not just the static file layer.
# The admin console shares the spectator markup; its role is checked in the
# rendered browser page below.
grep -q 'Trial by Combat' "$scratch/spectate.html"
grep -q 'Trial by Combat' "$scratch/admin.html"
grep -qF '=== TRIAL BY COMBAT - player1 (BLUE) ===' "$scratch/player1.txt"
grep -qF 'Phase: pre_lobby' "$scratch/player1.txt"

# Seat two players through the public API so the browsers render a live match.
post() {
    "$node_out/bin/node" -e '
const http = require("node:http");
const body = process.argv[3] || "";
const req = http.request({host: "127.0.0.1", port: Number(process.argv[2]), path: process.argv[1],
  method: "POST", headers: {"content-type": "application/json", "content-length": Buffer.byteLength(body)}}, (res) => {
  const chunks = [];
  res.on("data", (c) => chunks.push(c));
  res.on("end", () => {
    if (res.statusCode !== 200) {
      process.stderr.write(`${process.argv[1]}: ${res.statusCode} ${Buffer.concat(chunks)}`);
      process.exit(1);
    }
  });
});
req.on("error", (err) => { process.stderr.write(String(err)); process.exit(1); });
req.end(body);
' "$1" "$port" "${2:-}"
}
post /player1/join '{"name":"Smoke Blue"}'
post /player2/join '{"name":"Smoke Red"}'
post /player1/ready
post /player2/ready

# Drive a real headless browser over the DevTools protocol.  Plain
# `--screenshot' captures before Pixi's WebGL canvas has drawn, so wait for the
# renderer, the vendored face, and the board canvas, then capture the page and
# report where the canvas sits.
cat >"$scratch/capture.mjs" <<'EOF'
import { spawn } from 'node:child_process';
import fs from 'node:fs';

const [chrome, url, out, profile] = process.argv.slice(2);
const browser = spawn(chrome, [
  '--headless=new', '--no-sandbox', '--no-first-run', '--use-angle=swiftshader',
  '--enable-unsafe-swiftshader', '--hide-scrollbars', '--window-size=1280,1100',
  `--user-data-dir=${profile}`, '--remote-debugging-port=0', 'about:blank',
], { stdio: ['ignore', 'ignore', 'pipe'] });
const deadline = setTimeout(() => {
  process.stderr.write('capture timed out\n');
  browser.kill('SIGKILL');
  process.exit(1);
}, 60000);
let log = '';
const endpoint = await new Promise((resolve, reject) => {
  browser.stderr.on('data', (chunk) => {
    log += chunk;
    const match = log.match(/DevTools listening on (ws:\S+)/);
    if (match) resolve(match[1]);
  });
  browser.on('exit', (code) => reject(new Error(`chromium exited ${code}\n${log}`)));
});
const ws = new WebSocket(endpoint);
await new Promise((resolve) => ws.addEventListener('open', resolve, { once: true }));
let nextId = 0;
const pending = new Map();
const failures = [];
ws.addEventListener('message', (event) => {
  const message = JSON.parse(event.data);
  if (message.id && pending.has(message.id)) {
    pending.get(message.id)(message);
    pending.delete(message.id);
  } else if (message.method === 'Runtime.exceptionThrown') {
    failures.push(message.params.exceptionDetails.text);
  } else if (message.method === 'Network.loadingFailed' && !message.params.canceled) {
    failures.push(`load failed: ${message.params.errorText}`);
  }
});
const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
  const id = ++nextId;
  pending.set(id, (m) => (m.error ? reject(new Error(`${method}: ${m.error.message}`)) : resolve(m.result)));
  ws.send(JSON.stringify({ id, method, params, sessionId }));
});
const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
await send('Runtime.enable', {}, sessionId);
await send('Network.enable', {}, sessionId);
await send('Page.enable', {}, sessionId);
await send('Page.navigate', { url }, sessionId);
const probe = `(async () => {
  await document.fonts.ready;
  const canvas = document.querySelector('canvas');
  const rect = canvas ? canvas.getBoundingClientRect() : null;
  return JSON.stringify({
    pixi: typeof PIXI === 'object' ? PIXI.VERSION : null,
    font: document.fonts.check('12px "Press Start 2P"'),
    canvas: rect && { x: Math.round(rect.x), y: Math.round(rect.y), w: Math.round(rect.width), h: Math.round(rect.height) },
    text: document.body.innerText.slice(0, 4000),
  });
})()`;
let state;
for (let i = 0; i < 40; i += 1) {
  const { result } = await send('Runtime.evaluate', { expression: probe, awaitPromise: true, returnByValue: true }, sessionId);
  state = JSON.parse(result.value);
  if (state.pixi && state.font && state.canvas?.w > 0) break;
  await new Promise((resolve) => setTimeout(resolve, 250));
}
// Give Pixi a few frames to upload textures and draw the board.
await new Promise((resolve) => setTimeout(resolve, 3000));
const { data } = await send('Page.captureScreenshot', { format: 'png' }, sessionId);
fs.writeFileSync(out, Buffer.from(data, 'base64'));
clearTimeout(deadline);
browser.kill('SIGKILL');
console.log(JSON.stringify({ ...state, failures }));
process.exit(0);
EOF

capture() {
    role=$1
    shift
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
    TMPDIR="$scratch" \
        "$node_out/bin/node" "$scratch/capture.mjs" "$chromium_out/bin/chromium" \
        "http://127.0.0.1:$port/?player=$role" "$scratch/$role.png" \
        "$scratch/profile-$role" >"$scratch/$role.json"
    # Offline, same-origin, no script errors, vendored renderer and face.
    "$node_out/bin/node" -e '
const s = JSON.parse(require("node:fs").readFileSync(process.argv[1], "utf8"));
const fail = (m) => { process.stderr.write(`${process.argv[2]} console: ${m}\n`); process.exit(1); };
if (s.pixi !== "8.2.6") fail(`renderer ${s.pixi}`);
if (!s.font) fail("Press Start 2P did not load");
if (!s.canvas || s.canvas.w < 300 || s.canvas.h < 300) fail("no board canvas");
if (s.failures.length) fail(s.failures.join("; "));
const text = s.text.toLowerCase();
for (const needle of process.argv.slice(3)) if (!text.includes(needle.toLowerCase())) fail(`missing ${needle}`);
process.stdout.write(`${s.canvas.w}x${s.canvas.h}+${s.canvas.x}+${s.canvas.y}`);
' "$scratch/$role.json" "$role" "$@" >"$scratch/$role.geometry"
    image_info=$("$imagemagick_out/bin/identify" -format '%m %w %h %k' \
        "$scratch/$role.png")
    set -- $image_info
    test "$1" = PNG
    test "$2" -ge 800
    test "$3" -ge 500
    test "$4" -ge 10
    # The board itself must be drawn: an unrendered WebGL canvas is one flat
    # colour, while the arena has floor, wall, base, hero, and relic sprites.
    board_colors=$("$imagemagick_out/bin/convert" "$scratch/$role.png" \
        -crop "$(cat "$scratch/$role.geometry")" +repage -format '%k' info:)
    if test "$board_colors" -lt 16; then
        echo "trial-by-combat smoke: the $role board canvas is blank" >&2
        exit 1
    fi
}
capture spectate 'TRIAL BY COMBAT' 'Smoke Blue' 'Smoke Red'
capture admin 'Trial by Combat Admin' 'Smoke Blue' 'Smoke Red'

# The spectator board of the running match is the issue's visual evidence.
if test -n "$evidence"; then
    mkdir -p "$(dirname -- "$evidence")"
    cp "$scratch/spectate.png" "$evidence"
    test -s "$evidence"
fi

kill "$server_pid" 2>/dev/null || true
wait "$server_pid" 2>/dev/null || true
server_pid=

# Match logging defaults to off, so a packaged run leaves the store untouched.
test ! -e "$module/match-log.jsonl"
after=$($guix_bin hash -S nar "$out")
test "$before" = "$after"

printf '%s\n' 'trial-by-combat isolated offline smoke passed: loopback-only namespace, fresh HOME, --smoke-host marker, vendored Pixi.js and font rendered in spectator and admin browsers, immutable store'
