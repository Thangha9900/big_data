# Kịch bản demo SQL – Dự án phân tích dữ liệu bán hàng

Tài liệu tổng hợp các đoạn SQL có trong dự án để trình bày quy trình từ cơ sở dữ liệu vận hành, Data Warehouse, ETL, phân tích bán hàng đến tối ưu truy vấn. Các lệnh được viết cho PostgreSQL.

## Lưu ý trước khi trình diễn

- Kết nối đúng cơ sở dữ liệu `bigdata_sql` và kiểm tra schema/dữ liệu trước khi chạy.
- Không chạy `Database/create_tables.sql` trên cơ sở dữ liệu đã có dữ liệu: các bảng không dùng `IF NOT EXISTS`.
- `Data_Warehouse/create_star_schema.sql` dành cho khởi tạo Data Warehouse mới. Các lệnh tạo bảng cũng không dùng `IF NOT EXISTS`.
- `ETL/load_sales_to_warehouse.sql` là ví dụ nạp batch tháng 1/2024 vào staging và cập nhật các bảng dimension. Script hiện tại **không có câu lệnh nạp `dw.fact_sales`**. Ngoài ra, chạy lại có thể nạp trùng vào `dw.staging_orders`; cần kiểm tra dữ liệu và cách nạp trước khi chạy.
- Các truy vấn phân tích hiện có không lọc trạng thái `COMPLETED`. Không trình bày kết quả của chúng như doanh thu riêng của đơn hoàn thành.
- Dự án có kết quả benchmark dạng mẫu để ghi số đo thực tế; không khẳng định index cải thiện thời gian nếu chưa chạy `EXPLAIN (ANALYZE, BUFFERS)` trên môi trường trình diễn.

## 1. Giới thiệu mô hình dữ liệu vận hành

Đoạn sau trích từ [`Database/create_tables.sql`](../Database/create_tables.sql). Đây là cấu trúc nguồn gồm danh mục, khách hàng, sản phẩm, đơn hàng và chi tiết đơn hàng. Chỉ trình bày hoặc chạy khi khởi tạo cơ sở dữ liệu trống.

```sql
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    city VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id BIGSERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(category_id),
    product_name VARCHAR(200) NOT NULL,
    price NUMERIC(18,2) NOT NULL CHECK (price >= 0),
    stock INTEGER NOT NULL CHECK (stock >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(30) NOT NULL,
    total_amount NUMERIC(18,2) NOT NULL CHECK (total_amount >= 0)
);

CREATE TABLE order_items (
    order_item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id),
    product_id BIGINT NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(18,2) NOT NULL CHECK (unit_price >= 0)
);
```

## 2. Trình bày Data Warehouse dạng star schema

Đoạn sau trích từ [`Data_Warehouse/create_star_schema.sql`](../Data_Warehouse/create_star_schema.sql). Fact có grain là một dòng chi tiết sản phẩm trong đơn hàng; các dimension cung cấp thông tin ngày, khách hàng, sản phẩm và trạng thái.

```sql
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
    customer_name VARCHAR(150),
    city VARCHAR(100)
);

CREATE TABLE dw.dim_product (
    product_key BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL UNIQUE,
    product_name VARCHAR(200),
    category_id INTEGER,
    category_name VARCHAR(100)
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
```

### Các view tổng hợp trong Data Warehouse

```sql
CREATE OR REPLACE VIEW dw.vw_monthly_sales AS
SELECT
    d.year,
    d.month,
    SUM(f.revenue) AS total_revenue,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM dw.fact_sales AS f
JOIN dw.dim_date AS d ON d.date_key = f.date_key
GROUP BY d.year, d.month;

CREATE OR REPLACE VIEW dw.vw_category_sales AS
SELECT
    p.category_name,
    SUM(f.revenue) AS total_revenue
FROM dw.fact_sales AS f
JOIN dw.dim_product AS p ON p.product_key = f.product_key
GROUP BY p.category_name;

CREATE OR REPLACE VIEW dw.vw_product_sales AS
SELECT
    p.product_id,
    p.product_name,
    p.category_name,
    SUM(f.revenue) AS total_revenue
FROM dw.fact_sales AS f
JOIN dw.dim_product AS p ON p.product_key = f.product_key
GROUP BY p.product_id, p.product_name, p.category_name;
```

## 3. Trình bày quy trình ETL mẫu

Đoạn sau trích từ [`ETL/load_sales_to_warehouse.sql`](../ETL/load_sales_to_warehouse.sql). Trình bày ý nghĩa staging và nạp dimension; trước khi chạy thật cần kiểm tra khoảng ngày, dữ liệu hiện có và khả năng nạp trùng.

```sql
CREATE TABLE IF NOT EXISTS dw.staging_orders (
    order_id BIGINT,
    customer_id BIGINT,
    order_date TIMESTAMP,
    status VARCHAR(30),
    total_amount NUMERIC(18,2),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO dw.staging_orders (
    order_id, customer_id, order_date, status, total_amount
)
SELECT
    o.order_id, o.customer_id, o.order_date, o.status, o.total_amount
FROM orders AS o
WHERE o.order_date >= DATE '2024-01-01'
  AND o.order_date < DATE '2024-02-01';

INSERT INTO dw.dim_date (date_key, full_date, day, month, quarter, year)
SELECT DISTINCT
    TO_CHAR(order_date, 'YYYYMMDD')::INTEGER,
    order_date::DATE,
    EXTRACT(DAY FROM order_date)::INTEGER,
    EXTRACT(MONTH FROM order_date)::INTEGER,
    EXTRACT(QUARTER FROM order_date)::INTEGER,
    EXTRACT(YEAR FROM order_date)::INTEGER
FROM dw.staging_orders
ON CONFLICT (date_key) DO NOTHING;

INSERT INTO dw.dim_customer (customer_id, customer_name, city)
SELECT c.customer_id, c.name, c.city
FROM customers AS c
ON CONFLICT (customer_id) DO UPDATE
SET customer_name = EXCLUDED.customer_name,
    city = EXCLUDED.city;

INSERT INTO dw.dim_product (
    product_id, product_name, category_id, category_name
)
SELECT
    p.product_id, p.product_name, p.category_id, c.category_name
FROM products AS p
JOIN categories AS c ON c.category_id = p.category_id
ON CONFLICT (product_id) DO UPDATE
SET product_name = EXCLUDED.product_name,
    category_id = EXCLUDED.category_id,
    category_name = EXCLUDED.category_name;

INSERT INTO dw.dim_status (status)
SELECT DISTINCT status
FROM dw.staging_orders
ON CONFLICT (status) DO NOTHING;
```

Kiểm tra số dòng staging và fact:

```sql
SELECT COUNT(*) AS staging_orders FROM dw.staging_orders;
SELECT COUNT(*) AS fact_rows FROM dw.fact_sales;
```

Hai số đếm trên không nhất thiết bằng nhau: staging trong script là dữ liệu đơn hàng, trong khi `dw.fact_sales` có grain là dòng sản phẩm trong đơn hàng. Đây cũng không phải phép đối chiếu đầy đủ giữa hai bảng.

## 4. Demo truy vấn phân tích trên dữ liệu vận hành

Các truy vấn trong [`SQL_Queries/advanced_sales_analysis.sql`](../SQL_Queries/advanced_sales_analysis.sql) minh họa tổng hợp theo tháng, xếp hạng danh mục và window functions.

### 4.1. Doanh thu và số đơn theo tháng

```sql
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS month,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    COUNT(DISTINCT o.order_id) AS order_count
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY 1
ORDER BY 1;
```

### 4.2. Xếp hạng danh mục theo doanh thu

```sql
WITH category_sales AS (
    SELECT
        c.category_name,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items AS oi
    JOIN products AS p ON p.product_id = oi.product_id
    JOIN categories AS c ON c.category_id = p.category_id
    GROUP BY c.category_name
)
SELECT
    *,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM category_sales;
```

### 4.3. Thay đổi doanh thu so với tháng trước

```sql
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS month,
        SUM(total_amount) AS revenue
    FROM orders
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change
FROM monthly
ORDER BY month;
```

### 4.4. Doanh thu lũy kế theo tháng

```sql
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS month,
        SUM(total_amount) AS revenue
    FROM orders
    GROUP BY 1
)
SELECT
    month,
    revenue,
    SUM(revenue) OVER (ORDER BY month) AS cumulative_revenue
FROM monthly
ORDER BY month;
```

Các truy vấn này không lọc trạng thái đơn hàng. Truy vấn doanh thu theo tháng ở mục 4.1 tính doanh thu từ `quantity * unit_price`; hai truy vấn window dùng `orders.total_amount`. Khi thuyết trình, cần nêu rõ đây là hai cách lấy doanh thu từ hai nguồn cột khác nhau trong schema.

## 5. Demo truy vấn phân tích Data Warehouse và đối chiếu Spark

Các truy vấn sau trích từ [`SQL_Queries/spark_validation_queries.sql`](../SQL_Queries/spark_validation_queries.sql). Chúng tổng hợp các chỉ số trên `dw.fact_sales`; không có điều kiện lọc theo trạng thái.

### 5.1. Doanh thu, số đơn và số lượng theo tháng

```sql
SELECT
    d.year,
    d.month,
    SUM(f.revenue) AS revenue,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.quantity) AS quantity_sold
FROM dw.fact_sales AS f
JOIN dw.dim_date AS d ON d.date_key = f.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;
```

### 5.2. Doanh thu theo danh mục

```sql
SELECT
    p.category_name,
    SUM(f.revenue) AS revenue,
    SUM(f.quantity) AS quantity_sold
FROM dw.fact_sales AS f
JOIN dw.dim_product AS p ON p.product_key = f.product_key
GROUP BY p.category_name
ORDER BY revenue DESC;
```

### 5.3. Top 10 sản phẩm theo doanh thu

```sql
SELECT
    p.product_id,
    p.product_name,
    p.category_name,
    SUM(f.revenue) AS revenue,
    SUM(f.quantity) AS quantity_sold
FROM dw.fact_sales AS f
JOIN dw.dim_product AS p ON p.product_key = f.product_key
GROUP BY p.product_id, p.product_name, p.category_name
ORDER BY revenue DESC, p.product_id
LIMIT 10;
```

## 6. Demo tối ưu truy vấn bằng index

Các index trích từ [`Optimization/indexes.sql`](../Optimization/indexes.sql). Nên chạy truy vấn đo đạc với `EXPLAIN (ANALYZE, BUFFERS)` trước khi tạo index, tạo index tương ứng, cập nhật thống kê rồi đo lại. Lệnh `ANALYZE` bên dưới cập nhật thống kê cho bộ lập kế hoạch truy vấn.

```sql
CREATE INDEX IF NOT EXISTS idx_orders_order_date
    ON orders(order_date);

CREATE INDEX IF NOT EXISTS idx_orders_customer_date
    ON orders(customer_id, order_date);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
    ON order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_fact_sales_date_key
    ON dw.fact_sales(date_key);

CREATE INDEX IF NOT EXISTS idx_fact_sales_product_key
    ON dw.fact_sales(product_key);

ANALYZE orders;
ANALYZE order_items;
ANALYZE dw.fact_sales;
```

Ví dụ đo truy vấn lọc đơn hàng theo khoảng ngày:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, order_date, status
FROM orders
WHERE order_date >= TIMESTAMP '2024-01-01'
  AND order_date < TIMESTAMP '2024-02-01';
```

Ví dụ đo truy vấn sản phẩm trong chi tiết đơn hàng:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_item_id, order_id, product_id, quantity, unit_price
FROM order_items
WHERE product_id = 100;
```

Ghi nhận thời gian thực tế, loại scan và buffer đọc trước/sau khi tạo index trong [`Optimization/benchmark_results.md`](../Optimization/benchmark_results.md). PostgreSQL có thể vẫn chọn sequential scan nếu truy vấn trả về nhiều dòng; không nên kết luận index luôn làm truy vấn nhanh hơn.

## 7. Trình tự thuyết trình gợi ý

1. Giới thiệu các bảng vận hành và quan hệ chính.
2. Trình bày star schema, grain của `dw.fact_sales` và các dimension.
3. Giải thích ETL mẫu, staging và lưu ý phạm vi batch.
4. Chạy một truy vấn phân tích vận hành và một truy vấn Data Warehouse.
5. Giải thích `RANK`, `LAG` hoặc `SUM OVER` qua kết quả truy vấn.
6. Minh họa `EXPLAIN (ANALYZE, BUFFERS)` trước/sau index bằng số đo thực tế.
7. Liên hệ các truy vấn tổng hợp với CSV và Power BI; kết quả Spark hiện được kiểm tra bằng `Big_Data_Extension/output/validation_summary.txt`.
