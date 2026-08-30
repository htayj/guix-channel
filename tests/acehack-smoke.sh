#!/bin/sh
# Exercise AceHack in an empty HOME/XDG tree and a network-less namespace.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 2; then
    echo "usage: $0 [acehack-output [python-output]]" >&2
    exit 64
fi

if test "$#" -ge 1; then
    acehack_out=$1
else
    # The program under test must come from this channel's source build, not
    # a substitute whose provenance could hide a packaging regression.
    acehack_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes acehack)
fi

if test "$#" -eq 2; then
    python_out=$2
else
    python_out=
    for candidate in $($guix_bin build python); do
        if test -x "$candidate/bin/python3"; then
            python_out=$candidate
            break
        fi
    done
    test -n "$python_out"
fi

unshare_out=
for candidate in $($guix_bin build util-linux); do
    if test -x "$candidate/bin/unshare"; then
        unshare_out=$candidate
        break
    fi
done
test -n "$unshare_out"

# No network namespace is inherited by the actual package process.  A tty game
# needs no loopback device, so none is brought up here.
if test "${ACEHACK_SMOKE_IN_NETNS:-}" != 1; then
    if ! "$unshare_out/bin/unshare" --user --map-root-user --net --fork true; then
        echo "acehack-smoke: user and network namespaces are required" >&2
        exit 1
    fi
    exec env ACEHACK_SMOKE_IN_NETNS=1 GUIX="$guix_bin" \
        "$unshare_out/bin/unshare" --user --map-root-user --net --fork \
        "$0" "$acehack_out" "$python_out"
fi

test -x "$acehack_out/bin/acehack"
test -x "$acehack_out/libexec/acehack"
test -s "$acehack_out/share/acehack/nhdat"
test -s "$acehack_out/share/doc/acehack/license"
test -s "$acehack_out/share/doc/acehack/README"
test -s "$acehack_out/share/doc/acehack/Guidebook.txt"
test -s "$acehack_out/share/doc/acehack/fixes36.0"
grep -F 'NETHACK GENERAL PUBLIC LICENSE' "$acehack_out/share/doc/acehack/license" >/dev/null
grep -F 'AceHack 3.6.0' "$acehack_out/share/doc/acehack/README" >/dev/null
grep -F 'contributors to AceHack' "$acehack_out/share/doc/acehack/README" >/dev/null
grep -F 'also expect that you will follow it' "$acehack_out/share/doc/acehack/README" >/dev/null

"$python_out/bin/python3" - "$channel_dir" "$acehack_out" <<'PY'
import hashlib
import json
import os
import pathlib
import sys
import tempfile


channel, output = map(pathlib.Path, sys.argv[1:])
launcher = output / "bin" / "acehack"


def snapshot(root):
    entries = []
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        entries.append((str(path.relative_to(root)), status.st_mode, status.st_size, digest))
    return entries


contract = json.loads((channel / ".goocastle/runtime-evidence-contracts.json").read_text())
matching = [entry for entry in contract["contracts"] if entry["issueNumber"] == 650]
assert matching == [{
    "issueNumber": 650,
    "packageName": "acehack",
    "artifactPath": ".goocastle/evidence/issue-650.png",
    "runtime": {
        "executable": "acehack",
        "invocation": {"file": "acehack", "args": ["-s", "-v", "all"]},
        "successMarker": "Cannot find any entries for all",
    },
}], matching

before = snapshot(output)
for path in [output] + list(output.rglob("*")):
    assert not path.lstat().st_mode & 0o222, path

with tempfile.TemporaryDirectory(prefix="acehack-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    caller = temporary / "empty-caller"
    caller.mkdir()

    def environment(root):
        root.mkdir()
        paths = {name: root / name for name in ("home", "config", "cache", "data", "state", "runtime")}
        for path in paths.values():
            path.mkdir()
        os.chmod(paths["runtime"], 0o700)
        return {
            "HOME": str(paths["home"]), "XDG_CONFIG_HOME": str(paths["config"]),
            "XDG_CACHE_HOME": str(paths["cache"]), "XDG_DATA_HOME": str(paths["data"]),
            "XDG_STATE_HOME": str(paths["state"]), "XDG_RUNTIME_DIR": str(paths["runtime"]),
            "PATH": str(output / "bin"), "TERM": "xterm-256color", "LC_ALL": "C",
        }, paths

    # This exact contract invocation executes the installed AceHack binary and
    # renders its score-screen UI.  With an otherwise empty score file its
    # stdout marker is deterministic, avoiding an unbounded pseudo-terminal
    # gameplay script while still proving an end-user program invocation.
    score_environment, score_paths = environment(temporary / "score")
    import subprocess
    result = subprocess.run([str(launcher), "-s", "-v", "all"], cwd=caller,
                            env=score_environment, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=10, check=True)
    score_lines = [line for line in result.stdout.splitlines() if line]
    assert score_lines.count("Cannot find any entries for all") == 1, result.stdout
    assert (score_paths["data"] / "acehack").is_dir()

    assert not any(caller.iterdir()), list(caller.iterdir())
    for name in ("home", "config", "cache", "state", "runtime"):
        assert not any(score_paths[name].iterdir()), (name, list(score_paths[name].iterdir()))

assert snapshot(output) == before, "package output changed during smoke"
PY
