#!/bin/sh
# Drive the installed SDL window in fresh state, with no host network access.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [crashrun-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    crashrun_out=$1
else
    crashrun_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts crashrun)
fi

program_output() {
    program=$1
    shift
    for candidate in $($guix_bin build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate/$program"
            return 0
        fi
    done
    echo "crashrun-smoke: missing $program" >&2
    return 1
}
python_bin=$(program_output bin/python3 python)
xvfb_bin=$(program_output bin/Xvfb xorg-server)
xdotool_bin=$(program_output bin/xdotool xdotool)
capture_bin=$(program_output bin/import imagemagick)
convert_bin=$(program_output bin/convert imagemagick)
tesseract_bin=$(program_output bin/tesseract tesseract-ocr)
unshare_bin=$(program_output bin/unshare util-linux)

test -x "$crashrun_out/bin/crashrun"
test -s "$crashrun_out/share/crashrun/VeraMono.ttf"
test -s "$crashrun_out/share/doc/crashrun/license.txt"
test -s "$crashrun_out/share/doc/crashrun/COPYRIGHT.TXT"
grep -F 'GNU GENERAL PUBLIC LICENSE' "$crashrun_out/share/doc/crashrun/license.txt" >/dev/null
grep -F 'Bitstream Vera Fonts Copyright' "$crashrun_out/share/doc/crashrun/COPYRIGHT.TXT" >/dev/null
grep -F 'shall be included in all copies' "$crashrun_out/share/doc/crashrun/COPYRIGHT.TXT" >/dev/null

# Resolve all packages before entering an empty network namespace.  Xvfb uses
# only its Unix socket (-nolisten tcp), so loopback need not be brought up.
exec "$unshare_bin" --user --map-root-user --net --fork \
    "$python_bin" "$channel_dir/tests/crashrun-smoke.py" "$crashrun_out" \
    "$xvfb_bin" "$xdotool_bin" "$capture_bin" "$convert_bin" "$tesseract_bin"
