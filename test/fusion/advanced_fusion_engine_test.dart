import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/fusion/advanced_fusion_engine.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';
import 'package:ragify_flutter/src/storage/vector_database.dart';
import 'package:ragify_flutter/src/models/context_chunk.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import '../test_helper.dart';

void main() {
  setupTestMocks();

  group('AdvancedFusionEngine Tests', () {
    // Remove shared setup to avoid test isolation issues
    // Each test will create its own instances

    group('FusionStrategyConfig Tests', () {
      test('should create FusionStrategyConfig', () {
        final config = FusionStrategyConfig(
          name: 'test_strategy',
          weight: 0.5,
          parameters: {'param1': 'value1'},
          enabled: true,
        );

        expect(config.name, equals('test_strategy'));
        expect(config.weight, equals(0.5));
        expect(config.parameters['param1'], equals('value1'));
        expect(config.enabled, isTrue);
      });

      test('should convert FusionStrategyConfig to JSON', () {
        final config = FusionStrategyConfig(
          name: 'test_strategy',
          weight: 0.7,
          parameters: {'param1': 'value1'},
          enabled: false,
        );

        final json = config.toJson();
        expect(json['name'], equals('test_strategy'));
        expect(json['weight'], equals(0.7));
        expect(json['parameters']['param1'], equals('value1'));
        expect(json['enabled'], isFalse);
      });

      test('should create FusionStrategyConfig from JSON', () {
        final json = {
          'name': 'test_strategy',
          'weight': 0.6,
          'parameters': {'param1': 'value1'},
          'enabled': true,
        };

        final config = FusionStrategyConfig.fromJson(json);
        expect(config.name, equals('test_strategy'));
        expect(config.weight, equals(0.6));
        expect(config.parameters['param1'], equals('value1'));
        expect(config.enabled, isTrue);
      });
    });

    group('SemanticGroup Tests', () {
      late List<ContextChunk> testChunks;
      late SemanticGroup group;

      setUp(() {
        testChunks = [
          ContextChunk(
            id: 'chunk1',
            content: 'Test content 1',
            source: ContextSource(
              name: 'test_source',
              url: 'https://test.com',
              authorityScore: 0.8,
              lastUpdated: DateTime.now(),
              sourceType: SourceType.document,
            ),
            tags: ['test', 'content'],
            metadata: {'type': 'test'},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ContextChunk(
            id: 'chunk2',
            content: 'Test content 2',
            source: ContextSource(
              name: 'test_source',
              url: 'https://test.com',
              authorityScore: 0.9,
              lastUpdated: DateTime.now(),
              sourceType: SourceType.document,
            ),
            tags: ['test', 'content'],
            metadata: {'type': 'test'},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        group = SemanticGroup(
          id: 'test_group',
          chunks: testChunks,
          similarityThreshold: 0.7,
          groupFeatures: {'avg_authority': 0.85},
        );
      });

      test('should create SemanticGroup', () {
        expect(group.id, equals('test_group'));
        expect(group.chunks.length, equals(2));
        expect(group.similarityThreshold, equals(0.7));
        expect(group.groupFeatures['avg_authority'], equals(0.85));
      });

      test('should get representative chunk (highest authority)', () {
        final representative = group.representativeChunk;
        expect(representative.id, equals('chunk2')); // Higher authority score
        expect(representative.source.authorityScore, equals(0.9));
      });

      test('should get group size', () {
        expect(group.size, equals(2));
      });

      test('should calculate average authority', () {
        expect(group.averageAuthority, closeTo(0.85, 0.01));
      });

      test('should calculate freshness score', () {
        final freshness = group.freshnessScore;
        expect(freshness, isA<double>());
        expect(freshness, greaterThan(0.0));
        expect(freshness, lessThanOrEqualTo(1.0));
      });

      test('should convert SemanticGroup to JSON', () {
        final json = group.toJson();
        expect(json['id'], equals('test_group'));
        expect(json['chunk_count'], equals(2));
        expect(json['similarity_threshold'], equals(0.7));
        expect(json['group_features']['avg_authority'], closeTo(0.85, 0.01));
        expect(json['representative_chunk_id'], equals('chunk2'));
        expect(json['average_authority'], closeTo(0.85, 0.01));
        expect(json['freshness_score'], isA<double>());
      });
    });

    group('ConflictResolutionResult Tests', () {
      late ContextChunk testChunk;
      late List<ContextChunk> conflictingChunks;
      late ConflictResolutionResult result;

      setUp(() {
        testChunk = ContextChunk(
          id: 'resolved_chunk',
          content: 'Resolved content',
          source: ContextSource(
            name: 'test_source',
            url: 'https://test.com',
            authorityScore: 0.9,
            lastUpdated: DateTime.now(),
            sourceType: SourceType.document,
          ),
          tags: ['resolved'],
          metadata: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        conflictingChunks = [
          ContextChunk(
            id: 'conflict1',
            content: 'Conflict content 1',
            source: ContextSource(
              name: 'test_source',
              url: 'https://test.com',
              authorityScore: 0.7,
              lastUpdated: DateTime.now(),
              sourceType: SourceType.document,
            ),
            tags: ['conflict'],
            metadata: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        result = ConflictResolutionResult(
          resolvedChunk: testChunk,
          conflictingChunks: conflictingChunks,
          resolutionStrategy: 'authority_based',
          confidence: 0.9,
          metadata: {'authority_score': 0.9},
        );
      });

      test('should create ConflictResolutionResult', () {
        expect(result.resolvedChunk.id, equals('resolved_chunk'));
        expect(result.conflictingChunks.length, equals(1));
        expect(result.resolutionStrategy, equals('authority_based'));
        expect(result.confidence, equals(0.9));
        expect(result.metadata['authority_score'], equals(0.9));
      });

      test('should convert ConflictResolutionResult to JSON', () {
        final json = result.toJson();
        expect(json['resolved_chunk_id'], equals('resolved_chunk'));
        expect(json['conflicting_chunk_count'], equals(1));
        expect(json['resolution_strategy'], equals('authority_based'));
        expect(json['confidence'], equals(0.9));
        expect(json['metadata']['authority_score'], equals(0.9));
      });
    });

    group('QualityAssessment Tests', () {
      late QualityAssessment assessment;

      setUp(() {
        assessment = QualityAssessment(
          overallScore: 0.8,
          dimensionScores: {
            'content_quality': 0.9,
            'authority_quality': 0.8,
            'freshness_quality': 0.7,
          },
          issues: ['Content could be longer'],
          recommendations: ['Add more detail'],
        );
      });

      test('should create QualityAssessment', () {
        expect(assessment.overallScore, equals(0.8));
        expect(assessment.dimensionScores['content_quality'], equals(0.9));
        expect(assessment.issues.length, equals(1));
        expect(assessment.recommendations.length, equals(1));
      });

      test('should convert QualityAssessment to JSON', () {
        final json = assessment.toJson();
        expect(json['overall_score'], equals(0.8));
        expect(json['dimension_scores']['content_quality'], equals(0.9));
        expect(json['issues'], contains('Content could be longer'));
        expect(json['recommendations'], contains('Add more detail'));
        expect(json['assessed_at'], isA<String>());
      });
    });

    group('AdvancedFusionEngine Core Tests', () {
      test('should create AdvancedFusionEngine instance', () {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        expect(fusionEngine, isNotNull);

        // Cleanup
        vectorDatabase.close();
      });

      test('should initialize with default strategies', () {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        final strategies = fusionEngine.getStrategies();
        expect(strategies.length, equals(5));
        expect(strategies.containsKey('semantic_similarity'), isTrue);
        expect(strategies.containsKey('source_authority'), isTrue);
        expect(strategies.containsKey('freshness'), isTrue);
        expect(strategies.containsKey('content_quality'), isTrue);
        expect(strategies.containsKey('user_preference'), isTrue);

        // Cleanup
        vectorDatabase.close();
      });

      test('should set similarity threshold', () async {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        fusionEngine.setSimilarityThreshold(0.8);
        final stats = fusionEngine.getStats();
        expect(stats['similarity_threshold'], equals(0.8));

        // Cleanup
        await vectorDatabase.close();
      });

      test('should set max group size', () async {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        fusionEngine.setMaxGroupSize(15);
        final stats = fusionEngine.getStats();
        expect(stats['max_group_size'], equals(15));

        // Cleanup
        await vectorDatabase.close();
      });

      test('should update fusion strategy', () {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        final newConfig = FusionStrategyConfig(
          name: 'custom_strategy',
          weight: 0.5,
          parameters: {'custom_param': 'value'},
        );

        fusionEngine.updateStrategy(newConfig);
        final strategies = fusionEngine.getStrategies();
        expect(strategies.containsKey('custom_strategy'), isTrue);
        expect(strategies['custom_strategy']!.weight, equals(0.5));

        // Cleanup
        vectorDatabase.close();
      });

      test('should enable/disable strategy', () {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        fusionEngine.setStrategyEnabled('semantic_similarity', false);
        final strategy = fusionEngine.getStrategy('semantic_similarity');
        expect(strategy!.enabled, isFalse);

        // Cleanup
        vectorDatabase.close();
      });

      test('should update strategy weight', () {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        fusionEngine.setStrategyWeight('semantic_similarity', 0.4);
        final strategy = fusionEngine.getStrategy('semantic_similarity');
        expect(strategy!.weight, equals(0.4));

        // Cleanup
        vectorDatabase.close();
      });
    });

    group('Advanced Fusion Operations Tests', () {
      late List<ContextChunk> testChunks;

      setUp(() {
        testChunks = [
          ContextChunk(
            id: 'chunk1',
            content: 'Flutter is a UI toolkit for building applications',
            source: ContextSource(
              name: 'flutter_docs',
              url: 'https://flutter.dev',
              authorityScore: 0.9,
              lastUpdated: DateTime.now(),
              sourceType: SourceType.document,
            ),
            tags: ['flutter', 'ui', 'mobile'],
            metadata: {'type': 'documentation'},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ContextChunk(
            id: 'chunk2',
            content: 'Flutter provides widgets for building user interfaces',
            source: ContextSource(
              name: 'flutter_docs',
              url: 'https://flutter.dev',
              authorityScore: 0.8,
              lastUpdated: DateTime.now(),
              sourceType: SourceType.document,
            ),
            tags: ['flutter', 'widgets', 'ui'],
            metadata: {'type': 'documentation'},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ContextChunk(
            id: 'chunk3',
            content: 'Dart is the programming language used by Flutter',
            source: ContextSource(
              name: 'dart_lang',
              url: 'https://dart.dev',
              authorityScore: 0.7,
              lastUpdated: DateTime.now(),
              sourceType: SourceType.document,
            ),
            tags: ['dart', 'programming', 'language'],
            metadata: {'type': 'overview'},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      });

      test('should perform advanced fusion on chunks', () async {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        final fusedChunks = await fusionEngine.performAdvancedFusion(
          chunks: testChunks,
          query: 'How to build Flutter applications?',
        );

        expect(fusedChunks, isNotEmpty);
        expect(fusedChunks.length, lessThanOrEqualTo(testChunks.length));

        // Check that chunks have fusion metadata
        for (final chunk in fusedChunks) {
          expect(chunk.metadata.containsKey('fusion_score'), isTrue);
          expect(chunk.metadata.containsKey('quality_score'), isTrue);
          expect(chunk.metadata.containsKey('group_size'), isTrue);
        }

        // Cleanup
        await vectorDatabase.close();
      });

      test('should handle empty chunk list', () async {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        final fusedChunks = await fusionEngine.performAdvancedFusion(
          chunks: [],
          query: 'test query',
        );

        expect(fusedChunks, isEmpty);

        // Cleanup
        await vectorDatabase.close();
      });

      test('should use enabled strategies only', () async {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        // Disable some strategies
        fusionEngine.setStrategyEnabled('freshness', false);
        fusionEngine.setStrategyEnabled('user_preference', false);

        final fusedChunks = await fusionEngine.performAdvancedFusion(
          chunks: testChunks,
          query: 'Flutter development',
          enabledStrategies: ['semantic_similarity', 'source_authority'],
        );

        expect(fusedChunks, isNotEmpty);

        // Check that only enabled strategies were used
        for (final chunk in fusedChunks) {
          final strategies = chunk.metadata['fusion_strategies'] as List;
          expect(strategies.contains('freshness'), isFalse);
          expect(strategies.contains('user_preference'), isFalse);
        }

        // Cleanup
        await vectorDatabase.close();
      });
    });

    group('Engine Statistics Tests', () {
      test('should get engine statistics', () {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        final stats = fusionEngine.getStats();

        expect(stats['total_strategies'], equals(5));
        expect(stats['enabled_strategies'], equals(5));
        expect(stats['similarity_threshold'], equals(0.7));
        expect(stats['max_group_size'], equals(10));
        expect(stats['conflict_strategies'], isA<List>());
        expect(stats['cache_stats'], isA<Map>());
        expect(stats['vector_db_stats'], isA<Map>());

        // Cleanup
        vectorDatabase.close();
      });

      test('should get specific strategy', () {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        final strategy = fusionEngine.getStrategy('semantic_similarity');
        expect(strategy, isNotNull);
        expect(strategy!.name, equals('semantic_similarity'));
        expect(strategy.weight, equals(0.3));

        // Cleanup
        vectorDatabase.close();
      });

      test('should return null for non-existent strategy', () {
        final cacheManager = CacheManager();
        final vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
        final fusionEngine = AdvancedFusionEngine(
          cacheManager: cacheManager,
          vectorDatabase: vectorDatabase,
        );

        final strategy = fusionEngine.getStrategy('non_existent');
        expect(strategy, isNull);

        // Cleanup
        vectorDatabase.close();
      });
    });
  });
}
