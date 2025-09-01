import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/platform/storage/unified_storage.dart';
import 'package:ragify_flutter/src/platform/storage/storage_interface.dart';

void main() {
  group('UnifiedStorage Tests', () {
    late UnifiedStorage storage;

    setUp(() {
      storage = UnifiedStorage();
    });

    tearDown(() async {
      await storage.close();
    });

    test('should initialize successfully', () async {
      await storage.initialize();
      expect(storage, isA<CrossPlatformStorage>());
      // In test environment, it should fall back to in-memory storage
      expect(storage.isUsingHive, isFalse);
    });

    test('should close successfully', () async {
      await storage.initialize();
      await storage.close();
      // Should be able to close without errors
    });

    test('should handle basic storage operations', () async {
      await storage.initialize();

      // Store a value
      await storage.set('test_key', 'test_value');

      // Retrieve the value
      final value = await storage.get<String>('test_key');
      expect(value, equals('test_value'));

      // Remove the value
      await storage.remove('test_key');

      // Verify it's removed
      final removedValue = await storage.get<String>('test_key');
      expect(removedValue, isNull);
    });

    test('should handle different data types', () async {
      await storage.initialize();

      // Test different data types
      await storage.set('string_key', 'hello');
      await storage.set('int_key', 42);
      await storage.set('double_key', 3.14);
      await storage.set('bool_key', true);
      await storage.set('list_key', ['a', 'b', 'c']);

      expect(await storage.get<String>('string_key'), equals('hello'));
      expect(await storage.get<int>('int_key'), equals(42));
      expect(await storage.get<double>('double_key'), equals(3.14));
      expect(await storage.get<bool>('bool_key'), equals(true));
      expect(
        await storage.get<List<String>>('list_key'),
        equals(['a', 'b', 'c']),
      );
    });

    test('should handle complex objects', () async {
      await storage.initialize();

      final complexObject = {
        'name': 'test',
        'value': 123,
        'nested': {'key': 'value'},
      };

      await storage.set('complex_key', complexObject);

      final retrieved = await storage.get<Map<String, dynamic>>('complex_key');
      expect(retrieved, isNotNull);
      if (retrieved != null) {
        expect(retrieved['name'], equals('test'));
        expect(retrieved['value'], equals(123));
        expect(retrieved['nested']['key'], equals('value'));
      }
    });

    test('should get storage statistics', () async {
      await storage.initialize();

      await storage.set('key1', 'value1');
      await storage.set('key2', 'value2');

      final stats = await storage.getStats();
      expect(stats.totalKeys, greaterThanOrEqualTo(2));
      expect(stats.totalSizeBytes, greaterThan(0));
      // In test environment, platform should be 'unified_fallback'
      expect(stats.platform, equals('unified_fallback'));
    });

    test('should handle errors gracefully', () async {
      await storage.initialize();

      // Try to remove a non-existent key (should not throw)
      await storage.remove('non_existent_key');

      // Try to get a non-existent key (should return null)
      final value = await storage.get<String>('non_existent_key');
      expect(value, isNull);
    });

    test('should clear all data', () async {
      await storage.initialize();

      await storage.set('key1', 'value1');
      await storage.set('key2', 'value2');

      await storage.clear();

      final stats = await storage.getStats();
      expect(stats.totalKeys, equals(0));
    });

    test('should get all keys', () async {
      await storage.initialize();

      await storage.set('key1', 'value1');
      await storage.set('key2', 'value2');
      await storage.set('key3', 'value3');

      final keys = await storage.getKeys();
      expect(keys, containsAll(['key1', 'key2', 'key3']));
    });

    test('should handle containsKey operations', () async {
      await storage.initialize();

      await storage.set('existing_key', 'value');

      expect(await storage.containsKey('existing_key'), isTrue);
      expect(await storage.containsKey('non_existing_key'), isFalse);
    });

    test('should handle fallback storage when Hive is unavailable', () async {
      await storage.initialize();

      // Verify we're using fallback storage in test environment
      expect(storage.isUsingHive, isFalse);

      // Test that fallback storage works correctly
      await storage.set('fallback_key', 'fallback_value');
      final value = await storage.get<String>('fallback_key');
      expect(value, equals('fallback_value'));

      // Test that we can access the debug fallback storage
      final debugStorage = storage.debugFallbackStorage;
      expect(debugStorage['fallback_key'], equals('fallback_value'));
    });
  });
}
