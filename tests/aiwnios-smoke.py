#!/usr/bin/env python3
"""Run only the installed Aiwnios ELF and observe its native HolyC/SDL paths."""

import hashlib
import json
import os
from pathlib import Path
import re
import select
import shutil
import subprocess
import sys
import tempfile
import time

from PIL import Image, ImageChops, ImageStat

COMMIT = "e155e87a4a4ddae4cd7f25685d9db8869fd45a40"
EXPECTED = ["AIWNIOS_ARITHMETIC=42", "AIWNIOS_LOOP=55",
            "AIWNIOS_BRANCH=-7,3,42", "AIWNIOS_RECURSION=720",
            "AIWNIOS_HELLO_OK"]


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def signature(path):
    data = path.read_bytes()
    require(len(data) >= 32, "truncated HCRT module: " + str(path))
    # The upstream packed CBinFile exposes abi[4] at byte offset four.
    # HolyC literals are stored in source character order: X86\0, ARM\0, BYTC.
    return data[4:8].decode("ascii").rstrip("\0")


def main():
    require(len(sys.argv) == 6, "usage: runner OUTPUT ARTIFACTS HOST_NET HOST_MNT HOST_USER")
    output = Path(sys.argv[1])
    artifacts = Path(sys.argv[2])
    namespaces = {}
    for kind, host in zip(("net", "mnt", "user"), sys.argv[3:]):
        actual = os.readlink("/proc/self/ns/" + kind)
        require(actual != host, "inherited host " + kind + " namespace")
        namespaces[kind] = actual
    interfaces = sorted(line.split(":", 1)[0].strip()
                        for line in Path("/proc/net/dev").read_text().splitlines()[2:])
    require(interfaces == ["lo"], "host network interfaces exposed")
    require(os.getuid() == 1000 and os.environ.get("USER") == "aiwnios-smoke",
            "wrong container identity")
    require(not Path("/home/aiwnios-smoke/.guix-profile").exists(), "linked host profile")
    executable = output / "bin/aiwnios"
    require(executable.read_bytes()[:4] == b"\x7fELF", "bin/aiwnios is not the genuine ELF")
    require(Path(shutil.which("aiwnios")).resolve() == executable.resolve(),
            "profile resolves a different Aiwnios output")
    for path in [output, *output.rglob("*")]:
        if not path.is_symlink():
            require(not path.stat().st_mode & 0o222, "writable store item: " + str(path))
    package = "aiwnios-bytecode" if "-aiwnios-bytecode-" in output.name else "aiwnios"
    require(re.fullmatch(r"[a-z0-9]{32}-" + package + r"-0\.9\.0-0\.e155e87", output.name),
            "unexpected package or canonical source revision token")
    mode = "bytecode" if package == "aiwnios-bytecode" else "native"
    expected_signatures = {"BYTC"} if mode == "bytecode" else {"X86", "ARM", "RV64"}
    template = output / "share/aiwnios"
    installed_signature = signature(template / "HCRT2.BIN")
    require(installed_signature in expected_signatures, "installed HCRT mode mismatch")
    require((template / "HCRT2.DBG.Z").stat().st_size > 0, "missing HCRT debug module")
    require((template / "Src/FULL_PACKAGE.HC").is_file(), "bootstrap sources missing")
    require((template / "AiwniosHelp/Main.DD").is_file(), "native help resources missing")

    # Do not inherit host SDL, display, search paths, HOME or XDG settings.
    profile = os.environ["GUIX_ENVIRONMENT"]
    with tempfile.TemporaryDirectory(prefix="aiwnios-private-", dir="/tmp") as work_name:
        work = Path(work_name)
        env = {"PATH": profile + "/bin", "LC_ALL": "C", "USER": "aiwnios-smoke",
               "LOGNAME": "aiwnios-smoke", "GUIX_ENVIRONMENT": profile}
        for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                               ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                               ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                               ("TMPDIR", "tmp")):
            directory = work / name
            directory.mkdir(mode=0o700)
            env[variable] = str(directory)
        boot = work / "boot"
        shutil.copytree(template, boot, symlinks=False)
        # Guix's template is immutable; make only this private recursive copy writable.
        for path in [boot, *boot.rglob("*")]:
            path.chmod(path.stat().st_mode | 0o700 if path.is_dir()
                       else path.stat().st_mode | 0o600)
        for name in ("HCRT2.BIN", "HCRT2.DBG.Z"):
            (boot / name).unlink()
        base = [str(executable), "-d", "-F", "-t", str(boot)]
        # The slim C bootstrap lexer opens its initial #include with host
        # fopen, before HolyC's T-drive-aware runtime exists.  -t selects
        # runtime VFS storage but cannot change that host-relative include.
        with (artifacts / "bootstrap.log").open("wb") as log:
            result = subprocess.run(["timeout", "--kill-after=5s", "180s", *base, "-b"],
                                    cwd=boot, env=env, stdout=log, stderr=subprocess.STDOUT,
                                    timeout=190)
        require(result.returncode == 0, "real HCRT bootstrap failed; see bootstrap.log")
        rebuilt_signature = signature(boot / "HCRT2.BIN")
        require(rebuilt_signature == installed_signature, "rebuilt HCRT mode differs")
        require((boot / "HCRT2.DBG.Z").stat().st_size > 0, "bootstrap omitted debug module")
        rebuilt_hash = hashlib.sha256((boot / "HCRT2.BIN").read_bytes()).hexdigest()
        for name in ("HCRT2.BIN", "HCRT2.DBG.Z", "Src/STAGE1.HC"):
            shutil.copyfile(boot / name, artifacts / ("bootstrap-first-" + Path(name).name))
        with (artifacts / "bootstrap-repeat.log").open("wb") as log:
            result = subprocess.run(["timeout", "--kill-after=5s", "180s", *base, "-b"],
                                    cwd=boot, env=env, stdout=log, stderr=subprocess.STDOUT,
                                    timeout=190)
        require(result.returncode == 0, "repeated HCRT bootstrap failed")
        repeated_hash = hashlib.sha256((boot / "HCRT2.BIN").read_bytes()).hexdigest()
        for name in ("HCRT2.BIN", "HCRT2.DBG.Z", "Src/STAGE1.HC"):
            shutil.copyfile(boot / name, artifacts / ("bootstrap-repeat-" + Path(name).name))
        require(repeated_hash == rebuilt_hash, "repeated HCRT bootstrap is not deterministic")
        shutil.copyfile("/consumer.HC", boot / "consumer.HC")
        with (artifacts / "consumer.log").open("wb") as log:
            result = subprocess.run(["timeout", "--kill-after=5s", "60s", *base,
                                     "-c", "consumer.HC"], cwd=work, env=env,
                                    stdout=log, stderr=subprocess.STDOUT, timeout=70)
        require(result.returncode == 0, "HolyC fixture failed or did not exit")
        text = (artifacts / "consumer.log").read_text(errors="replace")
        lines = text.replace("\r", "").splitlines()
        observed = [line for line in lines if line.startswith("AIWNIOS_")]
        require(observed == EXPECTED, "HolyC results differ from independent oracle: " + repr(observed))
        # Exercise the genuine exit-status path separately, not just a success marker.
        (boot / "failure.HC").write_text("ExitAiwnios(23);\n")
        with (artifacts / "failure.log").open("wb") as log:
            result = subprocess.run(["timeout", "--kill-after=5s", "30s", *base,
                                     "-c", "failure.HC"], cwd=work, env=env,
                                    stdout=log, stderr=subprocess.STDOUT, timeout=40)
        require(result.returncode == 23, "ExitAiwnios(23) did not propagate status")

        # OnceExe is an upstream user-customization hook, not the application UI.
        # Remove only its copied build-time popup queue so the real User prompt starts.
        for registry in boot.rglob("Registry.HC.Z"):
            registry.unlink()
        env.update(DISPLAY=":93", SDL_VIDEODRIVER="x11", SDL_AUDIODRIVER="dummy",
                   SDL_RENDER_DRIVER="software", LIBGL_ALWAYS_SOFTWARE="1",
                   MESA_SHADER_CACHE_DISABLE="true")
        xvfb_log = (artifacts / "xvfb.log").open("wb")
        gui_log = (artifacts / "gui.log").open("wb")
        # Xvfb's -displayfd writes the allocated display only after the server
        # is ready to accept clients.  This is an actual readiness handshake,
        # not repeated failing client connections with suppressed diagnostics.
        display_read, display_write = os.pipe()
        xvfb = subprocess.Popen(["Xvfb", "-displayfd", str(display_write),
                                 "-screen", "0", "1280x960x24",
                                 "-nolisten", "tcp", "-ac"], env=env,
                                pass_fds=(display_write,),
                                stdout=xvfb_log, stderr=subprocess.STDOUT)
        os.close(display_write)
        gui = None
        try:
            with os.fdopen(display_read, "r") as display_pipe:
                ready, _, _ = select.select([display_pipe], [], [], 15)
                require(ready, "isolated Xvfb readiness handshake timed out")
                display_number = display_pipe.readline().strip()
            require(display_number.isdigit() and xvfb.poll() is None,
                    "isolated Xvfb failed to allocate a display")
            env["DISPLAY"] = ":" + display_number

            def tool(*args):
                return subprocess.check_output(args, env=env, timeout=15)
            gui = subprocess.Popen(base, cwd=work, env=env, stdout=gui_log,
                                   stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 45
            window = None
            while window is None:
                require(gui.poll() is None, "native GUI exited before its window appeared")
                found = subprocess.run(["xdotool", "search", "--onlyvisible", "--pid", str(gui.pid)],
                                       env=env, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                       timeout=10)
                windows = found.stdout.splitlines()
                if windows:
                    window = windows[-1].decode()
                else:
                    require(time.monotonic() < deadline, "no visible native SDL window")
                    time.sleep(0.2)
            title = tool("xdotool", "getwindowname", window).decode().strip()
            require(title == "AIWNIOS", "visible window is not the authentic AIWNIOS SDL UI")
            geometry = tool("xdotool", "getwindowgeometry", "--shell", window).decode()
            dimensions = dict(re.findall(r"^(WIDTH|HEIGHT)=(\d+)$", geometry, re.M))
            require(int(dimensions.get("WIDTH", 0)) >= 640 and
                    int(dimensions.get("HEIGHT", 0)) >= 400, "native UI window too small")
            tool("xdotool", "windowfocus", "--sync", window)
            time.sleep(5)

            def capture(name):
                raw = artifacts / (name + ".xwd")
                png = artifacts / (name + ".png")
                tool("xwd", "-silent", "-id", window, "-out", str(raw))
                tool("convert", str(raw), str(png))
                image = Image.open(png).convert("RGB")
                require(max(ImageStat.Stat(image).stddev) > 8,
                        "blank/native-window screenshot: " + name)
                return image

            before_image = capture("gui-before")
            commands = [
                "I64 SmokeGui(){I64 j,s=0;for(j=1;j<=6;j++)s+=j;return s*2;}",
                'I64 gui_result=SmokeGui();"AIWNIOS_GUI_RESULT=%d\\n",gui_result;FileWrite("/GUI_RESULT.TXT",MStrPrint("%d",gui_result),2);',
            ]
            (artifacts / "gui-typed-commands.txt").write_text("\n".join(commands) + "\n")
            for command in commands:
                tool("xdotool", "type", "--clearmodifiers", "--delay", "30", command)
                tool("xdotool", "key", "--clearmodifiers", "Return")
                time.sleep(1)
            result_file = boot / "GUI_RESULT.TXT"
            deadline = time.monotonic() + 30
            while not result_file.is_file():
                require(gui.poll() is None, "GUI died while evaluating typed HolyC")
                require(time.monotonic() < deadline, "typed HolyC never wrote native result")
                time.sleep(0.2)
            require(result_file.read_bytes() == b"42", "GUI HolyC computation is not 42")
            shutil.copyfile(result_file, artifacts / "GUI_RESULT.TXT")
            time.sleep(2)
            after_image = capture("gui-computation")
            require(before_image.size == after_image.size and
                    ImageChops.difference(before_image, after_image).getbbox() is not None,
                    "native UI did not render changed computation surface")
            tool("xdotool", "type", "--clearmodifiers", "--delay", "30", "ExitAiwnios(0);")
            tool("xdotool", "key", "--clearmodifiers", "Return")
            require(gui.wait(timeout=20) == 0, "native GUI quit failed")
        finally:
            if gui is not None and gui.poll() is None:
                gui.terminate()
                try:
                    gui.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    gui.kill()
                    gui.wait(timeout=5)
            xvfb.terminate()
            try:
                xvfb.wait(timeout=5)
            except subprocess.TimeoutExpired:
                xvfb.kill()
                xvfb.wait(timeout=5)
            xvfb_log.close()
            gui_log.close()
        result = {"package": package, "output": str(output), "source_pin_expected": COMMIT,
                  "source_revision_token_checked": "e155e87",
                  "mode": mode, "mode_checked_from_hcrt": True,
                  "installed_hcrt_signature": installed_signature,
                  "rebuilt_hcrt_signature": rebuilt_signature,
                  "rebuilt_hcrt_sha256": rebuilt_hash, "bootstrap_exit_status": 0,
                  "bootstrap_repeat_sha256": repeated_hash, "bootstrap_repeat_identical": True,
                  "holyc_results": observed, "failure_exit_status": 23,
                  "gui_window": window, "gui_title": title, "gui_geometry": dimensions,
                  "gui_native_result": 42, "gui_quit_status": 0,
                  "gui_screenshot": "gui-computation.png", "gui_screenshot_nonblank": True,
                  "gui_surface_changed": True, "network_interfaces": interfaces,
                  "namespaces": namespaces, "isolated_home_xdg_tmp": True,
                  "read_only_external_fixture": "/consumer.HC"}
        (artifacts / "result.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
        print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
