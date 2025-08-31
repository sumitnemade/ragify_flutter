/// Cross-platform storage interface
abstract class CrossPlatformStorage {
  /// Initialize the storage system
  Future<void> initialize();

  /// Close the storage system
  Future<void> close();

  /// Get a value from storage
  Future<T?> get<T>(String key);

  /// Set a value in storage
  Future<void> set<T>(String key, T value);

  /// Remove a value from storage
  Future<void> remove(String key);

  /// Check if a key exists
  Future<bool> containsKey(String key);

  /// Get all keys
  Future<List<String>> getKeys();

  /// Clear all data
  Future<void> clear();

  /// Get storage statistics
  Future<StorageStats> getStats();
}

/// Storage statistics
class StorageStats {
  final int totalKeys;
  final int totalSizeBytes;
  final DateTime lastAccess;
  final String platform;

  StorageStats({
    required this.totalKeys,
    required this.totalSizeBytes,
    required this.lastAccess,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
    'totalKeys': totalKeys,
    'totalSizeBytes': totalSizeBytes,
    'lastAccess': lastAccess.toIso8601String(),
    'platform': platform,
  };
}
