CREATE OR REPLACE TABLE `dashboardstrava1.strava_dwh.dim_calendar` AS
SELECT
    FORMAT_DATE('%Y%m%d', jour) AS date_id,
    jour AS date_complete,
    EXTRACT(YEAR FROM jour) AS annee,
    EXTRACT(MONTH FROM jour) AS mois,
    FORMAT_DATE('%B', jour) AS nom_mois,
    FORMAT_DATE('%A', jour) AS nom_jour,
    EXTRACT(QUARTER FROM jour) AS trimestre,
    IF(EXTRACT(MONTH FROM jour) <= 6, 1, 2) AS semestre,
    IF(EXTRACT(DAYOFWEEK FROM jour) IN (1, 7), TRUE, FALSE) AS est_weekend
FROM
    UNNEST(GENERATE_DATE_ARRAY('2020-01-01', '2026-12-31')) AS jour;