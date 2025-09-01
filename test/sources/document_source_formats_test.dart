import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/document_source.dart';

void main() {
  group('DocumentSource Formats', () {
    late String tempDir;
    late DocumentSource source;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('doc_formats').path;
      source = DocumentSource(name: 'docs', documentPath: tempDir);
    });

    tearDown(() {
      try {
        Directory(tempDir).deleteSync(recursive: true);
      } catch (_) {}
    });

    test('reads valid JSON file and handles invalid JSON gracefully', () async {
      final valid = File('$tempDir/valid.json');
      valid.writeAsStringSync('{"key": "value"}');

      final invalid = File('$tempDir/invalid.json');
      invalid.writeAsStringSync('{invalid json');

      final chunks = await source.getChunks(query: 'value');
      // Should parse valid.json and include its content; invalid falls back to raw string
      expect(chunks, isNotEmpty);
    });

    test('pdf/docx placeholders produce chunks without throwing', () async {
      File('$tempDir/test.pdf').writeAsStringSync('binary');
      File('$tempDir/test.docx').writeAsStringSync('binary');

      final chunks = await source.getChunks(query: 'PDF Document:');
      // Placeholders return identifiable strings; ensure no exception and some content exists
      expect(chunks, isNotEmpty);
    });
  });
}
