USE FuzzyNeighbor;
GO
IF OBJECT_ID(N'[AppData].[vSubCategoryCategoryXRef]') IS NOT NULL
    DROP VIEW [AppData].[vSubCategoryCategoryXRef];
GO
CREATE VIEW  [AppData].[vSubCategoryCategoryXRef]

WITH SCHEMABINDING
AS
SELECT c.POICategoryName, s.POISubcategoryName,   c.POICategory_pk, s.POISubcategory_pk
FROM [AppData].[POISubcategory] s 
JOIN AppData.POICategory c ON c.POICategory_pk = s.POICategory_fk
;
GO
SELECT
*
FROM [AppData].[vSubCategoryCategoryXRef]
ORDER BY POICategoryName, POISubcategoryName


