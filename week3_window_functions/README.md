```markdown
# Week 3: CTEs, Aggregations, Window Functions, & Deduplication

## Introduction
In Weeks 1 and 2, we focused on getting clean data into our database safely. Once data is stored, data engineers need to transform raw transaction rows into reliable summaries, running metrics, and deduplicated tables.

In this lab, we use DuckDB to work through three everyday SQL patterns:
1. **CTEs & Safe Aggregations:** Breaking queries into readable steps and calculating customer totals without losing inactive customers.
2. **Window Functions:** Calculating running totals and order rankings while keeping every individual row visible.
3. **Deduplication:** Filtering down to each customer's single most recent order using `ROW_NUMBER()`.

---

## Step-by-Step Walkthrough (`week3_lab.sql`)

### 1. Setting Up & Seeding Sample Data
First, we create two tables—`customers` (4 customers across North, South, and West regions) and `orders` (7 orders with `COMPLETED` and `CANCELLED` statuses):

```sql
CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR NOT NULL,
    region VARCHAR NOT NULL,
    signup_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR NOT NULL,
    amount DECIMAL(10, 2) NOT NULL
);

```

* `CREATE TABLE IF NOT EXISTS` and `INSERT OR IGNORE INTO` make the setup script idempotent—if you close your terminal and re-run the script later, DuckDB will not throw duplicate-table or primary-key errors.

---

### 2. CTE + Safe Aggregation (`WITH`, `LEFT JOIN`, `COALESCE`, `GROUP BY`)

**Goal:** Calculate how many `COMPLETED` orders each customer has and their total completed spend, without accidentally dropping customers who have zero completed orders.

```sql
WITH completed_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        amount
    FROM orders
    WHERE status = 'COMPLETED'
)
SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    COUNT(co.order_id) AS completed_order_count,
    COALESCE(SUM(co.amount), 0.00) AS total_completed_spend
FROM customers c
LEFT JOIN completed_orders co
    ON c.customer_id = co.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.region
ORDER BY
    total_completed_spend DESC;

```

**How it works:**

* `WITH completed_orders AS (...)`: Creates a temporary named result set (a **Common Table Expression**) containing only `COMPLETED` orders (so Alice's `$50.00` `CANCELLED` order is excluded before joining).
* `LEFT JOIN`: Keeps every row from `customers` even if a customer has no matching rows in `completed_orders`.
* `COUNT(co.order_id)`: Counts only non-null matched order IDs (so a customer with zero orders gets `0`, not `1`).
* `COALESCE(SUM(co.amount), 0.00)`: Replaces `NULL` with `0.00` if a customer has no completed orders.

**Output:**

* **Bob:** 2 orders, `$400.00`
* **Carol:** 1 order, `$300.00`
* **Alice:** 2 completed orders, `$200.00`
* **David:** 1 order, `$150.00`

---

### 3. Window Functions (`SUM() OVER` and `ROW_NUMBER() OVER`)

**Goal:** See every individual order alongside (a) that customer's cumulative running spend over time and (b) how recent each order is for that customer.

```sql
SELECT
    o.order_id,
    o.customer_id,
    c.customer_name,
    o.order_date,
    o.status,
    o.amount,
    SUM(o.amount) OVER (
        PARTITION BY o.customer_id
        ORDER BY o.order_date, o.order_id
    ) AS running_total_all_orders,
    ROW_NUMBER() OVER (
        PARTITION BY o.customer_id
        ORDER BY o.order_date DESC, o.order_id DESC
    ) AS most_recent_order_rank
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
ORDER BY
    o.customer_id,
    o.order_date,
    o.order_id;

```

**How it works:**

* **Why not `GROUP BY`?** `GROUP BY` collapses multiple rows into one summary row per customer. A **window function** (`OVER (...)`) keeps all 7 order rows visible while computing metrics across a defined slice ("window") of rows.
* `PARTITION BY o.customer_id`: Restarts the calculation from scratch for each customer.
* `SUM(o.amount) OVER (... ORDER BY o.order_date, o.order_id)`: Adds up order amounts chronologically for each customer (e.g., Alice's running total moves from `$120.00` -> `$200.00` -> `$250.00`).
* `ROW_NUMBER() OVER (... ORDER BY o.order_date DESC, o.order_id DESC)`: Numbers each customer's orders starting at `1` for their latest order, using `order_id DESC` as a tie-breaker if two orders happen on the same date.

---

### 4. Deduplication Pattern (`ROW_NUMBER()` + `WHERE row_num = 1`)

**Goal:** Return exactly one row per customer—their single latest order—a standard pattern for deduplicating raw event streams or CDC feeds.

```sql
WITH ranked_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        c.customer_name,
        o.order_date,
        o.status,
        o.amount,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date DESC, o.order_id DESC
        ) AS row_num
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
)
SELECT
    order_id,
    customer_id,
    customer_name,
    order_date,
    status,
    amount
FROM ranked_orders
WHERE row_num = 1
ORDER BY
    customer_id;

```

**How it works:**

* SQL evaluates `WHERE` before window functions, so you cannot write `WHERE ROW_NUMBER() OVER (...) = 1` directly.
* Wrapping `ROW_NUMBER()` inside the `ranked_orders` CTE lets the outer query filter `WHERE row_num = 1`, cleanly returning 4 rows—one latest order per customer (for example, order `103` on `2026-02-10` for Alice).

---

## How to Run

1. Open Command Prompt in `week3_window_functions`.
2. Start DuckDB with the local database file:
```cmd
..\duckdb.exe week3_practice.duckdb

```


3. Run the statements in `week3_lab.sql` and verify each query's output.

```
