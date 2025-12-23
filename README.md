# COVID-19 Vaccination, Policy, and Mortality Impact Analysis

## Overview
This project evaluates the relationship between COVID-19 vaccination rollout, government policy responses, and mortality outcomes using a global, country-level time series panel. The analysis is designed to answer a policy-relevant question:

> **Do increases in vaccination coverage lead to reductions in COVID-19 mortality after accounting for government response policies and global time effects?**

To address this, the project combines a reproducible data engineering pipeline, hypothesis-driven statistical modeling, and interpretable visualizations intended for policy and decision-making contexts.

---

## Key Contributions
- Built an end-to-end analytics pipeline from **raw public data ingestion** to **statistical inference**
- Designed a **weekly country–time panel** with lagged intervention features
- Applied **two-way fixed effects regression** (country and time) with cluster-robust standard errors
- Demonstrated how modeling choices (pooled vs. fixed effects) materially change conclusions
- Produced policy-facing visualizations that directly support analytical findings

---

## Data Sources
All data are publicly available and retrieved directly from authoritative sources (no raw data committed to the repository):

- **Our World in Data (OWID)** — COVID-19 cases, deaths, vaccinations  
  https://ourworldindata.org/covid-19

- **Oxford COVID-19 Government Response Tracker (OxCGRT)** — policy stringency and containment indices  
  https://www.bsg.ox.ac.uk/research/research-projects/covid-19-government-response-tracker

Data are pulled via OWID’s maintained CSV endpoints and ingested into PostgreSQL for reproducible analysis.

---

## Methodology (High-Level)
1. **Data Ingestion & Storage**
   - Automated extraction of OWID datasets into PostgreSQL
   - Separation of raw, mart, and analysis layers

2. **Feature Engineering**
   - Daily-to-weekly aggregation
   - Construction of 2-week and 4-week lagged vaccination variables
   - Country–week panel backbone

3. **Statistical Analysis**
   - Baseline pooled regression (null result)
   - Two-way fixed effects panel regression (country + week)
   - Clustered standard errors at the country level
   - Robustness checks across lag specifications

4. **Visualization**
   - Coefficient plots summarizing fixed-effects results
   - Country-level trend visualizations for interpretability

---

## Key Findings
- In pooled models, vaccination coverage is not significantly associated with short-term mortality.
- After introducing **country and time fixed effects**, increases in vaccination coverage are associated with **statistically significant reductions in COVID-19 mortality** at both 2- and 4-week lags.
- Government policy stringency remains a strong concurrent predictor of mortality outcomes.
- Results highlight the importance of controlling for unobserved heterogeneity and global shocks in cross-country health analyses.

---

## Repository Structure

```
covid-vax-policy-impact/
├── README.md
├── config/                 # Example environment and config files
├── data/
│   └── README.md           # Explains why raw data is not committed
├── notebooks/              # Exploratory and modeling notebooks
├── src/
│   ├── ingest/             # Data ingestion scripts
│   ├── db/                 # Database connection helpers
│   ├── features/           # Feature engineering logic
│   └── utils/              # Logging and utilities
├── sql/
│   ├── 00_create_schemas.sql
│   ├── 10_load_raw_checks.sql
│   ├── 20_build_mart_country_date.sql
│   ├── 30_build_features.sql
│   └── 99_views_for_analysis.sql
├── r/
│   ├── 00_connect_db.R
│   ├── 10_hypothesis_tests.R
│   ├── 20_inference_models.R
│   └── 30_diagnostics_plots.R
├── reports/
│   ├── figures/            # Final analytical figures
│   └── writeup.md          # Optional extended write-up
└── docs/
├── data_dictionary.md
├── methodology.md
└── changelog.md
```
---

## Tools & Technologies
- **SQL / PostgreSQL** — data modeling and panel construction  
- **R** — statistical inference, fixed effects regression, visualization  
- **Python** — ingestion and pipeline utilities  
- **Git / GitHub** — version control and reproducibility  

---

## Notes
This project focuses on **statistical inference and policy interpretation**, not predictive deployment. Results are observational and should be interpreted as associative, with fixed effects used to strengthen internal validity.

---

## Author
**Zoe Lin**  
Master’s in Analytics — Applied Machine Intelligence  
