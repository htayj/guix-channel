#!/usr/bin/env python3
"""Package-owned deterministic SDL smoke test for crashRun."""

import ctypes
import os
from pathlib import Path
import runpy
import struct
import sys
import threading
import time
import zlib


if len(sys.argv) != 3:
    raise SystemExit("crashrun-smoke.py requires DATA_ROOT and STATE_ROOT")

data_root = Path(sys.argv[1]).resolve()
state_root = Path(sys.argv[2]).resolve()
entrypoint = data_root / "crashRun.py"
xdg_state = Path(os.environ["XDG_STATE_HOME"]).resolve()
screenshot = Path(os.environ.get(
    "CRASHRUN_SMOKE_SCREENSHOT",
    str(xdg_state / "crashrun-smoke.png"),
)).resolve()

if not entrypoint.is_file() or not state_root.is_dir():
    raise RuntimeError("crashRun smoke roots are not installed directories")
if os.path.commonpath((str(xdg_state), str(state_root))) != str(xdg_state):
    raise RuntimeError("crashRun state escaped XDG_STATE_HOME")
for resource in ("help.txt", "keys.txt", "rumours.txt", "ttd.txt", "VeraMono.ttf"):
    if not (state_root / resource).is_file():
        raise RuntimeError("missing smoke resource: " + resource)

os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"
os.environ["PYTHONDONTWRITEBYTECODE"] = "1"
sys.path.insert(0, str(data_root))
os.chdir(state_root)

# Importing DisplayGuts loads the installed PySDL2/SDL bindings.  Its normal
# wait_for_key_input implementation remains in use; the wrapper only exposes
# each wait request to the deterministic SDL event feeder below.
import src.DisplayGuts as display_guts  # noqa: E402


original_wait_for_key_input = display_guts.DisplayGuts.wait_for_key_input
wait_condition = threading.Condition()
wait_count = {"value": 0}
feeder_errors = []
debug = os.environ.get("CRASHRUN_SMOKE_DEBUG") == "1"


def debug_log(message):
    if debug:
        print(message, file=sys.stderr, flush=True)


def observed_wait(self):
    with wait_condition:
        wait_count["value"] += 1
        debug_log("wait %d" % wait_count["value"])
        wait_condition.notify_all()
    return original_wait_for_key_input(self)


display_guts.DisplayGuts.wait_for_key_input = observed_wait


def key_event(sym, shifted=False):
    event = display_guts.SDL_Event()
    event.type = display_guts.SDL_KEYDOWN
    event.key.keysym.sym = sym
    event.key.keysym.mod = 4097 if shifted else 0
    result = display_guts.SDL_PushEvent(ctypes.byref(event))
    debug_log("push %s%s" % (chr(sym) if sym < 128 else sym,
                              " shifted" if shifted else ""))
    if result != 1:
        raise RuntimeError("SDL rejected a deterministic smoke key event")


def key(ch, shifted=False):
    return (ord(ch), shifted)


def feed(events):
    try:
        for index, (sym, shifted) in enumerate(events):
            with wait_condition:
                deadline = time.monotonic() + 30
                while wait_count["value"] <= index:
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        raise TimeoutError("crashRun stopped requesting smoke input")
                    wait_condition.wait(remaining)
            key_event(sym, shifted)
    except BaseException as error:  # propagate deterministic feeder failures
        feeder_errors.append(error)


first_session = [
    (display_guts.SDLK_SPACE, False),
]
first_session += [key(ch) for ch in "smoker"] + [(display_guts.SDLK_RETURN, False)]
first_session += [(display_guts.SDLK_SPACE, False)]
first_session += [(display_guts.SDLK_SPACE, False)]
first_session += [item for _ in range(6) for item in (key("1"), key("a"))]
first_session += [(display_guts.SDLK_SPACE, False)]
first_session += [key("s")]
first_session += [key("."), key(".")]
first_session += [key("s", True), key("y")]
first_session += [(display_guts.SDLK_RETURN, False)]
first_session += [(display_guts.SDLK_RETURN, False)]

second_session = [(display_guts.SDLK_SPACE, False)]
second_session += [key(ch) for ch in "smoker"]
second_session += [(display_guts.SDLK_RETURN, False), key("q", True), key("y")]
second_session += [(display_guts.SDLK_RETURN, False), (display_guts.SDLK_RETURN, False)]

events = first_session + second_session
feeder = threading.Thread(target=feed, args=(events,), daemon=True)
feeder.start()

import random  # noqa: E402

random.seed(670314)
first_namespace = runpy.run_path(str(entrypoint), run_name="__main__")
debug_log("first session returned after %d waits" % wait_count["value"])
first_dm = first_namespace["dm"]
first_player = first_dm.player
if first_dm.turn < 3:
    raise RuntimeError("smoke did not complete two pass turns")
if first_player.skill_points != 0:
    raise RuntimeError("smoke did not spend all six skill points")
if first_player.skills.get_skill("Guns").get_rank() != 6:
    raise RuntimeError("smoke did not choose the first category/skill")
if len(first_player.inventory.get_dump()) < 9:
    raise RuntimeError("smoke did not select the standard kit")
save_archive = state_root / "smoker.crsg"
if not save_archive.is_file():
    raise RuntimeError("smoke did not create the save archive")


def png_chunk(kind, payload):
    body = kind + payload
    return (struct.pack(">I", len(payload)) + body +
            struct.pack(">I", zlib.crc32(body) & 0xffffffff))


def save_surface(surface_pointer, target):
    surface = surface_pointer.contents
    pixel_format = surface.format.contents
    bytes_per_pixel = pixel_format.BytesPerPixel
    if bytes_per_pixel not in (3, 4):
        raise RuntimeError("unsupported SDL smoke surface format")
    raw = ctypes.string_at(surface.pixels, surface.pitch * surface.h)
    rows = []
    for row in range(surface.h):
        scanline = bytearray([0])
        for column in range(surface.w):
            offset = row * surface.pitch + column * bytes_per_pixel
            pixel = int.from_bytes(raw[offset:offset + bytes_per_pixel], sys.byteorder)
            red = ctypes.c_ubyte()
            green = ctypes.c_ubyte()
            blue = ctypes.c_ubyte()
            alpha = ctypes.c_ubyte()
            display_guts.SDL_GetRGBA(
                pixel, surface.format,
                ctypes.byref(red), ctypes.byref(green),
                ctypes.byref(blue), ctypes.byref(alpha),
            )
            scanline.extend((red.value, green.value, blue.value))
        rows.append(bytes(scanline))
    payload = (b"\x89PNG\r\n\x1a\n" +
               png_chunk(b"IHDR", struct.pack(">IIBBBBB", surface.w,
                                                  surface.h, 8, 2, 0, 0, 0)) +
               png_chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) +
               png_chunk(b"IEND", b""))
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(payload)


# Capture the rendered local game after the new-game, skill, kit, and turn
# path, before the save/load restart replaces its in-memory UI.
save_surface(first_namespace["dui"].guts.screen, screenshot)

second_namespace = runpy.run_path(str(entrypoint), run_name="__main__")
debug_log("second session returned after %d waits" % wait_count["value"])
if second_namespace["dm"].turn < 4:
    raise RuntimeError("smoke did not restart through the saved game")
if (state_root / "smoker.crsf").exists() or not save_archive.is_file():
    raise RuntimeError("smoke did not finish the loaded game cleanly")

feeder.join(timeout=5)
if feeder.is_alive():
    raise RuntimeError("crashRun smoke feeder did not finish")
if feeder_errors:
    raise feeder_errors[0]
if not screenshot.is_file() or screenshot.stat().st_size == 0:
    raise RuntimeError("crashRun smoke screenshot was not written")

for path in xdg_state.rglob("*"):
    if path.is_file() and os.path.commonpath((str(xdg_state), str(path.resolve()))) != str(xdg_state):
        raise RuntimeError("crashRun generated state outside XDG_STATE_HOME")

print("crashrun smoke passed: new-game, turn, save-load, and isolated-state")
