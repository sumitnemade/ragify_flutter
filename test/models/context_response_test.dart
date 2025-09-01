import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/models/context_response.dart';
import 'package:ragify_flutter/src/models/context_chunk.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/models/relevance_score.dart';

void main() {
  group('ContextResponse Tests', () {
    late ContextResponse response;
    late List<ContextChunk> testChunks;
    late ContextSource testSource;

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

      testChunks = [
        ContextChunk(
          id: 'chunk1',
          content: 'First chunk content',
          source: testSource,
          relevanceScore: RelevanceScore(score: 0.9),
          tokenCount: 10,
        ),
        ContextChunk(
          id: 'chunk2',
          content: 'Second chunk content',
          source: testSource,
          relevanceScore: RelevanceScore(score: 0.7),
          tokenCount: 15,
        ),
        ContextChunk(
          id: 'chunk3',
          content: 'Third chunk content',
          source: testSource,
          relevanceScore: RelevanceScore(score: 0.8),
          tokenCount: 12,
        ),
      ];

      response = ContextResponse(
        id: 'response1',
        query: 'Test query',
        chunks: testChunks,
        userId: 'user123',
        sessionId: 'session456',
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.public,
        metadata: {'source': 'test'},
        processingTimeMs: 150,
      );
    });

    group('Constructor Tests', () {
      test('should create with required parameters', () {
        final simpleResponse = ContextResponse(
          id: 'simple',
          query: 'Simple query',
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        expect(simpleResponse.id, equals('simple'));
        expect(simpleResponse.query, equals('Simple query'));
        expect(simpleResponse.chunks, isEmpty);
        expect(simpleResponse.maxTokens, equals(500));
        expect(simpleResponse.privacyLevel, equals(PrivacyLevel.public));
        expect(simpleResponse.userId, isNull);
        expect(simpleResponse.sessionId, isNull);
        expect(simpleResponse.metadata, equals({}));
        expect(simpleResponse.processingTimeMs, isNull);
      });

      test('should create with all parameters', () {
        expect(response.id, equals('response1'));
        expect(response.query, equals('Test query'));
        expect(response.chunks, equals(testChunks));
        expect(response.userId, equals('user123'));
        expect(response.sessionId, equals('session456'));
        expect(response.maxTokens, equals(1000));
        expect(response.privacyLevel, equals(PrivacyLevel.public));
        expect(response.metadata, equals({'source': 'test'}));
        expect(response.processingTimeMs, equals(150));
      });

      test('should use default values for optional parameters', () {
        final responseWithDefaults = ContextResponse(
          id: 'defaults',
          query: 'Query with defaults',
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        expect(responseWithDefaults.metadata, equals({}));
        expect(responseWithDefaults.createdAt, isA<DateTime>());
        expect(
          responseWithDefaults.createdAt.isAfter(
            DateTime.now().subtract(Duration(seconds: 1)),
          ),
          isTrue,
        );
      });

      test('should handle empty chunks list', () {
        final emptyResponse = ContextResponse(
          id: 'empty',
          query: 'Empty response',
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        expect(emptyResponse.chunks, isEmpty);
        expect(emptyResponse.chunkCount, equals(0));
        expect(emptyResponse.isEmpty, isTrue);
        expect(emptyResponse.isNotEmpty, isFalse);
      });

      test('should handle single chunk', () {
        final singleChunkResponse = ContextResponse(
          id: 'single',
          query: 'Single chunk',
          chunks: [testChunks[0]],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        expect(singleChunkResponse.chunks.length, equals(1));
        expect(singleChunkResponse.chunkCount, equals(1));
        expect(singleChunkResponse.isEmpty, isFalse);
        expect(singleChunkResponse.isNotEmpty, isTrue);
      });
    });

    group('Computed Properties Tests', () {
      test('should calculate chunk count correctly', () {
        expect(response.chunkCount, equals(3));
      });

      test('should calculate total content length correctly', () {
        // Each chunk has content length based on its content
        final expectedLength = testChunks.fold(
          0,
          (total, chunk) => total + chunk.content.length,
        );
        expect(response.totalContentLength, equals(expectedLength));
      });

      test('should calculate total token count correctly', () {
        // 10 + 15 + 12 = 37
        expect(response.totalTokenCount, equals(37));
      });

      test('should handle chunks without token count', () {
        final chunkWithoutTokenCount = ContextChunk(
          id: 'no_token',
          content: 'No token count',
          source: testSource,
        );

        final responseWithoutTokenCount = ContextResponse(
          id: 'no_token_response',
          query: 'No token count query',
          chunks: [chunkWithoutTokenCount],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        expect(responseWithoutTokenCount.totalTokenCount, equals(0));
      });

      test('should sort chunks by relevance score', () {
        final sortedChunks = response.chunksByRelevance;

        expect(sortedChunks.length, equals(3));
        expect(sortedChunks[0].relevanceScore?.score, equals(0.9));
        expect(sortedChunks[1].relevanceScore?.score, equals(0.8));
        expect(sortedChunks[2].relevanceScore?.score, equals(0.7));
      });

      test('should handle chunks without relevance score', () {
        final chunkWithoutRelevance = ContextChunk(
          id: 'no_relevance',
          content: 'No relevance score',
          source: testSource,
        );

        final responseWithoutRelevance = ContextResponse(
          id: 'no_relevance_response',
          query: 'No relevance query',
          chunks: [chunkWithoutRelevance],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        final sortedChunks = responseWithoutRelevance.chunksByRelevance;
        expect(sortedChunks.length, equals(1));
        expect(sortedChunks[0].relevanceScore, isNull);
      });

      test('should get source names correctly', () {
        final sourceNames = response.sourceNames;
        expect(sourceNames.length, equals(1));
        expect(sourceNames.contains('Test Source'), isTrue);
      });

      test('should handle multiple sources', () {
        final source2 = ContextSource(
          id: 'source2',
          name: 'Source 2',
          sourceType: SourceType.database,
          url: 'https://source2.com',
          metadata: {},
          privacyLevel: PrivacyLevel.public,
          authorityScore: 0.7,
          freshnessScore: 0.8,
        );

        final chunk2 = ContextChunk(
          id: 'chunk2',
          content: 'Content from source 2',
          source: source2,
        );

        final responseWithMultipleSources = ContextResponse(
          id: 'multiple_sources',
          query: 'Multiple sources query',
          chunks: [testChunks[0], chunk2],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        final sourceNames = responseWithMultipleSources.sourceNames;
        expect(sourceNames.length, equals(2));
        expect(sourceNames.contains('Test Source'), isTrue);
        expect(sourceNames.contains('Source 2'), isTrue);
      });
    });

    group('Filtering Methods Tests', () {
      test('should get chunks above relevance threshold', () {
        final chunksAboveThreshold = response.getChunksAboveThreshold(0.8);
        expect(
          chunksAboveThreshold.length,
          equals(2),
        ); // 0.9 and 0.8 are both >= 0.8
        expect(
          chunksAboveThreshold.any(
            (chunk) => chunk.relevanceScore?.score == 0.9,
          ),
          isTrue,
        );
        expect(
          chunksAboveThreshold.any(
            (chunk) => chunk.relevanceScore?.score == 0.8,
          ),
          isTrue,
        );
      });

      test('should get chunks at relevance threshold', () {
        final chunksAtThreshold = response.getChunksAboveThreshold(0.8);
        expect(
          chunksAtThreshold.length,
          equals(2),
        ); // 0.9 and 0.8 are both >= 0.8
        expect(
          chunksAtThreshold.any((chunk) => chunk.relevanceScore?.score == 0.9),
          isTrue,
        );
        expect(
          chunksAtThreshold.any((chunk) => chunk.relevanceScore?.score == 0.8),
          isTrue,
        );
      });

      test('should get chunks below relevance threshold', () {
        final chunksBelowThreshold = response.getChunksAboveThreshold(0.9);
        expect(chunksBelowThreshold.length, equals(1)); // Only 0.9 is >= 0.9
        expect(chunksBelowThreshold[0].relevanceScore?.score, equals(0.9));
      });

      test(
        'should handle chunks without relevance score in threshold filtering',
        () {
          final chunkWithoutRelevance = ContextChunk(
            id: 'no_relevance',
            content: 'No relevance score',
            source: testSource,
          );

          final responseWithoutRelevance = ContextResponse(
            id: 'no_relevance_response',
            query: 'No relevance query',
            chunks: [chunkWithoutRelevance],
            maxTokens: 500,
            privacyLevel: PrivacyLevel.public,
          );

          final chunksAboveThreshold = responseWithoutRelevance
              .getChunksAboveThreshold(0.5);
          expect(chunksAboveThreshold, isEmpty);
        },
      );

      test('should get chunks from specific source', () {
        final chunksFromSource = response.getChunksFromSource('Test Source');
        expect(chunksFromSource.length, equals(3));
        expect(
          chunksFromSource.every((chunk) => chunk.source.name == 'Test Source'),
          isTrue,
        );
      });

      test('should return empty list for non-existent source', () {
        final chunksFromNonExistentSource = response.getChunksFromSource(
          'Non-existent Source',
        );
        expect(chunksFromNonExistentSource, isEmpty);
      });

      test('should handle case-sensitive source name matching', () {
        final chunksFromSource = response.getChunksFromSource('test source');
        expect(chunksFromSource, isEmpty);
      });
    });

    group('Copy With Tests', () {
      test('should create copy with updated fields', () {
        final updatedResponse = response.copyWith(
          id: 'updated_id',
          query: 'Updated query',
          maxTokens: 2000,
          privacyLevel: PrivacyLevel.private,
          processingTimeMs: 300,
        );

        expect(updatedResponse.id, equals('updated_id'));
        expect(updatedResponse.query, equals('Updated query'));
        expect(updatedResponse.maxTokens, equals(2000));
        expect(updatedResponse.privacyLevel, equals(PrivacyLevel.private));
        expect(updatedResponse.processingTimeMs, equals(300));

        // Unchanged fields
        expect(updatedResponse.chunks, equals(response.chunks));
        expect(updatedResponse.userId, equals(response.userId));
        expect(updatedResponse.sessionId, equals(response.sessionId));
        expect(updatedResponse.metadata, equals(response.metadata));
        expect(updatedResponse.createdAt, equals(response.createdAt));
      });

      test('should create copy with partial updates', () {
        final updatedResponse = response.copyWith(query: 'Partial update');

        expect(updatedResponse.query, equals('Partial update'));
        expect(updatedResponse.id, equals(response.id));
        expect(updatedResponse.chunks, equals(response.chunks));
        expect(updatedResponse.maxTokens, equals(response.maxTokens));
        expect(updatedResponse.privacyLevel, equals(response.privacyLevel));
      });

      test('should create copy with no changes', () {
        final copy = response.copyWith();

        expect(copy.id, equals(response.id));
        expect(copy.query, equals(response.query));
        expect(copy.chunks, equals(response.chunks));
        expect(copy.userId, equals(response.userId));
        expect(copy.sessionId, equals(response.sessionId));
        expect(copy.maxTokens, equals(response.maxTokens));
        expect(copy.privacyLevel, equals(response.privacyLevel));
        expect(copy.metadata, equals(response.metadata));
        expect(copy.createdAt, equals(response.createdAt));
        expect(copy.processingTimeMs, equals(response.processingTimeMs));
      });

      test('should handle null values in copyWith', () {
        final updatedResponse = response.copyWith(
          userId: null,
          sessionId: null,
          processingTimeMs: null,
        );

        // The copyWith method uses the null-coalescing operator (??),
        // so null values will use the original values instead of becoming null
        expect(updatedResponse.userId, equals(response.userId));
        expect(updatedResponse.sessionId, equals(response.sessionId));
        expect(
          updatedResponse.processingTimeMs,
          equals(response.processingTimeMs),
        );

        // Other fields unchanged
        expect(updatedResponse.id, equals(response.id));
        expect(updatedResponse.query, equals(response.query));
        expect(updatedResponse.chunks, equals(response.chunks));
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when IDs match', () {
        final response2 = ContextResponse(
          id: 'response1', // Same ID
          query: 'Different query',
          chunks: [],
          maxTokens: 2000,
          privacyLevel: PrivacyLevel.private,
        );

        expect(response, equals(response2));
        expect(response.hashCode, equals(response2.hashCode));
      });

      test('should not be equal when IDs differ', () {
        final response2 = ContextResponse(
          id: 'response2', // Different ID
          query: 'Same query',
          chunks: response.chunks,
          maxTokens: response.maxTokens,
          privacyLevel: response.privacyLevel,
        );

        expect(response, isNot(equals(response2)));
        expect(response.hashCode, isNot(equals(response2.hashCode)));
      });

      test('should be equal to itself', () {
        expect(response, equals(response));
        expect(response.hashCode, equals(response.hashCode));
      });

      test('should not be equal to different types', () {
        expect(response, isNot(equals('string')));
        expect(response, isNot(equals(123)));
        expect(response, isNot(equals(null)));
      });
    });

    group('ToString Tests', () {
      test('should generate readable string representation', () {
        final stringRep = response.toString();

        expect(stringRep, contains('ContextResponse'));
        expect(stringRep, contains('response1'));
        expect(stringRep, contains('Test query'));
        expect(stringRep, contains('3')); // chunk count
        expect(stringRep, contains('public')); // privacy level
      });

      test('should handle special characters in query', () {
        final responseWithSpecialChars = ContextResponse(
          id: 'special',
          query: 'Query with "quotes" and \'apostrophes\'',
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        final stringRep = responseWithSpecialChars.toString();
        expect(stringRep, contains('Query with "quotes" and \'apostrophes\''));
      });

      test('should handle very long query', () {
        final longQuery = 'a' * 100;
        final responseWithLongQuery = ContextResponse(
          id: 'long_query',
          query: longQuery,
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
        );

        final stringRep = responseWithLongQuery.toString();
        expect(stringRep, contains(longQuery));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle zero maxTokens', () {
        final responseWithZeroTokens = ContextResponse(
          id: 'zero_tokens',
          query: 'Zero tokens query',
          chunks: [],
          maxTokens: 0,
          privacyLevel: PrivacyLevel.public,
        );

        expect(responseWithZeroTokens.maxTokens, equals(0));
      });

      test('should handle very large maxTokens', () {
        final responseWithLargeTokens = ContextResponse(
          id: 'large_tokens',
          query: 'Large tokens query',
          chunks: [],
          maxTokens: 999999,
          privacyLevel: PrivacyLevel.public,
        );

        expect(responseWithLargeTokens.maxTokens, equals(999999));
      });

      test('should handle empty metadata', () {
        final responseWithEmptyMetadata = ContextResponse(
          id: 'empty_metadata',
          query: 'Empty metadata query',
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
          metadata: {},
        );

        expect(responseWithEmptyMetadata.metadata, isEmpty);
      });

      test('should handle large metadata', () {
        final largeMetadata = Map.fromEntries(
          List.generate(100, (i) => MapEntry('key$i', 'value$i')),
        );

        final responseWithLargeMetadata = ContextResponse(
          id: 'large_metadata',
          query: 'Large metadata query',
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
          metadata: largeMetadata,
        );

        expect(responseWithLargeMetadata.metadata.length, equals(100));
      });

      test('should handle negative processing time', () {
        final responseWithNegativeTime = ContextResponse(
          id: 'negative_time',
          query: 'Negative time query',
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
          processingTimeMs: -100,
        );

        expect(responseWithNegativeTime.processingTimeMs, equals(-100));
      });

      test('should handle very large processing time', () {
        final responseWithLargeTime = ContextResponse(
          id: 'large_time',
          query: 'Large time query',
          chunks: [],
          maxTokens: 500,
          privacyLevel: PrivacyLevel.public,
          processingTimeMs: 999999,
        );

        expect(responseWithLargeTime.processingTimeMs, equals(999999));
      });
    });

    group('Validation Tests', () {
      test('should handle all privacy levels', () {
        for (final privacyLevel in PrivacyLevel.values) {
          final responseWithPrivacyLevel = ContextResponse(
            id: 'privacy_$privacyLevel',
            query: 'Privacy level test',
            chunks: [],
            maxTokens: 500,
            privacyLevel: privacyLevel,
          );

          expect(responseWithPrivacyLevel.privacyLevel, equals(privacyLevel));
        }
      });

      test('should handle different token limits', () {
        final tokenLimits = [1, 100, 1000, 10000, 100000];

        for (final limit in tokenLimits) {
          final responseWithLimit = ContextResponse(
            id: 'limit_$limit',
            query: 'Token limit test',
            chunks: [],
            maxTokens: limit,
            privacyLevel: PrivacyLevel.public,
          );

          expect(responseWithLimit.maxTokens, equals(limit));
        }
      });
    });

    group('Performance Tests', () {
      test('should handle multiple copy operations efficiently', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          response.copyWith(id: 'copy_$i');
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
        ); // Should be very fast
      });

      test('should handle multiple equality checks efficiently', () {
        final response2 = ContextResponse(
          id: 'response1', // Same ID
          query: 'Different query',
          chunks: [],
          maxTokens: 2000,
          privacyLevel: PrivacyLevel.private,
        );

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          response == response2;
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
        ); // Should be very fast
      });

      test('should handle sorting large numbers of chunks efficiently', () {
        final largeChunks = List.generate(
          1000,
          (i) => ContextChunk(
            id: 'chunk_$i',
            content: 'Content $i',
            source: testSource,
            relevanceScore: RelevanceScore(score: 1.0 - (i / 1000)),
          ),
        );

        final responseWithLargeChunks = ContextResponse(
          id: 'large_chunks',
          query: 'Large chunks query',
          chunks: largeChunks,
          maxTokens: 50000,
          privacyLevel: PrivacyLevel.public,
        );

        final stopwatch = Stopwatch()..start();
        final sortedChunks = responseWithLargeChunks.chunksByRelevance;
        stopwatch.stop();

        expect(sortedChunks.length, equals(1000));
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
        ); // Should be reasonably fast
        expect(sortedChunks[0].relevanceScore?.score, closeTo(1.0, 0.001));
        expect(sortedChunks[999].relevanceScore?.score, closeTo(0.001, 0.001));
      });
    });
  });
}
