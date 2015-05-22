USE FuzzyNeighbor;
GO

/*

    First DRAFT ;

*/
IF OBJECT_ID('App.SearchController') IS NOT NULL
        DROP PROCEDURE [App].[SearchController];
GO
CREATE PROCEDURE [App].[SearchController]

        @Request AS [App].[Request]  READONLY,
        @Latitude FLOAT  = NULL,
        @Longitude FLOAT = NULL,
        @DistanceInKilometers INT = 5,
        @NumberOfCandidates INT  = 10,
        @LevenshteinMinimum INT = 66,
        @PreferredPOICategory_fk INT = 0,
        @Debug BIT = 0

AS

SET NOCOUNT ON;

DECLARE 
    @RC INT = 0
    ,@ErrorMessage VARCHAR(MAX) = ''
    ,@ProcedureName VARCHAR(MAX) = OBJECT_NAME(@@PROCID)
    ,@ParameterSet VARCHAR(MAX) = ''
    ,@StatusMessage VARCHAR(MAX) = ''
    ,@ProcedureLog_fk INT = 0 
;

BEGIN

            DECLARE @POICandidates AS [App].[POISelection];
            DECLARE @POICandidateCount INT;
                                    
	BEGIN TRY

               SET @ParameterSet = 'Search X/Y= ' + CAST(@Longitude AS VARCHAR(20)) + ' / ' + CAST(@Latitude AS VARCHAR(20))  + '. ';
               SET @StatusMessage = 'Nearest neighbor ... ';

               EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk OUT, @ParameterSet = @ParameterSet, @StatusMessage = @StatusMessage, @ProcedureName = @ProcedureName;

                --Option A:  Search the radius around the provide coordinates
                IF @Latitude IS NOT NULL AND @Longitude IS NOT NULL
                        INSERT INTO @POICandidates (POI_fk, DistanceInMeters )
                                SELECT POI_fk, DistanceInMeters 
                                FROM [App].[fnPOI_Select_ByNearestNeighbor]  ( @Latitude,  @Longitude, @DistanceInKilometers , @NumberOfCandidates);

                SET @POICandidateCount = @@RowCount;
                SET @StatusMessage =+  CAST(@POICandidateCount AS VARCHAR(40)) + ' yielded candidates found.  ';

                --Match attempt
                SET @StatusMessage =+ 'Search ... ';

                IF @POICandidateCount > 0
                        SELECT 
                                p.POI_pk, 
                                p.POIName,
                                p.Locality,
                                s.POISubcategoryName,
                                a.MatchScore, 
                                a.MatchRankOrder 
                        FROM App.fnPOI_Select_ByName 
                        (
                                @POICandidates,
                                @Request,
                                @NumberOfCandidates,
                                @LevenshteinMinimum
                        ) a
                        JOIN AppData.POI p ON a.POI_fk = p.POI_pk
                        JOIN AppData.vSubCategoryCategoryXRef s ON s.POISubcategory_pk = p.POISubcategory_fk
                        ORDER BY
                                CASE
                                        WHEN @PreferredPOICategory_fk > 0 AND p.POISubcategory_fk=@PreferredPOICategory_fk THEN 1
                                        ELSE 0
                                END DESC, 
                                a.MatchRankOrder;
                                
                         SET @RC = @@RowCount;
                         SET @StatusMessage =+ CAST(@RC AS VARCHAR(40)) + ' found POIs. ';

                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk, @StatusMessage = @StatusMessage, @ReturnCode = @RC;


--TODO: expand to locality if nothing found
--                IF @POICandidateCount = 0
                    --use locality based


	END TRY
  
	BEGIN CATCH
 
		SET @RC = -1;
                        SET @StatusMessage = 'Error';
		EXEC [App].[Errors_GetInfo] @Message = @ErrorMessage OUT, @PrintMessage = 0;

		EXEC [App].[ProcedureLog_Merge]
				@ProcedureLog_fk = @ProcedureLog_fk OUT,
				@ProcedureName = @ProcedureName,
				@StatusMessage = @StatusMessage,
				@ErrorMessage = @ErrorMessage,
				@ReturnCode = @RC;

	END CATCH

RETURN(@RC)

END

GO

