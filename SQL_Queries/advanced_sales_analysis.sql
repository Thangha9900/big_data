-- 1. Monthly revenue and order count.
SELECT DATE_TRUNC('month', o.order_date)::DATE AS month,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       COUNT(DISTINCT o.order_id) AS order_count
FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY 1 ORDER BY 1;

-- 2. Revenue rank by category.
WITH category_sales AS (
    SELECT c.category_name, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items oi JOIN products p ON p.product_id = oi.product_id
    JOIN categories c ON c.category_id = p.category_id GROUP BY c.category_name
)
SELECT *, RANK() OVER (ORDER BY revenue DESC) AS revenue_rank FROM category_sales;

-- 3. Month-on-month revenue change.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month, SUM(total_amount) AS revenue
    FROM orders GROUP BY 1
)
SELECT month, revenue, LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
       revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change
FROM monthly ORDER BY month;

-- 4. Cumulative revenue by month.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month, SUM(total_amount) AS revenue
    FROM orders GROUP BY 1
)
SELECT month, revenue, SUM(revenue) OVER (ORDER BY month) AS cumulative_revenue FROM monthly ORDER BY month;
