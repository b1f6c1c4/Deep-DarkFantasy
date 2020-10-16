#!/bin/bash

set -eo pipefail

MY="$(realpath "$(dirname "$0")")"

TCL="$1"
shift
SCR="$(basename "$TCL")"
rm -rf build/fsbl/fsbl.sdk/
mkdir -p build/fsbl/fsbl.sdk/
LOG="${SCR%.*}.log"

cd build/fsbl/fsbl.sdk/

finish() {
    printf '\e[31mERROR: SDK failed. Log file: ./build/%s\e[0m\n' "$LOG"
}
trap finish EXIT

"$VITIS/bin/xsct" "../../../$TCL" 2>&1 | tee "../../$LOG"
trap - EXIT
