# SQLite Testing Database for RAGify Flutter

This directory contains a pre-configured SQLite database for testing the RAGify Flutter Database testing tab.

## Database Contents

### Tables
- **users** - 8 sample users with departments, salaries, and contact info
- **products** - 8 sample products with categories, prices, and stock
- **orders** - 9 sample orders linking users and products

### Sample Data
- **Users**: John Doe, Jane Smith, Bob Johnson, Alice Brown, Charlie Wilson, Diana Prince, Eve Adams, Frank Miller
- **Products**: Laptop Pro, Wireless Mouse, Office Chair, Coffee Maker, Notebook Set, Desk Lamp, USB Cable, Water Bottle
- **Orders**: Various completed, pending, and shipped orders

## Quick Start

1. **Open RAGify Flutter app**
2. **Navigate to Database tab**
3. **Select SQLite**
4. **Enter database path**: `test.db` (relative to this directory)
5. **Try sample queries!**

## Sample Queries

### Basic Queries
```sql
-- Find users by name
SELECT * FROM users WHERE name LIKE ?

-- Find users by department  
SELECT * FROM users WHERE department = ?

-- Find products by category
SELECT * FROM products WHERE category = ?

-- Count users by department
SELECT department, COUNT(*) as user_count FROM users GROUP BY department
```

### Advanced Queries
```sql
-- Find completed orders with user and product details
SELECT o.id, u.name as user_name, p.name as product_name, o.quantity, o.total_amount
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN products p ON o.product_id = p.id
WHERE o.status = 'completed';

-- Find total sales by department
SELECT u.department, SUM(o.total_amount) as total_sales, COUNT(o.id) as order_count
FROM orders o
JOIN users u ON o.user_id = u.id
GROUP BY u.department;

-- Find most popular products
SELECT p.name, SUM(o.quantity) as total_ordered, SUM(o.total_amount) as total_revenue
FROM orders o
JOIN products p ON o.product_id = p.id
GROUP BY p.id, p.name
ORDER BY total_ordered DESC;
```

## Test Parameters

### Query 1: Find users by name
- **Query**: `SELECT * FROM users WHERE name LIKE ?`
- **Parameters**: `%john%`
- **Expected**: Returns John Doe and Bob Johnson

### Query 2: Find Engineering users
- **Query**: `SELECT * FROM users WHERE department = ?`
- **Parameters**: `Engineering`
- **Expected**: Returns John Doe, Alice Brown, Frank Miller

### Query 3: Find products under $50
- **Query**: `SELECT * FROM products WHERE price < ?`
- **Parameters**: `50`
- **Expected**: Returns Wireless Mouse, Notebook Set, USB Cable, Water Bottle

### Query 4: Find completed orders
- **Query**: `SELECT * FROM orders WHERE status = ?`
- **Parameters**: `completed`
- **Expected**: Returns 5 completed orders

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INTEGER,
    department VARCHAR(50),
    salary DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Products Table
```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50),
    stock_quantity INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Orders Table
```sql
CREATE TABLE orders (
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
```

## Files

- **test.db** - SQLite database file
- **test_queries.sql** - Sample queries for testing
- **verify_setup.sh** - Verification script
- **README.md** - This documentation

## Troubleshooting

### Database not found
- Make sure you're using the correct path: `test.db`
- Check that the file exists in this directory

### Query errors
- Use `?` for parameter placeholders in SQLite
- Check table and column names are correct
- Try simpler queries first

### No results
- Verify the query syntax
- Check if the data exists
- Try without parameters first

## Next Steps

1. Test basic queries first
2. Try parameterized queries
3. Experiment with JOINs
4. Test complex aggregations
5. Try different database types (PostgreSQL, MySQL, MongoDB)

Happy testing! 🚀
