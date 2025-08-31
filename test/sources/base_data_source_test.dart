import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

// Mock implementation for testing
class MockDataSource extends BaseDataSource {
  @override
  String get name => 'mock_source';

  @override
  SourceType get sourceType => SourceType.document;

  @override
  Map<String, dynamic> get config => {'type': 'mock', 'enabled': true};

  @override
  Map<String, dynamic> get metadata => {
    'version': '1.0',
    'description': 'Mock source',
  };

  @override
  bool get isActive => true;

  @override
  ContextSource get source =>
      ContextSource(name: 'mock_source', sourceType: SourceType.document);

  @override
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  }) async {
    return [ContextChunk(content: 'Mock content for: $query', source: source)];
  }

  @override
  Future<void> refresh() async {
    // Mock refresh implementation
  }

  @override
  Future<void> close() async {
    // Mock close implementation
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    return {
      'total_chunks': 100,
      'last_refresh': DateTime.now().toIso8601String(),
      'status': 'healthy',
    };
  }

  @override
  Future<bool> isHealthy() async => true;

  @override
  Future<SourceStatus> getStatus() async => SourceStatus.healthy;

  @override
  Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    // Mock metadata update
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return {'type': 'mock', 'enabled': true, 'timeout': 30};
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    // Mock configuration update
  }
}

void main() {
  group('BaseDataSource Tests', () {
    late MockDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockDataSource();
    });

    group('MockDataSource Implementation', () {
      test('name getter returns correct value', () {
        expect(mockDataSource.name, equals('mock_source'));
      });

      test('sourceType getter returns correct value', () {
        expect(mockDataSource.sourceType, equals(SourceType.document));
      });

      test('config getter returns correct value', () {
        final config = mockDataSource.config;
        expect(config['type'], equals('mock'));
        expect(config['enabled'], isTrue);
      });

      test('metadata getter returns correct value', () {
        final metadata = mockDataSource.metadata;
        expect(metadata['version'], equals('1.0'));
        expect(metadata['description'], equals('Mock source'));
      });

      test('isActive getter returns correct value', () {
        expect(mockDataSource.isActive, isTrue);
      });

      test('source getter returns correct value', () {
        final source = mockDataSource.source;
        expect(source.name, equals('mock_source'));
        expect(source.sourceType, equals(SourceType.document));
      });

      test('getChunks returns mock data', () async {
        final chunks = await mockDataSource.getChunks(query: 'test query');
        expect(chunks.length, equals(1));
        expect(chunks.first.content, contains('test query'));
        expect(chunks.first.source.name, equals('mock_source'));
      });

      test('getChunks with all parameters', () async {
        final chunks = await mockDataSource.getChunks(
          query: 'test query',
          maxChunks: 5,
          minRelevance: 0.7,
          userId: 'user123',
          sessionId: 'session456',
        );
        expect(chunks.length, equals(1));
      });

      test('isHealthy returns true', () async {
        expect(await mockDataSource.isHealthy(), isTrue);
      });

      test('getStats returns mock statistics', () async {
        final stats = await mockDataSource.getStats();
        expect(stats['total_chunks'], equals(100));
        expect(stats['status'], equals('healthy'));
        expect(stats['last_refresh'], isA<String>());
      });

      test('getStatus returns healthy', () async {
        expect(await mockDataSource.getStatus(), equals(SourceStatus.healthy));
      });

      test('refresh method can be called', () async {
        expect(() => mockDataSource.refresh(), returnsNormally);
      });

      test('close method can be called', () async {
        expect(() => mockDataSource.close(), returnsNormally);
      });

      test('updateMetadata method can be called', () async {
        final metadata = {'key': 'value'};
        expect(() => mockDataSource.updateMetadata(metadata), returnsNormally);
      });

      test('getConfiguration returns mock config', () {
        final config = mockDataSource.getConfiguration();
        expect(config['type'], equals('mock'));
        expect(config['enabled'], isTrue);
        expect(config['timeout'], equals(30));
      });

      test('updateConfiguration method can be called', () async {
        final config = {'timeout': 60, 'enabled': false};
        expect(
          () => mockDataSource.updateConfiguration(config),
          returnsNormally,
        );
      });
    });

    group('SourceStatus Enum', () {
      test('enum values are correct', () {
        expect(SourceStatus.healthy.value, equals('healthy'));
        expect(SourceStatus.degraded.value, equals('degraded'));
        expect(SourceStatus.unhealthy.value, equals('unhealthy'));
        expect(SourceStatus.offline.value, equals('offline'));
        expect(SourceStatus.unknown.value, equals('unknown'));
      });

      test('fromString with valid values', () {
        expect(
          SourceStatus.fromString('healthy'),
          equals(SourceStatus.healthy),
        );
        expect(
          SourceStatus.fromString('degraded'),
          equals(SourceStatus.degraded),
        );
        expect(
          SourceStatus.fromString('unhealthy'),
          equals(SourceStatus.unhealthy),
        );
        expect(
          SourceStatus.fromString('offline'),
          equals(SourceStatus.offline),
        );
        expect(
          SourceStatus.fromString('unknown'),
          equals(SourceStatus.unknown),
        );
      });

      test('fromString with invalid value returns unknown', () {
        expect(
          SourceStatus.fromString('invalid'),
          equals(SourceStatus.unknown),
        );
        expect(SourceStatus.fromString(''), equals(SourceStatus.unknown));
        expect(SourceStatus.fromString('null'), equals(SourceStatus.unknown));
      });

      test('fromString is case insensitive', () {
        expect(
          SourceStatus.fromString('HEALTHY'),
          equals(SourceStatus.healthy),
        );
        expect(
          SourceStatus.fromString('Healthy'),
          equals(SourceStatus.healthy),
        );
        expect(
          SourceStatus.fromString('healthy'),
          equals(SourceStatus.healthy),
        );
      });

      test('enum index values', () {
        expect(SourceStatus.healthy.index, equals(0));
        expect(SourceStatus.degraded.index, equals(1));
        expect(SourceStatus.unhealthy.index, equals(2));
        expect(SourceStatus.offline.index, equals(3));
        expect(SourceStatus.unknown.index, equals(4));
      });

      test('all enum values are covered', () {
        final values = SourceStatus.values;
        expect(values.length, equals(5));
        expect(values.contains(SourceStatus.healthy), isTrue);
        expect(values.contains(SourceStatus.degraded), isTrue);
        expect(values.contains(SourceStatus.unhealthy), isTrue);
        expect(values.contains(SourceStatus.offline), isTrue);
        expect(values.contains(SourceStatus.unknown), isTrue);
      });
    });

    group('BaseDataSource Interface', () {
      test('can be instantiated through concrete implementation', () {
        expect(mockDataSource, isA<BaseDataSource>());
        expect(mockDataSource, isA<MockDataSource>());
      });

      test('has all required properties', () {
        expect(mockDataSource.name, isA<String>());
        expect(mockDataSource.sourceType, isA<SourceType>());
        expect(mockDataSource.config, isA<Map<String, dynamic>>());
        expect(mockDataSource.metadata, isA<Map<String, dynamic>>());
        expect(mockDataSource.isActive, isA<bool>());
        expect(mockDataSource.source, isA<ContextSource>());
      });

      test('can call all required methods', () async {
        // Test that all methods can be called without throwing
        expect(() => mockDataSource.getChunks(query: 'test'), returnsNormally);
        expect(() => mockDataSource.refresh(), returnsNormally);
        expect(() => mockDataSource.close(), returnsNormally);
        expect(() => mockDataSource.getStats(), returnsNormally);
        expect(() => mockDataSource.isHealthy(), returnsNormally);
        expect(() => mockDataSource.getStatus(), returnsNormally);
        expect(() => mockDataSource.updateMetadata({}), returnsNormally);
        expect(() => mockDataSource.updateConfiguration({}), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('getChunks with empty query', () async {
        final chunks = await mockDataSource.getChunks(query: '');
        expect(chunks.length, equals(1));
        expect(chunks.first.content, contains(''));
      });

      test('getChunks with very long query', () async {
        final longQuery = 'a' * 10000;
        final chunks = await mockDataSource.getChunks(query: longQuery);
        expect(chunks.length, equals(1));
        expect(chunks.first.content, contains(longQuery));
      });

      test('getStats with complex data', () async {
        final stats = await mockDataSource.getStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.keys, contains('total_chunks'));
        expect(stats.keys, contains('last_refresh'));
        expect(stats.keys, contains('status'));
      });

      test('getConfiguration with complex data', () {
        final config = mockDataSource.getConfiguration();
        expect(config, isA<Map<String, dynamic>>());
        expect(config.keys, contains('type'));
        expect(config.keys, contains('enabled'));
        expect(config.keys, contains('timeout'));
      });
    });
  });
}
