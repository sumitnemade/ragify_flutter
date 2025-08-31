import 'dart:async';
import 'package:logger/logger.dart';

import '../models/context_chunk.dart';
import '../models/context_source.dart';
import '../models/privacy_level.dart';
import '../exceptions/ragify_exceptions.dart';

/// Intelligent Context Fusion Engine
///
/// Handles conflict detection and resolution between data sources using
/// source authority, freshness, and semantic similarity analysis.
class IntelligentContextFusionEngine {
  /// Logger instance
  final Logger logger;

  /// Conflict detection threshold (0.0 to 1.0)
  final double conflictThreshold;

  /// Authority weight for conflict resolution
  final double authorityWeight;

  /// Freshness weight for conflict resolution
  final double freshnessWeight;

  /// Semantic similarity weight for conflict resolution
  final double semanticWeight;

  /// Create a new fusion engine
  IntelligentContextFusionEngine({
    Logger? logger,
    this.conflictThreshold = 0.7,
    this.authorityWeight = 0.4,
    this.freshnessWeight = 0.3,
    this.semanticWeight = 0.3,
  }) : logger = logger ?? Logger();

  /// Fuse context chunks from multiple sources
  ///
  /// [chunks] - List of context chunks to fuse
  /// [query] - Original query for context
  /// [userId] - Optional user ID for personalization
  ///
  /// Returns fused chunks with conflicts resolved
  Future<List<ContextChunk>> fuseChunks({
    required List<ContextChunk> chunks,
    required String query,
    String? userId,
  }) async {
    if (chunks.isEmpty) return chunks;

    logger.i('Fusing ${chunks.length} context chunks');

    try {
      // Group chunks by semantic similarity
      final groupedChunks = await _groupBySemanticSimilarity(chunks, query);

      // Detect and resolve conflicts within each group
      final fusedChunks = <ContextChunk>[];

      for (final group in groupedChunks) {
        if (group.length == 1) {
          fusedChunks.add(group.first);
        } else {
          final resolvedChunks = await _resolveConflicts(group, query, userId);
          fusedChunks.addAll(resolvedChunks);
        }
      }

      logger.i(
        'Fusion completed: ${chunks.length} → ${fusedChunks.length} chunks',
      );
      return fusedChunks;
    } catch (e, stackTrace) {
      logger.e('Fusion failed', error: e, stackTrace: stackTrace);
      throw FusionException('semantic_grouping', chunks.length);
    }
  }

  /// Group chunks by semantic similarity
  Future<List<List<ContextChunk>>> _groupBySemanticSimilarity(
    List<ContextChunk> chunks,
    String query,
  ) async {
    final groups = <List<ContextChunk>>[];
    final processed = <String>{};

    for (int i = 0; i < chunks.length; i++) {
      if (processed.contains(chunks[i].id)) continue;

      final group = <ContextChunk>[chunks[i]];
      processed.add(chunks[i].id);

      for (int j = i + 1; j < chunks.length; j++) {
        if (processed.contains(chunks[j].id)) continue;

        final similarity = await _calculateSemanticSimilarity(
          chunks[i].content,
          chunks[j].content,
        );

        if (similarity >= conflictThreshold) {
          group.add(chunks[j]);
          processed.add(chunks[j].id);
        }
      }

      groups.add(group);
    }

    return groups;
  }

  /// Calculate semantic similarity between two text chunks
  Future<double> _calculateSemanticSimilarity(
    String text1,
    String text2,
  ) async {
    // TODO: Implement real semantic similarity using embeddings
    // For now, use a simple text-based similarity as placeholder
    // This should be replaced with actual embedding-based similarity

    final words1 = text1.toLowerCase().split(RegExp(r'\s+'));
    final words2 = text2.toLowerCase().split(RegExp(r'\s+'));

    final intersection = words1.where((word) => words2.contains(word)).length;
    final union = words1.length + words2.length - intersection;

    if (union == 0) return 0.0;
    return intersection / union;
  }

  /// Resolve conflicts within a group of similar chunks
  Future<List<ContextChunk>> _resolveConflicts(
    List<ContextChunk> chunks,
    String query,
    String? userId,
  ) async {
    if (chunks.length == 1) return chunks;

    logger.d('Resolving conflicts in group of ${chunks.length} chunks');

    // Calculate conflict scores for each chunk
    final scoredChunks = await _scoreChunksForConflictResolution(chunks, query);

    // Sort by conflict resolution score (higher = better)
    scoredChunks.sort(
      (a, b) => b.conflictResolutionScore.compareTo(a.conflictResolutionScore),
    );

    // Return top chunks (avoiding exact duplicates)
    final resolvedChunks = <ContextChunk>[];
    final seenContent = <String>{};

    for (final chunk in scoredChunks) {
      final normalizedContent = _normalizeContent(chunk.content);
      if (!seenContent.contains(normalizedContent)) {
        resolvedChunks.add(chunk);
        seenContent.add(normalizedContent);
      }

      // Limit to prevent information overload
      if (resolvedChunks.length >= 3) break;
    }

    return resolvedChunks;
  }

  /// Score chunks for conflict resolution
  Future<List<ContextChunk>> _scoreChunksForConflictResolution(
    List<ContextChunk> chunks,
    String query,
  ) async {
    final scoredChunks = <ContextChunk>[];

    for (final chunk in chunks) {
      final authorityScore = _calculateAuthorityScore(chunk.source);
      final freshnessScore = _calculateFreshnessScore(chunk);
      final semanticScore = await _calculateQueryRelevance(
        chunk.content,
        query,
      );

      final conflictResolutionScore =
          (authorityScore * authorityWeight) +
          (freshnessScore * freshnessWeight) +
          (semanticScore * semanticWeight);

      // Create a copy with the conflict resolution score
      final scoredChunk = chunk.copyWith(
        metadata: {
          ...chunk.metadata,
          'conflict_resolution_score': conflictResolutionScore,
          'authority_score': authorityScore,
          'freshness_score': freshnessScore,
          'semantic_score': semanticScore,
        },
      );

      scoredChunks.add(scoredChunk);
    }

    return scoredChunks;
  }

  /// Calculate authority score based on source properties
  double _calculateAuthorityScore(ContextSource source) {
    // Base authority from source configuration
    double score = source.authorityScore;

    // Boost for enterprise sources
    if (source.privacyLevel == PrivacyLevel.enterprise) {
      score *= 1.2;
    }

    // Boost for active sources
    if (source.isActive) {
      score *= 1.1;
    }

    // Boost for recent updates
    final daysSinceUpdate = DateTime.now()
        .difference(source.lastUpdated)
        .inDays;
    if (daysSinceUpdate <= 7) {
      score *= 1.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate freshness score based on chunk age
  double _calculateFreshnessScore(ContextChunk chunk) {
    final ageInDays = DateTime.now().difference(chunk.createdAt).inDays;

    if (ageInDays == 0) return 1.0;
    if (ageInDays <= 1) return 0.9;
    if (ageInDays <= 7) return 0.8;
    if (ageInDays <= 30) return 0.6;
    if (ageInDays <= 90) return 0.4;

    return 0.2;
  }

  /// Calculate semantic relevance to the query
  Future<double> _calculateQueryRelevance(String content, String query) async {
    // TODO: Implement real semantic relevance using embeddings
    // For now, use simple keyword matching as placeholder

    final contentWords = content.toLowerCase().split(RegExp(r'\s+'));
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));

    final matches = queryWords
        .where((word) => contentWords.contains(word))
        .length;

    if (queryWords.isEmpty) return 0.0;
    return (matches / queryWords.length).clamp(0.0, 1.0);
  }

  /// Normalize content for duplicate detection
  String _normalizeContent(String content) {
    return content.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Get fusion statistics
  Map<String, dynamic> getStats() {
    return {
      'conflict_threshold': conflictThreshold,
      'authority_weight': authorityWeight,
      'freshness_weight': freshnessWeight,
      'semantic_weight': semanticWeight,
    };
  }
}

/// Extension to add conflict resolution score to ContextChunk
extension ConflictResolutionScore on ContextChunk {
  /// Get the conflict resolution score from metadata
  double get conflictResolutionScore {
    return metadata['conflict_resolution_score'] as double? ?? 0.0;
  }
}
