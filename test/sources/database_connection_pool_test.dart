import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/database_source.dart';

void main() {
  group('DatabaseConnectionPool', () {
    late DatabaseConnectionPool pool;
    late DatabaseConfig config;

    setUp(() {
      config = DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'db',
        username: 'u',
        password: 'p',
        maxConnections: 1,
        connectionTimeout: const Duration(milliseconds: 50),
      );
      pool = DatabaseConnectionPool(config);
    });

    test('getPerformanceMetrics and resetPerformanceMetrics', () {
      final metrics1 = pool.getPerformanceMetrics();
      expect(metrics1, containsPair('total_queries', 0));
      expect(metrics1, containsPair('average_wait_time_ms', isA<num>()));

      pool.resetPerformanceMetrics();
      final metrics2 = pool.getPerformanceMetrics();
      expect(metrics2['total_queries'], 0);
    });

    test('getHealthStatus returns defaults for empty pool', () {
      final health = pool.getHealthStatus();
      expect(health['total_connections'], 0);
      expect(health['available_connections'], 0);
      expect(health['in_use_connections'], 0);
      expect(health['pool_utilization'], '0%');
      expect(health['health_status'], 'healthy');
    });

    test('getConnection times out when no connection available', () async {
      // Use a pool with zero maxConnections to force wait loop and timeout
      final zeroMaxConfig = DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'db',
        username: 'u',
        password: 'p',
        maxConnections: 0,
        connectionTimeout: const Duration(milliseconds: 50),
      );
      final zeroMaxPool = DatabaseConnectionPool(zeroMaxConfig);

      await expectLater(
        zeroMaxPool.getConnection(),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('returnConnection is no-op for unknown connection', () {
      pool.returnConnection(Object());
      final health = pool.getHealthStatus();
      expect(health['available_connections'], 0);
    });

    test('close does not throw on empty pool', () async {
      await pool.close();
      final health = pool.getHealthStatus();
      expect(health['total_connections'], 0);
    });
  });
}
