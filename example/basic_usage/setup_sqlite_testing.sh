#!/bin/bash

# SQLite Testing Setup Script for RAGify Flutter
# This script creates a sample SQLite database with test data

echo "🗄️  Setting up SQLite testing environment for RAGify Flutter..."

# Create test directory
mkdir -p test_databases
cd test_databases

# Create sample SQLite database
echo "📊 Creating sample SQLite database..."

sqlite3 test.db << 'EOF'
-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INTEGER,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50),
    stock_quantity INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    product_id INTEGER,
    quantity INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Insert sample users
INSERT INTO users (name, email, age, department, salary) VALUES
('John Doe', 'john.doe@example.com', 30, 'Engineering', 75000.00),
('Jane Smith', 'jane.smith@example.com', 25, 'Marketing', 65000.00),
('Bob Johnson', 'bob.johnson@example.com', 35, 'Sales', 70000.00),
('Alice Brown', 'alice.brown@example.com', 28, 'Engineering', 80000.00),
('Charlie Wilson', 'charlie.wilson@example.com', 32, 'HR', 60000.00),
('Diana Prince', 'diana.prince@example.com', 29, 'Marketing', 68000.00),
('Eve Adams', 'eve.adams@example.com', 31, 'Sales', 72000.00),
('Frank Miller', 'frank.miller@example.com', 27, 'Engineering', 76000.00);

-- Insert sample products
INSERT INTO products (name, description, price, category, stock_quantity) VALUES
('Laptop Pro', 'High-performance laptop for professionals', 1299.99, 'Electronics', 50),
('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 'Electronics', 200),
('Office Chair', 'Comfortable ergonomic office chair', 199.99, 'Furniture', 30),
('Coffee Maker', 'Automatic coffee maker with timer', 89.99, 'Appliances', 25),
('Notebook Set', 'Premium notebook set with pen', 15.99, 'Stationery', 100),
('Desk Lamp', 'LED desk lamp with adjustable brightness', 45.99, 'Furniture', 40),
('USB Cable', 'High-speed USB-C cable', 12.99, 'Electronics', 150),
('Water Bottle', 'Insulated stainless steel water bottle', 24.99, 'Accessories', 75);

-- Insert sample orders
INSERT INTO orders (user_id, product_id, quantity, total_amount, status) VALUES
(1, 1, 1, 1299.99, 'completed'),
(1, 2, 2, 59.98, 'completed'),
(2, 3, 1, 199.99, 'pending'),
(3, 4, 1, 89.99, 'shipped'),
(4, 1, 1, 1299.99, 'completed'),
(5, 5, 3, 47.97, 'completed'),
(6, 6, 1, 45.99, 'pending'),
(7, 7, 5, 64.95, 'shipped'),
(8, 8, 2, 49.98, 'completed');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_users_department ON users(department);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(order_date);

-- Show table information
.schema
.tables

-- Show sample data
SELECT 'Users Table:' as info;
SELECT * FROM users LIMIT 5;

SELECT 'Products Table:' as info;
SELECT * FROM products LIMIT 5;

SELECT 'Orders Table:' as info;
SELECT * FROM orders LIMIT 5;

-- Show table counts
SELECT 'Table Counts:' as info;
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'products' as table_name, COUNT(*) as count FROM products
UNION ALL
SELECT 'orders' as table_name, COUNT(*) as count FROM orders;
EOF

echo "✅ SQLite database created successfully!"
echo "📁 Database location: $(pwd)/test.db"
echo "📊 Database contains:"
echo "   - 8 users"
echo "   - 8 products" 
echo "   - 9 orders"
echo "   - Proper indexes for performance"

# Create a simple test script
cat > test_queries.sql << 'EOF'
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
EOF

echo "📝 Test queries saved to: $(pwd)/test_queries.sql"

# Create a quick verification script
cat > verify_setup.sh << 'EOF'
#!/bin/bash
echo "🔍 Verifying SQLite setup..."

if [ -f "test.db" ]; then
    echo "✅ Database file exists"
    
    # Check if tables exist
    TABLES=$(sqlite3 test.db ".tables")
    if [ ! -z "$TABLES" ]; then
        echo "✅ Tables created: $TABLES"
        
        # Check data counts
        USER_COUNT=$(sqlite3 test.db "SELECT COUNT(*) FROM users;")
        PRODUCT_COUNT=$(sqlite3 test.db "SELECT COUNT(*) FROM products;")
        ORDER_COUNT=$(sqlite3 test.db "SELECT COUNT(*) FROM orders;")
        
        echo "✅ Data loaded:"
        echo "   - Users: $USER_COUNT"
        echo "   - Products: $PRODUCT_COUNT"
        echo "   - Orders: $ORDER_COUNT"
        
        echo ""
        echo "🎉 SQLite setup verification successful!"
        echo "📱 You can now test with the RAGify Flutter Database tab:"
        echo "   - Database Type: SQLite"
        echo "   - Database Name: $(pwd)/test.db"
        echo "   - Try query: SELECT * FROM users WHERE name LIKE ?"
        echo "   - Try parameters: %john%"
        
    else
        echo "❌ No tables found in database"
        exit 1
    fi
else
    echo "❌ Database file not found"
    exit 1
fi
EOF

chmod +x verify_setup.sh

echo "🔍 Verification script created: $(pwd)/verify_setup.sh"
echo ""
echo "🚀 Setup complete! Next steps:"
echo "1. Run: ./verify_setup.sh (to verify the setup)"
echo "2. Open RAGify Flutter app"
echo "3. Go to Database tab"
echo "4. Select SQLite"
echo "5. Enter database path: $(pwd)/test.db"
echo "6. Try the sample queries!"
echo ""
echo "📚 Sample queries are in: $(pwd)/test_queries.sql"
