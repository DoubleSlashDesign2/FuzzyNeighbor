USE FuzzyNeighbor;
GO

IF OBJECT_ID(N'[AppData].[LanguageClass]') IS NOT NULL
    DROP TABLE [AppData].[LanguageClass];
GO
CREATE TABLE [AppData].[LanguageClass]
(
LanguageCode_pk NCHAR(2)  NOT NULL CONSTRAINT PK_LanguageCode PRIMARY KEY,  --ISO 639-1 
LanguageName NVARCHAR(256) NOT NULL
)
ON SECONDARY;
GO
INSERT INTO [AppData].[LanguageClass] (LanguageCode_pk, LanguageName) VALUES
 ('EN', ' English'), 
('ES', 'Spanish');

GO

IF OBJECT_ID(N'[AppData].[TokenFilter]') IS NOT NULL
    DROP TABLE [AppData].[TokenFilter];
GO
CREATE TABLE [AppData].[TokenFilter]
(
TokenFilter_pk INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_TokenFilter PRIMARY KEY,
Token NVARCHAR(256) NOT NULL,
LanguageCode_fk NCHAR(2) NOT NULL
)
ON SECONDARY;
GO
ALTER TABLE AppData.TokenFilter  WITH CHECK ADD  CONSTRAINT FKC_TokenFilter_Language FOREIGN KEY(LanguageCode_fk) 
        REFERENCES  AppData.LanguageClass (LanguageCode_pk) 
;
GO
INSERT INTO [AppData].[TokenFilter] (Token, LanguageCode_fk) VALUES
 ('the','EN'), 
 ('a','EN'), 
 ('an','EN'), 
('la','ES'),
('las','ES'),
('el','ES'),
('lo','ES'),
('los','ES')
;

GO
SELECT * FROM [AppData].[TokenFilter];
