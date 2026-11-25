' basicDraCor demo: list the DraCor corpora with their number of plays, then
' show a few facts about Lessing's "Emilia Galotti" (ger / ger000088).
'
' Build: scripts/build.sh examples/demo.bas    Run: bin/demo

$CONSOLE:ONLY
'$INCLUDE: '../src/dracor.bi'

' Report runtime errors on stderr instead of in a dialog box.
ON ERROR GOTO Failed

DIM j AS Json, root AS LONG, c AS LONG, i AS LONG, n AS LONG
DIM corpusName AS STRING, playName AS STRING

PRINT "basicDraCor "; BASICDRACOR_VERSION; " - DraCor API from BASIC"
PRINT

root = DracorGetInfo&(j)
IF root < 0 THEN GOSUB Die
PRINT "API: "; DracorStr$(j, root, "name"); " "; DracorStr$(j, root, "version"); " at "; DracorGetApiUrl$
PRINT

root = DracorGetCorpora&(j, -1)
IF root < 0 THEN GOSUB Die
n = DracorCount&(j, root, "")
PRINT "Corpus     Plays  Title"
PRINT "---------- -----  -----"
FOR i = 0 TO n - 1
    c = DracorItem&(j, root, "", i)
    PRINT USING "\        \ #####  &"; DracorStr$(j, c, "name"); DracorNum#(j, c, "metrics.plays"); DracorStr$(j, c, "title")
NEXT
PRINT n; "corpora"
PRINT

PRINT "Resolving DraCor ID ger000088 ..."
IF NOT DracorResolveId%("ger000088", corpusName, playName) THEN GOSUB Die
PRINT "  -> corpus: "; corpusName; ", play: "; playName

root = DracorGetPlay&(j, corpusName, playName)
IF root < 0 THEN GOSUB Die
PRINT "Title:      "; DracorStr$(j, root, "title")
PRINT "Authors:    "; DracorPlayAuthors$(j, root, "; ")
PRINT "Year:      "; DracorNum#(j, root, "yearNormalized")
PRINT "Characters:"; DracorCount&(j, root, "characters")

root = DracorGetPlayMetrics&(j, corpusName, playName)
IF root < 0 THEN GOSUB Die
PRINT "Density:   "; DracorNum#(j, root, "density")

JsonClear j
SYSTEM 0

Die:
PRINT "Error: "; DracorError
SYSTEM 1

Failed:
PRINT "Runtime error"; ERR; "in line"; _ERRORLINE; ": "; _ERRORMESSAGE$
SYSTEM 2

'$INCLUDE: '../src/dracor.bm'
