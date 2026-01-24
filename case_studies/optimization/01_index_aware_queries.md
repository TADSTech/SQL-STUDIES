# Index-Aware Query Patterns

## Business Problem

A data analyst notices their queries are running slowly. The DBA suggests "writing index-aware queries" but what does that mean in practice?

This case study demonstrates how query structure affects index usage and performance.

---

## Schema Reference

| Table | Key Columns | Indexes (Assumed) |
|-------|-------------|-------------------|
| orders | order_id, customer_id, order_date, status | PK on order_id, idx on customer_id, idx on order_date |
| customers | customer_id, email, created_at | PK on customer_id, idx on email |

---

## Anti-Pattern vs Index-Friendly Queries

### 1. Function Wrapping Columns

**Anti-pattern (index cannot be used):**
```sql
SELECT * FROM orders
WHERE YEAR(order_date) = 2023;
```

**Index-friendly:**
```sql
SELECT * FROM orders
WHERE order_date >= '2023-01-01' 
  AND order_date < '2024-01-01';
```

**Why:** Functions on columns prevent index seeks. Use range conditions instead.

---

### 2. Implicit Type Conversion

**Anti-pattern:**
```sql
SELECT * FROM customers
WHERE customer_id = '123';  -- customer_id is INTEGER
```

**Index-friendly:**
```sql
SELECT * FROM customers
WHERE customer_id = 123;
```

**Why:** Type mismatch forces full table scan for conversion.

---

### 3. LIKE with Leading Wildcard

**Anti-pattern:**
```sql
SELECT * FROM customers
WHERE email LIKE '%@gmail.com';
```

**Index-friendly:**
```sql
SELECT * FROM customers
WHERE email LIKE 'john%';
```

**Alternative for suffix search:**
```sql
-- Create a reverse email column or use full-text search
SELECT * FROM customers
WHERE REVERSE(email) LIKE REVERSE('%@gmail.com');
```

**Why:** Leading wildcards cannot use B-tree indexes.

---

### 4. OR Conditions

**Anti-pattern:**
```sql
SELECT * FROM orders
WHERE customer_id = 5 OR status = 'pending';
```

**Index-friendly:**
```sql
SELECT * FROM orders WHERE customer_id = 5
UNION ALL
SELECT * FROM orders WHERE status = 'pending' AND customer_id != 5;
```

**Or create a composite index on (customer_id, status).**

**Why:** OR often forces index merge or table scan.

---

### 5. NOT IN with NULLs

**Anti-pattern:**
```sql
SELECT * FROM orders
WHERE customer_id NOT IN (SELECT customer_id FROM blacklist);
-- If blacklist contains NULL, returns no rows!
```

**Index-friendly:**
```sql
SELECT * FROM orders o
WHERE NOT EXISTS (
    SELECT 1 FROM blacklist b WHERE b.customer_id = o.customer_id
);
```

**Why:** NOT IN with possible NULLs has unexpected behavior and poor plans.

---

## Database Compatibility

| Pattern | PostgreSQL | SQLite | DuckDB |
|---------|------------|--------|--------|
| Range predicates | Full optimization | Full optimization | Full optimization |
| Type conversion | Warns in latest | Silent conversion | Warns |
| Leading wildcard | Trigram extension | No optimization | No optimization |

---

## Performance Notes

### Index Selection Principles

| Principle | Explanation |
|-----------|-------------|
| Leftmost prefix | Composite index (a, b, c) can serve queries on a, (a,b), or (a,b,c) |
| Selectivity | Indexes work best on columns with many distinct values |
| Write overhead | Each index slows INSERT/UPDATE/DELETE |
| Covering index | Include SELECT columns in index to avoid table lookup |

### When NOT to Use Indexes

- Small tables (< 1000 rows)
- Columns with low cardinality (status flags)
- Frequently updated columns
- Queries selecting > 20% of rows

---

## Conceptual EXPLAIN Output

```
-- Anti-pattern: Seq Scan
Seq Scan on orders
  Filter: (YEAR(order_date) = 2023)
  Rows Removed by Filter: 1000000

-- Index-friendly: Index Scan
Index Scan using idx_orders_date on orders
  Index Cond: order_date >= '2023-01-01' AND order_date < '2024-01-01'
```
