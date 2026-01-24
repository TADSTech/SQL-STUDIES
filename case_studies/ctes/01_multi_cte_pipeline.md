# Multi-CTE Pipelines: Data Transformation Chains

## Business Problem

The marketing team needs a customer segmentation report that:
- Calculates total customer spending
- Assigns customers to value tiers
- Summarizes each tier with relevant metrics

This requires multiple transformation steps that CTEs handle elegantly.

---

## Schema Reference

| Table | Key Columns |
|-------|-------------|
| customers | customer_id, segment, country |
| orders | order_id, customer_id, total_amount, order_date |

---

## SQL Query

```sql
WITH 
-- Step 1: Calculate customer lifetime spend
customer_spend AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.segment,
        c.country,
        COUNT(o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spent,
        MIN(o.order_date) AS first_order,
        MAX(o.order_date) AS last_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.segment, c.country
),

-- Step 2: Assign value tiers based on spend
customer_tiers AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent >= 1500 THEN 'platinum'
            WHEN total_spent >= 500 THEN 'gold'
            WHEN total_spent >= 100 THEN 'silver'
            WHEN total_spent > 0 THEN 'bronze'
            ELSE 'inactive'
        END AS value_tier
    FROM customer_spend
),

-- Step 3: Aggregate tier statistics
tier_summary AS (
    SELECT 
        value_tier,
        COUNT(*) AS customer_count,
        ROUND(AVG(total_spent), 2) AS avg_spend,
        SUM(total_spent) AS tier_revenue,
        ROUND(AVG(order_count), 1) AS avg_orders
    FROM customer_tiers
    GROUP BY value_tier
)

-- Final output: Combine detail and summary
SELECT 
    ct.customer_id,
    ct.first_name,
    ct.value_tier,
    ct.total_spent,
    ts.customer_count AS peers_in_tier,
    ts.avg_spend AS tier_avg_spend
FROM customer_tiers ct
JOIN tier_summary ts ON ct.value_tier = ts.value_tier
ORDER BY ct.total_spent DESC;
```

---

## Explanation

### CTE Pipeline Flow

```
customer_spend → customer_tiers → tier_summary
       ↓                ↓               ↓
    Raw data       Classification   Aggregation
       └──────────────────┴──────────────┘
                          ↓
                    Final SELECT
```

### Why CTEs vs Subqueries?

| Aspect | CTEs | Subqueries |
|--------|------|------------|
| Readability | Named, top-to-bottom flow | Nested, inside-out reading |
| Reusability | Reference multiple times | Repeat entire subquery |
| Debugging | Run each CTE independently | Hard to isolate issues |

---

## Sample Output

| customer_id | first_name | value_tier | total_spent | peers_in_tier | tier_avg_spend |
|-------------|------------|------------|-------------|---------------|----------------|
| 2 | Bob | platinum | 1899.98 | 2 | 1764.97 |
| 4 | David | platinum | 1699.98 | 2 | 1764.97 |
| 1 | Alice | gold | 1429.97 | 1 | 1429.97 |

---

## Database Compatibility

| Database | Support | Notes |
|----------|---------|-------|
| PostgreSQL | Full | Native CTE support |
| SQLite | Full (3.8.3+) | Native CTE support |
| DuckDB | Full | Excellent CTE optimization |

---

## Performance Notes

- Modern databases often **inline** CTEs like subqueries (no materialization)
- PostgreSQL 12+ uses inline by default; use `MATERIALIZED` hint if needed
- CTEs execute once even when referenced multiple times (in some databases)
- For very complex pipelines, consider breaking into temp tables

**Force materialization (PostgreSQL 12+):**
```sql
WITH customer_spend AS MATERIALIZED (
    SELECT ...
)
```

---

## Common Variations

**CTE with running totals:**
```sql
WITH daily_sales AS (
    SELECT date, SUM(amount) AS daily_total
    FROM orders GROUP BY date
)
SELECT 
    date,
    daily_total,
    SUM(daily_total) OVER (ORDER BY date) AS running_total
FROM daily_sales;
```
