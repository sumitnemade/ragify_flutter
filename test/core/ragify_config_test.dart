import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('RagifyConfig Tests', () {
    test('defaultConfig factory', () {
      final config = RagifyConfig.defaultConfig();
      expect(config.vectorDbUrl, isNull);
      expect(config.cacheUrl, isNull);
      expect(config.privacyLevel, equals(PrivacyLevel.public));
      expect(config.maxContextSize, equals(10000));
      expect(config.defaultRelevanceThreshold, equals(0.5));
      expect(config.maxConcurrentSources, equals(10));
      expect(config.sourceTimeout, equals(30.0));
      expect(config.enableCaching, isTrue);
      expect(config.enableAnalytics, isTrue);
      expect(config.conflictDetectionThreshold, equals(0.7));
    });

    test('minimal factory', () {
      final config = RagifyConfig.minimal();
      expect(config.vectorDbUrl, isNull);
      expect(config.cacheUrl, isNull);
      expect(config.privacyLevel, equals(PrivacyLevel.private));
      expect(config.maxContextSize, equals(5000));
      expect(config.defaultRelevanceThreshold, equals(0.5));
      expect(config.maxConcurrentSources, equals(10));
      expect(config.sourceTimeout, equals(30.0));
      expect(config.enableCaching, isFalse);
      expect(config.enableAnalytics, isFalse);
      expect(config.conflictDetectionThreshold, equals(0.7));
    });

    test('production factory', () {
      final config = RagifyConfig.production();
      expect(config.vectorDbUrl, isNull);
      expect(config.cacheUrl, isNull);
      expect(config.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(config.maxContextSize, equals(50000));
      expect(config.defaultRelevanceThreshold, equals(0.7));
      expect(config.maxConcurrentSources, equals(20));
      expect(config.sourceTimeout, equals(60.0));
      expect(config.enableCaching, isTrue);
      expect(config.enableAnalytics, isTrue);
      expect(config.conflictDetectionThreshold, equals(0.8));
    });

    test('copyWith functionality', () {
      final original = RagifyConfig.defaultConfig();
      final updated = original.copyWith(
        vectorDbUrl: 'https://new-vector.com',
        maxContextSize: 20000,
        enableCaching: false,
      );

      expect(updated.vectorDbUrl, equals('https://new-vector.com'));
      expect(updated.maxContextSize, equals(20000));
      expect(updated.enableCaching, isFalse);
      expect(updated.cacheUrl, equals(original.cacheUrl));
      expect(updated.privacyLevel, equals(original.privacyLevel));
    });

    test('JSON serialization', () {
      final config = RagifyConfig.defaultConfig();
      final json = config.toJson();

      expect(json['vector_db_url'], isNull);
      expect(json['cache_url'], isNull);
      expect(json['privacy_level'], equals('public'));
      expect(json['max_context_size'], equals(10000));
      expect(json['default_relevance_threshold'], equals(0.5));
      expect(json['max_concurrent_sources'], equals(10));
      expect(json['source_timeout'], equals(30.0));
      expect(json['enable_caching'], isTrue);
      expect(json['enable_analytics'], isTrue);
      expect(json['conflict_detection_threshold'], equals(0.7));
    });

    test('JSON deserialization', () {
      final json = {
        'vector_db_url': 'https://test.com',
        'cache_url': 'https://cache.test.com',
        'privacy_level': 'enterprise',
        'max_context_size': 15000,
        'default_relevance_threshold': 0.75,
        'max_concurrent_sources': 15,
        'source_timeout': 45.0,
        'enable_caching': false,
        'enable_analytics': true,
        'conflict_detection_threshold': 0.8,
      };

      final config = RagifyConfig.fromJson(json);
      expect(config.vectorDbUrl, equals('https://test.com'));
      expect(config.cacheUrl, equals('https://cache.test.com'));
      expect(config.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(config.maxContextSize, equals(15000));
      expect(config.defaultRelevanceThreshold, equals(0.75));
      expect(config.maxConcurrentSources, equals(15));
      expect(config.sourceTimeout, equals(45.0));
      expect(config.enableCaching, isFalse);
      expect(config.enableAnalytics, isTrue);
      expect(config.conflictDetectionThreshold, equals(0.8));
    });

    test('toString formatting', () {
      final config = RagifyConfig.defaultConfig();
      final str = config.toString();

      expect(str, contains('public'));
      expect(str, contains('10000'));
      expect(str, contains('true'));
    });

    test('equality and hashCode', () {
      final config1 = RagifyConfig.defaultConfig();
      final config2 = RagifyConfig.defaultConfig();
      final config3 = RagifyConfig.minimal();

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
    });
  });
}
