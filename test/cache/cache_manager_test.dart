import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';
import '../test_helper.dart';

void main() {
  setupTestMocks();

  group('CacheManager Tests', () {
    late CacheManager cacheManager;

    setUp(() {
      cacheManager = CacheManager();
    });

    tearDown(() {
      cacheManager.dispose();
    });

    group('Basic Operations', () {
      test('should set and get cache entry', () async {
        const key = 'test_key';
        const data = 'test_data';

        await cacheManager.set(key, data);
        final result = cacheManager.get(key);

        expect(result, equals(data));
      });

      test('should check if key exists', () async {
        const key = 'test_key';
        const data = 'test_data';

        expect(cacheManager.contains(key), isFalse);

        await cacheManager.set(key, data);
        expect(cacheManager.contains(key), isTrue);
      });

      test('should remove cache entry', () async {
        const key = 'test_key';
        const data = 'test_data';

        await cacheManager.set(key, data);
        expect(cacheManager.contains(key), isTrue);

        cacheManager.remove(key);
        expect(cacheManager.contains(key), isFalse);
      });

      test('should clear all entries', () async {
        await cacheManager.set('key1', 'data1');
        await cacheManager.set('key2', 'data2');

        expect(cacheManager.contains('key1'), isTrue);
        expect(cacheManager.contains('key2'), isTrue);

        cacheManager.clear();

        expect(cacheManager.contains('key1'), isFalse);
        expect(cacheManager.contains('key2'), isFalse);
      });

      test('should get cache statistics', () {
        final stats = cacheManager.getStats();

        expect(stats.totalEntries, isA<int>());
        expect(stats.memoryUsageBytes, isA<int>());
        expect(stats.totalHits, isA<int>());
        expect(stats.totalMisses, isA<int>());
        expect(stats.hitRate, isA<double>());
      });

      test('should get performance metrics', () {
        final metrics = cacheManager.getPerformanceMetrics();

        expect(metrics, isA<Map<String, dynamic>>());
        expect(metrics['cache_size'], isA<int>());
        expect(metrics['lru_enabled'], isA<bool>());
        expect(metrics['expiration_cleanup_enabled'], isA<bool>());
      });
    });

    group('TTL Management', () {
      test('should respect TTL settings', () async {
        const key = 'ttl_test_key';
        const data = 'ttl_test_data';
        const ttlSeconds = 1;

        await cacheManager.set(key, data, ttl: Duration(seconds: ttlSeconds));
        expect(cacheManager.contains(key), isTrue);

        // Wait for TTL to expire
        await Future.delayed(Duration(seconds: ttlSeconds + 1));
        expect(cacheManager.contains(key), isFalse);
      });

      test('should use default TTL when not specified', () async {
        const key = 'default_ttl_key';
        const data = 'default_ttl_data';

        await cacheManager.set(key, data);
        expect(cacheManager.contains(key), isTrue);

        // Wait for default TTL to expire (should be longer than 1 second)
        await Future.delayed(Duration(seconds: 2));
        expect(cacheManager.contains(key), isTrue); // Should still exist
      });
    });

    group('Memory Management', () {
      test('should enforce entry limit', () async {
        // Set a small max entries limit
        final limitedCache = CacheManager(config: {'max_entries': 2});

        await limitedCache.set('key1', 'data1');
        await limitedCache.set('key2', 'data2');
        await limitedCache.set(
          'key3',
          'data3',
        ); // This should trigger LRU eviction

        // The oldest entry should be evicted
        expect(limitedCache.contains('key1'), isFalse);
        expect(limitedCache.contains('key2'), isTrue);
        expect(limitedCache.contains('key3'), isTrue);

        limitedCache.dispose();
      });

      test('should handle memory limits efficiently', () async {
        final memoryLimitedCache = CacheManager(
          config: {
            'max_memory_mb': 1, // Very small memory limit
            'max_entries': 1000,
          },
        );

        // Add entries until memory limit is reached
        for (int i = 0; i < 100; i++) {
          await memoryLimitedCache.set('key_$i', 'data_$i' * 1000);
        }

        // Should handle memory enforcement efficiently
        final stats = memoryLimitedCache.getStats();
        expect(stats.totalEntries, lessThan(100));

        memoryLimitedCache.dispose();
      });
    });

    group('LRU Functionality', () {
      test('should implement LRU eviction correctly', () async {
        final lruCache = CacheManager(config: {'max_entries': 3});

        // Add 3 entries
        await lruCache.set('key1', 'data1');
        await lruCache.set('key2', 'data2');
        await lruCache.set('key3', 'data3');

        // Access key1 to make it most recently used
        lruCache.get('key1');

        // Add a new entry, should evict key2 (least recently used)
        await lruCache.set('key4', 'data4');

        expect(lruCache.contains('key1'), isTrue); // Most recently used
        expect(
          lruCache.contains('key2'),
          isFalse,
        ); // Least recently used, evicted
        expect(lruCache.contains('key3'), isTrue);
        expect(lruCache.contains('key4'), isTrue);

        lruCache.dispose();
      });
    });

    group('Metadata and TTL Extension', () {
      test('should support custom metadata', () async {
        const key = 'metadata_key';
        const data = 'metadata_data';
        final metadata = {
          'user_id': 123,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await cacheManager.set(key, data, metadata: metadata);
        final result = cacheManager.get(key);
        expect(result, equals(data));
      });

      test('should extend TTL for existing entries', () async {
        const key = 'extend_ttl_key';
        const data = 'extend_ttl_data';
        const shortTTL = Duration(milliseconds: 100);

        await cacheManager.set(key, data, ttl: shortTTL);
        expect(cacheManager.contains(key), isTrue);

        // Extend TTL before expiration
        cacheManager.extendTTL(key, Duration(seconds: 10));

        // Wait for original TTL to expire
        await Future.delayed(Duration(milliseconds: 200));

        // Should still exist due to extended TTL
        expect(cacheManager.contains(key), isTrue);
      });
    });

    group('Cache Keys and Management', () {
      test('should return all cache keys', () async {
        await cacheManager.set('key1', 'data1');
        await cacheManager.set('key2', 'data2');
        await cacheManager.set('key3', 'data3');

        final keys = cacheManager.getKeys();
        expect(keys.length, equals(3));
        expect(keys, contains('key1'));
        expect(keys, contains('key2'));
        expect(keys, contains('key3'));
      });

      test('should update metadata for existing entries', () async {
        const key = 'update_metadata_key';
        const data = 'update_metadata_data';
        const initialMetadata = {'version': 1};
        const updatedMetadata = {'version': 2, 'updated': true};

        await cacheManager.set(key, data, metadata: initialMetadata);
        cacheManager.updateMetadata(key, updatedMetadata);

        // Verify the entry still exists
        expect(cacheManager.contains(key), isTrue);
        final result = cacheManager.get(key);
        expect(result, equals(data));
      });
    });

    group('Error Handling', () {
      test('should handle invalid keys gracefully', () {
        final result = cacheManager.get('');
        expect(result, isNull);
      });

      test('should handle null data gracefully', () async {
        await cacheManager.set('null_key', null);
        final result = cacheManager.get('null_key');
        expect(result, isNull);
      });
    });

    group('Performance and Scalability', () {
      test('should handle multiple concurrent operations', () async {
        final futures = <Future>[];

        // Perform 100 concurrent set operations
        for (int i = 0; i < 100; i++) {
          futures.add(
            cacheManager.set('concurrent_key_$i', 'concurrent_data_$i'),
          );
        }

        await Future.wait(futures);

        // Verify all entries were added
        for (int i = 0; i < 100; i++) {
          expect(cacheManager.contains('concurrent_key_$i'), isTrue);
        }
      });

      test('should maintain performance under load', () async {
        final stopwatch = Stopwatch()..start();

        // Perform 1000 operations
        for (int i = 0; i < 1000; i++) {
          await cacheManager.set('load_key_$i', 'load_data_$i');
          cacheManager.get('load_key_$i');
        }

        final elapsed = stopwatch.elapsedMilliseconds;
        expect(elapsed, lessThan(5000)); // Should complete in under 5 seconds

        // Verify final state
        final stats = cacheManager.getStats();
        expect(stats.totalEntries, greaterThan(0));
      });
    });
  });
}
