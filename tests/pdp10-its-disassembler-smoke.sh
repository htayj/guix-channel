#!/bin/sh
# Offline smoke test for the installed PDP-10 ITS disassembler utilities.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [pdp10-its-disassembler-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes \
        pdp10-its-disassembler)
fi

python_out=
for candidate in $($guix_bin build --no-grafts --no-substitutes python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"

"$python_out/bin/python3" - "$package_out" <<'PY'
import hashlib
import os
import pathlib
import subprocess
import sys
import tempfile


out = pathlib.Path(sys.argv[1])
programs = (
    "dis10", "acct", "calcomp", "cat36", "classify-tape", "constantinople",
    "cross", "dart", "decdmp", "dskdmp", "dump", "dumper", "failsafe",
    "harscntopbm", "ipak", "itsarc", "kldcp", "klfedr", "linum", "macdmp",
    "macro-tapes", "magdmp", "magfrm", "mini-dumper", "od10", "old-cpio",
    "palx", "plt", "scrmbl", "tape-dir", "tendmp", "tito", "tvpic", "unscr",
)


def tree_digest(root):
    """Return a metadata-and-content digest for immutable-output checking."""
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest.update(str(path.relative_to(root)).encode("utf-8"))
        digest.update(repr((status.st_mode, status.st_uid, status.st_gid,
                            status.st_size, status.st_mtime_ns,
                            status.st_ctime_ns)).encode("ascii"))
        if path.is_symlink():
            digest.update(os.readlink(path).encode("utf-8"))
        elif path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


for program in programs:
    executable = out / "bin" / program
    assert executable.is_file() and os.access(executable, os.X_OK), executable

doc = out / "share" / "doc" / "pdp10-its-disassembler"
for document in ("README", "README.md", "COPYING", "tito.doc", "LODEPNG-LICENSE"):
    assert (doc / document).is_file() and (doc / document).stat().st_size, document
assert "GNU GENERAL PUBLIC LICENSE\n\t\t       Version 2" in (doc / "COPYING").read_text(
    encoding="utf-8")
lodepng_license = (doc / "LODEPNG-LICENSE").read_text(encoding="utf-8")
assert "including commercial applications" in lodepng_license
assert "alter it and redistribute it" in lodepng_license
assert "freely, subject to the following restrictions" in lodepng_license

before = tree_digest(out)
with tempfile.TemporaryDirectory(prefix="pdp10-its-disassembler-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home, config, cache, data, state, runtime, work = [root / name for name in
        ("home", "config", "cache", "data", "state", "runtime", "work")]
    for directory in (home, config, cache, data, state, runtime, work):
        directory.mkdir()
    runtime.chmod(0o700)
    environment = {
        "HOME": str(home), "XDG_CONFIG_HOME": str(config),
        "XDG_CACHE_HOME": str(cache), "XDG_DATA_HOME": str(data),
        "XDG_STATE_HOME": str(state), "XDG_RUNTIME_DIR": str(runtime),
        "LC_ALL": "C.UTF-8", "PATH": "",
    }

    # Two 36-bit words in the documented 36/8 binary representation: zero
    # and SETZ 0,.  The fixture is entirely local, and -r selects raw input,
    # so dis10 neither accesses devices nor needs mutable runtime data.
    fixture = work / "two-words.bin"
    fixture.write_bytes(bytes((0, 0, 0, 0, 8, 0, 0, 0, 0)))
    result = subprocess.run([out / "bin" / "dis10", "-r", "-Wbin", fixture],
                            env=environment, cwd=work, stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            check=True, text=True)
    assert "Raw format" in result.stdout
    assert "000000:  000000000000" in result.stdout
    assert "000001:  400000000000  setz" in result.stdout

    # The two compatibility names select behavior from argv[0].  Their own
    # usage text proves both installed executable names are independently
    # invocable without a wrapper or a shared mutable runtime directory.
    for program in ("tito", "failsafe", "dumper", "mini-dumper"):
        result = subprocess.run([out / "bin" / program], env=environment,
                                cwd=work, stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True)
        assert result.returncode != 0
        assert f"Usage: {out / 'bin' / program}" in result.stderr

assert tree_digest(out) == before, "the immutable package output changed"
print("pdp10-its-disassembler offline smoke passed")
PY
