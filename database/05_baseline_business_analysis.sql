-- ============================================================
-- Project: Growth Without Profit Analytics
-- File: 05_baseline_business_analysis.sql
-- Purpose: Analyze baseline growth and business performance
-- ============================================================


-- 1. OVERALL BUSINESS PERFORMANCE

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(AVG(price), 2) AS avg_item_price,
    ROUND(SUM(freight_value), 2) AS total_freight_cost
FROM vw_core_order_items
WHERE order_status = 'delivered';

-- 2. YEARLY BUSINESS GROWTH

SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight
FROM vw_core_order_items
WHERE order_status = 'delivered'
GROUP BY EXTRACT(YEAR FROM order_purchase_timestamp)
ORDER BY year;

-- 3. PRODUCT CATEGORY REVENUE ANALYSIS

SELECT
    COALESCE(product_category_name, 'unknown') AS product_category,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(AVG(price), 2) AS avg_item_price
FROM vw_core_order_items
WHERE order_status = 'delivered'
GROUP BY product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 4. CUSTOMER REGION REVENUE ANALYSIS

SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(AVG(freight_value), 2) AS avg_freight_per_item
FROM vw_core_order_items
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY total_revenue DESC;

-- 5. FREIGHT BURDEN TREND

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight,
    ROUND(
        100.0 * SUM(freight_value) / NULLIF(SUM(price), 0),
        2
    ) AS freight_to_revenue_pct
FROM vw_core_order_items
WHERE order_status = 'delivered'
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY month;