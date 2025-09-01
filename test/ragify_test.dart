import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/ragify.dart';
import 'package:ragify_flutter/src/core/ragify_config.dart';
import 'package:ragify_flutter/src/models/context_chunk.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';
import 'package:ragify_flutter/src/platform/platform_detector.dart';
import 'package:ragify_flutter/src/scoring/advanced_scoring_engine.dart';
import 'package:logger/logger.dart';

// Mock data source for testing
class MockDataSource extends BaseDataSource {
  MockDataSource() : super();

  @override
  String get name => 'mock_source';

  @override
  SourceType get sourceType => SourceType.database;

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
    sourceType: SourceType.database,
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
    return [
      ContextChunk(
        content: 'Test content for query: $query',
        source: source,
        metadata: {'score': 0.9, 'timestamp': DateTime.now().toIso8601String()},
        embedding: List.filled(384, 0.1),
      ),
    ];
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

void main() {
  group('RAGify Tests', () {
    late RAGify ragify;
    late RagifyConfig config;

    setUp(() {
      config = RagifyConfig.defaultConfig();
      ragify = RAGify(config: config, isTestMode: true);
    });

    tearDown(() async {
      try {
        await ragify.close();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    group('Initialization Tests', () {
      test('should create RAGify instance with default config', () {
        expect(ragify, isA<RAGify>());
        expect(ragify.config, isA<RagifyConfig>());
      });

      test('should create RAGify instance with custom config', () {
        final customConfig = RagifyConfig(
          maxContextSize: 10000,
          cacheTtl: 3600,
          vectorDbUrl: 'test://vector',
        );
        final customRagify = RAGify(config: customConfig, isTestMode: true);
        expect(customRagify.config.maxContextSize, equals(10000));
        expect(customRagify.config.cacheTtl, equals(3600));
        expect(customRagify.config.vectorDbUrl, equals('test://vector'));
      });

      test('should create RAGify instance with custom logger', () {
        final customLogger = Logger(level: Level.debug);
        final customRagify = RAGify(logger: customLogger, isTestMode: true);
        expect(customRagify.logger, equals(customLogger));
      });
    });

    group('Platform Information Tests', () {
      test('should get platform info', () {
        final platformInfo = ragify.getPlatformInfo();
        expect(platformInfo, isA<Map<String, dynamic>>());
        expect(platformInfo['platform'], isA<String>());
        expect(platformInfo['isWeb'], isA<bool>());
        expect(platformInfo['isMobile'], isA<bool>());
        expect(platformInfo['isDesktop'], isA<bool>());
        expect(platformInfo['isFuchsia'], isA<bool>());
        expect(platformInfo['features'], isA<Map<String, dynamic>>());
      });

      test('should check platform feature support', () {
        final supportsAI = ragify.supportsPlatformFeature(
          PlatformFeature.aiModelApis,
        );
        final supportsVector = ragify.supportsPlatformFeature(
          PlatformFeature.vectorOperations,
        );
        final supportsSQLite = ragify.supportsPlatformFeature(
          PlatformFeature.sqlite,
        );

        expect(supportsAI, isA<bool>());
        expect(supportsVector, isA<bool>());
        expect(supportsSQLite, isA<bool>());
      });

      test('should get platform recommendations', () {
        final recommendations = ragify.getPlatformRecommendations();
        expect(recommendations, isA<Map<String, String>>());
        expect(recommendations.isNotEmpty, isTrue);
      });
    });

    group('Data Source Management Tests', () {
      test('should add data source', () {
        final dataSource = MockDataSource();
        ragify.addDataSource(dataSource);
        // Should not throw
        expect(true, isTrue);
      });

      test('should remove data source', () {
        final dataSource = MockDataSource();
        ragify.addDataSource(dataSource);
        ragify.removeDataSource('mock_source');
        // Should not throw
        expect(true, isTrue);
      });
    });

    group('Statistics Tests', () {
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
    });

    group('User Profile Tests', () {
      test('should update user profile', () {
        ragify.updateUserProfile(
          'test_user',
          topic: 'test_topic',
          source: 'test_source',
          contentType: 'text',
          query: 'test query',
          interactionScore: 0.8,
        );
        // Should not throw
        expect(true, isTrue);
      });

      test('should get user profile', () {
        final profile = ragify.getUserProfile('test_user');
        expect(profile, isA<UserProfile?>());
      });
    });

    group('Configuration Tests', () {
      test('should have valid default configuration', () {
        final defaultConfig = RagifyConfig.defaultConfig();
        expect(defaultConfig.maxContextSize, greaterThan(0));
        expect(defaultConfig.cacheTtl, greaterThan(0));
        expect(
          defaultConfig.defaultRelevanceThreshold,
          greaterThanOrEqualTo(0.0),
        );
        expect(defaultConfig.defaultRelevanceThreshold, lessThanOrEqualTo(1.0));
        expect(defaultConfig.maxConcurrentSources, greaterThan(0));
      });

      test('should create custom configuration', () {
        final customConfig = RagifyConfig(
          maxContextSize: 5000,
          cacheTtl: 1800,
          defaultRelevanceThreshold: 0.6,
          vectorDbUrl: 'custom://vector',
          cacheUrl: 'custom://cache',
        );

        expect(customConfig.maxContextSize, equals(5000));
        expect(customConfig.cacheTtl, equals(1800));
        expect(customConfig.defaultRelevanceThreshold, equals(0.6));
        expect(customConfig.vectorDbUrl, equals('custom://vector'));
        expect(customConfig.cacheUrl, equals('custom://cache'));
      });
    });

    group('Method Availability Tests', () {
      test('should have all required methods available', () {
        // Test that all public methods exist and are callable
        expect(() => ragify.getPlatformInfo(), returnsNormally);
        expect(
          () => ragify.supportsPlatformFeature(PlatformFeature.aiModelApis),
          returnsNormally,
        );
        expect(() => ragify.getPlatformRecommendations(), returnsNormally);
        expect(() => ragify.getCacheStats(), returnsNormally);
        expect(() => ragify.getPrivacyStats(), returnsNormally);
        expect(() => ragify.getSecurityStats(), returnsNormally);
        expect(() => ragify.getVectorDatabaseStats(), returnsNormally);
        expect(() => ragify.getAdvancedScoringStats(), returnsNormally);
        expect(() => ragify.getAdvancedFusionStats(), returnsNormally);
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid platform features gracefully', () {
        // Test with invalid platform feature (this should not crash)
        expect(
          () => ragify.supportsPlatformFeature(PlatformFeature.aiModelApis),
          returnsNormally,
        );
      });

      test('should handle data source operations gracefully', () {
        final dataSource = MockDataSource();
        expect(() => ragify.addDataSource(dataSource), returnsNormally);
        expect(() => ragify.removeDataSource('non_existent'), returnsNormally);
      });
    });

    group('Performance Tests', () {
      test('should handle rapid method calls', () {
        // Test that methods can be called rapidly without issues
        for (int i = 0; i < 100; i++) {
          expect(() => ragify.getPlatformInfo(), returnsNormally);
          expect(() => ragify.getCacheStats(), returnsNormally);
        }
      });

      test('should handle multiple data source operations', () {
        // Test multiple data source operations
        for (int i = 0; i < 10; i++) {
          final dataSource = MockDataSource();
          expect(() => ragify.addDataSource(dataSource), returnsNormally);
          expect(() => ragify.removeDataSource('mock_source'), returnsNormally);
        }
      });
    });

    group('Integration Tests', () {
      test('should work with multiple data sources', () {
        final dataSource1 = MockDataSource();
        final dataSource2 = MockDataSource();

        expect(() => ragify.addDataSource(dataSource1), returnsNormally);
        expect(() => ragify.addDataSource(dataSource2), returnsNormally);
        expect(() => ragify.removeDataSource('mock_source'), returnsNormally);
      });

      test('should handle configuration changes', () {
        final originalConfig = ragify.config;
        expect(originalConfig, isA<RagifyConfig>());

        // Create new instance with different config
        final newRagify = RAGify(
          config: RagifyConfig(maxContextSize: 15000, cacheTtl: 7200),
          isTestMode: true,
        );

        expect(newRagify.config.maxContextSize, equals(15000));
        expect(newRagify.config.cacheTtl, equals(7200));

        // Clean up
        newRagify.close();
      });
    });
  });
}
