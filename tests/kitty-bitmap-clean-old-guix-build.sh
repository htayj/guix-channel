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

# Realize each channel-private Go dependency on its own, before Kitty.  Going
# through kitty-bitmap alone is too weak: a dependency that fails to build is
# indistinguishable from Kitty failing for its own reasons, and the failing
# derivation is only named deep inside Kitty's log.  Building them by name
# pins the blame -- which is where go-github-com-sgtdi-fswatcher-kitty-bitmap
# regressed on another machine.
dep_roots=''
for dep in go-github-com-emmansun-base64-kitty-bitmap \
           go-github-com-sgtdi-fswatcher-kitty-bitmap; do
  dep_out=$($guix_prefix build -L guix --no-grafts "$dep") || {
    echo "channel-private dependency $dep failed to build" >&2
    exit 1
  }
  # go-build-system installs sources; an empty output means the build silently
  # produced nothing for Kitty's GOPATH to union in.
  found_dep=
  for candidate in $dep_out; do
    if test -d "$candidate/src"; then
      found_dep=$candidate
      break
    fi
  done
  test -n "$found_dep" || {
    echo "$dep built no src/ output" >&2
    exit 1
  }
  dep_roots="$dep_roots${dep_roots:+:}$found_dep"
  echo "$dep -> $found_dep"
done

# fswatcher's own test suite is disabled in the channel (it drives live
# inotify/fanotify syscalls against fixed sleeps, so it measures the builder's
# kernel and scheduler rather than the code).  Replace it with the proof that
# actually matters here: the package compiles from its installed source and
# exports the exact API Kitty's tools/watch/api.go imports.  A compile error
# or a renamed symbol fails here, named, instead of surfacing as an opaque
# Kitty build failure.
go_env=$($guix_prefix build -L guix --no-grafts go)
go_bin=
for candidate in $go_env; do
  if test -x "$candidate/bin/go"; then
    go_bin=$candidate/bin/go
    break
  fi
done
test -n "$go_bin" || {
  echo 'no go toolchain found for the import proof' >&2
  exit 1
}

sys_out=$($guix_prefix build -L guix --no-grafts go-golang-org-x-sys)
for candidate in $sys_out; do
  if test -d "$candidate/src"; then
    dep_roots="$dep_roots:$candidate"
    break
  fi
done

mkdir -p "$workdir/importproof/src/kittyimportproof"
# Mirrors, call for call, the fswatcher surface kitty's tools/watch/api.go
# uses: the WatchEvent channel element type, a []WatcherOpt built from
# WithCooldown and WithPath, WithDepth/WatchTopLevel as a nested PathOption,
# New, and AddPath.
cat > "$workdir/importproof/src/kittyimportproof/main.go" <<'EOF'
package main

import (
	"time"

	"github.com/sgtdi/fswatcher"
)

func main() {
	events := make(chan fswatcher.WatchEvent)
	_ = events

	opts := []fswatcher.WatcherOpt{fswatcher.WithCooldown(time.Second)}
	opts = append(opts,
		fswatcher.WithPath("/tmp", fswatcher.WithDepth(fswatcher.WatchTopLevel)))

	w, err := fswatcher.New(opts...)
	if err != nil {
		panic(err)
	}
	if err := w.AddPath("/tmp", fswatcher.WithDepth(fswatcher.WatchTopLevel)); err != nil {
		panic(err)
	}
}
EOF

(
  cd "$workdir/importproof"
  GO111MODULE=off \
  GOFLAGS= \
  GOCACHE="$workdir/gocache" \
  GOPATH="$workdir/importproof:$dep_roots" \
    "$go_bin" build -o "$workdir/importproof/proof" kittyimportproof
) || {
  echo 'fswatcher does not compile or no longer exports the API kitty imports' >&2
  exit 1
}
echo 'fswatcher compile/import proof passed'

# The full kitty-bitmap graph must evaluate under the old Guix.
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
