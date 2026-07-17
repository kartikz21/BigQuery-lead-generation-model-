-- Behavioral Analysis Insight Table
-- Aggregated by lead tier, conversion status, device and daily date

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_DATASET_ID.insight_behavioral` AS
WITH tier_behavior AS (
  SELECT
    CASE 
      WHEN lead_score >= 85 THEN 'A_Hot'
      WHEN lead_score >= 70 THEN 'B_Warm'
      WHEN lead_score >= 50 THEN 'C_Interested'
      WHEN lead_score >= 30 THEN 'D_Cool'
      ELSE 'E_Cold'
    END AS lead_tier,
    CASE 
      WHEN is_high_quality_lead = 1 THEN 'Converted'
      ELSE 'Not Converted'
    END AS conversion_status,
    device_category,
    country,
    total_sessions,
    total_pages_viewed,
    total_time_spent_seconds,
    unique_landing_pages_seen,
    lead_score,
    is_high_quality_lead,
    first_visit_date
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scores_full_report`
  WHERE first_visit_date IS NOT NULL
)
SELECT
  lead_tier,
  conversion_status,
  device_category,
  first_visit_date,
  COUNT(*) AS users,
  ROUND(AVG(total_sessions), 1) AS avg_sessions,
  ROUND(AVG(total_pages_viewed), 1) AS avg_pages_viewed,
  ROUND(AVG(total_time_spent_seconds), 0) AS avg_time_spent,
  ROUND(AVG(unique_landing_pages_seen), 1) AS avg_unique_pages,
  ROUND(AVG(lead_score), 1) AS avg_lead_score,
  SUM(CASE WHEN total_sessions >= 3 THEN 1 ELSE 0 END) AS multi_session_users,
  SUM(CASE WHEN total_time_spent_seconds >= 300 THEN 1 ELSE 0 END) AS engaged_5min_plus
FROM tier_behavior
GROUP BY lead_tier, conversion_status, device_category, first_visit_date
ORDER BY lead_tier, conversion_status, device_category;
