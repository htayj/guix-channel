#!/bin/sh
# Prove the installed Buzz desktop in isolated state and capture its window.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 2; then
    echo "usage: $0 [buzz-output [screenshot-path]]" >&2
    exit 64
fi

if test "$#" -ge 1; then
    buzz_out=$1
else
    buzz_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes buzz)
fi
if test "$#" -eq 2; then
    screenshot=$2
else
    screenshot="$channel_dir/.goocastle/evidence/issue-726.png"
fi
case "$screenshot" in
    /*) ;;
    *) screenshot=$(CDPATH='' cd -- "$(dirname -- "$screenshot")" && pwd)/$(basename -- "$screenshot") ;;
esac
mkdir -p "$(dirname -- "$screenshot")"

test -x "$buzz_out/bin/buzz"
test -x "$buzz_out/bin/buzz-desktop"
test -x "$buzz_out/libexec/buzz/buzz-desktop"
test -x "$buzz_out/libexec/buzz/buzz-agent"
test -x "$buzz_out/libexec/buzz/buzz-acp"
test -x "$buzz_out/libexec/buzz/buzz-backend-kubernetes"
test -x "$buzz_out/libexec/buzz/buzz-dev-mcp"
test -x "$buzz_out/libexec/buzz/git-credential-nostr"
test -s "$buzz_out/share/applications/Buzz.desktop"
test -s "$buzz_out/share/doc/buzz/LICENSE"
grep -F 'Apache License' "$buzz_out/share/doc/buzz/LICENSE" >/dev/null
grep -F "Exec=$buzz_out/bin/buzz-desktop" \
    "$buzz_out/share/applications/Buzz.desktop" >/dev/null

before=$($guix_bin hash -rx "$buzz_out")
result=$(BUZZ_GUIX_SCREENSHOT_PATH="$screenshot" \
    "$buzz_out/bin/buzz-desktop" --guix-smoke)
printf '%s\n' "$result"
test "$result" = BUZZ_GUIX_SMOKE_OK
test -s "$screenshot"
imagemagick_out=
for candidate in $($guix_bin build imagemagick); do
    if test -x "$candidate/bin/identify"; then
        imagemagick_out=$candidate
        break
    fi
done
test -n "$imagemagick_out"
image_info=$("$imagemagick_out/bin/identify" -format '%m %w %h %k' "$screenshot")
IFS=' ' read -r image_format image_width image_height image_colors <<EOF
$image_info
EOF
test "$image_format" = PNG
test "$image_width" -ge 800
test "$image_height" -ge 500
test "$image_colors" -ge 10
after=$($guix_bin hash -rx "$buzz_out")
test "$before" = "$after"

echo "buzz desktop runtime proof passed: $screenshot"
