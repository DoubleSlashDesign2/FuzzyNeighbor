USE FuzzyNeighbor;
GO

--Search request;

PRINT 'Request';

DECLARE @Request AS [App].[Request] ;


INSERT INTO @Request(RequestValue) VALUES('Santiago Burnabay');

SELECT * FROM @Request;

--Define search area .

PRINT 'Candidates';

DECLARE @Candidates AS [App].[POISelection];
DECLARE
        @latitude  float =  40.46 ,
        @longitude float  = -3.69,
        @distanceInKilometers  int =  2 ,
        @NumberOfCandidates int  = 10;

DECLARE @RC INT;
EXEC @RC = [App].[SearchController]

        @Request,
        @Latitude  = @latitude,
        @Longitude = @longitude ,
        @DistanceInKilometers = @distanceInKilometers,
        @NumberOfCandidates = @NumberOfCandidates,
        @LevenshteinMinimum  = 66,
        @PreferredPOICategory_fk  = 0;

SELECT @RC AS RC;

 
