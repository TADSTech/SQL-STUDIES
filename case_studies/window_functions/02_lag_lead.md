# LAG and LEAD: Row Comparison Analysis

## Business Problem

The finance team needs to analyze month-over-month revenue trends. For each month, they want to:
- Compare current revenue to the previous month
- Calculate percentage change
- Identify growth or decline patterns

---

## Schema Reference

```sql
-- Using orders table
-- See data/sample_schema.sql for full schema
```

| Table | Key Columns |
|-------|-------------|
| orders | order_id, order_date, total_amount, status |

---

## SQL Query

```sql
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS revenue
    FROM orders
    WHERE status = 'delivered'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    revenue,
    
    -- Previous month's revenue
    LAG(revenue, 1) OVER (ORDER BY month) AS prev_month_revenue,
    
    -- Next month's revenue (for forecasting context)
    LEAD(revenue, 1) OVER (ORDER BY month) AS next_month_revenue,
    
    -- Month-over-month change
    revenue - LAG(revenue, 1) OVER (ORDER BY month) AS revenue_change,
    
    -- Percentage change
    ROUND(
        (revenue - LAG(revenue, 1) OVER (ORDER BY month)) * 100.0 /
        NULLIF(LAG(revenue, 1) OVER (ORDER BY month), 0),
        2
    ) AS pct_change

FROM monthly_revenue
ORDER BY month;
```

---

## Explanation

| Function | Purpose | Syntax |
|----------|---------|--------|
| `LAG(col, n)` | Value from N rows before | `LAG(revenue, 1) OVER (ORDER BY date)` |
| `LEAD(col, n)` | Value from N rows after | `LEAD(revenue, 1) OVER (ORDER BY date)` |

**Key concepts:**
- Both require an `ORDER BY` clause to define row sequence
- Optional third parameter provides a default value for NULLs
- Can use `PARTITION BY` to reset row sequence per group

**NULL handling:**
```sql
-- Avoid NULL on first row
LAG(revenue, 1, 0) OVER (ORDER BY month) AS prev_revenue
```

---

## Sample Output

| month | revenue | prev_month_revenue | next_month_revenue | revenue_change | pct_change |
|-------|---------|-------------------|-------------------|----------------|------------|
| 2023-02 | 449.99 | NULL | 2029.96 | NULL | NULL |
| 2023-03 | 2029.96 | 449.99 | 1779.97 | 1579.97 | 351.11 |
| 2023-04 | 1779.97 | 2029.96 | 639.97 | -249.99 | -12.31 |

---

## Database Compatibility

| Database | Support | Notes |
|----------|---------|-------|
| PostgreSQL | Full | Use `DATE_TRUNC()` |
| SQLite | Full (3.25+) | Replace with `strftime('%Y-%m', order_date)` |
| DuckDB | Full | Use `DATE_TRUNC()` |

**SQLite version:**
```sql
strftime('%Y-%m', order_date) AS month
```

---

## Performance Notes

- LAG/LEAD are computed in a single pass over the sorted data
- Ensure the ORDER BY column has an index for large datasets
- Pre-aggregating in a CTE (as shown) reduces window function overhead

---

## Common Variations

**Year-over-year comparison:**
```sql
LAG(revenue, 12) OVER (ORDER BY month) AS same_month_last_year
```

**Running difference from first value:**
```sql
revenue - FIRST_VALUE(revenue) OVER (ORDER BY month) AS change_from_start
```

**Comparing to previous non-null value:**
```sql
LAG(revenue) IGNORE NULLS OVER (ORDER BY month)
-- Note: Not supported in all databases
```
