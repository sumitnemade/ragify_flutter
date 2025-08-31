import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_interface.dart';

/// Mobile storage implementation using SQLite and SharedPreferences
class MobileStorage implements CrossPlatformStorage {
  Database? _database;
  SharedPreferences? _prefs;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize SQLite database
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = '${documentsDir.path}/ragify_storage.db';

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
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _prefs = null;
    _initialized = false;
  }

  @override
  Future<T?> get<T>(String key) async {
    if (!_initialized) await initialize();

    // Try SQLite first
    if (_database != null) {
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
    }

    // Fallback to SharedPreferences
    if (_prefs != null) {
      if (T == String) return _prefs!.getString(key) as T?;
      if (T == int) return _prefs!.getInt(key) as T?;
      if (T == double) return _prefs!.getDouble(key) as T?;
      if (T == bool) return _prefs!.getBool(key) as T?;
      if (T == List<String>) return _prefs!.getStringList(key) as T?;
    }

    return null;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    if (!_initialized) await initialize();

    // Store in SQLite
    if (_database != null) {
      final serialized = _serializeValue(value);
      await _database!.insert('storage', {
        'key': key,
        'value': serialized.value,
        'type': serialized.type,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Also store in SharedPreferences for quick access
    if (_prefs != null) {
      if (value is String) {
        await _prefs!.setString(key, value);
      } else if (value is int) {
        await _prefs!.setInt(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is bool) {
        await _prefs!.setBool(key, value);
      } else if (value is List<String>) {
        await _prefs!.setStringList(key, value);
      }
    }
  }

  @override
  Future<void> remove(String key) async {
    if (!_initialized) await initialize();

    // Remove from SQLite
    if (_database != null) {
      await _database!.delete('storage', where: 'key = ?', whereArgs: [key]);
    }

    // Remove from SharedPreferences
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    if (!_initialized) await initialize();

    // Check SQLite first
    if (_database != null) {
      final result = await _database!.query(
        'storage',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (result.isNotEmpty) return true;
    }

    // Check SharedPreferences
    if (_prefs != null) {
      return _prefs!.containsKey(key);
    }

    return false;
  }

  @override
  Future<List<String>> getKeys() async {
    if (!_initialized) await initialize();

    final keys = <String>{};

    // Get keys from SQLite
    if (_database != null) {
      final result = await _database!.query('storage', columns: ['key']);
      keys.addAll(result.map((row) => row['key'] as String));
    }

    // Get keys from SharedPreferences
    if (_prefs != null) {
      keys.addAll(_prefs!.getKeys());
    }

    return keys.toList();
  }

  @override
  Future<void> clear() async {
    if (!_initialized) await initialize();

    // Clear SQLite
    if (_database != null) {
      await _database!.delete('storage');
    }

    // Clear SharedPreferences
    if (_prefs != null) {
      await _prefs!.clear();
    }
  }

  @override
  Future<StorageStats> getStats() async {
    if (!_initialized) await initialize();

    int totalKeys = 0;
    int totalSizeBytes = 0;

    if (_database != null) {
      final result = await _database!.query('storage');
      totalKeys = result.length;
      totalSizeBytes = result.fold(0, (sum, row) {
        final value = row['value'] as String? ?? '';
        return sum + value.length;
      });
    }

    return StorageStats(
      totalKeys: totalKeys,
      totalSizeBytes: totalSizeBytes,
      lastAccess: DateTime.now(),
      platform: 'mobile',
    );
  }

  SerializedValue _serializeValue<T>(T value) {
    if (value is String) return SerializedValue(value, 'String');
    if (value is int) return SerializedValue(value.toString(), 'int');
    if (value is double) return SerializedValue(value.toString(), 'double');
    if (value is bool) return SerializedValue(value.toString(), 'bool');
    if (value is List<String>)
      return SerializedValue(value.join('|'), 'List<String>');

    // For complex objects, use JSON
    return SerializedValue(value.toString(), 'Object');
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
