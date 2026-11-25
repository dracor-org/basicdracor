' basicDraCor - a small DraCor API wrapper for QB64 Phoenix Edition
' https://dracor.org/api/v1
'
' Include this file at the TOP of your program and dracor.bm at the BOTTOM:
'
'   '$INCLUDE: 'path/to/src/dracor.bi'
'   ... your code ...
'   '$INCLUDE: 'path/to/src/dracor.bm'
'
' MIT licence, see LICENSE. Written by Ingo Boerner with Claude Code.

$UNSTABLE:HTTP

'$INCLUDE: '../vendor/qb64pe-json/json.bi'

CONST BASICDRACOR_VERSION = "0.1.0"
CONST DRACOR_DEFAULT_API = "https://dracor.org/api/v1"
CONST DRACOR_TIMEOUT_SECONDS = 60

' Base URL of the API, without trailing slash. Change with DracorSetApiUrl.
DIM SHARED DracorApiUrl AS STRING
' HTTP status code of the last request (0 if no connection could be made).
DIM SHARED DracorStatus AS LONG
' Empty after a successful call, otherwise a human-readable error message.
DIM SHARED DracorError AS STRING
' URL that finally answered the last request (after redirects).
DIM SHARED DracorFinalUrl AS STRING

DracorApiUrl = DRACOR_DEFAULT_API
