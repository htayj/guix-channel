#!/bin/sh
# Real external Node and Chromium consumers of the installed LiteGraph library.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -ne 2; then
    echo "usage: GUIX=guix sh $0 OUTPUT EVIDENCE" >&2
    exit 64
fi
out=$1
evidence=$2
case "$out:$evidence" in
    /*:/*) ;;
    *) echo 'OUTPUT and EVIDENCE must be absolute paths' >&2; exit 64 ;;
esac
module=$out/lib/node_modules/litegraph.js

# Internal stage inherits only explicitly resolved store tools.  Never build in it.
if test "${LITEGRAPH_ISOLATED:-}" = 1; then
    test "$("$COREUTILS/bin/id" -u)" = "$LITEGRAPH_EXPECTED_UID"
    test "$("$COREUTILS/bin/id" -g)" = "$LITEGRAPH_EXPECTED_GID"
    # Restricted util-linux mount refuses a non-root UID; use the capability-backed syscall.
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
    "$NODE/bin/node" "$channel_dir/guix/tay/packages/files/litegraph-engine.cjs" \
        "$module" "$evidence"
    "$CDP_NODE/bin/node" "$channel_dir/tests/litegraph-browser.mjs" \
        "$CHROMIUM/bin/chromium" "$module" \
        "$channel_dir/tests/litegraph-consumer.html" "$evidence" "$TMPDIR"
    for label in source minified; do
        info=$("$IMAGEMAGICK/bin/identify" -format '%m %w %h %k' "$evidence/$label.png")
        set -- $info
        test "$1" = PNG
        test "$2" -eq 1200
        test "$3" -eq 850
        test "$4" -ge 16
        geometry=$("$COREUTILS/bin/cat" "$evidence/$label.geometry")
        colors=$("$IMAGEMAGICK/bin/convert" "$evidence/$label.png" \
            -crop "$geometry" +repage -format '%k' info:)
        test "$colors" -ge 16
    done
    exit 0
fi

for asset in package.json build/litegraph.js build/litegraph.min.js \
    src/litegraph-editor.js src/litegraph.d.ts css/litegraph.css css/litegraph-editor.css \
    editor/imgs/grid.png editor/imgs/icon-play.png THIRD-PARTY-NOTICES LICENSE; do
    test -s "$module/$asset"
done
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
    for output in $candidates; do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "litegraph consumer: dependency lacks $program: $*" >&2
    return 1
}
# Resolve all dependencies before user/network/mount/PID namespaces exist.
node_out=$(find_output bin/node -e '(@ (gnu packages node) node-lts)') || exit 1
# The CDP runner reuses trial-by-combat's proven Node with built-in WebSocket.
cdp_node_out=$(find_output bin/node node) || exit 1
coreutils_out=$(find_output bin/timeout coreutils) || exit 1
util_linux_out=$(find_output bin/unshare util-linux) || exit 1
shell_out=$(find_output bin/sh bash-minimal) || exit 1
python_out=$(find_output bin/python3 python) || exit 1
iproute_out=$(find_output sbin/ip iproute2) || exit 1
ip_bin=$iproute_out/sbin/ip
chromium_out=$(find_output bin/chromium ungoogled-chromium) || exit 1
imagemagick_out=$(find_output bin/identify imagemagick) || exit 1
if ! "$util_linux_out/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --kill-child --fork \
    "$coreutils_out/bin/true"; then
    echo 'litegraph smoke requires user, mount, network and PID namespaces' >&2
    exit 77
fi
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/litegraph-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" -p "$evidence"
expected_uid=$("$coreutils_out/bin/id" -u)
expected_gid=$("$coreutils_out/bin/id" -g)
before=$("$guix_bin" hash -S nar "$out")
status=0
"$coreutils_out/bin/env" -i LC_ALL=C.UTF-8 PATH="$coreutils_out/bin" \
    LITEGRAPH_ISOLATED=1 LITEGRAPH_EXPECTED_UID="$expected_uid" \
    LITEGRAPH_EXPECTED_GID="$expected_gid" COREUTILS="$coreutils_out" \
    PYTHON="$python_out" NODE="$node_out" CDP_NODE="$cdp_node_out" IP="$ip_bin" \
    CHROMIUM="$chromium_out" IMAGEMAGICK="$imagemagick_out" \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
    XDG_DATA_HOME="$scratch/data" XDG_RUNTIME_DIR="$scratch/runtime" TMPDIR="$scratch" \
    "$coreutils_out/bin/timeout" --kill-after=10 180 \
    "$util_linux_out/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --kill-child --fork \
    "$shell_out/bin/sh" "$channel_dir/tests/litegraph-smoke.sh" "$out" "$evidence" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
"$node_out/bin/node" --input-type=module - "$evidence" "$status" "$before" "$after" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
const [root, status, before, after] = process.argv.slice(2);
const filename = path.join(root, 'evidence.json');
const record = fs.existsSync(filename) ? JSON.parse(fs.readFileSync(filename, 'utf8')) :
    { status: 'failed', error: 'runner ended without final evidence' };
Object.assign(record, { exit_status: Number(status), output_nar_before: before,
    output_nar_after: after, output_unchanged: before === after });
if (Number(status) || before !== after) record.status = 'failed';
fs.writeFileSync(filename, `${JSON.stringify(record, null, 2)}\n`);
JS
if test "$status" -ne 0 || test "$before" != "$after"; then
    echo "litegraph external proof failed (status $status); evidence: $evidence" >&2
    exit 1
fi
printf 'LITEGRAPH_RUNTIME_OK\n'
printf 'litegraph offline external graph/canvas proof passed; evidence: %s\n' "$evidence"
