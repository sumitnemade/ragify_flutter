import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/context_chunk.dart';
import '../models/context_response.dart';
import '../models/context_source.dart';
import '../models/relevance_score.dart';
import '../models/privacy_level.dart';
import '../exceptions/ragify_exceptions.dart';

/// Context Storage Engine
///
/// Handles persistent storage, caching, and vector database operations
/// for context chunks and responses with privacy controls.
class ContextStorageEngine {
  /// Logger instance
  final Logger logger;

  /// Database instance for persistent storage
  Database? _database;

  /// Cache for in-memory storage
  final Map<String, dynamic> _memoryCache = {};

  /// Cache TTL in milliseconds
  final int cacheTtl;

  /// Maximum cache size
  final int maxCacheSize;

  /// Storage directory for files
  Directory? _storageDir;

  /// Whether the engine is initialized
  bool _isInitialized = false;

  /// Create a new storage engine
  ContextStorageEngine({
    Logger? logger,
    this.cacheTtl = 3600000, // 1 hour in milliseconds
    this.maxCacheSize = 1000,
  }) : logger = logger ?? Logger();

  /// Initialize the storage engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logger.i('Initializing Context Storage Engine');

      // Web platform: Use in-memory storage only
      if (kIsWeb) {
        logger.i('Web platform detected, using in-memory storage mode');
        _isInitialized = true;
        logger.i(
          'Context Storage Engine initialized successfully for web platform',
        );
        return;
      }

      // Initialize database
      await _initializeDatabase();

      // Initialize storage directory
      await _initializeStorageDirectory();

      // Initialize cache cleanup
      _startCacheCleanup();

      _isInitialized = true;
      logger.i('Context Storage Engine initialized successfully');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize storage engine',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize SQLite database
  Future<void> _initializeDatabase() async {
    // Web platform doesn't support SQLite
    if (kIsWeb) {
      logger.i('Web platform detected, skipping SQLite initialization');
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDir.path, 'ragify_context.db');

      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _onDatabaseCreate,
        onUpgrade: _onDatabaseUpgrade,
      );

      logger.d('Database initialized at: $dbPath');
    } catch (e) {
      logger.e('Failed to initialize database: $e');
      rethrow;
    }
  }

  /// Initialize storage directory for files
  Future<void> _initializeStorageDirectory() async {
    // Web platform doesn't support file system operations
    if (kIsWeb) {
      logger.i('Web platform detected, skipping file system initialization');
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      _storageDir = Directory(path.join(documentsDir.path, 'ragify_storage'));

      if (!await _storageDir!.exists()) {
        await _storageDir!.create(recursive: true);
      }

      logger.d('Storage directory initialized at: ${_storageDir!.path}');
    } catch (e) {
      logger.e('Failed to initialize storage directory: $e');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _onDatabaseCreate(Database db, int version) async {
    // Context chunks table
    await db.execute('''
      CREATE TABLE context_chunks (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        source_id TEXT NOT NULL,
        source_name TEXT NOT NULL,
        source_type TEXT NOT NULL,
        metadata TEXT,
        relevance_score REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        token_count INTEGER,
        tags TEXT,
        privacy_level TEXT NOT NULL
      )
    ''');

    // Context responses table
    await db.execute('''
      CREATE TABLE context_responses (
        id TEXT PRIMARY KEY,
        query TEXT NOT NULL,
        user_id TEXT,
        session_id TEXT,
        max_tokens INTEGER NOT NULL,
        privacy_level TEXT NOT NULL,
        created_at TEXT NOT NULL,
        processing_time_ms INTEGER
      )
    ''');

    // Response chunks mapping table
    await db.execute('''
      CREATE TABLE response_chunks (
        response_id TEXT NOT NULL,
        chunk_id TEXT NOT NULL,
        chunk_order INTEGER NOT NULL,
        FOREIGN KEY (response_id) REFERENCES context_responses (id),
        FOREIGN KEY (chunk_id) REFERENCES context_chunks (id),
        PRIMARY KEY (response_id, chunk_id)
      )
    ''');

    // Create indexes for performance
    await db.execute(
      'CREATE INDEX idx_chunks_source ON context_chunks (source_id)',
    );
    await db.execute(
      'CREATE INDEX idx_chunks_privacy ON context_chunks (privacy_level)',
    );
    await db.execute(
      'CREATE INDEX idx_chunks_created ON context_chunks (created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_responses_user ON context_responses (user_id)',
    );

    logger.d('Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onDatabaseUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    logger.i('Upgrading database from version $oldVersion to $newVersion');
    // Add upgrade logic here when needed
  }

  /// Store context chunks
  Future<void> storeChunks(List<ContextChunk> chunks) async {
    if (!_isInitialized) await initialize();

    try {
      final batch = _database!.batch();

      for (final chunk in chunks) {
        batch.insert('context_chunks', {
          'id': chunk.id,
          'content': chunk.content,
          'source_id': chunk.source.id,
          'source_name': chunk.source.name,
          'source_type': chunk.source.sourceType.value,
          'metadata': jsonEncode(chunk.metadata),
          'relevance_score': chunk.relevanceScore?.score,
          'created_at': chunk.createdAt.toIso8601String(),
          'updated_at': chunk.updatedAt.toIso8601String(),
          'token_count': chunk.tokenCount,
          'tags': jsonEncode(chunk.tags),
          'privacy_level': chunk.source.privacyLevel.value,
        });
      }

      await batch.commit(noResult: true);
      logger.i('Stored ${chunks.length} context chunks');
    } catch (e, stackTrace) {
      logger.e('Failed to store chunks', error: e, stackTrace: stackTrace);
      throw VectorDatabaseException('store_chunks', databaseType: 'SQLite');
    }
  }

  /// Store context response
  Future<void> storeResponse(ContextResponse response) async {
    if (!_isInitialized) await initialize();

    try {
      // Store response
      await _database!.insert('context_responses', {
        'id': response.id,
        'query': response.query,
        'user_id': response.userId,
        'session_id': response.sessionId,
        'max_tokens': response.maxTokens,
        'privacy_level': response.privacyLevel.value,
        'created_at': response.createdAt.toIso8601String(),
        'processing_time_ms': response.processingTimeMs,
      });

      // Store chunk mappings
      final batch = _database!.batch();
      for (int i = 0; i < response.chunks.length; i++) {
        batch.insert('response_chunks', {
          'response_id': response.id,
          'chunk_id': response.chunks[i].id,
          'chunk_order': i,
        });
      }
      await batch.commit(noResult: true);

      logger.i('Stored context response: ${response.id}');
    } catch (e, stackTrace) {
      logger.e('Failed to store response', error: e, stackTrace: stackTrace);
      throw VectorDatabaseException('store_response', databaseType: 'SQLite');
    }
  }

  /// Retrieve context chunks by query
  Future<List<ContextChunk>> retrieveChunks({
    required String query,
    int? maxChunks,
    double? minRelevance,
    String? userId,
    PrivacyLevel? privacyLevel,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Check cache first
      final cacheKey = _generateCacheKey('chunks', query, userId, privacyLevel);
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        logger.d('Retrieved ${cached.length} chunks from cache');
        return cached;
      }

      // Build query
      var sql = '''
        SELECT * FROM context_chunks 
        WHERE privacy_level = ?
      ''';

      final args = <dynamic>[privacyLevel?.value ?? PrivacyLevel.private.value];

      if (minRelevance != null) {
        sql += ' AND relevance_score >= ?';
        args.add(minRelevance);
      }

      sql += ' ORDER BY relevance_score DESC, created_at DESC';

      if (maxChunks != null) {
        sql += ' LIMIT ?';
        args.add(maxChunks);
      }

      // Execute query
      final results = await _database!.rawQuery(sql, args);

      // Convert to ContextChunk objects
      final chunks = await _convertDatabaseResultsToChunks(results);

      // Cache results
      _setCache(cacheKey, chunks);

      logger.i('Retrieved ${chunks.length} chunks from database');
      return chunks;
    } catch (e, stackTrace) {
      logger.e('Failed to retrieve chunks', error: e, stackTrace: stackTrace);
      throw VectorDatabaseException('retrieve_chunks', databaseType: 'SQLite');
    }
  }

  /// Convert database results to ContextChunk objects
  Future<List<ContextChunk>> _convertDatabaseResultsToChunks(
    List<Map<String, dynamic>> results,
  ) async {
    final chunks = <ContextChunk>[];

    for (final row in results) {
      try {
        final source = ContextSource(
          id: row['source_id'] as String,
          name: row['source_name'] as String,
          sourceType: SourceType.fromString(row['source_type'] as String),
          privacyLevel: PrivacyLevel.fromString(row['privacy_level'] as String),
          metadata: jsonDecode(row['metadata'] as String? ?? '{}'),
          lastUpdated: DateTime.parse(row['updated_at'] as String),
          isActive: true,
          authorityScore: 0.5,
          freshnessScore: 1.0,
        );

        final chunk = ContextChunk(
          id: row['id'] as String,
          content: row['content'] as String,
          source: source,
          metadata: jsonDecode(row['metadata'] as String? ?? '{}'),
          relevanceScore: row['relevance_score'] != null
              ? RelevanceScore(score: row['relevance_score'] as double)
              : null,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          tokenCount: row['token_count'] as int?,
          tags: List<String>.from(jsonDecode(row['tags'] as String? ?? '[]')),
        );

        chunks.add(chunk);
      } catch (e) {
        logger.w('Failed to convert database row to chunk: $e');
        continue;
      }
    }

    return chunks;
  }

  /// Generate cache key
  String _generateCacheKey(
    String type,
    String query,
    String? userId,
    PrivacyLevel? privacyLevel,
  ) {
    return '${type}_${query.hashCode}_${userId ?? 'anonymous'}_${privacyLevel?.value ?? 'private'}';
  }

  /// Get value from cache
  dynamic _getFromCache(String key) {
    final cached = _memoryCache[key];
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as int;
    if (DateTime.now().millisecondsSinceEpoch - timestamp > cacheTtl) {
      _memoryCache.remove(key);
      return null;
    }

    return cached['data'];
  }

  /// Set value in cache
  void _setCache(String key, dynamic data) {
    // Implement LRU cache eviction
    if (_memoryCache.length >= maxCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Start cache cleanup timer
  void _startCacheCleanup() {
    Timer.periodic(Duration(minutes: 5), (timer) {
      _cleanupExpiredCache();
    });
  }

  /// Clean up expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = _memoryCache.entries
        .where((entry) => now - entry.value['timestamp'] > cacheTtl)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      logger.d('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Clear all cached data
  void clearCache() {
    _memoryCache.clear();
    logger.i('Cache cleared');
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) await initialize();

    try {
      final chunkCount =
          Sqflite.firstIntValue(
            await _database!.rawQuery('SELECT COUNT(*) FROM context_chunks'),
          ) ??
          0;

      final responseCount =
          Sqflite.firstIntValue(
            await _database!.rawQuery('SELECT COUNT(*) FROM context_responses'),
          ) ??
          0;

      return {
        'total_chunks': chunkCount,
        'total_responses': responseCount,
        'cache_size': _memoryCache.length,
        'cache_ttl_ms': cacheTtl,
        'max_cache_size': maxCacheSize,
        'is_initialized': _isInitialized,
      };
    } catch (e) {
      logger.w('Failed to get storage stats: $e');
      return {'error': e.toString(), 'is_initialized': _isInitialized};
    }
  }

  /// Close the storage engine
  Future<void> close() async {
    if (!_isInitialized) return;

    try {
      await _database?.close();
      _memoryCache.clear();
      _isInitialized = false;
      logger.i('Context Storage Engine closed');
    } catch (e) {
      logger.w('Error closing storage engine: $e');
    }
  }
}
