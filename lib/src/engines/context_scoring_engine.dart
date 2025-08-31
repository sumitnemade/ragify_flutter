import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';

import '../models/context_chunk.dart';
import '../models/context_source.dart';
import '../models/relevance_score.dart';
import '../models/privacy_level.dart';
import '../exceptions/ragify_exceptions.dart';

/// Context Scoring Engine
///
/// Provides intelligent relevance scoring for context chunks using
/// multiple scoring algorithms and confidence intervals.
class ContextScoringEngine {
  /// Logger instance
  final Logger logger;

  /// Scoring algorithms configuration
  final Map<String, double> algorithmWeights;

  /// Confidence level for scoring (0.0 to 1.0)
  final double confidenceLevel;

  /// Random number generator for reproducible results (unused but kept for future use)
  // ignore: unused_field
  final Random _random;

  /// Create a new scoring engine
  ContextScoringEngine({
    Logger? logger,
    Map<String, double>? algorithmWeights,
    this.confidenceLevel = 0.95,
  }) : logger = logger ?? Logger(),
       algorithmWeights =
           algorithmWeights ??
           {
             'semantic': 0.4,
             'temporal': 0.2,
             'source_authority': 0.2,
             'content_quality': 0.2,
           },
       _random = Random(42); // Fixed seed for reproducible results

  /// Score a list of context chunks for relevance to a query
  ///
  /// [chunks] - List of context chunks to score
  /// [query] - Query string for relevance assessment
  /// [userId] - Optional user ID for personalization
  /// [sessionId] - Optional session ID for context continuity
  ///
  /// Returns chunks with relevance scores attached
  Future<List<ContextChunk>> scoreChunks({
    required List<ContextChunk> chunks,
    required String query,
    String? userId,
    String? sessionId,
  }) async {
    if (chunks.isEmpty) return chunks;

    logger.i('Scoring ${chunks.length} context chunks for query: $query');

    try {
      final scoredChunks = <ContextChunk>[];

      for (final chunk in chunks) {
        final relevanceScore = await _calculateRelevanceScore(
          chunk: chunk,
          query: query,
          userId: userId,
          sessionId: sessionId,
        );

        final scoredChunk = chunk.copyWith(relevanceScore: relevanceScore);

        scoredChunks.add(scoredChunk);
      }

      logger.i('Scoring completed for ${chunks.length} chunks');
      return scoredChunks;
    } catch (e, stackTrace) {
      logger.e('Scoring failed', error: e, stackTrace: stackTrace);
      throw ScoringException('multi_algorithm_scoring', reason: e.toString());
    }
  }

  /// Calculate comprehensive relevance score for a chunk
  Future<RelevanceScore> _calculateRelevanceScore({
    required ContextChunk chunk,
    required String query,
    String? userId,
    String? sessionId,
  }) async {
    final scores = <String, double>{};

    // Semantic relevance scoring
    scores['semantic'] = await _calculateSemanticRelevance(
      chunk.content,
      query,
    );

    // Temporal relevance scoring
    scores['temporal'] = _calculateTemporalRelevance(chunk);

    // Source authority scoring
    scores['source_authority'] = _calculateSourceAuthorityScore(chunk.source);

    // Content quality scoring
    scores['content_quality'] = _calculateContentQualityScore(chunk);

    // User personalization scoring (if available)
    if (userId != null) {
      scores['personalization'] = await _calculatePersonalizationScore(
        chunk: chunk,
        userId: userId,
        sessionId: sessionId,
      );
    }

    // Calculate weighted final score
    final finalScore = _calculateWeightedScore(scores);

    // Calculate confidence interval
    final confidenceInterval = _calculateConfidenceInterval(scores, finalScore);

    return RelevanceScore(
      score: finalScore,
      confidenceLower: confidenceInterval['lower'],
      confidenceUpper: confidenceInterval['upper'],
      confidenceLevel: confidenceLevel,
    );
  }

  /// Calculate semantic relevance between content and query
  Future<double> _calculateSemanticRelevance(
    String content,
    String query,
  ) async {
    // TODO: Implement real semantic similarity using embeddings
    // For now, use advanced text-based similarity as placeholder

    final contentWords = _tokenizeText(content);
    final queryWords = _tokenizeText(query);

    if (queryWords.isEmpty) return 0.0;

    // Calculate TF-IDF inspired scoring
    final contentWordFreq = _calculateWordFrequency(contentWords);
    final queryWordFreq = _calculateWordFrequency(queryWords);

    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (final queryWord in queryWordFreq.keys) {
      final queryWeight = queryWordFreq[queryWord]!;
      final contentWeight = contentWordFreq[queryWord] ?? 0.0;

      // Higher score for exact matches
      final matchScore = contentWeight > 0 ? 1.0 : 0.0;

      // Bonus for frequency alignment
      final frequencyBonus = contentWeight > 0
          ? (contentWeight / contentWords.length).clamp(0.0, 0.5)
          : 0.0;

      final wordScore = matchScore + frequencyBonus;
      totalScore += wordScore * queryWeight;
      totalWeight += queryWeight;
    }

    if (totalWeight == 0) return 0.0;
    return (totalScore / totalWeight).clamp(0.0, 1.0);
  }

  /// Calculate temporal relevance based on chunk age
  double _calculateTemporalRelevance(ContextChunk chunk) {
    final ageInDays = DateTime.now().difference(chunk.createdAt).inDays;

    // Exponential decay with half-life of 30 days
    if (ageInDays <= 0) return 1.0;

    final halfLife = 30.0;
    final decayRate = log(0.5) / halfLife;

    return exp(decayRate * ageInDays).clamp(0.0, 1.0);
  }

  /// Calculate source authority score
  double _calculateSourceAuthorityScore(ContextSource source) {
    double score = source.authorityScore;

    // Boost for enterprise sources
    if (source.privacyLevel == PrivacyLevel.enterprise) {
      score *= 1.2;
    }

    // Boost for recently updated sources
    final daysSinceUpdate = DateTime.now()
        .difference(source.lastUpdated)
        .inDays;
    if (daysSinceUpdate <= 7) {
      score *= 1.1;
    }

    // Boost for active sources
    if (source.isActive) {
      score *= 1.05;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate content quality score
  double _calculateContentQualityScore(ContextChunk chunk) {
    double score = 0.5; // Base score

    // Length-based scoring (optimal length around 100-500 characters)
    final length = chunk.content.length;
    if (length >= 50 && length <= 1000) {
      score += 0.2;
    } else if (length > 1000) {
      score += 0.1;
    }

    // Metadata richness
    if (chunk.metadata.isNotEmpty) {
      score += 0.1;
    }

    // Tags presence
    if (chunk.tags.isNotEmpty) {
      score += 0.1;
    }

    // Embedding availability
    if (chunk.hasEmbedding) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate personalization score based on user preferences
  Future<double> _calculatePersonalizationScore({
    required ContextChunk chunk,
    required String userId,
    String? sessionId,
  }) async {
    // TODO: Implement real user preference scoring
    // For now, return a neutral score

    // This should integrate with user preference systems
    // and learning algorithms in the future

    return 0.5;
  }

  /// Calculate weighted final score from individual scores
  double _calculateWeightedScore(Map<String, double> scores) {
    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (final entry in scores.entries) {
      final algorithm = entry.key;
      final score = entry.value;
      final weight = algorithmWeights[algorithm] ?? 0.0;

      weightedSum += score * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return 0.0;
    return (weightedSum / totalWeight).clamp(0.0, 1.0);
  }

  /// Calculate confidence interval for the final score
  Map<String, double> _calculateConfidenceInterval(
    Map<String, double> scores,
    double finalScore,
  ) {
    if (scores.isEmpty) {
      return {'lower': finalScore, 'upper': finalScore};
    }

    // Calculate standard deviation of scores
    final scoreValues = scores.values.toList();
    final mean = scoreValues.reduce((a, b) => a + b) / scoreValues.length;

    final variance =
        scoreValues
            .map((score) => pow(score - mean, 2))
            .reduce((a, b) => a + b) /
        scoreValues.length;

    final standardDeviation = sqrt(variance);

    // Calculate confidence interval using normal distribution
    final zScore = _getZScore(confidenceLevel);
    final marginOfError = zScore * standardDeviation / sqrt(scoreValues.length);

    return {
      'lower': (finalScore - marginOfError).clamp(0.0, 1.0),
      'upper': (finalScore + marginOfError).clamp(0.0, 1.0),
    };
  }

  /// Get Z-score for confidence level
  double _getZScore(double confidenceLevel) {
    // Common Z-scores for confidence levels
    switch (confidenceLevel) {
      case 0.90:
        return 1.645;
      case 0.95:
        return 1.96;
      case 0.99:
        return 2.576;
      default:
        return 1.96; // Default to 95% confidence
    }
  }

  /// Tokenize text into words
  List<String> _tokenizeText(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^\w\s]'))
        .join(' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toList();
  }

  /// Calculate word frequency in text
  Map<String, double> _calculateWordFrequency(List<String> words) {
    final frequency = <String, int>{};

    for (final word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    // Convert to normalized frequencies
    final totalWords = words.length;
    return frequency.map((word, count) => MapEntry(word, count / totalWords));
  }

  /// Get scoring engine statistics
  Map<String, dynamic> getStats() {
    return {
      'algorithm_weights': algorithmWeights,
      'confidence_level': confidenceLevel,
      'total_algorithms': algorithmWeights.length,
    };
  }
}
