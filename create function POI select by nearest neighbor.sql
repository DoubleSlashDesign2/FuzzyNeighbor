Use FuzzyNeighbor;
GO
IF OBJECT_ID (N'App.fnPOI_Select_ByNearestNeighbor') IS NOT NULL
    DROP FUNCTION App.fnPOI_Select_ByNearestNeighbor;
GO
CREATE FUNCTION App.fnPOI_Select_ByNearestNeighbor 
            (   
                @Latitude float =  0,
                @Longitude float = 0,
                @distanceInKilometers INT =  0 ,
                @NumberOfCandidates INT = 1
              )
RETURNS @NearestPOI  TABLE 
(
    POI_fk INT NOT NULL, 
    DistanceInMeters  INT NOT NULL,
    CompassBearing FLOAT NULL           --future
)
--WITH SCHEMABINDING --index hints not allowed unless table is  memory optimized (which I can't do in my version)
AS

BEGIN

        DECLARE
            @searchPoint geography = geography::Point(@latitude, @longitude, 4326) ,        --WGS 84
            @distanceInMeters INT = @distanceInKilometers * 1000
        ;

        INSERT INTO @NearestPOI (POI_fk, DistanceInMeters, CompassBearing)
            SELECT 
                   TOP (@NumberOfCandidates)
                   POI_pk,
                   CAST(ROUND(MapPoint.STDistance(@searchPoint),0) AS INT) AS DistanceInMeters,
                   0 AS 'CompassBearing'
               FROM AppData.POI   WITH (INDEX = sidxPOI_MapPoint)
               WHERE MapPoint.STDistance(@searchPoint) < @distanceInMeters
                               AND MapPoint IS NOT NULL
                               AND MapPoint.STDistance(@searchPoint) IS NOT NULL
               ORDER BY MapPoint.STDistance(@searchPoint);


        RETURN


END
GO