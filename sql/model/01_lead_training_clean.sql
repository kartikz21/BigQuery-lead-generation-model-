-- Lead Training Table
-- Creates the clean training dataset with all 22 trap fixes applied
-- Run this FIRST before model training

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_training_clean` AS

WITH 
first_conversion AS (
  SELECT 
    user_pseudo_id,
    MIN(event_ts) AS first_conv_ts
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.fct_conversions`
  WHERE user_pseudo_id IS NOT NULL
  GROUP BY user_pseudo_id
),

-- All valid sessions with junk filters (Traps 11-16)
valid_sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    session_start_ts,
    source_medium,
    REGEXP_REPLACE(SPLIT(landing_page, '?')[OFFSET(0)], r'/$', '') AS clean_landing_page,
    device_category,
    country,
    pageviews_count,
    session_duration_sec,
    engaged_session_flag
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.fct_sessions`
  WHERE 
    -- Trap 11, 15, 16: Only real domains
    (
      landing_page LIKE 'https://www.mavlers.com%'
      OR landing_page LIKE '%calendly.com/YOUR_CALENDLY_SLUG%'
      OR landing_page LIKE '%mavlers-com.translate.goog%'
    )
    -- Trap 12: Remove zombie bots
    AND NOT (
      pageviews_count = 0 
      AND session_duration_sec = 0
      AND source_medium = '(direct) / (none)'
    )
    -- Trap 13: Remove spam referrers
    AND LOWER(source_medium) NOT LIKE '%sendibm%'
    AND LOWER(source_medium) NOT LIKE '%hdhdi%'
    AND LOWER(source_medium) NOT LIKE '%investing_journal%'
    AND LOWER(source_medium) NOT LIKE '%mailchimp%opt%ins%'
    -- Trap 14: Remove SEO crawlers
    AND LOWER(source_medium) NOT LIKE '%semrush%'
    AND LOWER(source_medium) NOT LIKE '%ahrefs%'
    AND LOWER(source_medium) NOT LIKE '%myallsearch%'
    AND LOWER(source_medium) NOT LIKE '%youdao%'
    AND LOWER(source_medium) NOT LIKE '%metacrawler%'
    AND LOWER(source_medium) NOT LIKE '%srpko%'
    AND LOWER(source_medium) NOT LIKE '%hotbot%'
    AND LOWER(source_medium) NOT LIKE '%nerdbot%'
    AND LOWER(source_medium) NOT LIKE '%askboth%'
    AND LOWER(source_medium) NOT LIKE '%inkbotdesign%'
    AND LOWER(source_medium) NOT LIKE '%quillbot%'
),

-- Trap 1, 2: Pre-conversion behavioral features ONLY
pre_conv_behavior AS (
  SELECT
    s.user_pseudo_id,
    COUNT(DISTINCT s.session_id) AS sessions_before_conv,
    SUM(s.pageviews_count) AS pageviews_before_conv,
    SUM(s.session_duration_sec) AS duration_before_conv,
    MAX(CASE WHEN s.clean_landing_page LIKE '%/pricing%' THEN 1 ELSE 0 END) AS visited_pricing,
    MAX(CASE WHEN s.clean_landing_page LIKE '%/contact%' THEN 1 ELSE 0 END) AS visited_contact,
    MAX(CASE WHEN s.engaged_session_flag = 1 THEN 1 ELSE 0 END) AS had_engaged_session,
    COUNT(DISTINCT s.clean_landing_page) AS unique_pages_seen
  FROM valid_sessions s
  LEFT JOIN first_conversion fc ON s.user_pseudo_id = fc.user_pseudo_id
  WHERE fc.first_conv_ts IS NULL OR s.session_start_ts < fc.first_conv_ts
  GROUP BY s.user_pseudo_id
),

-- First session per user
first_sessions AS (
  SELECT
    user_pseudo_id, session_start_ts,
    source_medium AS session1_source_medium,
    clean_landing_page AS session1_landing_page,
    device_category, country,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id ORDER BY session_start_ts ASC) AS session_rank
  FROM valid_sessions
),
session_one AS (
  SELECT * FROM first_sessions WHERE session_rank = 1
),

-- Trap 17: NULL-safe converter list
converters AS (
  SELECT DISTINCT user_pseudo_id
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.fct_conversions`
  WHERE user_pseudo_id IS NOT NULL
),

-- Trap 6: Deduped dim users
dim AS (
  SELECT
    user_pseudo_id, first_source, first_medium, first_campaign,
    REGEXP_REPLACE(SPLIT(first_landing_page, '?')[OFFSET(0)], r'/$', '') AS first_landing_page
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.dim_users`
  WHERE user_pseudo_id IS NOT NULL
),

-- Trap 7: Group rare campaigns
campaign_freq AS (
  SELECT first_campaign, COUNT(*) AS user_count FROM dim GROUP BY first_campaign
),
-- Trap 20: URL decode campaign names
campaign_clean AS (
  SELECT d.user_pseudo_id,
    REPLACE(REPLACE(REPLACE(
      CASE WHEN cf.user_count < 50 THEN '(other)' ELSE d.first_campaign END,
      '%2B', '+'), '%7C', '|'), '%20', ' ')
    AS first_campaign_clean
  FROM dim d LEFT JOIN campaign_freq cf USING (first_campaign)
),

-- Trap 7: Group rare landing pages
landing_freq AS (
  SELECT first_landing_page, COUNT(*) AS user_count FROM dim GROUP BY first_landing_page
),
landing_clean AS (
  SELECT d.user_pseudo_id,
    CASE WHEN lf.user_count < 50 THEN '(other)' ELSE d.first_landing_page END AS first_landing_page_clean
  FROM dim d LEFT JOIN landing_freq lf USING (first_landing_page)
)

SELECT
  s.user_pseudo_id,
  
  -- First-touch features (Trap 19: all COALESCEd)
  COALESCE(d.first_source, '(none)') AS first_source,
  COALESCE(d.first_medium, '(none)') AS first_medium,
  COALESCE(cc.first_campaign_clean, '(none)') AS first_campaign,
  COALESCE(lc.first_landing_page_clean, '(none)') AS first_landing_page,
  COALESCE(s.session1_source_medium, '(none)') AS session1_source_medium,
  COALESCE(s.session1_landing_page, '(none)') AS session1_landing_page,
  COALESCE(s.device_category, '(none)') AS device_category,
  COALESCE(s.country, '(none)') AS country,
  
  -- Pre-conversion behavioral features (Trap 1, 2 fixed)
  COALESCE(b.sessions_before_conv, 0) AS sessions_before_conv,
  COALESCE(b.pageviews_before_conv, 0) AS pageviews_before_conv,
  COALESCE(b.duration_before_conv, 0) AS duration_before_conv,
  COALESCE(b.visited_pricing, 0) AS visited_pricing,
  COALESCE(b.visited_contact, 0) AS visited_contact,
  COALESCE(b.had_engaged_session, 0) AS had_engaged_session,
  COALESCE(b.unique_pages_seen, 0) AS unique_pages_seen,
  
  -- Trap 24 fix: days since first visit
  TIMESTAMP_DIFF(
    TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)),
    s.session_start_ts,
    DAY
  ) AS days_since_first_visit,
  
  -- Label
  CASE WHEN c.user_pseudo_id IS NOT NULL THEN 1 ELSE 0 END AS is_high_quality_lead,
  
  -- Trap 10: For time-based split
  s.session_start_ts AS first_session_ts

FROM session_one s
LEFT JOIN dim d ON s.user_pseudo_id = d.user_pseudo_id
LEFT JOIN campaign_clean cc ON s.user_pseudo_id = cc.user_pseudo_id
LEFT JOIN landing_clean lc ON s.user_pseudo_id = lc.user_pseudo_id
LEFT JOIN pre_conv_behavior b ON s.user_pseudo_id = b.user_pseudo_id
LEFT JOIN converters c ON s.user_pseudo_id = c.user_pseudo_id

-- Trap 9: 7-day cutoff
WHERE DATE(s.session_start_ts) <= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);
