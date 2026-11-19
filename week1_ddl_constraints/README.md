# Week 1: Advanced DDL, Constraints, & Bulk Loading

## Overview
Staging tables act as the first line of defense in a data pipeline. This lab demonstrates how to enforce strict schema rules at ingestion, bulk-load CSV data using DuckDB, and catch bad records before they reach downstream warehouse tables.

## What This Lab Covers
- **Schema & Referential Integrity:** Created a parent `customers` table and a child `raw_orders` table with `PRIMARY KEY`, `NOT NULL`, `UNIQUE`, `CHECK`, and `FOREIGN KEY` constraints.
- **Bulk Ingestion:** Loaded sample batch data from `orders.csv` using DuckDB's `COPY` command.
- **Constraint Failure Testing:** Verified that invalid amounts, disallowed order statuses, and non-existent customer IDs are rejected cleanly.

## How to Run
1. Open a terminal in `week1_ddl_constraints`.
2. Launch DuckDB against a local database file: `..\duckdb.exe week1_practice.duckdb`
3. Run the SQL statements in `week1_lab.sql` and test invalid `INSERT` statements to observe constraint errors.
