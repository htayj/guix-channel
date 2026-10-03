#!/usr/bin/env python3
"""Drive The Smith's Hand X11 UI; inspect its native save, never fake it."""

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
    assets = output / "share/the-smiths-hand"
    game = output / "bin/smith"
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
                 "LIBTCOD-CREDITS.txt", "README-SDL.txt", "FONT-NOTICE.txt",
                 "THIRD-PARTY-NOTICES.txt"):
        require((output / "share/doc/the-smiths-hand" / name).stat().st_size > 0,
                "missing notice: " + name)
    # Canonical upstream assets; configuration is intentionally changed only
    # to disable unavailable music and fullscreen, so compare its semantics.
    asset_names = {
        "terminal.png": "5e9e64246b857dc414bd0acde98820885274483580f751b9b3329b8ee86b82f4",
        "text.txt": "4c87aa27918964903b71441b973a035ba1b5a57227d771befb3fadc8229a37f4",
        "rooms/village.map": "2945569c915aaeb2c8eab17533a0332677476d0e59e2043107513788d200f831",
    }
    asset_hashes = {}
    for name, digest in asset_names.items():
        asset_hashes[name] = hashlib.sha256((assets / name).read_bytes()).hexdigest()
        require(asset_hashes[name] == digest, "modified original asset: " + name)
    expected_config = {
        "coins.dynamic": "true", "music.enable": "false",
        "music.file": '"../music/pickyourfavorite.ogg"', "music.volume": "5",
        "screen.full": "false",
    }

    def config_properties(path):
        import re
        text = path.read_text()
        blocks = re.findall(r"(\w+)\s*\{([^{}]*)\}", text)
        properties = {}
        for section, body in blocks:
            for key, value in re.findall(r'(\w+)\s*=\s*("[^"\n]*"|\w+)', body):
                name = section + "." + key
                require(name not in properties, "duplicate configuration property: " + name)
                properties[name] = value
        require(properties == expected_config, "unexpected configuration: " + repr(properties))
        return properties

    config_properties(assets / "smith.cfg")
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
        root = Path("/tmp/the-smiths-hand-root")
        artifacts = Path("/tmp/the-smiths-hand-artifacts")
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
    state = root / "data/the-smiths-hand"
    save = state / "linux/smith.sav"
    expected_links = {
        "linux/terminal.png": assets / "terminal.png",
        "rooms/village.map": assets / "rooms/village.map",
        "text.txt": assets / "text.txt",
    }

    def confinement(saved):
        for directory in ("home", "config", "cache", "state", "runtime", "work", "tmp"):
            require(not list((root / directory).iterdir()),
                    "game wrote outside XDG data: " + directory)
        require(list((root / "data").iterdir()) == [state], "unexpected XDG data sibling")
        expected = {"linux", "rooms", "smith.cfg", *expected_links}
        if saved:
            expected.add("linux/smith.sav")
        actual = set()
        for parent, directories, files in os.walk(state, followlinks=False):
            for name in directories + files:
                actual.add(str((Path(parent) / name).relative_to(state)))
        require(actual == expected, "unexpected state paths: " + repr(actual ^ expected))
        for relative, target in expected_links.items():
            path = state / relative
            require(path.is_symlink() and path.resolve() == target.resolve(),
                    "asset is not an immutable symlink: " + relative)
        config = state / "smith.cfg"
        require(config.is_file() and not config.is_symlink() and config.stat().st_mode & 0o200,
                "configuration is not caller-writable")
        config_properties(config)
        if saved:
            for path in (save,):
                require(path.is_file() and not path.is_symlink() and path.stat().st_mode & 0o200,
                        "save is not caller-writable: " + str(path))

    def tool(*args):
        return subprocess.check_output(args, env=environment, timeout=10)

    # libtcod defaults to ASCII_INCOL, 16x16 glyphs; the console is 80x50.
    # The misleading .png suffix is not trusted: ImageMagick reads the original
    # bitmap by magic.  Read pixels only; never replace or annotate screenshots.
    font = assets / "terminal.png"
    fw, fh = map(int, tool(convert, str(font), "-format", "%w %h", "info:").split())
    require(fw % 16 == 0 and fh % 16 == 0, "invalid original font grid")
    cw, ch = fw // 16, fh // 16
    width, height = cw * 80, ch * 50
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
        for row in range(50):
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
                # Dense glyphs (B/N/W) have more ink than background. A modal
                # pixel is then the foreground, so its distance mask has the
                # opposite polarity. Match both without relaxing tolerance.
                inverse_mask = mask ^ ((1 << (cw * ch)) - 1)
                error, character = min((min((mask ^ glyph).bit_count(),
                                           (inverse_mask ^ glyph).bit_count()), character)
                                       for character, glyph in glyphs.items())
                line += character if error <= cw * ch * 0.08 else "~"
            rows.append(line)
        return "\n".join(rows)

    def native_save(label):
        # Native, unaligned fields from MAP::save and ROOM/POS/PORTAL,
        # ITEM::save/saveGlobal, MOB::save, BUF::save and SIMULATOR::save.
        # No fixture writes: this reads only the game's own normal Q save.
        data = save.read_bytes()
        (artifacts / (label + ".sav")).write_bytes(data)
        offset = 0

        def take(size):
            nonlocal offset
            require(0 <= size <= len(data) - offset, "truncated native save at " + str(offset))
            block = data[offset:offset + size]
            offset += size
            return block

        def integer():
            return struct.unpack("=i", take(4))[0]

        def count():
            value = integer()
            require(0 <= value <= len(data) - offset, "invalid native count at " + str(offset - 4))
            return value

        def boolean():
            value = take(1)[0]
            require(value in (0, 1), "invalid native boolean")
            return bool(value)

        def position():
            # POS::save writes x,y,angle,roomId, NOT just x,y.
            return dict(zip(("x", "y", "angle", "room"), (integer() for _ in range(4))))

        def portal():
            return {"source": position(), "destination": position()}

        def item():
            result = {"definition": integer(), "position": position()}
            require(0 <= result["definition"] < 24, "invalid native item definition")
            for name in ("count", "timer", "uid", "interested_mob_uid"):
                result[name] = integer()
            result["broken"], result["equipped"] = boolean(), boolean()
            result["mob_type"], result["material"] = integer(), integer()
            return result

        def mob():
            result = {"definition": integer()}
            require(0 <= result["definition"] < 11, "invalid native mob definition")
            name = take(count())
            result["name_bytes"] = name.hex()
            result["name"] = name.split(b"\0", 1)[0].decode("utf-8")
            for field in ("position", "meditate_position", "target", "home"):
                result[field] = position()
            result["waiting"] = boolean()
            for field in ("hp", "mp", "ai_state", "flee_count", "boredom", "yell_hysteresis",
                          "num_deaths", "uid", "strategy", "search_power", "cowardice", "kills",
                          "swallowed"):
                result[field] = integer()
            for field in ("saw_murder", "saw_mean_murder", "saw_victory", "avatar_has_ranged"):
                result[field] = boolean()
            result["heard_yells"] = [[boolean(), boolean()] for _ in range(10)]
            result["inventory"] = [item() for _ in range(count())]
            return result

        info = {name: integer() for name in (
            "time", "depth", "orcs", "dead_adventurers", "retired_adventurers",
            "invasion_active", "has_forged", "difficulty")}
        require(info["time"] >= 1, "invalid native clock")
        require(info["invasion_active"] in (0, 1) and info["has_forged"] in (0, 1),
                "invalid native map flags")
        info["global_items"] = [[integer(), integer()] for _ in range(24)]
        info["user_portals"] = []
        for _ in range(2):
            # MAP::myUserPortal is POS[2], not PORTAL[2]. ROOM portals
            # below contain two POS endpoints; these contain just one each.
            record = {"position": position()}
            record["direction"] = integer()
            info["user_portals"].append(record)
        rooms, avatars = [], []
        for _ in range(count()):
            room = {name: integer() for name in ("id", "depth", "type", "width", "height")}
            require(room["width"] > 0 and room["height"] > 0, "invalid native room dimensions")
            items = [item() for _ in range(count())]
            mobs = [mob() for _ in range(count())]
            avatars.extend(record for record in mobs if record["definition"] == 1)  # MOB_AVATAR
            room["portals"] = [portal() for _ in range(count())]
            cells = room["width"] * room["height"]
            room["tiles_sha256"] = hashlib.sha256(take(cells)).hexdigest()
            take(cells)  # myFlags: load rebuilds FOV, not a persistent-state invariant
            room["color"] = list(take(3))
            room["jacob"] = [integer() for _ in range(4)]
            room["items"] = items
            room["mob_uids"] = [record["uid"] for record in mobs]
            rooms.append(room)
        away_mobs = [mob() for _ in range(count())]
        events = [[integer(), integer(), integer()] for _ in range(count())]
        require(offset == len(data), "unparsed native save bytes: " + str(len(data) - offset))
        require(len(avatars) == 1 and avatars[0]["hp"] > 0, "native save has no unique living avatar")
        equipment = {record["definition"] for record in avatars[0]["inventory"]
                     if record["equipped"] and not record["broken"]}
        require({13, 18} <= equipment,
                "native avatar lost its equipped smith hammer or clothes")
        info.update(avatar=avatars[0], room_topology=rooms,
                    away_mob_uids=[record["uid"] for record in away_mobs],
                    events=sorted(events), bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
        return data, info

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
                        [xdotool, "search", "--onlyvisible", "--name", "^The Smith's Hand$"],
                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                        env=environment, timeout=5)
                    if found.returncode == 0 and (not restoring or not save.exists()):
                        window = found.stdout.decode().splitlines()[0]
                        tool(xdotool, "windowfocus", "--sync", window)
                        time.sleep(0.5)
                        require(Path(os.readlink(f"/proc/{process.pid}/cwd")) == state / "linux",
                                "game did not run from writable linux directory")
                        require(Path(os.readlink(f"/proc/{process.pid}/exe")).resolve() ==
                                (output / "libexec/smith").resolve(),
                                "launcher did not exec the source-built game")
                        if restoring:
                            require(not save.exists(), "original loader did not consume save")
                        return window
                    time.sleep(0.1)
                raise RuntimeError("The Smith's Hand options window or save consumption timed out")

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
            require("Play" in options and "Instructions" in options,
                    "original options menu not visible")
            key("Escape")  # optionsMenu: ESC enters Play, not a turn.
            welcome = capture("welcome", window)
            require("Adam Smith" in welcome and "Wealth of Nations" in welcome,
                    "original new-game welcome not visible")
            key("space")  # dismiss popup only
            initial = capture("initial", window)
            require("Orcs:" in initial and "Inventory:" in initial and
                    "Adventurers" in initial, "village HUD missing")
            key("question")
            help_surface = capture("help", window)
            require("Command Keys:" in help_surface and "Quit and Save" in help_surface,
                    "actual framebuffer does not contain original help commands")
            key("Escape")
            resumed = capture("help-dismissed", window)
            require("Inventory:" in resumed and "Command Keys:" not in resumed,
                    "ESC did not dismiss original help")
            # gfx_cookDir(space) gives (0,0): real ACTION_BUMP -> actionWait.
            # MAP::init starts native time at one; only turn-taking input advances it.
            key("space")
            capture("played", window)
            key("shift+q")  # original Q -> shutdownEverything -> ENGINE::save
            require(process.wait(timeout=15) == 0, "first normal quit failed")
            confinement(saved=True)
            first, first_info = native_save("first")
            require(first_info["time"] > 1, "real space wait did not advance native time")
            config_before = (state / "smith.cfg").read_bytes()

            # A fresh OS process consumes and unlinks smith.sav before Play.
            window = launch("restored", restoring=True)
            capture("restored-options", window)
            require(not save.exists(), "consumed save reappeared before Play")
            confinement(saved=False)
            key("Escape")
            back = capture("welcome-back", window)
            require("You return to the forge." in back, "original restore welcome not visible")
            key("space")
            restored = capture("restored", window)
            require("Orcs:" in restored and "Inventory:" in restored and
                    "Adventurers" in restored, "restored village HUD missing")
            # No turn-taking input in this process: compare parsed native fields.
            key("shift+q")
            require(process.wait(timeout=15) == 0, "restored normal quit failed")
            confinement(saved=True)
            second, second_info = native_save("restored")
            for field in ("time", "depth", "difficulty", "dead_adventurers",
                          "retired_adventurers", "orcs", "invasion_active", "has_forged",
                          "global_items", "user_portals", "avatar", "room_topology",
                          "away_mob_uids", "events"):
                require(first_info[field] == second_info[field],
                        "no-turn restore changed native field: " + field)
            require(config_before == (state / "smith.cfg").read_bytes(),
                    "restart did not preserve caller configuration")
            # FOV may be rebuilt on load: whole-file equality is reported,
            # not assumed. Parsed clock/avatar/topology equality is required.
            proof = {"namespaces": namespaces, "interfaces": interfaces,
                     "assets": asset_hashes, "configuration": expected_config,
                     "first": first_info, "restored": second_info,
                     "whole_save_identical": first == second,
                     "save_consumed_before_play": True, "state_confinement": True,
                     "framebuffer": {"width": width, "height": height},
                     "input": ["space", "Q"]}
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
    print("The Smith's Hand: real space wait advanced time; loader consumed save; native avatar and time restored")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("the-smiths-hand smoke: " + str(error), file=sys.stderr, flush=True)
        sys.exit(1)
