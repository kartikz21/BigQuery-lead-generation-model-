# Monthly Retraining Guide

Run these SQL files in order on the 1st of each month.

## Step 1: Rebuild Pipeline Tables
Run in this order:
1. `sql/pipeline/01_fct_sessions_hist.sql`
2. `sql/pipeline/02_fct_sessions_intraday.sql`
3. `sql/pipeline/03_fct_sessions.sql`
4. `sql/pipeline/04_fct_conversions_hist.sql`
5. `sql/pipeline/05_fct_conversions_intraday.sql`
6. `sql/pipeline/06_fct_conversions.sql`
7. `sql/pipeline/07_dim_users_hist.sql`
8. `sql/pipeline/08_dim_users_intraday.sql`
9. `sql/pipeline/09_dim_users.sql`

## Step 2: Rebuild Training Table
10. `sql/model/01_lead_training_clean.sql`

## Step 3: Retrain Model
11. `sql/model/02_lead_scoring_clean.sql`

## Step 4: Verify Model
```sql
SELECT * FROM ML.EVALUATE(MODEL `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scoring_clean`);
```
AUC should be 0.80+ to proceed. If below 0.75, investigate data quality.

## Step 5: Score Users
12. `sql/scoring/01_lead_scores_final.sql`

## Step 6: Rebuild Report Table
13. `sql/scoring/02_lead_scores_full_report.sql`

## Step 7: Rebuild Insight Tables
14. `sql/insights/01_insight_channel.sql`
15. `sql/insights/02_insight_campaign.sql`
16. `sql/insights/03_insight_landing_page.sql`
17. `sql/insights/04_insight_behavioral.sql`

## Step 8: Refresh Looker Studio
1. Open Looker Studio report
2. Resource -> Manage added data sources
3. Click Refresh Fields on each data source
4. Verify dashboard shows updated data

## Expected Timeline
- Pipeline rebuild: 5-10 minutes
- Model training: 10-15 minutes
- Scoring and reports: 5 minutes
- Total: ~30 minutes
