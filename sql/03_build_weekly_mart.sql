SELECT COUNT(*) FROM mart.covid_country_date_fact;

SELECT
    MIN(date),
    MAX(date)
FROM mart.covid_country_date_fact;

SELECT
    COUNT(*) FILTER (WHERE people_vaccinated_per_hundred IS NULL) AS vax_nulls,
    COUNT(*) AS total_rows
FROM mart.covid_country_date_fact;

DROP TABLE IF EXISTS mart.covid_country_week_fact;

CREATE TABLE mart.covid_country_week_fact AS
SELECT
    country,
    date_trunc('week', date)::date AS week_start,
    /* outcomes: sum or avg, intentionally chosen */
    SUM(new_cases)                     AS weekly_new_cases,
    SUM(new_deaths)                    AS weekly_new_deaths,
    AVG(new_cases_per_million)         AS avg_cases_per_million,
    AVG(new_deaths_per_million)        AS avg_deaths_per_million,
    AVG(new_cases_7d_avg)              AS avg_cases_7d,
    AVG(new_deaths_7d_avg)             AS avg_deaths_7d,
    /* vaccination: levels and flow */
    AVG(people_vaccinated_per_hundred)        AS vax_coverage_pct,
    AVG(people_fully_vaccinated_per_hundred)  AS fully_vax_coverage_pct,
    AVG(total_boosters_per_hundred)            AS boosters_pct,
    AVG(daily_vaccinations_smoothed)           AS avg_daily_vax,
    /* policy: average stringency over the week */
    AVG(stringency_index)               AS avg_stringency,
    AVG(containment_health_index)       AS avg_containment,
    AVG(stringency_index_vax)           AS avg_stringency_vax,
    AVG(stringency_index_nonvax)        AS avg_stringency_nonvax
FROM mart.covid_country_date_fact
GROUP BY
    country,
    date_trunc('week', date);