#!/usr/bin/env python3
"""Drive the original Six Two One X11 UI; inspect its native save, never fake it."""

import ctypes
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import time


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    require(len(sys.argv) == 8,
            "usage: runner OUTPUT ROOT XVFB XDOTOOL XWD CONVERT ARTIFACTS")
    output, root, xvfb, xdotool, xwd, convert, artifacts = sys.argv[1:]
    output, root, artifacts = Path(output), Path(root), Path(artifacts)
    assets = output / "share/six-two-one"
    game = output / "bin/six-two-one"
    artifacts.mkdir(parents=True, exist_ok=True)

    namespaces = {}
    for kind, variable in (("user", "HOST_USER_NS"), ("mnt", "HOST_MOUNT_NS"),
                           ("net", "HOST_NET_NS"), ("pid", "HOST_PID_NS")):
        actual = os.readlink("/proc/self/ns/" + kind)
        require(actual != os.environ[variable], "host " + kind + " namespace leaked")
        namespaces[kind] = actual
    interfaces = sorted(line.split(":", 1)[0].strip()
                        for line in Path("/proc/net/dev").read_text().splitlines()[2:])
    require(interfaces == ["lo"], "network namespace has non-loopback interfaces")
    for path in [output, *output.rglob("*")]:
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, "writable store path: " + str(path))
        require(path.suffix.lower() not in (".exe", ".dll"),
                "foreign bundled binary: " + str(path))
    for name in ("README.TXT", "LICENSE.TXT", "LIBTCOD-LICENSE.txt",
                 "LIBTCOD-CREDITS.txt", "README-SDL.txt", "OFL.txt",
                 "THIRD-PARTY-NOTICES.txt"):
        require((output / "share/doc/six-two-one" / name).stat().st_size > 0,
                "missing notice: " + name)
    # Digests of the canonical 7DRL archive's unmodified assets.
    asset_names = {
        "terminal.png": "7ed1cc4cc91e35b4b10330dcaac8ab2d4635174e69b8a9adc553f8067fc09c1f",
        "sixtwoone.cfg": "555a4e8d8b741928131b941c21d81b52862b7a958ecb40b8a7dc18ffb4989d76",
        "text.txt": "0d97a17b78e85c7bbc2513d685d7abf2ed6fcab575d83d21f1bf89a1287b82ff",
        "rooms/village.map": "2945569c915aaeb2c8eab17533a0332677476d0e59e2043107513788d200f831",
        "wordlist/wordlist.txt": "6da5a15e03fb157a34a80436cd5d0624e8c81ff20ae208df1155e6a54b585af4",
    }
    asset_hashes = {}
    for name in asset_names:
        data = (assets / name).read_bytes()
        require(bool(data), "empty asset: " + name)
        asset_hashes[name] = hashlib.sha256(data).hexdigest()
        require(asset_hashes[name] == asset_names[name], "modified original asset: " + name)
    text = (assets / "text.txt").read_text()
    require("welcome::Back" in text and "game::help" in text and
            "Q - Quit and Save" in text, "missing original welcome/help text")

    # Precedent: bind open directory descriptors back into a private tmpfs.
    # This works even when scratch and retained artifacts originally live in /tmp.
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    artifacts_fd = os.open(artifacts, os.O_RDONLY | os.O_DIRECTORY)
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int

    def mount(source, target, filesystem=None, flags=0):
        if libc.mount(os.fsencode(source), os.fsencode(target),
                      None if filesystem is None else os.fsencode(filesystem),
                      flags, None) != 0:
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), str(target))

    try:
        mount("tmpfs", "/tmp", "tmpfs", 2 | 4)  # MS_NOSUID | MS_NODEV
        os.chmod("/tmp", 0o1777)
        root = Path("/tmp/six-two-one-root")
        artifacts = Path("/tmp/six-two-one-artifacts")
        root.mkdir()
        artifacts.mkdir()
        mount("/proc/self/fd/" + str(root_fd), root, flags=4096)  # MS_BIND
        mount("/proc/self/fd/" + str(artifacts_fd), artifacts, flags=4096)
        Path("/tmp/.X11-unix").mkdir()
        os.chmod("/tmp/.X11-unix", 0o1777)
    finally:
        os.close(root_fd)
        os.close(artifacts_fd)
    for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                                ("TMPDIR", "tmp")):
        os.environ[variable] = str(root / directory)
    environment = dict(os.environ)
    environment.update(SDL_VIDEODRIVER="x11", SDL_AUDIODRIVER="dummy",
                       SDL_RENDER_DRIVER="software", LIBGL_ALWAYS_SOFTWARE="1",
                       MESA_SHADER_CACHE_DISABLE="true",
                       DBUS_SESSION_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-session-bus"),
                       DBUS_SYSTEM_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-system-bus"))
    state = root / "data/six-two-one"
    save = state / "save/Default.sav"
    expected_links = {
        "linux/terminal.png": assets / "terminal.png",
        "rooms/village.map": assets / "rooms/village.map",
        "wordlist/wordlist.txt": assets / "wordlist/wordlist.txt",
        "text.txt": assets / "text.txt",
    }

    def confinement(saved):
        for directory in ("home", "config", "cache", "state", "runtime", "work", "tmp"):
            require(not list((root / directory).iterdir()),
                    "game wrote outside XDG data: " + directory)
        require(list((root / "data").iterdir()) == [state], "unexpected XDG data sibling")
        expected = {"linux", "rooms", "wordlist", "save", "sixtwoone.cfg", *expected_links}
        if saved:
            expected |= {"save/Default.sav", "save/Default.txt"}
        actual = set()
        for parent, directories, files in os.walk(state, followlinks=False):
            for name in directories + files:
                actual.add(str((Path(parent) / name).relative_to(state)))
        require(actual == expected, "unexpected state paths: " + repr(actual ^ expected))
        for relative, target in expected_links.items():
            path = state / relative
            require(path.is_symlink() and path.resolve() == target.resolve(),
                    "asset is not an immutable symlink: " + relative)
        config = state / "sixtwoone.cfg"
        require(config.is_file() and not config.is_symlink() and config.stat().st_mode & 0o200,
                "configuration is not caller-writable")
        if saved:
            for path in (save, state / "save/Default.txt"):
                require(path.is_file() and not path.is_symlink() and path.stat().st_mode & 0o200,
                        "save is not caller-writable: " + str(path))

    def tool(*args):
        return subprocess.check_output(args, env=environment, timeout=10)

    # main.cpp selects ASCII_INCOL, 16x16 glyphs; the console is 80x25.
    # The misleading .png suffix is not trusted: ImageMagick reads the original
    # bitmap by magic.  Read pixels only; never replace or annotate screenshots.
    font = assets / "terminal.png"
    fw, fh = map(int, tool(convert, str(font), "-format", "%w %h", "info:").split())
    require(fw % 16 == 0 and fh % 16 == 0, "invalid original font grid")
    cw, ch = fw // 16, fh // 16
    width, height = cw * 80, ch * 25
    font_pixels = tool(convert, str(font), "-depth", "8", "rgba:-")
    require(len(font_pixels) == fw * fh * 4, "incomplete font bitmap")
    transparent = any(font_pixels[i] < 255 for i in range(3, len(font_pixels), 4))
    space_offset = ((32 % 16) * ch + ch // 2) * fw + (32 // 16) * cw + cw // 2
    invert = font_pixels[space_offset * 4] > 128
    glyphs = {}
    for code in range(32, 127):
        values = []
        for y in range((code % 16) * ch, (code % 16 + 1) * ch):
            for x in range((code // 16) * cw, (code // 16 + 1) * cw):
                i = (y * fw + x) * 4
                values.append(font_pixels[i + 3] if transparent else
                              255 - font_pixels[i] if invert else font_pixels[i])
        peak = max(values)
        glyphs[chr(code)] = sum(1 << i for i, value in enumerate(values)
                               if peak and value > peak / 3)

    def read_surface(pixels):
        """Recognize the supplied font's glyph masks on the actual framebuffer."""
        rows = []
        for row in range(25):
            line = ""
            for column in range(80):
                cell = [tuple(pixels[((row * ch + y) * width + column * cw + x) * 3:
                                     ((row * ch + y) * width + column * cw + x) * 3 + 3])
                        for y in range(ch) for x in range(cw)]
                background = max(set(cell), key=cell.count)
                distances = [sum((a - b) ** 2 for a, b in zip(p, background)) ** 0.5
                             for p in cell]
                peak = max(distances)
                mask = sum(1 << i for i, distance in enumerate(distances)
                           if peak and distance > peak / 3)
                error, character = min(((mask ^ glyph).bit_count(), character)
                                       for character, glyph in glyphs.items())
                line += character if error <= cw * ch * 0.08 else "~"
            rows.append(line)
        return "\n".join(rows)

    def native_save(label):
        data = save.read_bytes()
        require(len(data) > 342 + 8, "truncated native save")
        clock = struct.unpack_from("=i", data)[0]  # spd_gettime(), native-endian s32
        tail = data[-342:]  # 6 flags + 6 * (word[10] + known[10] + 9 * s32)
        require(clock >= 1, "invalid saved clock")
        require(all(flag in (0, 1) for flag in tail[:6]), "invalid solved flags")
        faces = []
        for face in range(6):
            offset = 6 + face * 56
            word, known = tail[offset:offset + 10], tail[offset + 10:offset + 20]
            indices = struct.unpack_from("=9i", tail, offset + 20)
            require(word[9] == 0 and all(97 <= c <= 122 for c in word[:9]),
                    "invalid saved nine-letter face word")
            require(0 in known and all(index >= 0 for index in indices),
                    "invalid saved face knowledge or topology")
            faces.append({"word": word[:9].decode("ascii"),
                          "known": known.split(b"\0", 1)[0].decode("ascii"),
                          "rooms": indices})
        (artifacts / (label + ".sav")).write_bytes(data)
        return data, {"time": clock, "bytes": len(data), "faces": faces,
                      "sha256": hashlib.sha256(data).hexdigest(),
                      "tail_sha256": hashlib.sha256(tail).hexdigest()}

    process = server = None
    with open(artifacts / "xvfb.log", "wb") as server_log:
        try:
            read_fd, write_fd = os.pipe()
            try:
                server = subprocess.Popen(
                    [xvfb, "-displayfd", str(write_fd), "-screen", "0",
                     f"{max(1024, width)}x{max(768, height)}x24", "-nolisten", "tcp", "-ac"],
                    pass_fds=(write_fd,), stdout=server_log, stderr=server_log, env=environment)
                os.close(write_fd)
                write_fd = None
                with os.fdopen(read_fd, "rb") as pipe:
                    display = pipe.readline().decode("ascii").strip()
                require(display.isdecimal(), "Xvfb did not allocate a display")
            finally:
                if write_fd is not None:
                    os.close(write_fd)
            environment["DISPLAY"] = ":" + display

            def launch(label, restoring=False):
                nonlocal process
                with open(artifacts / ("game-" + label + ".log"), "wb") as log:
                    process = subprocess.Popen([str(game)], cwd=root / "work", env=environment,
                                               stdout=log, stderr=log)
                deadline = time.monotonic() + 20
                while time.monotonic() < deadline:
                    require(process.poll() is None, "game exited before options menu")
                    found = subprocess.run(
                        [xdotool, "search", "--onlyvisible", "--name", "^Six Two One$"],
                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                        env=environment, timeout=5)
                    if found.returncode == 0 and (not restoring or not save.exists()):
                        window = found.stdout.decode().splitlines()[0]
                        tool(xdotool, "windowfocus", "--sync", window)
                        time.sleep(0.5)
                        require(Path(os.readlink(f"/proc/{process.pid}/cwd")) == state / "linux",
                                "game did not run from writable linux directory")
                        require(Path(os.readlink(f"/proc/{process.pid}/exe")).resolve() ==
                                (output / "libexec/six-two-one").resolve(),
                                "launcher did not exec the source-built game")
                        if restoring:
                            require(not save.exists(), "original loader did not consume save")
                        return window
                    time.sleep(0.1)
                raise RuntimeError("Six Two One options window or save consumption timed out")

            def key(name):
                tool(xdotool, "key", "--clearmodifiers", name)
                time.sleep(0.2)

            def capture(label, window):
                require(process.poll() is None, "game exited during " + label)
                dump = artifacts / (label + ".xwd")
                png = artifacts / (label + ".png")
                tool(xwd, "-silent", "-id", window, "-out", str(dump))
                tool(convert, str(dump), str(png))
                geometry = tool(convert, str(png), "-format", "%w %h", "info:")
                require(tuple(map(int, geometry.split())) == (width, height),
                        "unexpected original framebuffer geometry")
                pixels = tool(convert, str(png), "-depth", "8", "rgb:-")
                require(len(pixels) == width * height * 3, "incomplete framebuffer")
                surface = read_surface(pixels)
                (artifacts / (label + "-surface.txt")).write_text(surface + "\n")
                return surface

            window = launch("first")
            options = capture("options", window)
            require("Play" in options, "original Play menu not visible")
            key("Return")
            welcome = capture("welcome", window)
            require("Treska" in welcome, "original new-game welcome not visible")
            key("space")
            initial = capture("initial", window)
            require("Depth:" in initial and "Discoveries:" in initial, "dungeon HUD missing")
            key("question")
            help_surface = capture("help", window)
            require("Command Keys:" in help_surface and "Quit and Save" in help_surface,
                    "actual framebuffer does not contain original help commands")
            key("Escape")
            resumed = capture("help-dismissed", window)
            require("Depth:" in resumed and "Command Keys:" not in resumed,
                    "ESC did not dismiss original help")
            # Fixed cardinal moves test ACTION_BUMP, not wait/debug commands.
            # MAP::init starts the clock at one; only real timeused actions advance it.
            for direction in ("Up", "Right", "Down", "Left") * 2:
                key(direction)
            capture("played", window)
            key("shift+q")  # uppercase Q invokes shutdownEverything(true)
            require(process.wait(timeout=15) == 0, "first normal quit failed")
            confinement(saved=True)
            first, first_info = native_save("first")
            require(first_info["time"] > 1, "arrow gameplay did not advance native time")
            config_before = (state / "sixtwoone.cfg").read_bytes()

            # A new OS process loads and unlinks Default.sav BEFORE optionsMenu.
            window = launch("restored", restoring=True)
            capture("restored-options", window)
            require(not save.exists(), "consumed save reappeared before Play")
            key("Return")
            back = capture("welcome-back", window)
            require("return to your attempt" in back, "original restore welcome not visible")
            key("space")
            restored = capture("restored", window)
            require("Depth:" in restored and "Discoveries:" in restored,
                    "restored dungeon HUD missing")
            # No turn-taking input on this process: compare native game fields.
            key("shift+q")
            require(process.wait(timeout=15) == 0, "restored normal quit failed")
            confinement(saved=True)
            second, second_info = native_save("restored")
            require(first_info["time"] == second_info["time"], "restore changed native clock")
            require(first[-342:] == second[-342:], "restore lost face puzzle state/topology")
            require(first[4:8] == second[4:8], "restore changed native map depth")
            require(config_before == (state / "sixtwoone.cfg").read_bytes(),
                    "restart did not preserve caller configuration")
            # FOV is rebuilt on load and save flags may change; report whole-file
            # identity as stronger evidence, without pretending it is guaranteed.
            proof = {"namespaces": namespaces, "interfaces": interfaces,
                     "assets": asset_hashes, "first": first_info, "restored": second_info,
                     "whole_save_identical": first == second,
                     "save_consumed_before_play": True, "state_confinement": True,
                     "framebuffer": {"width": width, "height": height}}
            (artifacts / "proof.json").write_text(json.dumps(proof, indent=2) + "\n")
            print(json.dumps(proof, indent=2), flush=True)
        finally:
            for child in (process, server):
                if child is not None and child.poll() is None:
                    child.terminate()
                    try:
                        child.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        child.wait()
    print("Six Two One: real arrows advanced time; loader consumed save; puzzle and time restored")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("six-two-one smoke: " + str(error), file=sys.stderr, flush=True)
        sys.exit(1)
