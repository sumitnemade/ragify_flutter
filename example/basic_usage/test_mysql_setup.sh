#!/bin/bash

# MySQL Setup Test Script for RAGify Flutter
echo "🧪 Testing MySQL Setup for RAGify Flutter"
echo "=========================================="

# Test 1: Check if MySQL is running
echo "1️⃣ Checking MySQL service status..."
if systemctl is-active --quiet mysql; then
    echo "✅ MySQL is running"
else
    echo "❌ MySQL is not running. Starting it..."
    sudo systemctl start mysql
fi

# Test 2: Test database connection
echo "2️⃣ Testing database connection..."
if mysql -h 192.168.1.16 -P 3306 -u test_user -ptest_pass test_db -e "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed"
    exit 1
fi

# Test 3: Check if tables exist
echo "3️⃣ Checking if tables exist..."
TABLES=$(mysql -h 192.168.1.16 -P 3306 -u test_user -ptest_pass test_db -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'test_db' AND table_name IN ('users', 'products', 'orders');" -s -N)
if [ "$TABLES" -eq 3 ]; then
    echo "✅ All tables exist (users, products, orders)"
else
    echo "❌ Missing tables. Expected 3, found $TABLES"
fi

# Test 4: Check sample data
echo "4️⃣ Checking sample data..."
USER_COUNT=$(mysql -h 192.168.1.16 -P 3306 -u test_user -ptest_pass test_db -e "SELECT COUNT(*) FROM users;" -s -N)
PRODUCT_COUNT=$(mysql -h 192.168.1.16 -P 3306 -u test_user -ptest_pass test_db -e "SELECT COUNT(*) FROM products;" -s -N)
ORDER_COUNT=$(mysql -h 192.168.1.16 -P 3306 -u test_user -ptest_pass test_db -e "SELECT COUNT(*) FROM orders;" -s -N)

echo "   Users: $USER_COUNT"
echo "   Products: $PRODUCT_COUNT"
echo "   Orders: $ORDER_COUNT"

if [ "$USER_COUNT" -ge 5 ] && [ "$PRODUCT_COUNT" -ge 5 ] && [ "$ORDER_COUNT" -ge 5 ]; then
    echo "✅ Sample data looks good"
else
    echo "❌ Sample data might be incomplete"
fi

# Test 5: Test a sample query
echo "5️⃣ Testing sample query..."
RESULT=$(mysql -h 192.168.1.16 -P 3306 -u test_user -ptest_pass test_db -e "SELECT COUNT(*) FROM users WHERE name LIKE '%john%';" -s -N)
if [ "$RESULT" -ge 1 ]; then
    echo "✅ Sample query works (found $RESULT users with 'john' in name)"
else
    echo "❌ Sample query failed"
fi

echo ""
echo "🎉 MySQL setup test completed!"
echo ""
echo "📋 Connection Details for RAGify Flutter:"
echo "   Database Type: MySQL"
echo "   Host: 192.168.1.16"
echo "   Port: 3306"
echo "   Database: test_db"
echo "   Username: test_user"
echo "   Password: test_pass"
echo ""
echo "🔍 Try these test queries in RAGify Flutter:"
echo "   1. SELECT * FROM users WHERE name LIKE ? (params: %john%)"
echo "   2. SELECT * FROM users WHERE department = ? (params: Engineering)"
echo "   3. SELECT * FROM products WHERE category = ? (params: Electronics)"
