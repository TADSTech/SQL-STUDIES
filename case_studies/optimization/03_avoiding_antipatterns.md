# Avoiding SQL Anti-Patterns

## Business Problem

A junior analyst writes queries that "work" but perform terribly in production. This case study catalogs common anti-patterns with their corrections.

---

## Anti-Pattern Catalog

### 1. SELECT * in Production

**Anti-pattern:**
```sql
SELECT * FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = 123;
```

**Why it's bad:**
- Fetches unnecessary columns (network overhead)
- Prevents covering index optimization
- Breaks when schema changes

**Fix:**
```sql
SELECT 
    o.order_id,
    o.order_date,
    oi.product_id,
    oi.quantity
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = 123;
```

---

### 2. N+1 Query Pattern

**Anti-pattern (application code):**
```python
orders = query("SELECT * FROM orders WHERE customer_id = 123")
for order in orders:
    items = query(f"SELECT * FROM order_items WHERE order_id = {order.id}")
    # 1 + N queries!
```

**Fix (single query with JOIN):**
```sql
SELECT o.order_id, o.order_date, oi.product_id, oi.quantity
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = 123;
```

---

### 3. Using DISTINCT to Hide JOIN Issues

**Anti-pattern:**
```sql
-- Why are there duplicates?
SELECT DISTINCT customer_id, order_date
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id;
```

**The problem:** DISTINCT masks a cardinality explosion from the join.

**Fix:** Understand the data model and aggregate correctly:
```sql
SELECT 
    customer_id,
    order_date,
    COUNT(*) AS item_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY customer_id, order_date;
```

---

### 4. Implicit Cross Join

**Anti-pattern:**
```sql
SELECT a.*, b.*
FROM table_a a, table_b b
WHERE a.some_col = 'value';
-- Missing join condition = Cartesian product!
```

**Fix:**
```sql
SELECT a.*, b.*
FROM table_a a
JOIN table_b b ON a.id = b.a_id
WHERE a.some_col = 'value';
```

---

### 5. Correlated Subqueries in SELECT

**Anti-pattern:**
```sql
SELECT 
    customer_id,
    (SELECT COUNT(*) FROM orders WHERE customer_id = c.customer_id) AS order_count,
    (SELECT MAX(order_date) FROM orders WHERE customer_id = c.customer_id) AS last_order
FROM customers c;
-- Executes 2 subqueries per row!
```

**Fix (aggregate once):**
```sql
SELECT 
    c.customer_id,
    COALESCE(o.order_count, 0) AS order_count,
    o.last_order
FROM customers c
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        MAX(order_date) AS last_order
    FROM orders
    GROUP BY customer_id
) o ON c.customer_id = o.customer_id;
```

---

### 6. Using UNION Instead of UNION ALL

**Anti-pattern:**
```sql
SELECT product_id FROM warehouse_a
UNION
SELECT product_id FROM warehouse_b;
-- UNION removes duplicates (expensive sort)
```

**Fix (when duplicates OK or impossible):**
```sql
SELECT product_id FROM warehouse_a
UNION ALL
SELECT product_id FROM warehouse_b;
```

---

### 7. ORDER BY in Subqueries

**Anti-pattern:**
```sql
SELECT * FROM (
    SELECT * FROM orders ORDER BY order_date DESC
) sub
WHERE status = 'pending';
-- Inner ORDER BY is meaningless and wastes resources
```

**Fix:**
```sql
SELECT * FROM orders
WHERE status = 'pending'
ORDER BY order_date DESC;
```

---

### 8. GROUP BY with Non-Aggregated Columns

**Anti-pattern:**
```sql
SELECT customer_id, order_date, SUM(total_amount)
FROM orders
GROUP BY customer_id;
-- order_date is not in GROUP BY or aggregate!
```

**Why it's bad:** Results are undefined (PostgreSQL errors, MySQL picks arbitrary value).

**Fix:**
```sql
SELECT customer_id, MAX(order_date) AS latest_order, SUM(total_amount)
FROM orders
GROUP BY customer_id;
```

---

## Quick Reference Table

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| SELECT * | Fetches too much | List specific columns |
| N+1 queries | Network overhead | Use JOIN |
| DISTINCT to hide issues | Masks cardinality | Understand data, aggregate |
| Implicit cross join | Cartesian product | Explicit JOIN ON |
| Correlated SELECT subquery | N+1 execution | Aggregate subquery + JOIN |
| UNION vs UNION ALL | Unnecessary sort | Use UNION ALL when possible |
| ORDER BY in subquery | Wasted cycles | ORDER BY at outermost query |
| Ambiguous GROUP BY | Undefined results | Include all non-aggregated columns |

---

## Database Compatibility

All anti-patterns and fixes work across PostgreSQL, SQLite, and DuckDB.

Some databases are stricter:
- **PostgreSQL**: Errors on ambiguous GROUP BY
- **SQLite**: More permissive, may give unexpected results
- **DuckDB**: Generally strict like PostgreSQL
