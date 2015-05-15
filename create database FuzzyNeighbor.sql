Use Master
GO
CREATE DATABASE [FuzzyNeighbor]
CONTAINMENT = NONE
ON   (NAME = N'FuzzyNeighbor', FILENAME = N'C:\SS 2014 MDFs\FuzzyNeighbor_Pri.mdf', SIZE = 4145153KB, MAXSIZE = UNLIMITED , FILEGROWTH = 1024KB)
        LOG ON (NAME = N'FuzzyNeighbor_log', FILENAME = N'C:\SS 2014 MDFs\FuzzyNeighbor_log.ldf', SIZE = 768KB, MAXSIZE = UNLIMITED , FILEGROWTH = 10%)
COLLATE SQL_Latin1_General_CP1_CI_AS
WITH 
        FILESTREAM (NON_TRANSACTED_ACCESS = OFF),
        DB_CHAINING OFF,
        TRUSTWORTHY OFF;
GO
ALTER DATABASE [FuzzyNeighbor] ADD FILEGROUP [Secondary];
GO
ALTER DATABASE [FuzzyNeighbor] ADD FILE (NAME = N'FuzzyNeighbor_sec', FILENAME = N'C:\SS 2014 MDFs\FuzzyNeighbor_Sec.ndf', SIZE = 2254785KB, MAXSIZE = UNLIMITED , FILEGROWTH = 1024000KB) TO FILEGROUP [Secondary];
GO
ALTER DATABASE [FuzzyNeighbor] ADD FILEGROUP [IndexFileGroup];
GO
ALTER DATABASE [FuzzyNeighbor] ADD FILE (NAME = N'FuzzyNeighbor_ind', FILENAME = N'C:\SS 2014 MDFs\FuzzyNeighbor_ind.ndf', SIZE = 1024000KB, MAXSIZE = UNLIMITED , FILEGROWTH = 1024000KB) TO FILEGROUP [IndexFileGroup];
GO
ALTER DATABASE [FuzzyNeighbor] MODIFY FILEGROUP [Secondary] DEFAULT;
GO


--Add Schemas

Use FuzzyNeighbor
GO

CREATE SCHEMA [AppData];
GO
CREATE SCHEMA [AppDataStage];
GO
CREATE SCHEMA [App];
GO
CREATE SCHEMA [UserData];
GO