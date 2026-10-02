#!/usr/bin/env python3
"""Original offline fixtures; test real FFglitch codecs, scripts and X11 surface."""

import ctypes
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

WIDTH, HEIGHT, FRAMES, RATE = 320, 240, 36, 12
FRAME_BYTES = WIDTH * HEIGHT * 3


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    require(len(sys.argv) == 10,
            "usage: helper OUTPUT ROOT ARTIFACTS FFMPEG FFPROBE XVFB XDOTOOL XWD CONVERT")
    output, root, evidence, ffmpeg, ffprobe, xvfb, xdotool, xwd, convert = sys.argv[1:]
    output, root, evidence = Path(output), Path(root), Path(evidence)
    namespaces = {}
    for kind, variable in (("user", "HOST_USER_NS"), ("mnt", "HOST_MOUNT_NS"),
                           ("net", "HOST_NET_NS"), ("pid", "HOST_PID_NS")):
        actual = os.readlink("/proc/self/ns/" + kind)
        require(actual != os.environ[variable], "host namespace leaked: " + kind)
        namespaces[kind] = actual
    interfaces = sorted(line.split(":", 1)[0].strip()
                        for line in Path("/proc/net/dev").read_text().splitlines()[2:])
    require(interfaces == ["lo"], "network namespace contains external interfaces")
    for path in (output, *output.rglob("*")):
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, "writable package path: " + str(path))

    # Bind already-open caller directories into private /tmp. X11 cannot reach
    # host sockets, and evidence is retained verbatim even when it lives in /tmp.
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
    libc = ctypes.CDLL(None, use_errno=True)
    libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                           ctypes.c_ulong, ctypes.c_void_p]
    libc.mount.restype = ctypes.c_int

    def mount(source, target, filesystem=None, flags=0):
        if libc.mount(os.fsencode(source), os.fsencode(target),
                      None if filesystem is None else os.fsencode(filesystem),
                      flags, None):
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error), str(target))

    try:
        mount("tmpfs", "/tmp", "tmpfs", 2 | 4)
        os.chmod("/tmp", 0o1777)
        root, evidence = Path("/tmp/ffglitch-root"), Path("/tmp/ffglitch-evidence")
        root.mkdir()
        evidence.mkdir()
        mount("/proc/self/fd/" + str(root_fd), root, flags=4096)
        mount("/proc/self/fd/" + str(evidence_fd), evidence, flags=4096)
        Path("/tmp/.X11-unix").mkdir(mode=0o1777)
    finally:
        os.close(root_fd)
        os.close(evidence_fd)
    for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                                ("TMPDIR", "tmp")):
        os.environ[variable] = str(root / directory)
    environment = dict(os.environ)
    environment.update(SDL_VIDEODRIVER="x11", SDL_AUDIODRIVER="dummy",
                       SDL_RENDER_DRIVER="software", LIBGL_ALWAYS_SOFTWARE="1",
                       MESA_SHADER_CACHE_DISABLE="true", PYTHONNOUSERSITE="1",
                       DBUS_SESSION_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-bus"),
                       DBUS_SYSTEM_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-system-bus"))
    commands = []

    def run(label, *args, timeout=45):
        args = list(map(str, args))
        commands.append({"label": label, "argv": args})
        (evidence / "commands.json").write_text(json.dumps(commands, indent=2) + "\n")
        with (evidence / (label + ".log")).open("wb") as log:
            result = subprocess.run(args, cwd=evidence, env=environment,
                                    stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
        require(result.returncode == 0, label + " failed; see retained log")
        return (evidence / (label + ".log")).read_bytes()

    ffgac, ffedit, fflive = (output / "bin" / name for name in ("ffgac", "ffedit", "fflive"))
    for name, executable in (("ffgac-version", ffgac), ("ffedit-version", ffedit),
                             ("fflive-version", fflive),
                             ("probe-version", output / "bin/ffglitch-ffprobe")):
        run(name, executable, "-version")
    run("independent-decoder-version", ffmpeg, "-version")

    messaging = evidence / "messaging.js"
    messaging.write_text('''import * as zmq from "zmq";
const context = new zmq.Context();
const sender = context.socket(zmq.PAIR);
const receiver = context.socket(zmq.PAIR);
sender.bind("inproc://ffglitch-original-proof");
receiver.connect("inproc://ffglitch-original-proof");
const payload = "FFglitch offline payload: 16,0";
sender.send(payload);
const received = receiver.recv_str();
if (received !== payload) throw new Error("ZeroMQ changed payload");
receiver.send(received + " / reply");
if (sender.recv_str() !== payload + " / reply")
  throw new Error("ZeroMQ changed reply");
sender.close();
receiver.close();
context.term();
console.log("ZeroMQ PAIR bidirectional payload verified");
''')
    run("quickjs-messaging", output / "libexec/ffglitch/qjs", messaging, timeout=10)

    # A static, colourful spatial pattern makes forced zero vectors useful:
    # otherwise a smart encoder would skip them. No copied upstream sample.
    image = bytearray()
    for y in range(HEIGHT):
        for x in range(WIDTH):
            image.extend(((x * 3 + y) % 256, (y * 5 + (x // 16) * 31) % 256,
                          ((x // 12 ^ y // 12) & 1) * 220 + 20))
    raw = evidence / "fixture.rgb"
    with raw.open("wb") as stream:
        for _ in range(FRAMES):
            stream.write(image)
    source = evidence / "source.avi"
    run("encode", ffgac, "-hide_banner", "-nostdin", "-y", "-f", "rawvideo",
        "-pixel_format", "rgb24", "-video_size", f"{WIDTH}x{HEIGHT}",
        "-framerate", RATE, "-i", raw, "-frames:v", FRAMES, "-an",
        "-c:v", "mpeg4", "-pix_fmt", "yuv420p", "-threads", "1", "-bf", "0",
        "-qscale:v", "2", "-mpv_flags", "+nopimb+forcemv", "-fcode", "6",
        "-g", "max", "-sc_threshold", "max", source)

    # One module, two setup parameters: genuine no-op and native bitstream edit.
    native = evidence / "native.js"
    native.write_text('''let mutate = false;
export function setup(args) {
  args.features.push("mv");
  mutate = args.params === true;
}
export function glitch_frame(frame) {
  if (mutate && frame.mv && frame.mv.forward)
    frame.mv.forward.fill(MV(16, 0));
}
''')
    videos = {"source": source}
    for label, parameter in (("control", "false"), ("glitched", "true")):
        videos[label] = evidence / (label + ".avi")
        run(label + "-edit", ffedit, "-threads", "1", "-i", source,
            "-s", native, "-sp", parameter, "-o", videos[label])
    require(videos["control"].read_bytes() == source.read_bytes(),
            "no-op script did not preserve the original bitstream")

    exported = evidence / "vectors.json"
    run("json-export", ffedit, "-threads", "1", "-i", source, "-f", "mv", "-e", exported)
    original_json = json.loads(exported.read_text())
    require(original_json["features"] == ["mv"], "wrong exported feature")
    require(original_json["streams"][0]["codec"] == "mpeg4", "wrong exported codec")
    require(len(original_json["streams"][0]["frames"]) == FRAMES,
            "export did not process every frame")
    vectors = [vector for frame in original_json["streams"][0]["frames"]
               for row in frame.get("mv", {}).get("forward", [])
               for vector in row if vector is not None]
    require(len(vectors) >= (FRAMES - 1) * (WIDTH // 16) * (HEIGHT // 16),
            "encoder did not write forced motion vectors for static macroblocks")
    videos["json-roundtrip"] = evidence / "json-roundtrip.avi"
    run("json-import", ffedit, "-threads", "1", "-i", source, "-f", "mv",
        "-a", exported, "-o", videos["json-roundtrip"])

    # Standalone upstream QuickJS driver uses plain JSON arrays, not native MV.
    plain_js = evidence / "json-transform.js"
    plain_js.write_text('''function glitch_frame(frame) {
  const rows = frame.mv && frame.mv.forward;
  if (!rows) return;
  for (const row of rows)
    for (let x = 0; x < row.length; ++x)
      if (row[x] !== null) row[x] = [16, 0];
}
''')
    changed_json = evidence / "standalone-js.json"
    run("standalone-js", output / "libexec/ffglitch/qjs",
        output / "share/ffglitch/ffglitch.js", "-i", exported, "-s", plain_js,
        "-o", changed_json)
    changed = json.loads(changed_json.read_text())
    require(changed["sha1sum"] == original_json["sha1sum"], "JSON source identity changed")
    changed_vectors = [vector for frame in changed["streams"][0]["frames"]
                       for row in frame.get("mv", {}).get("forward", [])
                       for vector in row if vector is not None]
    require(len(changed_vectors) == len(vectors) and
            all(vector == [16, 0] for vector in changed_vectors),
            "standalone JS did not transform motion vectors")
    videos["standalone-js"] = evidence / "standalone-js.avi"
    run("standalone-js-import", ffedit, "-threads", "1", "-i", source, "-f", "mv",
        "-a", changed_json, "-o", videos["standalone-js"])

    plain_py = evidence / "json-transform.py"
    plain_py.write_text('''def glitch_frame(feature):
    for row in feature.get("forward", []):
        for x, vector in enumerate(row):
            if vector is not None:
                row[x] = [16, 0]
''')
    videos["standalone-python"] = evidence / "standalone-python.avi"
    python_temp = evidence / "python-json"
    python_temp.mkdir()
    old_tmpdir = environment["TMPDIR"]
    environment["TMPDIR"] = str(python_temp)
    try:
        run("standalone-python", sys.executable, output / "share/ffglitch/ffglitch.py",
            "-i", source, "-f", "mv", "-s", plain_py,
            "-o", videos["standalone-python"], "-v", "-k")
    finally:
        environment["TMPDIR"] = old_tmpdir

    native_py = evidence / "native.py"
    native_py.write_text('''def glitch_frame(frame, stream):
    for row in frame.get("mv", {}).get("forward", []):
        for x, vector in enumerate(row):
            if vector is not None:
                row[x] = [16, 0]
''')
    videos["native-python"] = evidence / "native-python.avi"
    run("native-python-edit", ffedit, "-threads", "1", "-i", source, "-f", "mv",
        "-s", native_py, "-o", videos["native-python"])

    decoded, metadata = {}, {}
    for label, video in videos.items():
        probe = json.loads(run(label + "-probe", ffprobe, "-v", "error", "-count_frames",
                               "-select_streams", "v:0", "-show_entries",
                               "stream=codec_name,width,height,nb_read_frames", "-of", "json", video))
        require(len(probe["streams"]) == 1, label + ": missing video stream")
        info = probe["streams"][0]
        require(info["codec_name"] == "mpeg4" and info["width"] == WIDTH and
                info["height"] == HEIGHT and int(info["nb_read_frames"]) == FRAMES,
                label + ": codec, dimensions or decoded frame count changed")
        metadata[label] = info
        pixels = evidence / (label + ".rgb")
        run(label + "-decode", ffmpeg, "-v", "error", "-xerror", "-nostdin", "-y",
            "-threads", "1", "-i", video, "-map", "0:v:0", "-an",
            "-pix_fmt", "rgb24", "-f", "rawvideo", pixels)
        decoded[label] = pixels.read_bytes()
        require(len(decoded[label]) == FRAMES * FRAME_BYTES, label + ": truncated decode")
        # Exact original decoded pixels as images; no labels or compositing.
        for index in (0, FRAMES - 1):
            ppm = evidence / f"{label}-frame-{index:03}.ppm"
            ppm.write_bytes(f"P6\n{WIDTH} {HEIGHT}\n255\n".encode() +
                            decoded[label][index * FRAME_BYTES:(index + 1) * FRAME_BYTES])
            run(f"{label}-image-{index}", convert, ppm,
                evidence / f"{label}-frame-{index:03}.png")
    require(decoded["control"] == decoded["source"] == decoded["json-roundtrip"],
            "no-op script or JSON roundtrip changed decoded pixels")
    changed_bytes = sum(a != b for a, b in zip(decoded["control"], decoded["glitched"]))
    mean_error = sum(abs(a - b) for a, b in zip(decoded["control"], decoded["glitched"])) / len(decoded["control"])
    require(changed_bytes > len(decoded["control"]) * 0.1 and mean_error > 5,
            "native bitstream mutation had no meaningful decoded effect")
    require(decoded["control"][:FRAME_BYTES] == decoded["glitched"][:FRAME_BYTES],
            "motion-vector script unexpectedly changed initial intra frame")
    for label in ("standalone-js", "standalone-python", "native-python"):
        require(decoded[label] == decoded["glitched"],
                label + " disagrees with native JavaScript bitstream transformation")

    # fflive selects features in setup(), since its -f means demuxer format.
    # Playback reaches EOF and holds the final image; q must exit normally.
    display_read, display_write = os.pipe()
    server = player = None
    screenshot_error = {}
    with (evidence / "xvfb.log").open("wb") as server_log, \
         (evidence / "fflive.log").open("wb") as player_log:
        try:
            server = subprocess.Popen([xvfb, "-displayfd", str(display_write),
                                       "-screen", "0", "640x480x24", "-nolisten", "tcp"],
                                      pass_fds=(display_write,), stdout=server_log,
                                      stderr=subprocess.STDOUT, env=environment)
            os.close(display_write)
            with os.fdopen(display_read) as pipe:
                display_number = pipe.readline().strip()
            require(display_number.isdigit(), "Xvfb did not allocate display")
            environment["DISPLAY"] = ":" + display_number
            arguments = list(map(str, [fflive, "-i", source, "-s", native, "-sp", "true",
                                      "-an", "-noframedrop", "-x", WIDTH, "-y", HEIGHT,
                                      "-noborder", "-window_title", "FFglitch native proof"]))
            commands.append({"label": "fflive", "argv": arguments})
            (evidence / "commands.json").write_text(json.dumps(commands, indent=2) + "\n")
            player = subprocess.Popen(arguments, cwd=evidence, env=environment,
                                      stdout=player_log, stderr=subprocess.STDOUT)
            window = None
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                require(player.poll() is None, "fflive exited before preview")
                result = subprocess.run([xdotool, "search", "--onlyvisible", "--name",
                                         "^FFglitch native proof$"], env=environment,
                                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                        timeout=3)
                if result.returncode == 0 and result.stdout.split():
                    window = result.stdout.split()[0].decode()
                    break
                time.sleep(0.1)
            require(window is not None, "fflive did not show its SDL video window")
            time.sleep(FRAMES / RATE + 2)
            require(player.poll() is None, "fflive exited before screenshot")
            run("fflive-capture", xwd, "-silent", "-id", window,
                "-out", evidence / "fflive-preview.xwd")
            run("fflive-image", convert, evidence / "fflive-preview.xwd",
                evidence / "fflive-preview.png")
            geometry = run("fflive-geometry", convert, evidence / "fflive-preview.png",
                           "-format", "%w %h", "info:").split()
            require(geometry == [str(WIDTH).encode(), str(HEIGHT).encode()],
                    "unexpected live preview geometry")
            screenshot = run("fflive-pixels", convert, evidence / "fflive-preview.png",
                             "-depth", "8", "rgb:-")
            require(len(screenshot) == FRAME_BYTES, "truncated live surface")
            for label in ("control", "glitched"):
                last = decoded[label][-FRAME_BYTES:]
                screenshot_error[label] = sum(abs(a - b) for a, b in zip(screenshot, last)) / FRAME_BYTES
            require(screenshot_error["glitched"] < 8 and
                    screenshot_error["control"] > screenshot_error["glitched"] + 5,
                    "actual live surface does not match the decoded native glitch")
            run("fflive-focus", xdotool, "windowfocus", "--sync", window)
            run("fflive-quit", xdotool, "key", "--clearmodifiers", "q")
            require(player.wait(timeout=10) == 0, "fflive did not exit cleanly on q")
        finally:
            if player is not None and player.poll() is None:
                player.terminate()
                try:
                    player.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    player.kill()
                    player.wait()
            if server is not None and server.poll() is None:
                server.terminate()
                server.wait(timeout=5)
    hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
              for path in evidence.iterdir() if path.suffix in (".avi", ".png", ".rgb", ".json", ".xwd")}
    result = {"namespaces": namespaces, "network_interfaces": interfaces,
              "metadata": metadata, "motion_vectors": len(vectors),
              "decoded_changed_bytes": changed_bytes, "decoded_mean_absolute_error": mean_error,
              "live_mean_absolute_error": screenshot_error, "fflive_exit_status": 0,
              "sha256": hashes}
    (evidence / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print("Passed native JS and Python, JSON roundtrip, standalone JS/Python, independent decoding and live X11 glitch preview")
    print(json.dumps({key: value for key, value in result.items() if key != "sha256"}, indent=2))


if __name__ == "__main__":
    main()
