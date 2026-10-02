#!/usr/bin/env python3
"""Installed ITSTAR proof; only launched inside namespaces by itstar-smoke.sh."""

import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import sys


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def main():
    output, mount, gzip, evidence = map(Path, sys.argv[1:])
    isolation = {}
    for name, proc in (("USER", "user"), ("MOUNT", "mnt"), ("NET", "net"),
                       ("IPC", "ipc"), ("PID", "pid")):
        current = os.readlink("/proc/self/ns/" + proc)
        host = os.environ["HOST_" + name + "_NS"]
        require(current != host, name + " namespace was not isolated")
        isolation[name.lower()] = {"host": host, "runtime": current}
    interfaces = [line.split(":", 1)[0].strip()
                  for line in Path("/proc/net/dev").read_text().splitlines() if ":" in line]
    require(interfaces == ["lo"], "unexpected network interfaces: " + repr(interfaces))
    subprocess.run([str(mount), "--bind", "/gnu/store", "/gnu/store"], check=True)
    subprocess.run([str(mount), "-o", "remount,bind,ro", "/gnu/store"], check=True)
    require(os.statvfs("/gnu/store").f_flag & os.ST_RDONLY, "store mount is writable")
    isolation.update(interfaces=interfaces, store_mount_read_only=True)

    private = evidence / "private"
    private.mkdir()
    environment = {"LC_ALL": "C", "TZ": "UTC0"}
    for variable, directory in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                                ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                                ("XDG_STATE_HOME", "state"), ("TMPDIR", "tmp"),
                                ("PATH", "empty-path")):
        path = private / directory
        path.mkdir()
        environment[variable] = str(path)
    isolation["environment"] = environment
    write_json(evidence / "isolation.json", isolation)
    work = evidence / "work"
    work.mkdir()
    commands = []

    def run(label, argv, cwd=work):
        argv = list(map(str, argv))
        result = subprocess.run(argv, cwd=cwd, env=environment, capture_output=True,
                                timeout=30)
        (evidence / (label + ".stdout")).write_bytes(result.stdout)
        (evidence / (label + ".stderr")).write_bytes(result.stderr)
        commands.append({"label": label, "argv": argv, "cwd": str(cwd),
                         "status": result.returncode})
        write_json(evidence / "commands.json", commands)
        require(result.returncode == 0, label + " failed: " + result.stderr.decode(errors="replace"))
        return result

    cli = output / "bin/itstar"
    doc = output / "share/doc/itstar-1.10-0.b709cd8"
    for name in ("README", "itstar.doc", "COPYING", "Relicensing Permission.txt"):
        require((doc / name).is_file(), "missing installed document: " + name)
    require("GNU GENERAL PUBLIC LICENSE" in (doc / "COPYING").read_text(), "missing GPL text")
    permission = (doc / "Relicensing Permission.txt").read_text()
    require("From: John Wilson <wilson@dbit.com>" in permission and
            "GPL sounds fine" in permission, "missing copyright-holder GPL permission")
    help_result = run("help", [cli, "-h"])
    require(b"GPLv3+" in help_result.stdout + help_result.stderr, "missing GPLv3+ notice")

    def listing(label, tape, entries):
        lines = run(label, [cli, "-t", "-f", tape]).stdout.decode("ascii").splitlines()
        require(lines and re.fullmatch(
            r"Tape 1, reel 0, created \d{2}/\d{2}/\d{2}, type=random", lines[0]),
            "invalid DUMP volume listing: " + repr(lines))
        require(lines[1:] == entries, "wrong ordered ITS file listing: " + repr(lines))

    def extracted(label, tape, expected):
        target = work / label
        target.mkdir()
        run(label, [cli, "-x", "-C", target, "-f", tape])
        members = sorted(str(path.relative_to(target)) for path in target.rglob("*")
                         if path.is_file() or path.is_symlink())
        require(members == sorted(expected), "wrong extracted member set: " + repr(members))
        for name, data in expected.items():
            path = target / name
            require(not path.is_symlink(), "unexpected link: " + name)
            require(path.read_bytes() == data, "extracted bytes differ: " + name)

    # ASCII longer than one 1024-word tape record; quoted 36-bit words have
    # their low bit set so the evacuated format remains canonically binary.
    # Arbitrary host binary is not valid ITS evacuated input.
    text = b"Guix ITS DUMP local fixture\n" * 600 + b"tail\n"
    binary = b"".join(bytes((0xF0 | (n % 16), n % 256, (n * 7) % 256,
                             (n * 11) % 256, ((n * 13) % 256) | 1))
                      for n in range(1100))
    expected = {"src/hello.txt": text, "src/words.bin": binary, "src/empty.txt": b""}
    source = work / "src"
    source.mkdir()
    (source / "hello.txt").write_bytes(text)
    (source / "empty.txt").write_bytes(b"")
    # A real UNIX compress (.Z) stream: fixed-width nine-bit literal LZW
    # codes, little-endian bit packing, no block-mode dictionary resets.
    lzw_text = b"compressed ITS\n"
    lzw_bits = sum(character << (9 * index)
                   for index, character in enumerate(lzw_text))
    (source / "lzw.txt.Z").write_bytes(
        b"\x1f\x9d\x09" + lzw_bits.to_bytes((9 * len(lzw_text) + 7) // 8, "little"))
    expected["src/lzw.txt"] = lzw_text
    # Upstream .Z handling detects the suffix, lets gzip detect the format,
    # expands in place, and deletes .Z.  Keep an oracle outside that directory.
    oracle = work / "words.expected"
    oracle.write_bytes(binary)
    compressed = run("compress-input", [gzip, "-n", "-c", oracle]).stdout
    (source / "words.bin.Z").write_bytes(compressed)
    require(not (source / "words.bin").exists(), "compressed input already expanded")
    tape = work / "created.tap"
    run("create", [cli, "-c", "-f", tape, "src/hello.txt", "src/words.bin.Z",
                   "src/empty.txt", "src/lzw.txt.Z"])
    require((source / "words.bin").read_bytes() == binary, "compressed input expanded incorrectly")
    require(not (source / "words.bin.Z").exists(), "upstream .Z in-place removal did not occur")
    require((source / "lzw.txt").read_bytes() == lzw_text, "UNIX compress input expanded incorrectly")
    require(not (source / "lzw.txt.Z").exists(), "UNIX compress source was not removed")
    entries = ["SRC;HELLO TXT", "SRC;WORDS BIN", "SRC;EMPTY TXT", "SRC;LZW TXT"]
    listing("list-created", tape, entries)
    extracted("extract-created", tape, expected)

    # Append is an existing upstream operation, not a replacement feature.
    extra = b"appended local file\n"
    (source / "extra.txt").write_bytes(extra)
    run("append", [cli, "-r", "-f", tape, "src/extra.txt"])
    expected["src/extra.txt"] = extra
    listing("list-appended", tape, entries + ["SRC;EXTRA TXT"])
    extracted("extract-appended", tape, expected)

    # Independent tiny DUMP image: SIMH little-endian record framing and TM03
    # five-byte 36-bit words, with no ITSTAR-generated data as the oracle.
    def word(value):
        value &= (1 << 36) - 1
        return bytes((value >> 28, (value >> 20) & 255, (value >> 12) & 255,
                      (value >> 4) & 255, value & 15))

    def sixbit(value):
        result = 0
        for character in value.ljust(6):
            result = (result << 6) | (ord(character) - 32)
        return result

    words = [((-4 & 0o777777) << 18), 1 << 18, sixbit("260101"), 0,
             ((-7 & 0o777777) << 18), sixbit("FIX"), sixbit("KNOWN"),
             sixbit("TXT"), 0, 0, 0]
    ascii_word = 0
    for character in b"ABCDE":
        ascii_word = (ascii_word << 7) | character
    words.append(ascii_word << 1)
    record = b"".join(map(word, words))
    length = struct.pack("<I", len(record))
    fixture = work / "known.tap"
    fixture.write_bytes(length + record + length + b"\0" * 8)
    listing("list-known", fixture, ["FIX;KNOWN TXT"])
    extracted("extract-known", fixture, {"fix/known.txt": b"ABCDE"})

    # The issue's explicit rmt restriction must fail before hostname lookup.
    result = subprocess.run([str(cli), "-t", "-f", "nonexistent.invalid:/dev/nst0"],
                            cwd=work, env=environment, capture_output=True, timeout=10)
    (evidence / "remote.stderr").write_bytes(result.stderr)
    require(result.returncode == 1 and
            b"Remote rmt tape paths are unsupported in this build" in result.stderr,
            "rmt restriction was not enforced")
    write_json(evidence / "report.json", {
        "output": str(output), "offline": True, "read_only_store": True,
        "private_home_xdg": True, "runtime_path_empty": True,
        "operations": ["create", "list", "extract", "append", "compressed-input"],
        "byte_exact_members": {name: hashlib.sha256(data).hexdigest()
                               for name, data in expected.items()},
        "independent_fixture_sha256": hashlib.sha256(fixture.read_bytes()).hexdigest(),
        "independent_fixture_content": "ABCDE", "rmt_rejected": True})
    print("Installed CLI produced exact listings and byte-identical evacuated text/binary/empty files;")
    print("compressed input, append, and independent local DUMP fixture also passed.")


if __name__ == "__main__":
    main()
