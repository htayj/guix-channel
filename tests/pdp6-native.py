#!/usr/bin/env python3
"""External PDP-6 operator-panel proof, using only the installed native UI/CLI.

Controls and geometry are from pinned upstream main_panel.c/elements.inc:
S/A select data/address octal switches, C clears, octal digits advance;
left-click POWER, DEPOSIT and EXAMINE operate the actual emulated memory.
No init file, memory fixture, device connection or runtime patch is supplied.
"""

import ctypes
import errno
import hashlib
import json
import os
from pathlib import Path
import pty
import re
import select
import struct
import subprocess
import sys
import termios
import time
import traceback


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    require(len(sys.argv) == 3, "usage: pdp6-native.py OUTPUT EVIDENCE")
    output, evidence = (Path(argument).resolve() for argument in sys.argv[1:])
    record = {"status": "failed", "output": str(output), "inputs": [],
              "source_commit": "2645ed907d0267710866fd8228863ce8867f4dc6"}

    def save():
        (evidence / "evidence.json").write_text(json.dumps(record, indent=2) + "\n")

    try:
        require(os.getuid() == int(os.environ["HOST_UID"]) and
                os.getgid() == int(os.environ["HOST_GID"]), "caller UID/GID changed")
        namespaces = {}
        for kind, variable in (("user", "HOST_USER_NS"), ("mnt", "HOST_MOUNT_NS"),
                               ("net", "HOST_NET_NS"), ("pid", "HOST_PID_NS")):
            namespaces[kind] = os.readlink("/proc/self/ns/" + kind)
            require(namespaces[kind] != os.environ[variable], "host namespace leaked: " + kind)
        interfaces = sorted(line.split(":", 1)[0].strip() for line in
                            Path("/proc/net/dev").read_text().splitlines()[2:])
        require(interfaces == ["lo"], "non-loopback network interface present")
        record["isolation"] = {"uid": os.getuid(), "gid": os.getgid(),
                               "namespaces": namespaces, "interfaces": interfaces}
        (evidence / "mountinfo-before.txt").write_text(Path("/proc/self/mountinfo").read_text())

        # Retain evidence by descriptor while replacing the entire host /tmp.
        # The store is a separate read-only bind, not merely permission-checked.
        evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
        libc = ctypes.CDLL(None, use_errno=True)
        libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                               ctypes.c_ulong, ctypes.c_void_p]
        libc.mount.restype = ctypes.c_int

        def mount(source, target, filesystem=None, flags=0):
            if libc.mount(None if source is None else os.fsencode(source), os.fsencode(target),
                          None if filesystem is None else os.fsencode(filesystem),
                          flags, None):
                error = ctypes.get_errno()
                raise OSError(error, os.strerror(error), str(target))

        try:
            mount("/gnu/store", "/gnu/store", flags=4096)  # MS_BIND
            mount(None, "/gnu/store", flags=4096 | 32 | 1)  # bind remount read-only
            mount("tmpfs", "/tmp", "tmpfs", 2 | 4)  # nosuid/nodev
            os.chmod("/tmp", 0o1777)
            retained = Path("/tmp/pdp6-evidence")
            retained.mkdir()
            mount("/proc/self/fd/" + str(evidence_fd), retained, flags=4096)
            evidence = retained
        finally:
            os.close(evidence_fd)
        mounts = Path("/proc/self/mountinfo").read_text()
        store_mounts = [line.split() for line in mounts.splitlines()
                        if line.split()[4] == "/gnu/store"]
        require(store_mounts and "ro" in store_mounts[-1][5].split(","),
                "store bind is not read-only")
        (evidence / "mountinfo-after.txt").write_text(mounts)
        record["isolation"]["store_read_only"] = True
        Path("/tmp/.X11-unix").mkdir(mode=0o1777)
        os.chmod("/tmp/.X11-unix", 0o1777)
        root = Path("/tmp/pdp6-state")
        root.mkdir(mode=0o700)
        environment = {"PATH": "", "LC_ALL": "C.UTF-8", "SDL_VIDEODRIVER": "x11",
                       "SDL_AUDIODRIVER": "dummy", "SDL_RENDER_DRIVER": "software",
                       "SDL_JOYSTICK_DISABLED": "1", "LIBGL_ALWAYS_SOFTWARE": "1",
                       "MESA_SHADER_CACHE_DISABLE": "true"}
        for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                    ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                    ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                                    ("TMPDIR", "tmp")):
            path = root / directory
            path.mkdir(mode=0o700)
            environment[variable] = str(path)
        work = root / "work"
        work.mkdir()
        environment["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=" + str(root / "runtime/no-session")
        environment["DBUS_SYSTEM_BUS_ADDRESS"] = "unix:path=" + str(root / "runtime/no-system")

        config = (output / "libexec/pdp6/init.ini").read_text()
        expected = ("mkdev apr apr166\nmkdev tty tty626\nmkdev ptr ptr760\n"
                    "mkdev ptp ptp761\nmkdev dc dc136\nmkdev dt0 dt551\n"
                    "mkdev dx0 dx555\nmkdev fmem fmem162 0\nmkdev mem0 moby\n"
                    "connectdev dc dt0\nconnectdev dt0 dx0 1\n"
                    "connectio tty apr\nconnectio ptr apr\nconnectio ptp apr\n"
                    "connectio dc apr\nconnectio dt0 apr\n"
                    "connectmem fmem 0 apr -1\nconnectmem mem0 0 apr 0\n")
        require(config == expected, "installed controlled init differs from local-device defaults")
        record["init_sha256"] = hashlib.sha256(config.encode()).hexdigest()
        for path in (output, *output.rglob("*")):
            if not path.is_symlink():
                require(not path.stat().st_mode & 0o222, "writable output path: " + str(path))

        def tool(*arguments):
            return subprocess.check_output(arguments, env=environment, cwd=work,
                                           stderr=subprocess.STDOUT, timeout=10)

        read_fd, write_fd = os.pipe()
        with (evidence / "xvfb.log").open("wb") as log:
            xserver = subprocess.Popen([os.environ["XVFB"], "-displayfd", str(write_fd),
                                        "-screen", "0", "1600x1000x24", "-nolisten", "tcp",
                                        "-noreset"], env=environment, cwd=work,
                                       pass_fds=(write_fd,), stdout=log, stderr=log)
        os.close(write_fd)
        ready, _, _ = select.select([read_fd], [], [], 10)
        require(ready and xserver.poll() is None, "private Xvfb did not become ready")
        display = os.read(read_fd, 64).decode().strip()
        os.close(read_fd)
        require(display.isdigit(), "Xvfb returned an invalid display number")
        environment["DISPLAY"] = ":" + display
        record["display"] = environment["DISPLAY"]

        master, slave = pty.openpty()
        attributes = termios.tcgetattr(slave)
        attributes[3] &= ~termios.ECHO
        termios.tcsetattr(slave, termios.TCSANOW, attributes)
        with (evidence / "pdp6.stderr").open("wb") as log:
            process = subprocess.Popen([os.environ["STRACE"], "-f", "-qq", "-s", "256",
                                        "-e", "trace=%network", "-o", str(evidence / "network.strace"),
                                        str(output / "bin/pdp6")], stdin=slave, stdout=slave,
                                       stderr=log, env=environment, cwd=work)
        os.close(slave)
        os.set_blocking(master, False)
        transcript = bytearray()

        def drain():
            while select.select([master], [], [], 0)[0]:
                try:
                    data = os.read(master, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not data:
                    break
                transcript.extend(data)
            (evidence / "console.raw").write_bytes(transcript)

        def command(text, expected_text=None):
            drain()
            start = len(transcript)
            record["inputs"].append({"native_cli": text})
            os.write(master, text.encode() + b"\n")
            if expected_text is not None:
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    drain()
                    if expected_text.encode() in transcript[start:]:
                        return
                    require(process.poll() is None, "emulator exited during CLI operation")
                    time.sleep(.05)
                raise RuntimeError("native CLI response missing: " + expected_text)

        window = None
        deadline = time.monotonic() + 15
        tree = ""
        while time.monotonic() < deadline:
            require(process.poll() is None, "emulator exited before opening the SDL panel")
            tree = tool(os.environ["XWININFO"], "-root", "-tree").decode()
            found = re.findall(r'(0x[0-9a-fA-F]+) "PDP-6 console"', tree)
            if len(found) == 1:
                window = found[0]
                break
            time.sleep(.1)
        (evidence / "window-tree.txt").write_text(tree)
        require(window is not None, "native titled PDP-6 console window missing")
        geometry = tool(os.environ["XWININFO"], "-id", window).decode()
        (evidence / "window-info.txt").write_text(geometry)
        width = int(re.search(r"Width: (\d+)", geometry)[1])
        height = int(re.search(r"Height: (\d+)", geometry)[1])
        require((width, height) == (1399, 740), "unexpected upstream operator-panel layout")
        record["window"] = {"id": window, "title": "PDP-6 console",
                            "width": width, "height": height}
        tool(os.environ["XDOTOOL"], "windowfocus", "--sync", window)

        def keys(*names):
            record["inputs"].append({"keys": names})
            tool(os.environ["XDOTOOL"], "key", "--clearmodifiers", "--delay", "90", *names)
            time.sleep(.2)

        # op_panel IHDR 1399x200, ind_panel1 height 200; findlayout puts
        # operator panel at y=540. xform uses bottom-origin 90x11 grid.
        panel_y, panel_h = 540, 200
        sx, sy = width / 90, panel_h / 11

        def click(label, x, y):
            record["inputs"].append({"mouse": label, "x": x, "y": y, "button": 1})
            tool(os.environ["XDOTOOL"], "mousemove", "--window", window, str(x), str(y),
                 "mousedown", "1", "sleep", "0.2", "mouseup", "1")
            time.sleep(.3)

        def screenshot(label):
            path = evidence / (label + ".png")
            tool(os.environ["IMPORT"], "-window", window, str(path))
            require(path.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n", "capture is not an actual PNG")
            require(struct.unpack(">II", path.read_bytes()[16:24]) == (width, height),
                    "captured window dimensions differ")
            pixels = tool(os.environ["CONVERT"], str(path), "-depth", "8", "RGB:-")
            require(len(pixels) == width * height * 3, "incomplete screenshot pixels")
            require(len(set(zip(pixels[0::3], pixels[1::3], pixels[2::3]))) > 32,
                    "SDL panel capture is blank")
            return pixels

        def cells(pixels, row):
            y = int(panel_y + panel_h - (sy / 2 + row * sy) + .5)
            result = []
            for column in range(36):
                x = int((column + 5) * sx + .5)
                result.append(b"".join(pixels[((y + dy) * width + x) * 3:
                                              ((y + dy) * width + x + 16) * 3]
                                       for dy in range(18)))
            return result

        keys("s", "c")
        screenshot("01-powered-off")
        click("POWER", int(83 * sx + 8), int(panel_y + panel_h - 5.5 * sy + 9))
        baseline = screenshot("02-power-on-memory-zero")
        command("examine 0100", "000100: 000000000000")
        pattern = "525252525252"
        keys("a", "c", *"000100", "s", "c", *pattern)
        selected = screenshot("03-data-and-address-set")
        expected_bits = [int(bit) for bit in f"{int(pattern, 8):036b}"]

        def changed_mask(before, after, row):
            return [int(sum(abs(a - b) > 24 for a, b in zip(old, new)) > 20)
                    for old, new in zip(cells(before, row), cells(after, row))]

        require(changed_mask(baseline, selected, 5) == expected_bits,
                "octal keyboard input did not set the actual data switches")
        # opgrid2: xoff=44.5*sx, scale=1.76*sx, yoff=200*2.4/143.
        key_scale = 1.76 * sx
        key_y = int(panel_y + panel_h - (panel_h * 2.4 / 143 + 2 * key_scale) + 13)
        click("DEPOSIT", int(44.5 * sx + 11 * key_scale + 13), key_y)
        command("examine 0100", "000100: " + pattern)
        deposited = screenshot("04-native-memory-deposited")
        require(changed_mask(baseline, deposited, 7) == expected_bits,
                "memory indicator lamps do not show the deposited 36-bit word")
        keys("s", "c")
        cleared = screenshot("05-data-switches-cleared")
        require(changed_mask(baseline, cleared, 5) == [0] * 36,
                "data switches did not clear through the native keyboard control")
        # Read untouched adjacent memory first so EXAMINE cannot pass merely
        # because DEPOSIT left the same word visible in the indicator lamps.
        keys("a", "c", *"000101")
        command("examine 0101", "000101: 000000000000")
        click("EXAMINE adjacent zero word", int(44.5 * sx + 13.75 * key_scale + 13), key_y)
        zero_examined = screenshot("06-adjacent-zero-examined")
        require(changed_mask(baseline, zero_examined, 7) == [0] * 36,
                "EXAMINE of untouched adjacent memory did not clear the lamps")
        keys("a", "c", *"000100", "s")
        click("EXAMINE", int(44.5 * sx + 13.75 * key_scale + 13), key_y)
        examined = screenshot("07-native-memory-examined")
        require(changed_mask(baseline, examined, 7) == expected_bits,
                "EXAMINE did not restore the actual deposited memory lamps")
        command("examine 0100", "000100: " + pattern)
        record["panel_memory"] = {"address_octal": "000100", "word_octal": pattern,
                                  "data_switch_bits": expected_bits,
                                  "examined_lamp_bits": changed_mask(baseline, examined, 7),
                                  "deposit_verified_by_native_cli": True,
                                  "data_cleared_before_examine": True,
                                  "adjacent_zero_examined_before_restore": True}
        # This is upstream c_quit -> quit(0), not EOF, a signal or windowkill.
        command("quit")
        status = process.wait(timeout=10)
        drain()
        os.close(master)
        require(status == 0, "native quit returned nonzero: " + str(status))
        trace = (evidence / "network.strace").read_text()
        require(trace.strip(), "network syscall trace is empty")
        forbidden = [line for line in trace.splitlines() if re.search(r"AF_INET6?\b", line)]
        require(not forbidden, "emulator attempted INET syscalls: " + repr(forbidden))
        require("AF_UNIX" in trace, "trace does not contain the real X11 Unix connection")
        record["network"] = {"trace": "network.strace", "inet_syscalls": forbidden,
                             "unix_connection_observed": True}
        record["quit"] = {"method": "native CLI quit", "exit_status": status}
        record["state_files"] = sorted(str(path.relative_to(root)) for path in root.rglob("*")
                                       if path.is_file())
        record["screenshots"] = sorted(path.name for path in evidence.glob("*.png"))
        record["status"] = "passed"
        # Namespace init exiting disposes of Xvfb; the emulator has already
        # completed its own clean quit. No process signal is a success criterion.
        save()
        print("PDP-6 native POWER/data/address/DEPOSIT/EXAMINE/quit proof passed")
    except BaseException as error:
        record["error"] = str(error)
        (evidence / "failure.txt").write_text(traceback.format_exc())
        save()
        raise


if __name__ == "__main__":
    main()
