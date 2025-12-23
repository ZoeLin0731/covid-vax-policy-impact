DROP TABLE IF EXISTS mart.covid_country_date_fact;

CREATE TABLE mart.covid_country_date_fact AS
WITH cases AS (
    SELECT
        country,
        date,
        new_cases,
        new_deaths,
        new_cases_per_million,
        new_deaths_per_million,
        new_cases_7_day_avg_right  AS new_cases_7d_avg,
        new_deaths_7_day_avg_right AS new_deaths_7d_avg,
        total_cases_per_million,
        total_deaths_per_million
    FROM raw.cases_deaths
),
vax AS (
    SELECT
        country,
        date,
        people_vaccinated_per_hundred,
        people_fully_vaccinated_per_hundred,
        total_boosters_per_hundred,
        daily_vaccinations_smoothed
    FROM raw.vaccinations
),
policy AS (
    SELECT
        country,
        date,
        stringency_index,
        containment_health_index,
        stringency_index_vax,
        stringency_index_nonvax
    FROM raw.gov_response
)
SELECT
    c.country,
    c.date,
    -- outcomes
    c.new_cases,
    c.new_deaths,
    c.new_cases_per_million,
    c.new_deaths_per_million,
    c.new_cases_7d_avg,
    c.new_deaths_7d_avg,
    c.total_cases_per_million,
    c.total_deaths_per_million,
    -- vaccination
    v.people_vaccinated_per_hundred,
    v.people_fully_vaccinated_per_hundred,
    v.total_boosters_per_hundred,
    v.daily_vaccinations_smoothed,
    -- policy
    p.stringency_index,
    p.containment_health_index,
    p.stringency_index_vax,
    p.stringency_index_nonvax
FROM cases c
LEFT JOIN vax v
  ON c.country = v.country
 AND c.date    = v.date
LEFT JOIN policy p
  ON c.country = p.country
 AND c.date    = p.date;




