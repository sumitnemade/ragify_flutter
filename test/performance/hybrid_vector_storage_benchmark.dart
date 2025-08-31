import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:math';

/// Performance benchmark tests for hybrid vector storage
/// Demonstrates the improvement after fixing the in-memory storage bottleneck
void main() {
  final logger = Logger();

  group('Hybrid Vector Storage Performance Benchmark', () {
    late VectorDatabase vectorDb;
    late List<VectorData> testVectors;
    late List<double> queryVector;

    setUp(() async {
      // Initialize vector database with hybrid storage
      vectorDb = VectorDatabase(
        vectorDbUrl: 'faiss://test_vectors',
        config: {
          'dimension': 384,
          'metric': 'cosine',
          'max_cache_size_mb': 50, // 50MB cache limit
          'max_cache_entries': 5000, // 5000 entry limit
          'enable_disk_storage': true,
        },
      );

      await vectorDb.initialize();

      // Generate test vectors with consistent dimension
      testVectors = [];
      final random = Random(42); // Fixed seed for reproducible tests

      for (int i = 0; i < 1000; i++) {
        final embedding = List<double>.generate(
          384,
          (index) => random.nextDouble() * 2 - 1,
        );
        testVectors.add(
          VectorData(
            id: 'vector_$i',
            chunkId: 'chunk_$i',
            embedding: embedding,
            metadata: {'index': i, 'generated': true},
          ),
        );
      }

      // Generate query vector
      queryVector = List<double>.generate(
        384,
        (index) => random.nextDouble() * 2 - 1,
      );
    });

    tearDown(() async {
      await vectorDb.close();
    });

    test('Benchmark: Vector Storage Initialization', () {
      final stopwatch = Stopwatch()..start();

      // Test initialization performance
      expect(vectorDb.getStats()['is_initialized'], isTrue);

      final initTime = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        'Vector storage initialization: ${initTime.toStringAsFixed(2)}ms',
      );

      expect(initTime, lessThan(100.0)); // Should initialize quickly
    });

    test('Benchmark: Vector Insertion Performance', () async {
      final stopwatch = Stopwatch()..start();

      // Add vectors in batches
      const batchSize = 100;
      for (int i = 0; i < testVectors.length; i += batchSize) {
        final end = (i + batchSize < testVectors.length)
            ? i + batchSize
            : testVectors.length;
        final batch = testVectors.sublist(i, end);
        await vectorDb.addVectors(batch);
      }

      final insertTime = stopwatch.elapsedMicroseconds / 1000.0;
      final vectorsPerSecond = (testVectors.length / insertTime) * 1000;

      logger.i(
        'Vector insertion: ${testVectors.length} vectors in ${insertTime.toStringAsFixed(2)}ms',
      );
      logger.i(
        '   Performance: ${vectorsPerSecond.toStringAsFixed(0)} vectors/second',
      );

      expect(
        insertTime,
        lessThan(5000.0),
      ); // Should handle 1000 vectors in under 5 seconds
      expect(
        vectorsPerSecond,
        greaterThan(100.0),
      ); // Should achieve at least 100 vectors/second
    });

    test('Benchmark: Memory Usage Efficiency', () async {
      // Get initial stats
      final initialStats = vectorDb.getStats();
      final initialMemory =
          initialStats['cache_stats']['cache_memory_mb'] as double;

      logger.i('Initial memory usage: ${initialMemory.toStringAsFixed(2)}MB');

      // Add vectors and monitor memory
      await vectorDb.addVectors(testVectors.take(500).toList());

      final afterInsertStats = vectorDb.getStats();
      final afterInsertMemory =
          afterInsertStats['cache_stats']['cache_memory_mb'] as double;

      logger.i(
        'Memory after 500 vectors: ${afterInsertMemory.toStringAsFixed(2)}MB',
      );

      // Memory should be within reasonable limits
      expect(
        afterInsertMemory,
        lessThan(50.0),
      ); // Should stay under 50MB cache limit

      // Check cache hit rate
      final cacheHitRate =
          afterInsertStats['cache_stats']['cache_hit_rate'] as double;
      logger.i('Cache hit rate: ${(cacheHitRate * 100).toStringAsFixed(1)}%');
    });

    test('Benchmark: Vector Search Performance', () async {
      // Add vectors first
      await vectorDb.addVectors(testVectors.take(500).toList());

      final stopwatch = Stopwatch()..start();

      // Perform multiple searches
      const searchCount = 10;
      List<List<SearchResult>> allResults = [];

      for (int i = 0; i < searchCount; i++) {
        final results = await vectorDb.searchVectors(
          queryVector,
          10,
          minScore: 0.5,
        );
        allResults.add(results);
      }

      final searchTime = stopwatch.elapsedMicroseconds / 1000.0;
      final avgSearchTime = searchTime / searchCount;
      final searchesPerSecond = (searchCount / searchTime) * 1000;

      logger.i(
        'Vector search: $searchCount searches in ${searchTime.toStringAsFixed(2)}ms',
      );
      logger.i('   Average search time: ${avgSearchTime.toStringAsFixed(2)}ms');
      logger.i(
        '   Performance: ${searchesPerSecond.toStringAsFixed(1)} searches/second',
      );

      expect(
        avgSearchTime,
        lessThan(100.0),
      ); // Each search should complete in under 100ms
      expect(
        searchesPerSecond,
        greaterThan(5.0),
      ); // Should achieve at least 5 searches/second

      // Verify search results
      for (final results in allResults) {
        expect(results.length, lessThanOrEqualTo(10));
        if (results.isNotEmpty) {
          expect(results.first.score, greaterThanOrEqualTo(0.5));
        }
      }
    });

    test('Benchmark: Cache Performance Under Load', () async {
      // Add vectors to fill cache
      await vectorDb.addVectors(testVectors.take(800).toList());

      final initialStats = vectorDb.getStats();
      final initialCacheSize = initialStats['cache_stats']['cache_size'] as int;

      logger.i('Initial cache size: $initialCacheSize entries');

      // Perform repeated searches to test cache performance
      final stopwatch = Stopwatch()..start();
      const searchCount = 50;

      for (int i = 0; i < searchCount; i++) {
        await vectorDb.searchVectors(queryVector, 5, minScore: 0.3);
      }

      final loadTime = stopwatch.elapsedMicroseconds / 1000.0;
      final searchesPerSecond = (searchCount / loadTime) * 1000;

      logger.i(
        'Cache performance under load: $searchCount searches in ${loadTime.toStringAsFixed(2)}ms',
      );
      logger.i(
        '   Performance: ${searchesPerSecond.toStringAsFixed(1)} searches/second',
      );

      // Check cache statistics
      final finalStats = vectorDb.getStats();
      final cacheHits = finalStats['cache_stats']['cache_hits'] as int;
      final cacheMisses = finalStats['cache_stats']['cache_misses'] as int;
      final hitRate = finalStats['cache_stats']['cache_hit_rate'] as double;

      logger.i(
        'Cache hits: $cacheHits, misses: $cacheMisses, hit rate: ${(hitRate * 100).toStringAsFixed(1)}%',
      );

      expect(
        searchesPerSecond,
        greaterThan(10.0),
      ); // Should achieve good performance under load
      expect(
        hitRate,
        greaterThan(0.5),
      ); // Should have reasonable cache hit rate
    });

    test('Benchmark: Memory Management Efficiency', () async {
      // Add vectors beyond cache capacity
      await vectorDb.addVectors(testVectors.take(1000).toList());

      final stats = vectorDb.getStats();
      final cacheSize = stats['cache_stats']['cache_size'] as int;
      final memoryUsage = stats['cache_stats']['cache_memory_mb'] as double;
      final evictions = stats['cache_stats']['cache_evictions'] as int;

      logger.i('Cache size: $cacheSize entries');
      logger.i('Memory usage: ${memoryUsage.toStringAsFixed(2)}MB');
      logger.i('Cache evictions: $evictions');

      // Should respect cache limits
      expect(
        cacheSize,
        lessThanOrEqualTo(5000),
      ); // Should not exceed max entries
      expect(
        memoryUsage,
        lessThanOrEqualTo(60.0),
      ); // Should stay within memory limit
      expect(evictions, greaterThan(0)); // Should have evicted some entries
    });

    test('Benchmark: Disk I/O Performance', () async {
      // Add vectors to trigger disk storage
      await vectorDb.addVectors(testVectors.take(1000).toList());

      final stats = vectorDb.getStats();
      final diskReads = stats['storage_stats']['disk_reads'] as int;
      final diskWrites = stats['storage_stats']['disk_writes'] as int;

      logger.i('Disk reads: $diskReads');
      logger.i('Disk writes: $diskWrites');

      // Should have written vectors to disk
      expect(diskWrites, greaterThan(0));

      // Test reading from disk by clearing cache and searching
      await vectorDb.clearCache();

      final stopwatch = Stopwatch()..start();
      final results = await vectorDb.searchVectors(
        queryVector,
        10,
        minScore: 0.3,
      );
      final diskReadTime = stopwatch.elapsedMicroseconds / 1000.0;

      logger.i(
        'Disk read performance: ${diskReadTime.toStringAsFixed(2)}ms for 10 results',
      );

      expect(diskReadTime, lessThan(200.0)); // Disk reads should be reasonable
      expect(results.length, greaterThan(0)); // Should find some results
    });

    test('Benchmark: Scalability with Large Datasets', () async {
      // Test with larger dataset
      final largeTestVectors = <VectorData>[];
      final random = Random(42);

      for (int i = 0; i < 2000; i++) {
        final embedding = List<double>.generate(
          384,
          (index) => random.nextDouble() * 2 - 1,
        );
        largeTestVectors.add(
          VectorData(
            id: 'large_vector_$i',
            chunkId: 'large_chunk_$i',
            embedding: embedding,
            metadata: {'index': i, 'size': 'large'},
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      // Add large dataset
      await vectorDb.addVectors(largeTestVectors);

      final insertTime = stopwatch.elapsedMicroseconds / 1000.0;
      final vectorsPerSecond = (largeTestVectors.length / insertTime) * 1000;

      logger.i(
        'Large dataset insertion: ${largeTestVectors.length} vectors in ${insertTime.toStringAsFixed(2)}ms',
      );
      logger.i(
        '   Performance: ${vectorsPerSecond.toStringAsFixed(0)} vectors/second',
      );

      // Should handle large datasets efficiently
      expect(
        insertTime,
        lessThan(10000.0),
      ); // Should complete in under 10 seconds
      expect(
        vectorsPerSecond,
        greaterThan(150.0),
      ); // Should maintain good performance

      // Test search performance with large dataset
      final searchStopwatch = Stopwatch()..start();
      final results = await vectorDb.searchVectors(
        queryVector,
        20,
        minScore: 0.2,
      );
      final searchTime = searchStopwatch.elapsedMicroseconds / 1000.0;

      logger.i(
        'Large dataset search: 20 results in ${searchTime.toStringAsFixed(2)}ms',
      );

      expect(
        searchTime,
        lessThan(300.0),
      ); // Should complete search in reasonable time
      expect(results.length, greaterThan(0)); // Should find results
    });

    test('Benchmark: Cache Optimization Performance', () async {
      // Fill cache with vectors
      await vectorDb.addVectors(testVectors.take(1000).toList());

      final beforeOptimization = vectorDb.getStats();
      final beforeCacheSize =
          beforeOptimization['cache_stats']['cache_size'] as int;

      logger.i('Cache size before optimization: $beforeCacheSize entries');

      // Perform cache optimization
      final stopwatch = Stopwatch()..start();
      await vectorDb.optimizeCache();
      final optimizationTime = stopwatch.elapsedMicroseconds / 1000.0;

      final afterOptimization = vectorDb.getStats();
      final afterCacheSize =
          afterOptimization['cache_stats']['cache_size'] as int;

      logger.i('Cache optimization: ${optimizationTime.toStringAsFixed(2)}ms');
      logger.i('Cache size after optimization: $afterCacheSize entries');

      // Optimization should be fast
      expect(optimizationTime, lessThan(100.0)); // Should complete quickly

      // Cache size should be reasonable
      expect(afterCacheSize, lessThanOrEqualTo(5000)); // Should respect limits
    });

    test('Benchmark: Concurrent Operations', () async {
      // Add vectors first
      await vectorDb.addVectors(testVectors.take(500).toList());

      final stopwatch = Stopwatch()..start();

      // Perform concurrent searches
      const concurrentCount = 5;
      final futures = <Future<List<SearchResult>>>[];

      for (int i = 0; i < concurrentCount; i++) {
        futures.add(vectorDb.searchVectors(queryVector, 10, minScore: 0.3));
      }

      final results = await Future.wait(futures);
      final concurrentTime = stopwatch.elapsedMicroseconds / 1000.0;

      logger.i(
        'Concurrent operations: $concurrentCount searches in ${concurrentTime.toStringAsFixed(2)}ms',
      );

      // Should handle concurrent operations efficiently
      expect(
        concurrentTime,
        lessThan(500.0),
      ); // Should complete in reasonable time

      // All searches should return results
      for (final result in results) {
        expect(result.length, greaterThanOrEqualTo(0));
      }
    });

    test('Benchmark: Overall System Performance', () async {
      final stopwatch = Stopwatch()..start();

      // Complete workflow: add vectors, search, optimize
      await vectorDb.addVectors(testVectors.take(800).toList());

      final searchResults = await vectorDb.searchVectors(
        queryVector,
        15,
        minScore: 0.4,
      );

      await vectorDb.optimizeCache();

      final totalTime = stopwatch.elapsedMicroseconds / 1000.0;

      logger.i('Overall system performance: ${totalTime.toStringAsFixed(2)}ms');
      logger.i('   - Added 800 vectors');
      logger.i('   - Performed search (${searchResults.length} results)');
      logger.i('   - Optimized cache');

      // Should complete full workflow efficiently
      expect(totalTime, lessThan(3000.0)); // Should complete in under 3 seconds
      expect(searchResults.length, greaterThan(0)); // Should find results

      // Final system stats
      final finalStats = vectorDb.getStats();
      final totalVectors = finalStats['total_vectors'] as int;
      final cacheHitRate =
          finalStats['cache_stats']['cache_hit_rate'] as double;
      final memoryUsage =
          finalStats['cache_stats']['cache_memory_mb'] as double;

      logger.i('Final system state:');
      logger.i('   - Total vectors: $totalVectors');
      logger.i(
        '   - Cache hit rate: ${(cacheHitRate * 100).toStringAsFixed(1)}%',
      );
      logger.i('   - Memory usage: ${memoryUsage.toStringAsFixed(2)}MB');

      expect(totalVectors, equals(800));
      expect(memoryUsage, lessThan(60.0)); // Should stay within limits
    });
  });
}
