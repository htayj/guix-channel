#!/bin/sh
# Installed pmatiello/tui consumer, actual cooked-input PTY and immutable NAR.
# Usage: sh tests/tui-smoke.sh [tui-output [pmatiello-tui-source-output]]
# TUI_SMOKE_ARTIFACTS selects a new/empty absolute evidence directory.
set -eu
fail() { printf 'tui-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 2 || { echo "usage: $0 [tui-output [pmatiello-tui-source-output]]" >&2; exit 64; }
if test "$#" -ge 1; then tui_out=$1
else tui_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts tui); fi
if test "$#" -eq 2; then snapshot_out=$2
else snapshot_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts pmatiello-tui-source); fi
for output in "$tui_out" "$snapshot_out"; do
    case "$output" in
        /gnu/store/*) test -d "$output" || fail "missing store output: $output" ;;
        *) fail "expected realized /gnu/store output: $output" ;;
    esac
done
snapshot=$snapshot_out/share/pmatiello/projects/tui
test -d "$snapshot" || fail 'missing immutable Tui snapshot'
test -s "$tui_out/share/java/tui.jar" || fail 'missing installed Tui jar'
test -x "$tui_out/bin/tui-clojure" || fail 'missing offline consumer launcher'

# Dependency realization happens before isolation. No installed user profile,
# Maven cache, Clojars repository or Clojure tools CLI is consulted at runtime.
temporary=$(mktemp -d "${TMPDIR:-/tmp}/tui-smoke.XXXXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
profile=$temporary/profile
"$guix_bin" package --no-grafts -p "$profile" \
    -i python python-pyte coreutils util-linux
for tool in python3 unshare mount timeout env; do
    test -x "$profile/bin/$tool" || fail "fresh profile lacks $tool"
done
artifacts=${TUI_SMOKE_ARTIFACTS:-$("$profile/bin/mktemp" -d "${TMPDIR:-/tmp}/tui-artifacts.XXXXXXXX")}
case "$artifacts" in /*) ;; *) fail 'TUI_SMOKE_ARTIFACTS must be absolute' ;; esac
"$profile/bin/mkdir" -p "$artifacts"
"$profile/bin/python3" -I -B - "$artifacts" "$tui_out" "$snapshot_out" <<'PY'
from pathlib import Path
import stat
import sys

evidence, *outputs = map(Path, sys.argv[1:])
if any(evidence.iterdir()):
    raise SystemExit("Tui evidence directory must be empty: " + str(evidence))
for output in outputs:
    for path in [output, *output.rglob("*")]:
        mode = path.lstat().st_mode
        if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
            raise SystemExit("writable installed store member: " + str(path))
PY
before=$("$guix_bin" hash -S nar "$tui_out") || fail 'cannot hash installed output'
snapshot_before=$("$guix_bin" hash -S nar "$snapshot") || fail 'cannot hash snapshot tree'
snapshot_output_before=$("$guix_bin" hash -S nar "$snapshot_out") || fail 'cannot hash snapshot output'
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
printf '%s\n' "$snapshot_before" >"$artifacts/snapshot-nar-before.txt"
printf '%s\n' "$snapshot_output_before" >"$artifacts/snapshot-output-nar-before.txt"
status=0
# Namespace failure is fatal. Runtime has a read-only store and no external
# network interfaces, a private PID/mount namespace and fresh HOME/XDG state.
"$profile/bin/env" -i LC_ALL=C PATH="$profile/bin" \
    HOST_NET_NS="$("$profile/bin/readlink" /proc/self/ns/net)" \
    "$profile/bin/timeout" --kill-after=10 180 \
    "$profile/bin/unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$profile/bin/python3" -I -B "$channel_dir/tests/tui-smoke.py" \
    "$profile" "$tui_out" "$profile/bin/mount" \
    "$channel_dir/tests/tui-smoke.clj" "$artifacts" "$snapshot_out" \
    >"$artifacts/proof.log" 2>&1 || status=$?
after=$("$guix_bin" hash -S nar "$tui_out") || fail 'cannot hash installed output after proof'
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
report["immutable_nar"] = dict(zip(("tui_output", "snapshot_tree", "snapshot_output"), sys.argv[2:]))
report["nar_unchanged"] = True
(evidence / "report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
for filename in ("tui.raw", "tui-live.raw"):
    if not (evidence / filename).stat().st_size:
        raise SystemExit("missing actual PTY raw capture: " + filename)
PY
printf '%s\n' "Tui installed consumer, upstream tests, offline PTY and unchanged snapshot NAR passed; evidence: $artifacts"
