import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/models/context_chunk.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/models/relevance_score.dart';
import 'package:ragify_flutter/src/utils/context_utils.dart';

void main() {
  group('ContextUtils Tests', () {
    late ContextSource testSource;
    late ContextChunk testChunk1;
    late ContextChunk testChunk2;
    late ContextChunk testChunk3;

    setUp(() {
      testSource = ContextSource(
        name: 'Test Source',
        sourceType: SourceType.document,
        privacyLevel: PrivacyLevel.public,
        metadata: {'test': 'data'},
        id: 'test_source_1',
        url: 'https://example.com',
        lastUpdated: DateTime.now(),
        isActive: true,
        authorityScore: 0.8,
        freshnessScore: 0.9,
      );

      testChunk1 = ContextChunk(
        id: 'chunk1',
        content: 'This is the first test chunk with some content.',
        source: testSource,
        relevanceScore: RelevanceScore(score: 0.9, confidenceLevel: 0.95),
        tokenCount: 10,
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
      );

      testChunk2 = ContextChunk(
        id: 'chunk2',
        content: 'This is the second test chunk with different content.',
        source: testSource,
        relevanceScore: RelevanceScore(score: 0.7, confidenceLevel: 0.85),
        tokenCount: 12,
        createdAt: DateTime.now().subtract(Duration(minutes: 30)),
      );

      testChunk3 = ContextChunk(
        id: 'chunk3',
        content: 'This is the third test chunk with unique content.',
        source: testSource,
        relevanceScore: RelevanceScore(score: 0.8, confidenceLevel: 0.90),
        tokenCount: 8,
        createdAt: DateTime.now(),
      );
    });

    group('Token Count Tests', () {
      test('should estimate token count for text', () {
        final text = 'This is a test text with multiple words.';
        final tokenCount = ContextUtils.estimateTokenCount(text);

        // Simple approximation: 1 token ≈ 4 characters
        expect(tokenCount, greaterThan(0));
        expect(tokenCount, closeTo(text.length / 4, 1));
      });

      test('should handle empty text', () {
        final tokenCount = ContextUtils.estimateTokenCount('');
        expect(tokenCount, equals(0));
      });

      test('should handle short text', () {
        final tokenCount = ContextUtils.estimateTokenCount('Hi');
        expect(tokenCount, equals(1));
      });

      test('should handle very long text', () {
        final longText = 'a' * 1000;
        final tokenCount = ContextUtils.estimateTokenCount(longText);
        expect(tokenCount, equals(250)); // 1000 / 4
      });
    });

    group('Token Calculation Tests', () {
      test('should calculate total tokens for chunks', () {
        final chunks = [testChunk1, testChunk2, testChunk3];
        final totalTokens = ContextUtils.calculateTotalTokens(chunks);
        expect(totalTokens, equals(30)); // 10 + 12 + 8
      });

      test('should handle chunks with null token count', () {
        final chunkWithNullTokens = ContextChunk(
          id: 'null_tokens',
          content: 'Test content',
          source: testSource,
        );
        final chunks = [chunkWithNullTokens];
        final totalTokens = ContextUtils.calculateTotalTokens(chunks);
        expect(totalTokens, equals(0));
      });

      test('should handle empty chunks list', () {
        final totalTokens = ContextUtils.calculateTotalTokens([]);
        expect(totalTokens, equals(0));
      });
    });

    group('Chunk Merging Tests', () {
      test('should merge chunks with default separator', () {
        final chunks = [testChunk1, testChunk2];
        final merged = ContextUtils.mergeChunks(chunks);
        expect(merged, contains(testChunk1.content.trim()));
        expect(merged, contains(testChunk2.content.trim()));
        expect(merged, contains('\n\n'));
      });

      test('should merge chunks with custom separator', () {
        final chunks = [testChunk1, testChunk2];
        final merged = ContextUtils.mergeChunks(chunks, separator: ' | ');
        expect(merged, contains(' | '));
      });

      test('should handle empty chunks list', () {
        final merged = ContextUtils.mergeChunks([]);
        expect(merged, equals(''));
      });

      test('should filter out empty content', () {
        final emptyChunk = ContextChunk(
          id: 'empty',
          content: '   ',
          source: testSource,
        );
        final chunks = [testChunk1, emptyChunk, testChunk2];
        final merged = ContextUtils.mergeChunks(chunks);
        expect(merged, isNot(contains('   ')));
      });
    });

    group('Relevance Sorting Tests', () {
      test('should sort chunks by relevance score descending', () {
        final chunks = [testChunk2, testChunk1, testChunk3]; // 0.7, 0.9, 0.8
        final sorted = ContextUtils.sortByRelevance(chunks);
        expect(sorted[0].relevanceScore?.score, equals(0.9));
        expect(sorted[1].relevanceScore?.score, equals(0.8));
        expect(sorted[2].relevanceScore?.score, equals(0.7));
      });

      test('should handle chunks with null relevance score', () {
        final chunkWithNullScore = ContextChunk(
          id: 'null_score',
          content: 'Test content',
          source: testSource,
        );
        final chunks = [chunkWithNullScore, testChunk1];
        final sorted = ContextUtils.sortByRelevance(chunks);
        expect(sorted[0].relevanceScore?.score, equals(0.9));
        expect(sorted[1].relevanceScore, isNull);
      });

      test('should handle empty chunks list', () {
        final sorted = ContextUtils.sortByRelevance([]);
        expect(sorted, isEmpty);
      });
    });

    group('Relevance Filtering Tests', () {
      test('should filter chunks by minimum relevance threshold', () {
        final chunks = [testChunk1, testChunk2, testChunk3]; // 0.9, 0.7, 0.8
        final filtered = ContextUtils.filterByRelevance(chunks, 0.8);
        expect(filtered.length, equals(2));
        expect(filtered.every((c) => (c.relevanceScore?.score ?? 0.0) >= 0.8), isTrue);
      });

      test('should handle chunks with null relevance score', () {
        final chunkWithNullScore = ContextChunk(
          id: 'null_score',
          content: 'Test content',
          source: testSource,
        );
        final chunks = [chunkWithNullScore, testChunk1];
        final filtered = ContextUtils.filterByRelevance(chunks, 0.5);
        expect(filtered.length, equals(1));
        expect(filtered.first, equals(testChunk1));
      });

      test('should handle empty chunks list', () {
        final filtered = ContextUtils.filterByRelevance([], 0.5);
        expect(filtered, isEmpty);
      });
    });

    group('Chunk Limiting Tests', () {
      test('should limit chunks by maximum count', () {
        final chunks = [testChunk1, testChunk2, testChunk3];
        final limited = ContextUtils.limitChunks(chunks, 2);
        expect(limited.length, equals(2));
        expect(limited[0], equals(testChunk1));
        expect(limited[1], equals(testChunk2));
      });

      test('should return all chunks when limit is greater than count', () {
        final chunks = [testChunk1, testChunk2];
        final limited = ContextUtils.limitChunks(chunks, 5);
        expect(limited.length, equals(2));
      });

      test('should return empty list for zero or negative limit', () {
        final chunks = [testChunk1, testChunk2];
        expect(ContextUtils.limitChunks(chunks, 0), isEmpty);
        expect(ContextUtils.limitChunks(chunks, -1), isEmpty);
      });

      test('should handle empty chunks list', () {
        final limited = ContextUtils.limitChunks([], 5);
        expect(limited, isEmpty);
      });
    });

    group('Chunks Summary Tests', () {
      test('should create summary for non-empty chunks', () {
        final chunks = [testChunk1, testChunk2, testChunk3];
        final summary = ContextUtils.createChunksSummary(chunks);

        expect(summary['total_chunks'], equals(3));
        expect(summary['total_tokens'], equals(30));
        expect(summary['sources'], contains(testSource));
        expect(summary['privacy_levels'], contains('public'));
        expect(summary['average_relevance'], closeTo(0.8, 0.01));
      });

      test('should create summary for empty chunks', () {
        final summary = ContextUtils.createChunksSummary([]);

        expect(summary['total_chunks'], equals(0));
        expect(summary['total_tokens'], equals(0));
        expect(summary['sources'], isEmpty);
        expect(summary['privacy_levels'], isEmpty);
      });

      test('should handle chunks with null relevance scores', () {
        final chunkWithNullScore = ContextChunk(
          id: 'null_score',
          content: 'Test content',
          source: testSource,
        );
        final chunks = [chunkWithNullScore];
        final summary = ContextUtils.createChunksSummary(chunks);
        expect(summary['average_relevance'], equals(0.0));
      });
    });

    group('Chunk Validation Tests', () {
      test('should validate valid chunks', () {
        final chunks = [testChunk1, testChunk2];
        final errors = ContextUtils.validateChunks(chunks);
        expect(errors, isEmpty);
      });

      test('should detect empty content', () {
        final invalidChunk = ContextChunk(
          id: 'invalid',
          content: '',
          source: testSource,
        );
        final chunks = [invalidChunk];
        final errors = ContextUtils.validateChunks(chunks);
        expect(errors, contains('Chunk 0: Empty content'));
      });

      test('should detect missing source name', () {
        final invalidSource = ContextSource(
          name: '',
          sourceType: SourceType.document,
          privacyLevel: PrivacyLevel.public,
          id: 'invalid_source',
          url: 'https://example.com',
          lastUpdated: DateTime.now(),
          isActive: true,
          authorityScore: 0.8,
          freshnessScore: 0.9,
          metadata: {},
        );
        final invalidChunk = ContextChunk(
          id: 'invalid',
          content: 'Test content',
          source: invalidSource,
        );
        final chunks = [invalidChunk];
        final errors = ContextUtils.validateChunks(chunks);
        expect(errors, contains('Chunk 0: Missing source name'));
      });

      test('should detect missing ID', () {
        final invalidChunk = ContextChunk(
          id: '',
          content: 'Test content',
          source: testSource,
        );
        final chunks = [invalidChunk];
        final errors = ContextUtils.validateChunks(chunks);
        expect(errors, contains('Chunk 0: Missing ID'));
      });

      test('should detect future creation date', () {
        final invalidChunk = ContextChunk(
          id: 'future',
          content: 'Test content',
          source: testSource,
          createdAt: DateTime.now().add(Duration(days: 1)),
        );
        final chunks = [invalidChunk];
        final errors = ContextUtils.validateChunks(chunks);
        expect(errors, contains('Chunk 0: Future creation date'));
      });

      test('should handle empty chunks list', () {
        final errors = ContextUtils.validateChunks([]);
        expect(errors, isEmpty);
      });
    });

    group('JSON Conversion Tests', () {
      test('should convert chunks to JSON', () {
        final chunks = [testChunk1, testChunk2];
        final json = ContextUtils.chunksToJson(chunks);
        expect(json.length, equals(2));
        expect(json[0], isA<Map<String, dynamic>>());
        expect(json[0]['id'], equals('chunk1'));
      });

      test('should convert JSON to chunks', () {
        final chunks = [testChunk1, testChunk2];
        final json = ContextUtils.chunksToJson(chunks);
        final convertedChunks = ContextUtils.chunksFromJson(json);
        expect(convertedChunks.length, equals(2));
        expect(convertedChunks[0].id, equals('chunk1'));
        expect(convertedChunks[1].id, equals('chunk2'));
      });

      test('should handle empty chunks list', () {
        expect(ContextUtils.chunksToJson([]), isEmpty);
        expect(ContextUtils.chunksFromJson([]), isEmpty);
      });
    });

    group('Deduplication Tests', () {
      test('should deduplicate chunks with exact content matches', () {
        final duplicateChunk = ContextChunk(
          id: 'duplicate',
          content: testChunk1.content,
          source: testSource,
        );
        final chunks = [testChunk1, duplicateChunk, testChunk2];
        final deduplicated = ContextUtils.deduplicateChunks(chunks, 0.8);
        expect(deduplicated.length, equals(2));
      });

      test('should deduplicate chunks with similar content', () {
        final similarChunk = ContextChunk(
          id: 'similar',
          content: 'This is the first test chunk with some content!', // Very similar
          source: testSource,
        );
        final chunks = [testChunk1, similarChunk, testChunk2];
        final deduplicated = ContextUtils.deduplicateChunks(chunks, 0.95);
        expect(deduplicated.length, equals(2));
      });

      test('should handle single chunk', () {
        final chunks = [testChunk1];
        final deduplicated = ContextUtils.deduplicateChunks(chunks, 0.8);
        expect(deduplicated.length, equals(1));
      });

      test('should handle empty chunks list', () {
        final deduplicated = ContextUtils.deduplicateChunks([], 0.8);
        expect(deduplicated, isEmpty);
      });

      test('should handle very low similarity threshold', () {
        final chunks = [testChunk1, testChunk2, testChunk3];
        final deduplicated = ContextUtils.deduplicateChunks(chunks, 0.1);
        expect(deduplicated.length, equals(1)); // All chunks are similar with very low threshold
      });
    });

    group('Performance Statistics Tests', () {
      test('should return performance statistics', () {
        final stats = ContextUtils.getPerformanceStats();

        expect(stats['optimization_features'], isA<List<String>>());
        expect(stats['performance_improvements'], isA<Map<String, dynamic>>());
        expect(stats['algorithms'], isA<Map<String, dynamic>>());

        expect(
          stats['optimization_features'],
          contains('content_hash_duplicate_detection'),
        );
        expect(
          stats['performance_improvements']['deduplication'],
          equals('O(n log n) instead of O(n²)'),
        );
        expect(
          stats['algorithms']['deduplication'],
          equals('Hash-based + similarity with early termination'),
        );
      });
    });

    group('Utility Method Tests', () {
      test('should handle empty lists gracefully', () {
        // Test that methods handle empty lists without errors
        expect(() => ContextUtils.calculateTotalTokens([]), returnsNormally);
        expect(() => ContextUtils.mergeChunks([]), returnsNormally);
        expect(() => ContextUtils.sortByRelevance([]), returnsNormally);
        expect(() => ContextUtils.filterByRelevance([], 0.5), returnsNormally);
        expect(() => ContextUtils.limitChunks([], 5), returnsNormally);
        expect(() => ContextUtils.createChunksSummary([]), returnsNormally);
        expect(() => ContextUtils.validateChunks([]), returnsNormally);
        expect(() => ContextUtils.chunksToJson([]), returnsNormally);
        expect(() => ContextUtils.chunksFromJson([]), returnsNormally);
        expect(() => ContextUtils.deduplicateChunks([], 0.8), returnsNormally);
      });
    });
  });
}
