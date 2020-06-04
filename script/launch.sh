#!/bin/bash

set -eo pipefail

MY="$(realpath "$(dirname "$0")")"
[ -z "$VIVADO" ] && VIVADO=vivado

cd build/
SCR="$(basename "$1")"
LOG="$SCR.log"

finish() {
    printf '\e[31mERROR: Vivado failed. Log file: ./build/%s\e[0m\n' "$LOG"
}
trap finish EXIT

"$VIVADO" -mode batch -source "../$1" 2>&1 | tee "$LOG" | "$MY/log_highlight.sh"
trap - EXIT
