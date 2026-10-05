#!/bin/sh
# Consume an already-built WeiDU output; retain native offline TP2 copy evidence
# and exercise the pinned upstream source's game-free test fixtures.
# No game installation, WeiDU build, installed test mode, or root UID mapping.
set -eu

if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE_DIR (new or empty, outside /gnu/store)" >&2
    exit 64
fi

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
find_output ()
{
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
                        --no-offload --cores=1 --max-jobs=1 --keep-failed "$2"); do
        if test -x "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
weidu_out=$(realpath -e -- "$1")
evidence_dir=$(realpath -m -- "$2")
case "$evidence_dir/" in
    /gnu/store/*|"$weidu_out/"*)
        echo 'evidence must be outside the store and package output' >&2
        exit 64 ;;
esac
if test -e "$evidence_dir"; then
    test -d "$evidence_dir"
    test -z "$(find "$evidence_dir" -mindepth 1 -maxdepth 1 -print -quit)"
fi
mkdir -p -- "$evidence_dir"
coreutils_out=$(find_output bin/env coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python)
mount=$util_linux_out/bin/mount
unshare=$util_linux_out/bin/unshare

# Source-resolve the pinned upstream test tree before isolation; the driver
# never invokes guix.  The snapshot package installs the exact codeload
# archive of the packaged commit under share/WeiDUorg/projects/weidu.
source_out=
for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
                    --no-offload --cores=1 --max-jobs=1 --keep-failed \
                    weiduorg-weidu-source); do
    if test -f "$output/share/WeiDUorg/projects/weidu/test/traify/run_tests.pl"; then
        source_out=$output
        break
    fi
done
if test -z "$source_out"; then
    echo 'could not find the pinned WeiDU source test tree' >&2
    exit 1
fi
test_tree=$(realpath -e -- "$source_out/share/WeiDUorg/projects/weidu/test")

# Resolve every store path and NAR hash before entering the namespaces; the
# isolated driver never invokes guix.
before=$("$guix_bin" hash -S nar "$weidu_out")
status=0
"$coreutils_out/bin/env" -i \
    LC_ALL=C MOUNT="$mount" \
    HOST_UID="$("$coreutils_out/bin/id" -u)" \
    HOST_GID="$("$coreutils_out/bin/id" -g)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    "$coreutils_out/bin/timeout" --kill-after=10 300 \
    "$unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" - "$weidu_out" "$evidence_dir" "$test_tree" \
    <<'PY' || status=$?
from contextlib import nullcontext
import hashlib
import json
import os
import pathlib
import shutil
import stat
import subprocess
import sys
import struct
import traceback


class ProofError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise ProofError(message)


def json_file(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def interfaces(path):
    return sorted(line.split(":", 1)[0].strip()
                  for line in path.read_text().splitlines()[2:] if ":" in line)


def identity(proc):
    status = {}
    for line in (proc / "status").read_text().splitlines():
        key, _, value = line.partition(":")
        if key in ("Uid", "Gid", "Groups"):
            status[key] = [int(part) for part in value.split()]
    expected_uid = int(os.environ["HOST_UID"])
    expected_gid = int(os.environ["HOST_GID"])
    require(status.get("Uid") == [expected_uid] * 4, "process changed caller UID identity")
    require(status.get("Gid") == [expected_gid] * 4, "process changed caller GID identity")
    return status


def namespace_evidence():
    proc = pathlib.Path("/proc/self")
    current = os.readlink(proc / "ns/net")
    host = os.environ.get("HOST_NET_NS")
    require(host and current != host, "consumer is not in a private network namespace")
    devices = interfaces(proc / "net/dev")
    require(devices == ["lo"], "private network must contain only loopback")
    return {"host_network_namespace": host, "network_namespace": current,
            "interfaces": devices, "identity": identity(proc),
            "uid_map": (proc / "uid_map").read_text(),
            "gid_map": (proc / "gid_map").read_text()}


def mount_path(field):
    # mountinfo escapes whitespace and backslashes as octal sequences.
    for escaped, literal in (("\\040", " "), ("\\011", "\t"),
                             ("\\012", "\n"), ("\\134", "\\")):
        field = field.replace(escaped, literal)
    return field


def store_mounts(text):
    mounts = []
    for line in text.splitlines():
        fields = line.split()
        target = mount_path(fields[4])
        if target == "/gnu/store" or target.startswith("/gnu/store/"):
            mounts.append({"target": target, "options": fields[5].split(","),
                           "optional": fields[6:fields.index("-")], "line": line})
    return mounts


def readonly_store(evidence):
    executable = pathlib.Path(os.environ.get("MOUNT", ""))
    require(executable.is_absolute() and os.access(executable, os.X_OK),
            "MOUNT must be the supplied absolute mount executable")
    before = pathlib.Path("/proc/self/mountinfo").read_text()
    (evidence / "mountinfo-before.txt").write_text(before)
    commands = []

    def mount(*args):
        result = subprocess.run([str(executable), *args], capture_output=True,
                                text=True, timeout=15)
        commands.append({"command": [str(executable), *args], "returncode": result.returncode,
                         "stdout": result.stdout, "stderr": result.stderr})
        json_file(evidence / "mount-commands.json", commands)
        require(result.returncode == 0, "cannot protect store: " + result.stderr)

    # The shell already made this mount namespace private.  A recursive bind
    # preserves every nested store mount; each is then remounted read-only.
    mount("--rbind", "/gnu/store", "/gnu/store")
    mount("--make-rprivate", "/gnu/store")
    bound = store_mounts(pathlib.Path("/proc/self/mountinfo").read_text())
    targets = sorted({entry["target"] for entry in bound}, key=len, reverse=True)
    require("/gnu/store" in targets, "recursive store bind mount missing")
    for target in targets:
        mount("-o", "remount,bind,ro", target)
    after = pathlib.Path("/proc/self/mountinfo").read_text()
    (evidence / "mountinfo-after.txt").write_text(after)
    mounts = store_mounts(after)
    require(mounts and all("ro" in entry["options"] and "rw" not in entry["options"]
                           for entry in mounts), "store mount is not recursively read-only")
    require(all(not any(option.startswith(("shared:", "master:"))
                        for option in entry["optional"]) for entry in mounts),
            "store bind mount is not private")
    proof = {"recursive_bind": True, "recursive_readonly": True, "mounts": mounts}
    json_file(evidence / "store.json", proof)
    return proof


def output_snapshot(root):
    """Return the complete file list and each regular-file digest."""
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


def validate_output(output):
    require(os.access(output / "bin" / "weidu", os.X_OK), "normal weidu binary missing")
    doc = output / "share" / "doc" / "weidu"
    proof = {}
    for name in ("COPYING", "README.md", "README-WeiDU-Changes.txt",
                 "third-party-notices/license.txt", "third-party-notices/fcase.c",
                 "third-party-notices/zlib.h", "third-party-notices/xinclude.h",
                 "third-party-notices/batList.ml", "third-party-notices/myhashtbl.ml",
                 "third-party-notices/parsing.ml", "third-party-notices/myarg.ml"):
        path = doc / name
        require(path.is_file() and path.stat().st_size > 0,
                "missing packaged notice: " + name)
        proof["share/doc/weidu/" + name] = {
            "bytes": path.stat().st_size, "sha256": digest(path.read_bytes())}
    require("GNU GENERAL PUBLIC LICENSE" in (doc / "COPYING").read_text(),
            "GPL notice missing")
    require("WeiDU" in (doc / "README.md").read_text(), "README notice missing")
    require("Regents of the University of California" in
            (doc / "third-party-notices" / "license.txt").read_text(),
            "Elkhound upstream notice missing")
    for parent, dirs, files in os.walk(output):
        for name in files:
            path = pathlib.Path(parent) / name
            require(not stat.S_IMODE(path.stat().st_mode) & 0o222,
                    "package file is writable: " + str(path))
    return proof


# WeiDU emits these anchored operational diagnostics from src/*.ml.  Scan
# every invocation, including help and licence, without rejecting prose that
# merely describes error-related options.
def native_error_lines(output):
    return [line for line in output.splitlines()
            if line.lstrip().startswith(("ERROR:", "FATAL ERROR:"))]


# Exact output digests pinned by the packaged commit's own
# test/traify/run_tests.pl (test_traify_nogame, the game-free subtest):
# weidu --nogame --traify test.tp2 must produce these MD5 sums.
TRAIFY_TP2_MD5 = "b9d17b468280c1b15d95a4ee091e033b"
TRAIFY_TRA_MD5 = "7eb0fdcc7f221e4f7437b7b14e692a46"


def main():
    require(len(sys.argv) == 4,
            "usage: weidu-smoke.sh OUTPUT EVIDENCE_DIR TEST_TREE")
    out = pathlib.Path(sys.argv[1]).resolve(strict=True)
    evidence = pathlib.Path(sys.argv[2]).resolve(strict=True)
    tests_root = pathlib.Path(sys.argv[3]).resolve(strict=True)
    require(evidence.is_dir() and not any(evidence.iterdir()),
            "evidence directory must be precreated and empty")
    require(evidence != out and out not in evidence.parents and
            pathlib.Path("/gnu/store") not in evidence.parents,
            "evidence must be outside package output and store")
    foozle_d = tests_root / "no-game" / "make-foozle.d"
    traify_tp2 = tests_root / "traify" / "traify.test.tp2"
    require(foozle_d.is_file() and traify_tp2.is_file(),
            "pinned upstream game-free fixtures missing from source tree")
    try:
        network = namespace_evidence()
        json_file(evidence / "network.json", network)
        store = readonly_store(evidence)
        package = validate_output(out)
        json_file(evidence / "package.json", package)

        # Retain native DEBUG logs, backups and fixture outputs on failure.
        # Do not mount over /tmp: evidence may itself live there.

        commands = evidence / "commands"
        commands.mkdir()
        runs = []

        with nullcontext(evidence / "session") as root:
            root.mkdir(mode=0o700)
            home, config, cache, data, state, tmp, work = [
                root / name for name in ("home", "config", "cache", "data",
                                         "state", "tmp", "work")]
            for directory in (home, config, cache, data, state, tmp, work):
                directory.mkdir()
            environment = {
                "HOME": str(home),
                "XDG_CONFIG_HOME": str(config),
                "XDG_CACHE_HOME": str(cache),
                "XDG_DATA_HOME": str(data),
                "XDG_STATE_HOME": str(state),
                "TMPDIR": str(tmp),
                "LC_ALL": "C",
                "PATH": "",
            }
            json_file(evidence / "environment.json", environment)
            state_before = {
                directory: output_snapshot(directory)
                for directory in (home, config, cache, data, state)
            }

            # myarg.ml usage() reads a newline after every ten options when
            # TERM is not a recognized terminal. Supply pager responses for
            # real --help; do not hide its FATAL ERROR: End_of_file diagnostic.
            def run(label, arguments, cwd=None):
                result = subprocess.run(
                    [str(out / "bin" / "weidu"), *arguments],
                    cwd=cwd or work, env=environment,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    input="\n" * 32 if label == "help" else "",
                    text=True, check=False, timeout=30,
                )
                (commands / (label + ".txt")).write_text(result.stdout)
                errors = native_error_lines(result.stdout)
                runs.append({"label": label, "arguments": arguments,
                             "returncode": result.returncode,
                             "stdin": "32 pager newlines" if label == "help" else "EOF",
                             "native_error_lines": errors})
                json_file(commands / "commands.json", runs)
                require(result.returncode == 0,
                        f"{label} failed with status {result.returncode}: {result.stdout}")
                require(not errors,
                        f"{label} reported a native error with exit status 0: {errors}")
                return result.stdout

            help_text = run("help", ["--help"])
            require("WeiDU" in help_text, "--help does not identify WeiDU")
            licence_text = run("licence", ["--licence"])
            require("GNU General Public licence" in licence_text,
                    "--licence omits the GPL notice")
            require("fcaseopen by Keith Bauer" in licence_text,
                    "--licence omits the bundled fcaseopen notice")

            fixture = evidence / "fixture"
            fixture.mkdir()
            (work / "input.txt").write_text("Guix offline copy fixture\n",
                                            encoding="utf-8")
            (work / "fixture.tp2").write_text(
                "BACKUP ~backup~\n"
                "AUTHOR ~Guix smoke~\n"
                "BEGIN ~offline copy~\n"
                "COPY ~input.txt~ ~output.txt~\n",
                encoding="utf-8",
            )
            run("install", ["--nogame", "--noautoupdate", "--no-exit-pause",
                            "--yes", "--force-install", "0", "fixture.tp2"])
            require((work / "output.txt").read_bytes() ==
                    (work / "input.txt").read_bytes(),
                    "offline TP2 COPY did not reproduce input.txt bytes")
            for name in ("fixture.tp2", "input.txt", "output.txt"):
                (fixture / name).write_bytes((work / name).read_bytes())

            # Upstream game-free fixtures, verbatim from the pinned source
            # tree. Its no-game/make-foozle.d header documents
            # "weidu --nogame make-foozle.d". The native
            # parsewrappers.ml save path uses name ^ ".dlg", so the exact
            # case-sensitive output is FOOZLE.dlg (the log prints .DLG).
            upstream = evidence / "upstream-tests"
            upstream.mkdir()
            foozle = work / "foozle"
            foozle.mkdir()
            shutil.copyfile(foozle_d, foozle / "make-foozle.d")
            run("foozle", ["--nogame", "make-foozle.d"], cwd=foozle)
            foozle_dlg = foozle / "FOOZLE.dlg"
            # Exact source-derived bytes: dparser.mly maps empty IF triggers
            # to none, dc.ml resolves SAY/REPLY strrefs in state order, and
            # dlg.ml emits a 52-byte header, two states, three transitions.
            expected_dlg = b"DLG V1.0" + struct.pack(
                "<11I", 2, 52, 3, 84, 180, 0, 180, 0, 180, 0, 0)
            expected_dlg += struct.pack("<4I", 0, 0, 2, 0xffffffff)
            expected_dlg += struct.pack("<4I", 3, 2, 1, 0xffffffff)
            for flags, reply, destination, state_index in (
                    (9, 1, b"", 0), (1, 2, b"FOOZLE", 1), (9, 4, b"", 0)):
                expected_dlg += struct.pack(
                    "<5I8sI", flags, reply, 0, 0, 0, destination, state_index)
            require(foozle_dlg.read_bytes() == expected_dlg,
                    "FOOZLE.dlg differs from exact source-derived fixture bytes")
            (upstream / "FOOZLE.dlg").write_bytes(foozle_dlg.read_bytes())

            # test/traify/run_tests.pl test_traify_nogame: copy
            # traify.test.tp2 to test.tp2, run "weidu --nogame --traify
            # test.tp2", then compare both files against the script's
            # pinned MD5 sums.  The plain --traify and --traify-old-tra
            # subtests have no documented game-free invocation and are
            # excluded below.
            traify = work / "traify"
            traify.mkdir()
            shutil.copyfile(traify_tp2, traify / "test.tp2")
            run("traify", ["--nogame", "--traify", "test.tp2"], cwd=traify)
            tp2_sum = hashlib.md5((traify / "test.tp2").read_bytes()).hexdigest()
            tra_sum = hashlib.md5((traify / "test.tra").read_bytes()).hexdigest()
            require(tp2_sum == TRAIFY_TP2_MD5,
                    f"--nogame --traify tp2 MD5 {tp2_sum} != pinned "
                    f"{TRAIFY_TP2_MD5}")
            require(tra_sum == TRAIFY_TRA_MD5,
                    f"--nogame --traify tra MD5 {tra_sum} != pinned "
                    f"{TRAIFY_TRA_MD5}")
            for name in ("test.tp2", "test.tra"):
                (upstream / ("traify-" + name)).write_bytes(
                    (traify / name).read_bytes())
            json_file(evidence / "upstream-tests.json", {
                "source_tree": str(tests_root),
                "foozle": {"fixture": "no-game/make-foozle.d",
                           "invocation": ["--nogame", "make-foozle.d"],
                           "output": "FOOZLE.dlg",
                           "exact_source_derived_bytes": True,
                           "bytes": len(expected_dlg),
                           "sha256": digest(foozle_dlg.read_bytes())},
                "traify": {"fixture": "traify/traify.test.tp2",
                           "invocation": ["--nogame", "--traify", "test.tp2"],
                           "pinned_by": "test/traify/run_tests.pl",
                           "test_tp2_md5": tp2_sum, "test_tra_md5": tra_sum,
                           "test_tp2_sha256": digest((traify / "test.tp2").read_bytes()),
                           "test_tra_sha256": digest((traify / "test.tra").read_bytes())},
                "excluded": [
                    "test/auto-test (extracts ~2700 DLG files from a game's "
                    "Dialog.Bif; proprietary Infinity Engine data)",
                    "test/good-syntax and test/bad-syntax (README expects DLG "
                    "generation against game data; no documented game-free "
                    "invocation)",
                    "test/quitch (demonstrates a game state roll-back bug)",
                    "test/tp2/tp2_regression_tests (README: install as a WeiDU "
                    "mod into a game; data/games.tpa enumerates proprietary "
                    "engines)",
                    "traify --traify and --traify-old-tra subtests of "
                    "run_tests.pl (README runs them inside an IE game "
                    "directory; only --nogame --traify is documented "
                    "game-free)"]})

            worktree = {"files": [], "digests": {}}
            for path in sorted(work.rglob("*")):
                if path.is_file():
                    relative = str(path.relative_to(work))
                    worktree["files"].append(relative)
                    worktree["digests"][relative] = digest(path.read_bytes())
            json_file(evidence / "worktree.json", worktree)

            for directory, snapshot in state_before.items():
                require(output_snapshot(directory) == snapshot, str(directory))

        json_file(evidence / "proof.json", {
            "output": str(out), "network": network, "readonly_store": store,
            "package": package, "runs": runs,
            "fixture": {"tp2": "fixture/fixture.tp2", "copied": "fixture/output.txt",
                        "bytes_match_input": True},
            "upstream_game_free_fixtures": {
                "no-game/make-foozle.d": True,
                "traify --nogame --traify pinned MD5s": True},
            "limits": [
                "No Infinity Engine game installation was present or exercised; "
                "the TP2 run targets a synthetic offline COPY fixture only, and "
                "upstream fixtures are limited to the documented game-free "
                "cases (see upstream-tests.json exclusions).",
                "WeiDU's native exit status is asserted together with its "
                "line-anchored ERROR:/FATAL ERROR: diagnostics because the tool "
                "can report failures while exiting 0."]})
        print("WEIDU_OFFLINE_TP2_OK")
    except BaseException:
        (evidence / "failure.txt").write_text(traceback.format_exc())
        raise


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"WeiDU offline proof failed: {error}", file=sys.stderr)
        sys.exit(1)
PY
# Hash the output even on native failures; preserve diagnostics without fallback.
after=$("$guix_bin" hash -S nar "$weidu_out")
printf '%s\n' "$before" > "$evidence_dir/output-before.nar-hash"
printf '%s\n' "$after" > "$evidence_dir/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'package output changed during offline TP2 proof' >&2
    exit 1
fi
if test "$status" -ne 0; then
    exit "$status"
fi
find "$evidence_dir" -type f -exec chmod a-w -- {} +
printf '%s\n' "WEIDU_OFFLINE_TP2_OK evidence=$evidence_dir"
