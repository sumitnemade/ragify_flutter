import 'dart:io';
import '../utils/ragify_logger.dart';

/// Dynamic Configuration Manager for RAGify Flutter
/// Provides environment-aware configuration for timeouts, memory limits, and other settings
class DynamicConfigManager {
  static RAGifyLogger _logger = const RAGifyLogger.disabled();
  static DynamicConfigManager? _instance;

  /// Environment detection
  final String _environment;
  final bool _isProduction;
  final bool _isDevelopment;
  final bool _isTesting;

  /// Device capabilities
  final int _availableMemoryMB;
  final int _cpuCores;
  final bool _isLowEndDevice;
  final bool _isHighEndDevice;

  /// Configuration cache
  final Map<String, dynamic> _configCache = {};

  /// Private constructor for singleton pattern
  DynamicConfigManager._()
    : _environment = _detectEnvironment(),
      _isProduction = _detectEnvironment() == 'production',
      _isDevelopment = _detectEnvironment() == 'development',
      _isTesting = _detectEnvironment() == 'testing',
      _availableMemoryMB = _detectAvailableMemory(),
      _cpuCores = _detectCpuCores(),
      _isLowEndDevice = _detectAvailableMemory() < 2048, // Less than 2GB
      _isHighEndDevice = _detectAvailableMemory() > 8192; // More than 8GB

  /// Get singleton instance
  static DynamicConfigManager get instance {
    _instance ??= DynamicConfigManager._();
    return _instance!;
  }

  /// Set logger for the singleton instance
  static void setLogger(RAGifyLogger logger) {
    _logger = logger;
  }

  /// Detect current environment
  static String _detectEnvironment() {
    const env = String.fromEnvironment(
      'FLUTTER_ENV',
      defaultValue: 'development',
    );
    return env;
  }

  /// Detect available memory in MB
  static int _detectAvailableMemory() {
    try {
      // This is a simplified approach - in production, use platform-specific APIs
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile devices typically have 2-16GB RAM
        return 4096; // Default to 4GB for mobile
      } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        // Desktop devices typically have 8-64GB RAM
        return 16384; // Default to 16GB for desktop
      }
    } catch (e) {
      // Fallback to default
    }
    return 4096; // Default fallback
  }

  /// Detect CPU cores
  static int _detectCpuCores() {
    try {
      return Platform.numberOfProcessors;
    } catch (e) {
      return 4; // Default fallback
    }
  }

  /// Get dynamic timeout configuration
  Map<String, Duration> getTimeoutConfig() {
    const cacheKey = 'timeout_config';

    if (_configCache.containsKey(cacheKey)) {
      return _configCache[cacheKey] as Map<String, Duration>;
    }

    final config = <String, Duration>{};

    // Base timeouts based on environment
    if (_isProduction) {
      config['base_timeout'] = const Duration(seconds: 60);
      config['max_timeout'] = const Duration(seconds: 300);
      config['min_timeout'] = const Duration(seconds: 10);
    } else if (_isDevelopment) {
      config['base_timeout'] = const Duration(seconds: 30);
      config['max_timeout'] = const Duration(seconds: 120);
      config['min_timeout'] = const Duration(seconds: 5);
    } else {
      // Testing
      config['base_timeout'] = const Duration(seconds: 10);
      config['max_timeout'] = const Duration(seconds: 60);
      config['min_timeout'] = const Duration(seconds: 2);
    }

    // Adjust based on device capabilities
    if (_isLowEndDevice) {
      config['base_timeout'] = Duration(
        seconds: (config['base_timeout']!.inSeconds * 1.5).round(),
      );
      config['max_timeout'] = Duration(
        seconds: (config['max_timeout']!.inSeconds * 1.5).round(),
      );
    } else if (_isHighEndDevice) {
      config['base_timeout'] = Duration(
        seconds: (config['base_timeout']!.inSeconds * 0.8).round(),
      );
      config['max_timeout'] = Duration(
        seconds: (config['max_timeout']!.inSeconds * 0.8).round(),
      );
    }

    // Component-specific timeouts
    config['database_query'] = Duration(
      seconds: (config['base_timeout']!.inSeconds * 1.5).round(),
    );
    config['api_request'] = config['base_timeout']!;
    config['file_operation'] = Duration(
      seconds: (config['base_timeout']!.inSeconds * 0.8).round(),
    );
    config['isolate_processing'] = Duration(
      seconds: (config['base_timeout']!.inSeconds * 2).round(),
    );
    config['connection_pool'] = Duration(
      seconds: (config['base_timeout']!.inSeconds * 0.5).round(),
    );
    config['realtime_connection'] = Duration(
      seconds: (config['base_timeout']!.inSeconds * 1.2).round(),
    );
    config['heartbeat'] = Duration(
      seconds: (config['base_timeout']!.inSeconds * 0.3).round(),
    );
    config['reconnect'] = Duration(
      seconds: (config['base_timeout']!.inSeconds * 0.2).round(),
    );

    _configCache[cacheKey] = config;
    return config;
  }

  /// Get dynamic memory configuration
  Map<String, int> getMemoryConfig() {
    const cacheKey = 'memory_config';

    if (_configCache.containsKey(cacheKey)) {
      return _configCache[cacheKey] as Map<String, int>;
    }

    final config = <String, int>{};

    // Base memory limits based on available memory
    final totalMemoryMB = _availableMemoryMB;
    final availableMemoryMB = (totalMemoryMB * 0.7)
        .round(); // Use 70% of available memory

    // Cache memory limits
    config['cache_max_memory_mb'] = (availableMemoryMB * 0.3)
        .round(); // 30% for cache
    config['cache_max_entries'] = _calculateMaxEntries(
      config['cache_max_memory_mb']!,
    );

    // Vector database memory limits
    config['vector_db_memory_mb'] = (availableMemoryMB * 0.4)
        .round(); // 40% for vectors
    config['vector_db_max_vectors'] = _calculateMaxVectors(
      config['vector_db_memory_mb']!,
    );

    // Connection pool limits
    config['connection_pool_size'] = _calculateOptimalPoolSize();
    config['connection_pool_max_wait_ms'] = _isLowEndDevice ? 5000 : 2000;

    // Isolate limits
    config['max_isolates'] = _calculateMaxIsolates();
    config['isolate_memory_mb'] = (availableMemoryMB * 0.1)
        .round(); // 10% per isolate

    // Buffer sizes
    config['file_buffer_size_kb'] = _isLowEndDevice ? 64 : 256;
    config['network_buffer_size_kb'] = _isLowEndDevice ? 32 : 128;

    _configCache[cacheKey] = config;
    return config;
  }

  /// Calculate optimal cache entries based on memory
  int _calculateMaxEntries(int memoryMB) {
    // Assume average entry size of 1KB
    return (memoryMB * 1024) ~/ 1;
  }

  /// Calculate optimal vector count based on memory
  int _calculateMaxVectors(int memoryMB) {
    // Assume average vector size of 2KB (512 dimensions * 4 bytes)
    return (memoryMB * 1024) ~/ 2;
  }

  /// Calculate optimal connection pool size
  int _calculateOptimalPoolSize() {
    if (_isLowEndDevice) {
      return 5;
    } else if (_isHighEndDevice) {
      return 20;
    } else {
      return 10;
    }
  }

  /// Calculate maximum isolates based on CPU and memory
  int _calculateMaxIsolates() {
    final cpuBased = _cpuCores - 1; // Leave one core for main thread
    final memoryBased = (_availableMemoryMB * 0.1)
        .round(); // 10% of memory per isolate

    return cpuBased.clamp(1, memoryBased.clamp(1, 8));
  }

  /// Get environment information
  Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': _environment,
      'is_production': _isProduction,
      'is_development': _isDevelopment,
      'is_testing': _isTesting,
      'available_memory_mb': _availableMemoryMB,
      'cpu_cores': _cpuCores,
      'is_low_end_device': _isLowEndDevice,
      'is_high_end_device': _isHighEndDevice,
    };
  }

  /// Get configuration summary
  Map<String, dynamic> getConfigSummary() {
    return {
      'timeouts': getTimeoutConfig().map(
        (k, v) => MapEntry(k, '${v.inSeconds}s'),
      ),
      'memory': getMemoryConfig(),
      'environment': getEnvironmentInfo(),
      'optimization_features': [
        'environment_aware_configuration',
        'device_capability_detection',
        'dynamic_timeout_adjustment',
        'adaptive_memory_management',
        'performance_optimization',
      ],
    };
  }

  /// Clear configuration cache (useful for testing)
  void clearCache() {
    _configCache.clear();
    _logger.d('Configuration cache cleared');
  }

  /// Update configuration for specific component
  void updateComponentConfig(String component, Map<String, dynamic> config) {
    _configCache[component] = config;
    _logger.i('Updated configuration for component: $component');
  }
}
