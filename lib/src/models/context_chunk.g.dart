// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_chunk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContextChunk _$ContextChunkFromJson(Map<String, dynamic> json) => ContextChunk(
  id: json['id'] as String?,
  content: json['content'] as String,
  source: ContextSource.fromJson(json['source'] as Map<String, dynamic>),
  metadata: json['metadata'] as Map<String, dynamic>?,
  relevanceScore: json['relevance_score'] == null
      ? null
      : RelevanceScore.fromJson(
          json['relevance_score'] as Map<String, dynamic>,
        ),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  tokenCount: (json['token_count'] as num?)?.toInt(),
  embedding: (json['embedding'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$ContextChunkToJson(ContextChunk instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'source': instance.source,
      'metadata': instance.metadata,
      'relevance_score': instance.relevanceScore,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'token_count': instance.tokenCount,
      'embedding': instance.embedding,
      'tags': instance.tags,
    };
