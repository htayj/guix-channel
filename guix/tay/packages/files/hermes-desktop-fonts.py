#!/usr/bin/env python3
"""Replace Hermes Desktop's restricted UI fonts after npm ci, before Vite.

Usage: hermes-desktop-fonts.py ROOT FONT_IBM_PLEX FONT_UNIFONT FONT_JETBRAINS_MONO
                             [NOTICES_DIR]
ROOT is the Hermes repository root. Font arguments are Guix package outputs:
font-ibm-plex:out (OpenType), font-gnu-unifont:out, font-jetbrains-mono:out (for
license retention only). Notices default to ROOT/apps/desktop/build/free-fonts-notices;
install this directory with the app.

Only font source URLs/formats change: CSS family aliases, weights, styles and
custom properties stay intact.  Font bytes and their internal names are copied
unchanged.  The npm UI origin must already have removed its restricted fonts;
this helper also removes any remaining bundled font files throughout the module.
"""

import argparse
import os
from pathlib import Path
import re
import shutil


# Cover all fourteen assets in @nous-research/ui 0.18.2, including faces not
# registered in fonts.css.  RulesCompressed-Medium is declared as CSS weight
# 600 upstream, so use Plex SemiBold rather than its 500-weight Medium face.
PLEX_FACES = {
    "Collapse-Regular": "IBMPlexSans-Regular.otf",
    "Collapse-Bold": "IBMPlexSans-Bold.otf",
    "Collapse-Italic": "IBMPlexSans-Italic.otf",
    "Collapse-BoldItalic": "IBMPlexSans-BoldItalic.otf",
    "Collapse-Light": "IBMPlexSans-Light.otf",
    "Collapse-LightItalic": "IBMPlexSans-LightItalic.otf",
    "Collapse-Thin": "IBMPlexSans-Thin.otf",
    "Collapse-ThinItalic": "IBMPlexSans-ThinItalic.otf",
    "RulesCompressed-Regular": "IBMPlexSansCondensed-Regular.otf",
    "RulesCompressed-Medium": "IBMPlexSansCondensed-SemiBold.otf",
    "RulesExpanded-Regular": "IBMPlexSans-Regular.otf",
    "RulesExpanded-Bold": "IBMPlexSans-Bold.otf",
}
PIXEL_FACES = ("Mondwest-Regular", "Neuebit-Bold")
FONT_SUFFIXES = {".ttf", ".otf", ".ttc", ".otc", ".woff", ".woff2", ".eot"}
FONT_SOURCE = re.compile(
    r"url\(\s*(['\"])(?P<url>[^'\"]+)\1\s*\)"
    r"\s*format\(\s*(['\"])[^'\"]+\3\s*\)"
)


def ui_module(root):
    """Find npm's workspace-local or hoisted UI dependency."""
    for directory in (root / "apps/desktop", root / "apps", root):
        candidate = directory / "node_modules/@nous-research/ui"
        if candidate.is_dir():
            return candidate
    raise FileNotFoundError("@nous-research/ui is missing; run npm ci first")


def font_notices(package, name):
    """Guix installs original license files under share/doc/NAME-VERSION."""
    directories = sorted((package / "share/doc").glob(name + "*"))
    if not directories or not any(path.is_file() for directory in directories
                                  for path in directory.rglob("*")):
        raise FileNotFoundError(f"No installed licensing documents in {package}")
    return directories


def rewrite_css(path, replacements, font_directory=None):
    """Keep the face declaration; replace its URL and real format only."""
    text = path.read_text(encoding="utf-8")

    def replace(match):
        old = Path(match.group("url"))
        filename = replacements.get(old.stem)
        if filename is None:
            return match.group(0)
        if font_directory is None:
            url = (old.parent / filename).as_posix()
        else:
            url = Path(os.path.relpath(font_directory / filename,
                                      path.parent)).as_posix()
        return f"url('{url}') format('opentype')"

    updated = FONT_SOURCE.sub(replace, text)
    if updated != text:
        path.write_text(updated, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("font_ibm_plex", type=Path)
    parser.add_argument("font_unifont", type=Path)
    parser.add_argument("font_jetbrains_mono", type=Path)
    parser.add_argument("notices_dir", type=Path, nargs="?")
    args = parser.parse_args()
    root = args.root.resolve()
    module = ui_module(root)
    notices = args.notices_dir or root / "apps/desktop/build/free-fonts-notices"

    # These are the actual flattened font-build-system and Unifont install
    # layouts.  Do not rename an OTF to WOFF or alter reserved internal names.
    plex = args.font_ibm_plex / "share/fonts/opentype"
    unifont = args.font_unifont / "share/fonts/opentype/unifont.otf"
    replacements = dict(PLEX_FACES)
    replacements.update({face: unifont.name for face in PIXEL_FACES})
    sources = {filename: plex / filename for filename in set(PLEX_FACES.values())}
    sources[unifont.name] = unifont
    for source in sources.values():
        if not source.is_file():
            raise FileNotFoundError(f"Missing Guix OpenType font: {source}")
    documents = {
        "font-ibm-plex": font_notices(args.font_ibm_plex, "font-ibm-plex"),
        "font-gnu-unifont": font_notices(args.font_unifont, "font-gnu-unifont"),
        "font-jetbrains-mono": font_notices(args.font_jetbrains_mono,
                                           "font-jetbrains-mono"),
    }
    # Required CSS is retained by the sanitized npm origin.  Resolve all
    # prerequisites before changing installed dependencies.
    for relative in ("src/ui/fonts.css", "dist/ui/fonts.css"):
        if not (module / relative).is_file():
            raise FileNotFoundError(f"Missing pinned UI stylesheet: {relative}")
    desktop_css = root / "apps/desktop/src/styles.css"
    if not desktop_css.is_file():
        raise FileNotFoundError(f"Missing desktop stylesheet: {desktop_css}")

    for path in module.rglob("*"):
        if path.is_file() and path.suffix.lower() in FONT_SUFFIXES:
            path.unlink()
    for relative in ("src/fonts", "dist/fonts"):
        destination = module / relative
        destination.mkdir(parents=True, exist_ok=True)
        for filename, source in sorted(sources.items()):
            shutil.copyfile(source, destination / filename)
    for path in sorted(module.rglob("*.css")):
        rewrite_css(path, replacements)
    # The wordmark has a separate direct font URL.  Calculate it from the
    # actual dependency location, so nested and hoisted installs both work.
    rewrite_css(desktop_css, replacements, module / "dist/fonts")

    notices.mkdir(parents=True, exist_ok=True)
    for name, directories in documents.items():
        for directory in directories:
            shutil.copytree(directory, notices / name / directory.name,
                            dirs_exist_ok=True)
    substitution_notice = (
        "Hermes Desktop free-font substitutions\n"
        "\nFonts are copied unchanged from Guix font-ibm-plex (SIL OFL 1.1)\n"
        "and font-gnu-unifont (dual SIL OFL 1.1 / GPL-2.0-or-later with the\n"
        "GNU font embedding exception). Original licenses accompany this file.\n"
        "Only CSS font-source URLs and formats are changed; CSS role aliases\n"
        "are retained. No font internal names or font bytes are modified.\n"
        "Unifont has one regular face: the unused Neuebit-Bold asset role maps\n"
        "to that pixel face, not an invented Unifont bold face. JetBrains Mono\n"
        "terminal faces remain unchanged; their SIL OFL 1.1 is retained from\n"
        "Guix font-jetbrains-mono. The Guix package version is not a claim\n"
        "about the version of Hermes's bundled WOFF2 files. All non-font\n"
        "styling remains unchanged.\n\n"
        + "".join(f"{role} -> {filename}\n"
                  for role, filename in sorted(replacements.items()))
    )
    (notices / "SUBSTITUTIONS.txt").write_text(substitution_notice, encoding="utf-8")
    # Keep notices with the source fonts as well as in the installable output.
    shutil.copytree(notices, module / "FONT-LICENSES", dirs_exist_ok=True)
    print(f"Installed unchanged free OpenType fonts; notices: {notices}")


if __name__ == "__main__":
    main()
