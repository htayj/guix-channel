#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Materialize LiteGraph's locked Grunt build tree without npm resolution."""

import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys

LEGAL = re.compile(r"licen[cs]e|copying|copyright|notice|authors", re.I)


def records(filename):
    for line in Path(filename).read_text().splitlines():
        location, key, archive = line.split("\t")
        parts = PurePosixPath(location).parts
        if not parts or parts[0] != "node_modules" or ".." in parts:
            raise ValueError(f"Invalid lock location: {location}")
        yield location, key, archive


def prepare(manifest, notices):
    packages = json.loads(Path("package-lock.json").read_text())["packages"]
    cache = Path(".litegraph-npm-cache")
    cache.mkdir()
    sources = {}
    selected = sorted(records(manifest), key=lambda record: record[0])
    for location, key, archive in selected:
        locked = packages[location]
        name, version = key.rsplit("@", 1)
        if locked["version"] != version or not locked.get("integrity"):
            raise ValueError(f"Unfixed or mismatched lock record: {location}")
        if key not in sources:
            source = cache / str(len(sources))
            source.mkdir()
            subprocess.run(["tar", "xf", archive, "-C", str(source),
                            "--strip-components=1"], check=True)
            metadata = json.loads((source / "package.json").read_text())
            if metadata["name"] != name or metadata["version"] != version:
                raise ValueError(f"Archive identity mismatch: {key}")
            if name == "async":
                # The per-function CommonJS source tree is complete; don't use
                # the rollup browser bundle advertised as its default entry.
                metadata["main"] = "index.js"
            elif name == "esprima":
                # Compile its matching TypeScript tag in the recipe, without
                # webpack's generated browser entrypoint or npm lifecycle code.
                metadata["main"] = "src/esprima.js"
            (source / "package.json").write_text(json.dumps(metadata) + "\n")
            sources[key] = source
        destination = Path(location)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(sources[key], destination)

    # The Grunt CLI and plugins require only the locked package tree.  Retain
    # every applicable notice from the archives actually used by the build.
    inventory = []
    legal = Path(notices)
    for key, source in sorted(sources.items()):
        metadata = json.loads((source / "package.json").read_text())
        destination = legal / key.replace("/", "__")
        destination.mkdir(parents=True)
        found = []
        for file in sorted(source.rglob("*")):
            relative = file.relative_to(source)
            if (file.is_file() and LEGAL.search(file.name)
                    and "node_modules" not in relative.parts):
                target = destination / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(file, target)
                found.append(str(relative))
        if not found:
            raise ValueError(f"Locked build archive has no legal notice: {key}")
        shutil.copyfile(source / "package.json", destination / "package.json")
        inventory.append({"package": key, "license": metadata.get("license"),
                          "notices": found})
    (legal / "inventory.json").write_text(json.dumps(inventory, indent=2) + "\n")
    shutil.rmtree(cache)

    for location, key, _ in selected:
        package = Path(location)
        metadata = json.loads((package / "package.json").read_text())
        binaries = metadata.get("bin", {})
        if isinstance(binaries, str):
            binaries = {metadata["name"].rsplit("/", 1)[-1]: binaries}
        directory = package.parent / ".bin"
        directory.mkdir(exist_ok=True)
        for name, binary in binaries.items():
            target = package / binary
            if not target.is_file():
                raise ValueError(f"Missing declared CLI: {key}: {binary}")
            target.chmod(target.stat().st_mode | 0o111)
            link = directory / name
            if not link.exists():
                link.symlink_to(os.path.relpath(target, directory))


if len(sys.argv) != 3:
    raise ValueError("Usage: litegraph-npm.py MANIFEST NOTICE-DIRECTORY")
prepare(sys.argv[1], sys.argv[2])
