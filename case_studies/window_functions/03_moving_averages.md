# Moving Averages: Trend Smoothing

## Business Problem

The operations team needs to smooth out daily order fluctuations to identify true trends. They want:
- 7-day moving average of order counts
- 30-day rolling revenue totals
- Trend identification using smoothed data

---

## Schema Reference

```sql
-- Using orders table
-- See data/sample_schema.sql for full schema
```

| Table | Key Columns |
|-------|-------------|
| orders | order_id, order_date, total_amount |

---

## SQL Query

```sql
WITH daily_stats AS (
    SELECT 
        order_date,
        COUNT(*) AS order_count,
        SUM(total_amount) AS daily_revenue
    FROM orders
    GROUP BY order_date
)
SELECT 
    order_date,
    order_count,
    daily_revenue,
    
    -- 7-day moving average (trailing)
    ROUND(
        AVG(order_count) OVER (
            ORDER BY order_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS order_count_7day_avg,
    
    -- 7-day rolling sum
    SUM(daily_revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS revenue_7day_sum,
    
    -- Centered moving average (better for analysis)
    ROUND(
        AVG(order_count) OVER (
            ORDER BY order_date
            ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
        ),
        2
    ) AS order_count_centered_avg,
    
    -- Cumulative sum (running total)
    SUM(daily_revenue) OVER (
        ORDER BY order_date
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_revenue

FROM daily_stats
ORDER BY order_date;
```

---

## Explanation

### Window Frame Types

| Frame | Syntax | Use Case |
|-------|--------|----------|
| Trailing | `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` | Historical trend |
| Centered | `ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING` | Smoother analysis |
| Cumulative | `ROWS UNBOUNDED PRECEDING` | Running totals |

### Frame Boundaries

| Boundary | Meaning |
|----------|---------|
| `UNBOUNDED PRECEDING` | From start of partition |
| `N PRECEDING` | N rows before current |
| `CURRENT ROW` | Current row |
| `N FOLLOWING` | N rows after current |
| `UNBOUNDED FOLLOWING` | To end of partition |

---

## Sample Output

| order_date | order_count | daily_revenue | order_count_7day_avg | revenue_7day_sum |
|------------|-------------|---------------|---------------------|------------------|
| 2023-02-10 | 1 | 449.99 | 1.00 | 449.99 |
| 2023-03-01 | 1 | 1349.98 | 1.00 | 1799.97 |
| 2023-03-10 | 1 | 79.99 | 1.00 | 1879.96 |

---

## Database Compatibility

| Database | Support | Notes |
|----------|---------|-------|
| PostgreSQL | Full | Native ROWS/RANGE support |
| SQLite | Full (3.25+) | Native support |
| DuckDB | Full | Native support |

---

## Performance Notes

- Window frames require sorting -- ensure indexes on ORDER BY columns
- `ROWS` is generally faster than `RANGE`
- For very large datasets, consider pre-aggregating daily data
- Materialized views can cache expensive moving average calculations

---

## Common Variations

**Exponential moving average (approximation):**
```sql
-- Not native in SQL, but can approximate with weighted averages
SELECT 
    order_date,
    daily_revenue,
    SUM(daily_revenue * power) OVER (...) / SUM(power) OVER (...)
```

**Moving average with minimum window:**
```sql
-- Only calculate when we have at least 7 days of data
CASE 
    WHEN COUNT(*) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) >= 7
    THEN AVG(order_count) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
    ELSE NULL
END AS order_count_7day_avg
```

**Partitioned moving average:**
```sql
-- Moving average per product category
AVG(daily_revenue) OVER (
    PARTITION BY category
    ORDER BY order_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```
