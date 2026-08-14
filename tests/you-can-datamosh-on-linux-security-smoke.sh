#!/bin/sh
# Exercise the installed script implementations with an argv-recording mock.
set -eu

out=${1:?usage: $0 PACKAGE-OUTPUT}
guix_bin=${GUIX:-guix}
work=$(mktemp -d /tmp/you-can-datamosh-security.XXXXXX)
trap 'rm -rf "$work"' EXIT
fake="$work/fake-bin"
mkdir "$fake"

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
python_bin="$python_out/bin/python3"

cat >"$fake/ffmpeg" <<'PY'
#!PYTHON_PLACEHOLDER
import json
import os
import pathlib
import sys

with open(os.environ["FAKE_FFMPEG_LOG"], "a", encoding="utf-8") as log:
    json.dump(sys.argv[1:], log)
    log.write("\n")
if len(sys.argv) > 1:
    pathlib.Path(sys.argv[-1]).touch()
PY
sed -i "1s|PYTHON_PLACEHOLDER|$python_bin|" "$fake/ffmpeg"
chmod 755 "$fake/ffmpeg"

log="$work/ffmpeg.jsonl"
input="$work/input with spaces; touch PWNED #.mp4"
touch "$input"

(
    cd "$work"
    # The public wrappers intentionally prepend their immutable FFmpeg input,
    # so invoke their .real implementations here to inject the mock FFmpeg.
    # This smoke intentionally targets the implementation to inject the mock;
    # public wrappers prepend the package's real FFmpeg input by design.
    FAKE_FFMPEG_LOG="$log" PATH="$fake:$python_out/bin" \
        "$out/bin/.do-the-mosh-real" "$input" \
        --start_sec 0 --end_sec 1 --start_effect_sec 0 \
        --end_effect_sec 0.5 --repeat_p_frames 1 --output_width 32 \
        --fps 5 --output_dir MOSH
    FAKE_FFMPEG_LOG="$log" PATH="$fake:$python_out/bin" \
        "$out/bin/.video-to-gif-real" "$input" 0 1 \
        --gif_folder GIFS --fps 5 --gif_width 32
)

test ! -e "$work/PWNED"
"$python_bin" - "$log" "$input" <<'PY'
import json
import pathlib
import sys

calls = [
    json.loads(line)
    for line in pathlib.Path(sys.argv[1]).read_text().splitlines()
]
input_name = sys.argv[2]
assert len(calls) == 5, calls       # probe + 2 mosh + 2 GIF calls
assert any(input_name in call for call in calls)
assert any("input with spaces; touch PWNED #.mp4" in arg
           for call in calls for arg in call)
assert pathlib.Path(sys.argv[1]).exists()
PY

echo "you-can-datamosh-on-linux argv security smoke passed"
