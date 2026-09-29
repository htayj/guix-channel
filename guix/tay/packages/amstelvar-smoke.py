#!/usr/bin/env python3
"""Check the installed Amstelvar v1.001 variable fonts semantically.

The default invocation loads both installed font files with fontTools,
verifies their naming, style, and variation tables, confirms that every
declared axis changes real glyph outlines, and renders one line per style
through FreeType at the axis extremes.  ``--specimen PATH`` additionally
writes a PNG specimen of the installed fonts at several axis locations.
Nothing is written below HOME or the XDG directories.
"""

import argparse
from pathlib import Path
import stat
import sys

from fontTools.pens.recordingPen import RecordingPen
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont


MARKER = "amstelvar: font metadata smoke passed"

ROMAN_FILE = ("Amstelvar-Roman[GRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,"
              "YTUC,wdth,wght,opsz].ttf")
ITALIC_FILE = ("Amstelvar-Italic[GRAD,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,"
               "wdth,wght,opsz].ttf")

COMMON_TABLES = frozenset({
    "GDEF", "GPOS", "GSUB", "OS/2", "STAT", "avar", "cmap", "fvar", "glyf",
    "gvar", "head", "hhea", "hmtx", "loca", "maxp", "name", "post",
})

# Probe glyphs whose outlines each axis is designed to move.  Transparency
# axes are deliberately narrow: YTUC moves capitals, YTLC lowercase x-height
# glyphs, YTAS ascenders, YTDE descenders, and YTFI figures.
AXIS_PROBES = {
    "wght": ("H", "n", "o"),
    "wdth": ("H", "n", "o"),
    "opsz": ("H", "n", "o"),
    "GRAD": ("H", "n", "o"),
    "XTRA": ("H", "n", "o"),
    "XOPQ": ("H", "n", "o"),
    "YOPQ": ("H", "n", "o"),
    "YTLC": ("n", "o"),
    "YTUC": ("H",),
    "YTAS": ("d",),
    "YTDE": ("p",),
    "YTFI": ("one", "zero"),
}

STYLES = {
    "roman": {
        "file": ROMAN_FILE,
        "names": {
            1: "Amstelvar Roman",
            2: "Regular",
            4: "Amstelvar Roman",
            5: "Version 1.001",
            6: "Amstelvar-Roman",
        },
        "axes": (
            ("wght", 100.0, 400.0, 1000.0),
            ("wdth", 50.0, 100.0, 125.0),
            ("opsz", 8.0, 14.0, 144.0),
            ("GRAD", -300.0, 0.0, 500.0),
            ("XTRA", 324.0, 562.0, 640.0),
            ("XOPQ", 18.0, 176.0, 263.0),
            ("YOPQ", 15.0, 124.0, 132.0),
            ("YTLC", 420.0, 500.0, 570.0),
            ("YTUC", 500.0, 750.0, 1000.0),
            ("YTAS", 500.0, 767.0, 983.0),
            ("YTDE", -500.0, -240.0, -138.0),
            ("YTFI", 425.0, 760.0, 1000.0),
        ),
        "italic": False,
        "italic_angle": 0.0,
        "glyphs": 962,
        "specimen": "Amstelvar Roman 1.001",
    },
    "italic": {
        "file": ITALIC_FILE,
        "names": {
            1: "Amstelvar",
            2: "Italic",
            4: "Amstelvar Italic",
            5: "Version 1.001",
            6: "Amstelvar-Italic",
        },
        "axes": (
            ("wght", 100.0, 400.0, 900.0),
            ("wdth", 50.0, 100.0, 125.0),
            ("opsz", 8.0, 14.0, 144.0),
            ("GRAD", -300.0, 0.0, 500.0),
            ("YOPQ", 18.0, 54.0, 263.0),
            ("YTLC", 420.0, 500.0, 570.0),
            ("YTUC", 500.0, 750.0, 1000.0),
            ("YTAS", 500.0, 767.0, 983.0),
            ("YTDE", -500.0, -240.0, -138.0),
        ),
        "italic": True,
        "italic_angle": -11.0,
        "glyphs": 945,
        "specimen": "Amstelvar Italic 1.001",
    },
}


def fail(message):
    raise SystemExit(f"amstelvar-smoke: {message}")


def require(condition, message):
    if not condition:
        fail(message)


def check_file(path, immutable):
    info = path.lstat()
    require(stat.S_ISREG(info.st_mode), f"{path} is not a regular file")
    if immutable:
        require(info.st_mode & 0o222 == 0, f"{path} is writable")


def outline(glyph_set, name):
    pen = RecordingPen()
    glyph = glyph_set[name]
    glyph.draw(pen)
    return glyph.width, pen.value


def check_font(style, spec, font_dir, immutable):
    path = font_dir / spec["file"]
    check_file(path, immutable)
    font = TTFont(path)

    missing = COMMON_TABLES - set(font.keys())
    require(not missing, f"{style}: missing tables {sorted(missing)}")
    require(font["head"].unitsPerEm == 2000, f"{style}: unexpected unitsPerEm")

    name = font["name"]
    for name_id, expected in spec["names"].items():
        actual = name.getDebugName(name_id)
        require(actual == expected,
                f"{style}: name ID {name_id} is {actual!r}, not {expected!r}")
    for record in name.names:
        require((record.platformID, record.platEncID, record.langID)
                == (3, 1, 0x409),
                f"{style}: unexpected name record platform "
                f"{record.platformID}/{record.platEncID}/{record.langID:#x}")

    os2 = font["OS/2"]
    require(os2.fsType == 0, f"{style}: embedding is restricted")
    require(os2.achVendID == "FBI ", f"{style}: unexpected vendor ID")
    require(os2.usWeightClass == 400, f"{style}: default weight is not 400")
    require(os2.usWidthClass == 5, f"{style}: default width is not normal")
    fs_italic = bool(os2.fsSelection & 0x01)
    fs_regular = bool(os2.fsSelection & 0x40)
    mac_italic = bool(font["head"].macStyle & 0x02)
    italic_angle = font["post"].italicAngle
    require(fs_italic == spec["italic"], f"{style}: fsSelection italic bit")
    require(fs_regular != spec["italic"], f"{style}: fsSelection regular bit")
    require(mac_italic == spec["italic"], f"{style}: macStyle italic bit")
    require(italic_angle == spec["italic_angle"],
            f"{style}: italicAngle is {italic_angle}")

    fvar = font["fvar"]
    axes = tuple((axis.axisTag, axis.minValue, axis.defaultValue,
                  axis.maxValue) for axis in fvar.axes)
    require(axes == spec["axes"], f"{style}: fvar axes are {axes}")
    tags = [axis[0] for axis in axes]
    stat_tags = [record.AxisTag
                 for record in font["STAT"].table.DesignAxisRecord.Axis]
    require(stat_tags == tags, f"{style}: STAT axes are {stat_tags}")
    require(font["avar"].segments.keys() >= set(tags),
            f"{style}: avar does not map every fvar axis")

    require(len(font.getGlyphOrder()) == spec["glyphs"],
            f"{style}: glyph count is {len(font.getGlyphOrder())}")
    cmap = font.getBestCmap()
    for character, glyph in (("A", "A"), ("a", "a"), ("0", "zero"),
                             ("\u00e9", "eacute")):
        require(cmap.get(ord(character)) == glyph,
                f"{style}: {character!r} does not map to {glyph!r}")

    # gvar must make each axis change real outlines, not just be declared.
    for tag, minimum, _default, maximum in axes:
        probes = AXIS_PROBES[tag]
        low = font.getGlyphSet(location={tag: minimum})
        high = font.getGlyphSet(location={tag: maximum})
        require(any(outline(low, glyph) != outline(high, glyph)
                    for glyph in probes),
                f"{style}: axis {tag} does not vary {probes}")

    # FreeType must load the same file as a variable font and render
    # visibly wider bold text than light text at the weight extremes.
    renderer = ImageFont.truetype(str(path), 96)
    freetype_axes = [(axis["minimum"], axis["default"], axis["maximum"])
                     for axis in renderer.get_variation_axes()]
    require(freetype_axes == [tuple(int(value) for value in axis[1:])
                              for axis in axes],
            f"{style}: FreeType axes are {freetype_axes}")
    defaults = [axis[2] for axis in axes]
    light = list(defaults)
    light[0] = axes[0][1]
    bold = list(defaults)
    bold[0] = axes[0][3]
    renderer.set_variation_by_axes(light)
    light_length = renderer.getlength("Hamburgefonstiv")
    renderer.set_variation_by_axes(bold)
    bold_length = renderer.getlength("Hamburgefonstiv")
    require(bold_length > light_length * 1.2,
            f"{style}: FreeType weight axis is inert "
            f"({light_length} -> {bold_length})")
    return path, axes


def render_specimen(fonts, destination):
    """Render the installed fonts at several variation locations."""
    width, height = 1600, 980
    image = Image.new("RGB", (width, height), "#fbfaf6")
    draw = ImageDraw.Draw(image)
    y = 36

    def line(path, axes, size, overrides, text, fill="#1b1b1b"):
        nonlocal y
        renderer = ImageFont.truetype(str(path), size)
        values = [overrides.get(tag, default)
                  for tag, _minimum, default, _maximum in axes]
        renderer.set_variation_by_axes(values)
        draw.text((48, y), text, font=renderer, fill=fill)
        y += int(size * 1.35)

    for style in ("roman", "italic"):
        path, axes = fonts[style]
        spec = STYLES[style]
        line(path, axes, 30, {"wght": 700}, spec["specimen"], "#7a1f1f")
        rows = [
            ({"wght": axes[0][1]}, "wght %d" % axes[0][1]),
            ({}, "wght 400 default"),
            ({"wght": axes[0][3]}, "wght %d" % axes[0][3]),
            ({"wdth": 50}, "wdth 50"),
            ({"wdth": 125}, "wdth 125"),
            ({"opsz": 144}, "opsz 144"),
        ]
        for overrides, label in rows:
            line(path, axes, 50, overrides,
                 f"Hamburgefonstiv 0123 \u2014 {label}")
        y += 18
    if destination.parent != Path(""):
        destination.parent.mkdir(parents=True, exist_ok=True)
    require(y <= height, f"specimen content overflows the canvas ({y})")
    image.save(destination, format="PNG")


def main(argv):
    parser = argparse.ArgumentParser(prog="amstelvar-smoke")
    parser.add_argument("--font-dir", type=Path, required=True)
    parser.add_argument("--specimen", type=Path)
    parser.add_argument("--build-check", action="store_true",
                        help="skip immutability checks inside the build")
    options = parser.parse_args(argv)

    installed = sorted(entry.name for entry in options.font_dir.iterdir())
    expected = sorted(spec["file"] for spec in STYLES.values())
    require(installed == expected,
            f"installed font set is {installed}, not {expected}")
    fonts = {style: check_font(style, spec, options.font_dir,
                               not options.build_check)
             for style, spec in STYLES.items()}
    if options.specimen is not None:
        render_specimen(fonts, options.specimen)
    print(MARKER, flush=True)


if __name__ == "__main__":
    main(sys.argv[1:])
