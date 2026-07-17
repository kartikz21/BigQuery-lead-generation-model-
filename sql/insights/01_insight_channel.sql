-- Channel Performance Insight Table
-- Aggregated by source/medium and daily date for Looker Studio date filtering

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_DATASET_ID.insight_channel` AS
SELECT
  first_source,
  first_medium,
  CONCAT(first_source, ' / ', first_medium) AS source_medium,
  first_visit_date,
  COUNT(*) AS total_users,
  SUM(is_high_quality_lead) AS converters,
  COUNT(*) - SUM(is_high_quality_lead) AS non_converters,
  ROUND(SUM(is_high_quality_lead) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(AVG(lead_score), 1) AS avg_lead_score,
  MAX(lead_score) AS max_lead_score,
  ROUND(AVG(total_time_spent_seconds), 0) AS avg_time_spent,
  ROUND(AVG(total_pages_viewed), 1) AS avg_pages_viewed,
  ROUND(AVG(total_sessions), 1) AS avg_sessions,
  SUM(CASE WHEN is_high_quality_lead = 0 AND lead_score >= 80 THEN 1 ELSE 0 END) AS hot_prospects,
  SUM(CASE WHEN is_high_quality_lead = 0 AND lead_score >= 50 THEN 1 ELSE 0 END) AS warm_prospects,
  SUM(CASE WHEN lead_score < 20 THEN 1 ELSE 0 END) AS cold_users
FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scores_full_report`
WHERE first_visit_date IS NOT NULL
GROUP BY first_source, first_medium, first_visit_date
HAVING COUNT(*) >= 1
ORDER BY total_users DESC;
