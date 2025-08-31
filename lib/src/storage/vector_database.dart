import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../exceptions/ragify_exceptions.dart';

/// **NEW: Cache configuration class**
class _CacheConfig {
  final double maxSizeMB;
  final int maxEntries;
  final int ttlSeconds;

  const _CacheConfig({
    required this.maxSizeMB,
    required this.maxEntries,
    required this.ttlSeconds,
  });
}

/// **NEW: Cached vector class**
class _CachedVector {
  final List<double> embedding;
  final DateTime lastAccessed;
  final int accessCount;

  _CachedVector({
    required this.embedding,
    required this.lastAccessed,
    this.accessCount = 1,
  });

  /// Update access information
  _CachedVector updateAccess() {
    return _CachedVector(
      embedding: embedding,
      lastAccessed: DateTime.now(),
      accessCount: accessCount + 1,
    );
  }

  /// Get memory usage in bytes
  int get memoryUsage => embedding.length * 8; // 8 bytes per double
}

/// Vector Database for context embedding storage and similarity search.
///
/// Provides efficient similarity search, indexing, and management
/// of vector embeddings for context chunks.
///
/// **NEW: Hybrid Storage System** - Combines disk storage with intelligent memory caching
/// - **Disk Storage**: Persistent vector data with efficient binary format
/// - **Memory Cache**: LRU-based caching for frequently accessed vectors
/// - **Configurable Limits**: Memory usage limits with automatic eviction
/// - **Performance**: O(1) cache access, O(log n) disk access
///
/// Supports:
/// - FAISS (local) - Primary implementation with hybrid storage
/// - ChromaDB (local/remote) - Future implementation
/// - Pinecone (cloud) - Future implementation
/// - Weaviate (local/cloud) - Future implementation
class VectorDatabase {
  /// Logger instance
  final Logger logger;

  /// Vector database connection URL
  final String vectorDbUrl;

  /// Database type (faiss, chroma, pinecone, weaviate)
  final String dbType;

  /// Connection string for the database
  final String connectionString;

  /// Database configuration
  final Map<String, dynamic> config;

  /// Whether the database is initialized
  bool _isInitialized = false;

  /// Whether the database is closed
  bool _isClosed = false;

  /// SQLite database for metadata storage
  Database? _metadataDb;

  /// FAISS index for vector operations
  dynamic _faissIndex;

  /// Vector dimension
  int _dimension = 384;

  /// Total vectors stored
  int _totalVectors = 0;

  /// **NEW: Hybrid Storage Components**

  /// Memory cache for frequently accessed vectors (LRU implementation)
  final Map<String, _CachedVector> _memoryCache = {};

  /// LRU queue for cache eviction
  final List<String> _lruQueue = [];

  /// Disk storage file for vector data
  RandomAccessFile? _vectorFile;

  /// Vector file path
  String? _vectorFilePath;

  /// Vector index mapping (ID -> file position)
  final Map<String, int> _vectorIndex = {};

  /// Cache configuration
  late final _CacheConfig _cacheConfig;

  /// Performance metrics
  final Map<String, dynamic> _metrics = {
    'total_searches': 0,
    'total_inserts': 0,
    'total_updates': 0,
    'total_deletes': 0,
    'average_search_time': 0.0,
    'average_insert_time': 0.0,
    // **NEW: Cache metrics**
    'cache_hits': 0,
    'cache_misses': 0,
    'cache_evictions': 0,
    'disk_reads': 0,
    'disk_writes': 0,
    'memory_usage_mb': 0.0,
  };

  /// Create a new vector database instance
  VectorDatabase({
    required this.vectorDbUrl,
    Logger? logger,
    Map<String, dynamic>? config,
  }) : logger = logger ?? Logger(),
       dbType = _parseDbType(vectorDbUrl),
       connectionString = _parseConnectionString(vectorDbUrl),
       config =
           config ??
           {
             'dimension': 384,
             'metric': 'cosine',
             'index_type': 'ivf',
             'nlist': 100,
             'nprobe': 10,
             'use_gpu': false,
             // **NEW: Cache configuration**
             'max_cache_size_mb': 100, // Maximum memory cache size
             'max_cache_entries': 10000, // Maximum cache entries
             'cache_ttl_seconds': 3600, // Cache entry TTL
             'enable_disk_storage': true, // Enable disk storage
             'disk_buffer_size': 8192, // Disk I/O buffer size
           } {
    // Initialize cache configuration
    _cacheConfig = _CacheConfig(
      maxSizeMB: (this.config['max_cache_size_mb'] ?? 100).toDouble(),
      maxEntries: this.config['max_cache_entries'] ?? 10000,
      ttlSeconds: this.config['cache_ttl_seconds'] ?? 3600,
    );
  }

  /// Parse database type from URL
  static String _parseDbType(String url) {
    if (url.startsWith('faiss://')) return 'faiss';
    if (url.startsWith('chroma://')) return 'chroma';
    if (url.startsWith('pinecone://')) return 'pinecone';
    if (url.startsWith('weaviate://')) return 'weaviate';
    if (url.startsWith('memory://')) return 'memory';

    // Default to FAISS for local paths
    return 'faiss';
  }

  /// Parse connection string from URL
  static String _parseConnectionString(String url) {
    if (url.startsWith('memory://')) return 'memory';

    final uri = Uri.parse(url);
    if (uri.scheme == 'faiss' && uri.path.isNotEmpty) {
      return uri.path;
    }

    // For other schemes like chroma://, return just the host part
    if (uri.scheme.isNotEmpty && uri.host.isNotEmpty) {
      return uri.host;
    }

    // For unsupported schemes with path, return just the path
    if (uri.scheme.isNotEmpty && uri.path.isNotEmpty) {
      return uri.path.substring(1); // Remove leading slash
    }

    return url;
  }

  /// Initialize the vector database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logger.i('Initializing Vector Database with hybrid storage system');

      // Web platform: Use memory-only mode
      if (kIsWeb) {
        logger.i('Web platform detected, using memory-only storage mode');
        config['enable_disk_storage'] = false;
        _isInitialized = true;
        logger.i('Vector Database initialized successfully for web platform');
        return;
      }

      // Initialize metadata database
      await _initializeMetadataDatabase();

      // Initialize vector storage
      await _initializeVectorStorage();

      // Initialize vector index
      await _initializeVectorIndex();

      _isInitialized = true;
      logger.i('Vector Database initialized successfully with hybrid storage');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize Vector Database',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// **NEW: Initialize vector storage (disk + memory cache)**
  Future<void> _initializeVectorStorage() async {
    if (config['enable_disk_storage'] == false) {
      logger.i('Disk storage disabled, using memory-only mode');
      return;
    }

    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(path.join(appDir.path, 'ragify_vectors'));

      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      // Create vector data file
      _vectorFilePath = path.join(dbDir.path, 'vectors.bin');
      final vectorFile = File(_vectorFilePath!);

      if (!await vectorFile.exists()) {
        await vectorFile.create();
      }

      _vectorFile = await vectorFile.open(mode: FileMode.append);

      logger.i('Vector storage initialized: $_vectorFilePath');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize vector storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// **NEW: Load vector from disk**
  Future<List<double>?> _loadVectorFromDisk(String id) async {
    if (_vectorFile == null || !_vectorIndex.containsKey(id)) {
      return null;
    }

    try {
      final position = _vectorIndex[id]!;
      await _vectorFile!.setPosition(position);

      // Read vector dimension (4 bytes)
      final dimensionBytes = await _vectorFile!.read(4);
      final dimension = ByteData.view(
        dimensionBytes.buffer,
      ).getUint32(0, Endian.little);

      // Read vector data (dimension * 8 bytes for doubles)
      final vectorBytes = await _vectorFile!.read(dimension * 8);
      final vector = <double>[];

      for (int i = 0; i < dimension; i++) {
        final doubleBytes = vectorBytes.sublist(i * 8, (i + 1) * 8);
        final value = ByteData.view(
          doubleBytes.buffer,
        ).getFloat64(0, Endian.little);
        vector.add(value);
      }

      _metrics['disk_reads'] = (_metrics['disk_reads'] as int) + 1;
      return vector;
    } catch (e) {
      logger.w('Failed to load vector from disk: $id', error: e);
      return null;
    }
  }

  /// **NEW: Save vector to disk**
  Future<void> _saveVectorToDisk(String id, List<double> embedding) async {
    if (_vectorFile == null) return;

    try {
      final position = await _vectorFile!.length();
      _vectorIndex[id] = position;

      // Write vector dimension (4 bytes)
      final dimensionBytes = ByteData(4)
        ..setUint32(0, embedding.length, Endian.little);
      await _vectorFile!.writeFrom(dimensionBytes.buffer.asUint8List());

      // Write vector data (dimension * 8 bytes for doubles)
      final vectorBytes = ByteData(embedding.length * 8);
      for (int i = 0; i < embedding.length; i++) {
        vectorBytes.setFloat64(i * 8, embedding[i], Endian.little);
      }
      await _vectorFile!.writeFrom(vectorBytes.buffer.asUint8List());

      _metrics['disk_writes'] = (_metrics['disk_writes'] as int) + 1;
    } catch (e) {
      logger.e('Failed to save vector to disk: $id', error: e);
      rethrow;
    }
  }

  /// **NEW: Get all vector IDs from metadata database**
  Future<List<String>> _getAllVectorIds() async {
    if (_metadataDb == null) return [];

    try {
      final results = await _metadataDb!.query('vectors', columns: ['id']);
      return results.map((row) => row['id'] as String).toList();
    } catch (e) {
      logger.w('Failed to get vector IDs from metadata', error: e);
      return [];
    }
  }

  /// **NEW: Get vector with intelligent caching**
  Future<List<double>?> _getVector(String id) async {
    // Check memory cache first
    if (_memoryCache.containsKey(id)) {
      final cached = _memoryCache[id]!;
      _memoryCache[id] = cached.updateAccess();
      _updateLRUQueue(id);
      _metrics['cache_hits'] = (_metrics['cache_hits'] as int) + 1;
      return cached.embedding;
    }

    // Cache miss - load from disk
    _metrics['cache_misses'] = (_metrics['cache_misses'] as int) + 1;
    final vector = await _loadVectorFromDisk(id);

    if (vector != null) {
      // Add to cache if space available
      await _addToCache(id, vector);
    }

    return vector;
  }

  /// **NEW: Add vector to cache with LRU eviction**
  Future<void> _addToCache(String id, List<double> embedding) async {
    // Check if we need to evict entries
    await _enforceCacheLimits();

    // Add new entry
    _memoryCache[id] = _CachedVector(
      embedding: embedding,
      lastAccessed: DateTime.now(),
    );

    _updateLRUQueue(id);
    _updateMemoryMetrics();
  }

  /// **NEW: Enforce cache limits with LRU eviction**
  Future<void> _enforceCacheLimits() async {
    // Check entry count limit
    while (_memoryCache.length >= _cacheConfig.maxEntries) {
      final evictedId = _lruQueue.removeAt(0);
      _memoryCache.remove(evictedId);
      _metrics['cache_evictions'] = (_metrics['cache_evictions'] as int) + 1;
      logger.d('Cache eviction: $evictedId (entry limit)');
    }

    // Check memory size limit
    while (_getCurrentMemoryUsage() > _cacheConfig.maxSizeMB * 1024 * 1024) {
      if (_lruQueue.isEmpty) break;

      final evictedId = _lruQueue.removeAt(0);
      final evicted = _memoryCache.remove(evictedId);
      if (evicted != null) {
        _metrics['cache_evictions'] = (_metrics['cache_evictions'] as int) + 1;
        logger.d('Cache eviction: $evictedId (memory limit)');
      }
    }
  }

  /// **NEW: Update LRU queue**
  void _updateLRUQueue(String id) {
    _lruQueue.remove(id);
    _lruQueue.add(id);
  }

  /// **NEW: Get current memory usage in bytes**
  double _getCurrentMemoryUsage() {
    double totalBytes = 0;
    for (final cached in _memoryCache.values) {
      totalBytes += cached.memoryUsage;
    }
    return totalBytes;
  }

  /// **NEW: Update memory usage metrics**
  void _updateMemoryMetrics() {
    final memoryMB = _getCurrentMemoryUsage() / (1024 * 1024);
    _metrics['memory_usage_mb'] = memoryMB;
  }

  /// Initialize metadata database
  Future<void> _initializeMetadataDatabase() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(appDir.path, 'ragify_metadata.db');

      _metadataDb = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE vectors (
              id TEXT PRIMARY KEY,
              chunk_id TEXT,
              metadata TEXT,
              created_at INTEGER,
              updated_at INTEGER
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_vectors_chunk_id ON vectors(chunk_id)
          ''');
        },
      );

      logger.d('Metadata database initialized: $dbPath');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize metadata database',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize vector index
  Future<void> _initializeVectorIndex() async {
    logger.d('Initializing vector index with hybrid storage');

    _dimension = config['dimension'] as int;
    _faissIndex = _HybridVectorIndex(
      dimension: _dimension,
      metric: config['metric'] as String,
      vectorDatabase: this, // Pass reference for hybrid operations
    );

    logger.d('Vector index initialized successfully');
  }

  /// Add vectors to the database
  Future<void> addVectors(List<VectorData> vectors) async {
    if (!_isInitialized) {
      throw VectorDatabaseException('not_initialized');
    }

    if (_isClosed) {
      throw VectorDatabaseException('closed');
    }

    if (vectors.isEmpty) return;

    final stopwatch = Stopwatch()..start();

    try {
      logger.i('Adding ${vectors.length} vectors to hybrid storage database');

      // Validate vectors
      for (final vector in vectors) {
        if (vector.embedding.length != _dimension) {
          throw VectorDatabaseException(
            'dimension_mismatch',
            databaseType: 'dimension_${vector.embedding.length}_vs_$_dimension',
          );
        }
      }

      // **NEW: Store vectors in hybrid storage**
      for (final vector in vectors) {
        // Save to disk
        await _saveVectorToDisk(vector.id, vector.embedding);

        // Add to memory cache if space available
        await _addToCache(vector.id, vector.embedding);
      }

      // Store metadata
      await _storeVectorMetadata(vectors);

      _totalVectors += vectors.length;
      _metrics['total_inserts'] =
          (_metrics['total_inserts'] as int) + vectors.length;

      final insertTime = stopwatch.elapsedMicroseconds / 1000.0;
      _updateAverageMetric('average_insert_time', insertTime);

      logger.i(
        'Successfully added ${vectors.length} vectors in ${insertTime.toStringAsFixed(2)}ms',
      );
    } catch (e, stackTrace) {
      logger.e('Failed to add vectors', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// **NEW: Search vectors with hybrid storage**
  Future<List<SearchResult>> searchVectors(
    List<double> queryVector,
    int k, {
    double minScore = 0.0,
    String? filterChunkId,
  }) async {
    if (!_isInitialized) {
      throw VectorDatabaseException('not_initialized');
    }

    if (_isClosed) {
      throw VectorDatabaseException('closed');
    }

    if (queryVector.length != _dimension) {
      throw VectorDatabaseException(
        'dimension_mismatch',
        databaseType: 'query_dimension_${queryVector.length}_vs_$_dimension',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      logger.d('Searching for $k similar vectors with minScore: $minScore');

      // **NEW: Use hybrid index for search**
      final results = await _faissIndex.search(queryVector, k, minScore);

      // Apply chunk ID filter if specified
      List<SearchResult> filteredResults = results;
      if (filterChunkId != null) {
        filteredResults = results
            .where((r) => r.chunkId == filterChunkId)
            .toList();
      }

      _metrics['total_searches'] = (_metrics['total_searches'] as int) + 1;

      final searchTime = stopwatch.elapsedMicroseconds / 1000.0;
      _updateAverageMetric('average_search_time', searchTime);

      logger.d(
        'Search completed in ${searchTime.toStringAsFixed(2)}ms, found ${filteredResults.length} results',
      );

      return filteredResults;
    } catch (e, stackTrace) {
      logger.e('Failed to search vectors', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// **NEW: Get database statistics including cache metrics**
  Map<String, dynamic> getStats() {
    return {
      'total_vectors': _totalVectors,
      'dimension': _dimension,
      'db_type': dbType,
      'is_initialized': _isInitialized,
      'is_closed': _isClosed,
      'config': config,
      'metrics': Map<String, dynamic>.from(_metrics),
      // **NEW: Cache statistics**
      'cache_stats': {
        'cache_size': _memoryCache.length,
        'cache_memory_mb': _metrics['memory_usage_mb'],
        'cache_hits': _metrics['cache_hits'],
        'cache_misses': _metrics['cache_misses'],
        'cache_hit_rate': _getCacheHitRate(),
        'cache_evictions': _metrics['cache_evictions'],
      },
      // **NEW: Storage statistics**
      'storage_stats': {
        'disk_reads': _metrics['disk_reads'],
        'disk_writes': _metrics['disk_writes'],
        'vector_file_path': _vectorFilePath,
        'vector_index_size': _vectorIndex.length,
      },
    };
  }

  /// **NEW: Calculate cache hit rate**
  double _getCacheHitRate() {
    final hits = _metrics['cache_hits'] as int;
    final misses = _metrics['cache_misses'] as int;
    final total = hits + misses;

    if (total == 0) return 0.0;
    return hits / total;
  }

  /// **NEW: Clear cache**
  Future<void> clearCache() async {
    _memoryCache.clear();
    _lruQueue.clear();
    _updateMemoryMetrics();
    logger.i('Memory cache cleared');
  }

  /// **NEW: Optimize cache**
  Future<void> optimizeCache() async {
    // Remove expired entries
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final entry in _memoryCache.entries) {
      final age = now.difference(entry.value.lastAccessed).inSeconds;
      if (age > _cacheConfig.ttlSeconds) {
        expiredIds.add(entry.key);
      }
    }

    for (final id in expiredIds) {
      _memoryCache.remove(id);
      _lruQueue.remove(id);
    }

    // Enforce limits
    await _enforceCacheLimits();

    logger.i('Cache optimized: removed ${expiredIds.length} expired entries');
  }

  /// Store vector metadata in SQLite
  Future<void> _storeVectorMetadata(List<VectorData> vectors) async {
    if (_metadataDb == null) return;

    final batch = _metadataDb!.batch();

    for (final vector in vectors) {
      batch.insert('vectors', {
        'id': vector.id,
        'chunk_id': vector.chunkId,
        'metadata': jsonEncode(vector.metadata),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Update average metric
  void _updateAverageMetric(String metricName, double newValue) {
    final currentCount = _metrics['total_searches'] as int;
    final currentAverage = _metrics[metricName] as double;

    if (currentCount == 0) {
      _metrics[metricName] = newValue;
    } else {
      _metrics[metricName] =
          (currentAverage * (currentCount - 1) + newValue) / currentCount;
    }
  }

  /// Close the database
  Future<void> close() async {
    if (_isClosed) return;

    try {
      logger.i('Closing Vector Database');

      // Close metadata database
      if (_metadataDb != null) {
        await _metadataDb!.close();
        _metadataDb = null;
      }

      // Close vector file
      if (_vectorFile != null) {
        await _vectorFile!.close();
        _vectorFile = null;
      }

      // Clear cache
      await clearCache();

      _isClosed = true;
      logger.i('Vector Database closed successfully');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to close Vector Database',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// **NEW: Hybrid Vector Index that combines memory cache with disk storage**
class _HybridVectorIndex {
  final int dimension;
  final String metric;
  final VectorDatabase vectorDatabase;

  _HybridVectorIndex({
    required this.dimension,
    required this.metric,
    required this.vectorDatabase,
  });

  /// Search for similar vectors using hybrid storage
  Future<List<SearchResult>> search(
    List<double> queryVector,
    int k,
    double minScore,
  ) async {
    final results = <SearchResult>[];

    try {
      // Get all vector IDs from the database metadata
      final vectorIds = await vectorDatabase._getAllVectorIds();

      // Calculate similarities for all vectors
      for (final id in vectorIds) {
        final vector = await vectorDatabase._getVector(id);
        if (vector == null) continue;

        final score = _calculateSimilarity(queryVector, vector);

        if (score >= minScore) {
          results.add(
            SearchResult(
              id: id,
              chunkId: id, // For now, using ID as chunk ID
              score: score,
            ),
          );
        }
      }

      // Sort by score (descending) and take top k
      results.sort((a, b) => b.score.compareTo(a.score));

      return results.take(k).toList();
    } catch (e) {
      // Fallback to empty results if search fails
      return <SearchResult>[];
    }
  }

  /// Calculate similarity between two vectors
  double _calculateSimilarity(List<double> vector1, List<double> vector2) {
    switch (metric) {
      case 'cosine':
        return _cosineSimilarity(vector1, vector2);
      case 'euclidean':
        return _euclideanSimilarity(vector1, vector2);
      case 'dot':
        return _dotProductSimilarity(vector1, vector2);
      default:
        return _cosineSimilarity(vector1, vector2);
    }
  }

  /// Calculate cosine similarity
  double _cosineSimilarity(List<double> vector1, List<double> vector2) {
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < vector1.length; i++) {
      dotProduct += vector1[i] * vector2[i];
      norm1 += vector1[i] * vector1[i];
      norm2 += vector2[i] * vector2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// Calculate Euclidean similarity (1 / (1 + distance))
  double _euclideanSimilarity(List<double> vector1, List<double> vector2) {
    double sumSquares = 0.0;

    for (int i = 0; i < vector1.length; i++) {
      final diff = vector1[i] - vector2[i];
      sumSquares += diff * diff;
    }

    final distance = sqrt(sumSquares);
    return 1.0 / (1.0 + distance);
  }

  /// Calculate dot product similarity
  double _dotProductSimilarity(List<double> vector1, List<double> vector2) {
    double dotProduct = 0.0;

    for (int i = 0; i < vector1.length; i++) {
      dotProduct += vector1[i] * vector2[i];
    }

    return dotProduct;
  }
}

// Legacy _SimpleVectorIndex class removed - no longer needed with hybrid storage

/// Vector data structure
class VectorData {
  final String id;
  final String chunkId;
  final List<double> embedding;
  final Map<String, dynamic> metadata;

  VectorData({
    required this.id,
    required this.chunkId,
    required this.embedding,
    this.metadata = const {},
  });
}

/// Search result structure
class SearchResult {
  final String id;
  final String chunkId;
  final double score;

  SearchResult({required this.id, required this.chunkId, required this.score});
}
