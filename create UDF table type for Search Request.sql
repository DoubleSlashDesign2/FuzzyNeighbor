Use FuzzyNeighbor;
GO


IF Type_ID(N'App.Request') IS NOT NULL
    DROP TYPE App.Request;

GO
CREATE TYPE [App].[Request] AS TABLE 
 ( 
Request_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,           
RequestValue VARCHAR(256)  NOT NULL
);