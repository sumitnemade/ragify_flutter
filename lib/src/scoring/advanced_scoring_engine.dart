import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';

import '../models/context_chunk.dart';
import '../models/relevance_score.dart';
import '../cache/cache_manager.dart';
import '../storage/vector_database.dart';
import '../utils/ragify_logger.dart';

/// Scoring algorithm configuration
class ScoringAlgorithmConfig {
  final String name;
  final double weight;
  final Map<String, dynamic> parameters;
  final bool enabled;

  const ScoringAlgorithmConfig({
    required this.name,
    required this.weight,
    this.parameters = const {},
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'weight': weight,
    'parameters': parameters,
    'enabled': enabled,
  };

  factory ScoringAlgorithmConfig.fromJson(Map<String, dynamic> json) {
    return ScoringAlgorithmConfig(
      name: json['name'] as String,
      weight: (json['weight'] as num).toDouble(),
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// Personalization profile for user behavior tracking
class UserProfile {
  final String userId;
  final Map<String, double> topicPreferences;
  final Map<String, double> sourcePreferences;
  final Map<String, double> contentTypePreferences;
  final List<String> recentQueries;
  final Map<String, int> queryFrequency;
  final DateTime lastActivity;
  final double engagementScore;

  UserProfile({
    required this.userId,
    this.topicPreferences = const {},
    this.sourcePreferences = const {},
    this.contentTypePreferences = const {},
    this.recentQueries = const [],
    this.queryFrequency = const {},
    DateTime? lastActivity,
    this.engagementScore = 0.0,
  }) : lastActivity = lastActivity ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'topic_preferences': topicPreferences,
    'source_preferences': sourcePreferences,
    'content_type_preferences': contentTypePreferences,
    'recent_queries': recentQueries,
    'query_frequency': queryFrequency,
    'last_activity': lastActivity.toIso8601String(),
    'engagement_score': engagementScore,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      topicPreferences: Map<String, double>.from(
        json['topic_preferences'] ?? {},
      ),
      sourcePreferences: Map<String, double>.from(
        json['source_preferences'] ?? {},
      ),
      contentTypePreferences: Map<String, double>.from(
        json['content_type_preferences'] ?? {},
      ),
      recentQueries: List<String>.from(json['recent_queries'] ?? []),
      queryFrequency: Map<String, int>.from(json['query_frequency'] ?? {}),
      lastActivity: DateTime.parse(json['last_activity'] as String),
      engagementScore: (json['engagement_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Update user preferences based on interaction
  UserProfile updatePreferences({
    String? topic,
    String? source,
    String? contentType,
    String? query,
    double interactionScore = 1.0,
  }) {
    final newTopicPreferences = Map<String, double>.from(topicPreferences);
    final newSourcePreferences = Map<String, double>.from(sourcePreferences);
    final newContentTypePreferences = Map<String, double>.from(
      contentTypePreferences,
    );
    final newQueryFrequency = Map<String, int>.from(queryFrequency);
    final newRecentQueries = List<String>.from(recentQueries);

    if (topic != null) {
      newTopicPreferences[topic] =
          (newTopicPreferences[topic] ?? 0.0) + interactionScore;
    }

    if (source != null) {
      newSourcePreferences[source] =
          (newSourcePreferences[source] ?? 0.0) + interactionScore;
    }

    if (contentType != null) {
      newContentTypePreferences[contentType] =
          (newContentTypePreferences[contentType] ?? 0.0) + interactionScore;
    }

    if (query != null) {
      newQueryFrequency[query] = (newQueryFrequency[query] ?? 0) + 1;
      if (!newRecentQueries.contains(query)) {
        newRecentQueries.insert(0, query);
        if (newRecentQueries.length > 10) {
          newRecentQueries.removeLast();
        }
      }
    }

    return UserProfile(
      userId: userId,
      topicPreferences: newTopicPreferences,
      sourcePreferences: newSourcePreferences,
      contentTypePreferences: newContentTypePreferences,
      recentQueries: newRecentQueries,
      queryFrequency: newQueryFrequency,
      lastActivity: DateTime.now(),
      engagementScore: engagementScore + interactionScore * 0.1,
    );
  }
}

/// Temporal decay function for relevance scoring
class TemporalDecayFunction {
  final double halfLife;
  final double decayRate;
  final DateTime referenceDate;

  TemporalDecayFunction({
    this.halfLife = 30.0, // days
    this.decayRate = 0.5,
    DateTime? referenceDate,
  }) : referenceDate = referenceDate ?? DateTime.now();

  /// Calculate temporal relevance score
  double calculateScore(DateTime contentDate) {
    final daysDiff = referenceDate.difference(contentDate).inDays.toDouble();
    if (daysDiff <= 0) return 1.0; // Future content gets full score

    // Exponential decay function
    final decayFactor = pow(decayRate, daysDiff / halfLife).toDouble();
    return decayFactor.clamp(0.0, 1.0);
  }

  /// Get decay parameters
  Map<String, dynamic> getParameters() => {
    'half_life': halfLife,
    'decay_rate': decayRate,
    'reference_date': referenceDate.toIso8601String(),
  };
}

/// Semantic similarity scoring using vector operations
class SemanticSimilarityScorer {
  final VectorDatabase vectorDatabase;
  final double similarityThreshold;
  final int maxSimilarityChecks;

  SemanticSimilarityScorer({
    required this.vectorDatabase,
    this.similarityThreshold = 0.7,
    this.maxSimilarityChecks = 100,
  });

  /// Calculate semantic similarity score between query and content
  Future<double> calculateSimilarity(String query, String content) async {
    try {
      // Get embeddings for query and content
      final queryEmbedding = await _getEmbedding(query);
      final contentEmbedding = await _getEmbedding(content);

      if (queryEmbedding == null || contentEmbedding == null) {
        return 0.0;
      }

      // Calculate cosine similarity
      final similarity = _cosineSimilarity(queryEmbedding, contentEmbedding);
      return similarity.clamp(0.0, 1.0);
    } catch (e) {
      Logger().e('Error calculating semantic similarity: $e');
      return 0.0;
    }
  }

  /// Calculate cosine similarity between two vectors
  double _cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    if (vectorA.length != vectorB.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Get embedding for text (placeholder for actual embedding service)
  Future<List<double>?> _getEmbedding(String text) async {
    // TODO: Implement actual embedding service
    // For now, return a simple hash-based vector
    try {
      final hash = text.hashCode;
      final vector = List<double>.generate(128, (i) {
        final seed = (hash + i * 31) % 1000;
        return (seed / 1000.0) * 2.0 - 1.0; // Normalize to [-1, 1]
      });
      return vector;
    } catch (e) {
      Logger().e('Error generating embedding: $e');
      return null;
    }
  }
}

/// Scoring function signature
typedef ScoringFunction =
    double Function(
      ContextChunk chunk,
      String query, {
      UserProfile? userProfile,
      Map<String, dynamic>? context,
    });

/// Multi-algorithm scoring engine
class MultiAlgorithmScorer {
  final List<ScoringAlgorithmConfig> algorithms;
  final Map<String, ScoringFunction> scoringFunctions;

  MultiAlgorithmScorer({
    required this.algorithms,
    required this.scoringFunctions,
  });

  /// Calculate weighted score using multiple algorithms
  double calculateWeightedScore(
    ContextChunk chunk,
    String query, {
    UserProfile? userProfile,
    Map<String, dynamic>? context,
  }) {
    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (final algorithm in algorithms) {
      if (!algorithm.enabled) continue;

      final function = scoringFunctions[algorithm.name];
      if (function != null) {
        try {
          final score = function(
            chunk,
            query,
            userProfile: userProfile,
            context: context,
          );
          totalScore += score * algorithm.weight;
          totalWeight += algorithm.weight;
        } catch (e) {
          Logger().e('Error in scoring algorithm ${algorithm.name}: $e');
        }
      }
    }

    if (totalWeight == 0.0) return 0.0;
    return totalScore / totalWeight;
  }

  /// Get algorithm statistics
  Map<String, dynamic> getAlgorithmStats() {
    return {
      'total_algorithms': algorithms.length,
      'enabled_algorithms': algorithms.where((a) => a.enabled).length,
      'algorithms': algorithms.map((a) => a.toJson()).toList(),
    };
  }
}

/// Main Advanced Scoring Engine
class AdvancedScoringEngine {
  final CacheManager cacheManager;
  final VectorDatabase vectorDatabase;
  final RAGifyLogger _logger;

  late MultiAlgorithmScorer _multiAlgorithmScorer;
  late final TemporalDecayFunction _temporalDecay;

  final Map<String, UserProfile> _userProfiles = {};
  final Map<String, ScoringAlgorithmConfig> _algorithmConfigs = {};
  final Map<String, ScoringFunction> _scoringFunctions = {};

  AdvancedScoringEngine({
    required this.cacheManager,
    required this.vectorDatabase,
    RAGifyLogger? logger,
  }) : _logger = logger ?? const RAGifyLogger.disabled() {
    _logger.d('Initializing Advanced Scoring Engine');
    _initializeScoringFunctions();
    _initializeDefaultAlgorithms();
    _multiAlgorithmScorer = MultiAlgorithmScorer(
      algorithms: _algorithmConfigs.values.toList(),
      scoringFunctions: _scoringFunctions,
    );

    _temporalDecay = TemporalDecayFunction();
    _logger.d('Advanced Scoring Engine initialized successfully');
  }

  /// Initialize default scoring functions
  void _initializeScoringFunctions() {
    _scoringFunctions['content_relevance'] = _contentRelevanceScore;
    _scoringFunctions['semantic_similarity'] = _semanticSimilarityScore;
    _scoringFunctions['temporal_relevance'] = _temporalRelevanceScore;
    _scoringFunctions['source_authority'] = _sourceAuthorityScore;
    _scoringFunctions['user_personalization'] = _userPersonalizationScore;
    _scoringFunctions['content_freshness'] = _contentFreshnessScore;
    _scoringFunctions['engagement_potential'] = _engagementPotentialScore;
  }

  /// Initialize default algorithm configurations
  void _initializeDefaultAlgorithms() {
    _algorithmConfigs['content_relevance'] = const ScoringAlgorithmConfig(
      name: 'content_relevance',
      weight: 0.25,
      parameters: {'min_length': 10, 'max_length': 10000},
    );

    _algorithmConfigs['semantic_similarity'] = const ScoringAlgorithmConfig(
      name: 'semantic_similarity',
      weight: 0.30,
      parameters: {'similarity_threshold': 0.7},
    );

    _algorithmConfigs['temporal_relevance'] = const ScoringAlgorithmConfig(
      name: 'temporal_relevance',
      weight: 0.15,
      parameters: {'half_life': 30.0, 'decay_rate': 0.5},
    );

    _algorithmConfigs['source_authority'] = const ScoringAlgorithmConfig(
      name: 'source_authority',
      weight: 0.10,
      parameters: {'min_authority': 0.5},
    );

    _algorithmConfigs['user_personalization'] = const ScoringAlgorithmConfig(
      name: 'user_personalization',
      weight: 0.15,
      parameters: {'personalization_strength': 0.8},
    );

    _algorithmConfigs['content_freshness'] = const ScoringAlgorithmConfig(
      name: 'content_freshness',
      weight: 0.05,
      parameters: {'freshness_weight': 0.3},
    );
  }

  /// Calculate advanced relevance score for a context chunk
  Future<RelevanceScore> calculateAdvancedScore(
    ContextChunk chunk,
    String query, {
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    final cacheKey =
        'score_${chunk.id}_${query.hashCode}_${userId ?? 'anonymous'}';

    // Check cache first
    final cachedScore = await cacheManager.get(cacheKey);
    if (cachedScore != null) {
      return RelevanceScore.fromJson(cachedScore);
    }

    // Get user profile if available
    final userProfile = userId != null ? _userProfiles[userId] : null;

    // Calculate weighted score using multiple algorithms
    final weightedScore = _multiAlgorithmScorer.calculateWeightedScore(
      chunk,
      query,
      userProfile: userProfile,
      context: context,
    );

    // Calculate confidence interval
    final confidenceInterval = _calculateConfidenceInterval(
      chunk,
      query,
      weightedScore,
    );

    // Create relevance score
    final relevanceScore = RelevanceScore(
      score: weightedScore,
      confidenceLower: confidenceInterval['lower_bound'],
      confidenceUpper: confidenceInterval['upper_bound'],
      confidenceLevel: confidenceInterval['confidence'],
    );

    // Cache the result
    await cacheManager.set(
      cacheKey,
      relevanceScore.toJson(),
      ttl: Duration(minutes: 30),
    );

    return relevanceScore;
  }

  /// Calculate confidence interval for the score
  Map<String, dynamic> _calculateConfidenceInterval(
    ContextChunk chunk,
    String query,
    double score,
  ) {
    // Simple confidence calculation based on content length and source authority
    double confidence = 0.8; // Base confidence

    // Adjust based on content length
    if (chunk.content.length < 50) {
      confidence -= 0.2;
    } else if (chunk.content.length > 1000) {
      confidence += 0.1;
    }

    // Adjust based on source authority
    if (chunk.source.authorityScore > 0.8) {
      confidence += 0.1;
    } else if (chunk.source.authorityScore < 0.3) {
      confidence -= 0.2;
    }

    // Adjust based on score extremity
    if (score < 0.1 || score > 0.9) {
      confidence -= 0.1;
    }

    return {
      'confidence': confidence.clamp(0.0, 1.0),
      'lower_bound': (score - (1.0 - confidence) * 0.5).clamp(0.0, 1.0),
      'upper_bound': (score + (1.0 - confidence) * 0.5).clamp(0.0, 1.0),
    };
  }

  /// Content relevance scoring function
  double _contentRelevanceScore(
    ContextChunk chunk,
    String query, {
    UserProfile? userProfile,
    Map<String, dynamic>? context,
  }) {
    final queryLower = query.toLowerCase();
    final contentLower = chunk.content.toLowerCase();

    // Basic text matching
    double score = 0.0;

    // Exact phrase matching
    if (contentLower.contains(queryLower)) {
      score += 0.6;
    }

    // Word matching
    final queryWords = queryLower.split(' ');
    final contentWords = contentLower.split(' ');
    final matchedWords = queryWords
        .where((word) => contentWords.contains(word))
        .length;
    score += (matchedWords / queryWords.length) * 0.4;

    // Length adjustment
    final lengthRatio = chunk.content.length / 1000.0;
    if (lengthRatio > 0.1 && lengthRatio < 2.0) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Semantic similarity scoring function
  double _semanticSimilarityScore(
    ContextChunk chunk,
    String query, {
    UserProfile? userProfile,
    Map<String, dynamic>? context,
  }) {
    // This would normally use the semantic scorer, but for now return a placeholder
    // Placeholder implementation for semantic similarity
    return 0.5; // Placeholder score
  }

  /// Temporal relevance scoring function
  double _temporalRelevanceScore(
    ContextChunk chunk,
    String query, {
    UserProfile? userProfile,
    Map<String, dynamic>? context,
  }) {
    return _temporalDecay.calculateScore(chunk.createdAt);
  }

  /// Source authority scoring function
  double _sourceAuthorityScore(
    ContextChunk chunk,
    String query, {
    UserProfile? userProfile,
    Map<String, dynamic>? context,
  }) {
    return chunk.source.authorityScore;
  }

  /// User personalization scoring function
  double _userPersonalizationScore(
    ContextChunk chunk,
    String query, {
    UserProfile? userProfile,
    Map<String, dynamic>? context,
  }) {
    if (userProfile == null) {
      return 0.5; // Neutral score for anonymous users
    }

    double score = 0.5; // Base score

    // Topic preference matching
    for (final topic in chunk.tags) {
      final preference = userProfile.topicPreferences[topic] ?? 0.0;
      score += preference * 0.1;
    }

    // Source preference matching
    final sourcePreference =
        userProfile.sourcePreferences[chunk.source.name] ?? 0.0;
    score += sourcePreference * 0.2;

    // Content type preference matching
    final contentType = chunk.metadata['content_type'] ?? 'text';
    final contentTypePreference =
        userProfile.contentTypePreferences[contentType] ?? 0.0;
    score += contentTypePreference * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Content freshness scoring function
  double _contentFreshnessScore(
    ContextChunk chunk,
    String query, {
    UserProfile? userProfile,
    Map<String, dynamic>? context,
  }) {
    final now = DateTime.now();
    final age = now.difference(chunk.updatedAt).inDays;

    if (age == 0) {
      return 1.0; // Today
    }
    if (age <= 7) {
      return 0.9; // This week
    }
    if (age <= 30) {
      return 0.7; // This month
    }
    if (age <= 90) {
      return 0.5; // This quarter
    }
    if (age <= 365) {
      return 0.3; // This year
    }
    return 0.1; // Older
  }

  /// Engagement potential scoring function
  double _engagementPotentialScore(
    ContextChunk chunk,
    String query, {
    UserProfile? userProfile,
    Map<String, dynamic>? context,
  }) {
    double score = 0.5; // Base score

    // Content length factor
    final length = chunk.content.length;
    if (length > 100 && length < 2000) {
      score += 0.2;
    }

    // Tag diversity
    if (chunk.tags.length > 2) {
      score += 0.1;
    }

    // Metadata richness
    if (chunk.metadata.length > 3) {
      score += 0.1;
    }

    // Source freshness
    final sourceAge = DateTime.now()
        .difference(chunk.source.lastUpdated)
        .inDays;
    if (sourceAge <= 30) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Update user profile based on interaction
  void updateUserProfile(
    String userId, {
    String? topic,
    String? source,
    String? contentType,
    String? query,
    double interactionScore = 1.0,
  }) {
    final currentProfile = _userProfiles[userId] ?? UserProfile(userId: userId);
    final updatedProfile = currentProfile.updatePreferences(
      topic: topic,
      source: source,
      contentType: contentType,
      query: query,
      interactionScore: interactionScore,
    );
    _userProfiles[userId] = updatedProfile;
  }

  /// Get user profile
  UserProfile? getUserProfile(String userId) {
    return _userProfiles[userId];
  }

  /// Update algorithm configuration
  void updateAlgorithmConfig(
    String algorithmName,
    ScoringAlgorithmConfig config,
  ) {
    _algorithmConfigs[algorithmName] = config;
    _multiAlgorithmScorer = MultiAlgorithmScorer(
      algorithms: _algorithmConfigs.values.toList(),
      scoringFunctions: _scoringFunctions,
    );
  }

  /// Get engine statistics
  Map<String, dynamic> getStats() {
    return {
      'total_algorithms': _algorithmConfigs.length,
      'enabled_algorithms': _algorithmConfigs.values
          .where((a) => a.enabled)
          .length,
      'total_user_profiles': _userProfiles.length,
      'cache_stats': cacheManager.getStats(),
      'vector_db_stats': vectorDatabase.getStats(),
      'algorithm_configs': _algorithmConfigs.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
    };
  }

  /// A/B testing for scoring algorithms
  Future<Map<String, dynamic>> runABTest({
    required String testName,
    required List<ContextChunk> testChunks,
    required String query,
    required ScoringAlgorithmConfig variantA,
    required ScoringAlgorithmConfig variantB,
    int iterations = 100,
  }) async {
    final results = <String, List<double>>{'variant_a': [], 'variant_b': []};

    for (int i = 0; i < iterations; i++) {
      // Test variant A
      final scorerA = MultiAlgorithmScorer(
        algorithms: [variantA],
        scoringFunctions: _scoringFunctions,
      );

      // Test variant B
      final scorerB = MultiAlgorithmScorer(
        algorithms: [variantB],
        scoringFunctions: _scoringFunctions,
      );

      for (final chunk in testChunks) {
        final scoreA = scorerA.calculateWeightedScore(chunk, query);
        final scoreB = scorerB.calculateWeightedScore(chunk, query);

        results['variant_a']!.add(scoreA);
        results['variant_b']!.add(scoreB);
      }
    }

    // Calculate statistics
    final avgA =
        results['variant_a']!.reduce((a, b) => a + b) /
        results['variant_a']!.length;
    final avgB =
        results['variant_b']!.reduce((a, b) => a + b) /
        results['variant_b']!.length;

    return {
      'test_name': testName,
      'iterations': iterations,
      'variant_a': {
        'config': variantA.toJson(),
        'average_score': avgA,
        'scores': results['variant_a'],
      },
      'variant_b': {
        'config': variantB.toJson(),
        'average_score': avgB,
        'scores': results['variant_b'],
      },
      'improvement': avgB - avgA,
      'improvement_percentage': ((avgB - avgA) / avgA * 100).toStringAsFixed(2),
    };
  }
}
