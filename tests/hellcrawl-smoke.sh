#!/bin/sh
# Installed Hellcrawl consumer, native dungeon/save/reload PTY and immutable NAR.
# Usage: sh tests/hellcrawl-smoke.sh [hellcrawl-output]
# HELLCRAWL_SMOKE_ARTIFACTS selects a new/empty absolute evidence directory.
set -eu
fail() { printf 'hellcrawl-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 1 || { echo "usage: $0 [hellcrawl-output]" >&2; exit 64; }
if test "$#" -eq 1; then hellcrawl_out=$1
else hellcrawl_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts hellcrawl); fi
case "$hellcrawl_out" in
    /gnu/store/*) test -d "$hellcrawl_out" || fail "missing store output: $hellcrawl_out" ;;
    *) fail "expected realized /gnu/store output: $hellcrawl_out" ;;
esac

test -x "$hellcrawl_out/bin/hellcrawl" || fail 'missing installed launcher'
test -x "$hellcrawl_out/libexec/hellcrawl" || fail 'missing installed game'
test ! -e "$hellcrawl_out/libexec/hellcrawl-smoke-pty" || fail 'obsolete PTY helper remains installed'
test ! -L "$hellcrawl_out/libexec/hellcrawl-smoke-pty" || fail 'obsolete PTY helper symlink remains installed'
test -d "$hellcrawl_out/share/hellcrawl/dat" || fail 'missing terminal data'
test ! -e "$hellcrawl_out/share/hellcrawl/dat/tiles" || fail 'tiles remain installed'
test ! -e "$hellcrawl_out/share/hellcrawl/webserver" || fail 'webserver remains installed'

# Preserve the root license and all compatible installed third-party notices.
doc=$hellcrawl_out/share/doc/hellcrawl
test -s "$doc/licence.txt" || fail 'missing root license'
test -s "$doc/CREDITS.txt" || fail 'missing credits'
for notice in cc0.txt lgpl.txt libpng-LICENSE.txt lualicense.txt \
              pcre_license.txt worley.txt license.txt; do
    test -s "$doc/license/$notice" || fail "missing license notice: $notice"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/licence.txt" >/dev/null
grep -F 'Dungeon Crawl Stone Soup team' "$doc/CREDITS.txt" >/dev/null
grep -F 'CC0 1.0 Universal' "$doc/license/cc0.txt" >/dev/null
grep -F 'GNU LESSER GENERAL PUBLIC LICENSE' "$doc/license/lgpl.txt" >/dev/null
grep -F 'Lua is licensed under the terms of the MIT license reproduced below' \
    "$doc/license/lualicense.txt" >/dev/null
grep -F 'PCRE LICENCE' "$doc/license/pcre_license.txt" >/dev/null

# Realize every runtime dependency before entering isolation. No installed user
# profile or cache is consulted by the native PTY driver.
temporary=$(mktemp -d "${TMPDIR:-/tmp}/hellcrawl-smoke.XXXXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
profile=$temporary/profile
"$guix_bin" package --no-grafts -p "$profile" \
    -i python python-pyte coreutils util-linux
for tool in python3 unshare mount timeout env readlink mkdir mktemp cat; do
    test -x "$profile/bin/$tool" || fail "fresh profile lacks $tool"
done
set -- "$profile"/lib/python3.*/site-packages
test "$#" -eq 1 && test -d "$1" || fail 'fresh profile lacks one Python module directory'
python_path=$1
artifacts=${HELLCRAWL_SMOKE_ARTIFACTS:-$("$profile/bin/mktemp" -d "${TMPDIR:-/tmp}/hellcrawl-artifacts.XXXXXXXX")}
case "$artifacts" in /*) ;; *) fail 'HELLCRAWL_SMOKE_ARTIFACTS must be absolute' ;; esac
"$profile/bin/mkdir" -p "$artifacts"
"$profile/bin/python3" -I -B - "$artifacts" <<'PY'
from pathlib import Path
import sys

evidence = Path(sys.argv[1])
if any(evidence.iterdir()):
    raise SystemExit("Hellcrawl evidence directory must be empty: " + str(evidence))
PY
check_immutable()
{
    "$profile/bin/python3" -I -B - "$hellcrawl_out" <<'PY'
from pathlib import Path
import stat
import sys

output = Path(sys.argv[1])
for path in [output, *output.rglob("*")]:
    mode = path.lstat().st_mode
    if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
        raise SystemExit("writable installed store member: " + str(path))
PY
}
check_immutable
before=$("$guix_bin" hash -S nar "$hellcrawl_out") || fail 'cannot hash installed output'
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
status=0
# The driver verifies the network namespace and remounts /gnu/store read-only.
# It creates fresh HOME/XDG state and drives the ordinary installed game.
"$profile/bin/env" -i LC_ALL=C TERM=xterm-256color PATH="$profile/bin" \
    GUIX_PYTHONPATH="$python_path" \
    HOST_NET_NS="$("$profile/bin/readlink" /proc/self/ns/net)" \
    "$profile/bin/timeout" --kill-after=10 120 \
    "$profile/bin/unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$profile/bin/python3" -I -B "$channel_dir/tests/hellcrawl-smoke.py" \
    "$profile" "$hellcrawl_out" "$artifacts" \
    >"$artifacts/proof.log" 2>&1 || status=$?
# Print retained diagnostics even if hashing, mode validation or the proof fails.
"$profile/bin/cat" "$artifacts/proof.log"
after=$("$guix_bin" hash -S nar "$hellcrawl_out") || fail "cannot hash installed output after proof; evidence: $artifacts"
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
test "$before" = "$after" || fail "installed output NAR changed; evidence: $artifacts"
check_immutable || fail "installed output modes changed; evidence: $artifacts"
test "$status" -eq 0 || fail "isolated PTY proof exited with status $status; evidence: $artifacts"
"$profile/bin/python3" -I -B - "$artifacts" "$after" <<'PY'
import json
from pathlib import Path
import sys

evidence = Path(sys.argv[1])
report = json.loads((evidence / "report.json").read_text())
report["immutable_nar"] = {"hellcrawl_output": sys.argv[2]}
report["nar_unchanged"] = True
for filename in ("new-game.raw", "reload.raw"):
    if not (evidence / filename).stat().st_size:
        raise SystemExit("missing actual PTY raw capture: " + filename)
(evidence / "report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
PY
printf '%s\n' "Hellcrawl native dungeon/save/reload PTY and unchanged NAR passed; NAR: $after; evidence: $artifacts"
