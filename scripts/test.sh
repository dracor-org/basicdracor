#!/bin/sh
# Build the tests and the demo, run them against dracor.org and check results.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Never show runtime-error dialogs; print to stderr and exit instead.
QB64PE_NOPROMPT=y
export QB64PE_NOPROMPT

TIMEOUT=120
BIN="${BASICDRACOR_BIN:-$ROOT/bin}"

# Run a command, kill it after $TIMEOUT seconds (macOS has no `timeout`).
run_with_timeout() {
    "$@" &
    pid=$!
    # The watchdog must not hold our stdout open, or $(...) would wait for it.
    sleep "$TIMEOUT" </dev/null >/dev/null 2>&1 &
    watchdog=$!
    while kill -0 "$pid" 2>/dev/null; do
        if ! kill -0 "$watchdog" 2>/dev/null; then
            echo "TIMEOUT after ${TIMEOUT}s: $*" >&2
            kill "$pid" 2>/dev/null
            break
        fi
        sleep 1
    done
    wait "$pid"
    rc=$?
    kill "$watchdog" 2>/dev/null
    wait "$watchdog" 2>/dev/null
    return $rc
}

if [ "${SKIP_BUILD:-}" = "" ]; then
    scripts/build.sh tests/test_dracor.bas examples/demo.bas || exit 1
fi

echo "== BASIC test program =="
run_with_timeout "$BIN/test_dracor"
tests_rc=$?

echo
echo "== Demo output =="
out="$(run_with_timeout "$BIN/demo")"
demo_rc=$?
echo "$out"

echo
echo "== Demo checks =="
demo_fail=0
check() {
    if printf '%s\n' "$out" | grep -q -- "$1"; then
        echo "ok    demo prints: $1"
    else
        echo "FAIL  demo prints: $1"; demo_fail=$((demo_fail + 1))
    fi
}
[ "$demo_rc" -eq 0 ] && echo "ok    demo exit code 0" || { echo "FAIL  demo exit code $demo_rc"; demo_fail=$((demo_fail + 1)); }
check "corpus: ger, play: lessing-emilia-galotti"
check "Title:      Emilia Galotti"
check "Authors:    Lessing, Gotthold Ephraim"
check "Characters: 13"
check "^ger  *[0-9][0-9]*  German Drama Corpus"

echo
if [ "$tests_rc" -eq 0 ] && [ "$demo_fail" -eq 0 ]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "TESTS FAILED (test program exit $tests_rc, demo failures $demo_fail)"
exit 1
