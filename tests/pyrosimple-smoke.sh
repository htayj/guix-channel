#!/bin/sh
# Offline pyrosimple proof: every console entry point loads, and mktor, lstor
# and chtor create, verify and edit a deterministic local metainfo file inside
# an isolated HOME/XDG tree with networking unshared.  No rTorrent is used.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [pyrosimple-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts pyrosimple)
fi

find_program_output() {
    program=$1
    shift
    for candidate in $($guix_bin build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

unshare_bin=$(find_program_output bin/unshare util-linux)/bin/unshare
timeout_bin=$(find_program_output bin/timeout coreutils)/bin/timeout

upstream_commands='rtxmlrpc rtcontrol lstor chtor mktor pyrotorque pyroadmin'
for command in $upstream_commands; do
    test -x "$package_out/bin/$command"
done
test "$(readlink "$package_out/bin/pyrosimple")" = rtcontrol
test "$(ls "$package_out/bin" | grep -v '^\.' | LC_ALL=C sort | tr '\n' ' ')" = \
    'chtor lstor mktor pyroadmin pyrosimple pyrotorque rtcontrol rtxmlrpc '

# SHA-256 of the complete GPLv3 COPYING at upstream commit
# d24655a708059d322633e361e2e204983e51f491.
license_hash=$(sha256sum "$package_out/share/doc/pyrosimple/COPYING")
test "${license_hash%% *}" = \
    3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986

# The helper packages keep their own exact upstream notices.
python_path=$(sed -n 's/^export GUIX_PYTHONPATH="\([^"]*\)".*/\1/p' \
    "$package_out/bin/rtcontrol")
test -n "$python_path"
check_notice() {
    doc=$(printf '%s\n' "$python_path" | tr ':' '\n' | grep "/[a-z0-9]*-$1-[0-9]" |
        sed -n '1s,/lib/python[^/]*/site-packages$,,p')
    test -n "$doc"
    notice=$(find "$doc/share/doc" -type f -name "$2" | sed -n '1p')
    test -n "$notice"
    hash=$(sha256sum "$notice")
    test "${hash%% *}" = "$3"
}
check_notice python-bencode.py LICENSE \
    7ee2a68978755bb2ccddd5f904464776e679ede7c723030f10e070075d33a7e5
check_notice python-parsimonious LICENSE \
    09f1c8c9e941af3e584d59641ea9b87d83c0cb0fd007eb5ef391a7e2643c1a46
check_notice python-lockfile LICENSE \
    a26276d53dacb369641f31aa0fe37216028a0d93753f862ae206ce04f54b7b29

python_bin=$(sed -n '1s/^#!\([^ ]*\).*/\1/p' "$package_out/bin/.rtcontrol-real")
test -x "$python_bin"

output_fingerprint() {
    find "$package_out" -xdev -type f -exec sha256sum {} \; | LC_ALL=C sort | sha256sum
}
before_fingerprint=$(output_fingerprint)

scratch=$(mktemp -d "${TMPDIR:-/tmp}/pyrosimple-smoke.XXXXXXXX")
trap 'rm -rf "$scratch"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    "$scratch/work/payload" "$scratch/work/payload/docs" "$scratch/work/out" \
    "$scratch/work/edited"
: >"$scratch/pyro.toml"
chmod 444 "$scratch/pyro.toml"
printf 'pyrosimple offline metainfo fixture\n' >"$scratch/work/payload/README.txt"
"$python_bin" -c 'import sys; sys.stdout.buffer.write(bytes((i * 7 + 3) % 256 for i in range(70000)))' \
    >"$scratch/work/payload/docs/blob.bin"
# The same tree with one byte flipped in the second 32 KiB piece.
cp -R "$scratch/work/payload" "$scratch/work/corrupt"
printf X | dd of="$scratch/work/corrupt/docs/blob.bin" bs=1 seek=40000 \
    conv=notrunc 2>/dev/null

cat >"$scratch/verify.py" <<'EOF'
# Independent stdlib verifier: decode the metainfo, recompute every SHA-1
# piece from the payload files, and print the info hash.
import hashlib, pathlib, sys

def decode(data, i=0):
    c = data[i:i + 1]
    if c == b"i":
        end = data.index(b"e", i)
        return int(data[i + 1:end]), end + 1
    if c in (b"l", b"d"):
        i += 1
        items = []
        while data[i:i + 1] != b"e":
            value, i = decode(data, i)
            items.append(value)
        if c == b"l":
            return items, i + 1
        return dict(zip(items[::2], items[1::2])), i + 1
    colon = data.index(b":", i)
    length = int(data[i:colon])
    return data[colon + 1:colon + 1 + length], colon + 1 + length

raw = pathlib.Path(sys.argv[1]).read_bytes()
meta, end = decode(raw)
assert end == len(raw)
info = meta[b"info"]
start = raw.index(b"4:infod") + len(b"4:info")
_, info_end = decode(raw, start)
payload = pathlib.Path(sys.argv[2])
blob = b"".join((payload.joinpath(*[p.decode() for p in f[b"path"]])).read_bytes()
                for f in info[b"files"])
size = info[b"piece length"]
pieces = b"".join(hashlib.sha1(blob[o:o + size]).digest()
                  for o in range(0, len(blob), size))
assert pieces == info[b"pieces"], "piece hashes differ"
assert b"creation date" not in meta
print(hashlib.sha1(raw[start:info_end]).hexdigest().upper(), len(info[b"files"]),
      size, info[b"private"], meta[b"announce"].decode())
EOF

cat >"$scratch/run.sh" <<EOF
set -eu
for command in pyrosimple $upstream_commands; do
    "$package_out/bin/\$command" --help >"$scratch/help-\$command.out"
done
cd "$scratch/work"
"$package_out/bin/mktor" --no-date --private --piece-size 32K \
    --comment 'offline fixture' -o out/first.torrent payload \
    http://tracker.example.invalid/announce
"$package_out/bin/mktor" --no-date --private --piece-size 32K \
    --comment 'offline fixture' -o out/second.torrent payload \
    http://tracker.example.invalid/announce
"$package_out/bin/lstor" out/first.torrent >"$scratch/lstor.out"
"$package_out/bin/lstor" -q --check-data payload -o __hash__,info.name,comment \
    out/first.torrent >"$scratch/check.out"
status=0
"$package_out/bin/lstor" -q --check-data corrupt out/first.torrent \
    >"$scratch/corrupt.out" || status=\$?
echo "\$status" >"$scratch/corrupt.status"
"$package_out/bin/chtor" -q --comment 'edited offline' -o edited \
    out/first.torrent
status=0
"$package_out/bin/pyrotorque" --status >"$scratch/torque.out" 2>&1 || status=\$?
echo "\$status" >"$scratch/torque.status"
EOF

status=0
"$timeout_bin" 60 "$unshare_bin" --user --map-root-user --net --fork \
    env -i \
    PATH=/nonexistent \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" \
    PYRO_CONF="$scratch/pyro.toml" \
    LC_ALL=C.UTF-8 \
    TZ=UTC0 \
    "$(command -v sh)" "$scratch/run.sh" >"$scratch/stdout" 2>"$scratch/stderr" ||
    status=$?
if test "$status" -ne 0; then
    cat "$scratch/stderr" >&2
    echo "isolated pyrosimple run exited with status $status" >&2
    exit 1
fi

# Every command parsed its own options after importing its module graph.
# Guix's Python wrapper execs the hidden .NAME-real script, which argparse
# reports as the program name.
for command in $upstream_commands; do
    grep -q "^usage: \\.$command-real " "$scratch/help-$command.out"
    grep -qx "\\.$command-real 2\\.14\\.2 on Python 3\\.[0-9.]*" \
        "$scratch/help-$command.out"
done
grep -q -- '--repl' "$scratch/help-rtxmlrpc.out"
grep -q -- '--summary' "$scratch/help-rtcontrol.out"
grep -q -- '--check-data' "$scratch/help-lstor.out"
grep -q -- '--make-private' "$scratch/help-chtor.out"
grep -q -- '--no-date' "$scratch/help-mktor.out"
grep -q -- '--pid-file' "$scratch/help-pyrotorque.out"
grep -q '{config,backfill}' "$scratch/help-pyroadmin.out"
cmp "$scratch/help-pyrosimple.out" "$scratch/help-rtcontrol.out"

# Deterministic metainfo: identical bytes twice, pinned digest, and pieces that
# an independent decoder recomputes from the payload.
cmp "$scratch/work/out/first.torrent" "$scratch/work/out/second.torrent"
torrent_hash=$(sha256sum "$scratch/work/out/first.torrent")
torrent_hash=${torrent_hash%% *}
test "$torrent_hash" = \
    a98cb551710de556e1ba6c9119bd4a006468caffbcc0cdf5de435a9c89cbf2cc
verified=$("$python_bin" "$scratch/verify.py" "$scratch/work/out/first.torrent" \
    "$scratch/work/payload")
set -- $verified
info_hash=$1
test "$info_hash" = DBE098492C45D8C432420FE3B438CDFF642C32BC
test "$2 $3 $4 $5" = '2 32768 1 http://tracker.example.invalid/announce'
grep -qx "HASH $info_hash" "$scratch/lstor.out"
grep -qx 'NAME payload' "$scratch/lstor.out"
grep -qx 'PRV  YES (DHT/PEX disabled)' "$scratch/lstor.out"
grep -qx 'TIME N/A' "$scratch/lstor.out"
grep -qx 'REM  offline fixture' "$scratch/lstor.out"
test "$(cat "$scratch/check.out")" = "$info_hash	payload	offline fixture"
test "$(cat "$scratch/corrupt.status")" -eq 65
grep -q 'did not hash check: Piece #1: Hashes differ' "$scratch/corrupt.out"

# chtor edits only the outer comment, so the info hash is unchanged.
edited=$("$python_bin" "$scratch/verify.py" "$scratch/work/edited/first.torrent" \
    "$scratch/work/payload")
test "${edited%% *}" = "$info_hash"
grep -q '7:comment14:edited offline' "$scratch/work/edited/first.torrent"
# Writing to -o left the source metafile byte-identical.
cmp "$scratch/work/out/first.torrent" "$scratch/work/out/second.torrent"

# pyrotorque's lockfile-backed PID check reports no daemon without starting one.
test "$(cat "$scratch/torque.status")" -eq 1
grep -q 'No pyrotorque process found' "$scratch/torque.out"

# Only the declared workspace artefacts exist; no state escaped elsewhere.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"
test "$(cd "$scratch/work" && find . -type f | LC_ALL=C sort | tr '\n' ' ')" = \
    './corrupt/README.txt ./corrupt/docs/blob.bin ./edited/first.torrent ./out/first.torrent ./out/second.torrent ./payload/README.txt ./payload/docs/blob.bin '
test ! -s "$scratch/stdout"
test ! -s "$scratch/stderr"
after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"

# Evidence runs may ask for the verbatim stdout of the isolated
# `lstor out/first.torrent` call above, taken from the deterministic metafile
# that mktor just created.  Copy it only after every check has passed; normal
# package tests leave no trace.
if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    test -s "$scratch/lstor.out"
    test "$(wc -c <"$scratch/lstor.out")" -le 4096
    cp "$scratch/lstor.out" "$GOOCASTLE_RUNTIME_RAW_CAPTURE"
fi

printf 'pyrosimple: 8 commands loaded; metainfo %s info-hash %s\n' \
    "$torrent_hash" "$info_hash"
