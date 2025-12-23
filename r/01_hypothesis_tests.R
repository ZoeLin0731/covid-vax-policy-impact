# ------------------------------------------------------------
# Hypothesis Test (R) — Vaccination Coverage vs COVID Mortality
# Data source: PostgreSQL mart.covid_country_week_lagged
#
# Hypothesis 1:
#   H0: beta = 0  (no association between lagged vax coverage and deaths)
#   H1: beta < 0  (higher lagged vax coverage is associated with lower deaths)
# ------------------------------------------------------------

# 0) Packages ----
# install.packages(c("DBI", "RPostgres", "dplyr", "lubridate", "broom", "sandwich", "lmtest"))

# install.packages(c(
#    "RPostgres",
#    "sandwich",
#    "lmtest",
#    "broom",
#    "dplyr",
#    "lubridate",
#    "DBI"
#))

library(DBI)
library(RPostgres)
library(dplyr)
library(broom)
library(sandwich)
library(lmtest)


# 1) Connect to PostgreSQL ----
# Option A (recommended): environment variables
# Sys.setenv(PGHOST="localhost", PGPORT="5432", PGDATABASE="covid_owid", PGUSER="...", PGPASSWORD="...")

con <- dbConnect(
    RPostgres::Postgres(),
    host     = "localhost",
    port     = 5432,
    dbname   = "covid_owid",
    user     = "zoelin",
    password = "YOUR_POSTGRES_PASSWORD"
)

# Quick connection test
dbGetQuery(con, "SELECT 1 AS ok;")
dbGetQuery(con, "SELECT COUNT(*) FROM mart.covid_country_week_lagged;")

# 2) Pull analysis dataset (weekly + lagged) ----
query <- "
SELECT
  country,
  week_start,
  avg_deaths_per_million,
  avg_cases_per_million,
  vax_coverage_lag_2w,
  vax_coverage_lag_4w,
  avg_stringency,
  stringency_lag_2w
FROM mart.covid_country_week_lagged;
"

df <- dbGetQuery(con, query) %>%
    mutate(
        week_start = as.Date(week_start)
    )

# 3) Basic filtering (keep it minimal + defensible) ----
# We need non-missing outcome and main predictors
df_model <- df %>%
    filter(
        !is.na(avg_deaths_per_million),
        !is.na(vax_coverage_lag_2w),
        !is.na(avg_stringency)
    )

# Optional: remove extreme early weeks where deaths are essentially zero everywhere
# (You can comment this out if you want to keep everything.)
df_model <- df_model %>%
    filter(avg_deaths_per_million >= 0)

# Quick sanity print
cat("Rows in model dataset:", nrow(df_model), "\n")
cat("Countries in model dataset:", n_distinct(df_model$country), "\n")
cat("Date range:", min(df_model$week_start), "to", max(df_model$week_start), "\n")

# 4) Model specification (Hypothesis 1) ----
# Outcome: avg_deaths_per_million
# Main predictor: vax_coverage_lag_2w (coverage %)
# Control: avg_stringency
#
# Interpretation:
# beta < 0 means higher vaccination coverage (2-week lag) associates with lower deaths

m1 <- lm(
    avg_deaths_per_million ~ vax_coverage_lag_2w + avg_stringency,
    data = df_model
)

# 5) Robust SEs (country-clustered) ----
# This is important because observations within a country are correlated over time.
# We cluster by country to avoid overstating significance.

vcov_country <- vcovCL(m1, cluster = df_model$country, type = "HC1")
m1_robust <- coeftest(m1, vcov. = vcov_country)

print(m1_robust)

# 6) One-sided hypothesis test: H1 beta < 0 ----
# coeftest returns two-sided p-values; convert to one-sided for beta < 0.
beta_hat <- coef(m1)["vax_coverage_lag_2w"]
se_hat   <- sqrt(vcov_country["vax_coverage_lag_2w", "vax_coverage_lag_2w"])
t_stat   <- beta_hat / se_hat
df_approx <- m1$df.residual

# One-sided p-value for H1: beta < 0
p_one_sided <- pt(t_stat, df = df_approx, lower.tail = TRUE)

cat("\n--- One-sided test for H1: beta < 0 ---\n")
cat("beta_hat:", beta_hat, "\n")
cat("t_stat:", t_stat, "\n")
cat("one-sided p-value:", p_one_sided, "\n")

# 7) 95% CI (robust, approximate) ----
# (For reporting; even with one-sided H1, CI is useful.)
z <- qt(0.975, df = df_approx)
ci_low  <- beta_hat - z * se_hat
ci_high <- beta_hat + z * se_hat

cat("\n--- Approx. 95% CI (cluster-robust) for beta ---\n")
cat("[", ci_low, ",", ci_high, "]\n")

# 8) Robustness check: 4-week lag ----
df_model_4w <- df %>%
    filter(
        !is.na(avg_deaths_per_million),
        !is.na(vax_coverage_lag_4w),
        !is.na(avg_stringency)
    )

m2 <- lm(
    avg_deaths_per_million ~ vax_coverage_lag_4w + avg_stringency,
    data = df_model_4w
)

vcov_country_m2 <- vcovCL(m2, cluster = df_model_4w$country, type = "HC1")
m2_robust <- coeftest(m2, vcov. = vcov_country_m2)

cat("\n--- Robustness check (4-week lag) ---\n")
print(m2_robust)

# 9) Save tidy results for reporting ----
tidy_m1 <- broom::tidy(m1) %>%
    mutate(model = "lag_2w")

tidy_m2 <- broom::tidy(m2) %>%
    mutate(model = "lag_4w")

results <- bind_rows(tidy_m1, tidy_m2)

getwd()

# Optional: write CSV for your report
write.csv(results, "/Users/zoelin/Documents/GitHub/covid-vax-policy-impact/reports/model_results_hypothesis1.csv", row.names = FALSE)

# 10) Close connection ----
dbDisconnect(con)

# Formal statistical conclusion (what you write in a report)

# Using a weekly country-level panel with cluster-robust standard errors, 
# we find no statistically significant evidence that lagged vaccination coverage (2- or 4-week lag) 
# is associated with reductions in COVID-19 mortality after controlling for government response stringency. 
# The null hypothesis cannot be rejected at conventional significance levels. 
# In contrast, policy stringency exhibits a strong and statistically significant association with mortality outcomes.










