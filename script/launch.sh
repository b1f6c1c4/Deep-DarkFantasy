#!/bin/bash

set -eo pipefail

MY="$(realpath "$(dirname "$0")")"
[ -z "$VIVADO" ] && VIVADO=vivado

mkdir -p build/report/
cd build/
SCR="$(basename "$1")"
LOG="$SCR.log"

finish() {
    printf '\e[31mERROR: Vivado failed. Log file: ./build/%s\e[0m\n' "$LOG"
}
trap finish EXIT

(
if [ "$1" = "script/synth.tcl" ]; then
    printf '# H_WIDTH=%s\n' "$H_WIDTH"
    printf '# H_START=%s\n' "$H_START"
    printf '# H_TOTAL=%s\n' "$H_TOTAL"
    printf '# V_HEIGHT=%s\n' "$V_HEIGHT"
    printf '# FREQ=%s\n' "$FREQ"
    printf '# KH=%s\n' "$KH"
    printf '# KV=%s\n' "$KV"
fi
"$VIVADO" -nojournal -nolog -mode batch -source "../$1" 2>&1
) | tee "$LOG" | "$MY/log_highlight.sh"
trap - EXIT
