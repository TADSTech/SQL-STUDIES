# Database Compatibility Guide

This repository contains SQL queries compatible with **PostgreSQL**, **SQLite**, and **DuckDB**.

---

## Quick Start

### PostgreSQL
```bash
psql -d your_database -f data/sample_schema.sql
```

### SQLite
```bash
sqlite3 case_studies.db < data/sample_schema.sql
```

### DuckDB
```bash
duckdb case_studies.duckdb < data/sample_schema.sql
```

---

## Syntax Differences

| Feature | PostgreSQL | SQLite | DuckDB |
|---------|------------|--------|--------|
| Recursive CTEs | `WITH RECURSIVE` | `WITH RECURSIVE` | `WITH RECURSIVE` |
| Window Functions | Full support | Full support | Full support |
| String concat | `\|\|` or `CONCAT()` | `\|\|` | `\|\|` or `CONCAT()` |
| Date functions | `DATE_TRUNC()` | `strftime()` | `DATE_TRUNC()` |
| Generate series | `generate_series()` | Not native | `generate_series()` |

---

## Compatibility Notes by Case Study

### Window Functions
All window functions (ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD) work identically across all three databases.

### CTEs
Standard CTEs work the same. Recursive CTEs require `WITH RECURSIVE` keyword in all three.

### Date Operations
- **PostgreSQL/DuckDB**: Use `DATE_TRUNC('month', date_column)`
- **SQLite**: Use `strftime('%Y-%m', date_column)`

Each case study includes database-specific syntax where needed.

---

## Recommended Tools

| Tool | Description |
|------|-------------|
| [DBeaver](https://dbeaver.io/) | Universal DB client (all 3 databases) |
| [TablePlus](https://tableplus.com/) | Modern DB GUI |
| [pgAdmin](https://www.pgadmin.org/) | PostgreSQL-specific |
| [DB Browser for SQLite](https://sqlitebrowser.org/) | SQLite GUI |

---

## Testing Your Queries

DuckDB is the fastest option for local testing:

```bash
# Install DuckDB
# macOS
brew install duckdb

# Ubuntu/Debian
sudo apt install duckdb

# Then run
duckdb
> .read data/sample_schema.sql
> -- Paste any query from the case studies
```
