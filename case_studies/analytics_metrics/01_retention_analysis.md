# Cohort Retention Analysis

## Business Problem

The growth team needs to measure user retention by signup cohort. They want to answer:
- What percentage of users are still active 30/60/90 days after signup?
- Which signup cohorts have the best retention?
- How does retention trend over time?

---

## Schema Reference

| Table | Key Columns |
|-------|-------------|
| customers | customer_id, created_at |
| events | event_id, customer_id, event_date, event_type |

---

## SQL Query

```sql
WITH 
-- Define cohorts by signup month
cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', created_at) AS cohort_month
    FROM customers
),

-- Get each user's activity months
user_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', event_date) AS activity_month
    FROM events
),

-- Calculate months since signup for each activity
retention_data AS (
    SELECT 
        c.cohort_month,
        ua.activity_month,
        EXTRACT(YEAR FROM ua.activity_month) * 12 + EXTRACT(MONTH FROM ua.activity_month) -
        EXTRACT(YEAR FROM c.cohort_month) * 12 - EXTRACT(MONTH FROM c.cohort_month) AS months_since_signup,
        COUNT(DISTINCT c.customer_id) AS active_users
    FROM cohorts c
    JOIN user_activity ua ON c.customer_id = ua.customer_id
    WHERE ua.activity_month >= c.cohort_month
    GROUP BY c.cohort_month, ua.activity_month
),

-- Get cohort sizes
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
)

SELECT 
    rd.cohort_month,
    cs.cohort_size,
    rd.months_since_signup,
    rd.active_users,
    ROUND(rd.active_users * 100.0 / cs.cohort_size, 1) AS retention_pct
FROM retention_data rd
JOIN cohort_sizes cs ON rd.cohort_month = cs.cohort_month
ORDER BY rd.cohort_month, rd.months_since_signup;
```

---

## Explanation

### Retention Matrix

```
              Month 0   Month 1   Month 2   Month 3
Jan Cohort     100%      65%       45%       38%
Feb Cohort     100%      70%       52%       --
Mar Cohort     100%      68%       --        --
```

### Key Concepts

| Term | Definition |
|------|------------|
| Cohort | Group of users by signup date |
| Month 0 | Signup month (always 100%) |
| Retention % | Active users / Total cohort size |
| Churned | Users not active in that period |

---

## Sample Output

| cohort_month | cohort_size | months_since_signup | active_users | retention_pct |
|--------------|-------------|---------------------|--------------|---------------|
| 2023-01-01 | 2 | 0 | 2 | 100.0 |
| 2023-01-01 | 2 | 1 | 2 | 100.0 |
| 2023-01-01 | 2 | 2 | 1 | 50.0 |

---

## Database Compatibility

| Database | Support | Notes |
|----------|---------|-------|
| PostgreSQL | Full | Native `DATE_TRUNC`, `EXTRACT` |
| SQLite | Modified | Use `strftime()` functions |
| DuckDB | Full | Native `DATE_TRUNC`, `EXTRACT` |

**SQLite version:**
```sql
strftime('%Y-%m', created_at) AS cohort_month,
CAST((julianday(activity_month) - julianday(cohort_month)) / 30 AS INTEGER) AS months_since_signup
```

---

## Performance Notes

- Index on `events.customer_id` and `events.event_date` essential
- For large datasets, pre-aggregate daily to monthly
- Consider materialized views for dashboards
- Limit date range to reduce computation

---

## Visualization

The output can be pivoted into a retention heatmap:

| Cohort | M0 | M1 | M2 | M3 |
|--------|-----|-----|-----|-----|
| Jan    | 100% | 65% | 45% | 38% |
| Feb    | 100% | 70% | 52% | 40% |

Colors: Green (>50%) / Yellow (25-50%) / Red (<25%)
