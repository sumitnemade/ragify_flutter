#!/bin/bash

# Setup SQLite database for Android emulator/device
echo "📱 Setting up SQLite database for Android..."

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

# Create a script to copy database to device storage
cat > copy_db_to_device.sh << 'EOF'
#!/bin/bash

# Copy database to Android device/emulator
echo "📱 Copying database to Android device..."

# Get the package name from pubspec.yaml
PACKAGE_NAME=$(grep "name:" pubspec.yaml | cut -d' ' -f2)

# Create app directory on device
adb shell "mkdir -p /data/data/$PACKAGE_NAME/databases"

# Copy database to device
adb push assets/test.db /data/data/$PACKAGE_NAME/databases/test.db

echo "✅ Database copied to device: /data/data/$PACKAGE_NAME/databases/test.db"
echo "📱 Use this path in the Database tab: /data/data/$PACKAGE_NAME/databases/test.db"
EOF

chmod +x copy_db_to_device.sh

echo "📝 Created copy_db_to_device.sh script"
echo ""
echo "🚀 Next steps:"
echo "1. Run: ./copy_db_to_device.sh (to copy to device)"
echo "2. In the Database tab, use: /data/data/$PACKAGE_NAME/databases/test.db"
echo "3. Or use the asset path: assets/test.db"
