#!/bin/bash

# Setup SQLite database for iOS simulator/device
echo "🍎 Setting up SQLite database for iOS..."

# Create the database in assets if it doesn't exist
if [ ! -f "test_databases/test.db" ]; then
    echo "❌ Database not found. Please run setup_sqlite_testing.sh first"
    exit 1
fi

# Create assets directory if it doesn't exist
mkdir -p assets

# Copy database to assets
cp test_databases/test.db assets/test.db
echo "✅ Database copied to assets/test.db"

# Create a script to copy database to iOS simulator
cat > copy_db_to_ios.sh << 'EOF'
#!/bin/bash

# Copy database to iOS simulator
echo "🍎 Copying database to iOS simulator..."

# Get simulator path
SIMULATOR_PATH=$(xcrun simctl get_app_container booted com.example.ragifyBasicUsage data)
if [ -z "$SIMULATOR_PATH" ]; then
    echo "❌ iOS simulator not running or app not installed"
    echo "Please run: flutter run on iOS simulator first"
    exit 1
fi

# Copy database to simulator
cp assets/test.db "$SIMULATOR_PATH/Documents/test.db"

echo "✅ Database copied to iOS simulator: $SIMULATOR_PATH/Documents/test.db"
echo "🍎 Use this path in the Database tab: $SIMULATOR_PATH/Documents/test.db"
EOF

chmod +x copy_db_to_ios.sh

echo "📝 Created copy_db_to_ios.sh script"
echo ""
echo "🚀 Next steps:"
echo "1. Run: flutter run on iOS simulator"
echo "2. Run: ./copy_db_to_ios.sh (to copy to simulator)"
echo "3. In the Database tab, use the path shown above"
echo "4. Or use the asset path: assets/test.db"
