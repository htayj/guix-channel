# Deterministic local stand-in for the separate ECA server, used only by
# tests/eca-emacs-smoke.sh.  The smoke prepends an absolute Bash shebang and
# installs the result as an executable named `eca'.  It speaks
# Content-Length-framed JSON-RPC over stdin/stdout using Bash builtins only
# and records every argv/frame in $ECA_SMOKE_LOG/server.log.
#
# Modes (second argument after `server'):
#   protocol    answer initialize; return JSON-RPC errors for chat/prompt and
#               completion/inline; answer shutdown; exit on the exit notice.
#   malformed   as protocol, but emit an unparsable frame before the
#               initialize response.
#   early-exit  read initialize, emit a truncated frame, and exit with 7.
LC_ALL=C
set -u

log=${ECA_SMOKE_LOG:?}/server.log

case ${1-} in
    server) ;;
    --version)
        # Local probe made by eca-process--server-version.
        printf 'VERSION\n' >>"$log"
        printf 'eca 0.0.0-offline-fake\n'
        exit 0
        ;;
    *)
        printf 'ARGV-REJECTED %s\n' "$*" >>"$log"
        exit 64
        ;;
esac
mode=${2-protocol}
printf 'START pid=%s mode=%s argv=%s\n' "$$" "$mode" "$*" >>"$log"

send() {
    printf 'Content-Length: %d\r\n\r\n%s' "${#1}" "$1"
    printf 'SEND %s\n' "$1" >>"$log"
}

while :; do
    length=
    state=eof
    while IFS= read -r line; do
        state=headers
        line=${line%$'\r'}
        if test -z "$line"; then
            state=body
            break
        fi
        case $line in
            Content-Length:*) length=${line#Content-Length:}; length=${length// /} ;;
        esac
    done
    if test "$state" != body; then
        printf 'EOF state=%s\n' "$state" >>"$log"
        exit 0
    fi
    case $length in
        ''|*[!0-9]*) printf 'BAD-LENGTH %s\n' "$length" >>"$log"; exit 65 ;;
    esac
    if ! IFS= read -r -N "$length" body; then
        printf 'SHORT-BODY %s\n' "$length" >>"$log"
        exit 65
    fi
    body=${body%$'\n'}
    printf 'RECV %s\n' "$body" >>"$log"

    method=
    case $body in
        *'"method":"'*) method=${body#*\"method\":\"}; method=${method%%\"*} ;;
    esac
    id=
    case $body in
        *'"id":'*) id=${body##*\"id\":}; id=${id%%[!0-9]*} ;;
    esac

    case $method in
        initialize)
            case $mode in
                malformed)
                    printf 'Content-Length: 11\r\n\r\n{"broken":['
                    printf 'SEND-MALFORMED {"broken":[\n' >>"$log"
                    ;;
                early-exit)
                    printf 'Content-Length: 64\r\n\r\n{"jsonrpc":"2.0"'
                    printf 'EARLY-EXIT 7\n' >>"$log"
                    exit 7
                    ;;
            esac
            send '{"jsonrpc":"2.0","id":'"$id"',"result":{"chatWelcomeMessage":"Offline fake ECA server: no provider configured."}}'
            ;;
        chat/prompt)
            send '{"jsonrpc":"2.0","id":'"$id"',"error":{"code":-32000,"message":"FAKE_CHAT_PROMPT_ERROR: no provider in offline smoke"}}'
            ;;
        completion/inline)
            send '{"jsonrpc":"2.0","id":'"$id"',"error":{"code":-32001,"type":"error","message":"FAKE_COMPLETION_ERROR: no provider in offline smoke"}}'
            ;;
        shutdown)
            send '{"jsonrpc":"2.0","id":'"$id"',"result":null}'
            ;;
        exit)
            printf 'EXIT\n' >>"$log"
            exit 0
            ;;
        *)
            if test -n "$id"; then
                send '{"jsonrpc":"2.0","id":'"$id"',"error":{"code":-32601,"message":"method not found"}}'
            fi
            ;;
    esac
done
