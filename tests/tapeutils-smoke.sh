#!/bin/sh
# Offline smoke test for the installed tapeutils programs.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [tapeutils-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    tapeutils_out=$1
else
    tapeutils_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes tapeutils)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"

"$python_out/bin/python3" - "$tapeutils_out" <<'PY'
import hashlib
import os
import pathlib
import subprocess
import sys
import tempfile


out = pathlib.Path(sys.argv[1])
programs = ("tapecopy", "tapedump", "taperead", "tapewrite", "t10backup",
            "read20", "tapex")


def tree_digest(root):
    """Return a metadata-and-content digest suitable for immutable output checks."""
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest.update(str(path.relative_to(root)).encode("utf-8"))
        digest.update(status.st_mode.to_bytes(4, "little"))
        if path.is_symlink():
            digest.update(os.readlink(path).encode("utf-8"))
        elif path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


for program in programs:
    executable = out / "bin" / program
    assert executable.is_file() and os.access(executable, os.X_OK), executable
license_file = out / "share" / "doc" / "tapeutils" / "COPYING"
assert "GNU GENERAL PUBLIC LICENSE" in license_file.read_text(encoding="utf-8")

before = tree_digest(out)
with tempfile.TemporaryDirectory(prefix="tapeutils-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home, config, cache, state, work, readback = [root / name for name in
                                                   ("home", "config", "cache", "state", "work", "readback")]
    for directory in (home, config, cache, state, work, readback):
        directory.mkdir()
    environment = {"HOME": str(home), "XDG_CONFIG_HOME": str(config),
                   "XDG_CACHE_HOME": str(cache), "XDG_STATE_HOME": str(state),
                   "LC_ALL": "C.UTF-8", "PATH": ""}

    # A deterministic local (not /dev or remote-colon) pathname exercises the
    # Wilson image path without selecting hardware, rmt, or network behavior.
    payload = work / "payload"
    tape = work / "tape.img"
    payload.write_bytes(bytes(range(256)) * 4)
    assert payload.stat().st_size == 1024
    subprocess.run([out / "bin" / "tapewrite", tape, payload], env=environment,
                   check=True, cwd=work, stdin=subprocess.DEVNULL,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert tape.stat().st_size == 1040, tape.stat().st_size

    dump = subprocess.run([out / "bin" / "tapedump", tape], env=environment,
                          check=True, cwd=work, stdin=subprocess.DEVNULL,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True).stdout.lower()
    assert "file 0 record 0: length 1024" in dump, dump
    assert "end of tape" in dump, dump

    # Taperead writes file0000 in its current directory.  Keeping that
    # directory empty beforehand proves both the installed behavior and that
    # no caller or host state is needed.
    subprocess.run([out / "bin" / "taperead", tape], env=environment,
                   check=True, cwd=readback, stdin=subprocess.DEVNULL,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert (readback / "file0000").read_bytes() == payload.read_bytes()

assert tree_digest(out) == before, "the immutable package output changed"
print("tapeutils offline smoke passed")
PY
