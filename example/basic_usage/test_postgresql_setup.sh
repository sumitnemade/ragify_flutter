#!/bin/bash

# PostgreSQL Setup Test Script for RAGify Flutter
echo "🧪 Testing PostgreSQL Setup for RAGify Flutter"
echo "=============================================="

# Test 1: Check if PostgreSQL is running
echo "1️⃣ Checking PostgreSQL service status..."
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL is running"
else
    echo "❌ PostgreSQL is not running. Starting it..."
    sudo systemctl start postgresql
fi

# Test 2: Test database connection
echo "2️⃣ Testing database connection..."
if PGPASSWORD=test_pass psql -h localhost -p 5432 -U test_user -d test_db -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed"
    exit 1
fi

# Test 3: Check if tables exist
echo "3️⃣ Checking if tables exist..."
TABLES=$(PGPASSWORD=test_pass psql -h localhost -p 5432 -U test_user -d test_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('users', 'products', 'orders');")
if [ "$TABLES" -eq 3 ]; then
    echo "✅ All tables exist (users, products, orders)"
else
    echo "❌ Missing tables. Expected 3, found $TABLES"
fi

# Test 4: Check sample data
echo "4️⃣ Checking sample data..."
USER_COUNT=$(PGPASSWORD=test_pass psql -h localhost -p 5432 -U test_user -d test_db -t -c "SELECT COUNT(*) FROM users;")
PRODUCT_COUNT=$(PGPASSWORD=test_pass psql -h localhost -p 5432 -U test_user -d test_db -t -c "SELECT COUNT(*) FROM products;")
ORDER_COUNT=$(PGPASSWORD=test_pass psql -h localhost -p 5432 -U test_user -d test_db -t -c "SELECT COUNT(*) FROM orders;")

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
RESULT=$(PGPASSWORD=test_pass psql -h localhost -p 5432 -U test_user -d test_db -t -c "SELECT COUNT(*) FROM users WHERE name ILIKE '%john%';")
if [ "$RESULT" -ge 1 ]; then
    echo "✅ Sample query works (found $RESULT users with 'john' in name)"
else
    echo "❌ Sample query failed"
fi

echo ""
echo "🎉 PostgreSQL setup test completed!"
echo ""
echo "📋 Connection Details for RAGify Flutter:"
echo "   Database Type: PostgreSQL"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: test_db"
echo "   Username: test_user"
echo "   Password: test_pass"
echo ""
echo "🔍 Try these test queries in RAGify Flutter:"
echo "   1. SELECT * FROM users WHERE name ILIKE \$1 (params: %john%)"
echo "   2. SELECT * FROM users WHERE department = \$1 (params: Engineering)"
echo "   3. SELECT * FROM products WHERE category = \$1 (params: Electronics)"
