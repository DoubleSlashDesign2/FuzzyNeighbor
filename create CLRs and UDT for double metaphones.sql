Use FuzzyNeighbor;
GO

/*
* Server side

CREATE ASSEMBLY DoubleMetaphone
FROM '.....\MSSQL\Binn\DoubleMetaphone.dll'
*/

GO

CREATE TYPE App.DoubleMetaphoneResult
EXTERNAL NAME DoubleMetaphone.[Phonetic.Tools.DoubleMetaphoneResult];

GO
IF Object_ID('App.fnDoubleMetaphoneEncode') IS NOT NULL
    DROP FUNCTION App.fnDoubleMetaphoneEncode;
GO

CREATE FUNCTION App.fnDoubleMetaphoneEncode (@string NVARCHAR(256))
RETURNS App.DoubleMetaphoneResult
AS
EXTERNAL NAME DoubleMetaphone.[Phonetic.Tools.DoubleMetaphone].DoubleMetaphoneEncode

GO

IF Object_ID('App.fnDoubleMetaphoneCompare ') IS NOT NULL
    DROP FUNCTION App.fnDoubleMetaphoneCompare ;
GO

CREATE FUNCTION App.fnDoubleMetaphoneCompare (@r1 App.DoubleMetaphoneResult, @r2 App.DoubleMetaphoneResult)
RETURNS Integer
AS
EXTERNAL NAME DoubleMetaphone.[Phonetic.Tools.DoubleMetaphone].DoubleMetaphoneCompare
GO
/*

--Test encoding with an example:

DECLARE  @InputStringsToShred App.TokenizerInput ;

INSERT INTO @InputStringsToShred (SourceKey, SourceString)
    VALUES    (2070794, 'Providence Park'),
                      (1119167,'Columbia Heights School (historical)')
                    ;
SELECT 
    Tokenizer_sfk,
    TokenOrdinal,
    Token,
    App.fnDoubleMetaphoneEncode(Token)
FROM App.fnTokenizeTableOfStrings(@InputStringsToShred);

*/

