#!/bin/sh
# Play, save, restore and score the installed UltraRogue in a fresh XDG tree,
# inside networkless user and PID namespaces.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [urogue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        urogue)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts \
                       --no-substitutes "$package"); do
        if test -e "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

coreutils_out=$(find_output bin/mktemp coreutils)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
util_linux_out=$(find_output bin/unshare util-linux)
python_out=$(find_output bin/python3 python-minimal)
faketime_out=$(find_output lib/faketime/libfaketime.so.1 libfaketime)
locales_out=$($guix_bin build --no-grafts --no-substitutes \
    -e '(@ (gnu packages base) glibc-utf8-locales)')

test -x "$game_out/bin/urogue"
test -x "$game_out/libexec/urogue"
doc=$game_out/share/doc/urogue-1.0.8
for document in LICENSE.TXT README.md CHANGELOG INSTALL README.orig \
    spoilers.txt; do
    test -s "$doc/$document"
done

# The complete, unmodified license from the fixed source revision, with every
# attribution and the UltraRogue naming conditions.
test "$("$coreutils_out/bin/sha256sum" "$doc/LICENSE.TXT" | \
    "$coreutils_out/bin/cut" -d ' ' -f 1)" = \
    b9098b600147f8629c680535c135bb14d5675e4d33d7710f95c5b63bf4158d4d
for notice in \
    'Copyright (C) 1985, 1986, 1992, 1993, 1995 Herb Chong' \
    'Portions Copyright (C) 1985 Michael Morgan, Ken Dalka' \
    'Portions Copyright (C) 1981 Michael Toy, Ken Arnold and Glenn Wichman' \
    'Portions Copyright (C) 1993, 1995  Nicholas J. Kisseberth' \
    'Recent code (2018+) by Earl Fogel, no rights reserved.' \
    '5. Products derived from this software may not be called "UltraRogue" or'
do
    "$grep_out/bin/grep" -F "$notice" "$doc/LICENSE.TXT" >/dev/null
done
"$grep_out/bin/grep" -F 'See the LICENSE.TXT file for details.' \
    "$doc/README.md" >/dev/null

# The per-issue runtime-evidence contract is part of this package proof.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
for field in '"issueNumber": 732' '"packageName": "urogue"' \
    '"packageModulePath": "guix/tay/packages/ultrarogue.scm"' \
    '"artifactPath": ".goocastle/evidence/issue-732.png"' \
    '"executable": "urogue"' '"successMarker": "Top Ten Adventurers:"'; do
    "$grep_out/bin/grep" -F "$field" "$contract" >/dev/null
done

unshare=$util_linux_out/bin/unshare
if ! "$unshare" --user --map-current-user --pid --net --fork true \
    >/dev/null 2>&1; then
    echo 'urogue smoke requires unprivileged user, PID and network namespaces' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$game_out")
test -z "$("$findutils_out/bin/find" "$game_out" -xdev -type f -perm /222 \
    -print -quit)"
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/urogue.XXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/tmp" "$scratch/work" \
    "$scratch/l"

# The runner's longest-path checks need a short scratch directory.
if test "${#scratch}" -gt 40; then
    echo "TMPDIR is too long for the urogue path length checks" >&2
    exit 1
fi

"$unshare" --user --map-current-user --pid --net --fork \
    "$python_out/bin/python3" -I "$channel_dir/tests/urogue-pty-runner.py" \
    "$game_out/bin/urogue" "$game_out/libexec/urogue" \
    "$faketime_out/lib/faketime/libfaketime.so.1" \
    "$locales_out/lib/locale" "$scratch" \
    >"$scratch/work/runner.out"
"$grep_out/bin/grep" -Fx 'UROGUE_PTY_OK' "$scratch/work/runner.out" >/dev/null

# The game never wrote outside its XDG state directory.
test -z "$("$findutils_out/bin/find" "$scratch/home" "$scratch/config" \
    "$scratch/cache" "$scratch/state" "$scratch/tmp" "$scratch/work" \
    -mindepth 1 ! -name runner.out -print -quit)"
test "$("$findutils_out/bin/find" "$scratch/data" -mindepth 1 -print | \
    LC_ALL=C "$coreutils_out/bin/sort")" = \
    "$(printf '%s\n' "$scratch/data/urogue" "$scratch/data/urogue/.rog_score")"

after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"
printf '%s\n' 'UROGUE_RUNTIME_OK'
