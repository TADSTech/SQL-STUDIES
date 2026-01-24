# Self-Joins: Same Table, Different Perspectives

## Business Problem

HR needs to answer questions that require comparing rows within the same table:
- Who are the direct reports for each manager?
- Find employees earning more than their manager
- Identify employees hired on the same day

---

## Schema Reference

| Table | Key Columns |
|-------|-------------|
| employees | employee_id, first_name, last_name, manager_id, salary, hire_date |

The `manager_id` column references `employee_id` in the same table.

---

## Use Case 1: Employee-Manager Report

```sql
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.department,
    e.salary AS employee_salary,
    m.first_name || ' ' || m.last_name AS manager_name,
    m.salary AS manager_salary,
    e.salary - m.salary AS salary_difference
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY e.department, e.employee_id;
```

### Explanation

```
employees AS e (Employee)
     │
     │  e.manager_id = m.employee_id
     ▼
employees AS m (Manager)
```

**Why LEFT JOIN?** The CEO has no manager (manager_id = NULL), so we need to include them.

---

## Use Case 2: Find Employees Earning More Than Their Manager

```sql
SELECT 
    e.first_name || ' ' || e.last_name AS employee_name,
    e.salary AS employee_salary,
    m.first_name || ' ' || m.last_name AS manager_name,
    m.salary AS manager_salary,
    e.salary - m.salary AS overpaid_by
FROM employees e
INNER JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary
ORDER BY overpaid_by DESC;
```

### Sample Output

| employee_name | employee_salary | manager_name | manager_salary | overpaid_by |
|---------------|-----------------|--------------|----------------|-------------|
| Tom Chen | 180000.00 | Jane CEO | 250000.00 | -70000.00 |

(In our sample data, no one earns more than their manager)

---

## Use Case 3: Find Employees Hired on the Same Day

```sql
SELECT 
    e1.first_name || ' ' || e1.last_name AS employee_1,
    e2.first_name || ' ' || e2.last_name AS employee_2,
    e1.hire_date
FROM employees e1
INNER JOIN employees e2 ON 
    e1.hire_date = e2.hire_date 
    AND e1.employee_id < e2.employee_id  -- Avoid duplicates and self-match
ORDER BY e1.hire_date;
```

### Key Trick: Avoiding Duplicates

| Condition | Purpose |
|-----------|---------|
| `e1.employee_id < e2.employee_id` | Prevents (A,B) and (B,A) duplicates |
| `e1.employee_id != e2.employee_id` | Would still produce mirror pairs |

---

## Use Case 4: Cumulative Salary (All Employees Below You)

```sql
SELECT 
    e.first_name || ' ' || e.last_name AS employee_name,
    e.salary,
    (
        SELECT COALESCE(SUM(sub.salary), 0)
        FROM employees sub
        WHERE sub.salary <= e.salary AND sub.employee_id != e.employee_id
    ) AS cumulative_salary_below
FROM employees e
ORDER BY e.salary DESC;
```

---

## Database Compatibility

| Feature | PostgreSQL | SQLite | DuckDB |
|---------|------------|--------|--------|
| Self-join syntax | Standard | Standard | Standard |
| String concat `\|\|` | Native | Native | Native |

All examples work identically across all three databases.

---

## Performance Notes

### Index Recommendations

| Column | Why Index |
|--------|-----------|
| employee_id | Primary key, fast lookup |
| manager_id | Self-join performance |
| hire_date | Same-day queries |

### Self-Join Considerations

- Self-joins can be expensive on large tables
- Consider materializing hierarchies for deep trees
- For same-value matching (hire_date), ensure column is indexed

---

## Common Variations

**Find gaps in sequences:**
```sql
SELECT a.id + 1 AS gap_start, b.id - 1 AS gap_end
FROM sequence_table a
JOIN sequence_table b ON a.id + 1 < b.id
WHERE NOT EXISTS (
    SELECT 1 FROM sequence_table c 
    WHERE c.id = a.id + 1
);
```

**Compare consecutive rows:**
```sql
SELECT 
    curr.date,
    curr.value,
    prev.value AS prev_value,
    curr.value - prev.value AS change
FROM measurements curr
LEFT JOIN measurements prev ON curr.date = prev.date + INTERVAL '1 day';
```

**Note:** For consecutive row comparisons, window functions (LAG/LEAD) are usually more efficient than self-joins.
