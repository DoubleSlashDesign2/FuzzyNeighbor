Use FuzzyNeighbor;
GO
/*
* Server side

CREATE ASSEMBLY Levenshtein
FROM '.....\MSSQL\Binn\Levenshtein.dll'
*/

GO
IF Object_ID('App.fnLevenshteinPercent') IS NOT NULL
    DROP FUNCTION App.fnLevenshteinPercent;
GO

CREATE Function App.fnLevenshteinPercent(@S1 nvarchar(4000), @S2 nvarchar(4000))
    RETURNS float as EXTERNAL NAME Levenshtein.StoredFunctions.LevenshteinPercent;

GO
IF Object_ID('App.fnLevenshteinDistance') IS NOT NULL
    DROP FUNCTION App.LevenshteinDistance;
GO

CREATE Function App.fnLevenshteinDistance(@S1 nvarchar(4000), @S2 nvarchar(4000))
    RETURNS INT as EXTERNAL NAME Levenshtein.StoredFunctions.LevenshteinDistance;
GO
