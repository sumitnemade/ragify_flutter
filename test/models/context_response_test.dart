import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('ContextResponse Tests', () {
    late ContextChunk testChunk;

    setUp(() {
      testChunk = ContextChunk(
        content: 'Test content',
        source: ContextSource(
          name: 'test_source',
          sourceType: SourceType.document,
        ),
      );
    });

    test('creation with required parameters', () {
      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [testChunk],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response.query, equals('test query'));
      expect(response.chunks, equals([testChunk]));
      expect(response.id, equals('test_id'));
      expect(response.maxTokens, equals(1000));
      expect(response.privacyLevel, equals(PrivacyLevel.private));
      expect(response.userId, isNull);
      expect(response.sessionId, isNull);
      expect(response.metadata, equals(const {}));
      expect(response.processingTimeMs, isNull);
    });

    test('creation with all parameters', () {
      final metadata = {'key': 'value'};
      final chunks = [testChunk];

      final response = ContextResponse(
        id: 'custom_id',
        query: 'test query',
        chunks: chunks,
        userId: 'user123',
        sessionId: 'session456',
        maxTokens: 2000,
        privacyLevel: PrivacyLevel.enterprise,
        metadata: metadata,
        createdAt: DateTime(2023, 1, 1),
        processingTimeMs: 150,
      );

      expect(response.id, equals('custom_id'));
      expect(response.query, equals('test query'));
      expect(response.chunks, equals(chunks));
      expect(response.userId, equals('user123'));
      expect(response.sessionId, equals('session456'));
      expect(response.maxTokens, equals(2000));
      expect(response.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(response.metadata, equals(metadata));
      expect(response.createdAt, equals(DateTime(2023, 1, 1)));
      expect(response.processingTimeMs, equals(150));
    });

    test('default values when not provided', () {
      final response = ContextResponse(
        id: 'test_id',
        query: 'Test query',
        chunks: [testChunk],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response.metadata, equals(const {}));
      expect(response.processingTimeMs, isNull);
    });

    test('copyWith functionality', () {
      final original = ContextResponse(
        id: 'original_id',
        query: 'original query',
        chunks: [testChunk],
        userId: 'user123',
        sessionId: 'session456',
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
        metadata: {'original': 'value'},
        createdAt: DateTime(2023, 1, 1),
        processingTimeMs: 100,
      );

      final updated = original.copyWith(
        query: 'updated query',
        userId: 'user456',
        maxTokens: 2000,
        privacyLevel: PrivacyLevel.enterprise,
        metadata: {'updated': 'value'},
        processingTimeMs: 200,
      );

      expect(updated.id, equals('original_id'));
      expect(updated.query, equals('updated query'));
      expect(updated.chunks, equals([testChunk]));
      expect(updated.userId, equals('user456'));
      expect(updated.sessionId, equals('session456'));
      expect(updated.maxTokens, equals(2000));
      expect(updated.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(updated.metadata, equals({'updated': 'value'}));
      expect(updated.createdAt, equals(DateTime(2023, 1, 1)));
      expect(updated.processingTimeMs, equals(200));
    });

    test('copyWith with partial updates', () {
      final original = ContextResponse(
        id: 'original_id',
        query: 'original query',
        chunks: [testChunk],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      final updated = original.copyWith(query: 'updated query');
      expect(updated.query, equals('updated query'));
      expect(updated.chunks, equals([testChunk]));
      expect(updated.metadata, equals(const {}));
    });

    test('totalTokenCount getter', () {
      final chunk1 = ContextChunk(
        content: 'Content 1',
        source: ContextSource(name: 'source1', sourceType: SourceType.document),
        tokenCount: 10,
      );

      final chunk2 = ContextChunk(
        content: 'Content 2',
        source: ContextSource(name: 'source2', sourceType: SourceType.document),
        tokenCount: 15,
      );

      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [chunk1, chunk2],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response.totalTokenCount, equals(25));
    });

    test('totalTokenCount with null token counts', () {
      final chunk1 = ContextChunk(
        content: 'Content 1',
        source: ContextSource(name: 'source1', sourceType: SourceType.document),
      );

      final chunk2 = ContextChunk(
        content: 'Content 2',
        source: ContextSource(name: 'source2', sourceType: SourceType.document),
        tokenCount: 15,
      );

      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [chunk1, chunk2],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response.totalTokenCount, equals(15));
    });

    test('totalTokenCount with no chunks', () {
      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response.totalTokenCount, equals(0));
    });

    test('chunkCount getter', () {
      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [testChunk, testChunk, testChunk],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response.chunkCount, equals(3));
    });

    test('chunkCount with empty chunks', () {
      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response.chunkCount, equals(0));
    });

    test('totalContentLength getter', () {
      final chunk1 = ContextChunk(
        content: 'Content 1',
        source: ContextSource(name: 'source1', sourceType: SourceType.document),
      );

      final chunk2 = ContextChunk(
        content: 'Content 2',
        source: ContextSource(name: 'source2', sourceType: SourceType.document),
      );

      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [chunk1, chunk2],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(
        response.totalContentLength,
        equals(18),
      ); // "Content 1" (9) + "Content 2" (9)
    });

    test('chunksByRelevance getter', () {
      final chunk1 = ContextChunk(
        content: 'Content 1',
        source: ContextSource(name: 'source1', sourceType: SourceType.document),
        relevanceScore: RelevanceScore(score: 0.8),
      );

      final chunk2 = ContextChunk(
        content: 'Content 2',
        source: ContextSource(name: 'source2', sourceType: SourceType.document),
        relevanceScore: RelevanceScore(score: 0.6),
      );

      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [chunk1, chunk2],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      final sortedChunks = response.chunksByRelevance;
      expect(sortedChunks.first.relevanceScore?.score, equals(0.8));
      expect(sortedChunks.last.relevanceScore?.score, equals(0.6));
    });

    test('getChunksAboveThreshold method', () {
      final chunk1 = ContextChunk(
        content: 'Content 1',
        source: ContextSource(name: 'source1', sourceType: SourceType.document),
        relevanceScore: RelevanceScore(score: 0.8),
      );

      final chunk2 = ContextChunk(
        content: 'Content 2',
        source: ContextSource(name: 'source2', sourceType: SourceType.document),
        relevanceScore: RelevanceScore(score: 0.6),
      );

      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [chunk1, chunk2],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      final highRelevanceChunks = response.getChunksAboveThreshold(0.7);
      expect(highRelevanceChunks.length, equals(1));
      expect(highRelevanceChunks.first.relevanceScore?.score, equals(0.8));
    });

    test('getChunksFromSource method', () {
      final chunk1 = ContextChunk(
        content: 'Content 1',
        source: ContextSource(name: 'source1', sourceType: SourceType.document),
      );

      final chunk2 = ContextChunk(
        content: 'Content 2',
        source: ContextSource(name: 'source2', sourceType: SourceType.document),
      );

      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [chunk1, chunk2],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      final source1Chunks = response.getChunksFromSource('source1');
      expect(source1Chunks.length, equals(1));
      expect(source1Chunks.first.source.name, equals('source1'));
    });

    test('sourceNames getter', () {
      final chunk1 = ContextChunk(
        content: 'Content 1',
        source: ContextSource(name: 'source1', sourceType: SourceType.document),
      );

      final chunk2 = ContextChunk(
        content: 'Content 2',
        source: ContextSource(name: 'source2', sourceType: SourceType.document),
      );

      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [chunk1, chunk2],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response.sourceNames, equals({'source1', 'source2'}));
    });

    test('isEmpty and isNotEmpty getters', () {
      final emptyResponse = ContextResponse(
        id: 'empty_id',
        query: 'test query',
        chunks: [],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      final nonEmptyResponse = ContextResponse(
        id: 'non_empty_id',
        query: 'test query',
        chunks: [testChunk],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(emptyResponse.isEmpty, isTrue);
      expect(emptyResponse.isNotEmpty, isFalse);
      expect(nonEmptyResponse.isEmpty, isFalse);
      expect(nonEmptyResponse.isNotEmpty, isTrue);
    });

    test('JSON serialization', () {
      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [testChunk],
        userId: 'user123',
        sessionId: 'session456',
        maxTokens: 2000,
        privacyLevel: PrivacyLevel.enterprise,
        metadata: {'key': 'value'},
        createdAt: DateTime(2023, 1, 1, 12, 0, 0),
        processingTimeMs: 150,
      );

      final json = response.toJson();
      expect(json['id'], equals('test_id'));
      expect(json['query'], equals('test query'));
      expect(json['chunks'], isA<List>());
      expect(json['user_id'], equals('user123'));
      expect(json['session_id'], equals('session456'));
      expect(json['max_tokens'], equals(2000));
      expect(json['privacy_level'], equals('enterprise'));
      expect(json['metadata'], equals({'key': 'value'}));
      expect(json['created_at'], isA<String>());
      expect(json['processing_time_ms'], equals(150));
    });

    test('JSON deserialization', () {
      final json = {
        'id': 'test_id',
        'query': 'test query',
        'chunks': [
          {
            'id': testChunk.id,
            'content': testChunk.content,
            'source': {
              'id': testChunk.source.id,
              'name': testChunk.source.name,
              'source_type': testChunk.source.sourceType.value,
              'url': testChunk.source.url,
              'metadata': testChunk.source.metadata,
              'last_updated': testChunk.source.lastUpdated.toIso8601String(),
              'is_active': testChunk.source.isActive,
              'privacy_level': testChunk.source.privacyLevel.value,
              'authority_score': testChunk.source.authorityScore,
              'freshness_score': testChunk.source.freshnessScore,
            },
            'metadata': testChunk.metadata,
            'relevance_score': null,
            'created_at': testChunk.createdAt.toIso8601String(),
            'updated_at': testChunk.updatedAt.toIso8601String(),
            'token_count': testChunk.tokenCount,
            'embedding': testChunk.embedding,
            'tags': testChunk.tags,
          },
        ],
        'user_id': 'user123',
        'session_id': 'session456',
        'max_tokens': 2000,
        'privacy_level': 'enterprise',
        'metadata': {'key': 'value'},
        'created_at': '2023-01-01T12:00:00.000Z',
        'processing_time_ms': 150,
      };

      final response = ContextResponse.fromJson(json);
      expect(response.id, equals('test_id'));
      expect(response.query, equals('test query'));
      expect(response.chunks.length, equals(1));
      expect(response.userId, equals('user123'));
      expect(response.sessionId, equals('session456'));
      expect(response.maxTokens, equals(2000));
      expect(response.privacyLevel, equals(PrivacyLevel.enterprise));
      expect(response.metadata, equals({'key': 'value'}));
      expect(response.processingTimeMs, equals(150));
    });

    test('toString formatting', () {
      final response = ContextResponse(
        id: 'test_id',
        query: 'test query',
        chunks: [testChunk],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      final str = response.toString();
      expect(str, contains('test_id'));
      expect(str, contains('test query'));
      expect(str, contains('1'));
      expect(str, contains('private'));
    });

    test('equality and hashCode', () {
      final response1 = ContextResponse(
        id: 'same_id',
        query: 'same query',
        chunks: [testChunk],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      final response2 = ContextResponse(
        id: 'same_id',
        query: 'different query',
        chunks: [],
        maxTokens: 2000,
        privacyLevel: PrivacyLevel.enterprise,
      );

      final response3 = ContextResponse(
        id: 'different_id',
        query: 'same query',
        chunks: [testChunk],
        maxTokens: 1000,
        privacyLevel: PrivacyLevel.private,
      );

      expect(response1, equals(response2)); // Same ID
      expect(response1, isNot(equals(response3))); // Different ID
      expect(response1.hashCode, equals(response2.hashCode));
      expect(response1.hashCode, isNot(equals(response3.hashCode)));
    });

    test('edge cases', () {
      // Empty query
      expect(
        () => ContextResponse(
          id: 'test_id',
          query: '',
          chunks: [],
          maxTokens: 1000,
          privacyLevel: PrivacyLevel.private,
        ),
        returnsNormally,
      );

      // Very long query
      final longQuery = 'a' * 10000;
      expect(
        () => ContextResponse(
          id: 'test_id',
          query: longQuery,
          chunks: [],
          maxTokens: 1000,
          privacyLevel: PrivacyLevel.private,
        ),
        returnsNormally,
      );

      // Empty chunks
      expect(
        () => ContextResponse(
          id: 'test_id',
          query: 'test',
          chunks: [],
          maxTokens: 1000,
          privacyLevel: PrivacyLevel.private,
        ),
        returnsNormally,
      );

      // Null values
      expect(
        () => ContextResponse(
          id: 'test_id',
          query: 'test',
          chunks: [testChunk],
          maxTokens: 1000,
          privacyLevel: PrivacyLevel.private,
          userId: null,
          sessionId: null,
          metadata: null,
        ),
        returnsNormally,
      );
    });
  });
}
