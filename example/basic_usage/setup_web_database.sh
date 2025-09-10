#!/bin/bash

# Setup SQLite database for Web platform
echo "🌐 Setting up SQLite database for Web..."

# Create the database in assets if it doesn't exist
if [ ! -f "test_databases/test.db" ]; then
    echo "❌ Database not found. Please run setup_sqlite_testing.sh first"
    exit 1
fi

# Create web/assets directory if it doesn't exist
mkdir -p web/assets

# Copy database to web assets
cp test_databases/test.db web/assets/test.db
echo "✅ Database copied to web/assets/test.db"

# Create a simple web page to test database access
cat > web/database_test.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Database Test</title>
</head>
<body>
    <h1>Database Test Page</h1>
    <p>Database file: <a href="assets/test.db" download>test.db</a></p>
    <p>Use this path in the Database tab: assets/test.db</p>
</body>
</html>
EOF

echo "📝 Created web/database_test.html"
echo ""
echo "🚀 Next steps:"
echo "1. Run: flutter run -d chrome"
echo "2. In the Database tab, use: assets/test.db"
echo "3. Or visit: http://localhost:port/database_test.html"
