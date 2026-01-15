CREATE OR REPLACE TABLE `dashboardstrava1.strava_dwh.fct_global_stats` AS
SELECT
    -- Totaux Course à pied
    total_run_count,
    ROUND(total_run_distance / 1000, 2) AS total_run_distance_km,
    ROUND(total_run_moving_time / 3600, 2) AS total_run_hours,

    -- Totaux Natation
    total_swim_count,
    ROUND(total_swim_distance / 1000, 2) AS total_swim_distance_km,

    -- Records Vélo
    ROUND(record_distance_velo / 1000, 2) AS record_distance_velo_km,
    record_denivele_velo AS record_denivele_velo_m

FROM `dashboardstrava1.strava_ods.ods_athlete_stats`;