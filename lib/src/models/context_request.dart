import 'package:json_annotation/json_annotation.dart';
import 'privacy_level.dart';

part 'context_request.g.dart';

/// Request for context retrieval
@JsonSerializable()
class ContextRequest {
  /// The user query
  final String query;

  /// User identifier for personalization
  @JsonKey(name: 'user_id')
  final String? userId;

  /// Session identifier for continuity
  @JsonKey(name: 'session_id')
  final String? sessionId;

  /// Maximum tokens in context
  @JsonKey(name: 'max_tokens')
  final int maxTokens;

  /// Maximum number of chunks
  @JsonKey(name: 'max_chunks')
  final int? maxChunks;

  /// Minimum relevance threshold
  @JsonKey(name: 'min_relevance')
  final double minRelevance;

  /// Privacy level for this request
  @JsonKey(name: 'privacy_level')
  final PrivacyLevel privacyLevel;

  /// Whether to include metadata
  @JsonKey(name: 'include_metadata')
  final bool includeMetadata;

  /// Specific sources to include
  final List<String>? sources;

  /// Sources to exclude
  @JsonKey(name: 'exclude_sources')
  final List<String>? excludeSources;

  const ContextRequest({
    required this.query,
    this.userId,
    this.sessionId,
    required this.maxTokens,
    this.maxChunks,
    required this.minRelevance,
    required this.privacyLevel,
    this.includeMetadata = true,
    this.sources,
    this.excludeSources,
  });

  /// Create from JSON
  factory ContextRequest.fromJson(Map<String, dynamic> json) =>
      _$ContextRequestFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ContextRequestToJson(this);

  /// Create a copy with updated fields
  ContextRequest copyWith({
    String? query,
    String? userId,
    String? sessionId,
    int? maxTokens,
    int? maxChunks,
    double? minRelevance,
    PrivacyLevel? privacyLevel,
    bool? includeMetadata,
    List<String>? sources,
    List<String>? excludeSources,
  }) {
    return ContextRequest(
      query: query ?? this.query,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      maxTokens: maxTokens ?? this.maxTokens,
      maxChunks: maxChunks ?? this.maxChunks,
      minRelevance: minRelevance ?? this.minRelevance,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      sources: sources ?? this.sources,
      excludeSources: excludeSources ?? this.excludeSources,
    );
  }

  @override
  String toString() {
    return 'ContextRequest(query: "$query", maxTokens: $maxTokens, privacy: $privacyLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextRequest &&
        other.query == query &&
        other.userId == userId &&
        other.sessionId == sessionId &&
        other.maxTokens == maxTokens;
  }

  @override
  int get hashCode => Object.hash(query, userId, sessionId, maxTokens);
}
