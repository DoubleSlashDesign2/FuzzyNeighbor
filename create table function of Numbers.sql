Use FuzzyNeighbor;
GO
/*

The tokenizing step requires a small table of numbers. Easy enough to create on the fly.
This function returns a list of sequential numbers, beginning with zero, and up to "MaxNumbers" long.

Likely got this fast solution from Itzik Ben-Gen.

*/
IF OBJECT_ID (N'App.fnNumbersList') IS NOT NULL
    DROP FUNCTION App.fnNumbersList;

GO

CREATE FUNCTION App.fnNumbersList (@MaxNumbers INT = 100)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN 
(
        WITH e1(n) AS
        (
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
        ), -- 10
        e2(n) AS (SELECT 1 FROM e1 CROSS JOIN e1 AS b), -- 10*10
        e3(n) AS (SELECT 1 FROM e1 CROSS JOIN e2) -- 10*100
        SELECT TOP (@MaxNumbers)  ROW_NUMBER() OVER (ORDER BY n) - 1 as n 
        FROM e3
        ORDER BY n

);
GO
--test run
SELECT  n FROM App.fnNumbersList(5);
SELECT  n FROM App.fnNumbersList(DEFAULT);

