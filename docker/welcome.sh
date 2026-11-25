# Shown when an interactive shell starts in the basicDraCor container.
cat <<'WELCOME'

  basicDraCor - a DraCor API wrapper in BASIC (QB64 Phoenix Edition)

  Run the demo:          demo
  Run the tests:         test_dracor        (or: scripts/test.sh, rebuilds first)
  Compile a program:     build.sh examples/demo.bas
                         -> binary in /opt/basicdracor/bin, already on PATH
  Compiler:              qb64pe -x your.bas -o yourprog

  Library: src/dracor.bi + src/dracor.bm, examples in examples/
  Docs: README.md

WELCOME
