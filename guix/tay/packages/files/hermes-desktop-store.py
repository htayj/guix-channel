#!/usr/bin/env python3
"""Patch the pinned Hermes Desktop source for an immutable Guix installation.

Invocation: hermes-desktop-store.py SOURCE_ROOT BACKEND_STORE_ROOT DESKTOP_STORE_ROOT
The desktop output contains share/hermes-desktop/{dist,resources,assets,public}.
The pinned Electron transport and store-path anchors are checked before writing.
"""

import hashlib
import json
import sys
from pathlib import Path


PINNED_COMMIT = "f97608f178d1ffeca59860195ab7da295f7c8e5f"


def patch_gateway_transport(source_root, source):
    """Prepare the Chromium transport cutover; fail on any pinned-source drift."""
    electron = source_root / "apps/desktop/electron"
    transport_path = electron / "api-transport.ts"
    tests_path = electron / "api-transport.test.ts"
    stream_path = electron / "gateway-file-download.ts"
    transport = transport_path.read_text(encoding="utf-8")
    tests = tests_path.read_text(encoding="utf-8")
    stream = stream_path.read_text(encoding="utf-8")

    def replace(text, old, new, count=1):
        found = text.count(old)
        if found != count:
            raise ValueError(f"Pinned transport anchor changed: expected {count}, found {found}: {old!r}")
        return text.replace(old, new)

    def region(text, start, end, digest, replacement):
        if text.count(start) != 1 or text.count(end) != 1:
            raise ValueError(f"Pinned transport region anchors changed: {start!r}, {end!r}")
        first = text.index(start)
        last = text.index(end, first)
        if hashlib.sha256(text[first:last].encode("utf-8")).hexdigest() != digest:
            raise ValueError(f"Pinned transport region changed: {start!r}")
        return text[:first] + replacement + text[last:]

    source = replace(source, "import http from 'node:http'\n", "")
    for name in ("destroyKeepaliveAgents", "downloadAgentFor", "jsonAgentFor"):
        source = replace(source, f"  {name},\n", "")
        transport = replace(transport, f"  {name},\n", "")
    source = replace(source, "  destroyKeepaliveAgents()", "  abortGatewayRequests()")
    source = replace(source,
        "// endpoints, e.g. kanban attachments). Hand-rolled because node's http has no\n"
        "// FormData and the payload is one file — a dependency would be overkill.",
        "// endpoints, e.g. kanban attachments). The payload is one file; keep the\n"
        "// explicit multipart serialization shared by the native request helpers.")
    source = region(source,
        "function fetchJson(url, token, options: any = {}) {",
        "function mimeTypeForPath(filePath) {",
        "6cebbd7604f63844a220bedc6719c112817f62de7a9e0ba85a36b6c8b173000f",
        NATIVE_GATEWAY_TRANSPORT)
    transport = region(transport, "/**\n * Shared HTTP transport policy", "// Transient transport errors:",
        "794f5fac4ca9757ba6a4452c5e630d84c87332659395b5a69f9e033bdb2f4d65",
        """/**
 * Shared retry and HTTP error policy for Chromium-backed Hermes REST helpers.
 * Electron owns connection reuse; JSON and download requests use separate
 * session partitions in main.ts. This module stays independent of Electron.
 *
 * Retry only GET/HEAD/OPTIONS on transient transport failures. Other verbs may
 * retry only connection-establishment failures or failures before bodySent.
 * A reset after submission is ambiguous: never double-submit a mutation.
 */

""")
    tests = replace(tests, "import { afterAll, describe, expect, it } from 'vitest'",
                    "import { describe, expect, it } from 'vitest'")
    for name in ("destroyKeepaliveAgents", "jsonAgentFor"):
        tests = replace(tests, f"  {name},\n", "")
    tests = replace(tests, "afterAll(() => {\n  destroyKeepaliveAgents()\n})\n\n", "")
    tests = replace(tests, "agent: jsonAgentFor('http:')", "agent: false", count=2)
    tests = replace(tests, " * Unit + live-transport tests for the Electron main process's Hermes REST",
                    " * Unit + independent Node-server tests for the Hermes REST")
    tests = replace(tests, "// LIVE transport tests against real misbehaving HTTP servers.",
                    "// Retry-policy tests against real HTTP servers, independent of Electron's transport.")
    tests = replace(tests, "/** Minimal single-attempt GET mirroring the pre-PR fetchJson (no retry). */",
                    "/** Independent Node GET to exercise the shared retry policy (no connection pool). */")
    tests = replace(tests,
        " * The live tests run REAL node http servers that misbehave the way the\n"
        " * reported backend does (closing sockets under burst keep-alive traffic) and\n"
        " * prove two things end to end:",
        " * The live tests run real Node HTTP servers that reset independent\n"
        " * requests. They exercise shared retry policy, not Electron connection\n"
        " * pooling or certificate verification, and prove two behaviors:")
    tests = replace(tests,
        "describe('live: GET burst against a server that resets keep-alive sockets',",
        "describe('live: GET burst against a server that resets requests',")
    stream = replace(stream,
        "// main-process singletons (https/http, electronNet, the OAuth session). They",
        "// main-process singletons (electronNet and the OAuth session). They")
    # Electron requires end/error listeners before data starts flowing. Preserve
    # the existing failure-atomic pump and its backpressure, only reorder wiring.
    stream = replace(stream,
        "    res.on('data', chunk => {",
        "    res.on('end', () => {\n"
        "      if (failed) {\n        return\n      }\n\n      finish()\n    })\n\n"
        "    res.on('data', chunk => {")
    stream = replace(stream,
        "\n    res.on('end', () => {\n      if (failed) {\n        return\n      }\n\n      finish()\n    })\n  })",
        "\n  })")
    source = replace(source,
        "  const disposition = headers['content-disposition'] || headers['Content-Disposition']",
        "  if (statusCode >= 300) {\n"
        "    ctx.abort?.()\n"
        "    throw htmlResponseError(ctx.url, statusCode, headers.location)\n"
        "  }\n\n"
        "  const disposition = headers['content-disposition'] || headers['Content-Disposition']")
    source = replace(source,
        "  try {\n    // Failure-atomic: exclusive temp create beside the destination, rename into",
        "  if (res.destroyed) {\n"
        "    throw ctx.responseError?.() || new Error('Gateway download response closed before it could be saved')\n"
        "  }\n\n"
        "  try {\n    // Failure-atomic: exclusive temp create beside the destination, rename into")
    source = replace(source,
        "    let total = 0\n\n    res.on('data', chunk => {",
        "    let total = 0\n\n"
        "    res.on('end', () => resolve(Buffer.concat(chunks).toString('utf8').slice(0, 500)))\n"
        "    res.on('error', () => resolve(Buffer.concat(chunks).toString('utf8').slice(0, 500)))\n\n"
        "    res.on('data', chunk => {")
    source = replace(source,
        "    })\n    res.on('end', () => resolve(Buffer.concat(chunks).toString('utf8').slice(0, 500)))\n"
        "    res.on('error', () => resolve(Buffer.concat(chunks).toString('utf8').slice(0, 500)))\n",
        "    })\n")
    return source, [(transport_path, transport), (tests_path, tests), (stream_path, stream)]


NATIVE_GATEWAY_TRANSPORT = r'''// Chromium supplies modern PKI verification and owns connection reuse. These
// cookieless partitions are separate from OAuth and from each other so file
// streams do not share the interactive JSON network context. No TLS hooks.
const gatewayRequests = new Set<Electron.ClientRequest>()
const gatewayRestrictedHeaders = new Set([
  'content-length', 'host', 'trailer', 'te', 'upgrade', 'cookie2',
  'keep-alive', 'transfer-encoding', 'cookie'
])

function abortGatewayRequests() {
  for (const request of gatewayRequests) {
    request.abort()
  }
  gatewayRequests.clear()
}

function gatewayNetError(error: any) {
  // Normalize only Chromium equivalents of the EXISTING retry codes. TLS,
  // HTTP and redirect failures are not transient and must never be retried.
  const codes = {
    ERR_CONNECTION_RESET: 'ECONNRESET',
    ERR_CONNECTION_CLOSED: 'ECONNRESET',
    ERR_EMPTY_RESPONSE: 'ECONNRESET',
    ERR_CONNECTION_REFUSED: 'ECONNREFUSED',
    ERR_CONNECTION_TIMED_OUT: 'ETIMEDOUT',
    ERR_TIMED_OUT: 'ETIMEDOUT',
    ERR_NAME_NOT_RESOLVED: 'ENOTFOUND',
    ERR_ADDRESS_UNREACHABLE: 'EHOSTUNREACH'
  }
  const nativeCode = String(error?.message || '').match(/\bnet::(ERR_[A-Z_]+)\b/)?.[1]
  if (nativeCode && codes[nativeCode] && !error.code) {
    error.code = codes[nativeCode]
  }
  return error
}

function createGatewayRequest(url, method, headers, download = false) {
  const request = electronNet.request({
    url,
    method,
    partition: download ? 'hermes-gateway-downloads' : 'hermes-gateway-json',
    credentials: 'omit',
    redirect: 'manual',
    bypassCustomProtocolHandlers: true
  })
  try {
    for (const [name, value] of Object.entries(headers)) {
      const lower = name.toLowerCase()
      // Chromium generates framing/authority headers. Never feed its forbidden
      // headers or a cookie override from stored extra headers to net.request.
      if (gatewayRestrictedHeaders.has(lower) ||
          (lower === 'connection' && String(value).toLowerCase() === 'upgrade') ||
          value == null) {
        continue
      }
      request.setHeader(name, String(value))
    }
  } catch (error) {
    request.abort()
    throw error
  }
  gatewayRequests.add(request)
  // ClientRequest is a Writable: its own close can precede the response in
  // Electron 40. Track the network transaction, not the upload stream lifetime.
  const untrack = () => gatewayRequests.delete(request)
  request.once('error', untrack)
  request.once('abort', untrack)
  request.once('response', response => {
    response.once('end', untrack)
    response.once('error', untrack)
    response.once('aborted', untrack)
  })
  return request
}

function gatewayJsonAttempt(url, headers, body, options, requestState) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url)
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      reject(new Error(`Unsupported Hermes backend URL protocol: ${parsed.protocol}`))
      return
    }
    const timeoutMs = resolveTimeoutMs(options.timeoutMs, DEFAULT_FETCH_TIMEOUT_MS)
    const request = createGatewayRequest(url, options.method || 'GET', headers)
    let settled = false
    let timer: ReturnType<typeof setTimeout>
    const fail = error => {
      if (settled) return
      settled = true
      clearTimeout(timer)
      gatewayRequests.delete(request)
      reject(gatewayNetError(error))
      request.abort()
    }
    // Retain JSON's inactivity timeout through the response body, unlike the
    // download connect-only timer. Clear it on every terminal path.
    const resetTimer = () => {
      clearTimeout(timer)
      timer = setTimeout(() => fail(new Error(`Timed out connecting to Hermes backend after ${timeoutMs}ms`)), timeoutMs)
    }
    resetTimer()
    request.once('redirect', (status, _method, target) => fail(htmlResponseError(url, status, target)))
    request.once('error', fail)
    request.once('abort', () => fail(new Error('Hermes backend request aborted')))
    request.once('response', res => {
      if (settled) return
      resetTimer()
      const chunks: Buffer[] = []
      res.once('error', fail)
      res.once('aborted', () => fail(new Error('Hermes backend response aborted')))
      res.once('end', () => {
        if (settled) return
        const text = Buffer.concat(chunks).toString('utf8')
        if ((res.statusCode || 500) >= 400) {
          fail(httpStatusError(res.statusCode, text, res.statusMessage))
          return
        }
        if (res.statusCode >= 300) {
          fail(htmlResponseError(url, res.statusCode, res.headers.location))
          return
        }
        if (!text) {
          settled = true
          clearTimeout(timer)
          resolve(null)
          return
        }
        if (/^\s*<(?:!doctype|html)/i.test(text) || String(res.headers['content-type'] || '').includes('text/html')) {
          fail(htmlResponseError(url, res.statusCode))
          return
        }
        let result = null
        try {
          result = text ? JSON.parse(text) : null
        } catch {
          fail(new Error(`Invalid JSON from ${url} (status ${res.statusCode}): ${text.slice(0, 200)}`))
          return
        }
        settled = true
        clearTimeout(timer)
        resolve(result)
      })
      res.on('data', chunk => {
        if (!settled) {
          resetTimer()
          chunks.push(chunk)
        }
      })
    })
    // First write/end may send headers. Mark BEFORE either; ambiguous mutation
    // failures must not replay, exactly as the original retry policy requires.
    requestState.bodySent = true
    try {
      if (body) request.write(body)
      request.end()
    } catch (error) {
      fail(error)
    }
  })
}

function fetchJson(url, token, options: any = {}) {
  return withRetry(requestState => {
    const { body, contentType } = options.upload ? multipartBody(options.upload) : {
      body: options.body === undefined ? undefined : Buffer.from(JSON.stringify(options.body)),
      contentType: 'application/json'
    }
    return gatewayJsonAttempt(url, {
      ...headersForRemoteRequest(url),
      ...(options.headers || {}),
      'Content-Type': contentType,
      'X-Hermes-Session-Token': token,
      ...(options.bearer ? { Authorization: `Bearer ${options.bearer}` } : {})
    }, body, options, requestState)
  }, { method: options.method || 'GET' })
}

// Keep downloads streaming and single-attempt. Headers end the connect timer;
// the save dialog and backpressured file pump have no request timeout.
function downloadViaTokenToFile(url, token, ctx, options: any = {}) {
  return new Promise((resolve, reject) => {
    let parsed
    try {
      parsed = new URL(url)
    } catch (error) {
      reject(new Error(`Invalid URL: ${error.message}`))
      return
    }
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      reject(new Error(`Unsupported Hermes backend URL protocol: ${parsed.protocol}`))
      return
    }
    const timeoutMs = resolveTimeoutMs(options.timeoutMs, DEFAULT_FETCH_TIMEOUT_MS)
    const request = createGatewayRequest(url, 'GET', options.bearer
      ? { Authorization: `Bearer ${options.bearer}` } : { 'X-Hermes-Session-Token': token }, true)
    let settled = false
    let hasResponse = false
    let localAbort = false
    let response
    let responseError
    const fail = error => {
      if (settled) return
      settled = true
      clearTimeout(timer)
      gatewayRequests.delete(request)
      reject(error)
      request.abort()
    }
    const timer = setTimeout(() => fail(new Error(`Timed out connecting to Hermes backend after ${timeoutMs}ms`)), timeoutMs)
    request.once('redirect', (status, _method, target) => fail(htmlResponseError(url, status, target)))
    request.once('error', error => {
      if (localAbort) return
      if (response) response.destroy(error)
      else fail(error)
    })
    request.once('abort', () => {
      clearTimeout(timer)
      if (!hasResponse) fail(new Error('Hermes backend request aborted'))
      else if (!localAbort && !settled) response.destroy(new Error('Gateway download response aborted'))
    })
    request.once('response', res => {
      if (settled) return
      hasResponse = true
      response = res
      clearTimeout(timer)
      res.once('error', error => { responseError = error })
      res.once('aborted', () => {
        if (!settled && !localAbort) res.destroy(new Error('Gateway download response aborted'))
      })
      finalizeGatewayDownload(res, res.statusCode || 500, res.headers || {}, {
        ...ctx, url, responseError: () => responseError,
        abort: () => {
          localAbort = true
          request.abort()
        }
      }).then(result => {
        if (!settled) {
          settled = true
          resolve(result)
        }
      }, fail)
    })
    try {
      request.end()
    } catch (error) {
      fail(error)
    }
  })
}

function fetchPublicJson(url, options: any = {}) {
  // Public probes never send a session token, bearer or session cookies.
  return withRetry(requestState => gatewayJsonAttempt(url, {
    ...headersForRemoteRequest(url),
    ...(options.headers || {}),
    'Content-Type': 'application/json'
  }, options.body === undefined ? undefined : Buffer.from(JSON.stringify(options.body)),
  options, requestState), { method: options.method || 'GET' })
}

'''


def patch_gateway_websocket(source):
    """Native renderer WS cutover, checked against pinned source before writes."""
    def replace(old, new, count=1):
        nonlocal source
        found = source.count(old)
        if found != count:
            raise ValueError(f"Pinned WS anchor changed: expected {count}, found {found}: {old!r}")
        source = source.replace(old, new)

    replace(
        "import { probeGatewayWebSocket, spawnedBackendProbeOptions } from './gateway-ws-probe'",
        "import { probeGatewayWebSocket as probeChromiumGatewayWebSocket, spawnedBackendProbeOptions } from './gateway-ws-probe'",
    )
    # app.getAppPath() is wrong for Guix's source-build launcher. APP_ROOT already
    # names the installed immutable app root; the inert page has file Origin null
    # exactly like the packaged chat renderer. Native module supplies no preload.
    replace(
        "function headersForRemoteRequest(requestUrl) {",
        "function probeGatewayWebSocket(wsUrl: string, options: {\n"
        "  headers?: Record<string, string>; connectTimeoutMs?: number; readyGraceMs?: number;\n"
        "  progressCheckIntervalMs?: number; maxConnectWaitMs?: number; keepWaitingWhile?: () => boolean\n"
        "} = {}) {\n"
        "  return probeChromiumGatewayWebSocket(wsUrl, {\n"
        "    ...options,\n"
        "    probePageUrl: pathToFileURL(path.join(APP_ROOT, 'public', 'hermes-ws-probe.html')).href,\n"
        "    headers: options.headers ?? headersForRemoteRequest(wsUrl)\n"
        "  })\n"
        "}\n\n"
        "function headersForRemoteRequest(requestUrl) {",
    )
    replace("if (wsUrl && typeof globalThis.WebSocket === 'function') {", "if (wsUrl) {", 2)
    replace(
        "probeGatewayWebSocket(wsUrl, { WebSocketImpl: globalThis.WebSocket, headers: testHeaders })",
        "probeGatewayWebSocket(wsUrl, { headers: testHeaders })", 2,
    )
    replace(
        "probeWebSocket: (wsUrl: string) => probeGatewayWebSocket(wsUrl, { WebSocketImpl: globalThis.WebSocket }),",
        "probeWebSocket: (wsUrl: string) => probeGatewayWebSocket(wsUrl),",
    )
    replace(
        "  const wsProbe = await probeGatewayWebSocket(wsUrl, {\n    WebSocketImpl: globalThis.WebSocket,\n",
        "  const wsProbe = await probeGatewayWebSocket(wsUrl, {\n",
    )
    replace(
        "    const wsProbe = await probeGatewayWebSocket(wsUrl, {\n      WebSocketImpl: globalThis.WebSocket,\n",
        "    const wsProbe = await probeGatewayWebSocket(wsUrl, {\n",
    )
    return source


def patch(source_root, backend_store, desktop_store):
    main = source_root / "apps/desktop/electron/main.ts"
    source = main.read_text(encoding="utf-8")
    app_root = desktop_store / "share/hermes-desktop"

    def replace(old, new, count=1):
        nonlocal source
        found = source.count(old)
        if found != count:
            raise ValueError(
                f"Pinned main.ts anchor changed: expected {count}, found {found}: {old!r}"
            )
        source = source.replace(old, new)

    def prepend(opener, body):
        replace(opener, opener + "\n" + body + "\n")

    replace(
        "const DEV_SERVER = process.env.HERMES_DESKTOP_DEV_SERVER\n"
        "const IS_PACKAGED = app.isPackaged || Boolean(process.env.HERMES_DESKTOP_IS_PACKAGED)",
        "// Guix source constants refer to this output, never a mutable profile.\n"
        "const GUIX_MANAGED = process.env.HERMES_DESKTOP_MANAGED === 'guix'\n"
        f"const GUIX_BACKEND_ROOT = {json.dumps(str(backend_store))}\n"
        f"const GUIX_HERMES_COMMAND = {json.dumps(str(backend_store / 'bin/hermes'))}\n"
        f"const GUIX_DESKTOP_ROOT = {json.dumps(str(app_root))}\n"
        f"const GUIX_RESOURCES_PATH = {json.dumps(str(app_root / 'resources'))}\n"
        f"const GUIX_SOURCE_COMMIT = {json.dumps(PINNED_COMMIT)}\n"
        "const GUIX_UPGRADE_COMMAND = 'guix upgrade hermes-desktop'\n"
        "const GUIX_REPAIR_MESSAGE = 'Hermes Desktop is managed by Guix. ' +\n"
        "  'It cannot reinstall or repair package files inside the app. ' +\n"
        "  'Run ' + GUIX_UPGRADE_COMMAND + ' in a terminal, then restart Hermes Desktop.'\n"
        "const DEV_SERVER = GUIX_MANAGED ? undefined : process.env.HERMES_DESKTOP_DEV_SERVER\n"
        "const IS_PACKAGED = true",
    )
    replace("const APP_ROOT = app.getAppPath()", "const APP_ROOT = GUIX_DESKTOP_ROOT")
    replace(
        "process.resourcesPath ? path.join(process.resourcesPath, 'install-stamp.json') : null,",
        "path.join(GUIX_RESOURCES_PATH, 'install-stamp.json'),",
    )
    replace("resourcesPath: process.resourcesPath,", "resourcesPath: GUIX_RESOURCES_PATH,")
    prepend(
        "function resolveWebDist() {",
        "  if (GUIX_MANAGED) {\n"
        "    return path.join(GUIX_DESKTOP_ROOT, 'dist')\n"
        "  }",
    )
    prepend(
        "async function resolveHermesBackend(backendArgs) {",
        "  // Deployment overrides precede ALL checkout, active-runtime and PATH discovery.\n"
        "  // A missing/broken explicit command must fail at spawn, never run an installer.\n"
        "  const explicitCommand = GUIX_MANAGED ? GUIX_HERMES_COMMAND :\n"
        "    process.env.HERMES_DESKTOP_HERMES\n"
        "\n"
        "  if (explicitCommand) {\n"
        "    return {\n"
        "      label: `Hermes CLI at ${explicitCommand}`,\n"
        "      command: explicitCommand,\n"
        "      args: backendArgs,\n"
        "      bootstrap: false,\n"
        "      env: {},\n"
        "      kind: 'command',\n"
        "      shell: isCommandScript(explicitCommand)\n"
        "    }\n"
        "  }",
    )
    # The old override branch is now unreachable: keep only discovered PATH probes.
    replace(
        "    let hermesCommand = null\n"
        "    const hermesOverride = process.env.HERMES_DESKTOP_HERMES\n"
        "\n"
        "    if (hermesOverride) {\n"
        "      const resolvedOverride = findOnPath(hermesOverride)\n"
        "\n"
        "      if (resolvedOverride) {\n"
        "        hermesCommand = resolvedOverride\n"
        "      } else if (!isWindowsBinaryPathInWsl(hermesOverride, { isWsl: IS_WSL })) {\n"
        "        hermesCommand = hermesOverride\n"
        "      } else {\n"
        "        rememberLog(`Ignoring Windows Hermes override under WSL: ${hermesOverride}`)\n"
        "      }\n"
        "    } else {\n"
        "      hermesCommand = findOnPath('hermes')\n"
        "    }",
        "    let hermesCommand = findOnPath('hermes')",
    )
    replace(
        "      // HERMES_DESKTOP_HERMES is an explicit deployment override (used by\n"
        "      // the Nix wrapper), not a discovered PATH candidate. It must not fall\n"
        "      // through to the install-script bootstrap if the optional probe times\n"
        "      // out under load; the pinned backend is the only valid runtime there.\n"
        "      if (\n"
        "        shouldTrustHermesOverride(hermesOverride) ||\n"
        "        (await verifyHermesCli(hermesCommand, { shell: shellForProbe }))\n"
        "      ) {",
        "      if (await verifyHermesCli(hermesCommand, { shell: shellForProbe })) {",
    )
    replace(
        "import { canImportHermesCli, PROBE_TIMEOUT_MS, shouldTrustHermesOverride, verifyHermesCli } from './backend-probes'",
        "import { canImportHermesCli, PROBE_TIMEOUT_MS, verifyHermesCli } from './backend-probes'",
    )
    # Host attach authenticates a server, not its executable/version provenance.
    # Isolate just the process; preserve HERMES_HOME, profiles and remote routing.
    replace(
        "const ISOLATED_BACKEND = process.env.HERMES_DESKTOP_ISOLATED_BACKEND === '1'",
        "const ISOLATED_BACKEND = GUIX_MANAGED || process.env.HERMES_DESKTOP_ISOLATED_BACKEND === '1'",
    )
    replace(
        "  if (!backend.bootstrap) {\n"
        "    await advanceBootProgress('runtime.external', `Using ${backend.label}`, 32)",
        "  if (GUIX_MANAGED && backend.bootstrap) {\n"
        "    throw new Error(GUIX_REPAIR_MESSAGE)\n"
        "  }\n"
        "\n"
        "  if (!backend.bootstrap) {\n"
        "    await advanceBootProgress('runtime.external', `Using ${backend.label}`, 32)",
    )
    prepend(
        "async function handOffWindowsBootstrapRecovery(reason) {",
        "  if (GUIX_MANAGED) {\n"
        "    throw new Error(GUIX_REPAIR_MESSAGE)\n"
        "  }",
    )
    prepend(
        "async function waitForUpdateToFinish() {",
        "  // An old mutable checkout's updater marker does not own this store runtime.\n"
        "  if (GUIX_MANAGED) {\n"
        "    return false\n"
        "  }",
    )
    prepend(
        "function resolveUpdateRoot() {",
        "  if (GUIX_MANAGED) {\n"
        "    return GUIX_BACKEND_ROOT\n"
        "  }",
    )
    prepend(
        "async function checkUpdates({ force = false }: { force?: boolean } = {}) {",
        "  if (GUIX_MANAGED) {\n"
        "    // The store has no .git directory. Compare the actual packaged revision\n"
        "    // with upstream using the same SHA/ancestry API and cache as upstream.\n"
        "    const branch = readDesktopUpdateConfig().branch\n"
        "    const currentSha = GUIX_SOURCE_COMMIT\n"
        "    const now = Date.now()\n"
        "    const cached = readUpdateCheckCache()\n"
        "\n"
        "    if (!force && cacheIsFresh(cached, { branch, currentSha, now })) {\n"
        "      return {\n"
        "        ...cached.status, dirty: false, currentBranch: branch,\n"
        "        hermesRoot: GUIX_BACKEND_ROOT, manual: true, command: GUIX_UPGRADE_COMMAND\n"
        "      }\n"
        "    }\n"
        "\n"
        "    const status = await checkUpdatesViaApi({\n"
        "      slug: githubRepoSlug(OFFICIAL_REPO_HTTPS_URL),\n"
        "      branch, currentSha, updateRoot: null\n"
        "    })\n"
        "    const result = {\n"
        "      supported: true, branch, currentBranch: branch, currentSha, dirty: false,\n"
        "      hermesRoot: GUIX_BACKEND_ROOT, fetchedAt: now,\n"
        "      manual: true, command: GUIX_UPGRADE_COMMAND, ...status\n"
        "    }\n"
        "\n"
        "    writeUpdateCheckCache({ fetchedAt: now, currentSha, branch, status: result })\n"
        "    return result\n"
        "  }",
    )
    manual_update = (
        "  if (GUIX_MANAGED) {\n"
        "    emitUpdateProgress({ stage: 'manual', message: GUIX_UPGRADE_COMMAND, percent: null })\n"
        "    return {\n"
        "      ok: true, manual: true, command: GUIX_UPGRADE_COMMAND,\n"
        "      message: GUIX_UPGRADE_COMMAND, hermesRoot: GUIX_BACKEND_ROOT\n"
        "    }\n"
        "  }"
    )
    prepend("async function applyUpdates(opts: { stopSafeBlockers?: boolean } = {}) {", manual_update)
    prepend("async function applyUpdatesPosixHandoff(opts: any) {", manual_update)
    prepend(
        "ipcMain.handle('hermes:bootstrap:repair', async () => {",
        "  if (GUIX_MANAGED) {\n"
        "    // The renderer currently ignores this IPC's result. A native dialog\n"
        "    // ensures the instruction is visible without pretending repair ran.\n"
        "    await dialog.showMessageBox({\n"
        "      type: 'info', title: 'Package-managed Hermes Desktop',\n"
        "      message: 'Repair Hermes Desktop with Guix', detail: GUIX_REPAIR_MESSAGE,\n"
        "      buttons: ['Close'], noLink: true\n"
        "    })\n"
        "    return {\n"
        "      ok: false, manual: true, error: 'package-managed',\n"
        "      command: GUIX_UPGRADE_COMMAND, message: GUIX_REPAIR_MESSAGE\n"
        "    }\n"
        "  }",
    )
    replace(
        "repairHint: 'hermes desktop --force-build',",
        "repairHint: GUIX_MANAGED ? GUIX_UPGRADE_COMMAND : 'hermes desktop --force-build',",
        count=2,
    )
    replace(
        "`Repair with: hermes desktop --force-build`",
        "`Repair with: ${GUIX_MANAGED ? GUIX_UPGRADE_COMMAND : 'hermes desktop --force-build'}`",
    )
    replace(
        "`Rebuild with: hermes desktop --force-build`",
        "`Rebuild with: ${GUIX_MANAGED ? GUIX_UPGRADE_COMMAND : 'hermes desktop --force-build'}`",
    )
    source, gateway_files = patch_gateway_transport(source_root, source)
    source = patch_gateway_websocket(source)
    # Prepare every affected source before writing any file: drift never leaves
    # only one side of the native transport cutover patched.
    for patched_path, patched_source in gateway_files:
        patched_path.write_text(patched_source, encoding="utf-8")
    main.write_text(source, encoding="utf-8")


def main():
    if len(sys.argv) != 4:
        raise SystemExit(
            "usage: hermes-desktop-store.py SOURCE_ROOT BACKEND_STORE_ROOT DESKTOP_STORE_ROOT"
        )
    roots = [Path(argument) for argument in sys.argv[1:]]
    if not all(root.is_absolute() for root in roots):
        raise SystemExit("all three roots must be absolute paths")
    patch(*roots)


if __name__ == "__main__":
    main()
