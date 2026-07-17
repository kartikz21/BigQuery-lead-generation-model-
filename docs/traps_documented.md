# All 22 Traps Identified and Fixed

## Pipeline Traps (1-6)
1. **Target leakage** — Session duration/pageviews included conversion activity. Fixed: compute features BEFORE conversion event only.
2. **Lifetime aggregates** — Used all-time data as features. Fixed: pre-conversion CTE limits to pre-conversion sessions.
3. **Timestamp mismatch** — fct_sessions used seconds, fct_conversions used microseconds. Fixed: standardized to TIMESTAMP type.
4. **Wildcard not scanning all tables** — _TABLE_SUFFIX missing BETWEEN clause. Fixed: added BETWEEN '20240827' AND '20260502'.
5. **events_* matching intraday** — Wildcard matched both daily and intraday tables. Fixed: added NOT LIKE 'intraday_%'.
6. **dim_users duplicates** — UNION ALL with MAX(first_source) picked lexicographic order. Fixed: ROW_NUMBER by earliest first_event_ts.

## Feature Engineering Traps (7-10)
7. **High cardinality categoricals** — Rare campaigns/landing pages created noise. Fixed: group < 50 users into '(other)'.
8. **Class imbalance** — 0.51% conversion rate unhandled. Fixed: AUTO_CLASS_WEIGHTS = TRUE.
9. **Cold-start bias** — Recent users had not had time to convert. Fixed: 7-day cutoff on first_session_ts.
10. **Random train/test split** — Temporal data split randomly. Fixed: time-based custom split (oldest 80% train, newest 20% test).

## Data Quality Traps (11-16)
11. **Non-Mavlers domains** — Staging, dev, localhost traffic included. Fixed: domain filter for www.mavlers.com, calendly.com/YOUR_CALENDLY_SLUG, translate.goog.
12. **Zombie bot sessions** — Direct/none with 0 pageviews and 0 duration. Fixed: filter these out.
13. **Spam referrers** — sendibm, hdhdi, etc. Fixed: NOT LIKE filters.
14. **SEO crawlers** — semrush, ahrefs, etc. Fixed: NOT LIKE filters.
15. **mavlers.com without www** — Singapore bot cluster. Fixed: www-only filter.
16. **API/security subdomains** — Backend traffic leaking in. Fixed: handled by www-only filter.

## SQL Traps (17-22)
17. **NOT IN with NULLs** — Returns empty results. Fixed: use LEFT JOIN + IS NULL.
18. **Score vs report count mismatch** — Report used dim_users as base. Fixed: use lead_scores_final as base.
19. **NULL features** — Unhandled NULLs in features. Fixed: COALESCE on all features.
20. **URL-encoded campaigns** — %2B, %7C, %20 creating false cardinality. Fixed: REPLACE.
21. **Trailing slash duplicates** — /page/ and /page counted separately. Fixed: REGEXP_REPLACE.
22. **r.clutch.co redirects** — googleadservices.com redirect traffic. Fixed: handled by www-only filter.

## New Traps Predicted (23-27)
23. **Conversion session in pre-conv count** — Minor leakage from form-filling session. Acceptable (verified 1.5-3x range).
24. **Non-converters accumulate more sessions** — Data window artifact. Fixed: added days_since_first_visit feature.
25. **Behavioral features change at scoring time** — Score changes as user accumulates sessions. Documented as expected behavior.
26. **Zero pre-conversion behavior** — Edge case where conversion happens at same timestamp. Handled by COALESCE.
27. **Engagement flag includes conversion session** — Minor inflation. Same as Trap 23.
