USE FuzzyNeighbor;
GO

/*

POI Table.  This is the table that we are searching.  Table is designed to be flexible in terms:
1) type if POI
2) source of POI data
3) source of map coordinates (which are needed for the nearest neighbor filter.

The SRID of the coordinates is required to be 4326, for WGS 84.  Throw an error if its not.

*/

IF OBJECT_ID('AppData.POI') IS NOT NULL 
 --           IF NOT EXISTS (SELECT TOP 1 * FROM AppData.POI)
                    DROP TABLE AppData.POI;

GO

CREATE TABLE AppData.POI
(
POI_pk INT NOT NULL CONSTRAINT PK_POI PRIMARY KEY,

POIName NVARCHAR(256) NOT NULL,
POISubcategory_fk INT NOT NULL CONSTRAINT DF_POI_POISubcategory_fk DEFAULT 0,   /*  cafe, ATM. cemetrary  */

/* If its a mailable location, or the address is known */
AddressLine NVARCHAR(256)  NULL,                                             /* Geocode this address if available */
AddressLastLine NVARCHAR(256)  NULL,                                      /* Mailable last line, if applicable */
PostalCode NVARCHAR(16)  NULL,                                                 /* If a mailable location */ 

/* Enclosing geographies. */
AdministrativeDistrict NVARCHAR(256) NOT NULL,                      /* e.g., a State or Province or Autonomous Community*/
AdministrativeDistrict2 NVARCHAR(256) NOT NULL,                    /* e.g., a County */
Locality NVARCHAR(256) NOT NULL,                                            /* e.g., a Municipality */                           
CountryCodeISO3 NCHAR(3)  NOT NULL,

/* Display and Nearest neigbor search  */
MapPoint GEOGRAPHY NULL,                                                        /* Business rule will require coordindates to be WGS 84 */
Longitude DECIMAL(11, 6) NULL,
Latitude DECIMAL(11, 6) NULL,
CoordinateSRID INT NULL CONSTRAINT  CHK_POI_CoordinateSRID  CHECK (CoordinateSRID=4326),
IsGeocodeUseableForMapping BIT NOT NULL CONSTRAINT DF_POI_IsGeocodeUseableForMapping DEFAULT 0,
StandardizedGeocodeAccuracy NVARCHAR(40) NULL,                  /*  Standardized transform Bing, Google, PB, etc. */
StandardizedGeocodePrecision NVARCHAR(40) NULL,
GeocodeSource_fk INT  NOT NULL CONSTRAINT DF_POI_GeocodeSource_fk DEFAULT 0,
GeocodeDate DATETIME NULL,

/* Where did the data record originate. */
DataSource_fk  INT NOT NULL CONSTRAINT DF_POI_DataSource_fk DEFAULT 0,
DataSourceNaturalKey NVARCHAR(40) NOT NULL,
CreatedOnDate DATETIME NULL CONSTRAINT DF_POI_CreatedOnDate DEFAULT CURRENT_TIMESTAMP,
LastUpdateDate DATETIME NULL CONSTRAINT DF_POI_LastUpdateDate  DEFAULT CURRENT_TIMESTAMP

)
ON Secondary;

GO

/*
    Triggers on AppData.POI

    1.  Maintain the Last Update Date
    2.  Main the spatial data element.  Done as a trigger because I'm assuing some sort of management tool.

*/
IF OBJECT_ID (N'AppData.trgPOI_LastUpdateDate', 'TR') IS NOT NULL
   DROP TRIGGER AppData.trgPOI_LastUpdateDate;
GO

CREATE TRIGGER [trgPOI_LastUpdateDate]
	ON AppData.POI
	FOR INSERT, UPDATE
	AS
	BEGIN

		SET NOCOUNT ON;

		DECLARE @Now DATETIME = CURRENT_TIMESTAMP;
		
		UPDATE x
		SET LastUpdateDate=@Now
		FROM AppData.POI x
		JOIN inserted i ON i.POI_pk = x.POI_pk;

	END
GO
IF OBJECT_ID (N'AppData.trgPOI_MapPoint', 'TR') IS NOT NULL
   DROP TRIGGER AppData.trgPOI_MapPoint;
GO

CREATE TRIGGER [trgPOI_MapPoint]
	ON AppData.POI
	FOR INSERT, UPDATE
	AS
	BEGIN

		SET NOCOUNT ON;
		
                        /*  Per Business rule, the SRID is required to be SRID. If the accuacy is considered good enough, then its OK to map it. */

		UPDATE x
		SET MapPoint = 
                                CASE
                                    WHEN  i.IsGeocodeUseableForMapping = 1 THEN geography::Point(i.Latitude, i.Longitude, 4326)
                                    ELSE NULL
                                 END
		FROM AppData.POI x
		JOIN inserted i ON i.POI_pk = x.POI_pk

	END

GO

/* 

    Foreign Key tables 

*/

 /*  
    Subcategory cafe, ATM. cemetary.

    Category TBD

*/

IF OBJECT_ID(N'AppData.POISubcategory') IS NOT NULL
        --IF NOT EXISTS (SELECT TOP 1 * FROM AppData.POISubcategory)
                DROP TABLE AppData.POISubcategory;
GO
CREATE TABLE  AppData.POISubcategory
(
POISubcategory_pk INT NOT NULL CONSTRAINT PK_POISubcategory PRIMARY KEY,
POICategory_fk INT NOT NULL,
POISubcategoryName NVARCHAR(40) NOT NULL,
LastUpdateDate DATETIME NULL CONSTRAINT DF_POISubcategory_LastUpdateDate  DEFAULT CURRENT_TIMESTAMP
)
ON Secondary;
GO
INSERT INTO AppData.POISubcategory (POISubcategory_pk, POICategory_fk, POISubcategoryName) VALUES(0, 0, 'None');
GO

 /*  
    Geocode source (e.g., Bing, Melissa, Google, Location Services, etc.

*/

 IF OBJECT_ID(N'AppData.GeocodeSource') IS NOT NULL
    --IF NOT EXISTS (SELECT TOP 1 * FROM AppData.GeocodeSource)
           DROP TABLE AppData.GeocodeSource;
GO
CREATE TABLE  AppData.GeocodeSource
(
GeocodeSource_pk INT NOT NULL CONSTRAINT PK_GeocodeSource PRIMARY KEY,
GeocodeSource NVARCHAR(40) NOT NULL
)
ON Secondary;
GO
INSERT INTO AppData.GeocodeSource (GeocodeSource_pk, GeocodeSource) VALUES(0, 'None');
GO

IF OBJECT_ID(N'AppData.DataSource') IS NOT NULL
    --IF NOT EXISTS (SELECT TOP 1 * FROM AppData.DataSource)
           DROP TABLE AppData.DataSource;
GO
CREATE TABLE  AppData.DataSource
(
DataSource_pk INT NOT NULL CONSTRAINT PK_DataSource PRIMARY KEY,
DataSource NVARCHAR(40) NOT NULL
)
ON Secondary;
GO
INSERT INTO AppData.DataSource (DataSource_pk, DataSource) VALUES(0, 'None');

GO

ALTER TABLE AppData.POI  WITH CHECK ADD  CONSTRAINT FKC_POI_POISubcategory FOREIGN KEY(POISubcategory_fk) 
        REFERENCES  AppData.POISubcategory (POISubcategory_pk) 
;
ALTER TABLE AppData.POI  WITH CHECK ADD  CONSTRAINT FKC_POI_GeocodeSource FOREIGN KEY(GeocodeSource_fk) 
        REFERENCES  AppData.GeocodeSource (GeocodeSource_pk) 
;
ALTER TABLE AppData.POI  WITH CHECK ADD  CONSTRAINT FKC_POI_DataSource FOREIGN KEY(DataSource_fk) 
        REFERENCES  AppData.DataSource (DataSource_pk) 
;