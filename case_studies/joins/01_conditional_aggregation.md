# Conditional Aggregation: CASE in Aggregates

## Business Problem

The reporting team needs a single query that produces:
- Total orders by month
- Breakdown by order status (pending, shipped, delivered)
- Percentage of each status

Instead of running multiple queries, conditional aggregation does it in one pass.

---

## Schema Reference

| Table | Key Columns |
|-------|-------------|
| orders | order_id, customer_id, order_date, status, total_amount |

---

## SQL Query

```sql
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    
    -- Total orders
    COUNT(*) AS total_orders,
    SUM(total_amount) AS total_revenue,
    
    -- Conditional counts by status
    COUNT(CASE WHEN status = 'pending' THEN 1 END) AS pending_orders,
    COUNT(CASE WHEN status = 'shipped' THEN 1 END) AS shipped_orders,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) AS delivered_orders,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled_orders,
    
    -- Conditional sums
    SUM(CASE WHEN status = 'delivered' THEN total_amount ELSE 0 END) AS delivered_revenue,
    
    -- Percentages
    ROUND(
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) AS delivery_rate,
    
    -- Cancellation rate
    ROUND(
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) AS cancellation_rate

FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
```

---

## Explanation

### How CASE in Aggregates Works

```sql
COUNT(CASE WHEN status = 'delivered' THEN 1 END)
```

| Row Status | CASE Result | COUNT Effect |
|------------|-------------|--------------|
| delivered | 1 | Counted |
| pending | NULL | Not counted |
| shipped | NULL | Not counted |

**Key insight:** COUNT ignores NULL, so only matching rows are counted.

### Alternative Syntaxes

```sql
-- PostgreSQL/DuckDB FILTER clause (cleaner)
COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_orders

-- SUM with boolean (works in PostgreSQL)
SUM((status = 'delivered')::int) AS delivered_orders
```

---

## Sample Output

| month | total_orders | pending_orders | shipped_orders | delivered_orders | delivery_rate |
|-------|--------------|----------------|----------------|------------------|---------------|
| 2023-02 | 1 | 0 | 0 | 1 | 100.0 |
| 2023-03 | 3 | 0 | 0 | 3 | 100.0 |
| 2023-04 | 1 | 0 | 0 | 1 | 100.0 |
| 2023-05 | 2 | 0 | 1 | 1 | 50.0 |

---

## Database Compatibility

| Feature | PostgreSQL | SQLite | DuckDB |
|---------|------------|--------|--------|
| CASE in COUNT | Full | Full | Full |
| FILTER clause | Native | No | Native |
| Boolean cast | `::int` | No | `::int` |

**SQLite version:**
```sql
-- Use CASE syntax (no FILTER)
COUNT(CASE WHEN status = 'delivered' THEN 1 END)
```

---

## Performance Notes

- Single table scan instead of multiple queries
- Group by date columns that have indexes
- For wide pivots (many statuses), consider dynamic SQL
- Pre-aggregate for dashboards with many time ranges

---

## Common Variations

**Pivot table pattern:**
```sql
SELECT 
    product_id,
    SUM(CASE WHEN region = 'North' THEN quantity ELSE 0 END) AS north_qty,
    SUM(CASE WHEN region = 'South' THEN quantity ELSE 0 END) AS south_qty,
    SUM(CASE WHEN region = 'East' THEN quantity ELSE 0 END) AS east_qty,
    SUM(CASE WHEN region = 'West' THEN quantity ELSE 0 END) AS west_qty
FROM sales
GROUP BY product_id;
```

**Flagging with conditional aggregation:**
```sql
SELECT 
    customer_id,
    MAX(CASE WHEN order_date >= CURRENT_DATE - 30 THEN 1 ELSE 0 END) AS active_last_30d,
    MAX(CASE WHEN total_amount > 1000 THEN 1 ELSE 0 END) AS has_large_order
FROM orders
GROUP BY customer_id;
```
