# Query benchmark

Run each query with `EXPLAIN (ANALYZE, BUFFERS)` before and after the matching index, then paste the measured execution time and plan here. Do not invent a speedup: a sequential scan can remain faster for low-selectivity queries or queries returning a large share of the table.

| Query | Index | Before | After | Observation |
| --- | --- | --- | --- | --- |
| Orders in date range | `idx_orders_order_date` | Record from pgAdmin | Record from pgAdmin | Compare scan type and execution time. |
| Items by product | `idx_order_items_product_id` | Record from pgAdmin | Record from pgAdmin | Index benefits selective product filters. |
| Sales by date | `idx_fact_sales_date_key` | Record from pgAdmin | Record from pgAdmin | Large range may still use sequential scan. |
