import 'dart:async';

import 'platform_detector.dart';
import 'storage/storage_factory.dart';
import 'storage/storage_interface.dart';
import 'ml/ml_factory.dart';
import 'ml/ml_interface.dart';
import '../utils/ragify_logger.dart';

/// Cross-platform service locator that provides platform-appropriate implementations
class CrossPlatformServiceLocator {
  static CrossPlatformServiceLocator? _instance;
  static RAGifyLogger _logger = const RAGifyLogger.disabled();

  CrossPlatformServiceLocator._();

  /// Logger instance
  RAGifyLogger get logger => _logger;

  /// Get the singleton instance
  static CrossPlatformServiceLocator get instance {
    _instance ??= CrossPlatformServiceLocator._();
    return _instance!;
  }

  /// Set logger for the singleton instance
  static void setLogger(RAGifyLogger logger) {
    _logger = logger;
    // Also set logger in dependent factories
    StorageFactory.setLogger(logger);
  }

  /// Get the current platform name
  String get platformName => PlatformDetector.platformName;

  /// Get the cross-platform storage implementation
  CrossPlatformStorage get storage => StorageFactory.storage;

  /// Get the cross-platform ML implementation
  CrossPlatformML get ml => MLFactory.ml;

  /// Check if a specific feature is supported on the current platform
  bool supportsFeature(PlatformFeature feature) {
    return PlatformDetector.supportsFeature(feature);
  }

  /// Get platform capabilities summary
  Map<String, dynamic> getPlatformCapabilities() {
    return {
      'platform': platformName,
      'isWeb': PlatformDetector.isWeb,
      'isMobile': PlatformDetector.isMobile,
      'isDesktop': PlatformDetector.isDesktop,
      'isFuchsia': PlatformDetector.isFuchsia,
      'features': {
        'aiModelApis': supportsFeature(PlatformFeature.aiModelApis),
        'vectorOperations': supportsFeature(PlatformFeature.vectorOperations),
        'encryption': supportsFeature(PlatformFeature.encryption),
        'sqlite': supportsFeature(PlatformFeature.sqlite),
        'webStorage': supportsFeature(PlatformFeature.webStorage),
        'fileSystem': supportsFeature(PlatformFeature.fileSystem),
        'sharedPreferences': supportsFeature(PlatformFeature.sharedPreferences),
        'realTimeCommunication': supportsFeature(
          PlatformFeature.realTimeCommunication,
        ),
      },
      'storage': {
        'type': _getStorageType(),
        'capabilities': _getStorageCapabilities(),
      },
      'ml': {'type': _getMLType(), 'capabilities': _getMLCapabilities()},
    };
  }

  /// Get storage type information
  String _getStorageType() {
    if (PlatformDetector.isWeb) {
      return 'WebStorage (IndexedDB + localStorage)';
    }
    if (PlatformDetector.isMobile) {
      return 'MobileStorage (SQLite + SharedPreferences)';
    }
    if (PlatformDetector.isDesktop) {
      return 'DesktopStorage (SQLite + File System)';
    }
    return 'MobileStorage (Fallback)';
  }

  /// Get ML type information
  String _getMLType() {
    if (PlatformDetector.isWeb) {
      return 'WebML (TensorFlow.js)';
    }
    if (PlatformDetector.isMobile) {
      return 'MobileML (TensorFlow Lite)';
    }
    return 'MobileML (Fallback)';
  }

  /// Get storage capabilities
  Map<String, dynamic> _getStorageCapabilities() {
    if (PlatformDetector.isWeb) {
      return {
        'persistent': true,
        'encrypted': false,
        'sync': false,
        'offline': true,
        'maxSize': 'Unlimited (browser dependent)',
      };
    } else {
      return {
        'persistent': true,
        'encrypted': false,
        'sync': false,
        'offline': true,
        'maxSize': 'Limited by device storage',
      };
    }
  }

  /// Get ML capabilities
  Map<String, dynamic> _getMLCapabilities() {
    if (PlatformDetector.isWeb) {
      return {
        'modelFormat': 'TensorFlow.js',
        'hardwareAcceleration': 'WebGL/WebGPU',
        'offline': false,
        'modelSize': 'Limited by browser memory',
        'performance': 'Good for inference, slower for training',
      };
    } else {
      return {
        'modelFormat': 'TensorFlow Lite',
        'hardwareAcceleration': 'GPU/Neural Engine',
        'offline': true,
        'modelSize': 'Limited by device memory',
        'performance': 'Excellent for inference, good for training',
      };
    }
  }

  /// Reset all factories (useful for testing)
  void reset() {
    StorageFactory.reset();
    MLFactory.reset();
  }

  /// Initialize all services
  Future<void> initialize() async {
    try {
      // Initialize storage
      await storage.initialize();

      // Initialize ML
      await ml.initialize();

      logger.i('Cross-platform services initialized successfully');
      logger.i('Platform: $platformName');
      logger.i('Storage: ${_getStorageType()}');
      logger.i('ML: ${_getMLType()}');
    } catch (e) {
      logger.e('Failed to initialize cross-platform services: $e');
      rethrow;
    }
  }

  /// Close all services
  Future<void> close() async {
    try {
      await storage.close();
      await ml.close();
      logger.i('Cross-platform services closed successfully');
    } catch (e) {
      logger.e('Failed to close cross-platform services: $e');
    }
  }
}
