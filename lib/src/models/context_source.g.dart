// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContextSource _$ContextSourceFromJson(Map<String, dynamic> json) =>
    ContextSource(
      id: json['id'] as String?,
      name: json['name'] as String,
      sourceType: $enumDecode(_$SourceTypeEnumMap, json['source_type']),
      url: json['url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
      isActive: json['is_active'] as bool?,
      privacyLevel: $enumDecodeNullable(
        _$PrivacyLevelEnumMap,
        json['privacy_level'],
      ),
      authorityScore: (json['authority_score'] as num?)?.toDouble(),
      freshnessScore: (json['freshness_score'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ContextSourceToJson(ContextSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'source_type': _$SourceTypeEnumMap[instance.sourceType]!,
      'url': instance.url,
      'metadata': instance.metadata,
      'last_updated': instance.lastUpdated.toIso8601String(),
      'is_active': instance.isActive,
      'privacy_level': _$PrivacyLevelEnumMap[instance.privacyLevel]!,
      'authority_score': instance.authorityScore,
      'freshness_score': instance.freshnessScore,
    };

const _$SourceTypeEnumMap = {
  SourceType.document: 'document',
  SourceType.api: 'api',
  SourceType.database: 'database',
  SourceType.realtime: 'realtime',
  SourceType.vector: 'vector',
  SourceType.cache: 'cache',
};

const _$PrivacyLevelEnumMap = {
  PrivacyLevel.public: 'public',
  PrivacyLevel.private: 'private',
  PrivacyLevel.enterprise: 'enterprise',
  PrivacyLevel.restricted: 'restricted',
};
