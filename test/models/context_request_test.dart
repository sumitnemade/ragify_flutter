import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('ContextRequest Tests', () {
    test('creation with required parameters', () {
      final request = ContextRequest(
        query: 'test query',
        maxTokens: 1000,
        minRelevance: 0.5,
        privacyLevel: PrivacyLevel.private,
      );

      expect(request.query, equals('test query'));
      expect(request.maxTokens, equals(1000));
      expect(request.minRelevance, equals(0.5));
      expect(request.privacyLevel, equals(PrivacyLevel.private));
      expect(request.userId, isNull);
      expect(request.sessionId, isNull);
      expect(request.maxChunks, isNull);
      expect(request.includeMetadata, isTrue);
      expect(request.sources, isNull);
      expect(request.excludeSources, isNull);
    });

    test('creation with all parameters', () {
      final request = ContextRequest(
        query: 'test query',
        userId: 'user123',
        sessionId: 'session456',
        maxTokens: 2000,
        maxChunks: 20,
        minRelevance: 0.7,
        privacyLevel: PrivacyLevel.enterprise,
        includeMetadata: false,
        sources: ['source1', 'source2'],
        excludeSources: ['excluded1'],
      );

      expect(request.query, equals('test query'));
      expect(request.userId, equals('user123'));
      expect(request.sessionId, equals('session456'));
      expect(request.maxTokens, equals(2000));
      expect(request.maxChunks, equals(20));
      expect(request.minRelevance, equals(0.7));
      expect(request.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(request.includeMetadata, isFalse);
      expect(request.sources, equals(['source1', 'source2']));
      expect(request.excludeSources, equals(['excluded1']));
    });

    test('default values when not provided', () {
      final request = ContextRequest(
        query: 'test query',
        maxTokens: 1000,
        minRelevance: 0.5,
        privacyLevel: PrivacyLevel.private,
      );

      expect(request.includeMetadata, isTrue);
    });

    test('copyWith functionality', () {
      final original = ContextRequest(
        query: 'original query',
        userId: 'user123',
        sessionId: 'session456',
        maxTokens: 1000,
        maxChunks: 10,
        minRelevance: 0.5,
        privacyLevel: PrivacyLevel.private,
        includeMetadata: true,
        sources: ['source1'],
        excludeSources: ['excluded1'],
      );

      final updated = original.copyWith(
        query: 'updated query',
        userId: 'user456',
        maxTokens: 2000,
        maxChunks: 20,
        minRelevance: 0.7,
        privacyLevel: PrivacyLevel.enterprise,
        includeMetadata: false,
        sources: ['source2'],
        excludeSources: ['excluded2'],
      );

      expect(updated.query, equals('updated query'));
      expect(updated.userId, equals('user456'));
      expect(updated.sessionId, equals('session456'));
      expect(updated.maxTokens, equals(2000));
      expect(updated.maxChunks, equals(20));
      expect(updated.minRelevance, equals(0.7));
      expect(updated.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(updated.includeMetadata, isFalse);
      expect(updated.sources, equals(['source2']));
      expect(updated.excludeSources, equals(['excluded2']));
    });

    test('copyWith with partial updates', () {
      final original = ContextRequest(
        query: 'original query',
        maxTokens: 1000,
        minRelevance: 0.5,
        privacyLevel: PrivacyLevel.private,
      );
      final updated = original.copyWith(query: 'updated query');

      expect(updated.query, equals('updated query'));
      expect(updated.maxTokens, equals(1000));
      expect(updated.minRelevance, equals(0.5));
      expect(updated.privacyLevel, equals(PrivacyLevel.private));
    });

    test('JSON serialization', () {
      final request = ContextRequest(
        query: 'test query',
        userId: 'user123',
        sessionId: 'session456',
        maxTokens: 2000,
        maxChunks: 20,
        minRelevance: 0.7,
        privacyLevel: PrivacyLevel.enterprise,
        includeMetadata: false,
        sources: ['source1', 'source2'],
        excludeSources: ['excluded1'],
      );

      final json = request.toJson();
      expect(json['query'], equals('test query'));
      expect(json['user_id'], equals('user123'));
      expect(json['session_id'], equals('session456'));
      expect(json['max_tokens'], equals(2000));
      expect(json['max_chunks'], equals(20));
      expect(json['min_relevance'], equals(0.7));
      expect(json['privacy_level'], equals('enterprise'));
      expect(json['include_metadata'], isFalse);
      expect(json['sources'], equals(['source1', 'source2']));
      expect(json['exclude_sources'], equals(['excluded1']));
    });

    test('JSON deserialization', () {
      final json = {
        'query': 'test query',
        'user_id': 'user123',
        'session_id': 'session456',
        'max_tokens': 2000,
        'max_chunks': 20,
        'min_relevance': 0.7,
        'privacy_level': 'enterprise',
        'include_metadata': false,
        'sources': ['source1', 'source2'],
        'exclude_sources': ['excluded1'],
      };

      final request = ContextRequest.fromJson(json);
      expect(request.query, equals('test query'));
      expect(request.userId, equals('user123'));
      expect(request.sessionId, equals('session456'));
      expect(request.maxTokens, equals(2000));
      expect(request.maxChunks, equals(20));
      expect(request.minRelevance, equals(0.7));
      expect(request.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(request.includeMetadata, isFalse);
      expect(request.sources, equals(['source1', 'source2']));
      expect(request.excludeSources, equals(['excluded1']));
    });

    test('toString formatting', () {
      final request = ContextRequest(
        query: 'test query',
        userId: 'user123',
        maxTokens: 2000,
        minRelevance: 0.5,
        privacyLevel: PrivacyLevel.private,
      );

      final str = request.toString();
      expect(str, contains('test query'));
      expect(str, contains('2000'));
      expect(str, contains('private'));
    });

    test('equality and hashCode', () {
      final request1 = ContextRequest(
        query: 'same query',
        userId: 'user123',
        maxTokens: 1000,
        minRelevance: 0.5,
        privacyLevel: PrivacyLevel.private,
      );

      final request2 = ContextRequest(
        query: 'same query',
        userId: 'user123',
        maxTokens: 1000,
        minRelevance: 0.5,
        privacyLevel: PrivacyLevel.private,
      );

      final request3 = ContextRequest(
        query: 'different query',
        userId: 'user123',
        maxTokens: 1000,
        minRelevance: 0.5,
        privacyLevel: PrivacyLevel.private,
      );

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
      expect(request1.hashCode, equals(request2.hashCode));
      expect(request1.hashCode, isNot(equals(request3.hashCode)));
    });

    test('edge cases', () {
      // Empty query
      expect(
        () => ContextRequest(
          query: '',
          maxTokens: 1000,
          minRelevance: 0.5,
          privacyLevel: PrivacyLevel.private,
        ),
        returnsNormally,
      );

      // Very long query
      final longQuery = 'a' * 10000;
      expect(
        () => ContextRequest(
          query: longQuery,
          maxTokens: 1000,
          minRelevance: 0.5,
          privacyLevel: PrivacyLevel.private,
        ),
        returnsNormally,
      );

      // Boundary values
      expect(
        () => ContextRequest(
          query: 'test',
          maxTokens: 1,
          maxChunks: 1,
          minRelevance: 0.0,
          privacyLevel: PrivacyLevel.private,
        ),
        returnsNormally,
      );

      expect(
        () => ContextRequest(
          query: 'test',
          maxTokens: 1000000,
          maxChunks: 1000,
          minRelevance: 1.0,
          privacyLevel: PrivacyLevel.private,
        ),
        returnsNormally,
      );

      // Null values
      expect(
        () => ContextRequest(
          query: 'test',
          maxTokens: 1000,
          minRelevance: 0.5,
          privacyLevel: PrivacyLevel.private,
          userId: null,
          sessionId: null,
          sources: null,
          excludeSources: null,
        ),
        returnsNormally,
      );
    });
  });
}
