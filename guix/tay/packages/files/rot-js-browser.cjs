#!/usr/bin/env node
'use strict';

// Copied to tests/run.js by Guix. Keep the original HTML and spec bodies;
// only Jasmine's asset URLs and the jasmineStarted reporter are changed there.
const assert = require('assert').strict;
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const puppeteer = require('puppeteer-core');

const timeout = 120000;

function inventory(indexPath) {
  const html = fs.readFileSync(indexPath, 'utf8');
  const directory = path.join(path.dirname(indexPath), 'spec');
  const files = fs.readdirSync(directory).filter(name => name.endsWith('.js')).sort();
  assert.equal(files.length, 11, 'Original suite must contain all 11 spec files');
  const urls = new Map(files.map(name => [
    pathToFileURL(path.join(directory, name)).href, name,
  ]));
  const scripts = [];
  // Upstream uses ordinary quoted src attributes, not generated script tags.
  for (const tag of html.matchAll(/<script\b[^>]*>/gi)) {
    const src = tag[0].match(/\bsrc\s*=\s*(["'])(.*?)\1/i);
    if (src) {
      const url = new URL(src[2], pathToFileURL(indexPath)).href;
      if (urls.has(url)) scripts.push(urls.get(url));
    }
  }
  assert.deepEqual(scripts.sort(), files,
    'index.html must load every original spec file exactly once');

  const disabled = [];
  for (const file of files) {
    const source = fs.readFileSync(path.join(directory, file), 'utf8');
    const root = source.match(/^describe\(\s*(["'])(.*?)\1\s*,/m);
    assert.ok(root, `${file}: missing original top-level suite declaration`);
    // Match actual upstream literal xit declarations, not pending() or xdescribe.
    // A declaration may occur in a loop, so runtime totals are not hardcoded.
    for (const match of source.matchAll(/^\s*xit\(\s*(["'])(.*?)\1\s*,/gm)) {
      disabled.push({ file, root: root[2], description: match[2], seen: 0 });
    }
  }
  return { files, urls, disabled };
}

async function main() {
  let browser;
  let closing = false;
  let timer;
  let defined;
  let started = false;
  let done = false;
  let passed = 0;
  let disabledCount = 0;
  let overallStatus = 'not finished';
  const specs = new Set();
  const suites = new Set();
  const failures = [];
  const loaded = new Set();
  let manifest;
  let queue = Promise.resolve();
  let resolveDone;
  const completion = new Promise(resolve => { resolveDone = resolve; });
  let rejectFatal;
  const fatal = new Promise((resolve, reject) => { rejectFatal = reject; });

  function fail(error) {
    rejectFatal(error instanceof Error ? error : new Error(String(error)));
  }

  function expectations(result, label) {
    assert.ok(Array.isArray(result.failedExpectations), `${label}: missing failedExpectations`);
    for (const expectation of result.failedExpectations) {
      failures.push(`${label}\n${expectation.stack || expectation.message || JSON.stringify(expectation)}`);
    }
  }

  function consume(result) {
    if (!result || typeof result !== 'object') return;
    const isStarted = Object.prototype.hasOwnProperty.call(result, 'totalSpecsDefined');
    const isDone = Object.prototype.hasOwnProperty.call(result, 'overallStatus');
    const isSpec = typeof result.id === 'string' && /^spec\d+$/.test(result.id);
    const isSuite = typeof result.id === 'string' && /^suite\d+$/.test(result.id);
    if (!isStarted && !isDone && !isSpec && !isSuite) return;
    assert.ok(!done, 'Jasmine reporter event arrived after jasmineDone');
    if (isStarted) {
      assert.ok(!started, 'Duplicate jasmineStarted');
      assert.ok(Number.isInteger(result.totalSpecsDefined) && result.totalSpecsDefined > 0,
        'jasmineStarted must define a positive spec count');
      defined = result.totalSpecsDefined;
      started = true;
      return;
    }
    assert.ok(started, 'Jasmine result arrived before jasmineStarted');
    const label = result.fullName || result.id || 'jasmineDone';
    expectations(result, label);
    if (isSpec) {
      assert.ok(!specs.has(result.id), `Duplicate specDone: ${label}`);
      specs.add(result.id);
      if (result.status === 'passed') {
        passed++;
      } else {
        const declaration = manifest.disabled.find(item =>
          result.description === item.description &&
          typeof result.fullName === 'string' &&
          result.fullName.startsWith(`${item.root} `) &&
          result.fullName.endsWith(` ${item.description}`));
        if ((result.status === 'pending' || result.status === 'excluded') &&
            result.pendingReason === 'Temporarily disabled with xit' && declaration &&
            result.failedExpectations.length === 0) {
          declaration.seen++;
          disabledCount++;
          console.log(`upstream-disabled (${declaration.file}): ${result.fullName}`);
        } else {
          failures.push(`${label}: status ${result.status}; pendingReason ${result.pendingReason || '(none)'}`);
        }
      }
    } else if (isSuite) {
      assert.ok(!suites.has(result.id), `Duplicate suiteDone: ${label}`);
      suites.add(result.id);
      if (result.status === 'failed') failures.push(`${label}: suite failed`);
    } else if (isDone) {
      overallStatus = result.overallStatus;
      if (overallStatus !== 'passed') {
        failures.push(`jasmineDone: overallStatus ${overallStatus}; ${result.incompleteReason || ''}`);
      }
      assert.equal(specs.size, defined, 'Every defined spec must emit specDone');
      assert.equal(passed + disabledCount, defined,
        'Every defined spec must pass or match an original xit declaration');
      for (const declaration of manifest.disabled) {
        assert.ok(declaration.seen > 0,
          `Missing upstream-disabled spec: ${declaration.file}: ${declaration.description}`);
      }
      done = true;
      resolveDone();
    }
  }

  async function run() {
    const executablePath = process.env.ROT_JS_CHROMIUM;
    assert.ok(executablePath && path.isAbsolute(executablePath),
      'ROT_JS_CHROMIUM must name the absolute Guix Chromium executable');
    const indexPath = path.join(__dirname, 'index.html');
    manifest = inventory(indexPath);
    browser = await puppeteer.launch({
      executablePath,
      headless: true,
      timeout: 30000,
      args: ['--no-sandbox', '--disable-dev-shm-usage'],
    });
    browser.on('disconnected', () => {
      if (!closing) fail(new Error('Chromium disconnected unexpectedly'));
    });
    const page = await browser.newPage();
    page.on('pageerror', error => fail(error));
    page.on('error', error => fail(error)); // Puppeteer emits this on renderer crash.
    page.on('close', () => {
      if (!closing) fail(new Error('Test page closed unexpectedly'));
    });
    page.on('requestfailed', request => {
      if (!closing) fail(new Error(
        `Request failed: ${request.url()}: ${JSON.stringify(request.failure())}`));
    });
    page.on('requestfinished', request => {
      if (request.resourceType() === 'script' && manifest.urls.has(request.url())) {
        loaded.add(manifest.urls.get(request.url()));
      }
    });
    page.on('console', message => {
      // jsonValue is asynchronous. Chaining extraction, not only consumption,
      // preserves specDone/suiteDone/jasmineDone order even when CDP is busy.
      queue = queue.then(async () => {
        const args = message.args();
        if (args.length) consume(await args[0].jsonValue());
      }).catch(fail);
    });
    await page.setRequestInterception(true);
    page.on('request', request => {
      const protocol = new URL(request.url()).protocol;
      if (protocol === 'file:' || protocol === 'data:') {
        request.continue().catch(fail);
      } else {
        fail(new Error(`Forbidden non-local request: ${request.url()}`));
        request.abort().catch(fail);
      }
    });
    await page.goto(pathToFileURL(indexPath).href, { waitUntil: 'load', timeout });
    await completion;
    await queue;
    assert.deepEqual([...loaded].sort(), manifest.files,
      'Chromium must finish loading all 11 original spec scripts');
    if (failures.length) throw new Error('Jasmine suite did not satisfy the original-suite contract');
  }

  try {
    timer = setTimeout(() => fail(new Error(`Browser suite timed out after ${timeout / 1000}s`)), timeout);
    await Promise.race([fatal, run()]);
  } catch (error) {
    process.exitCode = 1;
    console.error(error.stack || error);
  } finally {
    clearTimeout(timer);
    console.log(`Original suite: ${loaded.size}/${manifest ? manifest.files.length : 11} spec files loaded; ` +
      `${defined === undefined ? 'unknown' : defined} specs defined, ${specs.size} reported, ` +
      `${passed} passed, ${disabledCount} upstream-disabled; overallStatus=${overallStatus}`);
    for (const failure of failures) console.error(failure);
    closing = true;
    if (browser) {
      let closeTimer;
      try {
        await Promise.race([
          browser.close(),
          new Promise((resolve, reject) => {
            closeTimer = setTimeout(() => reject(new Error('Chromium close timed out after 5s')), 5000);
          }),
        ]);
      } catch (error) {
        console.error(error.stack || error);
        // A broken CDP connection must not keep a failed runner alive forever.
        process.exit(1);
      } finally {
        clearTimeout(closeTimer);
      }
    }
  }
}

main().catch(error => {
  console.error(error.stack || error);
  process.exitCode = 1;
});
