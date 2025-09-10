-- SQLite Test Queries for RAGify Flutter
-- Copy and paste these queries into the Database testing tab

-- Basic Queries
SELECT 'Basic Queries' as section;

-- 1. Find users by name
SELECT * FROM users WHERE name LIKE '%john%';

-- 2. Find users by department
SELECT * FROM users WHERE department = 'Engineering';

-- 3. Find users by age range
SELECT * FROM users WHERE age BETWEEN 25 AND 30;

-- 4. Count users by department
SELECT department, COUNT(*) as user_count FROM users GROUP BY department;

-- Advanced Queries
SELECT 'Advanced Queries' as section;

-- 5. Find users with highest salary
SELECT name, department, salary FROM users ORDER BY salary DESC LIMIT 3;

-- 6. Find products by category
SELECT * FROM products WHERE category = 'Electronics';

-- 7. Find products with low stock
SELECT name, stock_quantity FROM products WHERE stock_quantity < 50;

-- 8. Find completed orders
SELECT o.id, u.name as user_name, p.name as product_name, o.quantity, o.total_amount
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN products p ON o.product_id = p.id
WHERE o.status = 'completed';

-- 9. Find total sales by department
SELECT u.department, SUM(o.total_amount) as total_sales, COUNT(o.id) as order_count
FROM orders o
JOIN users u ON o.user_id = u.id
GROUP BY u.department;

-- 10. Find most popular products
SELECT p.name, SUM(o.quantity) as total_ordered, SUM(o.total_amount) as total_revenue
FROM orders o
JOIN products p ON o.product_id = p.id
GROUP BY p.id, p.name
ORDER BY total_ordered DESC;
