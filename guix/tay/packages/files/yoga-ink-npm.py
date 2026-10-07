#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Materialize Yoga's fixed compiler tree without npm or lifecycle scripts.

MANIFEST has location<TAB>name@version<TAB>archive rows; locations are relative
node_modules paths within MODULES-ROOT.  Optional NOTICE-MANIFEST has
name@version<TAB>notice-file rows.  Keep license texts in the packages and copy
all archive notices, README files and metadata into NOTICE-DIRECTORY.
"""

import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import sys
import tarfile

LEGAL = re.compile(r"licen[cs]e|copying|copyright|notice|authors", re.I)


def records(filename):
    selected = []
    for line in Path(filename).read_text(encoding="utf-8").splitlines():
        location, key, archive = line.split("\t")
        name, version = key.rsplit("@", 1)
        if not name or not version or location != "node_modules/" + name:
            raise ValueError(f"Invalid compiler package location: {location}")
        parts = PurePosixPath(location).parts
        if ".." in parts or "." in parts or location.startswith("/"):
            raise ValueError(f"Invalid compiler package location: {location}")
        selected.append((location, key, archive))
    if not selected or len({entry[0] for entry in selected}) != len(selected):
        raise ValueError("Empty manifest or duplicate compiler package locations")
    return sorted(selected)


def unpack(archive, destination):
    """Strip the npm top-level directory, ignoring host-specific tar metadata."""
    destination.mkdir(parents=True)
    with tarfile.open(archive, "r:gz") as source:
        members = sorted(source.getmembers(), key=lambda member: member.name)
        roots = {PurePosixPath(member.name).parts[0] for member in members}
        if len(roots) != 1:
            raise ValueError(f"Compiler archive has multiple roots: {archive}")
        for member in members:
            path = PurePosixPath(member.name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError(f"Unsafe compiler archive member: {member.name}")
            relative = path.parts[1:]
            if not relative:
                continue
            target = destination.joinpath(*relative)
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                target.parent.mkdir(parents=True, exist_ok=True)
                with source.extractfile(member) as content, target.open("xb") as output:
                    shutil.copyfileobj(content, output)
                target.chmod(0o755 if member.mode & 0o111 else 0o644)
            else:
                # The fixed compiler archives have no links or special files.
                raise ValueError(f"Unexpected compiler archive member: {member.name}")


def prepare(manifest, modules_root, notices, notice_manifest=None):
    selected = records(manifest)
    supplements = {}
    if notice_manifest:
        for line in Path(notice_manifest).read_text(encoding="utf-8").splitlines():
            key, filename = line.split("\t")
            if key in supplements:
                raise ValueError(f"Duplicate compiler license supplement: {key}")
            supplements[key] = filename
    keys = {key for _, key, _ in selected}
    if set(supplements) - keys:
        raise ValueError("License supplement has no matching compiler source")

    root = Path(modules_root)
    legal = Path(notices)
    legal.mkdir(parents=True)
    inventory = []
    for location, key, archive in selected:
        package = root / location
        unpack(archive, package)
        metadata = json.loads((package / "package.json").read_text(encoding="utf-8"))
        name, version = key.rsplit("@", 1)
        if metadata["name"] != name or metadata["version"] != version:
            raise ValueError(f"Compiler archive identity mismatch: {key}")
        if key in supplements:
            shutil.copyfile(supplements[key], package / "GUIX-LICENSE.txt")

        destination = legal / key.replace("/", "__")
        destination.mkdir()
        found = []
        licenses = []
        for file in sorted(package.rglob("*")):
            relative = file.relative_to(package)
            if file.is_file() and "node_modules" not in relative.parts:
                if LEGAL.search(file.name) or file.name.lower().startswith("readme"):
                    target = destination / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(file, target)
                    found.append(relative.as_posix())
                if re.search(r"licen[cs]e|copying", file.name, re.I):
                    licenses.append(relative.as_posix())
        if not licenses:
            raise ValueError(f"Compiler archive has no license text: {key}")
        shutil.copyfile(package / "package.json", destination / "package.json")
        inventory.append({"package": key, "license": metadata.get("license"),
                          "notices": found})

        binaries = metadata.get("bin", {})
        if isinstance(binaries, str):
            binaries = {name.rsplit("/", 1)[-1]: binaries}
        # Scoped package CLIs live in node_modules/.bin, not @scope/.bin.
        directory = root / "node_modules/.bin"
        for binary_name, binary in sorted(binaries.items()):
            target = package / binary
            if not target.is_file():
                raise ValueError(f"Missing upstream compiler CLI: {key}: {binary}")
            target.chmod(target.stat().st_mode | 0o111)
            directory.mkdir(exist_ok=True)
            link = directory / binary_name
            link.symlink_to(os.path.relpath(target, directory))

    (legal / "inventory.json").write_text(
        json.dumps(inventory, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    # No archived uid, gid, mtime, umask or extraction order enters the tree.
    for directory in (root / "node_modules", legal):
        for file in sorted(directory.rglob("*"), reverse=True):
            if not file.is_symlink():
                if file.is_dir():
                    file.chmod(0o755)
                else:
                    file.chmod(0o755 if file.stat().st_mode & 0o111 else 0o644)
                os.utime(file, (1, 1))
        directory.chmod(0o755)
        os.utime(directory, (1, 1))


if __name__ == "__main__":
    if len(sys.argv) not in (4, 5):
        raise ValueError("Usage: yoga-ink-npm.py MANIFEST MODULES-ROOT "
                         "NOTICE-DIRECTORY [NOTICE-MANIFEST]")
    prepare(*sys.argv[1:])
