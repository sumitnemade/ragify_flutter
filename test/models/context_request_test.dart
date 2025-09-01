import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/models/context_request.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';

void main() {
  group('ContextRequest Tests', () {
    group('Constructor Tests', () {
      test('should create with required parameters', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.query, equals('Test query'));
        expect(request.maxTokens, equals(1000));
        expect(request.minRelevance, equals(0.7));
        expect(request.privacyLevel, equals(PrivacyLevel.public));
        expect(request.userId, isNull);
        expect(request.sessionId, isNull);
        expect(request.maxChunks, isNull);
        expect(request.includeMetadata, isTrue);
        expect(request.sources, isNull);
        expect(request.excludeSources, isNull);
      });

      test('should create with all parameters', () {
        final request = ContextRequest(
          query: 'Test query',
          userId: 'user123',
          sessionId: 'session456',
          maxTokens: 2000,
          maxChunks: 10,
          minRelevance: 0.8,
          privacyLevel: PrivacyLevel.private,
          includeMetadata: false,
          sources: ['source1', 'source2'],
          excludeSources: ['exclude1'],
        );

        expect(request.query, equals('Test query'));
        expect(request.userId, equals('user123'));
        expect(request.sessionId, equals('session456'));
        expect(request.maxTokens, equals(2000));
        expect(request.maxChunks, equals(10));
        expect(request.minRelevance, equals(0.8));
        expect(request.privacyLevel, equals(PrivacyLevel.private));
        expect(request.includeMetadata, isFalse);
        expect(request.sources, equals(['source1', 'source2']));
        expect(request.excludeSources, equals(['exclude1']));
      });

      test('should use default values for optional parameters', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.includeMetadata, isTrue);
      });

      test('should handle empty query', () {
        final request = ContextRequest(
          query: '',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.query, equals(''));
        expect(request.maxTokens, equals(1000));
      });

      test('should handle very long query', () {
        final longQuery = 'a' * 1000;
        final request = ContextRequest(
          query: longQuery,
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.query, equals(longQuery));
        expect(request.query.length, equals(1000));
      });

      test('should handle edge case values', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1,
          minRelevance: 0.0,
          privacyLevel: PrivacyLevel.restricted,
        );

        expect(request.maxTokens, equals(1));
        expect(request.minRelevance, equals(0.0));
        expect(request.privacyLevel, equals(PrivacyLevel.restricted));
      });
    });

    group('Copy With Tests', () {
      test('should create copy with updated fields', () {
        final original = ContextRequest(
          query: 'Original query',
          userId: 'user1',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
          sources: ['source1'],
        );

        final updated = original.copyWith(
          query: 'Updated query',
          userId: 'user2',
          maxTokens: 2000,
          minRelevance: 0.8,
          privacyLevel: PrivacyLevel.private,
          sources: ['source2'],
        );

        expect(updated.query, equals('Updated query'));
        expect(updated.userId, equals('user2'));
        expect(updated.maxTokens, equals(2000));
        expect(updated.minRelevance, equals(0.8));
        expect(updated.privacyLevel, equals(PrivacyLevel.private));
        expect(updated.sources, equals(['source2']));
        expect(updated.sessionId, equals(original.sessionId));
        expect(updated.maxChunks, equals(original.maxChunks));
        expect(updated.includeMetadata, equals(original.includeMetadata));
        expect(updated.excludeSources, equals(original.excludeSources));
      });

      test('should create copy with partial updates', () {
        final original = ContextRequest(
          query: 'Original query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final updated = original.copyWith(
          query: 'Updated query',
          maxTokens: 2000,
        );

        expect(updated.query, equals('Updated query'));
        expect(updated.maxTokens, equals(2000));
        expect(updated.minRelevance, equals(original.minRelevance));
        expect(updated.privacyLevel, equals(original.privacyLevel));
        expect(updated.userId, equals(original.userId));
        expect(updated.sessionId, equals(original.sessionId));
        expect(updated.maxChunks, equals(original.maxChunks));
        expect(updated.includeMetadata, equals(original.includeMetadata));
        expect(updated.sources, equals(original.sources));
        expect(updated.excludeSources, equals(original.excludeSources));
      });

      test('should create copy with no changes', () {
        final original = ContextRequest(
          query: 'Original query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final copy = original.copyWith();

        expect(copy.query, equals(original.query));
        expect(copy.userId, equals(original.userId));
        expect(copy.sessionId, equals(original.sessionId));
        expect(copy.maxTokens, equals(original.maxTokens));
        expect(copy.maxChunks, equals(original.maxChunks));
        expect(copy.minRelevance, equals(original.minRelevance));
        expect(copy.privacyLevel, equals(original.privacyLevel));
        expect(copy.includeMetadata, equals(original.includeMetadata));
        expect(copy.sources, equals(original.sources));
        expect(copy.excludeSources, equals(original.excludeSources));
      });

      test('should handle null values in copyWith', () {
        final original = ContextRequest(
          query: 'Original query',
          userId: 'user1',
          sessionId: 'session1',
          maxTokens: 1000,
          maxChunks: 10,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
          sources: ['source1'],
          excludeSources: ['exclude1'],
        );

        final updated = original.copyWith(
          userId: null,
          sessionId: null,
          maxChunks: null,
          sources: null,
          excludeSources: null,
        );

        // The copyWith method uses the null-coalescing operator (??), 
        // so null values will use the original values instead of becoming null
        expect(updated.userId, equals(original.userId));
        expect(updated.sessionId, equals(original.sessionId));
        expect(updated.maxChunks, equals(original.maxChunks));
        expect(updated.sources, equals(original.sources));
        expect(updated.excludeSources, equals(original.excludeSources));
        expect(updated.query, equals(original.query));
        expect(updated.maxTokens, equals(original.maxTokens));
        expect(updated.minRelevance, equals(original.minRelevance));
        expect(updated.privacyLevel, equals(original.privacyLevel));
        expect(updated.includeMetadata, equals(original.includeMetadata));
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when all fields match', () {
        final request1 = ContextRequest(
          query: 'Test query',
          userId: 'user1',
          sessionId: 'session1',
          maxTokens: 1000,
          maxChunks: 10,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
          includeMetadata: true,
          sources: ['source1'],
          excludeSources: ['exclude1'],
        );

        final request2 = ContextRequest(
          query: 'Test query',
          userId: 'user1',
          sessionId: 'session1',
          maxTokens: 1000,
          maxChunks: 10,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
          includeMetadata: true,
          sources: ['source1'],
          excludeSources: ['exclude1'],
        );

        expect(request1, equals(request2));
        expect(request1.hashCode, equals(request2.hashCode));
      });

      test('should not be equal when query differs', () {
        final request1 = ContextRequest(
          query: 'Query 1',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final request2 = ContextRequest(
          query: 'Query 2',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request1, isNot(equals(request2)));
        expect(request1.hashCode, isNot(equals(request2.hashCode)));
      });

      test('should not be equal when userId differs', () {
        final request1 = ContextRequest(
          query: 'Test query',
          userId: 'user1',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final request2 = ContextRequest(
          query: 'Test query',
          userId: 'user2',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request1, isNot(equals(request2)));
        expect(request1.hashCode, isNot(equals(request2.hashCode)));
      });

      test('should not be equal when sessionId differs', () {
        final request1 = ContextRequest(
          query: 'Test query',
          sessionId: 'session1',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final request2 = ContextRequest(
          query: 'Test query',
          sessionId: 'session2',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request1, isNot(equals(request2)));
        expect(request1.hashCode, isNot(equals(request2.hashCode)));
      });

      test('should not be equal when maxTokens differs', () {
        final request1 = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final request2 = ContextRequest(
          query: 'Test query',
          maxTokens: 2000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request1, isNot(equals(request2)));
        expect(request1.hashCode, isNot(equals(request2.hashCode)));
      });

      test('should be equal to itself', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request, equals(request));
        expect(request.hashCode, equals(request.hashCode));
      });

      test('should not be equal to different types', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request, isNot(equals('string')));
        expect(request, isNot(equals(123)));
        expect(request, isNot(equals(null)));
      });

      test('should handle null values in equality', () {
        final request1 = ContextRequest(
          query: 'Test query',
          userId: null,
          sessionId: null,
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final request2 = ContextRequest(
          query: 'Test query',
          userId: null,
          sessionId: null,
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request1, equals(request2));
        expect(request1.hashCode, equals(request2.hashCode));
      });
    });

    group('ToString Tests', () {
      test('should generate readable string representation', () {
        final request = ContextRequest(
          query: 'Test query for context',
          userId: 'user123',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.private,
        );

        final stringRep = request.toString();

        expect(stringRep, contains('ContextRequest'));
        expect(stringRep, contains('Test query for context'));
        expect(stringRep, contains('1000'));
        expect(stringRep, contains('private'));
      });

      test('should handle special characters in query', () {
        final request = ContextRequest(
          query: 'Query with "quotes" and \'apostrophes\'',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final stringRep = request.toString();

        expect(stringRep, contains('Query with "quotes" and \'apostrophes\''));
      });

      test('should handle very long query in toString', () {
        final longQuery = 'a' * 100;
        final request = ContextRequest(
          query: longQuery,
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final stringRep = request.toString();

        expect(stringRep, contains(longQuery));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle zero maxTokens', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 0,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.maxTokens, equals(0));
      });

      test('should handle negative minRelevance', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: -0.1,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.minRelevance, equals(-0.1));
      });

      test('should handle minRelevance greater than 1', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: 1.1,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.minRelevance, equals(1.1));
      });

      test('should handle empty sources list', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
          sources: [],
        );

        expect(request.sources, equals([]));
        expect(request.sources, isEmpty);
      });

      test('should handle empty excludeSources list', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
          excludeSources: [],
        );

        expect(request.excludeSources, equals([]));
        expect(request.excludeSources, isEmpty);
      });

      test('should handle large maxTokens value', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 999999,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.maxTokens, equals(999999));
      });

      test('should handle large maxChunks value', () {
        final request = ContextRequest(
          query: 'Test query',
          maxTokens: 1000,
          maxChunks: 999999,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        expect(request.maxChunks, equals(999999));
      });
    });

    group('Validation Tests', () {
      test('should handle all privacy levels', () {
        for (final privacyLevel in PrivacyLevel.values) {
          final request = ContextRequest(
            query: 'Test query',
            maxTokens: 1000,
            minRelevance: 0.7,
            privacyLevel: privacyLevel,
          );

          expect(request.privacyLevel, equals(privacyLevel));
        }
      });

      test('should handle different relevance thresholds', () {
        final thresholds = [0.0, 0.1, 0.5, 0.9, 1.0];
        
        for (final threshold in thresholds) {
          final request = ContextRequest(
            query: 'Test query',
            maxTokens: 1000,
            minRelevance: threshold,
            privacyLevel: PrivacyLevel.public,
          );

          expect(request.minRelevance, equals(threshold));
        }
      });

      test('should handle different token limits', () {
        final tokenLimits = [1, 100, 1000, 10000, 100000];
        
        for (final limit in tokenLimits) {
          final request = ContextRequest(
            query: 'Test query',
            maxTokens: limit,
            minRelevance: 0.7,
            privacyLevel: PrivacyLevel.public,
          );

          expect(request.maxTokens, equals(limit));
        }
      });
    });

    group('Performance Tests', () {
      test('should handle multiple copy operations efficiently', () {
        final original = ContextRequest(
          query: 'Original query',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          original.copyWith(query: 'Query $i');
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
      });

      test('should handle multiple equality checks efficiently', () {
        final request1 = ContextRequest(
          query: 'Query 1',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final request2 = ContextRequest(
          query: 'Query 2',
          maxTokens: 1000,
          minRelevance: 0.7,
          privacyLevel: PrivacyLevel.public,
        );

        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          request1 == request2;
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be very fast
      });
    });
  });
}
