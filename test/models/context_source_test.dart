import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('ContextSource Tests', () {
    test('creation with required parameters', () {
      final source = ContextSource(
        name: 'test_source',
        sourceType: SourceType.document,
      );

      expect(source.name, equals('test_source'));
      expect(source.sourceType, equals(SourceType.document));
      expect(source.id.isNotEmpty, isTrue);
      expect(source.url, isNull);
      expect(source.metadata, equals(const {}));
      expect(source.isActive, isTrue);
      expect(source.privacyLevel, equals(PrivacyLevel.private));
      expect(source.authorityScore, equals(0.5));
      expect(source.freshnessScore, equals(1.0));
    });

    test('creation with all parameters', () {
      final source = ContextSource(
        id: 'custom_id',
        name: 'test_source',
        sourceType: SourceType.api,
        url: 'https://api.example.com',
        metadata: {'key': 'value'},
        lastUpdated: DateTime(2023, 1, 1),
        isActive: false,
        privacyLevel: PrivacyLevel.enterprise,
        authorityScore: 0.8,
        freshnessScore: 0.9,
      );

      expect(source.id, equals('custom_id'));
      expect(source.name, equals('test_source'));
      expect(source.sourceType, equals(SourceType.api));
      expect(source.url, equals('https://api.example.com'));
      expect(source.metadata, equals({'key': 'value'}));
      expect(source.lastUpdated, equals(DateTime(2023, 1, 1)));
      expect(source.isActive, isFalse);
      expect(source.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(source.authorityScore, equals(0.8));
      expect(source.freshnessScore, equals(0.9));
    });

    test('UUID generation when id not provided', () {
      final source1 = ContextSource(
        name: 'source1',
        sourceType: SourceType.document,
      );

      final source2 = ContextSource(
        name: 'source2',
        sourceType: SourceType.document,
      );

      expect(source1.id, isNot(equals(source2.id)));
      expect(source1.id.length, greaterThan(20));
    });

    test('default values when not provided', () {
      final source = ContextSource(
        name: 'test_source',
        sourceType: SourceType.document,
      );

      expect(source.isActive, isTrue);
      expect(source.privacyLevel, equals(PrivacyLevel.private));
      expect(source.authorityScore, equals(0.5));
      expect(source.freshnessScore, equals(1.0));
      expect(source.metadata, equals(const {}));
    });

    test('copyWith functionality', () {
      final original = ContextSource(
        id: 'original_id',
        name: 'original_name',
        sourceType: SourceType.document,
        url: 'https://original.com',
        metadata: {'original': 'value'},
        lastUpdated: DateTime(2023, 1, 1),
        isActive: true,
        privacyLevel: PrivacyLevel.private,
        authorityScore: 0.5,
        freshnessScore: 1.0,
      );

      final updated = original.copyWith(
        name: 'updated_name',
        url: 'https://updated.com',
        metadata: {'updated': 'value'},
        isActive: false,
        privacyLevel: PrivacyLevel.enterprise,
        authorityScore: 0.8,
        freshnessScore: 0.9,
      );

      expect(updated.id, equals('original_id'));
      expect(updated.name, equals('updated_name'));
      expect(updated.sourceType, equals(SourceType.document));
      expect(updated.url, equals('https://updated.com'));
      expect(updated.metadata, equals({'updated': 'value'}));
      expect(updated.lastUpdated, equals(DateTime(2023, 1, 1)));
      expect(updated.isActive, isFalse);
      expect(updated.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(updated.authorityScore, equals(0.8));
      expect(updated.freshnessScore, equals(0.9));
    });

    test('copyWith with partial updates', () {
      final original = ContextSource(
        name: 'original_name',
        sourceType: SourceType.document,
      );

      final updated = original.copyWith(name: 'updated_name');
      expect(updated.name, equals('updated_name'));
      expect(updated.sourceType, equals(SourceType.document));
      expect(updated.isActive, isTrue);
      expect(updated.privacyLevel, equals(PrivacyLevel.private));
    });

    test('JSON serialization', () {
      final source = ContextSource(
        id: 'test_id',
        name: 'test_source',
        sourceType: SourceType.api,
        url: 'https://api.example.com',
        metadata: {'key': 'value'},
        lastUpdated: DateTime(2023, 1, 1, 12, 0, 0),
        isActive: true,
        privacyLevel: PrivacyLevel.enterprise,
        authorityScore: 0.8,
        freshnessScore: 0.9,
      );

      final json = source.toJson();
      expect(json['id'], equals('test_id'));
      expect(json['name'], equals('test_source'));
      expect(json['source_type'], equals('api'));
      expect(json['url'], equals('https://api.example.com'));
      expect(json['metadata'], equals({'key': 'value'}));
      expect(json['last_updated'], isA<String>());
      expect(json['is_active'], isTrue);
      expect(json['privacy_level'], equals('enterprise'));
      expect(json['authority_score'], equals(0.8));
      expect(json['freshness_score'], equals(0.9));
    });

    test('JSON deserialization', () {
      final json = {
        'id': 'test_id',
        'name': 'test_source',
        'source_type': 'api',
        'url': 'https://api.example.com',
        'metadata': {'key': 'value'},
        'last_updated': '2023-01-01T12:00:00.000Z',
        'is_active': true,
        'privacy_level': 'enterprise',
        'authority_score': 0.8,
        'freshness_score': 0.9,
      };

      final source = ContextSource.fromJson(json);
      expect(source.id, equals('test_id'));
      expect(source.name, equals('test_source'));
      expect(source.sourceType, equals(SourceType.api));
      expect(source.url, equals('https://api.example.com'));
      expect(source.metadata, equals({'key': 'value'}));
      expect(source.isActive, isTrue);
      expect(source.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(source.authorityScore, equals(0.8));
      expect(source.freshnessScore, equals(0.9));
    });

    test('toString formatting', () {
      final source = ContextSource(
        id: 'test_id',
        name: 'test_source',
        sourceType: SourceType.document,
        privacyLevel: PrivacyLevel.private,
      );

      final str = source.toString();
      expect(str, contains('test_id'));
      expect(str, contains('test_source'));
      expect(str, contains('document'));
      expect(str, contains('private'));
    });

    test('equality and hashCode', () {
      final source1 = ContextSource(
        id: 'same_id',
        name: 'source1',
        sourceType: SourceType.document,
      );

      final source2 = ContextSource(
        id: 'same_id',
        name: 'source2',
        sourceType: SourceType.api,
      );

      final source3 = ContextSource(
        id: 'different_id',
        name: 'source1',
        sourceType: SourceType.document,
      );

      expect(source1, equals(source2)); // Same ID
      expect(source1, isNot(equals(source3))); // Different ID
      expect(source1.hashCode, equals(source2.hashCode));
      expect(source1.hashCode, isNot(equals(source3.hashCode)));
    });

    test('edge cases', () {
      // Empty name
      expect(
        () => ContextSource(name: '', sourceType: SourceType.document),
        returnsNormally,
      );

      // Very long name
      final longName = 'a' * 1000;
      expect(
        () => ContextSource(name: longName, sourceType: SourceType.document),
        returnsNormally,
      );

      // Null metadata
      expect(
        () => ContextSource(
          name: 'test',
          sourceType: SourceType.document,
          metadata: null,
        ),
        returnsNormally,
      );
    });
  });
}
