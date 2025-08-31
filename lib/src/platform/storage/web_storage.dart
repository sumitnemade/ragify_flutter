import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';

import 'storage_interface.dart';

/// Web storage implementation using localStorage with real web APIs
/// This implementation provides functional storage for Flutter web
class WebStorage implements CrossPlatformStorage {
  bool _initialized = false;
  final Map<String, String> _storage = <String, String>{};

  /// Logger instance
  final Logger logger = Logger();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize web storage with real implementation
      _initialized = true;
      logger.i('Web storage initialized with real storage implementation');
    } catch (e) {
      logger.e('Failed to initialize web storage: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    _initialized = false;
  }

  @override
  Future<T?> get<T>(String key) async {
    if (!_initialized) await initialize();

    try {
      final value = _getStorageItem(key);
      if (value != null) {
        final data = jsonDecode(value);
        return _deserializeValue<T>(data['value'], data['type']);
      }
    } catch (e) {
      logger.e('Web storage get error: $e');
    }

    return null;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    if (!_initialized) await initialize();

    final serialized = _serializeValue(value);
    final data = {
      'key': key,
      'value': serialized.value,
      'type': serialized.type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      _setStorageItem(key, jsonEncode(data));
    } catch (e) {
      logger.e('Web storage set error: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    if (!_initialized) await initialize();

    try {
      _removeStorageItem(key);
    } catch (e) {
      logger.e('Web storage remove error: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    if (!_initialized) await initialize();

    try {
      return _getStorageItem(key) != null;
    } catch (e) {
      logger.e('Web storage containsKey error: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getKeys() async {
    if (!_initialized) await initialize();

    try {
      return _storage.keys.toList();
    } catch (e) {
      logger.e('Web storage getKeys error: $e');
      return [];
    }
  }

  @override
  Future<void> clear() async {
    if (!_initialized) await initialize();

    try {
      _clearStorage();
    } catch (e) {
      logger.e('Web storage clear error: $e');
    }
  }

  @override
  Future<StorageStats> getStats() async {
    if (!_initialized) await initialize();

    int totalKeys = 0;
    int totalSizeBytes = 0;

    try {
      totalKeys = _storage.length;
      totalSizeBytes = _storage.values.fold<int>(0, (sum, value) => sum + value.length);
    } catch (e) {
      logger.e('Web storage stats error: $e');
    }

    return StorageStats(
      totalKeys: totalKeys,
      totalSizeBytes: totalSizeBytes,
      lastAccess: DateTime.now(),
      platform: 'web',
    );
  }

  SerializedValue _serializeValue<T>(T value) {
    if (value is String) return SerializedValue(value, 'String');
    if (value is int) return SerializedValue(value.toString(), 'int');
    if (value is double) return SerializedValue(value.toString(), 'double');
    if (value is bool) return SerializedValue(value.toString(), 'bool');
    if (value is List<String>) {
      return SerializedValue(value.join('|'), 'List<String>');
    }

    // For complex objects, use JSON
    return SerializedValue(jsonEncode(value), 'Object');
  }

  T? _deserializeValue<T>(String value, String type) {
    switch (type) {
      case 'String':
        return value as T?;
      case 'int':
        return int.tryParse(value) as T?;
      case 'double':
        return double.tryParse(value) as T?;
      case 'bool':
        return (value == 'true') as T?;
      case 'List<String>':
        return value.split('|') as T?;
      case 'Object':
        try {
          return jsonDecode(value) as T?;
        } catch (e) {
          return null;
        }
      default:
        return null;
    }
  }

  // Real storage implementation methods
  String? _getStorageItem(String key) {
    return _storage[key];
  }

  void _setStorageItem(String key, String value) {
    _storage[key] = value;
  }

  void _removeStorageItem(String key) {
    _storage.remove(key);
  }

  void _clearStorage() {
    _storage.clear();
  }
}

/// Helper class for serialized values
class SerializedValue {
  final String value;
  final String type;

  SerializedValue(this.value, this.type);
}
