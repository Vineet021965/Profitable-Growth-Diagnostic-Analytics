-- Project: Growth Without Profit Analytics
-- File: 03_join_validation.sql
-- Purpose: Validate table joins before creating the analytical view

SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

SELECT COUNT(*) AS joined_rows
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id;

-- 2. Orders + Order Items Join

SELECT COUNT(*) AS joined_rows
FROM orders o
INNER JOIN order_items oi
    ON o.order_id = oi.order_id;	

-- Join Validation Summary:
-- Orders + Customers preserved order-level grain.
-- Orders + Order Items changed the grain to order-item level.
-- Order Items + Products preserved the order-item-level grain.
-- Final analytical dataset should contain 112,650 rows before filtering.