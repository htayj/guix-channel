#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""External proof driver; only invoke through natron-smoke.sh."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys


def require(value, message):
    if not value:
        raise RuntimeError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


output, evidence, source = (Path(p).resolve() for p in sys.argv[1:])
fixtures = Path(__file__).resolve().parent
expected_uid = int(os.environ["NATRON_PROOF_UID"])
expected_gid = int(os.environ["NATRON_PROOF_GID"])
require(os.getuid() == os.geteuid() == expected_uid, "UID changed")
require(os.getgid() == os.getegid() == expected_gid, "GID changed")
fonts = Path(os.environ["NATRON_PROOF_FONTS"])
require(str(fonts).startswith("/gnu/store/") and (fonts / "share/fonts").is_dir(),
        "missing realized proof font closure")
namespaces = {}
for name in ("net", "mnt", "pid", "user"):
    current = os.readlink("/proc/self/ns/" + name)
    host = os.environ["NATRON_HOST_" + name.upper() + "NS"]
    require(current != host, "inherited " + name + " namespace")
    namespaces[name] = {"host": host, "proof": current}
require([name for _, name in socket.if_nameindex()] == ["lo"], "host network exposed")
tools = {name: str(Path(shutil.which(name)).resolve()) for name in ("mount", "g++", "xvfb-run")}
require(all(path.startswith("/gnu/store/") for path in tools.values()), "non-Guix proof tool")
fixture_dir = evidence / "fixtures"
fixture_dir.mkdir(mode=0o700)
for name in ("proof.cpp", "graph.py", "gui.py", "initGui.py"):
    shutil.copyfile(fixtures / name, fixture_dir / name)
fixture_hashes = {p.name: digest(p.read_bytes()) for p in fixture_dir.iterdir()}
# Retain exact immutable API/source excerpts, rather than relying on a network URL.
source_contracts = {
    "Gui/Gui.cpp": [(435, 452), (630, 636)],
    "Gui/Gui20.cpp": [(237, 294)],
    "Gui/GuiAppInstance.cpp": [(304, 355)],
    "Engine/Settings.cpp": [(3247, 3299)],
    "Engine/PyAppInstance.h": [(258, 322)],
    "Engine/CLArgs.cpp": [(346, 358), (378, 430)],
    "Engine/Project.cpp": [(845, 847), (888, 901)],
    "Documentation/source/devel/PythonReference/NatronEngine/App.rst": [(146, 160)],
    "libs/OpenFX/include/ofxImageEffect.h": [(82, 120), (1756, 1806)],
}
contracts = {}
for name, ranges in source_contracts.items():
    data = (source / name).read_bytes()
    lines = data.decode().splitlines()
    contracts[name] = {"sha256": digest(data), "excerpts": [
        {"first": first, "last": last,
         "text": "\n".join(f"{i}: {lines[i - 1]}" for i in range(first, last + 1))}
        for first, last in ranges]}
(evidence / "pinned-source-api.json").write_text(json.dumps(contracts, indent=2) + "\n")


def mount(*args):
    subprocess.run([tools["mount"], *map(str, args)], check=True, timeout=10)


# Minimal private root: the store is read-only; /work is the sole host-writable
# bind. All remaining writable paths are private tmpfs, not the host filesystem.
# This is stronger than merely checking the output digest after a run.
root = evidence / ".namespace-root"
root.mkdir(mode=0o700)
mount("--make-rprivate", "/")
mount("-t", "tmpfs", "-o", "mode=755,nosuid,nodev", "tmpfs", root)
for directory in ("gnu/store", "work", "tmp", "proc", "dev/shm", "etc"):
    (root / directory).mkdir(parents=True, exist_ok=True)
mount("--bind", "/gnu/store", root / "gnu/store")
mount("-o", "remount,bind,ro", root / "gnu/store")
mount("--bind", evidence, root / "work")
mount("-t", "tmpfs", "-o", "mode=1777,nosuid,nodev", "tmpfs", root / "tmp")
mount("-t", "tmpfs", "-o", "mode=1777,nosuid,nodev", "tmpfs", root / "dev/shm")
for name in ("null", "zero", "random", "urandom"):
    (root / "dev" / name).touch()
    mount("--bind", "/dev/" + name, root / "dev" / name)
(root / "dev/fd").symlink_to("/proc/self/fd")
(root / "dev/stdin").symlink_to("/proc/self/fd/0")
(root / "dev/stdout").symlink_to("/proc/self/fd/1")
(root / "dev/stderr").symlink_to("/proc/self/fd/2")
(root / "etc/passwd").write_text(f"proof:x:{expected_uid}:{expected_gid}:proof:/work/home:/bin/false\n")
(root / "etc/group").write_text(f"proof:x:{expected_gid}:\n")
mount("-t", "proc", "proc", root / "proc")
mount("-o", "remount,ro", root)
os.chroot(root)
os.chdir("/work")
evidence = Path("/work")
mountinfo = Path("/proc/self/mountinfo").read_text()
store = [line.split() for line in mountinfo.splitlines() if line.split()[4] == "/gnu/store"]
require(store and "ro" in store[-1][5].split(","), "store is not read-only")
require([name for _, name in socket.if_nameindex()] == ["lo"], "network isolation lost")
(evidence / "namespace-mountinfo.txt").write_text(mountinfo)
(evidence / "namespace-network.txt").write_text(Path("/proc/net/dev").read_text())
# Never pass host HOME, display, Python hooks, OCIO, or user plugin directories.
environment = {"PATH": os.environ["PATH"], "LC_ALL": "C", "LANG": "C",
               "QT_QPA_PLATFORM": "xcb", "QT_SCALE_FACTOR": "1",
               "QT_AUTO_SCREEN_SCALE_FACTOR": "0", "QT_ENABLE_HIGHDPI_SCALING": "0",
               "LIBGL_ALWAYS_SOFTWARE": "1", "PYTHONDONTWRITEBYTECODE": "1"}
for variable in ("C_INCLUDE_PATH", "CPLUS_INCLUDE_PATH", "LIBRARY_PATH"):
    if variable in os.environ:
        environment[variable] = os.environ[variable]
for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                       ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                       ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                       ("TMPDIR", "tmp")):
    path = evidence / name
    path.mkdir(mode=0o700)
    environment[variable] = str(path)
font_config = evidence / "fonts.conf"
font_config.write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">'
                       '<fontconfig><dir>' + str(fonts / "share/fonts") + '</dir>'
                       '<cachedir>/work/cache/fontconfig</cachedir></fontconfig>')
environment["FONTCONFIG_FILE"] = str(font_config)
plugin_dir = evidence / "ofx"
bundle = plugin_dir / "NatronProof.ofx.bundle/Contents/Linux-x86-64"
bundle.mkdir(parents=True)
environment.update(OFX_PLUGIN_PATH=str(plugin_dir), NATRON_PROOF_EVIDENCE=str(evidence),
                   NATRON_PROOF_OUTPUT="/work/frame.ppm", NATRON_PROOF_GRAPH="/work/graph.json")
runs = []


def run(name, command, timeout):
    command = [str(argument) for argument in command]
    result = subprocess.run(command, env=environment, cwd=evidence,
                            capture_output=True, timeout=timeout)
    (evidence / (name + ".stdout")).write_bytes(result.stdout)
    (evidence / (name + ".stderr")).write_bytes(result.stderr)
    runs.append({"name": name, "argv": command, "exit": result.returncode})
    require(result.returncode == 0, f"{name} exited {result.returncode}; see {name}.stderr")


run("compile-ofx", [tools["g++"], "-std=c++17", "-O2", "-shared", "-fPIC",
                    "-fvisibility=hidden", "-I" + str(source / "libs/OpenFX/include"),
                    "/work/fixtures/proof.cpp", "-o", bundle / "NatronProof.ofx"], 60)
startup = Path(environment["HOME"]) / ".Natron"
startup.mkdir(mode=0o700)
shutil.copyfile("/work/fixtures/initGui.py", startup / "initGui.py")
# Genuine Debian xvfb-run from Guix; no substitute frontend or launcher.
run("gui", [tools["xvfb-run"], "-a", "-e", "/work/xvfb-gui.log", "-s",
            "-screen 0 1280x1024x24 -nolisten tcp", output / "bin/Natron",
            "/work/fixtures/gui.py"], 60)
require(not (evidence / "gui.failure").exists(), "GUI Python callback failed")
gui = json.loads((evidence / "gui.json").read_text())
require(gui["exact_glyph_match"] is True, "no exact native GUI glyph proof")
run("renderer", [tools["xvfb-run"], "-a", "-e", "/work/xvfb-renderer.log", "-s",
                 "-screen 0 1280x1024x24 -nolisten tcp", output / "bin/NatronRenderer",
                 "-w", "NatronProofWriter", "1", "/work/fixtures/graph.py"], 60)
# PPM top row red/green; bottom row blue/white. Compare complete bytes, not only
# a file's existence, size, or a digest produced by the plugin itself.
expected = b"P6\n2 2\n255\n" + bytes((255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255))
actual = (evidence / "frame.ppm").read_bytes()
require(actual == expected, f"render bytes differ: {actual!r}")
expected_digest = digest(expected)
require(digest(actual) == expected_digest, "render digest mismatch")
graph = json.loads((evidence / "graph.json").read_text())
require(graph["generator"] == "org.guix.NatronProofGenerator" and
        graph["writer"] == "org.guix.NatronProofWriter" and graph["frames"] == [1, 1],
        "Natron did not create the real fixture graph")
(evidence / "proof.json").write_text(json.dumps({
    "schema": "natron-native-proof-v1", "output": str(output), "source": str(source),
    "revision": "3763d805d7d277d10af10025ae41af677682b3e6",
    "openfx_revision": "2303ff811bee3ffe085287602f684fe5fe5357e0",
    "uid": os.getuid(), "gid": os.getgid(), "namespaces": namespaces,
    "interfaces": ["lo"], "store_readonly": True,
    "host_writable_paths": ["/work (explicit evidence bind only)"],
    "private_writable_paths": ["/tmp", "/dev/shm"],
    "fixture_sha256": fixture_hashes, "gui": gui, "graph": graph,
    "render": {"file": "frame.ppm", "magic": "P6", "dimensions": [2, 2],
               "frame": 1, "expected_hex": expected.hex(), "actual_hex": actual.hex(),
               "expected_sha256": expected_digest, "actual_sha256": digest(actual)},
    "runs": runs, "environment": environment,
    "scope": "core source-built Natron host; no openfx-io/misc/arena or OCIO claim"
}, indent=2) + "\n")
print("NATRON_NATIVE_PROOF_OK")
