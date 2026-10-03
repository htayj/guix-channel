"""Install pinned official wheels without pip or network, retaining licenses."""
import configparser
import os
from pathlib import Path
import subprocess
import sys
import zipfile

out = Path(sys.argv[1])
python, loader = sys.argv[2:4]
external = sys.argv[4].split(":")
site = out / "lib/python3.12/site-packages"
site.mkdir(parents=True)
(out / "bin").mkdir()
for archive in sys.argv[5:]:
    with zipfile.ZipFile(archive) as wheel:
        for item in wheel.infolist():
            if item.is_dir():
                continue
            parts = Path(item.filename).parts
            if not parts or ".." in parts or item.filename.startswith("/"):
                raise ValueError("unsafe wheel path: " + item.filename)
            if parts[0].endswith(".data"):
                base = {"purelib": site, "platlib": site, "scripts": out / "bin",
                        "data": out, "headers": out / "include"}[parts[1]]
                target = base.joinpath(*parts[2:])
            else:
                target = site.joinpath(*parts)
            data = wheel.read(item)
            if target.exists() and target.read_bytes() != data:
                raise ValueError("wheel collision: " + str(target))
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            target.chmod((item.external_attr >> 16 & 0o777) or 0o644)

elfs = []
for file in site.rglob("*"):
    if file.is_file():
        with file.open("rb") as stream:
            if stream.read(4) == b"\x7fELF":
                elfs.append(file)
libdirs = sorted({str(file.parent) for file in elfs})
for file in elfs:
    file.chmod(file.stat().st_mode | 0o200)
    old = subprocess.check_output(["patchelf", "--print-rpath", str(file)], text=True).strip()
    subprocess.run(["patchelf", "--set-rpath",
                    ":".join(filter(None, [old] + libdirs + external)), str(file)], check=True)
    result = subprocess.run(["patchelf", "--print-interpreter", str(file)], capture_output=True)
    if result.returncode == 0:
        subprocess.run(["patchelf", "--set-interpreter", loader, str(file)], check=True)

for entry_file in site.glob("*.dist-info/entry_points.txt"):
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    config.read(entry_file)
    if config.has_section("console_scripts"):
        for name, entry in config.items("console_scripts"):
            module, symbol = entry.split(":", 1)
            symbol = symbol.split("[", 1)[0].strip()
            script = out / "bin" / name
            script.write_text("#!" + python + " -I\nimport importlib, sys\n"
                              "sys.path.insert(0, " + repr(str(site)) + ")\n"
                              "target = importlib.import_module(" + repr(module.strip()) + ")\n"
                              "for part in " + repr(symbol.split(".")) + ": target = getattr(target, part)\n"
                              "sys.exit(target())\n")
            script.chmod(0o755)
