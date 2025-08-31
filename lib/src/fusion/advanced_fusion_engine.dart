import 'dart:async';
import 'dart:math' as math;
import 'dart:isolate';
import 'package:logger/logger.dart';

import '../models/context_chunk.dart';

import '../storage/vector_database.dart';
import '../cache/cache_manager.dart';

/// Configuration for fusion strategies
class FusionStrategyConfig {
  final String name;
  final double weight;
  final Map<String, dynamic> parameters;
  final bool enabled;

  const FusionStrategyConfig({
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

  factory FusionStrategyConfig.fromJson(Map<String, dynamic> json) {
    return FusionStrategyConfig(
      name: json['name'] as String,
      weight: json['weight'] as double,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// **NEW: Parallel processing configuration**
class FusionParallelProcessingConfig {
  final int maxIsolates;
  final int chunkSize;
  final bool enableParallelProcessing;
  final Duration timeout;

  const FusionParallelProcessingConfig({
    this.maxIsolates = 4,
    this.chunkSize = 100,
    this.enableParallelProcessing = true,
    this.timeout = const Duration(seconds: 30),
  });

  Map<String, dynamic> toJson() => {
    'max_isolates': maxIsolates,
    'chunk_size': chunkSize,
    'enable_parallel_processing': enableParallelProcessing,
    'timeout_seconds': timeout.inSeconds,
  };
}

/// **NEW: Isolate message for parallel processing**
class FusionIsolateMessage {
  final String type;
  final Map<String, dynamic> data;

  const FusionIsolateMessage({required this.type, required this.data});

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  factory FusionIsolateMessage.fromJson(Map<String, dynamic> json) {
    return FusionIsolateMessage(
      type: json['type'] as String,
      data: Map<String, dynamic>.from(json['data']),
    );
  }
}

/// **NEW: Parallel processing result**
class FusionParallelProcessingResult<T> {
  final List<T> results;
  final Duration processingTime;
  final int isolatesUsed;
  final Map<String, dynamic> metadata;

  const FusionParallelProcessingResult({
    required this.results,
    required this.processingTime,
    required this.isolatesUsed,
    this.metadata = const {},
  });
}

/// Semantic similarity group for context chunks
class SemanticGroup {
  final String id;
  final List<ContextChunk> chunks;
  final double similarityThreshold;
  final Map<String, double> groupFeatures;
  final DateTime createdAt;

  SemanticGroup({
    required this.id,
    required this.chunks,
    required this.similarityThreshold,
    required this.groupFeatures,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get the most representative chunk (highest authority)
  ContextChunk get representativeChunk {
    if (chunks.isEmpty) throw StateError('Group has no chunks');
    return chunks.reduce(
      (a, b) => a.source.authorityScore > b.source.authorityScore ? a : b,
    );
  }

  /// Get group size
  int get size => chunks.length;

  /// Get average authority score
  double get averageAuthority {
    if (chunks.isEmpty) return 0.0;
    final total = chunks.fold(
      0.0,
      (sum, chunk) => sum + chunk.source.authorityScore,
    );
    return total / chunks.length;
  }

  /// Get group freshness score
  double get freshnessScore {
    if (chunks.isEmpty) return 0.0;
    final now = DateTime.now();
    final ages = chunks.map((c) => now.difference(c.updatedAt).inDays).toList();
    final avgAge = ages.reduce((a, b) => a + b) / ages.length;
    return math.exp(-avgAge / 30.0); // Exponential decay with 30-day half-life
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chunk_count': chunks.length,
    'similarity_threshold': similarityThreshold,
    'group_features': groupFeatures,
    'created_at': createdAt.toIso8601String(),
    'representative_chunk_id': representativeChunk.id,
    'average_authority': averageAuthority,
    'freshness_score': freshnessScore,
  };

  /// **NEW: Create SemanticGroup from JSON**
  factory SemanticGroup.fromJson(Map<String, dynamic> json) {
    // For now, return a placeholder since we need the actual chunks
    // In a real implementation, this would reconstruct the full object
    return SemanticGroup(
      id: json['id'] as String,
      chunks: [], // Placeholder - would need to reconstruct chunks
      similarityThreshold: json['similarity_threshold'] as double? ?? 0.7,
      groupFeatures: Map<String, double>.from(json['group_features'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Conflict resolution result
class ConflictResolutionResult {
  final ContextChunk resolvedChunk;
  final List<ContextChunk> conflictingChunks;
  final String resolutionStrategy;
  final double confidence;
  final Map<String, dynamic> metadata;

  ConflictResolutionResult({
    required this.resolvedChunk,
    required this.conflictingChunks,
    required this.resolutionStrategy,
    required this.confidence,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'resolved_chunk_id': resolvedChunk.id,
    'conflicting_chunk_count': conflictingChunks.length,
    'resolution_strategy': resolutionStrategy,
    'confidence': confidence,
    'metadata': metadata,
  };
}

/// Quality assessment result
class QualityAssessment {
  final double overallScore;
  final Map<String, double> dimensionScores;
  final List<String> issues;
  final List<String> recommendations;
  final DateTime assessedAt;

  QualityAssessment({
    required this.overallScore,
    required this.dimensionScores,
    this.issues = const [],
    this.recommendations = const [],
    DateTime? assessedAt,
  }) : assessedAt = assessedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'overall_score': overallScore,
    'dimension_scores': dimensionScores,
    'issues': issues,
    'recommendations': recommendations,
    'assessed_at': assessedAt.toIso8601String(),
  };
}

/// Advanced Fusion Engine for intelligent context fusion
class AdvancedFusionEngine {
  final CacheManager cacheManager;
  final VectorDatabase vectorDatabase;
  final Logger _logger = Logger();

  /// Fusion strategy configurations
  final Map<String, FusionStrategyConfig> _strategies = {};

  /// **NEW: Parallel processing configuration**
  FusionParallelProcessingConfig _parallelConfig =
      const FusionParallelProcessingConfig();

  /// Semantic similarity threshold
  double _similarityThreshold = 0.7;

  /// Maximum group size
  int _maxGroupSize = 10;

  /// Conflict resolution strategies
  final List<String> _conflictStrategies = [
    'authority_based',
    'freshness_based',
    'consensus_based',
    'hybrid_weighted',
  ];

  AdvancedFusionEngine({
    required this.cacheManager,
    required this.vectorDatabase,
    FusionParallelProcessingConfig? parallelConfig,
  }) {
    if (parallelConfig != null) {
      _parallelConfig = parallelConfig;
    }
    _initializeDefaultStrategies();
  }

  /// **NEW: Set parallel processing configuration**
  void setParallelProcessingConfig(FusionParallelProcessingConfig config) {
    _parallelConfig = config;
    _logger.i(
      'Parallel processing config updated: ${config.maxIsolates} isolates, ${config.chunkSize} chunk size',
    );
  }

  /// **NEW: Get parallel processing configuration**
  FusionParallelProcessingConfig getParallelProcessingConfig() =>
      _parallelConfig;

  /// Initialize default fusion strategies
  void _initializeDefaultStrategies() {
    _strategies['semantic_similarity'] = FusionStrategyConfig(
      name: 'semantic_similarity',
      weight: 0.3,
      parameters: {'threshold': _similarityThreshold},
    );

    _strategies['source_authority'] = FusionStrategyConfig(
      name: 'source_authority',
      weight: 0.25,
      parameters: {'min_authority': 0.5},
    );

    _strategies['freshness'] = FusionStrategyConfig(
      name: 'freshness',
      weight: 0.2,
      parameters: {'decay_rate': 0.1},
    );

    _strategies['content_quality'] = FusionStrategyConfig(
      name: 'content_quality',
      weight: 0.15,
      parameters: {'min_length': 10, 'max_length': 10000},
    );

    _strategies['user_preference'] = FusionStrategyConfig(
      name: 'user_preference',
      weight: 0.1,
      parameters: {'default_score': 0.5},
    );
  }

  /// Set similarity threshold for semantic grouping
  void setSimilarityThreshold(double threshold) {
    _similarityThreshold = threshold.clamp(0.0, 1.0);
    _strategies['semantic_similarity']?.parameters['threshold'] =
        _similarityThreshold;
    _logger.i('Similarity threshold set to: $_similarityThreshold');
  }

  /// Set maximum group size
  void setMaxGroupSize(int maxSize) {
    _maxGroupSize = maxSize.clamp(1, 100);
    _logger.i('Maximum group size set to: $_maxGroupSize');
  }

  /// Add or update fusion strategy
  void updateStrategy(FusionStrategyConfig config) {
    _strategies[config.name] = config;
    _logger.i('Updated fusion strategy: ${config.name}');
  }

  /// Get all fusion strategies
  Map<String, FusionStrategyConfig> getStrategies() =>
      Map.unmodifiable(_strategies);

  /// Perform advanced fusion on context chunks
  Future<List<ContextChunk>> performAdvancedFusion({
    required List<ContextChunk> chunks,
    required String query,
    String? userId,
    Map<String, dynamic>? context,
    List<String>? enabledStrategies,
  }) async {
    if (chunks.isEmpty) return [];

    final cacheKey =
        'fusion_${chunks.map((c) => c.id).join('_')}_${query.hashCode}_${userId ?? 'anonymous'}';

    // Check cache first
    final cachedResult = await cacheManager.get(cacheKey);
    if (cachedResult != null) {
      _logger.d('Returning cached fusion result');
      return (cachedResult['chunks'] as List)
          .map((c) => ContextChunk.fromJson(c))
          .toList();
    }

    _logger.i('Performing advanced fusion on ${chunks.length} chunks');

    final stopwatch = Stopwatch()..start();

    // **NEW: Use parallel processing for large datasets**
    List<SemanticGroup> groups;
    if (_parallelConfig.enableParallelProcessing &&
        chunks.length > _parallelConfig.chunkSize) {
      _logger.i('Using parallel processing for ${chunks.length} chunks');
      final result = await _performParallelSemanticGrouping(chunks, query);
      groups = result.results;
      _logger.d(
        'Parallel processing completed in ${result.processingTime.inMilliseconds}ms using ${result.isolatesUsed} isolates',
      );
    } else {
      _logger.d('Using sequential processing for ${chunks.length} chunks');
      groups = await _performSemanticGrouping(chunks, query);
    }

    _logger.d('Created ${groups.length} semantic groups');

    // Step 2: Conflict resolution within groups
    final resolvedGroups = await _resolveConflicts(
      groups,
      query,
      userId,
      context,
    );
    _logger.d('Resolved conflicts in ${resolvedGroups.length} groups');

    // Step 3: Quality assessment
    final qualityAssessments = await _assessQuality(resolvedGroups, query);
    _logger.d('Assessed quality for ${qualityAssessments.length} groups');

    // Step 4: Multi-strategy fusion
    final fusedChunks = await _applyFusionStrategies(
      resolvedGroups,
      qualityAssessments,
      query,
      userId,
      context,
      enabledStrategies,
    );

    // Step 5: Final ranking and selection
    final finalChunks = _rankAndSelectChunks(fusedChunks, query, userId);

    final totalTime = stopwatch.elapsed;

    // Cache the result
    final resultData = {
      'chunks': finalChunks.map((c) => c.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'processing_time_ms': totalTime.inMilliseconds,
      'parallel_processing_used':
          _parallelConfig.enableParallelProcessing &&
          chunks.length > _parallelConfig.chunkSize,
    };
    await cacheManager.set(cacheKey, resultData, ttl: Duration(minutes: 30));

    _logger.i(
      'Advanced fusion completed in ${totalTime.inMilliseconds}ms, returning ${finalChunks.length} chunks',
    );
    return finalChunks;
  }

  /// **NEW: Perform parallel semantic grouping using Isolates**
  Future<FusionParallelProcessingResult<SemanticGroup>>
  _performParallelSemanticGrouping(
    List<ContextChunk> chunks,
    String query,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Split chunks into batches for parallel processing
    final batches = _splitIntoBatches(chunks, _parallelConfig.chunkSize);
    final isolateCount = math.min(batches.length, _parallelConfig.maxIsolates);

    _logger.d(
      'Processing ${batches.length} batches using $isolateCount isolates',
    );

    // Create isolates for parallel processing
    final isolates = <Isolate>[];
    final receives = <ReceivePort>[];
    final futures = <Future<List<SemanticGroup>>>[];

    try {
      for (int i = 0; i < isolateCount; i++) {
        final receivePort = ReceivePort();
        receives.add(receivePort);

        final isolate = await Isolate.spawn(
          _semanticGroupingIsolate,
          FusionIsolateMessage(
            type: 'semantic_grouping',
            data: {
              'chunks': batches[i].map((c) => c.toJson()).toList(),
              'query': query,
              'similarity_threshold': _similarityThreshold,
              'max_group_size': _maxGroupSize,
            },
          ),
        );

        isolates.add(isolate);

        // Listen for results from isolate
        final future = receivePort.first.then((result) {
          return (result as List)
              .map((g) => SemanticGroup.fromJson(g))
              .toList();
        });

        futures.add(future);
      }

      // Wait for all isolates to complete
      final results = await Future.wait(futures);

      // Merge results from all isolates
      final allGroups = <SemanticGroup>[];
      for (final batchGroups in results) {
        allGroups.addAll(batchGroups);
      }

      // Merge overlapping groups across batches
      final mergedGroups = await _mergeOverlappingGroups(allGroups, query);

      final processingTime = stopwatch.elapsed;

      return FusionParallelProcessingResult<SemanticGroup>(
        results: mergedGroups,
        processingTime: processingTime,
        isolatesUsed: isolateCount,
        metadata: {
          'batch_count': batches.length,
          'total_groups': allGroups.length,
          'merged_groups': mergedGroups.length,
        },
      );
    } finally {
      // Clean up isolates
      for (final isolate in isolates) {
        isolate.kill();
      }
      for (final receivePort in receives) {
        receivePort.close();
      }
    }
  }

  /// **NEW: Isolate entry point for semantic grouping**
  static void _semanticGroupingIsolate(FusionIsolateMessage message) {
    if (message.type == 'semantic_grouping') {
      final chunks = (message.data['chunks'] as List)
          .map((c) => ContextChunk.fromJson(c))
          .toList();
      final query = message.data['query'] as String;
      final similarityThreshold =
          message.data['similarity_threshold'] as double;
      final maxGroupSize = message.data['max_group_size'] as int;

      // Perform semantic grouping in isolate
      final groups = _performSemanticGroupingInIsolate(
        chunks,
        query,
        similarityThreshold,
        maxGroupSize,
      );

      // Send results back
      final sendPort = Isolate.current.controlPort;
      sendPort.send(groups.map((g) => g.toJson()).toList());
    }
  }

  /// **NEW: Semantic grouping logic for isolate**
  static List<SemanticGroup> _performSemanticGroupingInIsolate(
    List<ContextChunk> chunks,
    String query,
    double similarityThreshold,
    int maxGroupSize,
  ) {
    final groups = <SemanticGroup>[];
    final processedChunks = <String>{};

    for (final chunk in chunks) {
      if (processedChunks.contains(chunk.id)) continue;

      final group = <ContextChunk>[chunk];
      processedChunks.add(chunk.id);

      // Find similar chunks
      for (final otherChunk in chunks) {
        if (otherChunk.id == chunk.id ||
            processedChunks.contains(otherChunk.id))
          continue;

        final similarity = _calculateSemanticSimilarityInIsolate(
          chunk,
          otherChunk,
          query,
        );
        if (similarity >= similarityThreshold && group.length < maxGroupSize) {
          group.add(otherChunk);
          processedChunks.add(otherChunk.id);
        }
      }

      // Create semantic group
      final groupFeatures = _extractGroupFeaturesInIsolate(group, query);
      groups.add(
        SemanticGroup(
          id: 'group_${groups.length}',
          chunks: group,
          similarityThreshold: similarityThreshold,
          groupFeatures: groupFeatures,
        ),
      );
    }

    return groups;
  }

  /// **NEW: Calculate semantic similarity in isolate (synchronous)**
  static double _calculateSemanticSimilarityInIsolate(
    ContextChunk chunk1,
    ContextChunk chunk2,
    String query,
  ) {
    // Content overlap similarity
    final words1 = chunk1.content.toLowerCase().split(RegExp(r'\s+'));
    final words2 = chunk2.content.toLowerCase().split(RegExp(r'\s+'));
    final intersection = words1.where((word) => words2.contains(word)).length;
    final union = words1.length + words2.length - intersection;
    final contentSimilarity = union > 0 ? intersection / union : 0.0;

    // Tag similarity
    final tagIntersection = chunk1.tags
        .where((tag) => chunk2.tags.contains(tag))
        .length;
    final tagUnion = chunk1.tags.length + chunk2.tags.length - tagIntersection;
    final tagSimilarity = tagUnion > 0 ? tagIntersection / tagUnion : 0.0;

    // Source similarity
    final sourceSimilarity = chunk1.source.name == chunk2.source.name
        ? 1.0
        : 0.0;

    // Weighted combination
    return (contentSimilarity * 0.5 +
        tagSimilarity * 0.3 +
        sourceSimilarity * 0.2);
  }

  /// **NEW: Extract group features in isolate (synchronous)**
  static Map<String, double> _extractGroupFeaturesInIsolate(
    List<ContextChunk> chunks,
    String query,
  ) {
    if (chunks.isEmpty) return {};

    final features = <String, double>{};

    // Average authority
    final avgAuthority =
        chunks.fold(0.0, (sum, c) => sum + c.source.authorityScore) /
        chunks.length;
    features['avg_authority'] = avgAuthority;

    // Content diversity
    final uniqueWords = <String>{};
    for (final chunk in chunks) {
      uniqueWords.addAll(chunk.content.toLowerCase().split(RegExp(r'\s+')));
    }
    features['content_diversity'] = uniqueWords.length / chunks.length;

    // Tag diversity
    final uniqueTags = <String>{};
    for (final chunk in chunks) {
      uniqueTags.addAll(chunk.tags);
    }
    features['tag_diversity'] = uniqueTags.length / chunks.length;

    // Freshness
    final now = DateTime.now();
    final ages = chunks.map((c) => now.difference(c.updatedAt).inDays).toList();
    final avgAge = ages.reduce((a, b) => a + b) / ages.length;
    features['freshness'] = math.exp(-avgAge / 30.0);

    return features;
  }

  /// **NEW: Split chunks into batches for parallel processing**
  List<List<ContextChunk>> _splitIntoBatches(
    List<ContextChunk> chunks,
    int batchSize,
  ) {
    final batches = <List<ContextChunk>>[];

    for (int i = 0; i < chunks.length; i += batchSize) {
      final end = math.min(i + batchSize, chunks.length);
      batches.add(chunks.sublist(i, end));
    }

    return batches;
  }

  /// **NEW: Merge overlapping groups across batches**
  Future<List<SemanticGroup>> _mergeOverlappingGroups(
    List<SemanticGroup> groups,
    String query,
  ) async {
    if (groups.length <= 1) return groups;

    final mergedGroups = <SemanticGroup>[];
    final processedGroups = <String>{};

    for (final group in groups) {
      if (processedGroups.contains(group.id)) continue;

      final mergedGroup = <ContextChunk>[...group.chunks];
      processedGroups.add(group.id);

      // Find overlapping groups
      for (final otherGroup in groups) {
        if (otherGroup.id == group.id ||
            processedGroups.contains(otherGroup.id))
          continue;

        // Check if groups overlap (have common chunks or high similarity)
        if (_groupsOverlap(group, otherGroup, query)) {
          mergedGroup.addAll(otherGroup.chunks);
          processedGroups.add(otherGroup.id);
        }
      }

      // Remove duplicates and create merged group
      final uniqueChunks = <String, ContextChunk>{};
      for (final chunk in mergedGroup) {
        uniqueChunks[chunk.id] = chunk;
      }

      final finalChunks = uniqueChunks.values.toList();
      final groupFeatures = await _extractGroupFeatures(finalChunks, query);

      mergedGroups.add(
        SemanticGroup(
          id: 'merged_${mergedGroups.length}',
          chunks: finalChunks,
          similarityThreshold: _similarityThreshold,
          groupFeatures: groupFeatures,
        ),
      );
    }

    return mergedGroups;
  }

  /// **NEW: Check if two groups overlap**
  bool _groupsOverlap(
    SemanticGroup group1,
    SemanticGroup group2,
    String query,
  ) {
    // Check for common chunks
    for (final chunk1 in group1.chunks) {
      for (final chunk2 in group2.chunks) {
        if (chunk1.id == chunk2.id) return true;
      }
    }

    // Check for high similarity between representative chunks
    final similarity = _calculateSemanticSimilarityInIsolate(
      group1.representativeChunk,
      group2.representativeChunk,
      query,
    );

    return similarity >=
        _similarityThreshold * 0.8; // Slightly lower threshold for merging
  }

  /// **LEGACY: Sequential semantic grouping (kept for small datasets)**
  Future<List<SemanticGroup>> _performSemanticGrouping(
    List<ContextChunk> chunks,
    String query,
  ) async {
    final groups = <SemanticGroup>[];
    final processedChunks = <String>{};

    for (final chunk in chunks) {
      if (processedChunks.contains(chunk.id)) continue;

      final group = <ContextChunk>[chunk];
      processedChunks.add(chunk.id);

      // Find similar chunks
      for (final otherChunk in chunks) {
        if (otherChunk.id == chunk.id ||
            processedChunks.contains(otherChunk.id))
          continue;

        final similarity = await _calculateSemanticSimilarity(
          chunk,
          otherChunk,
          query,
        );
        if (similarity >= _similarityThreshold &&
            group.length < _maxGroupSize) {
          group.add(otherChunk);
          processedChunks.add(otherChunk.id);
        }
      }

      // Create semantic group
      final groupFeatures = await _extractGroupFeatures(group, query);
      groups.add(
        SemanticGroup(
          id: 'group_${groups.length}',
          chunks: group,
          similarityThreshold: _similarityThreshold,
          groupFeatures: groupFeatures,
        ),
      );
    }

    return groups;
  }

  /// Calculate semantic similarity between chunks
  Future<double> _calculateSemanticSimilarity(
    ContextChunk chunk1,
    ContextChunk chunk2,
    String query,
  ) async {
    // This would normally use the vector database for semantic similarity
    // For now, use a simplified approach based on content overlap and tags

    // Content overlap similarity
    final words1 = chunk1.content.toLowerCase().split(RegExp(r'\s+'));
    final words2 = chunk2.content.toLowerCase().split(RegExp(r'\s+'));
    final intersection = words1.where((word) => words2.contains(word)).length;
    final union = words1.length + words2.length - intersection;
    final contentSimilarity = union > 0 ? intersection / union : 0.0;

    // Tag similarity
    final tagIntersection = chunk1.tags
        .where((tag) => chunk2.tags.contains(tag))
        .length;
    final tagUnion = chunk1.tags.length + chunk2.tags.length - tagIntersection;
    final tagSimilarity = tagUnion > 0 ? tagIntersection / tagUnion : 0.0;

    // Source similarity
    final sourceSimilarity = chunk1.source.name == chunk2.source.name
        ? 1.0
        : 0.0;

    // Weighted combination
    return (contentSimilarity * 0.5 +
        tagSimilarity * 0.3 +
        sourceSimilarity * 0.2);
  }

  /// Extract group features for analysis
  Future<Map<String, double>> _extractGroupFeatures(
    List<ContextChunk> chunks,
    String query,
  ) async {
    if (chunks.isEmpty) return {};

    final features = <String, double>{};

    // Average authority
    final avgAuthority =
        chunks.fold(0.0, (sum, c) => sum + c.source.authorityScore) /
        chunks.length;
    features['avg_authority'] = avgAuthority;

    // Content diversity
    final uniqueWords = <String>{};
    for (final chunk in chunks) {
      uniqueWords.addAll(chunk.content.toLowerCase().split(RegExp(r'\s+')));
    }
    features['content_diversity'] = uniqueWords.length / chunks.length;

    // Tag diversity
    final uniqueTags = <String>{};
    for (final chunk in chunks) {
      uniqueTags.addAll(chunk.tags);
    }
    features['tag_diversity'] = uniqueTags.length / chunks.length;

    // Freshness
    final now = DateTime.now();
    final ages = chunks.map((c) => now.difference(c.updatedAt).inDays).toList();
    final avgAge = ages.reduce((a, b) => a + b) / ages.length;
    features['freshness'] = math.exp(-avgAge / 30.0);

    return features;
  }

  /// Resolve conflicts within semantic groups
  Future<List<SemanticGroup>> _resolveConflicts(
    List<SemanticGroup> groups,
    String query,
    String? userId,
    Map<String, dynamic>? context,
  ) async {
    final resolvedGroups = <SemanticGroup>[];

    for (final group in groups) {
      if (group.chunks.length <= 1) {
        resolvedGroups.add(group);
        continue;
      }

      final resolutionResult = await _resolveGroupConflicts(
        group,
        query,
        userId,
        context,
      );
      final resolvedChunks = [resolutionResult.resolvedChunk];

      resolvedGroups.add(
        SemanticGroup(
          id: group.id,
          chunks: resolvedChunks,
          similarityThreshold: group.similarityThreshold,
          groupFeatures: group.groupFeatures,
        ),
      );
    }

    return resolvedGroups;
  }

  /// Resolve conflicts within a single group
  Future<ConflictResolutionResult> _resolveGroupConflicts(
    SemanticGroup group,
    String query,
    String? userId,
    Map<String, dynamic>? context,
  ) async {
    final chunks = group.chunks;
    if (chunks.length <= 1) {
      return ConflictResolutionResult(
        resolvedChunk: chunks.first,
        conflictingChunks: [],
        resolutionStrategy: 'single_chunk',
        confidence: 1.0,
      );
    }

    // Try different resolution strategies
    final strategies = [
      _resolveByAuthority,
      _resolveByFreshness,
      _resolveByConsensus,
      _resolveByHybridWeight,
    ];

    ConflictResolutionResult? bestResult;
    double bestConfidence = 0.0;

    for (final strategy in strategies) {
      try {
        final result = await strategy(chunks, query, userId, context);
        if (result.confidence > bestConfidence) {
          bestResult = result;
          bestConfidence = result.confidence;
        }
      } catch (e) {
        _logger.w('Strategy failed: $e');
      }
    }

    return bestResult ??
        ConflictResolutionResult(
          resolvedChunk: chunks.first,
          conflictingChunks: chunks.sublist(1),
          resolutionStrategy: 'fallback',
          confidence: 0.5,
        );
  }

  /// Resolve conflicts by source authority
  Future<ConflictResolutionResult> _resolveByAuthority(
    List<ContextChunk> chunks,
    String query,
    String? userId,
    Map<String, dynamic>? context,
  ) async {
    final sortedChunks = List<ContextChunk>.from(chunks)
      ..sort(
        (a, b) => b.source.authorityScore.compareTo(a.source.authorityScore),
      );

    final resolvedChunk = sortedChunks.first;
    final conflictingChunks = sortedChunks.sublist(1);

    return ConflictResolutionResult(
      resolvedChunk: resolvedChunk,
      conflictingChunks: conflictingChunks,
      resolutionStrategy: 'authority_based',
      confidence: resolvedChunk.source.authorityScore,
      metadata: {'authority_score': resolvedChunk.source.authorityScore},
    );
  }

  /// Resolve conflicts by freshness
  Future<ConflictResolutionResult> _resolveByFreshness(
    List<ContextChunk> chunks,
    String query,
    String? userId,
    Map<String, dynamic>? context,
  ) async {
    final now = DateTime.now();
    final sortedChunks = List<ContextChunk>.from(chunks)
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

    final resolvedChunk = sortedChunks.first; // Most recent
    final conflictingChunks = sortedChunks.sublist(1);

    final freshnessScore =
        1.0 - (now.difference(resolvedChunk.updatedAt).inDays / 365.0);

    return ConflictResolutionResult(
      resolvedChunk: resolvedChunk,
      conflictingChunks: conflictingChunks,
      resolutionStrategy: 'freshness_based',
      confidence: freshnessScore.clamp(0.0, 1.0),
      metadata: {'freshness_score': freshnessScore},
    );
  }

  /// Resolve conflicts by consensus
  Future<ConflictResolutionResult> _resolveByConsensus(
    List<ContextChunk> chunks,
    String query,
    String? userId,
    Map<String, dynamic>? context,
  ) async {
    // Find chunks with most similar content
    double bestSimilarity = 0.0;
    ContextChunk? bestChunk;
    List<ContextChunk>? bestConflicting;

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final others = chunks.where((c) => c.id != chunk.id).toList();

      if (others.isEmpty) continue;

      double totalSimilarity = 0.0;
      for (final other in others) {
        totalSimilarity += await _calculateSemanticSimilarity(
          chunk,
          other,
          query,
        );
      }

      final avgSimilarity = totalSimilarity / others.length;
      if (avgSimilarity > bestSimilarity) {
        bestSimilarity = avgSimilarity;
        bestChunk = chunk;
        bestConflicting = others;
      }
    }

    if (bestChunk == null) {
      throw StateError('No consensus found');
    }

    return ConflictResolutionResult(
      resolvedChunk: bestChunk,
      conflictingChunks: bestConflicting ?? [],
      resolutionStrategy: 'consensus_based',
      confidence: bestSimilarity,
      metadata: {'consensus_score': bestSimilarity},
    );
  }

  /// Resolve conflicts by hybrid weighted approach
  Future<ConflictResolutionResult> _resolveByHybridWeight(
    List<ContextChunk> chunks,
    String query,
    String? userId,
    Map<String, dynamic>? context,
  ) async {
    final scores = <ContextChunk, double>{};

    for (final chunk in chunks) {
      double score = 0.0;

      // Authority weight (40%)
      score += chunk.source.authorityScore * 0.4;

      // Freshness weight (30%)
      final now = DateTime.now();
      final age = now.difference(chunk.updatedAt).inDays;
      final freshness = math.exp(-age / 30.0);
      score += freshness * 0.3;

      // Content quality weight (20%)
      final contentLength = chunk.content.length;
      final contentQuality = contentLength >= 10 && contentLength <= 10000
          ? 1.0
          : 0.5;
      score += contentQuality * 0.2;

      // Tag relevance weight (10%)
      final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
      final tagRelevance =
          chunk.tags
              .where(
                (tag) =>
                    queryWords.any((word) => tag.toLowerCase().contains(word)),
              )
              .length /
          chunk.tags.length;
      score += tagRelevance * 0.1;

      scores[chunk] = score;
    }

    final sortedChunks = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final resolvedChunk = sortedChunks.first.key;
    final conflictingChunks = sortedChunks
        .sublist(1)
        .map((e) => e.key)
        .toList();

    return ConflictResolutionResult(
      resolvedChunk: resolvedChunk,
      conflictingChunks: conflictingChunks,
      resolutionStrategy: 'hybrid_weighted',
      confidence: sortedChunks.first.value,
      metadata: {'hybrid_score': sortedChunks.first.value},
    );
  }

  /// Assess quality of resolved groups
  Future<List<QualityAssessment>> _assessQuality(
    List<SemanticGroup> groups,
    String query,
  ) async {
    final assessments = <QualityAssessment>[];

    for (final group in groups) {
      final chunk = group.representativeChunk;

      // Content quality
      final contentLength = chunk.content.length;
      final contentQuality = contentLength >= 10 && contentLength <= 10000
          ? 1.0
          : 0.5;

      // Authority quality
      final authorityQuality = chunk.source.authorityScore;

      // Freshness quality
      final now = DateTime.now();
      final age = now.difference(chunk.updatedAt).inDays;
      final freshnessQuality = math.exp(-age / 30.0);

      // Tag relevance quality
      final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
      final tagRelevance =
          chunk.tags
              .where(
                (tag) =>
                    queryWords.any((word) => tag.toLowerCase().contains(word)),
              )
              .length /
          chunk.tags.length;

      // Metadata completeness
      final metadataCompleteness =
          chunk.metadata.length / 5.0; // Assuming 5 is optimal

      final dimensionScores = {
        'content_quality': contentQuality,
        'authority_quality': authorityQuality,
        'freshness_quality': freshnessQuality,
        'tag_relevance': tagRelevance,
        'metadata_completeness': metadataCompleteness.clamp(0.0, 1.0),
      };

      final overallScore =
          dimensionScores.values.reduce((a, b) => a + b) /
          dimensionScores.length;

      final issues = <String>[];
      final recommendations = <String>[];

      if (contentLength < 10) {
        issues.add('Content too short');
        recommendations.add('Consider adding more detailed content');
      }

      if (authorityQuality < 0.5) {
        issues.add('Low source authority');
        recommendations.add('Verify source credibility');
      }

      if (freshnessQuality < 0.3) {
        issues.add('Content may be outdated');
        recommendations.add('Update content or verify relevance');
      }

      assessments.add(
        QualityAssessment(
          overallScore: overallScore,
          dimensionScores: dimensionScores,
          issues: issues,
          recommendations: recommendations,
        ),
      );
    }

    return assessments;
  }

  /// Apply fusion strategies to create final chunks
  Future<List<ContextChunk>> _applyFusionStrategies(
    List<SemanticGroup> groups,
    List<QualityAssessment> assessments,
    String query,
    String? userId,
    Map<String, dynamic>? context,
    List<String>? enabledStrategies,
  ) async {
    final fusedChunks = <ContextChunk>[];

    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final assessment = assessments[i];
      final chunk = group.representativeChunk;

      // Apply enabled strategies
      final strategies = enabledStrategies ?? _strategies.keys.toList();
      double fusionScore = 0.0;

      for (final strategyName in strategies) {
        final strategy = _strategies[strategyName];
        if (strategy == null || !strategy.enabled) continue;

        double strategyScore = 0.0;

        switch (strategyName) {
          case 'semantic_similarity':
            strategyScore = group.groupFeatures['avg_authority'] ?? 0.0;
            break;
          case 'source_authority':
            strategyScore = chunk.source.authorityScore;
            break;
          case 'freshness':
            strategyScore = group.groupFeatures['freshness'] ?? 0.0;
            break;
          case 'content_quality':
            strategyScore =
                assessment.dimensionScores['content_quality'] ?? 0.0;
            break;
          case 'user_preference':
            strategyScore = 0.5; // Default user preference score
            break;
        }

        fusionScore += strategyScore * strategy.weight;
      }

      // Create enhanced chunk with fusion metadata
      final enhancedChunk = ContextChunk(
        id: '${chunk.id}_fused',
        content: chunk.content,
        source: chunk.source,
        tags: chunk.tags,
        metadata: {
          ...chunk.metadata,
          'fusion_score': fusionScore,
          'quality_score': assessment.overallScore,
          'group_size': group.size,
          'fusion_strategies': strategies,
        },
        createdAt: chunk.createdAt,
        updatedAt: DateTime.now(),
      );

      fusedChunks.add(enhancedChunk);
    }

    return fusedChunks;
  }

  /// Rank and select final chunks
  List<ContextChunk> _rankAndSelectChunks(
    List<ContextChunk> chunks,
    String query,
    String? userId,
  ) {
    // Sort by fusion score (descending)
    final sortedChunks = List<ContextChunk>.from(chunks)
      ..sort((a, b) {
        final scoreA = a.metadata['fusion_score'] ?? 0.0;
        final scoreB = b.metadata['fusion_score'] ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

    // Return top chunks (limit to reasonable number)
    final maxChunks = math.min(sortedChunks.length, 20);
    return sortedChunks.take(maxChunks).toList();
  }

  /// Get engine statistics
  Map<String, dynamic> getStats() {
    return {
      'total_strategies': _strategies.length,
      'enabled_strategies': _strategies.values.where((s) => s.enabled).length,
      'similarity_threshold': _similarityThreshold,
      'max_group_size': _maxGroupSize,
      'conflict_strategies': _conflictStrategies,
      'cache_stats': cacheManager.getStats().toJson(),
      'vector_db_stats': vectorDatabase.getStats(),
    };
  }

  /// Get fusion strategy by name
  FusionStrategyConfig? getStrategy(String name) => _strategies[name];

  /// Enable/disable fusion strategy
  void setStrategyEnabled(String name, bool enabled) {
    final strategy = _strategies[name];
    if (strategy != null) {
      _strategies[name] = FusionStrategyConfig(
        name: strategy.name,
        weight: strategy.weight,
        parameters: strategy.parameters,
        enabled: enabled,
      );
      _logger.i('Strategy $name ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Update strategy weight
  void setStrategyWeight(String name, double weight) {
    final strategy = _strategies[name];
    if (strategy != null) {
      _strategies[name] = FusionStrategyConfig(
        name: strategy.name,
        weight: weight.clamp(0.0, 1.0),
        parameters: strategy.parameters,
        enabled: strategy.enabled,
      );
      _logger.i('Strategy $name weight set to: $weight');
    }
  }
}
