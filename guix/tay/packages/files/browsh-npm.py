#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Replay Browsh's pinned npm lock, without npm, network or lifecycle scripts."""

import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys

# fsevents 2.3.2 declares optional: true and os: ["darwin"] in the
# pinned webext/package-lock.json.  All other optional dependencies remain.
EXCLUDED = {"node_modules/fsevents"}
LOCK_SHA256 = "427063e0e6d60355d57a552821fba42e660a34a02a3c765ac49e49435dca02b9"
LEGAL = re.compile(r"licen[cs]e|copying|copyright|notice|authors", re.I)


def license_label(metadata):
    license_value = metadata.get("license")
    if isinstance(license_value, str):
        return license_value
    if isinstance(license_value, dict):
        return license_value["type"]
    legacy = metadata.get("licenses", [])
    if isinstance(legacy, str):
        return legacy
    if legacy:
        return " OR ".join(item["type"] if isinstance(item, dict) else item
                           for item in legacy)
    # tosource@1.0.0 has no package.json license field; its Readme.md
    # identifies Zlib and its LICENSE contains the full Zlib text.
    if metadata["name"] == "tosource" and metadata["version"] == "1.0.0":
        return "Zlib"
    raise ValueError(f"Missing npm license declaration: {metadata['name']}")


def prepare(manifest, notice_directory):
    lock_bytes = Path("package-lock.json").read_bytes()
    if hashlib.sha256(lock_bytes).hexdigest() != LOCK_SHA256:
        raise ValueError("Not Browsh's pinned webext/package-lock.json")
    lockfile = json.loads(lock_bytes)
    if lockfile["lockfileVersion"] != 2:
        raise ValueError("Expected lockfile version 2")
    lock = lockfile["packages"]
    selected = []
    for line in Path(manifest).read_text().splitlines():
        location, name, version, archive, integrity, license_name = line.split("\t")
        parts = PurePosixPath(location).parts
        if (not parts or parts[0] != "node_modules" or ".." in parts
                or PurePosixPath(location).is_absolute()):
            raise ValueError(f"Invalid npm location: {location}")
        if name != location.rsplit("node_modules/", 1)[1]:
            raise ValueError(f"Mismatched npm name: {location}")
        selected.append((location, name, version, archive, integrity, license_name))
    locations = [entry[0] for entry in selected]
    if (len(locations) != len(set(locations))
            or set(locations) != set(lock) - {""} - EXCLUDED):
        raise ValueError("npm manifest does not exactly cover the upstream Linux lock closure")

    cache = Path(".browsh-npm-cache")
    cache.mkdir()
    sources = {}
    legal = Path(notice_directory)
    legal.mkdir(parents=True, exist_ok=True)
    inventory = []
    for location, name, version, archive, integrity, license_name in sorted(selected):
        if (lock[location]["version"] != version
                or lock[location].get("integrity") != integrity
                or not integrity.startswith("sha512-")):
            raise ValueError(f"Unfixed or mismatched lock entry: {location}")
        key = (name, version, integrity)
        if key not in sources:
            expected = base64.b64decode(integrity.removeprefix("sha512-"), validate=True)
            digest = hashlib.sha512()
            with open(archive, "rb") as stream:
                for chunk in iter(lambda: stream.read(65536), b""):
                    digest.update(chunk)
            if digest.digest() != expected:
                raise ValueError(f"npm lock integrity mismatch: {name}@{version}")
            source = cache / str(len(sources))
            source.mkdir()
            subprocess.run(["tar", "xf", archive, "-C", str(source),
                            "--strip-components=1"], check=True)
            metadata = json.loads((source / "package.json").read_text())
            if metadata["name"] != name or metadata["version"] != version:
                raise ValueError(f"npm archive identity mismatch: {name}@{version}")
            if license_label(metadata) != license_name:
                raise ValueError(f"npm archive license mismatch: {name}@{version}")
            sources[key] = (source, license_name)
            destination = legal / (name.replace("/", "__") + "@" + version)
            destination.mkdir(parents=True)
            found = []
            for file in sorted(source.rglob("*")):
                relative = file.relative_to(source)
                if (file.is_file() and "node_modules" not in relative.parts
                        and (LEGAL.search(file.name)
                             or file.name.lower().startswith("readme"))):
                    target = destination / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(file, target)
                    found.append(str(relative))
            shutil.copyfile(source / "package.json", destination / "package.json")
            inventory.append({"package": f"{name}@{version}",
                              "license": license_name,
                              "resolved": lock[location]["resolved"],
                              "integrity": integrity, "notices": found})
        elif sources[key][1] != license_name:
            raise ValueError(f"Inconsistent npm license: {location}")
        destination = Path(location)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(sources[key][0], destination)
    (legal / "inventory.json").write_text(json.dumps(inventory, indent=2) + "\n")
    shutil.rmtree(cache)

    for location, name, version, _, _, _ in sorted(selected):
        package = Path(location)
        metadata = json.loads((package / "package.json").read_text())
        binaries = metadata.get("bin", {})
        if isinstance(binaries, str):
            binaries = {name.rsplit("/", 1)[-1]: binaries}
        # Scoped package CLIs belong in node_modules/.bin, not @scope/.bin.
        modules = package.parent.parent if package.parent.name.startswith("@") else package.parent
        directory = modules / ".bin"
        directory.mkdir(exist_ok=True)
        for binary_name, binary in binaries.items():
            target = package / binary
            if not target.is_file():
                raise ValueError(f"Missing upstream CLI: {name}@{version}: {binary}")
            target.chmod(target.stat().st_mode | 0o111)
            link = directory / binary_name
            if not link.exists():
                link.symlink_to(os.path.relpath(target, directory))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise ValueError("Usage: browsh-npm.py MANIFEST NOTICE-DIRECTORY (cwd: webext)")
    prepare(sys.argv[1], sys.argv[2])
