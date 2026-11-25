-- Week 3: CTEs, Aggregations, Window Functions, & Deduplication

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

INSERT OR IGNORE INTO customers VALUES
    (1, 'Alice', 'North', '2026-01-10'),
    (2, 'Bob', 'South', '2026-01-18'),
    (3, 'Carol', 'North', '2026-02-02'),
    (4, 'David', 'West', '2026-02-15');

INSERT OR IGNORE INTO orders VALUES
    (101, 1, '2026-02-01', 'COMPLETED', 120.00),
    (102, 1, '2026-02-05', 'COMPLETED', 80.00),
    (103, 1, '2026-02-10', 'CANCELLED', 50.00),
    (104, 2, '2026-02-03', 'COMPLETED', 200.00),
    (105, 2, '2026-02-12', 'COMPLETED', 200.00),
    (106, 3, '2026-02-07', 'COMPLETED', 300.00),
    (107, 4, '2026-02-09', 'COMPLETED', 150.00);

-- 1. CTE + LEFT JOIN + COALESCE + GROUP BY: Completed spend per customer
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

-- 2. Window functions: Running order total & most-recent order rank per customer
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

-- 3. Deduplication pattern: Latest order per customer using CTE + ROW_NUMBER
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