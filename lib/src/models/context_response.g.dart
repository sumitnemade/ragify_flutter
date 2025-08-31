// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContextResponse _$ContextResponseFromJson(Map<String, dynamic> json) =>
    ContextResponse(
      id: json['id'] as String,
      query: json['query'] as String,
      chunks: (json['chunks'] as List<dynamic>)
          .map((e) => ContextChunk.fromJson(e as Map<String, dynamic>))
          .toList(),
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      maxTokens: (json['max_tokens'] as num).toInt(),
      privacyLevel: $enumDecode(_$PrivacyLevelEnumMap, json['privacy_level']),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      processingTimeMs: (json['processing_time_ms'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ContextResponseToJson(ContextResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'query': instance.query,
      'chunks': instance.chunks,
      'user_id': instance.userId,
      'session_id': instance.sessionId,
      'max_tokens': instance.maxTokens,
      'privacy_level': _$PrivacyLevelEnumMap[instance.privacyLevel]!,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
      'processing_time_ms': instance.processingTimeMs,
    };

const _$PrivacyLevelEnumMap = {
  PrivacyLevel.public: 'public',
  PrivacyLevel.private: 'private',
  PrivacyLevel.enterprise: 'enterprise',
  PrivacyLevel.restricted: 'restricted',
};
