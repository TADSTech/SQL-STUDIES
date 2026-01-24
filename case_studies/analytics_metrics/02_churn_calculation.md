# Customer Churn Calculation

## Business Problem

The customer success team needs to identify and measure churn:
- Monthly churn rate for SaaS subscriptions
- Churn cohort analysis
- Revenue impact of churn (dollar churn)

---

## Schema Reference

| Table | Key Columns |
|-------|-------------|
| subscriptions | subscription_id, customer_id, status, start_date, end_date, monthly_amount |
| customers | customer_id, first_name |

---

## SQL Query

```sql
WITH 
-- Calculate monthly subscription states
monthly_subs AS (
    SELECT 
        DATE_TRUNC('month', start_date) AS month,
        COUNT(*) AS new_subscriptions,
        SUM(monthly_amount) AS new_mrr
    FROM subscriptions
    GROUP BY DATE_TRUNC('month', start_date)
),

-- Calculate churned subscriptions by month
churned AS (
    SELECT 
        DATE_TRUNC('month', end_date) AS churn_month,
        COUNT(*) AS churned_subscriptions,
        SUM(monthly_amount) AS churned_mrr
    FROM subscriptions
    WHERE status = 'churned' AND end_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', end_date)
),

-- Active subscriptions at each month end
monthly_active AS (
    SELECT 
        gs.month,
        COUNT(s.subscription_id) AS active_subs,
        SUM(s.monthly_amount) AS active_mrr
    FROM (
        SELECT DISTINCT DATE_TRUNC('month', start_date) AS month 
        FROM subscriptions
        UNION 
        SELECT DISTINCT DATE_TRUNC('month', end_date) AS month 
        FROM subscriptions WHERE end_date IS NOT NULL
    ) gs
    JOIN subscriptions s ON 
        s.start_date <= gs.month + INTERVAL '1 month' - INTERVAL '1 day'
        AND (s.end_date IS NULL OR s.end_date > gs.month)
    GROUP BY gs.month
),

-- Combine metrics
churn_metrics AS (
    SELECT 
        ma.month,
        ma.active_subs,
        ma.active_mrr,
        COALESCE(c.churned_subscriptions, 0) AS churned_subs,
        COALESCE(c.churned_mrr, 0) AS churned_mrr,
        LAG(ma.active_subs) OVER (ORDER BY ma.month) AS prev_active_subs,
        LAG(ma.active_mrr) OVER (ORDER BY ma.month) AS prev_active_mrr
    FROM monthly_active ma
    LEFT JOIN churned c ON ma.month = c.churn_month
)

SELECT 
    month,
    active_subs,
    churned_subs,
    ROUND(churned_subs * 100.0 / NULLIF(prev_active_subs, 0), 2) AS customer_churn_rate,
    active_mrr,
    churned_mrr,
    ROUND(churned_mrr * 100.0 / NULLIF(prev_active_mrr, 0), 2) AS revenue_churn_rate
FROM churn_metrics
WHERE prev_active_subs IS NOT NULL
ORDER BY month;
```

---

## Explanation

### Churn Rate Formulas

| Metric | Formula |
|--------|---------|
| Customer Churn Rate | Churned Customers / Starting Customers |
| Revenue Churn Rate | Churned MRR / Starting MRR |
| Net Revenue Churn | (Churned - Expansion) / Starting MRR |

### Status Definitions

| Status | Meaning |
|--------|---------|
| active | Currently paying subscription |
| churned | Cancelled or expired |
| paused | Temporarily inactive |

---

## Sample Output

| month | active_subs | churned_subs | customer_churn_rate | active_mrr | churned_mrr | revenue_churn_rate |
|-------|-------------|--------------|---------------------|------------|-------------|--------------------|
| 2023-04 | 5 | 0 | 0.00 | 469.95 | 0.00 | 0.00 |
| 2023-05 | 5 | 0 | 0.00 | 489.95 | 0.00 | 0.00 |
| 2023-06 | 5 | 1 | 20.00 | 479.96 | 9.99 | 2.04 |

---

## Database Compatibility

| Database | Support | Notes |
|----------|---------|-------|
| PostgreSQL | Full | Native interval arithmetic |
| SQLite | Modified | Use date functions for intervals |
| DuckDB | Full | Native interval support |

**SQLite version for month end:**
```sql
date(month, '+1 month', '-1 day')
```

---

## Performance Notes

- Index on `subscriptions.start_date`, `end_date`, `status`
- Pre-compute monthly snapshots for large datasets
- Use incremental updates rather than full recalculation
- Consider a slowly-changing dimension (SCD) approach

---

## Common Variations

**Churn by customer segment:**
```sql
SELECT 
    c.segment,
    COUNT(CASE WHEN s.status = 'churned' THEN 1 END) AS churned,
    COUNT(*) AS total,
    ROUND(COUNT(CASE WHEN s.status = 'churned' THEN 1 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM subscriptions s
JOIN customers c ON s.customer_id = c.customer_id
GROUP BY c.segment;
```

**Early churn indicator (first 30 days):**
```sql
SELECT 
    DATE_TRUNC('month', start_date) AS cohort,
    COUNT(CASE WHEN end_date - start_date <= 30 THEN 1 END) AS early_churn,
    COUNT(*) AS total,
    ROUND(COUNT(CASE WHEN end_date - start_date <= 30 THEN 1 END) * 100.0 / COUNT(*), 2) AS early_churn_rate
FROM subscriptions
GROUP BY DATE_TRUNC('month', start_date);
```
