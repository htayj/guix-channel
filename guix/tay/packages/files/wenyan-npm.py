#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Materialize the reviewed subset of Wenyan's lock, without npm resolution."""

import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys

LEGAL = re.compile(r"licen[cs]e|copying|copyright|notice|authors|readme|unlicense", re.I)


def records(filename):
    for line in Path(filename).read_text().splitlines():
        path, key, archive = line.split("\t")
        parts = PurePosixPath(path).parts
        if not parts or parts[0] != "node_modules" or ".." in parts:
            raise ValueError(f"Invalid lock location: {path}")
        yield path, key, archive


def prepare(manifest):
    packages = json.loads(Path("package-lock.json").read_text())["packages"]
    cache = Path(".wenyan-npm-cache")
    cache.mkdir()
    sources = {}
    for location, key, archive in records(manifest):
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
            sources[key] = source
        destination = Path(location)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(sources[key], destination)
    shutil.rmtree(cache)
    # Tools spawn other CLI tools through the ordinary local .bin directory.
    for location, key, _ in records(manifest):
        package = Path(location)
        metadata = json.loads((package / "package.json").read_text())
        binaries = metadata.get("bin", {})
        if isinstance(binaries, str):
            binaries = {metadata["name"].rsplit("/", 1)[-1]: binaries}
        directory = package.parent / ".bin"
        if package.parent.name.startswith("@"):
            directory = package.parent.parent / ".bin"
        directory.mkdir(exist_ok=True)
        for name, binary in binaries.items():
            target = package / binary
            if not target.is_file():
                raise ValueError(f"Missing declared CLI: {key}: {binary}")
            target.chmod(target.stat().st_mode | 0o111)
            link = directory / name
            if not link.exists():
                import os
                link.symlink_to(os.path.relpath(target, directory))


def install(manifest, runtime_filename, output):
    output = Path(output)
    module = output / "lib/node_modules/wenyanlang"
    runtime = set(Path(runtime_filename).read_text().splitlines())
    legal = output / "share/doc/wenyan/npm"
    seen = set()
    inventory = []
    for location, key, _ in records(manifest):
        source = Path(location)
        if location in runtime:
            destination = module / location
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(source, destination,
                            ignore=shutil.ignore_patterns(".bin", "node_modules"))
        if key in seen:
            continue
        seen.add(key)
        metadata = json.loads((source / "package.json").read_text())
        destination = legal / key.replace("/", "__")
        destination.mkdir(parents=True)
        notices = []
        for file in sorted(source.rglob("*")):
            if (file.is_file() and LEGAL.search(file.name)
                    and "node_modules" not in file.relative_to(source).parts):
                relative = file.relative_to(source)
                target = destination / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(file, target)
                notices.append(str(relative))
        if not notices:
            raise ValueError(f"Reviewed archive contains no legal notice: {key}")
        shutil.copyfile(source / "package.json", destination / "package.json")
        inventory.append({"package": key, "license": metadata.get("license"),
                          "notices": notices, "runtime": location in runtime})
    if runtime - {location for location, _, _ in records(manifest)}:
        raise ValueError("Runtime closure refers to an unsupplied archive")
    (legal / "inventory.json").write_text(json.dumps(inventory, indent=2) + "\n")


if sys.argv[1] == "prepare":
    prepare(sys.argv[2])
elif sys.argv[1] == "install":
    install(*sys.argv[2:])
else:
    raise ValueError("Expected prepare or install")
