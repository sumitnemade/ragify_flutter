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
