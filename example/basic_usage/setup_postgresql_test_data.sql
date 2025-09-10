-- PostgreSQL Test Data Setup for RAGify Flutter
-- This script creates sample data for testing database connections

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INTEGER,
    department VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    category VARCHAR(50),
    in_stock BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users
INSERT INTO users (name, email, age, department) VALUES
('John Doe', 'john.doe@example.com', 30, 'Engineering'),
('Jane Smith', 'jane.smith@example.com', 25, 'Marketing'),
('Bob Johnson', 'bob.johnson@example.com', 35, 'Sales'),
('Alice Brown', 'alice.brown@example.com', 28, 'Engineering'),
('Charlie Wilson', 'charlie.wilson@example.com', 32, 'HR'),
('Diana Prince', 'diana.prince@example.com', 29, 'Engineering'),
('Eve Adams', 'eve.adams@example.com', 31, 'Marketing'),
('Frank Miller', 'frank.miller@example.com', 27, 'Sales')
ON CONFLICT (email) DO NOTHING;

-- Insert sample products
INSERT INTO products (name, description, price, category, in_stock) VALUES
('Laptop Pro', 'High-performance laptop for professionals', 1299.99, 'Electronics', true),
('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 'Electronics', true),
('Office Chair', 'Comfortable office chair with lumbar support', 199.99, 'Furniture', true),
('Coffee Maker', 'Automatic coffee maker with timer', 89.99, 'Appliances', false),
('Notebook Set', 'Set of 5 professional notebooks', 24.99, 'Stationery', true),
('Desk Lamp', 'LED desk lamp with adjustable brightness', 45.99, 'Furniture', true),
('Bluetooth Headphones', 'Noise-cancelling wireless headphones', 149.99, 'Electronics', true),
('Water Bottle', 'Insulated stainless steel water bottle', 19.99, 'Accessories', true)
ON CONFLICT DO NOTHING;

-- Insert sample orders
INSERT INTO orders (user_id, product_id, quantity, total_amount, status) VALUES
(1, 1, 1, 1299.99, 'completed'),
(2, 2, 2, 59.98, 'completed'),
(3, 3, 1, 199.99, 'pending'),
(4, 1, 1, 1299.99, 'completed'),
(5, 4, 1, 89.99, 'cancelled'),
(6, 5, 3, 74.97, 'completed'),
(7, 6, 1, 45.99, 'pending'),
(8, 7, 1, 149.99, 'completed'),
(1, 8, 2, 39.98, 'completed'),
(2, 1, 1, 1299.99, 'pending')
ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_users_department ON users(department);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Display summary
SELECT 'Users count: ' || COUNT(*) as summary FROM users
UNION ALL
SELECT 'Products count: ' || COUNT(*) as summary FROM products
UNION ALL
SELECT 'Orders count: ' || COUNT(*) as summary FROM orders;
