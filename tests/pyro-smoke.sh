#!/bin/sh
# Drive only the public launcher and its real curses UI; never an installed proof hook.
set -eu

fail() { printf 'pyro-smoke: %s\n' "$*" >&2; exit 1; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test "$#" -le 1 || { echo "usage: $0 [pyro-output]" >&2; exit 64; }
if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts pyro)
fi
case "$game_out" in
    /gnu/store/*) ;;
    *) fail 'Pyro output must be a realized /gnu/store path' ;;
esac

# Packages can have multiple outputs. Select the one containing the actual
# executable/module instead of assuming output order or a Python minor version.
find_output()
{
    outputs=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts "$2") || return
    for output in $outputs; do
        if test -x "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    fail "could not find $1 in Guix package $2"
}
find_site()
{
    outputs=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts "$1") || return
    for output in $outputs; do
        for module in "$output"/lib/python*/site-packages/"$2"/__init__.py; do
            if test -f "$module"; then
                site=${module%/*}
                printf '%s\n' "${site%/*}"
                return 0
            fi
        done
    done
    fail "could not find $2 site-packages in Guix package $1"
}
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
pyte_site=$(find_site python-pyte pyte)
wcwidth_site=$(find_site python-wcwidth wcwidth)
mount=$util_linux_out/bin/mount
test -x "$mount" || fail 'Guix util-linux output lacks mount'
test -x "$game_out/bin/pyro" || fail 'missing public launcher'

# A selected evidence directory must be new or empty. Never mix two proofs or
# overwrite old captures. All scratch HOME/XDG directories are made by the helper.
artifacts=${PYRO_SMOKE_ARTIFACTS:-$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/pyro-artifacts.XXXXXXXX")}
case "$artifacts" in
    /*) ;;
    *) fail 'PYRO_SMOKE_ARTIFACTS must be absolute' ;;
esac
"$coreutils_out/bin/mkdir" -p "$artifacts"
"$python_out/bin/python3" -I -B - "$game_out" "$artifacts" <<'PY'
import os
from pathlib import Path
import stat
import sys

out, evidence = map(Path, sys.argv[1:])
if any(evidence.iterdir()):
    raise SystemExit("Pyro evidence directory must be empty: " + str(evidence))
root = out / "libexec/pyro"
members = """astar.py creatures.py dungeon_gen.py dungeons.py fov.py install.nsi
io_curses.py items.py player.py professions.py pyro-license.txt pyro.py races.py
readme.txt setup.py util.py""".split()
if sorted(path.name for path in root.iterdir()) != sorted(members):
    raise SystemExit("installed source tree does not contain exactly the original 16 members")
for name in members:
    path = root / name
    if not path.is_file() or path.is_symlink() or not path.stat().st_size:
        raise SystemExit("missing original source member: " + name)
license_text = (root / "pyro-license.txt").read_text()
for notice in ("Copyright (c) 2006 Eric Burgess", "Permission is hereby granted, free of charge",
               'THE SOFTWARE IS PROVIDED "AS IS"'):
    if notice not in license_text:
        raise SystemExit("missing Pyro MIT notice: " + notice)
if "MIT open source license" not in (root / "readme.txt").read_text():
    raise SystemExit("missing upstream licensing statement")
installer = (root / "install.nsi").read_text()
for notice in ("Written by Philip Chu", "Copyright (c) 2004-2005 Technicat, LLC",
               "This notice may not be removed or altered from any source distribution"):
    if notice not in installer:
        raise SystemExit("missing retained installer license: " + notice)
for name in ("pyro-license.txt", "readme.txt"):
    document = out / "share/doc/pyro" / name
    if not document.is_file() or document.read_bytes() != (root / name).read_bytes():
        raise SystemExit("missing or altered installed documentation: " + name)
for path in [out, *out.rglob("*")]:
    mode = path.lstat().st_mode
    if (stat.S_ISREG(mode) or stat.S_ISDIR(mode)) and mode & 0o222:
        raise SystemExit("writable installed file/directory: " + str(path))
    if "smoke" in path.name.lower() or "proof" in path.name.lower():
        raise SystemExit("installed proof helper: " + str(path))
    if path.suffix.lower() in (".exe", ".dll", ".pyd", ".zip", ".pyc", ".pyo"):
        raise SystemExit("unexpected bundled binary/archive/bytecode: " + str(path))
print("complete original source and license notices retained; no installed proof helper; modes read-only")
PY

before=$("$guix_bin" hash -S nar "$game_out") || fail 'cannot hash output before play'
printf '%s\n' "$before" >"$artifacts/output-nar-before.txt"
status=0
# timeout is outside unshare, and --kill-child bounds the whole isolated PTY run.
# A private read-only bind mount enforces store immutability even as namespace root.
"$coreutils_out/bin/env" -i LC_ALL=C PATH="$coreutils_out/bin" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    "$coreutils_out/bin/timeout" --kill-after=10 240 \
    "$util_linux_out/bin/unshare" --user --map-root-user --mount --propagation private \
    --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" -I -B - "$game_out" "$artifacts" "$mount" \
    "$channel_dir/tests/pyro-smoke.py" "$pyte_site" "$wcwidth_site" \
    >"$artifacts/proof.log" 2>&1 <<'PY' || status=$?
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys

out, evidence, mount, helper, pyte_site, wcwidth_site = sys.argv[1:]
subprocess.run([mount, "--bind", out, out], check=True)
subprocess.run([mount, "-o", "remount,bind,ro", out], check=True)
readonly = bool(os.statvfs(out).f_flag & os.ST_RDONLY)
network = os.readlink("/proc/self/ns/net")
if not readonly:
    raise SystemExit("Pyro output mount is not read-only")
if network == os.environ["HOST_NET_NS"]:
    raise SystemExit("Pyro proof is not in a separate network namespace")
interfaces = [line.split(":", 1)[0].strip() for line in Path("/proc/net/dev").read_text().splitlines()
              if ":" in line]
if any(name != "lo" for name in interfaces):
    raise SystemExit("isolated network namespace has a non-loopback interface")
Path(evidence, "isolation.json").write_text(json.dumps({
    "output_mount_read_only": readonly, "network_namespace": network,
    "host_network_namespace": os.environ["HOST_NET_NS"], "interfaces": interfaces,
}, indent=2) + "\n")
sys.argv = [helper, str(Path(out, "bin/pyro")), evidence, pyte_site, wcwidth_site]
runpy.run_path(helper, run_name="__main__")
PY
# Hash even after timeout/assertion failure, so failed gameplay cannot hide writes.
after=$("$guix_bin" hash -S nar "$game_out") || fail 'cannot hash output after play'
printf '%s\n' "$after" >"$artifacts/output-nar-after.txt"
"$coreutils_out/bin/cat" "$artifacts/proof.log"
test "$before" = "$after" || fail "output NAR changed; evidence: $artifacts"
test "$status" -eq 0 || fail "isolated PTY proof exited with status $status; evidence: $artifacts"
for capture in issue-713.raw issue-477.raw session-1.raw session-2.raw; do
    test -s "$artifacts/$capture" || fail "missing raw capture $capture; evidence: $artifacts"
done
printf '%s\n' "Pyro real movement/native log rewrite, offline namespace, read-only store and unchanged NAR proof passed; evidence: $artifacts"
