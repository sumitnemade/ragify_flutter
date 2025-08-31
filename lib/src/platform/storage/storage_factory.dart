import 'package:flutter/foundation.dart';
import 'storage_interface.dart';
import 'mobile_storage.dart';
import 'web_storage.dart';
import 'desktop_storage.dart';

/// Factory class for creating platform-specific storage implementations
class StorageFactory {
  static CrossPlatformStorage? _instance;

  /// Get the appropriate storage implementation for the current platform
  static CrossPlatformStorage get storage {
    _instance ??= _createStorage();
    return _instance!;
  }

  /// Create a new storage instance for the current platform
  static CrossPlatformStorage _createStorage() {
    if (kIsWeb) {
      return WebStorage();
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return MobileStorage();
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return DesktopStorage();
    } else {
      // Fallback to mobile storage for other platforms (like Fuchsia)
      return MobileStorage();
    }
  }

  /// Create a specific storage implementation
  static CrossPlatformStorage createStorage(StorageType type) {
    switch (type) {
      case StorageType.mobile:
        return MobileStorage();
      case StorageType.web:
        return WebStorage();
      case StorageType.desktop:
        return DesktopStorage();
      case StorageType.auto:
        return _createStorage();
    }
  }

  /// Reset the singleton instance (useful for testing)
  static void reset() {
    _instance = null;
  }
}

/// Available storage types
enum StorageType { mobile, web, desktop, auto }
