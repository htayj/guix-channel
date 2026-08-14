#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

default_log="$work_dir/default-build.log"
if guix build -L "$repo_dir" --no-grafts --no-substitutes sentinelone \
  >"$default_log" 2>&1; then
  printf '%s\n' 'default SentinelOne build unexpectedly succeeded' >&2
  exit 1
fi
grep -F 'SentinelOne installer not supplied' "$default_log" >/dev/null

fixture_root="$work_dir/fixture"
agent_dir="$fixture_root/opt/sentinelone"
mkdir -p "$fixture_root/DEBIAN" "$agent_dir/bin" "$agent_dir/lib"

# This payload consists solely of Guix coreutils' harmless true executable.  It
# is not SentinelOne software and exists only to exercise Debian extraction.
true_path=
for coreutils_output in $(guix build coreutils); do
  if test -x "$coreutils_output/bin/true"; then
    true_path="$coreutils_output/bin/true"
    break
  fi
done
test -n "$true_path"
cp "$true_path" "$agent_dir/bin/sentinelctl"
cp "$true_path" "$agent_dir/bin/sentinelone-agent"
cp "$true_path" "$agent_dir/bin/sentinelone-watchdog"
cp "$true_path" "$agent_dir/lib/libbpf.so"
# Guix store files are read-only; model a normal vendor shared library that
# the package's documented patchelf compatibility fix can update.
chmod u+w "$agent_dir/lib/libbpf.so"

printf '%s\n' \
  'Package: sentinelone-fixture' \
  'Version: 24.3.3.1' \
  'Architecture: amd64' \
  'Maintainer: guix-channel tests' \
  'Description: synthetic package used only for a Guix build smoke test' \
  >"$fixture_root/DEBIAN/control"

dpkg_deb=$(guix build dpkg)/bin/dpkg-deb
"$dpkg_deb" --root-owner-group --build \
  "$fixture_root" "$work_dir/sentinelone-fixture.deb"

output=$(guix build -L "$repo_dir" --no-grafts \
  --with-source="sentinelone=$work_dir/sentinelone-fixture.deb" \
  sentinelone)

for program in sentinelctl sentinelone-agent sentinelone-watchdog; do
  test -x "$output/bin/$program"
  test "$(readlink "$output/bin/$program")" = \
    "$output/opt/sentinelone/bin/$program"
done
test -L "$output/lib"
test "$(readlink "$output/lib")" = "$output/opt/sentinelone/lib"
test -f "$output/opt/sentinelone/lib/libbpf.so"

printf 'synthetic SentinelOne fixture smoke passed: %s\n' "$output"
