# 🚀 RAGify Flutter Package Examples

Welcome to the RAGify Flutter package examples! This directory contains **working Flutter applications** that demonstrate how to use the RAGify Flutter package in real Flutter projects.

## 🎯 **What This Provides**

These are **actual Flutter apps** that you can run, modify, and use as a starting point for your own projects. Each example is a complete, working Flutter application that imports and uses the RAGify package.

## 📱 **Available Examples**

### **1. 🚀 Basic Usage** (`basic_usage/`)
- **Purpose**: Get started with RAGify in 5 minutes
- **What you'll learn**: Basic initialization, data sources, context retrieval
- **Features**: Simple search interface, system status, basic logging
- **Perfect for**: First-time users, understanding core concepts

### **2. 🎯 Advanced Features** (`advanced_features/`)
- **Purpose**: Master advanced scoring and fusion capabilities
- **What you'll learn**: Multi-algorithm scoring, user personalization, intelligent fusion
- **Features**: Tabbed interface, advanced scoring, fusion engine, user profiles
- **Perfect for**: Building intelligent content systems, user personalization

### **3. 🔗 Full Integration** (`full_integration/`)
- **Purpose**: See all RAGify features working together
- **What you'll learn**: Complete workflow, all engines, comprehensive integration
- **Features**: Full feature set, real-time updates, comprehensive monitoring
- **Perfect for**: Understanding complete workflow, production applications

## 🏃‍♂️ **How to Run Examples**

### **Prerequisites**
1. **Flutter SDK** (3.10.0 or higher)
2. **Dart SDK** (3.8.1 or higher)
3. **RAGify Flutter package** (this project)

### **Running Examples**

#### **Option 1: Run from Root Directory**
```bash
# From the ragify_flutter root directory
flutter run -d chrome example/basic_usage/lib/main.dart
flutter run -d chrome example/advanced_features/lib/main.dart
flutter run -d chrome example/full_integration/lib/main.dart
```

#### **Option 2: Run from Example Directory**
```bash
# Navigate to specific example
cd example/basic_usage
flutter run -d chrome

# Or for mobile
flutter run -d android
flutter run -d ios
```

#### **Option 3: Open in IDE**
1. Open the example directory in your IDE (VS Code, Android Studio, etc.)
2. Run the `main.dart` file directly

## 🔧 **How Examples Work**

### **Package Import**
Each example imports the RAGify package using:
```dart
import 'package:ragify_flutter/ragify_flutter.dart';
```

### **Local Development**
Examples use `path: ../` to import the package from the parent directory, allowing you to:
- **Modify the package** and see changes immediately
- **Test new features** before publishing
- **Debug package issues** in real Flutter apps

### **Real Flutter Apps**
These are **actual Flutter applications** that:
- Use **Material Design** components
- Have **proper state management**
- Include **error handling** and **loading states**
- Show **real-time updates** and **interactive features**

## 📚 **Learning Path**

### **🟢 Beginner: Start with Basic Usage**
1. **Run the basic usage example**
2. **Understand initialization** and basic setup
3. **See how data sources work**
4. **Learn basic context retrieval**

### **🟡 Intermediate: Explore Advanced Features**
1. **Run the advanced features example**
2. **Master advanced scoring** algorithms
3. **Understand user personalization**
4. **Learn intelligent fusion** strategies

### **🔴 Advanced: Master Full Integration**
1. **Run the full integration example**
2. **See all features working together**
3. **Understand complete workflows**
4. **Learn production patterns**

## 🛠 **Customizing Examples**

### **Modifying for Your Use Case**
1. **Copy an example** to your project
2. **Update the package import** to use the published version:
   ```yaml
   dependencies:
     ragify_flutter: ^1.0.0  # Use published version
   ```
3. **Modify the UI** and business logic
4. **Add your data sources** and requirements

### **Common Customizations**
- **Database connections** for your specific databases
- **API endpoints** for your services
- **UI themes** matching your brand
- **Business logic** for your domain
- **Error handling** for your requirements

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. Package Not Found**
```bash
# Ensure you're in the example directory
cd example/basic_usage

# Get dependencies
flutter pub get
```

#### **2. Import Errors**
- Check that the package path is correct in `pubspec.yaml`
- Ensure you're running from the example directory
- Verify Flutter and Dart versions

#### **3. Platform Issues**
- **Web**: Use `flutter run -d chrome`
- **Android**: Use `flutter run -d android`
- **iOS**: Use `flutter run -d ios`

### **Getting Help**
1. **Check the logs** in the app
2. **Verify Flutter version**: `flutter --version`
3. **Check dependencies**: `flutter pub deps`
4. **Clean and rebuild**: `flutter clean && flutter pub get`

## 📊 **Example Features Matrix**

| Feature | Basic Usage | Advanced Features | Full Integration |
|---------|-------------|------------------|------------------|
| **Core Setup** | ✅ Complete | ✅ Complete | ✅ Complete |
| **Data Sources** | ✅ Basic | ✅ Basic | ✅ Complete |
| **Context Retrieval** | ✅ Basic | ✅ Basic | ✅ Complete |
| **Vector Search** | ✅ Basic | ✅ Basic | ✅ Complete |
| **Advanced Scoring** | ❌ None | ✅ Complete | ✅ Complete |
| **Advanced Fusion** | ❌ None | ✅ Complete | ✅ Complete |
| **Privacy & Security** | ❌ Basic | ❌ Basic | ✅ Complete |
| **Real-time Updates** | ❌ None | ❌ None | ✅ Complete |
| **Comprehensive Monitoring** | ❌ Basic | ❌ Basic | ✅ Complete |

## 🎯 **Next Steps**

### **After Running Examples**
1. **Understand the code** - Read through the implementation
2. **Modify features** - Change UI, add functionality
3. **Integrate into your app** - Use patterns from examples
4. **Customize for your domain** - Adapt to your use case

### **Building Your Own App**
1. **Start with basic usage** as a template
2. **Add advanced features** as needed
3. **Customize the UI** for your brand
4. **Integrate with your backend** and data sources

## 🤝 **Contributing**

### **Improving Examples**
1. **Report issues** with examples
2. **Submit improvements** via pull requests
3. **Add new examples** for specific use cases
4. **Improve documentation** and code comments

### **Sharing Your Use Cases**
1. **Show how you used RAGify** in your projects
2. **Share customizations** and improvements
3. **Contribute patterns** that worked for you
4. **Help other developers** learn from your experience

---

## 🎉 **Ready to Get Started?**

**Choose an example and run it:**

```bash
# Quick start (5 minutes)
flutter run -d chrome example/basic_usage/lib/main.dart

# Advanced features
flutter run -d chrome example/advanced_features/lib/main.dart

# Full integration
flutter run -d chrome example/full_integration/lib/main.dart
```

**These are REAL Flutter apps that you can run, modify, and use in your own projects!**

---

*For more information about the RAGify package, see the main [README.md](../README.md) and [documentation](../docs/).*
