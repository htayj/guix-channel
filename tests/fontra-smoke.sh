#!/bin/sh
set -eu

channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
guix_bin=${GUIX:-guix}
out=${FONTRA_PACKAGE:-}
if test -z "$out"; then
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-offload fontra)
fi
python=$(sed -n '1s/^#!\([^ ]*\).*/\1/p' "$out/bin/.fontra-real")
test -x "$python"
for command in fontra fontra-copy fontra-workflow; do
    test -x "$out/bin/$command"
done
test -f "$out/share/doc/fontra/LICENSE"

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT HUP INT TERM
unset PYTHONPATH GUIX_PYTHONPATH PYTHONHOME
export HOME="$home" XDG_CACHE_HOME="$home/cache" XDG_CONFIG_HOME="$home/config" XDG_DATA_HOME="$home/data" PYTHONNOUSERSITE=1

"$python" - "$out" "$home" <<'PY'
import hashlib
import json
import pathlib
import plistlib
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser

out, home = map(pathlib.Path, sys.argv[1:])
work = home / "fonts"
work.mkdir()

def run(command, *args):
    subprocess.run([str(out / "bin" / command), *map(str, args)], cwd=work, check=True)

# Exercise project creation, not merely argparse or version reporting.
run("fontra", "new", work / "new.fontra")
created = json.loads((work / "new.fontra/font-data.json").read_text())
source = next(iter(created["sources"].values()))
assert source["name"] == "Regular", source
assert source["lineMetricsHorizontalLayout"]["ascender"]["value"] == 750, source

# A local UFO fixture with a real encoded outline and explicit metrics.
ufo = work / "input.ufo"
(ufo / "glyphs").mkdir(parents=True)
def plist(path, value):
    path.write_bytes(plistlib.dumps(value))
plist(ufo / "metainfo.plist", {"creator": "org.gnu.guix.fontra-smoke", "formatVersion": 3})
plist(ufo / "layercontents.plist", [["public.default", "glyphs"]])
plist(ufo / "fontinfo.plist", {"familyName": "Guix Smoke", "styleName": "Regular", "unitsPerEm": 1000, "ascender": 750, "descender": -250})
plist(ufo / "glyphs/contents.plist", {"A": "A.glif"})
(ufo / "glyphs/A.glif").write_text('''<?xml version="1.0" encoding="UTF-8"?>
<glyph name="A" format="2"><advance width="600"/><unicode hex="0041"/>
<outline><contour><point x="50" y="0" type="line"/><point x="300" y="700" type="line"/><point x="550" y="0" type="line"/></contour></outline></glyph>
''')
run("fontra-copy", ufo, work / "converted.fontra")
run("fontra-copy", work / "converted.fontra", work / "roundtrip.ufo")

def check_ufo(path):
    import xml.etree.ElementTree as ET
    info = plistlib.loads((path / "fontinfo.plist").read_bytes())
    assert info["unitsPerEm"] == 1000, info
    names = plistlib.loads((path / "glyphs/contents.plist").read_bytes())
    assert set(names) == {"A"}, names
    glyph = ET.parse(path / "glyphs" / names["A"]).getroot()
    assert glyph.find("unicode").attrib["hex"] == "0041"
    assert float(glyph.find("advance").attrib["width"]) == 600
    points = glyph.findall("outline/contour/point")
    assert [(float(p.attrib["x"]), float(p.attrib["y"])) for p in points] == [(50, 0), (300, 700), (550, 0)]

check_ufo(work / "roundtrip.ufo")
workflow = work / "workflow.yaml"
workflow.write_text('''steps:
  - input: fontra-read
    source: converted.fontra
  - filter: subset-glyphs
    glyphNames: [A]
  - output: fontra-write
    destination: workflow.ufo
''')
run("fontra-workflow", "--output-dir", work, workflow)
check_ufo(work / "workflow.ufo")

# Serve only on loopback; use no proxy and inspect the installed wheel assets.
with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0))
    port = listener.getsockname()[1]
base = f"http://127.0.0.1:{port}"
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

def fetch(path):
    with opener.open(base + path, timeout=5) as response:
        return response.read(), response.headers.get_content_type()

class Assets(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = set()
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "script" and "src" in attrs:
            self.urls.add(attrs["src"])
        elif tag == "link" and attrs.get("rel") == "stylesheet":
            self.urls.add(attrs["href"])

# Record the immutable installed tree; commands must not write caches into it.
def fingerprint():
    return {str(p.relative_to(out)): hashlib.sha256(p.read_bytes()).digest()
            for p in out.rglob("*") if p.is_file()}

before = fingerprint()
with (home / "server.log").open("wb") as log:
    process = subprocess.Popen([str(out / "bin/fontra"), "--host", "127.0.0.1", "--http-port", str(port), "filesystem", str(work), "--read-only"], cwd=home, stdout=log, stderr=log)
    try:
        deadline = time.monotonic() + 30
        while True:
            if process.poll() is not None:
                raise AssertionError((home / "server.log").read_text())
            try:
                landing, mime = fetch("/")
                break
            except (OSError, urllib.error.URLError):
                if time.monotonic() >= deadline:
                    raise AssertionError((home / "server.log").read_text())
                time.sleep(0.1)
        assert mime == "text/html" and b"Fontra" in landing
        assets = Assets()
        for path in ("/", "/editor.html", "/fontoverview.html", "/fontinfo.html", "/applicationsettings.html"):
            data, mime = fetch(path)
            assert mime == "text/html", (path, mime)
            assets.feed(data.decode())
        assert any(".js" in url for url in assets.urls), assets.urls
        assert any(".css" in url for url in assets.urls), assets.urls
        for url in assets.urls:
            parsed = urllib.parse.urlsplit(url)
            assert not parsed.scheme and not parsed.netloc, url
            path = "/" + parsed.path.lstrip("/")
            data, mime = fetch(path)
            assert len(data) > 100, path
            assert mime in ("text/javascript", "application/javascript", "text/css"), (path, mime)
        projects, _ = fetch("/projectlist")
        assert "converted.fontra" in json.loads(projects), projects
        client = next(out.glob("lib/python*/site-packages/fontra/client"))
        wasm = list(client.rglob("*.wasm"))
        assert wasm, "missing shaping WASM"
        for asset in wasm:
            data, mime = fetch("/" + asset.relative_to(client).as_posix())
            assert mime == "application/wasm" and data[:4] == b"\x00asm", asset
        assert fingerprint() == before, "server modified its store output"
    finally:
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
print("fontra smoke passed: project creation, encoded-outline conversion, workflow, and loopback HTML/JS/CSS/WASM")
PY
