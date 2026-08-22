#!/bin/sh
set -eu

channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
guix_bin=${GUIX:-guix}
out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes lyntin)
site=$(find "$out/lib" -type d -name site-packages -print -quit)
python=$(sed -n '1s/^#!//p' "$out/bin/.lyntin-real")
test -x "$python"

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT HUP INT TERM

HOME="$home" PYTHONPATH="$site" "$python" - "$out" <<'PY'
import socket
import sys
import threading

from lyntin import exported
from lyntin.net import SocketCommunicator

out = sys.argv[1]
seen = []
ready = threading.Event()


def server():
    listener = socket.socket()
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    seen.append(listener.getsockname()[1])
    ready.set()
    client, _ = listener.accept()
    seen.append(client.recv(64))
    client.sendall(b"Welcome to test MUD!\r\n")
    client.close()
    listener.close()


class Config:
    def get(self, name):
        return 0

    def change(self, name, value):
        pass


class Hook:
    def getList(self):
        return []


class Engine:
    def getConfigManager(self):
        return Config()

    def getSession(self, name):
        return object()

    def getHook(self, name):
        return Hook()


thread = threading.Thread(target=server)
thread.start()
ready.wait()
engine = Engine()
exported.myengine = engine
communicator = SocketCommunicator(engine, object(), "127.0.0.1", seen[0])
communicator.connect("127.0.0.1", seen[0], "smoke")
communicator.write("look\n")
received = communicator._pollForData()
communicator._sock.close()
thread.join(2)

assert seen[1] == b"look\r\n", seen
assert "Welcome to test MUD!" in received, received
assert not list(__import__("pathlib").Path.home().iterdir())
print("loopback-mud-ok")
PY

test "$(HOME="$home" "$out/bin/lyntin" --version 2>/dev/null)" = "$(printf '%s\n' 'Lyntin 5.0.1' 'For bugs, suggestions, mailing list info, feature requests,' 'architecture docs, et al, see https://gitlab.little-beak.com/projects/lyntin')"
test -z "$(find "$home" -mindepth 1 -print -quit)"
printf '%s\n' 'lyntin smoke passed: version, fresh HOME, and loopback MUD protocol'
