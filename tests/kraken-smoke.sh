#!/bin/sh
# Installed CPU OCR, pinned upstream image/model, no model repository/network.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [kraken-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    out=$1
else
    out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts kraken)
fi
find_output() {
    program=$1; shift
    for candidate in $("$guix_bin" build --no-grafts "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}
util_out=$(find_output bin/unshare util-linux)
core_out=$(find_output bin/timeout coreutils)
python_out=$(find_output bin/python3 python)
sh_out=$(find_output bin/sh bash-minimal)
test -x "$out/bin/kraken"
test -x "$out/bin/ketos"
if ! "$util_out/bin/unshare" --user --map-root-user --net --fork true; then
    echo 'kraken smoke requires unprivileged user/network namespaces' >&2
    exit 77
fi
scratch=$(mktemp -d -t kraken-smoke.XXXXXX)
trap 'rm -rf -- "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/cache" "$scratch/data" "$scratch/tmp"
"$core_out/bin/timeout" 240 "$util_out/bin/unshare" --user --map-root-user --net --fork \
    "$core_out/bin/env" -i HOME="$scratch/home" TMPDIR="$scratch/tmp" \
    XDG_CONFIG_HOME="$scratch/config" XDG_CACHE_HOME="$scratch/cache" \
    XDG_DATA_HOME="$scratch/data" LC_ALL=C.UTF-8 PYTHONNOUSERSITE=1 \
    OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 PATH="$core_out/bin" \
    "$sh_out/bin/sh" -c '
        set -eu
        out=$1; scratch=$2; python=$3; consumer=$4
        fixture=$out/share/kraken/fixtures
        # The same pinned source supplies image, real weights, and ground truth.
        "$out/bin/kraken" -d cpu -i "$fixture/000236.png" "$scratch/recognized.txt" \
            ocr -m "$fixture/overfit.mlmodel" --no-segmentation --no-reorder --pad 16
        "$out/bin/kraken" -d cpu -h -i "$fixture/000236.png" "$scratch/output.hocr" \
            ocr -m "$fixture/overfit.mlmodel" --no-segmentation --no-reorder --pad 16
        # Exercise discovery/import of all installed ketos commands, not training.
        "$out/bin/ketos" --help >"$scratch/ketos-help.txt"
        "$python" -I "$consumer" "$fixture" "$scratch"
    ' kraken-smoke "$out" "$scratch" "$python_out/bin/python3" "$channel_dir/tests/kraken-smoke.py"
if test -n "${KRAKEN_SMOKE_ARTIFACT_DIR:-}"; then
    mkdir -p "$KRAKEN_SMOKE_ARTIFACT_DIR"
    cp "$scratch/recognized.txt" "$scratch/output.hocr" "$scratch/consumer.json" \
        "$scratch/ketos-help.txt" "$KRAKEN_SMOKE_ARTIFACT_DIR/"
fi
printf 'kraken smoke passed: real offline CPU OCR and hOCR consumer\n'
