#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Materialize the production Bun lock graph from immutable Guix npm archives.

Usage: python3 oh-my-opencode-slim-npm.py map.json
Run in the unchanged upstream source directory.  Map keys are Bun lock package
keys, including nested keys such as @opencode-ai/plugin/zod.  GUIX_SYSTEM selects
x86_64-linux or aarch64-linux; otherwise the build machine determines the CPU.
No network, package-manager invocation, or lifecycle scripts are used.
"""

import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import platform
import re
import shutil
import sys
import tarfile

LEGAL_NAME = re.compile(
    r"(?:licen[cs]e|copying|copyright|notice|authors|ofl|unlicense|readme)", re.I
)
SYSTEM_CPUS = {"x86_64-linux": "x64", "aarch64-linux": "arm64"}
# This peer supplies declarations/typechecking only.  The published index.js
# imports bun:ffi, not TypeScript.  Do not pull the unrelated dev compiler.
TYPE_ONLY_PEERS = {("bun-ffi-structs", "typescript")}


def read_lock(root):
    # Bun's text lock is JSON with trailing commas, not arbitrary JSON5.
    text = (root / "bun.lock").read_text(encoding="utf-8")
    lock = json.loads(re.sub(r",\s*([}\]])", r"\1", text))
    if lock["lockfileVersion"] != 1 or set(lock["workspaces"]) != {""}:
        raise ValueError("unsupported upstream Bun lock layout")
    return lock


def components(key):
    fields = key.split("/")
    result = []
    index = 0
    while index < len(fields):
        if fields[index].startswith("@"):
            result.append("/".join(fields[index:index + 2]))
            index += 2
        else:
            result.append(fields[index])
            index += 1
    if any(not part or part in (".", "..") for part in fields):
        raise ValueError("invalid package key: " + key)
    return result


def package_path(root, key):
    destination = root
    for name in components(key):
        destination = destination / "node_modules" / name
    return destination


def resolve(packages, key, name):
    parents = components(key)
    while parents:
        candidate = "/".join(parents + [name])
        if candidate in packages:
            return candidate
        parents.pop()
    if name in packages:
        return name
    raise ValueError(f"missing locked dependency {name} of {key}")


def compatible(record, cpu):
    # This exact optional ARM64 accelerator publishes only musl prebuilds.
    # The unchanged msgpackr loader catches its absence and uses JS decoding.
    if record[0] == "@msgpackr-extract/msgpackr-extract-linux-arm64@3.0.4":
        return False
    for field, value in (("os", "linux"), ("cpu", cpu), ("libc", "glibc")):
        values = record[2].get(field, [])
        if isinstance(values, str):
            values = [values]
        positive = [item for item in values if not item.startswith("!")]
        if "!" + value in values or positive and value not in positive:
            return False
    return True


def references(packages, key):
    metadata = packages[key][2]
    for section in ("dependencies", "optionalDependencies", "peerDependencies"):
        for name in metadata.get(section, {}):
            if section == "peerDependencies" and (
                name in metadata.get("optionalPeers", [])
                or (key, name) in TYPE_ONLY_PEERS
            ):
                continue
            yield resolve(packages, key, name), section == "optionalDependencies"


def graph(root, cpu):
    packages = read_lock(root)["packages"]
    manifest = json.loads((root / "package.json").read_text(encoding="utf-8"))
    roots = set(manifest.get("dependencies", {}))
    roots.update(manifest.get("optionalDependencies", {}))
    roots.update(manifest.get("peerDependencies", {}))
    selected = set()
    pending = sorted(roots)
    while pending:
        key = pending.pop()
        if key in selected:
            continue
        if not compatible(packages[key], cpu):
            if key in manifest.get("optionalDependencies", {}):
                continue
            raise ValueError("incompatible required root: " + key)
        selected.add(key)
        for dependency, optional in references(packages, key):
            if compatible(packages[dependency], cpu):
                pending.append(dependency)
            elif not optional:
                raise ValueError("incompatible required dependency: " + dependency)
    return packages, selected


def unpack(archive, destination, record):
    with open(archive, "rb") as stream:
        digest = base64.b64encode(hashlib.file_digest(stream, "sha512").digest()).decode()
    if "sha512-" + digest != record[-1]:
        raise ValueError("archive integrity differs from Bun lock: " + archive)
    destination.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive) as source:
        members = source.getmembers()
        roots = {PurePosixPath(member.name).parts[0] for member in members}
        if len(roots) != 1:
            raise ValueError("archive lacks unique package root: " + archive)
        for member in members:
            relative = PurePosixPath(member.name)
            if relative.is_absolute() or ".." in relative.parts:
                raise ValueError("unsafe archive member: " + member.name)
            # The x64 archive also carries musl prebuilds.  Do not install
            # incompatible libc.so artifacts into a glibc package.
            if relative.name.endswith(".musl.node"):
                continue
            target = destination.joinpath(*relative.parts[1:])
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                target.parent.mkdir(parents=True, exist_ok=True)
                with source.extractfile(member) as incoming, target.open("wb") as outgoing:
                    shutil.copyfileobj(incoming, outgoing)
                target.chmod(0o755 if member.mode & 0o111 else 0o644)
                os.utime(target, (1, 1))
            else:
                # Audited archives contain no symlinks, hardlinks or devices.
                raise ValueError("unexpected non-file archive member: " + member.name)
    metadata = json.loads((destination / "package.json").read_text(encoding="utf-8"))
    name, version = record[0].rsplit("@", 1)
    if (metadata["name"], metadata["version"]) != (name, version):
        raise ValueError("archive identity differs from Bun lock: " + archive)
    return metadata


def link(target, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.symlink_to(os.path.relpath(target, path.parent))
    os.utime(path, (1, 1), follow_symlinks=False)


def notice_record(root, key, package, record, metadata):
    destination = root / "npm-licenses" / package.relative_to(root)
    files = []
    elfs = []
    for path in sorted(package.rglob("*")):
        if not path.is_file() or "node_modules" in path.relative_to(package).parts:
            continue
        relative = path.relative_to(package)
        with path.open("rb") as stream:
            if stream.read(4) == b"\x7fELF":
                elfs.append(str(relative))
        if path.name == "package.json" or LEGAL_NAME.search(path.name):
            output = destination / relative
            output.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, output)
            output.chmod(0o644)
            os.utime(output, (1, 1))
            files.append(str(relative))
    declared = metadata.get("license")
    name, version = record[0].rsplit("@", 1)
    effective = declared
    evidence = "registry and archive package.json"
    if (name, version) == ("exif-parser", "0.1.12"):
        effective = "MIT"
        evidence = "upstream package/LICENSE.md (registry and package.json omit license)"
    if not effective:
        raise ValueError("unaudited missing license: " + record[0])
    basename = name.rsplit("/", 1)[-1]
    return {
        "key": key, "name": name, "version": version,
        "url": f"https://registry.npmjs.org/{name}/-/{basename}-{version}.tgz",
        "integrity": record[-1], "declaredLicense": declared,
        "license": effective, "licenseEvidence": evidence,
        "noticeDirectory": str(destination.relative_to(root)),
        "noticeFiles": files, "elfFiles": elfs,
    }


def materialize(root, archives, cpu):
    packages, selected = graph(root, cpu)
    if (root / "node_modules").exists() or (root / "npm-licenses").exists():
        raise ValueError("node_modules and npm-licenses must be absent before materialization")
    missing = selected - archives.keys()
    if missing:
        raise ValueError("missing immutable archives: " + ", ".join(sorted(missing)))
    legal = []
    metadata = {}
    for key in sorted(selected, key=lambda item: (len(components(item)), item)):
        package = package_path(root, key)
        metadata[key] = unpack(archives[key], package, packages[key])
        legal.append(notice_record(root, key, package, packages[key], metadata[key]))

    # Upstream's postinstall copies this binary.  Expose the exact selected
    # binary directly instead; never run the npm downloader or lifecycle script.
    ast_grep = package_path(root, f"@ast-grep/cli-linux-{cpu}-gnu") / "ast-grep"
    for executable in ("sg", "ast-grep"):
        target = package_path(root, "@ast-grep/cli") / executable
        if target.exists() or target.is_symlink():
            target.unlink()
        link(ast_grep, target)

    for key in sorted(selected):
        package = package_path(root, key)
        module_dir = package.parent.parent if components(key)[-1].startswith("@") else package.parent
        entries = metadata[key].get("bin", {})
        if isinstance(entries, str):
            entries = {metadata[key]["name"].rsplit("/", 1)[-1]: entries}
        for name, relative in sorted(entries.items()):
            target = package / relative
            if not target.is_file():
                raise ValueError("missing declared executable: " + str(target))
            target.chmod(target.stat().st_mode | 0o111)
            destination = module_dir / ".bin" / name
            if not destination.is_symlink():
                link(target, destination)

    # Normalize directories only after all packages and notices are present.
    for tree in (root / "node_modules", root / "npm-licenses"):
        for directory in sorted((path for path in tree.rglob("*") if path.is_dir()), reverse=True):
            directory.chmod(0o755)
            os.utime(directory, (1, 1))
        tree.chmod(0o755)
        os.utime(tree, (1, 1))
    provenance = {
        "sourceCommit": "6faaed283f33ca5467a7909fa786d1c563fb81ad",
        "cpu": cpu, "os": "linux", "libc": "glibc",
        "lifecycleScripts": "not run",
        "omittedTypeOnlyPeers": ["bun-ffi-structs -> typescript"],
        "omittedNativeArtifacts": [
            "*.musl.node (glibc runtime)",
            "@msgpackr-extract/msgpackr-extract-linux-arm64@3.0.4 "
            "(musl-only optional accelerator; upstream msgpackr JS decoding)",
        ],
        "packages": sorted(legal, key=lambda record: record["key"]),
    }
    manifest = root / "npm-licenses" / "manifest.json"
    manifest.write_text(json.dumps(provenance, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    os.utime(manifest, (1, 1))
    os.utime(manifest.parent, (1, 1))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: python3 oh-my-opencode-slim-npm.py map.json")
    system = os.environ.get("GUIX_SYSTEM")
    if system is None:
        system = {"x86_64": "x86_64-linux", "aarch64": "aarch64-linux"}.get(platform.machine())
    if system not in SYSTEM_CPUS:
        raise SystemExit("unsupported GUIX_SYSTEM: " + str(system))
    with open(sys.argv[1], encoding="utf-8") as stream:
        archive_map = json.load(stream)
    if isinstance(archive_map, list):
        archive_map = dict(archive_map)
    materialize(Path.cwd(), archive_map, SYSTEM_CPUS[system])
