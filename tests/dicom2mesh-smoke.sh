#!/bin/sh
# Offline smoke test for the installed dicom2mesh command-line program.
#
# The fixture is three 8x8 16-bit grayscale PNG slices generated from source
# in a private scratch tree: the outer slices are empty and the middle slice
# holds a centred 4x4 block of value 2000.  With the default iso value of 400
# and unit spacing, marching cubes must produce one closed box whose bounds
# follow from linear interpolation: x and y in [1.2, 5.8], z in [0.2, 1.8].
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [dicom2mesh-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    d2m_out=$1
else
    d2m_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts dicom2mesh)
fi

find_program_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

util_linux_out=$(find_program_output bin/unshare util-linux)
coreutils_out=$(find_program_output bin/timeout coreutils)
python_out=$(find_program_output bin/python3 python)
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'dicom2mesh smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# Only the command-line program is built; the Qt front end stays disabled.
test -f "$d2m_out/bin/dicom2mesh"
test -x "$d2m_out/bin/dicom2mesh"
test ! -e "$d2m_out/bin/dicom2meshGUI"

# The build links against the upstream Guix VTK package, not a host library.
$guix_bin gc --references "$d2m_out" | grep -E '^/gnu/store/[^/]+-vtk-9\.[0-9.]+$' >/dev/null

# Upstream's MIT permission notice ships with the package.
license=$d2m_out/share/doc/dicom2mesh-0.823-0.c552b4f/LICENSE.md
test -s "$license"
grep -F 'Copyright (c) 2017 Adrian Schneider, AOT AG' "$license" >/dev/null
grep -F 'Permission is hereby granted, free of charge' "$license" >/dev/null

# The NAR hash covers installed files, modes, and symlinks.  It must be
# identical after the program has run.
before=$($guix_bin hash -S nar "$d2m_out")
test -z "$(find "$d2m_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d "${TMPDIR:-/tmp}/dicom2mesh-smoke.XXXXXXXX")
trap 'rm -rf "$scratch"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work"

"$python_out/bin/python3" - "$scratch/work" <<'PY'
import os
import struct
import sys
import zlib

work = sys.argv[1]


def chunk(kind, payload):
    return (struct.pack(">I", len(payload)) + kind + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF))


def write_slice(name, filled, size=8, margin=2, value=2000):
    raw = bytearray()
    for y in range(size):
        raw.append(0)  # no scanline filter
        for x in range(size):
            inside = (filled and margin <= x < size - margin
                      and margin <= y < size - margin)
            raw += struct.pack(">H", value if inside else 0)
    header = struct.pack(">IIBBBBB", size, size, 16, 0, 0, 0, 0)
    with open(os.path.join(work, name), "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
                     + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
                     + chunk(b"IEND", b""))


write_slice("slice1.png", False)
write_slice("slice2.png", True)
write_slice("slice3.png", False)
PY

# Run the installed program without inherited environment or network, with
# every HOME/XDG location inside the disposable scratch tree.
run_d2m ()
{
    (cd "$scratch/work" && \
        "$coreutils_out/bin/env" -i \
        HOME="$scratch/home" \
        XDG_CONFIG_HOME="$scratch/config" \
        XDG_DATA_HOME="$scratch/data" \
        XDG_CACHE_HOME="$scratch/cache" \
        XDG_STATE_HOME="$scratch/state" \
        XDG_RUNTIME_DIR="$scratch/runtime" \
        TMPDIR="$scratch/tmp" \
        LC_ALL=C \
        "$coreutils_out/bin/timeout" --kill-after=5 60 \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        "$d2m_out/bin/dicom2mesh" "$@")
}

# Usage text: upstream prints it and exits with status 255.
status=0
run_d2m -h >"$scratch/help.out" 2>"$scratch/help.err" || status=$?
test "$status" = 255
grep -Fx 'How to use dicom2Mesh:' "$scratch/help.out" >/dev/null
grep -F -- '> dicom2mesh -ipng [path1, path2, path3, ...]' \
    "$scratch/help.out" >/dev/null

# The reviewed invocation; visualization (-v/-vo) is deliberately absent.
run_d2m -ipng '[slice1.png,slice2.png,slice3.png]' -sxyz 1.0 1.0 1.0 \
    -o mesh.ply >"$scratch/convert.out" 2>"$scratch/convert.err"
grep -Fx 'Mesh export as ply file: mesh.ply' "$scratch/convert.out" >/dev/null
grep -Fx 'Create surface mesh with iso value = 400' \
    "$scratch/convert.out" >/dev/null
grep -Fx 'Parameters written to file:  mesh.info' \
    "$scratch/convert.out" >/dev/null
test ! -s "$scratch/convert.err"

test -s "$scratch/work/mesh.info"
grep -Fx 'Output file path: mesh.ply' "$scratch/work/mesh.info" >/dev/null
grep -Fx 'Surface segmentation: 400' "$scratch/work/mesh.info" >/dev/null
grep -Fx 'Mesh reduction: disabled' "$scratch/work/mesh.info" >/dev/null
grep -Fx 'Volume cropping: disabled' "$scratch/work/mesh.info" >/dev/null

"$python_out/bin/python3" - "$scratch/work/mesh.ply" <<'PY'
import collections
import sys

with open(sys.argv[1], encoding="ascii") as handle:
    lines = handle.read().splitlines()

assert lines[0] == "ply", lines[0]
assert lines[1] == "format ascii 1.0", lines[1]
end = lines.index("end_header")
header = lines[:end]
vertices = faces = None
for line in header:
    if line.startswith("element vertex "):
        vertices = int(line.split()[2])
    elif line.startswith("element face "):
        faces = int(line.split()[2])
assert vertices and faces, header
body = lines[end + 1:]
assert len(body) == vertices + faces, (len(body), vertices, faces)

points = [tuple(float(value) for value in line.split()[:3])
          for line in body[:vertices]]
polygons = [[int(value) for value in line.split()] for line in body[vertices:]]
assert all(polygon[0] == 3 and len(polygon) == 4 for polygon in polygons)
assert all(0 <= index < vertices for polygon in polygons
           for index in polygon[1:])

# Bounds follow from interpolating the iso value 400 between 0 and 2000.
expected = [(1.2, 5.8), (1.2, 5.8), (0.2, 1.8)]
for axis, (low, high) in enumerate(expected):
    values = [point[axis] for point in points]
    assert abs(min(values) - low) < 1e-5, (axis, min(values))
    assert abs(max(values) - high) < 1e-5, (axis, max(values))

# One closed, orientable surface: every edge is shared by exactly two
# triangles and the Euler characteristic V - E + F is 2 (a sphere).
edges = collections.Counter()
for _, a, b, c in polygons:
    for u, v in ((a, b), (b, c), (c, a)):
        edges[(min(u, v), max(u, v))] += 1
assert set(edges.values()) == {2}, collections.Counter(edges.values())
assert vertices - len(edges) + faces == 2, (vertices, len(edges), faces)
print(f"PLY geometry: {vertices} vertices, {faces} triangles, closed surface")
PY

# A missing slice must fail without writing a mesh.
status=0
run_d2m -ipng '[absent.png]' -o absent.ply \
    >"$scratch/absent.out" 2>"$scratch/absent.err" || status=$?
test "$status" != 0
grep -Fx 'PNG file does not exist: absent.png' "$scratch/absent.err" >/dev/null
test ! -e "$scratch/work/absent.ply"

# No state may escape into HOME/XDG, and the store output is unchanged.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -type f -print -quit)"
after=$($guix_bin hash -S nar "$d2m_out")
test "$before" = "$after"
test -z "$(find "$d2m_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$d2m_out"
printf '%s\n' 'dicom2mesh offline smoke passed'
