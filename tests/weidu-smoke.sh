#!/bin/sh
# Exercise WeiDU's installed offline TP2 workflow without host state/network.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [weidu-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    weidu_out=$1
else
    weidu_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes weidu)
fi

find_program_output() {
    program=$1
    shift
    for candidate in $($guix_bin build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

python_out=$(find_program_output bin/python3 python)
util_linux_out=$(find_program_output bin/unshare util-linux)

test -x "$weidu_out/bin/weidu"
test -s "$weidu_out/share/doc/weidu/COPYING"
test -s "$weidu_out/share/doc/weidu/README.md"
test -s "$weidu_out/share/doc/weidu/third-party-notices/license.txt"

# A private user/network namespace prevents WeiDU (and any optional action it
# could reach) from using the host network.  The fixture itself is entirely
# local and all mutable HOME/XDG/CWD paths are beneath one temporary directory.
exec "$util_linux_out/bin/unshare" --user --map-root-user --net --mount --fork \
    "$python_out/bin/python3" - "$weidu_out" "$util_linux_out/bin/mount" <<'PY'
import hashlib
import os
import pathlib
import subprocess
import sys
import tempfile


out = pathlib.Path(sys.argv[1])
mount = sys.argv[2]


def output_snapshot(root):
    """Return the complete output file list and each regular-file digest."""
    files = []
    digests = {}
    for path in sorted(root.rglob("*")):
        relative = str(path.relative_to(root))
        if path.is_file():
            files.append(relative)
            digests[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
        elif path.is_symlink():
            files.append(relative)
            digests[relative] = hashlib.sha256(
                os.readlink(path).encode("utf-8")
            ).hexdigest()
    return files, digests


assert (out / "bin" / "weidu").is_file()
doc = out / "share" / "doc" / "weidu"
assert "GNU GENERAL PUBLIC LICENSE" in (doc / "COPYING").read_text()
assert "WeiDU" in (doc / "README.md").read_text()
assert "Regents of the University of California" in (
    doc / "third-party-notices" / "license.txt"
).read_text()

before_files, before_digests = output_snapshot(out)

# Make mount propagation private before the fixture creates any mutable path,
# then replace /tmp in this namespace.  Along with the fresh HOME/XDG paths
# and working directory below, this confines all normal WeiDU logs, backups,
# and generated files to this mount namespace.
subprocess.run([mount, "--make-rprivate", "/"], check=True)
subprocess.run(
    [mount, "-t", "tmpfs", "-o", "mode=1777", "tmpfs", "/tmp"], check=True
)

with tempfile.TemporaryDirectory(prefix="weidu-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home, config, cache, data, tmp, work = [root / name for name in
                                            ("home", "config", "cache", "data",
                                             "tmp", "work")]
    for directory in (home, config, cache, data, tmp, work):
        directory.mkdir()
    environment = {
        "HOME": str(home),
        "XDG_CONFIG_HOME": str(config),
        "XDG_CACHE_HOME": str(cache),
        "XDG_DATA_HOME": str(data),
        "TMPDIR": str(tmp),
        "LC_ALL": "C",
        "PATH": "",
    }

    # /tmp is a fresh mount, so any path appearing there outside ROOT after
    # this snapshot is a write that escaped the fixture directory.  Capture
    # the isolated user-state directories separately so unexpected XDG/HOME
    # writes are also detected instead of being hidden by the broad ROOT
    # snapshot.
    temporary_before = set(pathlib.Path("/tmp").rglob("*"))
    state_before = {
        directory: output_snapshot(directory)
        for directory in (home, config, cache, data)
    }

    def run(arguments):
        return subprocess.run(
            [str(out / "bin" / "weidu"), *arguments],
            cwd=work,
            env=environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
            timeout=30,
        )

    help_result = run(["--help"])
    assert help_result.returncode == 0, help_result.stdout
    assert "WeiDU" in help_result.stdout, help_result.stdout

    licence_result = run(["--licence"])
    assert licence_result.returncode == 0, licence_result.stdout
    assert "GNU General Public licence" in licence_result.stdout, licence_result.stdout
    assert "fcaseopen by Keith Bauer" in licence_result.stdout, licence_result.stdout

    (work / "input.txt").write_text("Guix offline copy fixture\n", encoding="utf-8")
    (work / "fixture.tp2").write_text(
        "BACKUP ~backup~\n"
        "AUTHOR ~Guix smoke~\n"
        "BEGIN ~offline copy~\n"
        "COPY ~input.txt~ ~output.txt~\n",
        encoding="utf-8",
    )
    install_result = run([
        "--nogame", "--noautoupdate", "--no-exit-pause", "--yes",
        "--force-install", "0", "fixture.tp2",
    ])
    assert install_result.returncode == 0, install_result.stdout
    assert (work / "output.txt").read_bytes() == (work / "input.txt").read_bytes()

    temporary_after = set(pathlib.Path("/tmp").rglob("*"))
    escaped = sorted(
        str(path) for path in temporary_after - temporary_before
        if not path.is_relative_to(root)
    )
    assert not escaped, escaped
    for directory, snapshot in state_before.items():
        assert output_snapshot(directory) == snapshot, directory

after_files, after_digests = output_snapshot(out)
assert before_files == after_files, (before_files, after_files)
assert before_digests == after_digests, (before_digests, after_digests)

print("weidu offline smoke passed: isolated XDG state, notices, and TP2 copy")
PY
