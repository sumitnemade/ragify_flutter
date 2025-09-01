import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/document_source.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';

void main() {
  group('DocumentSource Coverage Tests', () {
    late String tempDir;
    late DocumentSource source;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('doc_coverage').path;
      source = DocumentSource(name: 'coverage_docs', documentPath: tempDir);
    });

    tearDown(() {
      try {
        Directory(tempDir).deleteSync(recursive: true);
      } catch (_) {}
    });

    group('Error Handling Coverage', () {
      test('handles getChunks with malformed files', () async {
        // Create a file with invalid content that might cause processing errors
        final invalidFile = File('$tempDir/invalid.json');
        await invalidFile.writeAsString('{ this is not valid json }');
        
        // This should handle the error gracefully
        final chunks = await source.getChunks(query: 'test');
        expect(chunks, isA<List>());
      });

      test('handles non-existent directory in _getDocuments', () async {
        final nonExistentSource = DocumentSource(
          name: 'non_existent', 
          documentPath: '$tempDir/does_not_exist'
        );
        
        final chunks = await nonExistentSource.getChunks(query: 'test');
        // This covers lines 173-174: logger.w() and return []
        expect(chunks, isEmpty);
      });

      test('handles empty directory gracefully', () async {
        // Create an empty subdirectory
        final subDir = Directory('$tempDir/empty');
        await subDir.create();
        
        final chunks = await source.getChunks(query: 'test');
        // Should handle empty directory gracefully
        expect(chunks, isA<List>());
      });

      test('handles very large files gracefully', () async {
        // Create a very large text file to test buffer limits
        final largeFile = File('$tempDir/large.txt');
        final largeContent = 'A' * 10000; // 10KB of 'A's
        await largeFile.writeAsString(largeContent);
        
        final chunks = await source.getChunks(query: 'test');
        // Should handle large files without issues
        expect(chunks, isA<List>());
      });

      test('handles unsupported file type error', () async {
        final unsupportedFile = File('$tempDir/test.xyz');
        await unsupportedFile.writeAsString('content');
        
        final chunks = await source.getChunks(query: 'test');
        // This covers line 251: UnsupportedError and line 254: logger.e() in catch
        expect(chunks, isA<List>());
      });
    });

    group('Metadata and Configuration Coverage', () {
      test('covers updateMetadata with new values', () {
        final initialMetadata = Map<String, dynamic>.from(source.metadata);
        
        source.updateMetadata({'new_key': 'new_value', 'count': 42});
        
        expect(source.metadata, containsPair('new_key', 'new_value'));
        expect(source.metadata, containsPair('count', 42));
        // This covers lines that update metadata
      });

      test('covers configuration getters and setters', () {
        final config = source.getConfiguration();
        expect(config, isA<Map<String, dynamic>>());
        
        source.updateConfiguration({'setting': 'value'});
        final updatedConfig = source.getConfiguration();
        expect(updatedConfig, containsPair('setting', 'value'));
      });
    });

    group('Cache and Performance Coverage', () {
      test('covers cache operations and statistics', () async {
        // Create a test file
        final testFile = File('$tempDir/cache_test.txt');
        await testFile.writeAsString('This is test content for caching');
        
        // First call should populate cache
        final chunks1 = await source.getChunks(query: 'test');
        expect(chunks1, isNotEmpty);
        
        // Second call should use cache
        final chunks2 = await source.getChunks(query: 'test');
        expect(chunks2, isNotEmpty);
        
        // Get statistics to cover stats methods
        final stats = await source.getStats();
        expect(stats, containsPair('total_cached_chunks', isA<int>()));
        expect(stats, containsPair('total_files', isA<int>()));
      });

      test('covers refresh functionality', () async {
        // Create initial file
        final testFile = File('$tempDir/refresh_test.txt');
        await testFile.writeAsString('initial content');
        
        final initialChunks = await source.getChunks(query: 'test');
        expect(initialChunks, isNotEmpty);
        
        // Add another file
        final newFile = File('$tempDir/new_file.txt');
        await newFile.writeAsString('new content');
        
        // Refresh should detect new file
        await source.refresh();
        
        final refreshedChunks = await source.getChunks(query: 'test');
        expect(refreshedChunks.length, greaterThanOrEqualTo(initialChunks.length));
      });
    });

    group('Edge Cases Coverage', () {
      test('covers empty query handling', () async {
        final testFile = File('$tempDir/empty_query.txt');
        await testFile.writeAsString('content for empty query test');
        
        final chunks = await source.getChunks(query: '');
        expect(chunks, isA<List>());
      });

      test('covers maxChunks parameter', () async {
        // Create multiple files to generate multiple chunks
        for (int i = 0; i < 5; i++) {
          final file = File('$tempDir/file_$i.txt');
          await file.writeAsString('Content for file $i. This is some test content that should generate chunks.');
        }
        
        final allChunks = await source.getChunks(query: 'test');
        final limitedChunks = await source.getChunks(query: 'test', maxChunks: 2);
        
        expect(limitedChunks.length, lessThanOrEqualTo(2));
        expect(limitedChunks.length, lessThanOrEqualTo(allChunks.length));
      });

      test('covers minRelevance filtering', () async {
        final testFile = File('$tempDir/relevance_test.txt');
        await testFile.writeAsString('This content has varying relevance to different queries');
        
        final highRelevanceChunks = await source.getChunks(
          query: 'content', 
          minRelevance: 0.1
        );
        
        final lowRelevanceChunks = await source.getChunks(
          query: 'xyz_nonexistent', 
          minRelevance: 0.9
        );
        
        expect(highRelevanceChunks.length, greaterThanOrEqualTo(lowRelevanceChunks.length));
      });
    });

    group('File Type Specific Coverage', () {
      test('covers JSON file processing with invalid JSON', () async {
        // Create invalid JSON file
        final invalidJsonFile = File('$tempDir/invalid.json');
        await invalidJsonFile.writeAsString('{ invalid json content }');
        
        final chunks = await source.getChunks(query: 'test');
        // Should handle gracefully and return empty or process as text
        expect(chunks, isA<List>());
      });

      test('covers markdown file processing', () async {
        final mdFile = File('$tempDir/test.md');
        await mdFile.writeAsString('''
# Test Markdown
This is a **markdown** file with *formatting*.
- List item 1
- List item 2
        ''');
        
        final chunks = await source.getChunks(query: 'markdown');
        expect(chunks, isNotEmpty);
        expect(chunks.first.content, contains('markdown'));
      });
    });

    group('Health and Status Coverage', () {
      test('covers health check functionality', () async {
        final isHealthy = await source.isHealthy();
        expect(isHealthy, isA<bool>());
        
        final status = await source.getStatus();
        expect(status, isA<SourceStatus>());
      });

      test('covers close functionality', () async {
        await source.close();
        expect(source.isActive, isFalse);
        
        // After closing, operations should throw StateError
        expect(
          () => source.getChunks(query: 'test'),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
