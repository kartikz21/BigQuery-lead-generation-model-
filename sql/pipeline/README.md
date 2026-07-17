# Pipeline SQL Files

Add your pipeline SQL queries here in this order:

1. `01_fct_sessions_hist.sql` — Historical sessions from events_* tables
2. `02_fct_sessions_intraday.sql` — Intraday sessions
3. `03_fct_sessions.sql` — UNION of hist + intraday
4. `04_fct_conversions_hist.sql` — Historical conversions
5. `05_fct_conversions_intraday.sql` — Intraday conversions
6. `06_fct_conversions.sql` — UNION of hist + intraday
7. `07_dim_users_hist.sql` — Historical user dimensions
8. `08_dim_users_intraday.sql` — Intraday user dimensions
9. `09_dim_users.sql` — Deduped UNION with ROW_NUMBER

Key fixes applied in pipeline:
- _TABLE_SUFFIX BETWEEN for date range
- NOT LIKE 'intraday_%' to exclude intraday from hist
- ROW_NUMBER dedup in dim_users by earliest first_event_ts
- All timestamps standardized to TIMESTAMP type
