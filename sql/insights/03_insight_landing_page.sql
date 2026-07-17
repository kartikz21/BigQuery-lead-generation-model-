-- Landing Page Performance Insight Table
-- Aggregated by landing page and daily date

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_DATASET_ID.insight_landing_page` AS
SELECT
  first_landing_page,
  CASE
    WHEN first_landing_page LIKE '%calendly.com%' THEN 'Calendly Booking'
    WHEN first_landing_page LIKE '%translate.goog%' THEN 'Google Translate'
    WHEN first_landing_page LIKE '%/blog%' THEN 'Blog Post'
    WHEN first_landing_page LIKE '%/contact%' THEN 'Contact Page'
    WHEN first_landing_page LIKE '%/pricing%' THEN 'Pricing Page'
    WHEN first_landing_page LIKE '%-ppc%' THEN 'PPC Landing Page'
    WHEN first_landing_page LIKE '%/ebooks%' THEN 'Ebook Page'
    WHEN first_landing_page LIKE '%/case-studies%' THEN 'Case Study'
    WHEN first_landing_page IN ('https://www.mavlers.com', 'https://www.mavlers.com/') THEN 'Homepage'
    WHEN first_landing_page = '(other)' THEN 'Other (grouped)'
    WHEN first_landing_page = '(none)' THEN 'Unknown'
    ELSE 'Service Page'
  END AS page_category,
  first_visit_date,
  COUNT(*) AS total_users,
  SUM(is_high_quality_lead) AS converters,
  ROUND(SUM(is_high_quality_lead) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(AVG(lead_score), 1) AS avg_lead_score,
  ROUND(AVG(total_time_spent_seconds), 0) AS avg_time_spent,
  ROUND(AVG(total_pages_viewed), 1) AS avg_pages_viewed,
  SUM(CASE WHEN is_high_quality_lead = 0 AND lead_score >= 80 THEN 1 ELSE 0 END) AS hot_prospects
FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scores_full_report`
WHERE first_landing_page IS NOT NULL AND first_visit_date IS NOT NULL
GROUP BY first_landing_page, first_visit_date
HAVING COUNT(*) >= 1
ORDER BY total_users DESC;
