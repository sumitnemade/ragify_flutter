#!/bin/bash

# MongoDB Setup Test Script
# This script verifies that MongoDB is properly configured for RAGify Flutter testing

echo "🔍 Testing MongoDB Setup for RAGify Flutter..."
echo "=============================================="

# Check if MongoDB service is running
echo "📊 Checking MongoDB service status..."
if systemctl is-active --quiet mongod; then
    echo "✅ MongoDB service is running"
else
    echo "❌ MongoDB service is not running"
    exit 1
fi

# Check MongoDB port
echo "📊 Checking MongoDB port 27017..."
if netstat -tlnp | grep -q ":27017 "; then
    echo "✅ MongoDB is listening on port 27017"
else
    echo "❌ MongoDB is not listening on port 27017"
    exit 1
fi

# Check network binding
echo "📊 Checking MongoDB network binding..."
if grep -q "bindIp: 0.0.0.0" /etc/mongod.conf; then
    echo "✅ MongoDB is configured to accept network connections"
else
    echo "❌ MongoDB is not configured for network access"
    exit 1
fi

# Test connection to test_db
echo "📊 Testing connection to test_db database..."
if mongosh mongodb://192.168.1.16:27017/test_db --quiet --eval "db.runCommand('ping')" > /dev/null 2>&1; then
    echo "✅ Successfully connected to test_db database"
else
    echo "❌ Failed to connect to test_db database"
    exit 1
fi

# Check if collections exist
echo "📊 Checking if sample collections exist..."
USERS_COUNT=$(mongosh mongodb://192.168.1.16:27017/test_db --quiet --eval "db.users.countDocuments()")
PRODUCTS_COUNT=$(mongosh mongodb://192.168.1.16:27017/test_db --quiet --eval "db.products.countDocuments()")
ORDERS_COUNT=$(mongosh mongodb://192.168.1.16:27017/test_db --quiet --eval "db.orders.countDocuments()")

if [ "$USERS_COUNT" -gt 0 ] && [ "$PRODUCTS_COUNT" -gt 0 ] && [ "$ORDERS_COUNT" -gt 0 ]; then
    echo "✅ Sample data found:"
    echo "   - Users: $USERS_COUNT documents"
    echo "   - Products: $PRODUCTS_COUNT documents"
    echo "   - Orders: $ORDERS_COUNT documents"
else
    echo "❌ Sample data not found or incomplete"
    exit 1
fi

# Test sample query
echo "📊 Testing sample query..."
SAMPLE_RESULT=$(mongosh mongodb://192.168.1.16:27017/test_db --quiet --eval "db.users.find({name: /john/i}).limit(1).toArray()")
if echo "$SAMPLE_RESULT" | grep -q "John"; then
    echo "✅ Sample query executed successfully"
else
    echo "❌ Sample query failed"
    exit 1
fi

# Check firewall
echo "📊 Checking firewall configuration..."
if ufw status | grep -q "27017/tcp"; then
    echo "✅ MongoDB port 27017 is open in firewall"
else
    echo "⚠️  MongoDB port 27017 might not be open in firewall"
fi

echo ""
echo "🎉 MongoDB setup test completed successfully!"
echo "📋 Configuration Summary:"
echo "   - Host: 192.168.1.16"
echo "   - Port: 27017"
echo "   - Database: test_db"
echo "   - Username: test_user"
echo "   - Password: test_pass"
echo ""
echo "🔧 Flutter App Configuration:"
echo "   - Database Type: MongoDB"
echo "   - Host: 192.168.1.16"
echo "   - Port: 27017"
echo "   - Database: test_db"
echo "   - Username: test_user"
echo "   - Password: test_pass"
echo ""
echo "📝 Sample Queries:"
echo "   - Find users: {\"name\": {\"\$regex\": \"john\", \"\$options\": \"i\"}}"
echo "   - Find by department: {\"department\": \"Engineering\"}"
echo "   - Find by age range: {\"age\": {\"\$gte\": 25, \"\$lte\": 35}}"
echo "   - Find products by category: {\"category\": \"Electronics\"}"
echo "   - Find orders by status: {\"status\": \"completed\"}"
