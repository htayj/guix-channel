#!/bin/sh
# Build and exercise ocaml-irc-client-unix against a loopback-only fake IRC
# server.  The library has no executable of its own, so this test compiles a
# tiny client with the installed findlib package and runs that real client.
set -eu

guix_tool=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [package-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    irc_out=$1
else
    irc_out=$($guix_tool build -L . --no-grafts --check ocaml-irc-client-unix)
fi

test -d "$irc_out"
if test -s "$irc_out/lib/ocaml/site-lib/irc-client-unix/META"; then
    package_kind=unix
    integration_out=$irc_out
elif test -s "$irc_out/lib/ocaml/site-lib/irc-client/META"; then
    package_kind=core
elif test -s "$irc_out/lib/ocaml/site-lib/irc-client-lwt/META"; then
    package_kind=lwt
elif test -s "$irc_out/lib/ocaml/site-lib/irc-client-lwt-ssl/META"; then
    package_kind=lwt-ssl
elif test -s "$irc_out/lib/ocaml/site-lib/lwt_ssl/META"; then
    package_kind=lwt-ssl-adapter
else
    echo "ocaml-irc-client-smoke: unrecognized findlib output" >&2
    exit 1
fi

if test "$package_kind" = lwt-ssl-adapter; then
    documentation=$irc_out/share/doc/ocaml-lwt-ssl
    test -s "$documentation/COPYING"
    grep -F "LGPL version 2.1" "$documentation/COPYING" >/dev/null
    test -s "$documentation/README.md"
else
    documentation=$irc_out/share/doc/ocaml-irc-client
    test -s "$documentation/LICENSE"
    grep -F "Permission is hereby granted" "$documentation/LICENSE" >/dev/null
    test -s "$documentation/README.md"
fi

if test "$package_kind" != unix; then
    integration_out=$($guix_tool build -L . --no-grafts --check ocaml-irc-client-unix)
fi

# Install the library and the compiler into a fresh profile.  This proves
# that the package is usable through Guix's installed findlib contract rather
# than only through a build-tree path.
temporary=$(mktemp -d "${TMPDIR:-/tmp}/ocaml-irc-client-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
profile=$temporary/profile
home=$temporary/home
xdg_config=$temporary/xdg-config
xdg_cache=$temporary/xdg-cache
xdg_data=$temporary/xdg-data
xdg_state=$temporary/xdg-state
mkdir -p "$home" "$xdg_config" "$xdg_cache" "$xdg_data" "$xdg_state"

$guix_tool package -L . --no-grafts -p "$profile" \
    -i ocaml@4.14.3 ocaml-findlib gcc-toolchain python util-linux ocaml-irc-client-unix

test -x "$profile/bin/ocamlfind"
test -x "$profile/bin/ocamlopt"

# Network isolation is an acceptance condition, not merely a convention.  A
# fresh user/network namespace contains only loopback; the server below and
# the client process both run inside it.
if test "${IRC_CLIENT_SMOKE_IN_NETNS:-}" != 1; then
    iproute_out=$($guix_tool build iproute2)
    if test -x "$iproute_out/bin/ip"; then
        ip_bin=$iproute_out/bin/ip
    else
        ip_bin=$iproute_out/sbin/ip
    fi
    test -x "$ip_bin"
    unshare_bin=$profile/bin/unshare
    test -x "$unshare_bin"
    if ! "$unshare_bin" --user --map-root-user --net --fork \
            sh -c '"$1" link set lo up' sh "$ip_bin"; then
        echo "ocaml-irc-client-smoke: user+network namespaces are required" >&2
        exit 1
    fi
    exec env IRC_CLIENT_SMOKE_IN_NETNS=1 \
        IRC_CLIENT_SMOKE_NETWORK_MODE=namespace \
        GUIX="$guix_tool" \
        "$unshare_bin" --user --map-root-user --net --fork \
        sh -c '"$1" link set lo up; exec "$2" "$3"' \
        sh "$ip_bin" "$0" "$irc_out"
fi

export HOME=$home
export XDG_CONFIG_HOME=$xdg_config
export XDG_CACHE_HOME=$xdg_cache
export XDG_DATA_HOME=$xdg_data
export XDG_STATE_HOME=$xdg_state
shell_path=$PATH
export PATH=$profile/bin:$shell_path
# Do not source the host profile.  Findlib discovers the installed library
# only through this fresh profile's site-lib path.
export OCAMLPATH=$profile/lib/ocaml/site-lib
export LC_ALL=C

client=$temporary/client.ml
cat > "$client" <<'EOF'
module C = Irc_client_unix
module M = Irc_message

let () =
  let port = int_of_string (Sys.argv.(1)) in
  try
    let connection =
      C.connect ~addr:Unix.inet_addr_loopback ~port ~username:"smoke-user"
        ~mode:0 ~realname:"ocaml irc smoke" ~nick:"smoke-nick" ()
    in
    C.send_privmsg ~connection ~target:"#smoke" ~message:"client-payload";
    C.listen ~keepalive:{mode=`Passive; timeout=8} ~connection
      ~callback:(fun _ result ->
        match result with
        | Result.Ok {M.command=M.PRIVMSG (target, message); _}
          when target = "#smoke" && message = "server-payload" ->
            print_endline "irc-client-loopback-ok";
            flush stdout;
            raise Exit
        | Result.Ok _ | Result.Error _ -> ()) ()
  with Exit -> ()
EOF

"$profile/bin/ocamlfind" ocamlopt -package irc-client-unix -linkpkg \
    -o "$temporary/client" "$client"

before=$temporary/output-before
after=$temporary/output-after
find "$irc_out" -printf '%y %m %s %T@ %p\n' | sort > "$before"

"$profile/bin/ocamlopt" -version >/dev/null

findlib_path=$("$profile/bin/ocamlfind" query irc-client-unix)
case "$findlib_path" in
    "$profile"/*|"$integration_out"/*) : ;;
    *)
        echo "ocaml-irc-client-smoke: findlib resolved outside the installed output" >&2
        exit 1
        ;;
esac

python=${IRC_CLIENT_SMOKE_PYTHON:-}
if test -z "$python"; then
    for candidate in "$profile/bin/python3" /usr/bin/python3 /bin/python3; do
        if test -x "$candidate"; then
            python=$candidate
            break
        fi
    done
fi
test -n "$python"

"$python" - "$temporary/client" <<'PY'
import pathlib
import socket
import subprocess
import sys
import tempfile

client = pathlib.Path(sys.argv[1])
listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
listener.bind(("127.0.0.1", 0))
listener.listen(1)
listener.settimeout(8)
port = listener.getsockname()[1]

with tempfile.TemporaryDirectory(prefix="irc-client-runtime-") as runtime:
    env = {
        "HOME": runtime,
        "XDG_CONFIG_HOME": str(pathlib.Path(runtime) / "config"),
        "XDG_CACHE_HOME": str(pathlib.Path(runtime) / "cache"),
        "XDG_DATA_HOME": str(pathlib.Path(runtime) / "data"),
        "XDG_STATE_HOME": str(pathlib.Path(runtime) / "state"),
        "PATH": pathlib.Path(sys.executable).parent.as_posix(),
        "LC_ALL": "C",
    }
    process = subprocess.Popen([str(client), str(port)], env=env,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, text=True)
    peer = None
    try:
        peer, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        peer.settimeout(8)
        received = b""
        while b"USER smoke-user" not in received:
            part = peer.recv(4096)
            assert part, received
            received += part
        assert b"NICK smoke-nick\r\n" in received, received
        peer.sendall(b":fake.local 001 smoke-nick :welcome\r\n")
        while b"PRIVMSG #smoke :client-payload\r\n" not in received:
            part = peer.recv(4096)
            assert part, received
            received += part
        peer.sendall(b":fake.local PRIVMSG #smoke :server-payload\r\n")
        stdout, stderr = process.communicate(timeout=8)
        assert process.returncode == 0, (process.returncode, stdout, stderr)
        assert "irc-client-loopback-ok" in stdout, (stdout, stderr)
    finally:
        if peer is not None:
            peer.close()
        listener.close()
        if process.poll() is None:
            process.kill()
            process.wait()
PY

find "$irc_out" -printf '%y %m %s %T@ %p\n' | sort > "$after"
cmp "$before" "$after"
if find "$irc_out" -type f -perm -u+w -print -quit | grep . >/dev/null; then
    echo "ocaml-irc-client-smoke: package output is writable" >&2
    exit 1
fi

echo "ocaml-irc-client smoke passed: installed findlib library, fresh XDG state, "\
     "loopback IRC exchange, namespace isolation, and immutable output"
