USE FuzzyNeighbor;
GO
IF OBJECT_ID(N'AppData.POICategory') IS NOT NULL
        --IF NOT EXISTS (SELECT TOP 1 * FROM AppData.POICategory)
                DROP TABLE AppData.POICategory;
GO
CREATE TABLE [AppData].[POICategory]  ( 
	[POICategory_pk] 	INT NOT NULL CONSTRAINT [PK_POICcategory] PRIMARY KEY CLUSTERED,
	[POICategoryName]	NVARCHAR(40) NOT NULL,
	[LastUpdateDate]    	DATETIME NULL CONSTRAINT [DF_POICategory_LastUpdateDate]  DEFAULT (Current_TimeStamp)
) ON Secondary;
GO

INSERT INTO AppData.POICategory (POICategory_pk, POICategoryName) VALUES(0, 'None');

GO

ALTER TABLE AppData.POISubcategory  WITH CHECK ADD  CONSTRAINT FKC_POISubcategory_Category FOREIGN KEY(POICategory_fk) 
        REFERENCES  AppData.POICategory (POICategory_pk) ;


GO
