#!/bin/sh
# Fail-closed proof for a package added or changed by the active Goocastle run.
set -eu

channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"
guix_bin=${GUIX:-guix}

# Normal Gooflow execution proves the active branch against origin/master.
# A post-delivery evidence replay instead supplies the persisted pre-delivery
# commit through GOOCASTLE_PROOF_BASE_REF; this keeps the same package scope
# after the branch itself has become origin/master.
base_ref=${GOOCASTLE_PROOF_BASE_REF:-origin/master}
git rev-parse --verify "$base_ref" >/dev/null 2>&1 || base_ref=master
base=$(git merge-base HEAD "$base_ref")
changed_modules=$(git diff --name-only "$base"...HEAD -- tay/packages | sed -n 's|^tay/packages/\(.*\)\.scm$|\1|p' | sort -u)
packages=${GOOCASTLE_PROOF_PACKAGE:-}

# An evidence-refresh or audit delivery may intentionally change no package
# module.  It can still prove one existing package, but only through the
# active issue's reviewed runtime contract; never infer a package from an
# artifact or an arbitrary issue number.
if test -z "$packages" && test -z "$changed_modules" && test -n "${GOOCASTLE_ISSUE_NUMBER:-}"; then
  packages=$(node -e '
const fs = require("fs");
const issueNumber = Number(process.argv[1]);
if (!Number.isSafeInteger(issueNumber) || issueNumber < 1) process.exit(2);
const document = JSON.parse(fs.readFileSync(".goocastle/runtime-evidence-contracts.json", "utf8"));
const contract = document.contracts?.find((entry) => entry?.issueNumber === issueNumber);
if (!contract || typeof contract.packageName !== "string" || !/^[a-z0-9][a-z0-9-]*$/.test(contract.packageName) || contract.artifactPath !== `.goocastle/evidence/issue-${issueNumber}.png`) process.exit(2);
process.stdout.write(contract.packageName);
' "$GOOCASTLE_ISSUE_NUMBER") || {
    echo "safe-package-proof: no reviewed runtime contract for issue #$GOOCASTLE_ISSUE_NUMBER" >&2
    exit 1
  }
fi

test -n "$packages" || test -n "$changed_modules" || {
  echo "safe-package-proof: active change adds no package module under tay/packages" >&2
  exit 1
}

for module in $changed_modules; do
  names=$(sed -n 's/^[[:space:]]*(define-public[[:space:]]\+\([a-z0-9][a-z0-9-]*\).*/\1/p' "tay/packages/$module.scm" | sort -u)
  # Supporting manifests can be changed together with a package but do not
  # themselves provide end-user deliverables.  They remain covered by the
  # consuming package's build, reproducibility, and smoke proof below.
  test -n "$names" || continue
  for name in $names; do
    # Source-preservation helpers are package inputs, not end-user
    # deliverables.  The consuming package realizes them above and owns the
    # required reproducibility and runtime smoke proof.
    case "$name" in
      *-source) ;;
      *) packages="$packages $name" ;;
    esac
  done
done

test -n "$packages" || {
  echo "safe-package-proof: active change adds no deliverable package" >&2
  exit 1
}

proof_root=$(mktemp -d -t goocastle-guix-package-proof.XXXXXX)
trap 'rm -rf "$proof_root"' EXIT HUP INT TERM
mkdir "$proof_root/home" "$proof_root/config" "$proof_root/data" "$proof_root/cache"

# Realize every changed sibling before any check or smoke gate.  A package's
# integration smoke test may intentionally exercise a later-defined backend.
for package in $packages; do
  "$guix_bin" build -L . --no-grafts "$package" >/dev/null
done

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
  # `guix package -p` tries to update the per-user profile registry below
  # /var/guix/profiles.  Rootless Goocastle containers deliberately expose
  # that registry read-only, so profile creation measures container authority
  # rather than package installability.  The realized output below, followed
  # by the package-specific smoke test against that exact output, is the
  # hermetic installation and runtime proof.
  HOME="$proof_root/home" XDG_CONFIG_HOME="$proof_root/config" \
    XDG_DATA_HOME="$proof_root/data" XDG_CACHE_HOME="$proof_root/cache" \
    GUIX="$guix_bin" sh "$smoke" "$output"
  test -z "$(find "$output" -xdev -type f -perm /222 -print -quit)"
done
