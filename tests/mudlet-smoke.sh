#!/bin/sh
# Exercise Mudlet's packaged Telnet URI path against a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [mudlet-output]" >&2
    exit 64
fi

# Keep both listener and client in an otherwise empty network namespace.  The
# smoke deliberately requires this isolation: a namespace failure is not
# silently weakened into a host-network test.
if test "${MUDLET_SMOKE_NAMESPACED:-}" != 1; then
    command -v unshare >/dev/null || {
        echo "mudlet-smoke: unshare is required" >&2
        exit 125
    }
    ip_out=$($guix_bin build iproute2)
    exec unshare --user --map-root-user --net sh -c '
        ip=$1
        script=$2
        shift 2
        "$ip" link set lo up
        export MUDLET_SMOKE_NAMESPACED=1
        exec "$script" "$@"
    ' sh "$ip_out/sbin/ip" "$0" "$@"
fi

if test "$#" -eq 1; then
    mudlet_out=$1
else
    mudlet_out=$($guix_bin build -L "$channel_dir" --no-grafts mudlet)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
xorg_server_out=$($guix_bin build xorg-server)
lua51_out=$($guix_bin build -e '(begin (use-modules (gnu packages lua)) lua-5.1)')

test -n "$python_out"
test -x "$python_out/bin/python3"
test -x "$xorg_server_out/bin/Xvfb"
test -x "$lua51_out/bin/lua"
test -x "$mudlet_out/bin/mudlet"
test -f "$mudlet_out/share/doc/mudlet/Mudlet-GPL-2.0-or-later.txt"
test -f "$mudlet_out/share/doc/mudlet/lua-code-formatter-GPL-3.0.txt"
test -f "$mudlet_out/share/doc/mudlet/Communi-BSD-3-Clause.txt"
test -f "$mudlet_out/share/doc/mudlet/edbee-lib-MIT.txt"
test -f "$mudlet_out/share/doc/mudlet/qt-tags-widget-MIT.txt"
test ! -e "$mudlet_out/3rdparty/discord/rpc/lib/libdiscord-rpc.so"
test ! -e "$mudlet_out/3rdparty/discord/rpc/lib/libdiscord-rpc.dylib"
test ! -e "$mudlet_out/3rdparty/discord/rpc/lib/discord-rpc64.dll"
test ! -e "$mudlet_out/3rdparty/discord/rpc/lib/discord-rpc32.dll"
test -z "$(find "$mudlet_out" -type f -perm /222 -print -quit)"

version_root=$(mktemp -d -t mudlet-version.XXXXXX)
trap 'rm -rf "$version_root"' EXIT HUP INT TERM
mkdir "$version_root/home" "$version_root/config" "$version_root/data" "$version_root/cache"
version=$(HOME="$version_root/home" XDG_CONFIG_HOME="$version_root/config" \
    XDG_DATA_HOME="$version_root/data" XDG_CACHE_HOME="$version_root/cache" \
    QT_QPA_PLATFORM=offscreen "$mudlet_out/bin/mudlet" --version)
printf '%s\n' "$version" | grep -F 'mudlet 4.22.0'
printf '%s\n' "$version" | grep -F 'Licence GPLv2+'

"$python_out/bin/python3" - "$mudlet_out" "$xorg_server_out/bin/Xvfb" \
    "$lua51_out/bin/lua" <<'PY'
import os
import pathlib
import re
import signal
import socket
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb = sys.argv[2]
lua51 = sys.argv[3]


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=8)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=8)


with tempfile.TemporaryDirectory(prefix="mudlet-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config = temporary / "config"
    data = temporary / "data"
    cache = temporary / "cache"
    runtime = temporary / "runtime"
    for directory in (home, config, data, cache, runtime):
        directory.mkdir()
    runtime.chmod(0o700)

    environment = os.environ.copy()
    environment.update({
        "HOME": str(home),
        "XDG_CONFIG_HOME": str(config),
        "XDG_DATA_HOME": str(data),
        "XDG_CACHE_HOME": str(cache),
        "XDG_RUNTIME_DIR": str(runtime),
        "DISPLAY": ":97",
        "QT_QPA_PLATFORM": "xcb",
        # Make Qt report dynamically discovered plugins so this smoke proves
        # the installed multimedia backend is usable, not merely wrapped.
        "QT_DEBUG_PLUGINS": "1",
        "LC_ALL": "C.UTF-8",
        # Avoid Mudlet's first-run desktop telnet-handler prompt: a smoke
        # cannot interact with it, and the URI path is tested directly below.
        "CI": "1",
    })
    for name in ("http_proxy", "https_proxy", "all_proxy", "HTTP_PROXY",
                 "HTTPS_PROXY", "ALL_PROXY", "MUDLET_PROFILES"):
        environment.pop(name, None)

    # Read the installed executable's outer wrapper, rather than reconstructing
    # package paths from the channel.  The wrapper is the runtime contract:
    # it must expose every Lua 5.1 C module before Mudlet initializes Lua.
    wrapper = (out / "bin" / "mudlet").read_text(encoding="utf-8")
    cpaths = re.findall(
        r"/gnu/store/[^\"'\s;:]+/(?:lib/lua/5\.1|share/lua/cmod)/\?\.so",
        wrapper,
    )
    lua_paths = re.findall(
        r"/gnu/store/[^\"'\s;:]+/share/lua/5\.1/\?\.lua", wrapper
    )
    cpaths = list(dict.fromkeys(cpaths))
    lua_paths = list(dict.fromkeys(lua_paths))
    assert len(cpaths) >= 7, cpaths
    assert lua_paths, wrapper
    lua_environment = environment.copy()
    lua_environment["LUA_CPATH"] = ";".join(cpaths)
    lua_environment["LUA_PATH"] = ";".join(lua_paths)
    module_check = subprocess.run(
        [lua51, "-e", r'''
            _G.lfs = assert(require "lfs")
            _G.zip = assert(require "brimworks.zip")
            _G.rex_pcre2 = assert(require "rex_pcre2")
            _G.luasql = assert(require "luasql.sqlite3")
            _G.utf8 = assert(require "lua-utf8")
            _G.yajl = assert(require "yajl")
            _G.lpeg = assert(require "lpeg")
            assert(lfs and zip and rex_pcre2 and luasql and utf8 and yajl and lpeg)
            io.write("mudlet-lua-globals=ok\n")
        '''],
        env=lua_environment, capture_output=True, text=True, check=False,
    )
    assert module_check.returncode == 0, module_check.stderr
    assert module_check.stdout == "mudlet-lua-globals=ok\n", module_check.stdout

    # Namespace evidence prevents an accidental host-network smoke.  In a new
    # net namespace loopback is the sole interface and the only listener below
    # binds to its IPv4 address.
    assert socket.if_nameindex() == [(1, "lo")], socket.if_nameindex()
    mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    mud.bind(("127.0.0.1", 0))
    mud.listen(1)
    mud.settimeout(20)
    port = mud.getsockname()[1]

    display = subprocess.Popen(
        [xvfb, environment["DISPLAY"], "-screen", "0", "1024x768x24",
         "-nolisten", "tcp"],
        env=environment, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        start_new_session=True, text=True,
    )
    client = None
    client_stdout = ""
    client_stderr = ""
    peer = None
    try:
        time.sleep(1)
        assert display.poll() is None, display.stderr.read()
        # This command-line URI is Mudlet's supported profile-creation and
        # auto-connect path; no profile fixture or credentials are supplied.
        client = subprocess.Popen(
            [str(out / "bin" / "mudlet"), f"telnet://127.0.0.1:{port}"],
            env=environment, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            start_new_session=True, text=True,
        )
        try:
            peer, address = mud.accept()
        except TimeoutError as error:
            # Preserve useful evidence when a GUI startup/environment issue
            # prevents the URI from reaching the isolated loopback listener.
            client_state = client.poll()
            stop(client)
            client_stdout, client_stderr = client.communicate()
            listeners = pathlib.Path("/proc/net/tcp").read_text(encoding="utf-8")
            profile_state = [str(path.relative_to(home)) for path in home.rglob("*")]
            raise AssertionError(
                "Mudlet did not connect to fake MUD; "
                f"returncode-before-stop={client_state}; "
                f"client-stdout={client_stdout!r}; client-stderr={client_stderr!r}; "
                f"tcp={listeners!r}; profile-state={profile_state!r}"
            ) from error
        assert address[0] == "127.0.0.1", address
        peer.settimeout(8)
        # Plain text does not demand a Telnet response.  Request terminal type
        # so the client must answer with a standards-level negotiation byte.
        peer.sendall(b"Mudlet loopback smoke banner\r\n\xff\xfd\x18")
        # Receiving a response proves the accepted socket is a live Telnet
        # session rather than a stalled GUI connection.
        assert peer.recv(4096), "Mudlet sent no Telnet traffic"
        assert client.poll() is None, client.stderr.read()
    finally:
        if peer is not None:
            peer.close()
        mud.close()
        if client is not None:
            stop(client)
            client_stdout, client_stderr = client.communicate()
        stop(display)

    assert "libffmpegmediaplugin" in client_stderr, client_stderr
    assert "No QtMultimedia backends found" not in client_stderr, client_stderr

    # Mudlet deliberately maintains its profile store below HOME rather than
    # XDG_DATA_HOME.  The generated metadata proves that mutable state stays
    # outside the immutable output.
    profiles = home / ".config" / "mudlet" / "profiles"
    assert profiles.is_dir(), list(home.rglob("*"))
    profile_files = list(profiles.rglob("*"))
    generated_profile = profiles / "127"
    assert (generated_profile / "url").is_file(), profile_files
    assert (generated_profile / "port").is_file(), profile_files
    # Mudlet profile values are QDataStream UTF-16BE strings: a four-byte
    # character-byte count followed by the encoded value.
    def read_profile_value(path):
        encoded = path.read_bytes()
        length = int.from_bytes(encoded[:4], byteorder="big")
        assert len(encoded) == length + 4, encoded
        return encoded[4:].decode("utf-16-be")

    stored_url = read_profile_value(generated_profile / "url")
    stored_port = read_profile_value(generated_profile / "port")
    assert stored_url == "127.0.0.1", stored_url
    assert stored_port == str(port), stored_port
    assert not any(str(out) in str(path) for path in home.rglob("*"))

print("mudlet fake-MUD smoke passed: installed Lua globals, user+net namespace, Xvfb, URI profile, loopback Telnet, and user profile state")
PY
