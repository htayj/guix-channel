#!/usr/bin/env python3
"""Patch the pinned Hermes Desktop source for an immutable Guix installation.

Invocation: hermes-desktop-store.py SOURCE_ROOT BACKEND_STORE_ROOT DESKTOP_STORE_ROOT
The desktop output contains share/hermes-desktop/{dist,resources,assets,public}.
Only apps/desktop/electron/main.ts is rewritten; upstream drift fails before writing.
"""

import json
import sys
from pathlib import Path


PINNED_COMMIT = "f97608f178d1ffeca59860195ab7da295f7c8e5f"


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
