# Week 2: Transactions, Idempotent Upserts, & Concurrency

## Introduction
In Week 1, you set up table rules and bulk-loaded data so bad records wouldn't slip in. In real data engineering, though, pipelines don't just run once in a clean vacuum—scripts crash halfway through, scheduled jobs get retried, and two processes can try to write to the same database at the same time.

In this lab, you will practice how to keep your data safe and consistent when things go wrong during a run:
- **Transactions (`BEGIN`, `COMMIT`, `ROLLBACK`):** Group multiple database changes into a single all-or-nothing step so a failure halfway through doesn't leave partial data behind.
- **Idempotent Upserts (`INSERT ... ON CONFLICT DO UPDATE`):** Make data loads safe to re-run so retrying a batch updates existing records or adds new ones instead of crashing on duplicate IDs.
- **Concurrency & File Locks:** Understand what happens when multiple processes try to access a local `.duckdb` database file at once, and why job scheduling matters.

## Overview
In real data pipelines, things go wrong mid-run, jobs get retried, and two scripts can try to touch the same database at once. This lab shows how to keep your data safe and clean using transactions, re-runnable upserts, and awareness of file locks.

## What We Built (`week2_lab.sql`)

### 1. Creating the Tables (`customers` and `orders`)
- `customers`: Stores each customer's ID, unique email, and status.
- `orders`: Stores each order's ID, which customer placed it, and the order amount (blocking negative numbers with `CHECK`).

### 2. Transactions: All-or-Nothing Changes (`BEGIN`, `COMMIT`, `ROLLBACK`)
Imagine saving a customer and their order together—if the order fails, you shouldn't keep half the work.
- `BEGIN;`: Starts a group of changes so they aren't permanently saved yet.
- `ROLLBACK;`: Cancels everything done since `BEGIN;` when an error happens (like a negative order amount), leaving tables clean.
- `COMMIT;`: Saves all changes in the group permanently once every step succeeds.

### 3. Idempotent Upserts: Safe to Re-Run (`INSERT ... ON CONFLICT DO UPDATE`)
Pipelines often retry after a network hiccup or re-send a batch. Running a normal `INSERT` twice on the same `order_id` causes a duplicate key error.
- `ON CONFLICT (order_id) DO UPDATE SET ...`: If `order_id` already exists, it updates the row instead of failing.
- `EXCLUDED.customer_id` and `EXCLUDED.amount`: Point to the new values coming in from your `INSERT` statement.
- Running the same upsert again gives the same result with no duplicates and no errors.

### 4. Concurrency & File Locks
- A local `.duckdb` file only lets one process write at a time. If `duckdb.exe` already has the file open, a second process trying to open it hits an `IO Error`.
- **Simple takeaway:** Don't let overlapping jobs write to the same local database file at the same time—run them one after another or coordinate schedules.

## How to Run
1. Open Command Prompt in `week2_transactions_upserts`[cite: 6].
2. Start DuckDB with the database file: `..\duckdb.exe week2_practice.duckdb`[cite: 6]
3. Run the queries in `week2_lab.sql` and check the final `SELECT` results[cite: 6].