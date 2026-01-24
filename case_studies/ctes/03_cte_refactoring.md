# CTE Refactoring: From Subqueries to Clarity

## Business Problem

A legacy query calculates customer metrics using deeply nested subqueries. The query is:
- Hard to read and debug
- Difficult to modify for new requirements
- Prone to copy-paste errors

This case study refactors a complex nested query into clean CTEs.

---

## Schema Reference

| Table | Key Columns |
|-------|-------------|
| customers | customer_id, created_at, segment |
| orders | order_id, customer_id, total_amount, order_date |
| subscriptions | subscription_id, customer_id, status, monthly_amount |

---

## Original Query (Nested Subqueries)

```sql
-- Hard to read, maintain, and debug
SELECT 
    c.customer_id,
    c.first_name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_count,
    (SELECT SUM(total_amount) FROM orders o WHERE o.customer_id = c.customer_id) AS total_spent,
    (SELECT monthly_amount FROM subscriptions s 
     WHERE s.customer_id = c.customer_id AND s.status = 'active' LIMIT 1) AS current_mrr,
    CASE 
        WHEN (SELECT SUM(total_amount) FROM orders o WHERE o.customer_id = c.customer_id) > 1000 
        THEN 'high_value' 
        ELSE 'standard' 
    END AS customer_tier
FROM customers c
WHERE (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) > 0;
```

### Problems:
- Same subquery repeated 3 times (orders aggregation)
- Correlated subqueries execute per-row (N+1 problem)
- Logic scattered, hard to test individual parts

---

## Refactored Query (CTE-based)

```sql
WITH 
-- Aggregate order metrics once
order_metrics AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent
    FROM orders
    GROUP BY customer_id
),

-- Get active subscription info
active_subscriptions AS (
    SELECT DISTINCT ON (customer_id)
        customer_id,
        monthly_amount AS current_mrr
    FROM subscriptions
    WHERE status = 'active'
    ORDER BY customer_id, subscription_id DESC
),

-- Classify customers
customer_classification AS (
    SELECT 
        c.customer_id,
        c.first_name,
        COALESCE(om.order_count, 0) AS order_count,
        COALESCE(om.total_spent, 0) AS total_spent,
        COALESCE(asub.current_mrr, 0) AS current_mrr,
        CASE 
            WHEN COALESCE(om.total_spent, 0) > 1000 THEN 'high_value'
            ELSE 'standard'
        END AS customer_tier
    FROM customers c
    LEFT JOIN order_metrics om ON c.customer_id = om.customer_id
    LEFT JOIN active_subscriptions asub ON c.customer_id = asub.customer_id
)

SELECT *
FROM customer_classification
WHERE order_count > 0
ORDER BY total_spent DESC;
```

---

## Explanation

### Before vs After Comparison

| Aspect | Nested Subqueries | CTE Approach |
|--------|-------------------|--------------|
| Readability | Low (inside-out) | High (top-to-bottom) |
| Performance | N+1 correlated queries | Single aggregation pass |
| Maintainability | Copy-paste errors | Single source of truth |
| Testability | All-or-nothing | Test each CTE |

### Refactoring Steps

1. **Identify repeated logic** - Same subquery in multiple places
2. **Extract to named CTE** - Give it a descriptive name
3. **Replace correlated with JOIN** - Aggregate once, join results
4. **Handle NULLs** - Use COALESCE for LEFT JOINs

---

## Database Compatibility

| Database | Support | Notes |
|----------|---------|-------|
| PostgreSQL | Full | `DISTINCT ON` supported |
| SQLite | Full | Replace `DISTINCT ON` with window function |
| DuckDB | Full | `DISTINCT ON` supported |

**SQLite alternative for DISTINCT ON:**
```sql
active_subscriptions AS (
    SELECT customer_id, monthly_amount AS current_mrr
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY subscription_id DESC) AS rn
        FROM subscriptions
        WHERE status = 'active'
    ) 
    WHERE rn = 1
)
```

---

## Performance Notes

- CTEs enable hash joins vs nested loop correlated queries
- Aggregations in CTEs benefit from parallel execution
- Query planner can optimize CTE-based queries better
- Use `EXPLAIN ANALYZE` to compare execution plans

---

## Common Refactoring Patterns

**Replace scalar subquery with JOIN:**
```sql
-- Before
SELECT name, (SELECT MAX(date) FROM orders WHERE customer_id = c.id)
FROM customers c

-- After
SELECT c.name, o.max_date
FROM customers c
JOIN (SELECT customer_id, MAX(date) AS max_date FROM orders GROUP BY customer_id) o
  ON c.id = o.customer_id
```

**Replace EXISTS with semi-join CTE:**
```sql
-- Before
SELECT * FROM products p WHERE EXISTS (SELECT 1 FROM order_items WHERE product_id = p.id)

-- After
WITH ordered_products AS (SELECT DISTINCT product_id FROM order_items)
SELECT p.* FROM products p JOIN ordered_products op ON p.id = op.product_id
```
