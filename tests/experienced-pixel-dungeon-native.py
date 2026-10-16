#!/usr/bin/env python3
"""Experienced PD 2.19 ordinary desktop consumer, not a headless game test.

Only XTest input enters the game. XGetImage pixels, immutable sprite assets,
and READ-ONLY copies of saves written by its normal Main Menu action supply
observations. No game APIs, seed/config/save writes, process-memory reads,
renderer instrumentation, or simulated replacement game are used.
"""
import ctypes as C
import csv
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import re
import select
import subprocess
import sys
import time
import traceback
import wave
import zipfile

# Isolated Python deliberately ignores ambient site packages. These two paths
# are resolved by the shell from explicit Guix outputs before network isolation.
for directory in os.environ['PYTHON_SITE_PACKAGES'].split(':'):
    if directory:
        sys.path.append(directory)
import numpy as np
from PIL import Image, ImageOps


def require(value, message):
    if not value:
        raise AssertionError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def namespace_proof(proc, evidence):
    record = {}
    for kind, key in [('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                      ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')]:
        actual = os.readlink(proc / 'ns' / kind)
        require(actual != os.environ[key], 'host namespace leaked: ' + kind)
        require(actual == os.readlink('/proc/self/ns/' + kind), 'namespace escape: ' + kind)
        record[kind] = actual
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            identity[key] = [int(x) for x in value.split()]
    for label, key in [('Uid', 'HOST_UID'), ('Gid', 'HOST_GID')]:
        require(identity[label] == [int(os.environ[key])] * 4, 'caller identity changed')
    for filename, key in [('uid_map', 'HOST_UID'), ('gid_map', 'HOST_GID')]:
        text = (proc / filename).read_text()
        require([int(x) for x in text.split()] ==
                [int(os.environ[key]), int(os.environ[key]), 1], 'not map-current-user')
        record[filename] = text
    dev, route = (proc / 'net/dev').read_text(), (proc / 'net/route').read_text()
    interfaces = sorted(line.split(':')[0].strip() for line in dev.splitlines()[2:] if ':' in line)
    require(interfaces == ['lo'] and len(route.splitlines()) <= 1, 'network not isolated')
    record.update(identity=identity, interfaces=interfaces, net_dev=dev, net_route=route)
    write_json(evidence / ('namespace-' + proc.name + '.json'), record)
    return record


def isolate_mounts(evidence):
    commands = []

    def mount(*args):
        result = subprocess.run([os.environ['MOUNT'], *args], capture_output=True,
                                text=True, timeout=15)
        commands.append(dict(argv=[os.environ['MOUNT'], *args], status=result.returncode,
                             stdout=result.stdout, stderr=result.stderr))
        write_json(evidence / 'mount-commands.json', commands)
        require(result.returncode == 0, 'mount failed: ' + result.stderr)

    def entries():
        text = Path('/proc/self/mountinfo').read_text()
        found = []
        for line in text.splitlines():
            fields = line.split()
            target = fields[4]
            for escaped, literal in [('\\040', ' '), ('\\011', '\t'),
                                     ('\\012', '\n'), ('\\134', '\\')]:
                target = target.replace(escaped, literal)
            if target == '/gnu/store' or target.startswith('/gnu/store/'):
                found.append((target, fields[5].split(','), fields[6:fields.index('-')]))
        return text, found

    (evidence / 'mountinfo-before.txt').write_text(entries()[0])
    mount('--rbind', '/gnu/store', '/gnu/store')
    mount('--make-rprivate', '/gnu/store')
    for target in sorted({row[0] for row in entries()[1]}, key=len, reverse=True):
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    require(found and all('ro' in opts and 'rw' not in opts and not
                         any(x.startswith(('shared:', 'master:')) for x in optional)
                         for _, opts, optional in found), 'store not recursively private read-only')
    (evidence / 'mountinfo-after.txt').write_text(text)
    # The caller owns this /proc/PID/fd alias for the entire driver lifetime,
    # including exception receipts. Never close it before /tmp is replaced.
    source = str(evidence)
    mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/tmp')
    retained = Path('/tmp/exppd-evidence')
    retained.mkdir()
    mount('--bind', source, str(retained))
    evidence = retained
    mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/run')
    return retained, found


class XImage(C.Structure):
    _fields_ = [('width', C.c_int), ('height', C.c_int), ('xoffset', C.c_int),
                ('format', C.c_int), ('data', C.c_void_p), ('byte_order', C.c_int),
                ('bitmap_unit', C.c_int), ('bitmap_bit_order', C.c_int),
                ('bitmap_pad', C.c_int), ('depth', C.c_int),
                ('bytes_per_line', C.c_int), ('bits_per_pixel', C.c_int),
                ('red_mask', C.c_ulong), ('green_mask', C.c_ulong), ('blue_mask', C.c_ulong)]


class ClientData(C.Union):
    _fields_ = [('b', C.c_char * 20), ('s', C.c_short * 10), ('l', C.c_long * 5)]


class ClientMessage(C.Structure):
    _fields_ = [('type', C.c_int), ('serial', C.c_ulong), ('send_event', C.c_int),
                ('display', C.c_void_p), ('window', C.c_ulong),
                ('message_type', C.c_ulong), ('format', C.c_int), ('data', ClientData)]


class XEvent(C.Union):
    _fields_ = [('client', ClientMessage), ('pad', C.c_long * 24)]


class XCapture:
    def __init__(self, display):
        self.lib = C.CDLL(os.environ['LIBX11'])
        for name, args, result in [
                ('XOpenDisplay', [C.c_char_p], C.c_void_p),
                ('XGetImage', [C.c_void_p, C.c_ulong, C.c_int, C.c_int,
                               C.c_uint, C.c_uint, C.c_ulong, C.c_int], C.c_void_p),
                ('XDestroyImage', [C.c_void_p], C.c_int),
                ('XInternAtom', [C.c_void_p, C.c_char_p, C.c_int], C.c_ulong),
                ('XSendEvent', [C.c_void_p, C.c_ulong, C.c_int, C.c_long,
                                C.POINTER(XEvent)], C.c_int),
                ('XFlush', [C.c_void_p], C.c_int),
                ('XCloseDisplay', [C.c_void_p], C.c_int)]:
            function = getattr(self.lib, name)
            function.argtypes, function.restype = args, result
        self.display = self.lib.XOpenDisplay(display.encode())
        require(self.display, 'cannot open private X display')

    def capture(self, window, width, height):
        image = self.lib.XGetImage(self.display, window, 0, 0, width, height,
                                   C.c_ulong(-1).value, 2)
        require(image, 'XGetImage failed')
        try:
            header = C.cast(image, C.POINTER(XImage)).contents
            require((header.depth, header.bits_per_pixel, header.byte_order,
                     header.red_mask, header.green_mask, header.blue_mask) ==
                    (24, 32, 0, 0xff0000, 0xff00, 0xff), 'unexpected native framebuffer format')
            raw = C.string_at(header.data, header.bytes_per_line * height)
            array = np.frombuffer(raw, dtype=np.uint8).reshape(height, header.bytes_per_line)
            rgb = array[:, :width * 4].reshape(height, width, 4)[:, :, 2::-1].copy()
            return rgb
        finally:
            self.lib.XDestroyImage(image)

    def close_window(self, window):
        event = XEvent()
        event.client.type = 33
        event.client.send_event = 1
        event.client.display = self.display
        event.client.window = window
        event.client.message_type = self.lib.XInternAtom(self.display, b'WM_PROTOCOLS', 0)
        event.client.format = 32
        event.client.data.l[0] = self.lib.XInternAtom(self.display, b'WM_DELETE_WINDOW', 0)
        require(self.lib.XSendEvent(self.display, window, 0, 0, C.byref(event)),
                'normal window-manager Close failed')
        self.lib.XFlush(self.display)


class SpriteObserver:
    """Matches actual opaque warrior pixels, not a changed rectangle heuristic."""
    def __init__(self, sprite_bytes):
        atlas = Image.open(io.BytesIO(sprite_bytes)).convert('RGBA')
        require(atlas.size == (256, 128), 'unexpected original warrior atlas')
        self.templates = []
        # HeroClass starts warrior in ClothArmor (visibleTier 1); HeroSprite's
        # 12x15 film selects tier row 1, idle frames 0 and 1. Include mirrored
        # orientation because ordinary movement changes horizontal facing.
        for frame in (0, 1):
            original = atlas.crop((frame * 12, 15, frame * 12 + 12, 30))
            for flip in (False, True):
                tile = ImageOps.mirror(original) if flip else original
                pixels = np.asarray(tile)
                ys, xs = np.where(pixels[:, :, 3] == 255)
                require(len(xs) >= 30, 'warrior atlas lacks opaque shape')
                colors = pixels[ys, xs, :3]
                require(len(np.unique(colors, axis=0)) >= 4, 'warrior template not distinctive')
                self.templates.append((frame, flip, ys, xs, colors))

    def locate(self, rgb):
        h, w, _ = rgb.shape
        matches = {}
        # Exclude the fixed bottom avatar/inventory and top-right buttons.
        for scale in range(2, 7):
            for frame, flip, ys, xs, colors in self.templates:
                ax, ay = int(xs[len(xs)//2]), int(ys[len(ys)//2])
                color = colors[len(xs)//2].astype(np.int16)
                difference = np.max(np.abs(rgb.astype(np.int16) - color), axis=2)
                cy, cx = np.where(difference < 4)
                for x, y in set(zip((cx - ax*scale - scale//2).tolist(),
                                    (cy - ay*scale - scale//2).tolist())):
                    if not (10 <= x < w * .72 and 35*scale < y < h - 45*scale):
                        continue
                    if x + 12*scale >= w or y + 15*scale >= h:
                        continue
                    points = [rgb[y + ys*scale + oy, x + xs*scale + ox].astype(np.int16)
                              for oy, ox in ((0, 0), (0, scale-1), (scale-1, 0),
                                             (scale-1, scale-1))]
                    error = np.maximum.reduce([np.max(np.abs(point - colors.astype(np.int16)),
                                                        axis=1) for point in points])
                    score = float(np.mean(error < 5))
                    if score >= .95:
                        # Collapse subpixel anchor choices within one source pixel.
                        key = (round(x/scale), round(y/scale), scale)
                        candidate = dict(x=int(x), y=int(y), scale=scale,
                                         frame=frame, mirrored=flip, opaque_match=score,
                                         opaque_source_pixels=len(xs))
                        if key not in matches or score > matches[key]['opaque_match']:
                            matches[key] = candidate
        ordered = sorted(matches.values(), key=lambda row: row['opaque_match'], reverse=True)
        require(ordered, 'original cloth-warrior sprite not visible')
        best = ordered[0]
        require(not any(abs(row['x']-best['x']) > best['scale']*2 or
                        abs(row['y']-best['y']) > best['scale']*2 for row in ordered[1:]),
                'more than one map warrior candidate')
        return best


class PixelHudObserver:
    """Independently partitions the original pixel font as BitmapText does."""
    def __init__(self, font_bytes):
        pixels = np.asarray(Image.open(io.BytesIO(font_bytes)).convert('RGBA'))
        self.height, width = pixels.shape[:2]
        occupied = np.any(pixels[:, :, 3] != 0, axis=0)
        separator = 0
        while separator < width and not occupied[separator]:
            separator += 1
        self.glyphs = {}
        for character in map(chr, range(33, 128)):
            while separator < width and not occupied[separator]:
                separator += 1
            start = separator
            while separator < width and occupied[separator]:
                separator += 1
            require(separator > start, 'original pixel font partition missing glyph')
            # Opaque black outline pixels delimit the font cell but are not
            # luminous text ink. The actual 0.6-alpha white ink blends pink
            # over StatusPane's red health bar, not opaque screenshot white.
            glyph = pixels[:, start:separator]
            self.glyphs[character] = np.minimum(glyph[:, :, 3],
                                               np.min(glyph[:, :, :3], axis=2))
            separator += 1

    def health(self, rgb, health, maximum, scale):
        text = str(health) + '/' + str(maximum)
        glyphs = [self.glyphs[character] for character in text]
        width = sum(glyph.shape[1]-1 for glyph in glyphs) + 1
        alpha = np.zeros((self.height, width), dtype=np.uint8)
        cursor = 0
        for glyph in glyphs:
            alpha[:, cursor:cursor+glyph.shape[1]] = np.maximum(
                alpha[:, cursor:cursor+glyph.shape[1]], glyph)
            cursor += glyph.shape[1]-1
        mask = np.repeat(np.repeat(alpha > 128, scale, axis=0), scale, axis=1)
        # StatusPane large HUD: bottom 39, HP x30/y19, text y20;
        # x is centered within its 128px bar, PixelScene.align rounds pixels.
        x = int(np.floor((30+(128-width)/2)*scale + .5))
        y = rgb.shape[0] - 19*scale
        candidates = []
        # PixelScene aligns in its logical UI camera; a bounded one-source-
        # pixel search handles viewport fractional origin without relocating
        # the source-defined HP bar or relaxing ink contrast/shape acceptance.
        for dy in range(-scale, scale+1):
            for dx in range(-scale, scale+1):
                crop = rgb[y+dy:y+dy+mask.shape[0], x+dx:x+dx+mask.shape[1]]
                if crop.shape[:2] != mask.shape:
                    continue
                brightness = np.min(crop, axis=2)
                foreground = float(np.median(brightness[mask]))
                background = float(np.median(brightness[~mask]))
                if foreground <= background + 35:
                    continue
                observed = brightness > (foreground+background)/2
                score = int(np.sum(observed & mask))/max(1, int(np.sum(observed | mask)))
                candidates.append((score, foreground-background, dx, dy))
        require(candidates, 'health glyphs lack expected white-ink blend contrast')
        score, contrast, dx, dy = max(candidates)
        require(score >= .85, 'visible health text differs from original font glyph masks')
        return dict(text=text, box=[x+dx, y+dy, x+dx+mask.shape[1], y+dy+mask.shape[0]],
                    glyph_mask_iou=score, ink_contrast=contrast, source_font='fonts/pixel_font.png',
                    method='0.6-alpha white ink on red HP bar; source black outlines excluded')


def terrain_alignment(before, after, player_before, player_after, shift):
    """Exact-color terrain samples with sprite/UI excluded; records real landmarks."""
    h, w, _ = before.shape
    s = player_before['scale']
    dx, dy = map(int, shift)
    ys, xs = np.mgrid[40*s:min(h-55*s, int(h*.75)):3,
                      20:min(w-115*s, int(w*.72)):3]
    tx, ty = xs + dx, ys + dy
    mask = (tx >= 0) & (tx < w) & (ty >= 0) & (ty < h)
    for p, xx, yy in ((player_before, xs, ys), (player_after, tx, ty)):
        mask &= ~((xx >= p['x']-s*3) & (xx <= p['x']+s*15) &
                  (yy >= p['y']-s*3) & (yy <= p['y']+s*19))
    # InventoryPane.WIDTH/HEIGHT = 210/108 UI pixels, fixed not terrain.
    ui_scale = max(2, min(4, w//360, h//200))
    for xx, yy in ((xs, ys), (tx, ty)):
        mask &= ~((xx >= w-210*ui_scale) & (yy >= h-108*ui_scale))
    xs, ys, tx, ty = xs[mask], ys[mask], tx[mask], ty[mask]
    a, b = before[ys, xs], after[ty, tx]
    # Black fog/flat backgrounds cannot constitute a terrain landmark.
    textured = np.max(a, axis=1) > 25
    textured &= np.any(before[ys, np.minimum(xs+2, w-1)] != a, axis=1)
    equal = textured & np.all(a == b, axis=1)
    count = int(np.sum(textured))
    score = float(np.sum(equal) / max(1, count))
    indices = np.flatnonzero(equal)
    landmarks = [dict(before=[int(xs[i]), int(ys[i])], after=[int(tx[i]), int(ty[i])],
                      rgb=a[i].tolist()) for i in indices[::max(1, len(indices)//24)][:24]]
    colors = len(np.unique(a[equal], axis=0)) if np.any(equal) else 0
    return dict(shift=[dx, dy], exact_textured_samples=int(np.sum(equal)),
                eligible_samples=count, score=score, distinct_colors=colors, landmarks=landmarks)


def movement(before, after, a, b, direction, observations):
    require(a['scale'] == b['scale'], 'map zoom changed during step')
    dx, dy = direction
    tile = 16 * a['scale']
    shift = (b['x'] - a['x'] - dx*tile, b['y'] - a['y'] - dy*tile)
    # CharSprite aligns its origin independently from camera terrain raster.
    # Bound this source quantization residual to ±1 actual pixel, not a tile.
    def raster_alignment(expected):
        candidates = [terrain_alignment(before, after, a, b, (expected[0]+rx, expected[1]+ry))
                      for rx in (-1, 0, 1) for ry in (-1, 0, 1)]
        result = max(candidates, key=lambda row: row['score'])
        result['expected_shift'] = list(expected)
        result['raster_phase_residual'] = [result['shift'][0]-expected[0],
                                           result['shift'][1]-expected[1]]
        return result
    aligned = raster_alignment(shift)
    stationary = raster_alignment((b['x']-a['x'], b['y']-a['y']))
    observations.append(dict(direction=[dx, dy], tile_pixels=tile,
        player_before=a, player_after=b, terrain=aligned,
        no_movement_alternative=stationary))
    require(aligned['exact_textured_samples'] >= 500 and aligned['distinct_colors'] >= 12
            and aligned['score'] >= .65 and aligned['score'] > stationary['score'] + .12,
            'no exact one-tile player displacement relative to textured terrain')
    return dict(direction=[dx, dy], tile_pixels=tile, player_before=a, player_after=b,
                terrain=aligned, no_movement_alternative=stationary,
                relative_player_displacement=[dx*tile, dy*tile])


def native_save(state, evidence, label):
    path = state / 'game1/game.dat'
    require(path.is_file() and not path.is_symlink(), 'ordinary game1 save missing')
    before = path.read_bytes()
    decoded = gzip.decompress(before) if before.startswith(b'\x1f\x8b') else before
    game = json.loads(decoded)
    hero = game['hero']
    require(isinstance(hero['pos'], int) and hero['HP'] > 0, 'saved hero not alive')
    require(game['depth'] == 1 and game.get('challenges', 0) == 0 and
            not game.get('custom_seed', '') and not game.get('daily', False),
            'not ordinary first-floor unseeded game')
    require(hero['class'] == 'WARRIOR', 'native save is not selected warrior')
    require(path.read_bytes() == before, 'observer raced native save writer')
    # Copies go to evidence only; the game never reads these copies.
    (evidence / (label + '-game.dat')).write_bytes(before)
    depth = state / 'game1/depth1.dat'
    depth_bytes = depth.read_bytes()
    level = json.loads(gzip.decompress(depth_bytes) if depth_bytes.startswith(b'\x1f\x8b')
                       else depth_bytes)['level']
    require(path.read_bytes() == before and depth.read_bytes() == depth_bytes,
            'native save changed during read-only observation')
    (evidence / (label + '-depth1.dat')).write_bytes(depth_bytes)
    buffs = hero.get('buffs', [])
    record = dict(path=str(path), sha256=sha(before), depth_sha256=sha(depth_bytes),
                  observer_wrote_native_path=False, pos=hero['pos'], HP=hero['HP'], HT=hero['HT'],
                  duration=game['duration'], depth=game['depth'], width=level['width'],
                  hunger=[b.get('level') for b in buffs if isinstance(b, dict) and
                          str(b.get('__className', '')).endswith('.Hunger')])
    write_json(evidence / (label + '-persisted.json'), record)
    return record


def main():
    require(len(sys.argv) == 3, 'usage: experienced-pixel-dungeon-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    proof = dict(success=False, output=str(output), upstream_commit=
        '7a71df6a56b371a6b0efffcbe6210dbcfaf8611d', input='ordinary XTest keyboard and mouse',
        injected_state=False, frames=[], inputs=[], moves=[], persisted=[], claim_limits=[
            'A real desktop GLFW/OpenGL window on a private Xvfb server; not a headless game.',
            'Early-floor birth, tile movement, native save/quit/relaunch/resume only; not a full playthrough.',
            'Visible sprite/terrain evidence and decoded native persisted state are reported separately.',
            'The licensed composite desktop font changes typography; no original-pixel equivalence claim.'])
    processes, capture, state = [], None, None
    # A live directory descriptor keeps the host evidence directory reachable
    # even when isolation fails between overmounting /tmp and binding it back.
    evidence_descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    evidence = Path('/proc') / str(os.getpid()) / 'fd' / str(evidence_descriptor)
    try:
        proof['driver_namespace'] = namespace_proof(Path('/proc/self'), evidence)
        jar = output / 'share/java/experienced-pixel-dungeon.jar'
        with zipfile.ZipFile(jar) as archive:
            sprite_bytes = archive.read('sprites/warrior.png')
            font_bytes = archive.read('fonts/pixel_font.png')
            item_bytes = archive.read('sprites/items.png')
            manifest_text = archive.read('META-INF/MANIFEST.MF').decode().replace('\r\n', '\n')
        manifest_text = manifest_text.replace('\n ', '')
        manifest = dict(line.split(': ', 1) for line in manifest_text.splitlines() if ': ' in line)
        expected_manifest = {'Specification-Title': 'Experienced Pixel Dungeon',
            'Specification-Version': 'ExpPD-2.19.0', 'Implementation-Version': '666',
            'Upstream-Commit': proof['upstream_commit'],
            'Upstream-Source-SHA256': '3242757d206ee86217120d4af306bdca25d9ca858aeb5aab215818a82d7daa68'}
        require(all(manifest.get(key) == value for key, value in expected_manifest.items()),
                'installed game manifest differs from exact release contract')
        proof['installed_manifest'] = manifest
        observer = SpriteObserver(sprite_bytes)
        hud_observer = PixelHudObserver(font_bytes)
        proof['sprite_asset'] = dict(jar=str(jar), member='sprites/warrior.png', sha256=sha(sprite_bytes),
            source_geometry='HeroSprite 12x15, ClothArmor tier 1, idle frames 0/1, 16px dungeon tiles')
        evidence, mounts = isolate_mounts(evidence)
        proof['store_read_only_mounts'] = mounts
        root = Path('/tmp/exppd-private')
        root.mkdir(mode=0o700)
        dirs = {}
        for key, name in [('HOME', 'home'), ('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'),
                          ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                          ('XDG_RUNTIME_DIR', 'runtime'), ('TMPDIR', 'tmp')]:
            dirs[key] = root / name
            dirs[key].mkdir(mode=0o700)
        work = root / 'work'
        work.mkdir(mode=0o700)
        env = dict(os.environ, **{k: str(v) for k, v in dirs.items()})
        env.update(LIBGL_ALWAYS_SOFTWARE='1', MESA_SHADER_CACHE_DISABLE='true',
                   JAVA_TOOL_OPTIONS='-Duser.home=' + str(dirs['HOME']),
                   DBUS_SESSION_BUS_ADDRESS='unix:path=/run/no-session-bus',
                   DBUS_SYSTEM_BUS_ADDRESS='unix:path=/run/no-system-bus')
        proof['renderer_environment'] = dict(
            LIBGL_ALWAYS_SOFTWARE=env['LIBGL_ALWAYS_SOFTWARE'],
            MESA_SHADER_CACHE_DISABLE=env['MESA_SHADER_CACHE_DISABLE'],
            applies_to=['xvfb', 'game-first', 'game-second'],
            scope='private subprocess environment only; host environment unchanged')
        state = dirs['XDG_DATA_HOME'] / '.trashboxbobylev/experienced-pixel-dungeon'
        require(not state.exists(), 'initial game state not fresh')
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)
        env.update(PULSE_SERVER='unix:' + str(dirs['XDG_RUNTIME_DIR'] / 'pulse-native'),
                   ALSOFT_DRIVERS='pulse')

        def start(label, command, **kwargs):
            with (evidence / (label + '.log')).open('wb') as log:
                child = subprocess.Popen(command, cwd=work, env=env, stdin=subprocess.DEVNULL,
                                         stdout=log, stderr=log, **kwargs)
            processes.append(child)
            return child

        def tool(*args):
            return subprocess.check_output([os.environ['XDOTOOL'], *map(str, args)], env=env,
                                           stderr=subprocess.PIPE, timeout=10)

        pulse_config = root / 'pulse.pa'
        pulse_config.write_text('load-module module-native-protocol-unix socket=' +
            str(dirs['XDG_RUNTIME_DIR'] / 'pulse-native') + ' auth-anonymous=1\n'
            'load-module module-null-sink sink_name=exppd_proof rate=22050 channels=2\n'
            'set-default-sink exppd_proof\n')
        audio = start('pulseaudio', [os.environ['PULSEAUDIO'], '--daemonize=no',
            '--exit-idle-time=-1', '--use-pid-file=no', '--disable-shm=yes',
            '--log-target=stderr', '-n', '--file=' + str(pulse_config)])
        deadline = time.monotonic() + 20
        while not (dirs['XDG_RUNTIME_DIR'] / 'pulse-native').exists() and time.monotonic() < deadline:
            require(audio.poll() is None, 'private PulseAudio exited before readiness')
            time.sleep(.1)
        info = subprocess.run([os.environ['PACTL'], 'info'], env=env, capture_output=True,
                              text=True, timeout=15)
        (evidence / 'pulse-info.txt').write_text(info.stdout + info.stderr)
        require(info.returncode == 0 and 'Default Sink: exppd_proof' in info.stdout,
                'private real PulseAudio null sink absent')
        proof['audio_namespace'] = namespace_proof(Path('/proc') / str(audio.pid), evidence)
        # Capture the real sink monitor while the unmodified game plays music
        # and UI sounds; no fake OpenAL device or game audio disablement.
        with (evidence / 'audio-monitor.s16le').open('wb') as raw_audio, \
                (evidence / 'audio-monitor.stderr').open('wb') as audio_log:
            recorder = subprocess.Popen([os.environ['PAREC'], '--raw', '--rate=22050',
                '--channels=2', '--format=s16le', '--device=exppd_proof.monitor'],
                env=env, cwd=work, stdin=subprocess.DEVNULL, stdout=raw_audio, stderr=audio_log)
        processes.append(recorder)
        readfd, writefd = os.pipe()
        try:
            server = start('xvfb', [os.environ['XVFB'], '-displayfd', str(writefd),
                '-screen', '0', '1280x800x24', '-nolisten', 'tcp', '-noreset'], pass_fds=(writefd,))
            os.close(writefd)
            writefd = None
            require(select.select([readfd], [], [], 20)[0] and server.poll() is None,
                    'private X server readiness absent')
            number = os.read(readfd, 64).decode().strip()
            require(number.isdigit(), 'invalid Xvfb displayfd')
            env['DISPLAY'] = ':' + number
        finally:
            os.close(readfd)
            if writefd is not None:
                os.close(writefd)
        capture = XCapture(env['DISPLAY'])
        process, window, width, height = None, None, None, None

        def launch(label):
            nonlocal process, window, width, height
            process = start(label, [str(output / 'bin/experienced-pixel-dungeon')])
            deadline = time.monotonic() + 40
            while time.monotonic() < deadline:
                require(process.poll() is None, 'native game exited before window')
                result = subprocess.run([os.environ['XDOTOOL'], 'search', '--onlyvisible',
                    '--pid', str(process.pid), '--name', 'Experienced Pixel Dungeon'],
                    capture_output=True, env=env, timeout=5)
                require(result.returncode in (0, 1), 'X11 window discovery failed')
                windows = result.stdout.decode().splitlines()
                if len(windows) == 1:
                    window = int(windows[0])
                    break
                time.sleep(.2)
            else:
                raise AssertionError('desktop readiness timed out')
            time.sleep(3)
            geometry = tool('getwindowgeometry', '--shell', window).decode()
            values = dict(line.split('=', 1) for line in geometry.splitlines() if '=' in line)
            width, height = int(values['WIDTH']), int(values['HEIGHT'])
            require(width >= 720 and height >= 400, 'native client below upstream minimum')
            proc = Path('/proc') / str(process.pid)
            proof[label + '_namespace'] = namespace_proof(proc, evidence)
            (evidence / (label + '-mountinfo.txt')).write_text((proc / 'mountinfo').read_text())
            command = (proc / 'cmdline').read_bytes().replace(b'\0', b' ').decode()
            require(str(jar) in command, 'running Java command does not use installed game jar')
            proof[label] = dict(pid=process.pid, executable=os.readlink(proc / 'exe'),
                                command=command, geometry=values)

        def frame(label):
            require(process.poll() is None, 'native game exited during ' + label)
            rgb = capture.capture(window, width, height)
            Image.fromarray(rgb).save(evidence / (label + '.png'))
            proof['frames'].append(dict(label=label, screenshot=label + '.png',
                                        sha256=sha(rgb.tobytes()), size=[width, height]))
            return rgb

        def key(name):
            tool('windowfocus', '--sync', window)
            # No --window: xdotool's default path is actual XTest, not XSendEvent.
            tool('key', '--clearmodifiers', '--delay', '90', name)
            proof['inputs'].append(dict(key=name, mechanism='XTest'))
            time.sleep(.9)

        def click(x, y, label):
            tool('windowfocus', '--sync', window)
            tool('mousemove', '--sync', '--window', window, round(x), round(y))
            tool('click', '--clearmodifiers', '1')
            tool('mousemove', '--window', window, width-2, height-2)
            proof['inputs'].append(dict(click=[round(x), round(y)], label=label, mechanism='XTest'))
            time.sleep(1)

        def text_lines(label):
            rgb = frame(label)
            # Preserve the actual source UI text palettes: neutral white
            # labels and Window.TITLE_COLOR yellow (#ffff44), which includes
            # the native hero-selection heading. Dark chrome stays excluded.
            neutral = (np.min(rgb, axis=2) > 150) & (np.ptp(rgb, axis=2) < 70)
            yellow = (rgb[:, :, 0] > 180) & (rgb[:, :, 1] > 180) & (rgb[:, :, 2] < 130)
            bright = neutral | yellow
            Image.fromarray(np.where(bright, 0, 255).astype(np.uint8)).resize(
                (width*2, height*2), Image.Resampling.NEAREST).save(evidence / (label + '-ocr.png'))
            result = subprocess.run([os.environ['TESSERACT'], str(evidence / (label + '-ocr.png')),
                'stdout', '-l', 'eng', '--psm', '11', 'tsv'], capture_output=True, env=env, timeout=25)
            (evidence / (label + '-ocr.stderr')).write_bytes(result.stderr)
            require(result.returncode == 0, 'menu OCR failed')
            (evidence / (label + '.tsv')).write_bytes(result.stdout)
            lines = {}
            for row in csv.DictReader(io.StringIO(result.stdout.decode()), delimiter='\t'):
                if row.get('text', '').strip():
                    # TSV coordinates refer to the 2x observer image, not the
                    # actual client; map them back before ordinary XTest input.
                    for dimension in ('left', 'top', 'width', 'height'):
                        row[dimension] = str(round(int(row[dimension])/2))
                    key_ = tuple(row[k] for k in ('block_num', 'par_num', 'line_num'))
                    lines.setdefault(key_, []).append(row)
            return list(lines.values())

        def menu(label, phrase, click_it=True):
            lines = text_lines(label)
            normalized = lambda text: re.sub('[^a-z0-9]', '', text.lower())
            matches = [rows for rows in lines if normalized(phrase) in
                       normalized(' '.join(row['text'] for row in rows))]
            if phrase == 'English':
                # LangsTab has an English description above its button row;
                # CJK may be mis-segmented into that same OCR row. Anchor the
                # exact English word in the lower native selector row only.
                words = [row for rows in matches for row in rows
                         if normalized(row['text']) == 'english']
                matches = [[max(words, key=lambda row: int(row['top']))]] if words else []
            if not matches and phrase == 'Choose Your Hero' and not click_it:
                # native8's exact three-word OCR read ends Hera (o/a). Accept
                # only that observed substitution, and only with all six
                # source-layout portrait button boundaries independently seen.
                aliases = [rows for rows in lines if
                    normalized(' '.join(row['text'] for row in rows)) == 'chooseyourhera']
                require(len(aliases) == 1, 'hero heading absent, not the bounded observed o/a ambiguity')
                rows = aliases[0]
                rgb = np.asarray(Image.open(evidence / (label + '.png')).convert('RGB'))
                zoom = max(2, min(4, width//360, height//200))
                left_area = max(100, width/zoom/3)
                ui_height = min(height/zoom-20, 300)
                spacing = (ui_height-120)/2 - (5 if ui_height >= 160 else 0) - (6 if ui_height >= 180 else 0)
                heading_bottom = max(int(row['top'])+int(row['height']) for row in rows)
                x0 = round((left_area-103)/2*zoom)
                y0 = round(heading_bottom + spacing*zoom)
                button_height = (30 if ui_height >= 180 else 24)*zoom
                boundaries = []
                for row_index in range(2):
                    for column in range(3):
                        x = x0 + column*36*zoom
                        expected_y = y0 + row_index*(button_height+zoom)
                        candidates = []
                        for y in range(expected_y-2*zoom, expected_y+2*zoom+1):
                            inside = rgb[y, x+3*zoom:x+32*zoom].astype(np.int16)
                            outside = rgb[y-zoom, x+3*zoom:x+32*zoom].astype(np.int16)
                            contrast = float(np.mean(np.max(np.abs(inside-outside), axis=1) > 8))
                            candidates.append((contrast, y))
                        contrast, y = max(candidates)
                        require(contrast > .8, 'source-layout portrait top boundary absent')
                        interior = rgb[y+3*zoom:y+button_height-3*zoom,
                                       x+3*zoom:x+32*zoom]
                        require(len(np.unique(interior.reshape(-1, 3), axis=0)) >= 6,
                                'portrait button has no independently visible content')
                        boundaries.append(dict(column=column, row=row_index,
                            top=[x, y, x+35*zoom], contrast=contrast))
                proof['hero_heading_observation'] = dict(expected='Choose Your Hero',
                    ocr='Choose Your Hera', bounded_substitution='final o/a only',
                    source_layout_portrait_boundaries=boundaries)
                matches = aliases
            require(len(matches) == 1, 'ordinary UI phrase not unique: ' + phrase)
            rows = matches[0]
            left = min(int(row['left']) for row in rows)
            top = min(int(row['top']) for row in rows)
            right = max(int(row['left'])+int(row['width']) for row in rows)
            bottom = max(int(row['top'])+int(row['height']) for row in rows)
            if click_it:
                click((left+right)/2, (top+bottom)/2, phrase)
            return [left, top, right, bottom]

        def game_frame(label):
            # Fade, sprite animation and asynchronous camera panning settle
            # before each observation. No game function is called.
            time.sleep(1.5)
            rgb = frame(label)
            player = observer.locate(rgb)
            write_json(evidence / (label + '-sprite.json'), player)
            return rgb, player

        def save_menu(label):
            key('Escape')
            menu(label + '-game-menu', 'Main Menu')
            time.sleep(1)
            saved = native_save(state, evidence, label)
            proof['persisted'].append(saved)
            return saved

        def resume(label):
            menu(label + '-title', 'Enter the Dungeon')
            # Existing game slot avatar/name is the first Warrior in StartScene.
            menu(label + '-slots', 'Warrior')
            menu(label + '-continue', 'Continue')
            time.sleep(3)
            return game_frame(label + '-game')

        launch('game-first')
        menu('title-new', 'Enter the Dungeon')
        title_box = menu('hero-selection', 'Choose Your Hero', click_it=False)
        # Source layout: 6 heroes, 3 columns, 2 rows in left third. The
        # observed title bottom anchors the first portrait row, avoiding an
        # assumption that rendered text height equals its requested font size.
        max_scale = min(width//360, height//200)
        scale = max(2, min(4, max_scale))
        virtual_h, left_area = height/scale, max(100, width/scale/3)
        ui_height = min(virtual_h-20, 300)
        spacing = (ui_height-120)/2 - (5 if ui_height >= 160 else 0) - (6 if ui_height >= 180 else 0)
        portrait_x = (left_area - (35*3-2))/2 + 17
        portrait_y = title_box[3] + (spacing + (15 if ui_height >= 180 else 12))*scale
        click(portrait_x*scale, portrait_y, 'first ordinary Warrior portrait')
        menu('warrior-selected', 'Start')
        time.sleep(4)
        # A fresh character sees the upstream first-region story gate.
        # Its ordinary Continue button marks the intro read and fades into
        # GameScene (InterlevelScene); no preference/save injection bypass.
        menu('first-region-introduction', 'Continue')
        time.sleep(3)
        initial_rgb, initial_player = game_frame('new-character')
        # Fresh-state upstream tutorial disables Main Menu and hides the HUD
        # until its actual Guidebook is collected and Introduction read.
        # Match immutable MASTERY (index 62) opaque atlas pixels on the map.
        atlas = Image.open(io.BytesIO(item_bytes)).convert('RGBA')
        book = np.asarray(atlas.crop((224, 48, 237, 64)))
        by, bx = np.where(book[:, :, 3] == 255)
        colors = book[by, bx, :3].astype(np.int16)
        require(len(bx) >= 30, 'original guidebook atlas shape absent')
        book_scale = initial_player['scale']
        def locate_book(rgb):
            distance = np.max(np.abs(rgb.astype(np.int16)-colors[anchor]), axis=2)
            cy, cx = np.where(distance < 5)
            candidates = []
            for x, y in set(zip((cx-int(bx[anchor])*book_scale).tolist(),
                                (cy-int(by[anchor])*book_scale).tolist())):
                if not (0 <= x < width-13*book_scale and 40 < y < height-16*book_scale):
                    continue
                sampled = rgb[y+by*book_scale, x+bx*book_scale].astype(np.int16)
                score = float(np.mean(np.max(np.abs(sampled-colors), axis=1) < 6))
                if score >= .95:
                    candidates.append(dict(x=int(x), y=int(y), score=score))
            if not candidates:
                return None
            guide = max(candidates, key=lambda row: row['score'])
            require(all(abs(row['x']-guide['x']) < book_scale*2 and
                        abs(row['y']-guide['y']) < book_scale*2 for row in candidates),
                    'guidebook visual match not unique')
            return guide

        anchor = len(bx)//2
        guide = locate_book(initial_rgb)
        proof['tutorial_exploration'] = []
        # NORMAL entrance max10x10, no traps. Doors can be visible/passable;
        # this bounded keyboard search is a heuristic, not guaranteed room
        # confinement/coverage. Every step retains screenshot and exact sprite.
        sweep = ['Left']*8 + ['Up']*8
        for row in range(8):
            sweep += (['Right'] if row % 2 == 0 else ['Left'])*8 + ['Down']
        for index, direction in enumerate(sweep):
            if guide is not None:
                break
            key(direction)
            search_rgb, search_player = game_frame('tutorial-search-' + str(index))
            proof['tutorial_exploration'].append(dict(key=direction, player=search_player,
                frame='tutorial-search-' + str(index) + '.png'))
            guide = locate_book(search_rgb)
        require(guide is not None, 'entrance guidebook not visible after bounded genuine room exploration')
        proof['tutorial'] = dict(visible_book=guide, atlas='sprites/items.png',
            atlas_sha256=sha(item_bytes), source_rect=[224, 48, 237, 64],
            source_opaque_pixels=len(bx), normal_inputs=['map book click', 'journal J', 'Escape'])
        click(guide['x']+6*book_scale, guide['y']+8*book_scale,
              'walk to and collect visible entrance guidebook')
        time.sleep(5)
        frame('tutorial-guidebook-collected')
        key('j')
        menu('tutorial-introduction-read', 'Introduction', click_it=False)
        key('Escape')
        time.sleep(3)
        initial_rgb, initial_player = game_frame('tutorial-complete-character')
        # Baseline and all later snapshots are produced through Main Menu, not
        # by forcing autosave or touching the native files from this observer.
        baseline = save_menu('baseline')
        proof['initial_visible_HUD'] = hud_observer.health(
            initial_rgb, baseline['HP'], baseline['HT'], scale)
        before_rgb, before_player = resume('baseline-resume')
        baseline_projection = terrain_alignment(initial_rgb, before_rgb, initial_player,
            before_player, (before_player['x']-initial_player['x'], before_player['y']-initial_player['y']))
        require(baseline_projection['score'] >= .65, 'baseline resume terrain differs')
        proof['baseline_resume_projection'] = baseline_projection
        chosen = None
        for index, (name, dx, dy, opposite) in enumerate([
                ('Right', 1, 0, 'Left'), ('Down', 0, 1, 'Up'),
                ('Left', -1, 0, 'Right'), ('Up', 0, -1, 'Down')]):
            key(name)
            after_rgb, after_player = game_frame('step-attempt-' + str(index))
            try:
                observation = movement(before_rgb, after_rgb, before_player, after_player, (dx, dy),
                    proof.setdefault('movement_hypotheses', []))
            except AssertionError as error:
                proof.setdefault('rejected_step_attempts', []).append(dict(key=name, reason=str(error)))
                # Failed attempted steps must demonstrably leave the same
                # player/terrain relation; otherwise never compound uncertainty.
                still = terrain_alignment(before_rgb, after_rgb, before_player, after_player,
                    (after_player['x']-before_player['x'], after_player['y']-before_player['y']))
                require(still['score'] >= .65, 'ambiguous movement attempt; refusing guessed state')
                before_rgb, before_player = after_rgb, after_player
                continue
            observation['key'] = name
            proof['moves'].append(observation)
            chosen = (name, dx, dy, opposite)
            break
        require(chosen, 'no observable adjacent one-tile movement')
        name, dx, dy, opposite = chosen
        moved = save_menu('moved')
        require(moved['width'] == baseline['width'] and
                moved['pos'] - baseline['pos'] == dx + dy*baseline['width'],
                'native persisted position differs from actual visible one-tile step')
        require(moved['duration'] > baseline['duration'], 'ordinary step did not advance saved game turns')
        proof['turn_progress'] = dict(method='READ-ONLY native menu-produced Statistics.duration',
                                     before=baseline['duration'], after=moved['duration'])
        # Quit while on TitleScene using the same ICCCM Close as a WM button.
        frame('saved-title-before-close')
        capture.close_window(window)
        status = process.wait(timeout=25)
        require(status == 0, 'first ordinary window close failed')
        proof['first_clean_exit'] = status
        launch('game-second')
        resumed_rgb, resumed_player = resume('relaunch-resume')
        aligned = terrain_alignment(after_rgb, resumed_rgb, after_player, resumed_player,
            (resumed_player['x']-after_player['x'], resumed_player['y']-after_player['y']))
        require(aligned['score'] >= .65 and aligned['exact_textured_samples'] >= 500 and
                aligned['distinct_colors'] >= 12, 'resumed visible player position/terrain differs')
        proof['resume_visible_projection'] = aligned
        resumed_save = save_menu('resumed-before-next-input')
        require(resumed_save['pos'] == moved['pos'] and
                resumed_save['duration'] == moved['duration'],
                'ordinary relaunch/continue did not preserve saved position and turn')
        proof['resumed_visible_HUD'] = hud_observer.health(
            resumed_rgb, resumed_save['HP'], resumed_save['HT'], scale)
        resumed_rgb, resumed_player = resume('resumed-confirmed')
        # Reverse the known successful edge, rather than relying on randomized
        # dungeon generation to make another direction walkable.
        key(opposite)
        continued_rgb, continued_player = game_frame('continued-after-resume')
        continued = movement(resumed_rgb, continued_rgb, resumed_player, continued_player, (-dx, -dy),
            proof.setdefault('movement_hypotheses', []))
        continued['key'] = opposite
        proof['moves'].append(continued)
        final_save = save_menu('continued')
        require(final_save['pos'] == baseline['pos'] and final_save['duration'] > moved['duration'],
                'resume did not continue the same live character with another turn')
        # Upstream registers exactly English and Chinese. Exercise both
        # through real settings; resource translations not registered in the
        # source enum are not invented as extra selectable UI languages.
        menu('font-settings-open', 'Settings')
        settings_rgb = frame('font-settings-display')
        # WndTabbed handles ordinary Tab (SPDAction.CYCLE). Settings starts
        # on Display; six desktop tabs place Languages five cycles on. The
        # unselected icon is source-clipped and 0.6-alpha, not opaque atlas.
        for index in range(5):
            key('Tab')
            frame('font-settings-tab-' + str(index+1))
        menu('font-language-heading', 'Language Settings', click_it=False)
        english_box = menu('font-language-selector', 'English', click_it=False)
        # LangsTab landscape 223px/6 columns =>36px buttons, 37px pitch.
        # Native C locale puts English first and source 中文 second.
        chinese_x = (english_box[0]+english_box[2])/2 + 37*scale
        chinese_y = (english_box[1]+english_box[3])/2
        selector_rgb = frame('font-latin-cjk-selector')
        label_crop = selector_rgb[round(chinese_y-5*scale):round(chinese_y+5*scale),
                                  round(chinese_x-7*scale):round(chinese_x+7*scale)]
        ink = np.min(label_crop, axis=2) > 150
        occupied_columns = np.any(ink, axis=0)
        runs, start_col = [], None
        for column, present in enumerate([*occupied_columns.tolist(), False]):
            if present and start_col is None:
                start_col = column
            elif not present and start_col is not None:
                runs.append((start_col, column))
                start_col = None
        require(len(runs) == 2 and all(np.sum(ink[:, l:r]) >= 15 for l, r in runs),
                'two visible Chinese selector glyphs absent')
        glyph_signatures = [sha(np.packbits(ink[:, l:r]).tobytes()) for l, r in runs]
        require(len(set(glyph_signatures)) == 2, 'Chinese selector repeats missing-glyph boxes')
        Image.fromarray(label_crop).save(evidence / 'font-chinese-selector-glyphs.png')
        click(chinese_x, chinese_y, 'ordinary upstream Chinese language choice')
        time.sleep(3)
        chinese_rgb = frame('font-chinese-title-menu')
        proof['native_font_UI'] = dict(registered_languages=['English', '中文'],
            selector='font-latin-cjk-selector.png', chinese_menu='font-chinese-title-menu.png',
            glyph_crop='font-chinese-selector-glyphs.png', distinct_CJK_glyph_signatures=glyph_signatures,
            source_language_navigation='five ordinary Tab cycles; WndTabbed/SPDAction.CYCLE',
            selection='ordinary settings XTest click',
            limits='Native UI Latin+CJK only; Cyrillic/Hangul not registered upstream and not claimed here')
        capture.close_window(window)
        status = process.wait(timeout=25)
        require(status == 0, 'final ordinary window close failed')
        proof['final_clean_exit'] = status
        require(recorder.poll() is None and audio.poll() is None, 'real audio path exited during game')
        recorder.terminate()
        recorder.wait(timeout=10)
        pcm = (evidence / 'audio-monitor.s16le').read_bytes()
        require(22050*4 <= len(pcm) <= 22050*4*600 and len(pcm) % 4 == 0,
                'real audio recording absent, unbounded or malformed')
        samples = np.frombuffer(pcm, dtype='<i2').astype(np.float64)
        rms = float(np.sqrt(np.mean(samples*samples)))
        nonzero = float(np.mean(np.abs(samples) > 16))
        require(rms > 50 and nonzero > .01, 'actual game sink monitor remained silent')
        with wave.open(str(evidence / 'audio-monitor.wav'), 'wb') as wav:
            wav.setnchannels(2)
            wav.setsampwidth(2)
            wav.setframerate(22050)
            wav.writeframes(pcm)
        proof['audio'] = dict(server='private real PulseAudio', sink='exppd_proof',
            monitor='exppd_proof.monitor', wav='audio-monitor.wav', sha256=sha(pcm),
            rate=22050, channels=2, seconds=len(pcm)/(22050*4), rms=rms,
            fraction_above_16=nonzero, claim='actual non-silent native game audio, not tune identification')
        bad = re.compile(r'(?i)exception|unsatisfiedlink|could not|cannot|failed|fatal|segmentation|'
                         r'error|warning|AL_INVALID|GL_INVALID|GLFW_.*ERROR')
        for label in ('game-first', 'game-second'):
            log = (evidence / (label + '.log')).read_text(errors='replace')
            require(not bad.search(log), 'native diagnostic in ' + label + '.log')
        require(not list(work.iterdir()), 'game polluted working directory')
        proof['mutable_files'] = {str(path.relative_to(root)): dict(
            size=path.stat().st_size, sha256=sha(path.read_bytes()))
            for path in root.rglob('*') if path.is_file() and not path.is_symlink()}
        require(any(key.endswith('game1/game.dat') for key in proof['mutable_files']),
                'normal native save evidence absent')
        proof['native_diagnostic_scan'] = 'both game stdout/stderr logs rejected errors and warnings'
        proof['success'] = True
    except Exception as error:
        proof['error'] = str(error)
        proof['traceback'] = traceback.format_exc()
        raise
    finally:
        if capture:
            capture.lib.XCloseDisplay(capture.display)
        for child in reversed(processes):
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait(timeout=5)
        # Failure diagnostics/native state survive too. These are evidence
        # copies, never files read back by the game, and never fixture input.
        if state is not None:
            for path in root.rglob('*'):
                if path.is_file() and not path.is_symlink():
                    destination = evidence / 'private-state' / path.relative_to(root)
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    destination.write_bytes(path.read_bytes())
        if (evidence / 'xvfb.log').exists():
            server_log = (evidence / 'xvfb.log').read_text(errors='replace')
            proof['xvfb_diagnostics'] = dict(log='xvfb.log', separate_from_game_logs=True,
                lines=[line for line in server_log.splitlines()
                       if re.search(r'(?i)warning|error|failed|fatal|amdgpu', line)],
                classification='display-server diagnostics retained separately; game logs remain strict')
        write_json(evidence / 'native-gameplay.json', proof)
        os.close(evidence_descriptor)
    print('ExpPD: ordinary new warrior, visible tile steps, native save/quit/relaunch/resume and clean exit')


if __name__ == '__main__':
    main()
