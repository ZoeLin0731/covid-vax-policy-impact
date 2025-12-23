# ------------------------------------------------------------
# Visualizations for Policy-Facing Results
# Outputs saved to: reports/figures/
# ------------------------------------------------------------

library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)
library(fixest)

# 0) Ensure output folder exists
if (!dir.exists("reports")) dir.create("reports")
if (!dir.exists("reports/figures")) dir.create("reports/figures", recursive = TRUE)

# 1) Connect to DB
con <- dbConnect(
    RPostgres::Postgres(),
    host = "localhost",
    port = 5432,
    dbname = "covid_owid",
    user = "zoelin",
    password = Sys.getenv("PGPASSWORD")  # or hardcode temporarily
)

df <- dbGetQuery(con, "
  SELECT
    country,
    week_start,
    avg_deaths_per_million,
    vax_coverage_pct,
    vax_coverage_lag_2w,
    vax_coverage_lag_4w,
    avg_stringency
  FROM mart.covid_country_week_lagged;
") %>%
    mutate(week_start = as.Date(week_start))

dbDisconnect(con)

# ------------------------------------------------------------
# Figure 1: Fixed Effects Coefficient Plot
# ------------------------------------------------------------

df_fe <- df %>%
    filter(!is.na(avg_deaths_per_million),
           !is.na(vax_coverage_lag_2w),
           !is.na(avg_stringency))

fe_2w <- feols(
    avg_deaths_per_million ~ vax_coverage_lag_2w + avg_stringency | country + week_start,
    cluster = ~country,
    data = df_fe
)

df_fe_4w <- df %>%
    filter(!is.na(avg_deaths_per_million),
           !is.na(vax_coverage_lag_4w),
           !is.na(avg_stringency))

fe_4w <- feols(
    avg_deaths_per_million ~ vax_coverage_lag_4w + avg_stringency | country + week_start,
    cluster = ~country,
    data = df_fe_4w
)

# Extract coefficients + 95% CI
coef_to_df <- function(model, model_name){
    b <- coef(model)
    se <- sqrt(diag(vcov(model)))
    terms <- names(b)
    out <- data.frame(
        model = model_name,
        term = terms,
        estimate = as.numeric(b),
        se = as.numeric(se)
    ) %>%
        mutate(
            ci_low = estimate - 1.96 * se,
            ci_high = estimate + 1.96 * se
        )
    out
}

coef_df <- bind_rows(
    coef_to_df(fe_2w, "FE (Lag 2w)"),
    coef_to_df(fe_4w, "FE (Lag 4w)")
) %>%
    filter(term %in% c("vax_coverage_lag_2w", "vax_coverage_lag_4w", "avg_stringency")) %>%
    mutate(
        term_label = case_when(
            term == "vax_coverage_lag_2w" ~ "Vaccination coverage (lag 2w)",
            term == "vax_coverage_lag_4w" ~ "Vaccination coverage (lag 4w)",
            term == "avg_stringency" ~ "Policy stringency (weekly avg)",
            TRUE ~ term
        )
    )

p1 <- ggplot(coef_df, aes(x = estimate, y = term_label)) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_point(size = 2) +
    geom_errorbarh(aes(xmin = ci_low, xmax = ci_high), height = 0.2) +
    facet_wrap(~ model) +
    labs(
        title = "Estimated effects on weekly COVID-19 deaths (two-way fixed effects)",
        subtitle = "Outcome: avg deaths per million | SE clustered by country | 95% CI shown",
        x = "Coefficient estimate (deaths per million per week)",
        y = ""
    ) +
    theme_minimal(base_size = 12)

ggsave("reports/figures/fig1_fe_coefficients.png", p1, width = 10, height = 5, dpi = 300)

# ------------------------------------------------------------
# Figure 2: Country-level time series (policy-maker story)
# ------------------------------------------------------------

# Pick a few countries (you can change this list anytime)
focus <- c("United States", "United Kingdom", "Canada")

df_focus <- df %>%
    filter(country %in% focus) %>%
    filter(week_start >= as.Date("2020-03-01")) %>%
    select(country, week_start, avg_deaths_per_million, vax_coverage_pct, avg_stringency)

# Normalize to show multiple lines on one plot (simple, policy-friendly)
# We'll standardize within each country to keep comparisons readable.
df_focus_scaled <- df_focus %>%
    group_by(country) %>%
    mutate(
        deaths_z = as.numeric(scale(avg_deaths_per_million)),
        vax_z = as.numeric(scale(vax_coverage_pct)),
        stringency_z = as.numeric(scale(avg_stringency))
    ) %>%
    ungroup()

df_long <- df_focus_scaled %>%
    tidyr::pivot_longer(
        cols = c(deaths_z, vax_z, stringency_z),
        names_to = "series",
        values_to = "value"
    ) %>%
    mutate(
        series = recode(series,
                        deaths_z = "Deaths (per million, standardized)",
                        vax_z = "Vaccination coverage (standardized)",
                        stringency_z = "Policy stringency (standardized)"
        )
    )

p2 <- ggplot(df_long, aes(x = week_start, y = value, group = series)) +
    geom_line() +
    facet_wrap(~ country, ncol = 1) +
    labs(
        title = "Trends over time (illustrative countries)",
        subtitle = "Standardized within each country to compare movement over time",
        x = "Week",
        y = "Standardized value"
    ) +
    theme_minimal(base_size = 12)

ggsave("reports/figures/fig2_country_trends.png", p2, width = 10, height = 10, dpi = 300)

cat("Saved:\n- reports/figures/fig1_fe_coefficients.png\n- reports/figures/fig2_country_trends.png\n")
