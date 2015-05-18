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
/*
Testing

SELECT  'Percent' as FunctionType, 'No difference' as 'Input type',  App.fnLevenshteinPercent('Kahaloch', 'Kahaloch') As Result
UNION ALL
SELECT  'Distance' as FunctionType, 'No difference' as 'Input type',  App.fnLevenshteinDistance('Kahaloch',  'Kahaloch')   As Result;


SELECT  'Percent' as FunctionType, '1 letter difference' as 'Input type',  App.fnLevenshteinPercent( 'Kahaloch', 'Kahloch') As Result
UNION ALL
SELECT  'Distance' as FunctionType, '1 letter difference' as 'Input type',  App.fnLevenshteinDistance( 'Kahaloch', 'Kahloch') As Result;


SELECT  'Percent' as FunctionType, '2 letter difference' as 'Input type',  App.fnLevenshteinPercent( 'Kahaloch', 'Kaloch') As Result
UNION ALL
SELECT  'Distance' as FunctionType, '2 letter difference' as 'Input type',  App.fnLevenshteinDistance('Kahaloch',  'Kaloch') As Result;


SELECT  'Percent' as FunctionType, 'garbage' as 'Input type',  App.fnLevenshteinPercent( 'Kahaloch', 'garbage') As Result
UNION ALL
SELECT  'Distance' as FunctionType, 'garbage' as 'Input type',  App.fnLevenshteinDistance( 'Kahaloch', 'garbage') As Result;

*/