CREATE OR REPLACE TABLE `dashboardstrava1.strava_dwh.dim_calendar` AS
SELECT
    FORMAT_DATE('%Y%m%d', jour) AS date_id,
    jour AS date_complete,
    EXTRACT(YEAR FROM jour) AS annee,
    EXTRACT(MONTH FROM jour) AS mois,


    CASE EXTRACT(MONTH FROM jour)
        WHEN 1 THEN 'Janvier' WHEN 2 THEN 'Février' WHEN 3 THEN 'Mars'
        WHEN 4 THEN 'Avril' WHEN 5 THEN 'Mai' WHEN 6 THEN 'Juin'
        WHEN 7 THEN 'Juillet' WHEN 8 THEN 'Août' WHEN 9 THEN 'Septembre'
        WHEN 10 THEN 'Octobre' WHEN 11 THEN 'Novembre' WHEN 12 THEN 'Décembre'
        END AS nom_mois,


    CASE EXTRACT(DAYOFWEEK FROM jour)
        WHEN 1 THEN 'Dimanche' WHEN 2 THEN 'Lundi' WHEN 3 THEN 'Mardi'
        WHEN 4 THEN 'Mercredi' WHEN 5 THEN 'Jeudi' WHEN 6 THEN 'Vendredi'
        WHEN 7 THEN 'Samedi'
        END AS nom_jour,

    EXTRACT(QUARTER FROM jour) AS trimestre,
    IF(EXTRACT(MONTH FROM jour) <= 6, 1, 2) AS semestre,
    IF(EXTRACT(DAYOFWEEK FROM jour) IN (1, 7), TRUE, FALSE) AS est_weekend
FROM
    -- Génère les dates de 2020 à 2026
    UNNEST(GENERATE_DATE_ARRAY('2020-01-01', '2026-12-31')) AS jour;