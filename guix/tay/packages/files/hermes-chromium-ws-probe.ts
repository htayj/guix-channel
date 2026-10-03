// Guix replacement for electron/gateway-ws-probe.ts.
// This is an actual renderer WebSocket, not Node's TLS stack or an HTTP probe.
import { app, BrowserWindow, session } from 'electron'
import type { Session } from 'electron'
import { randomUUID } from 'node:crypto'

const DEFAULT_CONNECT_TIMEOUT_MS = 10_000
const DEFAULT_READY_GRACE_MS = 750
const DEFAULT_PROGRESS_CHECK_INTERVAL_MS = 1_000
const SPAWNED_BACKEND_MAX_CONNECT_WAIT_MS = 90_000
const probeWindows = new Set<BrowserWindow>()

type ProbeResult = { ok: boolean; reason?: string }
type ProbeEvent = { type: 'open' | 'message' | 'error' | 'close'; code?: number; reason?: string }
interface ProbeOptions {
  probePageUrl: string
  headers?: Record<string, string>
  connectTimeoutMs?: number
  readyGraceMs?: number
  progressCheckIntervalMs?: number
  maxConnectWaitMs?: number
  keepWaitingWhile?: () => boolean
}

// Fixed trusted code, evaluated only in the inert packaged file page. No preload,
// IPC, remote script, credential-bearing HTML, or Node WebSocket adapter exists.
// Only event classifications cross the boundary: never frames, URLs or headers.
const START_RENDERER_PROBE = `(url => {
  const queue = [];
  let waiter = null;
  const push = event => {
    if (waiter) { const deliver = waiter; waiter = null; deliver(event); }
    else queue.push(event);
  };
  const socket = new WebSocket(url);
  globalThis.__hermesWsProbe = {
    next: () => {
      if (queue.length) return Promise.resolve(queue.shift());
      const { promise, resolve } = Promise.withResolvers();
      waiter = resolve;
      return promise;
    }
  };
  socket.onopen = () => push({ type: 'open' });
  socket.onmessage = () => { socket.onmessage = null; push({ type: 'message' }); };
  socket.onerror = () => { socket.onerror = null; push({ type: 'error' }); };
  socket.onclose = event => push({ type: 'close', code: event.code, reason: event.reason });
})`

function closeReason(event: ProbeEvent, fallback: string): string {
  const reason = event.reason?.trim() || ''
  if (event.code && reason) return `${fallback} (code ${event.code}: ${reason})`
  if (event.code) return `${fallback} (code ${event.code})`
  return reason ? `${fallback} (${reason})` : fallback
}

function probeGatewayWebSocket(wsUrl: string, options: ProbeOptions): Promise<ProbeResult> {
  let target: URL
  let page: URL
  try {
    target = new URL(wsUrl)
    page = new URL(options.probePageUrl)
    if (!['ws:', 'wss:'].includes(target.protocol) || target.username || target.password || target.hash) {
      throw new Error('Invalid gateway WebSocket URL.')
    }
    if (page.protocol !== 'file:' || page.search || page.hash) throw new Error('Invalid packaged WebSocket probe page.')
  } catch {
    return Promise.resolve({ ok: false, reason: 'Invalid WebSocket probe configuration.' })
  }
  if (!app.isReady()) return Promise.resolve({ ok: false, reason: 'Electron is not ready for a WebSocket probe.' })

  const connectTimeoutMs = options.connectTimeoutMs ?? DEFAULT_CONNECT_TIMEOUT_MS
  const readyGraceMs = options.readyGraceMs ?? DEFAULT_READY_GRACE_MS
  const progressCheckIntervalMs = options.progressCheckIntervalMs ?? DEFAULT_PROGRESS_CHECK_INTERVAL_MS
  const hardCapMs = Math.max(connectTimeoutMs, options.maxConnectWaitMs ?? connectTimeoutMs)
  // Copy per-probe header ownership. The main configuration's existing decrypt
  // funnel sanitizes values; these credentials never enter renderer JavaScript.
  const headers = { ...options.headers }

  const { promise, resolve } = Promise.withResolvers<ProbeResult>()
  {
    const startedAt = Date.now()
    let settled = false
    let opened = false
    let win: BrowserWindow | null = null
    let connectTimer: NodeJS.Timeout | undefined
    let graceTimer: NodeJS.Timeout | undefined
    let privateSession: Session | null = null
    const observedWindows = new Set<BrowserWindow>()

    const finish = (result: ProbeResult) => {
      if (settled) return
      settled = true
      clearTimeout(connectTimer)
      clearTimeout(graceTimer)
      app.removeListener('before-quit', onQuit)
      app.removeListener('browser-window-created', onWindowCreated)
      for (const window of observedWindows) window.removeListener('closed', onNormalWindowClosed)
      privateSession?.webRequest.onBeforeRequest(null)
      privateSession?.webRequest.onBeforeSendHeaders(null)
      privateSession?.webRequest.onErrorOccurred(null)
      if (win) {
        probeWindows.delete(win)
        // Destroying the renderer closes the socket even during a stuck upgrade,
        // page load, renderer crash, or a pending next-event promise.
        if (!win.isDestroyed()) win.destroy()
      }
      // Non-persistent unique sessions have no cookies/cache/profile on disk.
      // Drop listeners and all header references; do not mutate app sessions.
      resolve(result)
    }
    const fail = (reason: string) => finish({ ok: false, reason })
    const onQuit = () => fail('The application quit during the WebSocket probe.')
    const onNormalWindowClosed = () => {
      // A hidden diagnostic must not keep the application alive after its last
      // real window closes. Teardown lets the app's window-all-closed policy run.
      if (!BrowserWindow.getAllWindows().some(window => !probeWindows.has(window))) {
        fail('The application window closed during the WebSocket probe.')
      }
    }
    const onWindowCreated = (_event: Electron.Event, window: BrowserWindow) => {
      observedWindows.add(window)
      window.on('closed', onNormalWindowClosed)
    }
    const checkDeadline = () => {
      if (settled || opened) return
      const elapsedMs = Date.now() - startedAt
      let keepWaiting = false
      try { keepWaiting = Boolean(options.keepWaitingWhile?.()) } catch { /* fail closed */ }
      if (!keepWaiting) {
        fail(elapsedMs > connectTimeoutMs
          ? `Timed out after ${elapsedMs}ms waiting for the WebSocket to open (backend stopped after the ${connectTimeoutMs}ms budget).`
          : `Timed out after ${connectTimeoutMs}ms waiting for the WebSocket to open.`)
      } else if (elapsedMs >= hardCapMs) {
        fail(`Timed out after ${elapsedMs}ms waiting for the WebSocket to open (backend still running at the ${hardCapMs}ms cap).`)
      } else {
        connectTimer = setTimeout(checkDeadline, Math.min(progressCheckIntervalMs, hardCapMs - elapsedMs))
      }
    }

    app.on('before-quit', onQuit)
    app.on('browser-window-created', onWindowCreated)
    for (const window of BrowserWindow.getAllWindows()) onWindowCreated({} as Electron.Event, window)
    if (connectTimeoutMs > 0) connectTimer = setTimeout(checkDeadline, connectTimeoutMs)

    const run = async () => {
      privateSession = session.fromPartition(`hermes-ws-probe-${randomUUID()}`, { cache: false })
      privateSession.setPermissionCheckHandler(() => false)
      privateSession.setPermissionRequestHandler((_contents, _permission, callback) => callback(false))
      // Exact URL + webContents ownership, not just a hostname match: redirects
      // or any other requests cannot receive access-proxy credentials.
      privateSession.webRequest.onBeforeRequest((details, callback) => {
        const owned = win && details.webContentsId === win.webContents.id
        const allowed = owned && (details.url === page.href ||
          (details.resourceType === 'webSocket' && details.url === target.href))
        callback({ cancel: !allowed })
      })
      privateSession.webRequest.onBeforeSendHeaders((details, callback) => {
        if (win && details.webContentsId === win.webContents.id &&
            details.resourceType === 'webSocket' && details.url === target.href) {
          callback({ requestHeaders: { ...details.requestHeaders, ...headers } })
        } else callback({})
      })
      privateSession.webRequest.onErrorOccurred(details => {
        if (win && details.webContentsId === win.webContents.id &&
            details.resourceType === 'webSocket' && details.url === target.href) {
          // Chromium error names contain no request URL or credentials.
          const code = /^net::ERR_[A-Z0-9_]+$/.test(details.error) ? details.error : ''
          fail(code ? `WebSocket connection failed (${code}).` : 'WebSocket connection failed.')
        }
      })
      win = new BrowserWindow({
        show: false, width: 1, height: 1, skipTaskbar: true,
        webPreferences: {
          session: privateSession, nodeIntegration: false, contextIsolation: true,
          sandbox: true, webSecurity: true, webviewTag: false, devTools: false,
          backgroundThrottling: false
        }
      })
      probeWindows.add(win)
      win.webContents.setWindowOpenHandler(() => ({ action: 'deny' }))
      win.webContents.on('will-navigate', event => event.preventDefault())
      win.webContents.on('will-redirect', event => event.preventDefault())
      win.webContents.on('will-attach-webview', event => event.preventDefault())
      win.webContents.once('render-process-gone', () => fail('The WebSocket probe renderer stopped.'))
      win.once('closed', () => fail('The WebSocket probe window closed.'))
      await win.loadURL(page.href)
      if (settled) return
      // file:// gives Origin: null, exactly like the packaged chat renderer.
      // Chromium retains its default full PKI/hostname/nameConstraints checks.
      await win.webContents.executeJavaScript(`${START_RENDERER_PROBE}(${JSON.stringify(target.href)})`)
      while (!settled) {
        const event: ProbeEvent = await win.webContents.executeJavaScript('globalThis.__hermesWsProbe.next()')
        if (settled) return
        if (event.type === 'open') {
          opened = true
          clearTimeout(connectTimer)
          graceTimer = setTimeout(() => finish({ ok: true }), readyGraceMs)
        } else if (event.type === 'message') {
          finish({ ok: true })
        } else if (event.type === 'error') {
          fail('WebSocket connection failed.')
        } else if (event.type === 'close') {
          fail(closeReason(event, opened
            ? 'The gateway accepted the connection then closed it (credential rejected?).'
            : 'The gateway closed the WebSocket before it opened.'))
        }
      }
    }
    // Do not expose URL-bearing Chromium exceptions (the WS URL has a token).
    run().catch(() => fail('The native Chromium WebSocket probe failed.'))
  }
  return promise
}

function spawnedBackendProbeOptions(isChildAlive: () => boolean) {
  return {
    connectTimeoutMs: DEFAULT_CONNECT_TIMEOUT_MS,
    maxConnectWaitMs: SPAWNED_BACKEND_MAX_CONNECT_WAIT_MS,
    keepWaitingWhile: isChildAlive
  }
}

export {
  DEFAULT_CONNECT_TIMEOUT_MS, DEFAULT_PROGRESS_CHECK_INTERVAL_MS,
  DEFAULT_READY_GRACE_MS, SPAWNED_BACKEND_MAX_CONNECT_WAIT_MS,
  probeGatewayWebSocket, spawnedBackendProbeOptions
}
