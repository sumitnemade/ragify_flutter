import 'storage_interface.dart';
import 'unified_storage.dart';
import '../../utils/ragify_logger.dart';

/// Factory class for creating unified storage implementation
/// Since Hive works on all platforms, we use a single UnifiedStorage class
class StorageFactory {
  static CrossPlatformStorage? _instance;
  static RAGifyLogger? _logger;

  /// Get the unified storage implementation for all platforms
  static CrossPlatformStorage get storage {
    _instance ??= _createStorage();
    return _instance!;
  }

  /// Set logger for the factory
  static void setLogger(RAGifyLogger logger) {
    _logger = logger;
  }

  /// Create a new unified storage instance
  static CrossPlatformStorage _createStorage() {
    // Hive works on all platforms, so we use UnifiedStorage everywhere
    return UnifiedStorage(logger: _logger);
  }

  /// Create a specific storage implementation
  static CrossPlatformStorage createStorage(StorageType type) {
    // All storage types now use the same unified implementation
    return UnifiedStorage();
  }

  /// Reset the singleton instance (useful for testing)
  static void reset() {
    _instance = null;
  }
}

/// Available storage types (all now use UnifiedStorage)
enum StorageType { mobile, web, desktop, auto }
