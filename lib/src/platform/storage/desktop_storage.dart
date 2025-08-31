import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'storage_interface.dart';

/// Desktop storage implementation using SQLite and file system
class DesktopStorage implements CrossPlatformStorage {
  Database? _database;
  Directory? _storageDir;
  bool _initialized = false;

  /// Logger instance
  final Logger logger = Logger();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      _storageDir = Directory('${appDir.path}/ragify_storage');

      // Create storage directory if it doesn't exist
      if (!await _storageDir!.exists()) {
        await _storageDir!.create(recursive: true);
      }

      // Initialize SQLite database
      final dbPath = '${_storageDir!.path}/storage.db';
      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE storage (
              key TEXT PRIMARY KEY,
              value TEXT,
              type TEXT,
              timestamp INTEGER
            )
          ''');
        },
      );

      _initialized = true;
    } catch (e) {
      logger.e('Failed to initialize desktop storage: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _storageDir = null;
    _initialized = false;
  }

  @override
  Future<T?> get<T>(String key) async {
    if (!_initialized) await initialize();

    try {
      final result = await _database!.query(
        'storage',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (result.isNotEmpty) {
        final value = result.first['value'] as String?;
        final type = result.first['type'] as String?;

        if (value != null && type != null) {
          return _deserializeValue<T>(value, type);
        }
      }
    } catch (e) {
      logger.e('Desktop storage get error: $e');
    }

    return null;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    if (!_initialized) await initialize();

    try {
      final serialized = _serializeValue(value);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await _database!.insert('storage', {
        'key': key,
        'value': serialized.value,
        'type': serialized.type,
        'timestamp': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      logger.e('Desktop storage set error: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    if (!_initialized) await initialize();

    try {
      await _database!.delete('storage', where: 'key = ?', whereArgs: [key]);
    } catch (e) {
      logger.e('Desktop storage remove error: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    if (!_initialized) await initialize();

    try {
      final result = await _database!.query(
        'storage',
        where: 'key = ?',
        whereArgs: [key],
      );
      return result.isNotEmpty;
    } catch (e) {
      logger.e('Desktop storage containsKey error: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getKeys() async {
    if (!_initialized) await initialize();

    try {
      final result = await _database!.query('storage', columns: ['key']);
      return result.map((row) => row['key'] as String).toList();
    } catch (e) {
      logger.e('Desktop storage getKeys error: $e');
      return [];
    }
  }

  @override
  Future<void> clear() async {
    if (!_initialized) await initialize();

    try {
      await _database!.delete('storage');
    } catch (e) {
      logger.e('Desktop storage clear error: $e');
    }
  }

  @override
  Future<StorageStats> getStats() async {
    if (!_initialized) await initialize();

    try {
      final result = await _database!.query('storage');
      final totalKeys = result.length;
      final totalSizeBytes = result.fold<int>(0, (sum, row) {
        final value = row['value'] as String? ?? '';
        return sum + value.length;
      });

      return StorageStats(
        totalKeys: totalKeys,
        totalSizeBytes: totalSizeBytes,
        lastAccess: DateTime.now(),
        platform: 'desktop',
      );
    } catch (e) {
      logger.e('Desktop storage stats error: $e');
      return StorageStats(
        totalKeys: 0,
        totalSizeBytes: 0,
        lastAccess: DateTime.now(),
        platform: 'desktop',
      );
    }
  }

  SerializedValue _serializeValue<T>(T value) {
    if (value is String) return SerializedValue(value, 'String');
    if (value is int) return SerializedValue(value.toString(), 'int');
    if (value is double) return SerializedValue(value.toString(), 'double');
    if (value is bool) return SerializedValue(value.toString(), 'bool');
    if (value is List<String>)
      return SerializedValue(value.join('|'), 'List<String>');

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
}

/// Helper class for serialized values
class SerializedValue {
  final String value;
  final String type;

  SerializedValue(this.value, this.type);
}
