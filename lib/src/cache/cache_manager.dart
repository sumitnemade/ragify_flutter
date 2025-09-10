import 'dart:async';
import 'dart:collection';
import '../config/dynamic_config_manager.dart';
import '../utils/ragify_logger.dart';

/// Cache entry with metadata
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String key;
  final Map<String, dynamic> metadata;
  final int accessCount;
  final DateTime lastAccessed;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.key,
    this.metadata = const {},
    this.accessCount = 0,
    required this.lastAccessed,
  });

  /// Check if entry is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get time until expiration
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  /// Create a copy with updated access info
  CacheEntry<T> withAccess() {
    return CacheEntry<T>(
      data: data,
      createdAt: createdAt,
      expiresAt: expiresAt,
      key: key,
      metadata: metadata,
      accessCount: accessCount + 1,
      lastAccessed: DateTime.now(),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'key': key,
      'metadata': metadata,
      'access_count': accessCount,
      'last_accessed': lastAccessed.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CacheEntry.fromJson(Map<String, dynamic> json, T data) {
    return CacheEntry<T>(
      data: data,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      key: json['key'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      accessCount: json['access_count'] ?? 0,
      lastAccessed: DateTime.parse(json['last_accessed']),
    );
  }
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int activeEntries;
  final int totalHits;
  final int totalMisses;
  final double hitRate;
  final int memoryUsageBytes;
  final DateTime lastCleanup;
  final Duration averageAccessTime;

  CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.activeEntries,
    required this.totalHits,
    required this.totalMisses,
    required this.hitRate,
    required this.memoryUsageBytes,
    required this.lastCleanup,
    required this.averageAccessTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_entries': totalEntries,
      'expired_entries': expiredEntries,
      'active_entries': activeEntries,
      'total_hits': totalHits,
      'total_misses': totalMisses,
      'hit_rate': hitRate,
      'memory_usage_bytes': memoryUsageBytes,
      'last_cleanup': lastCleanup.toIso8601String(),
      'average_access_time_ms': averageAccessTime.inMilliseconds,
    };
  }
}

/// Optimized LRU Cache Manager for RAGify Flutter
/// Implements O(1) operations with efficient memory management
class CacheManager {
  final RAGifyLogger _logger;

  /// LRU cache implementation using LinkedHashMap for O(1) operations
  final LinkedHashMap<String, CacheEntry> _lruCache = LinkedHashMap();

  /// Expiration tracking for efficient cleanup
  final SplayTreeMap<DateTime, List<String>> _expirationIndex = SplayTreeMap();

  /// Cache configuration
  final Map<String, dynamic> _config;

  /// Cache statistics
  int _totalHits = 0;
  int _totalMisses = 0;
  DateTime _lastCleanup = DateTime.now();
  final List<DateTime> _accessTimes = [];

  /// Timer for periodic cleanup
  Timer? _cleanupTimer;

  /// Performance monitoring
  final Map<String, dynamic> _performanceMetrics = {
    'cleanup_operations': 0,
    'cleanup_duration_ms': 0.0,
    'memory_enforcement_operations': 0,
    'lru_evictions': 0,
    'expiration_evictions': 0,
  };

  /// Redis connection (placeholder for future implementation)
  // Redis? _redis;

  /// Memcached connection (placeholder for future implementation)
  // Memcached? _memcached;

  /// Cache Manager constructor
  CacheManager({Map<String, dynamic>? config, RAGifyLogger? logger})
    : _config = _mergeConfig(config ?? {}, _defaultConfig()),
      _logger = logger ?? const RAGifyLogger.disabled() {
    _initializeCache();
  }

  /// Default cache configuration with dynamic values
  static Map<String, dynamic> _defaultConfig() {
    final dynamicConfig = DynamicConfigManager.instance;
    final memoryConfig = dynamicConfig.getMemoryConfig();

    return {
      'max_memory_mb': memoryConfig['cache_max_memory_mb'] ?? 100,
      'default_ttl_seconds': 3600,
      'cleanup_interval_seconds': 300,
      'max_entries': memoryConfig['cache_max_entries'] ?? 10000,
      'enable_redis': false,
      'enable_memcached': false,
      'redis_url': 'redis://localhost:6379',
      'memcached_url': 'localhost:11211',
      'connection_pool_size': memoryConfig['connection_pool_size'] ?? 10,
      'cache_warming_enabled': false,
      'distributed_cache_enabled': false,
      'lru_enabled': true,
      'expiration_cleanup_enabled': true,
    };
  }

  /// Merge custom config with default config, ensuring all required values are present
  static Map<String, dynamic> _mergeConfig(
    Map<String, dynamic> custom,
    Map<String, dynamic> defaults,
  ) {
    final merged = Map<String, dynamic>.from(defaults);

    // Only merge non-null values from custom config
    for (final entry in custom.entries) {
      if (entry.value != null) {
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }

  /// Initialize cache system
  void _initializeCache() {
    _logger.d('Initializing Optimized Cache Manager with LRU support');

    // Start periodic cleanup
    _startCleanupTimer();

    // Initialize Redis if enabled
    if (_config['enable_redis'] == true) {
      _initializeRedis();
    }

    // Initialize Memcached if enabled
    if (_config['enable_memcached'] == true) {
      _initializeMemcached();
    }

    _logger.d('Optimized Cache Manager initialized successfully');
  }

  /// Initialize Redis connection (placeholder)
  Future<void> _initializeRedis() async {
    _logger.d('Redis integration not yet implemented');
    // TODO: Implement Redis integration
    // _redis = Redis();
    // await _redis!.connect(_config['redis_url']);
  }

  /// Initialize Memcached connection (placeholder)
  Future<void> _initializeMemcached() async {
    _logger.d('Memcached integration not yet implemented');
    // TODO: Implement Memcached integration
    // _memcached = Memcached();
    // await _memcached!.connect(_config['memcached_url']);
  }

  /// Start periodic cleanup timer
  void _startCleanupTimer() {
    final interval = Duration(seconds: _config['cleanup_interval_seconds']);
    _cleanupTimer = Timer.periodic(interval, (_) => _performOptimizedCleanup());
    _logger.d('Started cleanup timer with ${interval.inSeconds}s interval');
  }

  /// Get value from cache - O(1) optimized
  T? get<T>(String key) {
    try {
      final entry = _lruCache[key];

      if (entry == null) {
        _totalMisses++;
        return null;
      }

      // Check if expired
      if (entry.isExpired) {
        _removeExpiredEntry(key, entry);
        _totalMisses++;
        return null;
      }

      // Update access count and move to end (LRU)
      if (_config['lru_enabled'] == true) {
        _lruCache.remove(key);
        _lruCache[key] = entry.withAccess();
      }

      // Track access time for performance metrics
      _trackAccessTime();

      _totalHits++;
      return entry.data as T;
    } catch (e) {
      _logger.e('Error getting cache entry for key $key: $e');
      _totalMisses++;
      return null;
    }
  }

  /// Set value in cache - O(1) optimized
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      final ttlDuration =
          ttl ?? Duration(seconds: _config['default_ttl_seconds']);
      final expiresAt = now.add(ttlDuration);

      // Create cache entry
      final entry = CacheEntry<T>(
        data: data,
        createdAt: now,
        expiresAt: expiresAt,
        key: key,
        metadata: metadata ?? {},
        lastAccessed: now,
      );

      // Remove existing entry if present
      if (_lruCache.containsKey(key)) {
        _removeEntryFromExpirationIndex(key, _lruCache[key]!);
      }

      // Add to LRU cache
      _lruCache[key] = entry;

      // Add to expiration index for efficient cleanup
      if (_config['expiration_cleanup_enabled'] == true) {
        _addToExpirationIndex(expiresAt, key);
      }

      // Enforce memory limits if needed
      _enforceOptimizedMemoryLimits();
    } catch (e) {
      _logger.e('Error setting cache entry for key $key: $e');
    }
  }

  /// Remove value from cache - O(1) optimized
  void remove(String key) {
    try {
      final entry = _lruCache[key];
      if (entry != null) {
        _removeEntryFromExpirationIndex(key, entry);
        _lruCache.remove(key);
        _logger.d('Removed cache entry for key: $key');
      }
    } catch (e) {
      _logger.e('Error removing cache entry for key $key: $e');
    }
  }

  /// Check if key exists in cache - O(1) optimized
  bool contains(String key) {
    final entry = _lruCache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _removeExpiredEntry(key, entry);
      return false;
    }

    return true;
  }

  /// Clear all cache entries - O(1) optimized
  void clear() {
    try {
      _lruCache.clear();
      _expirationIndex.clear();
      _logger.d('Cache cleared successfully');
    } catch (e) {
      _logger.e('Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    final expiredEntries = _lruCache.values.where((e) => e.isExpired).length;
    final activeEntries = _lruCache.length - expiredEntries;

    return CacheStats(
      totalEntries: _lruCache.length,
      expiredEntries: expiredEntries,
      activeEntries: activeEntries,
      totalHits: _totalHits,
      totalMisses: _totalMisses,
      hitRate: _totalHits + _totalMisses > 0
          ? _totalHits / (_totalHits + _totalMisses)
          : 0.0,
      memoryUsageBytes: _estimateOptimizedMemoryUsage(),
      lastCleanup: _lastCleanup,
      averageAccessTime: _calculateAverageAccessTime(),
    );
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      ..._performanceMetrics,
      'cache_size': _lruCache.length,
      'expiration_index_size': _expirationIndex.length,
      'lru_enabled': _config['lru_enabled'],
      'expiration_cleanup_enabled': _config['expiration_cleanup_enabled'],
    };
  }

  /// Get cache keys
  List<String> getKeys() {
    return _lruCache.keys.toList();
  }

  /// Update cache entry metadata
  void updateMetadata(String key, Map<String, dynamic> metadata) {
    try {
      final entry = _lruCache[key];
      if (entry != null) {
        final updatedEntry = CacheEntry(
          data: entry.data,
          createdAt: entry.createdAt,
          expiresAt: entry.expiresAt,
          key: entry.key,
          metadata: metadata,
          accessCount: entry.accessCount,
          lastAccessed: entry.lastAccessed,
        );

        _lruCache[key] = updatedEntry;
        _logger.d('Updated metadata for key: $key');
      }
    } catch (e) {
      _logger.e('Error updating metadata for key $key: $e');
    }
  }

  /// Extend TTL for cache entry
  void extendTTL(String key, Duration additionalTTL) {
    try {
      final entry = _lruCache[key];
      if (entry != null) {
        final newExpiresAt = entry.expiresAt.add(additionalTTL);
        final updatedEntry = CacheEntry(
          data: entry.data,
          createdAt: entry.createdAt,
          expiresAt: newExpiresAt,
          key: entry.key,
          metadata: entry.metadata,
          accessCount: entry.accessCount,
          lastAccessed: entry.lastAccessed,
        );

        // Update expiration index
        _removeEntryFromExpirationIndex(key, entry);
        _addToExpirationIndex(newExpiresAt, key);

        _lruCache[key] = updatedEntry;
        _logger.d('Extended TTL for key: $key');
      }
    } catch (e) {
      _logger.e('Error extending TTL for key $key: $e');
    }
  }

  /// Dispose cache manager
  void dispose() {
    try {
      _cleanupTimer?.cancel();
      _lruCache.clear();
      _expirationIndex.clear();
      _logger.d('Cache Manager disposed');
    } catch (e) {
      _logger.e('Error disposing Cache Manager: $e');
    }
  }

  // ============================================================================
  // PRIVATE OPTIMIZED METHODS
  // ============================================================================

  /// Perform optimized cleanup - O(log n) instead of O(n)
  void _performOptimizedCleanup() {
    final stopwatch = Stopwatch()..start();

    try {
      int removedCount = 0;
      final now = DateTime.now();

      // Remove expired entries using expiration index - O(log n)
      if (_config['expiration_cleanup_enabled'] == true) {
        final expiredKeys = <String>[];

        // Get all expired entries efficiently
        final expiredEntries = _expirationIndex.entries.takeWhile(
          (entry) => entry.key.isBefore(now),
        );

        for (final entry in expiredEntries) {
          expiredKeys.addAll(entry.value);
          _expirationIndex.remove(entry.key);
        }

        // Remove expired entries from LRU cache
        for (final key in expiredKeys) {
          if (_lruCache.remove(key) != null) {
            removedCount++;
          }
        }

        _performanceMetrics['expiration_evictions'] =
            (_performanceMetrics['expiration_evictions'] as int) + removedCount;
      }

      _lastCleanup = now;
      _performanceMetrics['cleanup_operations'] =
          (_performanceMetrics['cleanup_operations'] as int) + 1;

      final cleanupTime = stopwatch.elapsedMicroseconds / 1000.0;
      _performanceMetrics['cleanup_duration_ms'] = cleanupTime;

      if (removedCount > 0) {
        _logger.d(
          'Optimized cleanup removed $removedCount expired entries in ${cleanupTime.toStringAsFixed(2)}ms',
        );
      }
    } catch (e) {
      _logger.e('Failed to perform optimized cleanup: $e');
    }
  }

  /// Enforce memory limits with O(1) operations
  void _enforceOptimizedMemoryLimits() {
    final maxEntries = _config['max_entries'];
    final maxMemoryMB = _config['max_memory_mb'];

    // Check entry count limit - O(1) with LRU
    if (_lruCache.length > maxEntries) {
      final entriesToRemove = _lruCache.length - maxEntries;

      // Remove oldest entries (LRU) - O(1) per removal
      for (int i = 0; i < entriesToRemove; i++) {
        final oldestKey = _lruCache.keys.first;
        final oldestEntry = _lruCache[oldestKey]!;

        _removeEntryFromExpirationIndex(oldestKey, oldestEntry);
        _lruCache.remove(oldestKey);
      }

      _performanceMetrics['lru_evictions'] =
          (_performanceMetrics['lru_evictions'] as int) + entriesToRemove;

      _logger.d(
        'LRU eviction removed $entriesToRemove entries due to entry count limit',
      );
    }

    // Check memory limit - O(1) estimation
    final currentMemoryMB = _estimateOptimizedMemoryUsage() / (1024 * 1024);
    if (currentMemoryMB > maxMemoryMB) {
      final targetMemoryMB = (maxMemoryMB as num) * 0.7; // Target 70% of limit
      final currentBytes = _estimateOptimizedMemoryUsage();
      final targetBytes = (targetMemoryMB * 1024 * 1024).round();
      final bytesToRemove = currentBytes - targetBytes;

      int removedBytes = 0;
      int removedCount = 0;

      // Remove oldest entries until memory target is reached
      while (removedBytes < bytesToRemove && _lruCache.isNotEmpty) {
        final oldestKey = _lruCache.keys.first;
        final oldestEntry = _lruCache[oldestKey]!;
        final entryBytes = _estimateOptimizedEntryMemory(oldestEntry);

        _removeEntryFromExpirationIndex(oldestKey, oldestEntry);
        _lruCache.remove(oldestKey);

        removedBytes += entryBytes;
        removedCount++;
      }

      _performanceMetrics['memory_enforcement_operations'] =
          (_performanceMetrics['memory_enforcement_operations'] as int) + 1;
      _performanceMetrics['lru_evictions'] =
          (_performanceMetrics['lru_evictions'] as int) + removedCount;

      _logger.d(
        'Memory limit enforcement removed $removedCount entries, freed ${(removedBytes / (1024 * 1024)).toStringAsFixed(2)}MB',
      );
    }
  }

  /// Add entry to expiration index for efficient cleanup
  void _addToExpirationIndex(DateTime expiresAt, String key) {
    _expirationIndex.putIfAbsent(expiresAt, () => <String>[]).add(key);
  }

  /// Remove entry from expiration index
  void _removeEntryFromExpirationIndex(String key, CacheEntry entry) {
    final expirationList = _expirationIndex[entry.expiresAt];
    if (expirationList != null) {
      expirationList.remove(key);
      if (expirationList.isEmpty) {
        _expirationIndex.remove(entry.expiresAt);
      }
    }
  }

  /// Remove expired entry efficiently
  void _removeExpiredEntry(String key, CacheEntry entry) {
    _removeEntryFromExpirationIndex(key, entry);
    _lruCache.remove(key);
  }

  /// Estimate memory usage for a single entry with precise tracking
  int _estimateOptimizedEntryMemory(CacheEntry entry) {
    int totalBytes = 0;

    // Key size - Dart strings are UTF-16 internally
    totalBytes += entry.key.length * 2;

    // Data size estimation with precise type handling
    if (entry.data is String) {
      totalBytes += (entry.data as String).length * 2; // UTF-16
    } else if (entry.data is List) {
      final list = entry.data as List;
      totalBytes +=
          list.length * 8; // Assume 8 bytes per element (64-bit pointers)
      // Add actual data size for primitive types
      for (final item in list) {
        if (item is String) {
          totalBytes += item.length * 2;
        } else if (item is num) {
          totalBytes += 8; // 64-bit number
        } else if (item is bool) {
          totalBytes += 1; // 1 byte boolean
        } else if (item is Map) {
          totalBytes += item.length * 16; // Rough estimate for map entries
        }
      }
    } else if (entry.data is Map) {
      final map = entry.data as Map;
      totalBytes += map.length * 24; // Key-value pair overhead
      for (final mapEntry in map.entries) {
        totalBytes += mapEntry.key.toString().length * 2;
        if (mapEntry.value is String) {
          totalBytes += (mapEntry.value as String).length * 2;
        } else if (mapEntry.value is num) {
          totalBytes += 8;
        }
      }
    } else if (entry.data is num) {
      totalBytes += 8; // 64-bit number
    } else if (entry.data is bool) {
      totalBytes += 1; // 1 byte boolean
    } else {
      // For other types, use more accurate estimation
      totalBytes += entry.data.toString().length * 2;
    }

    // Metadata size with precise calculation
    totalBytes += entry.metadata.toString().length * 2;

    // Precise overhead calculation
    totalBytes += 64; // DateTime objects (8 bytes each for 2 timestamps)
    totalBytes += 32; // Object header and references
    totalBytes += 16; // Map and List internal structures

    return totalBytes;
  }

  /// Estimate total memory usage - O(1) optimized
  int _estimateOptimizedMemoryUsage() {
    int totalBytes = 0;

    // Use cached estimation for better performance
    for (final entry in _lruCache.values) {
      totalBytes += _estimateOptimizedEntryMemory(entry);
    }

    return totalBytes;
  }

  /// Track access time for performance metrics
  void _trackAccessTime() {
    final now = DateTime.now();
    if (_accessTimes.isNotEmpty) {
      _accessTimes.add(now);

      // Keep only last 100 access times to prevent memory growth
      if (_accessTimes.length > 100) {
        _accessTimes.removeAt(0);
      }
    } else {
      _accessTimes.add(now);
    }
  }

  /// Calculate average access time
  Duration _calculateAverageAccessTime() {
    if (_accessTimes.length < 2) return Duration.zero;

    int totalMicroseconds = 0;
    for (int i = 1; i < _accessTimes.length; i++) {
      totalMicroseconds += _accessTimes[i]
          .difference(_accessTimes[i - 1])
          .inMicroseconds;
    }

    return Duration(
      microseconds: totalMicroseconds ~/ (_accessTimes.length - 1),
    );
  }

  /// Get detailed memory statistics with precise tracking
  Map<String, dynamic> getDetailedMemoryStats() {
    final estimatedBytes = _estimateOptimizedMemoryUsage();
    final estimatedMB = estimatedBytes / (1024 * 1024);
    final memoryLimitMB =
        (_config['max_memory_mb'] as int) * (1024 * 1024) / (1024 * 1024);
    final utilizationPercent =
        (estimatedBytes / ((_config['max_memory_mb'] as int) * 1024 * 1024)) *
        100;

    // Analyze entry types for better memory understanding
    final entryTypeStats = <String, int>{};
    final entrySizeStats = <String, double>{};

    for (final entry in _lruCache.values) {
      final type = entry.data.runtimeType.toString();
      final size = _estimateOptimizedEntryMemory(entry);

      entryTypeStats[type] = (entryTypeStats[type] ?? 0) + 1;
      entrySizeStats[type] = (entrySizeStats[type] ?? 0) + size;
    }

    // Get dynamic configuration information
    final dynamicConfig = DynamicConfigManager.instance;
    final environmentInfo = dynamicConfig.getEnvironmentInfo();
    final memoryConfig = dynamicConfig.getMemoryConfig();

    return {
      'estimated_memory_bytes': estimatedBytes,
      'estimated_memory_mb': estimatedMB.toStringAsFixed(2),
      'memory_limit_bytes': (_config['max_memory_mb'] as int) * 1024 * 1024,
      'memory_limit_mb': memoryLimitMB.toStringAsFixed(2),
      'memory_utilization_percent': utilizationPercent.toStringAsFixed(1),
      'entry_count': _lruCache.length,
      'entry_type_distribution': entryTypeStats,
      'entry_size_by_type': entrySizeStats.map(
        (k, v) => MapEntry(k, '${(v / 1024).toStringAsFixed(2)} KB'),
      ),
      'average_entry_size_bytes': _lruCache.isNotEmpty
          ? (estimatedBytes / _lruCache.length).toStringAsFixed(0)
          : '0',
      'memory_efficiency':
          '${((_lruCache.length / (_config['max_entries'] as int)) * 100).toStringAsFixed(1)}%',
      'lru_evictions': _performanceMetrics['lru_evictions'] ?? 0,
      'memory_enforcement_operations':
          _performanceMetrics['memory_enforcement_operations'] ?? 0,
      'dynamic_configuration': {
        'environment': environmentInfo['environment'],
        'device_capabilities': {
          'available_memory_mb': environmentInfo['available_memory_mb'],
          'cpu_cores': environmentInfo['cpu_cores'],
          'is_low_end_device': environmentInfo['is_low_end_device'],
          'is_high_end_device': environmentInfo['is_high_end_device'],
        },
        'adaptive_limits': {
          'cache_max_memory_mb': memoryConfig['cache_max_memory_mb'],
          'cache_max_entries': memoryConfig['cache_max_entries'],
          'connection_pool_size': memoryConfig['connection_pool_size'],
        },
      },
    };
  }
}
