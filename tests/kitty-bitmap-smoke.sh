#!/bin/sh
# Verify the kitty-bitmap derivation, its runtime version and keyboard
# encoding, and the headless Fontconfig-and-raster path for a native PCF strike.
set -eu

guix_tool=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

# Deliberately allow GUIX to be a command prefix such as
# "guix time-machine -C channels.guix --", not only an executable pathname.

# The package owns its complete Kitty identity: both the evaluated package and
# the built program must report the channel's Kitty release, so a rolling Guix
# kitty source or version cannot leak in.
kitty_bitmap_version=0.49.1
evaluated_version=$($guix_tool show -L "$channel_dir/guix" kitty-bitmap | \
  awk '/^version:/ { print $2; exit }')
test "$evaluated_version" = "$kitty_bitmap_version"

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
kitty_out=$(select_output bin/kitty -L "$channel_dir/guix" --no-grafts kitty-bitmap)
unscii_out=$(select_output share/fonts/misc/unscii-16-full.pcf font-unscii)
fontconfig_out=$(select_output bin/fc-cache fontconfig)

# The built program, not merely the package metadata, must be the channel's
# Kitty release.
test -x "$kitty_out/bin/kitty"
"$kitty_out/bin/kitty" --version
runtime_version=$("$kitty_out/bin/kitty" +runpy \
  'from kitty.constants import str_version; print(str_version)')
test "$runtime_version" = "$kitty_bitmap_version" || {
  echo "kitty-bitmap runs Kitty $runtime_version, expected $kitty_bitmap_version" >&2
  exit 1
}

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
  'from kitty.fast_data_types import GLFW_MOD_ALT, GLFW_MOD_CONTROL, GLFW_MOD_META, Face, KeyEvent, SingleKey, encode_key_for_tty, fc_list, fc_match; from kitty.fonts.fontconfig import find_best_match; from kitty.fonts.render import render_string; from kitty.keys import shortcut_matches; assert shortcut_matches(SingleKey(GLFW_MOD_META, False, ord("a")), KeyEvent(ord("a"), mods=GLFW_MOD_META)); esc = chr(27); assert encode_key_for_tty(ord("a"), mods=GLFW_MOD_META) == encode_key_for_tty(ord("a"), mods=GLFW_MOD_ALT) == esc + "a"; assert encode_key_for_tty(ord("a"), mods=GLFW_MOD_META | GLFW_MOD_CONTROL) == esc + chr(1); assert encode_key_for_tty(ord("a"), mods=GLFW_MOD_META, key_encoding_flags=1) == esc + "[97;3u"; primary = find_best_match("Unscii"); assert primary["family"] == "Unscii" and primary["spacing"] == "CHARCELL" and primary["path"].endswith(".pcf"), primary; w, h, cells = render_string("ABC", family="Unscii", size=8, dpi=96); assert w > 0 and h > 0 and cells and any(any(cell) for cell in cells); face = Face(fc_match("Unscii")); face.set_size(8, 96, 96); sample, cw, ch = face.render_sample_text("ABC", 160, 80); assert cw > 0 and ch > 0 and sample and any(sample); print(sorted({x["family"] for x in fc_list()})); print(fc_match("Unscii")["family"]); print("raw-meta-shortcut-ok"); print("meta-child-alt-ok"); print("unscii-primary-font-ok"); print("unscii-raster-ok")' \
  > "$kitty_smoke_tmp/font-list"
grep -F "'Unscii'" "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'Unscii' "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'raw-meta-shortcut-ok' "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'meta-child-alt-ok' "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'unscii-primary-font-ok' "$kitty_smoke_tmp/font-list" >/dev/null
grep -Fx 'unscii-raster-ok' "$kitty_smoke_tmp/font-list" >/dev/null

printf '%s\n' 'kitty-bitmap smoke passed: Kitty version, Meta shortcut and child Alt encoding, and Unscii PCF rasterization'
