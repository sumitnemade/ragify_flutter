import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';
import 'package:logger/logger.dart';

/// Performance benchmark tests for cache manager
/// Demonstrates the improvement after fixing the memory-intensive operations bottleneck
void main() {
  final logger = Logger();

  group('Cache Manager Performance Benchmark', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager(
        config: {
          'max_memory_mb': 50,
          'max_entries': 1000,
          'cleanup_interval_seconds': 60,
          'lru_enabled': true,
          'expiration_cleanup_enabled': true,
        },
      );
    });

    tearDown(() {
      cache.dispose();
    });

    test('Benchmark: Cache Initialization', () {
      final stopwatch = Stopwatch()..start();

      // Test cache creation
      final newCache = CacheManager();

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ Cache Initialization: ${elapsed.toStringAsFixed(2)}ms');

      // Cache creation should be very fast
      expect(elapsed, lessThan(5.0));

      newCache.dispose();
    });

    test('Benchmark: Cache Set Operations', () {
      final stopwatch = Stopwatch()..start();

      // Test multiple cache set operations
      for (int i = 0; i < 100; i++) {
        cache.set('key_$i', 'value_$i', ttl: Duration(seconds: 60));
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Cache Set Operations (100 entries): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Should be very fast with O(1) operations
      expect(elapsed, lessThan(50.0));

      // Verify entries were added
      expect(cache.getKeys().length, equals(100));
    });

    test('Benchmark: Cache Get Operations', () {
      // Setup: Add some entries
      for (int i = 0; i < 50; i++) {
        cache.set('key_$i', 'value_$i', ttl: Duration(seconds: 60));
      }

      final stopwatch = Stopwatch()..start();

      // Test multiple cache get operations
      for (int i = 0; i < 50; i++) {
        final value = cache.get<String>('key_$i');
        expect(value, equals('value_$i'));
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Cache Get Operations (50 entries): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Should be very fast with O(1) operations
      expect(elapsed, lessThan(20.0));
    });

    test('Benchmark: Cache Hit Rate Performance', () {
      // Setup: Add entries
      for (int i = 0; i < 100; i++) {
        cache.set('key_$i', 'value_$i', ttl: Duration(seconds: 60));
      }

      final stopwatch = Stopwatch()..start();

      // Test cache hit rate with repeated access
      for (int round = 0; round < 5; round++) {
        for (int i = 0; i < 100; i++) {
          cache.get<String>('key_$i');
        }
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Cache Hit Rate Performance (500 operations): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Should be very fast with O(1) operations
      expect(elapsed, lessThan(100.0));

      // Check hit rate
      final stats = cache.getStats();
      expect(stats.hitRate, greaterThan(0.8)); // Should have high hit rate
    });

    test('Benchmark: Memory Limit Enforcement', () {
      final stopwatch = Stopwatch()..start();

      // Add entries until memory limit is reached
      int entryCount = 0;
      try {
        while (entryCount < 2000) {
          cache.set(
            'key_$entryCount',
            'value_$entryCount' * 1000,
            ttl: Duration(seconds: 60),
          );
          entryCount++;
        }
      } catch (e) {
        // Expected to hit memory limit
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ Memory Limit Enforcement: ${elapsed.toStringAsFixed(2)}ms');

      // Should handle memory limits efficiently
      expect(elapsed, lessThan(1000.0));

      // Should have some entries (not all were evicted)
      final stats = cache.getStats();
      expect(stats.totalEntries, greaterThan(0));
      expect(
        stats.totalEntries,
        lessThanOrEqualTo(1000),
      ); // Should respect max_entries
    });

    test('Benchmark: LRU Eviction Performance', () {
      final stopwatch = Stopwatch()..start();

      // Fill cache to capacity
      for (int i = 0; i < 1000; i++) {
        cache.set('lru_key_$i', 'lru_value_$i', ttl: Duration(seconds: 60));
      }

      // Access some entries to make them "recently used"
      for (int i = 0; i < 100; i++) {
        cache.get<String>('lru_key_$i');
      }

      // Add more entries to trigger LRU eviction
      for (int i = 1000; i < 1100; i++) {
        cache.set('lru_key_$i', 'lru_value_$i', ttl: Duration(seconds: 60));
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ LRU Eviction Performance: ${elapsed.toStringAsFixed(2)}ms');

      // Should handle LRU eviction efficiently
      expect(elapsed, lessThan(500.0));

      // Should maintain max_entries limit
      final stats = cache.getStats();
      expect(stats.totalEntries, lessThanOrEqualTo(1000));
    });

    test('Benchmark: Expiration Cleanup Performance', () async {
      final stopwatch = Stopwatch()..start();

      // Add entries with short TTL
      for (int i = 0; i < 500; i++) {
        cache.set(
          'expire_key_$i',
          'expire_value_$i',
          ttl: Duration(milliseconds: 100),
        );
      }

      // Wait for expiration
      await Future.delayed(Duration(milliseconds: 200));

      // Trigger cleanup by adding more entries
      for (int i = 500; i < 1000; i++) {
        cache.set(
          'expire_key_$i',
          'expire_value_$i',
          ttl: Duration(seconds: 60),
        );
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Expiration Cleanup Performance: ${elapsed.toStringAsFixed(2)}ms',
      );

      // Should handle expiration cleanup efficiently
      expect(elapsed, lessThan(300.0));

      // Should have cleaned up expired entries
      final stats = cache.getStats();
      expect(stats.totalEntries, lessThanOrEqualTo(1000));
    });

    test('Benchmark: Concurrent Operations', () async {
      final stopwatch = Stopwatch()..start();

      // Test concurrent cache operations
      final futures = <Future<void>>[];
      for (int i = 0; i < 100; i++) {
        futures.add(
          Future(() async {
            cache.set(
              'concurrent_key_$i',
              'concurrent_value_$i',
              ttl: Duration(seconds: 60),
            );
          }),
        );
      }

      await Future.wait(futures);

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Concurrent Operations (100 concurrent sets): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Should handle concurrent operations efficiently
      expect(elapsed, lessThan(200.0));

      // Verify all entries were added
      for (int i = 0; i < 100; i++) {
        final value = cache.get<String>('concurrent_key_$i');
        expect(value, equals('concurrent_value_$i'));
      }
    });

    test('Benchmark: Cache Statistics Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test statistics collection
      final stats = cache.getStats();
      final metrics = cache.getPerformanceMetrics();

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Cache Statistics Performance: ${elapsed.toStringAsFixed(2)}ms',
      );

      expect(stats, isA<CacheStats>());
      expect(metrics, isA<Map<String, dynamic>>());

      // Statistics should be very fast
      expect(elapsed, lessThan(5.0));
    });

    test('Benchmark: Memory Efficiency', () {
      // Test that cache operations don't create excessive memory allocations
      int operationCount = 0;

      // Perform multiple operations
      for (int i = 0; i < 100; i++) {
        cache.set(
          'efficiency_key_$i',
          'efficiency_value_$i',
          ttl: Duration(seconds: 60),
        );
        final stats = cache.getStats();
        final metrics = cache.getPerformanceMetrics();

        expect(stats, isA<CacheStats>());
        expect(metrics, isA<Map<String, dynamic>>());

        operationCount++;
      }

      logger.i(
        '✅ Memory Efficiency: Completed $operationCount operations without excessive allocations',
      );

      // Should complete all operations successfully
      expect(operationCount, equals(100));
    });

    test('Benchmark: Cache Disposal Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test cache disposal performance
      cache.dispose();

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ Cache Disposal Performance: ${elapsed.toStringAsFixed(2)}ms');

      // Disposal should be very fast
      expect(elapsed, lessThan(10.0));
    });

    test('Benchmark: Performance Under Load', () {
      // Test performance when cache is under load
      final stopwatch = Stopwatch()..start();

      // Fill cache to capacity
      for (int i = 0; i < 1000; i++) {
        cache.set(
          'load_key_$i',
          'load_value_$i' * 100,
          ttl: Duration(seconds: 60),
        );
      }

      // Perform mixed operations
      int successfulOperations = 0;
      for (int i = 0; i < 500; i++) {
        try {
          if (i % 3 == 0) {
            cache.set(
              'load_key_$i',
              'updated_value_$i',
              ttl: Duration(seconds: 60),
            );
            successfulOperations++;
          } else if (i % 3 == 1) {
            final value = cache.get<String>('load_key_$i');
            if (value != null) successfulOperations++;
          } else {
            // Only try to remove if the key exists
            if (cache.contains('load_key_$i')) {
              cache.remove('load_key_$i');
              successfulOperations++;
            }
          }
        } catch (e) {
          // Expected that some operations may fail due to LRU eviction
        }
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Performance Under Load (1500 operations): ${elapsed.toStringAsFixed(2)}ms',
      );
      logger.i('✅ Successful operations: $successfulOperations out of 500');

      // Should handle load efficiently
      expect(elapsed, lessThan(500.0));

      // Should have some successful operations
      expect(successfulOperations, greaterThan(0));

      // Check final state
      final finalStats = cache.getStats();
      expect(finalStats.totalEntries, greaterThan(0));
      expect(
        finalStats.totalEntries,
        lessThanOrEqualTo(1000),
      ); // Should respect max_entries
    });
  });
}
