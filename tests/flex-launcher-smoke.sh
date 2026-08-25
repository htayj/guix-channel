#!/bin/sh
# Exercise Flex Launcher's installed SDL menu under an isolated Xvfb display.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [flex-launcher-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    flex_out=$1
else
    flex_out=$($guix_bin build -L "$channel_dir" --no-grafts flex-launcher)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
xorg_server_out=
for candidate in $($guix_bin build xorg-server); do
    if test -x "$candidate/bin/Xvfb"; then
        xorg_server_out=$candidate
        break
    fi
done
test -n "$xorg_server_out"

test -x "$flex_out/bin/flex-launcher"
test -f "$flex_out/share/flex-launcher/config.ini"
test -f "$flex_out/share/applications/flex-launcher.desktop"
test -f "$flex_out/share/icons/hicolor/48x48/apps/flex-launcher.png"
test -f "$flex_out/share/icons/hicolor/scalable/apps/flex-launcher.svg"
test -f "$flex_out/share/doc/flex-launcher/UNLICENSE"
test -f "$flex_out/share/doc/flex-launcher/third-party-notices/nanosvg.txt"
test -f "$flex_out/share/doc/flex-launcher/third-party-notices/fonts.txt"
test -f "$flex_out/share/doc/flex-launcher/third-party-notices/icons.txt"
grep -F 'cc0d98734518af897f6c2af86abd94d0790c0661' \
    "$channel_dir/tay/packages/flex-launcher.scm" >/dev/null
grep -F 'Numix project' \
    "$flex_out/share/doc/flex-launcher/third-party-notices/icons.txt" >/dev/null
grep -F 'SIL Open Font License 1.1' \
    "$flex_out/share/doc/flex-launcher/third-party-notices/fonts.txt" >/dev/null
grep -F 'Permission is granted' \
    "$flex_out/share/doc/flex-launcher/third-party-notices/nanosvg.txt" >/dev/null
if grep -F '/usr/share/applications' "$flex_out/share/flex-launcher/config.ini" >/dev/null; then
    echo "default configuration retained a host desktop-file path" >&2
    exit 1
fi

exec "$python_out/bin/python3" - "$flex_out" "$xorg_server_out/bin/Xvfb" <<'PY'
import hashlib
import os
import pathlib
import signal
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb = sys.argv[2]


def tree_digest(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        digest.update(str(path.relative_to(root)).encode())
        if path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


with tempfile.TemporaryDirectory(prefix="flex-launcher-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home = root / "home"
    config_home = root / "config"
    data_home = root / "data"
    cache_home = root / "cache"
    work = root / "work"
    for directory in (home, config_home, data_home, cache_home, work):
        directory.mkdir()

    # This configuration is entirely outside the store.  Its second entry is
    # a safe built-in quit action, so parsing the menu never starts a host
    # application during this proof.
    config = root / "flex-launcher.ini"
    asset = out / "share" / "flex-launcher" / "assets"
    config.write_text(
        "[General]\n"
        "DefaultMenu=Main\n"
        "VSync=false\n"
        "FPSLimit=30\n"
        "OnLaunch=Blank\n"
        "WrapEntries=false\n"
        "ResetOnBack=false\n"
        "MouseSelect=false\n"
        "InhibitOSScreensaver=false\n"
        "[Background]\nMode=Color\nColor=#000000\n"
        "[Layout]\nMaxButtons=2\nIconSize=96\nIconSpacing=10\nVCenter=50%\n"
        "[Titles]\nEnabled=true\n"
        f"Font={asset / 'fonts' / 'OpenSans-Regular.ttf'}\n"
        "FontSize=24\nColor=#FFFFFF\nOpacity=100%\nShadows=false\n"
        "OversizeMode=Shrink\nPadding=10\n"
        "[Highlight]\nEnabled=true\nFillColor=#FFFFFF\nFillOpacity=25%\n"
        "OutlineSize=0\nOutlineColor=#0000FF\nOutlineOpacity=100%\n"
        "CornerRadius=0\nVPadding=10\nHPadding=10\n"
        "[Scroll Indicators]\nEnabled=false\n"
        "[Clock]\nEnabled=false\n"
        "[Screensaver]\nEnabled=false\n"
        "[Hotkeys]\n"
        f"Hotkey1=#1B;:quit\n"
        "[Gamepad]\nEnabled=false\n"
        "[Main]\n"
        f"Entry1=First;{asset / 'icons' / 'system.png'};:submenu Child\n"
        f"Entry2=Second;{asset / 'icons' / 'system.png'};:quit\n",
        encoding="utf-8",
    )

    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(config_home),
            "XDG_DATA_HOME": str(data_home),
            "XDG_CACHE_HOME": str(cache_home),
            "DISPLAY": ":95",
            "SDL_AUDIODRIVER": "dummy",
            "SDL_RENDER_DRIVER": "software",
            "LIBGL_ALWAYS_SOFTWARE": "1",
            "LC_ALL": "C.UTF-8",
        }
    )
    for name in (
        "http_proxy", "https_proxy", "all_proxy",
        "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY",
    ):
        environment.pop(name, None)

    before = tree_digest(out)
    display = subprocess.Popen(
        [xvfb, ":95", "-screen", "0", "1024x768x24", "-nolisten", "tcp"],
        cwd=work,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    launcher = None
    try:
        time.sleep(0.5)
        assert display.poll() is None, display.stderr.read().decode(
            "utf-8", "replace"
        )
        launcher = subprocess.Popen(
            [str(out / "bin" / "flex-launcher"), "--debug", "--config", str(config)],
            cwd=work,
            env=environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )

        window = None
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if launcher.poll() is not None:
                raise RuntimeError(
                    "returncode: " + str(launcher.returncode) + "\n"
                    +
                    "stdout: "
                    + launcher.stdout.read().decode("utf-8", "replace")
                    + "\nstderr: "
                    + launcher.stderr.read().decode("utf-8", "replace")
                    + "\nlog: "
                    + (
                        (home / ".local" / "share" / "flex-launcher" /
                         "flex-launcher.log").read_text(encoding="utf-8")
                        if (home / ".local" / "share" / "flex-launcher" /
                            "flex-launcher.log").is_file()
                        else "<no log>"
                    )
                )
            # The program has created its X11 window once it has keyboard
            # focus.  This avoids depending on a host window manager.
            log = home / ".local" / "share" / "flex-launcher" / "flex-launcher.log"
            if log.is_file() and "Gained keyboard focus" in log.read_text(
                    encoding="utf-8"):
                window = True
                break
            time.sleep(0.1)
        assert window, "Flex Launcher did not create an X11 window"

        log = home / ".local" / "share" / "flex-launcher" / "flex-launcher.log"
        assert log.is_file(), list(root.rglob("*"))
        log_text = log.read_text(encoding="utf-8")
        assert "Loading menu 'Main'" in log_text, log_text
        assert "Entry 1 Title: Second" in log_text, log_text
        assert "Entry 1 Command: :quit" in log_text, log_text
        stop(launcher)
        assert launcher.returncode in (0, -signal.SIGTERM), launcher.returncode
        launcher = None

        # Separately prove a configured built-in action exits successfully,
        # without launching a host command.
        quit_config = root / "flex-launcher-quit.ini"
        quit_config.write_text(config.read_text(encoding="utf-8").replace(
            "OnLaunch=Blank\n", "OnLaunch=Blank\nStartupCmd=:quit\n"),
            encoding="utf-8")
        quitter = subprocess.run(
            [str(out / "bin" / "flex-launcher"), "--debug", "--config", str(quit_config)],
            cwd=work, env=environment, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, timeout=10, check=False,
        )
        assert quitter.returncode == 0, quitter.stderr.decode("utf-8", "replace")
        assert tree_digest(out) == before, "Flex Launcher modified its store output"
        assert not any(path.is_relative_to(out) for path in root.rglob("*"))
    finally:
        if launcher is not None:
            stop(launcher)
        stop(display)

print("flex-launcher smoke passed: fresh XDG state, X11 menu loading, safe action, notices, no store writes")
PY
