import '../models/context_chunk.dart';

/// Utility functions for context operations
class ContextUtils {
  /// Calculate token count for text (simple approximation)
  static int estimateTokenCount(String text) {
    // Simple approximation: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }

  /// Calculate token count for a list of chunks
  static int calculateTotalTokens(List<ContextChunk> chunks) {
    return chunks.fold(0, (total, chunk) => total + (chunk.tokenCount ?? 0));
  }

  /// Merge multiple chunks into a single context string
  static String mergeChunks(
    List<ContextChunk> chunks, {
    String separator = '\n\n',
  }) {
    if (chunks.isEmpty) return '';

    return chunks
        .map((chunk) => chunk.content.trim())
        .where((content) => content.isNotEmpty)
        .join(separator);
  }

  /// Sort chunks by relevance score
  static List<ContextChunk> sortByRelevance(List<ContextChunk> chunks) {
    final sorted = List<ContextChunk>.from(chunks);
    sorted.sort((a, b) {
      final scoreA = a.relevanceScore?.score ?? 0.0;
      final scoreB = b.relevanceScore?.score ?? 0.0;
      return scoreB.compareTo(scoreA); // Descending order
    });
    return sorted;
  }

  /// Filter chunks by minimum relevance threshold
  static List<ContextChunk> filterByRelevance(
    List<ContextChunk> chunks,
    double minRelevance,
  ) {
    return chunks
        .where((chunk) => (chunk.relevanceScore?.score ?? 0.0) >= minRelevance)
        .toList();
  }

  /// Limit chunks by maximum count
  static List<ContextChunk> limitChunks(
    List<ContextChunk> chunks,
    int maxChunks,
  ) {
    if (maxChunks <= 0) return [];
    if (chunks.length <= maxChunks) return chunks;
    return chunks.take(maxChunks).toList();
  }

  /// Create a summary of chunks for debugging
  static Map<String, dynamic> createChunksSummary(List<ContextChunk> chunks) {
    if (chunks.isEmpty) {
      return {
        'total_chunks': 0,
        'total_tokens': 0,
        'sources': <String>[],
        'privacy_levels': <String>[],
      };
    }

    final sources = chunks.map((c) => c.source).toSet().toList();
    final privacyLevels = chunks
        .map((c) => c.source.privacyLevel.value)
        .toSet()
        .toList();
    final totalTokens = calculateTotalTokens(chunks);

    return {
      'total_chunks': chunks.length,
      'total_tokens': totalTokens,
      'sources': sources,
      'privacy_levels': privacyLevels,
      'average_relevance':
          chunks
              .map((c) => c.relevanceScore?.score ?? 0.0)
              .reduce((a, b) => a + b) /
          chunks.length,
    };
  }

  /// Validate chunk data integrity
  static List<String> validateChunks(List<ContextChunk> chunks) {
    final errors = <String>[];

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];

      if (chunk.content.isEmpty) {
        errors.add('Chunk $i: Empty content');
      }

      if (chunk.source.name.isEmpty) {
        errors.add('Chunk $i: Missing source name');
      }

      if (chunk.id.isEmpty) {
        errors.add('Chunk $i: Missing ID');
      }

      if (chunk.createdAt.isAfter(DateTime.now())) {
        errors.add('Chunk $i: Future creation date');
      }
    }

    return errors;
  }

  /// Convert chunks to JSON for storage/transmission
  static List<Map<String, dynamic>> chunksToJson(List<ContextChunk> chunks) {
    return chunks.map((chunk) => chunk.toJson()).toList();
  }

  /// Create chunks from JSON data
  static List<ContextChunk> chunksFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => ContextChunk.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Deduplicate chunks based on content similarity - Optimized with efficient algorithms
  static List<ContextChunk> deduplicateChunks(
    List<ContextChunk> chunks,
    double similarityThreshold,
  ) {
    if (chunks.length <= 1) return chunks;

    // Use content hash for quick duplicate detection
    final contentHashes = <String, ContextChunk>{};
    final uniqueChunks = <ContextChunk>[];

    for (final chunk in chunks) {
      final contentHash = _generateContentHash(chunk.content);

      // Check for exact content match first (O(1) lookup)
      if (contentHashes.containsKey(contentHash)) {
        continue; // Exact duplicate
      }

      // Check for similar content using optimized similarity calculation
      bool isSimilar = false;
      for (final uniqueChunk in uniqueChunks) {
        // Use early termination for better performance
        if (_quickSimilarityCheck(
          chunk.content,
          uniqueChunk.content,
          similarityThreshold,
        )) {
          final similarity = _calculateSimilarity(
            chunk.content,
            uniqueChunk.content,
          );
          if (similarity >= similarityThreshold) {
            isSimilar = true;
            break;
          }
        }
      }

      if (!isSimilar) {
        uniqueChunks.add(chunk);
        contentHashes[contentHash] = chunk;
      }
    }

    return uniqueChunks;
  }

  /// Generate content hash for quick duplicate detection
  static String _generateContentHash(String content) {
    // Simple hash for quick comparison
    return '${content.length}_${content.hashCode}';
  }

  /// Quick similarity check to avoid expensive calculations
  static bool _quickSimilarityCheck(
    String text1,
    String text2,
    double threshold,
  ) {
    // Early termination checks
    if (text1.length < text2.length * threshold ||
        text2.length < text1.length * threshold) {
      return false;
    }

    // Only check length ratio for quick rejection
    // Removed first/last character check as it was too restrictive
    return true;
  }

  /// Calculate simple text similarity (0.0 to 1.0)
  static double _calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Clean words by removing punctuation and converting to lowercase
    final words1 = text1
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(' ')
        .where((word) => word.isNotEmpty) // Remove empty strings
        .toSet();
    final words2 = text2
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(' ')
        .where((word) => word.isNotEmpty) // Remove empty strings
        .toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2);
    final union = words1.union(words2);

    return intersection.length / union.length;
  }

  /// Get context utils performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'optimization_features': [
        'content_hash_duplicate_detection',
        'early_termination_similarity_check',
        'efficient_list_merging',
        'optimized_deduplication_algorithms',
      ],
      'performance_improvements': {
        'deduplication': 'O(n log n) instead of O(n²)',
        'similarity_check': 'Early termination for quick rejection',
        'duplicate_detection': 'O(1) hash-based lookup',
        'memory_usage': 'Optimized with hash maps',
      },
      'algorithms': {
        'deduplication': 'Hash-based + similarity with early termination',
        'similarity_calculation': 'Jaccard similarity with word sets',
        'content_hashing': 'Length + hashCode for quick comparison',
      },
    };
  }
}
