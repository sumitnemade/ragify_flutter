#!/bin/bash

# Universal database setup for all platforms
echo "🚀 Setting up SQLite database for all platforms..."

# Check if database exists
if [ ! -f "test_databases/test.db" ]; then
    echo "❌ Database not found. Please run setup_sqlite_testing.sh first"
    exit 1
fi

# Create assets directory
mkdir -p assets
cp test_databases/test.db assets/test.db
echo "✅ Database copied to assets/test.db"

# Create platform-specific directories and copy database
mkdir -p web/assets
cp test_databases/test.db web/assets/test.db
echo "✅ Database copied to web/assets/test.db"

# Create a comprehensive guide
cat > DATABASE_PATHS_GUIDE.md << 'EOF'
# Database Paths for Different Platforms

## 📱 Android Emulator/Device
**Path:** `/data/data/com.example.ragify_basic_usage/databases/test.db`

**Setup:**
1. Run: `./setup_android_database.sh`
2. Run: `./copy_db_to_device.sh`
3. Use the path above in Database tab

## 🍎 iOS Simulator/Device
**Path:** `[Simulator Path]/Documents/test.db`

**Setup:**
1. Run: `./setup_ios_database.sh`
2. Run: `flutter run` on iOS simulator
3. Run: `./copy_db_to_ios.sh`
4. Use the path shown in Database tab

## 🌐 Web Platform
**Path:** `assets/test.db`

**Setup:**
1. Run: `./setup_web_database.sh`
2. Run: `flutter run -d chrome`
3. Use `assets/test.db` in Database tab

## 🖥️ Desktop (Linux/Windows/macOS)
**Path:** `test_databases/test.db` (relative to app directory)

**Setup:**
1. Database is already in the right location
2. Use `test_databases/test.db` in Database tab

## 🔧 Alternative: Use Asset Database

For all platforms, you can use the asset database:
- **Path:** `assets/test.db`
- **Note:** This is read-only on most platforms

## 📝 Quick Test Commands

### Android
```bash
# Copy to device
adb push test_databases/test.db /data/data/com.example.ragify_basic_usage/databases/test.db

# Verify
adb shell "ls -la /data/data/com.example.ragify_basic_usage/databases/"
```

### iOS
```bash
# Get simulator path
xcrun simctl get_app_container booted com.example.ragifyBasicUsage data

# Copy to simulator
cp test_databases/test.db "[SIMULATOR_PATH]/Documents/test.db"
```

### Web
```bash
# Copy to web assets
cp test_databases/test.db web/assets/test.db
```

## 🎯 Recommended Approach

1. **For Testing:** Use the asset database (`assets/test.db`)
2. **For Production:** Copy to platform-specific data directory
3. **For Development:** Use the local file path

## 🚨 Important Notes

- **Android:** Requires app to be installed first
- **iOS:** Requires simulator to be running
- **Web:** Database is downloaded to user's device
- **Desktop:** Use relative paths from app directory
EOF

echo "📚 Created DATABASE_PATHS_GUIDE.md"
echo ""
echo "🎉 Setup complete for all platforms!"
echo ""
echo "📱 Quick start:"
echo "1. Choose your platform:"
echo "   - Android: ./setup_android_database.sh"
echo "   - iOS: ./setup_ios_database.sh"
echo "   - Web: ./setup_web_database.sh"
echo "2. Run the setup script for your platform"
echo "3. Use the recommended path in Database tab"
echo ""
echo "📖 See DATABASE_PATHS_GUIDE.md for detailed instructions"
