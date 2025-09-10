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
    // Initialize vector database first
    _vectorDatabase = VectorDatabase(
      vectorDbUrl: config.vectorDbUrl ?? 'memory://',
    );

    // Initialize context orchestrator with vector database
    _orchestrator = ContextOrchestrator(
      config: config,
      logger: logger,
      isTestMode: isTestMode,
      vectorDatabase: _vectorDatabase,
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
    } catch (e, stackTrace) {
      logger.e('Failed to initialize RAGify', error: e, stackTrace: stackTrace);
      rethrow;
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
    int? maxChunks,
    double? minRelevance,
    bool useCache = true,
    // Optional enterprise features
    String? userId,
    String? sessionId,
    PrivacyLevel? privacyLevel,
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
          if (cachedResponse is ContextResponse) {
            return cachedResponse;
          } else if (cachedResponse is Map<String, dynamic>) {
            return ContextResponse.fromJson(cachedResponse);
          } else {
            logger.w(
              'Cached response is not in expected format, ignoring cache',
            );
          }
        }
      }

      // Get context from orchestrator (which includes vector search fallback)
      final response = await _orchestrator.getContext(
        query: query,
        userId: userId,
        sessionId: sessionId,
        maxChunks: maxChunks,
        minRelevance: minRelevance,
        privacyLevel: effectivePrivacyLevel,
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
            response, // Store the object directly instead of JSON
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
          maxTokens: 0,
          // Use default from config
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
    // Create a 384-dimensional embedding based on text characteristics
    final embedding = List<double>.filled(384, 0.0);

    if (text.isEmpty) return embedding;

    final normalizedText = text.toLowerCase().trim();
    final words = normalizedText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final chars = normalizedText.split('');

    // Word-level analysis with exact matching priority (first 256 dimensions)
    if (words.isNotEmpty) {
      final wordFreq = <String, int>{};
      for (final word in words) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }

      int index = 0;
      final uniqueWords = words.toSet().toList();

      // Process each unique word with high priority
      for (int i = 0; i < uniqueWords.length && index < 200; i++) {
        final word = uniqueWords[i];
        final freq = wordFreq[word]!;

        // Create a strong signature for each word
        final wordHash = word.hashCode;
        final wordCode = word.codeUnits.fold(0, (a, b) => a + b);

        // Use multiple dimensions per word for better discrimination
        embedding[index] = (wordHash % 1000) / 1000.0;
        if (index + 1 < 200) {
          embedding[index + 1] = (wordCode % 1000) / 1000.0;
          index += 2;
        } else {
          index++;
        }

        // Add frequency information
        if (index < 200) {
          embedding[index] = (freq * 10 % 1000) / 1000.0;
          index++;
        }

        // Add word length information
        if (index < 200) {
          embedding[index] = (word.length % 100) / 100.0;
          index++;
        }
      }

      // Fill remaining word dimensions with zeros to ensure different words don't match
      while (index < 200) {
        embedding[index] = 0.0;
        index++;
      }
    }

    // Character frequency analysis (next 64 dimensions)
    final charFreq = <String, int>{};
    for (final char in chars) {
      charFreq[char] = (charFreq[char] ?? 0) + 1;
    }

    int index = 200;
    final sortedChars = charFreq.keys.toList()..sort();
    for (int i = 0; i < sortedChars.length && index < 264; i++) {
      final char = sortedChars[i];
      final freq = charFreq[char]!;
      final charCode = char.codeUnitAt(0);

      embedding[index] = (charCode % 100) / 100.0;
      if (index + 1 < 264) {
        embedding[index + 1] = (freq % 100) / 100.0;
        index += 2;
      } else {
        index++;
      }
    }

    // Text statistics (next 64 dimensions)
    index = 264;
    final textLength = text.length;
    final wordCount = words.length;
    final avgWordLength = wordCount > 0 ? textLength / wordCount : 0.0;
    final uniqueChars = charFreq.length;
    final uniqueWords = words.toSet().length;

    // Fill with text statistics
    final stats = [
      textLength / 1000.0, // Normalized text length
      wordCount / 100.0, // Normalized word count
      avgWordLength / 20.0, // Normalized average word length
      uniqueChars / 50.0, // Normalized unique character count
      uniqueWords / 50.0, // Normalized unique word count
    ];

    for (int i = 0; i < stats.length && index < 320; i++) {
      embedding[index] = stats[i].clamp(0.0, 1.0);
      index++;
    }

    // Position-based features (remaining dimensions)
    index = 320;
    for (int i = 0; i < chars.length && index < 384; i++) {
      final char = chars[i];
      final charCode = char.codeUnitAt(0);
      final position = i / chars.length; // Normalized position

      embedding[index] = ((charCode + i) % 100) / 100.0;
      if (index + 1 < 384) {
        embedding[index + 1] = position;
        index += 2;
      } else {
        index++;
      }
    }

    // Normalize the embedding to unit length
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
    double minSimilarity = 0.1, // Reasonable threshold for vector similarity
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
      logger.d(
        'Search parameters: maxResults=$maxResults, minSimilarity=$minSimilarity',
      );

      // Debug: Show what chunks are available
      final allVectorIds = await _vectorDatabase.getAllVectorIds();
      logger.d('Available vector IDs: $allVectorIds');

      // Skip vector database operations in test mode
      if (_isTestMode) {
        logger.d('Skipping vector similarity search in test mode');
        return [];
      }

      // First, try exact word matching for better relevance
      final queryWords = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      logger.d('Query words: $queryWords');

      // Generate embedding for the query
      final queryEmbedding = await _generateEmbedding(query);
      logger.d(
        'Generated query embedding with ${queryEmbedding.length} dimensions',
      );

      // Search for similar vectors
      final searchResults = await _vectorDatabase.searchVectors(
        queryEmbedding,
        maxResults,
        minScore: minSimilarity,
      );

      logger.d('Vector search returned ${searchResults.length} results');

      // Filter results based on relevance
      final filteredResults = <SearchResult>[];

      for (final result in searchResults) {
        try {
          final vectorData = await _vectorDatabase.getVectorData(result.id);
          if (vectorData != null) {
            final content = vectorData.metadata['content'] as String? ?? '';
            final contentLower = content.toLowerCase();

            // Check for exact word matches
            int exactMatches = 0;
            for (final word in queryWords) {
              if (contentLower.contains(word)) {
                exactMatches++;
              }
            }

            // Include results with exact matches OR high similarity scores
            if (exactMatches > 0 || result.score > 0.5) {
              filteredResults.add(result);
              logger.d(
                '✅ Including result: ${result.id} (exact: $exactMatches, score: ${result.score.toStringAsFixed(3)})',
              );
            } else {
              logger.d(
                '❌ Filtering out irrelevant result: ${result.id} (score: ${result.score.toStringAsFixed(3)})',
              );
            }
          }
        } catch (e) {
          logger.w('Failed to check result ${result.id}: $e');
          // Include result if we can't check it
          filteredResults.add(result);
        }
      }

      logger.d(
        'Filtered to ${filteredResults.length} relevant results out of ${searchResults.length} total',
      );
      final finalResults = filteredResults;

      // Convert search results back to context chunks using stored metadata
      final similarChunks = <ContextChunk>[];

      for (final result in finalResults) {
        try {
          // Get the full vector data including metadata
          final vectorData = await _vectorDatabase.getVectorData(result.id);
          if (vectorData == null) {
            logger.w('Vector data not found for ID: ${result.id}');
            continue;
          }

          // Reconstruct the original chunk from vector metadata
          final metadata = vectorData.metadata;
          final content =
              metadata['content'] as String? ?? 'Content not available';
          final sourceName = metadata['source'] as String? ?? 'unknown_source';
          final sourceTypeValue =
              metadata['sourceType'] as String? ?? 'document';
          final tags = List<String>.from(metadata['tags'] as List? ?? []);
          final createdAtMs =
              metadata['createdAt'] as int? ??
              DateTime.now().millisecondsSinceEpoch;

          // Create the original source
          final source = ContextSource(
            name: sourceName,
            sourceType: SourceType.fromString(sourceTypeValue),
            authorityScore: 0.8,
            // Default authority score
            lastUpdated: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
            isActive: true,
            freshnessScore: 1.0,
          );

          // Create the reconstructed chunk with the search score
          final chunk = ContextChunk(
            id: result.id,
            content: content,
            source: source,
            metadata: {
              ...metadata,
              'search_score': result.score,
              'search_timestamp': DateTime.now().millisecondsSinceEpoch,
            },
            tags: [
              ...tags,
              'search_result',
              'similarity:${result.score.toStringAsFixed(3)}',
            ],
            relevanceScore: RelevanceScore(score: result.score),
            createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
            updatedAt: DateTime.now(),
          );

          similarChunks.add(chunk);
        } catch (e) {
          logger.w('Failed to reconstruct chunk from search result: $e');
          // Fallback to a basic chunk if reconstruction fails
          final fallbackChunk = ContextChunk(
            id: result.id,
            content: 'Search result (reconstruction failed)',
            source: ContextSource(
              name: 'search_fallback',
              sourceType: SourceType.vector,
            ),
            tags: ['search_fallback', 'error'],
            relevanceScore: RelevanceScore(score: result.score),
          );
          similarChunks.add(fallbackChunk);
        }
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
}
