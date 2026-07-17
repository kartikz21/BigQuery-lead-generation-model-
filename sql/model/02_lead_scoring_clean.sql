-- Lead Scoring Model Training
-- First-touch features only (behavioral features tested but excluded - no improvement)
-- Run AFTER 01_lead_training_clean.sql

CREATE OR REPLACE MODEL `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scoring_clean`
OPTIONS(
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['is_high_quality_lead'],
  auto_class_weights = TRUE,
  data_split_method = 'CUSTOM',
  data_split_col = 'is_test_set',
  enable_global_explain = TRUE,
  max_iterations = 50,
  early_stop = TRUE,
  min_rel_progress = 0.01
) AS
WITH cutoff AS (
  SELECT APPROX_QUANTILES(first_session_ts, 5)[OFFSET(4)] AS test_threshold
  FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_training_clean`
)
SELECT
  first_source, first_medium, first_campaign, first_landing_page,
  session1_source_medium, session1_landing_page,
  device_category, country,
  is_high_quality_lead,
  CASE WHEN t.first_session_ts >= c.test_threshold THEN TRUE ELSE FALSE END AS is_test_set
FROM `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_training_clean` t
CROSS JOIN cutoff c
WHERE t.user_pseudo_id IS NOT NULL;

-- Evaluate model
-- SELECT * FROM ML.EVALUATE(MODEL `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scoring_clean`);

-- Feature importance
-- SELECT * FROM ML.FEATURE_IMPORTANCE(MODEL `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scoring_clean`) ORDER BY importance_weight DESC;
