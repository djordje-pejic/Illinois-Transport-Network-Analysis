--Examines the the number of valid/invalid road geometries using PostGIS

--Used PostGIS ST_IsValidDetail function that returns (t,,) if the road geometry is valid
--if it is not, it returns the reason

--Used road_illinois_m dataset
SELECT 
	COUNT(geom) as count_records,
    COUNT(CASE WHEN ST_IsValidDetail(geom) = '(t,,)'::valid_detail THEN 1 END) AS valid, 
    COUNT(CASE WHEN ST_IsValidDetail(geom) <> '(t,,)'::valid_detail THEN 1 END) AS invalid
FROM roads_illinois_m

--Calculating how far Chicago businesses are from closest street (representet with a line geometry)
--Creating two CTEs: one with buffer of 5 meters and one without

--Uses PostGIS function ST_Distance to calculate the distance between two geometries
--Uses PostGIS function ST_Buffer to add a buffer of 5 meters
--Uses ST_ClosestPoint to find the closest point to a business on a road linestring

--Used business dataset, road_illinois_m dataset
WITH with_buffer AS (SELECT business, MIN(ST_Distance(closest_point, b_geom)) AS buffered
FROM(
SELECT 
    roads_illinois_m.id as road, roads_illinois_m.geom, businesses_m.id as business, ST_Buffer(businesses_m.geom, 5) as b_geom,
    ST_ClosestPoint(roads_illinois_m.geom, businesses_m.geom) as closest_point
  FROM 
    roads_illinois_m,
    businesses_m) as closest_line
GROUP BY business
ORDER BY MIN(ST_Distance(closest_point, b_geom)) ASC),

without_buffer AS (SELECT business, MIN(ST_Distance(closest_point, b_geom)) AS not_buffered
FROM(
SELECT 
    roads_illinois_m.id as road, roads_illinois_m.geom, businesses_m.id as business, businesses_m.geom as b_geom,
    ST_ClosestPoint(roads_illinois_m.geom, businesses_m.geom) as closest_point
  FROM 
    roads_illinois_m,
    businesses_m) as closest_line
GROUP BY business
ORDER BY MIN(ST_Distance(closest_point, b_geom)) ASC)

--All business records and their buffered/unbuffered distances from the closes road geometry 
SELECT with_buffer.business, without_buffer.not_buffered, with_buffer.buffered
FROM without_buffer
INNER JOIN with_buffer
ON without_buffer.business = with_buffer.business
ORDER BY buffered ASC

--The number of businesses that have 0 as distance and number of businesses that do not
SELECT COUNT(CASE WHEN with_buffer.buffered = 0 THEN 1 END) as zero,
COUNT(CASE WHEN with_buffer.buffered != 0 THEN 1 END) as one
FROM with_buffer

--Examines road classes
SELECT roads_illinois_m.class, COUNT(*) as total
FROM roads_illinois_m
GROUP BY roads_illinois_m.class

--Examines road types
SELECT roads_illinois_m.type, COUNT(*) 
FROM roads_illinois_m
GROUP BY roads_illinois_m.type

--Examines road types per road class
SELECT class, type, COUNT(*)
FROM roads_illinois_m
GROUP BY class, type
ORDER BY class