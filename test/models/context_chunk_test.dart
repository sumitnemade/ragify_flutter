import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/models/context_chunk.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/models/relevance_score.dart';

void main() {
  group('ContextChunk Tests', () {
    late ContextSource testSource;
    late RelevanceScore testRelevanceScore;

    setUp(() {
      testSource = ContextSource(
        id: 'test_source',
        name: 'Test Source',
        sourceType: SourceType.database,
        url: 'https://test.com',
        metadata: {'description': 'Test source'},
        privacyLevel: PrivacyLevel.public,
        authorityScore: 0.8,
        freshnessScore: 0.9,
      );

      testRelevanceScore = RelevanceScore(score: 0.85);
    });

    group('Constructor Tests', () {
      test('should create with required parameters', () {
        final chunk = ContextChunk(
          content: 'Test content',
          source: testSource,
        );

        expect(chunk.content, equals('Test content'));
        expect(chunk.source, equals(testSource));
        expect(chunk.id, isNotEmpty);
        expect(chunk.createdAt, isA<DateTime>());
        expect(chunk.updatedAt, isA<DateTime>());
        expect(chunk.metadata, equals({}));
        expect(chunk.tags, equals([]));
        expect(chunk.relevanceScore, isNull);
        expect(chunk.tokenCount, isNull);
        expect(chunk.embedding, isNull);
      });

      test('should create with all parameters', () {
        final now = DateTime.now();
        final chunk = ContextChunk(
          id: 'custom_id',
          content: 'Test content',
          source: testSource,
          metadata: {'key': 'value'},
          relevanceScore: testRelevanceScore,
          createdAt: now,
          updatedAt: now,
          tokenCount: 10,
          embedding: [0.1, 0.2, 0.3],
          tags: ['tag1', 'tag2'],
        );

        expect(chunk.id, equals('custom_id'));
        expect(chunk.content, equals('Test content'));
        expect(chunk.source, equals(testSource));
        expect(chunk.metadata, equals({'key': 'value'}));
        expect(chunk.relevanceScore, equals(testRelevanceScore));
        expect(chunk.createdAt, equals(now));
        expect(chunk.updatedAt, equals(now));
        expect(chunk.tokenCount, equals(10));
        expect(chunk.embedding, equals([0.1, 0.2, 0.3]));
        expect(chunk.tags, equals(['tag1', 'tag2']));
      });

      test('should generate UUID when id not provided', () {
        final chunk1 = ContextChunk(
          content: 'Test content 1',
          source: testSource,
        );
        final chunk2 = ContextChunk(
          content: 'Test content 2',
          source: testSource,
        );

        expect(chunk1.id, isNotEmpty);
        expect(chunk2.id, isNotEmpty);
        expect(chunk1.id, isNot(equals(chunk2.id)));
      });

      test('should use current time when dates not provided', () {
        final beforeCreation = DateTime.now();
        final chunk = ContextChunk(
          content: 'Test content',
          source: testSource,
        );
        final afterCreation = DateTime.now();

        expect(chunk.createdAt.isAfter(beforeCreation) || 
               chunk.createdAt.isAtSameMomentAs(beforeCreation), isTrue);
        expect(chunk.updatedAt.isBefore(afterCreation) || 
               chunk.updatedAt.isAtSameMomentAs(afterCreation), isTrue);
      });
    });

    group('Property Tests', () {
      test('should calculate content length correctly', () {
        final chunk = ContextChunk(
          content: 'Test content with multiple words',
          source: testSource,
        );

        expect(chunk.contentLength, equals(32));
      });

      test('should detect embedding presence correctly', () {
        final chunkWithoutEmbedding = ContextChunk(
          content: 'Test content',
          source: testSource,
        );

        final chunkWithEmptyEmbedding = ContextChunk(
          content: 'Test content',
          source: testSource,
          embedding: [],
        );

        final chunkWithEmbedding = ContextChunk(
          content: 'Test content',
          source: testSource,
          embedding: [0.1, 0.2, 0.3],
        );

        expect(chunkWithoutEmbedding.hasEmbedding, isFalse);
        expect(chunkWithEmptyEmbedding.hasEmbedding, isFalse);
        expect(chunkWithEmbedding.hasEmbedding, isTrue);
      });

      test('should check relevance threshold correctly', () {
        final chunkWithRelevance = ContextChunk(
          content: 'Test content',
          source: testSource,
          relevanceScore: RelevanceScore(score: 0.8),
        );

        final chunkWithoutRelevance = ContextChunk(
          content: 'Test content',
          source: testSource,
        );

        expect(chunkWithRelevance.isRelevantAbove(0.7), isTrue);
        expect(chunkWithRelevance.isRelevantAbove(0.9), isFalse);
        expect(chunkWithoutRelevance.isRelevantAbove(0.5), isFalse);
      });

      test('should generate summary correctly', () {
        final shortChunk = ContextChunk(
          content: 'Short content',
          source: testSource,
        );

        final longChunk = ContextChunk(
          content: 'This is a very long content that exceeds one hundred characters and should be truncated with ellipsis at the end',
          source: testSource,
        );

        expect(shortChunk.summary, equals('Short content'));
        expect(longChunk.summary, equals('This is a very long content that exceeds one hundred characters and should be truncated with ellipsi...'));
        expect(longChunk.summary.length, equals(103)); // 100 + 3 for "..."
      });
    });

    group('Copy With Tests', () {
      test('should create copy with updated fields', () {
        final original = ContextChunk(
          content: 'Original content',
          source: testSource,
          metadata: {'key': 'original'},
          tags: ['original'],
        );

        final updated = original.copyWith(
          content: 'Updated content',
          metadata: {'key': 'updated'},
          tags: ['updated'],
        );

        expect(updated.content, equals('Updated content'));
        expect(updated.metadata, equals({'key': 'updated'}));
        expect(updated.tags, equals(['updated']));
        expect(updated.id, equals(original.id));
        expect(updated.source, equals(original.source));
        expect(updated.relevanceScore, equals(original.relevanceScore));
        expect(updated.createdAt, equals(original.createdAt));
        expect(updated.updatedAt, equals(original.updatedAt));
        expect(updated.tokenCount, equals(original.tokenCount));
        expect(updated.embedding, equals(original.embedding));
      });

      test('should create copy with partial updates', () {
        final original = ContextChunk(
          content: 'Original content',
          source: testSource,
        );

        final updated = original.copyWith(
          content: 'Updated content',
        );

        expect(updated.content, equals('Updated content'));
        expect(updated.source, equals(original.source));
        expect(updated.metadata, equals(original.metadata));
        expect(updated.tags, equals(original.tags));
      });

      test('should create copy with no changes', () {
        final original = ContextChunk(
          content: 'Original content',
          source: testSource,
        );

        final copy = original.copyWith();

        expect(copy.content, equals(original.content));
        expect(copy.source, equals(original.source));
        expect(copy.metadata, equals(original.metadata));
        expect(copy.tags, equals(original.tags));
        expect(copy.relevanceScore, equals(original.relevanceScore));
        expect(copy.createdAt, equals(original.createdAt));
        expect(copy.updatedAt, equals(original.updatedAt));
        expect(copy.tokenCount, equals(original.tokenCount));
        expect(copy.embedding, equals(original.embedding));
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when IDs are the same', () {
        final chunk1 = ContextChunk(
          id: 'same_id',
          content: 'Content 1',
          source: testSource,
        );

        final chunk2 = ContextChunk(
          id: 'same_id',
          content: 'Content 2',
          source: testSource,
        );

        expect(chunk1, equals(chunk2));
        expect(chunk1.hashCode, equals(chunk2.hashCode));
      });

      test('should not be equal when IDs are different', () {
        final chunk1 = ContextChunk(
          id: 'id_1',
          content: 'Same content',
          source: testSource,
        );

        final chunk2 = ContextChunk(
          id: 'id_2',
          content: 'Same content',
          source: testSource,
        );

        expect(chunk1, isNot(equals(chunk2)));
        expect(chunk1.hashCode, isNot(equals(chunk2.hashCode)));
      });

      test('should be equal to itself', () {
        final chunk = ContextChunk(
          content: 'Test content',
          source: testSource,
        );

        expect(chunk, equals(chunk));
        expect(chunk.hashCode, equals(chunk.hashCode));
      });

      test('should not be equal to different types', () {
        final chunk = ContextChunk(
          content: 'Test content',
          source: testSource,
        );

        expect(chunk, isNot(equals('string')));
        expect(chunk, isNot(equals(123)));
        expect(chunk, isNot(equals(null)));
      });
    });

    group('ToString Tests', () {
      test('should generate readable string representation', () {
        final chunk = ContextChunk(
          id: 'test_id',
          content: 'This is a test content that will be summarized',
          source: testSource,
        );

        final stringRep = chunk.toString();

        expect(stringRep, contains('ContextChunk'));
        expect(stringRep, contains('test_id'));
        expect(stringRep, contains('Test Source'));
        expect(stringRep, contains('This is a test content that will be summarized'));
      });

      test('should handle short content in toString', () {
        final chunk = ContextChunk(
          content: 'Short',
          source: testSource,
        );

        final stringRep = chunk.toString();

        expect(stringRep, contains('Short'));
        expect(stringRep, isNot(contains('...')));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle empty content', () {
        final chunk = ContextChunk(
          content: '',
          source: testSource,
        );

        expect(chunk.contentLength, equals(0));
        expect(chunk.summary, equals(''));
      });

      test('should handle very long content', () {
        final longContent = 'a' * 1000;
        final chunk = ContextChunk(
          content: longContent,
          source: testSource,
        );

        expect(chunk.contentLength, equals(1000));
        expect(chunk.summary.length, equals(103)); // 100 + 3 for "..."
      });

      test('should handle special characters in content', () {
        final specialContent = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
        final chunk = ContextChunk(
          content: specialContent,
          source: testSource,
        );

        expect(chunk.content, equals(specialContent));
        expect(chunk.contentLength, equals(specialContent.length));
      });

      test('should handle unicode characters', () {
        final unicodeContent = 'Hello 世界 🌍';
        final chunk = ContextChunk(
          content: unicodeContent,
          source: testSource,
        );

        expect(chunk.content, equals(unicodeContent));
        expect(chunk.contentLength, equals(unicodeContent.length));
      });

      test('should handle null embedding correctly', () {
        final chunk = ContextChunk(
          content: 'Test content',
          source: testSource,
          embedding: null,
        );

        expect(chunk.hasEmbedding, isFalse);
      });

      test('should handle empty tags list', () {
        final chunk = ContextChunk(
          content: 'Test content',
          source: testSource,
          tags: [],
        );

        expect(chunk.tags, equals([]));
        expect(chunk.tags, isEmpty);
      });

      test('should handle large metadata', () {
        final largeMetadata = Map.fromEntries(
          List.generate(100, (i) => MapEntry('key$i', 'value$i'))
        );

        final chunk = ContextChunk(
          content: 'Test content',
          source: testSource,
          metadata: largeMetadata,
        );

        expect(chunk.metadata.length, equals(100));
        expect(chunk.metadata['key50'], equals('value50'));
      });
    });

    group('Performance Tests', () {
      test('should handle multiple copy operations efficiently', () {
        final original = ContextChunk(
          content: 'Original content',
          source: testSource,
        );

        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          original.copyWith(content: 'Content $i');
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
      });

      test('should handle large content efficiently', () {
        final largeContent = 'a' * 10000;
        final chunk = ContextChunk(
          content: largeContent,
          source: testSource,
        );

        final stopwatch = Stopwatch()..start();
        final summary = chunk.summary;
        stopwatch.stop();

        expect(summary.length, equals(103)); // 100 + 3 for "..."
        expect(stopwatch.elapsedMilliseconds, lessThan(10)); // Should be very fast
      });
    });
  });
}
