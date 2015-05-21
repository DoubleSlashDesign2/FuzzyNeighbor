USE FuzzyNeighbor;
GO

--Search request;

PRINT 'Request';

DECLARE @Request AS [App].[Request] ;

--INSERT INTO @Request(RequestValue) VALUES('Century Link');
INSERT INTO @Request(RequestValue) VALUES('Bernabeu');

SELECT * FROM @Request;

--POI Candidates near the request.

PRINT 'Candidates';

DECLARE @Candidates AS [App].[POISelection];
DECLARE
        @latitude  float =  40.46 ,
        @longitude float  = -3.69,
        @distanceInKilometers  int =  2 ,
        @NumberOfCandidates int  = 10;

INSERT INTO @Candidates 
   SELECT POI_fk, DistanceInMeters FROM [App].[fnPOI_Select_ByNearestNeighbor]  ( @latitude,  @longitude ,  @distanceInKilometers ,  @NumberOfCandidates);

--Logic error to correct.  Instead of filtering out of candidates by category, change ranking of matches

SELECT p.POI_pk, POIName, c.DistanceInMeters FROM @Candidates c JOIN AppData.POI p ON c.POI_fk = p.POI_pk;

--match attempt
PRINT 'Match Attempt';

SELECT *
FROM App.fnPOI_Select_ByName 
(
@Candidates,
@Request,
10,
N'ES'
);

--   SELECT TOP 5 * FROM [AppData].[ProcedureLog]  ORDER BY ProcedureLog_pk DESC;

