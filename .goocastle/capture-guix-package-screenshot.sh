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
terminal_raw="$capture_root/terminal.raw"
terminal_text="$capture_root/terminal.txt"
runtime_home="$capture_root/home"
runtime_config="$capture_root/config"
runtime_data="$capture_root/data"
runtime_cache="$capture_root/cache"
runtime_state="$capture_root/state"
runtime_tmp="$capture_root/tmp"
mkdir "$runtime_home" "$runtime_config" "$runtime_data" "$runtime_cache" \
  "$runtime_state" "$runtime_tmp"

# The required tools are pinned in manifest.scm.  A nested `guix shell` would
# attempt to create a profile under the container's read-only /var/guix/profiles.
# Keep proof output out of command stdout because it can exceed Goocastle's
# command-output budget.  The runtime adapter below is deliberately different:
# its compact stdout is host-validated as an actual package invocation.
if ! GOOCASTLE_RUNTIME_RAW_CAPTURE="$terminal_raw" \
  sh .goocastle/prove-guix-package.sh >"$proof_transcript" 2>&1; then
  tail -c 12000 "$proof_transcript" >&2 || true
  exit 1
fi
if ! env -i \
  HOME="$runtime_home" \
  XDG_CONFIG_HOME="$runtime_config" \
  XDG_DATA_HOME="$runtime_data" \
  XDG_CACHE_HOME="$runtime_cache" \
  XDG_STATE_HOME="$runtime_state" \
  TMPDIR="$runtime_tmp" \
  SDL_VIDEODRIVER=dummy \
  SDL_AUDIODRIVER=dummy \
  TERM=xterm-256color \
  LC_ALL=C.UTF-8 \
  PATH="$PATH" \
  GUIX="${GUIX:-guix}" \
  GOOCASTLE_RUNTIME_RAW_CAPTURE="$terminal_raw" \
  node .goocastle/capture-runtime-evidence.mjs \
  .goocastle/runtime-evidence-contracts.json "$issue_number" >"$runtime_transcript" 2>&1; then
  tail -c 12000 "$runtime_transcript" >&2 || true
  exit 1
fi
# A package that owns a graphical capture can still provide its own canonical
# PNG.  Terminal applications instead hand the proof gate an actual PTY byte
# stream, which is emulated into a deterministic terminal screen and rendered
# locally.  This is visual evidence of the packaged program, not a caption of
# the smoke-test assertion.
if test -s "$terminal_raw"; then
  python3 .goocastle/render-terminal-screenshot.py "$terminal_raw" "$terminal_text"
  convert -size 1280x560 -background '#1e1e1e' -fill '#d4d4d4' \
    -font DejaVu-Sans-Mono -pointsize 16 -gravity northwest \
    -interline-spacing 2 "caption:@$terminal_text" "PNG24:$artifact"
fi
test -s "$artifact" || {
  echo "runtime-screenshot: missing native PNG or captured terminal UI for $artifact" >&2
  exit 1
}
# The host requires the last line to be a matching assertion.  Keep the
# program's stdout and this assertion out of the screenshot-only proof log.
cat "$runtime_transcript"
