import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/scoring/advanced_scoring_engine.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';
import 'package:ragify_flutter/src/storage/vector_database.dart';

void main() {
  group('AdvancedScoringEngine Tests', () {
    late AdvancedScoringEngine scoringEngine;
    late CacheManager cacheManager;
    late VectorDatabase vectorDatabase;

    setUp(() {
      cacheManager = CacheManager();
      vectorDatabase = VectorDatabase(vectorDbUrl: 'memory://');
      scoringEngine = AdvancedScoringEngine(
        cacheManager: cacheManager,
        vectorDatabase: vectorDatabase,
      );
    });

    tearDown(() async {
      await vectorDatabase.close();
    });

    test('should create AdvancedScoringEngine instance', () {
      expect(scoringEngine, isNotNull);
    });

    test('should create ScoringAlgorithmConfig', () {
      const config = ScoringAlgorithmConfig(
        name: 'test_algorithm',
        weight: 0.5,
        parameters: {'param1': 'value1'},
        enabled: true,
      );

      expect(config.name, equals('test_algorithm'));
      expect(config.weight, equals(0.5));
      expect(config.parameters['param1'], equals('value1'));
      expect(config.enabled, isTrue);
    });

    test('should convert ScoringAlgorithmConfig to JSON', () {
      const config = ScoringAlgorithmConfig(
        name: 'test_algorithm',
        weight: 0.5,
        parameters: {'param1': 'value1'},
        enabled: true,
      );

      final json = config.toJson();
      expect(json['name'], equals('test_algorithm'));
      expect(json['weight'], equals(0.5));
      expect(json['parameters']['param1'], equals('value1'));
      expect(json['enabled'], isTrue);
    });

    test('should create ScoringAlgorithmConfig from JSON', () {
      final json = {
        'name': 'test_algorithm',
        'weight': 0.5,
        'parameters': {'param1': 'value1'},
        'enabled': true,
      };

      final config = ScoringAlgorithmConfig.fromJson(json);
      expect(config.name, equals('test_algorithm'));
      expect(config.weight, equals(0.5));
      expect(config.parameters['param1'], equals('value1'));
      expect(config.enabled, isTrue);
    });

    test('should create UserProfile', () {
      final profile = UserProfile(
        userId: 'test_user',
        topicPreferences: {'topic1': 0.8},
        sourcePreferences: {'source1': 0.9},
        contentTypePreferences: {'text': 0.7},
        recentQueries: ['query1', 'query2'],
        queryFrequency: {'query1': 5, 'query2': 3},
        lastActivity: DateTime(2024, 1, 1),
        engagementScore: 0.85,
      );

      expect(profile.userId, equals('test_user'));
      expect(profile.topicPreferences['topic1'], equals(0.8));
      expect(profile.sourcePreferences['source1'], equals(0.9));
      expect(profile.contentTypePreferences['text'], equals(0.7));
      expect(profile.recentQueries, contains('query1'));
      expect(profile.queryFrequency['query1'], equals(5));
      expect(profile.engagementScore, equals(0.85));
    });

    test('should convert UserProfile to JSON', () {
      final profile = UserProfile(
        userId: 'test_user',
        topicPreferences: {'topic1': 0.8},
        sourcePreferences: {'source1': 0.9},
        contentTypePreferences: {'text': 0.7},
        recentQueries: ['query1', 'query2'],
        queryFrequency: {'query1': 5, 'query2': 3},
        lastActivity: DateTime(2024, 1, 1),
        engagementScore: 0.85,
      );

      final json = profile.toJson();
      expect(json['user_id'], equals('test_user'));
      expect(json['topic_preferences']['topic1'], equals(0.8));
      expect(json['source_preferences']['source1'], equals(0.9));
      expect(json['content_type_preferences']['text'], equals(0.7));
      expect(json['recent_queries'], contains('query1'));
      expect(json['query_frequency']['query1'], equals(5));
      expect(json['engagement_score'], equals(0.85));
    });

    test('should create UserProfile from JSON', () {
      final json = {
        'user_id': 'test_user',
        'topic_preferences': {'topic1': 0.8},
        'source_preferences': {'source1': 0.9},
        'content_type_preferences': {'text': 0.7},
        'recent_queries': ['query1', 'query2'],
        'query_frequency': {'query1': 5, 'query2': 3},
        'last_activity': '2024-01-01T00:00:00.000Z',
        'engagement_score': 0.85,
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.userId, equals('test_user'));
      expect(profile.topicPreferences['topic1'], equals(0.8));
      expect(profile.sourcePreferences['source1'], equals(0.9));
      expect(profile.contentTypePreferences['text'], equals(0.7));
      expect(profile.recentQueries, contains('query1'));
      expect(profile.queryFrequency['query1'], equals(5));
      expect(profile.engagementScore, equals(0.85));
    });

    test('should update user preferences', () {
      final profile = UserProfile(userId: 'test_user');

      final updatedProfile = profile.updatePreferences(
        topic: 'new_topic',
        source: 'new_source',
        contentType: 'new_type',
        query: 'new_query',
        interactionScore: 1.0,
      );

      expect(updatedProfile.topicPreferences['new_topic'], equals(1.0));
      expect(updatedProfile.sourcePreferences['new_source'], equals(1.0));
      expect(updatedProfile.contentTypePreferences['new_type'], equals(1.0));
      expect(updatedProfile.recentQueries.first, equals('new_query'));
      expect(updatedProfile.queryFrequency['new_query'], equals(1));
      expect(updatedProfile.engagementScore, equals(0.1));
    });

    test('should create TemporalDecayFunction', () {
      final decayFunction = TemporalDecayFunction(
        halfLife: 30.0,
        decayRate: 0.5,
      );

      expect(decayFunction.halfLife, equals(30.0));
      expect(decayFunction.decayRate, equals(0.5));
    });

    test('should calculate temporal decay score', () {
      final decayFunction = TemporalDecayFunction(
        halfLife: 30.0,
        decayRate: 0.5,
        referenceDate: DateTime(2024, 2, 1),
      );

      final contentDate = DateTime(2024, 1, 1);
      final score = decayFunction.calculateScore(contentDate);

      expect(score, isA<double>());
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });

    test('should get temporal decay parameters', () {
      final decayFunction = TemporalDecayFunction(
        halfLife: 30.0,
        decayRate: 0.5,
        referenceDate: DateTime(2024, 1, 1),
      );

      final params = decayFunction.getParameters();
      expect(params['half_life'], equals(30.0));
      expect(params['decay_rate'], equals(0.5));
      expect(params['reference_date'], isA<String>());
    });

    test('should create MultiAlgorithmScorer', () {
      final algorithms = [
        const ScoringAlgorithmConfig(name: 'algo1', weight: 0.5),
        const ScoringAlgorithmConfig(name: 'algo2', weight: 0.5),
      ];

      final scoringFunctions = <String, ScoringFunction>{
        'algo1': (chunk, query, {userProfile, context}) => 0.8,
        'algo2': (chunk, query, {userProfile, context}) => 0.6,
      };

      final scorer = MultiAlgorithmScorer(
        algorithms: algorithms,
        scoringFunctions: scoringFunctions,
      );

      expect(scorer, isNotNull);
    });

    test('should get algorithm statistics', () {
      final algorithms = [
        const ScoringAlgorithmConfig(name: 'algo1', weight: 0.5, enabled: true),
        const ScoringAlgorithmConfig(
          name: 'algo2',
          weight: 0.5,
          enabled: false,
        ),
      ];

      final scoringFunctions = <String, ScoringFunction>{
        'algo1': (chunk, query, {userProfile, context}) => 0.8,
        'algo2': (chunk, query, {userProfile, context}) => 0.6,
      };

      final scorer = MultiAlgorithmScorer(
        algorithms: algorithms,
        scoringFunctions: scoringFunctions,
      );

      final stats = scorer.getAlgorithmStats();
      expect(stats['total_algorithms'], equals(2));
      expect(stats['enabled_algorithms'], equals(1));
      expect(stats['algorithms'], hasLength(2));
    });

    test('should get engine statistics', () {
      final stats = scoringEngine.getStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['total_algorithms'], isA<int>());
      expect(stats['enabled_algorithms'], isA<int>());
      expect(stats['total_user_profiles'], isA<int>());
    });

    test('should update user profile', () {
      scoringEngine.updateUserProfile(
        'test_user',
        topic: 'test_topic',
        source: 'test_source',
        contentType: 'test_type',
        query: 'test_query',
        interactionScore: 1.0,
      );

      final profile = scoringEngine.getUserProfile('test_user');
      expect(profile, isNotNull);
      expect(profile!.userId, equals('test_user'));
      expect(profile.topicPreferences['test_topic'], equals(1.0));
      expect(profile.sourcePreferences['test_source'], equals(1.0));
      expect(profile.contentTypePreferences['test_type'], equals(1.0));
      expect(profile.recentQueries.first, equals('test_query'));
      expect(profile.queryFrequency['test_query'], equals(1));
    });

    test('should update algorithm configuration', () {
      final newConfig = const ScoringAlgorithmConfig(
        name: 'content_relevance',
        weight: 0.4,
        parameters: {'min_length': 20},
        enabled: true,
      );

      scoringEngine.updateAlgorithmConfig('content_relevance', newConfig);

      final stats = scoringEngine.getStats();
      expect(
        stats['algorithm_configs']['content_relevance']['weight'],
        equals(0.4),
      );
      expect(
        stats['algorithm_configs']['content_relevance']['parameters']['min_length'],
        equals(20),
      );
    });
  });
}
