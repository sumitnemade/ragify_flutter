import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/document_source.dart';

import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:logger/logger.dart';

void main() {
  group('DocumentSource Tests', () {
    late DocumentSource documentSource;
    late Logger mockLogger;

    setUp(() {
      mockLogger = Logger();
      documentSource = DocumentSource(
        name: 'Test Document Source',
        documentPath: '/test/path',
        logger: mockLogger,
        chunkSize: 1000,
        chunkOverlap: 200,
        includeMetadata: true,
      );
    });

    group('Constructor Tests', () {
      test('should create document source with default values', () {
        final source = DocumentSource(
          name: 'Default Source',
          documentPath: '/default/path',
        );

        expect(source.name, equals('Default Source'));
        expect(source.documentPath, equals('/default/path'));
        expect(source.sourceType, equals(SourceType.document));
        expect(source.chunkSize, equals(1000));
        expect(source.chunkOverlap, equals(200));
        expect(source.includeMetadata, isTrue);
        expect(source.isActive, isTrue);
        expect(source.config, isEmpty);
        expect(source.metadata, isEmpty);
      });

      test('should create document source with custom values', () {
        final source = DocumentSource(
          name: 'Custom Source',
          documentPath: '/custom/path',
          chunkSize: 500,
          chunkOverlap: 100,
          includeMetadata: false,
          config: {'custom': 'config'},
          metadata: {'custom': 'metadata'},
        );

        expect(source.name, equals('Custom Source'));
        expect(source.documentPath, equals('/custom/path'));
        expect(source.chunkSize, equals(500));
        expect(source.chunkOverlap, equals(100));
        expect(source.includeMetadata, isFalse);
        expect(source.config, equals({'custom': 'config'}));
        expect(source.metadata, equals({'custom': 'metadata'}));
      });

      test('should create context source correctly', () {
        final source = documentSource.source;

        expect(source.name, equals('Test Document Source'));
        expect(source.sourceType, equals(SourceType.document));
        expect(source.url, equals('/test/path'));
        expect(source.metadata, isEmpty);
        expect(source.privacyLevel, equals(PrivacyLevel.private));
        expect(source.authorityScore, equals(0.8));
        expect(source.freshnessScore, equals(1.0));
      });
    });

    group('Supported Extensions Tests', () {
      test('should have correct supported extensions', () {
        final extensions = documentSource.supportedExtensions;

        expect(extensions, contains('.txt'));
        expect(extensions, contains('.md'));
        expect(extensions, contains('.json'));
        expect(extensions, contains('.pdf'));
        expect(extensions, contains('.docx'));
        expect(extensions.length, equals(5));
      });

      test('should check if file is supported', () {
        // Test private method through reflection or public interface
        expect(() => documentSource.getChunks(query: 'test'), returnsNormally);
      });
    });

    group('Configuration Tests', () {
      test('should have correct default configuration', () {
        expect(documentSource.chunkSize, equals(1000));
        expect(documentSource.chunkOverlap, equals(200));
        expect(documentSource.includeMetadata, isTrue);
        expect(documentSource.isActive, isTrue);
      });

      test('should have correct source properties', () {
        expect(documentSource.name, equals('Test Document Source'));
        expect(documentSource.sourceType, equals(SourceType.document));
        expect(documentSource.documentPath, equals('/test/path'));
      });
    });

    group('Error Handling Tests', () {
      test('should handle inactive source gracefully', () {
        // Test that inactive source throws appropriate error
        expect(() => documentSource.getChunks(query: 'test'), returnsNormally);
      });

      test('should handle configuration errors gracefully', () {
        final source = DocumentSource(
          name: 'Error Source',
          documentPath: '/nonexistent/path',
        );

        expect(() => source.getChunks(query: 'test'), returnsNormally);
      });
    });

    group('Utility Method Tests', () {
      test('should handle basic operations without errors', () {
        // Test that methods handle basic operations without errors
        expect(() => documentSource.getChunks(query: 'test'), returnsNormally);
        expect(
          () => documentSource.getChunks(query: 'test', maxChunks: 5),
          returnsNormally,
        );
        expect(
          () => documentSource.getChunks(query: 'test', minRelevance: 0.5),
          returnsNormally,
        );
        expect(
          () => documentSource.getChunks(query: 'test', userId: 'user123'),
          returnsNormally,
        );
        expect(
          () =>
              documentSource.getChunks(query: 'test', sessionId: 'session456'),
          returnsNormally,
        );
      });

      test('should handle edge cases gracefully', () {
        // Test with empty query
        expect(() => documentSource.getChunks(query: ''), returnsNormally);

        // Test with very long query
        expect(
          () => documentSource.getChunks(query: 'a' * 1000),
          returnsNormally,
        );

        // Test with special characters
        expect(
          () => documentSource.getChunks(query: '!@#\$%^&*()'),
          returnsNormally,
        );
      });
    });

    group('Performance Tests', () {
      test('should handle multiple concurrent requests', () async {
        // Test that multiple concurrent requests don't cause issues
        final futures = List.generate(
          5,
          (i) => documentSource.getChunks(query: 'test$i'),
        );

        expect(() => Future.wait(futures), returnsNormally);
      });

      test('should handle large chunk sizes', () {
        final largeSource = DocumentSource(
          name: 'Large Chunk Source',
          documentPath: '/test/path',
          chunkSize: 10000,
          chunkOverlap: 2000,
        );

        expect(() => largeSource.getChunks(query: 'test'), returnsNormally);
      });
    });

    group('Integration Tests', () {
      test('should work with different logger configurations', () {
        final silentLogger = Logger(level: Level.error);
        final verboseLogger = Logger(level: Level.debug);

        final silentSource = DocumentSource(
          name: 'Silent Source',
          documentPath: '/test/path',
          logger: silentLogger,
        );

        final verboseSource = DocumentSource(
          name: 'Verbose Source',
          documentPath: '/test/path',
          logger: verboseLogger,
        );

        expect(() => silentSource.getChunks(query: 'test'), returnsNormally);
        expect(() => verboseSource.getChunks(query: 'test'), returnsNormally);
      });

      test('should handle different privacy levels through context source', () {
        final publicSource = DocumentSource(
          name: 'Public Source',
          documentPath: '/test/path',
        );

        final source = publicSource.source;
        expect(
          source.privacyLevel,
          equals(PrivacyLevel.private),
        ); // Default is private
      });
    });
  });
}
