import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';
import 'test_helper.dart';

void main() {
  setupTestMocks();

  group('RAGify Flutter Tests', () {
    test('PrivacyLevel enum values', () {
      expect(PrivacyLevel.public.value, equals('public'));
      expect(PrivacyLevel.private.value, equals('private'));
      expect(PrivacyLevel.enterprise.value, equals('enterprise'));
      expect(PrivacyLevel.restricted.value, equals('restricted'));
    });

    test('PrivacyLevel fromString', () {
      expect(PrivacyLevel.fromString('public'), equals(PrivacyLevel.public));
      expect(PrivacyLevel.fromString('PRIVATE'), equals(PrivacyLevel.private));
      expect(
        PrivacyLevel.fromString('Enterprise'),
        equals(PrivacyLevel.enterprise),
      );
      expect(
        PrivacyLevel.fromString('RESTRICTED'),
        equals(PrivacyLevel.restricted),
      );
    });

    test('PrivacyLevel fromString invalid value', () {
      expect(() => PrivacyLevel.fromString('invalid'), throwsArgumentError);
    });

    test('RelevanceScore creation and validation', () {
      final score = RelevanceScore(score: 0.8);
      expect(score.score, equals(0.8));
      expect(score.confidenceLevel, equals(0.95));
    });

    test('RelevanceScore validation - score too high', () {
      expect(() => RelevanceScore(score: 1.5), throwsAssertionError);
    });

    test('RelevanceScore validation - score too low', () {
      expect(() => RelevanceScore(score: -0.1), throwsAssertionError);
    });

    test('RelevanceScore isAboveThreshold', () {
      final score = RelevanceScore(score: 0.7);
      expect(score.isAboveThreshold(0.5), isTrue);
      expect(score.isAboveThreshold(0.8), isFalse);
    });

    test('ContextSource creation', () {
      final source = ContextSource(
        id: 'test_id',
        name: 'test_source',
        sourceType: SourceType.document,
      );

      expect(source.id, equals('test_id'));
      expect(source.name, equals('test_source'));
      expect(source.sourceType, equals(SourceType.document));
      expect(source.isActive, isTrue);
      expect(source.privacyLevel, equals(PrivacyLevel.private));
    });

    test('ContextSource copyWith', () {
      final source = ContextSource(
        id: 'test_id',
        name: 'test_source',
        sourceType: SourceType.document,
      );

      final updated = source.copyWith(
        name: 'updated_source',
        privacyLevel: PrivacyLevel.public,
      );

      expect(updated.id, equals('test_id'));
      expect(updated.name, equals('updated_source'));
      expect(updated.privacyLevel, equals(PrivacyLevel.public));
    });

    test('RagifyConfig creation', () {
      final config = RagifyConfig.defaultConfig();
      expect(config.privacyLevel, equals(PrivacyLevel.public));
      expect(config.maxContextSize, equals(10000));
      expect(config.enableCaching, isTrue);
    });

    test('RagifyConfig production', () {
      final config = RagifyConfig.production();
      expect(config.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(config.maxContextSize, equals(50000));
      expect(config.defaultRelevanceThreshold, equals(0.7));
    });

    test('RagifyConfig minimal', () {
      final config = RagifyConfig.minimal();
      expect(config.maxContextSize, equals(5000));
      expect(config.enableCaching, isFalse);
      expect(config.enableAnalytics, isFalse);
    });
  });
}
