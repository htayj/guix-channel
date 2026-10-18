// External observer only: installed launcher, trusted CDP keyboard, DOM and canvas reads.
// No injected event listeners, initialization scripts, game globals, RNG or save edits.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [output, chromium, evidence] = process.argv.slice(2);
const record = { status: 'failed', input: 'Chromium Input.dispatchKeyEvent (native keypress)',
  requests: [], responses: [], completed_requests: [], failures: [], screenshots: [], movement: [], observations: [] };
const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
let browser, ws, closed, call, classification = 'isolation';
let browserLog = '';
let exit;
let pageLoads = 0;
let sessionBus, busExit, busClosed, busLog = '';
const nativeErrors = () => browserLog.split('\n').filter((line) => /\b(?:ERROR|FATAL)\b/.test(line));
const pending = new Map();
let nextId = 0;
const deadline = setTimeout(() => {
  record.failure_class = 'observer-deadline';
  record.error = 'observer exceeded its 120 second deadline';
  fs.writeFileSync(path.join(evidence, 'evidence.json'), `${JSON.stringify(record, null, 2)}\n`);
  browser?.kill('SIGKILL');
  process.exit(1);
}, 120000);
const namespaceLinks = (pid) => Object.fromEntries(['user', 'mnt', 'net', 'pid'].map(
  (name) => [name, fs.readlinkSync(`/proc/${pid}/ns/${name}`)]));
try {
  record.uid = process.getuid();
  record.gid = process.getgid();
  assert.equal(record.uid, Number(process.env.FARMINGRL_EXPECTED_UID));
  assert.equal(record.gid, Number(process.env.FARMINGRL_EXPECTED_GID));
  assert.notEqual(record.uid, 0, 'the consumer must not run as root');
  record.namespaces = namespaceLinks('self');
  for (const [name, link] of Object.entries(record.namespaces)) {
    assert.notEqual(link, process.env[`FARMINGRL_HOST_${name.toUpperCase()}_NS`],
      `${name} must be a private namespace`);
  }
  record.interfaces = JSON.parse(fs.readFileSync(path.join(evidence, 'interfaces.json'), 'utf8'));
  assert.deepEqual(record.interfaces.map((entry) => entry.ifname), ['lo']);
  assert.ok(record.interfaces[0].flags.includes('UP'), 'loopback must be up');
  record.store_mount = fs.readFileSync('/proc/self/mountinfo', 'utf8').split('\n')
    .filter((line) => line.split(' ')[4] === '/gnu/store').at(-1);
  assert.ok(record.store_mount?.split(' ')[5].split(',').includes('ro'));
  record.readonly_store = true;
  record.fresh_state = Object.fromEntries(['HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME',
    'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'].map((name) => {
    const directory = process.env[name];
    assert.ok(path.isAbsolute(directory) && !directory.startsWith('/gnu/store/'));
    assert.deepEqual(fs.readdirSync(directory), [], `${name} must start empty`);
    return [name, directory];
  }));
  assert.equal(typeof WebSocket, 'function', 'observer Node must provide WebSocket');
  classification = 'private-session-bus';
  const busSocket = path.join(process.env.XDG_RUNTIME_DIR, 'bus');
  const busAddress = `unix:path=${busSocket}`;
  assert.equal(process.env.DBUS_SYSTEM_BUS_ADDRESS, undefined,
    'the observer must not substitute a session bus for a system bus');
  sessionBus = spawn(path.join(process.env.DBUS, 'bin/dbus-daemon'), [
    '--session', '--nofork', '--nosyslog', `--address=${busAddress}`, '--print-address=1',
  ], { stdio: ['ignore', 'pipe', 'pipe'] });
  sessionBus.stderr.on('data', (chunk) => { busLog += chunk.toString(); });
  let busAnnouncement = '';
  const busReady = new Promise((resolve, reject) => {
    sessionBus.stdout.on('data', (chunk) => {
      busAnnouncement += chunk.toString();
      if (busAnnouncement.includes('\n')) resolve(busAnnouncement.trim());
    });
    sessionBus.once('error', reject);
    sessionBus.once('exit', (code, signal) => reject(new Error(
      `private session bus exited before readiness: ${code}/${signal}: ${busLog}`)));
  });
  busExit = new Promise((resolve) => sessionBus.once('exit', (code, signal) => {
    busClosed = { code, signal };
    resolve(busClosed);
  }));
  const announced = await Promise.race([busReady, pause(5000).then(() => {
    throw new Error('private session D-Bus did not announce readiness within 5 seconds');
  })]);
  assert.ok(announced.startsWith(`${busAddress},guid=`), 'daemon must announce the private Unix socket');
  assert.ok(fs.statSync(busSocket).isSocket());
  const busExecutable = fs.readlinkSync(`/proc/${sessionBus.pid}/exe`);
  assert.ok(busExecutable.startsWith(`${process.env.DBUS}/`));
  assert.deepEqual(namespaceLinks(sessionBus.pid), record.namespaces);
  record.session_bus = { pid: sessionBus.pid, executable: busExecutable, address: announced,
    type: 'session', system_address: 'unset (ordinary default)', namespaces: namespaceLinks(sessionBus.pid) };
  process.env.DBUS_SESSION_BUS_ADDRESS = announced;
  classification = 'browser-startup';
  browser = spawn(path.join(output, 'bin/farmingrl'), [
    '--headless=new', '--no-sandbox', '--no-first-run', '--no-default-browser-check',
    '--disable-background-networking', '--disable-component-update', '--disable-sync',
    '--disable-domain-reliability', '--disable-breakpad', '--metrics-recording-only',
    '--disable-features=MediaRouter,OptimizationHints,AutofillServerCommunication',
    '--password-store=basic', '--hide-scrollbars', '--window-size=1360,900',
    '--remote-debugging-port=0',
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  let rejectReady;
  const ready = new Promise((resolve, reject) => {
    rejectReady = reject;
    browser.stderr.on('data', (chunk) => {
      browserLog += chunk.toString();
      const endpoint = browserLog.match(/DevTools listening on (ws:\S+)/);
      if (endpoint) resolve(endpoint[1]);
    });
    browser.once('error', reject);
  });
  exit = new Promise((resolve) => browser.once('exit', (code, signal) => {
    closed = { code, signal };
    rejectReady(new Error(`installed launcher exited: ${JSON.stringify(closed)}`));
    for (const request of pending.values()) request.reject(new Error('browser exited'));
    pending.clear();
    resolve(closed);
  }));
  const endpoint = await Promise.race([ready, pause(20000).then(() => {
    throw new Error('installed launcher did not expose CDP within 20 seconds');
  })]);
  record.browser_process = null;
  // The launcher may use Chromium's wrapper, so inspect actual processes rather
  // than claiming the wrapper pathname proves which executable is running.
  record.browser_identity_scan = { launcher_pid: browser.pid, attempts: 0, last_candidates: [] };
  const identityDeadline = Date.now() + 5000;
  do {
    assert.equal(closed, undefined, 'installed browser must stay alive during identity observation');
    record.browser_identity_scan.attempts++;
    const candidates = [];
    // argv is an observation, not identity: Chromium may rewrite its title.
    // Only the launched process and descendants reached through kernel task
    // children records can supply the executable identity receipt.
    const queue = [{ pid: browser.pid, parent: null }];
    const visited = new Set();
    while (queue.length) {
      const { pid, parent } = queue.shift();
      if (visited.has(pid)) continue;
      visited.add(pid);
      try {
        for (const tid of fs.readdirSync(`/proc/${pid}/task`)) {
          try {
            const children = fs.readFileSync(`/proc/${pid}/task/${tid}/children`, 'utf8').trim();
            if (children) for (const child of children.split(/\s+/)) {
              queue.push({ pid: Number(child), parent: pid });
            }
          } catch (error) {
            if (!['ENOENT', 'EACCES', 'ESRCH'].includes(error.code)) throw error;
          }
        }
        const candidate = { pid, parent, argv: [] };
        candidates.push(candidate);
        const argv = fs.readFileSync(`/proc/${pid}/cmdline`, 'utf8').split('\0').filter(Boolean);
        candidate.argv = argv;
        const executable = fs.readlinkSync(`/proc/${pid}/exe`);
        candidate.executable = executable;
        if (!executable.startsWith(`${chromium}/`)) continue;
        const status = fs.readFileSync(`/proc/${pid}/status`, 'utf8');
        const uid = status.match(/^Uid:\s+(\d+)\s+(\d+)/m)?.slice(1).map(Number);
        const gid = status.match(/^Gid:\s+(\d+)\s+(\d+)/m)?.slice(1).map(Number);
        assert.deepEqual(uid, [record.uid, record.uid]);
        assert.deepEqual(gid, [record.gid, record.gid]);
        const namespaces = namespaceLinks(pid);
        assert.deepEqual(namespaces, record.namespaces);
        record.browser_process = { pid: Number(pid), parent, executable, argv, uid, gid, namespaces };
        break;
      } catch (error) {
        if (!['ENOENT', 'EACCES', 'ESRCH'].includes(error.code)) throw error;
        candidates.push({ pid: Number(pid), observation_error: error.code });
      }
    }
    record.browser_identity_scan.last_candidates = candidates;
    if (!record.browser_process) await pause(50);
  } while (!record.browser_process && Date.now() < identityDeadline);
  assert.ok(record.browser_process, 'the installed launcher must run the resolved store Chromium');
  const expectedProfile = path.join(process.env.XDG_DATA_HOME, 'farmingrl/chromium');
  record.profile_argv_observed = record.browser_process.argv.includes(`--user-data-dir=${expectedProfile}`);
  record.profile = expectedProfile;
  ws = new WebSocket(endpoint);
  await new Promise((resolve, reject) => {
    ws.addEventListener('open', resolve, { once: true });
    ws.addEventListener('error', reject, { once: true });
  });
  ws.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const { resolve, reject, timer } = pending.get(message.id);
      pending.delete(message.id);
      clearTimeout(timer);
      if (message.error) reject(new Error(JSON.stringify(message.error)));
      else resolve(message.result);
    } else if (message.method === 'Page.loadEventFired') {
      pageLoads++;
    } else if (message.method === 'Runtime.exceptionThrown') {
      record.failures.push(message.params.exceptionDetails.exception?.description || message.params.exceptionDetails.text);
    } else if (message.method === 'Runtime.consoleAPICalled' &&
        ['error', 'assert'].includes(message.params.type)) {
      record.failures.push(JSON.stringify(message.params.args));
    } else if (message.method === 'Log.entryAdded' && message.params.entry.level === 'error') {
      record.failures.push(message.params.entry.text);
    } else if (message.method === 'Network.loadingFailed' && !message.params.canceled) {
      record.failures.push(message.params.errorText);
    } else if (message.method === 'Network.requestWillBeSent') {
      record.requests.push(message.params.request.url);
    } else if (message.method === 'Network.responseReceived') {
      const { requestId, response, type } = message.params;
      record.responses.push({ request_id: requestId, url: response.url,
        status: response.status, type, from_disk_cache: response.fromDiskCache || false });
    } else if (message.method === 'Network.loadingFinished') {
      record.completed_requests.push(message.params.requestId);
    } else if (message.method === 'Network.webSocketCreated') {
      record.requests.push(message.params.url);
    }
  });
  const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
    const id = ++nextId;
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`CDP ${method} exceeded 10 seconds`));
    }, 10000);
    pending.set(id, { resolve, reject, timer });
    ws.send(JSON.stringify({ id, method, params, sessionId }));
  });
  const expectedURL = pathToFileURL(path.join(output, 'share/farmingrl/index.html')).href;
  let target;
  for (let attempt = 0; attempt < 100; attempt++) {
    const { targetInfos } = await send('Target.getTargets');
    target = targetInfos.find((item) => item.type === 'page' && item.url === expectedURL);
    if (target) break;
    await pause(50);
  }
  assert.ok(target, 'ordinary installed --app launch must open its store index');
  record.app_url = target.url;
  const { sessionId } = await send('Target.attachToTarget', { targetId: target.targetId, flatten: true });
  call = (method, params = {}) => send(method, params, sessionId);
  const evaluate = async (expression) => {
    const reply = await call('Runtime.evaluate', { expression, returnByValue: true });
    assert.ok(!reply.exceptionDetails, JSON.stringify(reply.exceptionDetails));
    return reply.result.value;
  };
  await call('Runtime.enable');
  await call('Network.enable');
  await call('Log.enable');
  await call('Page.enable');
  await call('Page.bringToFront');
  await call('Emulation.setDeviceMetricsOverride', {
    width: 1360, height: 900, deviceScaleFactor: 1, mobile: false,
  });
  // Reload through the ordinary browser UI protocol only, after observation is
  // attached, so initial scripts, console errors and all asset requests count.
  const previousLoads = pageLoads;
  await call('Page.reload');
  for (let attempt = 0; pageLoads === previousLoads && attempt < 200; attempt++) await pause(25);
  assert.ok(pageLoads > previousLoads, 'observed ordinary page reload must finish');
  record.startup_observation = 'ordinary app first load located, then browser-level reload with CDP observers attached';
  const healthy = () => {
    assert.deepEqual(nativeErrors(), [], 'no native Chromium ERROR/FATAL stderr lines');
    assert.equal(busClosed, undefined, 'the real private session bus must remain running');
    assert.deepEqual(record.failures, [], 'no page exceptions, console errors or failed loads');
    assert.ok(record.requests.every((url) => url.startsWith('file:') || url.startsWith('data:')),
      `unexpected network attempt: ${record.requests.join(', ')}`);
  };
  const snapshot = () => evaluate(`(() => {
    const canvas = document.querySelector('#td1_2 canvas');
    const status = document.querySelector('#td1_1 textarea');
    const log = document.querySelector('#td2_2 textarea');
    if (!canvas || !status || !log) return null;
    const rect = canvas.getBoundingClientRect();
    return { title: document.title, status: status.value, log: log.value,
      url: location.href, focused: document.activeElement.tagName,
      canvas: { width: canvas.width, height: canvas.height,
        x: rect.x, y: rect.y, visibleWidth: rect.width, visibleHeight: rect.height },
      resources: performance.getEntriesByType('resource').map(entry => entry.name) };
  })()`);
  const until = async (read, predicate, description, milliseconds = 5000) => {
    const end = Date.now() + milliseconds;
    do {
      healthy();
      const value = await read();
      if (predicate(value)) return value;
      await pause(50);
    } while (Date.now() < end);
    throw new Error(`Timed out waiting for ${description}`);
  };
  const screenshot = async (label) => {
    const { data } = await call('Page.captureScreenshot', { format: 'png', fromSurface: true });
    const png = Buffer.from(data, 'base64');
    assert.equal(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
    assert.equal(png.readUInt32BE(16), 1360);
    assert.equal(png.readUInt32BE(20), 900);
    assert.ok(png.length > 5000, 'actual map/HUD screenshot must not be blank');
    fs.writeFileSync(path.join(evidence, `${label}.png`), png);
    record.screenshots.push({ file: `${label}.png`, bytes: png.length,
      sha256: createHash('sha256').update(png).digest('hex') });
  };
  classification = 'upstream-initial-render';
  const initial = await until(snapshot, (value) => value?.log.includes('hjkl or aswd - move') &&
    /STAGE:1 HP:\d+\/\d+ LV:1 EXP:0\//.test(value.status), 'ordinary upstream canvas and HUD');
  assert.equal(initial.title, 'FarmingRL');
  assert.equal(initial.url, expectedURL);
  assert.equal(initial.focused, 'BODY', 'native movement must not type into a textarea');
  assert.ok(initial.canvas.width >= 480 && initial.canvas.height === 440);
  assert.equal(initial.canvas.width % 80, 0);
  assert.ok(initial.canvas.x >= 0 && initial.canvas.y >= 0);
  assert.ok(initial.canvas.x + initial.canvas.visibleWidth < 1360);
  assert.ok(initial.canvas.y + initial.canvas.visibleHeight < 900);
  record.requests.push(expectedURL, ...initial.resources);
  for (const asset of ['game.js', 'rot.js']) {
    const url = pathToFileURL(path.join(output, 'share/farmingrl', asset)).href;
    assert.ok(record.requests.includes(url), `${asset} must be requested during the observed reload`);
    assert.ok(record.responses.some((response) => response.url === url && response.type === 'Script' &&
      response.status >= 200 && response.status < 300 &&
      record.completed_requests.includes(response.request_id)),
    `${asset} must have a successful, completed CDP script-load receipt`);
  }
  record.initial = initial;
  await screenshot('initial');
  // Extract visible pixel tiles only.  The first frame at the documented spawn
  // supplies @'s exact raster; no game state or renderer internals are consulted.
  const pixels = (x, y) => evaluate(`(() => {
    const canvas = document.querySelector('#td1_2 canvas');
    const width = canvas.width / 80, height = canvas.height / 40;
    return Array.from(canvas.getContext('2d').getImageData(${x} * width, ${y} * height,
      width, height).data);
  })()`);
  const player = await pixels(4, 33);
  const floor = await pixels(5, 33);
  assert.notDeepEqual(player, floor, 'spawn @ must differ visibly from adjacent floor');
  assert.ok(player.some((value, index) => index % 4 !== 3 && value < 100), '@ must contain dark pixels');
  const key = async (character) => {
    const fields = { key: character, code: `Key${character.toUpperCase()}`,
      windowsVirtualKeyCode: character.toUpperCase().charCodeAt(0),
      nativeVirtualKeyCode: character.toUpperCase().charCodeAt(0) };
    await call('Input.dispatchKeyEvent', { type: 'keyDown', ...fields,
      text: character, unmodifiedText: character });
    await call('Input.dispatchKeyEvent', { type: 'keyUp', ...fields });
  };
  const isPlayer = (tile) => tile.length === player.length && tile.every((v, i) => v === player[i]);
  const movement = async (character, from, to, label) => {
    await key(character);
    const destination = await until(() => pixels(...to), isPlayer, `native ${character} moves @ to ${to}`);
    if (from.join() !== to.join()) {
      assert.ok(!isPlayer(await pixels(...from)), 'old tile must no longer contain @');
    }
    record.movement.push({ key: character, from, to, destination_sha256:
      createHash('sha256').update(Buffer.from(destination)).digest('hex'),
      player_template_match: true, snapshot: await snapshot() });
    await screenshot(label);
  };
  classification = 'native-keyboard-movement';
  await movement('l', [4, 33], [5, 33], 'right');
  // Row 34 at x=5 is a wall: native down must leave @ exactly where it was.
  await key('j');
  await pause(100);
  assert.ok(isPlayer(await pixels(5, 33)), 'wall must block the down key');
  record.movement.push({ key: 'j', from: [5, 33], to: [5, 33], wall_blocked: true });
  await movement('h', [5, 33], [4, 33], 'left-return');
  await movement('w', [4, 33], [4, 32], 'up');
  await movement('s', [4, 32], [4, 33], 'down-return');
  record.player_tile_template = { source: [4, 33], width: initial.canvas.width / 80,
    height: initial.canvas.height / 40, rgba: player };
  classification = 'natural-combat-timeout';
  const initialExp = Number(initial.status.match(/EXP:(\d+)\//)[1]);
  let final;
  const combatDeadline = Date.now() + 90000;
  let lastStatus = '';
  do {
    healthy();
    final = await snapshot();
    if (final.status !== lastStatus) {
      record.observations.push({ elapsed_ms: 90000 - (combatDeadline - Date.now()), ...final });
      lastStatus = final.status;
    }
    const positiveHit = /(?:^|\n)[1-9]\d* hit\. /m.test(final.log);
    const positiveDamage = /(?:^|\n)[1-9]\d* damage\. You -?\d+\/\d+/m.test(final.log);
    const exp = Number(final.status.match(/EXP:(\d+)\//)?.[1]);
    if (positiveHit && positiveDamage && / died(?:\.| and drops )/.test(final.log) && exp > initialExp) break;
    if (/You died|You win/.test(final.log)) {
      classification = 'natural-game-ended-before-combat-criteria';
      throw new Error('natural game ended before positive hits, HP damage and EXP increase were all visible');
    }
    await pause(100);
  } while (Date.now() < combatDeadline);
  record.final = final;
  await screenshot('combat');
  assert.match(final.log, /(?:^|\n)[1-9]\d* hit\. /m, 'positive combat hit must be visible');
  assert.match(final.log, /(?:^|\n)[1-9]\d* damage\. You -?\d+\/\d+/m,
    'positive HP damage must be visible in the native battle log');
  assert.match(final.log, / died(?:\.| and drops )/, 'a natural monster defeat must be visible');
  assert.ok(Number(final.status.match(/EXP:(\d+)\//)?.[1]) > initialExp, 'native HUD EXP must increase');
  record.combat = { positive_hit: true, positive_hp_damage: true, monster_defeated: true,
    exp_before: initialExp, exp_after: Number(final.status.match(/EXP:(\d+)\//)[1]),
    hp_log: final.log.split('\n').filter((line) => /[1-9]\d* damage\. You /.test(line)) };
  healthy();
  classification = 'launcher-state';
  assert.ok(fs.statSync(expectedProfile).isDirectory());
  const localState = path.join(expectedProfile, 'Local State');
  const profileState = JSON.parse(fs.readFileSync(localState, 'utf8'));
  assert.ok(profileState && typeof profileState === 'object', 'fresh profile must contain real Chromium Local State');
  record.profile_state_receipt = { file: localState, bytes: fs.statSync(localState).size,
    sha256: createHash('sha256').update(fs.readFileSync(localState)).digest('hex') };
  assert.ok(fs.statSync(path.join(process.env.XDG_CACHE_HOME, 'farmingrl/chromium')).isDirectory());
  record.status = 'passed';
  await send('Browser.close').catch(() => {});
  await exit;
  classification = 'native-browser-errors';
  assert.deepEqual(nativeErrors(), [], 'native errors during browser shutdown also fail');
  console.log('FARMINGRL_BROWSER_OK: visible @ movement, blocked wall, native HP damage and EXP gain');
} catch (error) {
  record.status = 'failed';
  record.failure_class = classification;
  record.error = error.stack || String(error);
  if (call && !closed) {
    try {
      const visible = await call('Runtime.evaluate', { returnByValue: true,
        expression: `({ status: document.querySelector('#td1_1 textarea')?.value,
          log: document.querySelector('#td2_2 textarea')?.value })` });
      if (!visible.exceptionDetails) record.failure_visible_state = visible.result.value;
      const { data } = await call('Page.captureScreenshot', { format: 'png', fromSurface: true });
      fs.writeFileSync(path.join(evidence, 'failure.png'), Buffer.from(data, 'base64'));
      record.screenshots.push({ file: 'failure.png' });
    } catch (captureError) {
      record.capture_error = String(captureError);
    }
  }
  console.error(record.error);
  process.exitCode = 1;
} finally {
  clearTimeout(deadline);
  for (const { timer } of pending.values()) clearTimeout(timer);
  ws?.close();
  if (browser && !closed) {
    browser.kill('SIGKILL');
    await exit;
  }
  if (sessionBus && !busClosed) {
    sessionBus.kill('SIGTERM');
    await busExit;
  }
  record.native_errors = nativeErrors();
  record.session_bus_exit = busClosed;
  if (record.native_errors.length) {
    record.status = 'failed';
    record.failure_class = 'native-browser-errors';
    process.exitCode = 1;
  }
  fs.writeFileSync(path.join(evidence, 'dbus.stderr'), busLog);
  fs.writeFileSync(path.join(evidence, 'chromium.stderr'), browserLog);
  fs.writeFileSync(path.join(evidence, 'evidence.json'), `${JSON.stringify(record, null, 2)}\n`);
}
