#!/bin/sh
# Native installed source-app proof on private software audio/display surfaces.
# SOUNDTHREAD_SMOKE_ARTIFACTS selects retained WAV/THD/PNG/JSON/log evidence.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [soundthread-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    soundthread_out=$1
else
    soundthread_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts soundthread)
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
    echo "No output provides $program" >&2
    return 1
}

python_out=$(find_program_output bin/python3 python)
xorg_out=$(find_program_output bin/Xvfb xorg-server)
util_linux_out=$(find_program_output bin/unshare util-linux)
coreutils_out=$(find_program_output bin/timeout coreutils)
font_out=$($guix_bin build font-dejavu)
test -x "$soundthread_out/bin/soundthread"

# All builds happen above, before offline namespaces. PID namespace kill-child
# closes both engine/import workers and Xvfb even on the outer timeout. Python
# preserves an artifact directory FD before replacing /tmp with private tmpfs.
exec "$coreutils_out/bin/timeout" --kill-after=5s 240s \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --mount --ipc \
    --pid --kill-child --fork --mount-proc \
    "$python_out/bin/python3" "$channel_dir/tests/soundthread-smoke.py" \
    "$soundthread_out" "$xorg_out/bin/Xvfb" "$util_linux_out/bin/mount" \
    "$font_out" "$channel_dir/tests/soundthread-consumer.gd"
