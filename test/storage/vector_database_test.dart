import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('VectorDatabase Core Logic', () {
    late Logger testLogger;

    setUp(() {
      testLogger = Logger(level: Level.error); // Minimal logging for tests
    });

    group('VectorData and SearchResult', () {
      test('should create VectorData with all fields', () {
        final vector = VectorData(
          id: 'test_id',
          chunkId: 'chunk_id',
          embedding: [1.0, 2.0, 3.0],
          metadata: {'key': 'value'},
        );

        expect(vector.id, equals('test_id'));
        expect(vector.chunkId, equals('chunk_id'));
        expect(vector.embedding, equals([1.0, 2.0, 3.0]));
        expect(vector.metadata, equals({'key': 'value'}));
      });

      test('should create SearchResult with all fields', () {
        final result = SearchResult(
          id: 'result_id',
          chunkId: 'chunk_id',
          score: 0.85,
        );

        expect(result.id, equals('result_id'));
        expect(result.chunkId, equals('chunk_id'));
        expect(result.score, equals(0.85));
      });

      test('should handle VectorData with empty metadata', () {
        final vector = VectorData(
          id: 'test_id',
          chunkId: 'chunk_id',
          embedding: [1.0, 2.0, 3.0],
        );

        expect(vector.metadata, isEmpty);
      });

      test('should handle SearchResult with basic fields', () {
        final result = SearchResult(
          id: 'result_id',
          chunkId: 'chunk_id',
          score: 0.85,
        );

        expect(result.id, equals('result_id'));
        expect(result.chunkId, equals('chunk_id'));
        expect(result.score, equals(0.85));
      });
    });

    group('Vector Database Configuration', () {
      test('should parse database type from URL correctly', () {
        final faissDb = VectorDatabase(
          vectorDbUrl: 'faiss:///path',
          logger: testLogger,
        );
        final chromaDb = VectorDatabase(
          vectorDbUrl: 'chroma://localhost:8000',
          logger: testLogger,
        );
        final memoryDb = VectorDatabase(
          vectorDbUrl: 'memory://',
          logger: testLogger,
        );
        final localDb = VectorDatabase(
          vectorDbUrl: '/local/path',
          logger: testLogger,
        );

        expect(faissDb.dbType, equals('faiss'));
        expect(chromaDb.dbType, equals('chroma'));
        expect(memoryDb.dbType, equals('memory'));
        expect(localDb.dbType, equals('faiss')); // Default for local paths
      });

      test('should parse connection string from URL correctly', () {
        final faissDb = VectorDatabase(
          vectorDbUrl: 'faiss:///path',
          logger: testLogger,
        );
        final chromaDb = VectorDatabase(
          vectorDbUrl: 'chroma://localhost:8000',
          logger: testLogger,
        );
        final memoryDb = VectorDatabase(
          vectorDbUrl: 'memory://',
          logger: testLogger,
        );
        final localDb = VectorDatabase(
          vectorDbUrl: '/local/path',
          logger: testLogger,
        );

        expect(faissDb.connectionString, equals('/path'));
        expect(
          chromaDb.connectionString,
          equals('localhost'),
        ); // Only host part
        expect(memoryDb.connectionString, equals('memory'));
        expect(localDb.connectionString, equals('/local/path'));
      });

      test('should create with default configuration', () {
        final vectorDb = VectorDatabase(
          vectorDbUrl: 'memory://',
          logger: testLogger,
        );

        expect(vectorDb.config['dimension'], equals(384));
        expect(vectorDb.config['metric'], equals('cosine'));
        expect(vectorDb.config['index_type'], equals('ivf'));
        expect(vectorDb.config['nlist'], equals(100));
        expect(vectorDb.config['nprobe'], equals(10));
        expect(vectorDb.config['use_gpu'], equals(false));
      });

      test('should create with custom configuration', () {
        final vectorDb = VectorDatabase(
          vectorDbUrl: 'memory://',
          logger: testLogger,
          config: {
            'dimension': 512,
            'metric': 'euclidean',
            'index_type': 'flat',
            'nlist': 200,
            'nprobe': 20,
            'use_gpu': true,
          },
        );

        expect(vectorDb.config['dimension'], equals(512));
        expect(vectorDb.config['metric'], equals('euclidean'));
        expect(vectorDb.config['index_type'], equals('flat'));
        expect(vectorDb.config['nlist'], equals(200));
        expect(vectorDb.config['nprobe'], equals(20));
        expect(vectorDb.config['use_gpu'], equals(true));
      });
    });

    group('Vector Similarity Calculations', () {
      test('should calculate cosine similarity correctly', () {
        final vector1 = [1.0, 0.0, 0.0];
        final vector2 = [1.0, 0.0, 0.0];
        final vector3 = [0.0, 1.0, 0.0];
        final vector4 = [0.0, 0.0, 0.0];

        // Identical vectors should have similarity = 1.0
        expect(
          _calculateCosineSimilarity(vector1, vector2),
          closeTo(1.0, 0.001),
        );

        // Orthogonal vectors should have similarity = 0.0
        expect(
          _calculateCosineSimilarity(vector1, vector3),
          closeTo(0.0, 0.001),
        );

        // Zero vector should have similarity = 0.0
        expect(
          _calculateCosineSimilarity(vector1, vector4),
          closeTo(0.0, 0.001),
        );
      });

      test('should calculate euclidean similarity correctly', () {
        final vector1 = [1.0, 0.0, 0.0];
        final vector2 = [1.0, 0.0, 0.0];
        final vector3 = [2.0, 0.0, 0.0];

        // Identical vectors should have similarity = 1.0
        expect(
          _calculateEuclideanSimilarity(vector1, vector2),
          closeTo(1.0, 0.001),
        );

        // Different vectors should have similarity < 1.0
        expect(_calculateEuclideanSimilarity(vector1, vector3), lessThan(1.0));
        expect(
          _calculateEuclideanSimilarity(vector1, vector3),
          greaterThan(0.0),
        );
      });

      test('should calculate dot product similarity correctly', () {
        final vector1 = [1.0, 2.0, 3.0];
        final vector2 = [1.0, 2.0, 3.0];
        final vector3 = [0.0, 0.0, 0.0];

        // Identical vectors should have positive dot product
        expect(
          _calculateDotProductSimilarity(vector1, vector2),
          greaterThan(0.0),
        );

        // Zero vector should have dot product = 0.0
        expect(_calculateDotProductSimilarity(vector1, vector3), equals(0.0));
      });
    });

    group('Vector Normalization', () {
      test('should normalize vectors correctly', () {
        final vector = [3.0, 4.0, 0.0]; // Magnitude = 5.0
        final normalized = _normalizeVector(vector);

        // Check magnitude is approximately 1.0
        final magnitude = sqrt(
          normalized.map((x) => x * x).reduce((a, b) => a + b),
        );
        expect(magnitude, closeTo(1.0, 0.001));

        // Check direction is preserved
        expect(normalized[0], closeTo(0.6, 0.001)); // 3/5
        expect(normalized[1], closeTo(0.8, 0.001)); // 4/5
        expect(normalized[2], closeTo(0.0, 0.001)); // 0/5
      });

      test('should handle zero vector normalization', () {
        final vector = [0.0, 0.0, 0.0];
        final normalized = _normalizeVector(vector);

        // Zero vector should remain unchanged
        expect(normalized, equals([0.0, 0.0, 0.0]));
      });

      test('should handle single element vector normalization', () {
        final vector = [5.0];
        final normalized = _normalizeVector(vector);

        expect(normalized, equals([1.0]));
      });
    });

    group('Vector Generation', () {
      test('should generate vectors with correct dimensions', () {
        final dimensions = [1, 10, 100, 1000];

        for (final dim in dimensions) {
          final vector = _generateMockEmbedding(dim);
          expect(vector.length, equals(dim));
        }
      });

      test('should generate normalized vectors', () {
        final vector = _generateMockEmbedding(100);

        // Check magnitude is approximately 1.0
        final magnitude = sqrt(
          vector.map((x) => x * x).reduce((a, b) => a + b),
        );
        expect(magnitude, closeTo(1.0, 0.001));
      });

      test('should generate different vectors on each call', () {
        final vector1 = _generateMockEmbedding(10);
        final vector2 = _generateMockEmbedding(10);

        // Vectors should be different (not identical)
        expect(vector1, isNot(equals(vector2)));
      });
    });

    group('Error Handling', () {
      test('should handle unsupported database type', () {
        final vectorDb = VectorDatabase(
          vectorDbUrl: 'unsupported://test',
          logger: testLogger,
        );

        expect(
          vectorDb.dbType,
          equals('faiss'),
        ); // Defaults to faiss for unsupported schemes
        expect(vectorDb.connectionString, equals('test')); // Only host part
      });

      test('should handle empty URL gracefully', () {
        final vectorDb = VectorDatabase(vectorDbUrl: '', logger: testLogger);

        expect(vectorDb.dbType, equals('faiss')); // Default
        expect(vectorDb.connectionString, equals(''));
      });
    });

    group('Performance Metrics', () {
      test('should initialize metrics correctly', () {
        final vectorDb = VectorDatabase(
          vectorDbUrl: 'memory://',
          logger: testLogger,
        );

        final stats = vectorDb.getStats();
        final metrics = stats['metrics'] as Map<String, dynamic>;

        expect(metrics['total_searches'], equals(0));
        expect(metrics['total_inserts'], equals(0));
        expect(metrics['total_updates'], equals(0));
        expect(metrics['total_deletes'], equals(0));
        expect(metrics['average_search_time'], equals(0.0));
        expect(metrics['average_insert_time'], equals(0.0));
      });

      test('should provide comprehensive statistics structure', () {
        final vectorDb = VectorDatabase(
          vectorDbUrl: 'memory://',
          logger: testLogger,
        );

        final stats = vectorDb.getStats();

        expect(stats, contains('db_type'));
        expect(stats, contains('is_initialized'));
        expect(stats, contains('is_closed'));
        expect(stats, contains('total_vectors'));
        expect(stats, contains('dimension'));
        expect(stats, contains('config'));
        expect(stats, contains('metrics'));
      });
    });
  });
}

/// Helper function to calculate cosine similarity
double _calculateCosineSimilarity(List<double> vector1, List<double> vector2) {
  double dotProduct = 0.0;
  double norm1 = 0.0;
  double norm2 = 0.0;

  for (int i = 0; i < vector1.length; i++) {
    dotProduct += vector1[i] * vector2[i];
    norm1 += vector1[i] * vector1[i];
    norm2 += vector2[i] * vector2[i];
  }

  if (norm1 == 0.0 || norm2 == 0.0) return 0.0;

  return dotProduct / (sqrt(norm1) * sqrt(norm2));
}

/// Helper function to calculate euclidean similarity
double _calculateEuclideanSimilarity(
  List<double> vector1,
  List<double> vector2,
) {
  double sumSquares = 0.0;

  for (int i = 0; i < vector1.length; i++) {
    final diff = vector1[i] - vector2[i];
    sumSquares += diff * diff;
  }

  final distance = sqrt(sumSquares);
  return 1.0 / (1.0 + distance);
}

/// Helper function to calculate dot product similarity
double _calculateDotProductSimilarity(
  List<double> vector1,
  List<double> vector2,
) {
  double dotProduct = 0.0;

  for (int i = 0; i < vector1.length; i++) {
    dotProduct += vector1[i] * vector2[i];
  }

  return dotProduct;
}

/// Helper function to normalize a vector
List<double> _normalizeVector(List<double> vector) {
  final magnitude = sqrt(vector.map((x) => x * x).reduce((a, b) => a + b));
  if (magnitude == 0.0) return List<double>.from(vector);

  return vector.map((x) => x / magnitude).toList();
}

/// Helper function to generate mock embeddings for testing
List<double> _generateMockEmbedding(int dimension) {
  final random = Random();
  final vector = List.generate(dimension, (i) => random.nextDouble() * 2 - 1);

  // Normalize the vector
  final magnitude = sqrt(vector.map((x) => x * x).reduce((a, b) => a + b));
  if (magnitude > 0) {
    for (int i = 0; i < vector.length; i++) {
      vector[i] = vector[i] / magnitude;
    }
  }

  return vector;
}
