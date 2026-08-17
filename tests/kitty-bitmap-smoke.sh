#!/bin/sh
# Verify the kitty-bitmap derivation, its source-level invariants, and the
# headless Fontconfig-and-raster path for a native PCF strike.
set -eu

guix_tool=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

# Deliberately allow GUIX to be a command prefix such as
# "guix time-machine -C channels.guix --", not only an executable pathname.
source_tree=$($guix_tool build -L . --no-grafts -S kitty-bitmap)
select_output() {
  program=$1
  shift
  for candidate in $($guix_tool build "$@"); do
    if test -e "$candidate/$program"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

# Guix versions differ on command-line output selection syntax.  Select the
# named output structurally, so this works with the channel-pinned Guix too.
kitty_out=$(select_output bin/kitty -L . --no-grafts kitty-bitmap)
unscii_out=$(select_output share/fonts/misc/unscii-16-full.pcf font-unscii)
fontconfig_out=$(select_output bin/fc-cache fontconfig)

test -x "$kitty_out/bin/kitty"
"$kitty_out/bin/kitty" --version

# The source output is produced only after all three channel-local patches apply.
awk '
  /^def fc_list\(/ { in_fc_list = 1 }
  /^def fc_match\(/ { in_fc_list = 0 }
  in_fc_list && /allow_bitmapped_fonts: bool = True/ { found = 1 }
  END { exit !found }
' "$source_tree/kitty/fast_data_types.pyi"
awk '
  /^def fc_match\(/ { in_fc_match = 1 }
  /^def fc_match_postscript_name\(/ { in_fc_match = 0 }
  in_fc_match && /allow_bitmapped_fonts: bool = True/ { found = 1 }
  END { exit !found }
' "$source_tree/kitty/fast_data_types.pyi"
grep -F 'int allow_bitmapped_fonts = 1, spacing = -1, only_variable = 0;' "$source_tree/kitty/fontconfig.c" >/dev/null
grep -F 'int bold = 0, italic = 0, allow_bitmapped_fonts = 1, spacing = FC_MONO;' "$source_tree/kitty/fontconfig.c" >/dev/null
grep -F 'fc_list(spacing=FC_CHARCELL)' "$source_tree/kitty/fonts/fontconfig.py" >/dev/null
grep -F "descriptor['spacing'] in ('CHARCELL', 'MONO', 'DUAL')" "$source_tree/kitty/fonts/fontconfig.py" >/dev/null
grep -F 'mods = (mods & ~GLFW_MOD_META) | GLFW_MOD_ALT;' "$source_tree/kitty/key_encoding.c" >/dev/null
grep -F 'GLFW_MOD_META' "$source_tree/kitty/keys.py" >/dev/null
grep -F 'ae(q(mods=meta)' "$source_tree/kitty_tests/keys.py" >/dev/null
grep -F 'ae(dq(ord('\''a'\''), mods=meta)' "$source_tree/kitty_tests/keys.py" >/dev/null
grep -F 'self->face->size->metrics.max_advance' "$source_tree/kitty/freetype.c" >/dev/null
grep -F 'self->face->size->metrics.height / 64.0' "$source_tree/kitty/freetype.c" >/dev/null

# Use Unscii's non-scalable PCF output as a deterministic Fontconfig fixture.
# The native Fontconfig calls are reached through +runpy, not a GUI server, so
# this proves resolver discovery and rasterization, but not a live GUI window.
kitty_smoke_tmp=$(mktemp -d)
trap 'rm -rf "$kitty_smoke_tmp"' EXIT HUP INT TERM
mkdir "$kitty_smoke_tmp/cache"
printf '%s\n' \
  '<?xml version="1.0"?>' \
  '<fontconfig>' \
  '  <reset-dirs />' \
  "  <dir>$unscii_out/share/fonts/misc</dir>" \
  "  <cachedir>$kitty_smoke_tmp/cache</cachedir>" \
  '</fontconfig>' > "$kitty_smoke_tmp/fonts.conf"

# Populate only the fixture cache, then call Kitty's native fc_list/fc_match
# defaults.  The command has no display-server dependency.
FONTCONFIG_FILE="$kitty_smoke_tmp/fonts.conf" \
  "$fontconfig_out/bin/fc-cache" -f >/dev/null
FONTCONFIG_FILE="$kitty_smoke_tmp/fonts.conf" \
  "$kitty_out/bin/kitty" +runpy \
  'from kitty.fast_data_types import GLFW_MOD_META, Face, KeyEvent, SingleKey, fc_list, fc_match; from kitty.fonts.fontconfig import find_best_match; from kitty.fonts.render import render_string; from kitty.keys import shortcut_matches; assert shortcut_matches(SingleKey(GLFW_MOD_META, False, ord("a")), KeyEvent(ord("a"), mods=GLFW_MOD_META)); primary = find_best_match("Unscii"); assert primary["family"] == "Unscii" and primary["spacing"] == "CHARCELL" and primary["path"].endswith(".pcf"), primary; w, h, cells = render_string("ABC", family="Unscii", size=8, dpi=96); assert w > 0 and h > 0 and cells and any(any(cell) for cell in cells); face = Face(fc_match("Unscii")); face.set_size(8, 96, 96); sample, cw, ch = face.render_sample_text("ABC", 160, 80); assert cw > 0 and ch > 0 and sample and any(sample); print(sorted({x["family"] for x in fc_list()})); print(fc_match("Unscii")["family"]); print("raw-meta-shortcut-ok"); print("unscii-primary-font-ok"); print("unscii-raster-ok")' \
  > "$kitty_smoke_tmp/font-list"
grep -F "'Unscii'" "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'Unscii' "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'raw-meta-shortcut-ok' "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'unscii-primary-font-ok' "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'unscii-raster-ok' "$kitty_smoke_tmp/font-list" >/dev/null

printf '%s\n' 'kitty-bitmap smoke passed: patched source, keyboard invariants, and Unscii PCF rasterization'
