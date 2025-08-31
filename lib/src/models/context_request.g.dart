// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContextRequest _$ContextRequestFromJson(Map<String, dynamic> json) =>
    ContextRequest(
      query: json['query'] as String,
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      maxTokens: (json['max_tokens'] as num).toInt(),
      maxChunks: (json['max_chunks'] as num?)?.toInt(),
      minRelevance: (json['min_relevance'] as num).toDouble(),
      privacyLevel: $enumDecode(_$PrivacyLevelEnumMap, json['privacy_level']),
      includeMetadata: json['include_metadata'] as bool? ?? true,
      sources: (json['sources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      excludeSources: (json['exclude_sources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ContextRequestToJson(ContextRequest instance) =>
    <String, dynamic>{
      'query': instance.query,
      'user_id': instance.userId,
      'session_id': instance.sessionId,
      'max_tokens': instance.maxTokens,
      'max_chunks': instance.maxChunks,
      'min_relevance': instance.minRelevance,
      'privacy_level': _$PrivacyLevelEnumMap[instance.privacyLevel]!,
      'include_metadata': instance.includeMetadata,
      'sources': instance.sources,
      'exclude_sources': instance.excludeSources,
    };

const _$PrivacyLevelEnumMap = {
  PrivacyLevel.public: 'public',
  PrivacyLevel.private: 'private',
  PrivacyLevel.enterprise: 'enterprise',
  PrivacyLevel.restricted: 'restricted',
};
