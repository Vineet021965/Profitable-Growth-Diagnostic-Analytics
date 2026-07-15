-- ============================================================
-- Project: Growth Without Profit Analytics
-- File: 02_data_quality_checks.sql
-- Purpose: Validate imported data before business analysis
-- ============================================================

-- ============================================================
-- 1. ROW COUNT VALIDATION
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items;

-- ============================================================
-- 2. KEY UNIQUENESS VALIDATION
-- ============================================================


-- 2.1 Check duplicate customer_id values
SELECT
    customer_id,
    COUNT(*) AS occurrence_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 2.2 Check duplicate order_id values
SELECT
    order_id,
    COUNT(*) AS occurrence_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 2.3 Check duplicate product_id values
SELECT
    product_id,
    COUNT(*) AS occurrence_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- 2.4 Validate the composite key of order_items
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS occurrence_count
FROM order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

-- 2.5 Validate business-level customer identifier behavior

SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS actual_unique_customers
FROM customers;

-- ============================================================
-- 3. REFERENTIAL INTEGRITY & RELATIONSHIP VALIDATION
-- ============================================================


-- 3.1 Orders referencing customers that do not exist

SELECT COUNT(*) AS orders_without_customer
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 3.2 Order items referencing orders that do not exist

SELECT COUNT(*) AS items_without_order
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 3.3 Order items referencing products that do not exist

SELECT COUNT(*) AS items_without_product
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 3.4 Orders that do not have corresponding order-item records

SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- 3.5 Investigate the status of orders without order items

SELECT
    o.order_status,
    COUNT(*) AS order_count
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY order_count DESC;

-- 3.6 Products that never appear in order items

SELECT COUNT(*) AS products_never_ordered
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- ============================================================
-- 4. MISSING VALUES & BASIC BUSINESS RULES
-- ============================================================

-- 4.1 Missing product categories

SELECT COUNT(*) AS missing_product_categories
FROM products
WHERE product_category_name IS NULL;

-- 4.2 Invalid prices or freight values

SELECT
    COUNT(*) FILTER (WHERE price <= 0) AS invalid_prices,
    COUNT(*) FILTER (WHERE freight_value < 0) AS invalid_freight
FROM order_items;

-- 4.3 Missing delivery dates by order status

SELECT
    order_status,
    COUNT(*) AS orders_with_missing_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY orders_with_missing_delivery_date DESC;

-- 4.4 Invalid order date sequence

SELECT COUNT(*) AS invalid_delivery_dates
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;