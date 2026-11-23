-- Week 2: Transactions, Idempotent Upserts, & Concurrency

CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    customer_email VARCHAR NOT NULL UNIQUE,
    status VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    amount DECIMAL(10, 2) CHECK (amount >= 0.00)
);

-- 1. Failed transaction rolled back so partial writes do not persist
BEGIN;
INSERT INTO customers VALUES (1, 'carol@example.com', 'ACTIVE');
INSERT INTO orders VALUES (2001, 1, -25.00);
ROLLBACK;

-- 2. Valid transaction committed atomically
BEGIN;
INSERT INTO customers VALUES (1, 'carol@example.com', 'ACTIVE');
INSERT INTO orders VALUES (2001, 1, 75.00);
COMMIT;

-- 3. Idempotent upsert (safe to re-run without duplicates or primary key errors)
INSERT INTO orders (order_id, customer_id, amount)
VALUES
    (2001, 1, 95.50),
    (2002, 1, 40.00)
ON CONFLICT (order_id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    amount = EXCLUDED.amount;

SELECT * FROM customers ORDER BY customer_id;
SELECT * FROM orders ORDER BY order_id;