-- Star schema used by the project. Run only on a new database.
CREATE SCHEMA IF NOT EXISTS dw;

CREATE TABLE dw.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    year INTEGER NOT NULL
);
CREATE TABLE dw.dim_customer (
    customer_key BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL UNIQUE,
    customer_name VARCHAR(150), city VARCHAR(100)
);
CREATE TABLE dw.dim_product (
    product_key BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL UNIQUE,
    product_name VARCHAR(200), category_id INTEGER, category_name VARCHAR(100)
);
CREATE TABLE dw.dim_status (
    status_key SERIAL PRIMARY KEY,
    status VARCHAR(30) NOT NULL UNIQUE
);
CREATE TABLE dw.fact_sales (
    sales_key BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    order_item_id BIGINT NOT NULL UNIQUE,
    date_key INTEGER NOT NULL REFERENCES dw.dim_date(date_key),
    customer_key BIGINT NOT NULL REFERENCES dw.dim_customer(customer_key),
    product_key BIGINT NOT NULL REFERENCES dw.dim_product(product_key),
    status_key INTEGER NOT NULL REFERENCES dw.dim_status(status_key),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18,2) NOT NULL,
    revenue NUMERIC(18,2) NOT NULL
);

CREATE OR REPLACE VIEW dw.vw_monthly_sales AS
SELECT d.year, d.month, SUM(f.revenue) AS total_revenue, COUNT(DISTINCT f.order_id) AS total_orders
FROM dw.fact_sales f JOIN dw.dim_date d ON d.date_key = f.date_key
GROUP BY d.year, d.month;
CREATE OR REPLACE VIEW dw.vw_category_sales AS
SELECT p.category_name, SUM(f.revenue) AS total_revenue
FROM dw.fact_sales f JOIN dw.dim_product p ON p.product_key = f.product_key
GROUP BY p.category_name;
CREATE OR REPLACE VIEW dw.vw_product_sales AS
SELECT p.product_id, p.product_name, p.category_name, SUM(f.revenue) AS total_revenue
FROM dw.fact_sales f JOIN dw.dim_product p ON p.product_key = f.product_key
GROUP BY p.product_id, p.product_name, p.category_name;
