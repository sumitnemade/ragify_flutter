import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  group('RelevanceScore Tests', () {
    test('creation with required parameters', () {
      final score = RelevanceScore(score: 0.8);
      expect(score.score, equals(0.8));
      expect(score.confidenceLevel, equals(0.95));
      expect(score.confidenceLower, isNull);
      expect(score.confidenceUpper, isNull);
    });

    test('creation with all parameters', () {
      final score = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
        confidenceLevel: 0.90,
      );
      expect(score.score, equals(0.7));
      expect(score.confidenceLower, equals(0.6));
      expect(score.confidenceUpper, equals(0.8));
      expect(score.confidenceLevel, equals(0.90));
    });

    test('validation - score too high throws AssertionError', () {
      expect(() => RelevanceScore(score: 1.5), throwsAssertionError);
      expect(() => RelevanceScore(score: 2.0), throwsAssertionError);
    });

    test('validation - score too low throws AssertionError', () {
      expect(() => RelevanceScore(score: -0.1), throwsAssertionError);
      expect(() => RelevanceScore(score: -1.0), throwsAssertionError);
    });

    test('validation - score at boundaries is valid', () {
      expect(() => RelevanceScore(score: 0.0), returnsNormally);
      expect(() => RelevanceScore(score: 1.0), returnsNormally);
      expect(() => RelevanceScore(score: 0.5), returnsNormally);
    });

    test('isAboveThreshold works correctly', () {
      final score = RelevanceScore(score: 0.7);
      expect(score.isAboveThreshold(0.5), isTrue);
      expect(score.isAboveThreshold(0.7), isTrue);
      expect(score.isAboveThreshold(0.8), isFalse);
      expect(score.isAboveThreshold(1.0), isFalse);
    });

    test('confidenceIntervalWidth calculation', () {
      final score1 = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
      );
      expect(score1.confidenceIntervalWidth, closeTo(0.2, 0.001));

      final score2 = RelevanceScore(score: 0.7);
      expect(score2.confidenceIntervalWidth, isNull);
    });

    test('confidenceIntervalString formatting', () {
      final score1 = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
      );
      expect(score1.confidenceIntervalString, equals('0.600 - 0.800'));

      final score2 = RelevanceScore(score: 0.7);
      expect(score2.confidenceIntervalString, equals('N/A'));
    });

    test('copyWith functionality', () {
      final original = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
        confidenceLevel: 0.95,
      );

      final updated = original.copyWith(
        score: 0.8,
        confidenceLower: 0.7,
        confidenceUpper: 0.9,
        confidenceLevel: 0.90,
      );

      expect(updated.score, equals(0.8));
      expect(updated.confidenceLower, equals(0.7));
      expect(updated.confidenceUpper, equals(0.9));
      expect(updated.confidenceLevel, equals(0.90));
    });

    test('copyWith with partial updates', () {
      final original = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
      );

      final updated = original.copyWith(score: 0.8);
      expect(updated.score, equals(0.8));
      expect(updated.confidenceLower, equals(0.6));
      expect(updated.confidenceUpper, equals(0.8));
      expect(updated.confidenceLevel, equals(0.95));
    });

    test('JSON serialization', () {
      final score = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
        confidenceLevel: 0.90,
      );

      final json = score.toJson();
      expect(json['score'], equals(0.7));
      expect(json['confidence_lower'], equals(0.6));
      expect(json['confidence_upper'], equals(0.8));
      expect(json['confidence_level'], equals(0.90));
    });

    test('JSON deserialization', () {
      final json = {
        'score': 0.7,
        'confidence_lower': 0.6,
        'confidence_upper': 0.8,
        'confidence_level': 0.90,
      };

      final score = RelevanceScore.fromJson(json);
      expect(score.score, equals(0.7));
      expect(score.confidenceLower, equals(0.6));
      expect(score.confidenceUpper, equals(0.8));
      expect(score.confidenceLevel, equals(0.90));
    });

    test('toString formatting', () {
      final score1 = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
      );
      expect(score1.toString(), contains('0.700'));
      expect(score1.toString(), contains('0.600 - 0.800'));

      final score2 = RelevanceScore(score: 0.7);
      expect(score2.toString(), contains('0.700'));
      expect(score2.toString(), contains('N/A'));
    });

    test('equality and hashCode', () {
      final score1 = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
        confidenceLevel: 0.95,
      );

      final score2 = RelevanceScore(
        score: 0.7,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
        confidenceLevel: 0.95,
      );

      final score3 = RelevanceScore(score: 0.8);

      expect(score1, equals(score2));
      expect(score1, isNot(equals(score3)));
      expect(score1.hashCode, equals(score2.hashCode));
      expect(score1.hashCode, isNot(equals(score3.hashCode)));
    });
  });
}
