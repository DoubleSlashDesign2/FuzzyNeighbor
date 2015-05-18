USE FuzzyNeighbor;
GO
IF OBJECT_ID('App.Errors_GetInfo')   IS NOT NULL
    DROP PROCEDURE [App].[Errors_GetInfo];
GO

CREATE PROCEDURE [App].[Errors_GetInfo]

@Message nvarchar(max) = null output,
@PrintMessage bit = 0

AS

BEGIN

        set nocount on;

        set @Message = 
            'Error number: ' + IsNull(convert(nvarchar(10),ERROR_NUMBER()),'n/a') + '. ' +
            'Severity: ' + IsNull(convert(nvarchar(10),ERROR_SEVERITY()),'n/a') + '. ' +
            'State: ' + IsNull(convert(nvarchar(10),ERROR_STATE()),'n/a') + '. '  +
            'Procedure: ' + IsNull(convert(nvarchar(max),ERROR_PROCEDURE()),'n/a') + '. ' +
            'Line: ' + IsNull(convert(nvarchar(10),ERROR_LINE()),'n/a') + '. ' +
            'Message: ' + IsNull(convert(nvarchar(max),ERROR_MESSAGE()),'n/a') + '.';

        if @PrintMessage = 1
            select @Message as ErrorMessage;

END;
/*

Testing ....

--GO

DROP PROC App.test_trycatch
--GO
CREATE PROC App.test_trycatch

AS
BEGIN
        DECLARE @ErrorMessage nvarchar(max);

        BEGIN TRY

                    --illegal
                   SELECT 1/0 AS DividebyZero;

        END TRY
        BEGIN CATCH
                EXEC App.Errors_GetInfo @Message = @ErrorMessage out, @printMessage = 1;
        END CATCH
END
--GO

EXEC  App.test_trycatch;

*/

GO
