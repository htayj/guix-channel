#!/bin/sh
# Exercise NLarn's deterministic contract and isolated save/restore behavior.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=${GOOCASTLE_NODE:-$(command -v node)}
python_bin=${GOOCASTLE_PYTHON:-$(command -v python3)}
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [nlarn-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    nlarn_out=$1
else
    nlarn_out=$($guix_bin build -L . --no-grafts --no-substitutes nlarn)
fi

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

test -s "$doc/LICENSE"
test -s "$doc/README.md"
test -s "$doc/Changelog.md"
test -s "$doc/maze_doc.txt"
test -s "$doc/THIRD-PARTY-NOTICES"
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/LICENSE" >/dev/null
grep -F 'Copyright (c) 2009-2017 Dave Gamble and cJSON contributors.' \
    "$doc/THIRD-PARTY-NOTICES" >/dev/null
grep -F 'Creative Commons Attribution-ShareAlike' \
    "$doc/THIRD-PARTY-NOTICES" >/dev/null

contract="$channel_dir/.goocastle/runtime-evidence-contracts.json"
test -s "$contract"
grep -F '"issueNumber": 710' "$contract" >/dev/null
grep -F '"packageName": "nlarn"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/nlarn.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-710.png"' \
    "$contract" >/dev/null
grep -F '"executable": "nlarn"' "$contract" >/dev/null
grep -F '"--highscores"' "$contract" >/dev/null
grep -F '"successMarker": "NLarn Hall of Fame"' "$contract" >/dev/null

test -r "$bounded_validation"
test -x "$node_bin"
test -x "$python_bin"

util_linux_out=
for candidate in $($guix_bin build -L . --no-grafts --no-substitutes util-linux); do
    if test -x "$candidate/bin/unshare"; then
        util_linux_out=$candidate
        break
    fi
done
test -n "$util_linux_out"
unshare="$util_linux_out/bin/unshare"
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$unshare" --user --map-root-user --net --fork true \
        >/dev/null 2>&1; then
    echo 'nlarn smoke requires an unprivileged network namespace' >&2
    exit 77
fi

if test -n "${GOOCASTLE_DISPOSABLE_WORKSPACE-}"; then
    disposable_workspace=$GOOCASTLE_DISPOSABLE_WORKSPACE
else
    disposable_workspace=$(mktemp -d /tmp/goocastle-agent-XXXXXX)
fi
case "$disposable_workspace" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$disposable_workspace"
scratch=$(mktemp -d "$disposable_workspace/nlarn-smoke-XXXXXX")
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" \
    "$scratch/tmp" "$scratch/work"
chmod 700 "$scratch/runtime"

before=$($guix_bin hash -S nar "$nlarn_out")
test -z "$(find "$nlarn_out" -xdev -type f -perm /222 -print -quit)"

common_env="HOME=$scratch/home XDG_CONFIG_HOME=$scratch/config XDG_DATA_HOME=$scratch/data XDG_CACHE_HOME=$scratch/cache XDG_STATE_HOME=$scratch/state XDG_RUNTIME_DIR=$scratch/runtime TMPDIR=$scratch/tmp TERM=xterm-256color LC_ALL=C PATH= ALL_PROXY=http://127.0.0.1:9 HTTP_PROXY=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 NO_PROXY=*"

# This is the reviewed deterministic runtime contract.  It must not create
# the user's .nlarn directory merely to read an absent high-score file.
highscores=$(env -i $common_env \
    "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
    "$nlarn_out/bin/nlarn" --highscores)
printf '%s\n' "$highscores" | grep -F 'NLarn Hall of Fame' >/dev/null
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work" -mindepth 1 -print -quit)"

# Run both real curses sessions in a fresh network namespace.  The helper is
# itself launched by the bounded argv-only executor, which owns the complete
# process group if the PTY session ever stops responding.
raw="$scratch/nlarn-terminal.raw"
proof=$(cd "$scratch/work" && env -i $common_env \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 90000 -- \
    "$unshare" --user --map-root-user --net --fork \
    "$python_bin" "$channel_dir/tests/nlarn-pty-runner.py" \
    "$nlarn_out/bin/nlarn" "$scratch")
test "$proof" = 'NLARN PTY save/restore passed'
test -s "$raw"

test -f "$scratch/home/.nlarn/nlarn.ini"
test -f "$scratch/home/.nlarn/nlarn.sav"
test -z "$(find "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$nlarn_out")
test "$before" = "$after"
test ! -w "$nlarn_out"
printf '%s\n' 'NLarn isolated contract, PTY save/restore, license, and store-integrity smoke passed'
