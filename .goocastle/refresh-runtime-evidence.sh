#!/bin/sh
# Run the correct package proof for an evidence-refresh issue.
set -eu

mode=${1:-}
case "$mode" in
  proof|screenshot) ;;
  *) echo "usage: refresh-runtime-evidence.sh proof|screenshot" >&2; exit 2 ;;
esac

issue_number=${GOOCASTLE_ISSUE_NUMBER:?refresh-runtime-evidence: missing Goocastle issue number}
case "$issue_number" in
  *[!0-9]*|'') echo "refresh-runtime-evidence: invalid Goocastle issue number" >&2; exit 2 ;;
esac

package_name=$(node -e '
const fs = require("fs");
const issueNumber = Number(process.argv[1]);
const document = JSON.parse(fs.readFileSync(".goocastle/runtime-evidence-contracts.json", "utf8"));
const contract = document.contracts?.find((entry) => entry?.issueNumber === issueNumber);
if (!contract || typeof contract.packageName !== "string" || !/^[a-z0-9][a-z0-9-]*$/.test(contract.packageName)) process.exit(2);
process.stdout.write(contract.packageName);
' "$issue_number") || {
  echo "refresh-runtime-evidence: no safe package contract for issue #$issue_number" >&2
  exit 2
}

case "$mode" in
  proof) GOOCASTLE_PROOF_PACKAGE="$package_name" sh .goocastle/prove-guix-package.sh ;;
  screenshot) GOOCASTLE_PROOF_PACKAGE="$package_name" sh .goocastle/capture-guix-package-screenshot.sh ;;
esac
