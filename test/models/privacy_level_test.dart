import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';

void main() {
  group('PrivacyLevel Tests', () {
    group('Enum Values Tests', () {
      test('should have correct enum values', () {
        expect(PrivacyLevel.public.index, equals(0));
        expect(PrivacyLevel.private.index, equals(1));
        expect(PrivacyLevel.enterprise.index, equals(2));
        expect(PrivacyLevel.restricted.index, equals(3));
      });

      test('should have correct number of enum values', () {
        expect(PrivacyLevel.values.length, equals(4));
      });

      test('should contain all expected values', () {
        expect(PrivacyLevel.values.contains(PrivacyLevel.public), isTrue);
        expect(PrivacyLevel.values.contains(PrivacyLevel.private), isTrue);
        expect(PrivacyLevel.values.contains(PrivacyLevel.enterprise), isTrue);
        expect(PrivacyLevel.values.contains(PrivacyLevel.restricted), isTrue);
      });
    });

    group('Value Property Tests', () {
      test('should return correct string values', () {
        expect(PrivacyLevel.public.value, equals('public'));
        expect(PrivacyLevel.private.value, equals('private'));
        expect(PrivacyLevel.enterprise.value, equals('enterprise'));
        expect(PrivacyLevel.restricted.value, equals('restricted'));
      });

      test('should return lowercase string values', () {
        for (final level in PrivacyLevel.values) {
          expect(level.value, equals(level.value.toLowerCase()));
        }
      });

      test('should return non-empty string values', () {
        for (final level in PrivacyLevel.values) {
          expect(level.value, isNotEmpty);
          expect(level.value.trim(), isNotEmpty);
        }
      });
    });

    group('FromString Tests', () {
      test('should convert valid strings correctly', () {
        expect(PrivacyLevel.fromString('public'), equals(PrivacyLevel.public));
        expect(PrivacyLevel.fromString('private'), equals(PrivacyLevel.private));
        expect(PrivacyLevel.fromString('enterprise'), equals(PrivacyLevel.enterprise));
        expect(PrivacyLevel.fromString('restricted'), equals(PrivacyLevel.restricted));
      });

      test('should handle case insensitive conversion', () {
        expect(PrivacyLevel.fromString('PUBLIC'), equals(PrivacyLevel.public));
        expect(PrivacyLevel.fromString('Public'), equals(PrivacyLevel.public));
        expect(PrivacyLevel.fromString('pUbLiC'), equals(PrivacyLevel.public));
        expect(PrivacyLevel.fromString('public'), equals(PrivacyLevel.public));

        expect(PrivacyLevel.fromString('PRIVATE'), equals(PrivacyLevel.private));
        expect(PrivacyLevel.fromString('Private'), equals(PrivacyLevel.private));
        expect(PrivacyLevel.fromString('pRiVaTe'), equals(PrivacyLevel.private));
        expect(PrivacyLevel.fromString('private'), equals(PrivacyLevel.private));

        expect(PrivacyLevel.fromString('ENTERPRISE'), equals(PrivacyLevel.enterprise));
        expect(PrivacyLevel.fromString('Enterprise'), equals(PrivacyLevel.enterprise));
        expect(PrivacyLevel.fromString('eNtErPrIsE'), equals(PrivacyLevel.enterprise));
        expect(PrivacyLevel.fromString('enterprise'), equals(PrivacyLevel.enterprise));

        expect(PrivacyLevel.fromString('RESTRICTED'), equals(PrivacyLevel.restricted));
        expect(PrivacyLevel.fromString('Restricted'), equals(PrivacyLevel.restricted));
        expect(PrivacyLevel.fromString('rEsTrIcTeD'), equals(PrivacyLevel.restricted));
        expect(PrivacyLevel.fromString('restricted'), equals(PrivacyLevel.restricted));
      });

      test('should throw ArgumentError for invalid strings', () {
        expect(() => PrivacyLevel.fromString('invalid'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString(''), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('null'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('123'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public_extra'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public '), throwsArgumentError);
        expect(() => PrivacyLevel.fromString(' public'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\n'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\r'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\t'), throwsArgumentError);
      });

      test('should throw ArgumentError for edge cases', () {
        expect(() => PrivacyLevel.fromString('PUBLIC!'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public@'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public#'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\$'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public%'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public^'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public&'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public*'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public('), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public)'), throwsArgumentError);
      });
    });

    group('Integration Tests', () {
      test('should work with value and fromString round trip', () {
        for (final level in PrivacyLevel.values) {
          final stringValue = level.value;
          final convertedLevel = PrivacyLevel.fromString(stringValue);
          expect(convertedLevel, equals(level));
        }
      });

      test('should handle all case variations correctly', () {
        final testCases = [
          'public', 'Public', 'PUBLIC', 'pUbLiC',
          'private', 'Private', 'PRIVATE', 'pRiVaTe',
          'enterprise', 'Enterprise', 'ENTERPRISE', 'eNtErPrIsE',
          'restricted', 'Restricted', 'RESTRICTED', 'rEsTrIcTeD',
        ];

        for (final testCase in testCases) {
          final result = PrivacyLevel.fromString(testCase);
          expect(result, isNotNull);
          expect(result, isA<PrivacyLevel>());
        }
      });

      test('should maintain consistency across multiple calls', () {
        final testString = 'public';
        final firstResult = PrivacyLevel.fromString(testString);
        final secondResult = PrivacyLevel.fromString(testString);
        final thirdResult = PrivacyLevel.fromString(testString);

        expect(firstResult, equals(secondResult));
        expect(secondResult, equals(thirdResult));
        expect(firstResult, equals(PrivacyLevel.public));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle null-like strings', () {
        expect(() => PrivacyLevel.fromString('null'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('NULL'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('Null'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('nUlL'), throwsArgumentError);
      });

      test('should handle numeric strings', () {
        expect(() => PrivacyLevel.fromString('0'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('1'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('999'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('-1'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('1.5'), throwsArgumentError);
      });

      test('should handle special characters', () {
        expect(() => PrivacyLevel.fromString('!@#\$'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public!'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public@'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public#'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\$'), throwsArgumentError);
      });

      test('should handle whitespace variations', () {
        expect(() => PrivacyLevel.fromString('\tpublic'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\n'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\r'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\f'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('public\v'), throwsArgumentError);
      });

      test('should handle very long strings', () {
        final longString = 'public' + 'a' * 1000;
        expect(() => PrivacyLevel.fromString(longString), throwsArgumentError);
      });

      test('should handle single character strings', () {
        expect(() => PrivacyLevel.fromString('a'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('z'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('A'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('Z'), throwsArgumentError);
      });
    });

    group('Performance Tests', () {
      test('should handle rapid string conversions efficiently', () {
        final testStrings = ['public', 'private', 'enterprise', 'restricted'];
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          for (final testString in testStrings) {
            final result = PrivacyLevel.fromString(testString);
            expect(result, isNotNull);
          }
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
      });

      test('should handle mixed case conversions efficiently', () {
        final mixedCases = [
          'PUBLIC', 'Public', 'pUbLiC', 'PUBLIC',
          'PRIVATE', 'Private', 'pRiVaTe', 'PRIVATE',
          'ENTERPRISE', 'Enterprise', 'eNtErPrIsE', 'ENTERPRISE',
          'RESTRICTED', 'Restricted', 'rEsTrIcTeD', 'RESTRICTED',
        ];

        final stopwatch = Stopwatch()..start();
        
        for (final mixedCase in mixedCases) {
          final result = PrivacyLevel.fromString(mixedCase);
          expect(result, isNotNull);
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be very fast
      });
    });

    group('Comprehensive Coverage Tests', () {
      test('should cover all enum value combinations', () {
        // Test that all enum values have corresponding string representations
        for (final level in PrivacyLevel.values) {
          final stringValue = level.value;
          final convertedLevel = PrivacyLevel.fromString(stringValue);
          expect(convertedLevel, equals(level));
        }
      });

      test('should handle boundary conditions', () {
        // Test empty string
        expect(() => PrivacyLevel.fromString(''), throwsArgumentError);
        
        // Test single character strings
        expect(() => PrivacyLevel.fromString('a'), throwsArgumentError);
        expect(() => PrivacyLevel.fromString('z'), throwsArgumentError);
        
        // Test very long strings
        final longString = 'a' * 1000;
        expect(() => PrivacyLevel.fromString(longString), throwsArgumentError);
      });

      test('should maintain consistency across multiple calls', () {
        final testString = 'public';
        final firstResult = PrivacyLevel.fromString(testString);
        final secondResult = PrivacyLevel.fromString(testString);
        final thirdResult = PrivacyLevel.fromString(testString);
        
        expect(firstResult, equals(secondResult));
        expect(secondResult, equals(thirdResult));
        expect(firstResult, equals(PrivacyLevel.public));
      });

      test('should handle all error cases consistently', () {
        final invalidStrings = [
          '', 'null', '123', 'public_extra', 'public ', ' public',
          'public\n', 'public\r', 'public\t', 'public!', 'public@',
          'public#', 'public\$', 'public%', 'public^', 'public&',
          'public*', 'public(', 'public)', 'a', 'z', 'A', 'Z',
        ];

        for (final invalidString in invalidStrings) {
          expect(() => PrivacyLevel.fromString(invalidString), throwsArgumentError);
        }
      });
    });

    group('Error Message Tests', () {
      test('should provide meaningful error messages', () {
        try {
          PrivacyLevel.fromString('invalid');
          fail('Expected ArgumentError to be thrown');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(e.toString(), contains('Invalid privacy level: invalid'));
        }
      });

      test('should include invalid value in error message', () {
        final testValues = ['invalid', 'empty', '123', 'special!'];
        
        for (final testValue in testValues) {
          try {
            PrivacyLevel.fromString(testValue);
            fail('Expected ArgumentError to be thrown for: $testValue');
          } catch (e) {
            expect(e, isA<ArgumentError>());
            expect(e.toString(), contains('Invalid privacy level: $testValue'));
          }
        }
      });
    });
  });
}
