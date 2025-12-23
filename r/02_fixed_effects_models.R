# 1. Install + load packages (once)

# install.packages("fixest")

library(DBI)
library(RPostgres)
library(dplyr)
library(fixest)

con <- dbConnect(
    RPostgres::Postgres(),
    host     = "localhost",
    port     = 5432,
    dbname   = "covid_owid",
    user     = "zoelin",
    password = "YOUR_PASSWORD"
)

# 2. Pull the same weekly lagged data
df <- dbGetQuery(con, "
  SELECT
    country,
    week_start,
    avg_deaths_per_million,
    vax_coverage_lag_2w,
    vax_coverage_lag_4w,
    avg_stringency
  FROM mart.covid_country_week_lagged
") %>%
    mutate(week_start = as.Date(week_start)) %>%
    filter(
        !is.na(avg_deaths_per_million),
        !is.na(vax_coverage_lag_2w),
        !is.na(avg_stringency)
    )
# 3. Fixed-effects model (2-week lag)
fe_2w <- feols(
    avg_deaths_per_million ~ vax_coverage_lag_2w + avg_stringency |
        country + week_start,
    cluster = ~country,
    data = df
)

summary(fe_2w)

# 4. Robustness: 4-week lag
fe_4w <- feols(
    avg_deaths_per_million ~ vax_coverage_lag_4w + avg_stringency |
        country + week_start,
    cluster = ~country,
    data = df
)

summary(fe_4w)

# Formal hypothesis conclusion 

# After introducing country and week fixed effects to control for unobserved heterogeneity and global time shocks, 
# we find statistically significant evidence that increased vaccination coverage is associated with reductions in COVID-19 mortality at both 2- and 4-week lags. 
# Accordingly, the null hypothesis is rejected in the fixed-effects specification, 
# suggesting that within-country increases in vaccination coverage are linked to lower subsequent mortality.






