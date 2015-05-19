USE FuzzyNeighbor;
GO

INSERT INTO AppData.POICategory (POICategory_pk, POICategoryName)   VALUES 
(3, N'Public Transport'),
(1, N'Emergency/Aid'),
(4, N'Sport'),
(2, N'Landuse'),
(5, N'Building')
;
--SELECT * FROM AppData.POICategory;


INSERT INTO [AppData].[POISubcategory]([POISubcategory_pk], [POICategory_fk], [POISubcategoryName])  VALUES
(1, 4, N'Stadium'),
(2, 2, N'Cemetary' )
;
GO

SELECT
*
FROM [AppData].[vSubCategoryCategoryXRef]
ORDER BY POICategoryName, POISubcategoryName

/*
http://wiki.openstreetmap.org/wiki/Map_Features
*/

/*

Mountainous landforms	
Butte Hill Mountain Mountain range Ridge Plateau Valley Flat

Continental plain	
Ice sheet Plain Steppe Tundra

River landforms	
Lake Meander Rapid River River delta River mouth River valley Waterfall

Fluvial landforms	
Alluvial fan Beach Canyon Cave Channel Cliff Floodplain Levee Oasis Pond River delta Strait Swamp

Glacial landforms	
Arête Cirque Esker Fjord Glacier Tunnel valley

Oceanic and coastal landforms	
Atoll Bay Cape Channel Coast Continental shelf Coral reef Estuary High island Island Isthmus Lagoon Mid-ocean ridge Oceanic trench Peninsula Seamount

Volcanic landforms	
Caldera Crater lake Geyser High island Mid-ocean ridge Lava dome Lava field Lava plateau Submarine volcano Guyot Volcanic crater Volcanic plug Volcano Wall rock

Aeolian landforms	
Desert Dry lake Dune Sandhill Tundra

Artificial landforms
Artificial island Artificial reef  Bridge Building Canal (man-made) Dam Ditch Land reclamation Levee Polder Quarry Reservoir Road Tunnel
*/