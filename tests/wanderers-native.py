#!/usr/bin/env python3
"""Read-only consumer of normal Wanderers 054c1cd SDL/OpenGL gameplay.

Real XTest keys only. Native OCaml Marshal saves are decoded (never generated
or changed) using OCaml 4.07 caml/intext.h and pinned src/{state,common,global}.ml.
Exact UI glyph masks come from the packaged bitmap and pinned Grafx.Draw:
7x7 font, nearest-neighbour 2x scaling, gr_sml_ui, View.draw_state clock/speed.
No OCR, injected state, console cheats, installed helper, or synthetic capture.
"""
import ctypes as C
import hashlib
import json
import math
import os
from pathlib import Path
import select
import signal
import stat
import struct
import subprocess
import sys
import time
import traceback
import zlib


class ProofError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise ProofError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def identity(proc):
    values = {}
    for line in (proc / "status").read_text().splitlines():
        key, _, text = line.partition(":")
        if key in ("Uid", "Gid", "Groups"):
            values[key] = [int(x) for x in text.split()]
    require(values.get("Uid") == [int(os.environ["HOST_UID"])] * 4,
            "native process changed caller UID")
    require(values.get("Gid") == [int(os.environ["HOST_GID"])] * 4,
            "native process changed caller GID")
    return values


def namespace_proof(proc):
    namespaces = {name: os.readlink(proc / "ns" / name)
                  for name in ("user", "mnt", "net", "pid")}
    for name, host in (("user", "HOST_USER_NS"), ("mnt", "HOST_MOUNT_NS"),
                       ("net", "HOST_NET_NS"), ("pid", "HOST_PID_NS")):
        require(namespaces[name] != os.environ[host], "not in private " + name + " namespace")
        require(namespaces[name] == os.readlink(Path("/proc/self/ns") / name),
                "process escaped consumer " + name + " namespace")
    devices = sorted(line.split(":")[0].strip() for line in
                     (proc / "net/dev").read_text().splitlines()[2:] if ":" in line)
    require(devices == ["lo"], "offline namespace must have only loopback")
    uid_map = (proc / "uid_map").read_text()
    gid_map = (proc / "gid_map").read_text()
    require([int(x) for x in uid_map.split()] ==
            [int(os.environ["HOST_UID"]), int(os.environ["HOST_UID"]), 1],
            "user mapping is not exactly map-current-user")
    require([int(x) for x in gid_map.split()] ==
            [int(os.environ["HOST_GID"]), int(os.environ["HOST_GID"]), 1],
            "group mapping is not exactly current GID")
    return {"namespaces": namespaces, "interfaces": devices, "identity": identity(proc),
            "uid_map": uid_map, "gid_map": gid_map}


def readonly_store(evidence):
    commands = []
    def mount(*args):
        command = [os.environ["MOUNT"], *args]
        result = subprocess.run(command, capture_output=True, text=True, timeout=15)
        commands.append({"command": command, "returncode": result.returncode,
                         "stdout": result.stdout, "stderr": result.stderr})
        record(evidence / "mount-commands.json", commands)
        require(result.returncode == 0, "read-only store mount failed: " + result.stderr)
    def entries():
        text = Path("/proc/self/mountinfo").read_text()
        found = []
        for line in text.splitlines():
            f = line.split()
            target = f[4]
            for escaped, literal in (("\\040", " "), ("\\011", "\t"),
                                     ("\\012", "\n"), ("\\134", "\\")):
                target = target.replace(escaped, literal)
            if target == "/gnu/store" or target.startswith("/gnu/store/"):
                found.append((target, f[5].split(","), f[6:f.index("-")]))
        return text, found
    (evidence / "mountinfo-before.txt").write_text(entries()[0])
    mount("--rbind", "/gnu/store", "/gnu/store")
    mount("--make-rprivate", "/gnu/store")
    targets = sorted({x[0] for x in entries()[1]}, key=len, reverse=True)
    require("/gnu/store" in targets, "recursive store bind missing")
    for target in targets:
        mount("-o", "remount,bind,ro", target)
    text, found = entries()
    (evidence / "mountinfo-after.txt").write_text(text)
    require(found and all("ro" in opts and "rw" not in opts and not
                         any(x.startswith(("shared:", "master:")) for x in optional)
                         for _, opts, optional in found), "store is not recursively private/read-only")
    return {"recursive_bind": True, "recursive_readonly": True, "mounts": found}


class Block:
    def __init__(self, tag, size):
        self.tag = tag
        self.fields = [None] * size


def block(value, size=None, tag=0):
    require(isinstance(value, Block) and value.tag == tag and
            (size is None or len(value.fields) == size), "native save record/variant shape differs")
    return value.fields


def decode_save(data):
    """Strict OCaml 4.07 compact Marshal subset; reject code/custom pointers.

    Iterative traversal supports long world lists; shared references preserve
    pointer identity. Unknown encoding is an error, never a guessed fallback.
    """
    require(len(data) >= 20, "truncated native Marshal header")
    magic, length, objects, words32, words64 = struct.unpack(">5I", data[:20])
    require(magic == 0x8495A6BE and length == len(data) - 20,
            "native Marshal magic/declared byte length differs")
    offset = 20
    shared = []
    def take(n):
        nonlocal offset
        require(offset + n <= len(data), "truncated native Marshal payload")
        chunk = data[offset:offset + n]
        offset += n
        return chunk
    def integer(n, signed=False):
        return int.from_bytes(take(n), "big", signed=signed)
    def token():
        code = integer(1)
        children = 0
        if code >= 0x80:
            value = Block(code & 15, (code >> 4) & 7)
            children = len(value.fields)
        elif code >= 0x40:
            return code & 63, 0
        elif code >= 0x20:
            value = take(code & 31)
        elif code <= 3:
            return integer((1, 2, 4, 8)[code], True), 0
        elif code in (4, 5, 6, 0x14):
            distance = integer({4: 1, 5: 2, 6: 4, 0x14: 8}[code])
            require(0 < distance <= len(shared), "invalid native Marshal shared offset")
            return shared[-distance], 0
        elif code in (8, 0x13):
            header = integer(4 if code == 8 else 8)
            value = Block(header & 255, header >> 10)
            children = len(value.fields)
        elif code in (9, 10, 0x15):
            value = take(integer({9: 1, 10: 4, 0x15: 8}[code]))
        elif code in (11, 12):
            value = struct.unpack(">d" if code == 11 else "<d", take(8))[0]
        elif code in (13, 14, 15, 7, 0x16, 0x17):
            size = integer(1 if code in (13, 14) else 4 if code in (15, 7) else 8)
            order = ">" if code in (13, 15, 0x16) else "<"
            value = struct.unpack(order + str(size) + "d", take(size * 8))
        else:
            raise ProofError(f"unsupported native Marshal code 0x{code:02x}")
        if not isinstance(value, Block) or children:
            shared.append(value)
        return value, children
    root, children = token()
    pending = [(root, 0)] if children else []
    while pending:
        parent, index = pending[-1]
        value, children = token()
        parent.fields[index] = value
        pending[-1] = (parent, index + 1)
        if index + 1 == len(parent.fields):
            pending.pop()
        if children:
            pending.append((value, 0))
    require(offset == len(data) and len(shared) == objects,
            "native Marshal trailing data/shared object count differs")
    return root, {"bytes": len(data), "sha256": sha(data), "objects": objects,
                  "words32": words32, "words64": words64}


def map_values(tree):
    pending = [tree]
    while pending:
        node = pending.pop()
        if node == 0:
            continue
        left, key, value, right, height = block(node, 5)
        require(isinstance(height, int) and height > 0, "native map height invalid")
        yield key, value
        pending.extend((right, left))

def list_values(value):
    while value != 0:
        head, value = block(value, 2)
        yield head


def notifications(unit):
    u = block(unit, 12)
    core = block(u[1], 10)
    result = []
    for item in list_values(u[9]):
        event, age = block(item, 2)
        require(0 <= age < 4, "native notification age differs")
        if event == 0:  # NtfyStunned is the sole constant constructor.
            kind, payload = "stunned", None
        else:
            require(isinstance(event, Block) and len(event.fields) == 1 and event.tag in (0, 1),
                    "unknown native notification variant")
            kind, payload = ("damage", "other")[event.tag], event.fields[0]
        result.append({"kind": kind,
                       "value": payload.decode() if isinstance(payload, bytes) else payload,
                       "age": age, "position": block(u[3], 2), "hp": core[3], "unit_id": u[0]})
    return result


def native_state(data):
    root, info = decode_save(data)
    s = block(root, 17)
    require(s[14] == 0 and s[15] == b"guix-smoke", "debug mode or native seed changed")
    geo = block(s[3], 5)
    regions = dict(map_values(block(geo[4], 2)[0]))
    require(geo[0] in regions, "native current region absent from Prio map")
    region = block(regions[geo[0]], 8)
    units = dict(map_values(block(region[3], 2)[0]))
    controlled = [u for u in units.values() if
                  isinstance(block(u, 12)[1], Block) and
                  block(block(u, 12)[1], 10)[5] != 0 and
                  block(block(block(u, 12)[1], 10)[5], 1)[0] == s[4]]
    require(len(controlled) == 1, "native save must have exactly one live controlled player")
    u = block(controlled[0], 12)
    core = block(u[1], 10)
    require(core[3] > 0, "native controlled player is dead")
    waiting = block(s[2], 1, tag=4)
    require(block(waiting[0], 2)[0] is controlled[0], "native save is not waiting for controlled input")
    clock = block(s[11], 2)
    require(isinstance(clock[0], int) and 0 <= clock[1] < 1, "invalid native clock")
    loc = block(u[2], 2)
    pos = block(u[3], 2)
    require(all(isinstance(x, int) for x in loc) and all(math.isfinite(x) for x in pos),
            "invalid native player coordinates")
    require([math.floor(x + 0.5) for x in pos] == loc, "native loc/continuous position mismatch")
    info.update(seed=s[15].decode(), debug=False, region=geo[0], controller=s[4],
                player_id=u[0], location=loc, position=pos, hp=core[3],
                clock=clock[0] + clock[1], speed=block(s[13], 1)[0],
                female=core[2] != 0 and block(core[2], 1)[0] == 1,
                fencing=u[8], waiting_for_input=True,
                notifications=notifications(controlled[0]),
                scene_notifications=[n for other in units.values()
                    if block(block(block(s[9], 1)[0])[block(block(other, 12)[2], 2)[0]])[
                        block(block(other, 12)[2], 2)[1]] > 0
                    for n in notifications(other)],
                reaction=core[6][1])
    return info, (root, region, units, controlled[0])


def movement(state, decoded):
    _, region, units, _ = decoded
    columns = block(block(region[1], 1)[0])
    x, y = state["location"]
    occupied = {tuple(block(block(u, 12)[2], 2)) for u in units.values()}
    # Tile constant constructor indices exclude payload constructors (common.ml).
    floors = {0, 6, 7, 8, 9, 10, 11, 12, 14}
    for key, dx, dy, inverse in (("Right", 1, 0, "Left"), ("Left", -1, 0, "Right"),
                                  ("Up", 0, 1, "Down"), ("Down", 0, -1, "Up")):
        nx, ny = x + dx, y + dy
        if 1 <= nx < len(columns) - 1 and 1 <= ny < len(block(columns[nx])) - 1:
            tile = block(columns[nx])[ny]
            if isinstance(tile, int) and tile in floors and (nx, ny) not in occupied:
                return {"key": key, "inverse": inverse, "before": [x, y],
                        "after": [nx, ny], "delta": [dx, dy], "native_floor": tile}
    raise ProofError("native seeded player has no unoccupied cardinal floor")

class XImage(C.Structure):
    # Public Xlib.h prefix through channel masks; function table is unused.
    _fields_ = [("width", C.c_int), ("height", C.c_int), ("xoffset", C.c_int),
                ("format", C.c_int), ("data", C.c_void_p), ("byte_order", C.c_int),
                ("bitmap_unit", C.c_int), ("bitmap_bit_order", C.c_int),
                ("bitmap_pad", C.c_int), ("depth", C.c_int),
                ("bytes_per_line", C.c_int), ("bits_per_pixel", C.c_int),
                ("red_mask", C.c_ulong), ("green_mask", C.c_ulong),
                ("blue_mask", C.c_ulong)]



class XCapture:
    def __init__(self):
        self.lib = C.CDLL(os.environ["LIBX11"])
        for name, args, result in (
                ("XOpenDisplay", [C.c_char_p], C.c_void_p),
                ("XGetImage", [C.c_void_p, C.c_ulong, C.c_int, C.c_int, C.c_uint,
                               C.c_uint, C.c_ulong, C.c_int], C.c_void_p),
                ("XGetPixel", [C.c_void_p, C.c_int, C.c_int], C.c_ulong),
                ("XDestroyImage", [C.c_void_p], C.c_int),
                ("XCloseDisplay", [C.c_void_p], C.c_int)):
            function = getattr(self.lib, name)
            function.argtypes, function.restype = args, result
        self.display = self.lib.XOpenDisplay(os.environ["DISPLAY"].encode())
        require(self.display, "cannot open private X display")

    def capture(self, window):
        width, height = 854, 480  # main.ml: 854/2*zi, 480/2*zi
        image = self.lib.XGetImage(self.display, int(window), 0, 0, width, height,
                                  C.c_ulong(-1).value, 2)
        require(image, "XGetImage failed for normal SDL window")
        header = C.cast(image, C.POINTER(XImage)).contents
        require((header.width, header.height, header.depth, header.red_mask,
                 header.green_mask, header.blue_mask) ==
                (854, 480, 24, 0xff0000, 0xff00, 0xff),
                "private Xvfb capture is not the declared 24-bit RGB format")
        try:
            # The private Xvfb uses 24-bit TrueColor, standard RGB channel masks.
            rgb = bytearray(width * height * 3)
            for y in range(height):
                for x in range(width):
                    pixel = self.lib.XGetPixel(image, x, y)
                    offset = (y * width + x) * 3
                    rgb[offset:offset + 3] = bytes((pixel >> 16 & 255, pixel >> 8 & 255, pixel & 255))
            return bytes(rgb)
        finally:
            self.lib.XDestroyImage(image)

    def close(self):
        self.lib.XCloseDisplay(self.display)


def save_png(path, rgb):
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))
    rows = b"".join(b"\0" + rgb[y * 854 * 3:(y + 1) * 854 * 3] for y in range(480))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" +
                     chunk(b"IHDR", struct.pack(">IIBBBBB", 854, 480, 8, 2, 0, 0, 0)) +
                     chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))


class Glyphs:
    def __init__(self, path):
        data = path.read_bytes()
        require(data[:2] == b"BM", "packaged tileset is not BMP")
        offset = struct.unpack_from("<I", data, 10)[0]
        self.data, self.offset = data, offset
        width, height, planes, bits, compression = struct.unpack_from("<iiHHI", data, 18)
        require((width, height, planes, bits, compression) == (512, 512, 1, 24, 0),
                "pinned font bitmap format differs")
        self.masks = {}
        for code in sorted({ord(c) for c in "clock: speed[+-]:+0123456789"}):
            k = code - 33 if code > 32 else 94
            x0, y0 = k % 18 * 7, k // 18 * 7
            mask = []
            for y in range(7):
                for x in range(7):
                    p = offset + ((511 - y0 - y) * 512 + x0 + x) * 3
                    color = tuple(data[p:p + 3])
                    require(color in ((255, 255, 255), (255, 255, 0)),
                            "pinned required text glyph has unexpected color")
                    mask.append(color == (255, 255, 255))
            self.masks[chr(code)] = mask

    def read(self, rgb, col, row):
        # OpenGL origin is lower-left; 14-pixel cells, glyph source top-down.
        x0, y0 = col * 14, 480 - (row + 1) * 14
        observed = []
        for y in range(7):
            for x in range(7):
                # Exact foreground occupancy, including all four magnified
                # pixels. Cyan source texels are transparent over native scene.
                pixels = [rgb[((y0 + y * 2 + dy) * 854 + x0 + x * 2 + dx) * 3:
                              ((y0 + y * 2 + dy) * 854 + x0 + x * 2 + dx) * 3 + 3]
                          for dy in (0, 1) for dx in (0, 1)]
                foreground = [pixel == b"\xff\xff\xff" for pixel in pixels]
                if len(set(foreground)) != 1:
                    return []
                observed.append(foreground[0])
        matches = [ch for ch, mask in self.masks.items() if mask == observed]
        # Some ASCII glyphs are identical. Assertions use the full match set.
        return matches

    def text(self, rgb, col, row, expected):
        return all(ch in self.read(rgb, col + i, row) for i, ch in enumerate(expected))

    def clock(self, rgb):
        require(self.text(rgb, 25, 0, "clock: "), "normal gameplay clock glyphs missing")
        digits = ""
        for col in range(32, 42):
            options = self.read(rgb, col, 0)
            if " " in options:
                break
            found = [x for x in options if x.isdigit()]
            require(len(found) == 1, "native clock digit is not exactly decoded")
            digits += found[0]
        require(digits, "native clock has no digits")
        require(self.text(rgb, 10, 0, "speed[+-]:+0"), "normal default speed glyphs missing")
        return int(digits)

    def notification_pixels(self, state):
        # View.draw_ntfy after sprite draw. Compute only truly opaque font
        # texel coverage, not a bounding box that could excuse wrong pixels.
        covered = set()
        for notice in state["scene_notifications"]:
            age = notice["age"]
            if notice["kind"] == "damage":
                value, hp = notice["value"], notice["hp"]
                critical = max(0, min(value / hp, 1)) if hp > 0 else 1
                text = str(math.floor(value + .5))
                dx = .5 * (critical + .1) * math.sin(age)
            elif notice["kind"] == "stunned":
                text = "%"
                dx = .05 * math.sin(age)
            else:
                text = notice["value"]
                dx = -len(text) * .25 + .5 + .05 * math.sin(age)
            px, py = notice["position"]
            for index, ch in enumerate(text):
                code = ord(ch)
                require(32 <= code < 128, "native notification character outside renderer font")
                k = code - 33 if code > 32 else 94
                left = math.floor(14 + 28 * (px + dx + .5 * index) + .5)
                bottom = math.floor(14 + 28 * (py + age * .4) + .5)
                top = 480 - bottom - 14
                for y in range(7):
                    for x in range(7):
                        p = self.offset + ((511 - k // 18 * 7 - y) * 512 + k % 18 * 7 + x) * 3
                        if self.data[p:p + 3][::-1] == b"\0\xff\xff":
                            continue
                        for oy in (0, 1):
                            for ox in (0, 1):
                                covered.add((left + x * 2 + ox, top + y * 2 + oy))
        return covered

    def player(self, rgb, state):
        # View.draw_unit: Pos.u_hum=(0,12), female + (0,1), white tint.
        # Predraw.subimagef rounds Grid.posf; alpha-key cyan is transparent.
        x0 = math.floor(14 + 28 * state["position"][0] + .5)
        bottom = math.floor(14 + 28 * state["position"][1] + .5)
        y0 = 480 - bottom - 28
        require(0 <= x0 <= 854 - 28 and 0 <= y0 <= 480 - 28,
                "native player sprite is outside normal view")
        source_y = 14 * (12 + int(state["female"]))
        matched = 0
        occlusion = self.notification_pixels(state)
        occluded = 0
        exact_rows, exact_columns = set(), set()
        exact_colors = set()
        for y in range(14):
            for x in range(14):
                p = self.offset + ((511 - source_y - y) * 512 + x) * 3
                color = self.data[p:p + 3][::-1]
                if color == b"\0\xff\xff":
                    continue
                for dy in (0, 1):
                    for dx in (0, 1):
                        sx, sy = x0 + x * 2 + dx, y0 + y * 2 + dy
                        if (sx, sy) in occlusion:
                            occluded += 1
                            continue
                        q = ((y0 + y * 2 + dy) * 854 + x0 + x * 2 + dx) * 3
                        require(rgb[q:q + 3] == color,
                                "native controlled sprite pixels differ from source bitmap")
                        matched += 1
                        exact_rows.add(y)
                        exact_columns.add(x)
                        exact_colors.add(color)
        opaque_rows, opaque_columns = set(), set()
        opaque_colors = set()
        for y in range(14):
            for x in range(14):
                p = self.offset + ((511 - source_y - y) * 512 + x) * 3
                if self.data[p:p + 3][::-1] != b"\0\xff\xff":
                    opaque_rows.add(y)
                    opaque_columns.add(x)
                    opaque_colors.add(self.data[p:p + 3][::-1])
        # Distinctive source silhouette cannot vanish behind notifications:
        # every source-occupied row AND column needs exact visible evidence.
        require(exact_rows == opaque_rows and exact_columns == opaque_columns and
                exact_colors == opaque_colors,
                "notification occlusion hides complete source sprite row/column/palette color")
        return {"source_tile": [0, 12 + int(state["female"])],
                "screen_box": [x0, y0, 28, 28], "exact_opaque_pixels": matched,
                "native_notification_occluded_pixels": occluded,
                "all_source_occupied_rows_columns_and_palette_have_exact_pixels": True}


def env_tree(root):
    env = os.environ.copy()
    for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_CONFIG_DIRS", "config-dirs"), ("XDG_DATA_HOME", "data"),
                           ("XDG_DATA_DIRS", "data-dirs"), ("XDG_CACHE_HOME", "cache"),
                           ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                           ("TMPDIR", "tmp")):
        directory = root / name
        directory.mkdir(mode=0o700)
        env[variable] = str(directory)
    (root / "work").mkdir()
    env.update(SDL_VIDEODRIVER="x11", SDL_AUDIODRIVER="dummy", SDL_JOYSTICK_DISABLED="1",
               LIBGL_ALWAYS_SOFTWARE="1", LC_ALL="C", PATH="")
    record(root / "environment.json", env)
    return env


def terminate(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=3)


class Session:
    def __init__(self, output, root, env, label, new=False):
        self.output, self.root, self.label, self.env = output, root, label, env
        self.save = Path(env["XDG_DATA_HOME"]) / "wanderers/game.save"
        self.window = None
        self.log_path = root / (label + ".raw")
        self.log = self.log_path.open("wb")
        self.inputs = []
        command = [str(output / "bin/wanderers")] + (["guix-smoke"] if new else [])
        self.process = subprocess.Popen(command, cwd=root / "work", env=env,
                                        stdin=subprocess.DEVNULL, stdout=self.log, stderr=self.log,
                                        start_new_session=True)
        self.inputs.append({"command": command})
        self.capture = None

    def diagnostics(self):
        text = self.log_path.read_bytes().lower()
        require(not any(word in text for word in (b"fatal", b"exception", b"error",
                                                   b"failed", b"not found", b"invalid")),
                "native runtime diagnostic (including exit-zero errors): " + text.decode(errors="replace"))

    def xdo(self, *args):
        result = subprocess.run([os.environ["XDOTOOL"], *args], env=self.env,
                                capture_output=True, text=True, timeout=8)
        self.inputs.append({"xdotool": args, "returncode": result.returncode,
                            "stdout": result.stdout, "stderr": result.stderr})
        record(self.root / (self.label + ".inputs.json"), self.inputs)
        return result

    def start(self, glyphs):
        end = time.monotonic() + 90
        while time.monotonic() < end:
            self.diagnostics()
            require(self.process.poll() is None, "native game exited before gameplay")
            result = self.xdo("search", "--onlyvisible", "--name", "^Wanderers$")
            windows = result.stdout.split()
            if result.returncode == 0 and windows:
                require(len(windows) == 1, "ambiguous Wanderers window")
                self.window = windows[0]
                break
            time.sleep(.1)
        require(self.window, "native SDL window did not appear")
        geometry = self.xdo("getwindowgeometry", "--shell", self.window)
        values = dict(x.split("=", 1) for x in geometry.stdout.splitlines() if "=" in x)
        require(geometry.returncode == 0 and (values["WIDTH"], values["HEIGHT"]) == ("854", "480"),
                "native SDL window geometry differs")
        require(self.xdo("windowfocus", "--sync", self.window).returncode == 0, "cannot focus SDL game")
        proc = Path("/proc") / str(self.process.pid)
        state = Path(self.env["XDG_DATA_HOME"]) / "wanderers"
        proof = namespace_proof(proc)
        require((proc / "exe").resolve() == (self.output / "libexec/wanderers").resolve(),
                "game executable is not supplied libexec/wanderers")
        require((proc / "cwd").resolve() == state.resolve(), "wrapper did not use fresh XDG data cwd")
        require((state / "data").is_symlink() and (state / "data").resolve() ==
                (self.output / "share/wanderers/data").resolve(), "wrapper assets link differs")
        proof.update(executable=str((proc / "exe").resolve()), cwd=str(state),
                     cmdline=[x.decode() for x in (proc / "cmdline").read_bytes().split(b"\0")[:-1]])
        record(self.root / (self.label + ".process.json"), proof)
        self.capture = XCapture()
        # World generation happens after the window is mapped. Synchronize on
        # exact real clock text, then a stable clock (WaitInput freezes it).
        previous = None
        end = time.monotonic() + 90
        while time.monotonic() < end:
            self.diagnostics()
            require(self.process.poll() is None, "native game exited while generating world")
            rgb = self.capture.capture(self.window)
            save_png(self.root / (self.label + "-waiting.png"), rgb)
            if glyphs.text(rgb, 25, 0, "clock: "):
                clock = glyphs.clock(rgb)
                if previous == clock:
                    self.ready_rgb = rgb
                    save_png(self.root / (self.label + "-ready.png"), rgb)
                    return clock
                previous = clock
            time.sleep(.3)
        raise ProofError("native normal gameplay clock never became ready")

    def key(self, key, reason):
        self.inputs.append({"key": key, "reason": reason})
        require(self.xdo("windowfocus", "--sync", self.window).returncode == 0, "cannot focus game")
        require(self.xdo("key", "--clearmodifiers", "--delay", "80", key).returncode == 0,
                "cannot send real XTest game input")

    def finish(self, glyphs):
        # Main runs sim time at 11x wall time; the 10-unit Rest completes in
        # under one wall second normally. Stable exact clock captures gate quit.
        time.sleep(2)
        rgb = self.capture.capture(self.window)
        clock = glyphs.clock(rgb)
        time.sleep(.3)
        final = self.capture.capture(self.window)
        require(glyphs.clock(final) == clock, "native action did not settle to input wait")
        save_png(self.root / (self.label + "-before-save.png"), final)
        self.final_rgb = final
        before = self.save.read_bytes() if self.save.exists() else None
        self.key("ctrl+q", "normal Main.process_key_pressed save-and-quit")
        self.process.wait(timeout=15)
        self.log.flush()
        self.diagnostics()
        require(self.process.returncode == 0, "normal Ctrl-Q quit failed")
        require(self.save.is_file() and not self.save.is_symlink(), "native save not created as regular file")
        data = self.save.read_bytes()
        archive = self.root / (self.label + ".game.save")
        archive.write_bytes(data)  # original native bytes retained even if decoding fails
        info, decoded = native_state(data)
        require(round(info["clock"]) == clock, "native saved clock differs from exact displayed clock")
        info["sprite_pixels"] = glyphs.player(final, info)
        if before is not None:
            self.inputs.append({"previous_save_sha256": sha(before), "save_sha256": sha(data)})
        record(self.root / (self.label + ".state.json"), info)
        return data, info, decoded

    def close(self):
        terminate(self.process)
        if self.capture:
            self.capture.close()
        self.log.close()
        record(self.root / (self.label + ".inputs.json"), self.inputs)


def validate_output(output):
    for name in ("bin/wanderers", "libexec/wanderers"):
        require(os.access(output / name, os.X_OK), "normal executable missing: " + name)
    resources = ["share/wanderers/data/tileset.bmp", "share/wanderers/data/dg/cave1.au",
                 "share/doc/wanderers/COPYING", "share/doc/wanderers/README.markdown",
                 "share/doc/wanderers/OCamlMakefile"]
    resources += ["share/doc/wanderers/lib/" + x for x in
                  ("glcaml.ml", "glcaml.mli", "glcaml_stub.c", "sdl.ml", "sdl.mli", "sdl_stub.c", "win.ml", "win.mli")]
    info = {}
    for name in resources:
        content = (output / name).read_bytes()
        require(content, "packaged resource/notice missing: " + name)
        info[name] = {"bytes": len(content), "sha256": sha(content)}
    require("GNU GENERAL PUBLIC LICENSE" in (output / resources[2]).read_text(), "GPL notice missing")
    readme = (output / resources[3]).read_text()
    require("GPL3 license" in readme and "BSD 2-clause license" in readme, "upstream license summary missing")
    gl_notice = (output / "share/doc/wanderers/lib/glcaml.ml").read_text()
    require("Copyright (C) 2007, 2008 Elliott OTI" in gl_notice and
            "Redistributions in binary form must reproduce" in gl_notice and
            "THIS SOFTWARE IS PROVIDED" in gl_notice, "GLCaml binary redistribution notice missing")
    sdl_notice = (output / "share/doc/wanderers/lib/sdl.ml").read_text()
    require("Jean-Christophe FILLIATRE" in sdl_notice and
            "GNU Library General Public" in sdl_notice and "License version 2" in sdl_notice,
            "SDL binding license notice missing")
    for parent, dirs, files in os.walk(output):
        for name in dirs + files:
            require("smoke" not in name.lower(), "installed smoke helper is forbidden")
        for name in files:
            require(not stat.S_IMODE((Path(parent) / name).stat().st_mode) & 0o222,
                    "installed package file is writable")
    return info


def main():
    require(len(sys.argv) == 3, "usage: wanderers-native.py OUTPUT EVIDENCE_DIR")
    output, evidence = [Path(x).resolve(strict=True) for x in sys.argv[1:]]
    require(evidence.is_dir() and not any(evidence.iterdir()), "evidence must be empty")
    require(evidence != output and output not in evidence.parents and Path("/gnu/store") not in evidence.parents,
            "evidence cannot be in package/store")
    xserver = None
    readfd = writefd = None
    try:
        network = namespace_proof(Path("/proc/self"))
        record(evidence / "namespace.json", network)
        store = readonly_store(evidence)
        package = validate_output(output)
        record(evidence / "package.json", package)
        xroot = evidence / "xserver"
        xroot.mkdir()
        xenv = env_tree(xroot)
        readfd, writefd = os.pipe()
        with (xroot / "Xvfb.raw").open("wb") as log:
            xserver = subprocess.Popen([os.environ["XVFB"], "-displayfd", str(writefd),
                                         "-screen", "0", "1024x768x24", "-nolisten", "tcp"],
                                        env=xenv, cwd=xroot / "work", pass_fds=(writefd,),
                                        stdin=subprocess.DEVNULL, stdout=log, stderr=log,
                                        start_new_session=True)
        os.close(writefd)
        writefd = None
        ready = b""
        end = time.monotonic() + 20
        while b"\n" not in ready and time.monotonic() < end:
            require(xserver.poll() is None, "private Xvfb failed")
            if select.select([readfd], [], [], .1)[0]:
                chunk = os.read(readfd, 128)
                require(chunk, "private Xvfb readiness pipe closed")
                ready += chunk
        require(ready.endswith(b"\n") and ready[:-1].isdigit(), "invalid Xvfb displayfd readiness")
        os.environ["DISPLAY"] = ":" + ready[:-1].decode()
        record(xroot / "process.json", namespace_proof(Path("/proc") / str(xserver.pid)))
        root = evidence / "gameplay"
        root.mkdir()
        env = env_tree(root)
        glyphs = Glyphs(output / "share/wanderers/data/tileset.bmp")
        saves, states, decoded = [], [], []
        chosen = None
        for label in ("baseline", "movement", "rest", "roundtrip", "continued"):
            session = Session(output, root, env, label, new=label == "baseline")
            try:
                ready_clock = session.start(glyphs)
                if states:
                    require(ready_clock == round(states[-1]["clock"]), "default relaunch did not restore native clock")
                    require(session.save.read_bytes() == saves[-1], "normal load unexpectedly altered native save")
                    require(f"Random seed: guix-smoke\n".encode() in session.log_path.read_bytes(),
                            "default no-argument launch did not report restored seed")
                if label == "movement":
                    chosen = movement(states[0], decoded[0])
                    record(root / "movement.json", chosen)
                    session.key(chosen["key"], "one native cardinal movement to decoded unoccupied floor")
                elif label == "rest":
                    session.key("t", "normal Rest timed action, duration 10 simulation units")
                elif label == "continued":
                    continued = movement(states[-1], decoded[-1])
                    record(root / "continued-movement.json", continued)
                    session.key(continued["key"], "continued native movement from actual combat-displaced state")
                data, info, objects = session.finish(glyphs)
                if states:
                    require(info["seed"] == states[0]["seed"] and info["player_id"] == states[0]["player_id"] and
                            info["controller"] == states[0]["controller"] and info["region"] == states[0]["region"],
                            "native restore lost world/player identity")
                if label == "movement":
                    require(info["location"] == chosen["after"] and info["clock"] > states[-1]["clock"],
                            "native movement did not reach exact adjacent location/advance simulation clock")
                    for location in (chosen["before"], chosen["after"]):
                        x, y = location
                        x0, y0 = 14 + 28 * x, 480 - (14 + 28 * y) - 28
                        def cell(rgb):
                            return b"".join(rgb[((y0 + row) * 854 + x0) * 3:
                                               ((y0 + row) * 854 + x0 + 28) * 3]
                                            for row in range(28))
                        require(cell(session.ready_rgb) != cell(session.final_rgb),
                                "native movement did not change source-derived old/new tile pixels")
                elif label == "rest":
                    elapsed = info["clock"] - states[-1]["clock"]
                    reaction = states[-1]["reaction"]
                    require(10 + reaction <= elapsed < 10 + reaction + 2,
                            "native Rest did not complete its 10-unit timed action and reaction wait")
                    record(root / "rest-combat.json", {
                        "elapsed": elapsed, "before": states[-1]["location"],
                        "after": info["location"], "hp_before": states[-1]["hp"],
                        "hp_after": info["hp"], "damage_notifications": info["notifications"]})
                elif label == "roundtrip":
                    require(data == saves[-1], "no-action default restore/save did not preserve complete native state bytes")
                elif label == "continued":
                    require(info["location"] == continued["after"] and info["clock"] > states[-1]["clock"],
                            "continued native movement did not reach exact newly chosen floor")
                saves.append(data)
                states.append(info)
                decoded.append(objects)
            finally:
                session.close()
        record(evidence / "proof.json", {"output": str(output), "pinned_commit": "054c1cdc6dd833d8938357e6d898def510531d67",
               "normal_seed_argument": "guix-smoke", "namespace": network, "readonly_store": store,
               "native_states": states, "movement": chosen, "native_rest_duration": 10,
               "continued_movement": continued,
               "full_state_roundtrip_equal": True, "exact_source_font_clock": True,
               "exact_source_player_sprite": True, "native_movement_old_new_cells_changed": True,
               "normal_save_quit_and_default_restore": True,
               "limits": ["Software OpenGL on private 24-bit Xvfb; GPU and desktop integration are not exercised.",
                          "Exact sprite assertion excludes only source-derived opaque notification texels; every source-occupied sprite row and column retains exact visible evidence.",
                          "Clock is source-rendered rounded text; decoded saves retain the exact fractional simulation clock."]})
        print("WANDERERS_NATIVE_SAVE_RESTORE_OK")
    except BaseException:
        (evidence / "failure.txt").write_text(traceback.format_exc())
        raise
    finally:
        terminate(xserver)
        if writefd is not None:
            os.close(writefd)
        if readfd is not None:
            os.close(readfd)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Wanderers native proof failed: {error}", file=sys.stderr)
        sys.exit(1)
