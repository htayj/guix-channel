#!/bin/sh
# Consume a prebuilt FarmingRL output; never build or modify the game under test.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -ne 2; then
    echo "usage: GUIX=guix sh $0 /gnu/store/OUTPUT /absolute/FRESH-EVIDENCE" >&2
    exit 64
fi
out=$1
evidence=$2
case "$out" in /gnu/store/*) ;; *) echo 'OUTPUT must be a prebuilt store output' >&2; exit 64 ;; esac
case "$evidence" in /*) ;; *) echo 'EVIDENCE must be absolute' >&2; exit 64 ;; esac

# Only the already-resolved observers and the installed launcher run in here.
if test "${FARMINGRL_ISOLATED:-}" = 1; then
    test "$("$COREUTILS/bin/id" -u)" = "$FARMINGRL_EXPECTED_UID"
    test "$("$COREUTILS/bin/id" -g)" = "$FARMINGRL_EXPECTED_GID"
    # mount(8) rejects a nonzero UID even with namespace capabilities.
    "$PYTHON/bin/python3" -B -c '
import ctypes, os
libc = ctypes.CDLL(None, use_errno=True)
libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                       ctypes.c_ulong, ctypes.c_void_p]
for flags in (4096, 4096 | 32 | 1 | 2 | 4):
    if libc.mount(b"/gnu/store", b"/gnu/store", None, flags, None):
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), "/gnu/store")
'
    "$IP" link set lo up
    "$COREUTILS/bin/mkdir" -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" \
        "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_RUNTIME_DIR"
    "$COREUTILS/bin/chmod" 700 "$XDG_RUNTIME_DIR"
    "$IP" -details -json address show >"$evidence/interfaces.json"
    exec "$NODE/bin/node" "$channel_dir/tests/farmingrl-browser.mjs" \
        "$out" "$CHROMIUM" "$evidence"
fi

test -x "$out/bin/farmingrl"
for asset in index.html game.js rot.js; do test -s "$out/share/farmingrl/$asset"; done
for asset in LICENSE README.md; do test -s "$out/share/doc/farmingrl/$asset"; done
if test -e "$evidence"; then
    echo 'EVIDENCE must be a fresh, nonexistent directory' >&2
    exit 64
fi
find_output ()
{
    program=$1
    shift
    candidates=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 "$@") || return 1
    for candidate in $candidates; do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "farmingrl observer dependency lacks $program: $*" >&2
    return 1
}
# Resolution is deliberately outside every isolation namespace; the target is
# supplied by the caller and is never an argument to guix build.
node_out=$(find_output bin/node node) || exit 1
coreutils_out=$(find_output bin/timeout coreutils) || exit 1
util_linux_out=$(find_output bin/unshare util-linux) || exit 1
shell_out=$(find_output bin/sh bash-minimal) || exit 1
python_out=$(find_output bin/python3 python) || exit 1
iproute_out=$(find_output sbin/ip iproute2) || exit 1
chromium_out=$(find_output bin/chromium ungoogled-chromium) || exit 1
dbus_out=$(find_output bin/dbus-daemon dbus) || exit 1
"$coreutils_out/bin/mkdir" -p "$evidence"
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/farmingrl-native.XXXXXX")
cleanup ()
{
    cleanup_status=$?
    trap - EXIT HUP INT TERM
    if test -d "$scratch"; then
        # Never release an unmeasured tree: preserve it if its size cannot be
        # recorded, and remove only the exact path allocated by this run.
        if "$coreutils_out/bin/du" -sb -- "$scratch" >>"$evidence/scratch-cleanup.txt"; then
            if "$coreutils_out/bin/rm" -rf -- "$scratch"; then
                printf 'removed exact scratch tree: %s\n' "$scratch" >>"$evidence/scratch-cleanup.txt"
            else
                printf 'removal failed; retained path: %s\n' "$scratch" >>"$evidence/scratch-cleanup.txt"
                if test "$cleanup_status" -eq 0; then cleanup_status=1; fi
            fi
        else
            printf 'measurement failed; retained path: %s\n' "$scratch" >>"$evidence/scratch-cleanup.txt"
            if test "$cleanup_status" -eq 0; then cleanup_status=1; fi
        fi
    fi
    exit "$cleanup_status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
expected_uid=$("$coreutils_out/bin/id" -u)
expected_gid=$("$coreutils_out/bin/id" -g)
user_ns=$("$coreutils_out/bin/readlink" /proc/self/ns/user)
mount_ns=$("$coreutils_out/bin/readlink" /proc/self/ns/mnt)
net_ns=$("$coreutils_out/bin/readlink" /proc/self/ns/net)
pid_ns=$("$coreutils_out/bin/readlink" /proc/self/ns/pid)
before=$("$guix_bin" hash -S nar "$out")
status=0
"$coreutils_out/bin/env" -i LC_ALL=C.UTF-8 PATH="$coreutils_out/bin" \
    FARMINGRL_ISOLATED=1 FARMINGRL_EXPECTED_UID="$expected_uid" \
    FARMINGRL_EXPECTED_GID="$expected_gid" FARMINGRL_HOST_USER_NS="$user_ns" \
    FARMINGRL_HOST_MNT_NS="$mount_ns" FARMINGRL_HOST_NET_NS="$net_ns" \
    FARMINGRL_HOST_PID_NS="$pid_ns" COREUTILS="$coreutils_out" \
    PYTHON="$python_out" NODE="$node_out" IP="$iproute_out/sbin/ip" \
    CHROMIUM="$chromium_out" DBUS="$dbus_out" HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
    XDG_DATA_HOME="$scratch/data" XDG_RUNTIME_DIR="$scratch/runtime" TMPDIR="$scratch" \
    "$coreutils_out/bin/timeout" --kill-after=10 150 \
    "$util_linux_out/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --mount-proc --net --pid --kill-child --fork \
    "$shell_out/bin/sh" "$channel_dir/tests/farmingrl-smoke.sh" "$out" "$evidence" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
"$node_out/bin/node" --input-type=module - "$evidence" "$status" "$before" "$after" "$out" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
const [root, status, before, after, output] = process.argv.slice(2);
const filename = path.join(root, 'evidence.json');
const record = fs.existsSync(filename) ? JSON.parse(fs.readFileSync(filename, 'utf8')) :
    { status: 'failed', failure_class: Number(status) === 124 ? 'isolation-or-observer-timeout' :
        'isolation-or-observer-startup', error: 'runner ended without final evidence; see driver.stderr' };
Object.assign(record, { output, exit_status: Number(status), output_nar_before: before,
    output_nar_after: after, output_unchanged: before === after });
if (Number(status) || before !== after) record.status = 'failed';
if (before !== after) record.failure_class = 'store-output-mutated';
fs.writeFileSync(filename, `${JSON.stringify(record, null, 2)}\n`);
JS
if test "$status" -ne 0 || test "$before" != "$after"; then
    echo "farmingrl external proof failed (status $status); evidence: $evidence" >&2
    exit 1
fi
printf 'FARMINGRL_RUNTIME_OK\n'
printf 'FarmingRL native keyboard, visible canvas and natural combat proof: %s\n' "$evidence"
