-- Campaign Performance Insight Table
-- Aggregated by campaign, source/medium, country and daily date

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_DATASET_ID.insight_campaign` AS
SELECT
  campaign,
  first_source,
  first_medium,
  CONCAT(first_source, ' / ', first_medium) AS source_medium,
  country,
  first_visit_date,
  COUNT(*) AS total_users,
  SUM(is_high_quality_lead) AS converters,
  ROUND(SUM(is_high_quality_lead) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(AVG(lead_score), 1) AS avg_lead_score,
  ROUND(AVG(total_time_spent_seconds), 0) AS avg_time_spent,
  ROUND(AVG(total_pages_viewed), 1) AS avg_pages_viewed,
  SUM(CASE WHEN is_high_quality_lead = 0 AND lead_score >= 80 THEN 1 ELSE 0 END) AS hot_prospects
FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scores_full_report`
WHERE first_visit_date IS NOT NULL
GROUP BY campaign, first_source, first_medium, country, first_visit_date
HAVING COUNT(*) >= 1
ORDER BY total_users DESC;
