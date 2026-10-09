#!/usr/bin/env python3
"""Canonicalize metadata and ordering without changing web-ext entry payloads."""

import os
import sys
import time
import zipfile


def canonicalize(source, destination):
    epoch = int(os.environ["SOURCE_DATE_EPOCH"])
    # ZIP's DOS timestamp range is 1980 through 2107, with two-second precision.
    epoch = min(max(epoch, 315532800), 4354819198)
    timestamp = time.gmtime(epoch)[:6]
    timestamp = timestamp[:5] + (timestamp[5] & ~1,)
    with zipfile.ZipFile(source) as original:
        entries = sorted(original.infolist(), key=lambda entry: entry.filename)
        with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED,
                             compresslevel=9) as normalized:
            for entry in entries:
                metadata = zipfile.ZipInfo(entry.filename, timestamp)
                metadata.create_system = 3
                metadata.compress_type = zipfile.ZIP_DEFLATED
                metadata.external_attr = ((0o40755 if entry.is_dir() else 0o100644) << 16)
                if entry.is_dir():
                    metadata.external_attr |= 0x10
                normalized.writestr(metadata, original.read(entry), compresslevel=9)
        # Assert every source-built entry (including directories and empty icons)
        # survived byte-for-byte; only archive encoding was changed.
        with zipfile.ZipFile(destination) as normalized:
            actual = normalized.infolist()
            if [entry.filename for entry in entries] != [entry.filename for entry in actual]:
                raise ValueError("Canonicalization changed web-ext entry names")
            for source_entry, target_entry in zip(entries, actual):
                if original.read(source_entry) != normalized.read(target_entry):
                    raise ValueError("Canonicalization changed entry: " + source_entry.filename)


if __name__ == "__main__":
    canonicalize(*sys.argv[1:])
