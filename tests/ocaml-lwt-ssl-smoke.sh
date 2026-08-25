#!/bin/sh
exec "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/ocaml-irc-client-smoke.sh" "$@"
