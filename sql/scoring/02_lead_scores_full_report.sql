-- Full Report Table for Looker Studio
-- Contains all columns needed for dashboard with date filtering

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scores_full_report` AS

WITH 
session_aggs AS (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT session_id) AS sessions_count,
    COUNT(DISTINCT SPLIT(landing_page, '?')[OFFSET(0)]) AS unique_landing_pages_seen,
    SUM(session_duration_sec) AS total_time_spent_seconds,
    SUM(pageviews_count) AS total_pages_viewed
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.fct_sessions`
  GROUP BY user_pseudo_id
),
first_visit AS (
  SELECT user_pseudo_id, MIN(session_start_ts) AS first_session_ts
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.fct_sessions`
  GROUP BY user_pseudo_id
),
converters AS (
  SELECT DISTINCT user_pseudo_id
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.fct_conversions`
  WHERE user_pseudo_id IS NOT NULL
),
dim AS (
  SELECT user_pseudo_id, first_campaign AS campaign,
    REGEXP_REPLACE(SPLIT(first_landing_page, '?')[OFFSET(0)], r'/$', '') AS first_landing_page
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.dim_users`
),
first_conversion_event AS (
  SELECT
    user_pseudo_id,
    conversion_event_name,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id ORDER BY event_ts ASC) AS rn
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.fct_conversions`
  WHERE user_pseudo_id IS NOT NULL
)

SELECT
  s.user_pseudo_id,
  s.first_source,
  s.first_medium,
  CONCAT(s.first_source, ' / ', s.first_medium) AS source_medium,
  COALESCE(d.campaign, '(none)') AS campaign,
  COALESCE(d.first_landing_page, '(none)') AS first_landing_page,
  s.device_category,
  s.country,
  COALESCE(sa.sessions_count, 0) AS total_sessions,
  COALESCE(sa.unique_landing_pages_seen, 0) AS unique_landing_pages_seen,
  COALESCE(sa.total_time_spent_seconds, 0) AS total_time_spent_seconds,
  COALESCE(sa.total_pages_viewed, 0) AS total_pages_viewed,
  CASE WHEN c.user_pseudo_id IS NOT NULL THEN 1 ELSE 0 END AS is_high_quality_lead,
  s.lead_score,
  DATE(fv.first_session_ts) AS first_visit_date,

  -- Pre-calculated fields for Looker Studio
  CASE 
    WHEN s.lead_score >= 85 THEN 'A_Hot'
    WHEN s.lead_score >= 70 THEN 'B_Warm'
    WHEN s.lead_score >= 50 THEN 'C_Interested'
    WHEN s.lead_score >= 30 THEN 'D_Cool'
    ELSE 'E_Cold'
  END AS lead_tier,

  CASE 
    WHEN c.user_pseudo_id IS NOT NULL THEN 'Converted'
    ELSE 'Not Converted'
  END AS conversion_status,

  CASE
    WHEN COALESCE(d.first_landing_page, '') LIKE '%calendly.com%' THEN 'Calendly Booking'
    WHEN COALESCE(d.first_landing_page, '') LIKE '%translate.goog%' THEN 'Google Translate'
    WHEN COALESCE(d.first_landing_page, '') LIKE '%/blog%' THEN 'Blog Post'
    WHEN COALESCE(d.first_landing_page, '') LIKE '%/contact%' THEN 'Contact Page'
    WHEN COALESCE(d.first_landing_page, '') LIKE '%/pricing%' THEN 'Pricing Page'
    WHEN COALESCE(d.first_landing_page, '') LIKE '%-ppc%' THEN 'PPC Landing Page'
    WHEN COALESCE(d.first_landing_page, '') LIKE '%/ebooks%' THEN 'Ebook Page'
    WHEN COALESCE(d.first_landing_page, '') LIKE '%/case-studies%' THEN 'Case Study'
    WHEN COALESCE(d.first_landing_page, '') IN ('https://www.mavlers.com', 'https://www.mavlers.com/') THEN 'Homepage'
    WHEN COALESCE(d.first_landing_page, '') = '(other)' THEN 'Other'
    WHEN COALESCE(d.first_landing_page, '') = '(none)' THEN 'Unknown'
    ELSE 'Service Page'
  END AS page_category,

  CASE
    WHEN c.user_pseudo_id IS NOT NULL THEN 'Already Converted'
    WHEN s.lead_score >= 80 THEN 'Hot Prospect'
    WHEN s.lead_score >= 50 THEN 'Warm Prospect'
    ELSE 'Low Priority'
  END AS action_category,

  COALESCE(fce.conversion_event_name, 'No Conversion') AS conversion_event

FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scores_final` s
LEFT JOIN dim d USING (user_pseudo_id)
LEFT JOIN session_aggs sa USING (user_pseudo_id)
LEFT JOIN converters c USING (user_pseudo_id)
LEFT JOIN first_visit fv USING (user_pseudo_id)
LEFT JOIN first_conversion_event fce 
  ON s.user_pseudo_id = fce.user_pseudo_id AND fce.rn = 1;
