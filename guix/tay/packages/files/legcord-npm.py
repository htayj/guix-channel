#!/usr/bin/env python3
"""Materialize the pinned pnpm snapshot graph without a package-manager store.

No lifecycle scripts, network requests, or mutable version resolution are used.
Peer-qualified snapshots get distinct node_modules instances, as with pnpm.
The manifest maps exact lock package keys to Guix fixed-output archives.
"""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tarfile

import yaml


LEGAL_NAME = re.compile(
    r"(?:licen[cs]e|copying|copyright|notice|authors|ofl|readme|package\.json)",
    re.IGNORECASE,
)


def compatible(metadata):
    for field, platform in (("os", "linux"), ("cpu", "x64"), ("libc", "glibc")):
        values = metadata.get(field, [])
        positive = [value for value in values if not value.startswith("!")]
        if "!" + platform in values or (positive and platform not in positive):
            return False
    return True


def package_key(snapshot):
    return snapshot.split("(", 1)[0]


def instance_id(snapshot):
    # Peer-qualified identifiers can exceed filesystem component limits.
    return hashlib.sha256(snapshot.encode()).hexdigest()


def package_name(key, metadata):
    return metadata.get("name") or key.rsplit("@", 1)[0]


def graph(root):
    with (root / "pnpm-lock.yaml").open() as stream:
        lock = yaml.safe_load(stream)
    if str(lock["lockfileVersion"]) != "9.0" or set(lock["importers"]) != {"."}:
        raise ValueError("unsupported Legcord lockfile layout")
    packages = lock["packages"]
    snapshots = {
        key: value for key, value in lock["snapshots"].items()
        if compatible(packages[package_key(key)])
    }
    return lock, packages, snapshots


def references(record, sections):
    for section in sections:
        for name, version in record.get(section, {}).items():
            if isinstance(version, dict):
                version = version["version"]
            yield name, name + "@" + version, section == "optionalDependencies"


def link(target, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.symlink_to(os.path.relpath(target, path.parent))


def unpack(archive, destination):
    destination.mkdir(parents=True)
    with tarfile.open(archive) as stream:
        members = stream.getmembers()
        roots = {member.name.split("/", 1)[0] for member in members}
        if len(roots) != 1:
            raise ValueError("archive does not have a unique package root: " + archive)
        prefix = roots.pop()
        stream.extractall(destination, filter="data")
    extracted = destination / prefix
    if not (extracted / "package.json").is_file():
        raise ValueError("archive lacks root package.json: " + archive)
    return extracted


def bins(package):
    with (package / "package.json").open() as stream:
        metadata = json.load(stream)
    entries = metadata.get("bin", {})
    if isinstance(entries, str):
        entries = {metadata["name"].rsplit("/", 1)[-1]: entries}
    for name, relative in entries.items():
        target = package / relative
        if not target.is_file():
            raise ValueError("missing executable " + str(target))
        target.chmod(target.stat().st_mode | 0o111)
        yield name, target


def add_bins(module_dir, dependencies):
    bindir = module_dir / ".bin"
    for dependency in dependencies:
        for name, target in bins(dependency):
            destination = bindir / name
            if not destination.is_symlink():
                link(target, destination)


def prepare(root, manifest):
    lock, packages, snapshots = graph(root)
    module_dir = root / "node_modules"
    if module_dir.exists():
        raise ValueError("node_modules must be absent before prepare")
    module_dir.mkdir()
    instance_root = module_dir / ".pnpm"
    locations = {}
    for snapshot in sorted(snapshots):
        key = package_key(snapshot)
        name = package_name(key, packages[key])
        instance = instance_root / instance_id(snapshot) / "node_modules"
        package = instance / name
        extracted = unpack(manifest[key], instance / ".unpack")
        package.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(extracted, package)
        (instance / ".unpack").rmdir()
        locations[snapshot] = package

    # Wire every snapshot edge, not just unique name/version records.  This
    # preserves peer contexts, aliases and independently locked nested versions.
    for snapshot, record in snapshots.items():
        dependencies = []
        instance = locations[snapshot]
        for _ in package_name(package_key(snapshot), packages[package_key(snapshot)]).split("/"):
            instance = instance.parent
        for name, dependency, optional in references(
            record, ("dependencies", "optionalDependencies")
        ):
            if dependency not in locations:
                if optional:
                    continue
                raise ValueError("missing required snapshot: " + dependency)
            target = locations[dependency]
            destination = instance / name
            # A self dependency already occupies this path.
            if destination != target:
                link(target, destination)
            dependencies.append(target)
        add_bins(instance, dependencies)

    dependencies = []
    for name, dependency, optional in references(
        lock["importers"]["."],
        ("dependencies", "devDependencies", "optionalDependencies"),
    ):
        if dependency not in locations:
            if optional:
                continue
            raise ValueError("missing importer snapshot: " + dependency)
        target = locations[dependency]
        link(target, module_dir / name)
        dependencies.append(target)
    add_bins(module_dir, dependencies)


def runtime(root, destination):
    lock, packages, snapshots = graph(root)
    with (root / "package.json").open() as stream:
        current = json.load(stream)
    importer = {
        section: {
            name: record for name, record in lock["importers"]["."].get(section, {}).items()
            if name in current.get(section, {})
        }
        for section in ("dependencies", "optionalDependencies")
    }
    selected = set()
    pending = []
    top = []
    for name, dependency, optional in references(
        importer, ("dependencies", "optionalDependencies")
    ):
        if dependency not in snapshots:
            if optional:
                continue
            raise ValueError("missing runtime importer snapshot: " + dependency)
        top.append((name, dependency))
        pending.append(dependency)
    while pending:
        snapshot = pending.pop()
        if snapshot in selected:
            continue
        selected.add(snapshot)
        for _, dependency, optional in references(
            snapshots[snapshot], ("dependencies", "optionalDependencies")
        ):
            if dependency not in snapshots:
                if optional:
                    continue
                raise ValueError("missing runtime snapshot: " + dependency)
            pending.append(dependency)
    modules = destination / "node_modules"
    if modules.exists():
        raise ValueError("runtime node_modules must be absent")
    (modules / ".pnpm").mkdir(parents=True)
    for snapshot in sorted(selected):
        identifier = instance_id(snapshot)
        shutil.copytree(
            root / "node_modules" / ".pnpm" / identifier,
            modules / ".pnpm" / identifier,
            symlinks=True,
        )
        if package_key(snapshot) == "@vencord/venmic@7.1.0":
            # The app uses its source-built addon in dist/, never npm prebuilds.
            prebuilds = (modules / ".pnpm" / identifier / "node_modules"
                         / "@vencord" / "venmic" / "prebuilds")
            shutil.rmtree(prebuilds)
        if package_key(snapshot) == "koffi@2.16.3":
            # arrpc imports koffi only through native/win32.js; the Linux
            # branch reads /proc using fs/promises.  Keep JS/source/notices,
            # but do not install unused cross-platform native prebuilds.
            build = (modules / ".pnpm" / identifier / "node_modules"
                     / "koffi" / "build")
            shutil.rmtree(build)
    for name, snapshot in top:
        key = package_key(snapshot)
        target = (modules / ".pnpm" / instance_id(snapshot) / "node_modules"
                  / package_name(key, packages[key]))
        link(target, modules / name)


def notices(root, destination, manifest):
    destination.mkdir(parents=True, exist_ok=True)
    archive_dir = destination / "npm-sources"
    archive_dir.mkdir()
    index = []
    for key, archive in sorted(manifest.items()):
        if key.startswith("reference:"):
            continue
        if key.startswith("notice:"):
            package, name = key[len("notice:"):].rsplit(":", 1)
            directory = destination / "npm-notices" / instance_id(package)
            directory.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(archive, directory / ("UPSTREAM-" + name))
            index.append({"package": package, "supplement": name})
            continue
        identifier = instance_id(key)
        shutil.copyfile(archive, archive_dir / (identifier + ".tgz"))
        directory = destination / "npm-notices" / identifier
        directory.mkdir(parents=True)
        with tarfile.open(archive) as stream:
            members = stream.getmembers()
            prefix = members[0].name.split("/", 1)[0]
            metadata = None
            for member in members:
                if member.name == prefix + "/package.json":
                    metadata = json.load(stream.extractfile(member))
                if member.isfile() and LEGAL_NAME.search(Path(member.name).name):
                    relative = Path(member.name).relative_to(prefix)
                    if ".." in relative.parts:
                        raise ValueError("unsafe notice member")
                    target = directory / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with stream.extractfile(member) as source, target.open("wb") as output:
                        shutil.copyfileobj(source, output)
            if metadata is None:
                raise ValueError("missing archive manifest: " + key)
            index.append({"package": key, "source": "npm-sources/" + identifier + ".tgz",
                          "notices": "npm-notices/" + identifier,
                          "declaredLicense": metadata.get("license", metadata.get("licenses"))})
            # These versions declare SPDX licenses but omit standalone terms.
            # Preserve their metadata/attribution, and supply standard terms as
            # a reference, not an invented upstream copyright notice or grant.
            incomplete = {
                "chromium-pickle-js@0.2.0", "keyv@4.5.4", "lazy-val@1.0.5",
                "temp-file@3.4.0", "@tybys/wasm-util@0.10.3",
                "@electron-internal/extract-zip@1.0.4", "cross-dirname@0.1.0",
                "err-code@2.0.3", "node-api-version@0.2.1",
                "read-binary-file-arch@1.0.6", "rollup-plugin-copy@3.5.0",
                "tmp-promise@3.0.3", "compare-version@0.1.2",
                "dmg-builder@26.15.3", "dmg-builder@26.15.7",
            }
            if key in incomplete:
                license_id = metadata["license"]
                shutil.copyfile(manifest["reference:" + license_id],
                                directory / ("REFERENCE-" + license_id))
                (directory / "REFERENCE-NOTICE").write_text(
                    "This version declares " + license_id + " in package.json.\n"
                    "No standalone full license text was supplied in its archive.\n"
                    "Standard SPDX terms are supplied separately for reference,\n"
                    "not as a newly discovered upstream notice or new grant.\n"
                    "The original package.json, README and entire archive are\n"
                    "preserved; no copyright holder has been invented.\n"
                )
    (destination / "npm-sources.json").write_text(json.dumps(index, indent=2) + "\n")
    # Monaco's archive includes codicon.ttf, but does not supply its upstream
    # font license.  Keep that evidence separate from the package's MIT notice.
    with tarfile.open(manifest["codicons-license"]) as stream:
        with stream.extractfile("package/LICENSE") as source:
            (destination / "Codicons-LICENSE").write_bytes(source.read())
    (destination / "Codicons-NOTICE").write_text(
        "Codicons font: Copyright Microsoft Corporation.\n"
        "Project: https://github.com/microsoft/vscode-codicons\n"
        "License: Creative Commons Attribution 4.0 International (CC-BY-4.0).\n"
        "Bundled unmodified in monaco-editor@0.56.0 as codicon.ttf.\n"
        "Byte-identical to @vscode/codicons@0.0.46-21 dist/codicon.ttf.\n"
        "Font SHA-256: cc2472e239e17062e7760af87f8f5997720cc0d94aa014a615c418baaf6333a8.\n"
        "Monaco vscodeCommitId: f487add297079a02eb836810185b165e50cadabc.\n"
        "Its font-specific license was omitted from the Monaco archive; the\n"
        "actual matching Codicons archive and license are supplied separately.\n"
    )


def main():
    command = sys.argv[1]
    root = Path(sys.argv[2]).resolve()
    if command == "runtime":
        runtime(root, Path(sys.argv[3]).resolve())
    elif command in ("prepare", "notices"):
        manifest_path = Path(sys.argv[-1])
        with manifest_path.open() as stream:
            manifest = json.load(stream)
        if command == "prepare":
            prepare(root, manifest)
        else:
            notices(root, Path(sys.argv[3]).resolve(), manifest)
    else:
        raise ValueError("expected prepare ROOT MANIFEST, runtime ROOT DEST, "
                         "or notices ROOT DOC MANIFEST")


if __name__ == "__main__":
    main()
