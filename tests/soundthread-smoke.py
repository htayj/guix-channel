#!/usr/bin/env python3
"""Installed native consumer proof; intentionally no CDP/audio-device execution."""
import array
import hashlib
import json
import math
import os
from pathlib import Path
import re
import select
import socket
import struct
import subprocess
import sys
import tempfile
import wave
import zlib


def normalized_graph(graph):
    # FileDialog creates anonymous descendant controls with process-local
    # numeric object names. Preserve every control's type, path order and
    # state; only its transient numeric identity changes on reconstruction.
    result = json.loads(json.dumps(graph))
    anonymous = re.compile(r"(^|/)(@[A-Za-z]+@)\d+(?=/|$)")
    for node in result["nodes"]:
        for field in ("slider_values", "optionbutton_values"):
            node[field] = [(anonymous.sub(r"\1\2", key), value)
                           for key, value in node[field].items()]
    return result


def tree_digest(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest.update(str(path.relative_to(root)).encode())
        digest.update(repr((status.st_mode, status.st_size, status.st_mtime_ns)).encode())
        if path.is_symlink():
            digest.update(os.readlink(path).encode())
        elif path.is_file():
            assert not status.st_mode & 0o222, f"writable installed file: {path}"
            digest.update(path.read_bytes())
    return digest.hexdigest()


def fixture(path):
    pcm = array.array("h")
    for frame in range(96000):
        sample = round(8192 * math.sin(2 * math.pi * 440 * frame / 48000))
        pcm.extend((sample, sample))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(path), "wb") as wav:
        wav.setparams((2, 2, 48000, 0, "NONE", "not compressed"))
        wav.writeframes(pcm.tobytes())


def read_wav(path):
    with wave.open(str(path), "rb") as wav:
        assert wav.getnchannels() == 2 and wav.getsampwidth() == 2
        rate = wav.getframerate()
        samples = array.array("h", wav.readframes(wav.getnframes()))
    if sys.byteorder != "little":
        samples.byteswap()
    return rate, [samples[channel::2] for channel in (0, 1)]


def verify_pcm(evidence, report):
    source_rate, source = read_wav(evidence / "input.wav")
    rate, channels = read_wav(evidence / "mixed-output.wav")
    assert source_rate == 48000 and rate == report["mix_rate"]
    assert len(channels[0]) == report["captured_frames"]
    duration = len(channels[0]) / rate
    assert 1.95 <= duration <= 3.0, f"capture duration {duration}"
    metrics = []
    for original, samples in zip(source, channels):
        active = [i for i, sample in enumerate(samples) if abs(sample) > 300]
        assert active, "mixed output is silent"
        start, stop = active[0], active[-1] + 1
        active_duration = (stop - start) / rate
        assert 1.90 <= active_duration <= 2.10, f"active duration {active_duration}"
        # Discard edge blocks; estimate frequency on real captured samples.
        middle = samples[start + rate // 10:stop - rate // 10]
        rms = math.sqrt(sum(sample * sample for sample in middle) / len(middle)) / 32768
        input_rms = math.sqrt(sum(sample * sample for sample in original) / len(original)) / 32768
        assert 0.65 <= rms / input_rms <= 1.05, (rms, input_rms)
        crossings = [i for i in range(1, len(middle)) if middle[i - 1] <= 0 < middle[i]]
        assert len(crossings) > 100
        frequency = (len(crossings) - 1) * rate / (crossings[-1] - crossings[0])
        assert abs(frequency - 440) < 1.0, frequency
        peak = max(abs(value) for value in middle) / 32768
        assert peak < 0.4, f"unexpected clipping or gain {peak}"
        # A sine, not arbitrary PCM with a plausible crossing count.
        center = sum(middle) / len(middle)
        cosine = sum(value * math.cos(2 * math.pi * 440 * i / rate) for i, value in enumerate(middle))
        sine = sum(value * math.sin(2 * math.pi * 440 * i / rate) for i, value in enumerate(middle))
        energy = sum((value - center) ** 2 for value in middle)
        purity = 2 * (cosine * cosine + sine * sine) / (len(middle) * energy)
        assert purity > 0.97, f"mixed signal is not the fixture sine: {purity}"
        metrics.append({"rms": rms, "frequency_hz": frequency,
                        "active_duration_seconds": active_duration, "sine_purity": purity})
    return {"duration_seconds": duration, "channels": metrics}


def verify_png(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    offset, compressed, header = 8, bytearray(), None
    while offset < len(data):
        length = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4:offset + 8]
        body = data[offset + 8:offset + 8 + length]
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            compressed.extend(body)
        offset += length + 12
    width, height, depth, color, compression, filtering, interlace = header
    assert width == 1600 and height == 1000 and depth == 8 and color in (2, 6)
    assert (compression, filtering, interlace) == (0, 0, 0)
    bpp = 3 if color == 2 else 4
    stride = width * bpp
    raw = zlib.decompress(compressed)
    assert len(raw) == height * (stride + 1)
    previous = bytearray(stride)
    colors = set()
    for y in range(height):
        begin = y * (stride + 1)
        kind, row = raw[begin], bytearray(raw[begin + 1:begin + stride + 1])
        for x in range(stride):
            left = row[x - bpp] if x >= bpp else 0
            up = previous[x]
            upper_left = previous[x - bpp] if x >= bpp else 0
            if kind == 1:
                prediction = left
            elif kind == 2:
                prediction = up
            elif kind == 3:
                prediction = (left + up) // 2
            elif kind == 4:
                p = left + up - upper_left
                distances = (abs(p - left), abs(p - up), abs(p - upper_left))
                prediction = (left, up, upper_left)[distances.index(min(distances))]
            else:
                assert kind == 0
                prediction = 0
            row[x] = (row[x] + prediction) & 255
        if y % 4 == 0:
            colors.update(bytes(row[x:x + 3]) for x in range(0, stride, bpp * 4))
        previous = row
    assert len(colors) > 100, f"blank/non-rendered UI: {len(colors)} colors"
    return {"width": width, "height": height, "sampled_colors": len(colors)}


def stop(process):
    if process is not None and process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


def main():
    out, xvfb, mount, fonts, consumer = sys.argv[1:]
    out = Path(out).resolve()
    # Read before covering /tmp: repository/helper may live under host /tmp.
    consumer_source = Path(consumer).read_bytes()
    artifacts = Path(os.environ.get("SOUNDTHREAD_SMOKE_ARTIFACTS") or
                     tempfile.mkdtemp(prefix="soundthread-smoke-artifacts-", dir="/var/tmp")).resolve()
    assert artifacts != out and out not in artifacts.parents
    artifacts.mkdir(parents=True, exist_ok=True)
    print(f"SoundThread retained evidence: {artifacts}", flush=True)
    artifact_fd = os.open(artifacts, os.O_RDONLY | os.O_DIRECTORY)
    before = tree_digest(out)
    evidence = None
    xserver = app = None
    read_fd = write_fd = None

    def run_mount(*args):
        subprocess.run([mount, *args], check=True, timeout=10)

    try:
        run_mount("--make-rprivate", "/")
        run_mount("-t", "tmpfs", "-o", "mode=1777", "tmpfs", "/tmp")
        evidence = Path("/tmp/evidence")
        evidence.mkdir()
        subprocess.run([mount, "--bind", f"/proc/self/fd/{artifact_fd}", str(evidence)],
                       pass_fds=(artifact_fd,), check=True, timeout=10)
        os.close(artifact_fd)
        artifact_fd = None
        # Hide system audio/display sockets and all physical device nodes.
        # Bind only harmless character devices into a minimal read-only /dev.
        run_mount("-t", "tmpfs", "-o", "mode=755", "tmpfs", "/run")
        devices = Path("/tmp/devices")
        devices.mkdir()
        run_mount("-t", "tmpfs", "-o", "mode=755", "tmpfs", str(devices))
        for name in ("null", "zero", "random", "urandom"):
            (devices / name).touch()
            run_mount("--bind", f"/dev/{name}", str(devices / name))
        (devices / "shm").mkdir(mode=0o1777)
        (devices / "fd").symlink_to("/proc/self/fd")
        for number, name in enumerate(("stdin", "stdout", "stderr")):
            (devices / name).symlink_to(f"/proc/self/fd/{number}")
        # Recursive bind preserves the character-device child mounts. A plain
        # bind exposes empty backing files which become read-only below.
        run_mount("--rbind", str(devices), "/dev")
        run_mount("-t", "tmpfs", "-o", "mode=1777", "tmpfs", "/dev/shm")
        run_mount("-o", "remount,bind,ro", "/dev")
        assert [name for _, name in socket.if_nameindex()] == ["lo"]
        environment = {"LC_ALL": "C.UTF-8", "PATH": "", "LIBGL_ALWAYS_SOFTWARE": "1",
                       "GALLIUM_DRIVER": "llvmpipe", "PYTHONNOUSERSITE": "1"}
        root = Path(tempfile.mkdtemp(prefix="soundthread-private-", dir="/tmp"))
        for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                               ("XDG_CACHE_HOME", "cache"), ("XDG_DATA_HOME", "data"),
                               ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                               ("TMPDIR", "tmp")):
            directory = root / name
            directory.mkdir(mode=0o700)
            environment[variable] = str(directory)
        work = root / "work"
        work.mkdir()
        helper = work / "consumer.gd"
        helper.write_bytes(consumer_source)
        config = work / "fonts.conf"
        config.write_text(f'<fontconfig><dir>{fonts}/share/fonts</dir>'
                          f'<cachedir>{root}/cache/fontconfig</cachedir></fontconfig>')
        environment["FONTCONFIG_FILE"] = str(config)
        fixture(evidence / "input.wav")
        read_fd, write_fd = os.pipe()
        with (evidence / "xvfb.log").open("wb") as xlog, (evidence / "soundthread.log").open("wb") as log:
            xserver = subprocess.Popen([xvfb, "-displayfd", str(write_fd), "-screen", "0",
                                        "1600x1000x24", "-nolisten", "tcp", "-noreset"],
                                       env=environment, cwd=work, stdout=xlog, stderr=xlog,
                                       pass_fds=(write_fd,))
            os.close(write_fd)
            write_fd = None
            ready = select.select([read_fd], [], [], 15)[0]
            assert ready, "private Xvfb startup timed out"
            display = os.read(read_fd, 64).strip()
            assert display.isdigit(), f"Xvfb displayfd returned {display!r}"
            os.close(read_fd)
            read_fd = None
            environment["DISPLAY"] = ":" + display.decode()
            app = subprocess.Popen([str(out / "bin/soundthread"), "--audio-driver", "Dummy",
                                    "--rendering-method", "gl_compatibility", "--script", str(helper),
                                    "--", str(evidence / "input.wav"), str(evidence)],
                                   cwd=work, env=environment, stdout=log, stderr=log)
            assert app.wait(timeout=150) == 0, "native consumer failed; inspect soundthread.log/report.json"
        report = json.loads((evidence / "report.json").read_text())
        assert report["ok"] and report["missing_cdp_acknowledged"]
        assert report["input_reimported_after_reload"] and not report["cdp_executed"]
        assert report["cdp_location"] == "no_location" and report["discarded_frames"] == 0
        assert report["input_rate"] == 48000 and report["input_stereo"]
        assert report["rendering_method"] == "gl_compatibility"
        saved = json.loads((evidence / "graph.thd").read_text())
        loaded = json.loads((evidence / "graph-reloaded.thd").read_text())
        assert normalized_graph(saved) == normalized_graph(loaded), "native graph roundtrip changed persisted state"
        report["graph_roundtrip_identity_normalization"] = "Only numeric suffixes of anonymous @Type@number slider-path components and optionbutton keys; types, component order, control order and all values retained"
        nodes = {node["id"]: node for node in saved["nodes"]}
        assert sorted(node["command"] for node in nodes.values()) == ["inputfile", "modify_loudness_1", "outputfile"]
        edges = {(nodes[edge["from_node_id"]]["command"], edge["from_port"],
                  nodes[edge["to_node_id"]]["command"], edge["to_port"]) for edge in saved["connections"]}
        assert edges == {("inputfile", 0, "modify_loudness_1", 0), ("modify_loudness_1", 0, "outputfile", 0)}
        gain = next(node for node in nodes.values() if node["command"] == "modify_loudness_1")
        assert gain["slider_values"]["Gain/HSplitContainer/HSlider"]["value"] == 0.625
        report["external_pcm_verification"] = verify_pcm(evidence, report)
        report["rendered_viewport"] = verify_png(evidence / "soundthread.png")
        report["first_launch_viewport"] = verify_png(evidence / "missing-cdp.png")
        report["isolation"] = {"network": "private offline namespace", "devices": "minimal read-only /dev; no snd or dri", "audio": "Dummy software mixing; not audible output", "display": "private Xvfb displayfd"}
        (evidence / "verified-report.json").write_text(json.dumps(report, indent=2) + "\n")
        print("PASS: native WAV import/playback, Master mixed PCM, graph roundtrip and rendered UI", flush=True)
    finally:
        stop(app)
        stop(xserver)
        for fd in (artifact_fd, read_fd, write_fd):
            if fd is not None:
                os.close(fd)
        after = tree_digest(out)
        if evidence is not None:
            (evidence / "store-integrity.json").write_text(json.dumps({"before": before, "after": after, "unchanged": before == after}, indent=2) + "\n")
        assert before == after, "installed output changed during source-app smoke"


if __name__ == "__main__":
    main()
