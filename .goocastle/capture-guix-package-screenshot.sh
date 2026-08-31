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

capture_root=$(mktemp -d -t goocastle-guix-runtime-screenshot.XXXXXX)
trap 'rm -rf "$capture_root"' EXIT HUP INT TERM
proof_transcript="$capture_root/proof.txt"
runtime_transcript="$capture_root/runtime.txt"

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
# A terminal transcript is not visual evidence of an end-user application.
# The implementation/audit phase must commit the canonical PNG produced by the
# running program itself.  This retryable gate verifies that artifact together
# with a fresh, host-checked packaged-program invocation; it never overwrites
# a genuine visual receipt with a caption of command output.
test -s "$artifact" || {
  echo "runtime-screenshot: missing program-produced artifact $artifact" >&2
  exit 1
}
# The host requires the last line to be a matching assertion.  Keep the
# program's stdout and this assertion out of the screenshot-only proof log.
cat "$runtime_transcript"
