# Revenue Metrics: MRR, ARR, LTV

## Business Problem

The finance team needs to track key SaaS revenue metrics:
- **MRR** (Monthly Recurring Revenue) -- current monthly run rate
- **ARR** (Annual Recurring Revenue) -- annualized revenue
- **LTV** (Lifetime Value) -- expected revenue per customer

---

## Schema Reference

| Table | Key Columns |
|-------|-------------|
| subscriptions | subscription_id, customer_id, monthly_amount, status, start_date, end_date |
| orders | order_id, customer_id, total_amount, order_date |

---

## SQL Query

```sql
WITH 
-- Current MRR from active subscriptions
current_mrr AS (
    SELECT 
        SUM(monthly_amount) AS total_mrr,
        COUNT(*) AS active_subscriptions,
        AVG(monthly_amount) AS avg_subscription_value
    FROM subscriptions
    WHERE status = 'active'
),

-- MRR by plan type
mrr_by_plan AS (
    SELECT 
        plan_name,
        COUNT(*) AS subscribers,
        SUM(monthly_amount) AS plan_mrr,
        ROUND(SUM(monthly_amount) * 100.0 / SUM(SUM(monthly_amount)) OVER (), 2) AS mrr_pct
    FROM subscriptions
    WHERE status = 'active'
    GROUP BY plan_name
),

-- Historical MRR trend
monthly_mrr AS (
    SELECT 
        DATE_TRUNC('month', start_date) AS month,
        SUM(monthly_amount) AS new_mrr,
        SUM(SUM(monthly_amount)) OVER (ORDER BY DATE_TRUNC('month', start_date)) AS cumulative_mrr
    FROM subscriptions
    WHERE status = 'active'
    GROUP BY DATE_TRUNC('month', start_date)
),

-- LTV calculation components
ltv_data AS (
    SELECT 
        c.customer_id,
        COALESCE(SUM(o.total_amount), 0) AS total_order_revenue,
        COALESCE(SUM(
            s.monthly_amount * 
            CASE 
                WHEN s.end_date IS NOT NULL 
                THEN EXTRACT(MONTH FROM s.end_date - s.start_date) + 1
                ELSE EXTRACT(MONTH FROM CURRENT_DATE - s.start_date) + 1
            END
        ), 0) AS total_subscription_revenue
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id
),

-- Average LTV
ltv_summary AS (
    SELECT 
        COUNT(*) AS total_customers,
        ROUND(AVG(total_order_revenue + total_subscription_revenue), 2) AS avg_ltv,
        ROUND(MAX(total_order_revenue + total_subscription_revenue), 2) AS max_ltv,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_order_revenue + total_subscription_revenue), 2) AS median_ltv
    FROM ltv_data
)

-- Final metrics summary
SELECT 
    cm.total_mrr,
    cm.total_mrr * 12 AS arr,
    cm.active_subscriptions,
    cm.avg_subscription_value,
    ls.avg_ltv,
    ls.median_ltv,
    ls.max_ltv,
    ROUND(ls.avg_ltv / NULLIF(cm.avg_subscription_value, 0), 1) AS avg_lifetime_months
FROM current_mrr cm
CROSS JOIN ltv_summary ls;
```

---

## Explanation

### Metric Definitions

| Metric | Formula | Use |
|--------|---------|-----|
| MRR | Sum of all active monthly subscriptions | Monthly health |
| ARR | MRR x 12 | Annual planning |
| ARPU | MRR / Active customers | Pricing analysis |
| LTV | Total revenue per customer lifetime | CAC payback |

### LTV Calculation Methods

| Method | Formula | Best For |
|--------|---------|----------|
| Historical | Total past revenue per customer | Mature businesses |
| Predictive | ARPU x Avg Lifetime | Younger companies |
| Cohort-based | Revenue by signup cohort | Growth companies |

---

## Sample Output

| total_mrr | arr | active_subscriptions | avg_subscription_value | avg_ltv | median_ltv | avg_lifetime_months |
|-----------|-----|----------------------|------------------------|---------|------------|---------------------|
| 499.94 | 5999.28 | 6 | 83.32 | 847.45 | 679.98 | 10.2 |

---

## Database Compatibility

| Database | Support | Notes |
|----------|---------|-------|
| PostgreSQL | Full | Native `PERCENTILE_CONT` |
| SQLite | Limited | No native percentile |
| DuckDB | Full | Native percentile functions |

**SQLite median alternative:**
```sql
SELECT total_revenue
FROM ltv_data
ORDER BY total_revenue
LIMIT 1 OFFSET (SELECT COUNT(*)/2 FROM ltv_data)
```

---

## Performance Notes

- MRR queries should be indexed on `status`, `start_date`
- Pre-aggregate historical MRR for time series dashboards
- LTV calculations can be expensive -- cache results
- Consider dbt incremental models for large datasets

---

## MRR Movement Analysis

Track MRR changes over time:

```sql
SELECT 
    month,
    new_mrr,
    expansion_mrr,
    churned_mrr,
    new_mrr + expansion_mrr - churned_mrr AS net_new_mrr,
    SUM(new_mrr + expansion_mrr - churned_mrr) OVER (ORDER BY month) AS ending_mrr
FROM mrr_movements
ORDER BY month;
```

### MRR Categories

| Category | Definition |
|----------|------------|
| New MRR | From new customers |
| Expansion | Upgrades from existing |
| Contraction | Downgrades from existing |
| Churned | Lost from cancellations |
| Net New | New + Expansion - Contraction - Churned |
