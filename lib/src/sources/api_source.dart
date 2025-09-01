import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

import '../models/context_chunk.dart';
import '../models/context_source.dart';
import '../models/relevance_score.dart';
import '../models/privacy_level.dart';
import '../exceptions/ragify_exceptions.dart';
import '../config/dynamic_config_manager.dart';
import 'base_data_source.dart';

/// API Source for retrieving context from HTTP APIs
///
/// Supports REST APIs, GraphQL, and other HTTP-based data sources
/// with authentication, rate limiting, and error handling.
class APISource implements BaseDataSource {
  /// Name of the API source
  @override
  final String name;

  /// Type of data source
  @override
  final SourceType sourceType = SourceType.api;

  /// Source configuration
  @override
  final Map<String, dynamic> config;

  /// Source metadata
  @override
  final Map<String, dynamic> metadata;

  /// Whether the source is currently active
  @override
  bool get isActive => _isActive;

  /// Source object representation
  @override
  ContextSource get source => _source;

  /// Logger instance
  final Logger logger;

  /// Base URL for the API
  final String baseUrl;

  /// API authentication headers
  final Map<String, String> authHeaders;

  /// Request timeout duration
  final Duration timeout;

  /// Rate limiting configuration
  final RateLimitConfig rateLimit;

  /// Adaptive timeout configuration
  final AdaptiveTimeoutConfig adaptiveTimeout;

  /// Cache for API responses
  final Map<String, CachedResponse> _responseCache = {};

  /// HTTP client instance
  late final http.Client _httpClient;

  /// Internal state
  bool _isActive = true;
  late ContextSource _source;
  DateTime? _lastRequestTime;
  Duration? _lastResponseTime;

  /// Create a new API source
  APISource({
    required this.name,
    required this.baseUrl,
    Logger? logger,
    Map<String, dynamic>? config,
    Map<String, dynamic>? metadata,
    Map<String, String>? authHeaders,
    Duration? timeout,
    RateLimitConfig? rateLimit,
    AdaptiveTimeoutConfig? adaptiveTimeout,
    http.Client? httpClient,
  }) : logger = logger ?? Logger(),
       config = config ?? {},
       metadata = metadata ?? {},
       authHeaders = authHeaders ?? {},
       timeout =
           timeout ??
           DynamicConfigManager.instance.getTimeoutConfig()['api_request'] ??
           const Duration(seconds: 30),
       rateLimit = rateLimit ?? RateLimitConfig(),
       adaptiveTimeout = adaptiveTimeout ?? const AdaptiveTimeoutConfig() {
    _httpClient = httpClient ?? http.Client();
    _source = ContextSource(
      name: name,
      sourceType: sourceType,
      url: baseUrl,
      metadata: metadata,
      privacyLevel: PrivacyLevel.private,
      authorityScore: 0.7,
      freshnessScore: 1.0,
    );
  }

  /// Get context chunks from the API
  @override
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  }) async {
    if (!_isActive) {
      throw StateError('API source is not active');
    }

    try {
      logger.i('Querying API for: $query');

      // Check rate limiting
      await _checkRateLimit();

      // Build API request
      final request = _buildAPIRequest(query, userId, sessionId);

      // Check cache first
      final cacheKey = _generateCacheKey(request);
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        logger.d('Using cached response for query: $query');
        return _processAPIResponse(cached.data, query, maxChunks, minRelevance);
      }

      // Make API request
      final response = await _makeAPIRequest(request);

      // Cache response
      _setCache(cacheKey, response);

      // Process response into chunks
      final chunks = _processAPIResponse(
        response,
        query,
        maxChunks,
        minRelevance,
      );

      logger.i('Retrieved ${chunks.length} chunks from API');
      return chunks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to get chunks from API',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Build API request based on configuration
  Map<String, dynamic> _buildAPIRequest(
    String query,
    String? userId,
    String? sessionId,
  ) {
    final request = <String, dynamic>{
      'query': query,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (userId != null) {
      request['user_id'] = userId;
    }

    if (sessionId != null) {
      request['session_id'] = sessionId;
    }

    // Add configuration-based parameters
    if (config.containsKey('api_version')) {
      request['version'] = config['api_version'];
    }

    if (config.containsKey('language')) {
      request['language'] = config['language'];
    }

    return request;
  }

  /// Make HTTP request to the API
  Future<Map<String, dynamic>> _makeAPIRequest(
    Map<String, dynamic> request,
  ) async {
    final url = Uri.parse('$baseUrl/query');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...authHeaders,
    };

    // Add custom headers from config
    if (config.containsKey('custom_headers') &&
        config['custom_headers'] is Map) {
      headers.addAll(Map<String, String>.from(config['custom_headers']));
    }

    // Calculate adaptive timeout based on network conditions
    final adaptiveTimeoutDuration = adaptiveTimeout.calculateTimeout(
      _lastResponseTime,
    );

    final response = await _httpClient
        .post(url, headers: headers, body: jsonEncode(request))
        .timeout(adaptiveTimeoutDuration);

    _lastRequestTime = DateTime.now();
    _lastResponseTime = DateTime.now().difference(_lastRequestTime!);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } else if (response.statusCode == 401) {
      throw SourceConnectionException(name, 'authentication_failed');
    } else if (response.statusCode == 429) {
      throw SourceConnectionException(name, 'rate_limit_exceeded');
    } else {
      throw SourceConnectionException(
        name,
        'http_error_${response.statusCode}',
      );
    }
  }

  /// Process API response into context chunks
  List<ContextChunk> _processAPIResponse(
    Map<String, dynamic> response,
    String query,
    int? maxChunks,
    double minRelevance,
  ) {
    final chunks = <ContextChunk>[];

    try {
      final results = response['results'] as List<dynamic>? ?? [];

      for (final result in results) {
        if (result is Map<String, dynamic>) {
          final chunk = _createChunkFromResult(result, query);
          final relevanceScore = chunk.relevanceScore?.score ?? 0.0;
          if (relevanceScore >= minRelevance) {
            chunks.add(chunk);
          }
        }
      }

      // Sort by relevance score
      chunks.sort(
        (a, b) => (b.relevanceScore?.score ?? 0.0).compareTo(
          a.relevanceScore?.score ?? 0.0,
        ),
      );

      // Limit by max chunks
      if (maxChunks != null && chunks.length > maxChunks) {
        chunks.removeRange(maxChunks, chunks.length);
      }
    } catch (e) {
      logger.w('Failed to process API response: $e');
    }

    return chunks;
  }

  /// Create a context chunk from API result
  ContextChunk _createChunkFromResult(
    Map<String, dynamic> result,
    String query,
  ) {
    final content = result['content'] as String? ?? '';
    final score = (result['score'] as num?)?.toDouble() ?? 0.0;

    // Create metadata from result
    final metadata = <String, dynamic>{
      'api_source': name,
      'result_id': result['id'] ?? '',
      'confidence': result['confidence'] ?? 0.0,
      'source_url': result['source_url'] ?? '',
      'last_updated':
          result['last_updated'] ?? DateTime.now().toIso8601String(),
    };

    // Add custom metadata from result
    if (result.containsKey('metadata')) {
      final metadataValue = result['metadata'];
      if (metadataValue is Map) {
        metadata.addAll(Map<String, dynamic>.from(metadataValue));
      }
    }

    // Create tags from result
    final tags = <String>['api', 'external'];

    if (result.containsKey('category')) {
      final category = result['category'];
      if (category != null) {
        tags.add(category.toString());
      }
    }

    if (result.containsKey('type')) {
      final type = result['type'];
      if (type != null) {
        tags.add(type.toString());
      }
    }

    return ContextChunk(
      content: content,
      source: _source,
      metadata: metadata,
      relevanceScore: RelevanceScore(score: score),
      tags: tags.where((tag) => tag.isNotEmpty).toList(),
    );
  }

  /// Check rate limiting before making request
  Future<void> _checkRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < rateLimit.minInterval) {
        final waitTime = rateLimit.minInterval - timeSinceLastRequest;
        logger.d('Rate limiting: waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }
  }

  /// Generate cache key for request
  String _generateCacheKey(Map<String, dynamic> request) {
    final keyData = {
      'query': request['query'],
      'user_id': request['user_id'],
      'session_id': request['session_id'],
      'version': request['version'],
      'language': request['language'],
    };
    return jsonEncode(keyData);
  }

  /// Get response from cache
  CachedResponse? _getFromCache(String key) {
    final cached = _responseCache[key];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.timestamp) > rateLimit.cacheTtl) {
      _responseCache.remove(key);
      return null;
    }

    return cached;
  }

  /// Set response in cache
  void _setCache(String key, Map<String, dynamic> data) {
    if (_responseCache.length >= rateLimit.maxCacheSize) {
      // Remove oldest entry
      final oldestKey = _responseCache.keys.first;
      _responseCache.remove(oldestKey);
    }

    _responseCache[key] = CachedResponse(data: data, timestamp: DateTime.now());
  }

  /// Refresh the API source
  @override
  Future<void> refresh() async {
    logger.i('Refreshing API source: $name');

    // Clear cache to force fresh requests
    _responseCache.clear();

    // Update source metadata
    _source = _source.copyWith(lastUpdated: DateTime.now(), isActive: true);

    logger.i('API source refreshed successfully');
  }

  /// Close the API source
  @override
  Future<void> close() async {
    logger.i('Closing API source: $name');

    _isActive = false;
    _responseCache.clear();
    _httpClient.close();

    logger.i('API source closed');
  }

  /// Get source statistics
  @override
  Future<Map<String, dynamic>> getStats() async {
    final currentTimeout = adaptiveTimeout.calculateTimeout(_lastResponseTime);

    return {
      'name': name,
      'type': sourceType.value,
      'base_url': baseUrl,
      'auth_configured': authHeaders.isNotEmpty,
      'base_timeout_ms': timeout.inMilliseconds,
      'current_timeout_ms': currentTimeout.inMilliseconds,
      'last_response_time_ms': _lastResponseTime?.inMilliseconds,
      'adaptive_timeout': {
        'enabled': adaptiveTimeout.enabled,
        'base_timeout_ms': adaptiveTimeout.baseTimeout.inMilliseconds,
        'min_timeout_ms': adaptiveTimeout.minTimeout.inMilliseconds,
        'max_timeout_ms': adaptiveTimeout.maxTimeout.inMilliseconds,
        'slow_network_multiplier': adaptiveTimeout.slowNetworkMultiplier,
        'fast_network_multiplier': adaptiveTimeout.fastNetworkMultiplier,
        'network_quality_threshold_ms': adaptiveTimeout.networkQualityThreshold,
      },
      'rate_limit': {
        'min_interval_ms': rateLimit.minInterval.inMilliseconds,
        'max_requests_per_minute': rateLimit.maxRequestsPerMinute,
        'cache_ttl_ms': rateLimit.cacheTtl.inMilliseconds,
        'max_cache_size': rateLimit.maxCacheSize,
      },
      'cache_size': _responseCache.length,
      'is_active': _isActive,
      'last_request': _lastRequestTime?.toIso8601String(),
    };
  }

  /// Check if source is healthy
  @override
  Future<bool> isHealthy() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final healthTimeout = adaptiveTimeout.calculateTimeout(_lastResponseTime);
      final response = await _httpClient.get(url).timeout(healthTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get source status
  @override
  Future<SourceStatus> getStatus() async {
    if (!_isActive) return SourceStatus.offline;

    final healthy = await isHealthy();
    if (healthy) {
      return SourceStatus.healthy;
    } else {
      return SourceStatus.unhealthy;
    }
  }

  /// Update source metadata
  @override
  Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    this.metadata.addAll(metadata);
    _source = _source.copyWith(metadata: this.metadata);
    logger.d('Updated metadata for source: $name');
  }

  /// Get source configuration
  @override
  Map<String, dynamic> getConfiguration() => config;

  /// Update source configuration
  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    this.config.addAll(config);
    logger.d('Updated configuration for source: $name');
  }
}

/// Configuration for adaptive timeout strategies
class AdaptiveTimeoutConfig {
  /// Base timeout duration
  final Duration baseTimeout;

  /// Maximum timeout duration
  final Duration maxTimeout;

  /// Minimum timeout duration
  final Duration minTimeout;

  /// Timeout multiplier for slow networks
  final double slowNetworkMultiplier;

  /// Timeout multiplier for fast networks
  final double fastNetworkMultiplier;

  /// Network quality threshold (response time in ms)
  final int networkQualityThreshold;

  /// Enable adaptive timeouts
  final bool enabled;

  const AdaptiveTimeoutConfig({
    this.baseTimeout = const Duration(seconds: 30),
    this.maxTimeout = const Duration(seconds: 120),
    this.minTimeout = const Duration(seconds: 5),
    this.slowNetworkMultiplier = 2.0,
    this.fastNetworkMultiplier = 0.8,
    this.networkQualityThreshold = 1000, // 1 second
    this.enabled = true,
  });

  /// Calculate adaptive timeout based on network conditions
  Duration calculateTimeout(Duration? lastResponseTime) {
    if (!enabled || lastResponseTime == null) {
      return baseTimeout;
    }

    final responseTimeMs = lastResponseTime.inMilliseconds;

    if (responseTimeMs > networkQualityThreshold) {
      // Slow network - increase timeout
      final newTimeout = (baseTimeout.inMilliseconds * slowNetworkMultiplier)
          .round();
      return Duration(
        milliseconds: newTimeout.clamp(
          minTimeout.inMilliseconds,
          maxTimeout.inMilliseconds,
        ),
      );
    } else if (responseTimeMs < networkQualityThreshold / 2) {
      // Fast network - decrease timeout
      final newTimeout = (baseTimeout.inMilliseconds * fastNetworkMultiplier)
          .round();
      return Duration(
        milliseconds: newTimeout.clamp(
          minTimeout.inMilliseconds,
          maxTimeout.inMilliseconds,
        ),
      );
    }

    return baseTimeout;
  }
}

/// Configuration for rate limiting
class RateLimitConfig {
  /// Minimum interval between requests
  final Duration minInterval;

  /// Maximum requests per minute
  final int maxRequestsPerMinute;

  /// Cache TTL for responses
  final Duration cacheTtl;

  /// Maximum cache size
  final int maxCacheSize;

  const RateLimitConfig({
    this.minInterval = const Duration(milliseconds: 100),
    this.maxRequestsPerMinute = 60,
    this.cacheTtl = const Duration(minutes: 5),
    this.maxCacheSize = 100,
  });
}

/// Cached API response
class CachedResponse {
  /// Response data
  final Map<String, dynamic> data;

  /// When the response was cached
  final DateTime timestamp;

  const CachedResponse({required this.data, required this.timestamp});
}
