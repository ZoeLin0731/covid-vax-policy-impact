# COVID-19 Vaccination, Policy, and Mortality: An Empirical Analysis

## Motivation
During the COVID-19 pandemic, governments relied on a combination of pharmaceutical interventions (vaccination) and non-pharmaceutical interventions (policy restrictions) to reduce mortality. While vaccination is widely assumed to lower death rates, its short-term impact is difficult to isolate due to differences across countries, pandemic timing, and policy responses. This project examines whether increases in vaccination coverage are associated with reductions in COVID-19 mortality after accounting for government response policies and global time effects.

## Data
The analysis uses publicly available, country-level COVID-19 datasets from Our World in Data (OWID) and the Oxford COVID-19 Government Response Tracker. These sources provide consistent global coverage of COVID-19 cases, deaths, vaccination metrics, and policy stringency indicators. Data are ingested directly from maintained source endpoints and stored in PostgreSQL; no raw data are committed to the repository.

## Methods
Daily country-level data were aggregated to a weekly frequency to reduce reporting noise and align with epidemiological dynamics. Lagged vaccination variables (2-week and 4-week lags) were constructed to reflect the delayed effect of vaccination on mortality outcomes. The primary outcome variable is weekly average deaths per million.

The analysis proceeds in two stages. First, a pooled regression model is estimated as a baseline specification. Second, a two-way fixed effects panel regression is applied, including country fixed effects to control for time-invariant national characteristics and week fixed effects to account for global shocks such as variant waves and seasonal effects. Standard errors are clustered at the country level to address within-country correlation over time.

## Results
In the pooled regression model, vaccination coverage is not statistically significantly associated with short-term COVID-19 mortality. However, after introducing country and week fixed effects, vaccination coverage exhibits a negative and statistically significant association with mortality at both 2-week and 4-week lags. These results suggest that within-country increases in vaccination coverage are associated with subsequent reductions in COVID-19 deaths once unobserved heterogeneity and global time effects are controlled for.

Government policy stringency remains a strong and statistically significant concurrent predictor of mortality across all model specifications, highlighting the continued role of non-pharmaceutical interventions during the study period.

## Limitations
This analysis is observational and does not establish causal effects. Vaccination coverage may still be correlated with unobserved, time-varying factors such as healthcare capacity or behavioral responses. In addition, mortality reporting practices vary across countries. Results should therefore be interpreted as associative, albeit under a strengthened identification strategy using fixed effects.