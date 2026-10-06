-- Doi chieu voi ket qua Spark trong Big_Data_Extension/spark_analysis.py.
SELECT d.year, d.month, SUM(f.revenue) AS revenue,
       COUNT(DISTINCT f.order_id) AS order_count, SUM(f.quantity) AS quantity_sold
FROM dw.fact_sales AS f
JOIN dw.dim_date AS d ON d.date_key = f.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- Doanh thu theo danh muc.
SELECT p.category_name, SUM(f.revenue) AS revenue, SUM(f.quantity) AS quantity_sold
FROM dw.fact_sales AS f
JOIN dw.dim_product AS p ON p.product_key = f.product_key
GROUP BY p.category_name
ORDER BY revenue DESC;

-- Top 10 san pham theo doanh thu.
SELECT p.product_id, p.product_name, p.category_name,
       SUM(f.revenue) AS revenue, SUM(f.quantity) AS quantity_sold
FROM dw.fact_sales AS f
JOIN dw.dim_product AS p ON p.product_key = f.product_key
GROUP BY p.product_id, p.product_name, p.category_name
ORDER BY revenue DESC, p.product_id
LIMIT 10;
