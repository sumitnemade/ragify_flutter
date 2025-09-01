import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';

void main() {
  group('SourceStatus Tests', () {
    group('Enum Values Tests', () {
      test('should have correct enum values', () {
        expect(SourceStatus.healthy.value, equals('healthy'));
        expect(SourceStatus.degraded.value, equals('degraded'));
        expect(SourceStatus.unhealthy.value, equals('unhealthy'));
        expect(SourceStatus.offline.value, equals('offline'));
        expect(SourceStatus.unknown.value, equals('unknown'));
      });

      test('should convert from string correctly', () {
        expect(
          SourceStatus.fromString('healthy'),
          equals(SourceStatus.healthy),
        );
        expect(
          SourceStatus.fromString('degraded'),
          equals(SourceStatus.degraded),
        );
        expect(
          SourceStatus.fromString('unhealthy'),
          equals(SourceStatus.unhealthy),
        );
        expect(
          SourceStatus.fromString('offline'),
          equals(SourceStatus.offline),
        );
        expect(
          SourceStatus.fromString('unknown'),
          equals(SourceStatus.unknown),
        );
      });

      test('should handle case insensitive conversion', () {
        expect(
          SourceStatus.fromString('HEALTHY'),
          equals(SourceStatus.healthy),
        );
        expect(
          SourceStatus.fromString('Degraded'),
          equals(SourceStatus.degraded),
        );
        expect(
          SourceStatus.fromString('UnHeAlThY'),
          equals(SourceStatus.unhealthy),
        );
      });

      test('should return unknown for invalid strings', () {
        expect(
          SourceStatus.fromString('invalid'),
          equals(SourceStatus.unknown),
        );
        expect(SourceStatus.fromString(''), equals(SourceStatus.unknown));
        expect(SourceStatus.fromString('123'), equals(SourceStatus.unknown));
        expect(
          SourceStatus.fromString('healthy_extra'),
          equals(SourceStatus.unknown),
        );
      });

      test('should handle edge cases', () {
        expect(
          SourceStatus.fromString(' healthy '),
          equals(SourceStatus.unknown),
        );
        expect(
          SourceStatus.fromString('healthy '),
          equals(SourceStatus.unknown),
        );
        expect(
          SourceStatus.fromString(' healthy'),
          equals(SourceStatus.unknown),
        );
      });
    });

    group('Integration Tests', () {
      test('should handle all status values in conversion', () {
        final allStatuses = SourceStatus.values;
        for (final status in allStatuses) {
          final converted = SourceStatus.fromString(status.value);
          expect(converted, equals(status));
        }
      });

      test('should have correct number of enum values', () {
        expect(SourceStatus.values.length, equals(5));
      });

      test('should have correct enum indices', () {
        expect(SourceStatus.healthy.index, equals(0));
        expect(SourceStatus.degraded.index, equals(1));
        expect(SourceStatus.unhealthy.index, equals(2));
        expect(SourceStatus.offline.index, equals(3));
        expect(SourceStatus.unknown.index, equals(4));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle null-like strings', () {
        expect(SourceStatus.fromString('null'), equals(SourceStatus.unknown));
        expect(SourceStatus.fromString('NULL'), equals(SourceStatus.unknown));
        expect(SourceStatus.fromString('Null'), equals(SourceStatus.unknown));
      });

      test('should handle numeric strings', () {
        expect(SourceStatus.fromString('0'), equals(SourceStatus.unknown));
        expect(SourceStatus.fromString('1'), equals(SourceStatus.unknown));
        expect(SourceStatus.fromString('999'), equals(SourceStatus.unknown));
      });

      test('should handle special characters', () {
        expect(SourceStatus.fromString('!@#\$'), equals(SourceStatus.unknown));
        expect(
          SourceStatus.fromString('healthy!'),
          equals(SourceStatus.unknown),
        );
        expect(
          SourceStatus.fromString('healthy@'),
          equals(SourceStatus.unknown),
        );
      });

      test('should handle whitespace variations', () {
        expect(
          SourceStatus.fromString('\thealthy'),
          equals(SourceStatus.unknown),
        );
        expect(
          SourceStatus.fromString('healthy\n'),
          equals(SourceStatus.unknown),
        );
        expect(
          SourceStatus.fromString('healthy\r'),
          equals(SourceStatus.unknown),
        );
      });
    });

    group('Performance Tests', () {
      test('should handle rapid string conversions', () {
        final testStrings = [
          'healthy',
          'degraded',
          'unhealthy',
          'offline',
          'unknown',
        ];

        for (int i = 0; i < 100; i++) {
          for (final testString in testStrings) {
            final result = SourceStatus.fromString(testString);
            expect(result, isNotNull);
          }
        }
      });

      test('should handle mixed case conversions efficiently', () {
        final mixedCases = [
          'HEALTHY',
          'Healthy',
          'hEaLtHy',
          'healTHY',
          'HEALTHY',
          'DEGRADED',
          'Degraded',
          'dEgRaDeD',
          'degrADED',
          'DEGRADED',
        ];

        for (final mixedCase in mixedCases) {
          final result = SourceStatus.fromString(mixedCase);
          expect(result, isNotNull);
        }
      });
    });

    group('Comprehensive Coverage Tests', () {
      test('should cover all enum value combinations', () {
        // Test that all enum values have corresponding string representations
        for (final status in SourceStatus.values) {
          final stringValue = status.value;
          final convertedStatus = SourceStatus.fromString(stringValue);
          expect(convertedStatus, equals(status));
        }
      });

      test('should handle boundary conditions', () {
        // Test empty string
        expect(SourceStatus.fromString(''), equals(SourceStatus.unknown));

        // Test single character strings
        expect(SourceStatus.fromString('a'), equals(SourceStatus.unknown));
        expect(SourceStatus.fromString('z'), equals(SourceStatus.unknown));

        // Test very long strings
        final longString = 'a' * 1000;
        expect(
          SourceStatus.fromString(longString),
          equals(SourceStatus.unknown),
        );
      });

      test('should maintain consistency across multiple calls', () {
        final testString = 'healthy';
        final firstResult = SourceStatus.fromString(testString);
        final secondResult = SourceStatus.fromString(testString);
        final thirdResult = SourceStatus.fromString(testString);

        expect(firstResult, equals(secondResult));
        expect(secondResult, equals(thirdResult));
        expect(firstResult, equals(SourceStatus.healthy));
      });
    });
  });
}
