// Unit event/lifecycle tests; real Chromium TLS + RFC6455 acceptance is separate.
// Replaces the obsolete Node WebSocket adapter tests in the pinned build source.
import assert from 'node:assert/strict'
import type { EventEmitter } from 'node:events'
import type { BrowserWindowConstructorOptions } from 'electron'
import { afterEach, beforeEach, test, vi } from 'vitest'
import type { Mock } from 'vitest'

type ProbeEvent = { type: 'open' | 'message' | 'error' | 'close'; code?: number; reason?: string }
type RequestDetails = { webContentsId: number; resourceType: string; url: string; requestHeaders: Record<string, string> }
type RequestResult = { cancel?: boolean; requestHeaders?: Record<string, string> }
type RequestListener = (details: RequestDetails, callback: (result: RequestResult) => void) => void
type NativeSession = {
  partition: string; options: { cache: boolean }; request: RequestListener | null;
  headers: RequestListener | null; error: ((details: RequestDetails & { error: string }) => void) | null
}
type NativeWindow = {
  destroyed: boolean; preferences: NonNullable<BrowserWindowConstructorOptions['webPreferences']>;
  event: (value: ProbeEvent) => void;
  webContents: EventEmitter & { id: number; setWindowOpenHandler: Mock;
    executeJavaScript: Mock }
}
const native = vi.hoisted(() => ({
  app: undefined as unknown as EventEmitter,
  windows: [] as NativeWindow[], sessions: [] as NativeSession[]
}))
vi.mock('electron', async () => {
  // vi.mock factories run before ordinary import bindings initialize; this
  // test intentionally crosses the hoisted module-loading boundary.
  const { EventEmitter } = await import('node:events')
  native.app = Object.assign(new EventEmitter(), { isReady: () => true })
  class BrowserWindow extends EventEmitter {
    static getAllWindows() { return native.windows.filter(window => !window.destroyed) }
    destroyed = false
    preferences: NonNullable<BrowserWindowConstructorOptions['webPreferences']>
    webContents: NativeWindow['webContents']
    events: ProbeEvent[] = []
    waiter: ((event: ProbeEvent) => void) | null = null
    constructor(options: BrowserWindowConstructorOptions) {
      super()
      this.preferences = options.webPreferences || {}
      this.webContents = Object.assign(new EventEmitter(), {
        id: native.windows.length + 1,
        setWindowOpenHandler: vi.fn(),
        executeJavaScript: vi.fn(async (code: string) => {
          if (code !== 'globalThis.__hermesWsProbe.next()') return undefined
          if (this.events.length) return this.events.shift()
          const { promise, resolve } = Promise.withResolvers<ProbeEvent>()
          this.waiter = resolve
          return promise
        })
      })
      native.windows.push(this)
      native.app.emit('browser-window-created', {}, this)
    }
    async loadURL() {}
    isDestroyed() { return this.destroyed }
    destroy() { this.destroyed = true; this.emit('closed') }
    event(value: ProbeEvent) {
      if (this.waiter) { const deliver = this.waiter; this.waiter = null; deliver(value) }
      else this.events.push(value)
    }
  }
  return {
    app: native.app, BrowserWindow,
    session: { fromPartition: (partition: string, options: { cache: boolean }) => {
      const value: NativeSession & { setPermissionCheckHandler: Mock;
        setPermissionRequestHandler: Mock; webRequest: {
          onBeforeRequest: (listener: RequestListener | null) => void;
          onBeforeSendHeaders: (listener: RequestListener | null) => void;
          onErrorOccurred: (listener: NativeSession['error']) => void
        } } = { partition, options, request: null, headers: null, error: null,
        setPermissionCheckHandler: vi.fn(), setPermissionRequestHandler: vi.fn(),
        webRequest: {
          onBeforeRequest: (listener: RequestListener | null) => { value.request = listener },
          onBeforeSendHeaders: (listener: RequestListener | null) => { value.headers = listener },
          onErrorOccurred: (listener: NativeSession['error']) => { value.error = listener }
      }
      }
      native.sessions.push(value)
      return value
    } }
  }
})

import { probeGatewayWebSocket, spawnedBackendProbeOptions, DEFAULT_CONNECT_TIMEOUT_MS,
  DEFAULT_READY_GRACE_MS, DEFAULT_PROGRESS_CHECK_INTERVAL_MS, SPAWNED_BACKEND_MAX_CONNECT_WAIT_MS } from './gateway-ws-probe'
const page = 'file:///gnu/store/example/public/hermes-ws-probe.html'
const target = 'wss://192.0.2.1/api/ws?token=test-only'
const flush = async () => { for (let i = 0; i < 8; i++) await Promise.resolve() }
const start = () => probeGatewayWebSocket(target, { probePageUrl: page, readyGraceMs: 750 })

beforeEach(() => { vi.useFakeTimers(); native.windows.length = 0; native.sessions.length = 0 })
afterEach(() => { native.app.emit('before-quit'); vi.useRealTimers(); native.app.removeAllListeners() })

test('retains the cold-child policy constants and main-process callback', () => {
  const alive = () => true
  assert.equal(DEFAULT_CONNECT_TIMEOUT_MS, 10_000)
  assert.equal(DEFAULT_READY_GRACE_MS, 750)
  assert.equal(DEFAULT_PROGRESS_CHECK_INTERVAL_MS, 1_000)
  assert.equal(SPAWNED_BACKEND_MAX_CONNECT_WAIT_MS, 90_000)
  assert.deepEqual(spawnedBackendProbeOptions(alive), {
    connectTimeoutMs: 10_000, maxConnectWaitMs: 90_000, keepWaitingWhile: alive
  })
})

test('creates a sandboxed private window and injects headers only on its exact WS URL', async () => {
  const pending = probeGatewayWebSocket(target, { probePageUrl: page, headers: { 'X-Access': 'test-secret' } })
  await flush()
  const window = native.windows[0]
  const sess = native.sessions[0]
  assert.equal(sess.partition.startsWith('persist:'), false)
  assert.deepEqual(sess.options, { cache: false })
  assert.equal(window.preferences.nodeIntegration, false)
  assert.equal(window.preferences.contextIsolation, true)
  assert.equal(window.preferences.sandbox, true)
  assert.equal(window.preferences.webSecurity, true)
  assert.equal(window.preferences.preload, undefined)
  const details = { webContentsId: window.webContents.id, resourceType: 'webSocket', url: target, requestHeaders: { Origin: 'null' } }
  let answer: RequestResult = {}
  sess.headers?.(details, result => { answer = result })
  assert.deepEqual(answer.requestHeaders, { Origin: 'null', 'X-Access': 'test-secret' })
  for (const changed of [{ url: 'wss://elsewhere.invalid/api/ws' }, { webContentsId: 999 }, { resourceType: 'xhr' }]) {
    sess.headers?.({ ...details, ...changed }, result => { answer = result })
    assert.deepEqual(answer, {})
    sess.request?.({ ...details, ...changed }, result => { answer = result })
    assert.equal(answer.cancel, true)
  }
  const script = window.webContents.executeJavaScript.mock.calls[0][0]
  assert.match(script, /new WebSocket\(url\)/)
  assert.equal(script.includes('test-secret'), false)
  window.event({ type: 'message' })
  assert.deepEqual(await pending, { ok: true })
  assert.equal(window.destroyed, true)
  assert.equal(sess.headers, null)
  assert.equal(sess.request, null)
})

test('actual open requires the grace period but a frame succeeds immediately', async () => {
  const pending = start(); await flush()
  native.windows[0].event({ type: 'open' }); await flush()
  await vi.advanceTimersByTimeAsync(749)
  assert.equal(native.windows[0].destroyed, false)
  await vi.advanceTimersByTimeAsync(1)
  assert.deepEqual(await pending, { ok: true })
})

for (const opened of [false, true]) {
  test(`classifies close ${opened ? 'after' : 'before'} upgrade and tears down`, async () => {
    const pending = start(); await flush()
    if (opened) { native.windows[0].event({ type: 'open' }); await flush() }
    native.windows[0].event({ type: 'close', code: 4403, reason: 'forbidden' })
    const result = await pending
    assert.equal(result.ok, false)
    assert.match(result.reason || '', opened ? /accepted.*closed/ : /before it opened/)
    assert.match(result.reason || '', /4403: forbidden/)
    assert.equal(native.windows[0].destroyed, true)
  })
}

test('error and app quit fail closed without leaking target credentials', async () => {
  const pending = start(); await flush()
  native.windows[0].event({ type: 'error' })
  assert.deepEqual(await pending, { ok: false, reason: 'WebSocket connection failed.' })
  const next = start(); await flush()
  native.app.emit('before-quit')
  assert.equal((await next).ok, false)
  assert.equal(native.windows[1].destroyed, true)
})

test('keeps waiting for a live cold child, then fails if the child dies', async () => {
  let alive = true
  const pending = probeGatewayWebSocket(target, { probePageUrl: page, ...spawnedBackendProbeOptions(() => alive) })
  await flush()
  await vi.advanceTimersByTimeAsync(10_000)
  assert.equal(native.windows[0].destroyed, false)
  alive = false
  await vi.advanceTimersByTimeAsync(1_000)
  assert.match((await pending).reason || '', /backend stopped/)
})

test('caps a live stalled child and treats a throwing callback as stopped', async () => {
  const pending = probeGatewayWebSocket(target, { probePageUrl: page, ...spawnedBackendProbeOptions(() => true) })
  await flush()
  await vi.advanceTimersByTimeAsync(90_000)
  assert.match((await pending).reason || '', /90000ms cap/)
  const next = probeGatewayWebSocket(target, { probePageUrl: page, keepWaitingWhile: () => { throw new Error('dead') } })
  await flush()
  await vi.advanceTimersByTimeAsync(10_000)
  assert.equal((await next).ok, false)
})

test('open cancels the connect deadline while grace still classifies an early close', async () => {
  const pending = probeGatewayWebSocket(target, { probePageUrl: page, connectTimeoutMs: 10, readyGraceMs: 750 })
  await flush()
  native.windows[0].event({ type: 'open' }); await flush()
  await vi.advanceTimersByTimeAsync(20)
  assert.equal(native.windows[0].destroyed, false)
  native.windows[0].event({ type: 'close', code: 4401 })
  assert.equal((await pending).ok, false)
})

test('denies navigation, popups, unexpected requests and renderer crashes', async () => {
  const pending = start(); await flush()
  const contents = native.windows[0].webContents
  assert.deepEqual(contents.setWindowOpenHandler.mock.calls[0][0](), { action: 'deny' })
  for (const event of ['will-navigate', 'will-redirect', 'will-attach-webview']) {
    const preventDefault = vi.fn()
    contents.emit(event, { preventDefault })
    assert.equal(preventDefault.mock.calls.length, 1)
  }
  contents.emit('render-process-gone')
  assert.equal((await pending).ok, false)
  assert.equal(native.app.listenerCount('before-quit'), 0)
})

test('reports Chromium certificate error codes without URL credentials', async () => {
  const pending = start(); await flush()
  const window = native.windows[0]
  const sess = native.sessions[0]
  sess.error?.({ webContentsId: window.webContents.id, resourceType: 'webSocket',
    url: target, requestHeaders: {}, error: 'net::ERR_CERT_NAME_CONSTRAINT_VIOLATION' })
  assert.deepEqual(await pending, {
    ok: false, reason: 'WebSocket connection failed (net::ERR_CERT_NAME_CONSTRAINT_VIOLATION).'
  })
  assert.equal(sess.error, null)
  assert.equal(window.destroyed, true)
})
