#!/bin/sh
# Download QB64 Phoenix Edition into ./toolchain and build it there.
# Nothing is installed system-wide. Needs the Xcode Command Line Tools (clang).
set -eu

QB64PE_VERSION="4.7.0-GLFW"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TC="$ROOT/toolchain"

. "$ROOT/scripts/env.sh"

mkdir -p "$TC"
cd "$TC"
if [ ! -d qb64pe ]; then
    echo "Downloading QB64-PE $QB64PE_VERSION ..."
    curl -fsSL -o qb64pe_osx.tar.gz \
        "https://github.com/QB64-Phoenix-Edition/QB64pe/releases/download/v$QB64PE_VERSION/qb64pe_osx-$QB64PE_VERSION.tar.gz"
    tar xzf qb64pe_osx.tar.gz
fi

cd qb64pe
if [ ! -x ./qb64pe ]; then
    echo "Building QB64-PE (takes a few minutes) ..."
    make OS=osx clean >/dev/null 2>&1 || true
    make OS=osx BUILD_QB64=y -j4 > "$TC/build.log" 2>&1 || {
        echo "Build failed, see $TC/build.log"; exit 1; }
fi
echo "QB64-PE is ready: $TC/qb64pe/qb64pe"
