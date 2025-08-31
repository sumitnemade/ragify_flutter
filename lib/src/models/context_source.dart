import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'privacy_level.dart';

part 'context_source.g.dart';

/// Types of data sources
@JsonEnum()
enum SourceType {
  document,
  api,
  database,
  realtime,
  vector,
  cache;

  String get value {
    switch (this) {
      case SourceType.document:
        return 'document';
      case SourceType.api:
        return 'api';
      case SourceType.database:
        return 'database';
      case SourceType.realtime:
        return 'realtime';
      case SourceType.vector:
        return 'vector';
      case SourceType.cache:
        return 'cache';
    }
  }

  static SourceType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'document':
        return SourceType.document;
      case 'api':
        return SourceType.api;
      case 'database':
        return SourceType.database;
      case 'realtime':
        return SourceType.realtime;
      case 'vector':
        return SourceType.vector;
      case 'cache':
        return SourceType.cache;
      default:
        throw ArgumentError('Invalid source type: $value');
    }
  }
}

/// Represents a source of context data
@JsonSerializable()
class ContextSource {
  /// Unique identifier for the source
  final String id;

  /// Human-readable name for the source
  final String name;

  /// Type of data source
  @JsonKey(name: 'source_type')
  final SourceType sourceType;

  /// Optional URL or connection string
  final String? url;

  /// Additional metadata about the source
  final Map<String, dynamic> metadata;

  /// When the source was last updated
  @JsonKey(name: 'last_updated')
  final DateTime lastUpdated;

  /// Whether the source is currently active
  @JsonKey(name: 'is_active')
  final bool isActive;

  /// Privacy level for this source
  @JsonKey(name: 'privacy_level')
  final PrivacyLevel privacyLevel;

  /// Authority score (0.0 to 1.0) - higher = more authoritative
  @JsonKey(name: 'authority_score')
  final double authorityScore;

  /// Freshness score (0.0 to 1.0) - higher = more recent
  @JsonKey(name: 'freshness_score')
  final double freshnessScore;

  const ContextSource._({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.url,
    required this.metadata,
    required this.lastUpdated,
    required this.isActive,
    required this.privacyLevel,
    required this.authorityScore,
    required this.freshnessScore,
  });

  /// Create a new context source
  factory ContextSource({
    String? id,
    required String name,
    required SourceType sourceType,
    String? url,
    Map<String, dynamic>? metadata,
    DateTime? lastUpdated,
    bool? isActive,
    PrivacyLevel? privacyLevel,
    double? authorityScore,
    double? freshnessScore,
  }) {
    return ContextSource._(
      id: id ?? const Uuid().v4(),
      name: name,
      sourceType: sourceType,
      url: url,
      metadata: metadata ?? const {},
      lastUpdated: lastUpdated ?? DateTime.now(),
      isActive: isActive ?? true,
      privacyLevel: privacyLevel ?? PrivacyLevel.private,
      authorityScore: authorityScore ?? 0.5,
      freshnessScore: freshnessScore ?? 1.0,
    );
  }

  /// Create from JSON
  factory ContextSource.fromJson(Map<String, dynamic> json) =>
      _$ContextSourceFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ContextSourceToJson(this);

  /// Create a copy with updated fields
  ContextSource copyWith({
    String? id,
    String? name,
    SourceType? sourceType,
    String? url,
    Map<String, dynamic>? metadata,
    DateTime? lastUpdated,
    bool? isActive,
    PrivacyLevel? privacyLevel,
    double? authorityScore,
    double? freshnessScore,
  }) {
    return ContextSource(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceType: sourceType ?? this.sourceType,
      url: url ?? this.url,
      metadata: metadata ?? this.metadata,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      authorityScore: authorityScore ?? this.authorityScore,
      freshnessScore: freshnessScore ?? this.freshnessScore,
    );
  }

  @override
  String toString() {
    return 'ContextSource(id: $id, name: $name, type: $sourceType, privacy: $privacyLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextSource && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
