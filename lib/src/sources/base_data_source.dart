import '../models/context_chunk.dart';
import '../models/context_source.dart';

/// Abstract base class for all data sources
abstract class BaseDataSource {
  /// Name of the data source
  String get name;

  /// Type of data source
  SourceType get sourceType;

  /// Source configuration
  Map<String, dynamic> get config;

  /// Source metadata
  Map<String, dynamic> get metadata;

  /// Whether the source is currently active
  bool get isActive;

  /// Source object representation
  ContextSource get source;

  /// Get context chunks from this data source
  ///
  /// [query] - Search query
  /// [maxChunks] - Maximum number of chunks to return
  /// [minRelevance] - Minimum relevance threshold
  /// [userId] - Optional user ID for personalization
  /// [sessionId] - Optional session ID for continuity
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  });

  /// Refresh the data source
  ///
  /// This method should update the source's data and metadata
  Future<void> refresh();

  /// Close the data source and clean up resources
  Future<void> close();

  /// Get statistics about the data source
  Future<Map<String, dynamic>> getStats();

  /// Check if the source is healthy and accessible
  Future<bool> isHealthy();

  /// Get the source's current status
  Future<SourceStatus> getStatus();

  /// Update the source's metadata
  Future<void> updateMetadata(Map<String, dynamic> metadata);

  /// Get the source's configuration
  Map<String, dynamic> getConfiguration();

  /// Update the source's configuration
  Future<void> updateConfiguration(Map<String, dynamic> config);
}

/// Status of a data source
enum SourceStatus {
  /// Source is healthy and working normally
  healthy,

  /// Source has some issues but is still functional
  degraded,

  /// Source is not working properly
  unhealthy,

  /// Source is offline or unavailable
  offline,

  /// Source status is unknown
  unknown;

  String get value {
    switch (this) {
      case SourceStatus.healthy:
        return 'healthy';
      case SourceStatus.degraded:
        return 'degraded';
      case SourceStatus.unhealthy:
        return 'unhealthy';
      case SourceStatus.offline:
        return 'offline';
      case SourceStatus.unknown:
        return 'unknown';
    }
  }

  static SourceStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'healthy':
        return SourceStatus.healthy;
      case 'degraded':
        return SourceStatus.degraded;
      case 'unhealthy':
        return SourceStatus.unhealthy;
      case 'offline':
        return SourceStatus.offline;
      case 'unknown':
        return SourceStatus.unknown;
      default:
        return SourceStatus.unknown;
    }
  }
}
