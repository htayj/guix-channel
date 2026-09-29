#!/bin/sh
# Prove the installed Amstelvar fonts offline in isolated state and render
# the installed variable fonts into the issue's PNG evidence.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 2; then
    echo "usage: $0 [amstelvar-output [specimen-path]]" >&2
    exit 64
fi

if test "$#" -ge 1; then
    amstelvar_out=$1
else
    amstelvar_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes amstelvar)
fi
if test "$#" -eq 2; then
    specimen=$2
else
    specimen="$channel_dir/.goocastle/evidence/issue-745.png"
fi
case "$specimen" in
    /*) ;;
    *) specimen=$(CDPATH='' cd -- "$(dirname -- "$specimen")" && pwd)/$(basename -- "$specimen") ;;
esac
mkdir -p "$(dirname -- "$specimen")"

fonts="$amstelvar_out/share/fonts/truetype"
doc="$amstelvar_out/share/doc/amstelvar-1.001"
test -x "$amstelvar_out/bin/amstelvar-smoke"
test -s "$amstelvar_out/libexec/amstelvar/amstelvar-smoke.py"
test -s "$fonts/Amstelvar-Roman[GRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,wdth,wght,opsz].ttf"
test -s "$fonts/Amstelvar-Italic[GRAD,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,wdth,wght,opsz].ttf"
# Only the two v1.001 variable fonts are deliverables; the snapshot's
# historical fonts under fonts/old must not be installed.
test "$(find "$amstelvar_out/share/fonts" -type f | wc -l)" -eq 2
for file in OFL.txt COPYRIGHT.md AUTHORS.txt CONTRIBUTORS.txt FONTLOG.md \
    README.md; do
    test -f "$doc/$file"
done
grep -F 'SIL Open Font License, Version 1.1' "$doc/OFL.txt" >/dev/null
grep -F 'Copyright 2016 The Amstelvar Project Authors' "$doc/COPYRIGHT.md" \
    >/dev/null

util_linux_out=
for candidate in $($guix_bin build util-linux); do
    if test -x "$candidate/bin/unshare"; then
        util_linux_out=$candidate
        break
    fi
done
test -n "$util_linux_out"
imagemagick_out=
for candidate in $($guix_bin build imagemagick); do
    if test -x "$candidate/bin/identify"; then
        imagemagick_out=$candidate
        break
    fi
done
test -n "$imagemagick_out"

# The output NAR and file modes are checked before and after both runs,
# proving that the installed fonts and helper remain immutable.
before=$($guix_bin hash -S nar "$amstelvar_out")
test -z "$(find "$amstelvar_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$amstelvar_out"

scratch=$(mktemp -d -t amstelvar-smoke.XXXXXXXX)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
      "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
      "$scratch/out"
chmod 700 "$scratch/runtime"

run_isolated() {
    (cd "$scratch/work" && \
        env -i HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
        XDG_DATA_HOME="$scratch/data" XDG_STATE_HOME="$scratch/state" \
        XDG_CACHE_HOME="$scratch/cache" XDG_RUNTIME_DIR="$scratch/runtime" \
        TMPDIR="$scratch/tmp" LC_ALL=C PATH= \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        "$amstelvar_out/bin/amstelvar-smoke" "$@")
}

# The contract invocation takes no arguments and runs without any network
# interface; its only stdout is the marker.
result=$(run_isolated)
test "$result" = 'amstelvar: font metadata smoke passed'

# The specimen run renders the installed fonts through FreeType at several
# weight, width, and optical-size locations.
result=$(run_isolated --specimen "$scratch/out/issue-745.png")
test "$result" = 'amstelvar: font metadata smoke passed'
image_info=$("$imagemagick_out/bin/identify" -format '%m %w %h %k' \
    "$scratch/out/issue-745.png")
IFS=' ' read -r image_format image_width image_height image_colors <<EOF
$image_info
EOF
test "$image_format" = PNG
test "$image_width" -ge 800
test "$image_height" -ge 500
test "$image_colors" -ge 10

# HOME, every XDG location, TMPDIR, and the working directory stay empty.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work" -mindepth 1 -print -quit)"
after=$($guix_bin hash -S nar "$amstelvar_out")
test "$before" = "$after"
test -z "$(find "$amstelvar_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$amstelvar_out"

cp "$scratch/out/issue-745.png" "$specimen"
echo "amstelvar runtime proof passed: $specimen"
