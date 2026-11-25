#!/bin/sh
# Compile one or more .bas files into ./bin with the local QB64-PE.
# Usage: scripts/build.sh examples/demo.bas [tests/test_dracor.bas ...]
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QB64PE="$ROOT/toolchain/qb64pe/qb64pe"
. "$ROOT/scripts/env.sh"

[ -x "$QB64PE" ] || { echo "QB64-PE not found, run scripts/setup-toolchain.sh first"; exit 1; }
[ $# -gt 0 ] || set -- examples/demo.bas

mkdir -p "$ROOT/bin"
for src in "$@"; do
    case "$src" in /*) abs="$src" ;; *) abs="$PWD/$src" ;; esac
    name="$(basename "$src" .bas)"
    echo "Compiling $src -> bin/$name"
    "$QB64PE" -x "$abs" -o "$ROOT/bin/$name" > "$ROOT/bin/$name.log" 2>&1 || {
        cat "$ROOT/bin/$name.log"; exit 1; }
done
