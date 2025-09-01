import 'package:json_annotation/json_annotation.dart';
import '../models/privacy_level.dart';

part 'ragify_config.g.dart';

/// Configuration for the RAGify context orchestrator
@JsonSerializable()
class RagifyConfig {
  /// Vector database connection URL
  @JsonKey(name: 'vector_db_url')
  final String? vectorDbUrl;

  /// Cache connection URL
  @JsonKey(name: 'cache_url')
  final String? cacheUrl;

  /// Default privacy level for operations
  @JsonKey(name: 'privacy_level')
  final PrivacyLevel privacyLevel;

  /// Maximum context size in tokens
  @JsonKey(name: 'max_context_size')
  final int maxContextSize;

  /// Default relevance threshold
  @JsonKey(name: 'default_relevance_threshold')
  final double defaultRelevanceThreshold;

  /// Whether to enable caching
  @JsonKey(name: 'enable_caching')
  final bool enableCaching;

  /// Cache TTL in seconds
  @JsonKey(name: 'cache_ttl')
  final int cacheTtl;

  /// Whether to enable analytics
  @JsonKey(name: 'enable_analytics')
  final bool enableAnalytics;

  /// Log level for the system
  @JsonKey(name: 'log_level')
  final String logLevel;

  /// Fusion configuration options
  @JsonKey(name: 'fusion_config')
  final Map<String, dynamic> fusionConfig;

  /// Conflict detection threshold
  @JsonKey(name: 'conflict_detection_threshold')
  final double conflictDetectionThreshold;

  /// Source timeout in seconds
  @JsonKey(name: 'source_timeout')
  final double sourceTimeout;

  /// Maximum concurrent sources
  @JsonKey(name: 'max_concurrent_sources')
  final int maxConcurrentSources;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  const RagifyConfig({
    this.vectorDbUrl,
    this.cacheUrl,
    this.privacyLevel = PrivacyLevel.public,
    this.maxContextSize = 10000,
    this.defaultRelevanceThreshold = 0.5,
    this.enableCaching = true,
    this.cacheTtl = 3600,
    this.enableAnalytics = true,
    this.logLevel = 'INFO',
    this.fusionConfig = const {},
    this.conflictDetectionThreshold = 0.7,
    this.sourceTimeout = 30.0,
    this.maxConcurrentSources = 10,
    this.metadata = const {},
  });

  /// Create from JSON
  factory RagifyConfig.fromJson(Map<String, dynamic> json) =>
      _$RagifyConfigFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$RagifyConfigToJson(this);

  /// Create a copy with updated fields
  RagifyConfig copyWith({
    String? vectorDbUrl,
    String? cacheUrl,
    PrivacyLevel? privacyLevel,
    int? maxContextSize,
    double? defaultRelevanceThreshold,
    bool? enableCaching,
    int? cacheTtl,
    bool? enableAnalytics,
    String? logLevel,
    Map<String, dynamic>? fusionConfig,
    double? conflictDetectionThreshold,
    double? sourceTimeout,
    int? maxConcurrentSources,
    Map<String, dynamic>? metadata,
  }) {
    return RagifyConfig(
      vectorDbUrl: vectorDbUrl ?? this.vectorDbUrl,
      cacheUrl: cacheUrl ?? this.cacheUrl,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      maxContextSize: maxContextSize ?? this.maxContextSize,
      defaultRelevanceThreshold:
          defaultRelevanceThreshold ?? this.defaultRelevanceThreshold,
      enableCaching: enableCaching ?? this.enableCaching,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      logLevel: logLevel ?? this.logLevel,
      fusionConfig: fusionConfig ?? this.fusionConfig,
      conflictDetectionThreshold:
          conflictDetectionThreshold ?? this.conflictDetectionThreshold,
      sourceTimeout: sourceTimeout ?? this.sourceTimeout,
      maxConcurrentSources: maxConcurrentSources ?? this.maxConcurrentSources,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create default configuration
  factory RagifyConfig.defaultConfig() => const RagifyConfig();

  /// Create minimal configuration
  factory RagifyConfig.minimal() => const RagifyConfig(
    vectorDbUrl: null,
    cacheUrl: null,
    privacyLevel: PrivacyLevel.private,
    maxContextSize: 5000,
    enableCaching: false,
    enableAnalytics: false,
  );

  /// Create production configuration
  factory RagifyConfig.production() => const RagifyConfig(
    privacyLevel: PrivacyLevel.enterprise,
    maxContextSize: 50000,
    defaultRelevanceThreshold: 0.7,
    enableCaching: true,
    cacheTtl: 7200,
    enableAnalytics: true,
    logLevel: 'WARNING',
    conflictDetectionThreshold: 0.8,
    sourceTimeout: 60.0,
    maxConcurrentSources: 20,
  );

  @override
  String toString() {
    return 'RagifyConfig(privacy: $privacyLevel, maxSize: $maxContextSize, caching: $enableCaching)';
  }
}
