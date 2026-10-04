// External consumer driver: native Chromium input events, upstream canvas, real PNGs.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [chrome, moduleRoot, page, evidence, scratch] = process.argv.slice(2);
assert.equal(process.getuid(), Number(process.env.LITEGRAPH_EXPECTED_UID));
assert.equal(process.getgid(), Number(process.env.LITEGRAPH_EXPECTED_GID));
const interfaces = fs.readFileSync('/proc/net/dev', 'utf8').split('\n').slice(2)
  .filter((line) => line.includes(':')).map((line) => line.split(':')[0].trim());
assert.deepEqual(interfaces, ['lo'], 'only loopback may exist in the network namespace');
const storeMount = fs.readFileSync('/proc/self/mountinfo', 'utf8').split('\n')
  .filter((line) => line.split(' ')[4] === '/gnu/store').at(-1);
assert.ok(storeMount?.split(' ')[5].split(',').includes('ro'), 'store must be mounted read-only');
assert.ok(typeof WebSocket === 'function', 'Node must provide the standard WebSocket client');

const browser = spawn(chrome, [
  '--headless=new', '--no-sandbox', '--no-first-run', '--no-default-browser-check',
  '--disable-background-networking', '--disable-component-update', '--disable-sync',
  '--allow-file-access-from-files', '--use-angle=swiftshader', '--enable-unsafe-swiftshader',
  '--hide-scrollbars', '--window-size=1200,850',
  '--remote-debugging-port=0', `--user-data-dir=${path.join(scratch, 'chromium-profile')}`,
  'about:blank',
], { stdio: ['ignore', 'ignore', 'pipe'] });
let log = '';
let ws;
let closed;
const exit = new Promise((resolve) => browser.once('exit', (code, signal) => {
  closed = { code, signal };
  resolve(closed);
}));
const deadline = setTimeout(() => {
  console.error('LiteGraph browser interaction timed out');
  browser.kill('SIGKILL');
  process.exit(1);
}, 90000);
const pending = new Map();
let nextId = 0;
const failures = [];
const network = [];
const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
try {
  const endpoint = await new Promise((resolve, reject) => {
    browser.stderr.on('data', (chunk) => {
      log += chunk.toString();
      const match = log.match(/DevTools listening on (ws:\S+)/);
      if (match) resolve(match[1]);
    });
    browser.once('error', reject);
    browser.once('exit', () => reject(new Error(`Chromium exited before ready: ${log}`)));
  });
  ws = new WebSocket(endpoint);
  await new Promise((resolve, reject) => {
    ws.addEventListener('open', resolve, { once: true });
    ws.addEventListener('error', reject, { once: true });
  });
  ws.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const { resolve, reject } = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) reject(new Error(JSON.stringify(message.error)));
      else resolve(message.result);
    } else if (message.method === 'Runtime.exceptionThrown') {
      failures.push(message.params.exceptionDetails.exception?.description || message.params.exceptionDetails.text);
    } else if (message.method === 'Network.loadingFailed' && !message.params.canceled) {
      failures.push(message.params.errorText);
    } else if (message.method === 'Network.requestWillBeSent') {
      network.push(message.params.request.url);
    } else if (message.method === 'Log.entryAdded' && message.params.entry.level === 'error') {
      failures.push(message.params.entry.text);
    }
  });
  const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
    const id = ++nextId;
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, method, params, sessionId }));
  });
  const results = [];
  for (const [label, bundle] of [['source', 'litegraph.js'], ['minified', 'litegraph.min.js']]) {
    const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
    const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
    const call = (method, params = {}) => send(method, params, sessionId);
    const evaluate = async (expression) => {
      const reply = await call('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
      assert.ok(!reply.exceptionDetails, JSON.stringify(reply.exceptionDetails));
      return reply.result.value;
    };
    const until = async (expression, description) => {
      for (let attempt = 0; attempt < 100; attempt++) {
        const value = await evaluate(expression);
        if (value) return value;
        assert.equal(failures.length, 0, failures.join('\n'));
        await pause(50);
      }
      throw new Error(`Timed out waiting for ${description}`);
    };
    await call('Runtime.enable');
    await call('Network.enable');
    await call('Log.enable');
    await call('Page.enable');
    await call('Emulation.setDeviceMetricsOverride', {
      width: 1200, height: 850, deviceScaleFactor: 1, mobile: false,
    });
    const url = pathToFileURL(page);
    url.searchParams.set('root', pathToFileURL(`${moduleRoot}/`).href);
    url.searchParams.set('bundle', bundle);
    await call('Page.navigate', { url: url.href });
    await until('Boolean(window.consumer)', 'upstream consumer initialization');
    await evaluate('document.fonts.ready.then(() => true)');
    await until('consumer.inspect().gridLoaded', 'installed upstream grid image');
    const initial = await evaluate('consumer.inspect()');
    assert.equal(initial.nativeCanvas, true);
    assert.equal(initial.editorLoaded, true);
    assert.equal(initial.value, 7);
    assert.equal(initial.widgetValue, 7);
    assert.equal(initial.output, 12);
    assert.equal(initial.watch, 12);
    assert.equal(initial.graph.links.length, 3);
    assert.ok(initial.canvas.width >= 1000 && initial.canvas.height >= 600);

    const mouse = (type, point, extra = {}) => call('Input.dispatchMouseEvent', {
      type, x: point.x, y: point.y, ...extra,
    });
    // No position mutation through evaluate: the native title is dragged by Chromium.
    await mouse('mouseMoved', initial.title);
    await mouse('mousePressed', initial.title, { button: 'left', buttons: 1, clickCount: 1 });
    for (let step = 1; step <= 8; step++) {
      await mouse('mouseMoved', { x: initial.title.x + step * 10, y: initial.title.y + step * 5 },
        { button: 'left', buttons: 1 });
      await pause(15);
    }
    await mouse('mouseReleased', { x: initial.title.x + 80, y: initial.title.y + 40 },
      { button: 'left', buttons: 0, clickCount: 1 });
    await evaluate('consumer.update()');
    const dragged = await evaluate('consumer.inspect()');
    assert.deepEqual(dragged.position, [initial.position[0] + 80, initial.position[1] + 40]);
    assert.equal(dragged.output, 12);
    // Keep the following widget click out of the native double-click interval.
    await pause(350);
    await mouse('mouseMoved', dragged.widget);
    await mouse('mousePressed', dragged.widget, { button: 'left', buttons: 1, clickCount: 1 });
    await mouse('mouseReleased', dragged.widget, { button: 'left', buttons: 0, clickCount: 1 });
    await until('Boolean(document.querySelector(".graphdialog input.value"))', 'native number prompt');
    const input = await evaluate(`(() => {
      const box = document.querySelector('.graphdialog input.value').getBoundingClientRect();
      return { x: box.x + box.width / 2, y: box.y + box.height / 2 };
    })()`);
    await mouse('mouseMoved', input);
    await mouse('mousePressed', input, { button: 'left', buttons: 1, clickCount: 1 });
    await mouse('mouseReleased', input, { button: 'left', buttons: 0, clickCount: 1 });
    await until('document.activeElement?.matches(".graphdialog input.value")', 'focused native prompt');
    // Native Ctrl+A editing command then insertText produces trusted browser input.
    await call('Input.dispatchKeyEvent', {
      type: 'keyDown', modifiers: 2, key: 'a', code: 'KeyA', windowsVirtualKeyCode: 65,
      commands: ['selectAll'],
    });
    await call('Input.dispatchKeyEvent', {
      type: 'keyUp', modifiers: 2, key: 'a', code: 'KeyA', windowsVirtualKeyCode: 65,
    });
    await call('Input.insertText', { text: '11' });
    await call('Input.dispatchKeyEvent', {
      type: 'keyDown', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13,
    });
    await call('Input.dispatchKeyEvent', {
      type: 'keyUp', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13,
    });
    await until('!document.querySelector(".graphdialog")', 'native prompt commit');
    await evaluate('consumer.update()');
    const edited = await evaluate('consumer.inspect()');
    assert.equal(edited.value, 11);
    assert.equal(edited.widgetValue, 11);
    assert.equal(edited.output, 16);
    assert.equal(edited.watch, 16);
    assert.deepEqual(edited.position, dragged.position);
    assert.ok(edited.trusted.mousedown >= 3 && edited.trusted.mousemove >= 8);
    assert.ok(edited.trusted.keydown >= 2 && edited.trusted.input >= 1);
    assert.deepEqual(edited.graph.links, initial.graph.links, 'input must not disconnect graph edges');
    const imported = await evaluate('consumer.roundtrip()');
    assert.equal(imported.output, 16);
    assert.equal(imported.watch, 16);
    assert.equal(imported.value, 11);
    assert.deepEqual(imported.position, dragged.position);
    assert.deepEqual(imported.graph.links, edited.graph.links);
    assert.deepEqual(imported.graph.nodes.map((node) => node.id), edited.graph.nodes.map((node) => node.id));
    await evaluate('new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))).then(() => true)');
    assert.equal(failures.length, 0, failures.join('\n'));
    const { data } = await call('Page.captureScreenshot', { format: 'png', fromSurface: true });
    const png = Buffer.from(data, 'base64');
    assert.equal(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
    fs.writeFileSync(path.join(evidence, `${label}.png`), png);
    const record = { bundle, initial, dragged, edited, imported,
      screenshot: `${label}.png`, input: 'Chromium CDP trusted mouse/key/input events' };
    fs.writeFileSync(path.join(evidence, `browser-${label}.json`), `${JSON.stringify(record, null, 2)}\n`);
    fs.writeFileSync(path.join(evidence, `${label}.geometry`),
      `${Math.round(initial.canvas.width)}x${Math.round(initial.canvas.height)}+${Math.round(initial.canvas.x)}+${Math.round(initial.canvas.y)}\n`);
    results.push(record);
    await send('Target.closeTarget', { targetId });
  }
  assert.ok(network.length > 0);
  assert.ok(network.every((url) => /^(file|data):/.test(url)), 'consumer requested a network asset');
  fs.writeFileSync(path.join(evidence, 'evidence.json'), `${JSON.stringify({
    status: 'passed', uid: process.getuid(), gid: process.getgid(), interfaces,
    readonly_store: true, requests: network, failures, results,
  }, null, 2)}\n`);
  send('Browser.close').catch(() => {});
  await exit;
  console.log('LITEGRAPH_BROWSER_OK: both real bundles dragged, widget edited, imported, rendered');
} finally {
  clearTimeout(deadline);
  ws?.close();
  if (!closed) {
    browser.kill('SIGKILL');
    await exit;
  }
  fs.writeFileSync(path.join(evidence, 'chromium.stderr'), log);
}
