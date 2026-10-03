#!/bin/sh
# Compile real HolyC and drive the installed SDL/DolDoc UI in a private container.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [prebuilt-aiwnios-or-aiwnios-bytecode-store-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    out=$1
else
    out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts aiwnios)
fi
case "$out" in
    /gnu/store/*) ;;
    *) echo 'Aiwnios smoke requires a realized /gnu/store output' >&2; exit 64 ;;
esac
# This strict basename also makes inserting the item into a Scheme string safe.
case "${out#/gnu/store/}" in
    *[!a-zA-Z0-9+._-]*|'' ) echo 'invalid Aiwnios store item' >&2; exit 64 ;;
esac
test -x "$out/bin/aiwnios" || { echo 'missing installed bin/aiwnios' >&2; exit 1; }
test -d "$out/share/aiwnios/Src" || { echo 'missing complete boot template' >&2; exit 1; }

scratch=$(mktemp -d "${TMPDIR:-/tmp}/aiwnios-smoke.XXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
artifacts=${AIWNIOS_SMOKE_ARTIFACTS:-$scratch/artifacts}
case "$artifacts" in
    /*) ;;
    *) echo 'AIWNIOS_SMOKE_ARTIFACTS must be absolute' >&2; exit 64 ;;
esac
mkdir -p "$artifacts"
artifacts=$(CDPATH= cd -- "$artifacts" && pwd)
# Root exactly the supplied item, rather than resolving a different package.
cat >"$scratch/manifest.scm" <<EOF
(use-modules (guix profiles) (gnu packages)
             (gnu packages python) (gnu packages python-xyz))
(concatenate-manifests
 (list (packages->manifest (list python python-pillow))
       (specifications->manifest
        '("bash" "coreutils" "xorg-server" "xdotool" "xwd" "imagemagick"))
       (manifest
        (list (manifest-entry (name "aiwnios-smoke-tested-output")
                              (version "e155e87") (item "$out"))))))
EOF
before=$("$guix_bin" hash -x --serializer=nar "$out")
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
status=0
# No --network, --link-profile, --preserve or host X socket exposure.  Only
# artifacts are writable on the host; runner and HolyC fixture are read-only.
"$guix_bin" shell -L "$channel_dir/guix" --no-grafts --rebuild-cache \
    --container --pure --no-cwd --user=aiwnios-smoke \
    -m "$scratch/manifest.scm" \
    --expose="$channel_dir/tests/aiwnios-smoke.py=/aiwnios-smoke.py" \
    --expose="$channel_dir/tests/aiwnios-consumer.HC=/consumer.HC" \
    --share="$artifacts=/aiwnios-artifacts" \
    -- /bin/sh -c '
set -eu
# Search only this manifest profile, never a host Python/user site directory.
GUIX_PYTHONPATH=
for site in "$GUIX_ENVIRONMENT"/lib/python*/site-packages; do
    test -d "$site" || continue
    GUIX_PYTHONPATH=${GUIX_PYTHONPATH:+$GUIX_PYTHONPATH:}$site
done
test -n "$GUIX_PYTHONPATH"
export GUIX_PYTHONPATH PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1
exec "$GUIX_ENVIRONMENT/bin/python3" /aiwnios-smoke.py "$@"
' aiwnios-python "$out" /aiwnios-artifacts \
    "$(readlink /proc/self/ns/net)" "$(readlink /proc/self/ns/mnt)" \
    "$(readlink /proc/self/ns/user)" \
    >"$artifacts/proof.log" 2>&1 || status=$?
# Hash even when runtime assertions fail; store mutation must never be hidden.
after=$("$guix_bin" hash -x --serializer=nar "$out")
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
cat "$artifacts/proof.log"
if test "$before" != "$after"; then
    echo "Aiwnios output NAR changed: $before -> $after" >&2
    exit 1
fi
if test "$status" -ne 0; then
    echo "Aiwnios smoke failed (status $status); artifacts: $artifacts" >&2
    exit "$status"
fi
# Keep immutable-output evidence in the same JSON record as native consumer data.
"$guix_bin" shell --pure -m "$scratch/manifest.scm" -- python3 -c '
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
path = root / "result.json"
result = json.loads(path.read_text())
result["nar_before"] = sys.argv[2]
result["nar_after"] = sys.argv[3]
result["immutable_output"] = sys.argv[2] == sys.argv[3]
path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
print(json.dumps(result, sort_keys=True))
' "$artifacts" "$before" "$after"
if test -n "${AIWNIOS_SMOKE_ARTIFACTS:-}"; then
    printf 'Aiwnios native consumer passed; artifacts: %s\n' "$artifacts"
else
    printf 'Aiwnios native consumer passed; disposable artifacts removed on exit\n'
fi
