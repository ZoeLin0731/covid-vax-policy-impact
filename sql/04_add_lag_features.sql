DROP TABLE IF EXISTS mart.covid_country_week_lagged;

CREATE TABLE mart.covid_country_week_lagged AS
SELECT
    *,
    /* vaccination lags */
    LAG(vax_coverage_pct, 2) OVER w  AS vax_coverage_lag_2w,
    LAG(vax_coverage_pct, 4) OVER w  AS vax_coverage_lag_4w,
    LAG(fully_vax_coverage_pct, 2) OVER w AS fully_vax_lag_2w,
    LAG(fully_vax_coverage_pct, 4) OVER w AS fully_vax_lag_4w,
    /* policy lag (optional but useful) */
    LAG(avg_stringency, 2) OVER w AS stringency_lag_2w
FROM mart.covid_country_week_fact
WINDOW w AS (
    PARTITION BY country
    ORDER BY week_start
);

-- Snity Check
SELECT COUNT(*) FROM mart.covid_country_week_fact;
SELECT COUNT(*) FROM mart.covid_country_week_lagged;

SELECT
    MIN(week_start),
    MAX(week_start)
FROM mart.covid_country_week_lagged;

SELECT
    COUNT(*) FILTER (WHERE vax_coverage_lag_2w IS NULL) AS lag_nulls,
    COUNT(*) AS total_rows
FROM mart.covid_country_week_lagged;