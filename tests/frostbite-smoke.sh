#!/bin/sh
# Exercise Frostbite's packaged GUI, Ruby integration, and XDG state boundary.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

# Some Guix packages (notably util-linux) have several outputs.  Pick the
# one that actually provides the executable rather than assuming the first.
output_with_program() {
    program=$1
    shift
    for output in $($guix_bin build "$@"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix outputs for $*" >&2
    return 1
}

if test "$#" -gt 1; then
    echo "usage: $0 [frostbite-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    frostbite_out=$1
else
    frostbite_out=$($guix_bin build -L "$channel_dir" -e \
        '(begin (use-modules (tay packages frostbite)) frostbite)')
fi

python_out=$(output_with_program bin/python3 python)
xorg_server_out=$(output_with_program bin/Xvfb xorg-server)
iproute_out=$(output_with_program sbin/ip iproute2)
util_linux_out=$(output_with_program bin/unshare util-linux)
ruby_out=$(output_with_program bin/ruby ruby)
desktop_file_utils_out=$(output_with_program bin/desktop-file-validate desktop-file-utils)

test -x "$frostbite_out/bin/frostbite"
test -f "$frostbite_out/share/frostbite/config/client.ini"
test -f "$frostbite_out/share/frostbite/log.ini"
test -f "$frostbite_out/share/frostbite/scripts/lib/main.rb"
test -f "$frostbite_out/share/frostbite/security/auth-service.pem"
test -f "$frostbite_out/share/applications/frostbite.desktop"
test -f "$frostbite_out/share/icons/hicolor/64x64/apps/frostbite.png"
test -f "$frostbite_out/share/doc/frostbite/README.md"
test -f "$frostbite_out/share/doc/frostbite/licenses/LICENSE-2.0.txt"
test -f "$frostbite_out/share/doc/frostbite/licenses/NOTICE.txt"
test -f "$frostbite_out/share/doc/frostbite/licenses/qtlocalpeer.cpp"
test -f "$frostbite_out/share/doc/frostbite/licenses/qcleanlooksstyle.cpp"
"$desktop_file_utils_out/bin/desktop-file-validate" \
    "$frostbite_out/share/applications/frostbite.desktop"

# A user+network namespace makes loopback the only network interface.  The
# fake MUD and Frostbite's Ruby API are both deliberately local to this test.
exec "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$python_out/bin/python3" - "$frostbite_out" "$xorg_server_out/bin/Xvfb" \
    "$iproute_out/sbin/ip" "$ruby_out/bin/ruby" <<'PY'
import hashlib
import os
import pathlib
import select
import signal
import socket
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb, ip, ruby = sys.argv[2:]


def digest_tree(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        digest.update(str(path.relative_to(root)).encode())
        if path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=8)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=8)


with tempfile.TemporaryDirectory(prefix="frostbite-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home, config, data, cache, runtime, work = [root / name for name in
        ("home", "config", "data", "cache", "runtime", "work")]
    for directory in (home, config, data, cache, runtime, work):
        directory.mkdir()
    runtime.chmod(0o700)
    environment = os.environ.copy()
    environment.update({
        "HOME": str(home), "XDG_CONFIG_HOME": str(config),
        "XDG_DATA_HOME": str(data), "XDG_CACHE_HOME": str(cache),
        "XDG_RUNTIME_DIR": str(runtime), "DISPLAY": ":95",
        "QT_QPA_PLATFORM": "xcb", "LIBGL_ALWAYS_SOFTWARE": "1",
        "LC_ALL": "C.UTF-8",
    })

    subprocess.run([ip, "link", "set", "lo", "up"], check=True)
    links = subprocess.check_output([ip, "-o", "link", "show"], text=True)
    assert [line.split(":", 2)[1].strip().split("@", 1)[0]
            for line in links.splitlines()] == ["lo"], links

    mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    mud.bind(("127.0.0.1", 0)); mud.listen(1); mud.setblocking(False)
    xvfb_process = subprocess.Popen(
        [xvfb, ":95", "-screen", "0", "1024x768x24", "-nolisten", "tcp"],
        cwd=work, env=environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        start_new_session=True)
    client = None
    peer = None
    try:
        time.sleep(.5)
        assert xvfb_process.poll() is None, xvfb_process.stderr.read().decode()
        before = digest_tree(out)
        client = subprocess.Popen(
            [str(out / "bin" / "frostbite"), "--port=%d" % mud.getsockname()[1]],
            cwd=work, env=environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            start_new_session=True)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            if client.poll() is not None:
                raise RuntimeError(client.stderr.read().decode("utf-8", "replace"))
            readable, _, _ = select.select([mud], [], [], .1)
            if readable:
                peer, address = mud.accept()
                break
        assert peer is not None, "Frostbite did not reach the loopback MUD listener"
        assert address[0] == "127.0.0.1", address
        peer.sendall(b"<pushBold/>FROSTBITE LOOPBACK SMOKE<popBold/>\r\n")

        deadline = time.monotonic() + 10
        client_ini = api_ini = None
        while time.monotonic() < deadline:
            clients = list(config.rglob("client.ini"))
            apis = list(config.rglob("api.ini"))
            if clients and apis:
                client_ini, api_ini = clients[0], apis[0]
                break
            if client.poll() is not None:
                raise RuntimeError(client.stderr.read().decode("utf-8", "replace"))
            time.sleep(.1)
        assert client_ini and api_ini, list(root.rglob("*"))
        assert "type=H" in client_ini.read_text(encoding="utf-8")
        assert list(data.rglob("profiles/frostbite/general.ini")), list(data.rglob("*"))

        # This uses the packaged Ruby entry point against Frostbite's live,
        # loopback-only API.  Its output is the observable script protocol.
        ruby_script = work / "ruby-smoke.rb"
        ruby_script.write_text('echo "RUBY-SMOKE"\n', encoding="utf-8")
        ruby_environment = dict(environment)
        ruby_environment["FROSTBITE_API_SETTINGS"] = str(api_ini)
        ruby_run = subprocess.run(
            [ruby, str(out / "share" / "frostbite" / "scripts" / "lib" / "main.rb"),
             str(ruby_script)],
            cwd=work, env=ruby_environment, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, text=True, timeout=15)
        assert ruby_run.returncode == 0, ruby_run.stderr
        assert "echo#RUBY-SMOKE" in ruby_run.stdout, ruby_run.stdout
        assert client.poll() is None, client.stderr.read().decode("utf-8", "replace")
        assert digest_tree(out) == before, "Frostbite modified its Guix output"
        assert not any(path.is_relative_to(out) for path in root.rglob("*"))
    finally:
        if peer is not None:
            peer.close()
        mud.close()
        if client is not None:
            stop(client)
        stop(xvfb_process)

print("frostbite loopback smoke passed: Xvfb, XDG state, Ruby API, no store writes")
PY
