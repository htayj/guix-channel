#!/bin/sh
set -eu

raw_desktop="@RAW_DESKTOP@"
runtime_library_path="@LD_LIBRARY_PATH@"
gst_plugin_path="@GST_PLUGIN_PATH@"
gst_plugin_scanner="@GST_PLUGIN_SCANNER@"
runtime_data_dirs="@XDG_DATA_DIRS@"
runtime_path="@RUNTIME_PATH@"

export LD_LIBRARY_PATH="$runtime_library_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GST_PLUGIN_SYSTEM_PATH_1_0="$gst_plugin_path"
export GST_PLUGIN_SCANNER_1_0="$gst_plugin_scanner"
export XDG_DATA_DIRS="$runtime_data_dirs${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export PATH="$runtime_path${PATH:+:$PATH}"
export GDK_BACKEND=x11
: "${WEBKIT_DMABUF_RENDERER_FORCE_SHM:=1}"
export WEBKIT_DMABUF_RENDERER_FORCE_SHM

if test "${1-}" != --guix-smoke; then
    exec "$raw_desktop" "$@"
fi

# The proof path runs the actual desktop application in fresh user, mount, and
# network namespaces.  It cannot see the host network and all ordinary mutable
# state lives under a private tmpfs /tmp.
if test "${BUZZ_GUIX_SMOKE_NAMESPACED:-}" != 1; then
    export BUZZ_GUIX_SMOKE_NAMESPACED=1
    exec "@UNSHARE@" --user --map-root-user --net --mount --fork "$0" --guix-smoke
fi

"@MOUNT@" --make-rprivate /
"@MOUNT@" -t tmpfs -o mode=1777 tmpfs /tmp
printf '%s\n' 'root:x:0:0:Buzz smoke:/tmp:/bin/sh' >/tmp/passwd
"@MOUNT@" --bind /tmp/passwd /etc/passwd

if test "${BUZZ_GUIX_SMOKE_SESSION:-}" != 1; then
    export BUZZ_GUIX_SMOKE_SESSION=1
    exec "@DBUS_RUN_SESSION@" -- "$0" --guix-smoke
fi

root=$(mktemp -d /tmp/buzz-smoke.XXXXXX)
mkdir -p "$root/home" "$root/config" "$root/cache" "$root/data" \
    "$root/state" "$root/runtime" "$root/work"
chmod 700 "$root/runtime"
export HOME="$root/home"
export XDG_CONFIG_HOME="$root/config"
export XDG_CACHE_HOME="$root/cache"
export XDG_DATA_HOME="$root/data"
export XDG_STATE_HOME="$root/state"
export XDG_RUNTIME_DIR="$root/runtime"
export DISPLAY=:99

xvfb_pid=
app_pid=
cleanup() {
    if test -n "$app_pid" && kill -0 "$app_pid" 2>/dev/null; then
        kill "$app_pid" 2>/dev/null || true
        wait "$app_pid" 2>/dev/null || true
    fi
    if test -n "$xvfb_pid" && kill -0 "$xvfb_pid" 2>/dev/null; then
        kill "$xvfb_pid" 2>/dev/null || true
        wait "$xvfb_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT HUP INT TERM

"@XVFB@" :99 -screen 0 1280x800x24 -nolisten tcp >"$root/xvfb.log" 2>&1 &
xvfb_pid=$!
ready=
index=0
while test "$index" -lt 200; do
    if "@XWININFO@" -display :99 -root >/dev/null 2>&1; then
        ready=1
        break
    fi
    index=$((index + 1))
    sleep 0.05
done
test -n "$ready" || {
    cat "$root/xvfb.log" >&2
    echo 'buzz smoke: X server did not become ready' >&2
    exit 1
}

(cd "$root/work" && exec "$raw_desktop") >"$root/buzz.log" 2>&1 &
app_pid=$!
window=
index=0
while test "$index" -lt 300; do
    # WRY creates a small hidden helper before its unnamed 800x600 application
    # window.  Select the application by WM_CLASS and dimensions instead of
    # accidentally treating the helper as runtime evidence.
    for candidate in $("@XDOTOOL@" search 'buzz-desktop' 2>/dev/null || true); do
        width=
        height=
        while IFS='=' read -r key value; do
            case "$key" in
                WIDTH) width=$value ;;
                HEIGHT) height=$value ;;
            esac
        done <<EOF
$("@XDOTOOL@" getwindowgeometry --shell "$candidate" 2>/dev/null || true)
EOF
        if test -n "$width" && test -n "$height" \
                && test "$width" -ge 800 && test "$height" -ge 500; then
            window=$candidate
            break
        fi
    done
    test -n "$window" && break
    if ! kill -0 "$app_pid" 2>/dev/null; then
        cat "$root/buzz.log" >&2
        echo 'buzz smoke: desktop exited before showing a window' >&2
        exit 1
    fi
    index=$((index + 1))
    sleep 0.1
done
test -n "$window" || {
    cat "$root/buzz.log" >&2
    "@XWININFO@" -display :99 -root -tree >&2 || true
    echo 'buzz smoke: no visible desktop window appeared' >&2
    exit 1
}

if test -n "${BUZZ_GUIX_SCREENSHOT_PATH:-}"; then
    case "$BUZZ_GUIX_SCREENSHOT_PATH" in
        /*) ;;
        *) echo 'BUZZ_GUIX_SCREENSHOT_PATH must be absolute' >&2; exit 64 ;;
    esac
    # Window creation precedes WebKit's first rendered frame.  Give the real
    # frontend time to paint so the screenshot proves more than X11 mapping.
    sleep 5
    "@IMPORT@" -display :99 -window "$window" "PNG:$BUZZ_GUIX_SCREENSHOT_PATH"
    test -s "$BUZZ_GUIX_SCREENSHOT_PATH"
fi

printf '%s\n' BUZZ_GUIX_SMOKE_OK
