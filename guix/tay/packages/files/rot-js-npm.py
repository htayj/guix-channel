#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Replay rot.js's fixed npm locations, without resolution or lifecycle scripts."""

import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys

# The Java executable is replaced by the source-built compiler.  The other
# executable compiler archives and macOS fsevents must never enter this build.
EXCLUDED = {
    "node_modules/fsevents",
    "node_modules/google-closure-compiler-java",
    "node_modules/google-closure-compiler-linux",
    "node_modules/google-closure-compiler-osx",
    "node_modules/google-closure-compiler-windows",
}
LEGAL = re.compile(r"licen[cs]e|copying|copyright|notice|authors", re.I)


def prepare(manifest, notice_directory):
    lock = json.loads(Path("package-lock.json").read_text())["packages"]
    selected = []
    for line in Path(manifest).read_text().splitlines():
        location, key, archive = line.split("\t")
        parts = PurePosixPath(location).parts
        if not parts or parts[0] != "node_modules" or ".." in parts:
            raise ValueError(f"Invalid npm location: {location}")
        selected.append((location, key, archive))
    locations = [entry[0] for entry in selected]
    if len(locations) != len(set(locations)) or set(locations) != set(lock) - {""} - EXCLUDED:
        raise ValueError("npm manifest does not exactly cover the upstream Linux lock closure")

    cache = Path(".rot-js-npm-cache")
    cache.mkdir()
    sources = {}
    legal = Path(notice_directory)
    inventory = []
    for location, key, archive in sorted(selected):
        _, version = key.rsplit("@", 1)
        # A source key may include its lock locator to disambiguate versions.
        # Archive metadata uses only the name following the innermost
        # node_modules component (including @scope when present).
        name = location.rsplit("node_modules/", 1)[1]
        if lock[location]["version"] != version or not lock[location].get("integrity"):
            raise ValueError(f"Unfixed or mismatched lock entry: {location}")
        if key not in sources:
            integrity = lock[location]["integrity"].split()[0]
            algorithm, expected = integrity.split("-", 1)
            digest = hashlib.new(algorithm)
            with open(archive, "rb") as stream:
                for chunk in iter(lambda: stream.read(65536), b""):
                    digest.update(chunk)
            if base64.b64encode(digest.digest()).decode() != expected:
                raise ValueError(f"npm lock integrity mismatch: {key}")
            source = cache / str(len(sources))
            source.mkdir()
            subprocess.run(["tar", "xf", archive, "-C", str(source),
                            "--strip-components=1"], check=True)
            if key == "shiki@0.9.15":
                # Node loads vscode-oniguruma/release/onig.wasm.  This separate
                # browser-only object is unused and has different provenance.
                (source / "dist/onig.wasm").unlink()
            metadata = json.loads((source / "package.json").read_text())
            if metadata["name"] != name or metadata["version"] != version:
                raise ValueError(f"npm archive identity mismatch: {key}")
            sources[key] = source
            destination = legal / key.replace("/", "__")
            destination.mkdir(parents=True)
            found = []
            # Preserve nested notices, including Oniguruma's third-party
            # notices.  README license sections and metadata are retained too.
            for file in sorted(source.rglob("*")):
                relative = file.relative_to(source)
                if (file.is_file() and "node_modules" not in relative.parts
                        and (LEGAL.search(file.name) or file.name.lower().startswith("readme"))):
                    target = destination / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(file, target)
                    found.append(str(relative))
            shutil.copyfile(source / "package.json", destination / "package.json")
            inventory.append({"package": key, "license": metadata.get("license"),
                              "resolved": lock[location]["resolved"],
                              "integrity": lock[location]["integrity"], "notices": found})
        destination = Path(location)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(sources[key], destination)
    (legal / "inventory.json").write_text(json.dumps(inventory, indent=2) + "\n")
    shutil.rmtree(cache)

    for location, key, _ in selected:
        package = Path(location)
        metadata = json.loads((package / "package.json").read_text())
        binaries = metadata.get("bin", {})
        if isinstance(binaries, str):
            binaries = {metadata["name"].rsplit("/", 1)[-1]: binaries}
        # Scoped package CLIs belong to node_modules/.bin, not @scope/.bin.
        modules = package.parent.parent if package.parent.name.startswith("@") else package.parent
        directory = modules / ".bin"
        directory.mkdir(exist_ok=True)
        for name, binary in binaries.items():
            target = package / binary
            if not target.is_file():
                raise ValueError(f"Missing upstream CLI: {key}: {binary}")
            target.chmod(target.stat().st_mode | 0o111)
            link = directory / name
            if not link.exists():
                link.symlink_to(os.path.relpath(target, directory))


if len(sys.argv) != 3:
    raise ValueError("Usage: rot-js-npm.py MANIFEST NOTICE-DIRECTORY")
prepare(sys.argv[1], sys.argv[2])
