import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/utils/context_utils.dart';

void main() {
  group('ContextUtils Tests', () {
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
