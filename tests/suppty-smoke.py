#!/usr/bin/env python3
"""Exercise pinned SUPPTY's RFC734 handshake, CLI stream and GTK renderer.

All protocol data is an original local fixture. No historical guest, external
server, patched entry point or smoke-only client option is used.
"""
import ctypes
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import time
from xml.sax.saxutils import escape


def require(value, message):
    if not value:
        raise RuntimeError(message)


def main():
    require(len(sys.argv) == 10,
            "usage: helper OUTPUT ROOT EVIDENCE IP XVFB XDOTOOL XWD CONVERT FONT")
    output, root, evidence, ip, xvfb, xdotool, xwd, convert, font = sys.argv[1:]
    output, root, evidence = Path(output), Path(root), Path(evidence)
    namespaces = {}
    for kind, variable in (("user", "HOST_USER_NS"), ("mnt", "HOST_MOUNT_NS"),
                           ("net", "HOST_NET_NS"), ("pid", "HOST_PID_NS")):
        actual = os.readlink("/proc/self/ns/" + kind)
        require(actual != os.environ[variable], "host namespace leaked: " + kind)
        namespaces[kind] = actual
    interfaces = sorted(line.split(":", 1)[0].strip()
                        for line in Path("/proc/net/dev").read_text().splitlines()[2:])
    require(interfaces == ["lo"], "external network interfaces present")
    for path in (output, *output.rglob("*")):
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, "writable package path: " + str(path))

    # A private tmpfs hides host X sockets. Rebind scratch/evidence through open
    # descriptors to support callers whose retained artifacts reside in /tmp.
    descriptors = [os.open(path, os.O_RDONLY | os.O_DIRECTORY) for path in (root, evidence)]
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int

    def mount(source, target, filesystem=None, flags=0):
        if libc.mount(os.fsencode(source), os.fsencode(target),
                      None if filesystem is None else os.fsencode(filesystem), flags, None):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), str(target))

    try:
        mount("tmpfs", "/tmp", "tmpfs", 2 | 4)
        os.chmod("/tmp", 0o1777)
        root, evidence = Path("/tmp/suppty-root"), Path("/tmp/suppty-evidence")
        root.mkdir()
        evidence.mkdir()
        for descriptor, target in zip(descriptors, (root, evidence)):
            mount("/proc/self/fd/" + str(descriptor), target, flags=4096)
        Path("/tmp/.X11-unix").mkdir(mode=0o1777)
    finally:
        for descriptor in descriptors:
            os.close(descriptor)
    environment = dict(os.environ)
    for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                                ("TMPDIR", "tmp"), ("PUTTYDIR", "putty")):
        location = root / directory
        location.mkdir(mode=0o700)
        environment[variable] = str(location)
    fontconfig = root / "fonts.conf"
    fontconfig.write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">'
                          '<fontconfig><dir>' + escape(font) + '/share/fonts</dir><cachedir>'
                          + str(root / "cache/fonts") + '</cachedir></fontconfig>')
    environment.update(FONTCONFIG_FILE=str(fontconfig), DISPLAY=":97", GDK_BACKEND="x11",
                       PYTHONNOUSERSITE="1", LIBGL_ALWAYS_SOFTWARE="1",
                       DBUS_SESSION_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-bus"),
                       DBUS_SYSTEM_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-system-bus"))
    commands, exchanges = [], []

    def record(label, args):
        commands.append({"label": label, "argv": list(map(str, args))})
        (evidence / "commands.json").write_text(json.dumps(commands, indent=2) + "\n")

    def run(label, *args, timeout=30, expected_exit=0):
        args = list(map(str, args))
        record(label, args)
        result = subprocess.run(args, cwd=evidence, env=environment, capture_output=True,
                                timeout=timeout)
        (evidence / (label + ".stdout")).write_bytes(result.stdout)
        (evidence / (label + ".stderr")).write_bytes(result.stderr)
        (evidence / (label + ".exit")).write_text(str(result.returncode) + "\n")
        require(result.returncode == expected_exit,
                label + " failed: " + result.stderr.decode(errors="replace"))
        return result.stdout

    run("loopback-up", ip, "link", "set", "lo", "up")
    # Original usage() and version() call exit(1), even for --help/--version.
    # Record their actual transcript; protocol behavior below is the proof.
    run("cli-help", output / "bin/suppty-plink", "--help", expected_exit=1)
    run("cli-version", output / "bin/suppty-plink", "--version", expected_exit=1)

    def receive(connection, count):
        data = b""
        while len(data) < count:
            part = connection.recv(count - len(data))
            require(part, "premature protocol EOF")
            data += part
        return data

    def handshake(connection, label):
        data = receive(connection, 36)
        require(all(byte < 64 for byte in data), "handshake is not six-bit bytes")
        words = [sum(byte << (6 * (5 - index)) for index, byte in enumerate(data[start:start + 6]))
                 for start in range(0, 36, 6)]
        # RFC734 negative length, type 7, options, rows, columns-1, scroll count.
        expected_options = sum(int(bits, 8) for bits in
                               ("040000000000", "010000000000", "004000000000", "002000000000",
                                "000400000000", "000020000000", "000010000000", "000002000000",
                                "000001000000", "40", "10"))
        require(words == [int("777773000000", 8), 7, expected_options, 24, 79, 1],
                label + " handshake mismatch: " + repr(words))
        (evidence / (label + "-handshake.bin")).write_bytes(data)
        greeting = b"SUPPTY LOCAL RFC734 FIXTURE\n"
        connection.sendall(greeting + b"\x88")  # %TDNOP completes greeting.
        return greeting, words

    def location(connection, label):
        data = receive(connection, len(b"\xc0\xc2SUPPTY offline fixture\0"))
        require(data == b"\xc0\xc2SUPPTY offline fixture\0", "location negotiation failed")
        (evidence / (label + "-location.bin")).write_bytes(data)

    sessions = root / "putty/sessions"
    sessions.mkdir()

    def session(name, port):
        text = ("HostName=127.0.0.1\nProtocol=supdup\nPortNumber=" + str(port)
                + "\nTermWidth=80\nTermHeight=24\nCloseOnExit=1\nWarnOnClose=0\n"
                "SUPDUPLocation=SUPPTY offline fixture\nSUPDUPCharset=0\n"
                "SUPDUPMoreProcessing=0\nSUPDUPScrolling=0\nFontName=client:DejaVu Sans Mono 14\n")
        (sessions / name).write_text(text)
        (evidence / (name + "-session.txt")).write_text(text)

    display = client = None

    def stop(process):
        if process is not None and process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)

    def listener():
        server = socket.socket()
        server.settimeout(20)
        server.bind(("127.0.0.1", 0))
        server.listen(1)
        return server

    try:
        # Saved sessions are a normal upstream protocol selection path and
        # provide explicit location/geometry without adding client options.
        with listener() as server:
            session("cli", server.getsockname()[1])
            args = [str(output / "bin/suppty-plink"), "-batch", "-load", "cli"]
            record("cli-protocol", args)
            client = subprocess.Popen(args, env=environment, stdin=subprocess.PIPE,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      start_new_session=True)
            with server.accept()[0] as connection:
                connection.settimeout(20)
                greeting, words = handshake(connection, "cli")
                body = b"CLI BACKEND RECEIVED ORIGINAL LOCAL DATA\n"
                connection.sendall(body)
                location(connection, "cli")
                client.stdin.write(b"CLI_INPUT_60\n")
                client.stdin.flush()
                incoming = receive(connection, len(b"CLI_INPUT_60\n"))
                require(incoming == b"CLI_INPUT_60\n", "CLI input changed on wire")
                (evidence / "cli-input.bin").write_bytes(incoming)
                connection.shutdown(socket.SHUT_WR)
                stdout, stderr = client.communicate(timeout=20)
            require(client.returncode == 0, "CLI did not close normally")
            require(stdout == greeting + body, "CLI backend output mismatch: " + repr(stdout))
            (evidence / "cli-protocol.stdout").write_bytes(stdout)
            (evidence / "cli-protocol.stderr").write_bytes(stderr)
            exchanges.append({"frontend": "suppty-plink", "words": words, "input": incoming.decode(),
                              "exit": client.returncode})
        args = [xvfb, ":97", "-screen", "0", "1280x1024x24", "-nolisten", "tcp"]
        record("xvfb", args)
        with (evidence / "xvfb.log").open("wb") as log:
            display = subprocess.Popen(args, env=environment, stdout=log, stderr=log,
                                       start_new_session=True)
        deadline = time.monotonic() + 10
        while not Path("/tmp/.X11-unix/X97").exists():
            require(display.poll() is None and time.monotonic() < deadline, "private Xvfb failed")
            time.sleep(0.1)
        run("gui-help", output / "bin/suppty", "--help")
        with listener() as server:
            session("gui", server.getsockname()[1])
            args = [str(output / "bin/suppty"), "-load", "gui", "-title", "SUPPTY offline RFC734"]
            record("gtk-client", args)
            with (evidence / "gui.stdout").open("wb") as stdout, (evidence / "gui.stderr").open("wb") as stderr:
                client = subprocess.Popen(args, env=environment, stdout=stdout, stderr=stderr,
                                          start_new_session=True)
            with server.accept()[0] as connection:
                connection.settimeout(20)
                greeting, words = handshake(connection, "gui")
                body = (b"\x90SUPPTY LIVE HOST CLIENT\x87"
                        b"Original local SUPDUP protocol fixture\x87"
                        b"80 columns, 24 rows; ITS character set\x87"
                        b"Type ROUNDTRIP60 to verify keyboard traffic: ")
                connection.sendall(body)
                (evidence / "gui-display.bin").write_bytes(body)
                location(connection, "gui")
                deadline = time.monotonic() + 20
                window = None
                while time.monotonic() < deadline:
                    require(client.poll() is None, "GUI exited before terminal appeared")
                    found = subprocess.run([xdotool, "search", "--onlyvisible", "--name",
                                            "^SUPPTY offline RFC734$"], env=environment,
                                           capture_output=True, text=True)
                    if found.returncode == 0 and found.stdout.strip():
                        window = found.stdout.splitlines()[-1]
                        break
                    time.sleep(0.1)
                require(window, "live GTK terminal window missing")
                run("terminal-focus", xdotool, "windowfocus", "--sync", window)
                run("terminal-type", xdotool, "type", "--window", window, "--delay", "60", "ROUNDTRIP60")
                incoming = receive(connection, len(b"ROUNDTRIP60"))
                require(incoming == b"ROUNDTRIP60", "GTK input did not reach SUPDUP socket")
                (evidence / "gui-input.bin").write_bytes(incoming)
                connection.sendall(incoming + b"\x87KEYBOARD ROUND TRIP VERIFIED\x87"
                                   b"Connection remains open for actual GTK capture.")
                time.sleep(1)
                require(client.poll() is None, "GUI exited before live capture")
                run("terminal-xwd", xwd, "-silent", "-id", window, "-out", evidence / "terminal.xwd")
                run("terminal-png", convert, evidence / "terminal.xwd", evidence / "terminal.png")
                run("desktop-xwd", xwd, "-silent", "-root", "-out", evidence / "desktop.xwd")
                run("desktop-png", convert, evidence / "desktop.xwd", evidence / "desktop.png")
                require((evidence / "terminal.png").read_bytes().startswith(b"\x89PNG\r\n\x1a\n"),
                        "actual terminal capture is not PNG")
                connection.shutdown(socket.SHUT_WR)
                require(client.wait(timeout=20) == 0, "GTK did not close normally on remote EOF")
                exchanges.append({"frontend": "suppty", "words": words, "input": incoming.decode(),
                                  "exit": client.returncode, "capture": "terminal.png"})
    finally:
        stop(client)
        stop(display)
    result = {"namespaces": namespaces, "interfaces": interfaces, "exchanges": exchanges,
              "success": "SUPPTY_OFFLINE_PROTOCOL_AND_GTK_PASSED"}
    (evidence / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
