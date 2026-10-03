#!/usr/bin/env python3
"""Private X11/network namespace harness for the installed EAF application."""
import json
import os
from pathlib import Path
import select
import signal
import socket
import struct
import subprocess
import sys
import tempfile

out = Path(sys.argv[1]).resolve()
emacs, xvfb, mount, capture, helper = sys.argv[2:]
artifacts = Path(os.environ.get("EAF_SMOKE_ARTIFACTS") or
                 tempfile.mkdtemp(prefix="eaf-native-artifacts-")).resolve()
if artifacts == out or out in artifacts.parents:
    raise RuntimeError("artifacts must not be inside the package output")
artifacts.mkdir(parents=True, exist_ok=True)
print(f"EAF native artifacts: {artifacts}", flush=True)
roots = list(out.rglob("eaf.el"))
if len(roots) != 1:
    raise RuntimeError(f"expected one installed EAF core, got {roots}")
if not (roots[0].parent / "app/demo/buffer.py").is_file():
    raise RuntimeError("pinned upstream demo is missing")
subprocess.run([mount, "--make-rprivate", "/"], check=True, timeout=5)
if not Path("/tmp/.X11-unix").is_dir():
    raise RuntimeError("requires /tmp/.X11-unix mount point")
subprocess.run([mount, "-t", "tmpfs", "tmpfs", "/tmp/.X11-unix"],
               check=True, timeout=5)
if [name for _, name in socket.if_nameindex()] != ["lo"]:
    raise RuntimeError("private network namespace required")
# Linux network namespaces begin with loopback down; EPC needs 127.0.0.1.
import fcntl
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as interface:
    request = struct.pack("16sh", b"lo", 0)
    flags = struct.unpack("16sh", fcntl.ioctl(interface, 0x8913, request)[:18])[1]
    fcntl.ioctl(interface, 0x8914, struct.pack("16sh", b"lo", flags | 1))


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=3)


with tempfile.TemporaryDirectory(prefix="eaf-native-state-") as temporary:
    root = Path(temporary)
    environment = {"PATH": "", "LC_ALL": "C", "LIBGL_ALWAYS_SOFTWARE": "1",
                   "QT_QPA_PLATFORM": "xcb", "QTWEBENGINE_DISABLE_SANDBOX": "1",
                   "EAF_SMOKE_IMPORT": capture,
                   "EAF_SMOKE_ARTIFACTS": str(artifacts),
                   "EAF_SMOKE_RESULT": str(artifacts / "result.json")}
    for variable in ("HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_DATA_HOME",
                     "XDG_STATE_HOME", "XDG_RUNTIME_DIR", "TMPDIR"):
        path = root / variable.lower()
        path.mkdir(mode=0o700)
        environment[variable] = str(path)
    display = client = None
    read_fd, write_fd = os.pipe()
    with (artifacts / "xvfb.log").open("wb") as display_log, \
            (artifacts / "emacs.log").open("wb") as client_log:
        try:
            display = subprocess.Popen(
                [xvfb, "-displayfd", str(write_fd), "-screen", "0", "1600x1000x24",
                 "-nolock", "-nolisten", "tcp"], env=environment,
                stdout=display_log, stderr=subprocess.STDOUT,
                pass_fds=(write_fd,), start_new_session=True)
            os.close(write_fd)
            write_fd = None
            if not select.select([read_fd], [], [], 10)[0]:
                raise RuntimeError("Xvfb readiness timeout")
            number = os.read(read_fd, 32).decode("ascii").strip()
            if not number.isdigit():
                raise RuntimeError("Xvfb failed; see xvfb.log")
            environment["DISPLAY"] = ":" + number
            client = subprocess.Popen(
                [emacs, "-Q", "--geometry", "180x42", "-L", str(roots[0].parent), "-l", helper,
                 "--eval", "(run-at-time 0.5 nil #'eaf-smoke-run)"],
                env=environment, cwd=root, stdin=subprocess.DEVNULL,
                stdout=client_log, stderr=subprocess.STDOUT,
                start_new_session=True)
            if client.wait(timeout=100):
                raise RuntimeError("native EAF scenario failed; see emacs.log")
            report = json.loads((artifacts / "result.json").read_text())
            if report.get("status") != "ok":
                raise RuntimeError(f"native EAF scenario incomplete: {report}")
            if b"EAF_NATIVE_RUNTIME_OK" not in (artifacts / "emacs-messages.log").read_bytes():
                raise RuntimeError("native scenario success marker missing")
            pngs = list(artifacts.glob("*.png"))
            if not pngs:
                raise RuntimeError("native scenario screenshots missing")
            for png in pngs:
                image = png.read_bytes()
                if image[:8] != b"\x89PNG\r\n\x1a\n":
                    raise RuntimeError(f"invalid screenshot {png}")
            print("EAF_NATIVE_RUNTIME_OK: actual upstream Qt demo, bidirectional EPC, "
                  "native view transitions, isolated state and shutdown", flush=True)
        finally:
            stop(client)
            stop(display)
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
