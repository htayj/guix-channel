#!/bin/sh
# Generate and compare two real pages in isolated, networkless caller state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 2; then
    echo "usage: $0 [store-output [evidence-directory]]" >&2
    exit 64
fi
if test "$#" -ge 1; then
    out=$1
else
    out=$($guix_bin build --no-grafts -L "$channel_dir/guix" talmudifier)
fi
case "$out" in
    /*) ;;
    *) echo 'talmudifier output must be an absolute path' >&2; exit 64 ;;
esac

find_output ()
{
    for candidate in $($guix_bin build "$2"); do
        if test -x "$candidate/$1"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "could not find $1 in Guix package $2" >&2
    return 1
}
python_out=$(find_output bin/python3 python)
util_linux_out=$(find_output bin/unshare util-linux)
poppler_out=$(find_output bin/pdftotext poppler)
test -x "$poppler_out/bin/pdftoppm"
# Resolve the propagated Python API environment before disabling networking.
api_python_path=$($guix_bin shell --pure --no-grafts -L "$channel_dir/guix" \
    talmudifier python -- python3 -c \
    'import sys; print(":".join(p for p in sys.path if p.startswith("/gnu/store/")))')

"$python_out/bin/python3" -I - "$out" "$util_linux_out/bin/unshare" \
    "$poppler_out/bin/pdftotext" "$poppler_out/bin/pdftoppm" "${2-}" "$api_python_path" <<'PY'
import hashlib
import os
from pathlib import Path
import shutil
import stat
import struct
import subprocess
import sys
import tempfile

out = Path(sys.argv[1]).resolve(strict=True)
unshare, pdftotext, pdftoppm = sys.argv[2:5]
evidence = Path(sys.argv[5]).resolve() if sys.argv[5] else None
api_python_path = ":".join(
    [str(path) for path in sorted((out / "lib").glob("python*/site-packages"))]
    + [sys.argv[6]])
executable = out / "bin/talmudifier"
assert executable.is_file() and os.access(executable, os.X_OK), "missing launcher"
if evidence is not None:
    assert not evidence.is_relative_to(Path("/gnu/store")), "evidence must be outside the store"
    assert not evidence.is_relative_to(out), "evidence must be outside the package output"


def file_hash(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def tree_hash(root):
    # Include every entry, even empty directories, modes and symlink targets;
    # never follow links out of the package's full output tree.
    digest = hashlib.sha256()
    for path in [root, *sorted(root.rglob("*"))]:
        info = path.lstat()
        name = os.fsencode(str(path.relative_to(root)))
        digest.update(len(name).to_bytes(8, "big"))
        digest.update(name)
        digest.update(info.st_mode.to_bytes(4, "big"))
        if stat.S_ISREG(info.st_mode):
            digest.update(bytes.fromhex(file_hash(path)))
        elif stat.S_ISLNK(info.st_mode):
            target = os.fsencode(os.readlink(path))
            digest.update(len(target).to_bytes(8, "big"))
            digest.update(target)
        else:
            assert stat.S_ISDIR(info.st_mode), f"unexpected store entry: {path}"
    return digest.hexdigest()


def check_notices():
    docs = out / "share/doc/talmudifier"
    notices = {
        "LICENSE": ("permission is hereby granted",),
        "fonts/averia/OFL.txt": ("sil open font license",),
        "fonts/garamond/OFL.txt": ("sil open font license",),
        "fonts/fell_french_canon/Fell Types License.txt": ("sil open font license",),
        "fonts/fell_flowers/Fell Types License.txt": ("sil open font license",),
        "fonts/culmus/README.md": ("gnu general public license",),
        "fonts/culmus/LICENSE": ("gnu general public license",),
        "fonts/culmus/GNU-GPL": ("gnu general public license",),
        "fonts/culmus/LICENSE-BITSTREAM": ("permission", "redistribute"),
        "fonts/rashi/License": ("lppl",),
        "fonts/rashi/lppl.txt": ("latex project public license",),
    }
    for relative, required in notices.items():
        path = docs / relative
        assert path.is_file() and path.stat().st_size > 0, f"missing notice: {path}"
        text = " ".join(path.read_text(encoding="utf-8").lower().split())
        assert all(token in text for token in required), f"incomplete notice: {path}"


def isolated(command, cwd, environment):
    # Namespace failure is fatal: there is deliberately no online fallback.
    result = subprocess.run(
        [unshare, "--user", "--map-root-user", "--net", *command],
        cwd=cwd, env=environment, capture_output=True, timeout=240,
    )
    assert result.returncode == 0, (
        f"network-isolated command failed: {command!r}; status={result.returncode}\n"
        f"stdout:\n{result.stdout.decode('utf-8', errors='replace')}\n"
        f"stderr:\n{result.stderr.decode('utf-8', errors='replace')}\n"
        "User and network namespaces are required; no fallback is permitted."
    )
    return result


def generate(root):
    directories = {}
    for name in ("home", "config", "data", "cache", "state", "runtime", "tmp",
                 "texmf-home", "texmf-var", "texmf-config", "texmf-cache",
                 "vartexfonts", "work", "render"):
        directory = root / name
        directory.mkdir(parents=True, mode=0o700)
        directories[name] = str(directory)
    environment = {
        "HOME": directories["home"],
        "XDG_CONFIG_HOME": directories["config"],
        "XDG_DATA_HOME": directories["data"],
        "XDG_CACHE_HOME": directories["cache"],
        "XDG_STATE_HOME": directories["state"],
        "XDG_RUNTIME_DIR": directories["runtime"],
        "TMPDIR": directories["tmp"],
        "TEXMFHOME": directories["texmf-home"],
        "TEXMFVAR": directories["texmf-var"],
        "TEXMFCONFIG": directories["texmf-config"],
        "TEXMFCACHE": directories["texmf-cache"],
        "VARTEXFONTS": directories["vartexfonts"],
        "PATH": str(out / "bin"),
        "LC_ALL": "C.UTF-8",
        "TZ": "UTC",
        "SOURCE_DATE_EPOCH": "1704067200",
        "FORCE_SOURCE_DATE": "1",
        "PYTHONNOUSERSITE": "1",
        "PYTHONDONTWRITEBYTECODE": "1",
    }
    work = root / "work"
    # The wrapper's entire argv is exactly [out/bin/talmudifier], with no args.
    result = isolated([str(executable)], work, environment)
    assert b"TALMUDIFIER_RUNTIME_OK" in result.stdout.splitlines(), (
        "missing standalone runtime success marker", result.stdout, result.stderr
    )
    # Forward only bytes really emitted by the installed program.
    sys.stdout.buffer.write(result.stdout)
    sys.stdout.buffer.flush()
    assert sorted(path.name for path in work.iterdir()) == ["Output"], "unexpected caller files"
    output = work / "Output"
    assert output.is_dir() and not output.is_symlink(), "missing real Output directory"
    assert sorted(path.name for path in output.iterdir()) == ["test_page.pdf", "test_page.tex"], (
        "unexpected Output contents"
    )
    pdf, tex = output / "test_page.pdf", output / "test_page.tex"
    assert all(path.is_file() and not path.is_symlink() for path in (pdf, tex)), "outputs must be real files"
    with pdf.open("rb") as stream:
        assert stream.read(5) == b"%PDF-" and pdf.stat().st_size > 5, "invalid PDF"
    assert "Talmudifier Test Page" in tex.read_text(encoding="utf-8"), "missing TeX title"
    text = isolated([pdftotext, "-enc", "UTF-8", str(pdf), "-"], work, environment).stdout
    normalized = " ".join(text.decode("utf-8").split()).encode("utf-8")
    assert b"Talmudifier Test Page" in normalized, "missing rendered PDF title"
    image_prefix = root / "render/test_page"
    isolated([pdftoppm, "-f", "1", "-l", "1", "-singlefile", "-r", "96",
              "-png", str(pdf), str(image_prefix)], work, environment)
    png = image_prefix.with_suffix(".png")
    with png.open("rb") as stream:
        header = stream.read(24)
    assert png.stat().st_size > 24 and header[:8] == b"\x89PNG\r\n\x1a\n", "invalid PNG"
    assert header[8:16] == b"\x00\x00\x00\x0dIHDR", "missing PNG dimensions"
    width, height = struct.unpack(">II", header[16:24])
    assert width > 0 and height > 0, "empty rendered page"
    return {
        "pdf": pdf, "tex": tex, "png": png,
        "pdf_hash": file_hash(pdf), "tex_hash": file_hash(tex),
        "text": normalized, "dimensions": (width, height),
    }

def exercise_api(root):
    root.mkdir()
    home = root / "home"
    home.mkdir()
    code = '''from pathlib import Path
from talmudifier.talmudifier import Talmudifier
from talmudifier.word import Word
from talmudifier.style import Style
word = Word("Morbi", Style(False, False, False), None, None)
assert not word.pairs, "en_US must not leave a two-character suffix"
text = ("Offline left commentary discusses local documents and thoughtful interpretation. " * 6)
center = ("Independent central passage examines typesetting without a network connection. " * 3)
right = ("Right commentary compares typography and meaningful local source material. " * 6)
t = Talmudifier(text, center, right)
document = t.writer.write(t.get_chapter("Independent API Document") + "\\n" + t.get_tex(), "api_page")
Path("Output/api_page.tex").write_text(document, encoding="utf-8")
'''
    env = {
        "HOME": str(home), "TMPDIR": str(home), "PATH": "/nonexistent",
        "PYTHONPATH": api_python_path, "GUIX_PYTHONPATH": api_python_path,
        "PYTHONNOUSERSITE": "1", "PYTHONDONTWRITEBYTECODE": "1",
        "LC_ALL": "C.UTF-8", "SOURCE_DATE_EPOCH": "1704067200",
        "FORCE_SOURCE_DATE": "1",
    }
    # No recipes/fonts directory, XeLaTeX PATH, or launcher setup is provided.
    isolated([sys.executable, "-c", code], root, env)
    pdf = root / "Output/api_page.pdf"
    text = isolated([pdftotext, str(pdf), "-"], root, env).stdout
    assert b"Independent API Document" in b" ".join(text.split()), "API did not render own text"
    assert b"Offline left commentary" in b" ".join(text.split()), "API lost caller's local text"


before = tree_hash(out)
try:
    check_notices()
    # Ignore inherited TMPDIR even for the smoke's scratch root.
    with tempfile.TemporaryDirectory(prefix="talmudifier-smoke-", dir="/tmp") as scratch:
        runs = [generate(Path(scratch) / f"run-{index}") for index in (1, 2)]
        exercise_api(Path(scratch) / "api")
        assert runs[0]["tex_hash"] == runs[1]["tex_hash"], "TeX differs between isolated runs"
        assert (runs[0]["pdf_hash"] == runs[1]["pdf_hash"] or
                runs[0]["text"] == runs[1]["text"]), "PDF content differs between isolated runs"
        if evidence is not None:
            for index, run in enumerate(runs, 1):
                destination = evidence / f"run-{index}"
                destination.mkdir(parents=True, exist_ok=True)
                for kind in ("pdf", "tex", "png"):
                    shutil.copyfile(run[kind], destination / f"test_page.{kind}")
        print(f"talmudifier isolated render smoke passed: TeX SHA256={runs[0]['tex_hash']}; "
              f"PDF SHA256={[run['pdf_hash'] for run in runs]}; "
              f"PNG dimensions={[run['dimensions'] for run in runs]}")
finally:
    after = tree_hash(out)
    assert before == after, f"store tree changed: {before} -> {after}"
PY
