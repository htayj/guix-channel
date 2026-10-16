#!/usr/bin/env python3
"""Native proof for Exalt's 0.3.0 archive (internal 0.3.1), observing X11 glyphs.

No saves, seeds, configuration, game code, private APIs or process memory are
injected. Bundled Test World has fixed terrain/start; native item placement is
unseeded. InitLoadedGame is unimplemented: no save/resume claim is made.
SDL_ttf is used only to read the installed font into independent glyph masks;
all game observations are ordinary XGetImage screenshots, not renderer hooks.
Typography uses the documented Guix Liberation Mono replacement, not upstream
1.04 font bytes; original-pixel equivalence is deliberately not claimed.
"""
import ctypes as C
import hashlib
import json
import os
from pathlib import Path
import re
import select
import struct
import subprocess
import sys
import time
import traceback
import zlib

SOURCE_HASHES = {'src/mainstate.cpp': '060c76a216f83cf069e8c5ca6c0d9b4a8a1f10db4a1bd7003f3c1ad9d242b72b', 'src/birthstate.cpp': 'c4acdc693a146f7086d58fef297ff93377ffdf5fcbf9ad67a18f58d5b35fbe5e', 'src/cmd.cpp': 'd47b46608a185775c7f70fe0bbcd02c8a42ae0f7a4356e726900703c898ad88e', 'src/gamestate.cpp': 'b9b9ec5a43f69542b6b80c50295ba4bccc47a50ebe8010951d06f25302ea4854', 'src/maindisplay.cpp': 'f064af43233f432ef6b507355079cbffa2e5c32cdd234800315a774d7443ed8c', 'src/maindisplay.h': '347bc1c3977361664e66e396b73c21fb166f51e3f455f3e29853e4911bd307d1', 'src/pc.cpp': '55786cbcbf4c4d7414fdaf976254b5f7b481d7afb575b09be26d34f194390834', 'src/terminal.h': 'dd973d3e7a83115afdaa6566de1a52a41f2f9f19b1ce3cb7f385b797c280d8e1', 'src/helpstate.cpp': '5f45474e257009996a96a5283005fbbbd6deca860acd02a10bdc2a11777fdef0', 'data/worlds/test/world.txt': 'dc26ddc964c92a5a796f7037cea0993e9552ae931e0b4a6ef520122343b64dd9', 'data/worlds/test/areas/simple.txt': '50e61b05f9312d57f66dda8bfa5a943eb74d3896db431deb8e47e78493505acb', 'data/help/commands.txt': '0503ab73a72698cc874681fd430d160cb51925fa31bb7c1e4630f0a1bf6156da'}
SOURCE_HASHES.update({
    'src/simplegen.cpp': 'b304f82a63df1d1bdcec41579684f7d00a457179d2ae226ac4f52c9f97109f8c',
    'src/areadef.h': 'd549216d8cf9ae56b9505aac0eb62941e4240f588b4210db5a48a966856229f7',
    'src/menubox.cpp': '997b3e10e88005df4fc52df413e7c5a4ed0672852285d501b9457b3fbd133cd7',
    'src/compiledef.h': '73d4e0993a4afb66d9d28a68bfaeffe08f4c8ee4d6bfefcd8224aa6aff841593',
})


def require(value, message):
    if not value:
        raise AssertionError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def namespace_proof(proc, evidence):
    result = {}
    for kind, key in [('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                      ('net', 'HOST_NET_NS'), ('pid', 'HOST_PID_NS')]:
        value = os.readlink(proc / 'ns' / kind)
        require(value != os.environ[key], 'host namespace leaked: ' + kind)
        require(value == os.readlink('/proc/self/ns/' + kind), 'namespace escape: ' + kind)
        result[kind] = value
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid'):
            identity[key] = [int(x) for x in value.split()]
    for label, key in [('Uid', 'HOST_UID'), ('Gid', 'HOST_GID')]:
        require(identity[label] == [int(os.environ[key])] * 4, 'caller identity changed')
    for filename, key in [('uid_map', 'HOST_UID'), ('gid_map', 'HOST_GID')]:
        mapping = (proc / filename).read_text()
        require([int(x) for x in mapping.split()] ==
                [int(os.environ[key]), int(os.environ[key]), 1], 'not map-current-user')
        result[filename] = mapping
    dev, routes = (proc / 'net/dev').read_text(), (proc / 'net/route').read_text()
    interfaces = sorted(line.split(':')[0].strip() for line in dev.splitlines()[2:]
                        if ':' in line)
    require(interfaces == ['lo'] and len(routes.splitlines()) <= 1, 'network not isolated')
    result.update(identity=identity, interfaces=interfaces, net_dev=dev, net_route=routes)
    write_json(evidence / ('namespace-' + proc.name + '.json'), result)
    return result


def isolate_mounts(evidence):
    commands = []

    def mount(*args):
        result = subprocess.run([os.environ['MOUNT'], *args], capture_output=True,
                                text=True, timeout=15)
        commands.append(dict(command=[os.environ['MOUNT'], *args], status=result.returncode,
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
                         for _, opts, optional in found), 'store not private read-only')
    (evidence / 'mountinfo-after.txt').write_text(text)
    descriptor = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    try:
        source = '/proc/' + str(os.getpid()) + '/fd/' + str(descriptor)
        evidence = Path(source)
        mount('-t', 'tmpfs', '-o', 'nosuid,nodev', 'tmpfs', '/tmp')
        retained = Path('/tmp/exalt-evidence')
        retained.mkdir()
        mount('--bind', source, str(retained))
    finally:
        os.close(descriptor)
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
            h = C.cast(image, C.POINTER(XImage)).contents
            require((h.width, h.height, h.depth, h.bits_per_pixel, h.byte_order,
                     h.red_mask, h.green_mask, h.blue_mask) ==
                    (width, height, 24, 32, 0, 0xff0000, 0xff00, 0xff),
                    'native framebuffer format changed')
            raw = C.string_at(h.data, h.bytes_per_line * height)
            rgb = bytearray(width * height * 3)
            for y in range(height):
                row = raw[y * h.bytes_per_line:y * h.bytes_per_line + width * 4]
                offset = y * width * 3
                rgb[offset:offset + width * 3:3] = row[2::4]
                rgb[offset + 1:offset + width * 3:3] = row[1::4]
                rgb[offset + 2:offset + width * 3:3] = row[0::4]
            return bytes(rgb)
        finally:
            self.lib.XDestroyImage(image)

    def close_window(self, window):
        # The same ICCCM message as an ordinary window-manager Close button.
        event = XEvent()
        event.client.type = 33
        event.client.send_event = 1
        event.client.display = self.display
        event.client.window = window
        event.client.message_type = self.lib.XInternAtom(self.display, b'WM_PROTOCOLS', 0)
        event.client.format = 32
        event.client.data.l[0] = self.lib.XInternAtom(self.display, b'WM_DELETE_WINDOW', 0)
        event.client.data.l[1] = 0
        require(self.lib.XSendEvent(self.display, window, 0, 0, C.byref(event)),
                'normal WM_DELETE_WINDOW send failed')
        self.lib.XFlush(self.display)


def save_png(path, rgb, width, height):
    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body))
    rows = b''.join(b'\0' + rgb[y * width * 3:(y + 1) * width * 3] for y in range(height))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' +
                     chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) +
                     chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


class SDLRect(C.Structure):
    _fields_ = [('x', C.c_int), ('y', C.c_int), ('w', C.c_int), ('h', C.c_int)]


class SDLSurface(C.Structure):
    _fields_ = [('flags', C.c_uint32), ('format', C.c_void_p), ('w', C.c_int),
                ('h', C.c_int), ('pitch', C.c_int), ('pixels', C.c_void_p),
                ('userdata', C.c_void_p), ('locked', C.c_int), ('list_blitmap', C.c_void_p),
                ('clip_rect', SDLRect), ('map', C.c_void_p), ('refcount', C.c_int)]


class SDLColor(C.Structure):
    _fields_ = [('r', C.c_uint8), ('g', C.c_uint8), ('b', C.c_uint8), ('a', C.c_uint8)]


class FontObserver:
    """Independent read-only font rasterization, never loading the game binary."""
    def __init__(self, path):
        self.sdl, self.ttf = C.CDLL(os.environ['LIBSDL']), C.CDLL(os.environ['LIBTTF'])
        signatures = [
            (self.ttf, 'TTF_Init', [], C.c_int),
            (self.ttf, 'TTF_OpenFont', [C.c_char_p, C.c_int], C.c_void_p),
            (self.ttf, 'TTF_CloseFont', [C.c_void_p], None),
            (self.ttf, 'TTF_FontHeight', [C.c_void_p], C.c_int),
            (self.ttf, 'TTF_GlyphIsProvided', [C.c_void_p, C.c_uint16], C.c_int),
            (self.ttf, 'TTF_GlyphMetrics', [C.c_void_p, C.c_uint16] +
                [C.POINTER(C.c_int)] * 5, C.c_int),
            (self.ttf, 'TTF_RenderGlyph_Blended', [C.c_void_p, C.c_uint16, SDLColor],
                C.POINTER(SDLSurface)),
            (self.sdl, 'SDL_GetRGBA', [C.c_uint32, C.c_void_p] +
                [C.POINTER(C.c_uint8)] * 4, None),
            (self.sdl, 'SDL_FreeSurface', [C.POINTER(SDLSurface)], None)]
        for lib, name, args, result in signatures:
            function = getattr(lib, name)
            function.argtypes, function.restype = args, result
        require(self.ttf.TTF_Init() == 0, 'observer TTF_Init failed')
        for point in range(14, 0, -1):
            font = self.ttf.TTF_OpenFont(os.fsencode(path), point)
            require(font, 'cannot read installed Liberation Mono font')
            width, height = 0, self.ttf.TTF_FontHeight(font)
            for byte in range(32, 256):
                code = self.codepoint(byte)
                if self.ttf.TTF_GlyphIsProvided(font, code):
                    metrics = [C.c_int() for _ in range(5)]
                    require(self.ttf.TTF_GlyphMetrics(font, code,
                            *(C.byref(x) for x in metrics)) == 0, 'glyph metrics failed')
                    minx, maxx, _, _, advance = [x.value for x in metrics]
                    width = max(width, advance, maxx - min(0, minx))
            if 0 < width <= 9 and 0 < height <= 14:
                self.cw, self.ch, self.point = width, height, point
                break
            self.ttf.TTF_CloseFont(font)
        else:
            raise AssertionError('original font cannot fit requested 9x14 cells')
        self.templates = {}
        try:
            for code in range(33, 127):
                surface = self.ttf.TTF_RenderGlyph_Blended(font, code, SDLColor(255, 255, 255, 255))
                require(surface, 'font observer failed ASCII glyph ' + chr(code))
                try:
                    s = surface.contents
                    mask = [0] * (self.cw * self.ch)
                    require(s.w <= self.cw and s.h <= self.ch, 'glyph exceeds fitted cell')
                    raw = C.string_at(s.pixels, s.pitch * s.h)
                    for y in range(s.h):
                        for x in range(s.w):
                            rgba = [C.c_uint8() for _ in range(4)]
                            pixel = int.from_bytes(raw[y * s.pitch + x * 4:y * s.pitch + x * 4 + 4],
                                                   sys.byteorder)
                            self.sdl.SDL_GetRGBA(pixel, s.format, *(C.byref(v) for v in rgba))
                            target = (y + self.ch - s.h) * self.cw + x + (self.cw - s.w) // 2
                            mask[target] = rgba[3].value
                    peak = max(mask)
                    require(peak > 0, 'empty ASCII glyph')
                    self.templates[chr(code)] = tuple(v / peak for v in mask)
                finally:
                    self.sdl.SDL_FreeSurface(surface)
        finally:
            self.ttf.TTF_CloseFont(font)
        self.cache = {}

    @staticmethod
    def codepoint(byte):
        if 0x80 <= byte <= 0x9f:
            try:
                return ord(bytes([byte]).decode('cp1252'))
            except UnicodeDecodeError:
                return byte
        return byte

    def surface(self, rgb, width, height):
        cols, rows = min(256, width // self.cw), min(256, height // self.ch)
        lines, colours = [], {}
        for row in range(rows):
            line = []
            for col in range(cols):
                pixels = []
                for y in range(self.ch):
                    py = 4 + row * self.ch + y
                    for x in range(self.cw):
                        px = 2 + col * self.cw + x
                        offset = (py * width + px) * 3
                        pixels.append(tuple(rgb[offset:offset + 3]) if
                                      px < width - 2 and py < height - 4 else (0, 0, 0))
                levels = tuple(max(p) for p in pixels)
                peak = max(levels)
                if peak == 0:
                    glyph = ' '
                elif levels in self.cache:
                    glyph = self.cache[levels]
                else:
                    normalized = [v / peak for v in levels]
                    errors = sorted((sum((a - b) ** 2 for a, b in zip(normalized, mask)) /
                                     len(mask), char) for char, mask in self.templates.items())
                    glyph = errors[0][1] if errors[0][0] < .0025 else '~'
                    self.cache[levels] = glyph
                line.append(glyph)
                if glyph == '@':
                    colours[(col, row)] = list(pixels[levels.index(peak)])
            lines.append(''.join(line))
        return lines, colours


def main():
    require(len(sys.argv) == 3, 'usage: exalt-native.py OUTPUT EVIDENCE')
    output, evidence = map(Path, sys.argv[1:])
    proof = dict(success=False, output=str(output), injected_state=False,
        movement_observation='exact visible player glyph displacement against original terrain landmarks',
        claim_limits=[
            'Pre-alpha 0.3.0: InitLoadedGame, Open Character and Retire Character are unimplemented.',
            'No save/load/resume, combat, victory or complete-game claim.',
            'Bundled Test World has fixed starting terrain and position; ordinary native items are randomized.',
            'Guix Liberation Mono 2.1.5 replaces uncleared bundled 1.04; no original-pixel equivalence claim.',
            'Auxiliary windows are toggled as upstream implements them; populated auxiliary content is not claimed.'])
    assets = output / 'share/exalt'
    source = assets / 'source'
    processes = []
    capture = None
    state = None
    try:
        proof['driver_namespace'] = namespace_proof(Path('/proc/self'), evidence)
        for name, expected in SOURCE_HASHES.items():
            require(sha((source / name).read_bytes()) == expected, 'original observation source differs: ' + name)
        proof['original_source_sha256'] = SOURCE_HASHES
        version_source = (source / 'src/compiledef.h').read_text()
        version = []
        for name in ('MAJOR_VERSION', 'MINOR_VERSION', 'BUILD'):
            match = re.search(r'const\s+int\s+' + name + r'\s*=\s*(\d+)\s*;', version_source)
            require(match, 'missing original internal version constant: ' + name)
            version.append(match.group(1))
        internal_version = '.'.join(version)
        proof['version'] = dict(archive='0.3.0', internal=internal_version,
                                source='src/compiledef.h')
        require((output / 'share/doc/exalt').is_dir(), 'license notices missing')
        for path in output.rglob('*'):
            require(path.suffix.lower() not in ('.exe', '.dll'), 'foreign binary installed')
        terrain = [line for line in (source / 'data/worlds/test/areas/simple.txt').read_text().splitlines()
                   if re.fullmatch(r'[x.@]+', line)]
        require(len(terrain) == 23 and all(len(row) == 43 for row in terrain), 'original terrain differs')
        starts = [(x, y) for y, row in enumerate(terrain) for x, char in enumerate(row) if char == '@']
        require(len(starts) == 1, 'original start ambiguous')
        world_start = starts[0]
        font_path = assets / 'data/fonts/liberation.ttf'
        font_target = font_path.resolve()
        require(font_path.is_symlink() and font_target.is_relative_to('/gnu/store') and
                font_target.name == 'LiberationMono-Regular.ttf' and
                re.fullmatch(r'[a-z0-9]{32}-font-liberation-2\.1\.5', font_target.parts[3]),
                'font not linked to the selected Guix Liberation Mono 2.1.5 dependency')
        require((output / 'share/doc/exalt/LIBERATION-LICENSE.txt').is_file(),
                'selected Liberation font license missing')
        observer = FontObserver(font_path)
        proof['font'] = dict(path=str(font_path), resolved_path=str(font_path.resolve()),
            sha256=sha(font_path.read_bytes()), family='Liberation Mono', version='2.1.5',
            measured_cell=[observer.cw, observer.ch], point_size=observer.point,
            substitution='Guix Liberation Mono; upstream bundled 1.04 excluded; no exact-pixel claim',
            method='independent SDL_ttf alpha masks matched to native X11 screenshots')
        evidence, store_mounts = isolate_mounts(evidence)
        proof['store_read_only_mounts'] = store_mounts
        root = Path('/tmp/exalt-private')
        root.mkdir(mode=0o700)
        dirs = {}
        for variable, name in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'),
                ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime'), ('TMPDIR', 'tmp')]:
            dirs[variable] = root / name
            dirs[variable].mkdir(mode=0o700)
        work = root / 'work'
        work.mkdir(mode=0o700)
        env = dict(os.environ, **{k: str(v) for k, v in dirs.items()})
        env.update(SDL_VIDEODRIVER='x11', SDL_AUDIODRIVER='dummy', SDL_RENDER_DRIVER='software',
            LIBGL_ALWAYS_SOFTWARE='1', MESA_SHADER_CACHE_DISABLE='true',
            DBUS_SESSION_BUS_ADDRESS='unix:path=/run/no-session-bus',
            DBUS_SYSTEM_BUS_ADDRESS='unix:path=/run/no-system-bus')
        state = dirs['XDG_DATA_HOME'] / 'exalt'
        require(not state.exists(), 'initial state is not fresh')
        Path('/tmp/.X11-unix').mkdir(mode=0o1777)

        def start(label, command, **kwargs):
            with (evidence / (label + '.log')).open('wb') as log:
                child = subprocess.Popen(command, cwd=work, env=env, stdin=subprocess.DEVNULL,
                                         stdout=log, stderr=log, **kwargs)
            processes.append(child)
            return child

        def tool(*args):
            return subprocess.check_output([os.environ['XDOTOOL'], *map(str, args)], env=env,
                                           stderr=subprocess.PIPE, timeout=10)

        def visible(title):
            result = subprocess.run([os.environ['XDOTOOL'], 'search', '--onlyvisible',
                '--name', '^' + title + '$'], env=env, capture_output=True, timeout=5)
            require(result.returncode in (0, 1), 'X11 window discovery failed')
            return result.stdout.decode().splitlines() if result.returncode == 0 else []

        def key(name):
            require(process.poll() is None, 'game exited before input ' + name)
            tool('windowfocus', '--sync', window)
            tool('key', '--clearmodifiers', '--delay', '70', name)
            time.sleep(.35)

        readfd, writefd = os.pipe()
        try:
            server = start('xvfb', [os.environ['XVFB'], '-displayfd', str(writefd),
                '-screen', '0', '1280x900x24', '-nolisten', 'tcp', '-noreset'], pass_fds=(writefd,))
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
        process = start('game', [str(output / 'bin/exalt')])
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            require(process.poll() is None, 'native game exited before main menu')
            windows = visible('Exalt')
            if len(windows) == 1:
                window = windows[0]
                break
            time.sleep(.15)
        else:
            raise AssertionError('main window readiness timed out')
        time.sleep(.5)
        proc = Path('/proc') / str(process.pid)
        proof['game_namespace'] = namespace_proof(proc, evidence)
        require(Path(os.readlink(proc / 'exe')).resolve() == (output / 'libexec/exalt').resolve(),
                'launcher did not exec installed game')
        require(Path(os.readlink(proc / 'cwd')) == state, 'game working directory not private state')
        (evidence / 'game-mountinfo.txt').write_text((proc / 'mountinfo').read_text())
        proof['launch'] = dict(pid=process.pid, executable=os.readlink(proc / 'exe'),
                               cwd=os.readlink(proc / 'cwd'))
        width, height = 724, 428
        geometry = tool('getwindowgeometry', '--shell', window).decode()
        require('WIDTH=724\n' in geometry and 'HEIGHT=428\n' in geometry,
                'original initial client dimensions changed: ' + geometry)
        (evidence / 'main-window-geometry.txt').write_text(geometry)
        proof['frames'] = []
        captured_frames = {}

        def frame(label, target=None):
            require(process.poll() is None, 'native game exited during ' + label)
            rgb = capture.capture(int(target or window), width, height)
            save_png(evidence / (label + '.png'), rgb, width, height)
            captured_frames[label] = (rgb, width, height)
            rows, colours = observer.surface(rgb, width, height)
            text = '\n'.join(rows)
            (evidence / (label + '-surface.txt')).write_text(text + '\n')
            require(not re.search(r'(?i)fatal error|assertion failed|segmentation fault|initialization failed', text),
                    'native error visible in framebuffer')
            proof['frames'].append(dict(label=label, window=int(target or window),
                screenshot=label + '.png', surface=label + '-surface.txt', sha256=sha(rgb)))
            return rows, colours

        def expect(label, *phrases):
            rows, colours = frame(label)
            for phrase in phrases:
                require(phrase in '\n'.join(rows), 'ordinary UI missing ' + repr(phrase) + ' in ' + label)
            return rows, colours

        expect('main-menu', 'Main Menu', 'New Character', 'Open Character', 'v ' + internal_version)
        require(all(not visible(name) for name in ('Inventory', 'Equipment', 'Messages', 'Minimap')),
                'auxiliary windows initially visible')
        key('a')
        expect('race-menu', 'Choose your race', 'Human', 'Half-Giant')
        key('a')
        expect('name-prompt', 'Enter your name')
        # Real text/key events into the ordinary birth Prompt, not a state file.
        tool('windowfocus', '--sync', window)
        tool('type', '--clearmodifiers', '--delay', '100', 'NativeProof')
        time.sleep(.3)
        expect('name-entered', 'NativeProof')
        key('Return')
        expect('world-selection', 'World Selection', 'test')
        key('a')
        rows, colours = expect('new-game', 'NativeProof')
        cols, row_count = len(rows[0]), len(rows)
        map_width = cols - 22
        center = (map_width // 2, (row_count - 2) // 2 + 2)
        camera = (world_start[0] - center[0], world_start[1] - (center[1] - 2))

        def player(rows, colours):
            positions = [(x, y) for y, row in enumerate(rows) for x, char in enumerate(row[:map_width])
                         if y >= 2 and char == '@' and (lambda rgb: rgb is not None and
                             rgb[0] == rgb[1] > 0 and rgb[2] == 0)(colours.get((x, y)))]
            require(len(positions) == 1, 'unique original yellow @ player glyph not observed')
            # The yellow source foreground is alpha blended: this font's @
            # has no opaque pixel (observed peak 219,219,0 at 12 points).
            # Require its exact yellow channel ratio, not an opaque 255 peak;
            # independently matched glyph shape and exact displacement remain
            # mandatory, so arbitrary changed pixels cannot pass this proof.
            return positions[0]

        require(player(rows, colours) == center, 'original initial camera/player mapping differs')
        proof['initial_player'] = dict(world=list(world_start), screen=list(center), camera=list(camera),
            observed_peak_rgb=colours[center], source_foreground_bgr='0x0000FFFF')
        moves = []
        for keyname, dx, dy, opposite in [('Right', 1, 0, 'Left'), ('Left', -1, 0, 'Right'),
                                         ('Down', 0, 1, 'Up'), ('Up', 0, -1, 'Down')]:
            nx, ny = center[0] + dx, center[1] + dy
            wx, wy = world_start[0] + dx, world_start[1] + dy
            if terrain[wy][wx] in '.@' and rows[ny][nx] == '.':
                choice = (keyname, dx, dy, opposite)
                break
        else:
            raise AssertionError('no source-backed visible adjacent floor in ordinary world')
        keyname, dx, dy, opposite = choice
        original_rows = rows
        key(keyname)
        moved_rows, moved_colours = expect('moved-one-cell', 'NativeProof')
        destination = player(moved_rows, moved_colours)
        require(destination == (center[0] + dx, center[1] + dy),
                'directional input did not move actual visible player by exactly one cell')
        require(moved_rows[center[1]][center[0]] == '.', 'old player cell did not reveal original floor')
        # Stable original terrain proves this is player displacement, not camera
        # translation or a changed timer/pixel region. Unknown/hidden cells are
        # never asserted to be floor. The original map is observation only.
        landmarks = []
        for sy in range(2, row_count - 1):
            for sx in range(map_width - 1):
                wx, wy = camera[0] + sx, camera[1] + sy - 2
                if not (0 <= wy < len(terrain) and 0 <= wx < len(terrain[wy])):
                    continue
                expected = '#' if terrain[wy][wx] == 'x' else '.'
                if original_rows[sy][sx] == moved_rows[sy][sx] == expected:
                    landmarks.append(dict(screen=[sx, sy], world=[wx, wy], glyph=expected))
        require(len(landmarks) >= 12 and any(x['glyph'] == '#' for x in landmarks) and
                any(x['glyph'] == '.' for x in landmarks), 'insufficient stable source-backed wall/floor landmarks')
        moves.append(dict(key=keyname, screen_before=list(center), screen_after=list(destination),
            world_before=list(world_start), world_after=[world_start[0] + dx, world_start[1] + dy],
            source_walkable_glyph=terrain[world_start[1] + dy][world_start[0] + dx],
            old_cell_revealed='.', stable_landmarks=landmarks))
        key(opposite)
        returned_rows, returned_colours = expect('returned-one-cell', 'NativeProof')
        require(player(returned_rows, returned_colours) == center and
                returned_rows[destination[1]][destination[0]] == '.', 'ordinary reverse movement not proved')
        moves.append(dict(key=opposite, screen_before=list(destination), screen_after=list(center),
                          world_after=list(world_start), destination_revealed='.'))
        proof['movement'] = moves
        write_json(evidence / 'movement.json', moves)

        proof['resizes'] = []
        for label, new_width, new_height in [('enlarged', 814, 484), ('restored', 724, 428)]:
            tool('windowsize', '--sync', window, new_width, new_height)
            time.sleep(.5)
            geometry = tool('getwindowgeometry', '--shell', window).decode()
            require('WIDTH=' + str(new_width) + '\n' in geometry and
                    'HEIGHT=' + str(new_height) + '\n' in geometry,
                    'ordinary main-window resize geometry not applied')
            (evidence / ('resize-' + label + '-geometry.txt')).write_text(geometry)
            width, height = new_width, new_height
            resized_rows, resized_colours = expect('resize-' + label, 'NativeProof')
            map_width = len(resized_rows[0]) - 22
            resized_center = (map_width // 2, (len(resized_rows) - 2) // 2 + 2)
            require(player(resized_rows, resized_colours) == resized_center,
                    'resized camera did not recenter the unchanged player')
            require(resized_rows[0][map_width + 1:].startswith('NativeProof'),
                    'resized HUD did not move to source-defined status column')
            resized_camera = (world_start[0] - resized_center[0],
                              world_start[1] - resized_center[1] + 2)
            matched = []
            for sy, row in enumerate(resized_rows[2:], 2):
                for sx, glyph in enumerate(row[:map_width]):
                    wx, wy = resized_camera[0] + sx, resized_camera[1] + sy - 2
                    if 0 <= wy < len(terrain) and 0 <= wx < len(terrain[wy]):
                        expected = '#' if terrain[wy][wx] == 'x' else '.'
                        if glyph == expected:
                            matched.append(dict(screen=[sx, sy], world=[wx, wy], glyph=glyph))
            require(len(matched) >= 12 and any(x['glyph'] == '#' for x in matched) and
                    any(x['glyph'] == '.' for x in matched),
                    'resized terrain no longer maps to unchanged original world')
            proof['resizes'].append(dict(label=label, client=[width, height],
                grid=[len(resized_rows[0]), len(resized_rows)], player_screen=list(resized_center),
                player_world=list(world_start), stable_source_landmarks=matched))
        require(resized_center == center, 'restoring original client size did not restore player camera')

        def look_frames(label):
            frame(label)
            rgb, image_width, image_height = captured_frames[label]

            def cyan(x, y):
                offset = (y * image_width + x) * 3
                return rgb[offset:offset + 3] == b'\x00\xff\xff'

            boxes = []
            for cy in range(2, image_height // observer.ch - 1):
                for cx in range(map_width):
                    left, top = 2 + cx * observer.cw, 4 + cy * observer.ch
                    right, bottom = left + observer.cw - 1, top + observer.ch - 1
                    if all(cyan(x, y) for x, y in
                           [(x, top) for x in range(left, right + 1)] +
                           [(x, bottom) for x in range(left, right + 1)] +
                           [(left, y) for y in range(top + 1, bottom)] +
                           [(right, y) for y in range(top + 1, bottom)]):
                        boxes.append((cx, cy))
            return boxes

        key('l')
        require(look_frames('look-player') == [center],
                'ordinary look did not frame the player in exact cyan cell edges')
        key('6')
        look_right = (center[0] + 1, center[1])
        require(look_frames('look-right') == [look_right],
                'ordinary look cursor did not move exactly one cell right without a trail')
        key('4')
        require(look_frames('look-returned') == [center],
                'ordinary look cursor did not return without a trail')
        returned_look_text = (evidence / 'look-returned-surface.txt').read_text()
        require('You see yourself.' in returned_look_text, 'look did not describe the actual player')
        key('Escape')
        require(look_frames('look-cancelled') == [], 'look frame remained after Escape')
        look_rows, look_colours = expect('look-gameplay-restored', 'NativeProof')
        require(player(look_rows, look_colours) == center, 'look cursor moved actual player')
        proof['look'] = dict(keys=['l', '6', '4', 'Escape'],
            framed_cells=[list(center), list(look_right), list(center)],
            exact_cyan_perimeters=True, obsolete_frames_absent=True,
            player_world_unchanged=list(world_start), description='You see yourself.')

        key('i')
        expect('inventory', 'Inventory (', 'Equipment, ESC')
        key('backslash')
        expect('equipment-switched', 'Equipment (a-m,', 'Inventory, ESC')
        key('Escape')
        expect('equipment-cancelled', 'NativeProof')
        key('e')
        expect('equipment-direct', 'Equipment (a-m,', 'Inventory, ESC')
        key('Escape')
        key('question')
        expect('help-topics', 'Help Topics', 'Player Races', 'Commands')
        key('b')
        expect('help-commands', 'List of Commands', 'A list of commands.')
        key('Escape')
        expect('help-topics-returned', 'Help Topics')
        key('Escape')
        restored_rows, restored_colours = expect('help-cancelled', 'NativeProof')
        require(player(restored_rows, restored_colours) == center, 'UI did not restore gameplay player state')
        proof['auxiliary_windows'] = []
        for number, title in enumerate(('Inventory', 'Equipment', 'Messages', 'Minimap'), 1):
            key('F' + str(number))
            windows = visible(title)
            require(len(windows) == 1, 'F-key did not show ordinary auxiliary window ' + title)
            tool('windowraise', windows[0])
            time.sleep(.2)
            frame('aux-' + title.lower(), windows[0])
            capture.close_window(int(windows[0]))
            time.sleep(.35)
            require(process.poll() is None and not visible(title) and visible('Exalt') == [window],
                    'auxiliary WM_DELETE_WINDOW did not hide only ' + title)
            expect('aux-' + title.lower() + '-closed-main-alive', 'NativeProof')
            key('F' + str(number))
            reopened = visible(title)
            require(reopened == windows, 'F-key did not reopen same auxiliary window after Close: ' + title)
            tool('windowraise', reopened[0])
            time.sleep(.2)
            frame('aux-' + title.lower() + '-reopened', reopened[0])
            key('F' + str(number))
            require(not visible(title), 'F-key did not hide auxiliary window ' + title)
            proof['auxiliary_windows'].append(dict(title=title, key='F' + str(number),
                showed=True, hid=True, normal_close_hid_only_auxiliary=True,
                reopened_same_window=True, main_survived=True))
        final_rows, final_colours = expect('before-normal-close', 'NativeProof')
        require(player(final_rows, final_colours) == center, 'auxiliary toggles changed player position')
        capture.close_window(int(window))
        status = process.wait(timeout=20)
        require(status == 0, 'normal main-window close failed: ' + str(status))
        proof['normal_close'] = dict(method='ICCCM WM_DELETE_WINDOW main window', status=status)
        native_log = (state / 'log.xml').read_text(errors='replace')
        (evidence / 'native-log.xml').write_text(native_log)
        require('</Log>' in native_log, 'native logger did not finish normally')
        require(not re.search(r'<Level>\s*[12]\s*</Level>', native_log), 'native warning/critical diagnostic')
        messages = re.findall(r'<Msg>([^<]*)</Msg>', native_log)
        bad = r'(?i)error|failed|fatal|assert|segmentation|exception|could not|cannot|warning'
        require(not any(re.search(bad, text) for text in messages), 'native error diagnostic despite zero exit')
        require(not re.search(bad, (evidence / 'game.log').read_text(errors='replace')),
                'native stdout/stderr diagnostic despite zero exit')
        metric = re.search(r'measured cells (\d+)x(\d+)', native_log)
        # Original release OUTPUT_LEVEL=0x01|0x02 excludes INFO, including the
        # font metric line. Native glyph shape/placement and client geometry
        # above independently validate the fitted cells without changing that.
        if metric:
            require(tuple(map(int, metric.groups())) == (observer.cw, observer.ch),
                    'logged renderer metrics differ from independent installed font fit')
        proof['font']['native_info_log_metrics'] = list(map(int, metric.groups())) if metric else None
        proof['font']['metric_evidence'] = ('independent installed-font metrics, native X11 client '
            'geometry, matched visible glyph cells and exact source-backed player displacement; '
            'release logger naturally suppresses INFO')
        for name in ('display', 'fonts', 'help', 'templates', 'worlds', 'log.xsl'):
            link = state / 'data' / name
            require(link.is_symlink() and link.resolve() == assets / 'data' / name,
                    'asset not linked to immutable output: ' + name)
        require(set(x.name for x in state.iterdir()) == {'data', 'log.xml'}, 'unexpected mutable state root')
        require(set(x.name for x in (state / 'data').iterdir()) ==
                {'display', 'fonts', 'help', 'templates', 'worlds', 'log.xsl', 'db', 'save'},
                'unexpected mutable data paths')
        require((state / 'data/save').is_dir() and not (state / 'data/save').is_symlink(),
                'save directory not private')
        require((state / 'data/db').is_file() and not (state / 'data/db').is_symlink(),
                'SQLite database not a private regular file')
        require((state / 'data/save/NativeProof').is_dir(), 'ordinary new-character directory missing')
        require(not list(work.iterdir()) and list(dirs['XDG_DATA_HOME'].iterdir()) == [state],
                'game wrote outside private state')
        for name in ('HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME',
                     'XDG_RUNTIME_DIR', 'TMPDIR'):
            require(not list(dirs[name].iterdir()), 'game wrote outside private data: ' + name)
        proof['mutable_files'] = {str(p.relative_to(state)): dict(size=p.stat().st_size,
            sha256=sha(p.read_bytes())) for p in state.rglob('*') if p.is_file() and not p.is_symlink()}
        proof['success'] = True
    except Exception as error:
        proof['error'] = str(error)
        proof['traceback'] = traceback.format_exc()
        raise
    finally:
        # Preserve diagnostics on failures as well; terminate only this driver's
        # own processes, never any host service or rbw agent.
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
        if state and (state / 'log.xml').exists():
            (evidence / 'native-log.xml').write_bytes((state / 'log.xml').read_bytes())
        write_json(evidence / 'native-gameplay.json', proof)
    print('Exalt: ordinary birth/world, exact visible player movement, UI and normal close proved')


if __name__ == '__main__':
    main()
