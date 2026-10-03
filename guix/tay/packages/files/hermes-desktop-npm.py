#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Prepare the locked desktop install and retain npm redistribution notices."""

import argparse
import base64
import gzip
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import tarfile

LEGAL_NAME = re.compile(
    r"(?:^|[._-])(?:licen[cs]es?|copying|copyright|notices?|authors|readme|ofl|unlicense)(?:$|[._-])",
    re.I,
)


def read_lock(root):
    return json.loads((root / "package-lock.json").read_text(encoding="utf-8"))


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8")


def normalize_ui_archive(root, archive):
    """Expose Guix's sanitized zstd tar as the same gzip bytes npm will cache."""
    destination = root / "npm-inputs/nous-ui-0.18.2.tgz"
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("wb") as output:
        with gzip.GzipFile(filename="", mode="wb", fileobj=output, mtime=0) as compressed:
            with subprocess.Popen(["zstd", "--decompress", "--stdout", str(archive)],
                                  stdout=subprocess.PIPE) as decompressor:
                shutil.copyfileobj(decompressor.stdout, compressed)
                if decompressor.wait() != 0:
                    raise ValueError("Cannot decompress sanitized UI archive")
    return destination


def scope_workspaces(root, packages):
    """Keep desktop/shared manifests and their existing locked resolutions."""
    selected = ["apps/desktop", "apps/shared"]
    # The onboarding connector card imports Lucide, but upstream declares it
    # only in unrelated workspaces.  Keep that feature with the existing exact
    # root-lock pin rather than relying on their hoisted install.
    desktop_manifest_path = root / "apps/desktop/package.json"
    desktop_manifest = json.loads(desktop_manifest_path.read_text(encoding="utf-8"))
    desktop_dependencies = {
        "lucide-react": packages["node_modules/lucide-react"]["version"],
    }
    desktop_manifest["dependencies"].update(desktop_dependencies)
    packages["apps/desktop"]["dependencies"].update(desktop_dependencies)
    write_json(desktop_manifest_path, desktop_manifest)

    # tests-js is used by upstream development/test scripts, not declared as a
    # dependency of either production workspace.  Do not install it or web/TUI.
    excluded = [location for location in packages
                if location and "node_modules" not in PurePosixPath(location).parts
                and location not in selected]
    for location, package in list(packages.items()):
        if (location in excluded
                or any(location.startswith(workspace + "/") for workspace in excluded)
                or package.get("link") and package.get("resolved") not in selected):
            del packages[location]
    manifest_path = root / "package.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["workspaces"] = selected
    packages[""]["workspaces"] = selected
    write_json(manifest_path, manifest)


def remove_unused_gsap(packages):
    """Omit the unused optional UI peer without hiding required dependencies."""
    for location, package in packages.items():
        for field in ("dependencies", "devDependencies", "optionalDependencies"):
            if "gsap" in package.get(field, {}):
                raise ValueError(f"Cannot remove GSAP dependency: {location}")
        peers = package.get("peerDependencies", {})
        if "gsap" in peers:
            if not package.get("peerDependenciesMeta", {}).get("gsap", {}).get("optional"):
                raise ValueError(f"Cannot remove required GSAP peer: {location}")
            del peers["gsap"]
            del package["peerDependenciesMeta"]["gsap"]
    for location in list(packages):
        if location.rsplit("node_modules/", 1)[-1] == "gsap":
            del packages[location]


def prepare(root, ui_archive):
    """Scope the offline desktop install and retain all input notice metadata."""
    lock = read_lock(root)
    packages = lock["packages"]
    # Upstream pins LightningCSS 1.33.0 below Vite but omits its optional
    # platform package records.  Keep both the root 1.32.0 and Vite's 1.33.0
    # bindings instead of substituting an incompatible binary version.
    parent = packages["node_modules/vite/node_modules/lightningcss"]
    if parent["optionalDependencies"]["lightningcss-linux-x64-gnu"] != "1.33.0":
        raise ValueError("Unexpected Vite LightningCSS optional version")
    packages["node_modules/vite/node_modules/lightningcss-linux-x64-gnu"] = {
        "version": "1.33.0",
        "resolved": "https://registry.npmjs.org/lightningcss-linux-x64-gnu/-/lightningcss-linux-x64-gnu-1.33.0.tgz",
        "integrity": "sha512-ar+Ju7LmcN0Jo4FpL4hpFybwNG9/3A/Br5KW2n2jyODg3MEZXaDYADdemoNS+BDNfMgKvylJLj4S5tyRActuAg==",
        "license": "MPL-2.0",
        "optional": True,
        "os": ["linux"],
        "cpu": ["x64"],
        "engines": {"node": ">= 12.0.0"},
    }
    # Guix repacks snippet origins with zstd, whereas npm requires gzip.  The
    # recipe uses this exact normalized archive for both cache seeding and
    # notices; its digest below therefore describes the actual cached bytes.
    ui_archive = normalize_ui_archive(root, ui_archive)
    with tarfile.open(ui_archive, "r:gz") as source:
        metadata = json.load(source.extractfile("package/package.json"))
        if (metadata["name"], metadata["version"]) != ("@nous-research/ui", "0.18.2"):
            raise ValueError("Unexpected sanitized UI archive identity")
        if any(PurePosixPath(member.name).suffix.lower() in
               {".ttf", ".otf", ".woff", ".woff2", ".eot"}
               for member in source):
            raise ValueError("Sanitized UI archive still contains bundled fonts")
    with ui_archive.open("rb") as stream:
        integrity = "sha512-" + base64.b64encode(
            hashlib.file_digest(stream, "sha512").digest()
        ).decode("ascii")
    for location, package in packages.items():
        if location.rsplit("node_modules/", 1)[-1] == "@nous-research/ui":
            if package["version"] != "0.18.2":
                raise ValueError("Unexpected locked UI version")
            package["integrity"] = integrity
    # Notice inputs cover all registry origins, even excluded workspaces.  Save
    # their full metadata before scoping the install, with the repaired native
    # record and the normalized UI integrity already applied.
    write_json(root / "npm-inputs/registry-lock.json", {
        "packages": {location: package for location, package in packages.items()
                     if package.get("resolved", "").startswith("https://registry.npmjs.org/")}
    })
    scope_workspaces(root, packages)
    remove_unused_gsap(packages)
    write_json(root / "package-lock.json", lock)


def notices(root, destination, archives):
    """Copy legal files unchanged from archives, including unused build inputs."""
    locked = {}
    registry = json.loads((root / "npm-inputs/registry-lock.json").read_text(encoding="utf-8"))
    for location, package in registry["packages"].items():
        if package.get("resolved", "").startswith("https://registry.npmjs.org/"):
            name = package.get("name", location.rsplit("node_modules/", 1)[-1])
            locked[(name, package["version"])] = package
    destination.mkdir(parents=True, exist_ok=True)
    manifest = []
    seen = set()
    for archive in archives:
        with tarfile.open(archive, "r:gz") as source:
            # npm archives normally use package/, but DefinitelyTyped and
            # older publishers use named top-level directories (including
            # spaces).  Inspect only root-level manifests, never a bundled
            # dependency's package.json; PurePosixPath also normalizes ./.
            members = source.getmembers()
            candidates = []
            for member in members:
                relative = PurePosixPath(member.name)
                if relative.is_absolute() or ".." in relative.parts:
                    raise ValueError(f"Unsafe archive member: {member.name}")
                if (member.isfile() and relative.name == "package.json"
                        and len(relative.parts) <= 2):
                    candidates.append(member)
            depth = min((len(PurePosixPath(member.name).parts)
                         for member in candidates), default=0)
            candidates = [member for member in candidates
                          if len(PurePosixPath(member.name).parts) == depth]
            if len(candidates) != 1:
                raise ValueError(f"Expected one root package.json: {archive}")
            package_root = PurePosixPath(candidates[0].name).parent
            metadata = json.load(source.extractfile(candidates[0]))
            name, version = metadata["name"], metadata["version"]
            identity = (name, version)
            if identity in seen:
                raise ValueError(f"Duplicate archive: {name}@{version}")
            seen.add(identity)
            package = locked[identity]
            license_expression = package.get("license")
            if identity == ("khroma", "2.1.0"):
                # package/license carries the actual MIT grant; package.json and
                # the upstream lock omit their machine-readable license field.
                license_expression = "MIT"
            if not license_expression or name == "gsap":
                raise ValueError(f"No redistributable license: {name}@{version}")
            target = destination / f"{name}@{version}"
            copied = []
            for member in members:
                relative = PurePosixPath(member.name)
                if not member.isfile() or not relative.is_relative_to(package_root):
                    continue
                relative = relative.relative_to(package_root)
                if relative.name == "package.json" or LEGAL_NAME.search(relative.name):
                    output = target.joinpath(*relative.parts)
                    output.parent.mkdir(parents=True, exist_ok=True)
                    output.write_bytes(source.extractfile(member).read())
                    copied.append(str(relative))
            manifest.append({
                "name": name,
                "version": version,
                "license": license_expression,
                "uri": package["resolved"],
                "integrity": package["integrity"],
                "notice_files": sorted(copied),
            })
    (destination / "npm-licenses.json").write_text(
        json.dumps(sorted(manifest, key=lambda entry: (entry["name"], entry["version"])),
                   indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_subparsers(dest="action", required=True)
    preparation = actions.add_parser("prepare")
    preparation.add_argument("root", type=Path)
    preparation.add_argument("ui_archive", type=Path)
    retention = actions.add_parser("notices")
    retention.add_argument("root", type=Path)
    retention.add_argument("destination", type=Path)
    retention.add_argument("archives", type=Path, nargs="+")
    args = parser.parse_args()
    if args.action == "prepare":
        prepare(args.root, args.ui_archive)
    else:
        notices(args.root, args.destination, args.archives)


if __name__ == "__main__":
    main()
