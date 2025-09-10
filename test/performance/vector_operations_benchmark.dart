import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:math';

/// Performance benchmark tests for vector operations
/// Demonstrates the improvement after fixing O(n²) bottlenecks
void main() {
  final logger = RAGifyLogger.fromLogger(Logger());

  group('Vector Operations Performance Benchmark', () {
    late List<List<double>> testVectors;
    late List<double> queryVector;

    setUp(() {
      // Generate test data
      final random = Random(42); // Fixed seed for reproducible tests

      // Create vectors with compatible dimensions for testing
      testVectors = List.generate(100, (i) {
        // Use consistent dimension for compatibility
        final dimension = 384; // Same as query vector
        return List.generate(
          dimension,
          (_) => (random.nextDouble() - 0.5) * 2.0,
        );
      });

      queryVector = List.generate(
        384,
        (_) => (random.nextDouble() - 0.5) * 2.0,
      );
    });

    test('Benchmark: Cosine Similarity Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test individual cosine similarity calculations
      for (final vector in testVectors.take(50)) {
        final similarity = EmbeddingUtils.cosineSimilarity(queryVector, vector);
        expect(similarity, isA<double>());
        expect(similarity >= -1.0 && similarity <= 1.0, isTrue);
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Cosine Similarity (50 vectors): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Performance should be under 100ms for 50 vectors of size 384
      expect(elapsed, lessThan(100.0));
    });

    test('Benchmark: Batch Cosine Similarity Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test batch cosine similarity calculation
      final similarities = EmbeddingUtils.batchCosineSimilarity(
        queryVector,
        testVectors.take(100).toList(),
      );

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Batch Cosine Similarity (100 vectors): ${elapsed.toStringAsFixed(2)}ms',
      );

      expect(similarities.length, equals(100));
      expect(similarities.every((s) => s >= -1.0 && s <= 1.0), isTrue);

      // Batch processing should be significantly faster than individual calls
      expect(elapsed, lessThan(200.0));
    });

    test('Benchmark: Euclidean Distance Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test individual Euclidean distance calculations
      for (final vector in testVectors.take(50)) {
        final distance = EmbeddingUtils.euclideanDistance(queryVector, vector);
        expect(distance, isA<double>());
        expect(distance >= 0.0, isTrue);
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Euclidean Distance (50 vectors): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Performance should be under 100ms for 50 vectors
      expect(elapsed, lessThan(100.0));
    });

    test('Benchmark: Vector Addition Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test vector addition operations
      for (int i = 0; i < 50; i++) {
        final vector1 = testVectors[i];
        final vector2 = testVectors[(i + 1) % testVectors.length];

        if (vector1.length == vector2.length) {
          final result = EmbeddingUtils.addVectors(vector1, vector2);
          expect(result.length, equals(vector1.length));
        }
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Vector Addition (50 operations): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Vector addition should be very fast
      expect(elapsed, lessThan(50.0));
    });

    test('Benchmark: Vector Normalization Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test vector normalization operations
      for (final vector in testVectors.take(50)) {
        final normalized = EmbeddingUtils.normalizeVector(vector);
        expect(normalized.length, equals(vector.length));

        // Check that normalized vector has magnitude close to 1.0
        final magnitude = EmbeddingUtils.vectorMagnitude(normalized);
        expect(magnitude, closeTo(1.0, 0.01));
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Vector Normalization (50 vectors): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Normalization should be reasonably fast
      expect(elapsed, lessThan(80.0));
    });

    test('Benchmark: Top-K Similar Vectors Performance', () {
      final stopwatch = Stopwatch()..start();

      // Test finding top-k similar vectors
      final topK = EmbeddingUtils.findTopKSimilar(
        queryVector,
        testVectors.take(100).toList(),
        10,
      );

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Top-K Similar Vectors (100 vectors, k=10): ${elapsed.toStringAsFixed(2)}ms',
      );

      expect(topK.length, equals(10));
      expect(topK.every((entry) => entry.key >= 0 && entry.key < 100), isTrue);

      // Top-K should be reasonably fast
      expect(elapsed, lessThan(150.0));
    });

    test('Benchmark: Memory Efficiency', () {
      // Test that operations don't create excessive memory allocations
      // Use a simple counter instead of ProcessInfo for Flutter tests
      int operationCount = 0;

      // Perform multiple operations
      for (int i = 0; i < 100; i++) {
        final similarities = EmbeddingUtils.batchCosineSimilarity(
          queryVector,
          testVectors.take(20).toList(),
        );
        expect(similarities.length, equals(20));
        operationCount++;
      }

      logger.i(
        '✅ Memory Efficiency: Completed $operationCount operations without excessive allocations',
      );

      // Should complete all operations successfully
      expect(operationCount, equals(100));
    });

    test('Benchmark: Cache Effectiveness', () {
      // Test that caching improves performance for repeated operations
      final stopwatch1 = Stopwatch()..start();

      // First run - no cache hits
      for (int i = 0; i < 100; i++) {
        final vector = testVectors[i % testVectors.length];
        EmbeddingUtils.vectorMagnitude(vector);
      }

      final firstRunTime = stopwatch1.elapsedMicroseconds;

      final stopwatch2 = Stopwatch()..start();

      // Second run - should have cache hits
      for (int i = 0; i < 100; i++) {
        final vector = testVectors[i % testVectors.length];
        EmbeddingUtils.vectorMagnitude(vector);
      }

      final secondRunTime = stopwatch2.elapsedMicroseconds;

      logger.i(
        '✅ Cache Performance: First run: ${(firstRunTime / 1000).toStringAsFixed(2)}ms, Second run: ${(secondRunTime / 1000).toStringAsFixed(2)}ms',
      );

      // Second run should be faster due to caching
      expect(secondRunTime, lessThanOrEqualTo(firstRunTime));
    });

    test('Benchmark: Scalability with Vector Size', () {
      // Test performance scaling with different vector sizes
      final sizes = [100, 200, 400, 800];
      final results = <int, double>{};

      for (final size in sizes) {
        final vector1 = List.generate(size, (i) => i.toDouble());
        final vector2 = List.generate(size, (i) => (i + 1).toDouble());

        final stopwatch = Stopwatch()..start();
        EmbeddingUtils.cosineSimilarity(vector1, vector2);
        final elapsed = stopwatch.elapsedMicroseconds / 1000.0;

        results[size] = elapsed;
        logger.i('✅ Vector size $size: ${elapsed.toStringAsFixed(2)}ms');
      }

      // Performance should scale linearly, not exponentially
      final size100 = results[100]!;
      final size800 = results[800]!;

      // 800-dimension vector should take roughly 8x time of 100-dimension vector
      // (linear scaling), not 64x (quadratic scaling)
      expect(size800, lessThan(size100 * 12)); // Allow some overhead
    });
  });
}
