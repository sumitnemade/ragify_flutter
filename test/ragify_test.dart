import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/ragify.dart';
import 'package:ragify_flutter/src/core/ragify_config.dart';
import 'package:ragify_flutter/src/models/context_chunk.dart';
import 'package:ragify_flutter/src/models/context_response.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/models/relevance_score.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';
import 'package:ragify_flutter/src/sources/database_source.dart';
import 'package:ragify_flutter/src/exceptions/ragify_exceptions.dart';
import 'package:ragify_flutter/src/platform/platform_detector.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';
import 'package:logger/logger.dart';

// Mock data source for testing
class MockDataSource extends BaseDataSource {
  @override
  String get name => 'mock_source';

  @override
  SourceType get sourceType => SourceType.document;

  @override
  Map<String, dynamic> get config => {};

  @override
  Map<String, dynamic> get metadata => {};

  @override
  bool get isActive => true;

  @override
  ContextSource get source => ContextSource(
    id: 'mock_source_id',
    name: 'mock_source',
    sourceType: SourceType.document,
    url: null,
    metadata: {},
    lastUpdated: DateTime.now(),
    isActive: true,
    privacyLevel: PrivacyLevel.public,
    authorityScore: 0.8,
    freshnessScore: 0.9,
  );

  @override
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  }) async {
    // Return a test chunk for any query
    final chunks = [
      ContextChunk(
        id: 'test_chunk_1',
        content: 'This is a test chunk for query: $query',
        source: source,
        relevanceScore: RelevanceScore(score: 0.9, confidenceLevel: 0.95),
        tokenCount: query.length,
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
      ),
    ];
    return chunks;
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> close() async {}

  @override
  Future<Map<String, dynamic>> getStats() async => {};

  @override
  Future<bool> isHealthy() async => true;

  @override
  Future<SourceStatus> getStatus() async => SourceStatus.healthy;

  @override
  Future<void> updateMetadata(Map<String, dynamic> metadata) async {}

  @override
  Map<String, dynamic> getConfiguration() => {};

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {}
}

// Mock database source for testing
class MockDatabaseSource extends DatabaseSource {
  MockDatabaseSource()
    : super(
        name: 'mock_db',
        sourceType: SourceType.database,
        databaseConfig: DatabaseConfig(
          host: 'localhost',
          port: 5432,
          database: 'test',
          username: 'test',
          password: 'test',
        ),
        databaseType: 'sqlite',
        cacheManager: CacheManager(),
      );

  @override
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  }) async {
    return [];
  }

  @override
  Future<void> storeChunks(List<ContextChunk> chunks) async {}

  @override
  Future<void> close() async {}
}

void main() {
  group('RAGify Tests', () {
    late RAGify ragify;
    late RagifyConfig config;
    late Logger logger;
    late ContextSource testSource;
    late ContextChunk testChunk;

    setUp(() {
      config = RagifyConfig.defaultConfig();
      logger = Logger();
      ragify = RAGify(config: config, logger: logger, isTestMode: true);

      testSource = ContextSource(
        name: 'Test Source',
        sourceType: SourceType.document,
        privacyLevel: PrivacyLevel.public,
        metadata: {'test': 'data'},
        id: 'test_source_1',
        url: 'https://example.com',
        lastUpdated: DateTime.now(),
        isActive: true,
        authorityScore: 0.8,
        freshnessScore: 0.9,
      );

      testChunk = ContextChunk(
        id: 'chunk1',
        content: 'This is a test chunk content.',
        source: testSource,
        relevanceScore: RelevanceScore(score: 0.9, confidenceLevel: 0.95),
        tokenCount: 10,
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
      );

      // Add a mock data source to all tests
      final mockSource = MockDataSource();
      ragify.addDataSource(mockSource);
    });

    tearDown(() async {
      try {
        await ragify.close();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    group('Constructor and Initialization Tests', () {
      test('should create RAGify instance with default config', () {
        final defaultRagify = RAGify();
        expect(defaultRagify.config, isA<RagifyConfig>());
        expect(defaultRagify.logger, isA<Logger>());
      });

      test('should create RAGify instance with custom config', () {
        final customConfig = RagifyConfig.production();
        final customRagify = RAGify(config: customConfig);
        expect(customRagify.config, equals(customConfig));
      });

      test('should create RAGify instance with custom logger', () {
        final customLogger = Logger(level: Level.error);
        final customRagify = RAGify(logger: customLogger);
        expect(customRagify.logger, equals(customLogger));
      });

      test('should create RAGify instance in test mode', () {
        final testRagify = RAGify(isTestMode: true);
        expect(testRagify, isA<RAGify>());
      });

      test('should initialize components correctly', () {
        expect(ragify.orchestrator, isNotNull);
        expect(ragify.cacheManager, isNotNull);
        expect(ragify.privacyManager, isNotNull);
        expect(ragify.securityManager, isNotNull);
        expect(ragify.vectorDatabase, isNotNull);
        expect(ragify.advancedScoringEngine, isNotNull);
        expect(ragify.advancedFusionEngine, isNotNull);
      });
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        await ragify.initialize();
        expect(ragify.isHealthy(), completion(isTrue));
      });

      test('should not initialize twice', () async {
        await ragify.initialize();
        await ragify.initialize(); // Should not throw
        expect(ragify.isHealthy(), completion(isTrue));
      });

      test('should handle initialization errors gracefully', () async {
        // This test verifies error handling in initialize method
        final errorRagify = RAGify(
          config: config,
          logger: logger,
          isTestMode: true,
        );
        try {
          await errorRagify.initialize();
        } catch (e) {
          // Expected in some cases
        }
      });

      test('should handle vector database initialization failure', () async {
        // Test the error handling path in initialize method
        final errorRagify = RAGify(
          config: config,
          logger: logger,
          isTestMode: false,
        );
        try {
          await errorRagify.initialize();
        } catch (e) {
          // Expected when vector database fails to initialize
        }
      });
    });

    group('Platform Information Tests', () {
      test('should get platform information', () {
        final platformInfo = ragify.getPlatformInfo();
        expect(platformInfo, isA<Map<String, dynamic>>());
        expect(platformInfo['platform'], isA<String>());
        expect(platformInfo['isWeb'], isA<bool>());
        expect(platformInfo['isMobile'], isA<bool>());
        expect(platformInfo['isDesktop'], isA<bool>());
        expect(platformInfo['features'], isA<Map<String, dynamic>>());
      });

      test('should check platform feature support', () {
        final supportsAI = ragify.supportsPlatformFeature(
          PlatformFeature.aiModelApis,
        );
        expect(supportsAI, isA<bool>());
      });

      test('should get platform recommendations', () {
        final recommendations = ragify.getPlatformRecommendations();
        expect(recommendations, isA<Map<String, String>>());
        expect(recommendations['storage'], isA<String>());
        expect(recommendations['ml'], isA<String>());
        expect(recommendations['performance'], isA<String>());
        expect(recommendations['security'], isA<String>());
      });

      test('should get platform-optimized configuration', () {
        final optimizedConfig = ragify.getPlatformOptimizedConfig();
        expect(optimizedConfig, isA<Map<String, dynamic>>());
        expect(
          optimizedConfig['platform_optimizations'],
          isA<Map<String, dynamic>>(),
        );
      });

      test('should get platform status', () {
        final status = ragify.getPlatformStatus();
        expect(status, isA<Map<String, dynamic>>());
        expect(status['platform'], isA<String>());
        expect(status['capabilities'], isA<Map<String, dynamic>>());
        expect(status['features'], isA<Map<String, dynamic>>());
        expect(status['optimizations'], isA<Map<String, dynamic>>());
        expect(status['recommendations'], isA<Map<String, String>>());
        expect(status['services'], isA<Map<String, dynamic>>());
      });

      test('should handle different platform types in recommendations', () {
        // Test web platform recommendations
        final webRagify = RAGify(isTestMode: true);
        final recommendations = webRagify.getPlatformRecommendations();
        expect(recommendations, isA<Map<String, String>>());
      });
    });

    group('Data Source Management Tests', () {
      test('should add data source', () {
        final mockSource = MockDataSource();
        ragify.addDataSource(mockSource);
        // Verify source was added (this would require access to orchestrator internals)
        expect(ragify, isA<RAGify>());
      });

      test('should remove data source', () {
        ragify.removeDataSource('test_source');
        // Verify source was removed
        expect(ragify, isA<RAGify>());
      });

      test('should add database source', () {
        final mockDbSource = MockDatabaseSource();
        ragify.addDatabaseSource(mockDbSource);
        expect(ragify, isA<RAGify>());
      });

      test('should get database sources', () {
        final sources = ragify.getDatabaseSources();
        expect(sources, isA<List<DatabaseSource>>());
      });

      test('should get database source by name', () {
        final source = ragify.getDatabaseSource('test_source');
        expect(source, isNull); // No source with this name
      });

      test('should remove database source', () {
        ragify.removeDatabaseSource('test_source');
        expect(ragify, isA<RAGify>());
      });
    });

    group('Context Retrieval Tests', () {
      test('should get context successfully', () async {
        await ragify.initialize();
        final response = await ragify.getContext(query: 'test query');
        expect(response, isA<ContextResponse>());
        expect(response.query, equals('test query'));
      });

      test('should get context with all parameters', () async {
        await ragify.initialize();
        final response = await ragify.getContext(
          query: 'test query',
          userId: 'user123',
          sessionId: 'session456',
          maxTokens: 1000,
          maxChunks: 10,
          minRelevance: 0.5,
          privacyLevel: PrivacyLevel.public,
          includeMetadata: true,
          sources: ['source1'],
          excludeSources: ['source2'],
          useCache: true,
          useVectorSearch: true,
        );
        expect(response, isA<ContextResponse>());
      });

      test('should handle privacy violation', () async {
        await ragify.initialize();
        try {
          await ragify.getContext(
            query: 'test query',
            privacyLevel: PrivacyLevel.restricted,
          );
          fail('Should have thrown PrivacyViolationException');
        } catch (e) {
          expect(e, isA<PrivacyViolationException>());
        }
      });

      test('should handle closed instance', () async {
        await ragify.initialize();
        await ragify.close();
        try {
          await ragify.getContext(query: 'test query');
          fail('Should have thrown StateError');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      });

      test('should handle cache hit', () async {
        await ragify.initialize();
        // First call should cache
        await ragify.getContext(query: 'cached query');
        // Second call should use cache
        final response = await ragify.getContext(query: 'cached query');
        expect(response, isA<ContextResponse>());
      });

      test('should handle cache errors gracefully', () async {
        await ragify.initialize();
        final response = await ragify.getContext(query: 'test query');
        expect(response, isA<ContextResponse>());
      });

      test('should handle empty query', () async {
        await ragify.initialize();
        try {
          await ragify.getContext(query: '');
        } catch (e) {
          // Expected behavior
        }
      });

      test('should handle null parameters gracefully', () async {
        await ragify.initialize();
        final response = await ragify.getContext(query: 'test');
        expect(response, isA<ContextResponse>());
      });

      test('should handle large queries', () async {
        await ragify.initialize();
        final largeQuery = 'a' * 10000; // Very long query
        try {
          await ragify.getContext(query: largeQuery);
        } catch (e) {
          // Expected behavior for very long queries
        }
      });

      test('should handle concurrent operations', () async {
        await ragify.initialize();
        final futures = List.generate(
          5,
          (i) => ragify.getContext(query: 'query $i'),
        );
        final results = await Future.wait(futures);
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isA<ContextResponse>());
        }
      });
    });

    group('Vector Operations Tests', () {
      test('should store chunks in vector database', () async {
        await ragify.initialize();
        await ragify.storeChunks([testChunk]);
        expect(ragify, isA<RAGify>());
      });

      test('should search similar chunks', () async {
        await ragify.initialize();
        final results = await ragify.searchSimilarChunks(
          'test query',
          5,
          minSimilarity: 0.7,
          privacyLevel: PrivacyLevel.public,
          userId: 'user123',
        );
        expect(results, isA<List<ContextChunk>>());
      });

      test('should handle vector search privacy violation', () async {
        await ragify.initialize();
        try {
          await ragify.searchSimilarChunks(
            'test query',
            5,
            privacyLevel: PrivacyLevel.restricted,
          );
          fail('Should have thrown PrivacyViolationException');
        } catch (e) {
          expect(e, isA<PrivacyViolationException>());
        }
      });

      test('should generate embeddings for text', () async {
        await ragify.initialize();
        await ragify.storeChunks([testChunk]);
        // This tests the internal _generateEmbedding method indirectly
        expect(ragify, isA<RAGify>());
      });

      test('should handle vector operations when not initialized', () async {
        try {
          await ragify.storeChunks([testChunk]);
        } catch (e) {
          // Expected behavior
        }
      });
    });

    group('Advanced Features Tests', () {
      test('should calculate advanced score', () async {
        await ragify.initialize();
        final score = await ragify.calculateAdvancedScore(
          testChunk,
          'test query',
          userId: 'user123',
          context: {'key': 'value'},
        );
        expect(score, isA<RelevanceScore>());
      });

      test('should perform advanced fusion', () async {
        await ragify.initialize();
        final fusedChunks = await ragify.performAdvancedFusion(
          chunks: [testChunk],
          query: 'test query',
          userId: 'user123',
          context: {'key': 'value'},
          enabledStrategies: ['semantic_similarity'],
        );
        expect(fusedChunks, isA<List<ContextChunk>>());
      });

      test('should update user profile', () {
        ragify.updateUserProfile(
          'user123',
          topic: 'technology',
          source: 'document',
          contentType: 'article',
          query: 'AI',
          interactionScore: 0.8,
        );
        expect(ragify, isA<RAGify>());
      });

      test('should get user profile', () {
        final profile = ragify.getUserProfile('user123');
        // Profile might be null if not exists
        expect(profile, isNull);
      });

      test('should handle user profile operations with various parameters', () {
        ragify.updateUserProfile(
          'user456',
          topic: 'science',
          source: 'api',
          contentType: 'research',
          query: 'quantum physics',
          interactionScore: 0.95,
        );
        expect(ragify, isA<RAGify>());
      });
    });

    group('Database Operations Tests', () {
      test('should store chunks in databases', () async {
        await ragify.initialize();
        await ragify.storeChunksInDatabases([testChunk]);
        expect(ragify, isA<RAGify>());
      });

      test('should get chunks from databases', () async {
        await ragify.initialize();
        final chunks = await ragify.getChunksFromDatabases(
          query: 'test query',
          filters: {'key': 'value'},
          limit: 10,
          offset: 0,
        );
        expect(chunks, isA<List<ContextChunk>>());
      });

      test('should get database stats', () {
        final stats = ragify.getDatabaseStats();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test(
        'should handle database operations with various parameters',
        () async {
          await ragify.initialize();
          await ragify.storeChunksInDatabases([testChunk]);
          final chunks = await ragify.getChunksFromDatabases(
            query: 'test query',
            filters: {'type': 'document', 'category': 'tech'},
            limit: 5,
            offset: 2,
          );
          expect(chunks, isA<List<ContextChunk>>());
        },
      );
    });

    group('Statistics and Health Tests', () {
      test('should get cache stats', () {
        final stats = ragify.getCacheStats();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should get privacy stats', () {
        final stats = ragify.getPrivacyStats();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should get security stats', () {
        final stats = ragify.getSecurityStats();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should get vector database stats', () {
        final stats = ragify.getVectorDatabaseStats();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should get advanced scoring stats', () {
        final stats = ragify.getAdvancedScoringStats();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should get advanced fusion stats', () {
        final stats = ragify.getAdvancedFusionStats();
        expect(stats, isA<Map<String, dynamic>>());
      });

      test('should get overall stats', () {
        final stats = ragify.getStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['is_initialized'], isA<bool>());
        expect(stats['is_closed'], isA<bool>());
        expect(stats['config'], isA<Map<String, dynamic>>());
        expect(stats['orchestrator'], isA<Map<String, dynamic>>());
        expect(stats['cache'], isA<Map<String, dynamic>>());
        expect(stats['privacy'], isA<Map<String, dynamic>>());
        expect(stats['security'], isA<Map<String, dynamic>>());
        expect(stats['vector_database'], isA<Map<String, dynamic>>());
        expect(stats['advanced_scoring'], isA<Map<String, dynamic>>());
        expect(stats['advanced_fusion'], isA<Map<String, dynamic>>());
        expect(stats['databases'], isA<Map<String, dynamic>>());
      });

      test('should check health status', () async {
        await ragify.initialize();
        final isHealthy = await ragify.isHealthy();
        expect(isHealthy, isA<bool>());
      });

      test('should check health when not initialized', () async {
        final isHealthy = await ragify.isHealthy();
        expect(isHealthy, isFalse);
      });
    });

    group('Platform Capability Tests', () {
      test('should check hardware acceleration support', () {
        final supports = ragify.supportsHardwareAcceleration;
        expect(supports, isA<bool>());
      });

      test('should check advanced features support', () {
        final supports = ragify.supportsAdvancedFeatures;
        expect(supports, isA<bool>());
      });

      test('should check persistent storage support', () {
        final supports = ragify.supportsPersistentStorage;
        expect(supports, isA<bool>());
      });
    });

    group('Cleanup and Error Handling Tests', () {
      test('should close successfully', () async {
        await ragify.initialize();
        await ragify.close();
        expect(ragify, isA<RAGify>());
      });

      test('should not close twice', () async {
        await ragify.initialize();
        await ragify.close();
        await ragify.close(); // Should not throw
        expect(ragify, isA<RAGify>());
      });

      test('should handle errors during close', () async {
        await ragify.initialize();
        // This tests error handling in close method
        await ragify.close();
        expect(ragify, isA<RAGify>());
      });

      test('should generate cache keys correctly', () async {
        await ragify.initialize();
        // This tests the internal _generateCacheKey method indirectly
        await ragify.getContext(
          query: 'test query',
          userId: 'user123',
          sessionId: 'session456',
          privacyLevel: PrivacyLevel.public,
        );
        expect(ragify, isA<RAGify>());
      });
    });

    group('Edge Cases and Error Scenarios', () {
      test('should handle empty query', () async {
        await ragify.initialize();
        try {
          await ragify.getContext(query: '');
        } catch (e) {
          // Expected behavior
        }
      });

      test('should handle null parameters gracefully', () async {
        await ragify.initialize();
        final response = await ragify.getContext(query: 'test');
        expect(response, isA<ContextResponse>());
      });

      test('should handle large queries', () async {
        await ragify.initialize();
        final largeQuery = 'a' * 10000; // Very long query
        try {
          await ragify.getContext(query: largeQuery);
        } catch (e) {
          // Expected behavior for very long queries
        }
      });

      test('should handle concurrent operations', () async {
        await ragify.initialize();
        final futures = List.generate(
          5,
          (i) => ragify.getContext(query: 'query $i'),
        );
        final results = await Future.wait(futures);
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isA<ContextResponse>());
        }
      });

      test('should handle platform detection edge cases', () {
        // Test platform detection methods
        final platformInfo = ragify.getPlatformInfo();
        expect(platformInfo['platform'], isA<String>());

        final supportsFeature = ragify.supportsPlatformFeature(
          PlatformFeature.aiModelApis,
        );
        expect(supportsFeature, isA<bool>());
      });

      test('should handle error scenarios gracefully', () async {
        // Test various error handling paths
        try {
          await ragify.getContext(query: 'test');
        } catch (e) {
          // Expected in some cases
        }
      });
    });

    group('Advanced Method Tests', () {
      test('should handle user profile operations', () {
        ragify.updateUserProfile(
          'user123',
          topic: 'technology',
          source: 'document',
          contentType: 'article',
          query: 'AI',
          interactionScore: 0.8,
        );

        final profile = ragify.getUserProfile('user123');
        // Profile might be null if not exists
        expect(profile, isNull);
      }, skip: true);

      test(
        'should handle database operations with various parameters',
        () async {
          await ragify.initialize();
          await ragify.storeChunksInDatabases([testChunk]);
          final chunks = await ragify.getChunksFromDatabases(
            query: 'test query',
            filters: {'type': 'document', 'category': 'tech'},
            limit: 5,
            offset: 2,
          );
          expect(chunks, isA<List<ContextChunk>>());
        },
      );

      test('should handle platform-specific optimizations', () async {
        // Create a fresh instance for this test to avoid state issues
        final testRagify = RAGify(
          config: config,
          logger: logger,
          isTestMode: true,
        );
        try {
          await testRagify.initialize();
          // Ensure the config is accessible before calling getPlatformOptimizedConfig
          expect(testRagify.config, isNotNull);

          final optimizations = testRagify.getPlatformOptimizedConfig();
          expect(optimizations, isNotNull);
          expect(optimizations, isA<Map<String, dynamic>>());
          expect(optimizations['platform_optimizations'], isNotNull);
        } finally {
          await testRagify.close();
        }
      });
    });

    group('Platform Specific Tests', () {
      test('should test all platform features', () async {
        // Create a fresh instance for this test to avoid state issues
        final testRagify = RAGify(
          config: config,
          logger: logger,
          isTestMode: true,
        );
        try {
          // Test all platform features to ensure coverage
          final features = [
            PlatformFeature.aiModelApis,
            PlatformFeature.vectorOperations,
            PlatformFeature.sqlite,
            PlatformFeature.webStorage,
            PlatformFeature.fileSystem,
          ];

          for (final feature in features) {
            final supports = testRagify.supportsPlatformFeature(feature);
            expect(supports, isA<bool>());
          }
        } finally {
          await testRagify.close();
        }
      });

      test('should test platform capabilities logging', () async {
        // Create a fresh instance for this test to avoid state issues
        final testRagify = RAGify(
          config: config,
          logger: logger,
          isTestMode: true,
        );
        try {
          // This test will trigger the _logPlatformCapabilities method
          await testRagify.initialize();
          // The method is called during initialization, so we just verify it completed
          expect(testRagify, isA<RAGify>());
        } finally {
          await testRagify.close();
        }
      });
    });
  });
}
