# Recursive CTEs: Hierarchy Traversal

## Business Problem

HR needs to generate an organizational chart showing:
- Each employee's reporting chain up to the CEO
- Management level (depth in hierarchy)
- Full path from CEO to employee

This requires traversing a self-referencing table structure.

---

## Schema Reference

| Table | Key Columns |
|-------|-------------|
| employees | employee_id, first_name, last_name, manager_id, department |

The `manager_id` column references `employee_id` in the same table, creating a hierarchy.

---

## SQL Query

```sql
WITH RECURSIVE org_chart AS (
    -- Anchor: Start with the CEO (no manager)
    SELECT 
        employee_id,
        first_name,
        last_name,
        department,
        manager_id,
        1 AS level,
        first_name || ' ' || last_name AS path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: Find employees who report to current level
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.department,
        e.manager_id,
        oc.level + 1,
        oc.path || ' > ' || e.first_name || ' ' || e.last_name
    FROM employees e
    INNER JOIN org_chart oc ON e.manager_id = oc.employee_id
)
SELECT 
    employee_id,
    REPEAT('  ', level - 1) || first_name || ' ' || last_name AS employee_name,
    department,
    level,
    path AS reporting_chain
FROM org_chart
ORDER BY path;
```

---

## Explanation

### Recursive CTE Structure

```
┌──────────────────────────────────────────┐
│ ANCHOR MEMBER                            │
│ - Starting point (CEO with NULL manager) │
│ - Executes once                          │
└──────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────┐
│ RECURSIVE MEMBER                         │
│ - Joins back to CTE results              │
│ - Executes until no new rows             │
└──────────────────────────────────────────┘
```

### Key Concepts

| Component | Purpose |
|-----------|---------|
| `WITH RECURSIVE` | Enables self-referencing CTE |
| Anchor query | Base case - rows that don't recurse |
| `UNION ALL` | Combines anchor with recursive results |
| Recursive query | Joins CTE to itself via foreign key |

---

## Sample Output

| employee_name | department | level | reporting_chain |
|---------------|------------|-------|-----------------|
| Jane CEO | Executive | 1 | Jane CEO |
|   Tom Chen | Engineering | 2 | Jane CEO > Tom Chen |
|     Mike Johnson | Engineering | 3 | Jane CEO > Tom Chen > Mike Johnson |
|       James Taylor | Engineering | 4 | Jane CEO > Tom Chen > Mike Johnson > James Taylor |

---

## Database Compatibility

| Database | Support | Notes |
|----------|---------|-------|
| PostgreSQL | Full | `REPEAT()` for indentation |
| SQLite | Full (3.8.3+) | Use `printf()` or custom padding |
| DuckDB | Full | `REPEAT()` supported |

**SQLite alternative for indentation:**
```sql
substr('          ', 1, (level - 1) * 2) || first_name
```

---

## Performance Notes

- Add `CYCLE` detection for corrupted data (PostgreSQL 14+):
  ```sql
  WITH RECURSIVE ... CYCLE employee_id SET is_cycle USING path_array
  ```
- Index on `manager_id` is essential for performance
- Limit recursion depth if needed: `WHERE level < 10`
- For very deep hierarchies, consider materialized path pattern

---

## Common Variations

**Bottom-up traversal (employee to CEO):**
```sql
WITH RECURSIVE chain AS (
    SELECT employee_id, manager_id, 1 AS level
    FROM employees
    WHERE employee_id = 10  -- Start from specific employee
    
    UNION ALL
    
    SELECT e.employee_id, e.manager_id, c.level + 1
    FROM employees e
    JOIN chain c ON e.employee_id = c.manager_id
)
SELECT * FROM chain;
```

**Calculate subtree aggregates (total salary under each manager):**
```sql
WITH RECURSIVE subtree AS (...)
SELECT 
    manager_id,
    SUM(salary) AS team_salary_cost
FROM subtree
GROUP BY manager_id;
```
