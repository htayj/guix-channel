#!/usr/bin/env python3
"""Drive Diabaig's package-owned isolated smoke scenario through a PTY."""

import errno
import fcntl
import os
import pty
import re
import select
import signal
import struct
import sys
import tempfile
import termios
import time
from pathlib import Path


if len(sys.argv) != 2:
    raise SystemExit("usage: diabaig-smoke.py PROGRAM")

program = sys.argv[1]
scratch = Path(tempfile.mkdtemp(prefix="diabaig-smoke.",
                                dir=os.environ.get("TMPDIR")))
home = scratch / "home"
config = scratch / "config"
data = scratch / "data"
cache = scratch / "cache"
state_root = scratch / "state"
runtime = scratch / "runtime"
tmp = scratch / "tmp"
work = scratch / "work"
caller = scratch / "caller"
state = state_root / "diabaig"
for directory in (home, config, data, cache, state_root, runtime, tmp, work,
                  caller, state):
    directory.mkdir(parents=True)

child_environment = {
    "HOME": str(home),
    "XDG_CONFIG_HOME": str(config),
    "XDG_DATA_HOME": str(data),
    "XDG_CACHE_HOME": str(cache),
    "XDG_STATE_HOME": str(state_root),
    "XDG_RUNTIME_DIR": str(runtime),
    "TMPDIR": str(tmp),
    "TERM": "xterm-256color",
    "LC_ALL": "C",
}
if os.environ.get("TERMINFO_DIRS"):
    child_environment["TERMINFO_DIRS"] = os.environ["TERMINFO_DIRS"]

ansi = re.compile(
    rb"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\)|"
    rb"[()][0-9A-Za-z])")


def visible(stream):
    """Return printable text from a curses stream for state assertions."""
    stream = ansi.sub(b"", stream).replace(b"\r", b"")
    return bytes(byte if byte in (9, 10) or 32 <= byte < 127 else 32
                 for byte in stream)


def stop_child(pid):
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        os.waitpid(pid, 0)
    except ChildProcessError:
        pass


def fail(message, pid=None, master=None):
    if pid is not None:
        stop_child(pid)
    if master is not None:
        try:
            os.close(master)
        except OSError:
            pass
    raise SystemExit(message)


pid, master = pty.fork()
if pid == 0:
    os.environ.clear()
    os.environ.update(child_environment)
    os.chdir(state)
    os.execv(program, [program, "-t", "-s", "329"])

fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 33, 78, 0, 0))
deadline = time.monotonic() + 30
stage = bytearray()
raw_frame = bytearray()
sent_move = False
sent_inventory = False
sent_save = False
sent_save_slot = False
sent_save_confirm = False
sent_continue = False
sent_load_slot = False
sent_loaded_inventory = False
sent_quit = False
sent_quit_confirm = False
sent_home_quit = False
state_name = "home"
reaped = False


def send(keys):
    try:
        os.write(master, keys)
    except OSError as error:
        fail("Diabaig PTY smoke could not send input: %s" % error,
             pid, master)


while True:
    if time.monotonic() >= deadline:
        fail("Diabaig PTY smoke timed out in %s" % state_name, pid, master)

    chunk = b""
    ready, _, _ = select.select([master], [], [], 0.2)
    if ready:
        try:
            chunk = os.read(master, 8192)
        except OSError as error:
            if error.errno == errno.EIO:
                chunk = b""
            else:
                fail("Diabaig PTY smoke read failed: %s" % error,
                     pid, master)
        if chunk:
            stage.extend(chunk)
            del stage[:-65536]
            if sent_move and not raw_frame:
                raw_frame.extend(chunk)
                del raw_frame[65536:]

    text = visible(bytes(stage)).lower()
    save_file = state / "save" / "diabaig.save.1"
    autosave = state / "save" / "diabaig.autosave"

    if state_name == "home" and b"new game" in text:
        send(b"n")
        stage.clear()
        state_name = "name"
    elif state_name == "name" and b"choose your name" in text:
        send(b"GuixSmoke\n")
        stage.clear()
        state_name = "class"
    elif state_name == "class" and b"choose your starting class" in text:
        send(b"\n")
        stage.clear()
        state_name = "game"
    elif (state_name == "game" and b"floor:" in text and b"hp:" in text
          and b"@" in text):
        send(b"l")
        sent_move = True
        stage.clear()
        state_name = "moved"
    elif state_name == "moved" and b"floor:" in text and b"hp:" in text:
        send(b"i")
        sent_inventory = True
        stage.clear()
        state_name = "inventory"
    elif state_name == "inventory" and b"inventory (" in text:
        send(b"\n")
        stage.clear()
        state_name = "after-inventory"
    elif (state_name == "after-inventory" and b"floor:" in text
          and b"hp:" in text):
        send(b"S")
        sent_save = True
        stage.clear()
        state_name = "save"
    elif state_name == "save" and b"save game" in text:
        send(b"\n")
        sent_save_slot = True
        stage.clear()
        state_name = "save-confirm"
    elif state_name == "save-confirm" and b"are you sure" in text:
        send(b"y")
        sent_save_confirm = True
        stage.clear()
        state_name = "saved"
    elif (state_name == "saved" and save_file.is_file()
          and b"continue" in text):
        send(b"c")
        sent_continue = True
        stage.clear()
        state_name = "load"
    elif state_name == "load" and b"load game" in text:
        send(b"j\n")
        sent_load_slot = True
        stage.clear()
        state_name = "loaded"
    elif state_name == "loaded" and b"successfully loaded" in text:
        send(b"i")
        sent_loaded_inventory = True
        stage.clear()
        state_name = "loaded-inventory"
    elif state_name == "loaded-inventory" and b"inventory (" in text:
        send(b"\n")
        stage.clear()
        state_name = "loaded-after-inventory"
    elif (state_name == "loaded-after-inventory" and b"floor:" in text
          and b"hp:" in text):
        send(b"Q")
        sent_quit = True
        stage.clear()
        state_name = "quit-confirm"
    elif state_name == "quit-confirm" and b"quit?" in text:
        send(b"y")
        sent_quit_confirm = True
        stage.clear()
        state_name = "final-home"
    elif (state_name == "final-home" and b"new game" in text
          and b"quit" in text):
        send(b"q")
        sent_home_quit = True
        stage.clear()
        state_name = "done"

    finished, status = os.waitpid(pid, os.WNOHANG)
    if finished:
        reaped = True
        break
    if not chunk and ready:
        break

if not reaped:
    _, status = os.waitpid(pid, 0)
os.close(master)

required = (sent_move and sent_inventory and sent_save and sent_save_slot
            and sent_save_confirm and sent_continue and sent_load_slot
            and sent_loaded_inventory and sent_quit and sent_quit_confirm
            and sent_home_quit)
if not required:
    raise SystemExit("Diabaig PTY smoke stopped before the save/load flow")
if not os.WIFEXITED(status) or os.WEXITSTATUS(status) != 0:
    raise SystemExit("Diabaig PTY smoke exited unsuccessfully")
if save_file.exists():
    raise SystemExit("Diabaig PTY smoke left slot 1 behind")
if autosave.exists():
    raise SystemExit("Diabaig PTY smoke left an autosave behind")
if not raw_frame:
    raise SystemExit("Diabaig PTY smoke did not capture a dungeon frame")

raw_capture = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
if raw_capture:
    capture = Path(raw_capture)
    capture.parent.mkdir(parents=True, exist_ok=True)
    capture.write_bytes(raw_frame)

print("DIABAIG_RUNTIME_OK")
