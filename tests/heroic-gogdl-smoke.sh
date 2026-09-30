#!/bin/sh
# Credential-free CLI and local manifest/file/compression proof for Heroic GOGDL.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [heroic-gogdl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    gogdl_out=$1
else
    gogdl_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts heroic-gogdl)
fi

find_output() {
    program=$1
    package=$2
    for candidate in $($guix_bin build --no-grafts --no-substitutes "$package"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

python_out=$(find_output bin/python3 python)
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
find=$findutils_out/bin/find
grep=$grep_out/bin/grep
test -x "$gogdl_out/bin/gogdl"

parent_license=$gogdl_out/share/doc/heroic-gogdl/LICENSE
xdelta_license=$gogdl_out/share/doc/heroic-gogdl/xdelta3-LICENSE
test -f "$parent_license"
test -f "$xdelta_license"
"$grep" -q 'GNU GENERAL PUBLIC LICENSE' "$parent_license"
"$grep" -q 'Apache License' "$xdelta_license"

# Use the installed closure, not host Python modules.  Local module operations
# import requests too, although none of the operations below uses a session.
site_packages=
for reference in $($guix_bin gc --requisites "$gogdl_out"); do
    if test -d "$reference/lib"; then
        for directory in $("$find" "$reference/lib" -type d -name site-packages); do
            site_packages=${site_packages:+$site_packages:}$directory
        done
    fi
done
test -n "$site_packages"

# An installed Guix output must be immutable.  Hashing before and after also
# catches an accidental write that a permissive test environment might allow.
test ! -w "$gogdl_out"
before_digest=$($guix_bin hash -r "$gogdl_out")

# Fail closed: module code cannot reach a live service even if upstream changes.
if ! "$coreutils_out/bin/timeout" --kill-after=2 5 \
    "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
    "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'heroic-gogdl smoke requires an unprivileged network namespace' >&2
    exit 77
fi

temporary=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/heroic-gogdl-smoke.XXXXXXXX")
cleanup() {
    "$coreutils_out/bin/rm" -rf "$temporary"
}
trap cleanup EXIT HUP INT TERM

home=$temporary/home
xdg_config=$temporary/xdg-config
gogdl_config=$temporary/gogdl-config
work=$temporary/work
"$coreutils_out/bin/mkdir" "$home" "$xdg_config" "$gogdl_config" "$work" \
    "$temporary/data" "$temporary/cache" "$temporary/state" \
    "$temporary/runtime" "$temporary/tmp"
# This destination is evidence only; no external executor is invoked.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$temporary/cli.raw}

cd "$work"
"$coreutils_out/bin/timeout" --kill-after=5 60 \
    "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
    "$coreutils_out/bin/env" -i \
    HOME="$home" XDG_CONFIG_HOME="$xdg_config" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
    TMPDIR="$temporary/tmp" GOGDL_CONFIG_PATH="$gogdl_config" \
    GUIX_PYTHONPATH="$site_packages" PATH="$gogdl_out/bin:$python_out/bin" \
    LC_ALL=C.UTF-8 TZ=UTC PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$python_out/bin/python3" - <<'PY'
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess

from gogdl.dl import dl_utils
from gogdl.dl.objects import v2
from gogdl.saves import SyncFile
import gogdl_xdelta3

raw = Path(os.environ['GOOCASTLE_RUNTIME_RAW_CAPTURE'])
raw.write_bytes(b'')

def cli(*args, status=0):
    result = subprocess.run(['gogdl', *args], capture_output=True, timeout=8)
    # Save the actual executable's bytes even on failure, before asserting.
    with raw.open('ab') as capture:
        capture.write(result.stdout)
        capture.write(result.stderr)
    assert result.returncode == status, (args, result.returncode, result.stderr)
    return result.stdout.decode('utf-8')

assert cli('--version').strip() == '1.3.0'
help_output = cli('--help')
assert all(command in help_output for command in ('download', 'auth', 'import'))
assert json.loads(cli('lang-match', 'en')) == {
    'code': 'en-US', 'name': 'English', 'native_name': 'English',
    'deprecated_codes': ['en'],
}
assert json.loads(cli('lang-match', 'not-a-language')) == {}
# A missing required path must be rejected by the installed parser, not by an
# API call.  This also exercises the actual subcommand parser rather than a
# synthetic sys.argv assignment.
assert cli('import', status=2) == ''

# Synthetic installer metadata, not a game or an account: this Linux import
# branch reads only gameinfo and must produce usable metadata without GOG.
fixture = Path('fixture')
fixture.mkdir()
gameinfo = 'Offline fixture\n1.2.3\nunused\nen-US\nfixture-id\nunused\nfixture-build\n'
(fixture / 'gameinfo').write_text(gameinfo, encoding='utf-8')
assert json.loads(cli('import', str(fixture.resolve()))) == {
    'appName': 'fixture-id', 'buildId': 'fixture-build',
    'title': 'Offline fixture', 'tasks': None, 'installedLanguage': 'en-US',
    'dlcs': [], 'platform': 'linux', 'versionName': '1.2.3',
}
assert (fixture / 'gameinfo').read_text(encoding='utf-8') == gameinfo

# Local manifest selection and accounting.  The compressed and on-disk sizes
# differ, and the unselected DLC must not leak into the base product totals.
meta = {
    'version': 2, 'baseProductId': 'base', 'installDirectory': 'fixture',
    'HGLInstallLanguage': 'en-US', 'HGLdlcs': [{'id': 'selected-dlc'}],
    'depots': [
        {'productId': 'base', 'languages': ['*'], 'manifest': 'neutral',
         'compressedSize': 11, 'size': 21},
        {'productId': 'base', 'languages': ['en'], 'manifest': 'english',
         'compressedSize': 13, 'size': 31},
        {'productId': 'base', 'languages': ['fr-FR'], 'manifest': 'french',
         'compressedSize': 17, 'size': 41},
        {'productId': 'selected-dlc', 'languages': ['*'], 'manifest': 'dlc',
         'compressedSize': 19, 'size': 51},
        {'productId': 'excluded-dlc', 'languages': ['*'], 'manifest': 'excluded',
         'compressedSize': 999, 'size': 9999},
    ],
}
manifest_path = fixture / 'manifest.json'
manifest_path.write_text(json.dumps(meta), encoding='utf-8')
manifest = dl_utils.create_manifest_class(json.loads(manifest_path.read_text()), None)
assert [depot.manifest for depot in manifest.depots] == ['neutral', 'english', 'dlc']
sizes = manifest.calculate_download_size()
assert sizes == {
    'base': {'*': {'download_size': 11, 'disk_size': 21},
             'en-US': {'download_size': 13, 'disk_size': 31},
             'fr-FR': {'download_size': 17, 'disk_size': 41}},
    'selected-dlc': {'*': {'download_size': 19, 'disk_size': 51}},
}
assert set(manifest.list_languages()) == {'en-US', 'fr-FR'}
restored = dl_utils.create_manifest_class(json.loads(manifest.serialize_to_json()), None)
assert restored.calculate_download_size() == sizes

# Chunk reuse is a consumer-visible patch decision: a reordered old chunk
# must refer to its old byte offset while a novel chunk must not claim reuse.
old = v2.DepotFile({'path': 'data.bin', 'chunks': [
    {'md5': 'a', 'size': 3}, {'md5': 'b', 'size': 5}]}, 'base')
new = v2.DepotFile({'path': 'data.bin', 'chunks': [
    {'md5': 'b', 'size': 5}, {'md5': 'c', 'size': 7}]}, 'base')
diff = v2.FileDiff.compare(new, old)
assert diff.disk_size_diff == 4
assert diff.file.chunks[0]['old_offset'] == 3
assert 'old_offset' not in diff.file.chunks[1]

# Cross the checksum reader's 16 KiB boundary.  Resolve a mismatched-case path
# against an actual local file, not string-only path normalization.
directory = fixture / 'MixedCase'
directory.mkdir()
payload = bytes(range(256)) * 129 + b'\x00offline\xff'
local_file = directory / 'Save.BIN'
local_file.write_bytes(payload)
assert dl_utils.get_case_insensitive_name(str(fixture.resolve() / 'mixedcase' / 'save.bin')) == str(local_file.resolve())
assert dl_utils.calculate_sum(local_file, hashlib.md5) == hashlib.md5(payload).hexdigest()

# SyncFile computes its checksum over deterministic gzip bytes, not the raw
# file.  No cloud manager, sync operation, authentication or request is used.
os.utime(local_file, (1700000000, 1700000000))
sync_file = SyncFile(r'MixedCase\Save.BIN', str(local_file))
sync_file.get_file_metadata()
compressed_md5 = hashlib.md5(gzip.compress(payload, 6, mtime=0)).hexdigest()
assert sync_file.relative_path == 'MixedCase/Save.BIN'
assert sync_file.md5 == compressed_md5
assert sync_file.md5 != hashlib.md5(payload).hexdigest()
assert sync_file.update_time == '2023-11-14T22:13:20+00:00'
assert sync_file.update_ts == 1700000000
assert local_file.read_bytes() == payload

# RFC 3284 default-table VCDIFF: COPY five source bytes at address zero, then
# ADD seven literal bytes.  This exercises the installed C decoder on real
# files instead of treating an import or ABI suffix as proof of patching.
source = fixture / 'source.bin'
patch = fixture / 'update.vcdiff'
target = fixture / 'target.bin'
source.write_bytes(b'hello')
patch.write_bytes(bytes.fromhex('d6 c3 c4 00 00 01 05 00 0f 0c 00 07 02 01')
                  + b' world\n' + bytes.fromhex('15 08 00'))
from queue import SimpleQueue
gogdl_xdelta3.patch(str(source), str(patch), str(target), SimpleQueue())
assert target.read_bytes() == b'hello world\n'
assert source.read_bytes() == b'hello'

print(json.dumps({'manifest_sizes': sizes, 'compressed_save_md5': sync_file.md5}, sort_keys=True))
PY

test -s "$raw"
"$coreutils_out/bin/cat" "$raw"
test -z "$("$find" "$home" "$xdg_config" "$gogdl_config" "$temporary/data" \
    "$temporary/cache" "$temporary/state" "$temporary/runtime" "$temporary/tmp" \
    -mindepth 1 -print -quit)"
after_digest=$($guix_bin hash -r "$gogdl_out")
test "$before_digest" = "$after_digest"
test ! -w "$gogdl_out"
