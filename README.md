# SQL Case Studies

Advanced SQL patterns for **Data Analysts** and **Junior Data Scientists**. Real-world examples with clean documentation, ready for **PostgreSQL**, **SQLite**, and **DuckDB**.

---

## What People Will Find

| Skill | Demonstrated In |
|-------|-----------------|
| Window Functions | ROW_NUMBER, RANK, LAG/LEAD, Moving Averages |
| CTEs | Multi-step pipelines, Recursive queries, Refactoring |
| Business Analytics | Cohort retention, Churn analysis, MRR/ARR/LTV |
| Query Optimization | Index-aware patterns, Performance refactoring |
| Joins & Aggregation | Self-joins, Conditional aggregation, Multi-table |

---

## Case Studies (15 Total)

### Window Functions
- [Ranking Functions](case_studies/window_functions/01_ranking_functions.md) -- ROW_NUMBER, RANK, DENSE_RANK
- [LAG/LEAD](case_studies/window_functions/02_lag_lead.md) -- Month-over-month comparisons
- [Moving Averages](case_studies/window_functions/03_moving_averages.md) -- Rolling calculations

### CTEs & Recursive Queries
- [Multi-CTE Pipelines](case_studies/ctes/01_multi_cte_pipeline.md) -- Chained transformations
- [Recursive Hierarchy](case_studies/ctes/02_recursive_hierarchy.md) -- Org chart traversal
- [CTE Refactoring](case_studies/ctes/03_cte_refactoring.md) -- Subquery cleanup

### Analytics Metrics
- [Retention Analysis](case_studies/analytics_metrics/01_retention_analysis.md) -- Cohort retention
- [Churn Calculation](case_studies/analytics_metrics/02_churn_calculation.md) -- Customer/revenue churn
- [Revenue Metrics](case_studies/analytics_metrics/03_revenue_metrics.md) -- MRR, ARR, LTV

### Query Optimization
- [Index-Aware Queries](case_studies/optimization/01_index_aware_queries.md) -- Performance patterns
- [Query Refactoring](case_studies/optimization/02_query_refactoring.md) -- Systematic improvements
- [Avoiding Anti-Patterns](case_studies/optimization/03_avoiding_antipatterns.md) -- Common mistakes

### Joins & Aggregations
- [Conditional Aggregation](case_studies/joins/01_conditional_aggregation.md) -- CASE in aggregates
- [Complex Joins](case_studies/joins/02_complex_joins.md) -- Multi-table patterns
- [Self-Joins](case_studies/joins/03_self_joins.md) -- Same-table comparisons

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/sql-case-studies.git
cd sql-case-studies
```

### 2. Load Sample Data

**DuckDB (fastest for local testing):**
```bash
duckdb case_studies.duckdb < data/sample_schema.sql
```

**PostgreSQL:**
```bash
psql -d your_database -f data/sample_schema.sql
```

**SQLite:**
```bash
sqlite3 case_studies.db < data/sample_schema.sql
```

### 3. Run Any Case Study Query

Open a case study file, copy the SQL query, and run it in your database client.

---

## Sample Schema

The repository uses a synthetic e-commerce schema:

| Table | Purpose |
|-------|---------|
| customers | User profiles |
| orders | Transactions |
| order_items | Line items |
| products | Product catalog |
| subscriptions | SaaS recurring revenue |
| employees | Org hierarchy for recursive queries |
| events | User behavior analytics |

See [data/sample_schema.sql](data/sample_schema.sql) for full DDL and sample data.

---

## Database Compatibility

All queries tested on:
- **PostgreSQL** 14+
- **SQLite** 3.25+
- **DuckDB** 0.8+

Each case study notes database-specific syntax differences.

See [databases.md](databases.md) for detailed compatibility notes.

---

## Case Study Format

Each case study includes:

1. **Business Problem** -- Real-world context
2. **Schema Reference** -- Relevant tables
3. **SQL Query** -- Clean, formatted solution
4. **Explanation** -- Step-by-step logic
5. **Sample Output** -- Expected results
6. **Database Compatibility** -- Cross-DB notes
7. **Performance Notes** -- Optimization tips

---

## Skills Demonstrated

```
SQL Querying
├── SELECT, WHERE, GROUP BY, HAVING, ORDER BY
├── JOINs (INNER, LEFT, SELF)
└── Subqueries and correlated queries

Advanced SQL
├── Window Functions (ranking, offset, aggregate)
├── CTEs (standard and recursive)
├── Conditional Aggregation
└── Date/Time operations

Business Analytics
├── Cohort Analysis
├── Retention and Churn
├── Revenue Metrics (MRR, ARR, LTV)
└── Customer Segmentation

Performance Optimization
├── Index-aware query patterns
├── Query refactoring techniques
└── Anti-pattern avoidance
```

---

## Target Roles

- Data Analyst
- Junior Data Scientist
- Business Intelligence Analyst
- Analytics Engineer

---

## About

Built to demonstrate SQL proficiency with real-world patterns used in production environments. Each case study reflects actual problems encountered in data analytics roles.

---

## License

MIT
