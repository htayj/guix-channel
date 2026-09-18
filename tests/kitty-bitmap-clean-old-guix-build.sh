#!/bin/sh
# Regression: kitty-bitmap must build under a Guix revision that predates
# upstream's 2026-08-26 addition of go-github-com-emmansun-base64 and
# go-github-com-sgtdi-fswatcher to the rolling `kitty' inputs.  kitty-bitmap
# pins Kitty 0.48.2's source but inherits its dependency graph, so without the
# channel-private kitty-bitmap-go-deps module the Go build fails with
# `cannot find package' for exactly those two modules.  The build runs in a
# disposable clean clone so uncommitted or local files cannot leak in.
set -eu

# Pin the OLD side explicitly: plain `guix' is whatever this machine happens
# to have and would silently stop reproducing the bug after an update.  Only
# the core guix channel is pinned; the test needs nothing else, and the
# channel's own guix directory is layered on with -L below.
OLD_GUIX_COMMIT=${OLD_GUIX_COMMIT:-21c3d6748b65dad0d23c5d72e406ffee42212884}
repo=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}

workdir=$(mktemp -d /tmp/kitty-bitmap-oldguix.XXXXXX)
trap 'rm -rf "$workdir"' EXIT

cat > "$workdir/old-guix-channel.scm" <<EOF
(list (channel
        (name 'guix)
        (url "https://git.guix.gnu.org/guix.git")
        (commit "$OLD_GUIX_COMMIT")))
EOF

# Clean external checkout at HEAD of the working repo; no worktree spillover.
git clone --quiet --no-hardlinks "file://$repo" "$workdir/guix-channel"
cd "$workdir/guix-channel"
test -z "$(git status --porcelain)" || {
  echo 'clean clone is not clean' >&2
  exit 1
}

guix_prefix="guix time-machine -C $workdir/old-guix-channel.scm --disable-authentication --"

echo "clean clone at $(git rev-parse --short HEAD); old guix $OLD_GUIX_COMMIT"

# The two channel-private dependency packages must evaluate under the old Guix.
$guix_prefix build -L guix --no-grafts -d kitty-bitmap >/dev/null

# Source build proves the four channel patches still apply on the old graph.
$guix_prefix build -L guix --no-grafts -S kitty-bitmap >/dev/null

# Full build: fails pre-fix with
#   kittens/ssh/main.go:30:2: cannot find package "github.com/emmansun/base64"
#   tools/watch/api.go:14:2: cannot find package "github.com/sgtdi/fswatcher"
kitty_out=$($guix_prefix build -L guix --no-grafts kitty-bitmap)
found_kitty=
for candidate in $kitty_out; do
  if test -x "$candidate/bin/kitty"; then
    found_kitty=$candidate
    break
  fi
done
test -n "$found_kitty" || {
  echo 'built outputs do not contain bin/kitty' >&2
  exit 1
}
"$found_kitty/bin/kitty" --version

echo 'kitty-bitmap clean-clone old-guix regression passed'
