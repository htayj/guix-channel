#!/usr/bin/env python3
"""Original PCM fixture; execute packaged Praat's real batch and GTK interfaces.

Command syntax is grounded in v7.0.02 fon/praat_Sound.cpp,
 test/fon/SoundEditor_GUI_.praat and sys/praat.cpp. No playback is requested:
analysis and editing do not require a physical audio device.
"""

import ctypes
import hashlib
import json
import math
import os
from pathlib import Path
import signal
import struct
import subprocess
import sys
import time
import wave
from xml.sax.saxutils import escape

RATE, SECONDS, FREQUENCY, AMPLITUDE = 48000, 2, 440, 0.2


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    require(len(sys.argv) == 9,
            "usage: helper OUTPUT ROOT ARTIFACTS XVFB XDOTOOL XWD CONVERT FONT")
    output, root, evidence, xvfb, xdotool, xwd, convert, font = sys.argv[1:]
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

    # Private /tmp hides every host X11 socket. Bind retained directories using
    # open descriptors so an evidence directory originally in /tmp still works.
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY)
    evidence_fd = os.open(evidence, os.O_RDONLY | os.O_DIRECTORY)
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
        root, evidence = Path("/tmp/praat-root"), Path("/tmp/praat-evidence")
        root.mkdir()
        evidence.mkdir()
        mount("/proc/self/fd/" + str(root_fd), root, flags=4096)
        mount("/proc/self/fd/" + str(evidence_fd), evidence, flags=4096)
        Path("/tmp/.X11-unix").mkdir(mode=0o1777)
    finally:
        os.close(root_fd)
        os.close(evidence_fd)
    # Hide ALSA/OSS endpoints without changing the packaged audio support.
    # The test exercises analysis/editing only; playback is deliberately absent.
    empty_audio = root / "no-audio-devices"
    empty_audio.mkdir()
    if Path("/dev/snd").exists():
        mount(empty_audio, "/dev/snd", flags=4096)
    empty_endpoint = root / "no-audio-endpoint"
    empty_endpoint.touch()
    for endpoint in ("/dev/dsp", "/dev/audio"):
        if Path(endpoint).exists():
            mount(empty_endpoint, endpoint, flags=4096)
    require(not Path("/dev/snd").exists() or not any(Path("/dev/snd").iterdir()),
            "physical ALSA endpoints leaked")
    environment = dict(os.environ)
    for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                                ("TMPDIR", "tmp")):
        location = root / directory
        location.mkdir(mode=0o700)
        environment[variable] = str(location)
    fontconfig = root / "fonts.conf"
    fontconfig.write_text('<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd">'
                          '<fontconfig><dir>' + escape(font) + '/share/fonts</dir><cachedir>'
                          + str(root / "cache/fonts") + '</cachedir></fontconfig>')
    environment.update(FONTCONFIG_FILE=str(fontconfig), PYTHONNOUSERSITE="1",
                       GDK_BACKEND="x11", DISPLAY=":97", LIBGL_ALWAYS_SOFTWARE="1",
                       DBUS_SESSION_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-bus"),
                       DBUS_SYSTEM_BUS_ADDRESS="unix:path=" + str(root / "runtime/no-system-bus"))
    commands = []

    def record(label, args):
        commands.append({"label": label, "argv": list(map(str, args))})
        (evidence / "commands.json").write_text(json.dumps(commands, indent=2) + "\n")

    def run(label, *args, timeout=45):
        args = list(map(str, args))
        record(label, args)
        result = subprocess.run(args, cwd=evidence, env=environment, capture_output=True,
                                timeout=timeout)
        (evidence / (label + ".stdout")).write_bytes(result.stdout)
        (evidence / (label + ".stderr")).write_bytes(result.stderr)
        require(result.returncode == 0, label + " failed: " + result.stderr.decode(errors="replace"))
        return result.stdout.decode()

    praat = output / "bin/praat"
    version = run("version", praat, "--version").strip()
    require("7.0.02" in version, "wrong Praat version: " + version)
    integers = [round(32768 * AMPLITUDE * math.sin(2 * math.pi * FREQUENCY * n / RATE))
                for n in range(RATE * SECONDS)]
    pcm = struct.pack("<" + "h" * len(integers), *integers)
    expected_intensity = 10 * math.log10(sum((n / 32768) ** 2 for n in integers)
                                         / len(integers) / (2e-5) ** 2)
    fixture = evidence / "original-440hz.wav"
    with wave.open(str(fixture), "wb") as wav:
        wav.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        wav.writeframes(pcm)
    batch = evidence / "analysis.praat"
    batch.write_text('''# Original channel fixture: 2 s, mono 48 kHz, 440 Hz, 0.2 Pa peak.
sound = Read from file: "original-440hz.wav"
duration = Get total duration
rate = Get sampling frequency
samples = Get number of samples
channels = Get number of channels
intensity = Get intensity (dB)
pitch = To Pitch: 0, 75, 600
frequency = Get mean: 0.1, 1.9, "Hertz"
selectObject: sound
Save as binary file: "original.Sound"
reloaded = Read from file: "original.Sound"
reloadDuration = Get total duration
reloadRate = Get sampling frequency
reloadSamples = Get number of samples
reloadChannels = Get number of channels
assert duration = reloadDuration
assert rate = reloadRate
assert samples = reloadSamples
assert channels = reloadChannels
maxError = 0
for i to samples
    difference = abs (object [sound, 1, i] - object [reloaded, 1, i])
    maxError = max (maxError, difference)
endfor
assert maxError = 0
Save as WAV file: "reloaded.wav"
shell$ = runSystem$ ("printf 42")
assert shell$ = "42"
writeInfoLine: "duration_s=", fixed$ (duration, 12)
appendInfoLine: "rate_hz=", rate
appendInfoLine: "samples=", samples
appendInfoLine: "channels=", channels
appendInfoLine: "frequency_hz=", fixed$ (frequency, 9)
appendInfoLine: "intensity_db=", fixed$ (intensity, 9)
appendInfoLine: "native_max_sample_error=", maxError
appendInfoLine: "shell_value=", shell$
''')
    batch_output = run("batch", praat, "--FULL-TRUST", "--run", "--no-pref-files", "--no-plugins", batch)
    values = dict(line.split("=", 1) for line in batch_output.splitlines())
    expected = {"duration_s": (SECONDS, 1e-10), "rate_hz": (RATE, 0),
                "samples": (RATE * SECONDS, 0), "channels": (1, 0),
                "frequency_hz": (FREQUENCY, 0.5),
                "intensity_db": (expected_intensity, 1e-6), "native_max_sample_error": (0, 0),
                "shell_value": (42, 0)}
    for key, (value, tolerance) in expected.items():
        require(key in values and math.isfinite(float(values[key]))
                and abs(float(values[key]) - value) <= tolerance,
                f"{key}: expected {value} +/- {tolerance}, got {values.get(key)}")
    require((evidence / "original.Sound").read_bytes().startswith(b"ooBinaryFile"),
            "native file is not Praat binary format")
    with wave.open(str(evidence / "reloaded.wav"), "rb") as wav:
        require((wav.getnchannels(), wav.getsampwidth(), wav.getframerate(), wav.getnframes())
                == (1, 2, RATE, RATE * SECONDS), "reloaded WAV geometry changed")
        require(wav.readframes(RATE * SECONDS) == pcm, "reloaded PCM samples changed")

    # --new-send executes in a new real GUI (unlike --run). The upstream editor
    # script establishes both the actual analysis state and a pause barrier.
    gui_script = evidence / "editor.praat"
    gui_script.write_text('''sound = Read from file: "original-440hz.wav"
View & Edit
editor: sound
    Show analyses: "yes", "no", "no", "no", "no", 10
    Spectrogram settings: 0, 2000, 0.02, 70
    Zoom: 0.2, 0.3
    Move cursor to: 0.25
    info$ = Editor info
endeditor
writeFile: "editor-info.txt", info$
pauseScript: "Original 440 Hz waveform and spectrogram ready"
editor: sound
    Close
endeditor
removeObject: sound
writeFileLine: "gui-clean-exit.txt", "editor closed; Sound removed; Quit requested"
Quit
''')
    display = client = None

    def stop(process):
        if process is not None and process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)

    def window(pattern):
        result = subprocess.run([xdotool, "search", "--onlyvisible", "--name", pattern],
                                env=environment, capture_output=True, text=True)
        return result.stdout.splitlines() if result.returncode == 0 else []

    def wait_window(pattern):
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            require(client.poll() is None, "GUI exited before showing " + pattern)
            found = window(pattern)
            if found:
                return found[-1]
            time.sleep(0.1)
        raise RuntimeError("GUI window missing: " + pattern)

    try:
        args = [xvfb, environment["DISPLAY"], "-screen", "0", "1280x1024x24", "-nolisten", "tcp"]
        record("xvfb", args)
        with (evidence / "xvfb.log").open("wb") as log:
            display = subprocess.Popen(args, env=environment, stdout=log, stderr=log,
                                       start_new_session=True)
        deadline = time.monotonic() + 10
        while not Path("/tmp/.X11-unix/X97").exists():
            require(display.poll() is None and time.monotonic() < deadline, "private Xvfb failed")
            time.sleep(0.1)
        args = [str(praat), "--FULL-TRUST", "--new-send", "--no-plugins", str(gui_script)]
        record("gtk-editor", args)
        with (evidence / "gui.stdout").open("wb") as stdout, (evidence / "gui.stderr").open("wb") as stderr:
            client = subprocess.Popen(args, cwd=evidence, env=environment, stdout=stdout,
                                      stderr=stderr, start_new_session=True)
        pause = wait_window("^Pause:")
        editor = wait_window("Sound original-440hz")
        info = (evidence / "editor-info.txt").read_text()
        for text in ("Editor type: SoundEditor", "Spectrogram show: 1", "Pitch show: 0"):
            require(text in info, "missing actual editor state: " + text)
        run("editor-raise", xdotool, "windowraise", editor)
        run("editor-focus", xdotool, "windowfocus", "--sync", editor)
        time.sleep(1)
        run("editor-xwd", xwd, "-silent", "-id", editor, "-out", evidence / "editor.xwd")
        run("editor-png", convert, evidence / "editor.xwd", evidence / "editor.png")
        run("desktop-xwd", xwd, "-silent", "-root", "-out", evidence / "desktop.xwd")
        run("desktop-png", convert, evidence / "desktop.xwd", evidence / "desktop.png")
        run("pause-raise", xdotool, "windowraise", pause)
        run("pause-focus", xdotool, "windowfocus", "--sync", pause)
        # GTK can give initial keyboard focus to Stop, making Return cancel
        # instead of invoking the default Continue button. Ui.cpp positions
        # Continue at the lower right, 20 px above/right of the dialog edge.
        # Click that real button; retain the pause surface and its geometry.
        geometry = run("pause-geometry", xdotool, "getwindowgeometry", "--shell", pause)
        dimensions = dict(line.split("=", 1) for line in geometry.splitlines())
        run("pause-xwd", xwd, "-silent", "-id", pause, "-out", evidence / "pause.xwd")
        run("pause-png", convert, evidence / "pause.xwd", evidence / "pause.png")
        run("continue", xdotool, "mousemove", "--sync", "--window", pause,
            str(int(dimensions["WIDTH"]) - 60), str(int(dimensions["HEIGHT"]) - 32),
            "click", "1")
        require(client.wait(timeout=20) == 0, "Praat GUI did not quit cleanly")
        require((evidence / "gui-clean-exit.txt").read_text().strip()
                == "editor closed; Sound removed; Quit requested", "GUI script did not reach Quit")
        require(not window("Sound original-440hz"), "editor window survived Quit")
    finally:
        stop(client)
        stop(display)

    result = {"version": version, "fixture": {"rate_hz": RATE, "duration_s": SECONDS,
              "frequency_hz": FREQUENCY, "peak_pa": AMPLITUDE,
              "pcm_sha256": hashlib.sha256(pcm).hexdigest()},
              "measured": {key: float(value) for key, value in values.items()},
              "expected_and_absolute_tolerances": expected,
              "native_round_trip": "all 96000 sample values exactly equal; PCM export exactly equal",
              "gui": {"editor_window": editor, "pause_window": pause, "exit_status": 0,
                      "screenshot": "editor.png", "state": "editor-info.txt"},
              "namespaces": namespaces, "network_interfaces": interfaces,
              "physical_audio_device_required": False, "physical_audio_endpoints_hidden": True}
    (evidence / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(batch_output, end="")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
