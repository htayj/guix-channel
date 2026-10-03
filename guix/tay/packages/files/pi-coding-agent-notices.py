#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Retain notices from the entire fixed Pi install-lock source closure.

Usage: python pi-coding-agent-notices.py LOCK OUTPUT PATH:TARBALL ...
PATH is an exact packages key from the release install-lock/package-lock.json,
not a package name.  All non-root entries must be supplied, including optional
platform packages.  This program never installs npm packages or runs scripts.
The release lock omits integrity for its seven own 0.84.2 packages; only those
exact archives use pinned registry dist.integrity digests below.  The inventory
distinguishes these supplemental digests from integrity recorded in the lock.

The inventory records SPDX declarations, not substitute copyright notices.
Actual upstream notice bytes, source files containing copyright/SPDX notices,
and package.json are retained.  Without a dedicated license/copying/unlicense
file, the complete original tarball is also retained so no source notice is lost.
"""

import argparse
import base64
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import tarfile
from urllib.parse import urlsplit


ALLOWED_LICENSES = {
    "MIT", "Apache-2.0", "BSD-3-Clause", "ISC", "BlueOak-1.0.0", "0BSD",
}

# The upstream install lock omits these seven digests.  Retrieved from each
# exact https://registry.npmjs.org/@earendil-works/<name>/0.84.2 endpoint's
# dist.integrity on 2026-10-03 and verified against the downloaded source bytes.
# These are registry evidence, not fields claimed to exist in the release lock.
RELEASE_INTEGRITIES = {
    "pi-agent-core": "sha512-8Pn3wSCxj0cfo5I6jxQYVB/3uuQRmHhAlEclyjqpOuMEdQMIODHizRogv56FLdbU+dTiGnybeHQ2N+sV1/L2YA==",
    "pi-ai": "sha512-6MzsrYIYNVlE7SfpbL2yYb67Qo58p/7Q+xWG1RZvoX1P80aRCHSod2/13aFpxkow1lPO2LEh3c495J0Gwmyjig==",
    "pi-client": "sha512-/RFSPhD/bZbpOp1oJj+UneSUFSgZhWxzcSENUY+8+8xhoBrWXMYI2t77XNx4Yf+c8YK2qTHquForhNcelYpXvg==",
    "pi-coding-agent": "sha512-l4E+B7hgXKWddRo8bC/eSue2aWZjEgJ9xIpf5p0Og+lq8a2TArCwJ0HCoCPCgaBP/tN4zbYH/wOwvx9pJpeLCA==",
    "pi-protocol": "sha512-jbBh03fkeckWEroHpcZBr4w5/Ibat8WwdXFlXHivYQImrQNFtLpDeL0t1cku4hmK0q3pceIRQHkw4fwbM4YILQ==",
    "pi-telemetry": "sha512-wg5caea7uIv1BHRBm2Y116RvFG4oSAiP5qk9tA2463PDGIr4K8M1Ceyyg5DOpF/shUUl0gk826yQJAeAcHYB9g==",
    "pi-tui": "sha512-ds2TLihOnM5sLJB3VpXV6y0uR5efVuHf4MN7yDpsty6hA2DUO/EDVzjp/0od0G2JslzVLMjT8T8zavtxVb+qbg==",
}
LEGAL_NAME = re.compile(
    r"(?:^|[._-])(?:licen[cs]es?|copying|copyright|notices?|authors|readme|unlicense)"
    r"(?:$|[._-])", re.I,
)
GRANT_NAME = re.compile(
    r"(?:^|[._-])(?:licen[cs]es?|copying|unlicense)(?:$|[._-])", re.I,
)
INLINE_NOTICE = re.compile(rb"copyright|SPDX-License-Identifier", re.I)


def safe_path(value):
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or not path.parts:
        raise ValueError(f"Unsafe relative path: {value!r}")
    return path


def package_name(location):
    """Use the last node_modules segment, including scoped/nested packages."""
    path = safe_path(location)
    parts = path.parts
    if "node_modules" not in parts:
        raise ValueError(f"Not an npm install-lock package path: {location}")
    start = max(i for i, part in enumerate(parts) if part == "node_modules") + 1
    name = parts[start:]
    if not (len(name) == 1 and not name[0].startswith("@")
            or len(name) == 2 and name[0].startswith("@")):
        raise ValueError(f"Invalid npm package path: {location}")
    return "/".join(name)


def verify_integrity(archive, integrity):
    """Compare source bytes to the release's fixed SHA512 SRI digest."""
    if not isinstance(integrity, str) or not integrity.startswith("sha512-"):
        raise ValueError(f"Expected fixed SHA512 integrity: {archive}")
    expected = base64.b64decode(integrity[7:], validate=True)
    if len(expected) != 64:
        raise ValueError(f"Invalid SHA512 digest: {archive}")
    digest = hashlib.sha512()
    with archive.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    if digest.digest() != expected:
        raise ValueError(f"Source integrity mismatch: {archive}")


def has_inline_notice(source):
    """Scan without loading a large bundled source file into memory."""
    overlap = b""
    for chunk in iter(lambda: source.read(65536), b""):
        text = overlap + chunk
        if INLINE_NOTICE.search(text):
            return True
        overlap = text[-64:]
    return False


def collect_package(location, locked, archive, destination):
    name = package_name(location)
    integrity = locked.get("integrity")
    integrity_source = "release-install-lock"
    if integrity is None:
        unscoped = name.removeprefix("@earendil-works/")
        expected_url = (f"https://registry.npmjs.org/@earendil-works/{unscoped}"
                        f"/-/{unscoped}-0.84.2.tgz")
        if (name != "@earendil-works/" + unscoped
                or unscoped not in RELEASE_INTEGRITIES
                or locked["version"] != "0.84.2"
                or locked["resolved"] != expected_url):
            raise ValueError(f"No pinned supplemental integrity: {location}")
        integrity = RELEASE_INTEGRITIES[unscoped]
        integrity_source = "pinned-registry-dist.integrity (release lock omitted it)"
    verify_integrity(archive, integrity)
    if locked.get("name", name) != name:
        raise ValueError(f"Unexpected package name in lock: {location}")
    with tarfile.open(archive, "r:gz") as source:
        members = source.getmembers()
        paths = [(member, safe_path(member.name)) for member in members]
        candidates = [(member, path) for member, path in paths
                      if member.isfile() and path.name == "package.json"
                      and len(path.parts) <= 2]
        depth = min((len(path.parts) for _, path in candidates), default=0)
        candidates = [(member, path) for member, path in candidates
                      if len(path.parts) == depth]
        if len(candidates) != 1:
            raise ValueError(f"Expected one root package.json: {location}")
        metadata_member, metadata_path = candidates[0]
        package_root = metadata_path.parent
        with source.extractfile(metadata_member) as stream:
            metadata = json.load(stream)
        if (metadata.get("name"), metadata.get("version")) != (name, locked["version"]):
            raise ValueError(f"Package identity differs from lock: {location}")
        license_expression = metadata.get("license")
        if isinstance(license_expression, dict):
            license_expression = license_expression.get("type")
        if license_expression != locked["license"]:
            raise ValueError(f"Package license differs from lock: {location}: "
                             f"{license_expression!r} != {locked['license']!r}")

        target = destination / "packages" / location
        notice_files = []
        dedicated_grant = False
        regular_members = {}
        for member, path in paths:
            if member.isfile():
                regular_members.setdefault(path, []).append(member)
        duplicate_members = []
        identical_duplicates = set()
        for path, occurrences in regular_members.items():
            if len(occurrences) < 2:
                continue
            digests = []
            for occurrence in occurrences:
                with source.extractfile(occurrence) as stream:
                    digest = hashlib.sha256()
                    for chunk in iter(lambda: stream.read(65536), b""):
                        digest.update(chunk)
                    digests.append(digest.digest())
            identical = len(set(digests)) == 1
            if identical:
                identical_duplicates.add(path)
            duplicate_members.append({
                "path": str(path.relative_to(package_root)),
                "archive_members": [entry.name for entry in occurrences],
                "identical_bytes": identical,
            })
        for member_index, (member, path) in enumerate(paths):
            if not member.isfile():
                # Never follow symlinks or invoke tar extraction on host paths.
                continue
            if not path.is_relative_to(package_root):
                raise ValueError(f"Archive member outside package root: {member.name}")
            relative = path.relative_to(package_root)
            # Tar archives may spell the same path with and without ./.
            # Last member wins for the ordinary file tree.  Identical earlier
            # entries add no notice bytes; differing earlier legal versions
            # remain separately available instead of being overwritten.
            latest = regular_members[path][-1] is member
            if not latest and path in identical_duplicates:
                continue
            dedicated_grant |= bool(GRANT_NAME.search(relative.name))
            retain = (relative == PurePosixPath("package.json")
                      or any(LEGAL_NAME.search(part) for part in relative.parts))
            if not retain:
                with source.extractfile(member) as stream:
                    retain = has_inline_notice(stream)
            if retain:
                if latest:
                    output = target / "files" / str(relative)
                else:
                    output = target / "archive-members" / str(member_index) / str(relative)
                output.parent.mkdir(parents=True, exist_ok=True)
                with source.extractfile(member) as stream, output.open("wb") as writer:
                    shutil.copyfileobj(stream, writer)
                notice_files.append(str(output.relative_to(destination)))

    source_archive = None
    remark = "Upstream notice and copyright-bearing files retained verbatim."
    if not dedicated_grant:
        target.mkdir(parents=True, exist_ok=True)
        preserved = target / "source-tarball.tgz"
        shutil.copyfile(archive, preserved)
        source_archive = str(preserved.relative_to(destination))
        remark = ("No dedicated LICENSE/COPYING/UNLICENSE file was present. "
                  "The entire integrity-verified upstream source tarball is retained "
                  "to preserve all source notices. The SPDX declaration is metadata, "
                  "not a replacement copyright notice or license text.")
    return {
        "lock_path": location,
        "name": name,
        "version": locked["version"],
        "spdx_license": locked["license"],
        "integrity": integrity,
        "lock_integrity": locked.get("integrity"),
        "integrity_source": integrity_source,
        "source_url": locked["resolved"],
        "notice_files": sorted(notice_files),
        "source_archive": source_archive,
        "duplicate_members": duplicate_members,
        "remark": remark,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("lock", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("sources", nargs="+", metavar="PATH:TARBALL")
    args = parser.parse_args()
    with args.lock.open(encoding="utf-8") as stream:
        lock = json.load(stream)
    if lock.get("lockfileVersion") != 3:
        raise ValueError("Expected the release's version-3 npm install lock")
    locked = {path: entry for path, entry in lock["packages"].items() if path}
    for location, entry in locked.items():
        package_name(location)
        uri = urlsplit(entry.get("resolved", ""))
        if uri.scheme != "https" or uri.netloc != "registry.npmjs.org":
            raise ValueError(f"Expected fixed npm registry archive: {location}")
        if entry.get("license") not in ALLOWED_LICENSES:
            raise ValueError(f"Unreviewed license declaration: {location}")
    archives = {}
    for specification in args.sources:
        location, separator, tarball = specification.partition(":")
        if not separator or not tarball or location in archives:
            raise ValueError(f"Invalid or duplicate source argument: {specification!r}")
        archives[location] = Path(tarball)
    if archives.keys() != locked.keys():
        missing = sorted(locked.keys() - archives.keys())
        extra = sorted(archives.keys() - locked.keys())
        raise ValueError(f"Source coverage differs from lock; missing={missing}; extra={extra}")
    args.output.mkdir(parents=True, exist_ok=False)
    inventory = [collect_package(location, locked[location], archives[location], args.output)
                 for location in sorted(locked)]
    (args.output / "inventory.json").write_text(
        json.dumps({
            "lock_name": lock.get("name"),
            "lock_version": lock.get("version"),
            "package_count": len(inventory),
            "notice_policy": (
                "Every non-root install-lock entry is represented, including optional "
                "platform packages. SPDX declarations are not substitute license texts. "
                "Source archive integrity was verified against the release lock or "
                "explicitly pinned registry metadata where the lock omitted it. "
                "Package identity and license declarations match the release lock; "
                "no installation/scripts occurred."
            ),
            "packages": inventory,
        }, indent=2, ensure_ascii=False) + "\n", encoding="utf-8",
    )


if __name__ == "__main__":
    main()
