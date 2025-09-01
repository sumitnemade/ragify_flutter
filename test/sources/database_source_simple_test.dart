import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/database_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';

void main() {
  group('DatabaseSource Simple Coverage', () {
    late DatabaseSource source;
    late CacheManager cache;
    late DatabaseConfig config;

    setUp(() {
      cache = CacheManager();
      config = DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'test_db',
        username: 'test_user',
        password: 'test_pass',
        connectionTimeout: Duration(seconds: 30),
        queryTimeout: Duration(seconds: 10),
        maxConnections: 5,
      );

      source = DatabaseSource(
        name: 'simple_db_source',
        sourceType: SourceType.database,
        databaseConfig: config,
        databaseType: 'postgresql',
        cacheManager: cache,
      );
    });

    test('basic properties and getters', () {
      expect(source.name, 'simple_db_source');
      expect(source.sourceType, SourceType.database);
      expect(source.databaseConfig.host, 'localhost');
      expect(source.databaseType, 'postgresql');
      expect(source.isActive, isFalse);
      expect(source.metadata, isA<Map<String, dynamic>>());
      expect(source.config, isA<Map<String, dynamic>>());
      expect(source.source, isA<ContextSource>());
    });

    test('getConfiguration and updateConfiguration', () async {
      expect(source.getConfiguration(), isA<Map<String, dynamic>>());
      await source.updateConfiguration({'a': 1, 'b': 'x'});
      final cfg = source.getConfiguration();
      expect(cfg['a'], 1);
      expect(cfg['b'], 'x');
    });

    test('updateMetadata merges values', () async {
      await source.updateMetadata({'m': 1});
      await source.updateMetadata({'n': 2});
      expect(source.metadata['m'], 1);
      expect(source.metadata['n'], 2);
    });

    test('parallel config getters/setters', () {
      final initial = source.getParallelQueryConfig();
      expect(initial.maxConcurrentQueries, greaterThan(0));

      final updated = ParallelQueryConfig(
        maxConcurrentQueries: 8,
        batchSize: 50,
      );
      source.setParallelQueryConfig(updated);
      final current = source.getParallelQueryConfig();
      expect(current.maxConcurrentQueries, 8);
      expect(current.batchSize, 50);
    });

    group('status and health', () {
      test('isHealthy returns false when not initialized', () async {
        expect(await source.isHealthy(), isFalse);
      });

      test('getStatus returns offline when not initialized', () async {
        expect(await source.getStatus(), SourceStatus.offline);
      });

      test('getStats returns defaults when not initialized', () async {
        final stats = await source.getStats();
        expect(stats['database_type'], 'postgresql');
        expect(stats['host'], 'localhost');
        expect(stats['is_initialized'], isFalse);
        expect(stats['connection_pool_size'], 0);
        expect(stats['available_connections'], 0);
        expect(stats['parallel_query_config'], isA<Map>());
        expect(stats['performance_metrics'], isA<Map>());
        expect(stats['pool_health'], isA<Map>());
      });
    });

    group('public methods throw or return when not initialized', () {
      test('getChunks returns empty', () async {
        final chunks = await source.getChunks(query: 'SELECT 1');
        expect(chunks, isEmpty);
      });

      test('fetchData throws StateError', () async {
        expect(
          () => source.fetchData(query: 'SELECT 1'),
          throwsA(isA<StateError>()),
        );
      });

      test('executeQuery throws StateError', () async {
        expect(
          () => source.executeQuery('SELECT 1', []),
          throwsA(isA<StateError>()),
        );
      });

      test('storeChunks throws StateError', () async {
        expect(() => source.storeChunks(const []), throwsA(isA<StateError>()));
      });
    });
  });
}
