#!/bin/sh
# External consumer only: sh tests/handhrl-smoke.sh OUTPUT EVIDENCE
# OUTPUT is prebuilt; EVIDENCE must be a fresh canonical absolute directory.
set -eu
umask 077
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE (prebuilt store output; fresh absolute directory)" >&2
    exit 64
fi
case "$1" in /gnu/store/*) ;; *) echo 'OUTPUT must be an absolute store path' >&2; exit 64 ;; esac
case "$2" in /*) ;; *) echo 'EVIDENCE must be absolute' >&2; exit 64 ;; esac
guix_spec=${GUIX-guix}
case "$guix_spec" in
    ''|*[[:space:]]*) echo 'GUIX must name one executable, not a command string' >&2; exit 64 ;;
    /*) ;;
    */*) echo 'GUIX must be an executable name or absolute path' >&2; exit 64 ;;
esac
guix_bin=$(command -v "$guix_spec") || { echo 'GUIX executable not found' >&2; exit 64; }
guix_bin=$(realpath -e -- "$guix_bin") || exit 64
test -f "$guix_bin" && test -x "$guix_bin" || { echo 'GUIX must be an executable file' >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -e -- "$1") || exit 64
case "$out" in /gnu/store/*/*) echo 'OUTPUT must be a direct store item' >&2; exit 64 ;; /gnu/store/*) ;; *) exit 64 ;; esac
test "$1" = "$out" && test -d "$out" || { echo 'OUTPUT must be canonical' >&2; exit 64; }
test -f "$out/bin/handhrl" && test -x "$out/bin/handhrl" || { echo 'missing bin/handhrl' >&2; exit 1; }
if test -e "$2" || test -L "$2"; then
    echo 'EVIDENCE must not already exist' >&2; exit 64
fi
evidence=$(realpath -m -- "$2") || exit 64
test "$2" = "$evidence" || { echo 'EVIDENCE must be canonical' >&2; exit 64; }
case "$evidence/" in /gnu/store/*) echo 'EVIDENCE must be outside the store' >&2; exit 64 ;; esac
if test -e "$evidence" || test -L "$evidence"; then
    echo 'EVIDENCE must not already exist' >&2; exit 64
fi
test -r "$channel_dir/tests/handhrl-native.py" || exit 1
mkdir -p -- "$(dirname -- "$evidence")"
mkdir -- "$evidence"
find_output ()
{
    # Active guix build parses package names without :OUTPUT and its manifest
    # branch keeps manifest-entry-item, discarding manifest-entry-output.
    # Use the supported store API instead: an explicit derivation-input
    # selects only "out", without package mutation, profiles or an extra drv.
    outputs=$("$guix_bin" repl -q /dev/stdin "$2" "$evidence/tool-$2-output-selection.txt" <<'SCM'
(use-modules (gnu packages) (guix packages) (guix store)
             (guix derivations) (guix grafts) (ice-9 format))
(let* ((name (cadr (command-line)))
       (receipt (caddr (command-line)))
       (package (specification->package name)))
  (unless (member "out" (package-outputs package))
    (error "consumer requires an explicit out output; available split outputs"
           name (package-outputs package)))
  (with-store store
    (set-build-options store #:build-cores 1 #:max-build-jobs 1
                       #:offload? #f #:keep-failed? #t)
    (parameterize ((%graft? #f))
      (let* ((drv (package-derivation store package #:graft? #f))
             (output (derivation->output-path drv "out")))
        (call-with-output-file receipt
          (lambda (port)
            (format port "package=~a\nderivation=~a\nselected_output=out\npath=~a\nvalid_before=~s\n"
                    name (derivation-file-name drv) output
                    (valid-path? store output))))
        (unless (build-derivations store (list (derivation-input drv '("out"))))
          (error "exact consumer output realization failed" name output))
        (display output)
        (newline)))))
SCM
    ) || return 1
    # Exact outputs realized by this consumer. Main must consult valid_before
    # and shared roots before any later cleanup; this is not deletion authority.
    printf '%s\n' "$outputs" >> "$evidence/realized-tool-outputs.txt"
    case "$outputs" in
        /gnu/store/*/*|*[[:space:]]*) echo 'invalid exact-output response' >&2; return 1 ;;
        /gnu/store/*) ;;
        *) echo 'missing exact-output response' >&2; return 1 ;;
    esac
    if test -e "$outputs/$1"; then
        printf '%s\n' "$outputs"
        return 0
    fi
    echo "missing $1 in Guix prerequisite $2 output out; inspect its split outputs explicitly (no all-output fallback)" >&2
    return 1
}
realize_tool ()
{
    tool_name=$1
    tool_file=$2
    tool_pkg=$3
    tool_log="$evidence/tool-$tool_name-realization.log"
    if ! realize_out=$(find_output "$tool_file" "$tool_pkg" 2> "$tool_log"); then
        printf '{"failed":true,"tool":"%s","package":"%s","file":"%s"}\n' \
            "$tool_name" "$tool_pkg" "$tool_file" >> "$tool_log"
        echo "tool realization failed: $tool_name ($tool_pkg); see $tool_log" >&2
        exit 1
    fi
    printf '{"failed":false,"tool":"%s","package":"%s","output":"out","realized":"%s"}\n' \
        "$tool_name" "$tool_pkg" "$realize_out" >> "$tool_log"
    printf '%s\n' "$realize_out"
}
core=$(realize_tool coreutils bin/env coreutils)
util=$(realize_tool util-linux bin/unshare util-linux)
python=$(realize_tool python bin/python3 python)
xvfb=$(realize_tool xorg-server bin/Xvfb xorg-server)
xdotool=$(realize_tool xdotool bin/xdotool xdotool)
xwd=$(realize_tool xwd bin/xwd xwd)
convert=$(realize_tool imagemagick bin/convert imagemagick)
x11=$(realize_tool libx11 lib/libX11.so.6 libx11)
xtst=$(realize_tool libxtst lib/libXtst.so.6 libxtst)
host_uid=$("$core/bin/id" -u)
host_gid=$("$core/bin/id" -g)
if test "$host_uid" -ne 1000 || test "$host_gid" -ne 998; then
    echo 'contract requires original caller UID1000/GID998' >&2; exit 1
fi
host_user_ns=$("$core/bin/readlink" /proc/self/ns/user)
host_mount_ns=$("$core/bin/readlink" /proc/self/ns/mnt)
host_net_ns=$("$core/bin/readlink" /proc/self/ns/net)
host_pid_ns=$("$core/bin/readlink" /proc/self/ns/pid)
printf '{"uid":%s,"gid":%s,"user":"%s","mnt":"%s","net":"%s","pid":"%s"}\n' \
    "$host_uid" "$host_gid" "$host_user_ns" "$host_mount_ns" "$host_net_ns" "$host_pid_ns" \
    > "$evidence/host-namespaces.json"
"$guix_bin" gc -R "$out" > "$evidence/runtime-closure.txt"
printf '{"guix":"%s","coreutils":"%s","util-linux":"%s","python":"%s","xorg-server":"%s","xdotool":"%s","xwd":"%s","imagemagick":"%s","libx11":"%s","libxtst":"%s"}\n' \
    "$guix_bin" "$core" "$util" "$python" "$xvfb" "$xdotool" "$xwd" "$convert" "$x11" "$xtst" \
    > "$evidence/consumer-tools.json"
before=$("$guix_bin" hash -r -x "$out") || exit 1
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$core/bin/env" -i PATH='' LC_ALL=C PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$host_uid" HOST_GID="$host_gid" \
    HOST_USER_NS="$host_user_ns" HOST_MOUNT_NS="$host_mount_ns" \
    HOST_NET_NS="$host_net_ns" HOST_PID_NS="$host_pid_ns" \
    "$core/bin/timeout" --kill-after=5 300 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -B -s "$channel_dir/tests/handhrl-native.py" \
    "$out" "$evidence" \
    "$xvfb/bin/Xvfb" "$xdotool/bin/xdotool" "$xwd/bin/xwd" "$convert/bin/convert" \
    "$x11/lib/libX11.so.6" "$xtst/lib/libXtst.so.6" \
    > "$evidence/driver.stdout" 2> "$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -r -x "$out") || exit 1
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
printf '{"driver_status":%s,"nar_unchanged":%s}\n' "$status" \
    "$(test "$before" = "$after" && printf true || printf false)" > "$evidence/shell-result.json"
if test "$before" != "$after"; then
    echo 'HandhRL output NAR changed during native gameplay' >&2; exit 1
fi
test "$status" -eq 0 || exit "$status"
printf '%s\n' "HANDHRL_NATIVE_OK evidence=$evidence"
