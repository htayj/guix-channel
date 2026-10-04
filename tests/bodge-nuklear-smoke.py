#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Offline installed Lisp consumer plus upstream X11 renderer/button proof."""

import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import socket
import subprocess
import sys
import time

from Xlib import X, display, protocol


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def readonly_files(output):
    files = [path for path in output.rglob("*") if path.is_file()]
    writable = [str(path) for path in files if path.stat().st_mode & 0o222]
    require(not writable, "writable installed files: " + repr(writable))
    return {"files_examined": len(files), "writable_files": writable}


output, evidence, blob = map(lambda path: Path(path).resolve(), sys.argv[1:])
lisp_consumer = Path(__file__).with_name("bodge-nuklear-consumer.lisp").resolve()
require(not lisp_consumer.is_relative_to("/tmp"), "checkout must be outside host /tmp")
require(not Path(sys.executable).resolve().is_relative_to("/tmp"), "Python must be outside host /tmp")
namespaces = {}
for kind in ("user", "net", "mnt", "pid", "ipc"):
    current = os.readlink(f"/proc/self/ns/{kind}")
    host = os.environ[f"NUKLEAR_HOST_{kind.upper()}"]
    require(current != host, f"inherited {kind} namespace")
    namespaces[kind] = {"host": host, "consumer": current}
require(os.getuid() == int(os.environ["NUKLEAR_HOST_UID"]), "consumer UID changed")
require(os.geteuid() == int(os.environ["NUKLEAR_HOST_EUID"]), "consumer EUID changed")
require([name for _, name in socket.if_nameindex()] == ["lo"], "host network interface exposed")
mount = shutil.which("mount")
require(mount, "missing realized mount tool")
for command in ([mount, "--make-rprivate", "/"],
                [mount, "--bind", "/gnu/store", "/gnu/store"],
                [mount, "-o", "remount,bind,ro", "/gnu/store"]):
    subprocess.run(command, check=True, timeout=10)
mountinfo = Path("/proc/self/mountinfo").read_text()
store_mounts = [line.split() for line in mountinfo.splitlines() if line.split()[4] == "/gnu/store"]
require(store_mounts and "ro" in store_mounts[-1][5].split(","), "store mount is not read-only")
(evidence / "namespace-mountinfo.txt").write_text(mountinfo)
(evidence / "namespace-network.txt").write_text(Path("/proc/net/dev").read_text())
permissions = {"wrapper": readonly_files(output), "blob": readonly_files(blob)}
# Hide host X11 sockets, lock files and temporary state, while retaining the
# caller's evidence directory even when it is itself beneath host /tmp.
evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
try:
    subprocess.run([mount, "-t", "tmpfs", "-o", "mode=1777,nosuid,nodev", "tmpfs", "/tmp"],
                   check=True, timeout=10)
    evidence = Path("/tmp/nuklear-evidence")
    evidence.mkdir(mode=0o700)
    subprocess.run([mount, "--no-canonicalize", "--bind", f"/proc/self/fd/{evidence_fd}", str(evidence)],
                   pass_fds=(evidence_fd,), check=True, timeout=10)
finally:
    os.close(evidence_fd)
root = evidence / "consumer"
root.mkdir(mode=0o700)
os.chdir(root)
environment = {"PATH": os.environ["PATH"], "LC_ALL": "C", "LANG": "C"}
for variable, leaf in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                       ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                       ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                       ("TMPDIR", "tmp")):
    path = root / leaf
    path.mkdir(mode=0o700)
    environment[variable] = str(path)

for variable in ("C_INCLUDE_PATH", "CPLUS_INCLUDE_PATH", "LIBRARY_PATH", "GUIX_LOCPATH"):
    if variable in os.environ:
        environment[variable] = os.environ[variable]
runs = []


def run(label, command, timeout=30):
    command = [str(part) for part in command]
    result = subprocess.run(command, cwd=root, env=environment, text=True,
                            capture_output=True, timeout=timeout)
    (evidence / f"{label}.stdout").write_text(result.stdout)
    (evidence / f"{label}.stderr").write_text(result.stderr)
    require(result.returncode == 0, f"{label} failed ({result.returncode}): {result.stderr}")
    runs.append({"label": label, "command": command, "returncode": result.returncode})
    return result.stdout


native_library = (blob / "lib/x86_64/libnuklear.so").resolve()
require(native_library.is_relative_to(blob), "native library escaped blob output")
environment.update(NUKLEAR_ASDF_CONFIG=str(output / "etc/xdg/common-lisp"),
                   NUKLEAR_BLOB_ASDF_CONFIG=str(blob / "etc/xdg/common-lisp"),
                   NUKLEAR_NATIVE_LIBRARY=str(native_library),
                   NUKLEAR_LISP_RECEIPT=str(evidence / "lisp-proof.json"))
run("sbcl-consumer", ["sbcl", "--noinform", "--no-sysinit", "--no-userinit",
                      "--script", lisp_consumer], timeout=60)
lisp_proof = json.loads((evidence / "lisp-proof.json").read_text())
require(lisp_proof["button_frames"] == [0, 0, 1], "Lisp native button did not activate on release")

# Original demo sources are shipped unmodified.  Adapt only its ABI include
# block in this external consumer: bodge_nuklear.h selects the same structure
# layout as the source-built library, without embedding NK_IMPLEMENTATION.
demo = blob / "share/bodge-nuklear/demo/x11"
expected_hashes = {
    "main.c": "6a40737be60cbdf471f483549d8d69b808239987f8ce2899b3983234df9c1300",
    "nuklear_xlib.h": "e4f3b99f6a672d4b15b043fa18c3678b98ea05dbadd6af0089ab66212e6779cc",
}
for name, expected in expected_hashes.items():
    require(hashlib.sha256((demo / name).read_bytes()).hexdigest() == expected,
            f"installed {name} is not the pinned unmodified upstream source")
source = (demo / "main.c").read_text()
block = ('#define NK_INCLUDE_FIXED_TYPES\n#define NK_INCLUDE_STANDARD_IO\n'
         '#define NK_INCLUDE_STANDARD_VARARGS\n#define NK_INCLUDE_DEFAULT_ALLOCATOR\n'
         '#define NK_IMPLEMENTATION\n#define NK_XLIB_IMPLEMENTATION\n#include "../../nuklear.h"')
require(source.count(block) == 1, "upstream demo ABI include block did not occur exactly once")
source = source.replace(block, '#define NK_XLIB_IMPLEMENTATION\n#include <bodge_nuklear.h>', 1)
require("NK_IMPLEMENTATION" not in source, "consumer accidentally embeds native implementation")
(root / "main.c").write_text(source)
shutil.copyfile(demo / "nuklear_xlib.h", root / "nuklear_xlib.h")
x11 = Path(os.environ["NUKLEAR_X11"])
require("\n" not in str(x11) and x11.is_absolute() and x11.is_relative_to("/gnu/store")
        and x11.is_dir() and (x11 / "lib/libX11.so.6").is_file(),
        "wrapper must supply one realized libx11:out store directory")
run("compile-original-demo", ["gcc", "-std=c99", "-O2", "-D_POSIX_C_SOURCE=200809L",
                              "-DNK_ASSERT(e)=assert(e)", "-DNK_MEMSET=memset",
                              "-I" + str(blob / "include"), "-I" + str(x11 / "include"),
                              root / "main.c", "-L" + str(blob / "lib/x86_64"),
                              "-L" + str(x11 / "lib"), "-lnuklear",
                              "-Wl,-rpath," + str(blob / "lib/x86_64"),
                              "-Wl,-rpath," + str(x11 / "lib"), "-lX11", "-lm",
                              "-o", root / "original-demo"], timeout=60)
needed = run("demo-needed", ["readelf", "-d", root / "original-demo"])
require(re.search(r"\(NEEDED\).*\[libnuklear\.so\]", needed), "demo does not need delivered library")
linked = run("demo-linked", ["ldd", root / "original-demo"])
require("not found" not in linked, "external demo has unresolved shared libraries: " + linked)
match = re.search(r"libnuklear\.so\s+=>\s+(\S+)", linked)
require(match and Path(match[1]).resolve() == native_library, "demo linked to another Nuklear library")
symbols = run("demo-symbols", ["nm", root / "original-demo"])
require(re.search(r"^\s*U nk_begin$", symbols, re.MULTILINE), "demo embeds nk_begin implementation")
require(not re.search(r"^\s*\S+\s+[TtWw]\s+nk_begin$", symbols, re.MULTILINE), "nk_begin defined in demo")

# Core X font aliases are a separate Guix output.  Combine them externally;
# installed fonts themselves remain in the read-only store.
fonts = Path(os.environ["NUKLEAR_FONTS"]) / "share/fonts/X11/misc"
aliases = Path(os.environ["NUKLEAR_ALIASES"]) / "share/fonts/X11/misc/fonts.alias"
require((fonts / "fonts.dir").is_file() and aliases.is_file(), "missing realized fixed fonts/aliases")
fontdir = root / "xfonts"
fontdir.mkdir()
for font in fonts.iterdir():
    (fontdir / font.name).symlink_to(font)
shutil.copyfile(aliases, fontdir / "fonts.alias")
read_fd, write_fd = os.pipe()
server = application = None
Path("/tmp/.X11-unix").mkdir(mode=0o1777)
connection = None
try:
    with (evidence / "xvfb.log").open("wb") as log:
        server = subprocess.Popen(["Xvfb", "-displayfd", str(write_fd), "-screen", "0", "800x600x24",
                                   "-fp", str(fontdir), "-nolisten", "tcp", "-ac"],
                                  env=environment, cwd=root, stdout=log, stderr=subprocess.STDOUT,
                                  pass_fds=(write_fd,))
    os.close(write_fd)
    write_fd = None
    require(select.select([read_fd], [], [], 10)[0], "Xvfb did not announce a display")
    number = os.read(read_fd, 64).decode().strip()
    require(number.isdigit(), "invalid Xvfb display announcement")
    environment["DISPLAY"] = ":" + number
    with (evidence / "demo.stdout").open("wb") as stdout, (evidence / "demo.stderr").open("wb") as stderr:
        application = subprocess.Popen(["stdbuf", "-oL", str(root / "original-demo")],
                                       cwd=root, env=environment, stdout=stdout, stderr=stderr)
    deadline = time.monotonic() + 20
    window = None
    while time.monotonic() < deadline:
        require(application.poll() is None, "original X11 demo exited before window appeared")
        result = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "^X11$"],
                                env=environment, capture_output=True, text=True, timeout=3)
        if result.returncode == 0 and result.stdout.split():
            window = result.stdout.split()[0]
            break
        time.sleep(0.1)
    require(window, "original X11 window did not appear")
    run("window-focus", ["xdotool", "windowfocus", "--sync", window])
    time.sleep(0.3)
    run("screenshot", ["import", "-window", window, evidence / "original-demo.png"])
    geometry = run("screenshot-geometry", ["convert", evidence / "original-demo.png", "-format", "%w %h", "info:"])
    require(geometry.strip() == "800 600", "native demo screenshot geometry differs")
    colors = run("screenshot-colors", ["convert", evidence / "original-demo.png", "-format", "%c", "histogram:info:-"])
    # Actual renderer pixels: its background, panel and text colors all must
    # occur; a mapped blank window or successful process exit is not proof.
    for color in ("#1E1E1E", "#2D2D2D", "#AFAFAF"):
        require(color in colors.upper(), "original renderer did not draw expected color " + color)
    require((evidence / "demo.stdout").read_text() == "", "demo activated before pointer input")
    run("pointer-button", ["xdotool", "mousemove", "--window", window, "95", "105"])
    run("button-press", ["xdotool", "mousedown", "1"])
    time.sleep(0.15)
    require((evidence / "demo.stdout").read_text() == "", "button activated on press, not configured release")
    run("button-release", ["xdotool", "mouseup", "1"])
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline and not (evidence / "demo.stdout").read_text():
        require(application.poll() is None, "demo exited during pointer interaction")
        time.sleep(0.05)
    require((evidence / "demo.stdout").read_text() == "button pressed\n", "original button stdout not observed")
    run("activated-screenshot", ["import", "-window", window, evidence / "original-demo-activated.png"])
    # Send the ICCCM protocol itself, not windowkill/XDestroyWindow nor an
    # EWMH request that requires a window manager absent from this Xvfb.
    connection = display.Display(environment["DISPLAY"])
    native_window = connection.create_resource_object("window", int(window))
    wm_protocols = connection.intern_atom("WM_PROTOCOLS")
    wm_delete = connection.intern_atom("WM_DELETE_WINDOW")
    require(wm_delete in native_window.get_wm_protocols(), "demo does not advertise WM_DELETE_WINDOW")
    event = protocol.event.ClientMessage(window=native_window, client_type=wm_protocols,
                                         data=(32, [wm_delete, X.CurrentTime, 0, 0, 0]))
    native_window.send_event(event, event_mask=0)
    connection.flush()
    require(application.wait(timeout=10) == 0, "original X11 demo did not cleanly exit")
    require(not (evidence / "demo.stderr").read_text().strip(), "native demo emitted an error")
    permissions_after = {"wrapper": readonly_files(output), "blob": readonly_files(blob)}
    require(permissions_after == permissions, "installed file modes/counts changed")
    (evidence / "proof.json").write_text(json.dumps({
        "schema": "bodge-nuklear-native-consumer-v1", "wrapper": str(output), "blob": str(blob),
        "uid": os.getuid(), "euid": os.geteuid(), "namespaces": namespaces, "interfaces": ["lo"],
        "store_readonly": True, "installed_permissions_before": permissions,
        "installed_permissions_after": permissions_after, "fresh_environment": environment,
        "lisp": lisp_proof, "original_demo": {
            "source_sha256": expected_hashes, "external_abi_include_adaptations": 1,
            "native_library": str(native_library), "needed": "libnuklear.so", "nk_begin": "undefined",
            "window": window, "geometry": [800, 600], "rendered_colors": ["#1E1E1E", "#2D2D2D", "#AFAFAF"],
            "button_stdout": (evidence / "demo.stdout").read_text(), "activation": "release",
            "close_protocol": "WM_DELETE_WINDOW", "exit_code": application.returncode,
            "screenshot": "original-demo.png", "activated_screenshot": "original-demo-activated.png"},
        "runs": runs,
        "scope": "wrapper native API and original X11 demo; not bodge-nuklear/example"
    }, indent=2) + "\n")
    print("Installed Lisp native API and original X11 demo render/input/WM_DELETE_WINDOW passed")
finally:
    os.close(read_fd)
    if write_fd is not None:
        os.close(write_fd)
    if connection is not None:
        connection.close()
    for process in (application, server):
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
