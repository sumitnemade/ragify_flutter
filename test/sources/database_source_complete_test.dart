import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/database_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';

void main() {
  group('DatabaseSource Complete Coverage Tests', () {
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
    });

    group('DatabaseConfig Coverage', () {
      test('creates DatabaseConfig with all parameters', () {
        final customConfig = DatabaseConfig(
          host: 'custom.host.com',
          port: 3306,
          database: 'custom_db',
          username: 'custom_user',
          password: 'custom_pass',
          maxConnections: 20,
          connectionTimeout: Duration(seconds: 45),
          queryTimeout: Duration(seconds: 120),
        );

        expect(customConfig.host, 'custom.host.com');
        expect(customConfig.port, 3306);
        expect(customConfig.database, 'custom_db');
        expect(customConfig.username, 'custom_user');
        expect(customConfig.password, 'custom_pass');
        expect(customConfig.maxConnections, 20);
        expect(customConfig.connectionTimeout, Duration(seconds: 45));
        expect(customConfig.queryTimeout, Duration(seconds: 120));
      });

      test('creates DatabaseConfig with default values', () {
        final defaultConfig = DatabaseConfig(
          host: 'localhost',
          port: 5432,
          database: 'test_db',
          username: 'user',
          password: 'pass',
        );

        expect(defaultConfig.maxConnections, 10);
        expect(defaultConfig.connectionTimeout, isA<Duration>());
        expect(defaultConfig.queryTimeout, isA<Duration>());
      });

      test('serializes DatabaseConfig to JSON', () {
        final json = config.toJson();
        expect(json['host'], 'localhost');
        expect(json['port'], 5432);
        expect(json['database'], 'test_db');
        expect(json['username'], 'test_user');
        expect(json['max_connections'], 5);
        expect(json['connection_timeout_seconds'], 30);
        expect(json['query_timeout_seconds'], 10);
      });
    });

    group('ParallelQueryConfig Coverage', () {
      test('creates ParallelQueryConfig with default values', () {
        final parallelConfig = ParallelQueryConfig();
        expect(parallelConfig.maxConcurrentQueries, 4);
        expect(parallelConfig.batchSize, 100);
        expect(parallelConfig.enableParallelQueries, isTrue);
        expect(parallelConfig.queryTimeout, isA<Duration>());
        expect(parallelConfig.maxRetries, 3);
      });

      test('creates ParallelQueryConfig with custom values', () {
        final parallelConfig = ParallelQueryConfig(
          maxConcurrentQueries: 8,
          batchSize: 50,
          enableParallelQueries: false,
          queryTimeout: Duration(seconds: 15),
          maxRetries: 5,
        );

        expect(parallelConfig.maxConcurrentQueries, 8);
        expect(parallelConfig.batchSize, 50);
        expect(parallelConfig.enableParallelQueries, isFalse);
        expect(parallelConfig.queryTimeout, Duration(seconds: 15));
        expect(parallelConfig.maxRetries, 5);
      });

      test('serializes ParallelQueryConfig to JSON', () {
        final parallelConfig = ParallelQueryConfig(
          maxConcurrentQueries: 6,
          batchSize: 75,
          enableParallelQueries: true,
          queryTimeout: Duration(seconds: 20),
          maxRetries: 4,
        );

        final json = parallelConfig.toJson();
        expect(json['max_concurrent_queries'], 6);
        expect(json['batch_size'], 75);
        expect(json['enable_parallel_queries'], isTrue);
        expect(json['query_timeout_seconds'], 20);
        expect(json['max_retries'], 4);
      });
    });

    group('QueryBatch Coverage', () {
      test('creates QueryBatch with all parameters', () {
        final batch = QueryBatch(
          query: 'SELECT * FROM table',
          filters: {'status': 'active'},
          limit: 100,
          offset: 50,
          batchIndex: 2,
        );

        expect(batch.query, 'SELECT * FROM table');
        expect(batch.filters, {'status': 'active'});
        expect(batch.limit, 100);
        expect(batch.offset, 50);
        expect(batch.batchIndex, 2);
      });

      test('serializes QueryBatch to JSON', () {
        final batch = QueryBatch(
          query: 'SELECT id FROM users',
          filters: {'role': 'admin'},
          limit: 25,
          offset: 10,
          batchIndex: 1,
        );

        final json = batch.toJson();
        expect(json['query'], 'SELECT id FROM users');
        expect(json['filters'], {'role': 'admin'});
        expect(json['limit'], 25);
        expect(json['offset'], 10);
        expect(json['batch_index'], 1);
      });
    });

    group('ParallelQueryResult Coverage', () {
      test('creates ParallelQueryResult with all parameters', () {
        final result = ParallelQueryResult<String>(
          results: ['result1', 'result2'],
          queryTime: Duration(milliseconds: 250),
          queriesExecuted: 3,
          metadata: {'total_rows': 150},
        );

        expect(result.results, ['result1', 'result2']);
        expect(result.queryTime, Duration(milliseconds: 250));
        expect(result.queriesExecuted, 3);
        expect(result.metadata, {'total_rows': 150});
      });

      test('creates ParallelQueryResult with default metadata', () {
        final result = ParallelQueryResult<int>(
          results: [1, 2, 3],
          queryTime: Duration(milliseconds: 100),
          queriesExecuted: 1,
        );

        expect(result.results, [1, 2, 3]);
        expect(result.queryTime, Duration(milliseconds: 100));
        expect(result.queriesExecuted, 1);
        expect(result.metadata, isEmpty);
      });
    });

    group('DatabaseConnectionPool Coverage', () {
      late DatabaseConnectionPool pool;

      setUp(() {
        pool = DatabaseConnectionPool(config);
      });

      tearDown(() async {
        await pool.close();
      });

      test('initializes with empty connections', () {
        expect(pool.getPerformanceMetrics()['total_queries'], 0);
        expect(pool.getPerformanceMetrics()['parallel_queries'], 0);
        expect(pool.getPerformanceMetrics()['sequential_queries'], 0);
        expect(pool.getPerformanceMetrics()['query_timeouts'], 0);
        expect(pool.getPerformanceMetrics()['connection_waits'], 0);
        expect(pool.getPerformanceMetrics()['batch_queries'], 0);
      });

      test('getPerformanceMetrics returns comprehensive data', () {
        final metrics = pool.getPerformanceMetrics();
        expect(metrics, isA<Map<String, dynamic>>());
        expect(metrics, containsPair('total_queries', 0));
        expect(metrics, containsPair('parallel_queries', 0));
        expect(metrics, containsPair('sequential_queries', 0));
        expect(metrics, containsPair('query_timeouts', 0));
        expect(metrics, containsPair('connection_waits', 0));
        expect(metrics, containsPair('batch_queries', 0));
        expect(metrics, containsPair('average_wait_time_ms', 0.0));
        expect(metrics, containsPair('parallelization_rate', '0%'));
      });

      test('resetPerformanceMetrics clears all metrics', () {
        // Metrics start at 0, so this mainly tests the method exists
        pool.resetPerformanceMetrics();
        final metrics = pool.getPerformanceMetrics();
        expect(metrics['total_queries'], 0);
        expect(metrics['parallel_queries'], 0);
      });

      test('getHealthStatus returns pool health information', () {
        final health = pool.getHealthStatus();
        expect(health, isA<Map<String, dynamic>>());
        expect(health, containsPair('total_connections', 0));
        expect(health, containsPair('available_connections', 0));
        expect(health, containsPair('in_use_connections', 0));
        expect(health, containsPair('stale_connections', 0));
        expect(health, containsPair('pool_utilization', '0%'));
        expect(health, containsPair('health_status', 'healthy'));
      });

      test('getConnection times out with no connections', () async {
        // Configure a very short timeout to avoid long test times
        final timeoutConfig = DatabaseConfig(
          host: 'localhost',
          port: 5432,
          database: 'test_db',
          username: 'test_user',
          password: 'test_pass',
          maxConnections: 0, // No connections can be created
          connectionTimeout: Duration(milliseconds: 10),
        );
        final timeoutPool = DatabaseConnectionPool(timeoutConfig);

        await expectLater(
          timeoutPool.getConnection(),
          throwsA(isA<TimeoutException>()),
        );
        await timeoutPool.close();
      });

      test('returnConnection handles unknown connection gracefully', () {
        final unknownConnection = Object();
        // Should not throw
        pool.returnConnection(unknownConnection);
      });

      test('close completes without error on empty pool', () async {
        await expectLater(pool.close(), completes);
      });
    });

    group('DatabaseSource Basic Functionality', () {
      late DatabaseSource source;

      setUp(() {
        source = DatabaseSource(
          name: 'test_db_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'postgresql',
          cacheManager: cache,
          metadata: {'version': '1.0', 'environment': 'test'},
        );
      });

      tearDown(() async {
        await source.close();
      });

      test('initializes with correct properties', () {
        expect(source.name, 'test_db_source');
        expect(source.sourceType, SourceType.database);
        expect(source.databaseConfig, config);
        expect(source.databaseType, 'postgresql');
        expect(source.cacheManager, cache);
        expect(source.isActive, isFalse);
        expect(source.metadata, containsPair('version', '1.0'));
        expect(source.metadata, containsPair('environment', 'test'));
      });

      test('getConfiguration returns empty initially', () {
        expect(source.getConfiguration(), isEmpty);
      });

      test('updateConfiguration adds new values', () async {
        await source.updateConfiguration({'cache_enabled': true, 'timeout': 30});
        final config = source.getConfiguration();
        expect(config['cache_enabled'], isTrue);
        expect(config['timeout'], 30);
      });

      test('updateMetadata merges with existing metadata', () async {
        expect(source.metadata['version'], '1.0');
        
        await source.updateMetadata({'author': 'test_user', 'version': '2.0'});
        expect(source.metadata['version'], '2.0'); // Updated
        expect(source.metadata['environment'], 'test'); // Preserved
        expect(source.metadata['author'], 'test_user'); // Added
      });

      test('parallel query configuration management', () {
        final initialConfig = source.getParallelQueryConfig();
        expect(initialConfig.maxConcurrentQueries, 4);
        expect(initialConfig.batchSize, 100);

        final newConfig = ParallelQueryConfig(
          maxConcurrentQueries: 8,
          batchSize: 50,
          enableParallelQueries: true,
        );
        source.setParallelQueryConfig(newConfig);

        final updatedConfig = source.getParallelQueryConfig();
        expect(updatedConfig.maxConcurrentQueries, 8);
        expect(updatedConfig.batchSize, 50);
        expect(updatedConfig.enableParallelQueries, isTrue);
      });

      test('source property returns correct ContextSource', () {
        final contextSource = source.source;
        expect(contextSource.id, 'test_db_source');
        expect(contextSource.name, 'test_db_source');
        expect(contextSource.sourceType, SourceType.database);
        expect(contextSource.isActive, isFalse);
        expect(contextSource.privacyLevel, PrivacyLevel.public);
      });
    });

    group('DatabaseSource Uninitialized State Tests', () {
      late DatabaseSource source;

      setUp(() {
        source = DatabaseSource(
          name: 'uninitialized_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'postgresql',
          cacheManager: cache,
        );
      });

      tearDown(() async {
        await source.close();
      });

      test('getChunks returns empty when not initialized', () async {
        final chunks = await source.getChunks(query: 'test query');
        expect(chunks, isEmpty);
      });

      test('fetchData throws StateError when not initialized', () async {
        await expectLater(
          source.fetchData(query: 'SELECT * FROM test'),
          throwsA(isA<StateError>()),
        );
      });

      test('executeQuery throws StateError when not initialized', () async {
        await expectLater(
          source.executeQuery('SELECT COUNT(*)', []),
          throwsA(isA<StateError>()),
        );
      });

      test('storeChunks throws StateError when not initialized', () async {
        await expectLater(
          source.storeChunks([]),
          throwsA(isA<StateError>()),
        );
      });

      test('isHealthy returns false when not initialized', () async {
        expect(await source.isHealthy(), isFalse);
      });

      test('getStatus returns offline when not initialized', () async {
        expect(await source.getStatus(), SourceStatus.offline);
      });

      test('getStats returns default values when not initialized', () async {
        final stats = await source.getStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['is_initialized'], isFalse);
        expect(stats['connection_pool_size'], 0);
        expect(stats['parallel_query_config'], isA<Map>());
        expect(stats['performance_metrics'], isA<Map>());
        expect(stats['pool_health'], isA<Map>());
      });

      test('refresh does not throw when not initialized', () async {
        await expectLater(source.refresh(), completes);
      });

      test('close sets isActive to false', () async {
        expect(source.isActive, isFalse);
        await source.close();
        expect(source.isActive, isFalse);
      });
    });

    group('DatabaseSource Different Database Types', () {
      test('creates SQLite source', () {
        final sqliteSource = DatabaseSource(
          name: 'sqlite_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'sqlite',
          cacheManager: cache,
        );

        expect(sqliteSource.databaseType, 'sqlite');
        expect(sqliteSource.name, 'sqlite_source');
      });

      test('creates MySQL source', () {
        final mysqlSource = DatabaseSource(
          name: 'mysql_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'mysql',
          cacheManager: cache,
        );

        expect(mysqlSource.databaseType, 'mysql');
        expect(mysqlSource.name, 'mysql_source');
      });

      test('creates MongoDB source', () {
        final mongoSource = DatabaseSource(
          name: 'mongo_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'mongodb',
          cacheManager: cache,
        );

        expect(mongoSource.databaseType, 'mongodb');
        expect(mongoSource.name, 'mongo_source');
      });

      test('creates PostgreSQL source', () {
        final postgresSource = DatabaseSource(
          name: 'postgres_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'postgresql',
          cacheManager: cache,
        );

        expect(postgresSource.databaseType, 'postgresql');
        expect(postgresSource.name, 'postgres_source');
      });
    });

    group('DatabaseSource Constructor Variations', () {
      test('creates with custom parallel config', () {
        final customParallelConfig = ParallelQueryConfig(
          maxConcurrentQueries: 12,
          batchSize: 200,
        );

        final source = DatabaseSource(
          name: 'custom_parallel_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'postgresql',
          cacheManager: cache,
          parallelConfig: customParallelConfig,
        );

        final retrievedConfig = source.getParallelQueryConfig();
        expect(retrievedConfig.maxConcurrentQueries, 12);
        expect(retrievedConfig.batchSize, 200);
      });

      test('creates with custom metadata', () {
        final customMetadata = {
          'application': 'test_app',
          'version': '3.0',
          'maintainer': 'dev_team',
        };

        final source = DatabaseSource(
          name: 'metadata_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'sqlite',
          cacheManager: cache,
          metadata: customMetadata,
        );

        expect(source.metadata['application'], 'test_app');
        expect(source.metadata['version'], '3.0');
        expect(source.metadata['maintainer'], 'dev_team');
      });

      test('creates with injected connection pool', () {
        final mockConnections = [_MockConnection()];
        final customPool = DatabaseConnectionPool(config, initialConnections: mockConnections);

        final source = DatabaseSource(
          name: 'injected_pool_source',
          sourceType: SourceType.database,
          databaseConfig: config,
          databaseType: 'postgresql',
          cacheManager: cache,
          connectionPool: customPool,
        );

        expect(source.name, 'injected_pool_source');
        expect(source.databaseType, 'postgresql');
        // The pool should have the injected connections
        final health = customPool.getHealthStatus();
        expect(health['total_connections'], 1);
      });
    });
  });
}

/// Simple mock connection for testing connection pool injection
class _MockConnection {
  bool isClosed = false;
  
  Future<void> close() async {
    isClosed = true;
  }
}
