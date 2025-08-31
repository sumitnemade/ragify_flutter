#!/bin/bash

# 🚀 RAGify Flutter Examples Launcher
# This script makes it easy to run different examples

echo "🚀 RAGify Flutter Examples Launcher"
echo "=================================="
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter first: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "✅ Flutter version: $FLUTTER_VERSION"
echo ""

# Function to run an example
run_example() {
    local example_name=$1
    local example_path=$2
    local description=$3
    
    echo "🎯 Running: $example_name"
    echo "📝 Description: $description"
    echo "📁 Path: $example_path"
    echo ""
    
    # Check if example exists
    if [ ! -f "$example_path" ]; then
        echo "❌ Example not found: $example_path"
        echo ""
        return 1
    fi
    
    # Check if pubspec.yaml exists
    local pubspec_path=$(dirname "$example_path")/pubspec.yaml
    if [ ! -f "$pubspec_path" ]; then
        echo "❌ pubspec.yaml not found: $pubspec_path"
        echo ""
        return 1
    fi
    
    echo "🔄 Getting dependencies..."
    cd "$(dirname "$example_path")"
    flutter pub get
    
    if [ $? -eq 0 ]; then
        echo "✅ Dependencies installed successfully"
        echo "🚀 Starting example..."
        echo ""
        flutter run -d chrome
    else
        echo "❌ Failed to install dependencies"
        echo ""
        return 1
    fi
}

# Main menu
while true; do
    echo "📱 Available Examples:"
    echo "  1. 🚀 Basic Usage (5 minutes)"
    echo "  2. 🎯 Advanced Features"
    echo "  3. 🔗 Full Integration"
    echo "  4. 📊 Show Example Details"
    echo "  5. 🚪 Exit"
    echo ""
    
    read -p "Select an example (1-5): " choice
    
    case $choice in
        1)
            run_example \
                "Basic Usage" \
                "basic_usage/lib/main.dart" \
                "Get started with RAGify in 5 minutes - basic initialization, data sources, context retrieval"
            ;;
        2)
            run_example \
                "Advanced Features" \
                "advanced_features/lib/main.dart" \
                "Master advanced scoring and fusion capabilities - multi-algorithm scoring, user personalization, intelligent fusion"
            ;;
        3)
            run_example \
                "Full Integration" \
                "full_integration/lib/main.dart" \
                "See all RAGify features working together - complete workflow, all engines, comprehensive integration"
            ;;
        4)
            echo ""
            echo "📊 Example Details"
            echo "=================="
            echo ""
            echo "🚀 Basic Usage (basic_usage/)"
            echo "   - Perfect for first-time users"
            echo "   - Minimal setup required"
            echo "   - Demonstrates core functionality"
            echo "   - Run time: ~5 minutes"
            echo ""
            echo "🎯 Advanced Features (advanced_features/)"
            echo "   - Multi-algorithm scoring"
            echo "   - User personalization"
            echo "   - A/B testing capabilities"
            echo "   - Performance monitoring"
            echo "   - Run time: ~8-10 minutes"
            echo ""
            echo "🔗 Full Integration (full_integration/)"
            echo "   - Complete Flutter application"
            echo "   - All features working together"
            echo "   - Interactive UI with real-time updates"
            echo "   - Run time: ~10-15 minutes"
            echo ""
            echo "💡 Learning Path Recommendation:"
            echo "   1. Start with Basic Usage"
            echo "   2. Explore Advanced Features"
            echo "   3. Master Full Integration"
            echo "   4. Integrate into your own app!"
            echo ""
            ;;
        5)
            echo "👋 Goodbye! Happy coding with RAGify Flutter!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please select 1-5."
            echo ""
            ;;
    esac
    
    echo ""
    echo "=================================="
    echo ""
done
