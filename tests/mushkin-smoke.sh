#!/bin/sh
# Exercise Mushkin's packaged runtime only on a private loopback network.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [mushkin-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    mushkin_out=$1
else
    mushkin_out=$($guix_bin build -L "$channel_dir" --no-grafts mushkin)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then python_out=$candidate; break; fi
done
luajit_out=$($guix_bin build luajit)
openssl_out=
for candidate in $($guix_bin build openssl); do
    if test -x "$candidate/bin/openssl"; then openssl_out=$candidate; break; fi
done
xorg_server_out=$($guix_bin build xorg-server)
iproute_out=$($guix_bin build iproute2)
unshare_bin=$(command -v unshare)

test -x "$mushkin_out/bin/mushkin"
test -x "$mushkin_out/libexec/mushkin/mushkin"
test -d "$mushkin_out/libexec/mushkin/lua"
test -d "$mushkin_out/libexec/mushkin/lib"
test -f "$mushkin_out/share/doc/mushkin/LICENSE"
test -f "$mushkin_out/share/doc/mushkin/THIRD_PARTY_LICENSES.md"
test -d "$mushkin_out/share/doc/mushkin/third-party-notices"
test -f "$mushkin_out/share/applications/mushkin.desktop"
test -f "$mushkin_out/share/icons/hicolor/scalable/apps/mushkin.svg"
rg -qx 'Name=Mushkin' "$mushkin_out/share/applications/mushkin.desktop"
rg -qx "Exec=$mushkin_out/bin/mushkin %f" "$mushkin_out/share/applications/mushkin.desktop"
rg -qx 'Icon=mushkin' "$mushkin_out/share/applications/mushkin.desktop"
test -n "$python_out"
test -x "$python_out/bin/python3"
test -x "$luajit_out/bin/luajit"
test -n "$openssl_out"
test -x "$openssl_out/bin/openssl"
test -x "$xorg_server_out/bin/Xvfb"
test -n "$unshare_bin"
if test -x "$iproute_out/bin/ip"; then ip_bin=$iproute_out/bin/ip; else ip_bin=$iproute_out/sbin/ip; fi

# The namespace contains only lo.  Both the fake MUD and the TLS endpoint are
# local; a regression cannot contact a public server from this smoke test.
exec "$unshare_bin" --user --map-root-user --net --fork \
    "$python_out/bin/python3" - "$mushkin_out" "$luajit_out/bin/luajit" "$openssl_out/bin/openssl" \
    "$xorg_server_out/bin/Xvfb" "$ip_bin" <<'PY'
import hashlib
import os
import pathlib
import signal
import socket
import ssl
import subprocess
import sys
import tempfile
import threading
import time

out = pathlib.Path(sys.argv[1])
luajit, openssl, xvfb, ip = sys.argv[2:]


def tree_digest(root):
    result = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        result.update(str(path.relative_to(root)).encode())
        if path.is_file():
            result.update(path.read_bytes())
    return result.digest()


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=6)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=6)


with tempfile.TemporaryDirectory(prefix="mushkin-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home, xdg_config, xdg_data, xdg_cache, runtime = [root / name for name in
                                                        ("home", "config", "data", "cache", "runtime")]
    for directory in (home, xdg_config, xdg_data, xdg_cache, runtime):
        directory.mkdir()
    runtime.chmod(0o700)
    subprocess.run([ip, "link", "set", "lo", "up"], check=True)
    links = subprocess.check_output([ip, "-o", "link", "show"], text=True)
    assert [line.split(":", 2)[1].strip().split("@", 1)[0]
            for line in links.splitlines()] == ["lo"], links

    env = os.environ.copy()
    env.update({"HOME": str(home), "MUSHKIN_HOME": str(root / "mushkin-home"),
                "XDG_CONFIG_HOME": str(xdg_config), "XDG_DATA_HOME": str(xdg_data),
                "XDG_CACHE_HOME": str(xdg_cache), "XDG_RUNTIME_DIR": str(runtime),
                "DISPLAY": ":95", "QT_QPA_PLATFORM": "xcb", "LIBGL_ALWAYS_SOFTWARE": "1",
                "LC_ALL": "C.UTF-8"})
    display = subprocess.Popen([xvfb, ":95", "-screen", "0", "1024x768x24", "-nolisten", "tcp"],
                               env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               start_new_session=True)
    try:
        time.sleep(.4)
        assert display.poll() is None, display.stderr.read().decode("utf-8", "replace")
        before = tree_digest(out)

        # A valid MUSHclient world document selects MUSH auto-connect and MSP.
        mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        mud.bind(("127.0.0.1", 0)); mud.listen(2); mud.settimeout(12)
        mud_port = mud.getsockname()[1]
        script = root / "loopback.lua"
        script.write_text("""local function send_version()
  world.Send("MUSHKIN_VERSION " .. world.Version() .. "\\\\n")
end
function OnWorldOpen()
  if world.IsConnected() then send_version() else world.Connect() end
end
function OnWorldConnect()
  send_version()
end
""", encoding="utf-8")
        world = root / "loopback.mcl"
        world.write_text("""<?xml version=\"1.0\"?><!DOCTYPE muclient><muclient><world
name=\"Loopback\" site=\"127.0.0.1\" port=\"%d\" connect_method=\"1\"
use_msp=\"y\" enable_scripts=\"y\" script_language=\"Lua\" script_filename=\"%s\"></world></muclient>""" % (mud_port, script),
                         encoding="utf-8")
        escaped = root / "escaped.wav"
        accepts = []
        completed = []
        server_errors = []
        connected = threading.Condition()

        def fake_mud():
            for _ in range(2):
                peer, address = mud.accept()
                try:
                    assert address[0] == "127.0.0.1", address
                    with connected:
                        accepts.append(address)
                        connected.notify_all()
                    peer.sendall(b"\xff\xfb\x5a\r\n")      # IAC WILL MSP and a normal line
                    peer.settimeout(.25)
                    received = b""
                    deadline = time.monotonic() + 5
                    while time.monotonic() < deadline:
                        try:
                            received += peer.recv(256)
                        except socket.timeout:
                            continue
                        if b"\xff\xfd\x5a" in received and b"MUSHKIN_VERSION 0.5.1" in received:
                            break
                    assert b"\xff\xfd\x5a" in received, received
                    assert b"MUSHKIN_VERSION 0.5.1" in received, received
                # An MSP path traversal must neither fetch nor cache a file.
                    peer.sendall(b"\xff\xfa\x5aSOUND ../../escaped.wav U=http://127.0.0.1:9\xff\xf0")
                    with connected:
                        completed.append(address)
                        connected.notify_all()
                    time.sleep(.5)
                except BaseException as error:
                    with connected:
                        server_errors.append(error)
                        connected.notify_all()
                finally:
                    peer.close()
        thread = threading.Thread(target=fake_mud, daemon=True); thread.start()

        for launch in range(2):
            client = subprocess.Popen([str(out / "bin" / "mushkin"), str(world)], env=env,
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      start_new_session=True)
            try:
                with connected:
                    assert connected.wait_for(lambda: len(accepts) >= launch + 1, 8), "Mushkin did not connect to loopback MUD"
                    assert connected.wait_for(lambda: len(completed) >= launch + 1 or server_errors, 8), "MUD exchange did not complete"
                    assert not server_errors, server_errors[0]
                deadline = time.monotonic() + 4
                while not (pathlib.Path(env["MUSHKIN_HOME"]) / "mushclient_prefs.sqlite").exists() and time.monotonic() < deadline:
                    time.sleep(.1)
                assert (pathlib.Path(env["MUSHKIN_HOME"]) / "mushclient_prefs.sqlite").is_file()
                assert client.poll() is None, client.stderr.read().decode("utf-8", "replace")
            finally:
                stop(client)
        mud.close(); thread.join(timeout=2)
        assert not escaped.exists(), "unsafe MSP filename escaped its cache"
        assert tree_digest(out) == before, "Mushkin modified its Guix output"

        # The installed LuaSec/LuaSocket runtime performs a real loopback TLS
        # handshake; no host Lua modules or public certificate endpoint are used.
        cert, key = root / "cert.pem", root / "key.pem"
        subprocess.run([openssl, "req", "-x509", "-newkey", "rsa:2048", "-nodes",
                        "-keyout", str(key), "-out", str(cert), "-subj", "/CN=localhost",
                        "-days", "1"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        listener.bind(("127.0.0.1", 0)); listener.listen(1); listener.settimeout(8)
        tls_port = listener.getsockname()[1]
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); context.load_cert_chain(cert, key)
        def tls_server():
            raw, _ = listener.accept()
            with context.wrap_socket(raw, server_side=True) as peer:
                peer.recv(1024); peer.sendall(b"HTTP/1.0 200 OK\r\nContent-Length: 2\r\n\r\nOK")
        tls_thread = threading.Thread(target=tls_server, daemon=True); tls_thread.start()
        lua_env = dict(env)
        lua_env["LUA_PATH"] = str(out / "libexec/mushkin/lua/?.lua") + ";" + str(out / "libexec/mushkin/lua/?/init.lua")
        lua_env["LUA_CPATH"] = str(out / "libexec/mushkin/lib/?.so") + ";" + str(out / "libexec/mushkin/lib/?/core.so")
        program = ("local socket=require('socket'); local ssl=require('ssl'); "
                   "local tcp=assert(socket.tcp()); assert(tcp:connect('127.0.0.1',%d)); "
                   "local tls=assert(ssl.wrap(tcp,{mode='client',protocol='tlsv1_2',verify='none'})); "
                   "assert(tls:dohandshake()); assert(tls:send('GET / HTTP/1.0\\r\\n\\r\\n')); "
                   "local body,err,partial=tls:receive('*a'); local response=body or partial or ''; "
                   "assert(response:find('HTTP/1.0 200 OK',1,true) and response:sub(-2)=='OK', err)") % tls_port
        subprocess.run([luajit, "-e", program], env=lua_env, check=True, timeout=10)
        listener.close(); tls_thread.join(timeout=2)
    finally:
        stop(display)
PY
