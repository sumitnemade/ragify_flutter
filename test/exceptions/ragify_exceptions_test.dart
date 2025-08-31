import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('Ragify Exceptions Tests', () {
    group('RagifyException', () {
      test('creation with message', () {
        final exception = RagifyException('Test error message');
        expect(exception.message, equals('Test error message'));
        expect(exception.code, isNull);
        expect(exception.details, isNull);
        expect(exception.toString(), contains('Test error message'));
      });

      test('creation with message and code', () {
        final exception = RagifyException(
          'Test error message',
          code: 'TEST_ERROR',
        );
        expect(exception.message, equals('Test error message'));
        expect(exception.code, equals('TEST_ERROR'));
        expect(exception.details, isNull);
        expect(exception.toString(), contains('TEST_ERROR'));
      });

      test('creation with message, code, and details', () {
        final details = {'key': 'value', 'code': 123};
        final exception = RagifyException(
          'Test error message',
          code: 'TEST_ERROR',
          details: details,
        );
        expect(exception.message, equals('Test error message'));
        expect(exception.code, equals('TEST_ERROR'));
        expect(exception.details, equals(details));
      });
    });

    group('ContextNotFoundException', () {
      test('creation with query', () {
        final exception = ContextNotFoundException('test query');
        expect(exception.query, equals('test query'));
        expect(exception.userId, isNull);
        expect(
          exception.message,
          equals('Context not found for query: test query'),
        );
        expect(exception.code, equals('CONTEXT_NOT_FOUND'));
        expect(exception.toString(), contains('test query'));
      });

      test('creation with query and userId', () {
        final exception = ContextNotFoundException(
          'test query',
          userId: 'user123',
        );
        expect(exception.query, equals('test query'));
        expect(exception.userId, equals('user123'));
        expect(exception.toString(), contains('user123'));
      });
    });

    group('ConfigurationException', () {
      test('creation with field and value', () {
        final exception = ConfigurationException(
          'vector_db_url',
          'invalid_url',
        );
        expect(exception.field, equals('vector_db_url'));
        expect(exception.value, equals('invalid_url'));
        expect(
          exception.message,
          equals(
            'Configuration error for field "vector_db_url" with value "invalid_url"',
          ),
        );
        expect(exception.code, equals('CONFIGURATION_ERROR'));
        expect(exception.toString(), contains('vector_db_url'));
        expect(exception.toString(), contains('invalid_url'));
      });
    });

    group('PrivacyViolationException', () {
      test('creation with operation, requiredLevel, and actualLevel', () {
        final exception = PrivacyViolationException(
          'data_access',
          'enterprise',
          'public',
        );
        expect(exception.operation, equals('data_access'));
        expect(exception.requiredLevel, equals('enterprise'));
        expect(exception.actualLevel, equals('public'));
        expect(
          exception.message,
          equals(
            'Privacy violation in data_access: required enterprise, got public',
          ),
        );
        expect(exception.code, equals('PRIVACY_VIOLATION'));
        expect(exception.toString(), contains('data_access'));
        expect(exception.toString(), contains('enterprise'));
        expect(exception.toString(), contains('public'));
      });
    });

    group('SourceConnectionException', () {
      test('creation with sourceName and sourceType', () {
        final exception = SourceConnectionException(
          'database_source',
          'postgresql',
        );
        expect(exception.sourceName, equals('database_source'));
        expect(exception.sourceType, equals('postgresql'));
        expect(
          exception.message,
          equals('Failed to connect to postgresql source: database_source'),
        );
        expect(exception.code, equals('SOURCE_CONNECTION_ERROR'));
        expect(exception.toString(), contains('database_source'));
        expect(exception.toString(), contains('postgresql'));
      });
    });

    group('VectorDatabaseException', () {
      test('creation with operation', () {
        final exception = VectorDatabaseException('search');
        expect(exception.operation, equals('search'));
        expect(exception.databaseType, isNull);
        expect(exception.message, equals('Vector database error in search'));
        expect(exception.code, equals('VECTOR_DATABASE_ERROR'));
        expect(exception.toString(), contains('search'));
      });

      test('creation with operation and databaseType', () {
        final exception = VectorDatabaseException(
          'insert',
          databaseType: 'chroma',
        );
        expect(exception.operation, equals('insert'));
        expect(exception.databaseType, equals('chroma'));
        expect(
          exception.message,
          equals('Vector database error in insert for chroma'),
        );
        expect(exception.toString(), contains('chroma'));
      });
    });

    group('FusionException', () {
      test('creation with strategy and chunkCount', () {
        final exception = FusionException('weighted_average', 100);
        expect(exception.strategy, equals('weighted_average'));
        expect(exception.chunkCount, equals(100));
        expect(
          exception.message,
          equals(
            'Fusion failed using strategy "weighted_average" with 100 chunks',
          ),
        );
        expect(exception.code, equals('FUSION_ERROR'));
        expect(exception.toString(), contains('weighted_average'));
        expect(exception.toString(), contains('100'));
      });
    });

    group('ScoringException', () {
      test('creation with method', () {
        final exception = ScoringException('cosine_similarity');
        expect(exception.method, equals('cosine_similarity'));
        expect(exception.reason, isNull);
        expect(
          exception.message,
          equals('Scoring failed using method "cosine_similarity"'),
        );
        expect(exception.code, equals('SCORING_ERROR'));
        expect(exception.toString(), contains('cosine_similarity'));
      });

      test('creation with method and reason', () {
        final exception = ScoringException(
          'semantic_similarity',
          reason: 'embedding model failed',
        );
        expect(exception.method, equals('semantic_similarity'));
        expect(exception.reason, equals('embedding model failed'));
        expect(
          exception.message,
          equals(
            'Scoring failed using method "semantic_similarity": embedding model failed',
          ),
        );
        expect(exception.toString(), contains('embedding model failed'));
      });
    });

    group('Exception inheritance', () {
      test('all exceptions inherit from RagifyException', () {
        expect(ContextNotFoundException('test'), isA<RagifyException>());
        expect(
          ConfigurationException('field', 'value'),
          isA<RagifyException>(),
        );
        expect(
          PrivacyViolationException('op', 'req', 'act'),
          isA<RagifyException>(),
        );
        expect(
          SourceConnectionException('source', 'type'),
          isA<RagifyException>(),
        );
        expect(VectorDatabaseException('op'), isA<RagifyException>());
        expect(FusionException('strategy', 5), isA<RagifyException>());
        expect(ScoringException('method'), isA<RagifyException>());
      });
    });

    group('Exception details', () {
      test('exception with all optional parameters', () {
        final details = {'error_code': 500, 'timestamp': '2023-01-01'};

        final exception = RagifyException(
          'Complex error',
          code: 'COMPLEX_ERROR',
          details: details,
        );

        expect(exception.message, equals('Complex error'));
        expect(exception.code, equals('COMPLEX_ERROR'));
        expect(exception.details, equals(details));
        expect(exception.toString(), contains('COMPLEX_ERROR'));
      });
    });
  });
}
