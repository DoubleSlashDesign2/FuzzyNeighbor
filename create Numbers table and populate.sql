Use FuzzyNeighbor;
GO

/*

Sometimes its better to use  an indexed table of numbers, especially when you need a long list.


*/

IF Object_ID('AppData.Numbers') IS NOT NULL
    DROP TABLE AppData.Numbers;
GO
CREATE TABLE AppData.Numbers
(
    n INT NOT NULL CONSTRAINT  PK_Numbers PRIMARY KEY
)

ON Secondary;

GO

SET ROWCOUNT 0;

TRUNCATE TABLE AppData.Numbers;

DECLARE @Seed INT = 10000;

--this code goes up to 100,000;
--Likely got this fast solution from Itzik Ben-Gen.

WITH e1(n) AS
        (
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
        ), -- 10
        e2(n) AS (SELECT 1 FROM e1 CROSS JOIN e1 AS b), -- 10*10
        e3(n) AS (SELECT 1 FROM e1 CROSS JOIN e2 AS c), -- 10*10*10
        e4(n) AS (SELECT 1 FROM e1 CROSS JOIN e3 AS d), -- 10*10*10*10
        e5(n) AS (SELECT 1 FROM e1 CROSS JOIN e4 AS e) -- 10*10*10*10*10
INSERT INTO AppData.Numbers (n)
        SELECT TOP (@Seed)  ROW_NUMBER() OVER (ORDER BY n) - 1 as n 
        FROM e5
        ORDER BY n

SELECT MAX(n) as MaxN, Count(*) as nNumbers FROM AppData.Numbers;