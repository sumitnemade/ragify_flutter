import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';

import 'core/context_orchestrator.dart';
import 'core/ragify_config.dart';
import 'cache/cache_manager.dart';
import 'privacy/privacy_manager.dart';
import 'security/security_manager.dart';
import 'storage/vector_database.dart';
import 'sources/database_source.dart';
import 'sources/base_data_source.dart';
import 'models/context_chunk.dart';
import 'models/context_response.dart';
import 'models/context_source.dart';
import 'models/privacy_level.dart';
import 'models/relevance_score.dart';
import 'exceptions/ragify_exceptions.dart';
import 'scoring/advanced_scoring_engine.dart';
import 'fusion/advanced_fusion_engine.dart';
import 'platform/platform_detector.dart';
import 'package:uuid/uuid.dart';

/// Main RAGify class that integrates all features
///
/// This class provides a unified interface for:
/// - Context orchestration and retrieval
/// - Cache management
/// - Privacy controls
/// - Vector database operations
/// - Data source management
class RAGify {
  /// Configuration for the RAGify instance
  final RagifyConfig config;

  /// Logger instance
  final Logger logger;

  /// Main context orchestrator
  late final ContextOrchestrator _orchestrator;

  /// Cache manager for performance optimization
  late final CacheManager _cacheManager;

  /// Privacy manager for data protection
  late final PrivacyManager _privacyManager;

  /// Security manager for encryption and access control
  late final SecurityManager _securityManager;

  /// Vector database for similarity search
  late final VectorDatabase _vectorDatabase;

  /// Advanced scoring engine for intelligent relevance scoring
  late final AdvancedScoringEngine _advancedScoringEngine;

  /// Advanced fusion engine for intelligent context fusion
  late final AdvancedFusionEngine _advancedFusionEngine;

  /// Whether RAGify is initialized
  bool _isInitialized = false;

  /// Whether RAGify is closed
  bool _isClosed = false;

  /// Whether RAGify is running in test mode
  final bool _isTestMode;

  /// Create a new RAGify instance
  RAGify({RagifyConfig? config, Logger? logger, bool isTestMode = false})
    : config = config ?? RagifyConfig.defaultConfig(),
      logger = logger ?? Logger(),
      _isTestMode = isTestMode {
    _initializeComponents(isTestMode);
  }

  /// Initialize all components
  void _initializeComponents(bool isTestMode) {
    // Initialize context orchestrator
    _orchestrator = ContextOrchestrator(
      config: config,
      logger: logger,
      isTestMode: isTestMode,
    );

    // Initialize cache manager
    _cacheManager = CacheManager(
      config: {
        'max_memory_mb':
            config.maxContextSize ~/ 1000, // Scale cache with context size
        'default_ttl_seconds': config.cacheTtl,
        'enable_redis': config.cacheUrl != null,
        'redis_url': config.cacheUrl,
      },
    );

    // Initialize privacy manager
    _privacyManager = PrivacyManager();

    // Initialize security manager
    _securityManager = SecurityManager(initialLevel: SecurityLevel.medium);

    // Initialize vector database
    _vectorDatabase = VectorDatabase(
      vectorDbUrl: config.vectorDbUrl ?? 'memory://',
    );

    // Initialize advanced scoring engine
    _advancedScoringEngine = AdvancedScoringEngine(
      cacheManager: _cacheManager,
      vectorDatabase: _vectorDatabase,
    );

    // Initialize advanced fusion engine
    _advancedFusionEngine = AdvancedFusionEngine(
      cacheManager: _cacheManager,
      vectorDatabase: _vectorDatabase,
    );
  }

  /// Initialize RAGify and all components
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.w('RAGify already initialized');
      return;
    }

    try {
      logger.i('Initializing RAGify...');
      logger.i('Platform: ${PlatformDetector.platformName}');

      // Initialize orchestrator
      await _orchestrator.initialize();

      // Initialize cache manager
      // Cache manager doesn't need explicit initialization
      logger.d('Cache manager ready');

      // Privacy manager doesn't need explicit initialization
      logger.d('Privacy manager ready');

      // Initialize security manager
      await _securityManager.initialize();
      logger.d('Security manager initialized');

      // Initialize vector database (skip in test mode to avoid platform dependencies)
      if (!_isTestMode) {
        try {
          await _vectorDatabase.initialize();
          logger.d('Vector database initialized');
        } catch (e) {
          logger.w('Failed to initialize vector database: $e');
          // Continue without vector database in test mode
        }
      } else {
        logger.d('Vector database initialization skipped in test mode');
      }

      _isInitialized = true;
      logger.i(
        'RAGify initialized successfully on ${PlatformDetector.platformName}',
      );

      // Log platform capabilities
      _logPlatformCapabilities();
    } catch (e, stackTrace) {
      logger.e('Failed to initialize RAGify', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Log platform capabilities and optimizations
  void _logPlatformCapabilities() {
    final capabilities = {
      'aiModelApis': PlatformDetector.supportsFeature(
        PlatformFeature.aiModelApis,
      ),
      'vectorOperations': PlatformDetector.supportsFeature(
        PlatformFeature.vectorOperations,
      ),
      'sqlite': PlatformDetector.supportsFeature(PlatformFeature.sqlite),
      'webStorage': PlatformDetector.supportsFeature(
        PlatformFeature.webStorage,
      ),
      'fileSystem': PlatformDetector.supportsFeature(
        PlatformFeature.fileSystem,
      ),
    };

    logger.d('Platform capabilities: $capabilities');

    // Log platform-specific optimizations
    if (PlatformDetector.isWeb) {
      logger.i('Web platform: Using IndexedDB + TensorFlow.js optimizations');
    } else if (PlatformDetector.isMobile) {
      logger.i('Mobile platform: Using SQLite + TensorFlow Lite optimizations');
    } else if (PlatformDetector.isDesktop) {
      logger.i(
        'Desktop platform: Using File System + TensorFlow Lite optimizations',
      );
    } else {
      logger.i('Other platform: Using fallback implementations');
    }
  }

  /// Get platform information and capabilities
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': PlatformDetector.platformName,
      'isWeb': PlatformDetector.isWeb,
      'isMobile': PlatformDetector.isMobile,
      'isDesktop': PlatformDetector.isDesktop,
      'isFuchsia': PlatformDetector.isFuchsia,
      'features': {
        'aiModelApis': PlatformDetector.supportsFeature(
          PlatformFeature.aiModelApis,
        ),
        'vectorOperations': PlatformDetector.supportsFeature(
          PlatformFeature.vectorOperations,
        ),
        'sqlite': PlatformDetector.supportsFeature(PlatformFeature.sqlite),
        'webStorage': PlatformDetector.supportsFeature(
          PlatformFeature.webStorage,
        ),
        'fileSystem': PlatformDetector.supportsFeature(
          PlatformFeature.fileSystem,
        ),
      },
    };
  }

  /// Check if a specific platform feature is supported
  bool supportsPlatformFeature(PlatformFeature feature) {
    return PlatformDetector.supportsFeature(feature);
  }

  /// Get platform-specific recommendations for optimal usage
  Map<String, String> getPlatformRecommendations() {
    if (PlatformDetector.isWeb) {
      return {
        'storage': 'Use IndexedDB for large data, localStorage for small data',
        'ml': 'Use TensorFlow.js with WebGL acceleration',
        'performance': 'Optimize for browser limitations',
        'security': 'Limited by browser security model',
      };
    } else if (PlatformDetector.isMobile) {
      return {
        'storage': 'Use SQLite for persistent data',
        'ml': 'Use TensorFlow Lite with hardware acceleration',
        'performance': 'Optimize for battery life',
        'security': 'Full encryption and security features',
      };
    } else if (PlatformDetector.isDesktop) {
      return {
        'storage': 'Use file system for large data',
        'ml': 'Use TensorFlow Lite with full resources',
        'performance': 'Maximum performance available',
        'security': 'Full encryption and security features',
      };
    } else {
      return {
        'storage': 'Use fallback storage implementation',
        'ml': 'Limited ML capabilities',
        'performance': 'Basic performance',
        'security': 'Basic security features',
      };
    }
  }

  /// Add a data source to RAGify
  void addDataSource(BaseDataSource source) {
    _orchestrator.addSource(source);
    logger.i('Added data source: ${source.name}');
  }

  /// Remove a data source from RAGify
  void removeDataSource(String sourceName) {
    _orchestrator.removeSource(sourceName);
    logger.i('Removed data source: $sourceName');
  }

  /// Get context for a query with full feature integration
  Future<ContextResponse> getContext({
    required String query,
    String? userId,
    String? sessionId,
    int? maxTokens,
    int? maxChunks,
    double? minRelevance,
    PrivacyLevel? privacyLevel,
    bool includeMetadata = true,
    List<String>? sources,
    List<String>? excludeSources,
    bool useCache = true,
    bool useVectorSearch = true,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_isClosed) {
        throw StateError('Cannot get context from closed RAGify instance');
      }

      // Check privacy level
      final effectivePrivacyLevel = privacyLevel ?? config.privacyLevel;
      // For now, use a simple privacy check - in production, implement proper user privacy level management
      if (effectivePrivacyLevel == PrivacyLevel.restricted) {
        throw PrivacyViolationException(
          'context_retrieval',
          'private',
          effectivePrivacyLevel.value,
        );
      }

      // Try cache first if enabled
      if (useCache && config.enableCaching) {
        final cacheKey = _generateCacheKey(
          query,
          userId,
          sessionId,
          effectivePrivacyLevel,
        );
        final cachedResponse = await _cacheManager.get(cacheKey);
        if (cachedResponse != null) {
          logger.d('Returning cached context for query: $query');
          if (cachedResponse is Map<String, dynamic>) {
            return ContextResponse.fromJson(cachedResponse);
          } else {
            logger.w(
              'Cached response is not in expected format, ignoring cache',
            );
          }
        }
      }

      // Get context from orchestrator
      final response = await _orchestrator.getContext(
        query: query,
        userId: userId,
        sessionId: sessionId,
        maxTokens: maxTokens,
        maxChunks: maxChunks,
        minRelevance: minRelevance,
        privacyLevel: effectivePrivacyLevel,
        includeMetadata: includeMetadata,
        sources: sources,
        excludeSources: excludeSources,
      );

      // Cache the response if enabled
      if (useCache && config.enableCaching) {
        try {
          final cacheKey = _generateCacheKey(
            query,
            userId,
            sessionId,
            effectivePrivacyLevel,
          );
          await _cacheManager.set(
            cacheKey,
            response.toJson(),
            ttl: Duration(seconds: config.cacheTtl),
          );
          logger.d('Successfully cached response for query: $query');
        } catch (cacheError) {
          logger.w(
            'Failed to cache response, continuing without caching: $cacheError',
          );
        }
      }

      // Privacy audit logging would be implemented here in production
      if (effectivePrivacyLevel == PrivacyLevel.enterprise ||
          effectivePrivacyLevel == PrivacyLevel.restricted) {
        logger.i(
          'Privacy audit: context_retrieval for user $userId, session $sessionId, level $effectivePrivacyLevel',
        );
      }

      return response;
    } catch (e, stackTrace) {
      // Log the error with full context
      logger.e(
        'Failed to get context for query: $query',
        error: e,
        stackTrace: stackTrace,
      );

      // Provide user-friendly error information
      if (e is PrivacyViolationException) {
        logger.e('Privacy violation: ${e.message}');
        rethrow; // Re-throw privacy violations as they are security issues
      } else if (e is StateError) {
        logger.e('State error: ${e.message}');
        rethrow; // Re-throw state errors as they indicate system issues
      }
      // else if (e is ContextNotFoundException) {
      //   // This should have been handled above, but just in case
      //   logger.w('Context not found for query: $query');
      //   rethrow;
      // }
      else {
        // For other unexpected errors, try to provide a meaningful error response
        logger.e('Unexpected error in getContext: $e');

        // Create an error response that can be handled by the caller
        final errorResponse = ContextResponse(
          id: const Uuid().v4(),
          query: query,
          chunks: [],
          userId: userId,
          sessionId: sessionId,
          maxTokens: maxTokens ?? 0,
          privacyLevel: privacyLevel ?? config.privacyLevel,
          metadata: {
            'error': 'Failed to retrieve context',
            'error_type': e.runtimeType.toString(),
            'error_message': e.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        return errorResponse;
      }
    }
  }

  /// Store context chunks in the vector database
  Future<void> storeChunks(List<ContextChunk> chunks) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Skip vector database operations in test mode
    if (_isTestMode) {
      logger.i('Skipping vector database operations in test mode');
      return;
    }

    try {
      logger.i('Storing ${chunks.length} chunks in vector database');

      // Convert chunks to vector data format
      final vectorDataList = <VectorData>[];

      for (final chunk in chunks) {
        // Generate embedding for the chunk content
        final embedding = await _generateEmbedding(chunk.content);

        // Create vector data
        final vectorData = VectorData(
          id: chunk.id,
          chunkId: chunk.id,
          embedding: embedding,
          metadata: {
            'content': chunk.content,
            'source': chunk.source.name,
            'sourceType': chunk.source.sourceType.value,
            'tags': chunk.tags,
            'createdAt': chunk.createdAt.millisecondsSinceEpoch,
            'relevanceScore': chunk.relevanceScore?.score,
          },
        );

        vectorDataList.add(vectorData);
      }

      // Store vectors in the database
      await _vectorDatabase.addVectors(vectorDataList);

      logger.i(
        'Successfully stored ${chunks.length} chunks in vector database',
      );
    } catch (e) {
      logger.e('Failed to store chunks in vector database: $e');
      rethrow;
    }
  }

  /// Generate embedding for text content
  Future<List<double>> _generateEmbedding(String text) async {
    try {
      // For web platform, use a simple hash-based embedding
      if (PlatformDetector.isWeb) {
        return _generateSimpleEmbedding(text);
      }

      // For native platforms, use proper embedding generation
      // This would integrate with TensorFlow Lite or other ML libraries
      return _generateSimpleEmbedding(text);
    } catch (e) {
      logger.w('Failed to generate embedding, using fallback: $e');
      return _generateSimpleEmbedding(text);
    }
  }

  /// Generate simple embedding using hash-based approach
  List<double> _generateSimpleEmbedding(String text) {
    // Create a simple 384-dimensional embedding based on text characteristics
    final embedding = List<double>.filled(384, 0.0);

    // Use character frequency and position to generate embedding
    final chars = text.toLowerCase().split('');
    final charFreq = <String, int>{};

    for (final char in chars) {
      charFreq[char] = (charFreq[char] ?? 0) + 1;
    }

    // Fill embedding based on character frequencies and positions
    int index = 0;
    for (final char in charFreq.keys) {
      if (index >= 384) break;

      final freq = charFreq[char]!;
      final charCode = char.codeUnitAt(0);

      // Use character code and frequency to generate embedding values
      embedding[index] = (charCode % 100) / 100.0;
      if (index + 1 < 384) {
        embedding[index + 1] = (freq % 100) / 100.0;
        index += 2;
      } else {
        index++;
      }
    }

    // Normalize the embedding
    final magnitude = sqrt(embedding.map((x) => x * x).reduce((a, b) => a + b));
    if (magnitude > 0) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] = embedding[i] / magnitude;
      }
    }

    return embedding;
  }

  /// Search for similar chunks using vector similarity
  Future<List<ContextChunk>> searchSimilarChunks(
    String query,
    int maxResults, {
    double minSimilarity = 0.7,
    PrivacyLevel? privacyLevel,
    String? userId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check privacy level
    final effectivePrivacyLevel = privacyLevel ?? config.privacyLevel;
    if (effectivePrivacyLevel == PrivacyLevel.restricted) {
      throw PrivacyViolationException(
        'vector_search',
        'private',
        effectivePrivacyLevel.value,
      );
    }

    try {
      logger.i('Performing vector similarity search for query: $query');

      // Skip vector database operations in test mode
      if (_isTestMode) {
        logger.d('Skipping vector similarity search in test mode');
        return [];
      }

      // Generate embedding for the query
      final queryEmbedding = await _generateEmbedding(query);

      // Search for similar vectors
      final searchResults = await _vectorDatabase.searchVectors(
        queryEmbedding,
        maxResults,
        minScore: minSimilarity,
      );

      // Convert search results back to context chunks
      final similarChunks = <ContextChunk>[];

      for (final result in searchResults) {
        // Get the original chunk from the orchestrator or cache
        // For now, we'll create a simplified chunk with the search result
        final chunk = ContextChunk(
          content:
              'Similar content found (Score: ${result.score.toStringAsFixed(3)})',
          source: ContextSource(
            name: 'vector_search',
            sourceType: SourceType.vector,
          ),
          tags: [
            'vector_search',
            'similarity:${result.score.toStringAsFixed(3)}',
          ],
          relevanceScore: RelevanceScore(score: result.score),
        );

        similarChunks.add(chunk);
      }

      logger.i(
        'Vector search completed: found ${similarChunks.length} similar chunks',
      );
      return similarChunks;
    } catch (e) {
      logger.e('Vector search failed: $e');
      rethrow;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cacheManager.getStats().toJson();
  }

  /// Get privacy manager statistics
  Map<String, dynamic> getPrivacyStats() {
    return _privacyManager.getPrivacyStats();
  }

  /// Get security manager statistics
  Map<String, dynamic> getSecurityStats() {
    return _securityManager.getSecurityStats();
  }

  /// Get vector database statistics
  Map<String, dynamic> getVectorDatabaseStats() {
    return _vectorDatabase.getStats();
  }

  /// Get advanced scoring engine statistics
  Map<String, dynamic> getAdvancedScoringStats() {
    return _advancedScoringEngine.getStats();
  }

  /// Get advanced fusion engine statistics
  Map<String, dynamic> getAdvancedFusionStats() {
    return _advancedFusionEngine.getStats();
  }

  /// Get the advanced scoring engine instance
  AdvancedScoringEngine get advancedScoringEngine => _advancedScoringEngine;

  /// Get the advanced fusion engine instance
  AdvancedFusionEngine get advancedFusionEngine => _advancedFusionEngine;

  /// Calculate advanced relevance score for a context chunk
  Future<RelevanceScore> calculateAdvancedScore(
    ContextChunk chunk,
    String query, {
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _advancedScoringEngine.calculateAdvancedScore(
        chunk,
        query,
        userId: userId,
        context: context,
      );
    } catch (e) {
      logger.e('Failed to calculate advanced score: $e');
      rethrow;
    }
  }

  /// Update user profile for personalization
  void updateUserProfile(
    String userId, {
    String? topic,
    String? source,
    String? contentType,
    String? query,
    double interactionScore = 1.0,
  }) {
    _advancedScoringEngine.updateUserProfile(
      userId,
      topic: topic,
      source: source,
      contentType: contentType,
      query: query,
      interactionScore: interactionScore,
    );
    logger.i('Updated user profile for user: $userId');
  }

  /// Get user profile for personalization
  UserProfile? getUserProfile(String userId) {
    return _advancedScoringEngine.getUserProfile(userId);
  }

  /// Perform advanced fusion on context chunks
  Future<List<ContextChunk>> performAdvancedFusion({
    required List<ContextChunk> chunks,
    required String query,
    String? userId,
    Map<String, dynamic>? context,
    List<String>? enabledStrategies,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _advancedFusionEngine.performAdvancedFusion(
        chunks: chunks,
        query: query,
        userId: userId,
        context: context,
        enabledStrategies: enabledStrategies,
      );
    } catch (e) {
      logger.e('Failed to perform advanced fusion: $e');
      rethrow;
    }
  }

  /// Get overall RAGify statistics
  Map<String, dynamic> getStats() {
    return {
      'is_initialized': _isInitialized,
      'is_closed': _isClosed,
      'config': config.toJson(),
      'orchestrator': _orchestrator.getStats(),
      'cache': getCacheStats(),
      'privacy': getPrivacyStats(),
      'security': getSecurityStats(),
      'vector_database': getVectorDatabaseStats(),
      'advanced_scoring': getAdvancedScoringStats(),
      'advanced_fusion': getAdvancedFusionStats(),
      'databases': getDatabaseStats(),
    };
  }

  /// Check if RAGify is healthy
  Future<bool> isHealthy() async {
    if (!_isInitialized || _isClosed) return false;

    try {
      // Check orchestrator health
      final orchestratorHealthy = await _orchestrator.isHealthy();
      if (!orchestratorHealthy) return false;

      // Check vector database health
      // Vector database health check would be implemented here
      // Assume healthy for now

      return true;
    } catch (e) {
      logger.w('Health check failed: $e');
      return false;
    }
  }

  /// Close RAGify and clean up resources
  Future<void> close() async {
    if (_isClosed) return;

    logger.i('Closing RAGify...');

    try {
      // Close orchestrator
      await _orchestrator.close();

      // Close cache manager
      _cacheManager.dispose();

      // Privacy manager doesn't need explicit closing

      // Close security manager
      await _securityManager.close();

      // Close vector database
      await _vectorDatabase.close();

      _isClosed = true;
      logger.i('RAGify closed successfully');
    } catch (e, stackTrace) {
      logger.e('Error closing RAGify', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate cache key for context requests
  String _generateCacheKey(
    String query,
    String? userId,
    String? sessionId,
    PrivacyLevel privacyLevel,
  ) {
    final components = [
      'context',
      query.hashCode.toString(),
      userId ?? 'anonymous',
      sessionId ?? 'no_session',
      privacyLevel.value,
    ];
    return components.join('_');
  }

  /// Get the context orchestrator (for advanced usage)
  ContextOrchestrator get orchestrator => _orchestrator;

  /// Get the cache manager (for advanced usage)
  CacheManager get cacheManager => _cacheManager;

  /// Get the privacy manager (for advanced usage)
  PrivacyManager get privacyManager => _privacyManager;

  /// Get the security manager (for advanced usage)
  SecurityManager get securityManager => _securityManager;

  /// Get the vector database (for advanced usage)
  VectorDatabase get vectorDatabase => _vectorDatabase;

  /// Add a database source to the system
  void addDatabaseSource(DatabaseSource source) {
    _orchestrator.addSource(source);
    logger.i('Database source added: ${source.name} (${source.databaseType})');
  }

  /// Get all database sources
  List<DatabaseSource> getDatabaseSources() {
    final sources = <DatabaseSource>[];
    for (final sourceName in _orchestrator.sourceNames) {
      final source = _orchestrator.getSource(sourceName);
      if (source is DatabaseSource) {
        sources.add(source);
      }
    }
    return sources;
  }

  /// Get database source by name
  DatabaseSource? getDatabaseSource(String name) {
    try {
      final source = _orchestrator.getSource(name);
      return source is DatabaseSource ? source : null;
    } catch (e) {
      return null;
    }
  }

  /// Remove database source by name
  void removeDatabaseSource(String name) {
    final source = getDatabaseSource(name);
    if (source != null) {
      _orchestrator.removeSource(name);
      logger.i('Database source removed: $name');
    }
  }

  /// Store context chunks in all database sources
  Future<void> storeChunksInDatabases(List<ContextChunk> chunks) async {
    final databaseSources = getDatabaseSources();
    if (databaseSources.isEmpty) {
      logger.w('No database sources available for storing chunks');
      return;
    }

    for (final source in databaseSources) {
      try {
        await source.storeChunks(chunks);
        logger.i('Stored ${chunks.length} chunks in database: ${source.name}');
      } catch (e) {
        logger.e('Failed to store chunks in database ${source.name}: $e');
      }
    }
  }

  /// Get context chunks from all database sources
  Future<List<ContextChunk>> getChunksFromDatabases({
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    final databaseSources = getDatabaseSources();
    if (databaseSources.isEmpty) {
      logger.w('No database sources available for retrieving chunks');
      return [];
    }

    final allChunks = <ContextChunk>[];
    for (final source in databaseSources) {
      try {
        final chunks = await source.fetchData(
          query: query,
          filters: filters,
          limit: limit,
          offset: offset,
        );
        allChunks.addAll(chunks);
        logger.i(
          'Retrieved ${chunks.length} chunks from database: ${source.name}',
        );
      } catch (e) {
        logger.e('Failed to retrieve chunks from database ${source.name}: $e');
      }
    }

    return allChunks;
  }

  /// Get database source statistics
  Map<String, dynamic> getDatabaseStats() {
    final databaseSources = getDatabaseSources();
    final stats = <String, dynamic>{};

    for (final source in databaseSources) {
      stats[source.name] = {
        'database_type': source.databaseType,
        'host': source.databaseConfig.host,
        'port': source.databaseConfig.port,
        'database': source.databaseConfig.database,
        'is_active': source.isActive,
      };
    }

    return stats;
  }

  /// Check if current platform supports hardware acceleration
  bool get supportsHardwareAcceleration {
    return PlatformDetector.isMobile || PlatformDetector.isDesktop;
  }

  /// Check if current platform supports advanced features
  bool get supportsAdvancedFeatures {
    return PlatformDetector.supportsFeature(PlatformFeature.aiModelApis) ||
        PlatformDetector.supportsFeature(PlatformFeature.vectorOperations);
  }

  /// Check if current platform supports persistent storage
  bool get supportsPersistentStorage {
    return PlatformDetector.supportsFeature(PlatformFeature.sqlite) ||
        PlatformDetector.supportsFeature(PlatformFeature.fileSystem);
  }

  /// Get platform-optimized configuration
  Map<String, dynamic> getPlatformOptimizedConfig() {
    final baseConfig = config.toJson();

    // Add platform-specific optimizations
    if (PlatformDetector.isWeb) {
      baseConfig['platform_optimizations'] = {
        'max_context_size': (config.maxContextSize * 0.5)
            .round(), // Web: Reduce context size
        'cache_ttl': config.cacheTtl * 2, // Web: Increase cache TTL
        'vector_db_url': 'memory://vector_db', // Web: Use memory storage
        'enable_compression': true, // Web: Enable compression
      };
    } else if (PlatformDetector.isMobile) {
      baseConfig['platform_optimizations'] = {
        'max_context_size':
            config.maxContextSize, // Mobile: Use full context size
        'cache_ttl': config.cacheTtl, // Mobile: Use default cache TTL
        'vector_db_url':
            config.vectorDbUrl ?? 'faiss://vector_db', // Mobile: Use FAISS
        'enable_compression': true, // Mobile: Enable compression
        'battery_optimization': true, // Mobile: Enable battery optimization
      };
    } else if (PlatformDetector.isDesktop) {
      baseConfig['platform_optimizations'] = {
        'max_context_size': (config.maxContextSize * 1.5)
            .round(), // Desktop: Increase context size
        'cache_ttl': config.cacheTtl, // Desktop: Use default cache TTL
        'vector_db_url':
            config.vectorDbUrl ?? 'faiss://vector_db', // Desktop: Use FAISS
        'enable_compression':
            false, // Desktop: Disable compression for performance
        'parallel_processing': true, // Desktop: Enable parallel processing
      };
    } else {
      baseConfig['platform_optimizations'] = {
        'max_context_size':
            config.maxContextSize, // Other: Use default context size
        'cache_ttl': config.cacheTtl, // Other: Use default cache TTL
        'vector_db_url':
            config.vectorDbUrl ??
            'memory://vector_db', // Other: Use memory storage
        'enable_compression': true, // Other: Enable compression
      };
    }

    return baseConfig;
  }

  /// Get comprehensive platform status and health
  Map<String, dynamic> getPlatformStatus() {
    return {
      'platform': PlatformDetector.platformName,
      'is_initialized': _isInitialized,
      'is_closed': _isClosed,
      'capabilities': {
        'aiModelApis': PlatformDetector.supportsFeature(
          PlatformFeature.aiModelApis,
        ),
        'vectorOperations': PlatformDetector.supportsFeature(
          PlatformFeature.vectorOperations,
        ),
        'sqlite': PlatformDetector.supportsFeature(PlatformFeature.sqlite),
        'webStorage': PlatformDetector.supportsFeature(
          PlatformFeature.webStorage,
        ),
        'fileSystem': PlatformDetector.supportsFeature(
          PlatformFeature.fileSystem,
        ),
      },
      'features': {
        'advanced_features': supportsAdvancedFeatures,
        'persistent_storage': supportsPersistentStorage,
        'hardware_acceleration': supportsHardwareAcceleration,
      },
      'optimizations': getPlatformOptimizedConfig()['platform_optimizations'],
      'recommendations': getPlatformRecommendations(),
      'services': {
        'cache_manager': _cacheManager.getStats().toJson(),
        'privacy_manager': 'PrivacyManager (no status method)',
        'security_manager': 'SecurityManager (no status method)',
        'vector_database': _vectorDatabase.getStats(),
        'orchestrator': 'ContextOrchestrator (no status method)',
      },
    };
  }
}
