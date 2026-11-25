# basicDraCor

A small wrapper for the [DraCor API](https://dracor.org/doc/api/) written in
BASIC, more precisely in [QB64 Phoenix Edition](https://qb64phoenix.com/)
(QB64-PE). It is the little sibling of
[PyDraCor](https://github.com/dracor-org/pydracor) (Python) and
[rdracor](https://github.com/dracor-org/rdracor) (R).

It started as a playful answer to a reviewer's question: *"Does BASIC support
JSON natively?"* It does not. With a JSON library, an HTTP client and some
gzip handling, BASIC can still talk to DraCor:

```
Resolving DraCor ID ger000088 ...
  -> corpus: ger, play: lessing-emilia-galotti
Title:      Emilia Galotti
Authors:    Lessing, Gotthold Ephraim
Year:       1772
Characters: 13
Density:    .3717948717948718
```

basicDraCor was written by Ingo Börner with [Claude Code](https://claude.com/claude-code).

## Dialect and dependencies

- **QB64 Phoenix Edition 4.7.0** (release `v4.7.0-GLFW`). It compiles BASIC to
  C++ and has a built-in HTTP client (`_OPENCLIENT("HTTP:...")`, enabled with
  `$UNSTABLE:HTTP`, based on libcurl).
- **[qb64pe-json](https://github.com/mkilgore/qb64pe-json)** by Matt Kilgore
  (MIT) parses the JSON. A copy is included in `vendor/qb64pe-json/`.

Tested on macOS 15 (Apple Silicon) and in Docker (Debian bookworm, linux/amd64).

## Quick start with Docker

You only need Docker. The image builds QB64-PE from its pinned release, then
compiles the demo and the tests.

```sh
docker compose run --rm basicdracor          # interactive shell in the project
docker compose run --rm basicdracor demo     # run the demo
docker compose run --rm basicdracor test_dracor
```

In the shell, `demo` and `test_dracor` are on the `PATH`. `build.sh
examples/demo.bas` recompiles a program, and its binary also lands on the
`PATH`. `src/`, `examples/` and `tests/` are mounted from the host, so you can
edit the `.bas` files with your usual editor and recompile them in the
container. When you are done, `docker compose down` removes the network.

Without Compose:

```sh
docker build --platform linux/amd64 -t basicdracor .
docker run -it --rm --platform linux/amd64 basicdracor          # shell
docker run --rm --platform linux/amd64 basicdracor demo         # demo
```

The image is always `linux/amd64`, because QB64-PE 4.7.0 does not build on
Linux/arm64. On Apple Silicon, Docker Desktop runs it emulated, which is slower
but works.

## Native installation (macOS)

Requirements: the Xcode Command Line Tools (`xcode-select --install`), `curl`
and `make`. Nothing gets installed system-wide. QB64-PE is downloaded into
`./toolchain` (git-ignored) and built there:

```sh
scripts/setup-toolchain.sh          # download and build QB64-PE (a few minutes)
scripts/build.sh examples/demo.bas  # compile -> bin/demo
bin/demo
scripts/test.sh                     # build and run tests + demo against dracor.org
```

On Linux, get QB64-PE from its
[releases](https://github.com/QB64-Phoenix-Edition/QB64pe/releases), run its
`setup_lnx.sh`, and point the scripts at the compiler with
`QB64PE=/path/to/qb64pe scripts/build.sh ...`. Alternatively, follow the
`Dockerfile`.

`scripts/env.sh` points clang++ at the libc++ headers inside the macOS SDK.
This works around an incomplete Command Line Tools installation, where
`#include <cstddef>` fails, and does no harm on a healthy one.

## Using the library

Include `src/dracor.bi` at the top of your program and `src/dracor.bm` at the
bottom:

```basic
$CONSOLE:ONLY
'$INCLUDE: 'src/dracor.bi'

DIM j AS Json, root AS LONG
root = DracorGetPlay&(j, "ger", "lessing-emilia-galotti")
IF root < 0 THEN PRINT DracorError: SYSTEM 1
PRINT DracorStr$(j, root, "title"); " by "; DracorPlayAuthors$(j, root, "; ")
PRINT DracorCount&(j, root, "characters"); "characters"
JsonClear j
SYSTEM

'$INCLUDE: 'src/dracor.bm'
```

The JSON endpoints load the response into a `Json` object and return its root
token. The helpers (`DracorStr$`, `DracorNum#`, `DracorCount&`, `DracorItem&`)
read values with qb64pe-json query paths such as `"authors(0).name"` or
`"metrics.plays"`. You can also use the qb64pe-json API directly on the same
object.

### Identifying plays

As in the API, a play is identified by **corpus name + play name**, e.g. `ger`
+ `lessing-emilia-galotti`. Play names are unique only *within* a corpus:
`seneca-medea` exists both in `rom` (rom000005) and in `eng` (eng000633). The
**DraCor ID**, e.g. `ger000088`, is unique across DraCor. `DracorResolveId%`
and `DracorGetPlayById&` turn an ID into corpus and play name.

### Functions

| Function | API endpoint | Returns |
|---|---|---|
| `DracorGetInfo&(j)` | `/info` | root token |
| `DracorGetCorpora&(j, includeMetrics%)` | `/corpora` (`?include=metrics`) | root token (array) |
| `DracorGetCorpus&(j, corpusname$)` | `/corpora/{corpusname}` | root token, plays in `"plays"` |
| `DracorGetPlay&(j, corpusname$, playname$)` | `/corpora/{c}/plays/{p}` | root token (play metadata) |
| `DracorGetPlayMetrics&(j, corpusname$, playname$)` | `/corpora/{c}/plays/{p}/metrics` | root token |
| `DracorGetPlayCharacters&(j, corpusname$, playname$)` | `/corpora/{c}/plays/{p}/characters` | root token (array) |
| `DracorGetSpokenText$(corpusname$, playname$, sex$)` | `/corpora/{c}/plays/{p}/spoken-text` (`?sex=`) | text; `sex$` is `""`, `"MALE"`, `"FEMALE"` or `"UNKNOWN"` |
| `DracorResolveId%(id$, corpusname$, playname$)` | `/id/{id}` | true/false; sets `corpusname$` and `playname$` |
| `DracorGetPlayById&(j, id$)` | `/id/{id}` + play metadata | root token, checks that the `id` matches |

Helpers:

| Function | Purpose |
|---|---|
| `DracorStr$(j, tok, query$)` | string value (`""` if missing or null) |
| `DracorNum#(j, tok, query$)` | numeric value (0 if missing) |
| `DracorCount&(j, tok, query$)` | number of entries of an array or object |
| `DracorItem&(j, tok, query$, index&)` | token of the array entry `index&` (0-based), -1 if out of range |
| `DracorPlayAuthors$(j, playTok, sep$)` | authors' names joined with `sep$` |
| `DracorSetApiUrl url$` / `DracorGetApiUrl$` | change or read the API base URL (default `https://dracor.org/api/v1`) |
| `DracorGet$(path$)`, `DracorHttpGet$(url$)` | raw GET of an API path or of any URL |
| `DracorUrlEncode$(s$)` | percent-encoding |
| `DracorUtf8Len&(s$)` | length in UTF-8 characters (`LEN` counts bytes) |

The JSON functions return **-1 on error**. Each call sets the shared variables
`DracorError` (empty on success), `DracorStatus` (HTTP status) and
`DracorFinalUrl` (the URL after redirects). There is no need for `JsonInit`,
because each call clears `j` itself. Call `JsonClear j` when you are done.

## Tests

`scripts/test.sh` (or `test_dracor` in the container) runs
`tests/test_dracor.bas` against dracor.org. It checks, among other things,
that `ger000088` resolves to `ger` / `lessing-emilia-galotti`, that Emilia
Galotti has 13 characters, that `seneca-medea` has different IDs in `rom` and
`eng`, and that a 404 does not crash. It then runs the demo and checks its
output. The suite sends about 20 GET requests.

## Limitations

- **UTF-8**: QB64-PE strings are byte strings. Text from DraCor is passed
  through as UTF-8 bytes and prints correctly in a UTF-8 terminal, but `LEN`,
  `MID$` and `PRINT USING` column widths count bytes, not characters (use
  `DracorUtf8Len&` to count characters). qb64pe-json does not decode `\uXXXX`
  escapes, and it swaps `\n` and `\r`. The DraCor responses tested here contain
  raw UTF-8 rather than `\u` escapes, so this has not mattered so far.
- **No request headers**: the QB64-PE HTTP client cannot send headers such as
  `Accept: application/json`. `/id/{id}` therefore redirects to the web page
  (`https://dracor.org/{corpus}/{play}`), and `DracorResolveId%` reads corpus
  and play name from that URL. This breaks if the frontend URLs change. For the
  same reason, formats that the API offers only via the `Accept` header (e.g.
  RDF) are not available; TEI and CSV have their own endpoints (`…/tei`,
  `…/csv`).
- **gzip**: some responses arrive gzip-compressed even though the client did
  not ask for it (possibly a caching effect). basicDraCor detects this and decompresses with
  `_INFLATE$`, checked against the gzip CRC-32.
- **Empty responses**: in QB64-PE 4.7.0, `_STATUSCODE` fails with "Subscript
  out of range" on responses without a body. DraCor's 404s have no body. In
  that case basicDraCor does not ask for the status: it sets `DracorStatus` to
  -1 and `DracorError` to an "Empty response" message. As a consequence, a
  legitimately empty answer (e.g. spoken text of `sex = "UNKNOWN"` when there
  are no such characters) cannot be told apart from "not found".
- Only GET, only a handful of endpoints, no paging, whole responses in memory.
  A corpus listing such as `ger` (~800 KB) takes about half a second.
- Runtime errors in QB64-PE programs show a dialog box by default. The demo and
  tests install an `ON ERROR` handler. For headless runs, set
  `QB64PE_NOPROMPT=y`, as the scripts and the Docker image do.

## Licence

MIT, see [LICENSE](LICENSE). `vendor/qb64pe-json` is MIT-licensed by Matt
Kilgore. QB64-PE itself is not included; it is downloaded at build time under
its own licence.
