import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/utils/embedding_utils.dart';
import 'dart:math';

void main() {
  group('EmbeddingUtils Tests', () {
    late List<double> vector1;
    late List<double> vector2;
    late List<double> vector3;
    late List<double> emptyVector;
    late List<double> zeroVector;

    setUp(() {
      vector1 = [1.0, 2.0, 3.0, 4.0];
      vector2 = [2.0, 4.0, 6.0, 8.0];
      vector3 = [0.5, 1.0, 1.5, 2.0];
      emptyVector = [];
      zeroVector = [0.0, 0.0, 0.0, 0.0];
    });

    group('Cosine Similarity Tests', () {
      test('should calculate cosine similarity between vectors', () {
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, closeTo(1.0, 0.001)); // Vectors are proportional
      });

      test('should handle orthogonal vectors', () {
        final orthogonal1 = [1.0, 0.0];
        final orthogonal2 = [0.0, 1.0];
        final similarity = EmbeddingUtils.cosineSimilarity(orthogonal1, orthogonal2);
        expect(similarity, closeTo(0.0, 0.001));
      });

      test('should handle identical vectors', () {
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector1);
        expect(similarity, closeTo(1.0, 0.001));
      });

      test('should handle zero vectors', () {
        final similarity = EmbeddingUtils.cosineSimilarity(zeroVector, zeroVector);
        expect(similarity, equals(0.0));
      });

      test('should handle empty vectors', () {
        final similarity = EmbeddingUtils.cosineSimilarity(emptyVector, emptyVector);
        expect(similarity, equals(0.0));
      });

      test('should throw error for different length vectors', () {
        expect(
          () => EmbeddingUtils.cosineSimilarity(vector1, [1.0, 2.0]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Euclidean Distance Tests', () {
      test('should calculate Euclidean distance between vectors', () {
        final distance = EmbeddingUtils.euclideanDistance(vector1, vector2);
        expect(distance, greaterThan(0.0));
      });

      test('should handle identical vectors', () {
        final distance = EmbeddingUtils.euclideanDistance(vector1, vector1);
        expect(distance, equals(0.0));
      });

      test('should handle zero vectors', () {
        final distance = EmbeddingUtils.euclideanDistance(zeroVector, zeroVector);
        expect(distance, equals(0.0));
      });

      test('should handle empty vectors', () {
        final distance = EmbeddingUtils.euclideanDistance(emptyVector, emptyVector);
        expect(distance, equals(0.0));
      });

      test('should throw error for different length vectors', () {
        expect(
          () => EmbeddingUtils.euclideanDistance(vector1, [1.0, 2.0]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle small vectors (<=16)', () {
        final smallVector1 = [1.0, 2.0, 3.0];
        final smallVector2 = [4.0, 5.0, 6.0];
        final distance = EmbeddingUtils.euclideanDistance(smallVector1, smallVector2);
        expect(distance, greaterThan(0.0));
      });

      test('should handle large vectors (>16)', () {
        final largeVector1 = List.generate(20, (i) => i.toDouble());
        final largeVector2 = List.generate(20, (i) => (i + 1).toDouble());
        final distance = EmbeddingUtils.euclideanDistance(largeVector1, largeVector2);
        expect(distance, greaterThan(0.0));
      });
    });

    group('Manhattan Distance Tests', () {
      test('should calculate Manhattan distance between vectors', () {
        final distance = EmbeddingUtils.manhattanDistance(vector1, vector2);
        expect(distance, greaterThan(0.0));
      });

      test('should handle identical vectors', () {
        final distance = EmbeddingUtils.manhattanDistance(vector1, vector1);
        expect(distance, equals(0.0));
      });

      test('should handle zero vectors', () {
        final distance = EmbeddingUtils.manhattanDistance(zeroVector, zeroVector);
        expect(distance, equals(0.0));
      });

      test('should handle empty vectors', () {
        final distance = EmbeddingUtils.manhattanDistance(emptyVector, emptyVector);
        expect(distance, equals(0.0));
      });

      test('should throw error for different length vectors', () {
        expect(
          () => EmbeddingUtils.manhattanDistance(vector1, [1.0, 2.0]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Vector Normalization Tests', () {
      test('should normalize vector to unit length', () {
        final normalized = EmbeddingUtils.normalizeVector(vector1);
        final magnitude = EmbeddingUtils.vectorMagnitude(normalized);
        expect(magnitude, closeTo(1.0, 0.001));
      });

      test('should handle zero vector', () {
        final normalized = EmbeddingUtils.normalizeVector(zeroVector);
        expect(normalized, equals(zeroVector));
      });

      test('should handle empty vector', () {
        final normalized = EmbeddingUtils.normalizeVector(emptyVector);
        expect(normalized, equals(emptyVector));
      });

      test('should preserve vector direction', () {
        final normalized = EmbeddingUtils.normalizeVector(vector1);
        for (int i = 0; i < vector1.length; i++) {
          if (vector1[i] != 0.0) {
            expect(
              (normalized[i] > 0) == (vector1[i] > 0),
              isTrue,
            );
          }
        }
      });
    });

    group('Vector Magnitude Tests', () {
      test('should calculate vector magnitude', () {
        final magnitude = EmbeddingUtils.vectorMagnitude(vector1);
        expect(magnitude, greaterThan(0.0));
      });

      test('should handle zero vector', () {
        final magnitude = EmbeddingUtils.vectorMagnitude(zeroVector);
        expect(magnitude, equals(0.0));
      });

      test('should handle empty vector', () {
        final magnitude = EmbeddingUtils.vectorMagnitude(emptyVector);
        expect(magnitude, equals(0.0));
      });

      test('should handle small vectors (<=16)', () {
        final smallVector = [3.0, 4.0];
        final magnitude = EmbeddingUtils.vectorMagnitude(smallVector);
        expect(magnitude, equals(5.0));
      });

      test('should handle large vectors (>16)', () {
        final largeVector = List.generate(20, (i) => 1.0);
        final magnitude = EmbeddingUtils.vectorMagnitude(largeVector);
        expect(magnitude, closeTo(sqrt(20.0), 0.001));
      });
    });

    group('Vector Addition Tests', () {
      test('should add two vectors element-wise', () {
        final result = EmbeddingUtils.addVectors(vector1, vector2);
        expect(result.length, equals(vector1.length));
        expect(result[0], equals(3.0)); // 1.0 + 2.0
        expect(result[1], equals(6.0)); // 2.0 + 4.0
      });

      test('should handle zero vectors', () {
        final result = EmbeddingUtils.addVectors(zeroVector, vector1);
        expect(result, equals(vector1));
      });

      test('should throw error for different length vectors', () {
        expect(
          () => EmbeddingUtils.addVectors(vector1, [1.0, 2.0]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle small vectors (<=16)', () {
        final smallVector1 = [1.0, 2.0];
        final smallVector2 = [3.0, 4.0];
        final result = EmbeddingUtils.addVectors(smallVector1, smallVector2);
        expect(result, equals([4.0, 6.0]));
      });

      test('should handle large vectors (>16)', () {
        final largeVector1 = List.generate(20, (i) => i.toDouble());
        final largeVector2 = List.generate(20, (i) => i.toDouble());
        final result = EmbeddingUtils.addVectors(largeVector1, largeVector2);
        expect(result.length, equals(20));
        expect(result[0], equals(0.0));
        expect(result[19], equals(38.0));
      });
    });

    group('Vector Subtraction Tests', () {
      test('should subtract two vectors element-wise', () {
        final result = EmbeddingUtils.subtractVectors(vector2, vector1);
        expect(result.length, equals(vector1.length));
        expect(result[0], equals(1.0)); // 2.0 - 1.0
        expect(result[1], equals(2.0)); // 4.0 - 2.0
      });

      test('should handle zero vectors', () {
        final result = EmbeddingUtils.subtractVectors(vector1, zeroVector);
        expect(result, equals(vector1));
      });

      test('should throw error for different length vectors', () {
        expect(
          () => EmbeddingUtils.subtractVectors(vector1, [1.0, 2.0]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle small vectors (<=16)', () {
        final smallVector1 = [5.0, 6.0];
        final smallVector2 = [1.0, 2.0];
        final result = EmbeddingUtils.subtractVectors(smallVector1, smallVector2);
        expect(result, equals([4.0, 4.0]));
      });

      test('should handle large vectors (>16)', () {
        final largeVector1 = List.generate(20, (i) => (i + 10).toDouble());
        final largeVector2 = List.generate(20, (i) => i.toDouble());
        final result = EmbeddingUtils.subtractVectors(largeVector1, largeVector2);
        expect(result.length, equals(20));
        expect(result[0], equals(10.0));
        expect(result[19], equals(10.0));
      });
    });

    group('Scalar Multiplication Tests', () {
      test('should multiply vector by scalar', () {
        final result = EmbeddingUtils.multiplyVectorByScalar(vector1, 2.0);
        expect(result.length, equals(vector1.length));
        expect(result[0], equals(2.0)); // 1.0 * 2.0
        expect(result[1], equals(4.0)); // 2.0 * 2.0
      });

      test('should handle zero scalar', () {
        final result = EmbeddingUtils.multiplyVectorByScalar(vector1, 0.0);
        expect(result.every((x) => x == 0.0), isTrue);
      });

      test('should handle negative scalar', () {
        final result = EmbeddingUtils.multiplyVectorByScalar(vector1, -1.0);
        expect(result[0], equals(-1.0));
        expect(result[1], equals(-2.0));
      });

      test('should handle small vectors (<=16)', () {
        final smallVector = [1.0, 2.0, 3.0];
        final result = EmbeddingUtils.multiplyVectorByScalar(smallVector, 3.0);
        expect(result, equals([3.0, 6.0, 9.0]));
      });

      test('should handle large vectors (>16)', () {
        final largeVector = List.generate(20, (i) => i.toDouble());
        final result = EmbeddingUtils.multiplyVectorByScalar(largeVector, 2.0);
        expect(result.length, equals(20));
        expect(result[0], equals(0.0));
        expect(result[19], equals(38.0));
      });
    });

    group('Vector Averaging Tests', () {
      test('should calculate average of multiple vectors', () {
        final vectors = [vector1, vector2, vector3];
        final average = EmbeddingUtils.averageVectors(vectors);
        expect(average.length, equals(vector1.length));
        expect(average[0], closeTo(1.17, 0.01)); // (1.0 + 2.0 + 0.5) / 3
      });

      test('should handle single vector', () {
        final average = EmbeddingUtils.averageVectors([vector1]);
        expect(average, equals(vector1));
      });

      test('should handle empty list', () {
        final average = EmbeddingUtils.averageVectors([]);
        expect(average, isEmpty);
      });

      test('should throw error for different length vectors', () {
        expect(
          () => EmbeddingUtils.averageVectors([vector1, [1.0, 2.0]]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Similarity Finding Tests', () {
      test('should find most similar vector', () {
        final candidates = [vector2, vector3];
        final index = EmbeddingUtils.findMostSimilar(vector1, candidates);
        expect(index, equals(0)); // vector2 should be more similar
      });

      test('should handle empty candidates list', () {
        final index = EmbeddingUtils.findMostSimilar(vector1, []);
        expect(index, equals(-1));
      });

      test('should use custom similarity function', () {
        final candidates = [vector2, vector3];
        final index = EmbeddingUtils.findMostSimilar(
          vector1,
          candidates,
          similarityFunction: (a, b) => EmbeddingUtils.cosineSimilarity(a, b),
        );
        expect(index, isA<int>());
        expect(index, greaterThanOrEqualTo(0));
        expect(index, lessThan(candidates.length));
      });
    });

    group('Matrix Conversion Tests', () {
      test('should convert vectors to matrix', () {
        final vectors = [vector1, vector2, vector3];
        final matrix = EmbeddingUtils.vectorsToMatrix(vectors);
        expect(matrix, equals(vectors));
      });

      test('should convert matrix to vectors', () {
        final matrix = [vector1, vector2, vector3];
        final vectors = EmbeddingUtils.matrixToVectors(matrix);
        expect(vectors, equals(matrix));
      });

      test('should handle empty lists', () {
        expect(EmbeddingUtils.vectorsToMatrix([]), isEmpty);
        expect(EmbeddingUtils.matrixToVectors([]), isEmpty);
      });
    });

    group('Vector Equality Tests', () {
      test('should detect equal vectors', () {
        final result = EmbeddingUtils.vectorsAreEqual(vector1, vector1);
        expect(result, isTrue);
      });

      test('should detect different vectors', () {
        final result = EmbeddingUtils.vectorsAreEqual(vector1, vector2);
        expect(result, isFalse);
      });

      test('should handle different length vectors', () {
        final result = EmbeddingUtils.vectorsAreEqual(vector1, [1.0, 2.0]);
        expect(result, isFalse);
      });

      test('should handle tolerance', () {
        final nearlyEqual = [1.0, 2.0, 3.0, 4.0000000001];
        final result = EmbeddingUtils.vectorsAreEqual(vector1, nearlyEqual, tolerance: 1e-9);
        expect(result, isTrue);
      });
    });

    group('Random Vector Generation Tests', () {
      test('should generate random vector with specified dimension', () {
        final randomVector = EmbeddingUtils.generateRandomVector(4);
        expect(randomVector.length, equals(4));
        expect(randomVector.every((x) => x >= -1.0 && x <= 1.0), isTrue);
      });

      test('should use provided random number generator', () {
        final random1 = Random(42); // Fixed seed for deterministic test
        final random2 = Random(42); // Same seed, different instance
        
        final randomVector1 = EmbeddingUtils.generateRandomVector(4, random: random1);
        final randomVector2 = EmbeddingUtils.generateRandomVector(4, random: random2);
        
        // Same seed should produce same sequence of random numbers
        expect(randomVector1, equals(randomVector2));
      });

      test('should handle zero dimension', () {
        final randomVector = EmbeddingUtils.generateRandomVector(0);
        expect(randomVector, isEmpty);
      });
    });

    group('Dot Product Tests', () {
      test('should calculate dot product', () {
        final result = EmbeddingUtils.dotProduct(vector1, vector2);
        expect(result, equals(60.0)); // 1*2 + 2*4 + 3*6 + 4*8
      });

      test('should handle zero vectors', () {
        final result = EmbeddingUtils.dotProduct(zeroVector, zeroVector);
        expect(result, equals(0.0));
      });

      test('should handle empty vectors', () {
        final result = EmbeddingUtils.dotProduct(emptyVector, emptyVector);
        expect(result, equals(0.0));
      });

      test('should throw error for different length vectors', () {
        expect(
          () => EmbeddingUtils.dotProduct(vector1, [1.0, 2.0]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Batch Similarity Tests', () {
      test('should calculate batch cosine similarity', () {
        final candidates = [vector2, vector3];
        final similarities = EmbeddingUtils.batchCosineSimilarity(vector1, candidates);
        expect(similarities.length, equals(2));
        expect(similarities.every((s) => s >= -1.0 && s <= 1.0), isTrue);
      });

      test('should handle zero magnitude vectors in batch cosine similarity', () {
        // Create a zero vector to test the else branch
        final zeroCandidate = List.filled(4, 0.0);
        final candidates = [vector2, zeroCandidate, vector3];
        final similarities = EmbeddingUtils.batchCosineSimilarity(vector1, candidates);
        expect(similarities.length, equals(3));
        // The zero vector should result in 0.0 similarity
        expect(similarities[1], equals(0.0));
        expect(similarities.every((s) => s >= -1.0 && s <= 1.0), isTrue);
      });

      test('should handle empty candidates list', () {
        final similarities = EmbeddingUtils.batchCosineSimilarity(vector1, []);
        expect(similarities, isEmpty);
      });

      test('should handle zero query vector', () {
        final similarities = EmbeddingUtils.batchCosineSimilarity(zeroVector, [vector1, vector2]);
        expect(similarities.every((s) => s == 0.0), isTrue);
      });

      test('should calculate batch Euclidean distance', () {
        final candidates = [vector2, vector3];
        final distances = EmbeddingUtils.batchEuclideanDistance(vector1, candidates);
        expect(distances.length, equals(2));
        expect(distances.every((d) => d >= 0.0), isTrue);
      });

      test('should handle empty candidates list for Euclidean distance', () {
        final distances = EmbeddingUtils.batchEuclideanDistance(vector1, []);
        expect(distances, isEmpty);
      });

      test('should handle large vectors with optimized processing', () {
        // Create large vectors to test chunked processing paths
        final largeVector1 = List.generate(20, (i) => (i + 1) * 1.0);
        final largeVector2 = List.generate(20, (i) => (i + 1) * 2.0);
        
        // Test optimized dot product with large vectors
        final dotProduct = EmbeddingUtils.dotProduct(largeVector1, largeVector2);
        expect(dotProduct, greaterThan(0));
        
        // Test optimized magnitude with large vectors
        final magnitude1 = EmbeddingUtils.vectorMagnitude(largeVector1);
        final magnitude2 = EmbeddingUtils.vectorMagnitude(largeVector2);
        expect(magnitude1, greaterThan(0));
        expect(magnitude2, greaterThan(0));
      });

      test('should handle very large vectors with chunked processing', () {
        // Create very large vectors to ensure chunked processing is used
        final veryLargeVector1 = List.generate(25, (i) => (i + 1) * 1.0);
        final veryLargeVector2 = List.generate(25, (i) => (i + 1) * 2.0);
        
        // Test optimized dot product with very large vectors (>16)
        final dotProduct = EmbeddingUtils.dotProduct(veryLargeVector1, veryLargeVector2);
        expect(dotProduct, greaterThan(0));
        
        // Test optimized magnitude with very large vectors (>16)
        final magnitude1 = EmbeddingUtils.vectorMagnitude(veryLargeVector1);
        final magnitude2 = EmbeddingUtils.vectorMagnitude(veryLargeVector2);
        expect(magnitude1, greaterThan(0));
        expect(magnitude2, greaterThan(0));
      });
    });

    group('Top-K Similarity Tests', () {
      test('should find top-k most similar vectors', () {
        final candidates = [vector2, vector3, vector1];
        final topK = EmbeddingUtils.findTopKSimilar(vector1, candidates, 2);
        expect(topK.length, equals(2));
        expect(topK[0].value, greaterThanOrEqualTo(topK[1].value));
      });

      test('should handle k greater than candidates count', () {
        final candidates = [vector2, vector3];
        final topK = EmbeddingUtils.findTopKSimilar(vector1, candidates, 5);
        expect(topK.length, equals(2));
      });

      test('should handle empty candidates list', () {
        final topK = EmbeddingUtils.findTopKSimilar(vector1, [], 3);
        expect(topK, isEmpty);
      });

      test('should handle k <= 0', () {
        final candidates = [vector2, vector3];
        final topK = EmbeddingUtils.findTopKSimilar(vector1, candidates, 0);
        expect(topK, isEmpty);
      });

      test('should use custom similarity function', () {
        final candidates = [vector2, vector3];
        final topK = EmbeddingUtils.findTopKSimilar(
          vector1,
          candidates,
          2,
          similarityFunction: (a, b) => 1.0 - EmbeddingUtils.euclideanDistance(a, b),
        );
        expect(topK.length, equals(2));
      });
    });

    group('Cache Management Tests', () {
      test('should clear cache', () {
        // First, generate some vectors to populate cache
        EmbeddingUtils.generateRandomVector(100);
        EmbeddingUtils.generateRandomVector(100);
        
        EmbeddingUtils.clearCache();
        final stats = EmbeddingUtils.getCacheStats();
        expect(stats['cache_size'], equals(0));
      });

      test('should return cache statistics', () {
        final stats = EmbeddingUtils.getCacheStats();
        expect(stats['cache_size'], isA<int>());
        expect(stats['max_cache_size'], equals(1000));
        expect(stats['cache_hit_ratio'], equals('N/A'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle very large vectors', () {
        final largeVector = List.generate(1000, (i) => i.toDouble());
        final result = EmbeddingUtils.vectorMagnitude(largeVector);
        expect(result, greaterThan(0.0));
      });

      test('should handle vectors with very small values', () {
        final smallVector = [1e-10, 2e-10, 3e-10];
        final result = EmbeddingUtils.vectorMagnitude(smallVector);
        expect(result, greaterThan(0.0));
      });

      test('should handle vectors with very large values', () {
        final largeVector = [1e10, 2e10, 3e10];
        final result = EmbeddingUtils.vectorMagnitude(largeVector);
        expect(result, greaterThan(0.0));
      });

      test('should handle negative values in vectors', () {
        final negativeVector = [-1.0, -2.0, -3.0];
        final result = EmbeddingUtils.vectorMagnitude(negativeVector);
        expect(result, greaterThan(0.0));
      });
    });
  });
}
