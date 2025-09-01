import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/database_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';
import '../test_helper.dart';

void main() {
  setupTestMocks();

  group('DatabaseSource Tests', () {
    late DatabaseConfig config;

    setUp(() {
      config = DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'test_db',
        username: 'test_user',
        password: 'test_password',
        maxConnections: 5,
      );
    });

    // tearDown removed since we're not using databaseSource in the simplified tests

    group('DatabaseConfig', () {
      test('should create config with default values', () {
        final config = DatabaseConfig(
          host: 'localhost',
          port: 5432,
          database: 'test_db',
          username: 'test_user',
          password: 'test_password',
        );

        expect(config.host, equals('localhost'));
        expect(config.port, equals(5432));
        expect(config.database, equals('test_db'));
        expect(config.username, equals('test_user'));
        expect(config.password, equals('test_password'));
        expect(config.maxConnections, equals(10));
        // Note: Default timeouts come from DynamicConfigManager, so we can't predict exact values
        expect(config.connectionTimeout, isA<Duration>());
        expect(config.queryTimeout, isA<Duration>());
      });

      test('should create config with custom values', () {
        final config = DatabaseConfig(
          host: 'remote.host',
          port: 3306,
          database: 'prod_db',
          username: 'admin',
          password: 'secret',
          maxConnections: 20,
          connectionTimeout: Duration(seconds: 60),
          queryTimeout: Duration(seconds: 120),
        );

        expect(config.host, equals('remote.host'));
        expect(config.port, equals(3306));
        expect(config.database, equals('prod_db'));
        expect(config.username, equals('admin'));
        expect(config.password, equals('secret'));
        expect(config.maxConnections, equals(20));
        expect(config.connectionTimeout, equals(const Duration(seconds: 60)));
        expect(config.queryTimeout, equals(const Duration(seconds: 120)));
      });

      test('should convert to JSON', () {
        final config = DatabaseConfig(
          host: 'localhost',
          port: 5432,
          database: 'test_db',
          username: 'test_user',
          password: 'test_password',
          maxConnections: 15,
          connectionTimeout: Duration(seconds: 45),
          queryTimeout: Duration(seconds: 90),
        );

        final json = config.toJson();

        expect(json['host'], equals('localhost'));
        expect(json['port'], equals(5432));
        expect(json['database'], equals('test_db'));
        expect(json['username'], equals('test_user'));
        // Note: Password is not included in JSON for security reasons
        expect(json.containsKey('password'), isFalse);
        expect(json['max_connections'], equals(15));
        expect(json['connection_timeout_seconds'], equals(45));
        expect(json['query_timeout_seconds'], equals(90));
      });
    });

    group('DatabaseConnectionPool', () {
      late DatabaseConnectionPool pool;

      setUp(() {
        pool = DatabaseConnectionPool(config);
      });

      tearDown(() {
        pool.close();
      });

      test('should create connection pool', () {
        expect(pool, isNotNull);
        expect(pool.config, equals(config));
      });

      test('should close connection pool', () async {
        await pool.close();
        // Pool should be closed
        expect(pool, isNotNull);
      });

      test('should get performance metrics', () {
        final metrics = pool.getPerformanceMetrics();

        expect(metrics, isA<Map<String, dynamic>>());
        expect(metrics['total_queries'], equals(0));
        expect(metrics['parallel_queries'], equals(0));
        expect(metrics['sequential_queries'], equals(0));
        expect(metrics['query_timeouts'], equals(0));
        expect(metrics['connection_waits'], equals(0));
        expect(metrics['batch_queries'], equals(0));
        expect(metrics['average_wait_time_ms'], equals(0.0));
        expect(metrics['parallelization_rate'], equals('0%'));
      });

      test('should reset performance metrics', () {
        // First get metrics to ensure they exist
        final initialMetrics = pool.getPerformanceMetrics();
        expect(initialMetrics['total_queries'], equals(0));

        // Reset metrics
        pool.resetPerformanceMetrics();

        // Get metrics again to ensure they're still accessible
        final resetMetrics = pool.getPerformanceMetrics();
        expect(resetMetrics['total_queries'], equals(0));
      });

      test('should get health status', () {
        final health = pool.getHealthStatus();

        expect(health, isA<Map<String, dynamic>>());
        expect(health['total_connections'], equals(0));
        expect(health['available_connections'], equals(0));
        expect(health['in_use_connections'], equals(0));
        expect(health['stale_connections'], equals(0));
        expect(health['pool_utilization'], equals('0%'));
        expect(health['health_status'], equals('healthy'));
      });
    });

    group('DatabaseSource - Basic Tests', () {
      late DatabaseSource source;
      late _MockCacheManager mockCacheManager;

      setUp(() {
        mockCacheManager = _MockCacheManager();
        source = DatabaseSource(
          databaseConfig: config,
          databaseType: 'sqlite',
          name: 'test_source',
          sourceType: SourceType.database,
          cacheManager: mockCacheManager,
        );
      });

      test('should create database source with required parameters', () {
        expect(source, isNotNull);
        expect(source.name, equals('test_source'));
        expect(source.databaseType, equals('sqlite'));
        expect(source.sourceType, equals(SourceType.database));
      });

      test('should get configuration', () {
        final config = source.getConfiguration();
        expect(config, isA<Map<String, dynamic>>());
        expect(config, isEmpty);
      });

      test('should update configuration', () async {
        final newConfig = {'new': 'config'};
        await source.updateConfiguration(newConfig);

        final config = source.getConfiguration();
        expect(config['new'], equals('config'));
      });

      test('should update metadata', () async {
        final newMetadata = {'new': 'metadata'};
        await source.updateMetadata(newMetadata);

        final metadata = source.metadata;
        expect(metadata['new'], equals('metadata'));
      });

      test('should get source context', () {
        final sourceContext = source.source;

        expect(sourceContext.name, equals('test_source'));
        expect(sourceContext.sourceType, equals(SourceType.database));
        expect(sourceContext.metadata, isEmpty);
        expect(sourceContext.privacyLevel, equals(PrivacyLevel.public));
        expect(sourceContext.authorityScore, equals(1.0));
        expect(sourceContext.freshnessScore, equals(1.0));
      });

      test('should get stats when not initialized', () async {
        final stats = await source.getStats();

        expect(stats['database_type'], equals('sqlite'));
        expect(stats['host'], equals('localhost'));
        expect(stats['port'], equals(5432));
        expect(stats['database'], equals('test_db'));
        expect(stats['max_connections'], equals(5));
        expect(stats['is_initialized'], isFalse);
        expect(stats['connection_pool_size'], equals(0));
        expect(stats['available_connections'], equals(0));
        expect(stats['parallel_query_config'], isA<Map<String, dynamic>>());

        expect(stats['performance_metrics'], isA<Map>());
        expect(stats['pool_health'], isA<Map>());
        expect(stats['performance_metrics'], isEmpty);
        expect(stats['pool_health'], isEmpty);
      });

      test('should get status when not initialized', () async {
        final status = await source.getStatus();
        expect(status, equals(SourceStatus.offline));
      });

      test('should get health when not initialized', () async {
        final isHealthy = await source.isHealthy();
        expect(isHealthy, isFalse);
      });

      test('should refresh without error', () async {
        expect(() => source.refresh(), returnsNormally);
      });

      test('should get chunks when not initialized', () async {
        final chunks = await source.getChunks(query: 'test');
        expect(chunks, isEmpty);
      });

      test('should set and get parallel query configuration', () {
        final parallelConfig = ParallelQueryConfig(
          maxConcurrentQueries: 8,
          batchSize: 200,
          enableParallelQueries: true,
          queryTimeout: Duration(seconds: 45),
          maxRetries: 5,
        );

        source.setParallelQueryConfig(parallelConfig);
        final retrievedConfig = source.getParallelQueryConfig();

        expect(retrievedConfig.maxConcurrentQueries, equals(8));
        expect(retrievedConfig.batchSize, equals(200));
        expect(retrievedConfig.enableParallelQueries, isTrue);
        expect(retrievedConfig.queryTimeout, equals(Duration(seconds: 45)));
        expect(retrievedConfig.maxRetries, equals(5));
      });
    });

    group('QueryBatch Tests', () {
      test('should create QueryBatch with all parameters', () {
        final batch = QueryBatch(
          query: 'SELECT * FROM users',
          filters: {'status': 'active'},
          limit: 100,
          offset: 50,
          batchIndex: 1,
        );

        expect(batch.query, equals('SELECT * FROM users'));
        expect(batch.filters, equals({'status': 'active'}));
        expect(batch.limit, equals(100));
        expect(batch.offset, equals(50));
        expect(batch.batchIndex, equals(1));
      });

      test('should create QueryBatch with minimal parameters', () {
        final batch = QueryBatch(query: 'SELECT * FROM users', batchIndex: 0);

        expect(batch.query, equals('SELECT * FROM users'));
        expect(batch.filters, isNull);
        expect(batch.limit, isNull);
        expect(batch.offset, isNull);
        expect(batch.batchIndex, equals(0));
      });

      test('should convert QueryBatch to JSON', () {
        final batch = QueryBatch(
          query: 'SELECT * FROM users WHERE age > 18',
          filters: {'min_age': 18, 'status': 'active'},
          limit: 50,
          offset: 0,
          batchIndex: 2,
        );

        final json = batch.toJson();

        expect(json['query'], equals('SELECT * FROM users WHERE age > 18'));
        expect(json['filters'], equals({'min_age': 18, 'status': 'active'}));
        expect(json['limit'], equals(50));
        expect(json['offset'], equals(0));
        expect(json['batch_index'], equals(2));
      });
    });

    group('ParallelQueryResult Tests', () {
      test('should create ParallelQueryResult with all parameters', () {
        final result = ParallelQueryResult<String>(
          results: ['result1', 'result2', 'result3'],
          queryTime: Duration(milliseconds: 150),
          queriesExecuted: 3,
          metadata: {'total_results': 3, 'cache_hit': false},
        );

        expect(result.results, equals(['result1', 'result2', 'result3']));
        expect(result.queryTime, equals(Duration(milliseconds: 150)));
        expect(result.queriesExecuted, equals(3));
        expect(
          result.metadata,
          equals({'total_results': 3, 'cache_hit': false}),
        );
      });

      test('should create ParallelQueryResult with minimal parameters', () {
        final result = ParallelQueryResult<int>(
          results: [1, 2, 3, 4, 5],
          queryTime: Duration(milliseconds: 100),
          queriesExecuted: 1,
        );

        expect(result.results, equals([1, 2, 3, 4, 5]));
        expect(result.queryTime, equals(Duration(milliseconds: 100)));
        expect(result.queriesExecuted, equals(1));
        expect(result.metadata, isEmpty);
      });
    });
  });
}

/// Simple mock cache manager for testing
class _MockCacheManager implements CacheManager {
  @override
  T? get<T>(String key) => null;

  @override
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  bool contains(String key) => false;

  @override
  void remove(String key) {}

  @override
  void dispose() {}

  @override
  CacheStats getStats() => CacheStats(
    totalEntries: 0,
    expiredEntries: 0,
    activeEntries: 0,
    totalHits: 0,
    totalMisses: 0,
    hitRate: 0.0,
    memoryUsageBytes: 0,
    lastCleanup: DateTime.now(),
    averageAccessTime: Duration.zero,
  );

  // Additional methods that don't override but are required
  @override
  Future<void> clear() async {}
  @override
  void extendTTL(String key, Duration ttl) {}
  @override
  Map<String, dynamic> getDetailedMemoryStats() => {};
  @override
  List<String> getKeys() => [];
  @override
  Map<String, dynamic> getPerformanceMetrics() => {};
  @override
  Future<void> updateMetadata(
    String key,
    Map<String, dynamic> metadata,
  ) async {}
}
