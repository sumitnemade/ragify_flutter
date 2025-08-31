import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform detection utilities for RAGify
/// Determines the current Flutter platform and its capabilities
class PlatformDetector {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile platform (Android/iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if running on desktop platform (Windows/macOS/Linux)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if running on Fuchsia platform
  static bool get isFuchsia => !kIsWeb && Platform.isFuchsia;

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Get the current platform name
  static String get platformName {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isWindows) return 'windows';
    if (isMacOS) return 'macos';
    if (isLinux) return 'linux';
    if (isFuchsia) return 'fuchsia';
    return 'unknown';
  }

  /// Check if platform supports a specific feature
  static bool supportsFeature(PlatformFeature feature) {
    switch (feature) {
      case PlatformFeature.sqlite:
        return !isWeb; // SQLite not available on web
      case PlatformFeature.fileSystem:
        return !isWeb; // File system access limited on web
      case PlatformFeature.sharedPreferences:
        return true; // Available on all platforms
      case PlatformFeature.webStorage:
        return isWeb; // Only available on web
      case PlatformFeature.aiModelApis:
        return true; // AI Model APIs available on all platforms
      case PlatformFeature.vectorOperations:
        return true; // Vector operations available on all platforms
      case PlatformFeature.realTimeCommunication:
        return true; // WebSocket available on all platforms
      case PlatformFeature.encryption:
        return true; // Crypto available on all platforms
    }
  }

  /// Get platform-specific recommendations
  static Map<String, String> getPlatformRecommendations() {
    if (isWeb) {
      return {
        'storage': 'Use IndexedDB or localStorage for persistent storage',
        'ml': 'Use AI Model APIs for machine learning operations',
        'vector_ops': 'Use client-side vector operations with API fallbacks',
        'real_time': 'Use WebSocket for real-time communication',
      };
    } else if (isMobile) {
      return {
        'storage':
            'Use SQLite for structured data, SharedPreferences for settings',
        'ml': 'Use AI Model APIs for machine learning operations',
        'vector_ops': 'Use local vector operations with API fallbacks',
        'real_time': 'Use WebSocket for real-time communication',
      };
    } else if (isDesktop) {
      return {
        'storage':
            'Use SQLite for structured data, file system for large files',
        'ml': 'Use AI Model APIs for machine learning operations',
        'vector_ops': 'Use local vector operations with API fallbacks',
        'real_time': 'Use WebSocket for real-time communication',
      };
    } else {
      return {
        'storage': 'Use platform-appropriate storage solutions',
        'ml': 'Use AI Model APIs for machine learning operations',
        'vector_ops': 'Use local vector operations with API fallbacks',
        'real_time': 'Use WebSocket for real-time communication',
      };
    }
  }
}

/// Platform features that can be detected
enum PlatformFeature {
  sqlite, // SQLite database support
  fileSystem, // File system access
  sharedPreferences, // Shared preferences storage
  webStorage, // Web storage (IndexedDB, localStorage)
  aiModelApis, // AI Model API support
  vectorOperations, // Vector operations support
  realTimeCommunication, // Real-time communication support
  encryption, // Encryption support
}
