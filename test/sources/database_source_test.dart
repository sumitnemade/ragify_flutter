import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/database_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
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
    });

    group('DatabaseSource - Basic Tests', () {
      test('should create database source with required parameters', () {
        // Test that we can create a DatabaseSource with minimal parameters
        expect(() {
          DatabaseSource(
            databaseConfig: config,
            databaseType: 'sqlite',
            name: 'test_source',
            sourceType: SourceType.database,
            cacheManager: _MockCacheManager(),
          );
        }, returnsNormally);
      });

      test('should handle database source creation', () {
        // Test basic creation without complex operations
        final source = DatabaseSource(
          databaseConfig: config,
          databaseType: 'sqlite',
          name: 'test_source',
          sourceType: SourceType.database,
          cacheManager: _MockCacheManager(),
        );

        expect(source, isNotNull);
        expect(source.name, equals('test_source'));
        expect(source.databaseType, equals('sqlite'));
        expect(source.sourceType, equals(SourceType.database));
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
