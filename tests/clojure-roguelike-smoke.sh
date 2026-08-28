#!/bin/sh
# Run the installed roguelike in a fresh HOME/XDG tree and a networkless PTY.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [clojure-roguelike-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L . --no-grafts clojure-roguelike)
fi

if test "${CLOJURE_ROGUELIKE_SMOKE_IN_NETNS:-}" != 1; then
    util_linux=${UTIL_LINUX:-$($guix_bin build -L . --no-grafts util-linux \
      | grep -E -- '-util-linux-[0-9.]+$')}
    test -x "$util_linux/bin/script"
    if ! unshare --user --map-root-user --net --fork true >/dev/null 2>&1; then
        echo 'clojure-roguelike smoke requires an unprivileged network namespace' >&2
        exit 77
    fi
    # A new network namespace has no configured interfaces, fail-closed for
    # this program, which has no network feature or local protocol to expose.
    exec env CLOJURE_ROGUELIKE_SMOKE_IN_NETNS=1 GUIX="$guix_bin" \
        UTIL_LINUX="$util_linux" \
        unshare --user --map-root-user --net --fork "$0" "$game_out"
fi

script_bin=${UTIL_LINUX:?missing util-linux output}/bin/script
test -x "$script_bin"
test -x "$game_out/bin/clojure-roguelike"
test "$(find "$game_out/share/java" -maxdepth 1 -type f -name '*.jar' | wc -l)" -eq 1
test -s "$game_out/share/java/clojure-roguelike.jar"
test -s "$game_out/share/doc/clojure-roguelike/LICENSE"
test -s "$game_out/share/doc/clojure-roguelike/README.md"
test -s "$game_out/share/doc/clojure-roguelike/CHANGELOG.md"
test -s "$game_out/share/doc/clojure-roguelike/clojure-runtime-notices/readme.txt"
test -s "$game_out/share/doc/clojure-roguelike/clojure-runtime-notices/epl-v10.html"
grep -F 'ECLIPSE PUBLIC LICENSE' "$game_out/share/doc/clojure-roguelike/LICENSE" >/dev/null
grep -F 'ASM bytecode engineering library' \
    "$game_out/share/doc/clojure-roguelike/clojure-runtime-notices/readme.txt" >/dev/null
grep -F 'Guava Murmur3 hash implementation' \
    "$game_out/share/doc/clojure-roguelike/clojure-runtime-notices/readme.txt" >/dev/null
grep -F 'Eclipse Public License - v 1.0' \
    "$game_out/share/doc/clojure-roguelike/clojure-runtime-notices/epl-v10.html" >/dev/null

java_bin=$(sed -n 's|^exec \([^ ]*/bin/java\) -jar .*|\1|p' \
    "$game_out/bin/clojure-roguelike")
test -x "$java_bin"
jar_bin=${java_bin%/java}/jar
test -x "$jar_bin"

before=$($guix_bin hash -S nar "$game_out")
scratch=$(mktemp -d -t clojure-roguelike-smoke.XXXXXXXX)
cleanup() {
    rm -rf "$scratch"
}
trap cleanup EXIT INT TERM
mkdir -p "$scratch/home" "$scratch/config" "$scratch/cache" \
    "$scratch/state" "$scratch/tmp" "$scratch/caller" "$scratch/jar"

(cd "$scratch/jar" && "$jar_bin" xf "$game_out/share/java/clojure-roguelike.jar")
tr -d '\r' <"$scratch/jar/META-INF/MANIFEST.MF" | \
    grep -Fx 'Main-Class: roguelike.core' >/dev/null
test -f "$scratch/jar/roguelike/core__init.class"
test -f "$scratch/jar/clojure/lang/Compiler.class"

(
    cd "$scratch/caller"
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
    TMPDIR="$scratch/tmp" TERM=xterm-256color LC_ALL=C.UTF-8 \
      "$script_bin" -qefc \
      "printf 'q\\n' | exec '$game_out/bin/clojure-roguelike'" /dev/null | tr -d '\r'
) >"$scratch/actual"

printf '%s\n' \
    '########' \
    '#......#' \
    '#......#' \
    '.......#' \
    '#......#' \
    '#......#' \
    '#......#' \
    '########' | cmp - "$scratch/actual"

# The program is one-shot and should leave neither mutable state nor any
# altered package bytes behind.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/cache" \
    "$scratch/state" "$scratch/caller" -mindepth 1 -print -quit)"
after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"
printf '%s\n' 'clojure-roguelike isolated terminal smoke passed'
