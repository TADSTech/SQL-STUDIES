# Ranking Functions: ROW_NUMBER, RANK, DENSE_RANK

## Business Problem

A sales manager needs to identify top performers within each region. They want three different ranking perspectives:
- **Absolute position** (1, 2, 3, 4...)
- **Competition-style ranking** with gaps (1, 2, 2, 4...)
- **Sport-style ranking** without gaps (1, 2, 2, 3...)

---

## Schema Reference

```sql
-- Using orders and customers tables
-- See data/sample_schema.sql for full schema
```

| Table | Key Columns |
|-------|-------------|
| orders | order_id, customer_id, order_date, total_amount |
| customers | customer_id, country, segment |

---

## SQL Query

```sql
SELECT 
    c.country,
    c.customer_id,
    c.first_name,
    SUM(o.total_amount) AS total_spent,
    
    -- Absolute position: always unique
    ROW_NUMBER() OVER (
        PARTITION BY c.country 
        ORDER BY SUM(o.total_amount) DESC
    ) AS row_num,
    
    -- Competition ranking: ties share rank, gap after
    RANK() OVER (
        PARTITION BY c.country 
        ORDER BY SUM(o.total_amount) DESC
    ) AS rank_num,
    
    -- Dense ranking: ties share rank, no gaps
    DENSE_RANK() OVER (
        PARTITION BY c.country 
        ORDER BY SUM(o.total_amount) DESC
    ) AS dense_rank_num
    
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.country, c.customer_id, c.first_name
ORDER BY c.country, total_spent DESC;
```

---

## Explanation

| Function | Behavior | Use Case |
|----------|----------|----------|
| `ROW_NUMBER()` | Unique sequential numbers | Pagination, deduplication |
| `RANK()` | Ties get same rank, gaps follow | Leaderboards with ties |
| `DENSE_RANK()` | Ties get same rank, no gaps | "Top N distinct values" |

**How PARTITION BY works:**
- Divides data into groups (by country in this case)
- Ranking restarts at 1 for each partition
- Without PARTITION BY, ranking applies to entire result set

---

## Sample Output

| country | customer_id | first_name | total_spent | row_num | rank_num | dense_rank_num |
|---------|-------------|------------|-------------|---------|----------|----------------|
| USA | 1 | Alice | 1429.97 | 1 | 1 | 1 |
| USA | 4 | David | 1699.98 | 2 | 2 | 2 |
| UK | 2 | Bob | 1899.98 | 1 | 1 | 1 |

---

## Database Compatibility

| Database | Support |
|----------|---------|
| PostgreSQL | Full |
| SQLite | Full (3.25+) |
| DuckDB | Full |

---

## Performance Notes

- Window functions execute after WHERE, GROUP BY, and HAVING
- Adding appropriate indexes on ORDER BY columns improves performance
- For large datasets, consider materializing partitioned results

---

## Common Variations

**Top N per group (most common pattern):**
```sql
WITH ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rn
    FROM products
)
SELECT * FROM ranked WHERE rn <= 3;
```

**Deduplication (keep latest record):**
```sql
WITH ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) AS rn
    FROM users
)
SELECT * FROM ranked WHERE rn = 1;
```
