import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/utils/embedding_utils.dart';

void main() {
  group('EmbeddingUtils Tests', () {
    group('Cosine Similarity Tests', () {
      test('should calculate cosine similarity between identical vectors', () {
        final vector1 = [1.0, 0.0, 0.0];
        final vector2 = [1.0, 0.0, 0.0];
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, closeTo(1.0, 0.001));
      });

      test('should calculate cosine similarity between orthogonal vectors', () {
        final vector1 = [1.0, 0.0, 0.0];
        final vector2 = [0.0, 1.0, 0.0];
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, closeTo(0.0, 0.001));
      });

      test('should calculate cosine similarity between opposite vectors', () {
        final vector1 = [1.0, 0.0, 0.0];
        final vector2 = [-1.0, 0.0, 0.0];
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, closeTo(-1.0, 0.001));
      });

      test('should calculate cosine similarity between similar vectors', () {
        final vector1 = [1.0, 2.0, 3.0];
        final vector2 = [2.0, 4.0, 6.0];
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, closeTo(1.0, 0.001));
      });

      test('should handle empty vectors', () {
        final similarity = EmbeddingUtils.cosineSimilarity([], []);
        expect(similarity, equals(0.0));
      });

      test('should throw error for vectors of different lengths', () {
        expect(
          () => EmbeddingUtils.cosineSimilarity([1.0, 2.0], [1.0, 2.0, 3.0]),
          throwsArgumentError,
        );
      });

      test('should handle zero vectors', () {
        final vector1 = [0.0, 0.0, 0.0];
        final vector2 = [1.0, 2.0, 3.0];
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, equals(0.0));
      });
    });

    group('Euclidean Distance Tests', () {
      test('should calculate distance between identical vectors', () {
        final vector1 = [1.0, 2.0, 3.0];
        final vector2 = [1.0, 2.0, 3.0];
        final distance = EmbeddingUtils.euclideanDistance(vector1, vector2);
        expect(distance, closeTo(0.0, 0.001));
      });

      test('should calculate distance between different vectors', () {
        final vector1 = [0.0, 0.0, 0.0];
        final vector2 = [3.0, 4.0, 0.0];
        final distance = EmbeddingUtils.euclideanDistance(vector1, vector2);
        expect(distance, closeTo(5.0, 0.001)); // sqrt(3² + 4²) = 5
      });

      test('should calculate distance between unit vectors', () {
        final vector1 = [1.0, 0.0, 0.0];
        final vector2 = [0.0, 1.0, 0.0];
        final distance = EmbeddingUtils.euclideanDistance(vector1, vector2);
        expect(distance, closeTo(1.414, 0.001)); // sqrt(2) ≈ 1.414
      });

      test('should handle empty vectors', () {
        final distance = EmbeddingUtils.euclideanDistance([], []);
        expect(distance, equals(0.0));
      });

      test('should throw error for vectors of different lengths', () {
        expect(
          () => EmbeddingUtils.euclideanDistance([1.0, 2.0], [1.0, 2.0, 3.0]),
          throwsArgumentError,
        );
      });

      test('should handle small vectors (≤16 elements)', () {
        final vector1 = List.generate(10, (i) => i.toDouble());
        final vector2 = List.generate(10, (i) => (i + 1).toDouble());
        final distance = EmbeddingUtils.euclideanDistance(vector1, vector2);
        expect(distance, greaterThan(0.0));
      });

      test('should handle large vectors (>16 elements)', () {
        final vector1 = List.generate(20, (i) => i.toDouble());
        final vector2 = List.generate(20, (i) => (i + 1).toDouble());
        final distance = EmbeddingUtils.euclideanDistance(vector1, vector2);
        expect(distance, greaterThan(0.0));
      });
    });

    group('Manhattan Distance Tests', () {
      test('should calculate distance between identical vectors', () {
        final vector1 = [1.0, 2.0, 3.0];
        final vector2 = [1.0, 2.0, 3.0];
        final distance = EmbeddingUtils.manhattanDistance(vector1, vector2);
        expect(distance, equals(0.0));
      });

      test('should calculate distance between different vectors', () {
        final vector1 = [0.0, 0.0, 0.0];
        final vector2 = [3.0, 4.0, 5.0];
        final distance = EmbeddingUtils.manhattanDistance(vector1, vector2);
        expect(distance, equals(12.0)); // |3| + |4| + |5| = 12
      });

      test('should handle negative values', () {
        final vector1 = [1.0, -2.0, 3.0];
        final vector2 = [-1.0, 2.0, -3.0];
        final distance = EmbeddingUtils.manhattanDistance(vector1, vector2);
        expect(distance, equals(12.0)); // |2| + |4| + |6| = 12
      });

      test('should handle empty vectors', () {
        final distance = EmbeddingUtils.manhattanDistance([], []);
        expect(distance, equals(0.0));
      });

      test('should throw error for vectors of different lengths', () {
        expect(
          () => EmbeddingUtils.manhattanDistance([1.0, 2.0], [1.0, 2.0, 3.0]),
          throwsArgumentError,
        );
      });
    });

    group('Vector Normalization Tests', () {
      test('should normalize unit vector', () {
        final vector = [1.0, 0.0, 0.0];
        final normalized = EmbeddingUtils.normalizeVector(vector);
        expect(normalized.length, equals(vector.length));
        expect(normalized[0], closeTo(1.0, 0.001));
        expect(normalized[1], closeTo(0.0, 0.001));
        expect(normalized[2], closeTo(0.0, 0.001));
      });

      test('should normalize non-unit vector', () {
        final vector = [3.0, 4.0, 0.0];
        final normalized = EmbeddingUtils.normalizeVector(vector);
        final magnitude = EmbeddingUtils.vectorMagnitude(normalized);
        expect(magnitude, closeTo(1.0, 0.001));
      });

      test('should handle zero vector', () {
        final vector = [0.0, 0.0, 0.0];
        final normalized = EmbeddingUtils.normalizeVector(vector);
        expect(normalized, equals(vector));
      });

      test('should handle empty vector', () {
        final vector = <double>[];
        final normalized = EmbeddingUtils.normalizeVector(vector);
        expect(normalized, equals(vector));
      });

      test('should preserve vector length', () {
        final vector = [1.0, 2.0, 3.0];
        final normalized = EmbeddingUtils.normalizeVector(vector);
        expect(normalized.length, equals(vector.length));
      });
    });

    group('Vector Magnitude Tests', () {
      test('should calculate magnitude of unit vector', () {
        final vector = [1.0, 0.0, 0.0];
        final magnitude = EmbeddingUtils.vectorMagnitude(vector);
        expect(magnitude, closeTo(1.0, 0.001));
      });

      test('should calculate magnitude of non-unit vector', () {
        final vector = [3.0, 4.0, 0.0];
        final magnitude = EmbeddingUtils.vectorMagnitude(vector);
        expect(magnitude, closeTo(5.0, 0.001)); // sqrt(3² + 4²) = 5
      });

      test('should calculate magnitude of 3D vector', () {
        final vector = [1.0, 2.0, 2.0];
        final magnitude = EmbeddingUtils.vectorMagnitude(vector);
        expect(magnitude, closeTo(3.0, 0.001)); // sqrt(1² + 2² + 2²) = 3
      });

      test('should handle zero vector', () {
        final vector = [0.0, 0.0, 0.0];
        final magnitude = EmbeddingUtils.vectorMagnitude(vector);
        expect(magnitude, equals(0.0));
      });

      test('should handle empty vector', () {
        final vector = <double>[];
        final magnitude = EmbeddingUtils.vectorMagnitude(vector);
        expect(magnitude, equals(0.0));
      });

      test('should handle negative values', () {
        final vector = [-3.0, -4.0, 0.0];
        final magnitude = EmbeddingUtils.vectorMagnitude(vector);
        expect(magnitude, closeTo(5.0, 0.001)); // sqrt((-3)² + (-4)²) = 5
      });
    });

    group('Vector Operations Tests', () {
      test('should add vectors element-wise', () {
        final vector1 = [1.0, 2.0, 3.0];
        final vector2 = [4.0, 5.0, 6.0];
        final result = EmbeddingUtils.addVectors(vector1, vector2);
        expect(result, equals([5.0, 7.0, 9.0]));
      });

      test('should subtract vectors element-wise', () {
        final vector1 = [4.0, 5.0, 6.0];
        final vector2 = [1.0, 2.0, 3.0];
        final result = EmbeddingUtils.subtractVectors(vector1, vector2);
        expect(result, equals([3.0, 3.0, 3.0]));
      });

      test('should multiply vector by scalar', () {
        final vector = [1.0, 2.0, 3.0];
        final result = EmbeddingUtils.multiplyVectorByScalar(vector, 2.0);
        expect(result, equals([2.0, 4.0, 6.0]));
      });

      test('should handle empty vectors in operations', () {
        expect(() => EmbeddingUtils.addVectors([], []), returnsNormally);
        expect(() => EmbeddingUtils.subtractVectors([], []), returnsNormally);
        expect(() => EmbeddingUtils.multiplyVectorByScalar([], 2.0), returnsNormally);
      });

      test('should throw error for vectors of different lengths in operations', () {
        expect(
          () => EmbeddingUtils.addVectors([1.0, 2.0], [1.0]),
          throwsArgumentError,
        );
        expect(
          () => EmbeddingUtils.subtractVectors([1.0, 2.0], [1.0]),
          throwsArgumentError,
        );
      });
    });

    group('Edge Case Tests', () {
      test('should handle very small vectors', () {
        final vector1 = [0.001];
        final vector2 = [0.002];
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, closeTo(1.0, 0.001));
      });

      test('should handle very large vectors', () {
        final vector1 = List.generate(1000, (i) => i.toDouble());
        final vector2 = List.generate(1000, (i) => (i + 1).toDouble());
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, greaterThan(0.0));
        expect(similarity, lessThan(1.0));
      });

      test('should handle mixed positive and negative values', () {
        final vector1 = [1.0, -1.0, 1.0, -1.0];
        final vector2 = [-1.0, 1.0, -1.0, 1.0];
        final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
        expect(similarity, closeTo(-1.0, 0.001));
      });
    });

    group('Performance Tests', () {
      test('should handle multiple operations efficiently', () {
        final vector1 = List.generate(100, (i) => i.toDouble());
        final vector2 = List.generate(100, (i) => (i + 1).toDouble());
        
        // Perform multiple operations to test performance
        for (int i = 0; i < 10; i++) {
          final similarity = EmbeddingUtils.cosineSimilarity(vector1, vector2);
          final distance = EmbeddingUtils.euclideanDistance(vector1, vector2);
          final manhattan = EmbeddingUtils.manhattanDistance(vector1, vector2);
          
          expect(similarity, greaterThan(-1.0));
          expect(similarity, lessThan(1.0));
          expect(distance, greaterThan(0.0));
          expect(manhattan, greaterThan(0.0));
        }
      });
    });
  });
}
