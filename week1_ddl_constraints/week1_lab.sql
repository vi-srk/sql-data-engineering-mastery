-- Week 1: Advanced DDL, Constraints, & Bulk Loading
CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY,
    customer_email VARCHAR NOT NULL UNIQUE,
    signup_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS raw_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_timestamp TIMESTAMP NOT NULL,
    status VARCHAR CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'CANCELLED')),
    amount DECIMAL(10, 2) CHECK (amount >= 0.00),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT OR IGNORE INTO customers VALUES
(1, 'alice@example.com', '2026-01-10'),
(2, 'bob@example.com', '2026-02-14');

COPY raw_orders FROM 'orders.csv' (AUTO_DETECT TRUE, HEADER TRUE);
