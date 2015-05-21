Use FuzzyNeighbor;
GO
IF Type_ID(N'App.POISelection') IS NOT NULL
    DROP TYPE [App].[POISelection];
GO
CREATE TYPE [App].[POISelection] AS TABLE 
( 
POISelection_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,                
POI_fk INT NOT NULL UNIQUE,
DistanceInMeters INT NULL       --; used with nearest neighbor searches
);
--WITH ( MEMORY_OPTIMIZED = ON);