import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import '../models/context_chunk.dart';
import '../models/context_source.dart';
import '../models/relevance_score.dart';
import '../models/privacy_level.dart';
import 'base_data_source.dart';

/// Document Source for processing various document formats
///
/// Supports PDF, DOCX, TXT, and Markdown files with intelligent
/// chunking and metadata extraction.
class DocumentSource implements BaseDataSource {
  /// Name of the document source
  @override
  final String name;

  /// Type of data source
  @override
  final SourceType sourceType = SourceType.document;

  /// Source configuration
  @override
  final Map<String, dynamic> config;

  /// Source metadata
  @override
  final Map<String, dynamic> metadata;

  /// Whether the source is currently active
  @override
  bool get isActive => _isActive;

  /// Source object representation
  @override
  ContextSource get source => _source;

  /// Logger instance
  final Logger logger;

  /// Document directory path
  final String documentPath;

  /// Supported file extensions
  final Set<String> supportedExtensions = {
    '.txt',
    '.md',
    '.json',
    '.pdf',
    '.docx',
  };

  /// Chunk size in characters
  final int chunkSize;

  /// Chunk overlap in characters
  final int chunkOverlap;

  /// Whether to include metadata in chunks
  final bool includeMetadata;

  /// Internal state
  bool _isActive = true;
  late ContextSource _source;
  final Map<String, List<ContextChunk>> _documentCache = {};

  /// Create a new document source
  DocumentSource({
    required this.name,
    required this.documentPath,
    Logger? logger,
    Map<String, dynamic>? config,
    Map<String, dynamic>? metadata,
    this.chunkSize = 1000,
    this.chunkOverlap = 200,
    this.includeMetadata = true,
  }) : logger = logger ?? Logger(),
       config = config ?? {},
       metadata = metadata ?? {} {
    _source = ContextSource(
      name: name,
      sourceType: sourceType,
      url: documentPath,
      metadata: metadata,
      privacyLevel: PrivacyLevel.private,
      authorityScore: 0.8,
      freshnessScore: 1.0,
    );
  }

  /// Get context chunks from documents
  @override
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  }) async {
    if (!_isActive) {
      throw StateError('Document source is not active');
    }

    try {
      logger.i('Processing documents for query: $query');

      // Get all documents from the directory
      final documents = await _getDocuments();

      // Check if we have any documents
      if (documents.isEmpty) {
        logger.w('No documents found in directory: $documentPath');
        return [];
      }

      // Process documents in parallel for better performance
      final allChunks = <ContextChunk>[];

      if (documents.length > 1) {
        final futures = documents.map(
          (document) => _processDocument(document, query),
        );
        final results = await Future.wait(futures);

        for (final chunks in results) {
          allChunks.addAll(chunks);
        }
      } else {
        // Single document - process directly
        final chunks = await _processDocument(documents.first, query);
        allChunks.addAll(chunks);
      }

      // Filter by relevance if specified
      if (minRelevance > 0.0) {
        allChunks.removeWhere((chunk) {
          final score = chunk.relevanceScore?.score ?? 0.0;
          return score < minRelevance;
        });
      }

      // Limit by max chunks
      if (maxChunks != null && allChunks.length > maxChunks) {
        allChunks.sort(
          (a, b) => (b.relevanceScore?.score ?? 0.0).compareTo(
            a.relevanceScore?.score ?? 0.0,
          ),
        );
        allChunks.removeRange(maxChunks, allChunks.length);
      }

      logger.i('Retrieved ${allChunks.length} chunks from documents');
      return allChunks;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to get chunks from documents',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all documents from the directory
  Future<List<File>> _getDocuments() async {
    final directory = Directory(documentPath);

    if (!await directory.exists()) {
      logger.w('Document directory does not exist: $documentPath');
      return [];
    }

    final files = <File>[];

    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && _isSupportedFile(entity.path)) {
          files.add(entity);
        }
      }
    } catch (e) {
      logger.w('Error listing directory: $e');
    }

    logger.d('Found ${files.length} supported documents');
    if (files.isEmpty) {
      logger.w(
        'No supported documents found. Supported extensions: ${supportedExtensions.join(', ')}',
      );
    }
    return files;
  }

  /// Check if file is supported
  bool _isSupportedFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// Process a single document
  Future<List<ContextChunk>> _processDocument(
    File document,
    String query,
  ) async {
    final documentPath = document.path;
    final cacheKey = '${documentPath}_${query.hashCode}';

    // Check cache first
    if (_documentCache.containsKey(cacheKey)) {
      logger.d('Using cached chunks for: ${path.basename(documentPath)}');
      return _documentCache[cacheKey]!;
    }

    try {
      final content = await _readDocumentContent(document);
      final chunks = _createChunks(content, document, query);

      // Cache the chunks
      _documentCache[cacheKey] = chunks;

      logger.d(
        'Processed document: ${path.basename(documentPath)} -> ${chunks.length} chunks',
      );
      return chunks;
    } catch (e) {
      logger.w('Failed to process document ${path.basename(documentPath)}: $e');
      return [];
    }
  }

  /// Read document content based on file type with buffered reading
  Future<String> _readDocumentContent(File document) async {
    final extension = path.extension(document.path).toLowerCase();

    try {
      switch (extension) {
        case '.txt':
        case '.md':
          return await _readTextFileWithBuffer(document);
        case '.json':
          return await _readJsonFileWithBuffer(document);
        case '.pdf':
          return await _readPdfContent(document);
        case '.docx':
          return await _readDocxContent(document);
        default:
          throw UnsupportedError('Unsupported file type: $extension');
      }
    } catch (e) {
      logger.e('Error reading document ${path.basename(document.path)}: $e');
      rethrow;
    }
  }

  /// Read text files with buffered reading for better performance
  Future<String> _readTextFileWithBuffer(File document) async {
    final fileSize = await document.length();

    // Use buffered reading for large files
    if (fileSize > 1024 * 1024) {
      // 1MB threshold
      return await _readLargeFileWithBuffer(document);
    } else {
      return await document.readAsString();
    }
  }

  /// Read large files with buffered reading to prevent memory issues
  Future<String> _readLargeFileWithBuffer(File document) async {
    final buffer = StringBuffer();

    try {
      await for (final chunk in document.openRead().transform(utf8.decoder)) {
        buffer.write(chunk);
      }
      return buffer.toString();
    } catch (e) {
      logger.e('Error reading large file ${path.basename(document.path)}: $e');
      rethrow;
    }
  }

  /// Read JSON files with buffered reading and validation
  Future<String> _readJsonFileWithBuffer(File document) async {
    final content = await _readTextFileWithBuffer(document);

    try {
      final json = jsonDecode(content);
      return json.toString();
    } catch (e) {
      logger.w('Invalid JSON in file ${path.basename(document.path)}: $e');
      return content; // Return raw content if JSON parsing fails
    }
  }

  /// Read PDF content (placeholder for future implementation)
  Future<String> _readPdfContent(File document) async {
    // TODO: Implement real PDF reading using pdf_text package
    // For now, return a placeholder indicating PDF content
    return 'PDF Document: ${path.basename(document.path)} - Content extraction not yet implemented';
  }

  /// Read DOCX content (placeholder for future implementation)
  Future<String> _readDocxContent(File document) async {
    // TODO: Implement real DOCX reading using docx package
    // For now, return a placeholder indicating DOCX content
    return 'DOCX Document: ${path.basename(document.path)} - Content extraction not yet implemented';
  }

  /// Create chunks from document content
  List<ContextChunk> _createChunks(
    String content,
    File document,
    String query,
  ) {
    final chunks = <ContextChunk>[];
    final words = content.split(RegExp(r'\s+'));

    if (words.length <= chunkSize) {
      // Single chunk for small documents
      chunks.add(_createChunk(content, document, 0, words.length, query));
    } else {
      // Multiple chunks with overlap
      int start = 0;
      // Ensure we always make forward progress even when chunkOverlap >= chunkSize
      final int step = (chunkSize - chunkOverlap) <= 0 ? 1 : (chunkSize - chunkOverlap);

      while (start < words.length) {
        final int end = (start + chunkSize) > words.length ? words.length : (start + chunkSize);
        final chunkWords = words.sublist(start, end);
        final chunkText = chunkWords.join(' ');

        chunks.add(_createChunk(chunkText, document, start, end, query));

        if (end >= words.length) {
          break; // reached the end
        }

        start += step;
      }
    }

    return chunks;
  }

  /// Create a single chunk
  ContextChunk _createChunk(
    String content,
    File document,
    int start,
    int end,
    String query,
  ) {
    final documentName = path.basename(document.path);
    final documentPath = document.path;

    // Calculate relevance score based on query match
    final relevanceScore = _calculateQueryRelevance(content, query);

    // Create metadata
    final metadata = <String, dynamic>{
      'document_name': documentName,
      'document_path': documentPath,
      'chunk_start': start,
      'chunk_end': end,
      'chunk_size': content.length,
      'file_size': document.lengthSync(),
      'last_modified': document.lastModifiedSync(),
    };

    if (includeMetadata) {
      metadata.addAll(this.metadata);
    }

    // Create tags from document path and content
    final tags = <String>[
      'document',
      path.extension(documentPath).toLowerCase().replaceAll('.', ''),
      documentName.toLowerCase(),
    ];

    return ContextChunk(
      content: content,
      source: _source,
      metadata: metadata,
      relevanceScore: relevanceScore,
      tokenCount: content.split(RegExp(r'\s+')).length,
      tags: tags,
    );
  }

  /// Calculate query relevance for a chunk
  RelevanceScore _calculateQueryRelevance(String content, String query) {
    final contentWords = content.toLowerCase().split(RegExp(r'\s+'));
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));

    if (queryWords.isEmpty) return RelevanceScore(score: 0.0);

    int matches = 0;
    for (final queryWord in queryWords) {
      if (contentWords.contains(queryWord)) {
        matches++;
      }
    }

    final score = matches / queryWords.length;
    return RelevanceScore(score: score.clamp(0.0, 1.0));
  }

  /// Refresh the document source
  @override
  Future<void> refresh() async {
    logger.i('Refreshing document source: $name');

    // Clear cache to force reprocessing
    _documentCache.clear();

    // Check if directory still exists
    final directory = Directory(documentPath);
    if (!await directory.exists()) {
      logger.w('Document directory no longer exists: $documentPath');
      _isActive = false;
      return;
    }

    // Update source metadata
    _source = _source.copyWith(lastUpdated: DateTime.now(), isActive: true);

    logger.i('Document source refreshed successfully');
  }

  /// Close the document source
  @override
  Future<void> close() async {
    logger.i('Closing document source: $name');

    _isActive = false;
    _documentCache.clear();

    logger.i('Document source closed');
  }

  /// Get source statistics
  @override
  Future<Map<String, dynamic>> getStats() async {
    final directory = Directory(documentPath);
    int totalFiles = 0;
    int totalSize = 0;

    if (await directory.exists()) {
      try {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File && _isSupportedFile(entity.path)) {
            totalFiles++;
            totalSize += entity.lengthSync();
          }
        }
      } catch (e) {
        logger.w('Error calculating stats: $e');
      }
    }

    return {
      'name': name,
      'type': sourceType.value,
      'document_path': documentPath,
      'total_files': totalFiles,
      'total_size_bytes': totalSize,
      'supported_extensions': supportedExtensions.toList(),
      'chunk_size': chunkSize,
      'chunk_overlap': chunkOverlap,
      'cache_size': _documentCache.length,
      'is_active': _isActive,
      'performance_features': [
        'buffered_reading',
        'parallel_processing',
        'intelligent_caching',
        'large_file_optimization',
      ],
      'total_cached_chunks': _documentCache.values.fold<int>(
        0,
        (sum, chunks) => sum + chunks.length,
      ),
    };
  }

  /// Check if source is healthy
  @override
  Future<bool> isHealthy() async {
    try {
      final directory = Directory(documentPath);
      return await directory.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get source status
  @override
  Future<SourceStatus> getStatus() async {
    if (!_isActive) return SourceStatus.offline;

    final healthy = await isHealthy();
    if (healthy) {
      return SourceStatus.healthy;
    } else {
      return SourceStatus.unhealthy;
    }
  }

  /// Update source metadata
  @override
  Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    this.metadata.addAll(metadata);
    _source = _source.copyWith(metadata: this.metadata);
    logger.d('Updated metadata for source: $name');
  }

  /// Get source configuration
  @override
  Map<String, dynamic> getConfiguration() => config;

  /// Update source configuration
  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    // Update configuration and reinitialize if needed
    this.config.addAll(config);
    logger.d('Updated configuration for source: $name');
  }
}
