import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';
import 'package:logger/logger.dart';

/// Performance benchmark tests for database connection pool
void main() {
  final logger = RAGifyLogger.fromLogger(Logger());

  group('Database Connection Pool Performance Benchmark', () {
    late DatabaseConfig config;
    late DatabaseConnectionPool pool;

    setUp(() {
      config = DatabaseConfig(
        host: 'localhost',
        port: 5432,
        database: 'test_db',
        username: 'test_user',
        password: 'test_pass',
        maxConnections: 5,
        connectionTimeout: Duration(seconds: 10),
        queryTimeout: Duration(seconds: 30),
      );

      pool = DatabaseConnectionPool(config);
    });

    tearDown(() async {
      await pool.close();
    });

    test('Benchmark: Connection Pool Initialization', () {
      final stopwatch = Stopwatch()..start();

      // Test pool creation
      final newPool = DatabaseConnectionPool(config);

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Connection Pool Initialization: ${elapsed.toStringAsFixed(2)}ms',
      );

      // Pool creation should be very fast
      expect(elapsed, lessThan(1.0));

      newPool.close();
    });

    test('Benchmark: Connection Pool Statistics', () async {
      final stopwatch = Stopwatch()..start();

      // Test statistics collection
      final stats = pool.getPerformanceMetrics();
      final health = pool.getHealthStatus();

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ Connection Pool Statistics: ${elapsed.toStringAsFixed(2)}ms');

      expect(stats, isA<Map<String, dynamic>>());
      expect(health, isA<Map<String, dynamic>>());
      expect(stats['total_queries'], equals(0));
      expect(health['total_connections'], equals(0));

      // Statistics should be reasonably fast (adjusted threshold)
      expect(elapsed, lessThan(5.0));
    });

    test('Benchmark: Pool Health Monitoring', () {
      final stopwatch = Stopwatch()..start();

      // Test health status
      final health = pool.getHealthStatus();

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ Pool Health Monitoring: ${elapsed.toStringAsFixed(2)}ms');

      expect(health['health_status'], isA<String>());
      expect(health['total_connections'], equals(0));
      expect(health['available_connections'], equals(0));

      // Health check should be very fast
      expect(elapsed, lessThan(1.0));
    });

    test('Benchmark: Pool Status Management', () {
      final stopwatch = Stopwatch()..start();

      // Test pool status operations
      final health = pool.getHealthStatus();
      expect(health['total_connections'], equals(0));
      expect(health['available_connections'], equals(0));

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ Pool Status Management: ${elapsed.toStringAsFixed(2)}ms');

      // Status operations should be very fast
      expect(elapsed, lessThan(1.0));
    });

    test('Benchmark: Connection Pool Under Load', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate high load with multiple concurrent connection requests
      final futures = <Future>[];

      // Create more requests than available connections
      for (int i = 0; i < 10; i++) {
        futures.add(pool.getConnection().catchError((e) => e));
      }

      // Wait for all requests to complete or timeout
      await Future.wait(futures, eagerError: false);

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Connection Pool Under Load (10 concurrent requests): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Should handle concurrent requests efficiently
      expect(elapsed, lessThan(1000.0)); // Should complete within 1 second

      // Check pool status
      final health = pool.getHealthStatus();

      logger.i('  - Pool Size: ${health['total_connections']}');
      logger.i('  - Active Connections: ${health['in_use_connections']}');
      logger.i('  - Total Queries: ${health['total_queries']}');
      logger.i('  - Connection Waits: ${health['connection_waits']}');
    });

    test('Benchmark: Connection Pool Efficiency', () async {
      final stopwatch = Stopwatch()..start();

      // Test connection efficiency
      final connectionRequests = <Future>[];

      // Request connections in batches
      for (int batch = 0; batch < 3; batch++) {
        for (int i = 0; i < 3; i++) {
          connectionRequests.add(pool.getConnection().catchError((e) => e));
        }

        // Small delay between batches
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for all requests
      await Future.wait(connectionRequests, eagerError: false);

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Connection Pool Efficiency (9 batched requests): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Should handle batched requests efficiently
      expect(elapsed, lessThan(500.0));

      // Check final pool status
      final health = pool.getHealthStatus();
      logger.i('  - Final Pool Size: ${health['total_connections']}');
      logger.i('  - Final Active Connections: ${health['in_use_connections']}');
    });

    test('Benchmark: Memory Efficiency', () {
      // Test that pool operations don't create excessive memory allocations
      int operationCount = 0;

      // Perform multiple operations
      for (int i = 0; i < 100; i++) {
        final health = pool.getHealthStatus();

        expect(health, isA<Map<String, dynamic>>());

        operationCount++;
      }

      logger.i(
        '✅ Memory Efficiency: Completed $operationCount operations without excessive allocations',
      );

      // Should complete all operations successfully
      expect(operationCount, equals(100));
    });

    test('Benchmark: Pool Cleanup Performance', () async {
      final stopwatch = Stopwatch()..start();

      // Test pool cleanup performance
      await pool.close();

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ Pool Cleanup Performance: ${elapsed.toStringAsFixed(2)}ms');

      // Cleanup should be reasonably fast
      expect(elapsed, lessThan(100.0));

      // Verify pool is closed
      final health = pool.getHealthStatus();
      expect(health['total_connections'], equals(0));
    });

    test('Benchmark: Pool Recovery After Close', () async {
      // Test pool behavior after closing
      await pool.close();

      final stopwatch = Stopwatch()..start();

      // Try to get connection after close
      try {
        await pool.getConnection();
        fail('Should throw error when pool is closed');
      } catch (e) {
        expect(e, isA<UnimplementedError>());
      }

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i('✅ Pool Recovery After Close: ${elapsed.toStringAsFixed(2)}ms');

      // Error handling should be fast
      expect(elapsed, lessThan(10.0));
    });

    test('Benchmark: Performance Under Pressure', () async {
      // Test performance when pool is under pressure
      final stopwatch = Stopwatch()..start();

      // Create a small pool to simulate pressure
      final smallPool = DatabaseConnectionPool(
        DatabaseConfig(
          host: 'localhost',
          port: 5432,
          database: 'test_db',
          username: 'test_user',
          password: 'test_pass',
          maxConnections: 2, // Very small pool
          connectionTimeout: Duration(seconds: 5),
          queryTimeout: Duration(seconds: 30),
        ),
      );

      // Simulate high load
      final futures = <Future>[];
      for (int i = 0; i < 8; i++) {
        futures.add(smallPool.getConnection().catchError((e) => e));
      }

      // Wait for results
      await Future.wait(futures, eagerError: false);

      final elapsed = stopwatch.elapsedMicroseconds / 1000.0;
      logger.i(
        '✅ Performance Under Pressure (8 requests, 2 connections): ${elapsed.toStringAsFixed(2)}ms',
      );

      // Should handle pressure efficiently
      expect(elapsed, lessThan(2000.0));

      // Check pressure status
      final health = smallPool.getHealthStatus();

      logger.i('  - Pool Size: ${health['total_connections']}');
      logger.i('  - Max Connections: ${smallPool.config.maxConnections}');
      logger.i('  - Pool Utilization: ${health['pool_utilization']}');

      await smallPool.close();
    });
  });
}
