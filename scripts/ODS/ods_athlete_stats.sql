CREATE OR REPLACE TABLE `dashboardstrava1.strava_ods.ods_athlete_stats` AS
SELECT
    -- Extraction des totaux Course à pied
    CAST(JSON_VALUE(all_run_totals, '$.count') AS INT64) AS total_run_count,
    CAST(JSON_VALUE(all_run_totals, '$.distance') AS FLOAT64) AS total_run_distance,
    CAST(JSON_VALUE(all_run_totals, '$.moving_time') AS INT64) AS total_run_moving_time,

    -- Extraction des totaux Natation
    CAST(JSON_VALUE(all_swim_totals, '$.count') AS INT64) AS total_swim_count,
    CAST(JSON_VALUE(all_swim_totals, '$.distance') AS FLOAT64) AS total_swim_distance,

    -- Records
    CAST(biggest_ride_distance AS FLOAT64) AS record_distance_velo,
    CAST(biggest_climb_elevation_gain AS FLOAT64) AS record_denivele_velo

FROM `dashboardstrava1.strava_raw.athlete_stats`;