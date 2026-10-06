-- Indexes evaluated with EXPLAIN (ANALYZE, BUFFERS).
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_date_key ON dw.fact_sales(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_sales_product_key ON dw.fact_sales(product_key);

ANALYZE orders;
ANALYZE order_items;
ANALYZE dw.fact_sales;
