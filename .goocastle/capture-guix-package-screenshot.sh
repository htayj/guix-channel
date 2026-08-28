#!/bin/sh
# Capture a bounded terminal screenshot of the real Guix package proof.
set -eu

issue_number=${GOOCASTLE_ISSUE_NUMBER:?runtime-screenshot: missing Goocastle issue number}
case "$issue_number" in
  *[!0-9]*|'') echo "runtime-screenshot: invalid Goocastle issue number" >&2; exit 2 ;;
esac
artifact=".goocastle/evidence/issue-$issue_number.png"
case "$artifact" in
  .goocastle/evidence/*.png) ;;
  *) echo "runtime-screenshot: artifact must be under .goocastle/evidence and end in .png" >&2; exit 2 ;;
esac

channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"
mkdir -p "$(dirname -- "$artifact")"
test ! -e "$artifact" || {
  echo "runtime-screenshot: refusing to overwrite existing artifact $artifact" >&2
  exit 1
}

capture_root=$(mktemp -d -t goocastle-guix-runtime-screenshot.XXXXXX)
trap 'rm -rf "$capture_root"' EXIT HUP INT TERM
transcript="$capture_root/runtime.txt"

# The required tools are pinned in manifest.scm.  A nested `guix shell` would
# attempt to create a profile under the container's read-only /var/guix/profiles.
script -q -e -c "sh .goocastle/prove-guix-package.sh" "$transcript"
tail -c 12000 "$transcript" > "$transcript.tail"
mv "$transcript.tail" "$transcript"
convert -size 1280x -background "#101418" -fill "#e8eaed" \
  -font DejaVu-Sans-Mono -pointsize 16 -gravity northwest \
  "caption:@$transcript" "$artifact"

test -s "$artifact"
