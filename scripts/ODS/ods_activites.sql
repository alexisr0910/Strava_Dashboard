CREATE OR REPLACE TABLE `dashboardstrava1.strava_ods.ods_activites` AS
SELECT
    -- Identité
    id, name, type, external_id,

    -- Dates
    start_date_local, timezone,

    -- Physique (Déjà en NUMERIC/INTEGER d'après ton test)
    distance, moving_time, elapsed_time, total_elevation_gain,

    -- Altitudes
    elev_low, elev_high,

    -- Vitesse
    average_speed, max_speed,

    -- Social
    kudos_count, comment_count, achievement_count

FROM `dashboardstrava1.strava_raw.activities`;