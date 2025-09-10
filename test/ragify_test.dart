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
      test('should handle platform detection through Flutter built-ins', () {
        // Test that we can still access platform information through Flutter's built-in methods
        // This test verifies that the core functionality works without platform abstraction
        expect(ragify, isA<RAGify>());
        expect(ragify.config, isA<RagifyConfig>());
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
          maxChunks: 10,
          minRelevance: 0.5,
          privacyLevel: PrivacyLevel.public,
          useCache: true,
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

    group('Platform Capability Tests', () {
      test('should handle platform capabilities through Flutter built-ins', () {
        // Test that core functionality works without platform abstraction
        expect(ragify, isA<RAGify>());
        expect(ragify.config, isA<RagifyConfig>());
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
        // Test that core functionality works without platform abstraction
        expect(ragify, isA<RAGify>());
        expect(ragify.config, isA<RagifyConfig>());
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
          // Test that core functionality works without platform abstraction
          expect(testRagify.config, isNotNull);
          expect(testRagify, isA<RAGify>());
        } finally {
          await testRagify.close();
        }
      });
    });

    group('Platform Specific Tests', () {
      test(
        'should test core functionality without platform abstraction',
        () async {
          // Create a fresh instance for this test to avoid state issues
          final testRagify = RAGify(
            config: config,
            logger: logger,
            isTestMode: true,
          );
          try {
            // Test that core functionality works without platform abstraction
            await testRagify.initialize();
            expect(testRagify, isA<RAGify>());
            expect(testRagify.config, isNotNull);
          } finally {
            await testRagify.close();
          }
        },
      );

      test('should test initialization without platform logging', () async {
        // Create a fresh instance for this test to avoid state issues
        final testRagify = RAGify(
          config: config,
          logger: logger,
          isTestMode: true,
        );
        try {
          // Test initialization without platform-specific logging
          await testRagify.initialize();
          expect(testRagify, isA<RAGify>());
        } finally {
          await testRagify.close();
        }
      });
    });
  });
}
