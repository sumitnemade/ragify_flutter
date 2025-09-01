import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/database_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';

void main() {
  group('DatabaseSource Error Handling', () {
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
        name: 'test_db_source',
        sourceType: SourceType.database,
        databaseConfig: config,
        databaseType: 'postgresql',
        cacheManager: cache,
      );
    });

    tearDown(() async {
      await source.close();
    });

    group('Uninitialized Operations', () {
      test('getChunks returns empty when not initialized', () async {
        final chunks = await source.getChunks(query: 'SELECT * FROM test');
        expect(chunks, isEmpty);
      });

      test('fetchData throws when not initialized', () async {
        expect(
          () => source.fetchData(query: 'SELECT * FROM test'),
          throwsA(isA<StateError>()),
        );
      });

      // No public storeData/executeBatch API in DatabaseSource; covered via
      // storeChunks and internal batching during fetch.

      test('executeQuery throws when not initialized', () async {
        expect(
          () => source.executeQuery('UPDATE test SET column = ?', ['value']),
          throwsA(isA<StateError>()),
        );
      });

      test('QueryBatch can be created with required fields', () {
        final batch = QueryBatch(
          query: 'SELECT * FROM t',
          batchIndex: 0,
          limit: 10,
          offset: 0,
          filters: {'source_name': 'x'},
        );
        final json = batch.toJson();
        expect(json, containsPair('query', 'SELECT * FROM t'));
        expect(json, containsPair('batch_index', 0));
      });
    });

    group('Initialization Failure', () {
      test('initialize throws when connections cannot be created', () async {
        await expectLater(source.initialize(), throwsA(isA<StateError>()));
        expect(source.isActive, isFalse);
      });
    });

    group('DatabaseConfig Validation', () {
      test('creates config with parameters', () {
        final cfg = DatabaseConfig(
          host: 'example.com',
          port: 3306,
          database: 'mydb',
          username: 'user',
          password: 'pass',
          connectionTimeout: Duration(seconds: 45),
          queryTimeout: Duration(seconds: 20),
          maxConnections: 10,
        );

        expect(cfg.host, equals('example.com'));
        expect(cfg.port, equals(3306));
        expect(cfg.database, equals('mydb'));
        expect(cfg.username, equals('user'));
        expect(cfg.password, equals('pass'));
        expect(cfg.connectionTimeout, equals(Duration(seconds: 45)));
        expect(cfg.queryTimeout, equals(Duration(seconds: 20)));
        expect(cfg.maxConnections, equals(10));
      });

      test('serializes to JSON correctly', () {
        final json = config.toJson();
        
        expect(json, containsPair('host', 'localhost'));
        expect(json, containsPair('port', 5432));
        expect(json, containsPair('database', 'test_db'));
        expect(json, containsPair('username', 'test_user'));
        expect(json, containsPair('max_connections', 5));
        expect(json, containsPair('connection_timeout_seconds', 30));
        expect(json, containsPair('query_timeout_seconds', 10));
      });
    });

    group('ParallelQueryConfig', () {
      test('creates parallel config with defaults', () {
        final pc = ParallelQueryConfig();
        
        expect(pc.maxConcurrentQueries, equals(4));
        expect(pc.batchSize, equals(100));
        expect(pc.enableParallelQueries, isTrue);
        expect(pc.queryTimeout.inSeconds, greaterThan(0));
        expect(pc.maxRetries, equals(3));
      });

      test('creates parallel config with custom values', () {
        final pc = ParallelQueryConfig(
          maxConcurrentQueries: 8,
          batchSize: 50,
          enableParallelQueries: false,
          queryTimeout: Duration(seconds: 60),
          maxRetries: 5,
        );
        
        expect(pc.maxConcurrentQueries, equals(8));
        expect(pc.batchSize, equals(50));
        expect(pc.enableParallelQueries, isFalse);
        expect(pc.queryTimeout, equals(Duration(seconds: 60)));
        expect(pc.maxRetries, equals(5));
      });

      test('serializes to JSON', () {
        final pc = ParallelQueryConfig(
          maxConcurrentQueries: 6,
          batchSize: 200,
          enableParallelQueries: true,
          queryTimeout: Duration(seconds: 45),
          maxRetries: 3,
        );

        final json = pc.toJson();
        
        expect(json, containsPair('max_concurrent_queries', 6));
        expect(json, containsPair('batch_size', 200));
        expect(json, containsPair('enable_parallel_queries', true));
        expect(json, containsPair('query_timeout_seconds', 45));
        expect(json, containsPair('max_retries', 3));
      });
    });

    group('QueryBatch', () {
      test('creates query batch and serializes', () {
        final batch = QueryBatch(
          query: 'SELECT * FROM test',
          batchIndex: 1,
          limit: 100,
          offset: 10,
          filters: {'privacy_level': 'public'},
        );

        final json = batch.toJson();
        expect(json, containsPair('query', 'SELECT * FROM test'));
        expect(json, containsPair('batch_index', 1));
        expect(json, containsPair('limit', 100));
        expect(json, containsPair('offset', 10));
        expect(json['filters'], containsPair('privacy_level', 'public'));
      });
    });

    group('ParallelQueryResult', () {
      test('creates parallel query result', () {
        final result = ParallelQueryResult<Map<String, dynamic>>(
          results: [
            {'id': 1, 'name': 'John'},
            {'id': 2, 'name': 'Jane'},
          ],
          queryTime: Duration(milliseconds: 150),
          queriesExecuted: 2,
          metadata: {'note': 'ok'},
        );

        expect(result.results.length, equals(2));
        expect(result.queryTime, equals(Duration(milliseconds: 150)));
        expect(result.queriesExecuted, equals(2));
        expect(result.metadata, containsPair('note', 'ok'));
      });
    });

    group('DatabaseConnectionPool', () {
      test('creates connection pool and reports metrics/health', () {
        final pool = DatabaseConnectionPool(config);

        final metrics = pool.getPerformanceMetrics();
        expect(metrics, isA<Map<String, dynamic>>());
        expect(metrics, contains('total_queries'));

        final health = pool.getHealthStatus();
        expect(health, isA<Map<String, dynamic>>());
        expect(health, contains('total_connections'));
        expect(health, contains('available_connections'));
        expect(health, contains('health_status'));

        pool.resetPerformanceMetrics();
        final metrics2 = pool.getPerformanceMetrics();
        expect(metrics2['total_queries'], equals(0));
      });
    });

    group('Statistics and Health', () {
      test('provides stats when not initialized', () async {
        final stats = await source.getStats();
        expect(stats, containsPair('database_type', 'postgresql'));
        expect(stats, containsPair('is_initialized', false));
        expect(stats, containsPair('connection_pool_size', 0));
        expect(stats, containsPair('available_connections', 0));
        expect(stats, containsPair('parallel_query_config', isA<Map>()));
        expect(stats, containsPair('performance_metrics', isA<Map>()));
        expect(stats, containsPair('pool_health', isA<Map>()));
      });

      test('status and health when not initialized', () async {
        final status = await source.getStatus();
        expect(status, equals(SourceStatus.offline));
        final healthy = await source.isHealthy();
        expect(healthy, isFalse);
      });
    });

    group('Configuration', () {
      test('provides database configuration map (initially empty)', () {
        final configMap = source.config;
        expect(configMap, isA<Map<String, dynamic>>());
        expect(configMap, isEmpty);
      });
    });

    group('Lifecycle', () {
      test('handles refresh when not initialized', () async {
        await source.refresh();
        
        // Should complete without error
        expect(source.isActive, isFalse);
      });

      test('handles updateMetadata', () {
        source.updateMetadata({'new_key': 'new_value'});
        
        expect(source.metadata, containsPair('new_key', 'new_value'));
      });

      test('handles close', () async {
        await source.close();
        
        // Should complete without error
        expect(source.isActive, isFalse);
      });
    });

    group('Database Type Support', () {
      test('supports different database types', () async {
        final mysqlSource = DatabaseSource(
          name: 'mysql_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'mysql',
          cacheManager: cache,
        );

        final sqliteSource = DatabaseSource(
          name: 'sqlite_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'sqlite',
          cacheManager: cache,
        );

        final mongoSource = DatabaseSource(
          name: 'mongo_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'mongodb',
          cacheManager: cache,
        );

        expect(mysqlSource.databaseType, equals('mysql'));
        expect(sqliteSource.databaseType, equals('sqlite'));
        expect(mongoSource.databaseType, equals('mongodb'));

        await mysqlSource.close();
        await sqliteSource.close();
        await mongoSource.close();
      });
    });
  });
}
