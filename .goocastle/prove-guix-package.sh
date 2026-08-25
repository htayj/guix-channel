#!/bin/sh
# Fail-closed proof for a package added or changed by the active Goocastle run.
set -eu

channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"
guix_bin=${GUIX:-guix}

base_ref=origin/master
git rev-parse --verify "$base_ref" >/dev/null 2>&1 || base_ref=master
base=$(git merge-base HEAD "$base_ref")
changed_modules=$(git diff --name-only "$base"...HEAD -- tay/packages | sed -n 's|^tay/packages/\([A-Za-z0-9-]*\)\.scm$|\1|p' | sort -u)
test -n "$changed_modules" || {
  echo "safe-package-proof: active change adds no package module under tay/packages" >&2
  exit 1
}

packages=
for module in $changed_modules; do
  names=$(sed -n 's/^[[:space:]]*(define-public[[:space:]]\+\([a-z0-9][a-z0-9-]*\).*/\1/p' "tay/packages/$module.scm" | sort -u)
  test -n "$names" || {
    echo "safe-package-proof: tay/packages/$module.scm exports no package" >&2
    exit 1
  }
  packages="$packages $names"
done

proof_root=$(mktemp -d -t goocastle-guix-package-proof.XXXXXX)
trap 'rm -rf "$proof_root"' EXIT HUP INT TERM
mkdir "$proof_root/home" "$proof_root/config" "$proof_root/data" "$proof_root/cache"

for package in $packages; do
  smoke="tests/$package-smoke.sh"
  test -f "$smoke" || {
    echo "safe-package-proof: $package requires package-specific $smoke" >&2
    exit 1
  }
  "$guix_bin" lint -L . --no-network --exclude=cve,refresh,archival "$package"
  # Guix's --check rebuild compares against an already-realized ordinary
  # output; invoking it first fails before any reproducibility proof exists.
  output=$("$guix_bin" build -L . --no-grafts "$package")
  "$guix_bin" build -L . --no-grafts --check "$package"
  test -n "$output"
  HOME="$proof_root/home" XDG_CONFIG_HOME="$proof_root/config" \
    XDG_DATA_HOME="$proof_root/data" XDG_CACHE_HOME="$proof_root/cache" \
    "$guix_bin" package -L . -p "$proof_root/$package-profile" -i "$package"
  test -e "$proof_root/$package-profile"
  HOME="$proof_root/home" XDG_CONFIG_HOME="$proof_root/config" \
    XDG_DATA_HOME="$proof_root/data" XDG_CACHE_HOME="$proof_root/cache" \
    GUIX="$guix_bin" sh "$smoke" "$output"
  test -z "$(find "$output" -xdev -type f -perm /222 -print -quit)"
done
