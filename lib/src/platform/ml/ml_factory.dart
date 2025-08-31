import 'package:flutter/foundation.dart';
import 'ml_interface.dart';
import 'mobile_ml.dart';
import 'web_ml.dart';

/// Factory class for creating platform-specific ML implementations
class MLFactory {
  static CrossPlatformML? _instance;

  /// Get the appropriate ML implementation for the current platform
  static CrossPlatformML get ml {
    _instance ??= _createML();
    return _instance!;
  }

  /// Create a new ML instance for the current platform
  static CrossPlatformML _createML() {
    if (kIsWeb) {
      return WebML();
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return MobileML();
    } else {
      // For desktop and other platforms, fallback to mobile implementation
      // In a real implementation, you'd have a desktop-specific ML implementation
      return MobileML();
    }
  }

  /// Create a specific ML implementation
  static CrossPlatformML createML(MLType type) {
    switch (type) {
      case MLType.mobile:
        return MobileML();
      case MLType.web:
        return WebML();
      case MLType.auto:
        return _createML();
    }
  }

  /// Reset the singleton instance (useful for testing)
  static void reset() {
    _instance = null;
  }
}

/// Available ML types
enum MLType { mobile, web, auto }
