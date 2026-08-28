#!/bin/sh
# Exercise FreeLarn in an isolated PTY with no host state or network access.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [freelarn-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    freelarn_out=$1
else
    freelarn_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes freelarn)
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

util_linux_out=$(find_program_output bin/script util-linux)
unshare_out=$(find_program_output bin/unshare util-linux)
iproute_out=$(find_program_output bin/ip iproute2 || \
              find_program_output sbin/ip iproute2)
if test -x "$iproute_out/bin/ip"; then
    ip_bin=$iproute_out/bin/ip
else
    ip_bin=$iproute_out/sbin/ip
fi

test -x "$freelarn_out/bin/freelarn"
test -x "$freelarn_out/libexec/freelarn"
test ! -e "$freelarn_out/bin/stub"
test -s "$freelarn_out/share/doc/freelarn/LICENSE"
test -s "$freelarn_out/share/doc/freelarn/docs/LICENSE"
test -s "$freelarn_out/share/doc/freelarn/README.md"
test -s "$freelarn_out/share/doc/freelarn/docs/HISTORY"
test -s "$freelarn_out/share/doc/freelarn/docs/CHANGELOG"
grep -q 'Apache License' "$freelarn_out/share/doc/freelarn/LICENSE"
grep -q 'Apache License' "$freelarn_out/share/doc/freelarn/docs/LICENSE"
grep -q 'C++11 compiler' "$freelarn_out/share/doc/freelarn/README.md"
test -x "$util_linux_out/bin/script"
test -x "$unshare_out/bin/unshare"
test -x "$ip_bin"

# A fresh user/network namespace exposes no host network.  Bring its loopback
# interface up solely to make the isolation explicit; FreeLarn has no service.
if test "${FREELARN_SMOKE_IN_NETNS:-}" != 1; then
    if ! "$unshare_out/bin/unshare" --user --map-root-user --net --fork \
            sh -c '"$1" link set lo up' sh "$ip_bin"; then
        echo "freelarn-smoke: user and network namespaces are required" >&2
        exit 1
    fi
    exec env FREELARN_SMOKE_IN_NETNS=1 GUIX="$guix_bin" \
        "$unshare_out/bin/unshare" --user --map-root-user --net --fork \
        sh -c '"$1" link set lo up; exec "$2" "$3"' \
        sh "$ip_bin" "$0" "$freelarn_out"
fi

temporary=$(mktemp -d "${TMPDIR:-/tmp}/freelarn-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
home=$temporary/home
state=$temporary/state
work=$temporary/work
mkdir -p "$home" "$state" "$work"

test "$("$ip_bin" -o link show | wc -l)" -eq 1
"$ip_bin" -o link show | grep -q ' lo:'

# The first session creates all three cwd-relative game files in XDG state and
# saves the game.  The empty caller directory proves the launcher changes cwd.
before=$(find "$freelarn_out" -xdev -type f -exec sha256sum {} \; | sort)
(
    cd "$work"
    env HOME="$home" XDG_STATE_HOME="$state" PATH= TERM=xterm \
        "$util_linux_out/bin/script" -qefc \
        "printf '\\nsmoke\\nS' | '$freelarn_out/bin/freelarn'" /dev/null
)
test -f "$state/freelarn/fl_scorefile.dat"
test -f "$state/freelarn/fl_messages.txt"
test -f "$state/freelarn/fl_savefile.dat"
test -z "$(find "$work" -mindepth 1 -print -quit)"
test "$before" = "$(find "$freelarn_out" -xdev -type f -exec sha256sum {} \; | sort)"

# A second run consumes the saved game before quitting, proving restore works.
(
    cd "$work"
    env HOME="$home" XDG_STATE_HOME="$state" PATH= TERM=xterm \
        "$util_linux_out/bin/script" -qefc \
        "printf 'Qy' | '$freelarn_out/bin/freelarn'" /dev/null
)
test ! -e "$state/freelarn/fl_savefile.dat"
test -z "$(find "$work" -mindepth 1 -print -quit)"
test "$before" = "$(find "$freelarn_out" -xdev -type f -exec sha256sum {} \; | sort)"

printf '%s\n' 'freelarn isolated PTY, XDG state, save/restore, and license smoke passed'
