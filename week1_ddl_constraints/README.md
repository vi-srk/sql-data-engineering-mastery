# Week 1: Advanced DDL, Constraints, & Bulk Loading

## Overview
Staging tables act as the first line of defense in a data pipeline. This lab shows how to define strict schemas and constraints in SQL, seed reference data idempotently, and bulk-load CSV files in DuckDB while blocking invalid data before it reaches downstream tables.

## Code Breakdown (`week1_lab.sql`)

### 1. `customers` Table (Parent Table)
- `CREATE TABLE IF NOT EXISTS customers`: Creates the table safely if it does not already exist so scripts can be re-run without errors.
- `customer_id INTEGER PRIMARY KEY`: Uniquely identifies each customer and prevents duplicate IDs. Because `raw_orders` references this column, `customers` acts as the parent table.
- `customer_email VARCHAR NOT NULL UNIQUE`: Stores text (`VARCHAR`), requires a non-null email address (`NOT NULL`), and blocks duplicate emails (`UNIQUE`).
- `signup_date DATE NOT NULL`: Stores calendar dates (`DATE`) and requires a signup date on every customer row.

### 2. `raw_orders` Table (Child Table with Guardrails)
- `order_id INTEGER PRIMARY KEY`: Uniquely identifies each order and prevents duplicate order IDs.
- `customer_id INTEGER NOT NULL`: Links each order to a customer and cannot be left blank.
- `order_timestamp TIMESTAMP NOT NULL`: Captures both the date and time (`TIMESTAMP`) when the order occurred.
- `status VARCHAR CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED'))`: Enforces an allowlist of valid order statuses and rejects anything else.
- `amount DECIMAL(10, 2) CHECK (amount >= 0.00)`: Uses exact decimal precision (`DECIMAL(10, 2)`) for currency instead of floating-point numbers to prevent rounding drift, and blocks negative amounts.
- `FOREIGN KEY (customer_id) REFERENCES customers(customer_id)`: Makes `raw_orders` a child table and enforces referential integrity so an order cannot reference a `customer_id` that does not exist in `customers`.

### 3. Seeding Parent Data Safely
- `INSERT OR IGNORE INTO customers VALUES ...`: Inserts sample customers `(1, 'alice@example.com', '2026-01-10')` and `(2, 'bob@example.com', '2026-02-14')`, skipping rows if they already exist so re-running the script stays idempotent.

### 4. Bulk Loading CSV Data into `raw_orders`
- `COPY raw_orders FROM 'orders.csv' (AUTO_DETECT TRUE, HEADER TRUE);`: Bulk-loads rows from `orders.csv` into `raw_orders` in a batch operation, auto-detecting file structure (`AUTO_DETECT TRUE`) and treating the first row as column headers (`HEADER TRUE`) while still casting types and checking every constraint.

## How to Run
1. Open Command Prompt in `week1_ddl_constraints`.
2. Start DuckDB with a persistent database file: `..\duckdb.exe week1_practice.duckdb`
3. Run the statements in `week1_lab.sql` and test invalid `INSERT` statements (negative amount, invalid status, missing `customer_id`) to observe constraint errors.