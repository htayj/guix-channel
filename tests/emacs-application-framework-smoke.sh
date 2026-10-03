#!/bin/sh
# Exercise the installed EAF core and its real upstream Qt demo, offline.
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [emacs-eaf-emacs-application-framework-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        emacs-eaf-emacs-application-framework)
fi
output_with_program() {
    program=$1
    shift
    for output in $($guix_bin build "$@"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "cannot locate $program in outputs for $*" >&2
    return 1
}
emacs_out=$(output_with_program bin/emacs emacs)
python_out=$(output_with_program bin/python3 python)
xorg_out=$(output_with_program bin/Xvfb xorg-server)
util_linux_out=$(output_with_program bin/unshare util-linux)
coreutils_out=$(output_with_program bin/timeout coreutils)
imagemagick_out=$(output_with_program bin/import imagemagick)
# Loopback EPC is required, but external networking is forbidden.
before=$($guix_bin hash -S nar "$package_out")
set +e
"$coreutils_out/bin/timeout" --kill-after=5s 120s \
    "$util_linux_out/bin/unshare" --user --map-root-user --mount --net --ipc \
    --pid --kill-child --fork --mount-proc \
    "$python_out/bin/python3" "$channel_dir/tests/emacs-application-framework-smoke.py" \
    "$package_out" "$emacs_out/bin/emacs" "$xorg_out/bin/Xvfb" \
    "$util_linux_out/bin/mount" "$imagemagick_out/bin/import" \
    "$channel_dir/tests/emacs-application-framework-smoke.el"
status=$?
set -e
after=$($guix_bin hash -S nar "$package_out")
test "$before" = "$after"
exit "$status"
