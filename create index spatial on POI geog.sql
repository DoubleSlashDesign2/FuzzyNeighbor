USE FuzzyNeighbor;
Go

/*
*Indexes needed to support Nearest Neighbor search

*   Start  with default index options.

* Just in case
*  UPDATE AppData.POI  set MapPoint=MapPoint.MakeValid()  where MapPoint.STIsValid()=0;;

*/


IF EXISTS (SELECT object_id FROM sys.indexes i WHERE i.NAME = 'sidxPOI_MapPoint')
        DROP INDEX [sidxPOI_MapPoint] ON  [AppData].[POI];

CREATE SPATIAL INDEX [sidxPOI_MapPoint] 
ON [AppData].[POI]
(
    [MapPoint]
)USING  GEOGRAPHY_AUTO_GRID 
WITH (DATA_COMPRESSION = PAGE);


