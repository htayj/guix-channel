// Bounded self-check for the packaged Trial by Combat server.
//
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Starts the real application server from the installed tree, drives the
// player HTTP API and the admin and spectator WebSocket consoles through a
// lobby into a running match, verifies that every client asset is served
// from the store, and then shuts down and exits.  No request leaves the
// loopback interface.

import assert from 'node:assert/strict';

import { createAppServer } from './src/server.js';

const TIMEOUT_MS = 5000;

function withTimeout(promise, what) {
  let timer;
  return Promise.race([
    promise.finally(() => clearTimeout(timer)),
    new Promise((_, reject) => {
      timer = setTimeout(() => reject(new Error(`timed out waiting for ${what}`)), TIMEOUT_MS);
    }),
  ]);
}

async function get(base, path) {
  const response = await withTimeout(fetch(`${base}${path}`), `GET ${path}`);
  assert.equal(response.status, 200, `GET ${path} returned ${response.status}`);
  return { type: response.headers.get('content-type') ?? '', body: await response.text() };
}

async function post(base, path, body) {
  const response = await withTimeout(
    fetch(`${base}${path}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: body == null ? undefined : JSON.stringify(body),
    }),
    `POST ${path}`,
  );
  const text = await response.text();
  assert.equal(response.status, 200, `POST ${path} returned ${response.status}: ${text}`);
  return text;
}

// A console client that records every state frame the server pushes.
async function openConsole(wsBase, role) {
  const ws = new WebSocket(`${wsBase}/ws?player=${role}`);
  const frames = [];
  const waiters = new Set();
  ws.addEventListener('message', (event) => {
    const message = JSON.parse(String(event.data));
    if (message.type !== 'state') return;
    assert.equal(message.role, role, `unexpected role on ${role} console`);
    frames.push(message.state);
    for (const waiter of waiters) waiter();
  });
  await withTimeout(
    new Promise((resolve, reject) => {
      ws.addEventListener('open', resolve, { once: true });
      ws.addEventListener('error', () => reject(new Error(`${role} console failed to connect`)), {
        once: true,
      });
    }),
    `${role} console`,
  );
  return {
    ws,
    send: (message) => ws.send(JSON.stringify(message)),
    // Frames already received before an action must not satisfy a wait for
    // its effect, so callers take a mark first and wait past it.
    mark: () => frames.length,
    until(predicate, what, from = 0) {
      return withTimeout(
        new Promise((resolve) => {
          const check = () => {
            const match = frames.slice(from).findLast(predicate);
            if (match) {
              waiters.delete(check);
              resolve(match);
            }
          };
          waiters.add(check);
          check();
        }),
        `${role} console: ${what}`,
      );
    },
  };
}

async function exercise(port) {
  const base = `http://127.0.0.1:${port}`;
  const wsBase = `ws://127.0.0.1:${port}`;

  for (const role of ['spectate', 'admin']) {
    const page = await get(base, `/?player=${role}`);
    assert.match(page.body, /Trial by Combat/);
    assert.ok(page.body.includes('/client/vendor/pixi.min.js'), `${role} page lacks the vendored renderer`);
    assert.ok(!page.body.includes('cdn.jsdelivr.net'), `${role} page still references a CDN`);
  }
  const styles = await get(base, '/client/styles.css');
  assert.ok(styles.body.includes('/client/vendor/PressStart2P-v16.ttf'), 'stylesheet lacks the vendored face');
  assert.ok(!/fonts\.(googleapis|gstatic)\.com/.test(styles.body), 'stylesheet still references Google Fonts');
  const renderer = await get(base, '/client/vendor/pixi.min.js');
  assert.match(renderer.body.slice(0, 200), /PixiJS - v8\.2\.6/);
  const face = await withTimeout(fetch(`${base}/client/vendor/PressStart2P-v16.ttf`), 'font');
  assert.equal(face.status, 200);
  const faceBytes = Buffer.from(await face.arrayBuffer());
  // TrueType name records are UTF-16BE.
  const familyName = Buffer.from('Press Start 2P', 'utf16le').swap16();
  assert.equal(faceBytes.readUInt32BE(0), 0x00010000, 'served font is not TrueType');
  assert.ok(faceBytes.includes(familyName), 'served font is not Press Start 2P');
  console.log('client assets: renderer and arcade face served from the store');

  const lobby = await get(base, '/player1?nowait=true');
  assert.ok(lobby.body.includes('=== TRIAL BY COMBAT - player1 (BLUE) ==='), 'player1 view header missing');
  assert.ok(lobby.body.includes('Phase: pre_lobby'), 'player1 view is not in the lobby');

  const admin = await openConsole(wsBase, 'admin');
  const spectator = await openConsole(wsBase, 'spectate');
  await admin.until((state) => state.phase === 'pre_lobby', 'lobby state');
  await spectator.until((state) => state.phase === 'pre_lobby', 'lobby state');

  let mark = admin.mark();
  admin.send({ type: 'admin', action: 'set_series_length', bestOf: 3 });
  await admin.until((state) => state.match?.best_of === 3, 'best-of-3 series', mark);

  mark = spectator.mark();
  await post(base, '/player1/join', { name: 'Smoke Blue' });
  await post(base, '/player2/join', { name: 'Smoke Red' });
  await post(base, '/player1/ready');
  await post(base, '/player2/ready');
  const running = await spectator.until(
    (state) => state.phase === 'match' && state.full_board_state?.players?.blue,
    'running match',
    mark,
  );
  assert.equal(running.full_board_state.size, 9);
  console.log(`spectator console: match running, relic at ${running.full_board_state.relic.position}`);

  mark = spectator.mark();
  const action = { action: 'WAIT', intent: 'Smoke test blue waits to watch the arena.' };
  assert.match(await post(base, '/player1/action', action), /^Action accepted/);
  assert.match(
    await post(base, '/player2/action', { ...action, intent: 'Smoke test red waits as well.' }),
    /^Action accepted/,
  );
  await spectator.until((state) => state.phase === 'match' && state.turn === 1, 'resolved turn', mark);
  const view = await get(base, '/player1?nowait=true');
  assert.ok(view.body.includes('=== TRIAL BY COMBAT - player1 (BLUE) ==='));
  console.log('player API: both seats joined, readied, and resolved turn 1');

  mark = admin.mark();
  admin.send({ type: 'admin', action: 'pause' });
  await admin.until((state) => state.paused === true, 'pause', mark);
  mark = admin.mark();
  admin.send({ type: 'admin', action: 'resume' });
  await admin.until((state) => state.paused === false && state.phase === 'match', 'resume', mark);
  console.log('admin console: best-of-3 series, pause and resume applied');

  admin.ws.close();
  spectator.ws.close();
}

const app = createAppServer();
await app.listen(Number(process.env.PORT || 4178));
console.log(`Trial by Combat listening on http://localhost:${app.port}`);
try {
  await exercise(app.port);
} finally {
  await app.close();
}
console.log('smoke host: server closed cleanly');
