\# Week 3: CTEs, Aggregations, Window Functions, \& Deduplication



\## Introduction

Once data is safely stored and idempotently loaded, data engineers need to turn raw records into reliable summaries, running metrics, and clean deduplicated views. In this lab, you use DuckDB to break complex queries into readable steps with CTEs, compute customer spend safely, track running totals and rankings with window functions, and keep each customer's latest order.



\## What We Built (`week3\_lab.sql`)



\### 1. CTE + Safe Aggregation (`WITH`, `LEFT JOIN`, `COALESCE`, `GROUP BY`)

\- A \*\*CTE (`WITH completed\_orders AS (...)`)\*\* filters to `COMPLETED` orders first so the main query stays clean and easy to read.

\- `LEFT JOIN` keeps every customer even if they have no completed orders, and `COALESCE(SUM(co.amount), 0.00)` turns `NULL` into `0.00` instead of leaving blank totals.



\### 2. Window Functions (`SUM() OVER (...)` and `ROW\_NUMBER() OVER (...)`)

\- Unlike `GROUP BY`, which collapses multiple rows into one summary row, a \*\*window function\*\* keeps every row while calculating values across a related group (`PARTITION BY customer\_id`).

\- `SUM(o.amount) OVER (PARTITION BY o.customer\_id ORDER BY o.order\_date, o.order\_id)` builds a running total order by order for each customer.

\- `ROW\_NUMBER() OVER (PARTITION BY o.customer\_id ORDER BY o.order\_date DESC, o.order\_id DESC)` numbers each customer's orders starting with `1` for the most recent one.



\### 3. Deduplication Pattern (`ROW\_NUMBER()` + `WHERE row\_num = 1`)

\- Because window functions cannot be filtered directly inside a `WHERE` clause, we assign `row\_num` inside a CTE (`ranked\_orders`) and filter `WHERE row\_num = 1` in the outer query to keep only the latest order per customer.



\## How to Run

1\. Open Command Prompt in `week3\_window\_functions`.

2\. Start DuckDB with the local database file: `..\\duckdb.exe week3\_practice.duckdb`

3\. Run the queries in `week3\_lab.sql` and compare the aggregation, window, and deduplication outputs.

