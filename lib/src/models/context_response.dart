import 'package:json_annotation/json_annotation.dart';
import 'context_chunk.dart';
import 'privacy_level.dart';

part 'context_response.g.dart';

/// Response containing context data
@JsonSerializable()
class ContextResponse {
  /// Unique identifier for the response
  final String id;

  /// The original query
  final String query;

  /// List of context chunks
  final List<ContextChunk> chunks;

  /// User identifier
  @JsonKey(name: 'user_id')
  final String? userId;

  /// Session identifier
  @JsonKey(name: 'session_id')
  final String? sessionId;

  /// Maximum tokens in context
  @JsonKey(name: 'max_tokens')
  final int maxTokens;

  /// Privacy level for this response
  @JsonKey(name: 'privacy_level')
  final PrivacyLevel privacyLevel;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// When the response was created
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Processing time in milliseconds
  @JsonKey(name: 'processing_time_ms')
  final int? processingTimeMs;

  const ContextResponse._({
    required this.id,
    required this.query,
    required this.chunks,
    required this.userId,
    required this.sessionId,
    required this.maxTokens,
    required this.privacyLevel,
    required this.metadata,
    required this.createdAt,
    required this.processingTimeMs,
  });

  /// Create a new context response
  factory ContextResponse({
    required String id,
    required String query,
    required List<ContextChunk> chunks,
    String? userId,
    String? sessionId,
    required int maxTokens,
    required PrivacyLevel privacyLevel,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    int? processingTimeMs,
  }) {
    return ContextResponse._(
      id: id,
      query: query,
      chunks: chunks,
      userId: userId,
      sessionId: sessionId,
      maxTokens: maxTokens,
      privacyLevel: privacyLevel,
      metadata: metadata ?? const {},
      createdAt: createdAt ?? DateTime.now(),
      processingTimeMs: processingTimeMs,
    );
  }

  /// Create from JSON
  factory ContextResponse.fromJson(Map<String, dynamic> json) =>
      _$ContextResponseFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ContextResponseToJson(this);

  /// Create a copy with updated fields
  ContextResponse copyWith({
    String? id,
    String? query,
    List<ContextChunk>? chunks,
    String? userId,
    String? sessionId,
    int? maxTokens,
    PrivacyLevel? privacyLevel,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    int? processingTimeMs,
  }) {
    return ContextResponse(
      id: id ?? this.id,
      query: query ?? this.query,
      chunks: chunks ?? this.chunks,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      maxTokens: maxTokens ?? this.maxTokens,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
    );
  }

  /// Get the total number of chunks
  int get chunkCount => chunks.length;

  /// Get the total content length
  int get totalContentLength =>
      chunks.fold(0, (total, chunk) => total + chunk.contentLength);

  /// Get the total token count
  int get totalTokenCount =>
      chunks.fold(0, (total, chunk) => total + (chunk.tokenCount ?? 0));

  /// Get chunks sorted by relevance score
  List<ContextChunk> get chunksByRelevance {
    final sortedChunks = List<ContextChunk>.from(chunks);
    sortedChunks.sort(
      (a, b) => (b.relevanceScore?.score ?? 0.0).compareTo(
        a.relevanceScore?.score ?? 0.0,
      ),
    );
    return sortedChunks;
  }

  /// Get chunks above a relevance threshold
  List<ContextChunk> getChunksAboveThreshold(double threshold) {
    return chunks
        .where(
          (chunk) => chunk.relevanceScore?.isAboveThreshold(threshold) ?? false,
        )
        .toList();
  }

  /// Get chunks from a specific source
  List<ContextChunk> getChunksFromSource(String sourceName) {
    return chunks.where((chunk) => chunk.source.name == sourceName).toList();
  }

  /// Get all source names
  Set<String> get sourceNames =>
      chunks.map((chunk) => chunk.source.name).toSet();

  /// Check if the response is empty
  bool get isEmpty => chunks.isEmpty;

  /// Check if the response has content
  bool get isNotEmpty => chunks.isNotEmpty;

  @override
  String toString() {
    return 'ContextResponse(id: $id, query: "$query", chunks: $chunkCount, privacy: $privacyLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextResponse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
