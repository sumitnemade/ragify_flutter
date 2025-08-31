/// Base exception for all RAGify-related errors
class RagifyException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const RagifyException(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) {
      return 'RagifyException[$code]: $message';
    }
    return 'RagifyException: $message';
  }
}

/// Exception thrown when context is not found
class ContextNotFoundException extends RagifyException {
  final String query;
  final String? userId;

  const ContextNotFoundException(this.query, {this.userId})
    : super('Context not found for query: $query', code: 'CONTEXT_NOT_FOUND');

  @override
  String toString() {
    return 'ContextNotFoundException: Context not found for query "$query"${userId != null ? ' (user: $userId)' : ''}';
  }
}

/// Exception thrown when there's a configuration error
class ConfigurationException extends RagifyException {
  final String field;
  final String value;

  const ConfigurationException(this.field, this.value)
    : super(
        'Configuration error for field "$field" with value "$value"',
        code: 'CONFIGURATION_ERROR',
      );

  @override
  String toString() {
    return 'ConfigurationException: Invalid configuration for $field: $value';
  }
}

/// Exception thrown when there's a privacy violation
class PrivacyViolationException extends RagifyException {
  final String operation;
  final String requiredLevel;
  final String actualLevel;

  const PrivacyViolationException(
    this.operation,
    this.requiredLevel,
    this.actualLevel,
  ) : super(
        'Privacy violation in $operation: required $requiredLevel, got $actualLevel',
        code: 'PRIVACY_VIOLATION',
      );

  @override
  String toString() {
    return 'PrivacyViolationException: Operation "$operation" requires $requiredLevel privacy level, but got $actualLevel';
  }
}

/// Exception thrown when there's a source connection error
class SourceConnectionException extends RagifyException {
  final String sourceName;
  final String sourceType;

  const SourceConnectionException(this.sourceName, this.sourceType)
    : super(
        'Failed to connect to $sourceType source: $sourceName',
        code: 'SOURCE_CONNECTION_ERROR',
      );

  @override
  String toString() {
    return 'SourceConnectionException: Failed to connect to $sourceType source "$sourceName"';
  }
}

/// Exception thrown when there's a vector database error
class VectorDatabaseException extends RagifyException {
  final String operation;
  final String? databaseType;

  const VectorDatabaseException(this.operation, {this.databaseType})
    : super(
        'Vector database error in $operation${databaseType != null ? ' for $databaseType' : ''}',
        code: 'VECTOR_DATABASE_ERROR',
      );

  @override
  String toString() {
    return 'VectorDatabaseException: Error in $operation${databaseType != null ? ' for $databaseType' : ''}';
  }
}

/// Exception thrown when there's a fusion error
class FusionException extends RagifyException {
  final String strategy;
  final int chunkCount;

  const FusionException(this.strategy, this.chunkCount)
    : super(
        'Fusion failed using strategy "$strategy" with $chunkCount chunks',
        code: 'FUSION_ERROR',
      );

  @override
  String toString() {
    return 'FusionException: Failed to fuse $chunkCount chunks using strategy "$strategy"';
  }
}

/// Exception thrown when there's a scoring error
class ScoringException extends RagifyException {
  final String method;
  final String? reason;

  const ScoringException(this.method, {this.reason})
    : super(
        'Scoring failed using method "$method"${reason != null ? ': $reason' : ''}',
        code: 'SCORING_ERROR',
      );

  @override
  String toString() {
    return 'ScoringException: Failed to score using method "$method"${reason != null ? ': $reason' : ''}';
  }
}

/// Exception thrown when there's a cache error
class CacheException extends RagifyException {
  final String operation;
  final String? cacheType;

  const CacheException(this.operation, {this.cacheType})
    : super(
        'Cache error in $operation${cacheType != null ? ' for $cacheType' : ''}',
        code: 'CACHE_ERROR',
      );

  @override
  String toString() {
    return 'CacheException: Error in $operation${cacheType != null ? ' for $cacheType' : ''}';
  }
}
