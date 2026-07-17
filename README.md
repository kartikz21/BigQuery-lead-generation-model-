# Mavlers Lead Scoring Model (BigQuery ML)

## Overview
A lead scoring model built using BigQuery ML to predict which website visitors are most likely to convert on mavlers.com. The model scores every visitor from 0-100 based on their entry profile.

## Key Results
- **Model AUC:** 0.845
- **Total Users Scored:** 186,798
- **Total Converters:** 967
- **Overall Conversion Rate:** 0.51%
- **Hot Tier (85+) Conversion Rate:** 15.3% (30x site average)
- **Cold Tier (0-29) Conversion Rate:** 0.03%
- **Spread:** 500x between best and worst tier

## Lead Tier Distribution

| Tier | Score Range | Users | Converters | Conv Rate |
|------|-----------|-------|------------|-----------|
| A_Hot | 85-100 | 1,222 | 187 | 15.30% |
| B_Warm | 70-84 | 11,004 | 295 | 2.68% |
| C_Interested | 50-69 | 22,911 | 299 | 1.31% |
| D_Cool | 30-49 | 38,139 | 147 | 0.39% |
| E_Cold | 0-29 | 113,522 | 39 | 0.03% |

## Project Structure

```
mavlers-lead-scoring-bqml/
├── README.md
├── sql/
│   ├── pipeline/          # GA4 data pipeline (sessions, conversions, users)
│   │   ├── 01_fct_sessions_hist.sql
│   │   ├── 02_fct_sessions_intraday.sql
│   │   ├── 03_fct_sessions.sql
│   │   ├── 04_fct_conversions_hist.sql
│   │   ├── 05_fct_conversions_intraday.sql
│   │   ├── 06_fct_conversions.sql
│   │   ├── 07_dim_users_hist.sql
│   │   ├── 08_dim_users_intraday.sql
│   │   └── 09_dim_users.sql
│   ├── model/             # Model training
│   │   ├── 01_lead_training_clean.sql
│   │   └── 02_lead_scoring_clean.sql
│   ├── scoring/           # Scoring and reporting
│   │   ├── 01_lead_scores_final.sql
│   │   └── 02_lead_scores_full_report.sql
│   ├── insights/          # Insight tables for Looker Studio
│   │   ├── 01_insight_channel.sql
│   │   ├── 02_insight_campaign.sql
│   │   ├── 03_insight_landing_page.sql
│   │   └── 04_insight_behavioral.sql
│   └── looker/            # Looker Studio helper queries
│       └── 01_looker_tier_summary.sql
├── docs/
│   ├── traps_documented.md
│   ├── monthly_retraining_guide.md
│   └── insights_summary.md
```

## Data Source
- Google Analytics 4 exported to BigQuery
- Project: `YOUR_PROJECT_ID`
- Dataset: `YOUR_DATASET_ID`
- Date Range: August 27, 2024 to May 3, 2026 (591 daily tables)

## Model Details
- **Algorithm:** Boosted Tree Classifier (XGBoost via BQML)
- **Features:** 8 categorical (first-touch attribution only)
- **Train/Test Split:** Time-based (oldest 80% / newest 20%)
- **Class Weights:** AUTO_CLASS_WEIGHTS = TRUE
- **Behavioral features tested but excluded** due to target leakage

### Feature Importance
1. Country (142)
2. First Landing Page (70)
3. First Medium (68)
4. First Campaign (62)
5. Session Landing Page (56)
6. First Source (40)
7. Device Category (24)
8. Session Source/Medium (12)

## Data Quality Issues Fixed (22 Traps)
See [docs/traps_documented.md](docs/traps_documented.md) for full details.

## Monthly Retraining
Run SQL files in numbered order on the 1st of each month.
See [docs/monthly_retraining_guide.md](docs/monthly_retraining_guide.md) for step-by-step instructions.

## Dashboard
Looker Studio dashboard with 5 pages:
1. Executive Summary
2. Channel Performance
3. Campaign Performance
4. Landing Page Analysis
5. Behavioral Analysis

## Author
Samarth Analytics
