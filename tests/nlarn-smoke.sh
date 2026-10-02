#!/bin/sh
# Prove ordinary NLarn gameplay and native save continuity in an offline PTY.
set -eu

guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [nlarn-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    nlarn_out=$1
else
    nlarn_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes nlarn)
fi
nlarn_out=$(CDPATH= cd -- "$nlarn_out" && pwd)
case "$nlarn_out" in /gnu/store/*) ;; *) echo 'NLarn output must be in /gnu/store' >&2; exit 1 ;; esac
test -x "$nlarn_out/bin/nlarn"
data="$nlarn_out/share/nlarn"
doc="$nlarn_out/share/doc/nlarn"
for file in fortune fortune.de fortune.es fortune.fr fortune.pt \
    maze nlarn.hlp nlarn.hlp.de nlarn.hlp.es nlarn.hlp.fr nlarn.hlp.pt \
    nlarn.msg nlarn.msg.de nlarn.msg.es nlarn.msg.fr nlarn.msg.pt; do
    test -s "$data/$file"
done
for language in de es fr pt; do
    test -s "$data/locale/$language/LC_MESSAGES/nlarn.mo"
done
test ! -e "$data/FiraMono-Medium.otf"
test ! -e "$data/nlarn-128.bmp"
for file in LICENSE README.md Changelog.md maze_doc.txt THIRD-PARTY-NOTICES; do
    test -s "$doc/$file"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/LICENSE" >/dev/null
grep -F 'Copyright (c) 2009-2017 Dave Gamble and cJSON contributors.' "$doc/THIRD-PARTY-NOTICES" >/dev/null
grep -F 'Creative Commons Attribution-ShareAlike' "$doc/THIRD-PARTY-NOTICES" >/dev/null

scratch=$(mktemp -d "${NLARN_SMOKE_ARTIFACTS_PARENT:-${TMPDIR:-/tmp}}/nlarn-smoke-XXXXXX")
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work" "$scratch/proof"
chmod 700 "$scratch/runtime"
before=$($guix_bin hash -S nar "$nlarn_out")
test -z "$(find "$nlarn_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$nlarn_out"

# Python supervises the complete isolated process group and fails closed when
# user/network/mount namespaces or the read-only store bind mount are denied.
status=0
"$guix_bin" shell --pure --no-grafts python python-pyte util-linux coreutils -- \
    env NLARN_RAW_CAPTURE="${NLARN_RAW_CAPTURE:-$scratch/proof/pre-exit.raw}" \
    NLARN_TEXT_CAPTURE="${NLARN_TEXT_CAPTURE:-$scratch/proof/pre-exit.txt}" \
    NLARN_TRANSCRIPT="${NLARN_TRANSCRIPT:-$scratch/proof/transcript.raw}" \
    python3 -B "$channel_dir/tests/nlarn-pty-runner.py" \
    "$nlarn_out/bin/nlarn" "$scratch" || status=$?
after=$($guix_bin hash -S nar "$nlarn_out")
printf '%s\n' "$before" >"$scratch/proof/nar-before.txt"
printf '%s\n' "$after" >"$scratch/proof/nar-after.txt"
test "$before" = "$after"
test ! -w "$nlarn_out"
test "$status" -eq 0 || { echo "NLarn proof failed ($status): $scratch/proof" >&2; exit 1; }

test -s "$scratch/home/.nlarn/nlarn.ini"
test -s "$scratch/home/.nlarn/nlarn.sav"
test -s "$scratch/proof/receipt.json"
test -z "$(find "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    -mindepth 1 -print -quit)"
printf 'NLarn gameplay/save/restore/store proof: %s\nNAR before/after: %s\n' \
    "$scratch/proof/receipt.json" "$after"
