' basicDraCor tests against the live API at dracor.org.
' Prints one line per check and exits with the number of failed checks.
'
' Build and run: scripts/test.sh

$CONSOLE:ONLY
'$INCLUDE: '../src/dracor.bi'

ON ERROR GOTO Failed

DIM SHARED passed AS LONG, failed AS LONG
DIM j AS Json, root AS LONG, t AS LONG, i AS LONG, n AS LONG, found AS LONG
DIM corpusName AS STRING, playName AS STRING, s AS STRING, rid AS STRING

' --- offline helpers -------------------------------------------------------
CheckStr "UrlEncode", DracorUrlEncode$("a b/ä"), "a%20b%2F%C3%A4"
CheckNum "Utf8Len of 'Calderón'", DracorUtf8Len&("Calder" + CHR$(&HC3) + CHR$(&HB3) + "n"), 8
DracorSetApiUrl "https://example.org/api/v1/"
CheckStr "SetApiUrl strips trailing slash", DracorGetApiUrl$, "https://example.org/api/v1"
DracorSetApiUrl DRACOR_DEFAULT_API

' --- /info ------------------------------------------------------------------
root = DracorGetInfo&(j)
CheckTrue "info: request ok (" + DracorError + ")", root > 0
CheckStr "info: name", DracorStr$(j, root, "name"), "DraCor API v1"
CheckTrue "info: version not empty", DracorStr$(j, root, "version") <> ""

' --- /corpora ---------------------------------------------------------------
root = DracorGetCorpora&(j, -1)
CheckTrue "corpora: request ok (" + DracorError + ")", root > 0
n = DracorCount&(j, root, "")
CheckTrue "corpora: at least 20 corpora (got" + STR$(n) + ")", n >= 20
found = 0
FOR i = 0 TO n - 1
    t = DracorItem&(j, root, "", i)
    IF DracorStr$(j, t, "name") = "ger" THEN
        found = -1
        CheckStr "corpora: ger title", DracorStr$(j, t, "title"), "German Drama Corpus"
        CheckTrue "corpora: ger has > 500 plays", DracorNum#(j, t, "metrics.plays") > 500
    END IF
NEXT
CheckTrue "corpora: contains ger", found

' --- /corpora/{corpusname} --------------------------------------------------
root = DracorGetCorpus&(j, "rom")
CheckTrue "corpus rom: request ok (" + DracorError + ")", root > 0
CheckStr "corpus rom: name", DracorStr$(j, root, "name"), "rom"
n = DracorCount&(j, root, "plays")
CheckTrue "corpus rom: has plays (got" + STR$(n) + ")", n > 10
found = 0
FOR i = 0 TO n - 1
    t = DracorItem&(j, root, "plays", i)
    IF DracorStr$(j, t, "name") = "seneca-medea" THEN found = -1: rid = DracorStr$(j, t, "id")
NEXT
CheckTrue "corpus rom: contains seneca-medea", found
CheckStr "corpus rom: seneca-medea id", rid, "rom000005"

' play names are only unique within a corpus
root = DracorGetPlay&(j, "eng", "seneca-medea")
CheckStr "eng/seneca-medea has a different id", DracorStr$(j, root, "id"), "eng000633"

' --- play metadata ----------------------------------------------------------
root = DracorGetPlay&(j, "ger", "lessing-emilia-galotti")
CheckTrue "play: request ok (" + DracorError + ")", root > 0
CheckStr "play: id", DracorStr$(j, root, "id"), "ger000088"
CheckStr "play: title", DracorStr$(j, root, "title"), "Emilia Galotti"
CheckStr "play: authors", DracorPlayAuthors$(j, root, "; "), "Lessing, Gotthold Ephraim"
CheckStr "play: authors(0).fullname", DracorStr$(j, root, "authors(0).fullname"), "Gotthold Ephraim Lessing"
CheckNum "play: number of characters", DracorCount&(j, root, "characters"), 13
CheckNum "play: yearNormalized", DracorNum#(j, root, "yearNormalized"), 1772

' --- metrics ------------------------------------------------------------------
root = DracorGetPlayMetrics&(j, "ger", "lessing-emilia-galotti")
CheckTrue "metrics: request ok (" + DracorError + ")", root > 0
CheckNum "metrics: size", DracorNum#(j, root, "size"), 13
CheckTrue "metrics: density between 0 and 1", DracorNum#(j, root, "density") > 0 AND DracorNum#(j, root, "density") < 1

' --- characters (served gzip-compressed by the server) -------------------------
root = DracorGetPlayCharacters&(j, "ger", "lessing-emilia-galotti")
CheckTrue "characters: request ok (" + DracorError + ")", root > 0
CheckNum "characters: count", DracorCount&(j, root, ""), 13
found = 0
FOR i = 0 TO DracorCount&(j, root, "") - 1
    t = DracorItem&(j, root, "", i)
    IF DracorStr$(j, t, "id") = "emilia" THEN found = -1: CheckStr "characters: emilia is FEMALE", DracorStr$(j, t, "sex"), "FEMALE"
NEXT
CheckTrue "characters: contains emilia", found

' --- spoken text ----------------------------------------------------------------
s = DracorGetSpokenText$("ger", "lessing-emilia-galotti", "")
CheckTrue "spoken text: request ok (" + DracorError + ")", DracorError = ""
CheckTrue "spoken text: starts with the Prince's first words", LEFT$(s, 26) = "Klagen, nichts als Klagen!"
s = DracorGetSpokenText$("ger", "lessing-emilia-galotti", "female")
CheckTrue "spoken text (female): starts with Claudia", LEFT$(s, 26) = "Wer sprengte da in den Hof"
CheckTrue "spoken text (female): UTF-8 kept (more bytes than characters)", LEN(s) > DracorUtf8Len&(s)

' --- DraCor ID --------------------------------------------------------------------
CheckTrue "resolve ger000088 (" + DracorError + ")", DracorResolveId%("ger000088", corpusName, playName)
CheckStr "resolve ger000088: corpus", corpusName, "ger"
CheckStr "resolve ger000088: play", playName, "lessing-emilia-galotti"
root = DracorGetPlayById&(j, "rom000005")
CheckTrue "play by id rom000005 (" + DracorError + ")", root > 0
CheckStr "play by id rom000005: corpus", DracorStr$(j, root, "corpus"), "rom"
CheckStr "play by id rom000005: name", DracorStr$(j, root, "name"), "seneca-medea"

' --- errors -----------------------------------------------------------------------
root = DracorGetPlay&(j, "ger", "no-such-play")
CheckTrue "unknown play: returns -1", root = -1
CheckTrue "unknown play: error message set", DracorError <> ""
' QB64-PE cannot report the status of a response without body (see dracor.bm)
CheckNum "unknown play: HTTP status unknown", DracorStatus, -1
s = DracorGetSpokenText$("ger", "lessing-emilia-galotti", "UNKNOWN")
CheckTrue "spoken text (UNKNOWN, no such speakers): empty, no crash", s = ""
CheckTrue "unknown id: fails", NOT DracorResolveId%("ger999999", corpusName, playName)
CheckStr "missing key gives empty string", DracorStr$(j, JsonGetRootToken&(j), "nope"), ""

JsonClear j
PRINT
PRINT passed; "passed,"; failed; "failed"
SYSTEM failed

Failed:
PRINT "Runtime error"; ERR; "in line"; _ERRORLINE; ": "; _ERRORMESSAGE$
SYSTEM 99

SUB CheckTrue (label AS STRING, ok AS LONG)
    IF ok THEN
        passed = passed + 1
        PRINT "ok    "; label
    ELSE
        failed = failed + 1
        PRINT "FAIL  "; label
    END IF
END SUB

SUB CheckStr (label AS STRING, got AS STRING, expected AS STRING)
    IF got = expected THEN
        CheckTrue label, -1
    ELSE
        CheckTrue label + ": expected '" + expected + "', got '" + got + "'", 0
    END IF
END SUB

SUB CheckNum (label AS STRING, got AS DOUBLE, expected AS DOUBLE)
    IF got = expected THEN
        CheckTrue label, -1
    ELSE
        CheckTrue label + ": expected" + STR$(expected) + ", got" + STR$(got), 0
    END IF
END SUB

'$INCLUDE: '../src/dracor.bm'
