// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ragify_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RagifyConfig _$RagifyConfigFromJson(Map<String, dynamic> json) => RagifyConfig(
  vectorDbUrl: json['vector_db_url'] as String?,
  cacheUrl: json['cache_url'] as String?,
  privacyLevel:
      $enumDecodeNullable(_$PrivacyLevelEnumMap, json['privacy_level']) ??
      PrivacyLevel.private,
  maxContextSize: (json['max_context_size'] as num?)?.toInt() ?? 10000,
  defaultRelevanceThreshold:
      (json['default_relevance_threshold'] as num?)?.toDouble() ?? 0.5,
  enableCaching: json['enable_caching'] as bool? ?? true,
  cacheTtl: (json['cache_ttl'] as num?)?.toInt() ?? 3600,
  enableAnalytics: json['enable_analytics'] as bool? ?? true,
  logLevel: json['log_level'] as String? ?? 'INFO',
  fusionConfig: json['fusion_config'] as Map<String, dynamic>? ?? const {},
  conflictDetectionThreshold:
      (json['conflict_detection_threshold'] as num?)?.toDouble() ?? 0.7,
  sourceTimeout: (json['source_timeout'] as num?)?.toDouble() ?? 30.0,
  maxConcurrentSources: (json['max_concurrent_sources'] as num?)?.toInt() ?? 10,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$RagifyConfigToJson(RagifyConfig instance) =>
    <String, dynamic>{
      'vector_db_url': instance.vectorDbUrl,
      'cache_url': instance.cacheUrl,
      'privacy_level': _$PrivacyLevelEnumMap[instance.privacyLevel]!,
      'max_context_size': instance.maxContextSize,
      'default_relevance_threshold': instance.defaultRelevanceThreshold,
      'enable_caching': instance.enableCaching,
      'cache_ttl': instance.cacheTtl,
      'enable_analytics': instance.enableAnalytics,
      'log_level': instance.logLevel,
      'fusion_config': instance.fusionConfig,
      'conflict_detection_threshold': instance.conflictDetectionThreshold,
      'source_timeout': instance.sourceTimeout,
      'max_concurrent_sources': instance.maxConcurrentSources,
      'metadata': instance.metadata,
    };

const _$PrivacyLevelEnumMap = {
  PrivacyLevel.public: 'public',
  PrivacyLevel.private: 'private',
  PrivacyLevel.enterprise: 'enterprise',
  PrivacyLevel.restricted: 'restricted',
};
