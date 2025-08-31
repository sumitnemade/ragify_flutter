import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('PrivacyLevel Tests', () {
    test('enum values are correct', () {
      expect(PrivacyLevel.public.value, equals('public'));
      expect(PrivacyLevel.private.value, equals('private'));
      expect(PrivacyLevel.enterprise.value, equals('enterprise'));
      expect(PrivacyLevel.restricted.value, equals('restricted'));
    });

    test('fromString with valid values', () {
      expect(PrivacyLevel.fromString('public'), equals(PrivacyLevel.public));
      expect(PrivacyLevel.fromString('PRIVATE'), equals(PrivacyLevel.private));
      expect(
        PrivacyLevel.fromString('Enterprise'),
        equals(PrivacyLevel.enterprise),
      );
      expect(
        PrivacyLevel.fromString('RESTRICTED'),
        equals(PrivacyLevel.restricted),
      );
    });

    test('fromString with invalid value throws ArgumentError', () {
      expect(() => PrivacyLevel.fromString('invalid'), throwsArgumentError);
      expect(() => PrivacyLevel.fromString(''), throwsArgumentError);
      expect(() => PrivacyLevel.fromString('null'), throwsArgumentError);
    });

    test('fromString is case insensitive', () {
      expect(PrivacyLevel.fromString('PUBLIC'), equals(PrivacyLevel.public));
      expect(PrivacyLevel.fromString('Public'), equals(PrivacyLevel.public));
      expect(PrivacyLevel.fromString('public'), equals(PrivacyLevel.public));
    });

    test('enum index values', () {
      expect(PrivacyLevel.public.index, equals(0));
      expect(PrivacyLevel.private.index, equals(1));
      expect(PrivacyLevel.enterprise.index, equals(2));
      expect(PrivacyLevel.restricted.index, equals(3));
    });

    test('enum comparison works correctly', () {
      expect(PrivacyLevel.public.index < PrivacyLevel.private.index, isTrue);
      expect(
        PrivacyLevel.private.index < PrivacyLevel.enterprise.index,
        isTrue,
      );
      expect(
        PrivacyLevel.enterprise.index < PrivacyLevel.restricted.index,
        isTrue,
      );
    });
  });
}
