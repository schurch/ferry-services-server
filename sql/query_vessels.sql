SELECT mmsi, updated, name, X(location) as latitude, Y(location) as longitude, speed, course, status
FROM vessels
WHERE ST_CONTAINS(ST_Envelope(ST_GeomFromText('LineString(55.709319 -5.021439, 55.638897 -4.817119)')), location);

-- POLYGON((MINX MINY, MAXX MINY, MAXX MAXY, MINX MAXY, MINX MINY))
-- mysql> SELECT ST_AsText(ST_Envelope(ST_GeomFromText('LineString(1 1,2 2)')));
-- +----------------------------------------------------------------+
-- | ST_AsText(ST_Envelope(ST_GeomFromText('LineString(1 1,2 2)'))) |
-- +----------------------------------------------------------------+
-- | POLYGON((1 1,2 1,2 2,1 2,1 1))                                 |
-- +----------------------------------------------------------------+
