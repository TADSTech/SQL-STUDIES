# Complex Multi-Table Joins

## Business Problem

The product team needs a comprehensive order report combining:
- Customer information
- Order details
- Product information for each line item
- Total order value calculated from items

This requires joining 4 tables with different cardinalities.

---

## Schema Reference

| Table | Key Columns | Cardinality |
|-------|-------------|-------------|
| customers | customer_id, first_name, segment | 1 customer |
| orders | order_id, customer_id, order_date | Many orders per customer |
| order_items | item_id, order_id, product_id, quantity | Many items per order |
| products | product_id, product_name, category | 1 product |

---

## SQL Query

```sql
SELECT 
    -- Customer info
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.segment,
    c.country,
    
    -- Order info
    o.order_id,
    o.order_date,
    o.status,
    
    -- Aggregated order details
    COUNT(oi.item_id) AS line_items,
    SUM(oi.quantity) AS total_units,
    SUM(oi.quantity * oi.unit_price) AS calculated_total,
    
    -- Product mix
    STRING_AGG(DISTINCT p.category, ', ' ORDER BY p.category) AS categories_ordered,
    
    -- Average item value
    ROUND(SUM(oi.quantity * oi.unit_price) / NULLIF(SUM(oi.quantity), 0), 2) AS avg_unit_value

FROM customers c
-- Many orders per customer
INNER JOIN orders o ON c.customer_id = o.customer_id
-- Many items per order
INNER JOIN order_items oi ON o.order_id = oi.order_id
-- One product per item
INNER JOIN products p ON oi.product_id = p.product_id

WHERE o.order_date >= '2023-01-01'

GROUP BY 
    c.customer_id, c.first_name, c.last_name, c.segment, c.country,
    o.order_id, o.order_date, o.status

ORDER BY o.order_date DESC, o.order_id;
```

---

## Explanation

### Join Flow Visualization

```
customers (1) ─────┐
                   │
orders (N) ────────┤──> Result rows = Σ(order_items per order)
                   │
order_items (N) ───┤
                   │
products (1) ──────┘
```

### Cardinality Impact

| Join Sequence | Result Row Count |
|---------------|------------------|
| customers | 8 customers |
| + orders | 10 orders |
| + order_items | 13 items |
| + products | 13 (1:1 on item) |

### Join Types Explained

| Type | Returns |
|------|---------|
| INNER JOIN | Only matching rows |
| LEFT JOIN | All left + matching right |
| RIGHT JOIN | Matching left + all right |
| FULL OUTER | All rows from both |

---

## Sample Output

| customer_name | order_id | order_date | line_items | calculated_total | categories_ordered |
|---------------|----------|------------| -----------|------------------|-------------------|
| Alice Johnson | 1 | 2023-03-01 | 2 | 1349.98 | Electronics |
| David Brown | 6 | 2023-04-01 | 2 | 1699.98 | Electronics |

---

## Database Compatibility

| Function | PostgreSQL | SQLite | DuckDB |
|----------|------------|--------|--------|
| STRING_AGG | Native | GROUP_CONCAT | Native |
| String concat `\|\|` | Native | Native | Native |

**SQLite version:**
```sql
GROUP_CONCAT(DISTINCT p.category, ', ') AS categories_ordered
-- Note: SQLite GROUP_CONCAT doesn't support ORDER BY
```

---

## Performance Notes

### Join Order Matters

```sql
-- Start with the most filtered table
FROM orders o  -- Filtered by date range
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
```

### Index Recommendations

| Table | Index | Purpose |
|-------|-------|---------|
| orders | (order_date, order_id) | Date range filter |
| order_items | (order_id) | Join to orders |
| order_items | (product_id) | Join to products |

### Common Pitfalls

1. **Cartesian product** - Missing join condition
2. **Row explosion** - N:M join without proper aggregation
3. **NULL handling** - INNER vs LEFT JOIN on optional data

---

## Common Variations

**With optional relationships (LEFT JOIN):**
```sql
SELECT c.*, o.order_id, COALESCE(o.total_amount, 0) AS order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;
```

**Multiple conditions join:**
```sql
INNER JOIN prices p ON 
    oi.product_id = p.product_id 
    AND o.order_date BETWEEN p.valid_from AND p.valid_to
```
