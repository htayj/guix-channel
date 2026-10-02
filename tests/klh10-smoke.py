#!/usr/bin/env python3
"""Exercise installed KLH10 processors and converters, never guest software."""
import errno
import json
import os
from pathlib import Path
import pty
import re
import select
import socket
import struct
import subprocess
import sys
import time

output, scratch, artifacts = map(Path, sys.argv[1:])
for ns in ("user", "mnt", "net", "ipc", "pid"):
    key = {"mnt": "MOUNT", "net": "NET", "ipc": "IPC", "pid": "PID", "user": "USER"}[ns]
    assert os.readlink(f"/proc/self/ns/{ns}") != os.environ[f"HOST_{key}_NS"], ns
interfaces = socket.if_nameindex()
assert interfaces == [(1, "lo")], interfaces
print("isolated namespaces; network interfaces:", interfaces, flush=True)
for name in ("home", "config", "data", "cache", "state", "work"):
    (scratch / name).mkdir()
os.environ.update(HOME=str(scratch / "home"), XDG_CONFIG_HOME=str(scratch / "config"),
                  XDG_DATA_HOME=str(scratch / "data"), XDG_CACHE_HOME=str(scratch / "cache"),
                  XDG_STATE_HOME=str(scratch / "state"), TERM="dumb")
os.chdir(scratch / "work")
for excluded in ("dpni20", "dpimp", "dpchaos", "enaddr", "supdup", "supdupd"):
    assert not (output / "bin" / excluded).exists(), excluded
source = output / "share/klh10/source"
for excluded in ("run", "contrib", "install-guides"):
    assert not (source / excluded).exists(), excluded
assert (source / "LICENSE").is_file()


def run(name, args, data=None):
    result = subprocess.run([str(output / "bin" / name), *args], input=data,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
    (artifacts / f"{name}-{len(list(artifacts.glob(name + '-*.log')))}.log").write_bytes(
        result.stdout + result.stderr)
    assert result.returncode == 0, (name, args, result.returncode, result.stderr)
    if name == "tapedd":
        counters = re.findall(rb";\s*(In|Out):\s*(\d+)\+(\d+) errs,", result.stderr)
        assert counters == [(b"In", b"0", b"0"), (b"Out", b"0", b"0")], result.stderr
        assert b"Stopped" not in result.stderr and b"Error" not in result.stderr, result.stderr
    return result.stdout


def console(model):
    master, slave = pty.openpty()
    proc = subprocess.Popen([str(output / "bin" / model), "/dev/null"],
                            stdin=slave, stdout=slave, stderr=slave, close_fds=True)
    os.close(slave)
    transcript = bytearray()
    capture = artifacts / f"{model}-terminal.raw"

    def receive(pattern):
        start = len(transcript)
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            if re.search(pattern, transcript[start:]):
                return bytes(transcript[start:])
            if select.select([master], [], [], 0.2)[0]:
                try:
                    chunk = os.read(master, 65536)
                except OSError as exc:
                    if exc.errno == errno.EIO:
                        break
                    raise
                if not chunk:
                    break
                transcript.extend(chunk)
                capture.write_bytes(transcript)
        raise AssertionError((model, pattern, transcript[start:].decode("latin1")))

    def command(text):
        os.write(master, text.encode("ascii") + b"\n")
        # fecmd.c maps configuration/halted/running to KLH10#/>/>>.
        return receive(rb"KLH10(?:#|>>?)\s+")

    try:
        receive(rb"KLH10(?:#|>>?)\s+")
        assert b"deposit" in command("help"), model
        command("reset")
        command("deposit 100 201040000123")  # MOVEI AC1,123 (octal).
        command("deposit 101 254200000101")  # HALT at101.
        assert re.search(rb"201040,,123", command("examine 100")), model
        assert re.search(rb"254200,,101", command("examine 101")), model
        before = command("examine 1")
        assert re.search(rb"\b0*1/ 0\r?\n", before), before
        command("go 100")
        after = command("examine 1")
        assert re.search(rb"\b0*1/ 123\r?\n", after), after
        status = command("view")
        # Opcode254 AC4 is HALT (injrst.c), printed as JRST4 by disassembly.
        # The deposited instruction and AC transition above prove what ran;
        # require the actual stopped CPU and destination PC, not alias text.
        assert re.search(rb"KN10 status: STOPPED\b", status), status
        assert re.search(rb"\bPC: ?0*101\b", status), status
        command("deposit 200 777777777777")
        assert re.search(rb"777777,,777777", command("examine 200")), model
        command("zero")
        assert re.search(rb"\b0*200/ 0\r?\n", command("examine 200")), model
        os.write(master, b"really-quit\n")
        deadline = time.monotonic() + 10
        while proc.poll() is None and time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                try:
                    transcript.extend(os.read(master, 65536))
                except OSError as exc:
                    if exc.errno != errno.EIO:
                        raise
                    break
        assert proc.wait(timeout=5) == 0, model
        print(model, "MOVEI/HALT: AC1 0 -> octal123; memory deposit/zero verified", flush=True)
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        capture.write_bytes(transcript)
        os.close(master)


for model in ("kn10-kl", "kn10-ks", "kn10-ks-its"):
    assert b"Usage:" in run(model, ["--help"])
    assert b"2.0l-guix" in run(model, ["--version"])
    console(model)
assert b"Usage:" in run("klh10", ["-help"])
assert b"2.0l-guix" in run("klh10", ["-version"])

# Known, nonzero 36-bit words, including the maximum value; core -> high-density
# -> core must preserve every bit, not just produce some output.
words = (0, 1, 0o201040000123, 0o254200000101, (1 << 36) - 1, 0o123456654321)
core = b"".join((w >> 4).to_bytes(4, "big") + bytes([w & 15]) for w in words)
high = run("wfconv", ["-ch"], core)
assert high != core and len(high) == len(words) * 9 // 2
assert run("wfconv", ["-hc"], high) == core

# Sparse RP02 disk with nonzero first sector; verify fixed-format serialization
# of each nonzero 36-bit word and exact inverse. vdkfmt visits the final inclusive
# sector too, and treats missing tail sectors as zeros.
sector_words = tuple(((i + 1) * 0o1234567) & ((1 << 36) - 1) for i in range(128))
disk_data = b"".join(w.to_bytes(8, "little") for w in sector_words)
disk = Path("synthetic.dlw8")
disk.write_bytes(disk_data)
with disk.open("r+b") as stream:
    stream.truncate((40600 + 1) * 128 * 8)
run("vdkfmt", [f"ip={disk}", "op=synthetic.dbd9", "ifmt=DLW8", "ofmt=DBD9", "dt=RP02"])
expected_packed = b"".join(((sector_words[i] << 36) | sector_words[i + 1]).to_bytes(9, "big")
                           for i in range(0, 128, 2))
assert Path("synthetic.dbd9").read_bytes() == expected_packed
run("vdkfmt", ["ip=synthetic.dbd9", "op=roundtrip.dlw8", "ifmt=DBD9", "ofmt=DLW8", "dt=RP02"])
assert Path("roundtrip.dlw8").read_bytes() == disk_data

# Two synthetic tape records, including an odd-length record. TPS padding must
# disappear in TPE and reappear on inverse conversion; tapemarks remain exact.
records = (b"KLH10 offline synthetic tape", bytes(range(32)))
def tape(padded):
    body = bytearray()
    for record in records:
        count = struct.pack("<I", len(record))
        body.extend(count + record)
        if padded and len(record) % 2:
            body.append(0)
        body.extend(count)
    body.extend(struct.pack("<II", 0, 0))
    return bytes(body)
Path("synthetic.tps").write_bytes(tape(True))
run("tapedd", ["itvs=synthetic.tps", "otve=synthetic.tpe"])
assert Path("synthetic.tpe").read_bytes() == tape(False)
run("tapedd", ["itve=synthetic.tpe", "otvs=roundtrip.tps"])
assert Path("roundtrip.tps").read_bytes() == tape(True)
print("wfconv: all36bit patterns preserved; vdkfmt: exact disk format roundtrip; tapedd: exact record/tapemark roundtrip", flush=True)
(artifacts / "summary.json").write_text(json.dumps({
    "models": ["kn10-kl", "kn10-ks", "kn10-ks-its"],
    "accumulator1_octal": "123", "guest_images": False,
    "conversion_proof": ["core/high-density word bits", "DLW8/DBD9 disk words", "TPS/TPE tape records and tapemarks"],
    "interfaces": interfaces,
}, indent=2) + "\n")
