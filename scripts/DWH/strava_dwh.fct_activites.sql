CREATE OR REPLACE TABLE `dashboardstrava1.strava_dwh.fct_activites` AS
SELECT
    -- Clé Date
    FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP(start_date_local))) AS date_id,

    -- Clé Moment
    CASE
        WHEN EXTRACT(HOUR FROM TIMESTAMP(start_date_local)) BETWEEN 5 AND 11 THEN 'Matin'
        WHEN EXTRACT(HOUR FROM TIMESTAMP(start_date_local)) BETWEEN 12 AND 13 THEN 'Midi'
        WHEN EXTRACT(HOUR FROM TIMESTAMP(start_date_local)) BETWEEN 14 AND 17 THEN 'Après-midi'
        WHEN EXTRACT(HOUR FROM TIMESTAMP(start_date_local)) BETWEEN 18 AND 22 THEN 'Soir'
        ELSE 'Nuit'
        END AS moment_id,

    id AS activite_id,
    name AS nom_activite,
    type AS type_sport,

    -- Mesures calculées
    ROUND(distance / 1000, 2) AS distance_km,
    ROUND(moving_time / 60, 2) AS duree_minutes,
    ROUND(average_speed * 3.6, 2) AS vitesse_moyenne_kmh,

    -- Allure
    ROUND(SAFE_DIVIDE((moving_time / 60), (distance / 1000)), 2) AS allure_min_km,

    total_elevation_gain AS denivele_positif,
    kudos_count,
    achievement_count

FROM `dashboardstrava1.strava_ods.ods_activites`;