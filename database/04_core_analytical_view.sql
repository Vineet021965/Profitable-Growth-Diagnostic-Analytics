-- ============================================================
-- Project: Growth Without Profit Analytics
-- File: 04_core_analytical_view.sql
-- Purpose: Create reusable order-item-level analytical view
-- ============================================================

CREATE OR REPLACE VIEW vw_core_order_items AS

SELECT
    o.order_id,
    o.order_purchase_timestamp,
    o.order_status,

    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,

    p.product_category_name

FROM orders o

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

LEFT JOIN products p
    ON oi.product_id = p.product_id;

SELECT COUNT(*)
FROM vw_core_order_items;

SELECT *
FROM vw_core_order_items
LIMIT 10;