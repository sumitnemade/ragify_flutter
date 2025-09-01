import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'context_source.dart';
import 'relevance_score.dart';

part 'context_chunk.g.dart';

/// Represents a chunk of context data
@JsonSerializable()
class ContextChunk {
  /// Unique identifier for the chunk
  final String id;

  /// The actual content/text of the chunk
  final String content;

  /// Source information for this chunk
  @JsonKey(
    name: 'source',
    fromJson: ContextSource.fromJson,
    toJson: _sourceToJson,
  )
  final ContextSource source;

  /// Additional metadata about the chunk
  final Map<String, dynamic> metadata;

  /// Relevance score for this chunk
  @JsonKey(
    name: 'relevance_score',
    fromJson: RelevanceScore.fromJson,
    toJson: _relevanceScoreToJson,
  )
  final RelevanceScore? relevanceScore;

  /// When the chunk was created
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// When the chunk was last updated
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// Token count for the chunk
  @JsonKey(name: 'token_count')
  final int? tokenCount;

  /// Embedding vector for the chunk (if available)
  final List<double>? embedding;

  /// Tags or categories for the chunk
  final List<String> tags;

  const ContextChunk._({
    required this.id,
    required this.content,
    required this.source,
    required this.metadata,
    this.relevanceScore,
    required this.createdAt,
    required this.updatedAt,
    this.tokenCount,
    this.embedding,
    required this.tags,
  });

  /// Create a new context chunk
  factory ContextChunk({
    String? id,
    required String content,
    required ContextSource source,
    Map<String, dynamic>? metadata,
    RelevanceScore? relevanceScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? tokenCount,
    List<double>? embedding,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return ContextChunk._(
      id: id ?? const Uuid().v4(),
      content: content,
      source: source,
      metadata: metadata ?? const {},
      relevanceScore: relevanceScore,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      tokenCount: tokenCount,
      embedding: embedding,
      tags: tags ?? const [],
    );
  }

  /// Create from JSON
  factory ContextChunk.fromJson(Map<String, dynamic> json) =>
      _$ContextChunkFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ContextChunkToJson(this);

  /// Helper method for JSON serialization of ContextSource
  static Map<String, dynamic> _sourceToJson(ContextSource source) =>
      source.toJson();

  /// Helper method for JSON serialization of RelevanceScore
  static Map<String, dynamic>? _relevanceScoreToJson(RelevanceScore? score) =>
      score?.toJson();

  /// Create a copy with updated fields
  ContextChunk copyWith({
    String? id,
    String? content,
    ContextSource? source,
    Map<String, dynamic>? metadata,
    RelevanceScore? relevanceScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? tokenCount,
    List<double>? embedding,
    List<String>? tags,
  }) {
    return ContextChunk(
      id: id ?? this.id,
      content: content ?? this.content,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tokenCount: tokenCount ?? this.tokenCount,
      embedding: embedding ?? this.embedding,
      tags: tags ?? this.tags,
    );
  }

  /// Get the chunk size in characters
  int get contentLength => content.length;

  /// Check if the chunk has an embedding
  bool get hasEmbedding => embedding != null && embedding!.isNotEmpty;

  /// Check if the chunk is relevant above a threshold
  bool isRelevantAbove(double threshold) {
    return relevanceScore?.isAboveThreshold(threshold) ?? false;
  }

  /// Get a summary of the chunk
  String get summary {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  @override
  String toString() {
    return 'ContextChunk(id: $id, source: ${source.name}, content: $summary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextChunk && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
