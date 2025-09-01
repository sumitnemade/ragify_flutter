import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/models/relevance_score.dart';

void main() {
  group('RelevanceScore Tests', () {
    group('Constructor Tests', () {
      test('should create with required parameters', () {
        final score = RelevanceScore(score: 0.8);

        expect(score.score, equals(0.8));
        expect(score.confidenceLower, isNull);
        expect(score.confidenceUpper, isNull);
        expect(score.confidenceLevel, equals(0.95));
      });

      test('should create with all parameters', () {
        final score = RelevanceScore(
          score: 0.7,
          confidenceLower: 0.6,
          confidenceUpper: 0.8,
          confidenceLevel: 0.9,
        );

        expect(score.score, equals(0.7));
        expect(score.confidenceLower, equals(0.6));
        expect(score.confidenceUpper, equals(0.8));
        expect(score.confidenceLevel, equals(0.9));
      });

      test('should use default confidence level when not provided', () {
        final score = RelevanceScore(score: 0.5);

        expect(score.confidenceLevel, equals(0.95));
      });

      test('should handle boundary values', () {
        final minScore = RelevanceScore(score: 0.0);
        final maxScore = RelevanceScore(score: 1.0);

        expect(minScore.score, equals(0.0));
        expect(maxScore.score, equals(1.0));
      });

      test('should handle decimal precision', () {
        final score = RelevanceScore(score: 0.123456);

        expect(score.score, equals(0.123456));
      });

      test('should handle confidence level boundary values', () {
        final minConfidence = RelevanceScore(score: 0.5, confidenceLevel: 0.0);
        final maxConfidence = RelevanceScore(score: 0.5, confidenceLevel: 1.0);

        expect(minConfidence.confidenceLevel, equals(0.0));
        expect(maxConfidence.confidenceLevel, equals(1.0));
      });
    });

    group('Validation Tests', () {
      test('should throw assertion error for score below 0.0', () {
        expect(
          () => RelevanceScore(score: -0.1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw assertion error for score above 1.0', () {
        expect(
          () => RelevanceScore(score: 1.1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should accept score exactly at boundaries', () {
        expect(() => RelevanceScore(score: 0.0), returnsNormally);
        expect(() => RelevanceScore(score: 1.0), returnsNormally);
      });

      test('should handle very small positive scores', () {
        final score = RelevanceScore(score: 0.000001);

        expect(score.score, equals(0.000001));
      });

      test('should handle scores very close to 1.0', () {
        final score = RelevanceScore(score: 0.999999);

        expect(score.score, equals(0.999999));
      });
    });

    group('Copy With Tests', () {
      test('should create copy with updated fields', () {
        final original = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
          confidenceLevel: 0.95,
        );

        final updated = original.copyWith(
          score: 0.7,
          confidenceLower: 0.6,
          confidenceUpper: 0.8,
          confidenceLevel: 0.9,
        );

        expect(updated.score, equals(0.7));
        expect(updated.confidenceLower, equals(0.6));
        expect(updated.confidenceUpper, equals(0.8));
        expect(updated.confidenceLevel, equals(0.9));
      });

      test('should create copy with partial updates', () {
        final original = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
          confidenceLevel: 0.95,
        );

        final updated = original.copyWith(score: 0.7);

        expect(updated.score, equals(0.7));
        expect(updated.confidenceLower, equals(original.confidenceLower));
        expect(updated.confidenceUpper, equals(original.confidenceUpper));
        expect(updated.confidenceLevel, equals(original.confidenceLevel));
      });

      test('should create copy with no changes', () {
        final original = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
          confidenceLevel: 0.95,
        );

        final copy = original.copyWith();

        expect(copy.score, equals(original.score));
        expect(copy.confidenceLower, equals(original.confidenceLower));
        expect(copy.confidenceUpper, equals(original.confidenceUpper));
        expect(copy.confidenceLevel, equals(original.confidenceLevel));
      });

      test('should handle null values in copyWith', () {
        final original = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
          confidenceLevel: 0.95,
        );

        final updated = original.copyWith(
          confidenceLower: null,
          confidenceUpper: null,
        );

        // The copyWith method uses the null-coalescing operator (??),
        // so null values will use the original values instead of becoming null
        expect(updated.confidenceLower, equals(original.confidenceLower));
        expect(updated.confidenceUpper, equals(original.confidenceUpper));
        expect(updated.score, equals(original.score));
        expect(updated.confidenceLevel, equals(original.confidenceLevel));
      });
    });

    group('Threshold Tests', () {
      test('should return true when score is above threshold', () {
        final score = RelevanceScore(score: 0.8);

        expect(score.isAboveThreshold(0.7), isTrue);
        expect(score.isAboveThreshold(0.5), isTrue);
        expect(score.isAboveThreshold(0.1), isTrue);
      });

      test('should return true when score equals threshold', () {
        final score = RelevanceScore(score: 0.8);

        expect(score.isAboveThreshold(0.8), isTrue);
      });

      test('should return false when score is below threshold', () {
        final score = RelevanceScore(score: 0.8);

        expect(score.isAboveThreshold(0.9), isFalse);
        expect(score.isAboveThreshold(1.0), isFalse);
      });

      test('should handle boundary thresholds', () {
        final score = RelevanceScore(score: 0.5);

        expect(score.isAboveThreshold(0.0), isTrue);
        expect(score.isAboveThreshold(0.5), isTrue);
        expect(score.isAboveThreshold(1.0), isFalse);
      });

      test('should handle very small thresholds', () {
        final score = RelevanceScore(score: 0.000001);

        expect(score.isAboveThreshold(0.0), isTrue);
        expect(score.isAboveThreshold(0.000001), isTrue);
        expect(score.isAboveThreshold(0.000002), isFalse);
      });

      test('should handle very large thresholds', () {
        final score = RelevanceScore(score: 0.999999);

        expect(score.isAboveThreshold(0.999998), isTrue);
        expect(score.isAboveThreshold(0.999999), isTrue);
        expect(score.isAboveThreshold(1.0), isFalse);
      });
    });

    group('Confidence Interval Tests', () {
      test('should calculate confidence interval width correctly', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
        );

        expect(score.confidenceIntervalWidth, closeTo(0.2, 0.001));
      });

      test('should return null when confidence bounds are missing', () {
        final score1 = RelevanceScore(score: 0.5);
        final score2 = RelevanceScore(score: 0.5, confidenceLower: 0.4);
        final score3 = RelevanceScore(score: 0.5, confidenceUpper: 0.6);

        expect(score1.confidenceIntervalWidth, isNull);
        expect(score2.confidenceIntervalWidth, isNull);
        expect(score3.confidenceIntervalWidth, isNull);
      });

      test('should handle zero confidence interval width', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.5,
          confidenceUpper: 0.5,
        );

        expect(score.confidenceIntervalWidth, equals(0.0));
      });

      test('should handle negative confidence interval width', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.6,
          confidenceUpper: 0.4,
        );

        expect(score.confidenceIntervalWidth, closeTo(-0.2, 0.001));
      });

      test('should handle very small confidence intervals', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.499999,
          confidenceUpper: 0.500001,
        );

        expect(score.confidenceIntervalWidth, closeTo(0.000002, 0.000001));
      });

      test('should handle very large confidence intervals', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.0,
          confidenceUpper: 1.0,
        );

        expect(score.confidenceIntervalWidth, equals(1.0));
      });
    });

    group('Confidence Interval String Tests', () {
      test('should format confidence interval string correctly', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
        );

        expect(score.confidenceIntervalString, equals('0.400 - 0.600'));
      });

      test('should return N/A when confidence bounds are missing', () {
        final score1 = RelevanceScore(score: 0.5);
        final score2 = RelevanceScore(score: 0.5, confidenceLower: 0.4);
        final score3 = RelevanceScore(score: 0.5, confidenceUpper: 0.6);

        expect(score1.confidenceIntervalString, equals('N/A'));
        expect(score2.confidenceIntervalString, equals('N/A'));
        expect(score3.confidenceIntervalString, equals('N/A'));
      });

      test('should handle decimal precision in string format', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.123456,
          confidenceUpper: 0.789012,
        );

        expect(score.confidenceIntervalString, equals('0.123 - 0.789'));
      });

      test('should handle boundary values in string format', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.0,
          confidenceUpper: 1.0,
        );

        expect(score.confidenceIntervalString, equals('0.000 - 1.000'));
      });

      test('should handle very small values in string format', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.000001,
          confidenceUpper: 0.000002,
        );

        expect(score.confidenceIntervalString, equals('0.000 - 0.000'));
      });
    });

    group('ToString Tests', () {
      test('should generate readable string representation', () {
        final score = RelevanceScore(
          score: 0.8,
          confidenceLower: 0.7,
          confidenceUpper: 0.9,
        );

        final stringRep = score.toString();

        expect(stringRep, contains('RelevanceScore'));
        expect(stringRep, contains('0.800'));
        expect(stringRep, contains('0.700 - 0.900'));
      });

      test('should handle missing confidence bounds in toString', () {
        final score = RelevanceScore(score: 0.8);

        final stringRep = score.toString();

        expect(stringRep, contains('RelevanceScore'));
        expect(stringRep, contains('0.800'));
        expect(stringRep, contains('N/A'));
      });

      test('should handle decimal precision in toString', () {
        final score = RelevanceScore(
          score: 0.123456,
          confidenceLower: 0.111111,
          confidenceUpper: 0.222222,
        );

        final stringRep = score.toString();

        expect(stringRep, contains('0.123'));
        expect(stringRep, contains('0.111 - 0.222'));
      });

      test('should handle boundary values in toString', () {
        final score = RelevanceScore(
          score: 1.0,
          confidenceLower: 0.0,
          confidenceUpper: 1.0,
        );

        final stringRep = score.toString();

        expect(stringRep, contains('1.000'));
        expect(stringRep, contains('0.000 - 1.000'));
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when all fields match', () {
        final score1 = RelevanceScore(
          score: 0.8,
          confidenceLower: 0.7,
          confidenceUpper: 0.9,
          confidenceLevel: 0.95,
        );

        final score2 = RelevanceScore(
          score: 0.8,
          confidenceLower: 0.7,
          confidenceUpper: 0.9,
          confidenceLevel: 0.95,
        );

        expect(score1, equals(score2));
        expect(score1.hashCode, equals(score2.hashCode));
      });

      test('should not be equal when score differs', () {
        final score1 = RelevanceScore(score: 0.8);
        final score2 = RelevanceScore(score: 0.9);

        expect(score1, isNot(equals(score2)));
        expect(score1.hashCode, isNot(equals(score2.hashCode)));
      });

      test('should not be equal when confidenceLower differs', () {
        final score1 = RelevanceScore(score: 0.8, confidenceLower: 0.7);
        final score2 = RelevanceScore(score: 0.8, confidenceLower: 0.6);

        expect(score1, isNot(equals(score2)));
        expect(score1.hashCode, isNot(equals(score2.hashCode)));
      });

      test('should not be equal when confidenceUpper differs', () {
        final score1 = RelevanceScore(score: 0.8, confidenceUpper: 0.9);
        final score2 = RelevanceScore(score: 0.8, confidenceUpper: 0.8);

        expect(score1, isNot(equals(score2)));
        expect(score1.hashCode, isNot(equals(score2.hashCode)));
      });

      test('should not be equal when confidenceLevel differs', () {
        final score1 = RelevanceScore(score: 0.8, confidenceLevel: 0.95);
        final score2 = RelevanceScore(score: 0.8, confidenceLevel: 0.9);

        expect(score1, isNot(equals(score2)));
        expect(score1.hashCode, isNot(equals(score2.hashCode)));
      });

      test('should be equal to itself', () {
        final score = RelevanceScore(score: 0.8);

        expect(score, equals(score));
        expect(score.hashCode, equals(score.hashCode));
      });

      test('should not be equal to different types', () {
        final score = RelevanceScore(score: 0.8);

        expect(score, isNot(equals('string')));
        expect(score, isNot(equals(123)));
        expect(score, isNot(equals(null)));
      });

      test('should handle null values in equality', () {
        final score1 = RelevanceScore(
          score: 0.8,
          confidenceLower: null,
          confidenceUpper: null,
        );

        final score2 = RelevanceScore(
          score: 0.8,
          confidenceLower: null,
          confidenceUpper: null,
        );

        expect(score1, equals(score2));
        expect(score1.hashCode, equals(score2.hashCode));
      });

      test('should handle mixed null and non-null values in equality', () {
        final score1 = RelevanceScore(
          score: 0.8,
          confidenceLower: 0.7,
          confidenceUpper: null,
        );

        final score2 = RelevanceScore(
          score: 0.8,
          confidenceLower: 0.7,
          confidenceUpper: null,
        );

        expect(score1, equals(score2));
        expect(score1.hashCode, equals(score2.hashCode));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle very small scores', () {
        final score = RelevanceScore(score: 0.000001);

        expect(score.score, equals(0.000001));
        expect(score.isAboveThreshold(0.0), isTrue);
        expect(score.isAboveThreshold(0.000001), isTrue);
        expect(score.isAboveThreshold(0.000002), isFalse);
      });

      test('should handle scores very close to 1.0', () {
        final score = RelevanceScore(score: 0.999999);

        expect(score.score, equals(0.999999));
        expect(score.isAboveThreshold(0.999998), isTrue);
        expect(score.isAboveThreshold(0.999999), isTrue);
        expect(score.isAboveThreshold(1.0), isFalse);
      });

      test('should handle very small confidence intervals', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.499999,
          confidenceUpper: 0.500001,
        );

        expect(score.confidenceIntervalWidth, closeTo(0.000002, 0.000001));
        expect(score.confidenceIntervalString, equals('0.500 - 0.500'));
      });

      test('should handle very large confidence intervals', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.0,
          confidenceUpper: 1.0,
        );

        expect(score.confidenceIntervalWidth, equals(1.0));
        expect(score.confidenceIntervalString, equals('0.000 - 1.000'));
      });

      test('should handle negative confidence intervals', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.6,
          confidenceUpper: 0.4,
        );

        expect(score.confidenceIntervalWidth, closeTo(-0.2, 0.001));
        expect(score.confidenceIntervalString, equals('0.600 - 0.400'));
      });

      test('should handle zero confidence interval width', () {
        final score = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.5,
          confidenceUpper: 0.5,
        );

        expect(score.confidenceIntervalWidth, equals(0.0));
        expect(score.confidenceIntervalString, equals('0.500 - 0.500'));
      });
    });

    group('Performance Tests', () {
      test('should handle multiple copy operations efficiently', () {
        final original = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
          confidenceLevel: 0.95,
        );

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          original.copyWith(score: 0.5 + (i / 10000));
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
        ); // Should be very fast
      });

      test('should handle multiple equality checks efficiently', () {
        final score1 = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
          confidenceLevel: 0.95,
        );

        final score2 = RelevanceScore(
          score: 0.5,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
          confidenceLevel: 0.95,
        );

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          score1 == score2;
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
        ); // Should be very fast
      });

      test('should handle multiple threshold checks efficiently', () {
        final score = RelevanceScore(score: 0.5);

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          score.isAboveThreshold(i / 1000.0);
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
        ); // Should be very fast
      });
    });
  });
}
