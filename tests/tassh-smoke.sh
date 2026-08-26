#!/bin/sh
# Exercise tassh entirely in a fresh user/network namespace and loopback mesh.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

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
    echo "usage: $0 [tassh-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    tassh_out=$1
else
    tassh_out=$($guix_bin build -L "$channel_dir" tassh)
fi

python_out=$(output_with_program bin/python3 python)
xclip_out=$(output_with_program bin/xclip xclip)
iproute_out=$(output_with_program sbin/ip iproute2)
util_linux_out=$(output_with_program bin/unshare util-linux)

test -x "$tassh_out/bin/tassh"
test -s "$tassh_out/share/doc/tassh/LICENSE"
test -d "$tassh_out/share/doc/tassh/third-party-licenses"
test "$(find "$tassh_out/share/doc/tassh/third-party-licenses" -type f | wc -l)" -ge 181
"$tassh_out/bin/tassh" --help >/dev/null
"$tassh_out/bin/tassh" daemon --help >/dev/null
"$tassh_out/bin/tassh" notify --help >/dev/null
"$tassh_out/bin/tassh" setup daemon --help >/dev/null

# A private network namespace permits the local protocol but no external
# network.  Each daemon has an isolated home/runtime tree; fake tailscale
# exposes different 127/8 endpoints without a tailnet.
exec "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    --mount --propagation private \
    "$python_out/bin/python3" - "$tassh_out" "$xclip_out/bin/xclip" \
    "$iproute_out/sbin/ip" "$util_linux_out/bin/mount" <<'PY'
import base64
import hashlib
import pathlib
import subprocess
import sys
import tempfile
import time


out, xclip, ip, mount = map(pathlib.Path, sys.argv[1:])


def digest_tree(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        digest.update(str(path.relative_to(root)).encode())
        if path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


def stop(process):
    if process and process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=8)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def run(binary, *args, env, timeout=10):
    return subprocess.run([str(binary), *args], env=env, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          timeout=timeout, check=False)


subprocess.run([str(mount), "-t", "tmpfs", "tmpfs", "/tmp"], check=True)
subprocess.run([str(ip), "link", "set", "lo", "up"], check=True)
links = subprocess.check_output([str(ip), "-o", "link", "show"], text=True)
assert [line.split(":", 2)[1].strip().split("@", 1)[0]
        for line in links.splitlines()] == ["lo"], links

with tempfile.TemporaryDirectory(prefix="tassh-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home_a, home_b = root / "home-a", root / "home-b"
    runtime_a, runtime_b = root / "runtime-a", root / "runtime-b"
    fake = root / "fake-bin"
    for directory in (home_a, home_b, runtime_a, runtime_b, fake):
        directory.mkdir()
    runtime_a.chmod(0o700)
    runtime_b.chmod(0o700)
    (fake / "tailscale").write_text(
        "#!/bin/sh\nprintf '%s\\n' \"$TASSH_TEST_IP\"\n", encoding="utf-8")
    (fake / "tailscale").chmod(0o755)

    def environment(home, runtime, address):
        return {
            "HOME": str(home), "XDG_RUNTIME_DIR": str(runtime),
            "PATH": str(fake), "TASSH_TEST_IP": address,
            "LC_ALL": "C.UTF-8",
        }

    env_a = environment(home_a, runtime_a, "127.0.0.1")
    env_b = environment(home_b, runtime_b, "127.0.0.2")
    before = digest_tree(out)
    daemon_a = daemon_b = helper = None
    try:
        # The wrapper supplies Xvfb, xclip, wl-clipboard, which, pgrep, and
        # hostname even though the caller PATH contains only fake tailscale.
        daemon_b = subprocess.Popen(
            [str(out / "bin/tassh"), "daemon", "--port", "19987"],
            env=env_b, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            start_new_session=True)
        socket = home_b / ".tassh/daemon.sock"
        deadline = time.monotonic() + 15
        while not socket.exists() and time.monotonic() < deadline:
            assert daemon_b.poll() is None, daemon_b.stderr.read().decode()
            time.sleep(.05)
        assert socket.exists(), daemon_b.stderr.read().decode()
        daemon_a = subprocess.Popen(
            [str(out / "bin/tassh"), "daemon", "--port", "19987"],
            env=env_a, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            start_new_session=True)
        socket = home_a / ".tassh/daemon.sock"
        deadline = time.monotonic() + 15
        while not socket.exists() and time.monotonic() < deadline:
            assert daemon_a.poll() is None, daemon_a.stderr.read().decode()
            time.sleep(.05)
        assert socket.exists(), daemon_a.stderr.read().decode()

        helper = subprocess.Popen(["sleep", "60"], start_new_session=True)
        notify = run(out / "bin/tassh", "notify", "--host", "127.0.0.2",
                     "--ssh-pid", str(helper.pid), env=env_a)
        assert notify.returncode == 0, notify.stdout

        deadline = time.monotonic() + 15
        status = ""
        while time.monotonic() < deadline:
            status = run(out / "bin/tassh", "status", env=env_a).stdout
            if "127.0.0.2 -- syncing (1 SSH session)" in status:
                break
            time.sleep(.1)
        assert "127.0.0.2 -- syncing (1 SSH session)" in status, status

        png = root / "frame.png"
        png.write_bytes(base64.b64decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4"
            "z8DwHwAFgAI/ScL9nAAAAABJRU5ErkJggg=="))
        injected = run(out / "bin/tassh", "inject", "--png-file", str(png),
                       env=env_a)
        assert injected.returncode == 0, injected.stdout
        display = (home_b / ".tassh/display").read_text().splitlines()[0].split("=", 1)[1]
        deadline = time.monotonic() + 10
        received = b""
        while time.monotonic() < deadline:
            result = subprocess.run(
                [str(xclip), "-selection", "clipboard", "-t", "image/png",
                 "-o", "-display", display],
                env={**env_b, "DISPLAY": display},
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
            received = result.stdout
            if hashlib.sha256(received).digest() == hashlib.sha256(png.read_bytes()).digest():
                break
            time.sleep(.1)
        assert hashlib.sha256(received).digest() == hashlib.sha256(png.read_bytes()).digest(), (
            result.returncode, result.stderr.decode("utf-8", "replace"),
            hashlib.sha256(received).hexdigest(), hashlib.sha256(png.read_bytes()).hexdigest())

        helper.terminate()
        helper.wait(timeout=8)
        helper = None
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            status = run(out / "bin/tassh", "status", env=env_a).stdout
            if "no active connections" in status:
                break
            time.sleep(.1)
        assert "no active connections" in status, status
        assert daemon_a.poll() is None and daemon_b.poll() is None
        assert digest_tree(out) == before
    finally:
        stop(helper)
        stop(daemon_a)
        stop(daemon_b)
PY
