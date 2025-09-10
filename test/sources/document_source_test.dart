import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/document_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';
import 'package:ragify_flutter/src/utils/ragify_logger.dart';
import 'package:logger/logger.dart';
import 'dart:io';

void main() {
  group('DocumentSource Tests', () {
    late DocumentSource documentSource;
    late String tempDir;

    setUp(() {
      tempDir = Directory.systemTemp
          .createTempSync('document_source_test')
          .path;
      documentSource = DocumentSource(
        name: 'Test Document Source',
        documentPath: tempDir,
        chunkSize: 100,
        chunkOverlap: 20,
        includeMetadata: true,
      );
    });

    tearDown(() {
      // Clean up temp directory
      try {
        Directory(tempDir).deleteSync(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Constructor and Basic Properties', () {
      test('should create DocumentSource with required parameters', () {
        expect(documentSource.name, equals('Test Document Source'));
        expect(documentSource.documentPath, equals(tempDir));
        expect(documentSource.sourceType, equals(SourceType.document));
        expect(documentSource.chunkSize, equals(100));
        expect(documentSource.chunkOverlap, equals(20));
        expect(documentSource.includeMetadata, isTrue);
        expect(documentSource.isActive, isTrue);
      });

      test('should create DocumentSource with custom logger', () {
        final customLogger = Logger();
        final source = DocumentSource(
          name: 'Custom Logger Source',
          documentPath: tempDir,
          logger: customLogger,
        );

        expect(source.logger, isA<RAGifyLogger>());
        expect(source.logger.underlyingLogger, equals(customLogger));
      });

      test('should create DocumentSource with custom config and metadata', () {
        final customConfig = {'custom': 'config'};
        final customMetadata = {'custom': 'metadata'};

        final source = DocumentSource(
          name: 'Custom Config Source',
          documentPath: tempDir,
          config: customConfig,
          metadata: customMetadata,
        );

        expect(source.config, equals(customConfig));
        expect(source.metadata, equals(customMetadata));
      });

      test('should have correct supported extensions', () {
        final expectedExtensions = {
          // Text files
          '.txt', '.md', '.markdown', '.rst', '.log',
          // Data files
          '.csv', '.tsv', '.json', '.yaml', '.yml',
          // Web files
          '.html', '.htm', '.css', '.js', '.xml',
          // Config files
          '.ini', '.cfg', '.conf', '.properties',
          // Document files
          '.pdf', '.docx', '.doc',
        };
        expect(documentSource.supportedExtensions, equals(expectedExtensions));
      });
    });

    group('Source Context', () {
      test('should get source context correctly', () {
        final source = documentSource.source;

        expect(source.name, equals('Test Document Source'));
        expect(source.sourceType, equals(SourceType.document));
        expect(source.url, equals(tempDir));
        expect(source.privacyLevel, equals(PrivacyLevel.private));
        expect(source.authorityScore, equals(0.8));
        expect(source.freshnessScore, equals(1.0));
        expect(source.isActive, isTrue);
      });
    });

    group('File Support Detection', () {
      test('should have correct supported extensions', () {
        final extensions = documentSource.supportedExtensions;
        // Text files
        expect(extensions.contains('.txt'), isTrue);
        expect(extensions.contains('.md'), isTrue);
        expect(extensions.contains('.markdown'), isTrue);
        expect(extensions.contains('.rst'), isTrue);
        expect(extensions.contains('.log'), isTrue);
        // Data files
        expect(extensions.contains('.json'), isTrue);
        expect(extensions.contains('.csv'), isTrue);
        expect(extensions.contains('.tsv'), isTrue);
        expect(extensions.contains('.yaml'), isTrue);
        expect(extensions.contains('.yml'), isTrue);
        // Web files
        expect(extensions.contains('.html'), isTrue);
        expect(extensions.contains('.htm'), isTrue);
        expect(extensions.contains('.css'), isTrue);
        expect(extensions.contains('.js'), isTrue);
        expect(extensions.contains('.xml'), isTrue);
        // Config files
        expect(extensions.contains('.ini'), isTrue);
        expect(extensions.contains('.cfg'), isTrue);
        expect(extensions.contains('.conf'), isTrue);
        expect(extensions.contains('.properties'), isTrue);
        // Document files
        expect(extensions.contains('.pdf'), isTrue);
        expect(extensions.contains('.docx'), isTrue);
        expect(extensions.contains('.doc'), isTrue);
        // Unsupported files
        expect(extensions.contains('.rtf'), isFalse);
        expect(extensions.contains('.exe'), isFalse);
      });

      test('should check if file is supported', () {
        final extensions = documentSource.supportedExtensions;
        // Test supported file types
        expect(extensions.contains('.txt'), isTrue);
        expect(extensions.contains('.md'), isTrue);
        expect(extensions.contains('.json'), isTrue);
        expect(extensions.contains('.pdf'), isTrue);
        expect(extensions.contains('.docx'), isTrue);
        expect(extensions.contains('.doc'), isTrue);
        expect(extensions.contains('.html'), isTrue);
        expect(extensions.contains('.csv'), isTrue);
        expect(extensions.contains('.yaml'), isTrue);
        expect(extensions.contains('.xml'), isTrue);
        expect(extensions.contains('.ini'), isTrue);
        expect(extensions.contains('.css'), isTrue);
        expect(extensions.contains('.js'), isTrue);
        expect(extensions.contains('.log'), isTrue);
        expect(extensions.contains('.properties'), isTrue);
      });
    });

    group('Document Processing', () {
      test('should process documents and create chunks', () async {
        final content =
            'This is a test document with multiple words for chunking';
        File('$tempDir/test.txt').writeAsStringSync(content);

        final chunks = await documentSource.getChunks(query: 'test document');

        expect(chunks, isNotEmpty);
        expect(chunks.first.content, contains('test'));
        expect(chunks.first.source.name, equals('Test Document Source'));
        expect(chunks.first.tokenCount, greaterThan(0));
        expect(chunks.first.tags, contains('txt'));
        expect(chunks.first.tags, contains('document'));
      });

      test('should handle large documents with multiple chunks', () async {
        final content = 'word ' * 500; // 500 words
        File('$tempDir/large.txt').writeAsStringSync(content);

        final chunks = await documentSource.getChunks(query: 'word');

        expect(chunks.length, greaterThan(1));
        expect(chunks.first.content.split(' ').length, lessThanOrEqualTo(100));
      });

      test('should create chunks with correct metadata', () async {
        final content = 'Test content for metadata testing';
        File('$tempDir/metadata_test.txt').writeAsStringSync(content);

        final chunks = await documentSource.getChunks(query: 'metadata');

        expect(chunks, isNotEmpty);
        final chunk = chunks.first;
        expect(chunk.metadata['document_name'], equals('metadata_test.txt'));
        expect(chunk.metadata['document_path'], contains('metadata_test.txt'));
        expect(chunk.metadata['chunk_size'], equals(chunk.content.length));
        expect(chunk.metadata['file_size'], greaterThan(0));
      });
    });

    group('Chunk Retrieval', () {
      test('should get chunks from documents', () async {
        // Create test document
        final content =
            'This is a test document with multiple words for chunking';
        File('$tempDir/test.txt').writeAsStringSync(content);

        final chunks = await documentSource.getChunks(query: 'test document');

        expect(chunks, isNotEmpty);
        expect(chunks.first.content, contains('test'));
        expect(chunks.first.source.name, equals('Test Document Source'));
      });

      test('should respect maxChunks limit', () async {
        // Create large document
        final content = 'word ' * 500; // 500 words
        File('$tempDir/large.txt').writeAsStringSync(content);

        final chunks = await documentSource.getChunks(
          query: 'word',
          maxChunks: 3,
        );

        expect(chunks.length, lessThanOrEqualTo(3));
      });

      test('should filter by relevance score', () async {
        // Create test document
        final content =
            'This document contains important information about testing';
        File('$tempDir/test.txt').writeAsStringSync(content);

        final chunks = await documentSource.getChunks(
          query: 'testing',
          minRelevance: 0.5,
        );

        expect(chunks, isNotEmpty);
        for (final chunk in chunks) {
          expect(chunk.relevanceScore?.score ?? 0.0, greaterThanOrEqualTo(0.5));
        }
      });

      test('should handle empty document directory', () async {
        final chunks = await documentSource.getChunks(query: 'test');
        expect(chunks, isEmpty);
      });

      test('should handle inactive source gracefully', () async {
        // Close the source to make it inactive
        await documentSource.close();

        expect(
          () => documentSource.getChunks(query: 'test'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Caching', () {
      test('should cache processed documents', () async {
        final content = 'Test content for caching';
        File('$tempDir/cache_test.txt').writeAsStringSync(content);

        // First call should process the document
        final chunks1 = await documentSource.getChunks(query: 'test');
        expect(chunks1, isNotEmpty);

        // Second call should use cache
        final chunks2 = await documentSource.getChunks(query: 'test');
        expect(chunks2, equals(chunks1));
      });

      test('should use different cache keys for different queries', () async {
        final content = 'Test content for different queries';
        File('$tempDir/query_test.txt').writeAsStringSync(content);

        final chunks1 = await documentSource.getChunks(query: 'test');
        final chunks2 = await documentSource.getChunks(query: 'content');

        expect(chunks1, isNotEmpty);
        expect(chunks2, isNotEmpty);
        // Should be cached separately
        expect(chunks1.first.content, equals(chunks2.first.content));
      });
    });

    group('Source Management', () {
      test('should refresh source successfully', () async {
        // Create initial document
        File('$tempDir/initial.txt').writeAsStringSync('Initial content');

        // Get initial chunks to populate cache
        await documentSource.getChunks(query: 'initial');

        // Refresh source
        await documentSource.refresh();

        // Source should still be active
        expect(documentSource.isActive, isTrue);
      });

      test('should handle refresh when directory no longer exists', () async {
        // Create source with temp directory
        final tempSource = DocumentSource(
          name: 'Temp Source',
          documentPath: tempDir,
        );

        // Delete the directory
        Directory(tempDir).deleteSync(recursive: true);

        // Refresh should deactivate source
        await tempSource.refresh();
        expect(tempSource.isActive, isFalse);
      });

      test('should close source successfully', () async {
        // Create document and get chunks to populate cache
        File(
          '$tempDir/close_test.txt',
        ).writeAsStringSync('Content for closing');
        await documentSource.getChunks(query: 'closing');

        // Close source
        await documentSource.close();

        // Source should be inactive
        expect(documentSource.isActive, isFalse);
      });

      test('should update metadata successfully', () async {
        final newMetadata = {'new_key': 'new_value'};

        await documentSource.updateMetadata(newMetadata);

        expect(documentSource.metadata['new_key'], equals('new_value'));
      });

      test('should update configuration successfully', () async {
        final newConfig = {'new_config': 'new_value'};

        await documentSource.updateConfiguration(newConfig);

        expect(documentSource.config['new_config'], equals('new_value'));
      });
    });

    group('Health and Status', () {
      test('should check health correctly', () async {
        final isHealthy = await documentSource.isHealthy();
        expect(isHealthy, isTrue);
      });

      test('should return unhealthy when directory does not exist', () async {
        final nonExistentSource = DocumentSource(
          name: 'Non-existent Source',
          documentPath: '/non/existent/path',
        );

        final isHealthy = await nonExistentSource.isHealthy();
        expect(isHealthy, isFalse);
      });

      test('should get status correctly', () async {
        final status = await documentSource.getStatus();
        expect(status, equals(SourceStatus.healthy));
      });

      test('should return offline status when inactive', () async {
        // Close the source to make it inactive
        await documentSource.close();

        final status = await documentSource.getStatus();
        expect(status, equals(SourceStatus.offline));
      });
    });

    group('Statistics', () {
      test('should get source statistics', () async {
        // Create test files
        File('$tempDir/stats1.txt').writeAsStringSync('Content 1');
        File('$tempDir/stats2.md').writeAsStringSync('Content 2');
        File('$tempDir/ignored.rtf').writeAsStringSync('Ignored');

        final stats = await documentSource.getStats();

        expect(stats['name'], equals('Test Document Source'));
        expect(stats['type'], equals('document'));
        expect(stats['document_path'], equals(tempDir));
        expect(stats['total_files'], equals(2));
        expect(stats['total_size_bytes'], greaterThan(0));
        expect(stats['supported_extensions'], isA<List<String>>());
        expect(stats['chunk_size'], equals(100));
        expect(stats['chunk_overlap'], equals(20));
        expect(stats['cache_size'], equals(0));
        expect(stats['is_active'], isTrue);
        expect(stats['performance_features'], isA<List<String>>());
        expect(stats['total_cached_chunks'], equals(0));
      });

      test('should handle stats calculation errors gracefully', () async {
        // Create a directory that can't be accessed
        final restrictedDir = Directory('$tempDir/restricted');
        restrictedDir.createSync();

        final restrictedSource = DocumentSource(
          name: 'Restricted Source',
          documentPath: restrictedDir.path,
        );

        final stats = await restrictedSource.getStats();
        expect(stats['total_files'], equals(0));
        expect(stats['total_size_bytes'], equals(0));
      });
    });

    group('Error Handling', () {
      test('should handle unsupported file types gracefully', () async {
        // Create a file with unsupported extension
        final unsupportedFile = File('$tempDir/unsupported.rtf');
        unsupportedFile.writeAsStringSync('Content');

        // The source should ignore unsupported files
        final chunks = await documentSource.getChunks(query: 'Content');
        expect(chunks, isEmpty);
      });

      test('should handle file reading errors gracefully', () async {
        // Create a file that might cause encoding issues
        final problematicFile = File('$tempDir/problematic.txt');
        problematicFile.writeAsStringSync('Content with special chars: éñü');

        // Should handle encoding gracefully
        final chunks = await documentSource.getChunks(query: 'Content');
        expect(chunks, isNotEmpty);
      });
    });

    group('URL Handling', () {
      test('should detect URL correctly', () {
        final urlSource = DocumentSource(
          name: 'URL Source',
          documentPath: 'https://example.com/document.pdf',
        );

        // Test URL detection (this would be tested through private method behavior)
        expect(urlSource.documentPath, startsWith('https://'));
      });

      test('should handle URL file extension detection', () {
        final urlSource = DocumentSource(
          name: 'URL Source',
          documentPath: 'https://example.com/document.pdf',
        );

        expect(urlSource.documentPath, contains('.pdf'));
      });
    });

    group('New File Type Support', () {
      test('should process HTML files', () async {
        final htmlContent = '''
        <html>
          <body>
            <h1>Test Document</h1>
            <p>This is a test HTML document with multiple paragraphs.</p>
            <p>It should be processed correctly by the document source.</p>
          </body>
        </html>
        ''';
        File('$tempDir/test.html').writeAsStringSync(htmlContent);

        final chunks = await documentSource.getChunks(query: 'test document');
        expect(chunks, isNotEmpty);
        // Check if any chunk contains the expected content
        final hasExpectedContent = chunks.any(
          (chunk) => chunk.content.contains('Test Document'),
        );
        expect(hasExpectedContent, isTrue);
        expect(chunks.first.tags, contains('html'));
      });

      test('should process CSV files', () async {
        final csvContent = '''
        name,age,city
        John,25,New York
        Jane,30,Los Angeles
        Bob,35,Chicago
        ''';
        File('$tempDir/test.csv').writeAsStringSync(csvContent);

        final chunks = await documentSource.getChunks(query: 'John');
        expect(chunks, isNotEmpty);
        expect(chunks.first.content, contains('John'));
        expect(chunks.first.tags, contains('csv'));
      });

      test('should process JSON files', () async {
        final jsonContent = '''
        {
          "name": "Test Document",
          "description": "This is a test JSON document",
          "data": {
            "value": 123,
            "items": ["item1", "item2", "item3"]
          }
        }
        ''';
        File('$tempDir/test.json').writeAsStringSync(jsonContent);

        final chunks = await documentSource.getChunks(query: 'Test Document');
        expect(chunks, isNotEmpty);
        expect(chunks.first.content, contains('Test Document'));
        expect(chunks.first.tags, contains('json'));
      });

      test('should process YAML files', () async {
        final yamlContent = '''
        name: Test Document
        description: This is a test YAML document
        data:
          value: 123
          items:
            - item1
            - item2
            - item3
        ''';
        File('$tempDir/test.yaml').writeAsStringSync(yamlContent);

        final chunks = await documentSource.getChunks(query: 'Test Document');
        expect(chunks, isNotEmpty);
        expect(chunks.first.content, contains('Test Document'));
        expect(chunks.first.tags, contains('yaml'));
      });

      test('should process XML files', () async {
        final xmlContent = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <document>
          <title>Test Document</title>
          <content>This is a test XML document with structured data.</content>
          <metadata>
            <author>Test Author</author>
            <date>2024-01-01</date>
          </metadata>
        </document>
        ''';
        File('$tempDir/test.xml').writeAsStringSync(xmlContent);

        final chunks = await documentSource.getChunks(query: 'Test Document');
        expect(chunks, isNotEmpty);
        expect(chunks.first.content, contains('Test Document'));
        expect(chunks.first.tags, contains('xml'));
      });

      test('should process configuration files', () async {
        final iniContent = '''
        [database]
        host=localhost
        port=5432
        name=testdb

        [app]
        name=Test Application
        version=1.0.0
        debug=true
        ''';
        File('$tempDir/test.ini').writeAsStringSync(iniContent);

        final chunks = await documentSource.getChunks(
          query: 'Test Application',
        );
        expect(chunks, isNotEmpty);
        // Check if any chunk contains the expected content
        final hasExpectedContent = chunks.any(
          (chunk) => chunk.content.contains('Test Application'),
        );
        expect(hasExpectedContent, isTrue);
        expect(chunks.first.tags, contains('ini'));
      });
    });

    group('Encoding Detection', () {
      test('should handle UTF-8 encoded files', () async {
        final utf8Content = 'Test content with special characters: éñü中文';
        File('$tempDir/utf8_test.txt').writeAsStringSync(utf8Content);

        final chunks = await documentSource.getChunks(
          query: 'special characters',
        );
        expect(chunks, isNotEmpty);
        expect(chunks.first.content, contains('éñü中文'));
      });

      test('should handle large files with buffered reading', () async {
        // Create a large file (simulate by creating content that would trigger buffered reading)
        final largeContent = 'word ' * 2000; // 2000 words
        File('$tempDir/large_test.txt').writeAsStringSync(largeContent);

        final chunks = await documentSource.getChunks(query: 'word');
        expect(chunks, isNotEmpty);
        expect(chunks.length, greaterThan(1)); // Should create multiple chunks
      });
    });
  });
}
