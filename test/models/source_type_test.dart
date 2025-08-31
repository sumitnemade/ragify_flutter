import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('SourceType Tests', () {
    test('enum values are correct', () {
      expect(SourceType.document.value, equals('document'));
      expect(SourceType.api.value, equals('api'));
      expect(SourceType.database.value, equals('database'));
      expect(SourceType.realtime.value, equals('realtime'));
      expect(SourceType.vector.value, equals('vector'));
      expect(SourceType.cache.value, equals('cache'));
    });

    test('fromString with valid values', () {
      expect(SourceType.fromString('document'), equals(SourceType.document));
      expect(SourceType.fromString('api'), equals(SourceType.api));
      expect(SourceType.fromString('database'), equals(SourceType.database));
      expect(SourceType.fromString('realtime'), equals(SourceType.realtime));
      expect(SourceType.fromString('vector'), equals(SourceType.vector));
      expect(SourceType.fromString('cache'), equals(SourceType.cache));
    });

    test('fromString with invalid value throws ArgumentError', () {
      expect(() => SourceType.fromString('invalid'), throwsArgumentError);
      expect(() => SourceType.fromString(''), throwsArgumentError);
      expect(() => SourceType.fromString('null'), throwsArgumentError);
      expect(() => SourceType.fromString('unknown'), throwsArgumentError);
    });

    test('fromString is case insensitive', () {
      expect(SourceType.fromString('DOCUMENT'), equals(SourceType.document));
      expect(SourceType.fromString('Document'), equals(SourceType.document));
      expect(SourceType.fromString('document'), equals(SourceType.document));

      expect(SourceType.fromString('API'), equals(SourceType.api));
      expect(SourceType.fromString('Api'), equals(SourceType.api));
      expect(SourceType.fromString('api'), equals(SourceType.api));
    });

    test('enum index values', () {
      expect(SourceType.document.index, equals(0));
      expect(SourceType.api.index, equals(1));
      expect(SourceType.database.index, equals(2));
      expect(SourceType.realtime.index, equals(3));
      expect(SourceType.vector.index, equals(4));
      expect(SourceType.cache.index, equals(5));
    });

    test('all enum values are covered', () {
      final values = SourceType.values;
      expect(values.length, equals(6));
      expect(values.contains(SourceType.document), isTrue);
      expect(values.contains(SourceType.api), isTrue);
      expect(values.contains(SourceType.database), isTrue);
      expect(values.contains(SourceType.realtime), isTrue);
      expect(values.contains(SourceType.vector), isTrue);
      expect(values.contains(SourceType.cache), isTrue);
    });
  });
}
