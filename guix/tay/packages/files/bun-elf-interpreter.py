#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Change the pinned Bun ELF interpreter without relocating any load segment.

Usage: python3 bun-elf-interpreter.py PROGRAM LOADER
The inspected x86-64-baseline and aarch64 archives reserve bytes 0x238..0x298
for .interp, alignment padding, and optional GNU ABI/build-id notes.  Reuse
only that interval.  Drop those notes, retaining every other byte and every
PT_LOAD/PT_PHDR field.  Reject other layouts rather than falling back to
patchelf.  No RUNPATH is added: the caller must supply the library search path
and perform the actual loader --verify/runtime checks separately.
"""

import mmap
from pathlib import Path
import struct
import sys

ELF_HEADER = struct.Struct("<16sHHIQQQIHHHHHH")
PROGRAM_HEADER = struct.Struct("<IIQQQQQQ")
SECTION_HEADER = struct.Struct("<IIQQQQIIQQ")
DYNAMIC = struct.Struct("<qQ")
PT_LOAD, PT_DYNAMIC, PT_INTERP, PT_NOTE = 1, 2, 3, 4
SHT_NULL, SHT_PROGBITS, SHT_STRTAB, SHT_NOTE, SHT_NOBITS = 0, 1, 3, 7, 8
SHF_ALLOC, SHF_INFO_LINK = 2, 0x40
ARCHITECTURES = {
    62: ("ld-linux-x86-64.so.2", b"/lib64/ld-linux-x86-64.so.2\0"),
    183: ("ld-linux-aarch64.so.1", b"/lib/ld-linux-aarch64.so.1\0"),
}


def require(condition, message):
    if not condition:
        raise ValueError("unsupported Bun ELF layout: " + message)


def bounded(data, offset, size, label):
    require(0 <= offset <= len(data) and 0 <= size <= len(data) - offset,
            label + " is outside the file")
    return offset + size


def overlaps(start, end, offset, size):
    return size > 0 and start < offset + size and offset < end


def cstring(data, offset, end, label):
    require(offset < end, label + " offset is outside its string table")
    terminator = data.find(b"\0", offset, end)
    require(terminator != -1, label + " is not NUL-terminated")
    return data[offset:terminator]


def needed_libraries(data, programs, loader):
    dynamic = [p for p in programs if p[0] == PT_DYNAMIC]
    require(len(dynamic) == 1, "expected one PT_DYNAMIC")
    segment = dynamic[0]
    require(segment[5] % DYNAMIC.size == 0, "partial dynamic entry")
    entries = []
    for offset in range(segment[2], segment[2] + segment[5], DYNAMIC.size):
        tag, value = DYNAMIC.unpack_from(data, offset)
        if tag == 0:
            break
        entries.append((tag, value))
    else:
        require(False, "missing DT_NULL")
    addresses = [value for tag, value in entries if tag == 5]
    sizes = [value for tag, value in entries if tag == 10]
    require(len(addresses) == len(sizes) == 1, "ambiguous DT_STRTAB/DT_STRSZ")
    address, size = addresses[0], sizes[0]
    mappings = [p[2] + address - p[3] for p in programs if p[0] == PT_LOAD
                and p[3] <= address and address + size <= p[3] + p[5]]
    require(len(mappings) == 1 and size > 0, "dynamic strings are not file-backed")
    start = mappings[0]
    end = bounded(data, start, size, "dynamic strings")
    names = []
    for tag, value in entries:
        if tag == 1:
            require(value < size, "DT_NEEDED offset exceeds DT_STRSZ")
            names.append(cstring(data, start + value, end, "DT_NEEDED").decode("ascii"))
    expected = {"libc.so.6", loader.name, "libpthread.so.0", "libdl.so.2", "libm.so.6"}
    require(len(names) == len(expected) and set(names) == expected,
            "unexpected DT_NEEDED closure: " + repr(names))
    for name in names:
        require((loader.parent / name).is_file(),
                "missing loader-directory dependency " + str(loader.parent / name))
    return names


def plan_rewrite(data, loader):
    bounded(data, 0, ELF_HEADER.size, "ELF header")
    header = ELF_HEADER.unpack_from(data)
    ident, elf_type, machine, version = header[:4]
    require(ident[:7] == b"\x7fELF\x02\x01\x01", "expected ELF64 little-endian version 1")
    require(elf_type in (2, 3) and version == 1, "expected ET_EXEC or ET_DYN version 1")
    require(machine in ARCHITECTURES, "expected x86-64 or aarch64")
    expected_loader, original_interpreter = ARCHITECTURES[machine]
    require(loader.is_absolute() and loader.name == expected_loader and loader.is_file(),
            "loader must be an existing absolute " + expected_loader + " path")
    replacement = str(loader).encode("utf-8") + b"\0"
    require(b"\0" not in replacement[:-1], "loader path contains NUL")
    phoff, shoff = header[5:7]
    ehsize, phentsize, phnum, shentsize, shnum, shstrndx = header[8:]
    require(ehsize == 64 and phentsize == 56 and shentsize == 64,
            "unexpected ELF header sizes")
    require(phoff == 64 and phnum == 9 and shnum == 37 and 0 < shstrndx < shnum,
            "unexpected pinned header tables (extended counts are unsupported)")
    phend = bounded(data, phoff, phnum * phentsize, "program headers")
    shend = bounded(data, shoff, shnum * shentsize, "section headers")
    programs = [PROGRAM_HEADER.unpack_from(data, phoff + i * phentsize)
                for i in range(phnum)]
    sections = [SECTION_HEADER.unpack_from(data, shoff + i * shentsize)
                for i in range(shnum)]
    for p in programs:
        bounded(data, p[2], p[5], "program segment")
        if p[0] == PT_LOAD:
            require(p[5] <= p[6], "PT_LOAD file size exceeds memory size")
    for s in sections:
        if s[1] not in (SHT_NULL, SHT_NOBITS):
            bounded(data, s[4], s[5], "section")
    strings = sections[shstrndx]
    require(strings[1] == SHT_STRTAB, "section names are not a string table")
    string_end = bounded(data, strings[4], strings[5], "section names")
    names = [cstring(data, strings[4] + s[0], string_end, "section name")
             for s in sections]
    interps = [i for i, p in enumerate(programs) if p[0] == PT_INTERP]
    require(len(interps) == 1, "expected one PT_INTERP")
    interp_index = interps[0]
    interp = programs[interp_index]
    start = interp[2]
    require(start == phend == 0x238 and interp[5] == interp[6] == len(original_interpreter)
            and data[start:start + interp[5]] == original_interpreter,
            "unexpected original interpreter interval")
    notes = [i for i, p in enumerate(programs)
             if p[0] == PT_NOTE and p[2] == 0x254]
    require(len(notes) == 1, "expected adjacent GNU note segment")
    note_index = notes[0]
    note = programs[note_index]
    end = note[2] + note[5]
    require(note[5] == note[6] == 0x44 and end == 0x298
            and note[3] - note[2] == interp[3] - start
            and note[4] - note[2] == interp[4] - start,
            "unexpected note interval or virtual-address mapping")
    require(not any(data[start + interp[5]:note[2]]), "nonzero alignment padding")
    require(len(replacement) <= end - start,
            f"loader needs {len(replacement)} bytes; only {end - start} bytes are available")
    require(not overlaps(start, end, 0, ehsize)
            and not overlaps(start, end, phoff, phend - phoff)
            and not overlaps(start, end, shoff, shend - shoff), "header table overlaps interpreter")
    loads = [p for p in programs if p[0] == PT_LOAD
             and p[2] <= start and end <= p[2] + p[5]
             and p[3] + start - p[2] == interp[3]]
    require(len(loads) == 1, "interpreter span is not in one unchanged PT_LOAD")
    for i, p in enumerate(programs):
        require(i in (interp_index, note_index) or p[0] == PT_LOAD
                or not overlaps(start, end, p[2], p[5]), "another segment overlaps interpreter")
    interp_sections = [i for i, name in enumerate(names) if name == b".interp"]
    require(len(interp_sections) == 1, "expected one .interp section")
    interp_section = interp_sections[0]
    s = sections[interp_section]
    require(s[1] == SHT_PROGBITS and s[2] == SHF_ALLOC and s[3] == interp[3]
            and s[4] == start and s[5] == interp[5], ".interp disagrees with PT_INTERP")
    removed = []
    cursor = note[2]
    for expected_name, expected_size, expected_type in (
            (b".note.ABI-tag", 32, 1), (b".note.gnu.build-id", 36, 3)):
        indexes = [i for i, name in enumerate(names) if name == expected_name]
        require(len(indexes) == 1, "missing or duplicate " + repr(expected_name))
        i = indexes[0]
        s = sections[i]
        require(s[1] == SHT_NOTE and s[2] == SHF_ALLOC and s[4] == cursor
                and s[5] == expected_size and s[3] == interp[3] + cursor - start,
                "unexpected optional GNU note section")
        namesz, descsz, note_type = struct.unpack_from("<III", data, cursor)
        require(namesz == 4 and descsz == expected_size - 16 and note_type == expected_type
                and data[cursor + 12:cursor + 16] == b"GNU\0", "unexpected GNU note contents")
        removed.append(i)
        cursor += expected_size
    require(cursor == end, "notes do not exactly cover reclaimed interval")
    for i, s in enumerate(sections):
        if i not in (*removed, interp_section) and s[1] not in (SHT_NULL, SHT_NOBITS):
            require(not overlaps(start, end, s[4], s[5]), "another section overlaps interpreter")
        require(s[6] not in removed and not (s[2] & SHF_INFO_LINK and s[7] in removed),
                "another section references a discarded note")
    next_allocated = [(s[4], names[i]) for i, s in enumerate(sections)
                      if s[2] & SHF_ALLOC and s[1] != SHT_NOBITS and s[5] and s[4] >= end]
    require(next_allocated and min(next_allocated) == (end, b".dynsym"),
            "expected .dynsym immediately after reclaimed interval")
    dependencies = needed_libraries(data, programs, loader)
    # Sparse writes keep every unrelated byte, offset, address and permission.
    patches = [(start, replacement.ljust(end - start, b"\0")),
               (phoff + interp_index * phentsize + 32, struct.pack("<QQ", len(replacement), len(replacement))),
               (phoff + note_index * phentsize, struct.pack("<I", 0)),
               (shoff + interp_section * shentsize + 32, struct.pack("<Q", len(replacement)))]
    for i in removed:
        offset = shoff + i * shentsize
        patches.extend([(offset + 4, struct.pack("<I", SHT_NULL)),
                        (offset + 8, struct.pack("<Q", sections[i][2] & ~SHF_ALLOC)),
                        (offset + 32, struct.pack("<Q", 0))])
    expected = list(programs)
    changed = list(interp)
    changed[5:7] = [len(replacement), len(replacement)]
    expected[interp_index] = tuple(changed)
    expected[note_index] = (0, *note[1:])
    return patches, phoff, phentsize, expected, dependencies


def main():
    if len(sys.argv) != 3:
        raise ValueError("usage: bun-elf-interpreter.py PROGRAM LOADER")
    program, loader = map(Path, sys.argv[1:])
    # No mutation occurs until the complete layout and dependency closure pass.
    with program.open("r+b") as stream:
        with mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_WRITE) as data:
            patches, phoff, phentsize, expected, dependencies = plan_rewrite(data, loader)
            for offset, payload in patches:
                data[offset:offset + len(payload)] = payload
            actual = [PROGRAM_HEADER.unpack_from(data, phoff + i * phentsize)
                      for i in range(len(expected))]
            require(actual == expected, "program headers changed beyond INTERP sizes/NOTE type")
            data.flush()
    print("Replaced Bun interpreter in fixed 96-byte span; DT_NEEDED: " + ", ".join(dependencies))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, UnicodeError, struct.error) as error:
        sys.exit("bun-elf-interpreter: " + str(error))
