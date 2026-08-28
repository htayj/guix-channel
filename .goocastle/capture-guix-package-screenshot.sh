#!/bin/sh
# Capture real packaged-program evidence after the isolated Guix proof.
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
proof_transcript="$capture_root/proof.txt"
runtime_transcript="$capture_root/runtime.txt"
transcript="$capture_root/screenshot.txt"

# The required tools are pinned in manifest.scm.  A nested `guix shell` would
# attempt to create a profile under the container's read-only /var/guix/profiles.
# Keep proof output out of command stdout because it can exceed Goocastle's
# command-output budget.  The runtime adapter below is deliberately different:
# its compact stdout is host-validated as an actual package invocation.
if ! sh .goocastle/prove-guix-package.sh >"$proof_transcript" 2>&1; then
  tail -c 12000 "$proof_transcript" >&2 || true
  exit 1
fi
if ! node .goocastle/capture-runtime-evidence.mjs \
  .goocastle/runtime-evidence-contracts.json "$issue_number" >"$runtime_transcript" 2>&1; then
  tail -c 12000 "$runtime_transcript" >&2 || true
  exit 1
fi
tail -c 8000 "$proof_transcript" >"$transcript"
printf '\n\n=== packaged program runtime ===\n\n' >>"$transcript"
cat "$runtime_transcript" >>"$transcript"
convert -size 1280x -background "#101418" -fill "#e8eaed" \
  -font DejaVu-Sans-Mono -pointsize 16 -gravity northwest \
  "caption:@$transcript" "$artifact"

test -s "$artifact"
# The host requires the last line to be a matching assertion.  Keep the
# program's stdout and this assertion out of the screenshot-only proof log.
cat "$runtime_transcript"
