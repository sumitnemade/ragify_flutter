import 'dart:async';
import 'dart:convert';
import 'dart:collection';
// SQLite only available on mobile and desktop platforms
import 'package:sqflite/sqflite.dart'
    if (dart.library.html) 'sqflite_web_stub.dart'
    as sqflite_stub;
import 'package:postgres/postgres.dart' as postgres;
import 'package:mysql1/mysql1.dart' as mysql;
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:math' as math;

import '../utils/ragify_logger.dart';

import '../models/context_chunk.dart';
import '../models/context_source.dart';
import '../models/privacy_level.dart';
import '../models/relevance_score.dart';
import '../sources/base_data_source.dart';
import '../cache/cache_manager.dart';
import '../config/dynamic_config_manager.dart';

// Platform-agnostic database types
typedef Database = dynamic;
typedef ConflictAlgorithm = dynamic;

/// **NEW: Parallel query configuration**
class ParallelQueryConfig {
  final int maxConcurrentQueries;
  final int batchSize;
  final bool enableParallelQueries;
  final Duration queryTimeout;
  final int maxRetries;

  ParallelQueryConfig({
    this.maxConcurrentQueries = 4,
    this.batchSize = 100,
    this.enableParallelQueries = true,
    Duration? queryTimeout,
    this.maxRetries = 3,
  }) : queryTimeout =
           queryTimeout ??
           DynamicConfigManager.instance.getTimeoutConfig()['database_query'] ??
           const Duration(seconds: 30);

  Map<String, dynamic> toJson() => {
    'max_concurrent_queries': maxConcurrentQueries,
    'batch_size': batchSize,
    'enable_parallel_queries': enableParallelQueries,
    'query_timeout_seconds': queryTimeout.inSeconds,
    'max_retries': maxRetries,
  };
}

/// **NEW: Parallel query result**
class ParallelQueryResult<T> {
  final List<T> results;
  final Duration queryTime;
  final int queriesExecuted;
  final Map<String, dynamic> metadata;

  const ParallelQueryResult({
    required this.results,
    required this.queryTime,
    required this.queriesExecuted,
    this.metadata = const {},
  });
}

/// **NEW: Query batch for parallel processing**
class QueryBatch {
  final String query;
  final Map<String, dynamic>? filters;
  final int? limit;
  final int? offset;
  final int batchIndex;

  const QueryBatch({
    required this.query,
    this.filters,
    this.limit,
    this.offset,
    required this.batchIndex,
  });

  Map<String, dynamic> toJson() => {
    'query': query,
    'filters': filters,
    'limit': limit,
    'offset': offset,
    'batch_index': batchIndex,
  };
}

/// Database configuration
class DatabaseConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final int maxConnections;
  final Duration connectionTimeout;
  final Duration queryTimeout;

  DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.maxConnections = 10,
    Duration? connectionTimeout,
    Duration? queryTimeout,
  }) : connectionTimeout =
           connectionTimeout ??
           DynamicConfigManager.instance
               .getTimeoutConfig()['connection_pool'] ??
           const Duration(seconds: 30),
       queryTimeout =
           queryTimeout ??
           DynamicConfigManager.instance.getTimeoutConfig()['database_query'] ??
           const Duration(seconds: 60);

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'database': database,
    'username': username,
    'max_connections': maxConnections,
    'connection_timeout_seconds': connectionTimeout.inSeconds,
    'query_timeout_seconds': queryTimeout.inSeconds,
  };
}

/// Database connection pool
class DatabaseConnectionPool {
  final DatabaseConfig config;
  final RAGifyLogger _logger;

  final List<dynamic> _connections = [];
  final Queue<dynamic> _availableConnections = Queue();
  final Map<dynamic, DateTime> _connectionTimestamps = {};

  /// **NEW: Performance monitoring**
  final Map<String, int> _performanceMetrics = {
    'total_queries': 0,
    'parallel_queries': 0,
    'sequential_queries': 0,
    'query_timeouts': 0,
    'connection_waits': 0,
    'batch_queries': 0,
  };

  DatabaseConnectionPool(
    this.config, {
    List<dynamic>? initialConnections,
    RAGifyLogger? logger,
  }) : _logger = logger ?? const RAGifyLogger.disabled() {
    if (initialConnections != null) {
      _connections.addAll(initialConnections);
      _availableConnections.addAll(initialConnections);
      for (final connection in initialConnections) {
        _connectionTimestamps[connection] = DateTime.now();
      }
    }
  }

  /// **NEW: Get performance metrics**
  Map<String, dynamic> getPerformanceMetrics() {
    final avgWaitTime = _performanceMetrics['connection_waits']! > 0
        ? _performanceMetrics['connection_waits']! /
              _performanceMetrics['total_queries']!
        : 0.0;

    return {
      'total_queries': _performanceMetrics['total_queries'],
      'parallel_queries': _performanceMetrics['parallel_queries'],
      'sequential_queries': _performanceMetrics['sequential_queries'],
      'query_timeouts': _performanceMetrics['query_timeouts'],
      'connection_waits': _performanceMetrics['connection_waits'],
      'batch_queries': _performanceMetrics['batch_queries'],
      'average_wait_time_ms': avgWaitTime,
      'parallelization_rate': _performanceMetrics['total_queries']! > 0
          ? '${(_performanceMetrics['parallel_queries']! / _performanceMetrics['total_queries']! * 100).toStringAsFixed(1)}%'
          : '0%',
    };
  }

  /// **NEW: Reset performance metrics**
  void resetPerformanceMetrics() {
    _performanceMetrics.forEach((key, value) => _performanceMetrics[key] = 0);
  }

  /// Get a database connection
  Future<dynamic> getConnection() async {
    final startTime = DateTime.now();

    // Check if we have an available connection
    if (_availableConnections.isNotEmpty) {
      final connection = _availableConnections.removeFirst();
      _connectionTimestamps[connection] = DateTime.now();
      return connection;
    }

    // Create new connection if under limit
    if (_connections.length < config.maxConnections) {
      final connection = await _createConnection();
      _connections.add(connection);
      _connectionTimestamps[connection] = DateTime.now();
      return connection;
    }

    // Wait for a connection to become available
    _performanceMetrics['connection_waits'] =
        _performanceMetrics['connection_waits']! + 1;

    // Use a simple polling approach for now (could be improved with streams)
    while (_availableConnections.isEmpty) {
      await Future.delayed(Duration(milliseconds: 10));

      // Check for timeout
      if (DateTime.now().difference(startTime) > config.connectionTimeout) {
        _performanceMetrics['query_timeouts'] =
            _performanceMetrics['query_timeouts']! + 1;
        throw TimeoutException(
          'Connection acquisition timeout',
          config.connectionTimeout,
        );
      }
    }

    final connection = _availableConnections.removeFirst();
    _connectionTimestamps[connection] = DateTime.now();
    return connection;
  }

  /// Return a connection to the pool
  void returnConnection(dynamic connection) {
    if (_connections.contains(connection)) {
      _availableConnections.add(connection);
    }
  }

  /// Close all connections
  Future<void> close() async {
    for (final connection in _connections) {
      try {
        if (connection is postgres.Connection) {
          await connection.close();
        } else if (connection is mysql.MySqlConnection) {
          await connection.close();
        } else if (connection is Db) {
          await connection.close();
        }
      } catch (e) {
        _logger.e('Error closing connection: $e');
      }
    }

    _connections.clear();
    _availableConnections.clear();
    _connectionTimestamps.clear();
  }

  /// **NEW: Create connection based on database type**
  Future<dynamic> _createConnection() async {
    // This would be implemented based on the database type
    // For now, return a placeholder
    throw UnimplementedError('Connection creation not implemented');
  }

  /// **NEW: Get pool health status**
  Map<String, dynamic> getHealthStatus() {
    final staleConnections = _connectionTimestamps.entries
        .where(
          (entry) =>
              DateTime.now().difference(entry.value) > Duration(minutes: 5),
        )
        .length;

    return {
      'total_connections': _connections.length,
      'available_connections': _availableConnections.length,
      'in_use_connections': _connections.length - _availableConnections.length,
      'stale_connections': staleConnections,
      'pool_utilization': _connections.isNotEmpty
          ? '${((_connections.length - _availableConnections.length) / _connections.length * 100).toStringAsFixed(1)}%'
          : '0%',
      'health_status': staleConnections > _connections.length * 0.5
          ? 'warning'
          : 'healthy',
    };
  }
}

/// Database source implementation
class DatabaseSource implements BaseDataSource {
  @override
  final String name;
  @override
  final SourceType sourceType;
  final DatabaseConfig databaseConfig;
  final String databaseType;
  final CacheManager cacheManager;
  final RAGifyLogger _logger;

  /// **NEW: Parallel query configuration**
  ParallelQueryConfig _parallelConfig = ParallelQueryConfig();

  late DatabaseConnectionPool _connectionPool;
  bool _isInitialized = false;
  final Map<String, dynamic> _metadata = {};
  final Map<String, dynamic> _config = {};

  DatabaseSource({
    required this.name,
    required this.sourceType,
    required this.databaseConfig,
    required this.databaseType,
    required this.cacheManager,
    ParallelQueryConfig? parallelConfig,
    DatabaseConnectionPool? connectionPool, // Inject for testing
    Map<String, dynamic>? metadata,
    RAGifyLogger? logger,
  }) : _logger = logger ?? const RAGifyLogger.disabled() {
    if (parallelConfig != null) {
      _parallelConfig = parallelConfig;
    }

    if (metadata != null) {
      _metadata.addAll(metadata);
    }

    _connectionPool =
        connectionPool ??
        DatabaseConnectionPool(databaseConfig, logger: _logger);
  }

  /// **NEW: Set parallel query configuration**
  void setParallelQueryConfig(ParallelQueryConfig config) {
    _parallelConfig = config;
    _logger.i(
      'Parallel query config updated: ${config.maxConcurrentQueries} concurrent queries, ${config.batchSize} batch size',
    );
  }

  /// **NEW: Get parallel query configuration**
  ParallelQueryConfig getParallelQueryConfig() => _parallelConfig;

  // name and sourceType are already defined as final fields in the class

  @override
  Map<String, dynamic> get config => _config;

  @override
  bool get isActive => _isInitialized;

  @override
  Map<String, dynamic> get metadata => _metadata;

  @override
  ContextSource get source => ContextSource(
    id: name,
    name: name,
    sourceType: sourceType,
    url: null,
    metadata: _metadata,
    lastUpdated: DateTime.now(),
    isActive: _isInitialized,
    privacyLevel: PrivacyLevel.public,
    authorityScore: 1.0,
    freshnessScore: 1.0,
  );

  @override
  Future<void> refresh() async {
    // For database sources, refresh is not typically needed
    // as data is fetched on-demand
    _logger.d('Database source refresh not implemented');
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) {
      return {
        'database_type': databaseType,
        'host': databaseConfig.host,
        'port': databaseConfig.port,
        'database': databaseConfig.database,
        'max_connections': databaseConfig.maxConnections,
        'is_initialized': _isInitialized,
        'connection_pool_size': 0,
        'available_connections': 0,
        'parallel_query_config': _parallelConfig.toJson(),
        'performance_metrics': {},
        'pool_health': {},
      };
    }

    return {
      'database_type': databaseType,
      'host': databaseConfig.host,
      'port': databaseConfig.port,
      'database': databaseConfig.database,
      'max_connections': databaseConfig.maxConnections,
      'is_initialized': _isInitialized,
      'connection_pool_size': _connectionPool._connections.length,
      'available_connections': _connectionPool._availableConnections.length,
      'parallel_query_config': _parallelConfig.toJson(),
      'performance_metrics': _connectionPool.getPerformanceMetrics(),
      'pool_health': _connectionPool.getHealthStatus(),
    };
  }

  @override
  Future<bool> isHealthy() async {
    if (!_isInitialized) return false;

    try {
      final connection = await _connectionPool.getConnection();
      _connectionPool.returnConnection(connection);
      return true;
    } catch (e) {
      _logger.e('Database health check failed: $e');
      return false;
    }
  }

  @override
  Future<SourceStatus> getStatus() async {
    if (!_isInitialized) return SourceStatus.offline;

    final isHealthy = await this.isHealthy();
    if (isHealthy) {
      return SourceStatus.healthy;
    } else {
      return SourceStatus.unhealthy;
    }
  }

  @override
  Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    // Update metadata
    _metadata.addAll(metadata);
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return _config;
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    // Update configuration
    _config.addAll(config);
  }

  /// Initialize the database source
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize connection pool
      await _initializeConnectionPool();

      // Initialize database tables
      await _initializeDatabaseTables();

      _isInitialized = true;
      _logger.i('Database source initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize database source: $e');
      rethrow;
    }
  }

  /// **NEW: Initialize connection pool**
  Future<void> _initializeConnectionPool() async {
    _logger.d('Initializing connection pool for database type: $databaseType');
    _logger.d(
      'Database config: host=${databaseConfig.host}, port=${databaseConfig.port}, database=${databaseConfig.database}',
    );

    // Skip if connections are already injected (for testing)
    if (_connectionPool._connections.isNotEmpty) {
      _logger.i(
        'Connection pool already initialized with ${_connectionPool._connections.length} connections',
      );
      return;
    }

    // Create initial connections
    for (int i = 0; i < databaseConfig.maxConnections; i++) {
      try {
        _logger.d('Creating connection $i of ${databaseConfig.maxConnections}');
        final connection = await _createConnection();
        _connectionPool._connections.add(connection);
        _connectionPool._availableConnections.add(connection);
        _connectionPool._connectionTimestamps[connection] = DateTime.now();
        _logger.d('Successfully created connection $i');
      } catch (e) {
        _logger.w('Failed to create connection $i: $e');
      }
    }

    if (_connectionPool._connections.isEmpty) {
      throw StateError('Failed to create any database connections');
    }

    _logger.i(
      'Connection pool initialized with ${_connectionPool._connections.length} connections',
    );
  }

  /// **NEW: Create database connection based on type**
  Future<dynamic> _createConnection() async {
    _logger.d('Creating connection for database type: $databaseType');
    _logger.d(
      'Host: ${databaseConfig.host}, Port: ${databaseConfig.port}, Database: ${databaseConfig.database}',
    );

    switch (databaseType.toLowerCase()) {
      case 'sqlite':
        return await sqflite_stub.openDatabase(
          databaseConfig.database,
          version: 1,
          onCreate: _onCreateSQLite,
        );
      case 'postgresql':
        _logger.d(
          'Opening PostgreSQL connection to ${databaseConfig.host}:${databaseConfig.port}',
        );
        return postgres.Connection.open(
          postgres.Endpoint(
            host: databaseConfig.host,
            port: databaseConfig.port,
            database: databaseConfig.database,
            username: databaseConfig.username,
            password: databaseConfig.password,
          ),
        );
      case 'mysql':
        _logger.d(
          'Opening MySQL connection to ${databaseConfig.host}:${databaseConfig.port}',
        );
        return await mysql.MySqlConnection.connect(
          mysql.ConnectionSettings(
            host: databaseConfig.host,
            port: databaseConfig.port,
            user: databaseConfig.username,
            password: databaseConfig.password,
            db: databaseConfig.database,
          ),
        );
      case 'mongodb':
        // Create MongoDB connection with authentication
        final connectionString =
            'mongodb://${databaseConfig.username}:${databaseConfig.password}@${databaseConfig.host}:${databaseConfig.port}/${databaseConfig.database}?authSource=${databaseConfig.database}';
        _logger.d('MongoDB connection string: $connectionString');
        final db = await Db.create(connectionString);
        await db.open();
        return db;
      default:
        throw ArgumentError('Unsupported database type: $databaseType');
    }
  }

  /// **NEW: SQLite table creation callback**
  Future<void> _onCreateSQLite(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS context_chunks (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        metadata TEXT,
        source_name TEXT NOT NULL,
        privacy_level TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_content ON context_chunks(content)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_source_name ON context_chunks(source_name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_created_at ON context_chunks(created_at)',
    );
  }

  /// **NEW: Initialize database tables**
  Future<void> _initializeDatabaseTables() async {
    // Skip table initialization if using injected connections (for testing)
    if (_connectionPool._connections.isNotEmpty &&
        _connectionPool._connections.first.runtimeType.toString().contains(
          'Mock',
        )) {
      return;
    }

    final connection = await _connectionPool.getConnection();

    try {
      switch (databaseType.toLowerCase()) {
        case 'sqlite':
          await _initializeSQLiteTables(connection);
          break;
        case 'postgresql':
          await _initializePostgreSQLTables(connection);
          break;
        case 'mysql':
          await _initializeMySQLTables(connection);
          break;
        case 'mongodb':
          await _initializeMongoDBTables(connection);
          break;
      }
    } finally {
      _connectionPool.returnConnection(connection);
    }
  }

  /// **NEW: Initialize SQLite tables**
  Future<void> _initializeSQLiteTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS context_chunks (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        metadata TEXT,
        source_name TEXT NOT NULL,
        privacy_level TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_content ON context_chunks(content)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_source_name ON context_chunks(source_name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_created_at ON context_chunks(created_at)',
    );
  }

  /// **NEW: Initialize PostgreSQL tables**
  Future<void> _initializePostgreSQLTables(postgres.Connection db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS context_chunks (
        id VARCHAR(255) PRIMARY KEY,
        content TEXT NOT NULL,
        metadata JSONB,
        source_name VARCHAR(255) NOT NULL,
        privacy_level VARCHAR(50) NOT NULL,
        created_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_content ON context_chunks USING gin(to_tsvector(\'english\', content))',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_source_name ON context_chunks(source_name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_created_at ON context_chunks(created_at)',
    );
  }

  /// **NEW: Initialize MySQL tables**
  Future<void> _initializeMySQLTables(mysql.MySqlConnection db) async {
    await db.query('''
      CREATE TABLE IF NOT EXISTS context_chunks (
        id VARCHAR(255) PRIMARY KEY,
        content TEXT NOT NULL,
        metadata JSON,
        source_name VARCHAR(255) NOT NULL,
        privacy_level VARCHAR(50) NOT NULL,
        created_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP NOT NULL
      )
    ''');

    // Create indexes for better performance (MySQL doesn't support IF NOT EXISTS for indexes)
    try {
      await db.query(
        'CREATE INDEX idx_content ON context_chunks(content(100))',
      );
    } catch (e) {
      // Index might already exist, ignore error
      _logger.d('Index idx_content might already exist: $e');
    }

    try {
      await db.query(
        'CREATE INDEX idx_source_name ON context_chunks(source_name)',
      );
    } catch (e) {
      // Index might already exist, ignore error
      _logger.d('Index idx_source_name might already exist: $e');
    }

    try {
      await db.query(
        'CREATE INDEX idx_created_at ON context_chunks(created_at)',
      );
    } catch (e) {
      // Index might already exist, ignore error
      _logger.d('Index idx_created_at might already exist: $e');
    }
  }

  /// **NEW: Initialize MongoDB tables**
  Future<void> _initializeMongoDBTables(Db db) async {
    final collection = db.collection('context_chunks');

    // Create indexes for better performance
    await collection.createIndex(keys: {'content': 'text'});
    await collection.createIndex(keys: {'source_name': 1});
    await collection.createIndex(keys: {'created_at': -1});
  }

  @override
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  }) async {
    if (!_isInitialized) {
      _logger.w('Database source not initialized');
      return []; // Return empty list when not initialized
    }

    _logger.i('getChunks called with query: $query');

    // Check if this looks like a SQL query or MongoDB JSON query
    if (query.trim().toUpperCase().startsWith('SELECT') ||
        (query.trim().startsWith('{') && query.trim().endsWith('}'))) {
      _logger.i(
        'Detected custom query (SQL or MongoDB JSON), using custom query execution',
      );
      return await executeCustomQuery(query, maxChunks);
    }

    _logger.i('Using default search approach');
    // Otherwise, use the default search approach
    return await fetchData(query: query, limit: maxChunks);
  }

  /// **NEW: Execute custom SQL query**
  Future<List<ContextChunk>> executeCustomQuery(
    String sqlQuery,
    int? limit,
  ) async {
    if (!_isInitialized) {
      throw StateError('Database source not initialized');
    }

    _logger.i('executeCustomQuery called with: $sqlQuery, limit: $limit');

    try {
      final connection = await _connectionPool.getConnection();
      _logger.i('Got database connection for type: $databaseType');

      try {
        switch (databaseType.toLowerCase()) {
          case 'sqlite':
            _logger.i('Executing SQLite custom query');
            return await _executeCustomSQLiteQuery(
              connection,
              sqlQuery,
              null,
              limit,
              null,
            );
          case 'postgresql':
            _logger.i('Executing PostgreSQL custom query');
            return await _executeCustomPostgreSQLQuery(
              connection,
              sqlQuery,
              null,
              limit,
              null,
            );
          case 'mysql':
            _logger.i('Executing MySQL custom query');
            return await _executeCustomMySQLQuery(
              connection,
              sqlQuery,
              null,
              limit,
              null,
            );
          case 'mongodb':
            _logger.i('Executing MongoDB custom query');
            return await _executeCustomMongoDBQuery(
              connection,
              sqlQuery,
              null,
              limit,
              null,
            );
          default:
            throw ArgumentError('Unsupported database type: $databaseType');
        }
      } finally {
        _connectionPool.returnConnection(connection);
      }
    } catch (e) {
      _logger.e('Error executing custom query: $e');
      return [];
    }
  }

  /// **ENHANCED: Fetch data with parallel processing support**
  Future<List<ContextChunk>> fetchData({
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    if (!_isInitialized) {
      throw StateError('Database source not initialized');
    }

    final stopwatch = Stopwatch()..start();

    try {
      // **NEW: Use parallel processing for complex queries**
      if (_parallelConfig.enableParallelQueries &&
          _shouldUseParallelProcessing(query, filters, limit)) {
        _logger.i('Using parallel processing for complex query');
        final result = await _fetchDataParallel(query, filters, limit, offset);
        _connectionPool._performanceMetrics['parallel_queries'] =
            _connectionPool._performanceMetrics['parallel_queries']! + 1;
        return result.results;
      } else {
        _logger.d('Using sequential processing for simple query');
        final result = await _fetchDataSequential(
          query,
          filters,
          limit,
          offset,
        );
        _connectionPool._performanceMetrics['sequential_queries'] =
            _connectionPool._performanceMetrics['sequential_queries']! + 1;
        return result;
      }
    } catch (e) {
      _logger.e('Error fetching data from database: $e');
      rethrow;
    } finally {
      _connectionPool._performanceMetrics['total_queries'] =
          _connectionPool._performanceMetrics['total_queries']! + 1;
      final queryTime = stopwatch.elapsed;
      _logger.d('Query completed in ${queryTime.inMilliseconds}ms');
    }
  }

  /// **NEW: Determine if parallel processing should be used**
  bool _shouldUseParallelProcessing(
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
  ) {
    // Use parallel processing for:
    // 1. Complex queries with multiple filters
    // 2. Large result sets
    // 3. Full-text search queries

    if (query != null && query.length > 50) return true; // Long queries
    if (filters != null && filters.length > 2) {
      return true; // Multiple filters
    }
    if (limit != null && limit > _parallelConfig.batchSize) {
      return true; // Large result sets
    }

    return false;
  }

  /// **NEW: Fetch data using parallel processing**
  Future<ParallelQueryResult<ContextChunk>> _fetchDataParallel(
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Split the query into batches for parallel processing
    final batches = _createQueryBatches(query, filters, limit, offset);
    final concurrentQueries = math.min(
      batches.length,
      _parallelConfig.maxConcurrentQueries,
    );

    _logger.d(
      'Processing ${batches.length} query batches using $concurrentQueries concurrent queries',
    );

    // Execute queries in parallel
    final futures = <Future<List<ContextChunk>>>[];

    for (int i = 0; i < concurrentQueries; i++) {
      final batch = batches[i];
      final future = _executeQueryBatch(batch);
      futures.add(future);
    }

    // Wait for all queries to complete
    final results = await Future.wait(futures);

    // Merge results from all batches
    final allChunks = <ContextChunk>[];
    for (final batchResult in results) {
      allChunks.addAll(batchResult);
    }

    // Remove duplicates and apply final filtering
    final uniqueChunks = _removeDuplicateChunks(allChunks);
    final finalChunks = _applyFinalFiltering(
      uniqueChunks,
      query,
      filters,
      limit,
    );

    final queryTime = stopwatch.elapsed;

    return ParallelQueryResult<ContextChunk>(
      results: finalChunks,
      queryTime: queryTime,
      queriesExecuted: concurrentQueries,
      metadata: {
        'batch_count': batches.length,
        'total_chunks_found': allChunks.length,
        'final_chunks': finalChunks.length,
        'duplicates_removed': allChunks.length - uniqueChunks.length,
      },
    );
  }

  /// **NEW: Create query batches for parallel processing**
  List<QueryBatch> _createQueryBatches(
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) {
    final batches = <QueryBatch>[];

    if (limit != null && limit > _parallelConfig.batchSize) {
      // Split large queries into batches
      final batchCount = (limit / _parallelConfig.batchSize).ceil();

      for (int i = 0; i < batchCount; i++) {
        final batchLimit = math.min(
          _parallelConfig.batchSize,
          limit - (i * _parallelConfig.batchSize),
        );
        final batchOffset = (offset ?? 0) + (i * _parallelConfig.batchSize);

        batches.add(
          QueryBatch(
            query: query ?? '',
            filters: filters,
            limit: batchLimit,
            offset: batchOffset,
            batchIndex: i,
          ),
        );
      }
    } else {
      // Single batch for smaller queries
      batches.add(
        QueryBatch(
          query: query ?? '',
          filters: filters,
          limit: limit,
          offset: offset,
          batchIndex: 0,
        ),
      );
    }

    return batches;
  }

  /// **NEW: Execute a single query batch**
  Future<List<ContextChunk>> _executeQueryBatch(QueryBatch batch) async {
    final connection = await _connectionPool.getConnection();

    try {
      switch (databaseType.toLowerCase()) {
        case 'sqlite':
          return await _fetchFromSQLite(
            connection,
            batch.query,
            batch.filters,
            batch.limit,
            batch.offset,
          );
        case 'postgresql':
          return await _fetchFromPostgreSQL(
            connection,
            batch.query,
            batch.filters,
            batch.limit,
            batch.offset,
          );
        case 'mysql':
          return await _fetchFromMySQL(
            connection,
            batch.query,
            batch.filters,
            batch.limit,
            batch.offset,
          );
        case 'mongodb':
          return await _fetchFromMongoDB(
            connection,
            batch.query,
            batch.filters,
            batch.limit,
            batch.offset,
          );
        default:
          throw ArgumentError('Unsupported database type: $databaseType');
      }
    } finally {
      _connectionPool.returnConnection(connection);
    }
  }

  /// **NEW: Remove duplicate chunks from batch results**
  List<ContextChunk> _removeDuplicateChunks(List<ContextChunk> chunks) {
    final uniqueChunks = <String, ContextChunk>{};

    for (final chunk in chunks) {
      if (!uniqueChunks.containsKey(chunk.id)) {
        uniqueChunks[chunk.id] = chunk;
      }
    }

    return uniqueChunks.values.toList();
  }

  /// **NEW: Apply final filtering to merged results**
  List<ContextChunk> _applyFinalFiltering(
    List<ContextChunk> chunks,
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
  ) {
    var filteredChunks = chunks;

    // Apply relevance filtering if query exists
    if (query != null && query.isNotEmpty) {
      filteredChunks = filteredChunks.where((chunk) {
        final contentLower = chunk.content.toLowerCase();
        final queryLower = query.toLowerCase();
        return contentLower.contains(queryLower);
      }).toList();
    }

    // Apply source filtering
    if (filters != null && filters['source_name'] != null) {
      filteredChunks = filteredChunks.where((chunk) {
        return chunk.source.name == filters['source_name'];
      }).toList();
    }

    // Apply privacy filtering
    if (filters != null && filters['privacy_level'] != null) {
      filteredChunks = filteredChunks.where((chunk) {
        return chunk.source.privacyLevel.value == filters['privacy_level'];
      }).toList();
    }

    // Apply limit
    if (limit != null && filteredChunks.length > limit) {
      filteredChunks = filteredChunks.take(limit).toList();
    }

    return filteredChunks;
  }

  /// **LEGACY: Sequential data fetching (kept for simple queries)**
  Future<List<ContextChunk>> _fetchDataSequential(
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    final connection = await _connectionPool.getConnection();

    try {
      switch (databaseType.toLowerCase()) {
        case 'sqlite':
          return await _fetchFromSQLite(
            connection,
            query,
            filters,
            limit,
            offset,
          );
        case 'postgresql':
          return await _fetchFromPostgreSQL(
            connection,
            query,
            filters,
            limit,
            offset,
          );
        case 'mysql':
          return await _fetchFromMySQL(
            connection,
            query,
            filters,
            limit,
            offset,
          );
        case 'mongodb':
          return await _fetchFromMongoDB(
            connection,
            query,
            filters,
            limit,
            offset,
          );
        default:
          throw ArgumentError('Unsupported database type: $databaseType');
      }
    } finally {
      _connectionPool.returnConnection(connection);
    }
  }

  /// **NEW: Fetch data from SQLite**
  Future<List<ContextChunk>> _fetchFromSQLite(
    Database db,
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    // If query is provided, use it directly (for custom SQL queries)
    if (query != null && query.isNotEmpty) {
      return await _executeCustomSQLiteQuery(db, query, filters, limit, offset);
    }

    // Otherwise, use the default context_chunks table approach
    String sql = 'SELECT * FROM context_chunks WHERE 1=1';
    final List<dynamic> args = [];

    if (filters != null) {
      if (filters['source_name'] != null) {
        sql += ' AND source_name = ?';
        args.add(filters['source_name']);
      }

      if (filters['privacy_level'] != null) {
        sql += ' AND privacy_level = ?';
        args.add(filters['privacy_level']);
      }
    }

    sql += ' ORDER BY created_at DESC';

    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
    }

    if (offset != null) {
      sql += ' OFFSET ?';
      args.add(offset);
    }

    final results = await db.rawQuery(sql, args);

    return results.map((row) => _mapSQLiteRowToContextChunk(row)).toList();
  }

  /// **NEW: Execute custom SQLite query and map to ContextChunk**
  Future<List<ContextChunk>> _executeCustomSQLiteQuery(
    Database db,
    String sqlQuery,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    try {
      _logger.i('Executing SQLite query: $sqlQuery');

      // For now, we'll execute the query as-is
      // In a real implementation, you'd want to handle parameter substitution
      final results = await db.rawQuery(sqlQuery, []);

      _logger.i('Query returned ${results.length} raw results');

      // Map results to ContextChunk objects
      final chunks = results
          .map<ContextChunk>((row) => _mapGenericSQLiteRowToContextChunk(row))
          .toList();

      _logger.i('Mapped to ${chunks.length} ContextChunk objects');

      return chunks;
    } catch (e) {
      _logger.e('Error executing custom SQLite query: $e');
      return [];
    }
  }

  /// **NEW: Map generic SQLite row to ContextChunk**
  ContextChunk _mapGenericSQLiteRowToContextChunk(Map<String, dynamic> row) {
    // Try to find content in common column names
    String content = '';
    Map<String, dynamic> metadata = {};

    // Look for common content fields
    if (row.containsKey('content')) {
      content = row['content']?.toString() ?? '';
    } else if (row.containsKey('name')) {
      content = row['name']?.toString() ?? '';
    } else if (row.containsKey('description')) {
      content = row['description']?.toString() ?? '';
    } else {
      // Use all fields as content
      content = row.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }

    // Build metadata from all fields
    metadata = Map<String, dynamic>.from(row);

    // Generate a unique ID
    final id = '${DateTime.now().millisecondsSinceEpoch}_${row.hashCode}';

    return ContextChunk(
      id: id,
      content: content,
      metadata: metadata,
      source: ContextSource(
        id: 'database_$name',
        name: name,
        sourceType: SourceType.database,
        url: null,
        metadata: {},
        lastUpdated: DateTime.now(),
        isActive: true,
        privacyLevel: PrivacyLevel.public,
        authorityScore: 1.0,
        freshnessScore: 1.0,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      relevanceScore: RelevanceScore(score: 1.0),
    );
  }

  /// **NEW: Execute custom PostgreSQL query**
  Future<List<ContextChunk>> _executeCustomPostgreSQLQuery(
    postgres.Connection db,
    String sqlQuery,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    try {
      final results = await db.execute(sqlQuery);
      return results
          .map((row) => _mapGenericSQLiteRowToContextChunk(row.toColumnMap()))
          .toList();
    } catch (e) {
      _logger.e('Error executing custom PostgreSQL query: $e');
      return [];
    }
  }

  /// **NEW: Execute custom MySQL query**
  Future<List<ContextChunk>> _executeCustomMySQLQuery(
    mysql.MySqlConnection db,
    String sqlQuery,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    try {
      final results = await db.query(sqlQuery);
      return results
          .map<ContextChunk>(
            (row) => _mapGenericSQLiteRowToContextChunk(row.fields),
          )
          .toList();
    } catch (e) {
      _logger.e('Error executing custom MySQL query: $e');
      return [];
    }
  }

  /// **NEW: Execute custom MongoDB query**
  Future<List<ContextChunk>> _executeCustomMongoDBQuery(
    Db db,
    String jsonQuery,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    try {
      _logger.d('Executing MongoDB query: $jsonQuery');

      // Parse the JSON query
      final Map<String, dynamic> query = jsonDecode(jsonQuery);

      // Determine which collection to query based on the query content
      String collectionName = 'users'; // default
      if (jsonQuery.contains('products') || jsonQuery.contains('category')) {
        collectionName = 'products';
      } else if (jsonQuery.contains('orders') || jsonQuery.contains('status')) {
        collectionName = 'orders';
      }

      final collection = db.collection(collectionName);
      _logger.d('Querying collection: $collectionName');

      // Execute the query
      final results = await collection.find(query).toList();
      _logger.d('Found ${results.length} documents');

      // Debug: Log the first few results
      if (results.isNotEmpty) {
        _logger.d('First result: ${results.first}');
      } else {
        _logger.w('No documents found for query: $query');
        // Let's try a simple query to see if there's any data
        final allDocs = await collection.find({}).toList();
        _logger.d('Total documents in collection: ${allDocs.length}');
        if (allDocs.isNotEmpty) {
          _logger.d('Sample document: ${allDocs.first}');
        }
      }

      // Apply limit and offset
      var finalResults = results;
      if (offset != null && offset > 0) {
        finalResults = finalResults.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        finalResults = finalResults.take(limit).toList();
      }

      // Convert to ContextChunks
      return finalResults
          .map((doc) => _mapMongoDBDocToContextChunk(doc))
          .toList();
    } catch (e) {
      _logger.e('Error executing custom MongoDB query: $e');
      return [];
    }
  }

  /// **NEW: Fetch data from PostgreSQL**
  Future<List<ContextChunk>> _fetchFromPostgreSQL(
    postgres.Connection db,
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    String sql = 'SELECT * FROM context_chunks WHERE 1=1';
    final List<dynamic> args = [];
    int paramIndex = 1;

    if (query != null && query.isNotEmpty) {
      sql += ' AND content ILIKE \$$paramIndex';
      args.add('%$query%');
      paramIndex++;
    }

    if (filters != null) {
      if (filters['source_name'] != null) {
        sql += ' AND source_name = \$$paramIndex';
        args.add(filters['source_name']);
        paramIndex++;
      }

      if (filters['privacy_level'] != null) {
        sql += ' AND privacy_level = \$$paramIndex';
        args.add(filters['privacy_level']);
        paramIndex++;
      }
    }

    sql += ' ORDER BY created_at DESC';

    if (limit != null) {
      sql += ' LIMIT \$$paramIndex';
      args.add(limit);
      paramIndex++;
    }

    if (offset != null) {
      sql += ' OFFSET \$$paramIndex';
      args.add(offset);
      paramIndex++;
    }

    final results = await db.execute(sql, parameters: args);

    return results.map((row) => _mapPostgreSQLRowToContextChunk(row)).toList();
  }

  /// **NEW: Fetch data from MySQL**
  Future<List<ContextChunk>> _fetchFromMySQL(
    mysql.MySqlConnection db,
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    String sql = 'SELECT * FROM context_chunks WHERE 1=1';
    final List<dynamic> args = [];

    if (query != null && query.isNotEmpty) {
      sql += ' AND content LIKE ?';
      args.add('%$query%');
    }

    if (filters != null) {
      if (filters['source_name'] != null) {
        sql += ' AND source_name = ?';
        args.add(filters['source_name']);
      }

      if (filters['privacy_level'] != null) {
        sql += ' AND privacy_level = ?';
        args.add(filters['privacy_level']);
      }
    }

    sql += ' ORDER BY created_at DESC';

    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
    }

    if (offset != null) {
      sql += ' OFFSET ?';
      args.add(offset);
    }

    final results = await db.query(sql, args);

    return results.map((row) => _mapMySQLRowToContextChunk(row)).toList();
  }

  /// **NEW: Fetch data from MongoDB**
  Future<List<ContextChunk>> _fetchFromMongoDB(
    Db db,
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  ) async {
    final collection = db.collection('context_chunks');
    final Map<String, dynamic> mongoQuery = {};

    if (query != null && query.isNotEmpty) {
      mongoQuery['content'] = {'\$regex': query, '\$options': 'i'};
    }

    if (filters != null) {
      if (filters['source_name'] != null) {
        mongoQuery['source_name'] = filters['source_name'];
      }

      if (filters['privacy_level'] != null) {
        mongoQuery['privacy_level'] = filters['privacy_level'];
      }
    }

    final results = await collection.find(mongoQuery).toList();

    // Sort and limit in memory since MongoDB cursor methods aren't available
    var sortedResults = results;
    if (results.isNotEmpty) {
      sortedResults.sort(
        (a, b) => (b['created_at'] as DateTime).compareTo(
          a['created_at'] as DateTime,
        ),
      );
    }

    if (limit != null && sortedResults.length > limit) {
      sortedResults = sortedResults.take(limit).toList();
    }

    if (offset != null && offset < sortedResults.length) {
      sortedResults = sortedResults.skip(offset).toList();
    }

    return sortedResults
        .map((doc) => _mapMongoDBDocToContextChunk(doc))
        .toList();
  }

  /// **NEW: Store context chunks in the database**
  Future<void> storeChunks(List<ContextChunk> chunks) async {
    if (!_isInitialized) {
      throw StateError('Database source not initialized');
    }

    try {
      final connection = await _connectionPool.getConnection();

      try {
        switch (databaseType.toLowerCase()) {
          case 'sqlite':
            await _storeInSQLite(connection, chunks);
            break;
          case 'postgresql':
            await _storeInPostgreSQL(connection, chunks);
            break;
          case 'mysql':
            await _storeInMySQL(connection, chunks);
            break;
          case 'mongodb':
            await _storeInMongoDB(connection, chunks);
            break;
          default:
            throw ArgumentError('Unsupported database type: $databaseType');
        }
      } finally {
        _connectionPool.returnConnection(connection);
      }
    } catch (e) {
      _logger.e('Error storing chunks in database: $e');
      rethrow;
    }
  }

  /// **NEW: Store chunks in SQLite**
  Future<void> _storeInSQLite(Database db, List<ContextChunk> chunks) async {
    final batch = db.batch();

    for (final chunk in chunks) {
      batch.insert(
        'context_chunks',
        {
          'id': chunk.id,
          'content': chunk.content,
          'metadata': jsonEncode(chunk.metadata),
          'source_name': chunk.source.name,
          'privacy_level': chunk.source.privacyLevel.value,
          'created_at': chunk.createdAt.millisecondsSinceEpoch,
          'updated_at': chunk.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: sqflite_stub.ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// **NEW: Store chunks in PostgreSQL**
  Future<void> _storeInPostgreSQL(
    postgres.Connection db,
    List<ContextChunk> chunks,
  ) async {
    for (final chunk in chunks) {
      await db.execute(
        '''
        INSERT INTO context_chunks (id, content, metadata, source_name, privacy_level, created_at, updated_at)
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)
        ON CONFLICT (id) DO UPDATE SET
          content = EXCLUDED.content,
          metadata = EXCLUDED.metadata,
          source_name = EXCLUDED.source_name,
          privacy_level = EXCLUDED.privacy_level,
          updated_at = EXCLUDED.updated_at
      ''',
        parameters: [
          chunk.id,
          chunk.content,
          jsonEncode(chunk.metadata),
          chunk.source.name,
          chunk.source.privacyLevel.value,
          chunk.createdAt,
          chunk.updatedAt,
        ],
      );
    }
  }

  /// **NEW: Store chunks in MySQL**
  Future<void> _storeInMySQL(
    mysql.MySqlConnection db,
    List<ContextChunk> chunks,
  ) async {
    for (final chunk in chunks) {
      await db.query(
        '''
        INSERT INTO context_chunks (id, content, metadata, source_name, privacy_level, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          content = VALUES(content),
          metadata = VALUES(metadata),
          source_name = VALUES(source_name),
          privacy_level = VALUES(privacy_level),
          updated_at = VALUES(updated_at)
      ''',
        [
          chunk.id,
          chunk.content,
          jsonEncode(chunk.metadata),
          chunk.source.name,
          chunk.source.privacyLevel.value,
          chunk.createdAt,
          chunk.updatedAt,
        ],
      );
    }
  }

  /// **NEW: Store chunks in MongoDB**
  Future<void> _storeInMongoDB(Db db, List<ContextChunk> chunks) async {
    final collection = db.collection('context_chunks');

    for (final chunk in chunks) {
      final doc = {
        'id': chunk.id,
        'content': chunk.content,
        'metadata': chunk.metadata,
        'source_name': chunk.source.name,
        'privacy_level': chunk.source.privacyLevel.value,
        'created_at': chunk.createdAt,
        'updated_at': chunk.updatedAt,
      };

      await collection.replaceOne({'id': chunk.id}, doc, upsert: true);
    }
  }

  /// **NEW: Map SQLite row to ContextChunk**
  ContextChunk _mapSQLiteRowToContextChunk(Map<String, dynamic> row) {
    return ContextChunk(
      id: row['id'],
      content: row['content'],
      metadata: row['metadata'] != null ? jsonDecode(row['metadata']) : {},
      source: ContextSource(
        name: row['source_name'],
        sourceType: SourceType.database,
        privacyLevel: PrivacyLevel.fromString(row['privacy_level']),
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']),
      relevanceScore: RelevanceScore(score: 1.0),
    );
  }

  /// **NEW: Map PostgreSQL row to ContextChunk**
  ContextChunk _mapPostgreSQLRowToContextChunk(postgres.ResultRow row) {
    return ContextChunk(
      id: row[0] as String,
      content: row[1] as String,
      metadata: row[2] != null ? jsonDecode(row[2] as String) : {},
      source: ContextSource(
        name: row[3] as String,
        sourceType: SourceType.database,
        privacyLevel: PrivacyLevel.fromString(row[4] as String),
      ),
      createdAt: row[5] as DateTime,
      updatedAt: row[6] as DateTime,
      relevanceScore: RelevanceScore(score: 1.0),
    );
  }

  /// **NEW: Map MySQL row to ContextChunk**
  ContextChunk _mapMySQLRowToContextChunk(mysql.ResultRow row) {
    return ContextChunk(
      id: row[0] as String,
      content: row[1] as String,
      metadata: row[2] != null ? jsonDecode(row[2] as String) : {},
      source: ContextSource(
        name: row[3] as String,
        sourceType: SourceType.database,
        privacyLevel: PrivacyLevel.fromString(row[4] as String),
      ),
      createdAt: row[5] as DateTime,
      updatedAt: row[6] as DateTime,
      relevanceScore: RelevanceScore(score: 1.0),
    );
  }

  /// **NEW: Map MongoDB document to ContextChunk**
  ContextChunk _mapMongoDBDocToContextChunk(Map<String, dynamic> doc) {
    // Generate a unique ID if not present
    final String id =
        doc['_id']?.toString() ??
        doc['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // Create content from the document fields
    final List<String> contentParts = [];
    doc.forEach((key, value) {
      if (key != '_id' && value != null) {
        contentParts.add('$key: $value');
      }
    });
    final String content = contentParts.join(', ');

    // Extract metadata
    final Map<String, dynamic> metadata = Map<String, dynamic>.from(doc);
    metadata.remove('_id');

    return ContextChunk(
      id: id,
      content: content,
      metadata: metadata,
      source: ContextSource(
        name: 'MongoDB Database',
        sourceType: SourceType.database,
        privacyLevel: PrivacyLevel.public,
      ),
      createdAt: doc['created_at'] is DateTime
          ? doc['created_at'] as DateTime
          : DateTime.now(),
      updatedAt: DateTime.now(),
      relevanceScore: RelevanceScore(score: 1.0),
    );
  }

  /// **NEW: Execute a custom SQL query**
  Future<List<Map<String, dynamic>>> executeQuery(
    String sql,
    List<dynamic> params,
  ) async {
    if (!_isInitialized) {
      throw StateError('Database source not initialized');
    }

    try {
      final connection = await _connectionPool.getConnection();

      try {
        switch (databaseType.toLowerCase()) {
          case 'sqlite':
            return await _executeSQLiteQuery(connection, sql, params);
          case 'postgresql':
            return await _executePostgreSQLQuery(connection, sql, params);
          case 'mysql':
            return await _executeMySQLQuery(connection, sql, params);
          case 'mongodb':
            return await _executeMongoDBQuery(connection, sql, params);
          default:
            throw ArgumentError('Unsupported database type: $databaseType');
        }
      } finally {
        _connectionPool.returnConnection(connection);
      }
    } catch (e) {
      _logger.e('Error executing query: $e');
      rethrow;
    }
  }

  /// **NEW: Execute SQLite query**
  Future<List<Map<String, dynamic>>> _executeSQLiteQuery(
    Database db,
    String sql,
    List<dynamic> params,
  ) async {
    final results = await db.rawQuery(sql, params);
    return results;
  }

  /// **NEW: Execute PostgreSQL query**
  Future<List<Map<String, dynamic>>> _executePostgreSQLQuery(
    postgres.Connection db,
    String sql,
    List<dynamic> params,
  ) async {
    final results = await db.execute(sql, parameters: params);
    return results.map((row) => row.toColumnMap()).toList();
  }

  /// **NEW: Execute MySQL query**
  Future<List<Map<String, dynamic>>> _executeMySQLQuery(
    mysql.MySqlConnection db,
    String sql,
    List<dynamic> params,
  ) async {
    final results = await db.query(sql, params);
    // Convert ResultRow to Map<String, dynamic> manually since assoc() doesn't exist
    return results.map((row) {
      final Map<String, dynamic> rowMap = {};
      for (int i = 0; i < row.length; i++) {
        rowMap['column_$i'] = row[i];
      }
      return rowMap;
    }).toList();
  }

  /// **NEW: Execute MongoDB query**
  Future<List<Map<String, dynamic>>> _executeMongoDBQuery(
    Db db,
    String sql,
    List<dynamic> params,
  ) async {
    // MongoDB doesn't use SQL, so we'll parse the query and convert it
    // This is a simplified implementation
    final collection = db.collection('context_chunks');
    final results = await collection.find({}).toList();
    return results;
  }

  @override
  Future<void> close() async {
    if (_isInitialized) {
      await _connectionPool.close();
      _isInitialized = false;
      _logger.i('Database source closed');
    }
  }
}
