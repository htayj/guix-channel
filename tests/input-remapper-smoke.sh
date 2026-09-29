#!/bin/sh
# Prove the installed Input Remapper in isolated, network-less state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 2; then
    echo "usage: $0 [input-remapper-output [screenshot-path]]" >&2
    exit 64
fi

if test "$#" -ge 1; then
    out=$1
else
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts input-remapper)
fi
if test "$#" -eq 2; then
    screenshot=$2
else
    screenshot="$channel_dir/.goocastle/evidence/issue-756.png"
fi
case "$screenshot" in
    /*) ;;
    *) screenshot=$(CDPATH='' cd -- "$(dirname -- "$screenshot")" && pwd)/$(basename -- "$screenshot") ;;
esac
mkdir -p "$(dirname -- "$screenshot")"

# Installed programs, license and upstream data files.
for program in input-remapper-control input-remapper-gtk \
    input-remapper-reader-service input-remapper-service; do
    test -x "$out/bin/$program"
    test -f "$out/libexec/input-remapper/$program"
done
license=$(find "$out/share/doc" -name LICENSE -type f)
test -n "$license"
grep -F 'GNU GENERAL PUBLIC LICENSE' "$license" >/dev/null
grep -F 'Version 3, 29 June 2007' "$license" >/dev/null
test -s "$out/share/input-remapper/input-remapper.glade"
test -s "$out/share/input-remapper/style.css"
test -s "$out/share/input-remapper/lang/fr/LC_MESSAGES/input-remapper.mo"
test -s "$out/share/icons/hicolor/scalable/apps/input-remapper.svg"
test -s "$out/share/metainfo/io.github.sezanzeb.input_remapper.metainfo.xml"
test -s "$out/share/dbus-1/system.d/inputremapper.Control.conf"
test -s "$out/lib/udev/rules.d/69-input-remapper-forwarded.rules"

# Integration files point at this output instead of FHS locations.  They are
# shipped for administrators to enable; the package activates none of them.
grep -F "RUN+=\"$out/bin/input-remapper-control --command autoload" \
    "$out/lib/udev/rules.d/99-input-remapper.rules" >/dev/null
grep -Fx "ExecStart=$out/bin/input-remapper-service" \
    "$out/lib/systemd/system/input-remapper.service" >/dev/null
grep -Fx 'BusName=inputremapper.Control' \
    "$out/lib/systemd/system/input-remapper.service" >/dev/null
grep -F ">$out/bin/input-remapper-control</annotate>" \
    "$out/share/polkit-1/actions/input-remapper.policy" >/dev/null
grep -F "$out/bin/input-remapper-control --command autoload" \
    "$out/share/input-remapper/xdg/autostart/input-remapper-autoload.desktop" \
    >/dev/null
test ! -e "$out/etc/xdg/autostart"
grep -Fx "Exec=$out/bin/input-remapper-gtk" \
    "$out/share/applications/input-remapper-gtk.desktop" >/dev/null
if grep -R -e '/usr/bin' -e '"/bin/input-remapper' \
    "$out/lib/udev" "$out/lib/systemd" "$out/share/polkit-1" \
    "$out/share/applications" "$out/share/input-remapper/xdg" >/dev/null; then
    echo "input-remapper: integration file still names an FHS path" >&2
    exit 1
fi
grep -F "DATA_DIR = \"$out/share/input-remapper\"" \
    "$out"/lib/python3.*/site-packages/inputremapper/installation_info.py >/dev/null
grep -F 'COMMIT_HASH = "3b519a18fc39c4d3b4b3074ca96fbcd46585a9ac"' \
    "$out"/lib/python3.*/site-packages/inputremapper/installation_info.py >/dev/null

# The reviewed runtime contract for issue #756 names this exact invocation.
contracts="$channel_dir/.goocastle/runtime-evidence-contracts.json"
if test -f "$contracts"; then
    grep -F '"packageModulePath": "guix/tay/packages/input-remapper.scm"' \
        "$contracts" >/dev/null
    grep -F '"artifactPath": ".goocastle/evidence/issue-756.png"' \
        "$contracts" >/dev/null
fi

find_tool() {
    package=$1
    tool=$2
    for candidate in $($guix_bin build "$package"); do
        if test -e "$candidate/$tool"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "input-remapper: $package provides no $tool" >&2
    return 1
}
util_linux=$(find_tool util-linux bin/unshare)
imagemagick=$(find_tool imagemagick bin/convert)
font_dejavu=$(find_tool font-dejavu share/fonts/truetype/DejaVuSansMono.ttf)
coreutils=$(find_tool coreutils bin/timeout)
sh_bin=$(command -v sh)

before=$($guix_bin hash -S nar "$out")

scratch=$(mktemp -d -t input-remapper-smoke.XXXXXX)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
state=$scratch/state
mkdir -p "$state/home" "$state/config" "$state/data" "$state/cache" \
    "$state/xdg-state" "$state/runtime" "$state/tmp"
chmod 700 "$state/runtime"

# No display, no D-Bus, no /dev/input access and only a loopback interface:
# the command resolves key names from its packaged evdev tables.
status=0
env -i \
    HOME="$state/home" \
    XDG_CONFIG_HOME="$state/config" \
    XDG_DATA_HOME="$state/data" \
    XDG_CACHE_HOME="$state/cache" \
    XDG_STATE_HOME="$state/xdg-state" \
    XDG_RUNTIME_DIR="$state/runtime" \
    TMPDIR="$state/tmp" \
    LC_ALL=C \
    "$coreutils/bin/timeout" 120 \
    "$util_linux/bin/unshare" --user --map-root-user --net --fork \
    "$sh_bin" -c '
        interfaces=
        while IFS=: read -r name _; do
            case "$name" in *\|*) continue ;; esac
            set -- $name
            interfaces="$interfaces$1 "
        done </proc/net/dev
        test "$interfaces" = "lo " || {
            echo "network namespace has: $interfaces" >&2
            exit 90
        }
        exec "$0" --symbol-names' \
    "$out/bin/input-remapper-control" \
    >"$scratch/stdout" 2>"$scratch/stderr" || status=$?
if test "$status" -ne 0; then
    cat "$scratch/stderr" >&2
    echo "input-remapper: --symbol-names exited with status $status" >&2
    exit 1
fi
grep -Fx KEY_A "$scratch/stdout" >/dev/null
grep -Fx BTN_LEFT "$scratch/stdout" >/dev/null
grep -Fx disable "$scratch/stdout" >/dev/null
names=$(wc -l <"$scratch/stdout" | tr -d ' ')
test "$names" -ge 500

# The read-only query leaves no configuration, cache or data behind.
leftover=$(find "$state" -mindepth 1 ! -type d -print)
if test -n "$leftover"; then
    printf 'input-remapper: unexpected state files:\n%s\n' "$leftover" >&2
    exit 1
fi

after=$($guix_bin hash -S nar "$out")
test "$before" = "$after"
test -z "$(find "$out" -xdev -type f -perm /222 -print -quit)"

# Render verbatim, contiguous stdout of the isolated run around the contract
# marker; nothing is added to the program's own output lines.
grep -Fx -B 8 -A 12 KEY_A "$scratch/stdout" >"$scratch/screen.txt"
test "$(grep -c . "$scratch/screen.txt")" -eq 21
"$imagemagick/bin/convert" -size 1280x560 -background '#1e1e1e' -fill '#d4d4d4' \
    -font "$font_dejavu/share/fonts/truetype/DejaVuSansMono.ttf" -pointsize 16 \
    -gravity northwest -interline-spacing 2 "caption:@$scratch/screen.txt" \
    "PNG24:$screenshot"
image_info=$("$imagemagick/bin/identify" -format '%m %w %h %k' "$screenshot")
IFS=' ' read -r image_format image_width image_height image_colors <<EOF
$image_info
EOF
test "$image_format" = PNG
test "$image_width" -ge 800
test "$image_height" -ge 500
test "$image_colors" -ge 10

grep -Fx KEY_A "$scratch/stdout"
echo "input-remapper runtime proof passed: $names symbol names, $screenshot"
