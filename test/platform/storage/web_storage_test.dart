import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/platform/storage/web_storage.dart';

void main() {
  group('WebStorage Tests', () {
    late WebStorage storage;

    setUp(() {
      storage = WebStorage();
    });

    tearDown(() async {
      await storage.close();
    });

    test('should initialize successfully', () async {
      await storage.initialize();
      expect(storage, isNotNull);
    });

    test('should close successfully', () async {
      await storage.initialize();
      await storage.close();
      // Should not throw any errors
    });

    test('should handle basic storage operations', () async {
      await storage.initialize();

      // Test set and get
      await storage.set('test_key', 'test_value');
      final retrieved = await storage.get<String>('test_key');
      expect(retrieved, equals('test_value'));

      // Test containsKey
      final contains = await storage.containsKey('test_key');
      expect(contains, isTrue);

      // Test remove
      await storage.remove('test_key');
      final afterRemove = await storage.get<String>('test_key');
      expect(afterRemove, isNull);

      // Test clear
      await storage.set('key1', 'value1');
      await storage.set('key2', 'value2');
      await storage.clear();
      
      final keys = await storage.getKeys();
      expect(keys, isEmpty);
    });

    test('should handle different data types', () async {
      await storage.initialize();

      // Test String
      await storage.set('string_key', 'hello');
      expect(await storage.get<String>('string_key'), equals('hello'));

      // Test int
      await storage.set('int_key', 42);
      expect(await storage.get<int>('int_key'), equals(42));

      // Test double
      await storage.set('double_key', 3.14);
      expect(await storage.get<double>('double_key'), equals(3.14));

      // Test bool
      await storage.set('bool_key', true);
      expect(await storage.get<bool>('bool_key'), equals(true));

      // Test List<String>
      await storage.set('list_key', ['a', 'b', 'c']);
      expect(await storage.get<List<String>>('list_key'), equals(['a', 'b', 'c']));
    });

    test('should handle complex objects', () async {
      await storage.initialize();

      final complexObject = {
        'name': 'test',
        'values': [1, 2, 3],
        'nested': {'key': 'value'}
      };

      await storage.set('complex_key', complexObject);
      final retrieved = await storage.get<Map<String, dynamic>>('complex_key');
      
      expect(retrieved, isNotNull);
      expect(retrieved!['name'], equals('test'));
      expect(retrieved['values'], equals([1, 2, 3]));
      expect(retrieved['nested']['key'], equals('value'));
    });

    test('should get storage statistics', () async {
      await storage.initialize();

      await storage.set('key1', 'value1');
      await storage.set('key2', 'value2');

      final stats = await storage.getStats();
      expect(stats.totalKeys, equals(2));
      expect(stats.platform, equals('web'));
      expect(stats.totalSizeBytes, greaterThan(0));
    });

    test('should handle errors gracefully', () async {
      await storage.initialize();

      // Test with invalid key
      final result = await storage.get<String>('');
      expect(result, isNull);

      // Test with non-existent key
      final nonExistent = await storage.get<String>('non_existent');
      expect(nonExistent, isNull);
    });
  });
}
