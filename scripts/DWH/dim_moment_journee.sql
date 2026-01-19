CREATE OR REPLACE TABLE `dashboardstrava1.strava_dwh.dim_moment_journee` AS
SELECT 'Matin' AS moment_id, '05:00 - 11:59' AS tranche_horaire, 1 AS ordre_tri
UNION ALL SELECT 'Midi', '12:00 - 13:59', 2
UNION ALL SELECT 'Après-midi', '14:00 - 17:59', 3
UNION ALL SELECT 'Soir', '18:00 - 22:59', 4
UNION ALL SELECT 'Nuit', '23:00 - 04:59', 5;