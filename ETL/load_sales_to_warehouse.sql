-- ETL from operational tables to dw. Review date range before execution.
CREATE TABLE IF NOT EXISTS dw.staging_orders (
    order_id BIGINT, customer_id BIGINT, order_date TIMESTAMP,
    status VARCHAR(30), total_amount NUMERIC(18,2), loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Parameterise the dates for each batch, for example January 2024.
INSERT INTO dw.staging_orders (order_id, customer_id, order_date, status, total_amount)
SELECT o.order_id, o.customer_id, o.order_date, o.status, o.total_amount
FROM orders o
WHERE o.order_date >= DATE '2024-01-01' AND o.order_date < DATE '2024-02-01';

INSERT INTO dw.dim_date (date_key, full_date, day, month, quarter, year)
SELECT DISTINCT TO_CHAR(order_date, 'YYYYMMDD')::INTEGER, order_date::DATE,
       EXTRACT(DAY FROM order_date)::INTEGER, EXTRACT(MONTH FROM order_date)::INTEGER,
       EXTRACT(QUARTER FROM order_date)::INTEGER, EXTRACT(YEAR FROM order_date)::INTEGER
FROM dw.staging_orders
ON CONFLICT (date_key) DO NOTHING;

INSERT INTO dw.dim_customer (customer_id, customer_name, city)
SELECT c.customer_id, c.name, c.city FROM customers c
ON CONFLICT (customer_id) DO UPDATE SET customer_name = EXCLUDED.customer_name, city = EXCLUDED.city;
INSERT INTO dw.dim_product (product_id, product_name, category_id, category_name)
SELECT p.product_id, p.product_name, p.category_id, c.category_name
FROM products p JOIN categories c ON c.category_id = p.category_id
ON CONFLICT (product_id) DO UPDATE SET product_name = EXCLUDED.product_name, category_id = EXCLUDED.category_id, category_name = EXCLUDED.category_name;
INSERT INTO dw.dim_status (status)
SELECT DISTINCT status FROM dw.staging_orders ON CONFLICT (status) DO NOTHING;

-- Validation: source and fact lines must be equal for the loaded batch.
SELECT COUNT(*) AS staging_orders FROM dw.staging_orders;
SELECT COUNT(*) AS fact_rows FROM dw.fact_sales;
