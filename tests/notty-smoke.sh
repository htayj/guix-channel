#!/bin/sh
# Compile a disposable installed-package consumer, then prove Unix and Lwt on PTYs.
# Usage: sh tests/notty-smoke.sh [notty-output [pqwy-notty-source-output]]
# NOTTY_SMOKE_ARTIFACTS selects a new/empty absolute evidence directory.
set -eu

fail() { printf 'notty-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 2 || { echo "usage: $0 [notty-output [pqwy-notty-source-output]]" >&2; exit 64; }
if test "$#" -ge 1; then
    notty_out=$1
else
    notty_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts notty)
fi
if test "$#" -eq 2; then
    snapshot_out=$2
else
    snapshot_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts pqwy-notty-source)
fi
for output in "$notty_out" "$snapshot_out"; do
    case "$output" in
        /gnu/store/*) test -d "$output" || fail "missing store output: $output" ;;
        *) fail "expected realized /gnu/store output: $output" ;;
    esac
done
snapshot=$snapshot_out/share/pqwy/projects/notty
test -d "$snapshot" || fail 'missing immutable Notty snapshot'
test -s "$notty_out/lib/ocaml/site-lib/notty/META" || fail 'missing installed Notty META'

# No host profile is sourced. The fresh profile supplies findlib, compiler,
# propagated library dependencies and a real ANSI screen model.
temporary=$(mktemp -d "${TMPDIR:-/tmp}/notty-smoke.XXXXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
profile=$temporary/profile
# Resolve compiler and findlib by binding, not ambiguous exported package names.
cat >"$temporary/manifest.scm" <<'SCM'
(use-modules (guix profiles) (guix packages) (gnu packages)
             (gnu packages ocaml) (tay packages notty))
(packages->manifest
 (append (list notty ocaml-4.14 ocaml-findlib)
         (map specification->package
              '("gcc-toolchain" "python" "python-pyte" "coreutils" "util-linux"))))
SCM
"$guix_bin" package -L "$channel_dir/guix" --no-grafts -p "$profile" \
    --manifest="$temporary/manifest.scm"
for tool in ocamlfind ocamlopt python3 unshare mount timeout env; do
    test -x "$profile/bin/$tool" || fail "fresh profile lacks $tool"
done
artifacts=${NOTTY_SMOKE_ARTIFACTS:-$("$profile/bin/mktemp" -d "${TMPDIR:-/tmp}/notty-artifacts.XXXXXXXX")}
case "$artifacts" in
    /*) ;;
    *) fail 'NOTTY_SMOKE_ARTIFACTS must be absolute' ;;
esac
"$profile/bin/mkdir" -p "$artifacts"
"$profile/bin/python3" -I -B - "$artifacts" "$notty_out" "$snapshot_out" <<'PY'
from pathlib import Path
import stat
import sys

evidence, *outputs = map(Path, sys.argv[1:])
if any(evidence.iterdir()):
    raise SystemExit("Notty evidence directory must be empty: " + str(evidence))
for output in outputs:
    for path in [output, *output.rglob("*")]:
        mode = path.lstat().st_mode
        if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
            raise SystemExit("writable installed store member: " + str(path))
PY
before=$("$guix_bin" hash -S nar "$notty_out") || fail 'cannot hash installed output'
snapshot_before=$("$guix_bin" hash -S nar "$snapshot") || fail 'cannot hash snapshot tree'
snapshot_output_before=$("$guix_bin" hash -S nar "$snapshot_out") || fail 'cannot hash snapshot output'
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
printf '%s\n' "$snapshot_before" >"$artifacts/snapshot-nar-before.txt"
printf '%s\n' "$snapshot_output_before" >"$artifacts/snapshot-output-nar-before.txt"
status=0
# Namespace creation must succeed: no fallback to host networking or writable
# store. Host dependency realization above may fetch; compilation/runtime below
# have no network interfaces except unconfigured loopback and a read-only store.
"$profile/bin/env" -i LC_ALL=C PATH="$profile/bin" \
    HOST_NET_NS="$("$profile/bin/readlink" /proc/self/ns/net)" \
    "$profile/bin/timeout" --kill-after=10 180 \
    "$profile/bin/unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$profile/bin/python3" -I -B "$channel_dir/tests/notty-smoke.py" \
    "$profile" "$notty_out" "$profile/bin/mount" \
    "$channel_dir/tests/notty-smoke.ml" "$artifacts" \
    >"$artifacts/proof.log" 2>&1 || status=$?
# Always hash after a failed proof too; a runtime assertion cannot hide a write.
after=$("$guix_bin" hash -S nar "$notty_out") || fail 'cannot hash installed output after proof'
snapshot_after=$("$guix_bin" hash -S nar "$snapshot") || fail 'cannot hash snapshot tree after proof'
snapshot_output_after=$("$guix_bin" hash -S nar "$snapshot_out") || fail 'cannot hash snapshot output after proof'
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
printf '%s\n' "$snapshot_after" >"$artifacts/snapshot-nar-after.txt"
printf '%s\n' "$snapshot_output_after" >"$artifacts/snapshot-output-nar-after.txt"
"$profile/bin/cat" "$artifacts/proof.log"
test "$before" = "$after" || fail "installed output NAR changed; evidence: $artifacts"
test "$snapshot_before" = "$snapshot_after" || fail "snapshot tree NAR changed; evidence: $artifacts"
test "$snapshot_output_before" = "$snapshot_output_after" || fail "snapshot output NAR changed; evidence: $artifacts"
test "$status" -eq 0 || fail "isolated PTY proof exited with status $status; evidence: $artifacts"
"$profile/bin/python3" -I -B - "$artifacts" "$before" "$snapshot_before" "$snapshot_output_before" <<'PY'
import json
from pathlib import Path
import sys

evidence = Path(sys.argv[1])
report = json.loads((evidence / "report.json").read_text())
report["immutable_nar"] = dict(zip(("notty_output", "snapshot_tree", "snapshot_output"), sys.argv[2:]))
report["nar_unchanged"] = True
(evidence / "report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
for backend in ("unix", "lwt"):
    if not (evidence / (backend + ".raw")).stat().st_size:
        raise SystemExit("missing actual PTY raw capture: " + backend)
PY
printf '%s\n' "Notty installed core/Unix/Lwt consumer, offline PTY and unchanged snapshot NAR passed; evidence: $artifacts"
