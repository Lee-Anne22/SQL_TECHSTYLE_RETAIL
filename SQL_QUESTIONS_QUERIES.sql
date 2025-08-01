--MONTHLY REVENUE OVER THE PAST YEAR
SELECT 
TOP 12 YEAR(order_date) AS Year, 
MONTH(order_date) AS Month,
SUM(total_amount) AS Total_Revenue
FROM orders   
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date) DESC;
-----------------------------------------------------
--WHICH PRODUCT CATEGORIES GENERATE THE MOST REVENUE
SELECT
p.category,
SUM(oi.quantity * oi.price) AS total_revenue
FROM products AS p
JOIN order_items AS oi ON p.product_id = oi.product_id
JOIN orders AS o ON oi.order_id = o.order_id
GROUP BY p.category
ORDER BY total_revenue DESC;
-----------------------------------------------
-- THE TOP 5 BEST SELLING PRODUCTS PER CATEGORY
SELECT 
category, 
product_name, 
total_revenue
FROM (
    SELECT 
        p.category,
        p.name AS product_name,
        SUM(oi.quantity * oi.price) AS total_revenue,
        RANK() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity * oi.price) DESC) AS revenue_rank
    FROM products AS p
    JOIN order_items AS oi ON p.product_id = oi.product_id
    JOIN orders AS o ON oi.order_id = o.order_id
    GROUP BY p.category, p.name
) ranked_products
WHERE revenue_rank <= 5
ORDER BY category, total_revenue DESC;
-------------------------------------------
--Which products have high stock but poor sales
SELECT 
    product_name,
    stock_quantity,
    total_revenue
FROM (
    SELECT 
        p.category,
        p.name AS product_name,
        p.stock_quantity,
        SUM(oi.quantity * oi.price) AS total_revenue,
        RANK() OVER (
            PARTITION BY p.category 
            ORDER BY SUM(oi.quantity * oi.price) ASC  -- lower revenue gets ranked higher
        ) AS revenue_rank
    FROM products AS p
    LEFT JOIN order_items AS oi ON p.product_id = oi.product_id
    LEFT JOIN orders AS o ON oi.order_id = o.order_id
    GROUP BY p.category, p.name, p.stock_quantity
) ranked_products
ORDER BY stock_quantity DESC;
------------------------------------------------------------------
-- TOP 10 CUSTOMERS BY LIFETIME VALUE
SELECT 
    customer_id,
    name,
    total_revenue
FROM (
    SELECT 
        c.customer_id,
        c.name,
        SUM(oi.quantity * oi.price) AS total_revenue,
        RANK() OVER (
            ORDER BY SUM(oi.quantity * oi.price) DESC
        ) AS revenue_rank
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.name
) ranked_customers
WHERE revenue_rank <= 10
ORDER BY total_revenue DESC;
--Percentage of customers with more than 1 order
WITH OrderCounts AS (
    SELECT customer_id, COUNT(order_id) AS num_orders
    FROM orders
    GROUP BY customer_id
),
CustomersWithMultipleOrders AS (
    SELECT COUNT(*) AS multiple_order_count
    FROM OrderCounts
    WHERE num_orders > 1
),
TotalCustomers AS (
    SELECT COUNT(*) AS total_customer_count
    FROM OrderCounts
)
SELECT 
    ROUND(
        (multiple_order_count * 100.0) / total_customer_count, 
        2
    ) AS percentage_with_multiple_orders
FROM CustomersWithMultipleOrders, TotalCustomers;
--ANY ORDERS WHERE TOTAL AMOUNT NOT = SUM OF ITEMS
SELECT 
    p.price AS productprice,
    oi.price AS orderamount,
    oi.product_id,
    oi.quantity,
    p.price * oi.quantity AS sum_of_items
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE oi.price <> p.price * oi.quantity;
--IDENTIFY DUPLICATE EMAILS IN CUSTOMER TABLE
SELECT 
    email,
    COUNT(*) AS number_of_occurances
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;
