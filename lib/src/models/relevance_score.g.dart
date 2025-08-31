// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relevance_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelevanceScore _$RelevanceScoreFromJson(Map<String, dynamic> json) =>
    RelevanceScore(
      score: (json['score'] as num).toDouble(),
      confidenceLower: (json['confidence_lower'] as num?)?.toDouble(),
      confidenceUpper: (json['confidence_upper'] as num?)?.toDouble(),
      confidenceLevel: (json['confidence_level'] as num?)?.toDouble() ?? 0.95,
    );

Map<String, dynamic> _$RelevanceScoreToJson(RelevanceScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'confidence_lower': instance.confidenceLower,
      'confidence_upper': instance.confidenceUpper,
      'confidence_level': instance.confidenceLevel,
    };
