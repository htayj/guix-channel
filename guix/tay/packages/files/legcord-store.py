#!/usr/bin/env python3
"""Apply the documented Guix-managed application-update policy to pinned source.

Runtime mod downloads and userData paths deliberately remain upstream behavior.
"""

import json
import pathlib
import sys

GUIDANCE = "This Legcord installation is managed by Guix. Run guix pull, then guix upgrade legcord."


def replace(root, relative, before, after):
    path = root / relative
    text = path.read_text()
    if text.count(before) != 1:
        raise RuntimeError(f"Pinned source contract changed: {relative}: {before!r}")
    path.write_text(text.replace(before, after))


def prepare(root):
    # Sandboxed Electron preloads use CommonJS, not the upstream ESM output.
    # Keep the same contextBridge/IPC implementation while migrating both ends.
    replace(root, "src/splash/main.ts", "            sandbox: false,", "            sandbox: true,")
    replace(root, "src/splash/main.ts", '"splash", "preload.mjs"', '"splash", "preload.cjs"')
    replace(
        root,
        "rolldown.config.ts",
        '            dir: "ts-out/splash",\n'
        '            format: "esm",\n'
        '            entryFileNames: "[name].mjs",',
        '            dir: "ts-out/splash",\n'
        '            format: "cjs",\n'
        '            entryFileNames: "[name].cjs",',
    )
    # rollup-plugin-copy flattens this glob, so each language's contribution
    # overwrites the others.  The recipe copies the complete AMD tree instead.
    replace(
        root,
        "rolldown.config.ts",
        '                    // Monaco AMD tree for the offline Quick CSS editor (next to editor.html)\n'
        '                    { src: "node_modules/monaco-editor/min/vs/**/*", dest: "ts-out/html/monaco/vs" },\n',
        "",
    )
    # The upstream require() dispatch is not suitable for an immutable ESM
    # application.  Keep the user's setting, but give visible package guidance
    # instead of attempting AppImage or dpkg installation.
    replace(
        root,
        "src/common/config.ts",
        '        require("../updater.js");',
        '        void app.whenReady().then(() => dialog.showMessageBox({\n'
        '            type: "info",\n'
        '            title: "Legcord updates are managed by Guix",\n'
        f'            message: "{GUIDANCE}",\n'
        '            detail: "Guix updates the immutable application and its runtime. '
        'Your settings and runtime mod cache remain in your user data directory.",\n'
        '        }));',
    )
    # The now-unreferenced AppImage/dpkg installer must not remain a second
    # update implementation in the retained, modified application source.
    (root / "src/updater.ts").unlink()
    manifest_path = root / "package.json"
    manifest = json.loads(manifest_path.read_text())
    del manifest["dependencies"]["electron-updater"]
    manifest_path.write_text(json.dumps(manifest, indent=4) + "\n")
    relative = "src/shelter/settings/components/HeroUpdater.tsx"
    replace(root, relative, 'const DOWNLOAD_URL = "https://legcord.app/download";',
            f'const GUIX_UPDATE_GUIDANCE = "{GUIDANCE}";')
    replace(root, relative,
            '    const handleDownload = () => {\n        window.open(DOWNLOAD_URL, "_blank");\n    };\n',
            '')
    replace(root, relative,
            '<Text>Check if a new version is available and download updates easily.</Text>',
            '<Text>{GUIX_UPDATE_GUIDANCE}</Text>')
    replace(root, relative,
            '                    <Button size={ButtonSizes.XLARGE} color={ButtonColors.RED} onClick={handleDownload}>\n'
            '                        Open Download Page\n'
            '                    </Button>',
            '                    <Text>Update the tay-channel package with Guix; '
            'do not replace files inside the immutable store.</Text>')
    replace(root, relative,
            'ui: { Button, ButtonSizes, Header, HeaderTags, Text, ButtonColors }',
            'ui: { Button, Header, HeaderTags, Text }')
    replace(root, "src/splash/splash.html",
            'text.innerHTML = await internal.getLang("loading_screen_update");',
            f'text.textContent = "{GUIDANCE}";')
    replace(root, "src/setup/setup.tsx",
            '        <Button\n            color={ButtonColors.PRIMARY}\n'
            '            size={ButtonSizes.LARGE}\n            onClick={onNext}',
            '        <p class="setup-note" id="guix-update-guidance">'
            f'{GUIDANCE}</p>\n        <Button\n            color={{ButtonColors.PRIMARY}}\n'
            '            size={ButtonSizes.LARGE}\n            onClick={onNext}')
    # Mark the derived work conspicuously while retaining upstream attribution,
    # source headers, and the complete OSL-3.0 text (OSL section 6).
    (root / "GUIX-MODIFICATIONS.txt").write_text(
        "Legcord 1.3.0, commit c8d91f61296019bb0c45f375535de8c93cf26ee1\n"
        "Modified for tay-channel GNU Guix packaging, 2026-10-03.\n"
        "These are Guix packaging modifications, not an upstream release.\n"
        "Application updates display Guix commands rather than installing an\n"
        "AppImage or Debian package. Runtime mods and userData remain upstream.\n"
        "Venmic is built from its C++ source rather than npm prebuilt binaries.\n"
        "The renderer, preload and main code are compiled from this source.\n"
        "The splash renderer is sandboxed; its unchanged IPC preload is emitted\n"
        "as CommonJS, which Electron supports inside sandboxed preloads.\n"
        "The offline Monaco editor retains its complete AMD directory tree;\n"
        "language module names no longer collide in a flattened copy.\n"
        "Lune sorts CSS module export keys before serializing plugin bundles\n"
        "and their hashes, avoiding randomized Rust HashMap iteration order.\n"
        "Electron is the approved pinned upstream executable, NOT source-built.\n"
        "The Node host tool and pinned npm native build bindings are also\n"
        "upstream binaries; this is not a fully source-built package.\n"
        "This directory retains the complete modified application source;\n"
        "the Guix recipe, fixed dependency sources and helper scripts are\n"
        "available in the tay-channel repository and its Guix store inputs.\n"
        "Legcord source is covered by the accompanying complete license.txt.\n"
    )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: legcord-store.py SOURCE_ROOT")
    prepare(pathlib.Path(sys.argv[1]))
