-- Score all users
-- Run AFTER model training is complete

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scores_final` AS
SELECT
  user_pseudo_id, first_source, first_medium, country, device_category,
  ROUND(
    (SELECT prob FROM UNNEST(predicted_is_high_quality_lead_probs) WHERE label = 1) * 100,
    0
  ) AS lead_score
FROM ML.PREDICT(
  MODEL `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_scoring_clean`,
  TABLE `YOUR_PROJECT_ID.YOUR_DATASET_ID.lead_training_clean`
);
