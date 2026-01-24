# Query Refactoring for Performance

## Business Problem

A report query runs for 45 minutes. The business needs it to run in under 5 minutes. Rather than just "adding indexes," this case study shows systematic query refactoring techniques.

---

## Schema Reference

| Table | Rows | Key Columns |
|-------|------|-------------|
| orders | 10M | order_id, customer_id, order_date, total_amount |
| order_items | 50M | item_id, order_id, product_id, quantity |
| products | 10K | product_id, category, price |

---

## Original Slow Query

```sql
-- Takes 45 minutes
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p.category
ORDER BY revenue DESC;
```

---

## Refactoring Step 1: Filter Early

```sql
-- Pre-filter orders to reduce join size
WITH filtered_orders AS (
    SELECT order_id, customer_id
    FROM orders
    WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    p.category,
    COUNT(DISTINCT fo.order_id) AS order_count,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    COUNT(DISTINCT fo.customer_id) AS unique_customers
FROM filtered_orders fo
JOIN order_items oi ON fo.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;
```

**Why:** Reduces rows before expensive joins.

---

## Refactoring Step 2: Aggregate Before Join

```sql
-- Aggregate order_items first, then join to products
WITH 
filtered_orders AS (
    SELECT order_id, customer_id
    FROM orders
    WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31'
),
order_product_summary AS (
    SELECT 
        oi.product_id,
        fo.order_id,
        fo.customer_id,
        SUM(oi.quantity * oi.unit_price) AS line_revenue
    FROM order_items oi
    JOIN filtered_orders fo ON oi.order_id = fo.order_id
    GROUP BY oi.product_id, fo.order_id, fo.customer_id
)
SELECT 
    p.category,
    COUNT(DISTINCT ops.order_id) AS order_count,
    SUM(ops.line_revenue) AS revenue,
    COUNT(DISTINCT ops.customer_id) AS unique_customers
FROM order_product_summary ops
JOIN products p ON ops.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;
```

**Why:** Reduce cardinality before joining to dimension table.

---

## Refactoring Step 3: Replace DISTINCT with Approximate

For dashboards where 99% accuracy is acceptable:

```sql
-- PostgreSQL specific: HyperLogLog approximation
SELECT 
    p.category,
    COUNT(*) AS order_count,  -- If one row per order after grouping
    SUM(line_revenue) AS revenue,
    -- Approximate distinct count (much faster)
    APPROX_COUNT_DISTINCT(customer_id) AS approx_unique_customers
FROM ...
```

**DuckDB version:**
```sql
APPROX_COUNT_DISTINCT(customer_id)
```

---

## Refactoring Step 4: Materialized Aggregates

For frequently-run reports:

```sql
-- Create a materialized summary table (run nightly)
CREATE TABLE daily_category_stats AS
SELECT 
    DATE_TRUNC('day', o.order_date) AS date,
    p.category,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY DATE_TRUNC('day', o.order_date), p.category;

-- Fast query against aggregated data
SELECT category, SUM(order_count), SUM(revenue), SUM(unique_customers)
FROM daily_category_stats
WHERE date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY category;
```

---

## Performance Comparison

| Version | Technique | Time |
|---------|-----------|------|
| Original | Naive joins | 45 min |
| Step 1 | Filter early | 22 min |
| Step 2 | Aggregate before join | 8 min |
| Step 3 | Approximate distinct | 4 min |
| Step 4 | Materialized table | 3 sec |

---

## Database Compatibility

| Technique | PostgreSQL | SQLite | DuckDB |
|-----------|------------|--------|--------|
| CTEs for filtering | Full | Full | Full |
| APPROX_COUNT_DISTINCT | HyperLogLog extension | No | Native |
| Materialized views | Native | Manual | Native |

---

## Key Takeaways

| Rule | Explanation |
|------|-------------|
| Filter early | Reduce row counts before joins |
| Aggregate then join | Join to smaller result sets |
| Avoid DISTINCT if possible | Very expensive on large datasets |
| Pre-aggregate for reports | Trade storage for query speed |
