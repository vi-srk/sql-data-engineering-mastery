\# Week 2: Transactions, Idempotent Upserts, \& Concurrency



\## Overview

Data pipelines rarely run in a single clean pass—batches fail mid-way, jobs retry on schedule, and multiple processes can contend for the same database. This lab covers atomic transactions, re-runnable upserts, and single-writer lock behavior in DuckDB.



\## Code Breakdown (`week2\_lab.sql`)



\### 1. Tables (`customers` and `orders`)

\- `customers`: Stores `customer\_id` (`PRIMARY KEY`), `customer\_email` (`NOT NULL UNIQUE`), and `status` (`NOT NULL`).

\- `orders`: Stores `order\_id` (`PRIMARY KEY`), `customer\_id` (`NOT NULL`), and `amount` (`DECIMAL(10, 2)` with `CHECK (amount >= 0.00)`).



\### 2. Atomic Transactions (`BEGIN`, `COMMIT`, `ROLLBACK`)

\- `BEGIN;`: Starts a transaction block so changes are grouped together rather than applied piecemeal.

\- `ROLLBACK;`: Discards everything done since `BEGIN;` when an error occurs (such as inserting a negative `amount` on order `2001`), preventing half-finished data from remaining in `customers` or `orders`.

\- `COMMIT;`: Permanently saves all statements in the transaction once every step succeeds.



\### 3. Idempotent Upserts (`INSERT ... ON CONFLICT DO UPDATE`)

\- `ON CONFLICT (order\_id) DO UPDATE SET ...`: If a row with `order\_id` already exists, updates its values instead of failing with a primary key violation.

\- `EXCLUDED.customer\_id` and `EXCLUDED.amount`: Reference the incoming candidate row values that conflicted with the existing row.

\- Re-running the same upsert produces the same state without creating duplicate rows or errors.



\### 4. Concurrency \& File Locks

\- A local `.duckdb` file enforces a single-writer lock: while one `duckdb.exe` process holds the database open, another process attempting to open the same file receives an `IO Error`.

\- Pipeline design takeaway: avoid overlapping writers on a local file database without job coordination or sequential queuing.



\## How to Run

1\. Open Command Prompt in `week2\_transactions\_upserts`.

2\. Start DuckDB against a local database file: `..\\duckdb.exe week2\_practice.duckdb`

3\. Run the statements in `week2\_lab.sql` and verify the final `SELECT` outputs.

