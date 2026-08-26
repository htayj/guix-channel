#!/bin/sh
# Offline smoke proof for the installed Azurra GTK theme.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [azurra-gtk-theme-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    theme_out=$1
else
    theme_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes azurra-gtk-theme)
fi

find_program_output() {
    program=$1
    shift
    for candidate in $($guix_bin build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

python_out=$(find_program_output bin/python3 python)
xorg_server_out=$(find_program_output bin/Xvfb xorg-server)
gtk_out=
for candidate in $($guix_bin build gtk+); do
    if test -x "$candidate/bin/gtk-query-settings"; then
        gtk_out=$candidate
        break
    fi
done
util_linux_out=$(find_program_output bin/unshare util-linux)

test -n "$gtk_out"
test -x "$python_out/bin/python3"
test -x "$xorg_server_out/bin/Xvfb"
test -x "$gtk_out/bin/gtk-query-settings"
test -x "$util_linux_out/bin/unshare"

exec "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$python_out/bin/python3" - "$theme_out" "$gtk_out/bin/gtk-query-settings" \
    "$xorg_server_out/bin/Xvfb" <<'PY'
import hashlib
import os
import pathlib
import re
import subprocess
import sys
import tempfile


theme_out = pathlib.Path(sys.argv[1])
gtk_query_settings = sys.argv[2]
xvfb = sys.argv[3]
theme = theme_out / "share" / "themes" / "Azurra"


def tree_digest(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest.update(str(path.relative_to(root)).encode())
        digest.update(repr((status.st_mode, status.st_size)).encode())
        if path.is_symlink():
            digest.update(os.readlink(path).encode())
        elif path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


assert (theme / "gtk.css").stat().st_size > 0
assert (theme / "gtk-dark.css").stat().st_size > 0
assert (theme / "theme.conf").is_file()
for directory in (theme / "assets", theme / "assets-dark"):
    assert directory.is_dir() and any(directory.iterdir()), directory
assert not (theme_out / "bin").exists()
assert not (theme / "assets-render").exists()
assert not (theme / "SCSS").exists()
assert [path.name for path in (theme_out / "share" / "themes").iterdir()] == ["Azurra"]

url_pattern = re.compile(r"url\(\s*['\"]?([^'\")?#]+)")
for css_name in ("gtk.css", "gtk-dark.css"):
    css = (theme / css_name).read_text(encoding="utf-8")
    for relative in url_pattern.findall(css):
        asset = (theme / relative).resolve()
        assert asset.is_relative_to(theme.resolve()) and asset.exists(), (css_name, relative)

before = tree_digest(theme_out)
with tempfile.TemporaryDirectory(prefix="azurra-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home = root / "home"
    data = root / "data"
    config = root / "config"
    cache = root / "cache"
    runtime = root / "runtime"
    for directory in (home, data, config, cache, runtime):
        directory.mkdir()
    runtime.chmod(0o700)
    environment = {
        "HOME": str(home), "XDG_DATA_HOME": str(data),
        "XDG_CONFIG_HOME": str(config), "XDG_CACHE_HOME": str(cache),
        "XDG_RUNTIME_DIR": str(runtime),
        "XDG_DATA_DIRS": str(theme_out / "share"), "GTK_THEME": "Azurra",
        "GDK_BACKEND": "x11", "DISPLAY": ":99",
        "LC_ALL": "C.UTF-8", "PATH": "",
    }
    display = subprocess.Popen([xvfb, ":99", "-screen", "0", "64x64x24",
                                "-nolisten", "tcp"], env=environment,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        import time
        time.sleep(.3)
        assert display.poll() is None, display.stderr.read().decode()
        result = subprocess.run([gtk_query_settings], env=environment,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True)
        assert result.returncode == 0, result.stderr
    finally:
        display.terminate()
        display.wait(timeout=5)

assert tree_digest(theme_out) == before, "the immutable package output changed"
print("azurra GTK theme offline smoke passed")
PY
