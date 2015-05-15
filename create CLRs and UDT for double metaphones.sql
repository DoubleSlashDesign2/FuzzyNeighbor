Use FuzzyNeighor;

/*
Assumption:  The DoubleMetaphone DLL is has been registered with db server.
*/

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
