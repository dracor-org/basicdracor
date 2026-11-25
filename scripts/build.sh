#!/bin/sh
# Compile one or more .bas files with QB64-PE (console programs).
# Usage: scripts/build.sh examples/demo.bas [tests/test_dracor.bas ...]
#
# Environment (optional):
#   QB64PE           path of the qb64pe compiler (default: ./toolchain/qb64pe/qb64pe)
#   BASICDRACOR_BIN  output directory (default: ./bin)
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QB64PE="${QB64PE:-$ROOT/toolchain/qb64pe/qb64pe}"
BIN="${BASICDRACOR_BIN:-$ROOT/bin}"
. "$ROOT/scripts/env.sh"

[ -x "$QB64PE" ] || { echo "QB64-PE not found, run scripts/setup-toolchain.sh first"; exit 1; }
[ $# -gt 0 ] || set -- examples/demo.bas

mkdir -p "$BIN"
for src in "$@"; do
    case "$src" in /*) abs="$src" ;; *) abs="$PWD/$src" ;; esac
    name="$(basename "$src" .bas)"
    echo "Compiling $src -> $BIN/$name"
    "$QB64PE" -x "$abs" -o "$BIN/$name" > "$BIN/$name.log" 2>&1 || {
        grep -v '%' "$BIN/$name.log"; exit 1; }
done
